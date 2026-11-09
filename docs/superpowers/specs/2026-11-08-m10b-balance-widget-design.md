# M10b 模拟余额 Widget 设计

日期：2026-11-08。基线：`main@3cebcde`（M10a 已合并并推送），分支 `feat/m10b-widget`。对应 [开发计划](../../development-plan.md) 阶段 M10 的 Widget 部分。

## 1. 目标与已确认决策

**目标**：新增桌面 Widget，展示默认借记卡的模拟余额与本月收支，点击进入已完成页面。数据由 App 在账本变化后写入 App Group 快照，Widget 只读快照；全部为本地模拟，不联网。

用户已确认：

| 议题 | 决策 |
|---|---|
| 尺寸 | 小号 + 中号（不做锁屏小组件） |
| 数据共享 | App Group 快照；模拟器验收，真机需在开发者账号下注册 App Group |
| 金额显示 | 默认显示金额，角标“模拟数据” |
| 点击 | 使用极小的白名单 URL scheme（Widget 点击只能打开 URL），无参数，只导航到已完成页面 |
| 方案 | 方案 A：App 写快照，Widget 扩展只读；不做内置演示数据、不做 iOS 17+ 交互 Widget |

**验收标准**

1. 工程新增 `ABankWidget` 扩展 target，App 能构建并嵌入扩展；小号、中号 Widget 出现在 Widget 库，显示名“模拟余额”。
2. 小号显示余额与“模拟数据”；中号显示余额、本月收入/支出与三个入口（扫一扫、转账、收支明细）。
3. App 内转账等操作改变余额后，Widget 刷新为新余额；从未打开过 App 时显示“打开 App 同步”占位，不显示伪造数据。
4. 点击小号进入我的账户；中号点击空白进入我的账户，三个入口分别进入扫一扫、转账、收支明细。
5. 未知链接、带多余路径或查询的链接被忽略，不跳转不崩溃。
6. 快照不含卡号、姓名等敏感信息，只含金额、月份与更新时间；不新增网络请求与相机权限。

## 2. 方案选择

- **A（采用）App Group 快照**：`FinanceLedgerStore.persist` 已在每次写入后发出变化通知；监听后重建快照并刷新 Widget，不改账本规则。
- B Widget 内置演示余额：不随操作变化，违背“读取共享模拟快照”，不采用。
- C App Intents/交互 Widget：需 iOS 17+，高于 15.6 部署目标，不采用。

## 3. 数据

### 3.1 快照（Foundation only，App 与 Widget 共用同一源文件）

```swift
struct WidgetSnapshot: Codable, Equatable {
    var balanceInCents: Int64
    var monthIncomeInCents: Int64
    var monthExpenseInCents: Int64
    var month: String          // yyyy-MM
    var updatedAt: String      // yyyy-MM-dd HH:mm:ss 北京时间
    static let groupID = "group.com.axdxa.AtlasBarKit.ABank"
    static let storageKey = "abank.widget.snapshot.v1"
    static func decode(_ data: Data?) -> WidgetSnapshot?        // nil 或损坏返回 nil
    func encoded() -> Data
}
```

`WidgetSnapshotStore`（同一文件）：`init(defaults: UserDefaults?)`，`save(_:)`、`load() -> WidgetSnapshot?`；默认使用 `UserDefaults(suiteName: WidgetSnapshot.groupID)`，取不到 suite 时 `load` 返回 nil、`save` 静默失败（不影响 App）。

### 3.2 构建

`FinanceLedgerStore.widgetSnapshot() -> WidgetSnapshot?` 放在 App 侧扩展（依赖账本，`ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Widget.swift`）：

- 余额：默认借记卡（`FinanceLedgerRecord.defaultAccountId`）的当前余额，转为分；找不到账户则不写快照。
- 本月收入/支出：`analysis(query: IncomeExpenseQuery()).summary`（默认当月、全部账户），转为分。
- `month` 取 `dates.currentMonth`，`updatedAt` 取 `dates.now` 格式化。

`WidgetSnapshotWriter`（App 侧）：

- `start()`：App 启动时写一次，并监听 `.financeLedgerDidChange`，每次重建快照并 `WidgetCenter.reloadAllTimelines()`。
- 重复内容不重复刷新（与上次快照相等则跳过）。
- 仅在 `canImport(WidgetKit)` 时调用刷新。

## 4. Widget 扩展

`ABankWidget` target：iOS 15.6+，`@main WidgetBundle`，一个 `StaticConfiguration`（kind `ABankBalanceWidget`，显示名“模拟余额”，描述“查看模拟余额与本月收支”），支持 `.systemSmall`、`.systemMedium`。

- Timeline：单条 entry，`policy: .never`（数据变化由 App 主动 `reloadAllTimelines`）；`placeholder` 用固定示例金额并加“模拟数据”。
- 小号：标题“借记卡余额”、金额（`¥1,234.56` 千分位，沿用 App 的格式）、角标“模拟数据”、更新时间（`HH:mm`）。
- 中号：左侧余额块；右侧本月收入/支出；底部三个入口按钮（扫一扫、转账、收支明细，SF Symbol + 文字）。
- 无快照：小号/中号都显示“打开 App 同步”，点击进入 App。
- 配色沿用 App 主色橙与白底；不使用私有字体或图片资源，iOS 15 兼容（不使用 iOS 16+ API，如 `containerBackground`；背景用 `.background` 修饰符）。

## 5. 点击与链接

- scheme：`abank`，仅识别 `abank://widget/<name>`，`name ∈ {account, scan, transfer, incomeExpense}`。
- `WidgetLink.route(for url: URL) -> AppRoute?`（Foundation only，`ABank/Core/Routing/WidgetLink.swift`，Widget 扩展也编译它以生成链接字符串 `WidgetLink.url(for:)`）：
  - `account` → `.myAccount`，`scan` → `.scan`，`transfer` → `.transfer(payerAccountID: nil)`，`incomeExpense` → `.incomeExpense(accountID: nil)`。
  - scheme/host 不符、路径不是单段、存在 query/fragment、name 未知 → nil。
- `Info.plist` 增加 `CFBundleURLTypes`（scheme `abank`）。
- `SceneDelegate`：冷启动从 `connectionOptions.urlContexts` 取第一个 URL，运行中经 `scene(_:openURLContexts:)`；路由有效时调用 `MainTabBarController.openFromShortcut`（与 M10a 同一入口，冷启动沿用 `pendingRoute`，取出即清空，只打开一次）。

## 6. 工程配置

- 使用 CocoaPods 自带 `xcodeproj` gem 的脚本新增 target（脚本一次性运行，不入库）：
  - 产品 `ABankWidget.appex`，bundle id `com.axdxa.AtlasBarKit.ABank.widget`，团队 `DX4MURAK7P`，部署目标 15.6，`SKIP_INSTALL=YES`。
  - 源码目录 `ABankWidget/`（同步组，与 App 一致）；共享文件 `WidgetSnapshot.swift`、`WidgetLink.swift` 通过 target membership 同时属于两个 target（放在 `ABank/Core/Widget/` 与 `ABank/Core/Routing/`，Widget target 通过文件引用加入 Sources）。
  - App target 新增“嵌入扩展”阶段与对扩展 target 的依赖。
  - 两个 target 的 entitlements：`ABank/ABank.entitlements`、`ABankWidget/ABankWidget.entitlements`，均含 `com.apple.security.application-groups = [group.com.axdxa.AtlasBarKit.ABank]`；Debug/Release 都指定。
- 工程变化后 `pod install`（Widget 不需要 Pods，Podfile 不为 Widget 增加 target），确认 `ABank.xcworkspace` 仍可构建。
- 命令行构建沿用 `CODE_SIGNING_ALLOWED=NO`：此时无 entitlements，App 与 Widget 不共享真实 App Group。模拟器验收改用带 ad-hoc 签名（`CODE_SIGN_IDENTITY=-` 并保留 entitlements）的构建；若仍无法共享，如实记为模拟器未验证并只做代码与单元检查。

## 7. 错误与边界

- 找不到默认账户、编码失败、App Group 不可用：不写快照、不崩溃，Widget 显示占位。
- 快照 JSON 损坏：`decode` 返回 nil，同占位。
- 负数余额或收支金额：照常格式化显示，不做特殊处理。
- 账本 `Double` 金额经 `TransferMoney.cents(from:)` 转分；余额转换失败则不写快照，收入/支出转换失败按 0 处理。

## 8. 测试

`scripts/check_entry.swift` 新增（`WidgetSnapshot.swift`、`WidgetLink.swift` 加入 `sources`）：

- `widgetSnapshotRoundTrip`：编码解码一致；nil、空数据、损坏数据解码为 nil；JSON 不含卡号、姓名字段（遍历键只含四个金额/时间字段与 month）。
- `widgetSnapshotStore`：使用独立 `UserDefaults(suiteName:)`，保存后读取一致；覆盖写入后为新值。
- `widgetSnapshotBuild`：用测试账本（种子）构建，余额等于默认借记卡余额，本月收支等于 `analysis` 汇总；转账后重建余额减少；无默认账户返回 nil。
- `widgetLinks`：4 个合法链接映射路由；`WidgetLink.url(for:)` 往返；未知 name、错误 scheme/host、多段路径、带 query 或 fragment、空路径均为 nil。
- `plistUrlScheme`：`Info.plist` 含 `abank` scheme。
- 构建检查：App 与扩展均 `BUILD SUCCEEDED`，`ABank.app/PlugIns/ABankWidget.appex` 存在。
- 模拟器验收（尽力）：Widget 出现在库中并显示余额；转账后刷新；点击入口跳转。受模拟器 App Group 与签名限制，无法验证的项如实记录。

## 9. 不做

- 锁屏小组件、大号、可配置（Intent）Widget、自动定时刷新。
- 真机 App Group 注册与真机验收（需用户在开发者账号下处理，交接中说明）。
- 任何网络请求或真实银行数据。
