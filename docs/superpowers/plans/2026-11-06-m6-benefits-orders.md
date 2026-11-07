# M6 权益订单 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本地模拟的权益订单模块：积分/小豆分账、小豆签到、权益领取、兑换、卡券状态、订单列表/详情与取消、客户等级，并把功能目录 M6 五项改为可用、“我的”统计卡接入跳转。

**Architecture:** 纯 Foundation 模型层（卡券模板/权益/商品/种子流水为静态目录；等级、状态、签到连续、限兑、编码均为纯函数，时间来自注入的 `BankingDateContext`）+ 单一聚合 `BenefitsStore`（UserDefaults 快照，照 `BranchServiceStore` 模式，每次变更整体一次提交）。UIKit 页面经 `AppRoute`/`AppRouter` 进入，继承 `BenefitsFlowViewController`（`TransferFlowViewController` 子类）。

**Tech Stack:** Swift 5、UIKit、SnapKit、UserDefaults；检查脚本 `xcrun swiftc -default-isolation MainActor`。

**Spec:** `docs/superpowers/specs/2026-11-06-m6-benefits-orders-design.md`

## Global Constraints

- iOS 15.6+；不新增依赖；不发网络请求；无实物商品、无真实资金；不新增图片资源（SF Symbols + 现有图标）。
- 所有日期按 `BankingDateContext`（Asia/Shanghai）计算；不得用 `Date()` / `Calendar.current` 直接取时间。
- 被检查脚本编译的模型类型标 `nonisolated`（脚本带 `-default-isolation MainActor`）。
- 稳定编码一律复用 `BranchSchedule.stableHash`（FNV-1a 64），**不得**用 `hashValue`。
- 存储键 `abank.benefits.v1`；无法解码时视为空快照，原字节保留到下次成功保存；写入失败内存不变、不发通知。
- 币种分账：兑换只扣商品标价币种；取消退回原币种原金额；累计获得积分不含 `refund`。
- 文案用中文；页面用 `abank*` 颜色/字体与 `Spacing`、`CornerRadius`；新页面实现 `RouteHosting`。
- 工程使用文件系统同步分组，新文件放进 `ABank/` 即可，不改 pbxproj。
- 提交：中文 Conventional Commits，只提交本任务文件，不推送、不合并。
- 构建命令：`xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build`

## Review Focus

1. **取消订单抬高等级**：累计获得积分只算 `seed/checkIn/claim` 正收入，退回不计（Task 1 `lifetimeEarned`、Task 2 `cancelKeepsLevel`）。
2. **上海日/月界**：UTC 23:30（上海次日 07:30）签到记在上海新一天；UTC 10 月 31 日 16:30（上海 11 月 1 日）“每月一次”权益重新可领（Task 1 `shanghaiBoundaries`、Task 2 `monthlyClaimRollover`）。
3. **过期/可取消边界**：`now == expiresAt` 即已过期，不可取消、不可使用（Task 1 `couponStatus`、Task 2 `cancelRules`）。
4. **余额与限兑边界**：余额恰等于标价可兑，少 1 不可兑；同商品本月限兑次数满后拒绝，取消的订单不占名额（Task 2 `redeemRules`）。
5. **损坏数据与写入失败原子性**：损坏 JSON 视为空且不覆盖原字节；兑换/取消写入失败时流水、卡券、订单三者都不变且不发通知（Task 2 `corruptRecordsKeepOriginal`、`writeFailureIsAtomic`）。

---

### Task 1: 模型、目录与规则纯函数

**Files:**
- Create: `ABank/Features/Benefits/Models/BenefitsModels.swift`
- Create: `ABank/Features/Benefits/Models/BenefitsCatalog.swift`
- Create: `ABank/Features/Benefits/Models/BenefitsRules.swift`
- Create: `scripts/check_benefits.swift`
- Modify: `scripts/check_banking_data.sh`（sources 加三个模型文件；循环加 `benefits` → `scripts/check_benefits.swift`）

**Interfaces:**
- Produces（全部 `nonisolated`）：
  - `enum RewardCurrency: String, Codable, CaseIterable { case points, beans }`，`title`（积分 / 小豆）
  - `enum RewardEntryKind: String, Codable { case seed, checkIn, claim, redeem, refund }`
  - `struct RewardEntry: Codable, Equatable { let id: String; let currency: RewardCurrency; let amount: Int; let kind: RewardEntryKind; let title: String; let createdAt: Date; let orderID: String? }`
  - `enum CustomerLevel: Int, CaseIterable, Comparable { case none, one, two, three, four, five }`，`title`（普通客户 / 一星客户 … 五星客户）、`threshold`（0 / 2,000 / 10,000 / 30,000 / 80,000 / 200,000）、`next: CustomerLevel?`、`shortTitle`（“普通”“一星”…用于“需 X 星”提示）
  - `enum BenefitPeriod { case once, monthly }`、`enum BenefitReward: Equatable { case points(Int), coupon(templateID: String) }`
  - `struct Benefit { let id, title, subtitle: String; let minLevel: CustomerLevel; let period: BenefitPeriod; let reward: BenefitReward }`
  - `struct CouponTemplate { let id, title, brand, faceText: String; let validDays: Int; let note: String }`
  - `struct RewardGoods { let id: String; let templateID: String; let currency: RewardCurrency; let price: Int; let monthlyLimit: Int }`
  - `struct Coupon: Codable, Equatable { let id, templateID: String; let benefitID: String?; var orderID: String?; let receivedAt: Date; var usedAt: Date?; var voidedAt: Date? }`
  - `enum CouponStatus: Equatable { case unused, used, expired, voided }`，`title`：待使用 / 已使用 / 已过期 / 已作废；`isActive`（仅 unused）
  - `struct RewardOrder: Codable, Equatable { let id, orderNo, goodsID, title: String; let currency: RewardCurrency; let cost: Int; let quantity: Int; let createdAt: Date; let couponID: String; var cancelledAt: Date? }`
  - `enum OrderStatus: Equatable { case pendingUse, used, expired, cancelled }`，`title`：待使用 / 已使用 / 已过期 / 已取消
  - `struct BenefitClaim: Codable, Equatable { let id, benefitID: String; let createdAt: Date; let couponID: String? }`
  - `enum ClaimState: Equatable { case available, claimedOnce, claimedThisMonth, levelTooLow(CustomerLevel) }`，`title`（领取 / 已领取 / 本月已领 / 需 X 星）
  - `struct BenefitsRecords: Codable, Equatable { var entries: [RewardEntry]; var coupons: [Coupon]; var orders: [RewardOrder]; var claims: [BenefitClaim]; var checkInDays: [String]; static let empty }`
  - `enum BenefitsError: LocalizedError, Equatable { case insufficientBalance, monthlyLimitReached, alreadyCheckedIn, alreadyClaimed, levelTooLow, notCancellable, notUsable, unknownItem, saveFailed }`，`errorDescription` 中文：余额不足 / 本月兑换次数已达上限 / 今日已签到 / 已领取 / 客户等级不足 / 当前订单不可取消 / 卡券当前不可使用 / 内容不存在 / 保存失败，请稍后重试
  - `enum BenefitsCatalog { static let templates: [CouponTemplate]; static let benefits: [Benefit]; static let goods: [RewardGoods]; static let seedEntries: [RewardEntry]; static func template(id:) -> CouponTemplate?; static func benefit(id:) -> Benefit?; static func goods(id:) -> RewardGoods?; static func goods(in currency: RewardCurrency) -> [RewardGoods] }`
  - `enum BenefitsRules`（带 `dates: BankingDateContext` 参数）：
    - `static func level(forEarnedPoints: Int) -> CustomerLevel`
    - `static func balance(_ currency: RewardCurrency, entries: [RewardEntry]) -> Int`（entries 为种子 + 用户流水合并后）
    - `static func lifetimeEarned(entries: [RewardEntry]) -> Int`（积分币种、`kind` 不是 `refund`/`redeem` 且 `amount > 0`）
    - `static let checkInRewards = [5, 5, 8, 8, 10, 10, 20]`
    - `static func checkInStreak(days: [String], now: Date, dates:) -> Int`（从今天已签则今天、否则昨天起向前连续的天数；昨天也未签则 0）
    - `static func nextCheckInReward(streak: Int) -> Int`（`checkInRewards[streak % 7]`）
    - `static func expiresAt(_ coupon: Coupon, dates:) -> Date`（`receivedAt` 所在上海日 0 点 + `validDays` 天，若找不到模板按 30 天）
    - `static func status(of: Coupon, at: Date, dates:) -> CouponStatus`（优先级 voided > used > expired(now ≥ expiresAt) > unused）
    - `static func status(of: RewardOrder, coupon: Coupon?, at: Date, dates:) -> OrderStatus`
    - `static func claimState(of: Benefit, claims: [BenefitClaim], level: CustomerLevel, now: Date, dates:) -> ClaimState`
    - `static func redeemedCount(goodsID: String, orders: [RewardOrder], now: Date, dates:) -> Int`（本上海自然月、未取消）
    - `static func orderNo(id: String, createdAt: Date, dates:) -> String`（`M6` + `yyyyMMdd` + 8 位数字，由 `stableHash(id)` 派生）
    - `static func couponCode(id: String) -> String`（`XXXX-XXXX-XXXX` 12 位大写字母数字，由 `stableHash` 派生）

- [ ] **Step 1: 写失败检查** `scripts/check_benefits.swift`，`@main struct BenefitsChecks`，固定时钟工具 `at(_:)`/`clock(_:)`（同 `check_branch_services.swift`：解析 `yyyy-MM-dd HH:mm` 上海时区）。用例：
  - `catalog()`：`benefits.count == 8`，ID 唯一；`goods.count == 12`（积分 6 / 小豆 6），每个 goods 的 `templateID` 存在、`price > 0`、`monthlyLimit` 在 2…3；每个 benefit 的卡券奖励模板存在；`templates` ID 唯一；种子余额：`balance(.points) == 12860`、`balance(.beans) == 260`；`lifetimeEarned == 14360`；种子流水全部 `kind == .seed`；`level(forEarnedPoints: 14360) == .two`、`.two.title == "二星客户"`。
  - `levels()`：`level(forEarnedPoints:)` 在 0→none、1999→none、2000→one、9999→one、10000→two、29999→two、30000→three、80000→four、200000→five、1_000_000→five；`CustomerLevel.five.next == nil`、`.none.next == .one`；`threshold` 与上表一致。
  - `lifetimeEarned()`：在种子基础上追加 `redeem -500`、`refund +500`、`claim +200`、`checkIn` 小豆 `+5` → 累计积分为 14,360 + 200（refund 与 redeem 与小豆都不计）；`balance(.points)` 随之 = 12,860 − 500 + 500 + 200。
  - `checkInStreak()`：时钟 2026-11-06 10:00：`[]`→0；`["2026-11-06"]`→1；`["2026-11-05","2026-11-04"]`→2（今天未签从昨天算）；`["2026-11-06","2026-11-05","2026-11-03"]`→2（中断）；`["2026-11-04"]`→0；`nextCheckInReward(streak:)` 0…7 依次为 5,5,8,8,10,10,20,5。
  - `shanghaiBoundaries()`：时钟 UTC `2026-11-05T23:30:00Z`（上海 11-06 07:30）下 `checkInStreak(days:["2026-11-06"])` 为 1、`["2026-11-05"]` 为 1（昨天）；`claimState` 对“每月”权益：领取记录创建于 UTC `2026-10-31T15:59:00Z`（上海 10-31 23:59）时，在 UTC `2026-10-31T16:00:00Z`（上海 11-01 00:00）为 `.available`，在 UTC `2026-10-31T15:59:30Z` 仍为 `.claimedThisMonth`。
  - `claimStates()`：以 `.two` 级时钟 2026-11-06：新客礼（once）无记录 → `.available`，有记录 → `.claimedOnce`；月度积分礼（monthly，一星）本月有记录 → `.claimedThisMonth`；“三星月度加成”在 `.two` → `.levelTooLow(.three)` 且 `title == "需三星"`；等级足够且无记录 → `.available`。
  - `couponStatus()`：模板有效 30 天，`receivedAt` = 2026-11-01 15:00 → `expiresAt` = 2026-12-01 00:00；2026-11-30 23:59 `.unused`、2026-12-01 00:00 `.expired`；`usedAt` 非 nil → `.used`（即使已过期也 `.used`）；`voidedAt` 非 nil → `.voided`（优先于 used）；`isActive` 仅 `.unused`。订单状态：`cancelledAt` 非 nil → `.cancelled`，否则按卡券 `.unused/.used/.expired` 映射到 `.pendingUse/.used/.expired`；卡券为 nil → `.cancelled`。
  - `redeemedCount()`：同商品本月 2 单（其中 1 单已取消）、上月 1 单 → 1。
  - `codes()`：`orderNo` 匹配 `^M6\d{8}\d{8}$`，同输入确定、不同 id 不同；`couponCode` 匹配 `^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$` 且确定。

- [ ] **Step 2: 运行确认失败** — `scripts/check_banking_data.sh`，预期编译错误（类型未定义）。

- [ ] **Step 3: 实现三个模型文件。** 数据按下表（spec §3 已定的口径不再重复，以下为 spec 未逐项列出的目录值）：
  - 种子流水（积分 / 日期 / 标题 / 金额）：2026-02-10 新户开通礼 +3000；04-05 月度活跃奖励 +2500；05-20 消费积分 +1860；07-12 理财达标奖励 +4000；08-30 代发工资奖励 +3000；09-18 兑换咖啡券 −1500。小豆：06-01 新手礼 +100；08-15 活动奖励 +80；10-01 国庆签到礼 +120；10-10 兑换公交券 −40。ID 形如 `seed.points.1`；时间取各日 10:00 上海。
  - 卡券模板（虚构品牌，有效期均 30 天，除外卖券 15 天）：权益用 `coffee10` 咖啡 10 元券、`takeout15` 外卖 15 元红包（15 天）、`movie20` 电影 20 元券、`travel30` 出行 30 元券；商品用 `coffee30`、`phone10`、`cinema40`、`ride20`、`market50`、`book30`（积分）与 `phone5`、`coffeeBogo`、`videoMonth`、`carWash`、`bus5`、`bookstore10`（小豆）。每个模板含标题、品牌、面额文案、使用说明。
  - 权益 ID 与 spec §3.3 表一一对应：`welcomeGift`、`takeoutPack`、`monthlyPoints`、`coffeeMonthly`、`star2Points`、`movieMonthly`、`star3Points`、`travelMonthly`。
  - 商品（ID / 币种 / 标价 / 每月限兑）：`g.coffee30` 积分 3000/3；`g.phone10` 积分 1000/3；`g.cinema40` 积分 4000/2；`g.ride20` 积分 2000/3；`g.market50` 积分 5000/2；`g.book30` 积分 2500/2；`g.phone5` 小豆 100/3；`g.coffeeBogo` 小豆 150/2；`g.videoMonth` 小豆 200/2；`g.carWash` 小豆 120/2；`g.bus5` 小豆 50/3；`g.bookstore10` 小豆 80/2。商品 `templateID` 与同名模板对应（`g.` 前缀去掉）。
  - `BenefitClaim` 的“每月”判定与 `redeemedCount` 均以 `dates.string(from:, format: "yyyy-MM")` 比较。

- [ ] **Step 4: 运行通过** — `scripts/check_banking_data.sh`，预期输出 `Benefits checks passed`，其余检查照常通过。

- [ ] **Step 5: 提交** — `git add ABank/Features/Benefits/Models scripts/check_benefits.swift scripts/check_banking_data.sh && git commit -m "feat: 新增权益订单目录与规则模型"`

---

### Task 2: BenefitsStore

**Files:**
- Create: `ABank/Features/Benefits/BenefitsStore.swift`
- Modify: `scripts/check_benefits.swift`、`scripts/check_banking_data.sh`（sources 加 Store）

**Interfaces:**
- Consumes: Task 1 全部类型。
- Produces:
  - `final class BenefitsStore { static let shared; static let storageKey = "abank.benefits.v1"; static let didChangeNotification = Notification.Name("ABank.benefitsDidChange"); init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default, dates: BankingDateContext = .system, dataWriter: ((Data) throws -> Void)? = nil) }`
  - 读：`func balance(_ currency: RewardCurrency) -> Int`；`func ledger(currency: RewardCurrency) -> [RewardEntry]`（种子 + 用户流水，`createdAt` 倒序）；`var lifetimeEarnedPoints: Int`；`var level: CustomerLevel`；`var coupons: [Coupon]`、`var orders: [RewardOrder]`（`receivedAt`/`createdAt` 倒序）；`func coupon(id:) -> Coupon?`、`func order(id:) -> RewardOrder?`；`func status(of: Coupon) -> CouponStatus`、`func status(of: RewardOrder) -> OrderStatus`；`func claimState(of: Benefit) -> ClaimState`；`func redeemedCount(goodsID: String) -> Int`；`var checkInStreak: Int`、`var hasCheckedInToday: Bool`、`var nextCheckInReward: Int`；`var unusedCouponCount: Int`；`func couponCode(for: Coupon) -> String`
  - 写（全部 `throws BenefitsError`，成功后发通知）：`@discardableResult func checkIn() throws -> Int`（返回获得小豆）；`@discardableResult func claim(benefitID: String) throws -> BenefitClaim`；`@discardableResult func redeem(goodsID: String) throws -> RewardOrder`；`func cancelOrder(id: String) throws`；`func useCoupon(id: String) throws`
  - 内部：一律在 `records` 副本上改，再 `commit(_:)` 写入；解码失败视为 `.empty` 且不覆盖原字节。

- [ ] **Step 1: 写失败检查**（沿用 `withSuite` / `expect`；时钟用可变引用以便拨动）：
  - `seedAndFreshStore()`：新 Store：积分 12,860、小豆 260、`level == .two`、`coupons`/`orders` 空、`unusedCouponCount == 0`、`ledger(.points).count == 6`、倒序、`ledger(.beans)` 不含积分条目。
  - `checkInRules()`：2026-11-06 签到得 5 小豆，小豆余额 265，`hasCheckedInToday`；同日再签 → `alreadyCheckedIn`；拨到次日签到得 5（streak 1 → 第 2 日奖励 5）；再隔一天未签后再签 → 回到第 1 日奖励 5、`checkInStreak == 1`；连续签满 7 天第 7 日得 20，第 8 日回 5；流水 `kind == .checkIn`、币种小豆。
  - `claimRules()`：`welcomeGift` 领取 → 积分 +500、流水 `kind == .claim`；再领 → `alreadyClaimed`；`takeoutPack` 领取生成卡券（`benefitID` 有值、`orderID == nil`、状态 `.unused`、`unusedCouponCount == 1`）；`star3Points`（需三星）→ `levelTooLow`；未知 ID → `unknownItem`；`monthlyPoints` 同月再领 → `alreadyClaimed`。
  - `monthlyClaimRollover()`：Review Focus 2——10-31 23:59（上海）领取 `monthlyPoints`，拨到 11-01 00:00 可再领成功。
  - `redeemRules()`：兑换 `g.coffee30`（3000 积分）成功：积分 −3000，小豆不变，订单 `cost == 3000`、`currency == .points`、`orderNo` 符合格式、`couponID` 指向状态 `.unused` 的卡券（`orderID` 回指订单），流水 `kind == .redeem` 且 `orderID` 为订单 ID；`unusedCouponCount == 1`；`redeemedCount == 1`；余额恰等于价格——先把积分兑换到恰 1,000（构造方式：向 defaults 预置一个 `BenefitsRecords`，含一条用户 `redeem` 积分流水 `-11860`，使余额为 1,000；另一份预置 `-11861` 使余额为 999），再兑 `g.phone10` 成功、余额 0，再兑任意积分商品 → `insufficientBalance`；少 1（余额 999）兑 `g.phone10` → `insufficientBalance`；同商品兑满 3 次后第 4 次 → `monthlyLimitReached`，取消其中一单后可再兑；拨到下月后限额重置；小豆商品只扣小豆。
  - `useCoupon()`：使用待使用卡券成功 → `.used`、订单 `.used`；再次使用 → `notUsable`；过期卡券（拨时钟）使用 → `notUsable`；已作废 → `notUsable`。
  - `cancelRules()`：取消待使用订单：订单 `.cancelled`、卡券 `.voided`、原币种流水出现 `refund +cost`、余额回到兑换前、`orderID` 一致；再取消 → `notCancellable`；已使用订单取消 → `notCancellable`；`now == expiresAt` 的订单取消 → `notCancellable`（Review Focus 3）；不存在 ID → `notCancellable`；失败情形均不发通知。
  - `cancelKeepsLevel()`：Review Focus 1——兑换 `g.market50` 后取消，再兑换 `g.coffee30` 后取消：`lifetimeEarnedPoints` 恒为 14,360、`level` 恒为 `.two`；之后 `claim(welcomeGift)` → `lifetimeEarnedPoints == 14,860`（只有 claim/checkIn 会增加累计）。
- `persistence()`：做一次签到、领取、兑换后新建 Store（同 defaults）读回：余额、卡券、订单、领取、签到日全部一致。
  - `corruptRecordsKeepOriginal()`：写入 `{"entries":[{"id":1}]}` → 视为空快照（余额为种子值），defaults 中原字节未变；随后成功签到才覆盖。
  - `writeFailureIsAtomic()`：`dataWriter` 抛错时 `redeem`/`cancelOrder`/`checkIn`/`claim` 均抛 `saveFailed`，余额、`coupons`、`orders`、`ledger` 与调用前一致，通知计数不变；换成功 writer 后同一操作可成功。
  - `notifications()`：每个成功写入各发 1 次通知，失败 0 次。

- [ ] **Step 2: 运行确认失败** — `scripts/check_banking_data.sh`，预期编译错误。

- [ ] **Step 3: 实现 `BenefitsStore`。** 要点：`records` 私有；`entries` 读取 = `BenefitsCatalog.seedEntries + records.entries`；`redeem` 在副本上追加订单、卡券（`receivedAt = now`、`orderID`）、流水（id 用 `UUID().uuidString`），校验顺序：商品存在 → 币种余额 → 本月限兑；`cancelOrder` 校验订单存在且未取消、卡券 `.unused`；`checkIn` 在副本上追加日期 `yyyy-MM-dd` 与小豆流水，奖励按提交时刻重算的 streak；`claim` 先查等级再查周期，积分类写流水、卡券类生成卡券；`commit` 同 `BranchServiceStore`（编码→`dataWriter` 或 defaults→赋值→发通知）。

- [ ] **Step 4: 运行通过** — `scripts/check_banking_data.sh`，预期输出 `Benefits checks passed`。

- [ ] **Step 5: 提交** — `git add ABank/Features/Benefits/BenefitsStore.swift scripts/check_benefits.swift scripts/check_banking_data.sh && git commit -m "feat: 新增权益订单存储"`

---

### Task 3: 路由骨架、页面基类、共用视图与权益中心

**Files:**
- Modify: `ABank/Core/Routing/AppRoute.swift`、`ABank/Core/Routing/AppRouter.swift`
- Create: `ABank/Features/Benefits/BenefitsFlowViewController.swift`
- Create: `ABank/Features/Benefits/Views/BenefitsViews.swift`
- Create: `ABank/Features/Benefits/BenefitsCenterViewController.swift`
- Create: `ABank/Features/Benefits/Views/BenefitsPresentation.swift`（枚举到文案/图标/颜色的 UI 扩展）

**Interfaces:**
- Consumes: Task 2 `BenefitsStore`；`TransferFlowViewController`（`contentStack`、`addButton`、`addGroup`）；`BranchCardView`、`BranchStatusTagView(text:active:)`、`BranchChipBar`、`branchTitleLine`、`branchCaption`。
- Produces:
  - `AppRoute` 新增：`benefits`、`pointsMall`、`beans`、`goodsDetail(goodsID: String)`、`rewardLedger(currency: RewardCurrency)`、`coupons`、`couponDetail(couponID: String)`、`orders`、`orderDetail(orderID: String, justRedeemed: Bool)`、`customerLevel`。
  - `AppRouter.makeViewController` 补全分支：`.benefits → BenefitsCenterViewController()`；其余 9 个暂映射到 `ComingSoonViewController(featureID: …)`（`.pointsMall/.beans/.orders/.customerLevel` 用对应 FeatureID，其余用 `.benefits`），每处加注释 `// 由 Task N 替换`，后续任务逐个替换，保证每个任务可构建。
  - `class BenefitsFlowViewController: TransferFlowViewController`：`let benefits: BenefitsStore`、`let dates: BankingDateContext`；`init(benefits: BenefitsStore = .shared, dates: BankingDateContext = .system)`（`hidesBottomBarWhenPushed = true`）；监听 `BenefitsStore.didChangeNotification` 调 `refreshBankingData()`；`func clearContent()`、`func addCard(_:)`、`func addSectionTitle(_:)`、`func addEmptyState(_:id:)`、`func confirm(_:confirmTitle:action:)`、`func showError(_:)`（读 `BenefitsError`），与 `BranchFlowViewController` 同形。
  - `BenefitsViews.swift`：`final class BalanceCardView: UIView`（`init(level: CustomerLevel, points: Int, beans: Int)`，`onPointsTapped`、`onBeansTapped`、`onLevelTapped`）；`final class BenefitsRow: UIControl`（`init(title: String, subtitle: String, trailing: UIView?, id: String)`，`onTap`）；`func formattedAmount(_ value: Int) -> String`（千分位）。
  - `BenefitsPresentation.swift`：`extension RewardCurrency { var iconName: String; var tint: UIColor }`、`extension CouponStatus/OrderStatus/ClaimState { var tagActive: Bool }`。

- [ ] **Step 1: 实现。** 新路由与 Router 分支先加，构建确认通过（旧页面不受影响）；权益中心页面（`RouteHosting`，`hostedRoute == .benefits`，标题“权益中心”）：顶部 `BalanceCardView`（点积分/小豆 → `.rewardLedger`，点等级 → `.customerLevel`）、快捷入口行（积分商城、小豆乐园、我的卡券、我的订单，→ 对应路由）、“可领取权益”8 项（`BenefitsRow`，状态标签用 `ClaimState.title`，仅 `.available` 显示“领取”按钮；领取成功 toast “领取成功”并刷新，失败 `showError`）。`refreshBankingData()` 重建内容。控件设 `accessibilityIdentifier`：`benefits.points`、`benefits.beans`、`benefits.claim.<benefitID>`、`benefits.entry.<mall|beans|coupons|orders>`。

- [ ] **Step 2: 构建** — 运行构建命令，预期 `BUILD SUCCEEDED`；`scripts/check_banking_data.sh` 仍通过（`AppRoute` 新枚举值引用 `RewardCurrency`，确保 `AppRoute.swift` 与检查脚本 sources 已含 `BenefitsModels.swift`）。

- [ ] **Step 3: 提交** — `git add ABank/Core/Routing ABank/Features/Benefits && git commit -m "feat: 新增权益中心与路由骨架"`

---

### Task 4: 积分商城、小豆乐园与商品详情

**Files:**
- Create: `ABank/Features/Benefits/RewardMallViewController.swift`
- Create: `ABank/Features/Benefits/GoodsDetailViewController.swift`
- Modify: `ABank/Features/Benefits/Views/BenefitsViews.swift`（加 `CheckInCardView`、`GoodsCardView`）
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.pointsMall`、`.beans`、`.goodsDetail`）

**Interfaces:**
- Consumes: Task 2/3。
- Produces:
  - `final class RewardMallViewController: BenefitsFlowViewController, RouteHosting`，`init(currency: RewardCurrency, …)`；`hostedRoute` 为 `.pointsMall`（积分）/`.beans`（小豆）；标题“积分商城”/“小豆乐园”。顶部余额条（点击 → `.rewardLedger(currency:)`）；`currency == .beans` 时再加 `CheckInCardView(streak:todayReward:checkedIn:rewards:)`（7 格进度，已签 `streak` 格高亮；按钮“签到领 N 小豆”或“今日已签到”禁用，`onCheckIn`）；商品列表 `GoodsCardView(goods:template:remaining:)`（标价、本月余量 `monthlyLimit - redeemedCount`，点击 → `.goodsDetail`）。签到成功 toast “签到成功，获得 N 小豆”。
  - `final class GoodsDetailViewController: BenefitsFlowViewController, RouteHosting`，`init(goodsID:)`，`hostedRoute == .goodsDetail(goodsID:)`。显示卡券名、品牌、面额、有效天数、使用说明、标价、当前余额、兑换后余额、本月余量；按钮“立即兑换”：余额不足 → 禁用并显示“积分不足/小豆不足”，本月限兑已满 → 禁用并显示“本月兑换次数已达上限”；点击 → `confirm("确认用 N 积分兑换 …？")` → `benefits.redeem(goodsID:)` → 成功后 `router.open(.orderDetail(orderID:justRedeemed: true), from: self)`；失败 `showError`。控件 id：`mall.goods.<goodsID>`、`goods.redeem`、`checkin.button`。

- [ ] **Step 2: 构建** 预期 `BUILD SUCCEEDED`；`scripts/check_banking_data.sh` 通过。

- [ ] **Step 3: 提交** — `git add ABank/Features/Benefits ABank/Core/Routing/AppRouter.swift && git commit -m "feat: 新增积分商城小豆乐园与商品兑换"`

---

### Task 5: 我的卡券与我的订单

**Files:**
- Create: `ABank/Features/Benefits/CouponsViewController.swift`
- Create: `ABank/Features/Benefits/CouponDetailViewController.swift`
- Create: `ABank/Features/Benefits/OrdersViewController.swift`
- Create: `ABank/Features/Benefits/OrderDetailViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.coupons`、`.couponDetail`、`.orders`、`.orderDetail`）

**Interfaces:**
- Consumes: Task 2/3。
- Produces（均 `BenefitsFlowViewController, RouteHosting`）：
  - `CouponsViewController`（标题“我的卡券”，`hostedRoute == .coupons`）：`UISegmentedControl` 待使用 / 已使用 / 已失效（已过期+已作废）；行显示卡券名、面额、有效期至、状态标签；点击 → `.couponDetail`；空态“暂无卡券”（id `coupons.empty`）。
  - `CouponDetailViewController`（`init(couponID:)`）：卡券名、品牌、面额、状态、模拟券码（`couponCode(for:)`）、有效期、使用说明、来源（领取权益名 / 关联订单号，订单可点 → `.orderDetail(orderID:justRedeemed:false)`）；`unused` 时按钮“模拟使用”（`confirm` 后 `useCoupon`，toast “已模拟使用”）。
  - `OrdersViewController`（标题“我的订单”，`hostedRoute == .orders`）：`BranchChipBar` 筛选 全部 / 待使用 / 已使用 / 已失效 / 已取消；行显示商品标题、币种与金额（如“3,000 积分”）、下单时间、状态标签；空态“暂无订单”（id `orders.empty`）。
  - `OrderDetailViewController`（`init(orderID:justRedeemed:)`）：`justRedeemed` 时顶部成功横幅“兑换成功”；状态、商品、数量、支付币种与金额、订单号、下单时间、关联卡券（点击 → `.couponDetail`）；可取消时按钮“取消订单”（`confirm("取消后卡券作废，N 积分将原路退回，确定取消？")` → `cancelOrder`，成功 toast “已取消，N 积分已退回”）；不可取消时显示原因（已使用 / 已过期 / 已取消）。找不到订单时显示“订单不存在”。控件 id：`coupon.use`、`order.cancel`、`orders.filter.<i>`、`orders.row.<orderID>`。

- [ ] **Step 2: 构建** 预期 `BUILD SUCCEEDED`；`scripts/check_banking_data.sh` 通过。

- [ ] **Step 3: 提交** — `git add ABank/Features/Benefits ABank/Core/Routing/AppRouter.swift && git commit -m "feat: 新增我的卡券与订单页面"`

---

### Task 6: 积分/小豆明细与客户等级

**Files:**
- Create: `ABank/Features/Benefits/RewardLedgerViewController.swift`
- Create: `ABank/Features/Benefits/CustomerLevelViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.rewardLedger`、`.customerLevel`）

**Interfaces:**
- Produces:
  - `RewardLedgerViewController(currency:)`（`hostedRoute == .rewardLedger(currency:)`，标题“积分明细”/“小豆明细”）：余额头；筛选 全部 / 收入 / 支出（`BranchChipBar`）；按月分组（`yyyy年M月` 小标题），行显示标题、时间、带符号金额（收入绿色、支出默认色）；退回（refund）算收入；空态“暂无明细”（id `ledger.empty`）。
  - `CustomerLevelViewController`（`hostedRoute == .customerLevel`，标题“客户等级”）：当前等级、累计获得积分、进度条与“距 X 星还差 N 积分”（五星显示“已是最高等级”）、各等级对比表（等级 / 累计积分门槛 / 可领取权益数 = `minLevel <= 该等级` 的 `BenefitsCatalog.benefits` 个数）。

- [ ] **Step 2: 构建** 预期 `BUILD SUCCEEDED`；`scripts/check_banking_data.sh` 通过。

- [ ] **Step 3: 提交** — `git add ABank/Features/Benefits ABank/Core/Routing/AppRouter.swift && git commit -m "feat: 新增积分小豆明细与客户等级"`

---

### Task 7: 入口开放与接线

**Files:**
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（`beans/pointsMall/benefits/customerLevel/orders` 改 `.available`，删除 `benefitsStage`）
- Modify: `scripts/check_feature_catalog.swift`
- Modify: `ABank/Features/Mine/Models/MineModels.swift`、`ABank/Data/MockDataProvider.swift`
- Modify: `ABank/Features/Mine/Views/MineAssetStatsCardView.swift`、`ABank/Features/Mine/MineViewController.swift`
- Modify: `ABank/Features/Life/LifeViewController.swift`
- Test: `scripts/check_benefits.swift`（追加 `mineStats()`）

**Interfaces:**
- Produces:
  - 路由映射：`beans → .beans`、`pointsMall → .pointsMall`、`benefits → .benefits`、`customerLevel → .customerLevel`、`orders → .orders`。
  - `MineAssetStat` 增加 `let route: AppRoute?`（初始化器保持 `MineAssetStat(value:label:route:)`）。
  - `MockDataProvider.mineAssetStats(benefits: BenefitsStore = .shared) -> [MineAssetStat]`：银行卡 `1` → `.myAccount`；小豆 → `benefits.balance(.beans)`、`.rewardLedger(currency: .beans)`；积分 → `balance(.points)`、`.rewardLedger(currency: .points)`；礼券 → `unusedCouponCount`、`.coupons`；`getMinePageData().assetStats` 使用它。
  - `MineAssetStatsCardView.onItemTapped: ((Int) -> Void)?`，四格为 `UIControl`（id `mine.stat.<index>`）。
  - `MineViewController`：点击统计格 → `router.open(route, from:)`；监听 `BenefitsStore.didChangeNotification` 刷新统计卡与资料头等级（`vipLevel = BenefitsStore.shared.level.title`，`refreshProfileFromStore` 与 `bindData` 一致）。
  - 生活页：`onCouponsTapped → router.open(feature: .coupons…)`——卡券无 FeatureID，直接 `router.open(.coupons, from: self)`；缤纷活动主卡 `onFeaturedTapped → router.open(feature: .beans, …)`；`onPromoTapped → router.open(feature: .benefits, …)`。

- [ ] **Step 1: 写失败检查。** `check_feature_catalog.swift`：删除 `.benefits` 的 `.planned` 断言，改为五项均 `.available(对应路由)`；`.charity` 的“后续规划”断言保留；新增一个仍计划中的样例 `.mobileRecharge.plannedStageText == "计划阶段：M8 充值缴费"`；可用数 `24 → 29`；“计划中不记最近使用”两处 `store.recordUse(.benefits)` 改为 `.mobileRecharge`（第 104、120 行）；检查搜索 `vip` 仍命中 `.customerLevel`。`check_benefits.swift` 追加 `mineStats()`：新 Store 下 `mineAssetStats` 四项为 `1/260/12860/0`，标签、路由如上；`redeem` 后礼券 `1`、积分减少；`cancelOrder` 后礼券 `0`。

- [ ] **Step 2: 运行确认失败** — `scripts/check_banking_data.sh`。

- [ ] **Step 3: 实现上述改动。** 统计卡值用 `formattedAmount`（千分位）显示。

- [ ] **Step 4: 运行检查与构建** — `scripts/check_banking_data.sh` 全部通过；构建命令 `BUILD SUCCEEDED`；`git diff --check` 无输出。

- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 开放权益订单入口并接入我的统计卡"`

---

### Task 8: 模拟器验收

**Files:**
- Create（被 Git 忽略）：`artifacts/abc-resources/verification/m6-*.png`

- [ ] **Step 1: 构建并安装**到 iPhone 16 Pro 模拟器（用 `mcp__Claude_Code_iOS_Simulator__control`：`attach` → 构建 → `launch`）。
- [ ] **Step 2: 逐项验收并截图**（`m6-<name>.png`）：
  1. “我的”统计卡：小豆 260、积分 12,860、礼券 0；点银行卡进入“我的账户”；点小豆/积分进入对应明细；点礼券进入我的卡券（空态）。
  2. 权益中心：领取“新客礼”（积分 +500）、“外卖红包”（卡券 +1）；二次领取显示已领取；三星权益显示“需三星”。
  3. 小豆乐园：签到（+5、按钮变“今日已签到”）；用小豆兑换“公交 5 元券”；积分商城兑换“咖啡 30 元券”，余额变化正确。
  4. 订单列表/详情（含成功横幅）；卡券详情“模拟使用”后订单变已使用；另一单取消 → 积分/小豆原额退回、卡券作废、订单保留。
  5. 明细：收入/支出筛选与月份分组；客户等级页进度。
  6. 重启 App 后余额、订单、卡券、签到状态保持；功能目录中 5 项可进入；生活页“卡券”“订单”按钮。
- [ ] **Step 3: 记录问题**：发现的 Bug 先修再复验（修复各自提交，信息 `fix: …`）；无法验证的（320pt、小屏、大字体、午夜/过期实时界面）如实记入交接。
- [ ] **Step 4: 清理**：用 `simctl` 从 App 容器偏好中删除 `abank.benefits.v1`，恢复种子状态。

---

### Task 9: 全分支审查与文档

**Files:**
- Modify: `docs/development-plan.md`（M6 行改“已完成”、新增“M6 实施记录”、“下一会话：M7 财富产品”）
- Create: `docs/continuity/tasks/m6-benefits-orders.md`
- Modify: `docs/continuity/CURRENT.md`（索引加 m6）

- [ ] **Step 1: 全分支审查**：对 `main..HEAD` 做一次全分支代码审查（Critical / Important 必须修复并复验，Minor 记入交接）。
- [ ] **Step 2: 最终验证**：`scripts/check_banking_data.sh`、正常构建、`git diff --check` 全部通过。
- [ ] **Step 3: 写文档**：开发计划实施记录按 M5 格式（分支与起点、数据与规则、页面、入口、验证、模拟器、审查、未验证）；任务记录含目标与验收、已确认决策、提交列表、裁定、延后 Minor、未验证、下一步；不写 token/Cookie/个人敏感数据。
- [ ] **Step 4: 提交** — `git add docs && git commit -m "docs: 记录 M6 权益订单实施与验证结果"`；不推送、不合并。
