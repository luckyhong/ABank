# M9a 账户别名、查看分享与交易权限设计

日期：2026-11-07。基线：`main@e5250dc`，分支 `feat/m9-account-loan`。对应 [开发计划](../../development-plan.md) 阶段 M9 的账户部分；贷款部分（M9b）另行设计。

## 1. 目标与已确认决策

**目标**：把“我的账户”和借记卡详情里只弹提示的账户入口做成可演示的本地功能：账户别名、查看/分享、账户限额入口和模拟交易权限。

用户已确认：

| 议题 | 决策 |
|---|---|
| 阶段拆分 | M9 拆为 M9a 账户、M9b 贷款，先做 M9a |
| 交易权限 | 真实拦截，只做“手机银行转账”“网上支付”两项；确认前与提交时都校验 |
| 别名显示范围 | 所有显示卡名的地方统一使用别名 |
| 存储方案 | 方案 A：别名与权限作为借记卡属性存入账本 `LedgerAccount` |
| 视觉参考 | 无原版截图，按现有设计系统设计，交接中标注“待截图校准” |

**验收标准**

1. “我的账户”卡片的“设置别名”“查看/分享”，借记卡详情“更多”中的“账户别名”“账户限额”“交易权限”均进入对应页面，不再只弹提示。
2. 设置别名后，“我的账户”卡片、借记卡详情、转账付款账户、充值缴费付款账户都显示“别名（8472）”；清除后恢复“借记卡8472”；重启后保持。
3. 别名不合规时行内提示并禁用保存；保存失败时保留旧值并提示。
4. 关闭“手机银行转账”后，转账在确认前校验和提交时均被拒绝，不扣款、不生成流水和记录；重新开启后可正常转账。
5. 关闭“网上支付”后，手机充值和生活缴费在确认前与扣款时均被拒绝，余额、订单、流水、优惠券不变。
6. 被拦截时弹窗说明哪项权限已关闭，“去开启”进入交易权限页。
7. 查看/分享页可显示/隐藏完整卡号、复制卡号、调起系统分享，内容标注模拟数据。
8. 旧账本数据可正常读取；数据检查（新增账户设置检查）、构建、模拟器验收全部通过；不新增网络请求。

**不在本阶段范围**：贷款相关功能（M9b）；新增借记卡或多账户管理；其他权限项（境外交易、ATM 取现、无卡支付等）；理财购买的权限拦截；修改户名、开户行等账户资料；生成二维码或图片形式的分享卡片。

## 2. 方案选择

选定方案 A：在 `LedgerAccount` 上新增 `alias` 与 `permissions`。

- 卡名统一由 `LedgerAccount.cardLabel` 生成，转账、缴费、账户页都读它；把别名放进账户，所有显示处自动生效。
- 转账（`validateTransfer`/`submitTransfer`）与缴费（`FinanceLedgerStore+Payment`）在扣款前都从账本取这张卡，权限检查直接放在这些校验里，任何入口都绕不过。
- 代价：改变账本存储结构，须保证旧数据可读（§3.1）。

未选：B 独立 `AccountSettingsStore` 经闭包注入账本——接入点多，别名与卡分开存放易不一致；C 并入 `SecuritySettingsStore`——别名不属于安全设置。

## 3. 数据与规则

### 3.1 模型

```swift
struct AccountPermissions: Codable, Equatable {
    var mobileTransfer: Bool   // 手机银行转账
    var onlinePayment: Bool    // 网上支付（手机充值、生活缴费）
    static let allEnabled = AccountPermissions(mobileTransfer: true, onlinePayment: true)
}
```

`LedgerAccount` 新增：

- `var alias: String?`——`nil` 表示无别名。
- `var permissions: AccountPermissions`——解码时缺失则为 `.allEnabled`（自定义 `init(from:)` 用 `decodeIfPresent`）。

旧账本数据缺少这两个字段时读取为“无别名、两项权限都开”，余额、明细不变。

### 3.2 卡名

`cardLabel`：有别名时为 `"\(alias)（\(tailNumber)）"`（全角括号），否则保持 `"借记卡\(tailNumber)"`。`displayName` 不变。

### 3.3 别名规则（`AccountAliasRules`）

- 去掉首尾空白后判断；结果为空表示清除别名（存为 `nil`）。
- 最多 10 个字，按 `String.count`（字形簇）计算，一个表情算一个字。
- 不得包含换行符。
- 页面实时校验，`FinanceLedgerStore` 保存时再校验一次。

### 3.4 错误

新增 `AccountSettingsError: LocalizedError, Equatable`：

| case | 文案 |
|---|---|
| `aliasTooLong` | 别名最多 10 个字 |
| `aliasInvalidCharacter` | 别名不能包含换行 |
| `accountNotFound` | 账户不存在或暂不可用 |
| `persistence` | 本地保存失败，请重试 |

`TransferError` 新增 `transferPermissionDisabled`：“手机银行转账已关闭，请先在交易权限中开启”。
`PaymentError` 新增 `onlinePaymentDisabled`：“网上支付已关闭，请先在交易权限中开启”。

### 3.5 写入

`FinanceLedgerStore` 新增（放在 `FinanceLedgerStore+AccountSettings.swift`）：

- `func account(id: String) -> LedgerAccount?`
- `func setAlias(_ raw: String, accountID: String) throws`
- `func setPermissions(_ permissions: AccountPermissions, accountID: String) throws`

均为严格读取账本（读取失败抛错）→ 修改 → 通过 `persist` 整份写回；写入失败抛 `.persistence`，内存与存储都不变化。

## 4. 页面与交互

### 4.1 路由与入口

`AppRoute` 新增 `accountAlias(accountID:)`、`accountShare(accountID:)`、`accountPermissions(accountID:)`。

| 入口 | 目标 |
|---|---|
| 我的账户卡片“设置别名” | `accountAlias` |
| 我的账户卡片“查看/分享” | `accountShare` |
| 借记卡详情“更多”→账户别名 | `accountAlias` |
| 借记卡详情“更多”→账户限额 | `transferLimits`（M4 已有） |
| 借记卡详情“更多”→交易权限 | `accountPermissions` |
| 全部功能“账户”分类新增“交易权限”（关键词：权限、开关、网上支付） | `accountPermissions(accountID: nil)`，`nil` 取默认账户 |

我的账户卡片与借记卡详情信息卡目前只显示掩码卡号、没有卡名：有别名时在卡号上方加一行别名文字，无别名时不显示该行。两页在 `viewWillAppear` 从账本重新读取别名，返回后即显示新名字。转账、缴费付款账户直接使用 `cardLabel`。

### 4.2 设置别名页

- 输入框预填当前别名，下方显示剩余字数。
- 不合规时输入框下方显示原因并禁用“保存”。
- 保存成功返回上一页并提示“别名已更新”；留空保存提示“已恢复默认名称”。
- 保存失败提示 `persistence` 文案，停留在本页。

### 4.3 查看/分享页

- 顶部标注“本机模拟数据”。
- 显示户名、卡号、开户行、账户类型（I 类）。
  - 户名取自客户信息，保留首尾字、中间用 `*`（两个字时为“张*”）。
  - 卡号默认显示掩码，右侧眼睛切换完整卡号（与金额隐私无关）。
  - 开户行使用借记卡详情已有的“开户网点”模拟值（农行西安东关正街支行）。
- “复制卡号”写入剪贴板（无空格完整卡号），提示“已复制”。
- “分享”调起 `UIActivityViewController`，文本为户名、卡号、开户行，末尾加“（模拟数据，非真实账户）”。

### 4.4 交易权限页

- 两个开关：手机银行转账（关闭后无法转账）、网上支付（关闭后无法手机充值和生活缴费）。
- 切换立即保存；失败时开关回弹并提示 `persistence` 文案。
- 底部说明“本机模拟权限，不涉及真实账户”。

### 4.5 被拦截时

转账、充值、缴费在确认前校验或提交时收到权限错误，弹出提示框：标题为对应错误文案，按钮“去开启”（进入 `accountPermissions`）与“取消”（留在当前页）。

## 5. 拦截规则

- 转账：`validateTransfer` 与 `submitTransfer` 在取得付款账户后、校验余额与限额之前检查 `permissions.mobileTransfer`。
- 手机充值与生活缴费：`FinanceLedgerStore+Payment` 的确认前校验与扣款路径在取付款账户时先检查 `permissions.onlinePayment`，早于余额、优惠券、金额变化校验。
- 理财购买不受影响。
- 被拦截时不扣款，不生成流水、订单、转账记录，优惠券保持未使用。

## 6. 测试与验收

### 6.1 数据检查

新增 `scripts/check_account_settings.swift` 并接入 `scripts/check_banking_data.sh`：

1. 旧格式账户 JSON（无 `alias`/`permissions`）可解码，结果为 `nil` 与 `.allEnabled`，余额不变。
2. 别名：首尾空白被去掉；10 字可存、11 字拒绝（`aliasTooLong`）；10 个表情可存；含换行拒绝；空白字符串清除为 `nil`。
3. `cardLabel`：有别名为“工资卡（8472）”，无别名为“借记卡8472”。
4. 关闭转账权限：`validateTransfer` 与 `submitTransfer` 抛 `transferPermissionDisabled`；余额、流水、转账记录不变；重新开启后转账成功。
5. 关闭网上支付：手机充值与生活缴费抛 `onlinePaymentDisabled`；余额、订单、流水不变，使用的优惠券仍为未使用。
6. 权限优先：关闭权限且余额不足时，报权限错误而非余额不足。
7. 写入失败（注入抛错的 `dataWriter`）：别名与权限保持原值。
8. 现有转账、缴费、理财、安全设置等检查全部通过。

### 6.2 构建

```bash
export LANG=en_US.UTF-8
xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build
```

### 6.3 模拟器验收（截图存 `artifacts/abc-resources/verification/m9a-*.png`）

1. 设置别名后，我的账户、借记卡详情、转账付款账户、缴费付款账户都显示新名字。
2. 查看/分享：完整卡号显示/隐藏、复制、分享面板。
3. 关闭转账权限后转账被拦截，“去开启”进入权限页，开启后转账成功。
4. 关闭网上支付后充值被拦截。
5. 借记卡详情“更多”→账户限额进入转账设置。

验收后恢复模拟器数据到默认状态。

## 7. 风险

- 账本结构变化：旧数据兼容由检查 1 覆盖；新字段写入后旧版本 App 无法回退读取不在考虑范围（本地学习项目）。
- `cardLabel` 变化会影响已存流水中按卡名生成的文案：已有流水保存的是 `cardNumber`（`****8472`），不受影响；新流水同样不使用别名。
