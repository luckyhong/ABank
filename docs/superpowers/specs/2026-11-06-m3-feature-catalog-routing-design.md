# M3 功能目录与统一路由设计

日期：2026-11-06。基线：`main@75d3a68`（工作区干净）。对应 [开发计划](../../development-plan.md) 阶段 M3。

## 1. 目标与已确认决策

**目标**：为各 Tab 的功能入口建立统一的类型化路由；提供“全部功能”目录、功能搜索、常用功能编辑与最近使用；同一功能从不同入口进入同一页面。

用户已确认：

| 议题 | 决策 |
|---|---|
| 常用功能作用范围 | 驱动首页宫格：前 9 格显示常用，第 10 格固定“全部”。首页上方 4 个大快捷入口不可编辑 |
| 未完成入口 | 进入统一“即将上线”页，目录中显示“待上线”角标；不显示任何“已办理”类结果 |
| 路由覆盖范围 | 各 Tab 的功能宫格类入口；广告、产品卡片、客服、消息、公告保持现状，留待后续阶段 |
| 视觉参考 | 无原版截图，按现有设计系统设计，交接中标注“待截图校准” |

假设（未被否定即采用）：

- 默认常用 = 当前首页 9 个宫格（信用卡、养老社区、普惠金融、存款、理财产品、贷款、生活缴费、热门活动、城市专区），老用户首次看到的首页不变。
- 只记录“已完成功能”的最近使用，避免最近使用被“待上线”占满。

**验收标准**

1. 首页宫格、全部功能页、财富/生活/我的/转账页里同一功能进入同一控制器；需要上下文的入口（账户、月份）保留上下文。
2. 编辑常用（添加/移除/排序）后返回首页立即生效，重启后保留；取消编辑不保存。
3. 搜索能按名称和关键词找到功能，无结果显示空态。
4. 未完成功能统一进入“即将上线”页，显示计划阶段。
5. 首页“网点取号”不再提示“已为您取号”。
6. 数据检查、正常构建、模拟器验收通过；不新增网络请求，不改动账本数据。

**不在本阶段范围**：M4 及之后的业务页面本身；广告/产品卡片/客服/消息入口；外部 URL / 桌面快捷操作（M10 再加 URL→路由映射）；拼音搜索。

## 2. 方案选择

采用 **枚举路由 + 静态功能目录 + 可注入 Router**。

- 备选 B 字符串 URL 路由：灵活但重新依赖字符串，拼写错误只能在运行时发现。
- 备选 C 每个 Tab 一个 Coordinator：结构最规范，但需改写现有 45 处 push，超出 M3 范围。

A 方案编译期可检查，满足计划中“稳定 ID 与类型化路由、不依赖显示文案”的约定，且 M10 只需在其前面增加 URL 解析层。

## 3. 组成单元

```
ABank/Core/Routing/
  AppRoute.swift            路由枚举（含上下文参数）
  AppRouter.swift           协议 + 默认实现（route → 控制器 → push）
ABank/Features/AllFeatures/
  Models/FeatureCatalog.swift          FeatureID / FeatureCategory / FeatureDescriptor / 目录数据
  Models/FeatureSearch.swift           纯函数搜索
  FeaturePreferencesStore.swift        常用与最近使用的持久化
  AllFeaturesViewController.swift      全部功能 + 搜索
  FavoriteFeaturesEditViewController.swift  编辑常用
  ComingSoonViewController.swift       即将上线
  Views/FeatureGridCell.swift          目录/编辑共用单元（图标、标题、角标）
  Views/FeatureCategoryIndexView.swift 左侧分类索引
```

每个单元职责单一：目录是纯数据；搜索是纯函数；Store 只管持久化；Router 只管把路由变成页面；页面不直接创建其他业务控制器。

### 3.1 数据模型

```swift
enum FeatureID: String, Codable, CaseIterable   // 稳定 ID，持久化只存 rawValue
enum FeatureCategory: String, CaseIterable      // account, transfer, wealth, credit, life, service
struct FeatureDescriptor {
    let id: FeatureID
    let title: String
    let keywords: [String]          // 搜索别名，如 收支 → ["账单", "流水"]
    let imageName: String?          // 优先已有农行切图
    let systemIcon: String          // 无切图时回退
    let category: FeatureCategory
    let availability: Availability
    enum Availability { case available(AppRoute); case planned(stage: String?) }
}
enum FeatureCatalog {
    static let all: [FeatureDescriptor]
    static func descriptor(_ id: FeatureID) -> FeatureDescriptor
    static let defaultFavorites: [FeatureID]
}
```

`planned(stage: nil)` 表示尚未排入计划，即将上线页显示“后续规划”。

### 3.2 功能目录（共 69 项）

**已完成，接通现有页面（15 项）**

| ID | 名称 | 路由 → 控制器 |
|---|---|---|
| myAccount | 我的账户 | `.myAccount` → MyAccountViewController |
| accountDetail | 明细查询 | `.accountDetail(accountID: nil, maskedNumber: nil)` → AccountDetailQueryViewController |
| debitCard | 借记卡 | `.debitCardDetail` → DebitCardDetailViewController |
| transfer | 转账 | `.transfer(payerAccountID: nil)` → TransferViewController |
| accountTransfer | 账号转账 | `.transferForm(.account)` → TransferFormViewController |
| phoneTransfer | 手机号转账 | `.transferForm(.phone)` → TransferFormViewController |
| transferRecords | 转账记录 | `.transferRecords` → TransferRecordsViewController |
| transferLimits | 转账限额 | `.transferLimits` → TransferLimitsViewController（只读） |
| receipts | 电子回单 | `.transferReceipts` → TransferReceiptsViewController |
| incomeExpense | 收支 | `.incomeExpense(accountID: nil)` → IncomeExpenseViewController |
| monthlyBill | 月度账单 | `.ledgerAnalysis` → LedgerAnalysisViewController（默认上月） |
| ledgerSearch | 交易搜索 | `.ledgerSearch` → LedgerSearchViewController（查询范围默认上月，与月度账单一致） |
| assetLiability | 资产负债 | `.assetLiability` → AssetLiabilityViewController |
| loan | 贷款 | `.myLoan` → MyLoanViewController |
| customerInfo | 客户资料 | `.customerInfo` → CustomerInfoViewController |

**待上线（按分类，括号为计划阶段）**

- 账户：我要开卡（M5）、同号换卡（M5）
- 转账：信用卡还款、预约转账、向多人转账、他行卡转入、跨境服务、公益捐款、手机号收款、转账撤销（均为后续规划）
- 财富：存款（M7）、理财产品（M7）、基金（M7）、贵金属、债券、保险、证券期货、外汇、个人养老金
- 贷款信用卡：信用卡、普惠金融
- 生活：生活缴费（M8）、手机充值（M8）、小豆乐园（M6）、积分商城（M6）、政务民生、社保医保、校园、食堂、党费、车主服务、农银商城、医疗挂号、公积金、交通出行、美团外卖、电影演出、酒店旅行、快递寄件、爱心公益、养老社区、热门活动、城市专区
- 网点与安全：网点查询（M5）、网点取号（M5）、纪念币预约（M5）、安全中心（M4）、登录设置（M4）、支付设置（M4）、登录设备（M4）、权益中心（M6）、客户等级（M6）、我的订单（M6）、扫一扫（M10）

图标沿用各 Tab 已有 imageset（`abc_home_*`、`abc_wealth_menu_*`、`abc_life_menu_*`、`abc_mine_*`、`abc_transfer_*`），没有切图的使用当前代码中的系统图标。

### 3.3 路由

```swift
enum AppRoute: Equatable {
    case myAccount, debitCardDetail, transferRecords, transferLimits, transferReceipts
    case transfer(payerAccountID: String?)
    case accountDetail(accountID: String?, maskedNumber: String?)
    case transferForm(method: TransferMethod)
    case incomeExpense(accountID: String?)
    case ledgerAnalysis, ledgerSearch, assetLiability, myLoan, customerInfo
    case allFeatures(searchKeyword: String?)
    case editFavorites
    case comingSoon(FeatureID)
}

protocol AppRouting: AnyObject {
    func open(_ route: AppRoute, from source: UIViewController)
    func open(feature id: FeatureID, from source: UIViewController)   // 解析可用性并记录最近使用
}
```

- `AppRouter` 默认实现持有 `FeaturePreferencesStore` 与 `FinanceLedgerStore`，`makeViewController(for:)` 集中构造控制器；`open` 使用 `source.navigationController?.pushViewController`。
- `open(feature:)`：`.available(route)` → 记录最近使用并打开；`.planned` → 打开 `.comingSoon(id)`，不记录。
- `BaseViewController` 增加 `var router: AppRouting = AppRouter.shared`，便于测试注入；不改动现有 init 签名。
- 已有的带上下文跳转（如账户页 → 某账户收支）改为传入带参数的路由，参数语义不变。

### 3.4 偏好持久化 `FeaturePreferencesStore`

- 键 `abank.featurePreferences.v1`，JSON 编码 `{favorites: [String], recents: [String]}`，支持注入 `UserDefaults`。
- 常用：最多 9 个、去重、保持顺序、允许为空（首页只剩“全部”）。
- 最近使用：最多 8 个，最新在前，重复打开移到最前。
- 解码时丢弃未知 rawValue；整体解码失败时回退默认值，不崩溃。
- 无存储时返回 `FeatureCatalog.defaultFavorites`。
- 变更后发送 `FeaturePreferencesStore.didChangeNotification`，首页宫格据此刷新。
- 只存功能 ID，不存敏感数据。

### 3.5 搜索 `FeatureSearch`

`static func search(_ query: String, in catalog: [FeatureDescriptor]) -> [FeatureDescriptor]`

- 去除首尾空白；空查询返回空数组。
- 不区分大小写，在名称、关键词、分类名中做子串匹配；按空格拆成多个词时要求全部命中。
- 排序：名称前缀命中 > 名称包含 > 关键词/分类命中；同级按目录顺序；已完成功能与待上线功能同等排序但显示角标。

## 4. 页面设计（按现有设计系统）

### 4.1 全部功能 `AllFeaturesViewController`

- 导航标题“全部功能”。顶部搜索框（复用现有搜索栏样式）。
- 非搜索态从上到下：
  1. **我的常用**：横向一行最多 9 个图标，右侧“编辑”按钮 → `.editFavorites`。为空时显示“点击编辑添加常用功能”。
  2. **最近使用**：最多 8 个；为空时隐藏整段。
  3. **分类目录**：左侧分类索引（固定宽度），右侧按分类分组的 4 列宫格；点击左侧索引滚动到对应分组，滚动右侧时同步高亮左侧。
- 搜索态：输入即过滤，显示结果宫格；无结果显示“未找到相关功能”空态；清空恢复非搜索态。
- 带 `searchKeyword` 进入时直接进入搜索态并填入关键词。
- 待上线功能图标右上角灰色“待上线”角标；点击一律走 `router.open(feature:)`。
- 页面在 `viewWillAppear` 及偏好变更通知时刷新常用/最近使用。

### 4.2 编辑常用 `FavoriteFeaturesEditViewController`

- 导航栏左“取消”、右“完成”。编辑内容保存在页面内的草稿数组，点“完成”才写入 Store，“取消”直接返回。
- 上半区“我的常用（n/9）”：带删除角标，支持长按拖拽排序（`UICollectionView` drag & drop）。
- 下半区按分类列出全部功能：未加入的显示添加角标，已加入的显示勾选态不可重复添加。
- 已满 9 个时点击添加提示“最多添加 9 个常用功能”。
- 角标素材：工程内已有 `abc_resource_hp_allmenus_icon_add_b8a98a9e1ab8`、`abc_resource_hp_allmenus_icon_delete_c7006f39f5d4`（原包 45×45，SHA-256 见 `abc-feature-gap-assets.json`）。在导入脚本中新增语义名 `abc_allmenus_add`、`abc_allmenus_delete` 并更新来源清单，不虚构 2x/3x。

### 4.3 即将上线 `ComingSoonViewController`

- 居中显示功能图标、名称、说明“该功能正在建设中”，以及“计划阶段：M5 网点服务”或“后续规划”。
- 明确标注“学习项目演示”，底部“返回”按钮。无任何业务结果提示。

## 5. 入口改接清单

| 位置 | 改接内容 |
|---|---|
| 首页 4 个快捷入口 | 我的账户 / 转账 / 收支 → 对应功能；扫一扫 → `scan`（待上线） |
| 首页宫格 | 由 `FeaturePreferencesStore.favorites` 生成前 9 格 + 固定“全部”→ `.allFeatures(nil)`；`GridMenuView` 支持少于 10 项 |
| 首页搜索 | `.allFeatures(searchKeyword: 当前占位词)` |
| 首页网点服务 | 取号 → `branchQueue`；三个服务图标 → 对应功能；电话、刷新保持现状 |
| 财富宫格 10 项 | 对应 FeatureID；“全部” → `.allFeatures(nil)` |
| 生活宫格 20 项 | 对应 FeatureID；“全部” → `.allFeatures(nil)` |
| 我的页 | 顶部搜索 → `.allFeatures(nil)`；权益/等级/网点卡片/网点服务 4 项/安全中心及 4 项/订单 → 对应功能；“转账设置”→ `transferLimits`；已接通的头像、资产负债、收支、账单改走 router |
| 转账页 | 8 个功能项 → 对应 FeatureID；记录/限额/表单改走 router |

宫格与 FeatureID 的对应放在各页面的数据模型中（为 `HomeGridItem`、`WealthGridItem`、`LifeGridItem`、`MineGridItem`、`TransferFunctionItem` 增加可选 `featureID`），点击时不再按标题文字判断。

## 6. 错误与边界

- 未登记或缺失的 FeatureID：解码丢弃；路由层 `descriptor` 对所有 `FeatureID.allCases` 均有登记（由数据检查保证）。
- 无导航控制器的来源：`open` 不执行并在 Debug 下 `assertionFailure`。
- 快速重复点击：Router 在目标控制器已在栈顶且路由相同时忽略。
- 常用为空、最近使用为空、搜索无结果均有空态。
- 小屏 320pt：宫格 4 列下标题最多 2 行省略；分类索引宽度固定。

## 7. 验证

**数据检查** `scripts/check_feature_catalog.swift`，并加入 `scripts/check_banking_data.sh`：

- 每个 `FeatureID.allCases` 有且仅有一个描述；标题不重复。
- 每个 `.available` 路由都能由 `AppRouter.makeViewController` 生成控制器（类型断言）。
- 默认常用 9 项与原首页宫格一致。
- 常用：上限 9、去重、排序、空数组、持久化重读、未知 ID 丢弃、损坏 JSON 回退默认。
- 最近使用：上限 8、重复移到最前、待上线功能不记录。
- 搜索：空查询、大小写、关键词命中、多词、排序、无结果。
- 测试使用独立 UserDefaults suite。

**构建**：开发计划中的 `xcodebuild` 命令通过；`git diff --check` 通过。

**模拟器验收**（独立 Bundle ID 的 QA 包，结束后卸载、移除临时代码）：

- 首页宫格默认与改前一致；编辑常用（删除、添加、拖拽排序、满 9 提示、取消不保存）后首页同步；杀进程重启后保留。
- 首页、财富、生活、我的、转账里同一功能进入同一控制器；账户页进入收支仍带账户。
- 搜索“转账”“账单”“网点”结果正确，无结果空态。
- 待上线功能进入即将上线页并显示阶段；首页取号不再提示已取号。
- 320pt 宽度与大字体下全部功能页、编辑页无重叠。

## 8. 交付与交接

- 更新 `docs/development-plan.md` 的 M3 实施记录（实现、验证、未覆盖项、下一步 M4）。
- 新建 `docs/continuity/tasks/m3-feature-catalog.md` 任务记录，并更新 `docs/continuity/CURRENT.md` 索引。
- 未经用户要求不提交、不推送。
