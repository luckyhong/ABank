# M10b 模拟余额 Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增小号/中号“模拟余额”Widget：App 在账本变化后写 App Group 快照，Widget 只读快照，点击经白名单链接进入已完成页面。

**Architecture:** 纯 Foundation 的 `WidgetSnapshot`/`WidgetSnapshotStore`/`WidgetLink` 由 App 与 Widget 扩展共用同一源文件，检查脚本直接测试；App 侧 `FinanceLedgerStore.widgetSnapshot()` 构建快照，`WidgetSnapshotWriter` 监听账本变化后写入并刷新；`SceneDelegate` 把 `abank://widget/<name>` 交给 M10a 的 `MainTabBarController.openFromShortcut`。

**Tech Stack:** UIKit，WidgetKit + SwiftUI（iOS 15.6 兼容），App Group，CocoaPods 自带 `xcodeproj` gem（一次性脚本新增 target）。

**Spec:** `docs/superpowers/specs/2026-11-08-m10b-balance-widget-design.md`

## Global Constraints

- 本地模拟：不联网、不申请相机等权限；快照只含 `balanceInCents`、`monthIncomeInCents`、`monthExpenseInCents`、`month`、`updatedAt`，不含卡号、姓名。
- 部署目标 iOS 15.6：Widget 不使用 iOS 16+ API（如 `containerBackground`，背景用 `.background`）。
- App Group：`group.com.axdxa.AtlasBarKit.ABank`；快照键 `abank.widget.snapshot.v1`；链接仅 `abank://widget/<account|scan|transfer|incomeExpense>`，无 query/fragment/多段路径。
- Widget bundle id `com.axdxa.AtlasBarKit.ABank.widget`，团队 `DX4MURAK7P`，`SKIP_INSTALL=YES`。
- 共享源文件只 `import Foundation`；新增 App 侧共享文件加入 `scripts/check_banking_data.sh` 的 `sources`。
- 文案：显示名“模拟余额”，描述“查看模拟余额与本月收支”，角标“模拟数据”，无快照时“打开 App 同步”。
- 提交信息用中文 Conventional Commits；不推送、不合并。
- 构建命令（App，含扩展）：`export LANG=en_US.UTF-8; xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build > /private/tmp/m10b-build.log 2>&1; grep -E "BUILD (SUCC|FAIL)|error:" /private/tmp/m10b-build.log`

## Review Focus

1. 快照 JSON 损坏、空数据、旧版本键缺失时 Widget 必须显示占位，不崩溃——Task 1 `widgetSnapshotRoundTrip`。
2. 余额为负数或收支为 0 时格式化与显示正常——Task 4 格式化函数的检查（`WidgetFormat.money`）。
3. 链接带 query、fragment、多段路径、大小写不同的 scheme/host 必须忽略——Task 2 `widgetLinks`。
4. 冷启动被链接唤起只打开一次、运行中被链接唤起时模态页先关闭——Task 2 沿用 `openFromShortcut`，模拟器验证。
5. 连续多次账本变化（如一笔转账触发多次 persist）不应反复刷新 Widget——Task 3 `widgetWriterSkipsDuplicates`。

---

### Task 1: 快照模型、存储与构建

**Files:**
- Create: `ABank/Core/Widget/WidgetSnapshot.swift`（共享，只 import Foundation）
- Create: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Widget.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加上两个文件）
- Modify: `scripts/check_entry.swift`

**Interfaces:**
- Produces:
  - `struct WidgetSnapshot: Codable, Equatable { var balanceInCents: Int64; var monthIncomeInCents: Int64; var monthExpenseInCents: Int64; var month: String; var updatedAt: String; static let groupID: String; static let storageKey: String; static func decode(_ data: Data?) -> WidgetSnapshot?; func encoded() -> Data }`
  - `struct WidgetSnapshotStore { init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.groupID)); func save(_ snapshot: WidgetSnapshot); func load() -> WidgetSnapshot? }`
  - `extension FinanceLedgerStore { func widgetSnapshot() -> WidgetSnapshot? }`

- [ ] **Step 1: 写失败测试**（加入 `EntryChecks.main`）。账本取测试用的独立存储：参照 `scripts/check_loan.swift` 的 `withStore`（读它的写法，用同样的临时 `UserDefaults(suiteName:)` 建 `FinanceLedgerStore`）：

```swift
static func widgetSnapshotRoundTrip() {
    let s = WidgetSnapshot(balanceInCents: 151_966, monthIncomeInCents: 0, monthExpenseInCents: 12_300, month: "2026-11", updatedAt: "2026-11-08 20:00:00")
    precondition(WidgetSnapshot.decode(s.encoded()) == s)
    precondition(WidgetSnapshot.decode(nil) == nil && WidgetSnapshot.decode(Data()) == nil)
    precondition(WidgetSnapshot.decode(Data("{\"balanceInCents\":1}".utf8)) == nil)
    precondition(WidgetSnapshot.decode(Data("not json".utf8)) == nil)
    let keys = Set((try! JSONSerialization.jsonObject(with: s.encoded()) as! [String: Any]).keys)
    precondition(keys == ["balanceInCents", "monthIncomeInCents", "monthExpenseInCents", "month", "updatedAt"])
}

static func widgetSnapshotStore() {
    let name = "abank.test.widget.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let store = WidgetSnapshotStore(defaults: defaults)
    precondition(store.load() == nil)
    let a = WidgetSnapshot(balanceInCents: 100, monthIncomeInCents: 1, monthExpenseInCents: 2, month: "2026-11", updatedAt: "x")
    store.save(a); precondition(store.load() == a)
    var b = a; b.balanceInCents = 200
    store.save(b); precondition(store.load() == b)
    precondition(WidgetSnapshotStore(defaults: nil).load() == nil)
    WidgetSnapshotStore(defaults: nil).save(a)   // 不崩溃
}

@MainActor static func widgetSnapshotBuild() throws {
    // 种子账本：余额 1519.66（见 check_loan 的说明）
    let store = /* 测试用 FinanceLedgerStore，写法同 check_loan.withStore */
    let snap = store.widgetSnapshot()!
    let account = store.account(id: FinanceLedgerRecord.defaultAccountId)!
    precondition(snap.balanceInCents == TransferMoney.cents(from: account.balance)!)
    let flow = store.analysis(query: IncomeExpenseQuery()).summary
    precondition(snap.monthIncomeInCents == TransferMoney.cents(from: flow.income)! && snap.monthExpenseInCents == TransferMoney.cents(from: flow.expense)!)
    precondition(snap.month == store.dates.currentMonth && snap.updatedAt.count == 19)
    // 转账后余额减少
    _ = try store.submitTransfer(/* 参照 check_account_settings 中的转账调用，1 元 */)
    precondition(store.widgetSnapshot()!.balanceInCents == snap.balanceInCents - 100)
}
```
实现者先读 `scripts/check_loan.swift` 的 `withStore` 与 `scripts/check_account_settings.swift` 的转账调用，用相同方式构造；无默认账户的情形用只含其他账户的自定义账本断言返回 nil（写入方式见 `check_loan` 里篡改账本的用例）。

- [ ] **Step 2: 运行确认失败** Run: `zsh scripts/check_banking_data.sh` Expected: entry 组编译失败 `cannot find 'WidgetSnapshot' in scope`。
- [ ] **Step 3: 实现** `WidgetSnapshot`：`decode` 用 `JSONDecoder`，任何错误返回 nil；`encoded()` 用 `JSONEncoder`（`sortedKeys`）。`WidgetSnapshotStore`：`defaults` 为 nil 时 `load` 返回 nil、`save` 空操作。`widgetSnapshot()`：取默认账户（缺失返回 nil），余额 `TransferMoney.cents(from:)` 失败返回 nil；收支取 `analysis(query: IncomeExpenseQuery()).summary`，转换失败按 0；`month = dates.currentMonth`，`updatedAt = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")`（读 `BankingDateContext` 确认 `string(from:format:)` 的真实签名）。
- [ ] **Step 4: 运行确认通过** Run: `zsh scripts/check_banking_data.sh` Expected: 全部组通过，含 `Entry checks passed`。
- [ ] **Step 5: Commit** `git add ABank scripts && git commit -m "feat: 模拟余额 Widget 快照模型与构建"`

---

### Task 2: 白名单链接与 URL scheme

**Files:**
- Create: `ABank/Core/Routing/WidgetLink.swift`（共享，只 import Foundation）
- Modify: `ABank/Info.plist`（`CFBundleURLTypes`，scheme `abank`）
- Modify: `ABank/SceneDelegate.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加 `WidgetLink.swift`）、`scripts/check_entry.swift`

**Interfaces:**
- Consumes: `AppRoute`（`.myAccount`、`.scan`、`.transfer(payerAccountID:)`、`.incomeExpense(accountID:)`）；`MainTabBarController.openFromShortcut(_:)`（M10a）。
- Produces: `enum WidgetLink { enum Target: String, CaseIterable { case account, scan, transfer, incomeExpense }; static func url(for target: Target) -> URL; static func route(for url: URL) -> AppRoute? }`

- [ ] **Step 1: 写失败测试**
```swift
static func widgetLinks() {
    let expected: [(WidgetLink.Target, AppRoute)] = [
        (.account, .myAccount), (.scan, .scan),
        (.transfer, .transfer(payerAccountID: nil)), (.incomeExpense, .incomeExpense(accountID: nil))
    ]
    for (target, route) in expected {
        let url = WidgetLink.url(for: target)
        precondition(url.absoluteString == "abank://widget/\(target.rawValue)")
        precondition(WidgetLink.route(for: url) == route)
    }
    let bad = ["abank://widget/", "abank://widget", "abank://widget/unknown", "abank://widget/scan/extra",
               "abank://widget/scan?x=1", "abank://widget/scan#f", "ABANK://widget/scan", "abank://WIDGET/scan",
               "http://widget/scan", "abank://other/scan", "abank:///scan", "abank://widget/Scan"]
    for text in bad { precondition(URL(string: text).flatMap(WidgetLink.route(for:)) == nil, text) }
}

static func plistUrlScheme() {
    let plist = NSDictionary(contentsOfFile: "ABank/Info.plist")!
    let types = plist["CFBundleURLTypes"] as! [[String: Any]]
    let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
    precondition(schemes == ["abank"])
}
```
- [ ] **Step 2: 运行确认失败** Expected: `cannot find 'WidgetLink' in scope`。
- [ ] **Step 3: 实现**
  - `route(for:)`：用 `URLComponents`，要求 `scheme == "abank"`、`host == "widget"`（均区分大小写，所以大写写法被拒）、`query == nil`、`fragment == nil`、`path` 恰为 `/` + 一个已知 target 的 rawValue。
  - `Info.plist` 加 `CFBundleURLTypes`：一项，`CFBundleURLName` `com.axdxa.AtlasBarKit.ABank.widget`，`CFBundleURLSchemes` `["abank"]`。
  - `SceneDelegate`：冷启动 `connectionOptions.urlContexts.first?.url` 经 `WidgetLink.route` 得到路由，与快捷操作共用 `pendingRoute` 的取出即清空逻辑（若同时存在快捷操作，以快捷操作为准）；新增 `scene(_:openURLContexts:)`，有效路由调用 `tabBar.openFromShortcut`，无效忽略。
- [ ] **Step 4: 运行确认通过** Expected: `Entry checks passed`，全部组通过。
- [ ] **Step 5: 构建**（见 Global Constraints）Expected: `** BUILD SUCCEEDED **`
- [ ] **Step 6: Commit** `git commit -m "feat: Widget 白名单链接与 URL scheme"`

---

### Task 3: 快照写入器

**Files:**
- Create: `ABank/Core/Widget/WidgetSnapshotWriter.swift`（App 侧，可 import WidgetKit）
- Modify: `ABank/AppDelegate.swift`（启动时 `WidgetSnapshotWriter.shared.start()`）
- Modify: `scripts/check_banking_data.sh`（writer 依赖 WidgetKit，不加入 `sources`；把可测试逻辑放在共享文件，见下）
- Modify: `ABank/Core/Widget/WidgetSnapshot.swift`、`scripts/check_entry.swift`

**Interfaces:**
- Consumes: `FinanceLedgerStore.widgetSnapshot()`、`WidgetSnapshotStore`、`Notification.Name.financeLedgerDidChange`。
- Produces:
  - 共享文件新增 `struct WidgetSnapshotSync { init(store: WidgetSnapshotStore, reload: @escaping () -> Void); mutating func sync(_ snapshot: WidgetSnapshot?) }`：`snapshot` 为 nil 不写；与上次写入（含启动时已存的快照）相等则不写、不刷新；否则写入并调用 `reload`。
  - `final class WidgetSnapshotWriter { static let shared; func start() }`：启动时与每次 `.financeLedgerDidChange` 调用 `sync(FinanceLedgerStore.shared.widgetSnapshot())`，`reload` 为 `WidgetCenter.shared.reloadAllTimelines()`。

- [ ] **Step 1: 写失败测试**
```swift
static func widgetWriterSkipsDuplicates() {
    let name = "abank.test.widgetsync.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    var reloads = 0
    var sync = WidgetSnapshotSync(store: WidgetSnapshotStore(defaults: defaults), reload: { reloads += 1 })
    let a = WidgetSnapshot(balanceInCents: 1, monthIncomeInCents: 0, monthExpenseInCents: 0, month: "2026-11", updatedAt: "t1")
    sync.sync(nil); precondition(reloads == 0)
    sync.sync(a); precondition(reloads == 1)
    var sameButLaterTime = a; sameButLaterTime.updatedAt = "t2"
    sync.sync(sameButLaterTime); precondition(reloads == 1)          // 只有更新时间不同不算变化
    var changed = a; changed.balanceInCents = 2
    sync.sync(changed); precondition(reloads == 2)
    precondition(WidgetSnapshotStore(defaults: defaults).load()?.balanceInCents == 2)
    // 新实例读到已存快照，同内容不重复刷新
    var reloads2 = 0
    var restarted = WidgetSnapshotSync(store: WidgetSnapshotStore(defaults: defaults), reload: { reloads2 += 1 })
    restarted.sync(changed); precondition(reloads2 == 0)
}
```
- [ ] **Step 2: 运行确认失败** Expected: `cannot find 'WidgetSnapshotSync' in scope`。
- [ ] **Step 3: 实现** `WidgetSnapshotSync`：比较时忽略 `updatedAt`（内容比较用 balance/income/expense/month）；初始 `last` 从 `store.load()` 取。`WidgetSnapshotWriter` 在主线程用 `NotificationCenter` 观察并同步；`start()` 幂等（重复调用不重复注册）。`AppDelegate.didFinishLaunching` 调用 `start()`。
- [ ] **Step 4: 运行确认通过** Expected: 全部组通过。
- [ ] **Step 5: 构建** Expected: `** BUILD SUCCEEDED **`
- [ ] **Step 6: Commit** `git commit -m "feat: 账本变化后写入 Widget 快照并刷新"`

---

### Task 4: Widget 扩展 target 与界面

**Files:**
- Create: `ABankWidget/ABankWidget.swift`（`@main` Bundle + Provider + Entry）、`ABankWidget/WidgetViews.swift`（小号/中号视图）、`ABankWidget/Info.plist`（`NSExtension`，`com.apple.widgetkit-extension`）、`ABankWidget/ABankWidget.entitlements`、`ABank/ABank.entitlements`
- Create: `ABank/Core/Widget/WidgetFormat.swift`（共享，只 import Foundation）
- Modify: `ABank.xcodeproj/project.pbxproj`（经一次性 `xcodeproj` 脚本，脚本不入库）
- Modify: `scripts/check_banking_data.sh`（`sources` 加 `WidgetFormat.swift`）、`scripts/check_entry.swift`

**Interfaces:**
- Consumes: `WidgetSnapshot`、`WidgetSnapshotStore`、`WidgetLink`（共享源文件，同时加入 Widget target 的 Sources）。
- Produces: `enum WidgetFormat { static func money(_ cents: Int64) -> String; static func time(_ updatedAt: String) -> String }`：`money` 返回 `¥1,234.56`，负数 `-¥12.30`，0 为 `¥0.00`；`time` 取 `updatedAt` 的 `HH:mm`，格式不符返回 `--:--`。

- [ ] **Step 1: 写失败测试**
```swift
static func widgetFormat() {
    precondition(WidgetFormat.money(123_456) == "¥1,234.56")
    precondition(WidgetFormat.money(0) == "¥0.00" && WidgetFormat.money(5) == "¥0.05")
    precondition(WidgetFormat.money(-1_230) == "-¥12.30")
    precondition(WidgetFormat.money(100_000_000_00) == "¥100,000,000.00")
    precondition(WidgetFormat.time("2026-11-08 20:05:09") == "20:05" && WidgetFormat.time("") == "--:--" && WidgetFormat.time("x") == "--:--")
}
```
- [ ] **Step 2: 运行确认失败** Expected: `cannot find 'WidgetFormat' in scope`。
- [ ] **Step 3: 实现 `WidgetFormat`** 用整数运算拼接千分位，不用 `NumberFormatter` 的区域设置。
- [ ] **Step 4: 运行确认通过** Expected: 全部组通过。
- [ ] **Step 5: 新增 target** 写临时脚本（放在 `/private/tmp`，不入库）用 `xcodeproj` gem：新增 app extension target `ABankWidget`（bundle id `com.axdxa.AtlasBarKit.ABank.widget`，`DEVELOPMENT_TEAM=DX4MURAK7P`，`IPHONEOS_DEPLOYMENT_TARGET=15.6`，`SKIP_INSTALL=YES`，`INFOPLIST_FILE=ABankWidget/Info.plist`，`GENERATE_INFOPLIST_FILE=NO`，`SWIFT_VERSION=5.0`，Debug/Release 的 `CODE_SIGN_ENTITLEMENTS` 指向各自 entitlements）；`ABankWidget/` 用同步组（与现有 `ABank` 组一致）；把 `WidgetSnapshot.swift`、`WidgetLink.swift`、`WidgetFormat.swift` 文件引用加入 Widget Sources；App target 加对扩展的依赖和“Embed Foundation Extensions”（`PlugIns`，`dstSubfolderSpec=13`）阶段，并给 App 设置 `CODE_SIGN_ENTITLEMENTS=ABank/ABank.entitlements`。两个 entitlements 都含 `com.apple.security.application-groups`。注意：`ABank/` 是同步组，`ABank.entitlements` 与 Widget 共享的源文件不得再被 App 重复编译——为 `ABank.entitlements` 与 `ABankWidget` 目录添加同步组例外或确认其不被当作资源。随后 `pod install`（`export LANG=en_US.UTF-8`），确认 `git diff --stat` 里只有预期的 pbxproj/Pods 变化。
- [ ] **Step 6: 实现 Widget 界面** `ABankWidget.swift`：`StaticConfiguration(kind: "ABankBalanceWidget")`，`.configurationDisplayName("模拟余额")`、`.description("查看模拟余额与本月收支")`、`.supportedFamilies([.systemSmall, .systemMedium])`；Provider：`placeholder`/`getSnapshot` 用示例快照（余额 123456 分、收入 0、支出 12300 分），`getTimeline` 读 `WidgetSnapshotStore().load()` 返回单条 entry，`policy: .never`。`WidgetViews.swift`：小号——“借记卡余额”、`WidgetFormat.money`、角标“模拟数据”、`WidgetFormat.time`，整块 `.widgetURL(WidgetLink.url(for: .account))`；中号——左侧余额块，右侧“本月收入/支出”，底部三个 `Link`（扫一扫/转账/收支明细，SF Symbol `qrcode.viewfinder`/`arrow.left.arrow.right`/`list.bullet.rectangle`），空白处 `.widgetURL(account)`；无快照两种尺寸均显示“打开 App 同步”并 `.widgetURL(account)`；背景 `Color.white` 经 `.background`，主色橙 `Color(red: 1, green: 149/255, blue: 0)`。不使用 iOS 16+ API。
- [ ] **Step 7: 构建** 运行 Global Constraints 的构建命令。Expected: `** BUILD SUCCEEDED **`，且 `ls /private/tmp/ABank-ResourceBuild/Build/Products/Debug-iphonesimulator/ABank.app/PlugIns/ABankWidget.appex` 存在。
- [ ] **Step 8: 运行检查** `zsh scripts/check_banking_data.sh` Expected: 全部通过。
- [ ] **Step 9: Commit** `git add -A ABank ABankWidget ABank.xcodeproj Podfile.lock Pods scripts 2>/dev/null; git commit -m "feat: 模拟余额 Widget 扩展"`（只提交本任务产生的变化，提交前 `git status` 核对没有无关文件）

---

### Task 5: 模拟器验收与文档

**Files:**
- Modify: `docs/development-plan.md`（M10 行改为“已完成（M10a、M10b）”；新增“### M10b 实施记录（2026-11-08）”；写明真机需注册 App Group、M10 全部完成后的后续说明）
- Modify: `docs/continuity/tasks/m10b-widget.md`

- [ ] **Step 1: 验收构建与安装** 先用 Global Constraints 命令构建；再尝试带 entitlements 的模拟器构建：`xcodebuild ... CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ... build`（若报签名/描述文件错误，如实记录并退回 `CODE_SIGNING_ALLOWED=NO` 构建，此时只验证代码与单元检查）。
- [ ] **Step 2: 模拟器验证**（iPhone 16 Pro，截图存 `artifacts/abc-resources/verification/m10b-*.png`）：Widget 库中出现“模拟余额”小号/中号；添加后显示余额与“模拟数据”；在 App 内转账 1 元后 Widget 余额刷新；点击小号进入我的账户，中号三个入口分别进入扫一扫、转账、收支明细；未打开过 App 时显示“打开 App 同步”。无法在模拟器验证的项（尤其 App Group 共享）如实记为未验证。
- [ ] **Step 3: 更新文档** 分支、提交、检查与构建结果、截图清单、未验证项、真机 App Group 说明、视觉待截图校准。
- [ ] **Step 4: Commit** `git commit -m "docs: 记录 M10b 实施与验证结果"`
