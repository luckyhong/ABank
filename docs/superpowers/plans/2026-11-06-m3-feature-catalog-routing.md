# M3 功能目录与统一路由 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 ABank 建立类型化统一路由与 69 项功能目录，提供全部功能页、功能搜索、常用编辑（驱动首页宫格）、最近使用和统一“即将上线”页，并把各 Tab 的功能宫格改走路由。

**Architecture:** 纯 Foundation 层（`FeatureID`/`FeatureCatalog`/`AppRoute`/`FeatureSearch`/`FeaturePreferencesStore`）可被 macOS `swiftc` 数据检查脚本编译测试；UIKit 层（`AppRouter`、三个新页面、入口改接）只做路由到控制器的构造与展示。各页面宫格数据带可选 `featureID`，点击统一调用 `router.open(feature:from:)`。

**Tech Stack:** Swift 5、UIKit、SnapKit、UserDefaults；数据检查用 `xcrun swiftc` 编译的独立可执行脚本（`precondition` 断言）。

**Spec:** `docs/superpowers/specs/2026-11-06-m3-feature-catalog-routing-design.md`

## Global Constraints

- iOS 15.6+，Swift 5，UIKit + SnapKit；打开 `ABank.xcworkspace`。工程使用 Xcode 文件夹同步组，新文件无需修改 `project.pbxproj`。
- 不新增任何网络请求；不修改 `FinanceLedgerStore` 的数据格式与 `abank.financeLedger.record.v8`。
- 偏好存储键：`abank.featurePreferences.v1`；常用上限 **9**，最近使用上限 **8**。
- 默认常用（顺序固定）：`creditCard, pensionCommunity, inclusiveFinance, deposit, wealthProduct, loan, lifePayment, hotActivities, cityZone`。
- 纯模型文件只 `import Foundation`（数据检查脚本在 macOS 编译，无 UIKit）。
- 即将上线页文案：“该功能正在建设中”“学习项目演示”；阶段显示 `计划阶段：<stage>` 或 `后续规划`。不得出现“已办理/已取号”等业务结果提示。
- 满额提示文案：`最多添加 9 个常用功能`；搜索空态：`未找到相关功能`；常用为空提示：`点击编辑添加常用功能`；角标文字：`待上线`。
- 素材命名 `abc_allmenus_add`、`abc_allmenus_delete`，不虚构 2x/3x。
- **项目规则：未经用户要求不提交、不推送。** 本计划各任务结束不做 `git commit`，改为“自检 diff”步骤。
- 每个任务的 UI 构建命令：

```sh
xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build
```

  期望末尾 `** BUILD SUCCEEDED **`。

- 数据检查命令：`zsh scripts/check_banking_data.sh`，期望无输出错误、退出码 0。

**对设计的两处修正**：(1) 设计 §3.3 的 `.transfer` 与 `.accountDetail(accountID:)` 补充上下文参数为 `.transfer(payerAccountID:)`、`.accountDetail(accountID:maskedNumber:)`，以保留我的账户页现有的付款账户与卡号上下文。(2) 设计 §7 “每个 available 路由都能生成控制器”无法在 macOS 脚本中验证（无 UIKit）。改由 `AppRouter.makeViewController(for:)` 的穷举 `switch`（无 `default`）在编译期保证，并在 Task 10 模拟器验收逐项打开 15 个已完成功能。

## Review Focus

1. **旧偏好含已删除/改名的 ID**：用户升级后不应崩溃，未知 ID 被丢弃、其余顺序保留 → Task 3 `unknownIDsDropped`。
2. **快速连点宫格**：只推入一个页面 → Task 4 `AppRouter` 栈顶同路由忽略，Task 10 模拟器连点验证。
3. **只含空白或全角空格的搜索词**（如 `"　"`、`" 转账  记录 "`）：前者返回空，后者按两词匹配 → Task 2 `whitespaceQueries`。
4. **待上线功能或带上下文的路由被记入最近使用**：最近使用只记录通过功能入口打开的已完成功能 → Task 3 `plannedNotRecorded`，Task 4 `open(_ route:)` 不记录。
5. **编辑页取消后首页变化**：取消不得写入 Store，首页保持原样 → Task 7 草稿模型 + Task 10 模拟器验证。

---

## File Structure

| 文件 | 职责 |
|---|---|
| Create `ABank/Core/Routing/AppRoute.swift` | 路由枚举（Foundation） |
| Create `ABank/Features/AllFeatures/Models/FeatureCatalog.swift` | `FeatureID`、`FeatureCategory`、`FeatureDescriptor`、69 项目录、默认常用（Foundation） |
| Create `ABank/Features/AllFeatures/Models/FeatureSearch.swift` | 纯函数搜索（Foundation） |
| Create `ABank/Features/AllFeatures/FeaturePreferencesStore.swift` | 常用/最近使用持久化（Foundation） |
| Create `ABank/Core/Routing/AppRouter.swift` | `AppRouting` 协议与默认实现（UIKit） |
| Create `ABank/Features/AllFeatures/ComingSoonViewController.swift` | 即将上线页 |
| Create `ABank/Features/AllFeatures/AllFeaturesViewController.swift` | 全部功能 + 搜索 |
| Create `ABank/Features/AllFeatures/FavoriteFeaturesEditViewController.swift` | 编辑常用 |
| Create `ABank/Features/AllFeatures/Views/FeatureGridCell.swift` | 目录/编辑共用单元 |
| Create `ABank/Features/AllFeatures/Views/FeatureCategoryIndexView.swift` | 左侧分类索引 |
| Create `ABank/Shared/Utilities/FeatureDescriptor+UI.swift` | 描述 → `UIImage` 图标 |
| Create `scripts/check_feature_catalog.swift` | 功能目录/搜索/偏好数据检查 |
| Create `scripts/import_all_features_assets.py` | 从已有 Loose imageset 生成语义素材 |
| Create `docs/abc-all-features-resource-manifest.json` | 素材来源清单 |
| Modify `scripts/check_banking_data.sh` | 增加源文件与 `feature` 检查 |
| Modify `ABank/Core/Base/BaseViewController.swift` | 增加 `router` 属性 |
| Modify Home/Wealth/Life/Mine/Transfer 的 Models、`MockDataProvider.swift`、对应 ViewController | 宫格携带 `featureID` 并改走路由 |
| Modify `ABank/Features/Home/Views/GridMenuView.swift` | 支持 1–10 项 |
| Modify `docs/development-plan.md`、`docs/continuity/tasks/m3-feature-catalog.md` | 交接记录 |

---

### Task 1: 功能 ID、目录与路由枚举

**Files:**
- Create: `ABank/Core/Routing/AppRoute.swift`
- Create: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`
- Create: `scripts/check_feature_catalog.swift`
- Modify: `scripts/check_banking_data.sh`

**Interfaces:**
- Consumes: `TransferMethod`（`ABank/Features/Transfer/Models/TransferSimulationModels.swift`，`.account`/`.phone`）
- Produces:
  - `enum AppRoute: Equatable` —— cases：`myAccount, debitCardDetail, transferRecords, transferLimits, transferReceipts, ledgerAnalysis, ledgerSearch, assetLiability, myLoan, customerInfo, editFavorites`，`transfer(payerAccountID: String?)`，`accountDetail(accountID: String?, maskedNumber: String?)`，`transferForm(method: TransferMethod)`，`incomeExpense(accountID: String?)`，`allFeatures(searchKeyword: String?)`，`comingSoon(FeatureID)`
  - `enum FeatureID: String, Codable, CaseIterable`（69 个 case，rawValue 即 case 名）
  - `enum FeatureCategory: String, CaseIterable { case account, transfer, wealth, credit, life, service }`，`var title: String`：账户 / 转账 / 财富 / 贷款信用卡 / 生活 / 网点与安全
  - `struct FeatureDescriptor { id, title, keywords: [String], imageName: String?, systemIcon: String, category, availability }`，`enum Availability: Equatable { case available(AppRoute); case planned(stage: String?) }`，`var isAvailable: Bool`，`var plannedStageText: String`（`计划阶段：X` 或 `后续规划`）
  - `enum FeatureCatalog { static let all: [FeatureDescriptor]; static func descriptor(_ id: FeatureID) -> FeatureDescriptor; static let defaultFavorites: [FeatureID]; static func features(in category: FeatureCategory) -> [FeatureDescriptor] }`

- [ ] **Step 1: 写失败的检查** `scripts/check_feature_catalog.swift`，`@main struct FeatureCatalogChecks`，`@MainActor static func main() throws`，第一个函数 `catalogIntegrity()`：

```swift
let ids = FeatureCatalog.all.map(\.id)
precondition(Set(ids).count == ids.count && ids.count == FeatureID.allCases.count && ids.count == 69)
precondition(Set(FeatureCatalog.all.map(\.title)).count == 69)
precondition(FeatureCatalog.all.filter(\.isAvailable).count == 15)
precondition(FeatureCatalog.defaultFavorites == [.creditCard, .pensionCommunity, .inclusiveFinance, .deposit, .wealthProduct, .loan, .lifePayment, .hotActivities, .cityZone])
precondition(FeatureCatalog.descriptor(.loan).availability == .available(.myLoan))
precondition(FeatureCatalog.descriptor(.phoneTransfer).availability == .available(.transferForm(method: .phone)))
precondition(FeatureCatalog.descriptor(.branchQueue).availability == .planned(stage: "M5 网点服务"))
precondition(FeatureCatalog.descriptor(.charity).plannedStageText == "后续规划")
precondition(FeatureCategory.allCases.allSatisfy { !FeatureCatalog.features(in: $0).isEmpty })
```

- [ ] **Step 2: 修改 `scripts/check_banking_data.sh`**：`sources` 追加 `ABank/Core/Routing/AppRoute.swift` 与 `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（后续任务再追加 `FeatureSearch.swift`、`FeaturePreferencesStore.swift`）；循环改为 `for check in banking transfer insights feature`，其中 `feature` 对应 `scripts/check_feature_catalog.swift`（脚本按 `check_${check}_data.swift` 命名，因此把新脚本条件映射：`[[ $check == feature ]] && file=scripts/check_feature_catalog.swift || file="scripts/check_${check}_data.swift"`）。

- [ ] **Step 3: 运行确认失败**

Run: `zsh scripts/check_banking_data.sh`
Expected: 编译失败，`cannot find 'FeatureCatalog' in scope`。

- [ ] **Step 4: 实现 `AppRoute.swift` 与 `FeatureCatalog.swift`**

目录内容严格按设计 §3.2。可用项与路由：

| id | title | route |
|---|---|---|
| myAccount | 我的账户 | `.myAccount` |
| accountDetail | 明细查询 | `.accountDetail(accountID: nil, maskedNumber: nil)` |
| debitCard | 借记卡 | `.debitCardDetail` |
| transfer | 转账 | `.transfer(payerAccountID: nil)` |
| accountTransfer | 账号转账 | `.transferForm(method: .account)` |
| phoneTransfer | 手机号转账 | `.transferForm(method: .phone)` |
| transferRecords | 转账记录 | `.transferRecords` |
| transferLimits | 转账限额 | `.transferLimits` |
| receipts | 电子回单 | `.transferReceipts` |
| incomeExpense | 收支 | `.incomeExpense(accountID: nil)` |
| monthlyBill | 月度账单 | `.ledgerAnalysis` |
| ledgerSearch | 交易搜索 | `.ledgerSearch` |
| assetLiability | 资产负债 | `.assetLiability` |
| loan | 贷款 | `.myLoan` |
| customerInfo | 客户资料 | `.customerInfo` |

待上线 ID（category: stage）：
- account：`openCard`(M5 网点服务)、`sameNumberReplace`(M5 网点服务)
- transfer（stage nil）：`creditCardRepay, scheduledTransfer, multiTransfer, otherBankIn, crossBorder, donation, mobileCollection, transferCancel`
- wealth：`deposit, wealthProduct, fund`(M7 财富产品)；`preciousMetals, bonds, insurance, securities, forex, personalPension`(nil)
- credit（nil）：`creditCard, inclusiveFinance`
- life：`lifePayment, mobileRecharge`(M8 充值缴费)；`beans, pointsMall`(M6 权益订单)；`government, socialInsurance, campus, cafeteria, partyFee, carService, abcMall, hospital, providentFund, transport, takeout, movies, hotelTravel, express, charity, pensionCommunity, hotActivities, cityZone`(nil)
- service：`branchQuery, branchQueue, coinReservation`(M5 网点服务)；`securityCenter, loginSettings, paymentSettings, loginDevices`(M4 安全中心)；`benefits, customerLevel, orders`(M6 权益订单)；`scan`(M10 快捷与扫码)

标题使用设计 §3.2 中文名（`branchQueue` = 网点取号，`scan` = 扫一扫，`takeout` = 美团外卖，`movies` = 电影演出，`hotelTravel` = 酒店旅行，`express` = 快递寄件，`charity` = 爱心公益）。`imageName`/`systemIcon` 复用 `MockDataProvider.swift` 中同名宫格的现有值（首页 `abc_home_*`、财富 `abc_wealth_menu_*`、生活 `abc_life_menu_*`、我的 `abc_mine_branch_*`/`abc_mine_security_*`、转账 `abc_transfer_*`）；首页快捷入口的 `abc_home_account/transfer/income/scan` 用于 myAccount/transfer/incomeExpense/scan；其余无切图项给系统图标、`imageName: nil`。关键词至少包含：incomeExpense `["账单","流水","收入","支出"]`、monthlyBill `["账单","分析","统计"]`、ledgerSearch `["流水","查询"]`、receipts `["回单","凭证"]`、branchQueue `["排队","取号","网点"]`、branchQuery `["网点","附近"]`、transferLimits `["限额","转账设置"]`。

- [ ] **Step 5: 运行确认通过**

Run: `zsh scripts/check_banking_data.sh`
Expected: 退出码 0。

- [ ] **Step 6: 自检 diff**（不提交）：`git diff --check && git status --short`，确认只有本任务文件。

---

### Task 2: 功能搜索

**Files:**
- Create: `ABank/Features/AllFeatures/Models/FeatureSearch.swift`
- Modify: `scripts/check_feature_catalog.swift`、`scripts/check_banking_data.sh`（sources 追加本文件）

**Interfaces:**
- Consumes: `FeatureDescriptor`、`FeatureCategory.title`、`FeatureCatalog.all`
- Produces: `enum FeatureSearch { static func search(_ query: String, in catalog: [FeatureDescriptor] = FeatureCatalog.all) -> [FeatureDescriptor] }`

- [ ] **Step 1: 写失败的检查** `searchBehavior()` 与 `whitespaceQueries()`：

```swift
precondition(FeatureSearch.search("").isEmpty)
precondition(FeatureSearch.search("   ").isEmpty && FeatureSearch.search("　").isEmpty)
let t = FeatureSearch.search("转账").map(\.id)
precondition(t.first == .transfer)                      // 名称前缀/全等优先
precondition(t.contains(.accountTransfer) && t.contains(.transferLimits))
precondition(FeatureSearch.search("账单").map(\.id).prefix(2).contains(.monthlyBill))  // 关键词命中
precondition(FeatureSearch.search("网点").contains { $0.id == .branchQueue })
precondition(FeatureSearch.search(" 转账  记录 ").map(\.id) == [.transferRecords])   // 多词全命中
precondition(FeatureSearch.search("转账　记录").map(\.id) == [.transferRecords])     // 全角空格
precondition(FeatureSearch.search("理财").contains { $0.id == .wealthProduct })      // 待上线也可搜到
precondition(FeatureSearch.search("不存在的功能").isEmpty)
```

- [ ] **Step 2: 运行确认失败**：`zsh scripts/check_banking_data.sh`，Expected：`cannot find 'FeatureSearch'`。

- [ ] **Step 3: 实现 `search`**：用 `CharacterSet.whitespacesAndNewlines`（含全角空格 U+3000）切词并丢弃空词；无词返回 `[]`。每项的匹配文本 = 标题、关键词、分类标题；所有词都需在其中任一文本出现（`localizedCaseInsensitiveContains`）。排序键：0 = 标题以第一个词开头，1 = 标题包含第一个词，2 = 其他；同键保持目录顺序（对 `enumerated()` 稳定排序）。

- [ ] **Step 4: 运行确认通过**：同上，退出码 0。

- [ ] **Step 5: 自检 diff**（不提交）。

---

### Task 3: 常用与最近使用持久化

**Files:**
- Create: `ABank/Features/AllFeatures/FeaturePreferencesStore.swift`
- Modify: `scripts/check_feature_catalog.swift`、`scripts/check_banking_data.sh`

**Interfaces:**
- Consumes: `FeatureID`、`FeatureCatalog.defaultFavorites`、`FeatureCatalog.descriptor(_:).isAvailable`
- Produces:

```swift
final class FeaturePreferencesStore {
    static let shared: FeaturePreferencesStore
    static let didChangeNotification: Notification.Name   // "ABank.featurePreferencesDidChange"
    static let storageKey = "abank.featurePreferences.v1"
    static let maxFavorites = 9
    static let maxRecents = 8
    init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default)
    var favorites: [FeatureID] { get }
    var recents: [FeatureID] { get }
    @discardableResult func setFavorites(_ ids: [FeatureID]) -> [FeatureID]   // 去重保序、截断到 9，保存并通知，返回实际保存值
    func recordUse(_ id: FeatureID)                                           // 待上线忽略；移到最前；截断到 8；保存并通知
}
```

- [ ] **Step 1: 写失败的检查**（每个用独立 `UserDefaults(suiteName: "ABank.FeatureChecks." + UUID().uuidString)`，结束 `removePersistentDomain`）：
  - `defaultsWhenEmpty`：新 suite → `favorites == FeatureCatalog.defaultFavorites`，`recents == []`。
  - `favoritesRules`：`setFavorites([.transfer, .loan, .transfer])` 返回 `[.transfer, .loan]`；传 11 个不同 ID 返回前 9 个；`setFavorites([])` 后 `favorites == []`（不回退默认）；新建同 suite 的 Store 读到相同值。
  - `unknownIDsDropped`：直接写入 `{"favorites":["transfer","removedFeature","loan"],"recents":["ghost"]}` → `favorites == [.transfer, .loan]`，`recents == []`。
  - `corruptDataFallsBack`：写入 `Data("not json".utf8)` → `favorites == defaultFavorites`。
  - `recentsRules`：依次 `recordUse` `.transfer, .loan, .transfer` → `[.transfer, .loan]`；记录 10 个不同已完成 ID 后 `count == 8` 且首项为最后记录者。
  - `plannedNotRecorded`：`recordUse(.branchQueue)` 后 `recents` 不变。
  - `notifies`：用独立 `NotificationCenter` 计数，`setFavorites` 与 `recordUse(.transfer)` 各发一次；`recordUse(.branchQueue)` 不发。

- [ ] **Step 2: 运行确认失败**：Expected `cannot find 'FeaturePreferencesStore'`。

- [ ] **Step 3: 实现**：私有 `Codable` 结构 `{favorites: [String], recents: [String]}`；读取时 `compactMap(FeatureID.init(rawValue:))`；键缺失或解码失败 → 默认常用 + 空最近。写入失败（编码异常）时不通知、不改变内存值。

- [ ] **Step 4: 运行确认通过**：退出码 0。

- [ ] **Step 5: 自检 diff**（不提交）。

---

### Task 4: AppRouter、即将上线页与图标辅助

**Files:**
- Create: `ABank/Core/Routing/AppRouter.swift`
- Create: `ABank/Features/AllFeatures/ComingSoonViewController.swift`
- Create: `ABank/Shared/Utilities/FeatureDescriptor+UI.swift`
- Modify: `ABank/Core/Base/BaseViewController.swift`

**Interfaces:**
- Consumes: Task 1–3 全部；现有控制器 init：`MyAccountViewController()`、`DebitCardDetailViewController()`、`TransferViewController()`、`TransferFormViewController(method:payerAccountID:...)`、`TransferRecordsViewController(store:)`、`TransferLimitsViewController(store:)`、`TransferReceiptsViewController(accountID: nil)`、`TransferViewController(payerAccountID:)`、`IncomeExpenseViewController(accountId:)`、`AccountDetailQueryViewController(accountId:maskedNumber:)`（nil 时用其默认参数 `FinanceLedgerRecord.defaultAccountId` 与 `"6230 **** 8472"`）、`LedgerAnalysisViewController()`、`LedgerSearchViewController(query: IncomeExpenseQuery(dateMode: .month(BankingDateContext.system.previousMonth)))`、`AssetLiabilityViewController()`、`MyLoanViewController()`、`CustomerInfoViewController()`
- Produces:

```swift
protocol AppRouting: AnyObject {
    func open(_ route: AppRoute, from source: UIViewController)          // 不记录最近使用
    func open(feature id: FeatureID, from source: UIViewController)      // available → recordUse + open；planned → open(.comingSoon(id))
}
final class AppRouter: AppRouting {
    static let shared: AppRouter
    init(preferences: FeaturePreferencesStore = .shared, ledger: FinanceLedgerStore = .shared)
    func makeViewController(for route: AppRoute) -> UIViewController   // 穷举 switch，禁止 default
}
protocol RouteHosting: UIViewController { var hostedRoute: AppRoute? { get } }   // 用于栈顶去重
extension FeatureDescriptor { var iconImage: UIImage? }                         // UIImage.abankAsset(imageName, fallback: systemIcon)
final class ComingSoonViewController: BaseViewController, RouteHosting { init(featureID: FeatureID) }
// BaseViewController 新增：var router: AppRouting = AppRouter.shared
```

为保持穷举，Task 4 中 `.allFeatures` 与 `.editFavorites` 两个 case 临时返回 `UIViewController()` 并标注 `// Task 6/7 替换`；Task 6、7 必须替换，Task 10 前 `grep -n "Task 6/7 替换"` 应无结果。

- [ ] **Step 1: 实现 `AppRouter`**：`open(_:from:)` 取 `source.navigationController`；为 nil 时 `assertionFailure` 并返回。防连点：若栈顶 `as? RouteHosting` 的 `hostedRoute == route`，直接返回；现有控制器不实现该协议，因此 Router 另存 `private weak var lastPushed: UIViewController?` 与 `private var lastRoute: AppRoute?`，当 `lastPushed === nav.topViewController && lastRoute == route` 时也忽略。

- [ ] **Step 2: 实现 `ComingSoonViewController`**：标题为功能名；居中图标（64pt）、功能名、`该功能正在建设中`、`descriptor.plannedStageText`、小字 `学习项目演示`；底部主色按钮 `返回` → `navigationController?.popViewController`。全部使用 `UIColor.abank*`、`UIFont.abank*`、`Spacing`。

- [ ] **Step 3: `BaseViewController` 增加 `var router: AppRouting = AppRouter.shared`。**

- [ ] **Step 4: 构建**：运行 Global Constraints 中的构建命令，Expected `** BUILD SUCCEEDED **`。再运行 `zsh scripts/check_banking_data.sh`，退出码 0。

- [ ] **Step 5: 自检 diff**（不提交）。

---

### Task 5: 编辑角标语义素材

**Files:**
- Create: `scripts/import_all_features_assets.py`
- Create: `ABank/Assets.xcassets/ABCImported/AllFeatures/Contents.json`、`abc_allmenus_add.imageset/`、`abc_allmenus_delete.imageset/`
- Create: `docs/abc-all-features-resource-manifest.json`

**Interfaces:**
- Produces: 图片名 `abc_allmenus_add`、`abc_allmenus_delete`（供 Task 6/7）

- [ ] **Step 1: 编写脚本**：不依赖 `artifacts/`。从 `ABank/Assets.xcassets/ABCImported/Loose/Main/abc_resource_hp_allmenus_icon_add_b8a98a9e1ab8.imageset` 与 `..._delete_c7006f39f5d4.imageset` 复制图片文件与原 `Contents.json`（保留原 scale 与 rendering intent）到新语义 imageset；清单记录 `semantic_name`、`source`（`hp_allmenus_icon_add.png`/`hp_allmenus_icon_delete.png`）、`source_sha256`（取自 `docs/abc-feature-gap-assets.json`）、`dimensions [45,45]`、`copied_from`。脚本校验复制后图片 SHA-256 与源 imageset 文件一致，不一致则退出码非 0。

- [ ] **Step 2: 运行**：`python3 -I scripts/import_all_features_assets.py`，Expected 打印两个 imageset 路径，退出码 0；`python3 -m json.tool docs/abc-all-features-resource-manifest.json` 通过。

- [ ] **Step 3: 构建**通过（Expected `** BUILD SUCCEEDED **`）。

- [ ] **Step 4: 自检 diff**（不提交）。

---

### Task 6: 全部功能页（含搜索、常用、最近使用）

**Files:**
- Create: `ABank/Features/AllFeatures/AllFeaturesViewController.swift`
- Create: `ABank/Features/AllFeatures/Views/FeatureGridCell.swift`
- Create: `ABank/Features/AllFeatures/Views/FeatureCategoryIndexView.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（`.allFeatures` 构造真实页面）

**Interfaces:**
- Consumes: `FeatureCatalog`、`FeatureSearch.search`、`FeaturePreferencesStore`（`favorites`/`recents`/`didChangeNotification`）、`router.open(feature:from:)`、`router.open(.editFavorites, from:)`、`FeatureDescriptor.iconImage`
- Produces:
  - `final class AllFeaturesViewController: BaseViewController, RouteHosting { init(searchKeyword: String? = nil, preferences: FeaturePreferencesStore = .shared) }`
  - `final class FeatureGridCell: UICollectionViewCell { static let reuseID; enum Accessory { case none, planned, add, delete, added }; func configure(_ d: FeatureDescriptor, accessory: Accessory) }`（`planned` 显示灰色“待上线”标签；`add`/`delete` 用 Task 5 素材；`added` 显示主色对勾 `checkmark.circle.fill`）
  - `final class FeatureCategoryIndexView: UIView { var onSelect: ((FeatureCategory) -> Void)?; func setHighlighted(_ c: FeatureCategory) }`

- [ ] **Step 1: 实现页面**：单个 `UICollectionView` + compositional layout，section 顺序：`favorites`（横向滚动，空时一个提示单元 `点击编辑添加常用功能`，section header 含“编辑”按钮）、`recents`（为空时整段不出现）、6 个分类 section（4 列）。分类区左侧 `FeatureCategoryIndexView` 固定宽 84pt，右侧集合视图；点击索引滚动到对应 section header，`scrollViewDidScroll` 根据可见首个分类 section 回写高亮。顶部 `UISearchBar`：文字非空时切换为单个结果 section（4 列），空结果显示 `未找到相关功能`；清空恢复。`init(searchKeyword:)` 非空时预填并进入搜索态。所有单元点击 → `router.open(feature: id, from: self)`。观察 `didChangeNotification` 与 `viewWillAppear` 时重载 favorites/recents。标题最多两行、`adjustsFontSizeToFitWidth = false`，截断 `.byTruncatingTail`。

- [ ] **Step 2: `AppRouter` 中 `.allFeatures(let keyword)` → `AllFeaturesViewController(searchKeyword: keyword)`，并移除 Task 4 留下的对应占位注释。**

- [ ] **Step 3: 构建**通过。

- [ ] **Step 4: 模拟器冒烟**：先 `xcrun simctl list devices booted` 查询当前设备（不复用历史 ID），安装构建产物，临时在本地（不保存）用调试器或 Task 8 完成后从首页“全部”进入均可；本任务只需确认：页面渲染 6 个分类、索引点击滚动、搜索“账单”出现月度账单、搜索“xyz”出现空态。若 Task 8 尚未完成，可推迟到 Task 8 Step 5 一并验证，并在任务记录中注明。

- [ ] **Step 5: 自检 diff**（不提交）。

---

### Task 7: 编辑常用页

**Files:**
- Create: `ABank/Features/AllFeatures/FavoriteFeaturesEditViewController.swift`
- Modify: `ABank/Core/Routing/AppRouter.swift`（`.editFavorites`）、`scripts/check_feature_catalog.swift`

**Interfaces:**
- Consumes: `FeatureGridCell`、`FeaturePreferencesStore.setFavorites(_:)`、`maxFavorites`
- Produces:
  - `struct FavoritesDraft: Equatable { private(set) var ids: [FeatureID]; enum AddResult { case added, duplicate, full }; mutating func add(_:) -> AddResult; mutating func remove(_:); mutating func move(from: Int, to: Int) }`（放在 `FeaturePreferencesStore.swift` 末尾，Foundation，可脚本测试）
  - `final class FavoriteFeaturesEditViewController: BaseViewController, RouteHosting { init(preferences: FeaturePreferencesStore = .shared) }`

- [ ] **Step 1: 写失败的检查** `favoritesDraftRules()`：

```swift
var d = FavoritesDraft(ids: [.transfer, .loan])
precondition(d.add(.loan) == .duplicate && d.ids == [.transfer, .loan])
d.move(from: 1, to: 0); precondition(d.ids == [.loan, .transfer])
d.remove(.loan); precondition(d.ids == [.transfer])
var full = FavoritesDraft(ids: Array(FeatureCatalog.all.prefix(9).map(\.id)))
precondition(full.add(FeatureCatalog.all[9].id) == .full && full.ids.count == 9)
d.move(from: 0, to: 5); precondition(d.ids == [.transfer])   // 越界目标夹到末尾，不崩溃
```

- [ ] **Step 2: 运行确认失败**：Expected `cannot find 'FavoritesDraft'`。

- [ ] **Step 3: 实现 `FavoritesDraft`**，`init(ids:)` 去重并截断到 9；`move` 对越界下标夹取到有效范围。运行检查通过。

- [ ] **Step 4: 实现页面**：导航左 `取消`（pop，不写入）、右 `完成`（`preferences.setFavorites(draft.ids)` 后 pop）。上区标题 `我的常用（n/9）`，单元 `.delete` 角标，点击删除；`collectionView.dragInteractionEnabled = true`，实现 `UICollectionViewDragDelegate`/`DropDelegate` 仅限上区内部重排并调用 `draft.move`。下区按分类列出全部功能：在草稿中 → `.added`，否则 `.add`；点击 `.add` 调 `draft.add`，`.full` 时 `showToast("最多添加 9 个常用功能")`。`AppRouter` 中 `.editFavorites` → 本页面。

- [ ] **Step 5: 构建**通过；`zsh scripts/check_banking_data.sh` 退出码 0。

- [ ] **Step 6: 自检 diff**（不提交）。

---

### Task 8: 首页改接

**Files:**
- Modify: `ABank/Features/Home/Models/HomeModels.swift`（`HomeShortcutItem`、`HomeGridItem`、`HomeBranchServiceItem` 增加 `var featureID: FeatureID? = nil`）
- Modify: `ABank/Data/MockDataProvider.swift`（首页快捷入口与网点服务填 featureID；宫格数据不再写死）
- Modify: `ABank/Features/Home/Views/GridMenuView.swift`
- Modify: `ABank/Features/Home/HomeViewController.swift:226-286`

**Interfaces:**
- Consumes: `FeaturePreferencesStore.favorites`/`didChangeNotification`、`FeatureCatalog.descriptor`、`router`
- Produces: `extension HomeGridItem { init(descriptor: FeatureDescriptor); static let allEntry: HomeGridItem }`（`allEntry` 使用 `abc_home_all`/`ellipsis.circle`，标题“全部”，`featureID: nil`）

- [ ] **Step 1: 快捷入口**：`我的账户/转账/收支/扫一扫` 分别填 `.myAccount/.transfer/.incomeExpense/.scan`；`shortcutRow.onItemTapped` 改为 `router.open(feature:)`，删除按标题 `switch`。

- [ ] **Step 2: 宫格**：`HomeViewController` 新增 `private func reloadFavoriteGrid()`：`favorites.map { HomeGridItem(descriptor: FeatureCatalog.descriptor($0)) } + [.allEntry]` 交给 `gridMenu.configure(with:)`，并保存当前数组用于点击；`featureID == nil` → `router.open(.allFeatures(searchKeyword: nil), from: self)`。在 `setupBindings` 和 `didChangeNotification` 回调中调用。保留 `badge`：若 descriptor 为 `inclusiveFinance` 则 badge `"NEW"`（保持原首页外观）。`GridMenuView.configure` 已支持任意数量，确认 1 项（仅“全部”）时行高与空白填充正常，必要时仅调整空态布局。

- [ ] **Step 3: 搜索与网点**：`topSearchBar.onSearchTapped` → `.allFeatures(searchKeyword: keyword)`；`branchService.onQueueTapped` → `open(feature: .branchQueue)`；三个服务图标填 `.openCard/.coinReservation/.sameNumberReplace` 并在其点击回调中路由（若 `BranchServiceView` 目前没有服务图标点击回调，增加 `var onServiceTapped: ((Int) -> Void)?`）。电话、刷新、公告、消费者保护、客服、消息、版本、礼物保持原样。

- [ ] **Step 4: 构建**通过。

- [ ] **Step 5: 模拟器验证**（查询当前设备）：首页宫格与改前 9 项一致且“普惠金融”带 NEW；点“全部”进入全部功能页（补做 Task 6 冒烟）；点“贷款”进入我的贷款；点“信用卡”进入即将上线页显示“后续规划”；点“取号”进入即将上线页显示“计划阶段：M5 网点服务”；搜索框进入全部功能并带关键词。截图保存到 `artifacts/abc-resources/verification/m3-home.png`（Git 忽略）。

- [ ] **Step 6: 自检 diff**（不提交）。

---

### Task 9: 财富、生活、我的、转账改接

**Files:**
- Modify: `ABank/Features/Finance/Models/WealthModels.swift`、`ABank/Features/Life/Models/LifeModels.swift`、`ABank/Features/Mine/Models/MineModels.swift`、`ABank/Features/Transfer/Models/TransferModels.swift`（各 item 增加 `var featureID: FeatureID? = nil`）
- Modify: `ABank/Data/MockDataProvider.swift`（填写 featureID；“全部”保持 nil）
- Modify: `ABank/Features/Finance/FinanceViewController.swift:196-200`、`ABank/Features/Life/LifeViewController.swift:157-184`、`ABank/Features/Mine/MineViewController.swift:141-207`、`ABank/Features/Transfer/TransferViewController.swift:195-215`

**Interfaces:**
- Consumes: `router.open(feature:from:)`、`router.open(_:from:)`
- Produces: 无新增公共接口

- [ ] **Step 1: 映射填写**：
  - 财富：存款 `.deposit`、理财产品 `.wealthProduct`、基金 `.fund`、贵金属 `.preciousMetals`、债券 `.bonds`、保险 `.insurance`、证券期货 `.securities`、外汇 `.forex`、个人养老金 `.personalPension`、全部 nil。
  - 生活：生活缴费 `.lifePayment`、手机充值 `.mobileRecharge`、政务民生 `.government`、社保医保 `.socialInsurance`、小豆乐园 `.beans`、校园 `.campus`、食堂 `.cafeteria`、党费 `.partyFee`、车主服务 `.carService`、农银商城 `.abcMall`、美团外卖 `.takeout`、电影演出 `.movies`、酒店旅行 `.hotelTravel`、快递寄件 `.express`、医疗挂号 `.hospital`、公积金 `.providentFund`、交通出行 `.transport`、积分商城 `.pointsMall`、爱心公益 `.charity`、全部 nil。
  - 我的网点服务：我要开卡 `.openCard`、纪念币预约 `.coinReservation`、同号换卡 `.sameNumberReplace`、网点查询 `.branchQuery`；安全：登录设置 `.loginSettings`、转账设置 `.transferLimits`、支付设置 `.paymentSettings`、登录设备 `.loginDevices`。
  - 转账功能项：信用卡还款 `.creditCardRepay`、预约转账 `.scheduledTransfer`、向多人转账 `.multiTransfer`、他行卡转入 `.otherBankIn`、跨境服务 `.crossBorder`、公益捐款 `.donation`、手机号收款 `.mobileCollection`、转账撤销 `.transferCancel`。

- [ ] **Step 2: 改接回调**：
  - 财富 `functionGrid.onItemTapped`：有 featureID → `open(feature:)`，nil → `.allFeatures(nil)`。产品卡片、搜索、客服、消息等保持 toast。
  - 生活 `serviceGrid.onItemTapped(section, index)`：同上规则；`onOrdersTapped` → `open(feature: .orders)`；城市、搜索、活动、横幅保持 toast。
  - 我的：`onSearchTapped` → `.allFeatures(nil)`；`onBenefitsTapped` → `.benefits`；`onVIPTapped` → `.customerLevel`；`branchCard.onTap` → `.branchQuery`；`branchCard.onItemTapped` → 对应 featureID；`securityCard.onTap` → `.securityCenter`；`securityCard.onItemTapped` → 对应 featureID；`orderCard.onTap` → `.orders`；头像 → `open(.customerInfo)`；资产负债 → `open(.assetLiability)`；月度收支 → `open(.incomeExpense(accountID: nil))`；两个账单入口 → `open(.ledgerAnalysis)`。退出登录、设置、更多、刷新网点、客户经理保持 toast。
  - 转账：`functionGrid.onItemTapped` → `open(feature:)`；`primaryCard` 主按钮 → `open(.transferForm(method:))`；次按钮 → `open(.transferRecords)` / `open(.transferLimits)`。注意 `openForm(method:)` 若传递 `payerAccountID` 等上下文，保留原调用不改。
  - `AssetLiabilityViewController.swift:215` 与 `MyAccountViewController.swift:128-136` 的带账户跳转改为 `router.open(.incomeExpense(accountID: itemId))`、`router.open(.transfer(payerAccountID: ...))`、`router.open(.accountDetail(accountID: ..., maskedNumber: masked))`，参数语义不变。

- [ ] **Step 3: 数据检查与构建**：`zsh scripts/check_banking_data.sh` 退出码 0（`MineModels.swift` 现依赖 `FeatureID`，Task 1 已把目录文件加入 sources）；构建通过。

- [ ] **Step 4: 自检**：`grep -n "showToast" ABank/Features/{Finance,Life,Mine,Transfer}/*.swift ABank/Features/Home/HomeViewController.swift`，确认剩余 toast 均属于设计 §1 排除范围（广告、产品卡片、客服、消息、公告、刷新、电话、退出、设置、更多）。`git diff --check`。

---

### Task 10: 整体验收与交接

**Files:**
- Modify: `docs/development-plan.md`（M3 状态与实施记录、下一会话 M4）
- Modify: `docs/continuity/tasks/m3-feature-catalog.md`、`docs/continuity/CURRENT.md`（更新时间）

- [ ] **Step 1: 数据检查**：`zsh scripts/check_banking_data.sh`，退出码 0。

- [ ] **Step 2: 正常构建**通过；`git diff --check` 通过。

- [ ] **Step 3: 模拟器验收**（查询当前设备；需要 QA 入口时用独立 Bundle ID `com.axdxa.AtlasBarKit.ABank.M3QA`，结束卸载并移除临时代码）逐项记录通过/失败：
  1. 首页默认宫格与改前一致。
  2. 编辑常用：删除、添加、拖拽排序、满 9 提示、取消不保存、完成后首页同步。
  3. 杀进程重启后常用与最近使用保留。
  4. 15 个已完成功能均能从全部功能页打开到正确页面（编译期穷举之外的运行验证）。
  5. 同一功能多入口一致：转账（首页快捷、全部功能、我的账户）、收支（首页、我的、全部功能）、转账限额（转账页、我的安全“转账设置”、全部功能）。
  6. 资产负债进入某账户收支仍带该账户。
  7. 搜索“转账”“账单”“网点”“xyz”。
  8. 待上线功能显示正确阶段；首页取号不再提示“已为您取号”。
  9. 连点宫格只推入一页。
  10. 320pt 宽度与最大动态字体下全部功能页、编辑页无重叠。
  截图存 `artifacts/abc-resources/verification/m3-*.png`，结果 `m3-qa-results.txt`（Git 忽略）。

- [ ] **Step 4: 更新文档**：`development-plan.md` 表格 M3 → 已完成，新增“M3 实施记录”（实现、数据检查、构建、UI 验收、验证边界：无原版截图待校准、程序触发与手指操作差异）与“下一会话：M4 安全中心”；任务记录写入已完成内容、验证结果、未验证项、下一步。

- [ ] **Step 5: 交付说明**：向用户汇报改动文件与验证结果；**不提交、不推送**，询问是否需要提交。
