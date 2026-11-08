# M9a 账户别名、查看分享与交易权限 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把借记卡的别名、查看/分享、账户限额入口和两项模拟交易权限做成可用的本地功能，权限在转账与充值缴费的确认前和提交时真实拦截。

**Architecture:** 别名与权限作为 `LedgerAccount` 的字段存入账本（方案 A），卡名统一由 `cardLabel` 生成；读写放在新扩展 `FinanceLedgerStore+AccountSettings.swift`；权限检查写在账本已有的转账与缴费校验里。三个新页面走 `AppRoute`，拦截提示由页面根据错误类型弹窗。

**Tech Stack:** UIKit、SnapKit、Swift 5、iOS 15.6+；数据检查脚本用 `xcrun swiftc` 在 macOS 编译运行。

**Spec:** `docs/superpowers/specs/2026-11-07-m9a-account-settings-design.md`

## Global Constraints

- 银行业务只用本地模拟数据，不新增网络请求、不做真实身份验证。
- 新文件放在同步文件夹内，无需修改 pbxproj。
- 卡名格式：有别名 `"\(alias)（\(tailNumber)）"`（全角括号），无别名 `"借记卡\(tailNumber)"`。
- 别名：去首尾空白；最多 10 个字（`String.count`）；不能含换行；空即清除（存 `nil`）。
- 文案逐字使用 spec §3.4：`别名最多 10 个字`、`别名不能包含换行`、`账户不存在或暂不可用`、`本地保存失败，请重试`、`手机银行转账已关闭，请先在交易权限中开启`、`网上支付已关闭，请先在交易权限中开启`。
- 权限检查早于余额、限额、优惠券、金额变化校验；被拦截时不扣款、不写任何记录、不使用优惠券。
- 理财购买不受权限影响。
- 提交信息用中文 Conventional Commits；不推送。

## Review Focus

1. 已存的旧账本（无 `alias`/`permissions` 键）升级后必须照常读取，余额与明细不变——测试见 Task 1 `legacyDecode`。
2. 转账确认页停留期间在另一处关闭权限，再点“确认”必须被拒且不跳到结果页——测试见 Task 2 `transferBlocked`（提交路径）与 Task 5 模拟器步骤。
3. 已有幂等请求（同一 `requestID` 已成交）在权限关闭后重放，应返回原订单而不是报权限错误——测试见 Task 2 `idempotentReplayAfterDisable`。
4. 关闭权限且余额不足/优惠券失效时，报的是权限错误——测试见 Task 2 `permissionFirst`。
5. 别名含表情或前后空格时卡名显示正确且计数按字——测试见 Task 1 `aliasRules`。

---

### Task 1: 账户模型、别名规则与读写

**Files:**
- Modify: `ABank/Features/Mine/Models/FinanceLedgerModels.swift:52-61`（`LedgerAccount`）
- Create: `ABank/Features/MyAccount/Models/AccountSettingsModels.swift`
- Create: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+AccountSettings.swift`
- Create: `scripts/check_account_settings.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加入两个新文件；循环加入 `account` → `scripts/check_account_settings.swift`）

**Interfaces:**
- Produces:
  - `struct AccountPermissions: Codable, Equatable { var mobileTransfer: Bool; var onlinePayment: Bool; static let allEnabled }`
  - `LedgerAccount.alias: String?`、`LedgerAccount.permissions: AccountPermissions`；`init(id:tailNumber:currency:balance:openingBalance:alias: String? = nil, permissions: AccountPermissions = .allEnabled)`
  - `enum AccountAliasRules { static let maxLength = 10; static func normalized(_ raw: String) throws -> String? }`
  - `enum AccountSettingsError: LocalizedError, Equatable { case aliasTooLong, aliasInvalidCharacter, accountNotFound, persistence }`
  - `FinanceLedgerStore.account(id: String) -> LedgerAccount?`
  - `FinanceLedgerStore.setAlias(_ raw: String, accountID: String) throws`
  - `FinanceLedgerStore.setPermissions(_ permissions: AccountPermissions, accountID: String) throws`
  - `enum AccountHolderName { static func masked(_ name: String) -> String }`（首尾保留，中间每字一个 `*`；两字为 `张*`；一字原样）

- [ ] **Step 1: Write the failing checks** in `scripts/check_account_settings.swift`（`@main struct AccountSettingsChecks`，沿用 `check_security_settings.swift` 的 `withSuite`/`expect` 写法，账本用独立 `UserDefaults` suite 构造 `FinanceLedgerStore(defaults:)`）：

```swift
legacyDecode()      // JSON {"id":"acct_8472","tailNumber":"8472","currency":"人民币","balance":100,"openingBalance":100}
                    // 解码后 alias == nil, permissions == .allEnabled, balance == 100
aliasRules()        // normalized("  工资卡 ") == "工资卡"; normalized("   ") == nil; normalized("") == nil
                    // normalized(String(repeating: "字", count: 10)) 成功; 11 个 → .aliasTooLong
                    // normalized(String(repeating: "😀", count: 10)) 成功; "工资\n卡" → .aliasInvalidCharacter
cardLabel()         // alias "工资卡" → "工资卡（8472）"; nil → "借记卡8472"
storeRoundTrip()    // setAlias("工资卡", accountID: defaultAccountId) 后新建 store 读出 alias == "工资卡"
                    // setAlias("", …) 后 alias == nil; setPermissions(mobileTransfer:false) 后读出 false
                    // 未知 accountID → .accountNotFound
writeFailure()      // dataWriter 抛错：setAlias/setPermissions 抛 .persistence，重新 load 后值不变
holderName()        // masked("韩继宏") == "韩*宏"; masked("张三") == "张*"; masked("欧阳明月") == "欧**月"; masked("李") == "李"
```

- [ ] **Step 2: Run to verify it fails**

Run: `zsh scripts/check_banking_data.sh`
Expected: 编译失败，提示 `AccountPermissions`/`AccountAliasRules` 未定义。

- [ ] **Step 3: Implement** 模型与规则、`LedgerAccount` 自定义 `init(from:)`（新字段 `decodeIfPresent`，缺省 `nil`/`.allEnabled`）、`cardLabel` 新格式、三个 store 方法（`loadForTransfer()` 严格读取，读取失败转为 `.persistence`；修改后 `persist`，失败抛 `.persistence`）。

- [ ] **Step 4: Run to verify it passes**

Run: `zsh scripts/check_banking_data.sh`
Expected: 全部原有检查输出 passed，并新增 `Account settings checks passed`。

- [ ] **Step 5: Commit**

```bash
git add ABank/Features/Mine/Models/FinanceLedgerModels.swift ABank/Features/MyAccount/Models/AccountSettingsModels.swift ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+AccountSettings.swift scripts/check_account_settings.swift scripts/check_banking_data.sh
git commit -m "feat: 账户别名与交易权限数据模型"
```

### Task 2: 账本中的权限拦截

**Files:**
- Modify: `ABank/Features/Transfer/Models/TransferSimulationModels.swift`（`TransferError` 加 `transferPermissionDisabled`）
- Modify: `ABank/Features/Payment/Models/PaymentModels.swift`（`PaymentError` 加 `onlinePaymentDisabled`）
- Modify: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift`（私有 `validateTransfer(_:record:now:)`：找到 `payer` 后立即检查）
- Modify: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Payment.swift`
- Test: `scripts/check_account_settings.swift`

**Interfaces:**
- Consumes: Task 1 的 `setPermissions`、`LedgerAccount.permissions`
- Produces:
  - `TransferError.transferPermissionDisabled`、`PaymentError.onlinePaymentDisabled`
  - `FinanceLedgerStore.validateUtilityPayment(billAccountID: String) throws`（新，确认前校验：权限、账单存在、未缴清、余额）
  - 充值：`checkedRecharge` 开头、缴费：`submitUtilityPayment` 在幂等返回之后、账单校验之前，调用私有 `requireOnlinePayment(in: FinanceLedgerRecord) throws`

- [ ] **Step 1: Write the failing checks**

```swift
transferBlocked()   // setPermissions(mobileTransfer: false) 后：validateTransfer(draft) 与 submitTransfer(draft:requestID:"r1")
                    // 均抛 .transferPermissionDisabled；余额、transactions.count、transferRecords.count 不变
                    // 重新开启后 submitTransfer 成功（status == .succeeded）
paymentBlocked()    // onlinePayment false：validateMobileRecharge、submitMobileRecharge(带可用话费券)、
                    // validateUtilityPayment、submitUtilityPayment 均抛 .onlinePaymentDisabled；
                    // 余额、paymentOrders().count、transactions.count 不变；该券 status 仍为 .unused
permissionFirst()   // 余额置 0 且关闭两项权限：转账报 .transferPermissionDisabled，缴费报 .onlinePaymentDisabled
idempotentReplayAfterDisable() // 先 submitMobileRecharge(requestID:"same") 成功，再关 onlinePayment，
                    // 同 requestID 重放返回同一订单 id（与转账已有幂等行为一致）
wealthUnaffected()  // 两项都关闭时，理财购买（沿用 check_wealth 的最小可成交参数）仍成功
```

- [ ] **Step 2: Run to verify it fails**

Run: `zsh scripts/check_banking_data.sh`
Expected: 编译失败（新 error case 未定义）。

- [ ] **Step 3: Implement** 两个 error case 与文案（见 Global Constraints）、转账检查、`requireOnlinePayment`、`validateUtilityPayment`。转账检查位置：`guard let payer … else { throw .missingAccount }` 之后、`sameAccount` 之前。

- [ ] **Step 4: Run to verify it passes**

Run: `zsh scripts/check_banking_data.sh`
Expected: 全部 passed（含原 transfer/payment/wealth 检查）。

- [ ] **Step 5: Commit**

```bash
git add -A ABank/Features scripts/check_account_settings.swift
git commit -m "feat: 交易权限拦截转账与充值缴费"
```

### Task 3: 路由、目录与别名页、权限页

**Files:**
- Modify: `ABank/Core/Routing/AppRoute.swift`（加 `accountAlias(accountID: String?)`、`accountShare(accountID: String?)`、`accountPermissions(accountID: String?)`）
- Modify: `ABank/Core/Routing/AppRouter.swift`（`makeViewController`：`nil` 取 `FinanceLedgerRecord.defaultAccountId`）
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（`FeatureID` 加 `accountPermissions`；账户分类条目“交易权限”，关键词 `["权限", "开关", "网上支付"]`，`.available(.accountPermissions(accountID: nil))`）
- Modify: `scripts/check_feature_catalog.swift:15-17`（69→70，可用 32→33；断言该条目路由与关键词搜索“权限”命中）
- Create: `ABank/Features/MyAccount/AccountSettings/AccountAliasViewController.swift`
- Create: `ABank/Features/MyAccount/AccountSettings/AccountPermissionsViewController.swift`
- Modify: `ABank/Features/MyAccount/MyAccountViewController.swift:107-125`（`.setAlias` → 路由）
- Modify: `ABank/Features/MyAccount/DebitCardDetail/DebitCardDetailViewController.swift:87-104`（账户别名→`accountAlias`、账户限额→`.transferLimits`、交易权限→`accountPermissions`）

**Interfaces:**
- Consumes: Task 1 的 `account(id:)`、`setAlias`、`setPermissions`、`AccountAliasRules`、`AccountSettingsError`
- Produces: 两个页面类 `AccountAliasViewController(accountID:ledger:)`、`AccountPermissionsViewController(accountID:ledger:)`，均 `RouteHosting`

三个新页面都继承 `TransferFlowViewController`（`ABank/Features/Transfer/Views/TransferFlowViews.swift`，提供 `contentStack`、`addNotice`、`addGroup`、`addButton`，并在 `refreshBankingData` 时刷新），行组件复用 `TransferInputRow`、`TransferInfoRow`、`SecuritySwitchRow`。

- [ ] **Step 1: Update catalog checks first**（数量 70/33、新条目路由、搜索“权限”含 `.accountPermissions`）

- [ ] **Step 2: Run to verify it fails**

Run: `zsh scripts/check_banking_data.sh`
Expected: 编译失败或 `ids 69` 断言失败。

- [ ] **Step 3: Implement** 路由、目录条目、两页面与入口接线：
  - 别名页：预填当前别名；`editingChanged` 时用 `AccountAliasRules.normalized` 校验，错误显示在输入框下方并禁用“保存”；下方“还可输入 N 字”；保存成功 pop 并在上一页提示“别名已更新”（清除时“已恢复默认名称”）；失败提示 `AccountSettingsError.persistence` 文案。accessibility id：`alias.field`、`alias.error`、`alias.save`。
  - 权限页：两个开关，标题“手机银行转账”/“网上支付”，副标题“关闭后无法转账”/“关闭后无法手机充值和生活缴费”；切换即 `setPermissions`，失败回弹并提示；底部注明“本机模拟权限，不涉及真实账户”。id：`permissions.transfer`、`permissions.payment`。

- [ ] **Step 4: Verify**

Run: `zsh scripts/check_banking_data.sh` 然后 spec §6.2 构建命令（输出重定向到 `/private/tmp/m9a-build.log`，`tail -3`）
Expected: 检查全部 passed；`** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add -A ABank scripts/check_feature_catalog.swift
git commit -m "feat: 账户别名页与交易权限页"
```

### Task 4: 查看/分享页与别名显示

**Files:**
- Create: `ABank/Features/MyAccount/AccountSettings/AccountShareViewController.swift`
- Modify: `ABank/Features/MyAccount/MyAccountViewController.swift`（`.viewShare` → 路由；`viewWillAppear` 重新读取别名并刷新卡片）
- Modify: `ABank/Features/MyAccount/Views/MyAccountDebitCardView.swift`（掩码卡号上方加别名行，`alias == nil` 时隐藏；`configure(with:alias:)`）
- Modify: `ABank/Features/MyAccount/DebitCardDetail/DebitCardDetailViewController.swift` 与 `Views/DebitCardDetailInfoCardView.swift`（同样的别名行，`viewWillAppear` 刷新）
- Modify: `ABank/Features/Payment/PaymentFlowViewController.swift:83-87`（`label` 改用 `account.cardLabel`）

**Interfaces:**
- Consumes: Task 1 的 `account(id:)`、`AccountHolderName.masked`；Task 3 的路由
- Produces: `AccountShareViewController(accountID:ledger:customer:)`，`RouteHosting`

- [ ] **Step 1: Implement 查看/分享页**：顶部“本机模拟数据”；行：户名（`AccountHolderName.masked(CustomerInfoStore.shared.load().name)`）、卡号（默认 `MyAccountDebitCard.maskedNumber`，眼睛切换 `fullNumber`）、开户行“农行西安东关正街支行”、账户类型“I类”；按钮“复制卡号”（`UIPasteboard.general.string` = 去空格完整卡号，提示“已复制”）、“分享”（`UIActivityViewController`，文本 `"户名：…\n卡号：…\n开户行：…\n（模拟数据，非真实账户）"`，iPad 设 popover 源）。卡号与账户类型取 `MockDataProvider.shared.getMyAccountPageData()` 中与 `accountID` 匹配的卡。id：`share.number`、`share.eye`、`share.copy`、`share.share`。

- [ ] **Step 2: Implement 别名显示** 于两张卡片与缴费付款账户。

- [ ] **Step 3: Verify**

Run: `zsh scripts/check_banking_data.sh` 与构建命令
Expected: 全部 passed；`** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add -A ABank
git commit -m "feat: 账户查看分享与别名显示"
```

### Task 5: 拦截提示与“去开启”

**Files:**
- Create: `ABank/Features/MyAccount/AccountSettings/PermissionBlockedAlert.swift`
- Modify: `ABank/Features/Transfer/TransferFormViewController.swift:102-109`
- Modify: `ABank/Features/Transfer/TransferConfirmViewController.swift:41-65`
- Modify: `ABank/Features/Payment/MobileRechargeViewController.swift:111-115`
- Modify: `ABank/Features/Payment/PaymentFlowViewController.swift:74-76`（`showError`）
- Modify: `ABank/Features/Payment/UtilityBillViewController.swift`（`payTapped` 前置 `validateUtilityPayment`）

**Interfaces:**
- Consumes: Task 2 的两个 error case 与 `validateUtilityPayment`；Task 3 的 `accountPermissions` 路由
- Produces: `extension UIViewController { @discardableResult func presentPermissionBlockedIfNeeded(_ error: Error, router: AppRouting) -> Bool }`——是两种权限错误时弹窗（标题为错误文案，按钮“取消”“去开启”→`router.open(.accountPermissions(accountID: nil), from: self)`）并返回 `true`

- [ ] **Step 1: Implement**
  - 转账表单 `nextTapped`：`catch` 先 `presentPermissionBlockedIfNeeded`，否则走原 `addError`。
  - 转账确认 `submit`：提交抛 `.transferPermissionDisabled` 时不进入结果页——恢复按钮标题“确认模拟转账”、启用按钮、恢复返回手势与 `hidesBackButton = false`、`isSubmitting = false`，再弹窗；其他错误保持原有结果页。
  - 充值 `nextTapped`：先 `ledger.validateMobileRecharge(phone:faceInCents:couponID: nil)`，权限错误弹窗并停留；其他错误不拦截（交给确认页原逻辑）。
  - `PaymentFlowViewController.showError`：权限错误弹窗，否则原 toast。
  - 缴费 `payTapped`：先 `validateUtilityPayment`，失败走 `showError` 后返回。

- [ ] **Step 2: Verify**

Run: `zsh scripts/check_banking_data.sh` 与构建命令
Expected: 全部 passed；`** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add -A ABank
git commit -m "feat: 权限关闭时提示并引导开启"
```

### Task 6: 模拟器验收与文档

**Files:**
- Modify: `docs/development-plan.md`（M9 行改为“进行中（M9a 已完成，M9b 未开始）”，新增 M9a 实施记录与“下一会话：M9b 贷款扩展”）
- Create/Modify: `docs/continuity/tasks/m9a-account-settings.md`

- [ ] **Step 1: 模拟器验收**（iPhone 16 Pro，安装 Debug 构建；截图存 `artifacts/abc-resources/verification/`）：
  1. `m9a-alias-edit.png` 设置别名“工资卡”；`m9a-alias-myaccount.png`、`m9a-alias-detail.png`、`m9a-alias-transfer.png`、`m9a-alias-payment.png` 四处显示“工资卡（8472）”或别名行。
  2. `m9a-share-hidden.png`、`m9a-share-visible.png`；复制后提示“已复制”；`m9a-share-sheet.png` 分享面板。
  3. 关闭转账权限：`m9a-transfer-blocked.png` 弹窗；“去开启”进入 `m9a-permissions.png`；开启后转账成功。
  4. 关闭网上支付：`m9a-recharge-blocked.png`。
  5. 借记卡详情“更多”→账户限额进入转账设置：`m9a-limits-entry.png`。
  6. 验收后清除别名、两项权限恢复开启。

- [ ] **Step 2: 更新文档**（验证命令与结果、截图清单、未覆盖项“待截图校准”、提交号）。

- [ ] **Step 3: Commit**

```bash
git add docs/development-plan.md docs/continuity/tasks/m9a-account-settings.md
git commit -m "docs: 记录 M9a 账户设置实施与验证结果"
```
