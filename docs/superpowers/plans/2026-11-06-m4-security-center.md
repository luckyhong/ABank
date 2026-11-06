# M4 安全中心 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本地可演示的安全中心：登录、转账、支付设置，登录设备列表、详情与移除，全局金额隐私，以及可编辑并在转账中生效的模拟限额。

**Architecture:** 新增仅依赖 Foundation 的 `SecuritySettings` 模型、`TransferLimitRules` 与 `SecuritySettingsStore`（UserDefaults JSON + 通知）。`FinanceLedgerStore` 改为通过闭包读取限额。页面放在 `Features/Security/`，复用 `TransferFlowViewController` 的分组卡片布局，经 `AppRoute`/`AppRouter` 打开。

**Tech Stack:** UIKit、SnapKit、Swift 5、iOS 15.6+；检查脚本用 `xcrun swiftc` 编译（`scripts/check_banking_data.sh`）。

**Spec:** `docs/superpowers/specs/2026-11-06-m4-security-center-design.md`

## Global Constraints

- 全部本地模拟数据；不新增网络请求；不使用 LocalAuthentication，不弹密码框。
- 不改变账本存储结构（`abank.financeLedger.record.v8`）。
- 设置持久化键：`abank.securitySettings.v1`。
- 默认值：单笔 5_000_000 分，日累计 20_000_000 分，`hidesAmounts=false`，`faceIDLoginEnabled=true`，`gestureLoginEnabled=false`，`smallPaymentWithoutPasswordEnabled=false`，`smallPaymentQuotaInCents=50_000`，免密额度只能是 20_000 / 50_000 / 100_000 分。
- 限额规则：单笔为 100…50_000_000 分，日累计为 100…100_000_000 分，单笔 ≤ 日累计。输入最多两位小数，统一用 `TransferMoney.parse`。
- 文案：
  - 限额错误：“单笔限额需在 1 元至 50 万元之间”、“日累计限额需在 1 元至 100 万元之间”、“单笔限额不能高于日累计限额”、“请输入正确金额”。
  - 保存失败：“保存失败，请稍后重试”。
  - 限额保存成功：“限额已更新”。
  - 设备移除成功：“已移除”。
  - 移除确认：“移除后该设备需重新验证才能登录”。
  - 本机：“当前使用的设备不可移除”。
  - 演示声明：“演示设置，不做真实验证”。
  - 设备不存在：“设备不存在或已移除”。
- 页面继承 `BaseViewController`（经 `TransferFlowViewController`），使用标准导航栏；外观只改 `navigationItem`，不碰共享 `navigationBar`。
- 新素材放 `ABank/Assets.xcassets/ABCImported/Security/`，96px 单图只放 3x 槽位。
- 不提交、不推送，除非用户要求；Conventional Commits 中文说明。

## Review Focus

1. 当日已转金额高于新的日累计限额：保存允许，此后转账提示 `dailyLimit`，并且“今日已转”正确显示；由 Task 2 的检查覆盖。
2. 写入失败时开关回弹、限额页停留：Store 不更新内存、不发通知（Task 1 检查）；界面回读 Store（Task 4/5 代码）。
3. 设置 JSON 损坏或缺字段：使用默认值，原字节不被覆盖直到下次成功保存（Task 1 检查）。
4. 在一页切换隐私后返回另一页：页面在 `viewWillAppear` 和通知中都重新读取（Task 7），由模拟器验证。
5. 设备详情传入已移除或不存在的 ID：显示空态，不崩溃（Task 6 检查 `device(id:)` 返回 nil）。

---

### Task 1: 安全设置模型、规则与 Store

**Files:**
- Create: `ABank/Features/Security/Models/SecuritySettings.swift`（仅 Foundation）
- Create: `ABank/Features/Security/SecuritySettingsStore.swift`（仅 Foundation）
- Create: `scripts/check_security_settings.swift`
- Modify: `scripts/check_banking_data.sh`（`sources` 加入上述两个文件；循环加入 `security` → `scripts/check_security_settings.swift`）

**Interfaces:**
- Produces:
  - `nonisolated struct SecuritySettings: Codable, Equatable`，字段见 Global Constraints，外加 `removedDeviceIDs: [String]`。
    - `static let default`
    - 自定义 `init(from:)`，缺失字段取默认值。
    - `var transferLimits: TransferLimits`
  - `nonisolated enum TransferLimitError: LocalizedError, Equatable { case invalidAmount, perTransferOutOfRange, dailyOutOfRange, perTransferAboveDaily }`，`errorDescription` 为上面四条文案。
  - `nonisolated enum TransferLimitRules`：
    - `static func validate(perTransfer: Int64, daily: Int64) throws`
    - `static func parse(_ text: String) throws -> Int64`：`TransferMoney.parse` 失败或结果 ≤ 0 时抛 `.invalidAmount`。
  - `nonisolated struct LoginDevice: Equatable { id, name, model, system: String; firstLogin, lastLogin: Date; city: String; isCurrent: Bool }`
    - `static func seed(dates: BankingDateContext) -> [LoginDevice]`
    - 种子：`current-iphone` 本机 iPhone 16 Pro / iOS 18.3 / 北京，最近登录为 now；`ipad-air` iPad Air / iPadOS 17.5 / 上海，3 天前；`iphone-12` iPhone 12 / iOS 16.7 / 广州，40 天前。
    - 首次登录分别为 120 / 60 / 400 天前。
    - 偏离 spec 的说明：设备种子放在模型文件而非 `MockDataProvider`，以便脚本测试。
  - `nonisolated enum SecuritySettingsError: Error, Equatable { case persistence, deviceNotRemovable, deviceNotFound }`
  - `final class SecuritySettingsStore`：
    - 静态成员：
      - `static let shared`
      - `static let storageKey = "abank.securitySettings.v1"`
      - `static let didChangeNotification = Notification.Name("ABank.securitySettingsDidChange")`
    - 初始化：`init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default, dates: BankingDateContext = .system, dataWriter: ((Data) throws -> Void)? = nil)`
    - 属性：
      - `private(set) var settings: SecuritySettings`
      - `var transferLimits: TransferLimits`
      - `var hidesAmounts: Bool`
      - `var devices: [LoginDevice]`（种子减去已移除）
    - 方法：
      - `func device(id: String) -> LoginDevice?`
      - `func setTransferLimits(perTransfer: Int64, daily: Int64) throws`：抛 `TransferLimitError` 或 `SecuritySettingsError.persistence`。
      - `@discardableResult func setHidesAmounts(_: Bool) -> Bool`
      - `@discardableResult func setFaceIDLogin(_: Bool) -> Bool`
      - `@discardableResult func setGestureLogin(_: Bool) -> Bool`
      - `@discardableResult func setSmallPayment(enabled: Bool, quotaInCents: Int64) -> Bool`：额度不在三档内时返回 false。
      - `func removeDevice(id: String) throws`
      - `var enabledProtectionCount: Int`：faceID + gesture + hidesAmounts + (单笔 < 默认 或 日累计 < 默认 ? 1 : 0)。
    - 所有修改只在写入成功后更新内存并在注入的通知中心发通知。值未变化时不写入、不发通知、返回 true。

- [ ] **Step 1: 写检查脚本** `scripts/check_security_settings.swift`。`@main struct SecuritySettingsChecks`，用 `UserDefaults(suiteName:)` 临时套件。每个函数用 `precondition`：
  - `defaults()`：新 Store 的 `transferLimits == (5_000_000, 20_000_000)`；`!hidesAmounts`；`devices.map(\.id) == ["current-iphone","ipad-air","iphone-12"]`；`enabledProtectionCount == 1`。
  - `limitRules()`：
    - `validate(100, 100)` 通过；`validate(50_000_000, 100_000_000)` 通过。
    - `validate(99, 1000)` → `.perTransferOutOfRange`；`validate(50_000_001, 100_000_000)` → `.perTransferOutOfRange`。
    - `validate(100, 100_000_001)` → `.dailyOutOfRange`；`validate(2000, 1000)` → `.perTransferAboveDaily`。
    - `parse("1.234")`、`parse("0")`、`parse("abc")` → `.invalidAmount`；`parse("0.5") == 50`。
  - `roundTrip()`：`setTransferLimits(1_000_000, 3_000_000)`、`setHidesAmounts(true)`、`removeDevice("ipad-air")` 后新建 Store 读回相同值，`devices.count == 2`。
  - `corruptAndMissingFields()`：
    - 写入 `Data("{".utf8)` → Store 为默认值，且 `defaults.data(forKey:)` 仍等于原字节。
    - 写入只含 `{"hidesAmounts":true}` 的 JSON → `hidesAmounts == true`，其余为默认值。
  - `writeFailure()`：`dataWriter` 抛错。`setHidesAmounts(true) == false` 且值不变、未收到通知；`setTransferLimits` 抛 `SecuritySettingsError.persistence` 且限额不变。
  - `devicesRules()`：`removeDevice("current-iphone")` 抛 `.deviceNotRemovable`；`removeDevice("nope")` 抛 `.deviceNotFound`；移除后 `device(id: "ipad-air") == nil`。
  - `notifications()`：`setHidesAmounts(true)` 恰好发 1 次通知；再次设为 true 发 0 次。
  - `smallPayment()`：`setSmallPayment(enabled: true, quotaInCents: 30_000) == false`；`quotaInCents: 100_000` 返回 true。
  - 结束打印 `Security settings checks passed`。
- [ ] **Step 2: 运行** `zsh scripts/check_banking_data.sh`。预期在 security 编译阶段失败（找不到 `SecuritySettingsStore`）。
- [ ] **Step 3: 实现**上述两个文件。持久化用 `JSONEncoder`，写入走 `dataWriter ?? { defaults.set($0, forKey: key) }`；`BankingDateContext.date(byAddingDays:)` 不存在时用 `Calendar` 计算。
- [ ] **Step 4: 运行** `zsh scripts/check_banking_data.sh`。预期全部通过，输出包含 `Security settings checks passed`。
- [ ] **Step 5: 提交** `feat: 新增安全设置模型与本地存储`

### Task 2: 账本读取可编辑限额

**Files:**
- Modify: `ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift:22-31,131-139`
- Modify: `scripts/check_security_settings.swift`（新增 `ledgerUsesLiveLimits()`）

**Interfaces:**
- Consumes: `SecuritySettingsStore.transferLimits`、`setTransferLimits`
- Produces:
  - `FinanceLedgerStore.init(defaults:dates:transferLimitsProvider: @escaping () -> TransferLimits = { SecuritySettingsStore.shared.transferLimits }, dataWriter:simulationSucceeds:)`
  - `var transferLimits: TransferLimits { transferLimitsProvider() }`（只读）
  - `func transferredTodayInCents() -> Int64`：今日成功转账合计；溢出时返回 `Int64.max`。`validateTransfer` 复用同一计算。

- [ ] **Step 1: 写检查** `ledgerUsesLiveLimits()`：
  - 准备：临时套件建 `SecuritySettingsStore`，账本用 `transferLimitsProvider: { security.transferLimits }`。草稿与 `check_transfer_data.swift` 中可通过的 1000 元草稿相同，`validateTransfer` 通过。
  - `setTransferLimits(50_000, 20_000_000)` 后 `validateTransfer` 抛 `TransferError.singleLimit`。
  - 恢复后 `submitTransfer` 一笔 1000 元，`transferredTodayInCents() == 100_000`。
  - `setTransferLimits(100, 100)`（低于已转）保存成功，此后 `validateTransfer` 抛 `.singleLimit`。
  - `setTransferLimits(5_000_000, 100_000)` 后抛 `.dailyLimit`。
  - 恢复默认后通过。
- [ ] **Step 2: 运行** `zsh scripts/check_banking_data.sh`。预期编译失败（无 `transferLimitsProvider` 参数）。
- [ ] **Step 3: 实现**：
  - `let transferLimits` → 闭包属性。
  - 抽出今日累计函数。
  - 全仓 `grep -rn "transferLimits:" ABank scripts` 修正调用方（预期无）。
- [ ] **Step 4: 运行** `zsh scripts/check_banking_data.sh`，全部通过。
- [ ] **Step 5: 提交** `feat: 转账校验读取可编辑限额`

### Task 3: 安全中心素材导入

**Files:**
- Create: `scripts/import_security_assets.py`（以 `scripts/import_common_ui_assets.py` 为模板）
- Create: `ABank/Assets.xcassets/ABCImported/Security/`（`Contents.json` + 5 个 imageset）
- Create: `docs/abc-security-resource-manifest.json`

**Interfaces:**
- Produces 素材名：
  - `abc_security_center` ← `safecenter_home_700_native500.png`
  - `abc_security_login` ← `safecenter_login_setting_700_native500.png`
  - `abc_security_transfer` ← `safecenter_trans_setting_700_native500.png`
  - `abc_security_payment` ← `safecenter_pay_setting_700_native500.png`
  - `abc_security_devices` ← `safecenter_trusted_device_1100_native500.png`
  - 来源目录 `artifacts/abc-resources/images/`；渲染 original；imageset 只填 `"scale":"3x"`。

- [ ] **Step 1:** `python3 -I scripts/import_security_assets.py`。预期打印 5 行带 SHA-256 的映射，清单中 5 条与源文件哈希一致。
- [ ] **Step 2:** 用 `python3 -I` 复算目标文件哈希，与清单对比。预期全部一致；用 `sips -g pixelWidth` 确认 96。
- [ ] **Step 3: 提交** `feat: 导入安全中心图标资源`

### Task 4: 安全中心、登录设置、支付设置页与路由

**Files:**
- Create: `ABank/Features/Security/Views/SecurityRowViews.swift`
- Create: `ABank/Features/Security/SecurityCenterViewController.swift`
- Create: `ABank/Features/Security/LoginSettingsViewController.swift`
- Create: `ABank/Features/Security/PaymentSettingsViewController.swift`
- Modify: `ABank/Core/Routing/AppRoute.swift`、`ABank/Core/Routing/AppRouter.swift`
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift:244-249`
- Modify: `scripts/check_feature_catalog.swift`

**Interfaces:**
- Consumes: Task 1 的 Store API，Task 3 的素材名
- Produces:
  - `AppRoute` 新 case：`.securityCenter`、`.loginSettings`、`.paymentSettings`、`.loginDevices`、`.loginDeviceDetail(deviceID: String)`。后两个在 Task 6 才有页面；本任务路由暂时返回 `ComingSoonViewController(featureID: .loginDevices)`，Task 6 替换。
  - 视图组件：
    - `SecurityNavigationRow(title:, imageName:, fallback:, detail: String?, id:)`：`onTap: (() -> Void)?`、`func setDetail(_:)`。
    - `SecuritySwitchRow(title:, subtitle: String?, id:)`：`onChange: ((Bool) -> Void)?`、`func setOn(_:animated:)`。
    - 行高 52，左右 16。图标 24pt 走 `UIImage.abankAsset`，开关 `onTintColor = .abankPrimary`。
  - 三个 VC 都继承 `TransferFlowViewController`，`hidesBottomBarWhenPushed = true`，实现 `RouteHosting`，注入 `store: SecuritySettingsStore = .shared`、`router: AppRouting = AppRouter.shared`。

- [ ] **Step 1: 改目录检查**：
  - `FeatureCatalog.all.filter(\.isAvailable).count == 18`。
  - `descriptor(.securityCenter).availability == .available(.securityCenter)`；`.loginSettings`、`.paymentSettings` 同理。
  - `.loginDevices` 仍为 planned（Task 6 改）。
  - 运行 `zsh scripts/check_banking_data.sh`，预期 feature 检查失败。
- [ ] **Step 2: 实现路由与目录**。三项改为 `.available`；`AppRouter.makeViewController` 补全所有新 case（禁止 default）。
- [ ] **Step 3: 实现页面**：
  - **安全中心**：顶部白卡片，左侧 `abc_security_center` 40pt，标题“已开启 N 项保护”，副标题“本机模拟数据”。
    - 分组“账户安全”：登录设置、转账设置（`.transferLimits`）、支付设置、登录设备（detail 为“N 台”）。
    - 分组“隐私”：隐藏金额开关。
    - 收到 `didChangeNotification` 和 `viewWillAppear` 时刷新计数、台数与开关。
  - **登录设置**：两个开关，底部 `addNotice("演示设置，不做真实验证")`。
  - **支付设置**：免密开关；开启后显示三档单选行（200/500/1000 元，选中显示 `checkmark`）。
  - 所有开关写入失败时 `setOn(旧值)` 并 `showToast("保存失败，请稍后重试")`。
  - 各控件设置 `accessibilityIdentifier`（如 `security.hideAmounts`）。
- [ ] **Step 4: 运行**检查脚本并构建（开发计划的 `xcodebuild` 命令，输出到 `/private/tmp/m4-build.log`）。预期两者都通过。
- [ ] **Step 5: 提交** `feat: 新增安全中心、登录设置与支付设置页`

### Task 5: 转账设置与修改限额

**Files:**
- Create: `ABank/Features/Security/TransferSettingsViewController.swift`
- Create: `ABank/Features/Security/TransferLimitEditViewController.swift`
- Modify: `ABank/Features/Transfer/TransferRecordsViewController.swift:101-120`（删除 `TransferLimitsViewController`）
- Modify: `ABank/Core/Routing/AppRouter.swift`（`.transferLimits` → `TransferSettingsViewController(store: ledger)`）

**Interfaces:**
- Consumes: `SecuritySettingsStore.setTransferLimits`、`TransferLimitRules.parse/validate`、`FinanceLedgerStore.transferredTodayInCents()`
- Produces: `TransferSettingsViewController(ledger: FinanceLedgerStore = .shared, security: SecuritySettingsStore = .shared)`、`TransferLimitEditViewController(security:)`

- [ ] **Step 1: 实现转账设置页**（`hostedRoute = .transferLimits`，标题“转账设置”）：
  - 行：单笔限额 / 日累计限额（`SecurityNavigationRow`，detail 为 `"¥ " + TransferMoney.text(...)`，点击 push 编辑页），今日已转（`TransferInfoRow`）。
  - 底部 notice“金额和限额在确认前及提交时均会校验”。
  - `viewWillAppear` 与通知时刷新。
- [ ] **Step 2: 实现修改限额页**（标题“修改限额”）：
  - 两个 `TransferInputRow`（`.decimalPad`），预填 `TransferMoney.text`。
  - 每次编辑先对两个框调用 `TransferLimitRules.parse`，再调用 `validate`；第一条错误显示在下方红色 `abankError` 标签中，“保存”按钮 `isEnabled = false`。
  - 保存时 `setTransferLimits`。成功则 `showToast("限额已更新")` 并 pop；`SecuritySettingsError.persistence` 时 toast“保存失败，请稍后重试”并留在页面。
  - 键盘由 `TransferFlowViewController` 的 `keyboardLayoutGuide` 约束避让。
- [ ] **Step 3: 构建并运行检查脚本**，预期通过；`grep -rn TransferLimitsViewController ABank` 无结果。
- [ ] **Step 4: 提交** `feat: 转账设置支持修改限额`

### Task 6: 登录设备列表与详情

**Files:**
- Create: `ABank/Features/Security/LoginDevicesViewController.swift`
- Create: `ABank/Features/Security/LoginDeviceDetailViewController.swift`
- Modify: `AppRouter.swift`（替换 Task 4 的占位）、`FeatureCatalog.swift`（`.loginDevices` → `.available(.loginDevices)`）、`scripts/check_feature_catalog.swift`（可用数 19，`securityStage` 删除后也不再引用）

**Interfaces:**
- Consumes: `SecuritySettingsStore.devices/device(id:)/removeDevice(id:)`、`AppRoute.loginDeviceDetail(deviceID:)`

- [ ] **Step 1:** 更新目录检查（19 项可用，`.loginDevices` 可用），运行脚本，预期失败。
- [ ] **Step 2: 实现列表页**（标题“登录设备”）：
  - 每行：`abc_security_devices` 图标，名称 + “本机”标签（`abankPrimary` 描边小标签），副标题“最近登录 yyyy-MM-dd HH:mm · 城市”。
  - 点击打开 `.loginDeviceDetail`。
  - 只剩本机时显示 notice“没有其他登录设备”。
  - 刷新时机同上。
- [ ] **Step 3: 实现详情页**（标题“设备详情”）：
  - `TransferInfoRow` 显示型号、系统、首次登录、最近登录、登录城市。
  - 非本机时显示 `addButton("移除此设备", id: "device.remove", primary: false)`，用 `UIAlertController` 确认（取消 / 移除，后者 `.destructive`）。成功后 pop 并 toast“已移除”，失败时 toast“保存失败，请稍后重试”。
  - 本机显示 notice“当前使用的设备不可移除”。
  - `device(id:)` 为 nil 时只显示 notice“设备不存在或已移除”。
- [ ] **Step 4: 运行脚本并构建**，预期通过。
- [ ] **Step 5: 提交** `feat: 新增登录设备列表与详情`

### Task 7: 全局金额隐私

**Files:**
- Modify: `ABank/Features/Mine/Views/MineAssetLiabilityCardView.swift`、`MineMonthlyFlowCardView.swift`（删除本地 `isAmountVisible`，新增 `func setAmountVisible(_ visible: Bool)` 转给 header，`onEyeTapped` 只上报）
- Modify: `ABank/Features/Mine/MineViewController.swift`（眼睛回调 → `security.setHidesAmounts(!security.hidesAmounts)`；监听通知并在 `viewWillAppear` 时调用 `applyAmountVisibility()`）
- Modify: `ABank/Features/Mine/MyLoan/MyLoanViewController.swift:12,97`、`MyLoan/Views/MyLoanSummaryView.swift`（同样改为由 VC 驱动）
- 不改：`DebitCardDetailInfoCardView`（卡号眼睛）

**Interfaces:**
- Consumes: `SecuritySettingsStore.hidesAmounts/setHidesAmounts`、`didChangeNotification`
- Produces: `MineViewController.init` 与 `MyLoanViewController.init` 新增可注入参数 `security: SecuritySettingsStore = .shared`

- [ ] **Step 1: 实现**：
  - 所有眼睛的显示状态 = `!security.hidesAmounts`。
  - 写入失败时 toast“保存失败，请稍后重试”，界面保持原状态。
  - `grep -rn "isAmountVisible = true" ABank/Features/Mine` 预期无结果。
- [ ] **Step 2: 构建并运行脚本**，预期通过。
- [ ] **Step 3: 提交** `feat: 金额隐私改为全局同步`

### Task 8: 模拟器验收与交接

**Files:**
- Modify: `docs/development-plan.md`（M4 状态与 M4 实施记录、下一会话 M5）、`docs/continuity/tasks/m4-security-center.md`
- 临时 QA 钩子：如需直达页面，按 UI 走查的做法临时加入，完成后删除，并用 `grep -rn UIQA ABank` 确认。

- [ ] **Step 1:** 先 `xcrun simctl list devices booted` 确认设备，再安装构建产物。逐项验证 spec §6 模拟器清单，截图存 `artifacts/abc-resources/verification/m4-*.png`：
  - 入口
  - 限额改小后被拦截，改回后转账成功
  - 重启后限额、开关与设备保持
  - 隐私三处同步，借记卡卡号眼睛不受影响
  - 设备移除；本机无移除按钮
  - 键盘不遮挡
- [ ] **Step 2:** 依次运行 `zsh scripts/check_banking_data.sh`、正常构建、`git diff --check`，预期全部通过。最后把模拟器上的设置恢复默认（重置限额、开关，或删除 `abank.securitySettings.v1` 后重启）。
- [ ] **Step 3:** 更新开发计划和任务记录，写明验证结果、未验证项（320pt、无原版截图校准）和下一步。
- [ ] **Step 4: 提交** `docs: 记录 M4 安全中心实施与验证结果`
