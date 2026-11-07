# M7 财富产品（理财）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本地模拟的理财产品模块：产品列表/筛选/详情、风险测评、购买、持仓与按日累计收益、赎回，现金与持仓转换与资产汇总一致，并把功能目录“理财产品”改为可用。

**Architecture:** Foundation 纯模型层（产品目录、收益/持有天数/测评等级均为纯函数，时间来自注入的 `BankingDateContext`）+ 理财订单并入账本根快照（`FinanceLedgerRecord.wealthOrders`，购买/赎回与账户流水在 `FinanceLedgerStore` 内一次 `persist` 原子写入）+ 独立 `RiskAssessmentStore`（UserDefaults，无资金）。UIKit 页面经 `AppRoute`/`AppRouter` 进入。

**Tech Stack:** Swift 5、UIKit、SnapKit、UserDefaults；检查脚本 `xcrun swiftc -default-isolation MainActor`。

**Spec:** `docs/superpowers/specs/2026-11-06-m7-wealth-products-design.md`

## Global Constraints

- iOS 15.6+；不新增依赖；不发网络请求；无真实资金；不新增图片资源（SF Symbols + 现有图标）。
- 所有日期按 `BankingDateContext`（Asia/Shanghai）计算；不得用 `Date()` / `Calendar.current` 直接取时间。
- 被检查脚本编译的纯模型类型标 `nonisolated`（脚本带 `-default-isolation MainActor`）；金额统一 `Int64` 分，复用 `TransferMoney`（`TransferSimulationModels.swift`）与账本既有 Double 余额的换算（`TransferMoney.cents(from:)` / `amount(_:)`）。
- 账本存储键保持 `abank.financeLedger.record.v8`；`wealthOrders` 用 `decodeIfPresent`，旧数据解码为空；风险测评键 `abank.riskAssessment.v1`；损坏数据不覆盖原字节，写入失败内存不变。
- 规格偏离（裁定）：理财买入/赎回流水的 `categoryId` 统一用既有筛选类别 `wealth_product`（“理财产品”，已在 `IncomeExpenseFilterCatalog` 本人资金往来组中），而非规格里的 `wealth_purchase`/`wealth_redeem`；其余流水字段按规格（`includeInFlow: false`、`iconKey: "wealth"`、渠道“本机模拟”）。
- 文案中文；页面用 `abank*` 颜色/字体与 `Spacing`；新页面实现 `RouteHosting`；复用 `BenefitsRow`、`BranchCardView`、`BranchStatusTagView`、`BranchChipBar`、`benefitsActionButton`、`branchCaption`、`TransferFlowViewController`、`TransferInfoRow`、`TransferInputRow`。
- 工程使用文件系统同步分组，新文件放进 `ABank/` 即可。
- 提交：中文 Conventional Commits，只提交本任务文件，不推送、不合并。
- 构建命令：`xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build`

## Review Focus

1. **上海日界**：购买日 23:59（UTC 15:59）持有 0 天，次日 00:00 为 1 天；可赎回日按上海日计算（Task 1 `holdingDays`、Task 3 `redeemBoundary`）。
2. **金额边界与 Double 余额换算**：余额 1,499.66 元 = 149,966 分；买入恰等于余额成功、多 1 分被拒；恰等于起购额成功、少 1 分被拒；100 万元上限（Task 3 `purchaseAmountRules`）。
3. **幂等**：同一 `requestID` 重复提交（含新建 Store 实例重启后）只产生一笔订单和一条流水（Task 3 `purchaseIdempotency`）。
4. **损坏与写入失败**：损坏账本字节不被覆盖并报 `corruptLedger`；购买/赎回写入失败时订单、流水、余额都不变且不发通知（Task 3 `corruptLedgerKeepsBytes`、`writeFailureIsAtomic`）。
5. **测评有效期与旧账本**：测评到期时刻即过期；重测不影响已有持仓；缺 `wealthOrders` 的旧账本解码为空且总资产不变（Task 2 `assessmentExpiry`、Task 3 `legacyLedgerDecodes`）。

---

### Task 1: 产品模型、目录与收益规则

**Files:**
- Create: `ABank/Features/WealthProduct/Models/WealthProductModels.swift`
- Create: `ABank/Features/WealthProduct/Models/WealthProductCatalog.swift`
- Create: `ABank/Features/WealthProduct/Models/WealthRules.swift`
- Create: `scripts/check_wealth.swift`
- Modify: `scripts/check_banking_data.sh`（sources 加三个模型文件；循环加 `wealth` → `scripts/check_wealth.swift`）

**Interfaces:**
- Produces（全部 `nonisolated`）：
  - `enum ProductRiskLevel: Int, CaseIterable, Comparable { case r1 = 1, r2, r3 }`：`title`（低风险/中低风险/中风险）、`shortTitle`（R1…）、`requiredProfile: RiskProfile`（R1→C1，R2→C2，R3→C3）
  - `enum RiskProfile: Int, Codable, CaseIterable, Comparable { case c1 = 1, c2, c3, c4, c5 }`：`title`（保守型/稳健型/平衡型/成长型/进取型）、`shortTitle`（C1…）
  - `enum WealthCategory: String, CaseIterable { case daily, steady, performance }`：`title`（日日悦享/低波稳健/业绩优选）
  - `enum HoldingPeriodFilter: CaseIterable { case any, within7, within30, over30 }`：`title`（不限/7天内/30天内/30天以上）、`func matches(minHoldDays: Int) -> Bool`
  - `struct WealthProduct: Equatable { let id, name: String; let category: WealthCategory; let risk: ProductRiskLevel; let rateBasisPoints: Int; let minHoldDays: Int; let minPurchaseInCents: Int64; let summary: String }`：`rateText`（如 `2.40%`）
  - `struct WealthOrder: Codable, Equatable { let id, requestID, productID, productName, accountID: String; let principalInCents: Int64; let rateBasisPoints: Int; let minHoldDays: Int; let createdAt: String; let purchaseTransactionID: String; var redeemedAt: String?; var redeemedAmountInCents: Int64?; var redeemTransactionID: String? }`（`createdAt` 为 `yyyy-MM-dd HH:mm:ss`，上海）
  - `enum WealthOrderStatus: Equatable { case holding(redeemable: Bool, daysUntilRedeemable: Int), redeemed }`
  - `enum WealthError: LocalizedError, Equatable { case invalidRequest, productNotFound, assessmentRequired, assessmentExpired, riskLevelTooLow, invalidAmount, belowMinimum, aboveMaximum, insufficientBalance, orderNotFound, notRedeemable, alreadyRedeemed, corruptLedger, persistence }`，`errorDescription` 中文：购买请求无效 / 产品不存在 / 请先完成风险测评 / 风险测评已过期，请重新测评 / 您的风险承受等级低于该产品风险等级 / 请输入有效金额 / 低于起购金额 / 超过单笔购买上限 / 账户可用余额不足 / 订单不存在 / 未达最低持有期，暂不可赎回 / 该订单已赎回 / 本地账本无法读取，请先检查账本数据 / 本地保存失败，本次未成交，请重试
  - `enum WealthProductCatalog { static let products: [WealthProduct]; static func product(id:) -> WealthProduct?; static func filtered(category: WealthCategory?, risk: ProductRiskLevel?, period: HoldingPeriodFilter) -> [WealthProduct] }`（保持目录顺序）
  - `enum WealthRules`（带 `dates: BankingDateContext` 参数）：
    - `static let maxPurchaseInCents: Int64 = 100_000_000`、`static let maxAccrualDays = 3650`
    - `static func holdingDays(since createdAt: String, now: Date, dates:) -> Int`（上海自然日差，购买当日 0，最小 0，封顶 `maxAccrualDays`）
    - `static func accruedInterestInCents(principal: Int64, rateBasisPoints: Int, days: Int) -> Int64`（`principal × bps × days / (10_000 × 365)` 整数向下取整）
    - `static func holdingValueInCents(of: WealthOrder, now: Date, dates:) -> Int64`（已赎回为 0）
    - `static func redeemableDay(of: WealthOrder, dates:) -> String`（`yyyy-MM-dd`，购买日 + `minHoldDays` 天）
    - `static func status(of: WealthOrder, now: Date, dates:) -> WealthOrderStatus`
    - `static func canBuy(_ product: WealthProduct, with profile: RiskProfile) -> Bool`

- [ ] **Step 1: 写失败检查** `scripts/check_wealth.swift`，`@main struct WealthChecks`，固定时钟工具 `at(_:)`/`clock(_:)`/`clock(utc:)`（同 `check_benefits.swift`）。用例：
  - `catalog()`：`products.count == 8`、ID 唯一；`w.tiantianli2` 为 日日悦享/R2/240bps/1 天/起购 100 分；`w.chengzhang` 为 业绩优选/R3/360bps/180 天/起购 100_000 分；`w.shishifu` R1/90bps；`w.lingdong90` 起购 100_000 分；每款 `minPurchaseInCents > 0`；`filtered(category: .daily, risk: nil, period: .any)` 仅含 `w.shishifu`、`w.tiantianli2`；`filtered(category: nil, risk: .r3, period: .any).map(\.id) == ["w.chengzhang"]`；`period: .within7` 含 `w.shishifu/tiantianli2/piaoxi/wenjian7` 且不含 30 天以上；`.over30` 恰为 90/180 天产品；`rateText == "2.40%"`。
  - `riskMapping()`：`ProductRiskLevel.r2.requiredProfile == .c2`；`canBuy(r3 产品, with: .c2) == false`、`with: .c3 == true`、`r1 产品 with .c5 == true`；`RiskProfile.c1 < .c5`、`.c2.title == "稳健型"`、`ProductRiskLevel.r2.title == "中低风险"`。
  - `interestMath()`：`accruedInterestInCents(principal: 100_000, rateBasisPoints: 240, days: 30) == 197`；`days: 0 → 0`；`principal: 1, bps: 240, days: 30 → 0`；`principal: 10_000_000, bps: 240, days: 1 == 657`（10_000_000×240/3_650_000 向下取整）；最大值 `principal: 100_000_000, bps: 360, days: 3650`：脚本内用 `Decimal` 独立计算 `principal × bps × days / (10_000 × 365)` 并向下取整作为期望，断言相等（验证不溢出）。
  - `holdingDays()`：购买 `2026-11-06 23:59:30`：同日 23:59 → 0、次日 00:00 → 1、UTC `2026-11-06T15:59:00Z`（上海 23:59）→ 0、UTC `2026-11-06T16:00:00Z`（上海 11-07 00:00）→ 1；跨月 `2026-10-31 10:00` 买、`2026-11-02 08:00` → 2；跨年；超 3,650 天封顶；`now` 早于购买日 → 0。
  - `statusAndRedeemable()`：`minHoldDays: 1`，购买 11-06 10:00：当日 `.holding(redeemable: false, daysUntilRedeemable: 1)`；11-07 00:00 `.holding(redeemable: true, daysUntilRedeemable: 0)`；`redeemableDay == "2026-11-07"`；`minHoldDays: 180` 的 `redeemableDay == "2027-05-05"`；已赎回订单 `.redeemed` 且 `holdingValueInCents == 0`；持有中价值 = 本金 + 累计收益。

- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误（类型未定义）。
- [ ] **Step 3: 实现三个模型文件**，目录数据按 spec §3.1 表（名称、分类、风险、年化、持有期、起购额一一对应；`summary` 各写一句中文简介；ID 用 `w.shishifu/tiantianli2/piaoxi/wenjian7/wenjian30/lingdong90/lingdong180/chengzhang`）。收益整数运算先 `multipliedReportingOverflow` 防护，溢出时按 `Int64.max` 处理（不应触发）。
- [ ] **Step 4: 运行通过** — `zsh scripts/check_banking_data.sh`，预期末尾输出 `Wealth checks passed`，其余检查照常通过。
- [ ] **Step 5: 提交** — `git add ABank/Features/WealthProduct/Models scripts/check_wealth.swift scripts/check_banking_data.sh && git commit -m "feat: 新增理财产品目录与收益规则"`

---

### Task 2: 风险测评模型与存储

**Files:**
- Create: `ABank/Features/WealthProduct/Models/RiskAssessmentModels.swift`
- Create: `ABank/Features/WealthProduct/RiskAssessmentStore.swift`
- Modify: `scripts/check_wealth.swift`、`scripts/check_banking_data.sh`（sources 加两个文件）

**Interfaces:**
- Consumes: Task 1 `RiskProfile`。
- Produces:
  - `struct RiskQuestion: Equatable { let title: String; let options: [String] }`；`enum RiskQuestionnaire { static let questions: [RiskQuestion]（5 题，每题 4 项，按风险偏好由低到高排列）; static func score(answers: [Int]) -> Int?（答案数 ≠ 5 或下标越界返回 nil；每题得分 = 下标 + 1）; static func profile(forScore: Int) -> RiskProfile（5–8 C1，9–11 C2，12–14 C3，15–17 C4，18–20 C5）}`
  - 5 题标题：投资经验；可承受的最大亏损；计划投资期限；收入稳定性；投资目的。选项文案每题 4 条（保守 → 进取）自行拟定，须与题目含义匹配。
  - `struct RiskAssessmentRecord: Codable, Equatable { let answers: [Int]; let level: RiskProfile; let assessedAt: Date }`
  - `enum RiskAssessmentState: Equatable { case none, valid(RiskProfile, expiresOn: String), expired(RiskProfile) }`
  - `enum RiskAssessmentRules { static let validDays = 365; static func expiresAt(_ record: RiskAssessmentRecord, dates:) -> Date（测评日上海 0 点 + 365 天）; static func state(of record: RiskAssessmentRecord?, now: Date, dates:) -> RiskAssessmentState（now ≥ 到期时刻为 expired；expiresOn 为到期日前一天 `yyyy-MM-dd`）}`
  - `enum RiskAssessmentError: LocalizedError, Equatable { case incompleteAnswers, saveFailed }`（请完成全部题目 / 保存失败，请稍后重试）
  - `final class RiskAssessmentStore { static let shared; static let storageKey = "abank.riskAssessment.v1"; static let didChangeNotification = Notification.Name("ABank.riskAssessmentDidChange"); init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default, dates: BankingDateContext = .system, dataWriter: ((Data) throws -> Void)? = nil); var record: RiskAssessmentRecord?; var state: RiskAssessmentState; @discardableResult func submit(answers: [Int]) throws -> RiskAssessmentRecord }`

- [ ] **Step 1: 写失败检查**（追加到 `check_wealth.swift`，沿用 `withSuite`/`expect` 写法）：
  - `questionnaire()`：5 题、每题 4 项；`score(answers: [0,0,0,0,0]) == 5`、`[3,3,3,3,3] == 20`、`[1,1,1,1,1] == 10`；`score(answers: [0,0,0,0]) == nil`、`[0,0,0,0,4] == nil`、`[0,0,0,0,-1] == nil`；`profile(forScore:)` 边界 5→C1、8→C1、9→C2、11→C2、12→C3、14→C3、15→C4、17→C4、18→C5、20→C5。
  - `assessmentStoreRules()`：新 Store `state == .none`、`record == nil`；`submit(answers: [1,1,1,1,1])`（分数 10 → C2）成功，`state == .valid(.c2, …)` 并发 1 次通知；未答完 `submit(answers: [1])` → `incompleteAnswers` 且无通知；新建 Store 读回相同记录。
  - `assessmentExpiry()`：Review Focus 5——测评于 2026-11-06 10:00，到期时刻 2027-11-06 00:00：2027-11-05 23:59 为 `.valid`（`expiresOn == "2027-11-05"`），2027-11-06 00:00 为 `.expired(.c2)`；重测（拨时钟后再 `submit`）覆盖为新记录且 `state` 回到 `.valid`。
  - `assessmentPersistence()`：损坏字节 → `state == .none` 且 defaults 原字节未变，成功提交后才被覆盖；`dataWriter` 抛错 → `submit` 抛 `saveFailed`、`record` 不变、无通知。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误。
- [ ] **Step 3: 实现两个文件**（Store 模式同 `BenefitsStore`：`commit` 先编码、写入成功后赋值并发通知）。
- [ ] **Step 4: 运行通过** — 预期 `Wealth checks passed`。
- [ ] **Step 5: 提交** — `git add ABank/Features/WealthProduct scripts && git commit -m "feat: 新增风险测评模型与存储"`

---

### Task 3: 账本集成（订单、购买、赎回、资产汇总）

**Files:**
- Modify: `ABank/Features/Mine/Models/FinanceLedgerModels.swift`（`FinanceLedgerRecord` 加 `wealthOrders`，`wealthCategoryId`）
- Modify: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift`（`dates`、`loadForTransfer`、`persist` 去掉 `private`；新增 `riskStateProvider`；`totalAssets()` 含持仓；`assetLiabilityPageData()` 加“理财”类别）
- Create: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Wealth.swift`
- Modify: `scripts/check_wealth.swift`、`scripts/check_banking_data.sh`（sources 加 `FinanceLedgerStore+Wealth.swift`、`RiskAssessmentStore` 已在）

**Interfaces:**
- Consumes: Task 1/2 全部类型。
- Produces:
  - `FinanceLedgerRecord.wealthOrders: [WealthOrder] = []`（`CodingKeys` 加入，`decodeIfPresent`；`init(...)` 末尾加默认参数 `wealthOrders: [WealthOrder] = []`）；`FinanceLedgerRecord.wealthCategoryId = "wealth"`
  - `FinanceLedgerStore.init(…, riskStateProvider: @escaping @MainActor () -> RiskAssessmentState = { RiskAssessmentStore.shared.state }, …)`（参数位置放在 `transferLimitsProvider` 之后；既有调用点不受影响）
  - 扩展（`@MainActor`）：
    - `func wealthOrders() -> [WealthOrder]`（`createdAt` 倒序，同刻后建在前）、`func wealthOrder(id: String) -> WealthOrder?`
    - `func wealthStatus(of: WealthOrder) -> WealthOrderStatus`、`func accruedInterestInCents(of: WealthOrder) -> Int64`、`func holdingValueInCents(of: WealthOrder) -> Int64`、`func totalHoldingValueInCents() -> Int64`（未赎回订单价值之和）
    - `func validateWealthPurchase(productID: String, amountInCents: Int64) throws`（购买校验，不写入）
    - `@discardableResult func submitWealthPurchase(productID: String, amountInCents: Int64, requestID: String) throws -> WealthOrder`
    - `@discardableResult func redeemWealthOrder(orderID: String) throws -> WealthOrder`
  - 购买校验顺序（均抛 `WealthError`）：`requestID` 为空或超 100 字符 → `invalidRequest`；同 `requestID` 已有订单 → 直接返回；严格读取账本（损坏 → `corruptLedger`）；产品不存在 → `productNotFound`；测评状态 `.none` → `assessmentRequired`、`.expired` → `assessmentExpired`、`.valid` 但等级低于产品要求 → `riskLevelTooLow`；金额 ≤ 0 → `invalidAmount`；< 起购 → `belowMinimum`；> `maxPurchaseInCents` → `aboveMaximum`；付款账户固定为 `FinanceLedgerRecord.defaultAccountId` 对应账户（不存在或币种非人民币 → `invalidRequest`），余额（`TransferMoney.cents(from:)`）不足 → `insufficientBalance`。通过后一次根快照：追加订单与一条支出流水（`id: "wealth_buy_<订单ID>"`、`title: "理财购买-<产品名>"`、`direction: .expense`、`amount: TransferMoney.amount(分)`、`iconKey: "wealth"`、`categoryId: "wealth_product"`、`includeInFlow: false`、`counterpartyName: "农银理财（模拟）"`、`summary: "模拟理财购买"`、`cardNumber: "****" + 尾号`、`transactionType: "理财购买"`、`channel: "本机模拟"`）→ `recalculate` → 更新 `dataTimestamp` → `persist`（失败 → `persistence`）。
  - 赎回：订单不存在 → `orderNotFound`；已赎回 → `alreadyRedeemed`；`holdingDays < minHoldDays` → `notRedeemable`；赎回金额 = 本金 + 累计收益；追加收入流水（`id: "wealth_redeem_<订单ID>"`，`title: "理财赎回-<产品名>"`，`transactionType: "理财赎回"`，其余同购买）并写入订单的 `redeemedAt`（`yyyy-MM-dd HH:mm:ss`）、`redeemedAmountInCents`、`redeemTransactionID`；同样严格读取与一次 `persist`。
  - `totalAssets()` = 账户余额之和 + `TransferMoney.amount(totalHoldingValueInCents())`；`assetLiabilityPageData()` 在“活期”后、仅当存在未赎回订单时追加 `AssetLiabilityCategory(id: wealthCategoryId, title: "理财", totalAmount: 持仓价值合计, items: 每笔未赎回订单一项 { id: 订单 ID, title: 产品名, amount: 当前价值, showsCurrencySymbol: true, subtitle: "本金 x 元 · 收益 y 元", showsMenu: false })`。

- [ ] **Step 1: 写失败检查**（追加到 `check_wealth.swift`；参照 `check_transfer_data.swift` 的账本夹具：单账户 `acct_8472`、人民币、`FinanceLedgerStore(defaults:dates:riskStateProvider:dataWriter:)`，可变时钟 `TestClock`，`riskState` 用可变变量供 provider 读取）：
  - `legacyLedgerDecodes()`：Review Focus 5——夹具保存后去掉 JSON 的 `wealthOrders` 键写回，`load().wealthOrders.isEmpty`、`totalAssets()` 等于余额之和，`defaults` 字节未被改写。
  - `purchaseRules()`：风险状态 `.valid(.c2, …)`、余额 1,499.66（`balance: 1499.66`）：买 `w.tiantianli2` 500 元 → 订单本金 50_000、`createdAt` 为时钟格式化、流水 `wealth_buy_…` 支出 500.00 且 `includeInFlow == false`、`categoryId == "wealth_product"`；账户余额 999.66；`totalAssets()` 买前买后相等（1,499.66）；`mineMonthlyFlow().expense` 不变；`wealthOrders().count == 1`、`wealthStatus` 为 `.holding(redeemable: false, daysUntilRedeemable: 1)`；`.valid(.c2)` 买 `w.chengzhang` → `riskLevelTooLow`；`.none` → `assessmentRequired`；`.expired(.c3)` → `assessmentExpired`；未知产品 → `productNotFound`；以上失败均不改变订单数与余额。
  - `purchaseAmountRules()`：Review Focus 2——`w.tiantianli2` 起购 100 分：99 分 → `belowMinimum`、100 分成功；0 与 -1 → `invalidAmount`；余额 149_966 分时买 149_966 成功且余额 0、再买 100 → `insufficientBalance`；另起夹具余额 149_966 买 149_967 → `insufficientBalance`；余额 2 亿元的夹具买 100_000_001 分 → `aboveMaximum`、买 100_000_000 分成功；`w.lingdong90` 起购 100_000：99_999 → `belowMinimum`。
  - `purchaseIdempotency()`：Review Focus 3——同 `requestID` 连续两次返回相等订单、仅 1 条订单与 1 条流水；新建 `FinanceLedgerStore`（同 defaults）再提交同 `requestID` 仍相等；`requestID` 为空和 101 字符 → `invalidRequest`。
  - `accrualAndAssets()`：买 `w.tiantianli2` 100,000 分（1,000 元）；时钟拨 30 天后 `accruedInterestInCents == 197`、`holdingValueInCents == 100_197`、`totalAssets()` = 余额 + 1,001.97；`assetLiabilityPageData()` 含“理财”类别，类别合计 1,001.97，项副标题为“本金 1000.00 元 · 收益 1.97 元”，且 `totalAssets` 与各类别合计一致；无未赎回订单时不含“理财”类别。
  - `redeemBoundary()`：Review Focus 1——`w.tiantianli2`（1 天）购买 `2026-11-06 23:59:30`：同日赎回 → `notRedeemable`；UTC `2026-11-06T15:59:59Z` 仍 `notRedeemable`、UTC `2026-11-06T16:00:00Z`（上海 11-07 00:00）赎回成功；赎回金额 = 本金 + 0 天收益（购买后 1 天收益 = `accrued(…, days: 1)`）；收入流水 `wealth_redeem_…`、`includeInFlow == false`；订单 `redeemedAt/redeemedAmountInCents/redeemTransactionID` 有值、`wealthStatus == .redeemed`；赎回后 `totalAssets()` = 账户余额；再赎回 → `alreadyRedeemed`；未知 ID → `orderNotFound`；`w.lingdong180` 第 179 天 `notRedeemable`、第 180 天可赎回。
  - `corruptLedgerKeepsBytes()`：Review Focus 4——defaults 写入非法 JSON → 购买/赎回抛 `corruptLedger`，defaults 字节不变。
  - `writeFailureIsAtomic()`：Review Focus 4——`dataWriter` 先成功完成一笔购买，再置失败：`submitWealthPurchase` 与 `redeemWealthOrder` 均抛 `persistence`，订单、流水、余额与调用前一致，`.financeLedgerDidChange` 计数不变；恢复写入后赎回成功。
  - 既有检查必须保持通过（`zsh scripts/check_banking_data.sh` 全绿）。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误。
- [ ] **Step 3: 实现。** 账本改动按 Interfaces；`FinanceLedgerStore` 中把 `dates`、`loadForTransfer()`、`persist(_:)` 改为内部可见；订单 ID 用 `UUID().uuidString`；购买/赎回内部用 `loadForTransfer()` 读取（损坏映射为 `WealthError.corruptLedger`，写入失败映射为 `persistence`）；时间格式沿用转账（`dates.string(from:format:)`）。
- [ ] **Step 4: 运行通过** — `zsh scripts/check_banking_data.sh` 全部通过；`xcodebuild …` `BUILD SUCCEEDED`。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 理财订单并入账本并支持购买赎回"`

---

### Task 4: 路由骨架、页面基类、产品列表与详情

**Files:**
- Modify: `ABank/Core/Routing/AppRoute.swift`、`ABank/Core/Routing/AppRouter.swift`
- Create: `ABank/Features/WealthProduct/WealthFlowViewController.swift`
- Create: `ABank/Features/WealthProduct/Views/WealthViews.swift`
- Create: `ABank/Features/WealthProduct/WealthProductListViewController.swift`
- Create: `ABank/Features/WealthProduct/WealthProductDetailViewController.swift`

**Interfaces:**
- Consumes: Task 1–3。
- Produces:
  - `AppRoute` 新增：`wealthProducts`、`wealthProductDetail(productID: String)`、`riskAssessment`、`wealthPurchase(productID: String)`、`wealthOrderDetail(orderID: String, justPurchased: Bool)`、`wealthHoldings`。`AppRouter.makeViewController`：`.wealthProducts → WealthProductListViewController()`、`.wealthProductDetail → WealthProductDetailViewController(productID:)`，其余 4 个暂映射到 `ComingSoonViewController(featureID: .wealthProduct)` 并加注释 `// 由 Task N 替换`。
  - `class WealthFlowViewController: TransferFlowViewController`：`let ledger: FinanceLedgerStore`、`let risk: RiskAssessmentStore`、`let dates: BankingDateContext`；`init(ledger: FinanceLedgerStore = .shared, risk: RiskAssessmentStore = .shared, dates: BankingDateContext = .system)`（`hidesBottomBarWhenPushed = true`）；监听 `RiskAssessmentStore.didChangeNotification` 调 `refreshBankingData()`（账本通知由 `BankingDataViewController` 已处理）；同 `BenefitsFlowViewController` 提供 `clearContent()`、`addCard(_:)`、`addSectionTitle(_:)`、`addEmptyState(_:id:)`、`confirm(_:confirmTitle:action:)`、`showError(_:)`（读 `WealthError`/`RiskAssessmentError`/`TransferError` 文案）。
  - `WealthViews.swift`：`func wealthMoneyText(_ cents: Int64) -> String`（千分位、两位小数，如 `1,499.66`）；`func wealthRateText(_ bps: Int) -> String`；`func wealthProductRow(_ product: WealthProduct, onTap: @escaping () -> Void) -> BenefitsRow`（标题名称，副标题“<风险简称> <风险名> · 最低持有 N 天 · <起购额>元起购”，右侧年化率，id `wealth.row.<productID>`）。
- **产品列表页**（`hostedRoute == .wealthProducts`，标题“理财产品”）：分类 `BranchChipBar`（全部 + 3 类）、风险 `BranchChipBar`（全部风险 + R1–R3）、期限 `BranchChipBar`（`HoldingPeriodFilter`），三组筛选叠加；空结果显示“暂无符合条件的产品”（id `wealth.empty`）；右上角“我的持仓”（id `wealth.holdings`）→ `.wealthHoldings`。chip id 前缀 `wealth.filter.category/risk/period`。
- **产品详情页**（`hostedRoute == .wealthProductDetail(productID:)`，标题“产品详情”）：名称、年化（大字）、`TransferInfoRow`：风险等级、最低持有期、起购额、产品简介、可赎回规则（“持有满 N 天后可赎回，本息即时到账”）；风险提示文案；按钮“立即购买”（id `wealth.buy`）：读 `risk.state` 与产品要求——未测评/已过期/等级不足时 `confirm` 提示（含原因与“去测评”），确认后 `router.open(.riskAssessment, from: self)`；满足时 `router.open(.wealthPurchase(productID:), from: self)`。产品不存在显示“产品不存在”。

- [ ] **Step 1: 实现**，先加路由与 Router 分支并确认可构建，再做页面。
- [ ] **Step 2: 构建** — 运行构建命令，预期 `BUILD SUCCEEDED`；`zsh scripts/check_banking_data.sh` 通过。
- [ ] **Step 3: 提交** — `git add ABank && git commit -m "feat: 新增理财产品列表与详情"`

---

### Task 5: 风险测评页面

**Files:**
- Create: `ABank/Features/WealthProduct/RiskAssessmentViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.riskAssessment`）

**Interfaces:**
- Produces: `final class RiskAssessmentViewController: WealthFlowViewController, RouteHosting`（`hostedRoute == .riskAssessment`，标题“风险测评”）：
  - 顶部状态卡：当前测评等级与有效期（`.none` 显示“尚未测评”，`.expired` 显示“已过期，请重新测评”）。
  - 5 题，每题 4 个单选项（选中高亮，id `risk.q<题号>.<选项号>`）；全部作答前“提交测评”（id `risk.submit`）禁用；提交调用 `risk.submit(answers:)`，成功后显示结果区（等级名称、说明、有效期至）与“完成”按钮（`navigationController?.popViewController`）；失败 `showError`。
  - 已有有效测评时顶部显示“重新测评”语义（可直接作答覆盖）；作答状态在页面存活期内保持（刷新不丢失）。
- [ ] **Step 1: 实现并构建** — 预期 `BUILD SUCCEEDED`；`zsh scripts/check_banking_data.sh` 通过。
- [ ] **Step 2: 提交** — `git add ABank && git commit -m "feat: 新增风险测评页面"`

---

### Task 6: 购买页与订单详情

**Files:**
- Create: `ABank/Features/WealthProduct/WealthPurchaseViewController.swift`
- Create: `ABank/Features/WealthProduct/WealthOrderDetailViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.wealthPurchase`、`.wealthOrderDetail`）

**Interfaces:**
- Produces:
  - `WealthPurchaseViewController(productID:)`（`hostedRoute == .wealthPurchase(productID:)`，标题“购买”）：显示产品名、年化、风险、最低持有期；付款账户“借记卡 尾号xxxx”与可用余额（`wealthMoneyText`）；金额输入 `TransferInputRow`（id `wealth.amount`，小数键盘，占位“请输入金额（元）”）；预计可赎回日（购买日 + `minHoldDays`）；风险揭示勾选（id `wealth.agree`，未勾选禁用提交）；金额校验用 `TransferMoney.parse` 与 `ledger.validateWealthPurchase`，输入变化时在行下方显示错误文案（`wealth.error`）并禁用提交；“确认购买”（id `wealth.submit`）→ `confirm("确认购买 <金额> 元「产品名」？")` → `ledger.submitWealthPurchase(productID:amountInCents:requestID:)`，`requestID` 在页面创建时生成一次并复用（重复点击幂等）；成功后 `router.open(.wealthOrderDetail(orderID:justPurchased: true), from: self)`；失败 `showError`。
  - `WealthOrderDetailViewController(orderID:justPurchased:)`（`hostedRoute == .wealthOrderDetail(orderID:justPurchased:)`，标题“订单详情”）：`justPurchased` 且持有中时显示成功横幅“✓ 购买成功（本机模拟）”（id `wealth.success`）；产品名与状态标签；`TransferInfoRow`：本金、累计收益、当前价值、持有天数、购买时间、年化、可赎回日；持有中且可赎回时“赎回”按钮（id `wealth.redeem`）→ `confirm("赎回后本息约 <金额> 元将回到账户，确定赎回？")` → `redeemWealthOrder`，成功 toast“赎回成功，<金额> 元已到账”；未满期时按钮禁用并说明“还需持有 N 天，<日期>起可赎回”；已赎回显示赎回时间与赎回金额与说明；订单不存在显示“订单不存在”。
- [ ] **Step 1: 实现并构建** — 预期 `BUILD SUCCEEDED`；`zsh scripts/check_banking_data.sh` 通过。
- [ ] **Step 2: 提交** — `git add ABank && git commit -m "feat: 新增理财购买与订单详情"`

---

### Task 7: 我的持仓与资产负债联动

**Files:**
- Create: `ABank/Features/WealthProduct/WealthHoldingsViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.wealthHoldings`，此后不再有 `ComingSoon` 临时映射）
- Modify: `ABank/Features/Mine/AssetLiability/AssetLiabilityViewController.swift`（`navigate(for:)` 增加 `FinanceLedgerRecord.wealthCategoryId` → `.wealthHoldings`，子项 → `.wealthOrderDetail(orderID: itemId, justPurchased: false)`）

**Interfaces:**
- Produces: `WealthHoldingsViewController`（`hostedRoute == .wealthHoldings`，标题“我的持仓”）：顶部汇总卡（总持仓价值、累计收益，均持有中订单合计，id `holdings.total`）；`UISegmentedControl` 持有中 / 已赎回（id `holdings.segment`）；行显示产品名、本金与当前价值、状态标签（“可赎回”/“N 天后可赎回”/“已赎回”），点击进订单详情（id `holdings.row.<orderID>`）；空态“暂无持仓，去看看理财产品”并带“去选产品”按钮（→ `.wealthProducts`，id `holdings.empty`）。
- [ ] **Step 1: 实现并构建** — 预期 `BUILD SUCCEEDED`；`grep -n "ComingSoonViewController" ABank/Core/Routing/AppRouter.swift` 仅剩 `.comingSoon(id)` 一处；`zsh scripts/check_banking_data.sh` 通过。
- [ ] **Step 2: 提交** — `git add ABank && git commit -m "feat: 新增我的持仓并联动资产负债"`

---

### Task 8: 入口开放与接线

**Files:**
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（`wealthProduct` 改 `.available(.wealthProducts)`；`wealthStage` 改为 `"M7 扩展（存款/基金）"`）
- Modify: `scripts/check_feature_catalog.swift`
- Modify: `ABank/Features/Finance/Models/WealthModels.swift`、`ABank/Data/MockDataProvider.swift`、`ABank/Features/Finance/FinanceViewController.swift`
- Test: `scripts/check_wealth.swift`（目录一致性断言）

**Interfaces:**
- `WealthProductTab` 与 `WealthSteadyProduct` 各增加 `var productID: String? = nil`；`getWealthPageData()` 填充：日日悦享→`w.tiantianli2`、低波稳健→`w.piaoxi`、业绩优选→`w.lingdong180`；稳健增长两项→`w.piaoxi`、`w.lingdong180`。
- `WealthViewController`：`featuredProduct.onBuyTapped`（当前页签对应 `productID`）与 `steadyGrowth.onProductTapped(index)` → `router.open(.wealthProductDetail(productID:), from: self)`（无 `productID` 时保持 toast）；`featuredProduct.onTabSelected` 记录当前页签索引（保留原 toast 可去除）；`loginCard.onLoginTapped` → `router.open(.wealthHoldings, from: self)`；其余 toast 不动。

- [ ] **Step 1: 写失败检查。** `check_feature_catalog.swift`：`.wealthProduct` 的 `availability == .available(.wealthProducts)`；`.deposit`、`.fund` 仍为 `.planned`，`plannedStageText == "计划阶段：M7 扩展（存款/基金）"`；可用数 `29 → 30`；其它计划中样例不变。`check_wealth.swift` 追加 `catalogLinks()`：`WealthProductCatalog.products` 中存在 Tab 映射使用的三个 ID（`w.tiantianli2`、`w.piaoxi`、`w.lingdong180`）。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`。
- [ ] **Step 3: 实现上述改动。**
- [ ] **Step 4: 运行检查与构建** — `zsh scripts/check_banking_data.sh` 全部通过；构建 `BUILD SUCCEEDED`；`git diff --check` 无输出。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 开放理财产品入口并接入财富页"`

---

### Task 9: 模拟器验收

**Files:**
- Create（被 Git 忽略）：`artifacts/abc-resources/verification/m7-*.png`

- [ ] **Step 1: 构建并安装**到 iPhone 16 Pro 模拟器（`mcp__Claude_Code_iOS_Simulator__control`：`attach` → 构建 → `launch`）；截图用 `xcrun simctl io <udid> screenshot <path>`，点击后等待约 2 秒再截图。
- [ ] **Step 2: 逐项验收并截图**（`m7-<name>.png`）：
  1. 财富 Tab：点击“理财产品”宫格、“立即购买”、稳健增长产品、“请登录查看持仓”进入对应页面；“存款”“基金”仍为即将上线。
  2. 产品列表：三组筛选叠加（分类/风险/期限）、空态；详情页字段。
  3. 未测评点“立即购买”被拦截并引导；完成测评（得到等级与有效期）；`R3` 产品在低等级下被拦截（用较保守答案测得低等级验证，再重测）。
  4. 购买页：金额校验提示（低于起购、超过余额）；确认后购买成功、订单详情与成功横幅；账户余额扣减（我的账户/资产负债页）、总资产不变、资产负债页出现“理财”类别并可点击进入。
  5. 我的持仓：汇总、持有中列表；赎回受限提示（未满期）；按模拟器日期无法跨日时，仅验证受限提示，赎回成功路径由脚本覆盖并在交接中如实记录。
  6. 重启 App 后订单、测评、余额保持；“本月收支”不含理财流水。
- [ ] **Step 3: 记录问题**：发现的 Bug 先修再复验（每个修复单独提交，`fix: …`）；无法验证的（320pt、小屏、大字体、跨日赎回成功界面）如实记入交接。
- [ ] **Step 4: 清理**：用 `simctl` 从 App 容器偏好中删除 `abank.riskAssessment.v1` 与 `abank.financeLedger.record.v8`（恢复种子账本）。

---

### Task 10: 全分支审查与文档

**Files:**
- Modify: `docs/development-plan.md`（M7 行改“已完成（待合并）”、新增“M7 实施记录”、“下一会话：M8 充值缴费”）
- Create: `docs/continuity/tasks/m7-wealth-products.md`
- Modify: `docs/continuity/CURRENT.md`（索引加 m7）

- [ ] **Step 1: 全分支审查**：对 `main..HEAD` 做一次全分支代码审查（Critical / Important 必须修复并复验，Minor 记入交接）。
- [ ] **Step 2: 最终验证**：`zsh scripts/check_banking_data.sh`、正常构建、`git diff --check` 全部通过。
- [ ] **Step 3: 写文档**：开发计划实施记录按 M6 格式（分支与起点、数据与规则、页面、入口、验证、模拟器、审查、未验证）；任务记录含目标与验收、已确认决策、提交列表、裁定、延后 Minor、未验证、下一步（存款/基金扩展留后）；不写 token/Cookie/个人敏感数据。
- [ ] **Step 4: 提交** — `git add docs && git commit -m "docs: 记录 M7 财富产品实施与验证结果"`；不推送、不合并。
