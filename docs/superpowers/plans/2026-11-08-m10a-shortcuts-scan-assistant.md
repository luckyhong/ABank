# M10a 快捷操作、演示扫码与关键词助手 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增桌面快捷操作、演示扫码与本地关键词助手三个入口，全部只跳转已完成页面并统一经 `AppRouter`。

**Architecture:** 三个只依赖 Foundation 的解析器（`ScanCodeParser`、`AssistantEngine`、`QuickAction`）把输入转成 `AppRoute`/`FeatureID`，由检查脚本直接测试；页面（`ScanViewController`、`AssistantViewController`）只负责展示，跳转交给 `AppRouter`；`SceneDelegate` 把快捷操作交给 `MainTabBarController.openFromShortcut(_:)`。

**Tech Stack:** UIKit + SnapKit，Swift 5，iOS 15.6+；检查脚本 `zsh scripts/check_banking_data.sh`（swiftc 编译 `sources` + 单个 check 文件）。

**Spec:** `docs/superpowers/specs/2026-11-08-m10a-shortcuts-scan-assistant-design.md`

## Global Constraints

- 全部本地模拟：不联网、不调用相机/相册、不申请任何权限（`Info.plist` 不加相机描述）、不新增持久化。
- 只跳转已完成页面；所有跳转经 `AppRouter`（扫码“前往”用 `makeViewController(for:)` 替换栈中扫码页）。
- 收款码不携带金额；转账仍走原有交易权限、限额、余额与确认页；永不自动付款。
- 解析器文件只 `import Foundation`，并加入 `scripts/check_banking_data.sh` 的 `sources`。
- 文件夹为同步组，新文件无需改 pbxproj。
- 文案以规格为准；提交信息用中文 Conventional Commits。
- 构建命令：`export LANG=en_US.UTF-8; xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build > /private/tmp/m10a-build.log 2>&1; grep -E "BUILD (SUCC|FAIL)|error:" /private/tmp/m10a-build.log`

## Review Focus

1. 卡号带空格或全角数字（“6230 1234 5678”“６２３０１２”）发给助手，必须识别为敏感并不回显——测试见 Task 3 `assistantSensitive`。
2. 收款码账号用全角数字、姓名含 `|` 或 `=`、键重复——必须 `.unrecognized`——测试见 Task 1 `scanRejects`。
3. 快捷操作在其他 Tab 深层页面或有模态页（弹窗、分享面板、扫码结果卡片）时点击，应关闭模态、回到首页根页后只打开一次目标页——Task 5 模拟器步骤逐项验证。
4. 冷启动用快捷操作打开，目标页只推入一次（不因 `sceneDidBecomeActive` 等重复处理）——Task 5 `pendingRoute` 取出即清空，模拟器验证。
5. 识别中连点示例卡片或连点“前往”，只跳转一次——Task 2 识别期间禁用卡片、“前往”后立即禁用按钮。

---

### Task 1: 扫码解析与收款人转账路由

**Files:**
- Create: `ABank/Features/Scan/Models/ScanCode.swift`
- Create: `scripts/check_entry.swift`
- Modify: `ABank/Core/Routing/AppRoute.swift`（新增 `.transferToPayee`）
- Modify: `ABank/Core/Routing/AppRouter.swift`（穷举补全）
- Modify: `scripts/check_banking_data.sh`（`sources` 加 `ScanCode.swift`；循环加 `entry` → `scripts/check_entry.swift`）

**Interfaces:**
- Produces:
  - `AppRoute.transferToPayee(name: String, bankName: String, account: String)`
  - `enum ScanResult: Equatable { case payee(name:bankName:account:), branch(branchID:branchName:), bill(billAccountID:title:), unrecognized; var route: AppRoute? }`
  - `enum ScanCodeParser { static func parse(_ text: String) -> ScanResult }`
  - `enum ScanSample: CaseIterable { case payee, branch, bill, invalid; var title: String; var payload: String }`（标题：个人收款码、网点取号码、电费缴费码、无效码；payload 见规格 §4.1）

- [ ] **Step 1: 写失败测试** `scripts/check_entry.swift`，`@main struct EntryChecks`，`main()` 依次调用并最后 `print("Entry checks passed")`：

```swift
static func scanSamples() {
    precondition(ScanCodeParser.parse(ScanSample.payee.payload) == .payee(name: "欧梦瑶", bankName: "中国建设银行", account: "6217000000000593"))
    precondition(ScanCodeParser.parse(ScanSample.payee.payload).route == .transferToPayee(name: "欧梦瑶", bankName: "中国建设银行", account: "6217000000000593"))
    precondition(ScanCodeParser.parse(ScanSample.branch.payload) == .branch(branchID: "xa-fengdong", branchName: "西安沣东新城支行"))
    precondition(ScanCodeParser.parse(ScanSample.branch.payload).route == .takeTicket(branchID: "xa-fengdong"))
    precondition(ScanCodeParser.parse(ScanSample.bill.payload) == .bill(billAccountID: "bill.electric.home", title: "电费 · 家庭住宅"))
    precondition(ScanCodeParser.parse(ScanSample.bill.payload).route == .utilityBill(billAccountID: "bill.electric.home"))
    precondition(ScanCodeParser.parse(ScanSample.invalid.payload) == .unrecognized && ScanResult.unrecognized.route == nil)
    precondition(ScanCodeParser.parse("  " + ScanSample.branch.payload + "\n") != .unrecognized)
}

static func scanRejects() {
    let bad = [
        "", "ABANK|BRANCH|id=xa-fengdong", "ABANKDEMO|SHOP|id=1", "ABANKDEMO|BRANCH",
        "ABANKDEMO|BRANCH|id=", "ABANKDEMO|BRANCH|id=xa-fengdong|id=xa-gaoxin",
        "ABANKDEMO|BRANCH|id=nope", "ABANKDEMO|BRANCH|id=xa-self-dongguan",
        "ABANKDEMO|BILL|id=bill.nope", "ABANKDEMO|BILL|id=bill.gas.home|amount=1",
        "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=621700000000059",        // 15 位
        "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=62170000000005930000",   // 20 位
        "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217a00000000593",
        "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=６２１７000000000593",    // 全角数字
        "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217000000000593|amount=100",
        "ABANKDEMO|PAY|name=|bank=中国建设银行|acct=6217000000000593",
        "ABANKDEMO|PAY|name=欧=瑶|bank=中国建设银行|acct=6217000000000593",
        "ABANKDEMO|PAY|name=\(String(repeating: "欧", count: 21))|bank=中国建设银行|acct=6217000000000593",
        "ABANKDEMO|PAY|bank=中国建设银行|acct=6217000000000593"
    ]
    for text in bad { precondition(ScanCodeParser.parse(text) == .unrecognized, text) }
}
```

- [ ] **Step 2: 运行确认失败**
Run: `zsh scripts/check_banking_data.sh`
Expected: `entry` 组编译失败：`cannot find 'ScanCodeParser' in scope`（其余组照常通过）。

- [ ] **Step 3: 实现**
  - `AppRoute` 加 `case transferToPayee(name: String, bankName: String, account: String)`。
  - `AppRouter.makeViewController`：`TransferFormViewController(method: .account, initialDraft: TransferDraft(payerAccountID: ledger.load().accounts.first?.id ?? "", method: .account, recipientName: name, bankName: bankName, destination: account), store: ledger)`。
  - `ScanCode.swift`：去首尾空白 → 必须 `ABANKDEMO|` 开头 → 按 `|` 切分，类型取第 2 段 → 其余段各自恰含一个 `=`，键不重复、值非空 → 键集合必须等于该类型所需。账号用 `^[0-9]{16,19}$`（ASCII）；姓名 1–20 字符。`BRANCH` 用 `BranchCatalog.branch(id:)` 且 `kind == .full`；`BILL` 用 `PaymentCatalog.billAccount(id:)`，title 为 `"\(account.kind.title) · \(account.name)"`。

- [ ] **Step 4: 运行确认通过**
Run: `zsh scripts/check_banking_data.sh`
Expected: 全部组通过，末尾含 `Entry checks passed`。

- [ ] **Step 5: 构建**（见 Global Constraints）Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**
```bash
git add ABank/Features/Scan scripts/check_entry.swift scripts/check_banking_data.sh ABank/Core/Routing
git commit -m "feat: 演示扫码示例码解析与收款人转账路由"
```

---

### Task 2: 演示扫码页与“扫一扫”上线

**Files:**
- Create: `ABank/Features/Scan/ScanViewController.swift`
- Modify: `ABank/Core/Routing/AppRoute.swift`（`.scan`）、`AppRouter.swift`
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift:256-257`（`.scan` → `.available(.scan)`）
- Modify: `scripts/check_feature_catalog.swift`（已完成 33 → 34；`.scan` 可用断言）

**Interfaces:**
- Consumes: `ScanSample`、`ScanCodeParser.parse`、`ScanResult.route`（Task 1）；`AccountHolderName.masked(_:)`（已有）。
- Produces: `AppRoute.scan`；`ScanViewController()`（`hidesBottomBarWhenPushed = true`）。

- [ ] **Step 1: 写失败测试**（`check_feature_catalog.swift` `catalogIntegrity`）：
```swift
precondition(FeatureCatalog.all.filter(\.isAvailable).count == 34)
precondition(FeatureCatalog.descriptor(.scan).availability == .available(.scan))
```
- [ ] **Step 2: 运行确认失败** Run: `zsh scripts/check_banking_data.sh` Expected: feature 组编译失败 `type 'AppRoute' has no member 'scan'`。
- [ ] **Step 3: 实现** 路由与目录；`ScanViewController` 按规格 §4.2：
  - 背景黑色，导航栏透明白色返回键，标题“扫一扫”；顶部提示“演示扫码 · 不调用相机”。
  - 取景框 240×240 四角橙色角标，扫描线 `CABasicAnimation` 往复（`viewWillAppear` 开始、`viewWillDisappear` 移除）。
  - 4 张示例卡（`ScanSample.allCases`，accessibilityIdentifier `scan.sample.<case>`），点击后所有卡片禁用，取景框文字“识别中…”，0.8 秒后显示结果卡片。
  - 结果卡片（自建底部视图，不用系统 sheet，保证 iOS 15）：`payee` 显示“个人收款码”、“收款人 \(masked(name))”、“\(bankName) · 尾号 \(后4位)”；`branch` 显示“网点取号码”与网点名；`bill` 显示“缴费码”与 title；按钮“前往”（`scan.result.go`）“重新扫描”（`scan.result.retry`）；`unrecognized` 文案“无法识别该二维码，请扫描 ABank 演示码”，仅“重新扫描”。
  - “前往”：立即禁用按钮，`AppRouter.shared.makeViewController(for: route)`，在 `navigationController.viewControllers` 中用其替换 self 后 `setViewControllers(animated: true)`。“重新扫描”：收起卡片、恢复卡片可点。
- [ ] **Step 4: 运行确认通过** Run: `zsh scripts/check_banking_data.sh` Expected: 全部通过。
- [ ] **Step 5: 构建** Expected: `** BUILD SUCCEEDED **`
- [ ] **Step 6: Commit** `git commit -m "feat: 演示扫码页与扫一扫入口上线"`

---

### Task 3: 关键词助手引擎

**Files:**
- Create: `ABank/Features/Assistant/Models/AssistantEngine.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加该文件）
- Modify: `scripts/check_entry.swift`

**Interfaces:**
- Consumes: `FeatureCatalog.descriptor(_:).isAvailable`、`FeatureSearch.search(_:)`（已有）。
- Produces:
  - `struct AssistantReply: Equatable { let text: String; let features: [FeatureID]; let isSensitiveWarning: Bool }`
  - `enum AssistantEngine { static func reply(to input: String) -> AssistantReply?; static let quickQuestions: [String]; static let welcomeText: String }`
  - `quickQuestions == ["怎么转账", "查余额", "提前还款", "附近网点"]`；欢迎语、敏感提醒、搜索前缀、兜底文案逐字取规格 §5。

- [ ] **Step 1: 写失败测试**（加入 `EntryChecks.main`）：
```swift
static func first(_ s: String) -> FeatureID? { AssistantEngine.reply(to: s)?.features.first }

static func assistantIntents() {
    let cases: [(String, FeatureID)] = [
        ("怎么转账", .transfer), ("查余额", .myAccount), ("提前还款", .loan), ("附近网点", .branchQuery),
        ("交电费", .lifePayment), ("话费充值", .mobileRecharge), ("理财收益", .wealthProduct),
        ("积分怎么用", .benefits), ("网上支付", .accountPermissions), ("登录密码", .securityCenter),
        ("二维码", .scan), ("我的订单", .orders),
        ("　转账？　", .transfer), ("ＡＢＣ转账", .transfer)
    ]
    for (input, id) in cases { precondition(first(input) == id, input) }
}

static func assistantTieBreak() {
    precondition(first("转账余额") == .transfer)
    precondition(first("开通转账") == .accountPermissions)
}

static func assistantSearchFallback() {
    let r = AssistantEngine.reply(to: "电子回单")!
    precondition(r.features.first == .receipts && r.text == "为您找到以下功能：" && !r.isSensitiveWarning)
}

static func assistantFilters() {
    let inputs = AssistantEngine.quickQuestions + ["转账", "余额", "贷款", "网点", "缴费", "充值", "理财", "积分", "交易权限", "登录", "扫码", "订单", "信用卡", "存款"]
    for input in inputs {
        let r = AssistantEngine.reply(to: input)!
        precondition(r.features.count <= 3 && r.features.allSatisfy { FeatureCatalog.descriptor($0).isAvailable }, input)
    }
}

static func assistantSensitive() {
    for input in ["我的卡号 6230 1234 5678", "验证码123456", "６２３０１２"] {
        let r = AssistantEngine.reply(to: input)!
        precondition(r.isSensitiveWarning && r.features.isEmpty && !r.text.contains("123456") && !r.text.contains("6230"), input)
    }
    precondition(AssistantEngine.reply(to: "12345")?.isSensitiveWarning == false)
}

static func assistantFallback() {
    let r = AssistantEngine.reply(to: "今天天气怎么样")!
    precondition(r.text == "没找到相关内容，换个说法试试，或看看这些常用功能：" && r.features == [.transfer, .incomeExpense, .branchQuery])
    precondition(AssistantEngine.reply(to: "  \n ") == nil && AssistantEngine.reply(to: "？！") == nil)
}
```
- [ ] **Step 2: 运行确认失败** Expected: entry 组编译失败 `cannot find 'AssistantEngine' in scope`。
- [ ] **Step 3: 实现** 按规格 §5.1：规整（`applyingTransform(.fullwidthToHalfwidth, reverse: false)` → 去掉 `CharacterSet.punctuationCharacters ∪ .symbols ∪ .whitespacesAndNewlines` → 小写）；空返回 nil；`range(of: "[0-9]{6,}", options: .regularExpression)` 判敏感；意图表为 `private static let intents: [(answer: String, triggers: [String], features: [FeatureID])]`，顺序与规格表一致，每条回答一句话（如转账：“转账支持账号和手机号，可在转账页查看记录与限额。”）；得分 = 命中触发词字符数之和；功能过滤已完成后取前 3；意图无命中时 `FeatureSearch.search(input.trimmingCharacters(in: .whitespacesAndNewlines))` 过滤已完成取前 3，非空则返回搜索回复，否则兜底。若某意图过滤后无功能，仍返回其回答（无卡片）。
- [ ] **Step 4: 运行确认通过** Expected: `Entry checks passed`，全部组通过。
- [ ] **Step 5: Commit** `git commit -m "feat: 本地关键词助手匹配引擎"`

---

### Task 4: 在线助手页与客服入口

**Files:**
- Create: `ABank/Features/Assistant/AssistantViewController.swift`
- Create: `ABank/Features/Assistant/Views/AssistantMessageCell.swift`（气泡 + 功能卡片）
- Modify: `AppRoute.swift`（`.assistant`）、`AppRouter.swift`
- Modify: `FeatureCatalog.swift`（`FeatureID.assistant` 加在服务分类末尾 `scan` 之后；条目“在线助手”，`.service`，`icon: "headphones"`，keywords `["客服", "帮助", "助手", "咨询"]`，`.available(.assistant)`）
- Modify: `scripts/check_feature_catalog.swift`（70 → 71，34 → 35）
- Modify 客服入口：`HomeViewController.swift:255`、`FinanceViewController.swift:189`、`NewsViewController.swift:432`、`TransferViewController.swift:253`、`AccountDetailQueryViewController.swift:188`、`LoanDetailViewController.swift:211`

**Interfaces:**
- Consumes: `AssistantEngine.reply(to:)`、`quickQuestions`、`welcomeText`（Task 3）；`AppRouter.shared.open(feature:from:)`。
- Produces: `AppRoute.assistant`；`AssistantViewController()`；`FeatureID.assistant`。

- [ ] **Step 1: 写失败测试**（`catalogIntegrity`）：把 70 改为 71（两处）、34 改为 35，并加
```swift
precondition(FeatureCatalog.descriptor(.assistant).availability == .available(.assistant))
precondition(FeatureSearch.search("客服").first?.id == .assistant)
```
- [ ] **Step 2: 运行确认失败** Expected: feature 组编译失败 `type 'FeatureID' has no member 'assistant'`。
- [ ] **Step 3: 实现** 路由、目录；页面按规格 §5.2：
  - `UITableView`（无分隔线，`keyboardDismissMode = .interactive`），消息模型 `private struct Message { let isUser: Bool; let text: String; let features: [FeatureID] }` 仅存于数组。
  - 顶部小字“智能助手为本地演示，回答仅供参考”；首条助手消息 `welcomeText`，下附 4 个快捷标签（`assistant.quick.<index>`），点击即发送。
  - 用户气泡右侧 `.abankOrange` 白字；助手气泡左侧白底；功能卡片（图标取 descriptor 的 imageName/systemIcon + 标题 + chevron，`assistant.feature.<rawValue>`）点击 `AppRouter.shared.open(feature:from: self)`。
  - 底部输入栏（`assistant.input`、`assistant.send`）贴 `view.keyboardLayoutGuide`；发送：`reply(to:)` 为 nil 时不追加任何消息；否则追加用户消息（原文）与助手回复，清空输入，滚到底部。
  - 6 处客服回调改为 `AppRouter.shared.open(.assistant, from: self)`（Home 用已有 `router`）。
- [ ] **Step 4: 运行确认通过** Expected: 全部组通过。
- [ ] **Step 5: 构建** Expected: `** BUILD SUCCEEDED **`
- [ ] **Step 6: Commit** `git commit -m "feat: 在线助手页与客服入口"`

---

### Task 5: 桌面快捷操作

**Files:**
- Create: `ABank/Core/Routing/QuickAction.swift`
- Modify: `ABank/Info.plist`（`UIApplicationShortcutItems`）
- Modify: `ABank/SceneDelegate.swift`
- Modify: `ABank/Core/MainTabBarController.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加 `QuickAction.swift`）、`scripts/check_entry.swift`

**Interfaces:**
- Consumes: `AppRoute.scan`、`.assistant`（Task 2/4）。
- Produces:
  - `enum QuickAction { static func route(forType type: String) -> AppRoute? }`（type 与路由见规格 §3.3）
  - `MainTabBarController.openFromShortcut(_ route: AppRoute)`

- [ ] **Step 1: 写失败测试**
```swift
static func quickActions() {
    precondition(QuickAction.route(forType: "com.abank.shortcut.scan") == .scan)
    precondition(QuickAction.route(forType: "com.abank.shortcut.transfer") == .transfer(payerAccountID: nil))
    precondition(QuickAction.route(forType: "com.abank.shortcut.incomeExpense") == .incomeExpense(accountID: nil))
    precondition(QuickAction.route(forType: "com.abank.shortcut.assistant") == .assistant)
    precondition(QuickAction.route(forType: "") == nil && QuickAction.route(forType: "com.abank.shortcut.pay") == nil)
}
```
另断言 `Info.plist` 中的 4 个 type 与 `QuickAction` 一致：
```swift
let plist = NSDictionary(contentsOfFile: "ABank/Info.plist")!
let items = plist["UIApplicationShortcutItems"] as! [[String: Any]]
precondition(items.compactMap { $0["UIApplicationShortcutItemType"] as? String }.allSatisfy { QuickAction.route(forType: $0) != nil } && items.count == 4)
```
- [ ] **Step 2: 运行确认失败** Expected: entry 组编译失败 `cannot find 'QuickAction' in scope`。
- [ ] **Step 3: 实现**
  - `Info.plist`：4 项依次扫一扫、转账、收支明细、在线助手，每项 `UIApplicationShortcutItemType`、`UIApplicationShortcutItemTitle`、`UIApplicationShortcutItemIconSymbolName`（规格 §3.3）。
  - `MainTabBarController.openFromShortcut(_:)`：`selectedIndex = 0`；若 `presentedViewController` 存在先 `dismiss(animated: false)`；首页导航 `popToRootViewController(animated: false)`；`AppRouter.shared.open(route, from: 首页根页)`。
  - `SceneDelegate`：`private var pendingRoute: AppRoute?`；`willConnectTo` 取 `connectionOptions.shortcutItem` 的路由存入，`makeKeyAndVisible()` 后 `DispatchQueue.main.async` 取出、置 nil、调用 `openFromShortcut`；`windowScene(_:performActionFor:completionHandler:)` 直接处理并 `completionHandler(route != nil)`。
- [ ] **Step 4: 运行确认通过** Expected: `Entry checks passed`，全部组通过。
- [ ] **Step 5: 构建** Expected: `** BUILD SUCCEEDED **`
- [ ] **Step 6: Commit** `git commit -m "feat: 桌面快捷操作"`

---

### Task 6: 模拟器验收与文档

**Files:**
- Modify: `docs/development-plan.md`（M10 行改为“进行中（M10a 已完成，M10b 未开始）”；新增“### M10a 实施记录（2026-11-08）”与“#### 下一会话：M10b 模拟余额 Widget”）
- Modify: `docs/continuity/tasks/m10a-shortcuts.md`

- [ ] **Step 1: 模拟器验收**（iPhone 16 Pro，`xcrun simctl install` 后启动；截图存 `artifacts/abc-resources/verification/m10a-*.png`）：
  1. 首页“扫一扫”→ 扫码页；4 个示例码各自识别结果；收款码“前往”→ 转账表单预填收款人与账号、金额为空，返回回到首页；网点码→沣东新城支行取号；电费码→家庭住宅电费账单；无效码只能重新扫描。
  2. 首页、财富、资讯、转账、明细查询、贷款详情的客服 → 在线助手；4 个快捷标签各得到回答与卡片；输入“电子回单”得到搜索结果；输入“123456”得到安全提醒；点卡片打开对应页面。
  3. 全部功能搜索“客服”出现“在线助手”。
  4. 长按图标显示 4 个快捷操作（模拟器主屏长按）；从后台、冷启动各点一次；在“我的”Tab 深层页面打开分享面板时点击快捷操作，回到首页并只打开一次目标页（Review Focus 3、4）。
  无法在模拟器完成的项（如长按菜单未弹出）如实记为未验证。
- [ ] **Step 2: 更新文档**（分支、提交、检查与构建结果、截图清单、未验证项、视觉“待截图校准”）。
- [ ] **Step 3: Commit** `git commit -m "docs: 记录 M10a 实施与验证结果"`
