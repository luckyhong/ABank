# M8 充值缴费（手机充值 + 生活缴费）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本地模拟的手机充值与水/电/燃气缴费：输入、确认、结果、记录与订单，支持话费券抵扣，付款账户、流水、订单与券状态一致，并把功能目录“手机充值”“生活缴费”改为可用。

**Architecture:** Foundation 纯模型层（面额、预置户号、手机号规则、账单金额与账期、券抵扣均为纯函数，时间来自注入的 `BankingDateContext`）+ 缴费订单并入账本根快照（`FinanceLedgerRecord.paymentOrders`，扣款、流水、订单在 `FinanceLedgerStore` 内一次 `persist` 原子写入）+ 话费券先 `useCoupon` 再写账本、写入失败则 `releaseCoupon` 补偿。UIKit 页面经 `AppRoute`/`AppRouter` 进入；“我的订单”改为统一展示兑换订单与缴费订单。

**Tech Stack:** Swift 5、UIKit、SnapKit、UserDefaults；检查脚本 `xcrun swiftc -default-isolation MainActor`。

**Spec:** `docs/superpowers/specs/2026-11-07-m8-payment-recharge-design.md`

## Global Constraints

- iOS 15.6+；不新增依赖；不发网络请求；无真实资金；不新增图片资源（SF Symbols + 现有图标）。
- 所有日期按 `BankingDateContext`（Asia/Shanghai）计算；不得用 `Date()` / `Calendar.current` 直接取时间；稳定哈希只用 `BranchSchedule.stableHash`，不用 `hashValue`。
- 被检查脚本编译的纯模型类型标 `nonisolated`（脚本带 `-default-isolation MainActor`）；金额统一 `Int64` 分，复用 `TransferMoney`（`parse` / `cents(from:)` / `amount(_:)`）；界面金额文案用 `wealthMoneyText(_:)`（`WealthViews.swift`，千分位两位小数）。
- 账本存储键保持 `abank.financeLedger.record.v8`；`paymentOrders` 用 `decodeIfPresent`，旧数据解码为空；损坏账本字节不被覆盖，写入失败内存不变且不发通知；权益存储键 `abank.benefits.v1` 不变。
- 流水：`direction: .expense`、`includeInFlow: true`、渠道“本机模拟”、`categoryId` 为 `mobile_recharge` / `life_payment`（新增到 `IncomeExpenseFilterCatalog.expenseGroup`，标题“手机充值”“生活缴费”）。
- 限额：M4 转账限额与“小额免密”设置不套用；手机充值面额只能取固定档位（最高 200 元）。
- 文案中文；页面用 `abank*` 颜色/字体与 `Spacing`；新页面实现 `RouteHosting`；复用 `BenefitsRow`、`BranchCardView`、`BranchStatusTagView`、`BranchChipBar`、`benefitsActionButton`、`branchCaption`、`TransferFlowViewController`、`TransferInfoRow`、`TransferInputRow`。
- 工程使用文件系统同步分组，新文件放进 `ABank/` 即可。
- 提交：中文 Conventional Commits，只提交本任务文件，不推送、不合并。
- 构建命令：`xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build`
- 检查命令：`zsh scripts/check_banking_data.sh`（新增 `payment` → `scripts/check_payment.swift`，末尾输出 `Payment checks passed`）。

## Review Focus

1. **幂等与券**：同一 `requestID` 重复提交（含新建 Store 实例后、以及券此时已是“已使用”）只返回旧订单，不重复扣款、不再动券（Task 3 `rechargeIdempotency`）。
2. **券补偿**：账本写入失败时订单、流水、余额不变，话费券回到“待使用”，不发账本通知；余额不足、号码非法等校验失败发生在 `useCoupon` 之前，券不被消耗（Task 3 `couponCompensation`）。
3. **金额边界**：余额恰等于实付成功、少 1 分被拒；券面值 < 面额才可用（10 元面额不能用 10 元券，5 元券可用且实付 5 元）；账单金额最大 26,000 分不超出区间（Task 1 `couponRules`/`billAmounts`、Task 3 `rechargeRules`/`utilityRules`）。
4. **账期日界**：上海月末 23:59（UTC 15:59）仍是本月账期，次日 00:00 为下月新账单，上月已缴不影响下月；同账期重复缴费被拒（Task 1 `billPeriods`、Task 3 `utilityRules`）。
5. **输入与数据完整性**：手机号带空格/连字符可规范化；10/12 位、首位非 1、第二位 0–2、含字母被拒；损坏账本字节不被覆盖；旧账本缺 `paymentOrders` 解码为空；订单列表混排时间相同时顺序确定（Task 1 `phoneRules`、Task 2 `legacyLedgerDecodes`、Task 3 `corruptLedgerKeepsBytes`、Task 6 `orderListMerge`）。

---

### Task 1: 缴费模型、目录与规则

**Files:**
- Create: `ABank/Features/Payment/Models/PaymentModels.swift`
- Create: `ABank/Features/Payment/Models/PaymentCatalog.swift`
- Create: `ABank/Features/Payment/Models/PaymentRules.swift`
- Create: `scripts/check_payment.swift`
- Modify: `scripts/check_banking_data.sh`（sources 加三个文件；循环加 `payment` → `scripts/check_payment.swift`）

**Interfaces:**
- Produces（全部 `nonisolated`）：
  - `enum PaymentKind: String, Codable, CaseIterable { case mobile, water, electric, gas }`：`title`（手机充值/水费/电费/燃气费）、`isUtility`、`iconKey`（`iphone`/`drop.fill`/`bolt.fill`/`flame.fill`）、`categoryId`（`mobile_recharge` 或 `life_payment`）、`transactionType`（手机充值/生活缴费）
  - `enum PhoneOperator: String { case mobile, unicom, telecom, other }`：`title`（中国移动/中国联通/中国电信/其他运营商）
  - `struct BillAccount: Equatable { let id: String; let kind: PaymentKind; let name, accountNo, address, provider: String }`
  - `struct UtilityBill: Equatable { let account: BillAccount; let period: String; let dueDate: String; let amountInCents: Int64; let isPaid: Bool }`
  - `struct PaymentOrder: Codable, Equatable { let id, orderNo, requestID: String; let kind: PaymentKind; let targetID, targetTitle: String; let period: String?; let faceInCents: Int64; let couponID: String?; let couponDiscountInCents: Int64; let paidInCents: Int64; let accountID, createdAt, transactionID: String }`（`createdAt` 为 `yyyy-MM-dd HH:mm:ss`，上海）
  - `enum PaymentError: LocalizedError, Equatable { case invalidRequest, invalidPhone, invalidDenomination, billNotFound, alreadyPaid, couponUnavailable, insufficientBalance, orderNotFound, corruptLedger, persistence }`，`errorDescription`：请求无效 / 请输入正确的 11 位手机号 / 请选择有效面额 / 账单不存在 / 本期账单已缴清 / 话费券不可用 / 账户可用余额不足 / 订单不存在 / 本地账本无法读取，请先检查账本数据 / 本地保存失败，本次未成交，请重试
  - `enum PaymentCatalog { static let denominationsInCents: [Int64]（[1000, 2000, 3000, 5000, 10000, 20000]）; static let billAccounts: [BillAccount]（spec §3.1 表的 6 个，ID `bill.water.home/parents`、`bill.electric.home/office`、`bill.gas.home/parents`）; static func billAccount(id:) -> BillAccount?; static func billAccounts(of kind: PaymentKind) -> [BillAccount]; static func phoneOperator(prefix: String) -> PhoneOperator }`（号段表按 spec §3.1；`prefix` 为前 3 位）
  - `enum PaymentRules`：
    - `static func normalizedPhone(_ text: String) -> String`（仅去掉空格与连字符）、`static func isValidPhone(_ normalized: String) -> Bool`（11 位纯数字、首位 1、第二位 3–9）、`static func maskedPhone(_ normalized: String) -> String`（`152****8684`）、`static func phoneOperator(of normalized: String) -> PhoneOperator`
    - `static func currentPeriod(now: Date, dates:) -> String`（`yyyy-MM`）、`static func dueDate(period: String, dates:) -> String`（该月最后一天 `yyyy-MM-dd`）
    - `static func billAmountInCents(for account: BillAccount, period: String) -> Int64`（`base + stableHash(account.id, period) % span`：水 3,500 + [0,6,000)、电 8,000 + [0,18,000)、燃气 4,000 + [0,14,000)）
    - `static func bill(for account: BillAccount, orders: [PaymentOrder], now: Date, dates:) -> UtilityBill`（`isPaid` = 存在同 `targetID` 且 `period` 等于当前账期的订单）
    - `static func phoneCouponFaceInCents(templateID: String) -> Int64?`（`phone5` → 500，`phone10` → 1000，其余 nil）、`static func usableCouponFaceInCents(templateID: String, faceInCents amount: Int64) -> Int64?`（面值 < 面额才返回面值）
    - `static func orderNo(id: String, createdAt: Date, dates:) -> String`（`M8` + `yyyyMMdd` + 8 位稳定哈希数字，补零）、`static func createdDate(of order: PaymentOrder, dates:) -> Date?`
    - `static func targetTitle(phone normalized: String) -> String`（`手机号 152****8684`）、`static func targetTitle(for account: BillAccount) -> String`（`水费 · 家庭住宅`）

- [ ] **Step 1: 写失败检查** `scripts/check_payment.swift`，`@main struct PaymentChecks`，固定时钟工具 `at(_:)`/`clock(_:)`/`clock(utc:)`（同 `check_wealth.swift`）。用例：
  - `catalog()`：6 个户号、ID 唯一；`billAccounts(of: .water).count == 2`；`denominationsInCents == [1000,2000,3000,5000,10000,20000]`；`PaymentKind.mobile.categoryId == "mobile_recharge"`、`.gas.categoryId == "life_payment"`、`.water.title == "水费"`、`.mobile.isUtility == false`。
  - `phoneRules()`：Review Focus 5——`normalizedPhone("152 8888-8684") == "15288888684"`；合法 `15288888684`、`13012345678`、`19912345678`；非法：10 位、12 位、`25288888684`（首位 2）、`12288888684`（第二位 2）、`1528888868a`、空串；`maskedPhone("15288888684") == "152****8684"`；运营商 `152`→移动、`186`→联通、`189`→电信、`170`→其他运营商、`199`→电信；`targetTitle(phone:) == "手机号 152****8684"`、`targetTitle(for: billAccount("bill.water.home")) == "水费 · 家庭住宅"`。
  - `couponRules()`：Review Focus 3——`phoneCouponFaceInCents(templateID: "phone10") == 1000`、`"phone5" == 500`、`"coffee10" == nil`；`usableCouponFaceInCents("phone10", faceInCents: 1000) == nil`、`("phone10", 2000) == 1000`、`("phone5", 1000) == 500`、`("phone5", 500) == nil`、`("coffee10", 5000) == nil`。
  - `billAmounts()`：Review Focus 3——对 6 个户号 × 连续 24 个账期，金额落在各类型区间内（水 [3500, 9500)、电 [8000, 26000)、燃气 [4000, 18000)）；同户号同账期两次调用相等；最大值 < 26_000；不同账期至少出现两个不同金额（`bill.electric.home`）。
  - `billPeriods()`：Review Focus 4——上海 `2026-11-30 23:59`（UTC `2026-11-30T15:59:00Z`）账期 `2026-11`，UTC `2026-11-30T16:00:00Z`（上海 12-01 00:00）账期 `2026-12`；`dueDate(period: "2026-11") == "2026-11-30"`、`"2028-02" == "2028-02-29"`、`"2026-02" == "2026-02-28"`；`bill(for:orders:now:)`：订单账期 `2026-11` 时 11 月 `isPaid == true`、12 月 `false`；订单 `targetID` 不同户号不影响；`orderNo` 以 `M820261106` 开头、总长 18、同输入稳定。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误（类型未定义）。
- [ ] **Step 3: 实现三个模型文件**；户号数据按 spec §3.1 表（名称、户号、供应商、地址各写一条合理的模拟中文地址，不含真实地址）。账期到期日用 `dates.calendar` 的月天数。
- [ ] **Step 4: 运行通过** — `zsh scripts/check_banking_data.sh`，预期末尾 `Payment checks passed`，其余检查照常通过。
- [ ] **Step 5: 提交** — `git add ABank/Features/Payment/Models scripts/check_payment.swift scripts/check_banking_data.sh && git commit -m "feat: 新增充值缴费目录与规则"`

---

### Task 2: 账本数据层（订单字段、类别、释放话费券）

**Files:**
- Modify: `ABank/Features/Mine/Models/FinanceLedgerModels.swift`（`FinanceLedgerRecord` 加 `paymentOrders`；`expenseGroup` 加两个类别）
- Modify: `ABank/Features/Benefits/BenefitsStore.swift`（`releaseCoupon`）
- Modify: `scripts/check_payment.swift`

**Interfaces:**
- Consumes: Task 1 `PaymentOrder`。
- Produces:
  - `FinanceLedgerRecord.paymentOrders: [PaymentOrder] = []`（`CodingKeys` 加入，`decodeIfPresent`；`init(...)` 末尾加默认参数 `paymentOrders: [PaymentOrder] = []`）
  - `IncomeExpenseFilterCatalog.expenseGroup` 在“其他支出”之前新增 `.init(id: "mobile_recharge", title: "手机充值", isAll: false)`、`.init(id: "life_payment", title: "生活缴费", isAll: false)`
  - `BenefitsStore.releaseCoupon(id: String) throws`：券不存在 → `BenefitsError.unknownItem`；券 `usedAt == nil` 或 `voidedAt != nil` → `BenefitsError.notUsable`；否则清除 `usedAt` 并 `commit`（与 `useCoupon` 对称）。

- [ ] **Step 1: 写失败检查**（追加到 `check_payment.swift`，参照 `check_wealth.swift` 的 `withSuite`/`TestClock`/`ledgerStore` 夹具）：
  - `legacyLedgerDecodes()`：夹具保存后去掉 JSON 的 `paymentOrders` 键写回，`load().paymentOrders.isEmpty`；带订单的记录编码再解码相等；defaults 字节未被改写。
  - `categories()`：`IncomeExpenseFilterCatalog.title(for: "mobile_recharge") == "手机充值"`、`"life_payment" == "生活缴费"`；两个 ID 属于 `expenseCategoryIds` 且 `allCategoryIds`；`selectableOptions(for: .expense)` 含二者、`.income` 不含。
  - `releaseCoupon()`：用 `BenefitsStore(defaults:dates:)` 经 `redeem(goodsID: "g.phone5")` 取得待使用券（小豆 260 足够）；`useCoupon` 后状态 `.used`，`releaseCoupon` 后回到 `.unused` 且发通知一次；对待使用券再 `releaseCoupon` → `notUsable`；未知 ID → `unknownItem`；已作废券（`cancelOrder` 后）`releaseCoupon` → `notUsable`；`dataWriter` 抛错 → `saveFailed` 且状态不变。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误。
- [ ] **Step 3: 实现。**
- [ ] **Step 4: 运行通过** — `zsh scripts/check_banking_data.sh` 全绿。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 账本新增缴费订单字段并支持释放话费券"`

---

### Task 3: 手机充值与生活缴费提交

**Files:**
- Modify: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift`（新增 `benefitsProvider`；`strictRecord` 复用需要时改内部可见）
- Create: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Payment.swift`
- Modify: `scripts/check_payment.swift`、`scripts/check_banking_data.sh`（sources 加 `FinanceLedgerStore+Payment.swift`；其余已在）

**Interfaces:**
- Consumes: Task 1/2。
- Produces:
  - `FinanceLedgerStore.init(…, riskStateProvider:…, benefitsProvider: @escaping @MainActor () -> BenefitsStore = { BenefitsStore.shared }, dataWriter:…)`（参数位于 `riskStateProvider` 之后；既有调用点不受影响）；`let benefitsProvider`
  - 扩展（`@MainActor`）：
    - `func paymentOrders() -> [PaymentOrder]`（`createdAt` 倒序，同刻后建在前）、`func paymentOrder(id: String) -> PaymentOrder?`
    - `func currentBill(for account: BillAccount) -> UtilityBill`
    - `func usableCoupons(forFaceInCents amount: Int64) -> [Coupon]`（`benefitsProvider().coupons` 中状态待使用、模板为话费券且面值 < 面额的券，保持原顺序）
    - `func validateMobileRecharge(phone: String, faceInCents: Int64, couponID: String?) throws -> Int64`（返回实付分；不写入、不动券）
    - `@discardableResult func submitMobileRecharge(phone: String, faceInCents: Int64, couponID: String?, requestID: String) throws -> PaymentOrder`
    - `@discardableResult func submitUtilityPayment(billAccountID: String, requestID: String) throws -> PaymentOrder`
  - 充值顺序（均抛 `PaymentError`）：`requestID` 为空或超 100 字符 → `invalidRequest`；同 `requestID` 已有订单 → 直接返回（先于任何校验与券操作）；严格读取账本（损坏 → `corruptLedger`）；规范化手机号非法 → `invalidPhone`；面额不在档位 → `invalidDenomination`；选券：券不存在/非待使用/非话费券/面值 ≥ 面额 → `couponUnavailable`；付款账户固定为 `FinanceLedgerRecord.defaultAccountId`（不存在或币种非人民币 → `invalidRequest`），实付 ≤ 余额（`TransferMoney.cents(from:)`）否则 `insufficientBalance`；通过后（选券时）`benefitsProvider().useCoupon(id:)`（失败 → `couponUnavailable`）→ 构造订单与流水（`id: "payment_<订单ID>"`，`title: "手机充值-<掩码号>"`，`transactionType`/`categoryId`/`iconKey` 取 `PaymentKind.mobile`，`counterpartyName: "模拟通信服务商"`，`summary: "模拟手机充值"`，`cardNumber: "****" + 尾号`，`includeInFlow: true`，渠道“本机模拟”）→ `recalculate` → 更新 `dataTimestamp` → `persist`；`persist` 失败 → 若用了券则 `releaseCoupon`（忽略其错误）→ 抛 `persistence`。订单 `faceInCents` = 面额，`couponDiscountInCents` = 券面值（无券 0），`paidInCents` = 面额 − 券面值，`period` nil，`targetID` = 规范化手机号，`orderNo` 用 `PaymentRules.orderNo`。
  - 缴费顺序：`requestID` 校验 → 同请求直接返回 → 严格读取 → 户号不存在 → `billNotFound` → 本期已缴 → `alreadyPaid` → 付款账户与余额（`insufficientBalance`）→ 订单与流水（`title: "<类型>缴费-<户号名称>"`，`counterpartyName: account.provider`，`summary: "模拟生活缴费"`，`period` = 当前账期，`faceInCents == paidInCents` = 账单额，`couponID` nil）→ 一次 `persist`（失败 → `persistence`）。

- [ ] **Step 1: 写失败检查**（追加到 `check_payment.swift`；账本夹具同 Task 2，余额默认 1,499.66 元；`benefitsProvider` 指向测试用 `BenefitsStore`）：
  - `rechargeRules()`：充值 `15288888684` 面额 2000、无券：订单 `paidInCents == 2000`、`period == nil`、`targetTitle == "手机号 152****8684"`、流水 `payment_…` 支出 20.00 且 `includeInFlow == true`、`categoryId == "mobile_recharge"`、余额 1,479.66、`totalAssets()` 减少 20.00、`mineMonthlyFlow().expense` 增加 20.00、`paymentOrders().count == 1`、`orderNo` 以 `M8` 开头；带空格号码 `152 8888 8684` 成功且 `targetID` 为规范化号；非法号 → `invalidPhone`；面额 1500 → `invalidDenomination`；失败均不改订单数与余额。
  - `rechargeCoupons()`：面额 1000 + `phone5` 券：`paidInCents == 500`、`couponDiscountInCents == 500`、券状态 `.used`；面额 1000 + `phone10` 券 → `couponUnavailable`（券仍 `.unused`）；面额 2000 + `phone10` 券 → 实付 1000；已使用/已作废/非话费券（如 `coffee10` 经 `claim(benefitID: "coffeeMonthly")` 获得）→ `couponUnavailable`；未知券 ID → `couponUnavailable`；`usableCoupons(forFaceInCents: 1000)` 仅含 `phone5` 待使用券。
  - `rechargeAmountRules()`：Review Focus 3——余额 149_966 分（`balance: 1499.66`）时：面额 20000 成功三次后余额 99_966 起算累计；单独夹具：余额 `10.00` 面额 1000 成功且余额 0、再充 1000 → `insufficientBalance`；余额 `9.99` 面额 1000 → `insufficientBalance`；余额 `5.00` + `phone5` 券面额 1000（实付 500）成功且余额 0。
  - `rechargeIdempotency()`：Review Focus 1——同 `requestID` 连续两次（第二次金额/号码不同也一样）返回相等订单、仅 1 条订单与 1 条流水、余额只扣一次；带券时第二次提交时券已 `.used` 仍返回旧订单且券未被二次动用；新建 `FinanceLedgerStore`（同 defaults、同 BenefitsStore）再提交同 `requestID` 仍相等；`requestID` 为空和 101 字符 → `invalidRequest`。
  - `couponCompensation()`：Review Focus 2——`dataWriter` 先成功完成一笔无券充值，再置失败：带券充值抛 `persistence`，订单、流水、余额不变，券回到 `.unused`，`.financeLedgerDidChange` 计数不变，恢复写入后同一券、同一 `requestID` 可成功；余额不足、号码非法、面额非法时券保持 `.unused` 且无任何写入（校验先于 `useCoupon`）。
  - `utilityRules()`：Review Focus 4——时钟 `2026-11-06 10:00`：`currentBill(for: waterHome)` 金额等于 `billAmountInCents`、`isPaid == false`；缴费成功：订单 `period == "2026-11"`、`paidInCents == faceInCents == 账单额`、流水 `categoryId == "life_payment"`、标题 `水费缴费-家庭住宅`、余额扣减、`currentBill.isPaid == true`；再缴同户号 → `alreadyPaid`；另一户号（`bill.water.parents`）不受影响；未知户号 → `billNotFound`；时钟拨到 `2026-11-30 23:59` 仍 `alreadyPaid`、拨到 UTC `2026-11-30T16:00:00Z`（上海 12-01）`isPaid == false` 并可再缴，新订单 `period == "2026-12"`；余额恰等于账单额成功且为 0，余额少 1 分 → `insufficientBalance`；同请求幂等同充值。
  - `corruptLedgerKeepsBytes()`：defaults 写入非法 JSON → 充值/缴费抛 `corruptLedger`，defaults 字节不变，券未被动用。
  - `writeFailureIsAtomic()`：缴费写入失败抛 `persistence`，订单、流水、余额与调用前一致，通知计数不变；恢复写入后成功。
  - 既有检查必须保持通过。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误。
- [ ] **Step 3: 实现。** 订单 ID 用 `UUID().uuidString`；时间格式沿用转账（`dates.string(from:format:)`）；`FinanceLedgerStore` 的 `loadForTransfer()` 读取失败映射 `corruptLedger`。
- [ ] **Step 4: 运行通过** — `zsh scripts/check_banking_data.sh` 全绿；构建命令 `BUILD SUCCEEDED`。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 支持手机充值与生活缴费提交"`

---

### Task 4: 路由骨架、页面基类、手机充值与订单详情

**Files:**
- Modify: `ABank/Core/Routing/AppRoute.swift`、`ABank/Core/Routing/AppRouter.swift`
- Create: `ABank/Features/Payment/PaymentFlowViewController.swift`
- Create: `ABank/Features/Payment/Views/PaymentViews.swift`
- Create: `ABank/Features/Payment/MobileRechargeViewController.swift`
- Create: `ABank/Features/Payment/MobileRechargeConfirmViewController.swift`
- Create: `ABank/Features/Payment/PaymentOrderDetailViewController.swift`

**Interfaces:**
- Consumes: Task 1–3。
- Produces:
  - `AppRoute` 新增：`mobileRecharge`、`mobileRechargeConfirm(phone: String, faceInCents: Int64)`、`lifePayment`、`utilityBill(billAccountID: String)`、`paymentOrderDetail(orderID: String, justPaid: Bool)`。`AppRouter.makeViewController`：前三个页面（`mobileRecharge`、`mobileRechargeConfirm`、`paymentOrderDetail`）映射真实页面；`lifePayment`、`utilityBill` 暂映射 `ComingSoonViewController(featureID: .lifePayment)` 并加注释 `// 由 Task 5 替换`。
  - `class PaymentFlowViewController: TransferFlowViewController`：`let ledger: FinanceLedgerStore`、`let benefits: BenefitsStore`、`let dates: BankingDateContext`；`init(ledger: = .shared, benefits: = .shared, dates: = .system)`（`hidesBottomBarWhenPushed = true`）；监听 `BenefitsStore.didChangeNotification` 调 `refreshBankingData()`（账本通知由基类处理）；提供 `clearContent()`、`addCard(_:)`、`addSectionTitle(_:)`、`addEmptyState(_:id:)`、`confirm(_:confirmTitle:action:)`、`showError(_:)`（读 `error.localizedDescription`）、`dateText(_:format:)`，写法同 `WealthFlowViewController`。
  - `PaymentViews.swift`：`func paymentOrderRow(_ order: PaymentOrder, onTap: @escaping () -> Void) -> BenefitsRow`（标题 `targetTitle`，副标题“实付 x 元 · 时间”，右侧 `BranchStatusTagView(text: "已完成", active: false)`，id `orders.payment.<订单ID>`，带箭头）；`func paymentTimeText(_ order: PaymentOrder) -> String`（`createdAt` 去掉秒）。
- **手机充值页**（`hostedRoute == .mobileRecharge`，标题“手机充值”）：手机号 `TransferInputRow`（id `recharge.phone`，数字键盘，预填 `CustomerInfoStore.shared.load().mobile`，输入变化时规范化校验并更新运营商文案 id `recharge.carrier`，非法时显示错误色提示）；面额网格 6 项（id `recharge.face.<元>`，选中高亮，默认选中 50 元）；“下一步”（id `recharge.next`，号码非法禁用）→ `router.open(.mobileRechargeConfirm(phone: 规范化号, faceInCents:), from: self)`；右上“充值记录”（id `recharge.records`）→ `.orders`；底部说明“本机模拟 · 不发生真实资金交易”。
- **充值确认页**（`hostedRoute == .mobileRechargeConfirm(phone:faceInCents:)`，标题“确认充值”）：`TransferInfoRow`：充值号码（掩码）、运营商、充值面额、付款账户（借记卡 尾号xxxx）、可用余额；话费券行（id `recharge.coupon`，`BenefitsRow`）：无可用券显示“暂无可用话费券”不可点，有券显示“已选 <券名> -x 元”或“可用 N 张”，点击弹出 `UIAlertController(.actionSheet)` 列出 `ledger.usableCoupons(forFaceInCents:)` 与“不使用”，选择后刷新；实付金额大字（id `recharge.pay`）；“确认充值”（id `recharge.submit`）→ `confirm("确认充值 x 元？")` → `ledger.submitMobileRecharge(phone:faceInCents:couponID:requestID:)`，`requestID` 页面创建时生成、成功后重新生成；成功 `router.open(.paymentOrderDetail(orderID:justPaid: true), from: self)`；失败 `showError`；所选券失效（被其他入口使用/过期）时刷新后自动取消选择。
- **订单详情页**（`hostedRoute == .paymentOrderDetail(orderID:justPaid:)`，标题“订单详情”）：`justPaid` 时成功横幅“✓ 充值成功（本机模拟）”或“✓ 缴费成功（本机模拟）”（id `payment.success`）；类型与对象标题卡 + “已完成”标签；`TransferInfoRow`：类型、对象、账期（缴费才有）、面额/账单额、话费券抵扣（有则显示 -x 元）、实付金额、付款账户、订单号、创建时间、流水号；底部说明“模拟交易 · 不可撤销、无退款”；订单不存在显示“订单不存在”（id `payment.missing`）。
- [ ] **Step 1: 实现**，先加路由与 Router 分支并确认可构建，再做页面。
- [ ] **Step 2: 构建与检查** — 构建命令 `BUILD SUCCEEDED`；`zsh scripts/check_banking_data.sh` 全绿。
- [ ] **Step 3: 提交** — `git add ABank && git commit -m "feat: 新增手机充值页面与缴费订单详情"`

---

### Task 5: 生活缴费列表与账单页

**Files:**
- Create: `ABank/Features/Payment/LifePaymentViewController.swift`
- Create: `ABank/Features/Payment/UtilityBillViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（替换 `.lifePayment`、`.utilityBill`，之后不再有临时映射）

**Interfaces:**
- Produces:
  - `LifePaymentViewController: PaymentFlowViewController, RouteHosting`（`hostedRoute == .lifePayment`，标题“生活缴费”）：类型 `BranchChipBar`（水费/电费/燃气费，id 前缀 `payment.kind`，选中项页面存活期内保持）；下方该类型的户号行 `BenefitsRow`（id `payment.row.<户号ID>`）：标题名称，副标题“户号 <户号> · 本期 <金额> 元”，右侧标签“待缴”（active）或“已缴清”；点击 → `.utilityBill(billAccountID:)`；右上“缴费记录”（id `payment.records`）→ `.orders`；说明“本机模拟 · 账单为演示数据”。
  - `UtilityBillViewController(billAccountID:): PaymentFlowViewController, RouteHosting`（`hostedRoute == .utilityBill(billAccountID:)`，标题“账单详情”）：户号不存在显示“账单不存在”（id `bill.missing`）；卡片：类型、名称、供应商；`TransferInfoRow`：户号、地址、账期、到期日、应缴金额（大字 id `bill.amount`）、状态（待缴/本期已缴清）、付款账户、可用余额；“立即缴费”（id `bill.pay`，已缴清时禁用并显示“本期已缴清”）→ `confirm("确认缴纳 x 元？")` → `ledger.submitUtilityPayment(billAccountID:requestID:)`，`requestID` 页面创建时生成、成功后重新生成；成功 `router.open(.paymentOrderDetail(orderID:justPaid: true), from: self)`；失败 `showError`；回前台/跨日/账本变化时刷新账单与状态。
- [ ] **Step 1: 实现并构建** — 构建命令 `BUILD SUCCEEDED`；`grep -n "ComingSoonViewController" ABank/Core/Routing/AppRouter.swift` 仅剩 `.comingSoon(id)` 一处；`zsh scripts/check_banking_data.sh` 全绿。
- [ ] **Step 2: 提交** — `git add ABank && git commit -m "feat: 新增生活缴费列表与账单页面"`

---

### Task 6: 我的订单统一展示

**Files:**
- Create: `ABank/Features/Benefits/Models/OrderListItem.swift`
- Modify: `ABank/Features/Benefits/OrdersViewController.swift`
- Modify: `scripts/check_payment.swift`、`scripts/check_banking_data.sh`（sources 加 `OrderListItem.swift`）

**Interfaces:**
- Consumes: Task 1/3、`RewardOrder`、`OrderStatus`。
- Produces（`nonisolated`，Foundation-only）：
  - `enum OrderListItem: Equatable { case reward(RewardOrder), payment(PaymentOrder) }`：`id`、`func createdAt(dates:) -> Date`（缴费订单经 `PaymentRules.createdDate`，解析失败用 `Date.distantPast`）
  - `enum OrderListFilter: Int, CaseIterable { case all, pendingUse, used, expired, cancelled, payments }`：`title`（全部/待使用/已使用/已失效/已取消/充值缴费）
  - `enum OrderListBuilder { static func items(filter: OrderListFilter, reward: [RewardOrder], payment: [PaymentOrder], status: (RewardOrder) -> OrderStatus, dates: BankingDateContext) -> [OrderListItem] }`：`.all` = 全部兑换订单 + 全部缴费订单；`.pendingUse/.used/.expired/.cancelled` = 仅状态匹配的兑换订单；`.payments` = 仅缴费订单；结果按创建时间倒序，时间相同时缴费订单在前、其余保持输入顺序。
  - `OrdersViewController`：新增 `ledger: FinanceLedgerStore`（`init(ledger: = .shared, benefits: = .shared, dates: = .system)`），筛选条改用 `OrderListFilter.allCases`；缴费订单行用 `paymentOrderRow` → `.paymentOrderDetail(orderID:justPaid: false)`；兑换订单行保持原样；空态“暂无订单”不变；账本变更时刷新（基类 `BankingDataViewController` 已监听账本通知）。
- [ ] **Step 1: 写失败检查**（追加到 `check_payment.swift`）`orderListMerge()`：Review Focus 5——构造 2 个 `RewardOrder`（`createdAt` 2026-11-05 10:00 / 2026-11-06 09:00，状态由闭包按 ID 返回 `.pendingUse` / `.used`）与 2 个 `PaymentOrder`（`createdAt` `2026-11-06 09:00:00` / `2026-11-04 12:00:00`）：`.all` 顺序为 [缴费 11-06 09:00、兑换 11-06 09:00（时间相同，缴费在前）、兑换 11-05、缴费 11-04]；`.payments` 仅 2 个缴费订单且倒序；`.pendingUse` 仅含 `.pendingUse` 的兑换订单、`.used` 同理、`.expired/.cancelled` 为空；空输入 `.all` 为空；缴费订单 `createdAt` 非法字符串排在末尾不崩溃；`OrderListFilter.allCases.map(\.title) == ["全部","待使用","已使用","已失效","已取消","充值缴费"]`。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`，预期编译错误。
- [ ] **Step 3: 实现模型与列表页。**
- [ ] **Step 4: 运行通过并构建** — 检查全绿；构建命令 `BUILD SUCCEEDED`。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 我的订单统一展示充值缴费订单"`

---

### Task 7: 入口开放与接线

**Files:**
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（`lifePayment` → `.available(.lifePayment)`，`mobileRecharge` → `.available(.mobileRecharge)`；删除不再使用的 `paymentStage`）
- Modify: `scripts/check_feature_catalog.swift`
- Modify: `ABank/Features/Life/Models/*`（`LifeBannerItem` 加 `var featureID: FeatureID? = nil`）、`ABank/Data/MockDataProvider.swift`（“生活缴费”横幅 `featureID: .lifePayment`）、`ABank/Features/Life/Views/LifeBannerView.swift`（`var onItemTapped: ((Int) -> Void)?`，实现 `collectionView(_:didSelectItemAt:)`）、`ABank/Features/Life/LifeViewController.swift`（`bannerView.onItemTapped` → 有 `featureID` 时 `router.open(feature:, from:)`，否则保持原行为不响应）

**Interfaces:** 无新增类型；宫格“生活缴费”“手机充值”与首页入口经 `FeatureCatalog` 路由自动生效，无需单独接线。

- [ ] **Step 1: 写失败检查。** `check_feature_catalog.swift`：`.lifePayment` 的 `availability == .available(.lifePayment)`、`.mobileRecharge` 为 `.available(.mobileRecharge)`；可用数 `30 → 32`；搜索“话费”“水费”“电费”“燃气”结果含对应入口且标记可用（沿用文件内既有搜索用例写法）；同步修正文件内所有依赖 `lifePayment`/`mobileRecharge`/“M8 充值缴费”计划阶段的旧断言（先 `grep -n "lifePayment\|mobileRecharge\|M8" scripts/check_feature_catalog.swift` 列出）。
- [ ] **Step 2: 运行确认失败** — `zsh scripts/check_banking_data.sh`。
- [ ] **Step 3: 实现上述改动。**
- [ ] **Step 4: 运行检查与构建** — 检查全绿；构建 `BUILD SUCCEEDED`；`git diff --check` 无输出。
- [ ] **Step 5: 提交** — `git add ABank scripts && git commit -m "feat: 开放手机充值与生活缴费入口"`

---

### Task 8: 模拟器验收

**Files:**
- Create（被 Git 忽略）：`artifacts/abc-resources/verification/m8-*.png`

- [ ] **Step 1: 构建并安装**到 iPhone 16 Pro 模拟器（`mcp__Claude_Code_iOS_Simulator__control`：`attach` → 构建 → `launch`）；截图用 `screenshot` 动作，点击后等待约 2 秒再截图。
- [ ] **Step 2: 逐项验收并截图**（`m8-<name>.png`）：
  1. 生活 Tab：宫格“手机充值”“生活缴费”、横幅“生活缴费”进入对应页面；全部功能里两项可用；首页“生活缴费”入口进入。
  2. 手机充值：默认号码与运营商；改成非法号时下一步禁用；选面额；确认页无券与有券（先在积分商城用小豆兑换 5 元话费券）、选券后实付变化；确认提交成功、订单详情与成功横幅；券变“已使用”、M6 订单“已使用”。
  3. 生活缴费：三类页签、户号行状态；账单详情；缴费成功；同户号再进显示“本期已缴清”且按钮禁用；余额不足提示（连续充值/缴费到余额不足）。
  4. “我的订单”：混排、“充值缴费”筛选、缴费订单详情；账户明细出现“手机充值-…”“水费缴费-…”流水；“本月收支”支出同步增加；总资产同步减少。
  5. 重启 App 后订单、余额、券状态保持。
- [ ] **Step 3: 记录问题**：发现的 Bug 先修再复验（每个修复单独提交，`fix: …`）；无法验证的（320pt、小屏、大字体、跨月账期切换界面）如实记入交接。
- [ ] **Step 4: 清理**：从 App 容器偏好中删除 `abank.benefits.v1` 与 `abank.financeLedger.record.v8`（恢复种子数据）。

---

### Task 9: 全分支审查与文档

**Files:**
- Modify: `docs/development-plan.md`（M8 行改“已完成（待合并）”，新增“M8 实施记录”，写“下一会话：M9 账户与贷款扩展”）
- Create: `docs/continuity/tasks/m8-payment-recharge.md`
- Modify: `docs/continuity/CURRENT.md`（索引加 m8）

- [ ] **Step 1: 全分支审查**：对 `main..HEAD` 做一次全分支代码审查（Critical / Important 必须修复并复验，Minor 记入交接）。
- [ ] **Step 2: 最终验证**：`zsh scripts/check_banking_data.sh`、正常构建、`git diff --check` 全部通过。
- [ ] **Step 3: 写文档**：开发计划实施记录按 M7 格式（分支与起点、数据与规则、页面、入口、验证、模拟器、审查、未验证）；任务记录含目标与验收、已确认决策、提交列表、裁定（含话费券补偿取舍）、延后 Minor、未验证、下一步；不写 token/Cookie/个人敏感数据。
- [ ] **Step 4: 提交** — `git add docs && git commit -m "docs: 记录 M8 充值缴费实施与验证结果"`；不推送、不合并。
