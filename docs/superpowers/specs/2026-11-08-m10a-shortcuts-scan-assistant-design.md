# M10a 桌面快捷操作、演示扫码与本地关键词助手设计

日期：2026-11-08。基线：`main@b796ca8`（M9 已合并并推送），分支 `feat/m10a-shortcuts`。对应 [开发计划](../../development-plan.md) 阶段 M10 的 App 内部分；模拟余额 Widget 留给 M10b。

## 1. 目标与已确认决策

**目标**：新增三个本地入口——长按 App 图标的快捷操作、“扫一扫”演示扫码、“客服”进入的关键词助手——都只跳转已完成页面，统一经 `AppRouter`。全部为本地模拟，不联网、不调用相机、不自动产生交易。

用户已确认：

| 议题 | 决策 |
|---|---|
| 扫一扫 | 演示扫码：取景框动画 + 选择示例码，不申请相机权限 |
| 扫码结果 | 先显示识别结果卡片，点“前往”才跳转；4 个示例码（个人收款码、网点取号码、电费缴费码、无效码）；永不自动付款 |
| 助手形式 | 对话式：欢迎语 + 快捷问题标签，回复一段说明与 1–3 个功能卡片；会话只在本次页面内保留 |
| 桌面快捷操作 | 固定 4 个（扫一扫、转账、收支明细、在线助手），写在 Info.plist |
| 实现方案 | 方案 A：三个纯 Foundation 解析器产出 `AppRoute`/`FeatureID`，入口统一交给 `AppRouter` |
| 视觉参考 | 无原版截图，按现有页面风格设计，交接标注“待截图校准” |

**验收标准**

1. 长按 App 图标显示 4 个快捷操作；冷启动与后台唤起时点击都切到首页 Tab、回到根页并打开对应页面；未知类型忽略。
2. 首页宫格与全部功能中的“扫一扫”进入演示扫码页，不再进入“即将上线”。
3. 演示扫码选择示例码后显示识别结果；收款码“前往”进入预填收款人的转账表单（金额为空，仍走原有权限、确认与限额校验）；网点取号码进入该网点取号页；缴费码进入该账单缴费页；无效码只提示无法识别。
4. 首页、财富、资讯、转账、明细查询、贷款详情的“客服”入口进入在线助手，不再弹提示。
5. 助手对常见问题给出固定回答与可点功能卡片；无意图命中时按功能搜索；都无结果时给出兜底回复；卡片只含已完成功能，最多 3 个。
6. 输入含 6 位及以上连续数字时不回显，提醒勿发送卡号、密码、验证码等信息。
7. 全部功能新增“在线助手”；目录总数 70 → 71，已完成 33 → 35。

## 2. 方案选择

- **A（采用）本地入口 → 路由层**：`QuickAction`、`ScanCodeParser`、`AssistantEngine` 只依赖 Foundation，可由检查脚本直接测试；页面只负责展示，跳转统一经 `AppRouter`（复用栈顶去重与“已完成/即将上线”判断）。
- B 注册 `abank://` URL scheme 统一走链接：对外暴露入口，任何 App 或网页都能调用，项目不需要，不采用。
- C 各入口直接 push 页面：绕过路由去重与可用性判断，逻辑无法脚本测试，不采用。

## 3. 路由与入口

### 3.1 新路由

`AppRoute` 新增：

- `.scan`：演示扫码页。
- `.assistant`：在线助手页。
- `.transferToPayee(name: String, bankName: String, account: String)`：以 `TransferDraft(method: .account, recipientName:, bankName:, destination:)` 打开现有转账表单；金额为空，不设 `savedRecipientID`。

`AppRouter.makeViewController` 穷举补全。

### 3.2 功能目录

- `.scan`“扫一扫”由 `.planned(stage: "M10 快捷与扫码")` 改为 `.available(.scan)`。
- 新增 `FeatureID.assistant`“在线助手”，分类“网点与安全”，关键词“客服、帮助、助手、咨询”，`.available(.assistant)`，图标 `headphones`。
- 检查脚本：总数 71、标题唯一、已完成 35。

### 3.3 桌面快捷操作

`Info.plist` 增加 `UIApplicationShortcutItems`（静态，首次安装未打开也可用）：

| type | 标题 | 系统图标 | 路由 |
|---|---|---|---|
| `com.abank.shortcut.scan` | 扫一扫 | `qrcode.viewfinder`（UIApplicationShortcutIconSymbolName） | `.scan` |
| `com.abank.shortcut.transfer` | 转账 | `arrow.left.arrow.right` | `.transfer(payerAccountID: nil)` |
| `com.abank.shortcut.incomeExpense` | 收支明细 | `list.bullet.rectangle` | `.incomeExpense(accountID: nil)` |
| `com.abank.shortcut.assistant` | 在线助手 | `headphones` | `.assistant` |

- `QuickAction.route(forType:) -> AppRoute?`：仅识别上表 4 个 type，其余返回 nil。
- `SceneDelegate`：
  - 冷启动：`scene(_:willConnectTo:options:)` 从 `connectionOptions.shortcutItem` 取出并暂存，主界面建立后处理。
  - 后台唤起：`windowScene(_:performActionFor:completionHandler:)` 直接处理，`completionHandler(route != nil)`。
- 处理：`MainTabBarController` 切到首页 Tab，关闭已弹出的模态页，该 Tab 导航栈回到根页，再 `AppRouter.shared.open(route, from: 首页根页)`。
- 快捷操作直达页面不记录“最近使用”（与带上下文的直接跳转一致）。

### 3.4 客服入口

以下“客服”入口改为 `AppRouter.open(.assistant, from:)`，其余拨打电话类提示（如资产负债的“拨打客服 95599”）不变：

- 首页顶部栏、财富顶部栏、资讯顶部栏；
- 转账页、明细查询页、贷款详情页导航栏“客服”。

## 4. 演示扫码

### 4.1 示例码与解析

示例码为固定字符串，字段以 `|` 分隔，`key=value`：

| 示例 | 内容 |
|---|---|
| 个人收款码 | `ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217000000000593` |
| 网点取号码 | `ABANKDEMO|BRANCH|id=xa-fengdong` |
| 电费缴费码 | `ABANKDEMO|BILL|id=bill.electric.home` |
| 无效码 | `https://example.com/pay?amount=100` |

`ScanCodeParser.parse(_ text: String) -> ScanResult`：

```swift
enum ScanResult: Equatable {
    case payee(name: String, bankName: String, account: String)   // → .transferToPayee
    case branch(branchID: String, branchName: String)             // → .takeTicket(branchID:)
    case bill(billAccountID: String, title: String)               // → .utilityBill(billAccountID:)
    case unrecognized
    var route: AppRoute? { get }                                  // .unrecognized 为 nil
}
```

规则（任一不满足即 `.unrecognized`）：

- 去首尾空白后以 `ABANKDEMO|` 开头；类型只能是 `PAY`、`BRANCH`、`BILL`；
- 字段集合必须恰好等于该类型所需（PAY：name、bank、acct；BRANCH、BILL：id），重复键、多余字段（包括 `amount`）、空值均拒绝；
- `acct` 为 16–19 位 ASCII 数字；`name` 1–20 个字符；
- `BRANCH` 的 id 必须存在于 `BranchCatalog` 且为可取号网点（非自助银行）；`BILL` 的 id 必须存在于 `PaymentCatalog`。

### 4.2 页面

`ScanViewController`（深色全屏，导航栏透明，标题“扫一扫”）：

- 顶部提示“演示扫码 · 不调用相机”；中部取景框四角与上下往复的扫描线动画（页面消失时停止）。
- 取景框下方 4 张示例码卡片（图标 + 名称），点击后取景框显示“识别中…”约 0.8 秒，期间卡片不可再点。
- 结果卡片（底部弹出）：
  - 可识别：类型标题与内容（收款人姓名脱敏如“欧*瑶”、银行与账号尾号 4 位；网点名称；账单名称），按钮“前往”“重新扫描”。
  - 无法识别：“无法识别该二维码，请扫描 ABank 演示码”，仅“重新扫描”。
- “前往”：在导航栈中用目标页替换扫码页（返回回到进入扫码前的页面）。

## 5. 本地关键词助手

### 5.1 引擎

```swift
struct AssistantReply: Equatable {
    let text: String
    let features: [FeatureID]     // 仅已完成功能，最多 3 个
    let isSensitiveWarning: Bool
}
enum AssistantEngine {
    static func reply(to input: String) -> AssistantReply?   // 规整后为空返回 nil
}
```

处理顺序：

1. **规整**：全角转半角（`applyingTransform(.fullwidthToHalfwidth)`），去首尾空白，去标点与空白，转小写；为空返回 nil。
2. **敏感检查**：规整后含 6 位及以上连续数字 → 固定回复“为保障安全，请勿在对话中发送卡号、密码、验证码等信息。”，无卡片，`isSensitiveWarning = true`。
3. **意图匹配**：按命中触发词个数取最高分，同分取表中靠前者。意图表（回答为固定文案，功能按顺序过滤已完成后取前 3）：

| 意图 | 触发词 | 功能 |
|---|---|---|
| 转账 | 转账、汇款、打钱、转钱 | transfer、transferRecords、transferLimits |
| 余额明细 | 余额、明细、流水、收支 | myAccount、accountDetail、incomeExpense |
| 贷款 | 贷款、还贷、提前还款、月供、房贷 | loan |
| 网点 | 网点、预约、取号、排队、营业时间 | branchQuery、branchQueue |
| 缴费 | 缴费、水费、电费、燃气 | lifePayment |
| 充值 | 话费、充值、流量 | mobileRecharge |
| 理财 | 理财、风险测评、收益 | wealthProduct |
| 积分权益 | 积分、小豆、卡券、优惠券、权益 | benefits、pointsMall、beans |
| 交易权限 | 交易权限、开通转账、网上支付、关闭转账 | accountPermissions |
| 登录安全 | 登录、密码、设备、安全 | securityCenter、loginSettings、loginDevices |
| 扫码 | 扫码、扫一扫、二维码、收款码 | scan |
| 订单 | 订单、兑换记录 | orders |

4. **功能搜索兜底**：`FeatureSearch.search(规整前的去空白输入)`，过滤已完成取前 3；有结果回复“为您找到以下功能：”。
5. **无结果**：“没找到相关内容，换个说法试试，或看看这些常用功能：”，卡片固定为 transfer、incomeExpense、branchQuery。

### 5.2 页面

`AssistantViewController`（标题“在线助手”）：

- 顶部小字“智能助手为本地演示，回答仅供参考”。
- 首条助手消息：“您好，我是 ABank 在线助手，可以帮您查找功能和解答常见问题。”下方 4 个快捷问题标签：怎么转账、查余额、提前还款、附近网点；点击即作为用户消息发送。
- 气泡：用户在右侧橙色，助手在左侧白色；助手气泡内可带功能卡片（图标 + 名称 + 箭头），点击经 `AppRouter.open(feature:from:)` 打开（记录最近使用）。
- 底部输入栏（文本框 + 发送），随键盘上移；发送后清空输入并滚到底部；敏感提醒的用户消息仍显示原文在用户气泡中（仅在本页内存），助手不复述。
- 会话只存于页面内存，离开即清空，不写任何存储。

## 6. 错误与边界

- 快捷操作 type 未知、扫码内容不合规、助手输入为空：均不跳转、不报错崩溃。
- 扫码“前往”目标页由现有页面自行处理数据异常（如网点或账单被移除时现有页面的空态）。
- 收款码不携带金额；转账仍须用户输入金额并经过 M9a 交易权限、限额、余额与确认页。
- 不新增持久化、网络请求或权限申请（`Info.plist` 不加相机描述）。

## 7. 测试

`scripts/check_banking_data.sh` 新增检查组 `entry`（`scripts/check_entry.swift`）：

- `quickActions`：4 个 type 对应路由；未知 type、空字符串为 nil。
- `scanSamples`：3 个有效示例码解析为期望结果与路由；无效示例为 `.unrecognized`。
- `scanRejects`：错误前缀、未知类型、缺字段、重复键、多余 `amount`、空值、账号 15/20 位或含非数字、未知网点、自助银行网点、未知账单、空字符串均为 `.unrecognized`；首尾空白可接受。
- `assistantIntents`：每个意图至少一个触发词命中期望功能；全角与标点输入（如“　转账？　”、“ＡＢＣ转账”）规整后仍命中转账。
- `assistantTieBreak`：同分取表中靠前意图。
- `assistantSearchFallback`：无意图命中但功能名命中时返回搜索结果（如“电子回单”）。
- `assistantFilters`：卡片均为已完成功能且不超过 3 个（遍历全部意图）。
- `assistantSensitive`：含 6 位连续数字（含全角数字）时返回安全提醒且回复文本不含该数字；5 位数字不触发。
- `assistantFallback`：无意义输入返回兜底文案与固定 3 个卡片；空白输入返回 nil。

功能目录检查同步更新（71 / 35）。模拟器验收覆盖第 1 节 1–6 条。

## 8. 不做

- 真实相机、相册识别、URL scheme、Widget（M10b）。
- 助手接入任何模型或网络、聊天记录持久化、多轮上下文。
- 动态快捷操作（跟随常用功能或最近使用）。
