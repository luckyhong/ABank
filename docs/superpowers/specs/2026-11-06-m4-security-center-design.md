# M4 安全中心设计

日期：2026-11-06。基线：`main@ef46672`，分支 `feat/m4-security-center`。对应 [开发计划](../../development-plan.md) 阶段 M4。

## 1. 目标与已确认决策

**目标**：把安全中心从“即将上线”占位变成可演示的本地模块，包括登录、转账、支付设置，登录设备的列表、详情与移除，全局金额隐私，以及可编辑的模拟转账限额。

用户已确认：

| 议题 | 决策 |
|---|---|
| 设置深度 | 只做演示开关和少量联动。开关可切换并持久化；只有影响已有功能的设置才联动：金额隐私全局生效、限额可编辑并在确认和提交时校验、移除设备后列表更新。面容、手势、免密支付只展示状态，不弹任何验证 |
| 金额隐私 | 全局只有一个状态。安全中心的“隐藏金额”开关与各页面的眼睛按钮读写同一持久化状态，任一处切换其余同步，重启后保持 |
| 方案 | 新增 `SecuritySettingsStore` 统一管理；账本通过闭包读取当前限额（见 §2） |
| 视觉参考 | 无原版截图，按现有设计系统设计，交接中标注“待截图校准” |

**验收标准**

1. “我的”安全中心卡片标题、全部功能目录、搜索结果都能进入安全中心；四个子入口进入对应页面。M4 目录项由“待上线”改为已完成。
2. 转账设置中修改单笔或日累计限额后立即生效：转账确认前校验与 `submitTransfer` 均使用新值，超限文案正确；重启后保留。
3. 限额输入不合法时显示行内提示，保存按钮不可用；保存失败时保留旧值并提示。
4. 任一金额眼睛按钮或“隐藏金额”开关切换后，“我的”（资产负债、月度收支）与我的贷款同步显示或隐藏金额；重启后保持。借记卡详情的卡号眼睛不受影响。
5. 登录设备可查看详情并移除（需确认）；“本机”不可移除；移除结果重启后保持。
6. 登录设置、支付设置的开关可切换并持久化，页面注明“演示设置，不做真实验证”。
7. 数据检查（新增安全设置检查）、正常构建、模拟器验收全部通过；不新增网络请求，不改变账本存储结构。

**不在本阶段范围**：真实身份验证（LocalAuthentication、密码框）；修改登录密码/手势图案的流程；默认付款账户；账户锁定、手机管家、安全工具等其余安全中心功能（目录中保留为待上线或不新增）；对首页、资产负债页等其余金额文案做隐私改造（见 §4.3 的覆盖范围）。

## 2. 方案选择

采用 **独立 `SecuritySettingsStore` + 账本闭包读取限额**。

- 备选 B：把限额写入账本根记录（`FinanceLedgerRecord`）。数据和转账记录放在一起，但需改变 `v8` 存储结构并处理兼容解码，收益有限、风险较大。
- 备选 C：每项设置单独一个 Store。状态分散，页面需要监听多个通知。

`FinanceLedgerStore` 现有 `let transferLimits: TransferLimits` 改为 `transferLimitsProvider: () -> TransferLimits`，默认读取 `SecuritySettingsStore.shared.transferLimits`；对外仍提供只读计算属性 `transferLimits`，调用方不变。校验逻辑每次调用时读取一次限额，确认前校验和提交校验都会拿到最新值。检查脚本注入固定闭包。

## 3. 数据模型与 Store

新目录 `ABank/Features/Security/`：

```
Security/
  Models/SecuritySettings.swift      // 设置模型、设备模型、限额规则（仅依赖 Foundation）
  SecuritySettingsStore.swift        // 持久化与通知
  SecurityCenterViewController.swift
  LoginSettingsViewController.swift
  TransferSettingsViewController.swift   // 取代 TransferLimitsViewController
  TransferLimitEditViewController.swift
  PaymentSettingsViewController.swift
  LoginDevicesViewController.swift
  LoginDeviceDetailViewController.swift
  Views/                             // 设置行、开关行、设备行等复用视图
```

**`SecuritySettings`（Codable）**

| 字段 | 类型 | 默认值 |
|---|---|---|
| `perTransferLimitInCents` | `Int64` | 5_000_000（5 万元） |
| `dailyLimitInCents` | `Int64` | 20_000_000（20 万元） |
| `hidesAmounts` | `Bool` | `false` |
| `faceIDLoginEnabled` | `Bool` | `true` |
| `gestureLoginEnabled` | `Bool` | `false` |
| `smallPaymentWithoutPasswordEnabled` | `Bool` | `false` |
| `smallPaymentQuotaInCents` | `Int64` | 50_000（500 元），可选 200/500/1000 元 |
| `removedDeviceIDs` | `[String]` | `[]` |

解码时缺少的字段使用默认值。整体无法解码时回到默认值，原数据不覆盖，直到下一次成功保存。

**限额规则 `TransferLimitRules`**（纯函数，脚本可测）

- 单笔：1 元 ≤ 单笔 ≤ 50 万元。
- 日累计：1 元 ≤ 日累计 ≤ 100 万元。
- 单笔 ≤ 日累计。
- 只接受最多两位小数的正数。
- 违规时返回枚举错误，界面映射成中文提示：“单笔限额需在 1 元至 50 万元之间”、“日累计限额需在 1 元至 100 万元之间”、“单笔限额不能高于日累计限额”、“请输入正确金额”。
- 日累计可以调低到今日已转金额以下。此后今日转账被拦截，提示沿用现有的 `TransferError.dailyLimit` 文案。

**登录设备**：`LoginDevice`（id、名称、型号、系统、首次登录、最近登录、登录城市、`isCurrent`）。种子 3 台，由 `MockDataProvider` 提供，日期取自 `BankingDateContext` 推算（最近登录：本机 = 今天，其余为若干天前）：

- 本机 iPhone（`isCurrent = true`）
- iPad Air
- iPhone 12

可见设备 = 种子设备减去 `removedDeviceIDs`。

**`SecuritySettingsStore`**

- 按 `FeaturePreferencesStore` 模式实现：
  - `static let shared`
  - UserDefaults 键 `abank.securitySettings.v1`
  - `static let didChangeNotification`
  - 可注入 `defaults`、`notificationCenter`、`dataWriter`（用于模拟写入失败）
- 修改接口：
  - `setTransferLimits(perTransfer:daily:) throws`：先按规则校验，再持久化；校验或写入失败时抛错，内存值不变。
  - `setHidesAmounts(_:)`、`setFaceIDLogin(_:)`、`setGestureLogin(_:)`、`setSmallPayment(enabled:quota:)`：返回 `Bool` 表示是否保存成功。
  - `removeDevice(id:) throws`：本机或不存在的设备抛错。
- 只有保存成功后才更新内存并发通知。

## 4. 页面与联动

### 4.1 页面

所有新页面继承 `BaseViewController`，用 `ABankNavigationController` 标准导航栏，背景 `abankBackground`，分组卡片为白底、`CornerRadius.lg`、左右 `Spacing.md`。行高 52pt，标题用 `abankBody`，说明文字用 `abankCaption` / `abankTextSecondary`。开关颜色 `abankPrimary`。

- **安全中心**：
  - 顶部状态卡：安全图标，加“已开启 N 项保护”。N 为面容登录、手势登录、隐藏金额、限额低于默认值时的“限额保护”中已开启项的数量，再加副标题“本机模拟数据”。
  - 列表分两组：
    - “账户安全”：登录设置、转账设置、支付设置、登录设备（右侧显示“N 台”）。
    - “隐私”：隐藏金额（开关）。
- **登录设置**：两个开关，面容 ID 登录、手势密码登录。底部说明“演示设置，不做真实验证”。
- **转账设置**（取代 `TransferLimitsViewController`，路由 `.transferLimits` 不变）：
  - 三行：单笔限额、日累计限额（都可点击进入编辑）、今日已转（只读）。
  - 底部保留说明“金额和限额在确认前及提交时均会校验”。
- **修改限额**：
  - 两个金额输入框，预填当前值，单位为元；数字键盘带小数点。
  - 实时校验，出错时在输入框下方显示红色提示，此时“保存”禁用。
  - 保存成功后 toast“限额已更新”并返回；失败时 toast“保存失败，请稍后重试”并留在页面。
  - 键盘不遮挡输入框和按钮。
- **支付设置**：
  - 小额免密支付开关。
  - 开启后展开免密额度单选，可选 200 / 500 / 1000 元。
  - 底部说明同上。
- **登录设备**：
  - 设备列表：设备图标、名称、“本机”标签、最近登录时间与城市。点击进入详情。
  - 只剩本机时，列表下方显示“没有其他登录设备”。
- **设备详情**：
  - 显示型号、系统、首次登录、最近登录、登录城市。
  - 非本机设备底部有“移除此设备”按钮。点击后弹出确认框：“移除后该设备需重新验证才能登录”，选项为“取消”/“移除”。确认后返回列表并 toast“已移除”。
  - 本机不显示该按钮，改为说明“当前使用的设备不可移除”。

### 4.2 路由与入口

- `AppRoute` 新增：`.securityCenter`、`.loginSettings`、`.paymentSettings`、`.loginDevices`、`.loginDeviceDetail(deviceID: String)`。
- `.transferLimits` 改为指向 `TransferSettingsViewController`。
- `FeatureCatalog`：`securityCenter`、`loginSettings`、`paymentSettings`、`loginDevices` 改为 `.available(...)`，`securityStage` 不再被引用时删除。
- “我的”安全中心卡片的 `onTap` 已调用 `open(feature: .securityCenter)`，目录可用后自动生效。核对四个子入口的映射。
- 转账首页的限额入口不变。

### 4.3 金额隐私

- 覆盖范围是现有的金额眼睛按钮：
  - “我的”：资产负债卡片、月度收支卡片（`MineAssetLiabilityCardView`、`MineMonthlyFlowCardView`，经 `MineCardHeaderView`）
  - 我的贷款：`MyLoanSummaryView` / `MyLoanViewController`
- 借记卡详情（`DebitCardDetailInfoCardView`）的眼睛控制的是完整卡号显示，默认隐藏，属于另一种语义，保持页面内的临时状态，不接入全局隐私。
- 改法：
  - 各处删除本地 `isAmountVisible` 初值，改为读取 `!SecuritySettingsStore.shared.hidesAmounts`。
  - 点眼睛时调用 `setHidesAmounts(!hidesAmounts)`。
  - 所属页面监听 `didChangeNotification`（注入的通知中心）后刷新，进入页面时也再读一次。
  - 眼睛图标语义保持“睁眼 = 可见”。
- 隐藏时沿用各视图现有的隐藏样式（如我的贷款的 `****`），不新增样式。

### 4.4 资源

用安全中心原版线性图标，规格 96×96 单倍图，统一为：

| 新素材名 | 来源 | 用途 |
|---|---|---|
| `abc_security_center` | `safecenter_home_700_native500` | 安全中心状态卡 |
| `abc_security_login` | `safecenter_login_setting_700_native500` | 登录设置行 |
| `abc_security_transfer` | `safecenter_trans_setting_700_native500` | 转账设置行 |
| `abc_security_payment` | `safecenter_pay_setting_700_native500` | 支付设置行 |
| `abc_security_devices` | `safecenter_trusted_device_1100_native500` | 登录设备行、设备列表 |

具体做法：

- 源图来自 `artifacts/abc-resources/images/`。`originals/` 下的同名文件是 iOS 优化格式，不能直接读取。
- 新增 `scripts/import_security_assets.py`，按 `import_common_ui_assets.py` 的方式复制并校验 SHA-256，输出到 `ABank/Assets.xcassets/ABCImported/Security/`，写入 `docs/abc-security-resource-manifest.json`。
- 96px 单图只放在 imageset 的 3x 槽位（显示为 32pt），不另造 2x 图。
- 页面里按 24–32pt 显示，并用 `UIImage.abankAsset(_:fallback:)` 提供 SF Symbol 兜底。

## 5. 错误处理

| 情况 | 行为 |
|---|---|
| 设置数据无法解码 | 使用默认值；原数据保留到下次成功保存 |
| 写入失败 | 内存值和界面恢复旧值；开关回弹；toast“保存失败，请稍后重试” |
| 限额不合法 | 行内提示，保存禁用；Store 二次校验，抛错时不保存 |
| 移除本机或不存在的设备 | Store 抛错，界面不提供本机移除入口 |
| 设备详情路由传入已移除的 ID | 显示“设备不存在或已移除”空态 |

## 6. 验证

**新增 `scripts/check_security_settings.swift`**，接入 `check_banking_data.sh`（与现有脚本一起编译 `SecuritySettings.swift`、`SecuritySettingsStore.swift` 以及所需的账本源文件）。检查内容：

1. 默认值：5 万 / 20 万，隐私关闭，3 台设备。
2. 限额规则各边界：0、1 元、50 万、50 万 + 0.01、单笔大于日累计、三位小数。
3. 保存后重新构造 Store 能读回同样的值；无法解码的数据回到默认值且原数据不被覆盖。
4. 写入失败时值不变、不发通知。
5. 移除设备持久化；移除本机抛错。
6. `hidesAmounts` 变化会发通知。
7. 账本联动：注入共用设置 Store 的账本，下调单笔限额后，原本合法的转账被 `singleLimit` 拦截；下调日累计后被 `dailyLimit` 拦截；恢复后又能通过。

**构建**：按开发计划的 `xcodebuild` 命令。

**模拟器（iPhone 16 Pro）**：
- 入口：“我的”和全部功能都能进入安全中心及四个子页。
- 限额：改小后转账确认被拦截，提示正确；改回后成功。重启后限额仍在。
- 隐私：在“我的”点眼睛后，进入我的贷款也同步隐藏；在我的贷款切回后返回“我的”同步；切换安全中心开关后返回“我的”同步；借记卡卡号眼睛不受影响。
- 设备：移除一台后列表少一台；本机无移除按钮。
- 开关：登录、支付开关重启后保持。
- 键盘不遮挡限额输入，长文本不截断。

**未验证项预期**：320pt 宽度；中文输入（限额只用数字键盘，不涉及）；无原版截图的页面布局待校准。
