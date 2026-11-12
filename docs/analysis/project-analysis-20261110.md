# ABank 当前项目分析

分析日期：2026-11-10（会话日期）。分支 `main`，HEAD `ea8a238d8e09c593f76a8982921f7efd8f9c9806`。

## 判断

ABank 已从静态页面练习发展为具有多条本地业务闭环的 UIKit 示例 App。共享账本、类型化路由和独立规则检查已经形成基础；当前重点适合转向数据错误处理、入口一致性与 Widget 验收。开发计划中的 M0–M10“完成”代表阶段范围，不代表功能目录里的每项业务、所有设备和所有点击路径都已验收。

本次检查源码、当前差异和现有脚本，并执行构建及数据检查；没有逐页运行 UI，也没有操作正常 App 数据。银行业务继续为本地模拟数据，资讯是公开 RSS 例外。

## 当前规模与工程现场

| 项目 | 当前结果 |
| --- | --- |
| 主工程 | UIKit、SnapKit 5.6.0、CocoaPods、Swift 5，App target 最低 iOS 15.6 |
| 目标 | 主 App + SwiftUI/WidgetKit 扩展；未配置独立测试 target |
| 代码规模 | App 与 Widget 合计 268 个 Swift 文件、38,259 行；不含 Pods 和检查脚本 |
| 功能组织 | 15 个 Features 一级目录、89 个 `*ViewController.swift` 文件；这是目录/文件统计，不代表独立编译模块或精确页面数 |
| 功能目录 | 71 项定义：35 项标记可用，36 项规划中；该比例不应当作项目整体完成率 |
| 素材 | 3,175 个 imageset，资产目录原始文件约 41.04 MiB；没有据此认定哪些可删除，也未测发行包大小 |
| Git | 接手时暂存区为空，3 个已有未暂存配置文件；本轮保留原状 |

已有差异为：工程中删除两个冗余分组 `name`、用户 Scheme 管理增加 Widget 排序、Info.plist 的 URL scheme 条目移动位置。从当前差异看，没有业务逻辑变化。本次新增分析文件和续接索引，不提交、不推送。

依据：[Podfile](../../Podfile)、[锁定依赖](../../Podfile.lock)、[target 配置](../../ABank.xcodeproj/project.pbxproj)、[功能目录](../../ABank/Features/AllFeatures/Models/FeatureCatalog.swift)。

## 实际架构

| 区域 | 当前职责与实现 |
| --- | --- |
| Core | 应用容器、五个 Tab、导航样式、统一路由、账务页面刷新、Widget 快照 |
| Features | 按功能域组织控制器、视图、模型、规则和部分 Store，属于目录模块化 |
| Shared | 设计常量、日期与视图工具 |
| Data | `MockDataProvider` 提供首页展示模型；并非所有业务数据都由这里提供 |
| ABankWidget | 独立扩展 target，复用共享快照、格式化与链接模型 |

主要控制流是：功能入口 → `AppRouter` → 页面 → Store/规则 → 本地快照持久化 → 通知刷新页面。页面采用 UIKit 控制器配合拆分视图，并未建立完整统一的 MVVM 层。资讯使用独立的 `actor NewsRepository`，负责并发读取、缓存和降级。

有价值的基础：

- `AppRoute` 和 `AppRouter` 用穷举分支构造页面，并对栈顶同一路由去重，入口可以保留账户等上下文。见 [AppRouter.swift:35](../../ABank/Core/Routing/AppRouter.swift#L35)。
- `FinanceLedgerStore` 在主 actor 上管理统一根记录。转账、理财、缴费与贷款扩展把关联订单、流水和余额变动写入同份账本。见 [账本提交:164](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L164)、[理财购买:71](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Wealth.swift#L71)、[缴费:84](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Payment.swift#L84)、[提前还款:100](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Loan.swift#L100)。
- `BankingDataViewController` 统一返回页面、前台激活、显著时间变化和午夜刷新。见 [刷新基础:6](../../ABank/Core/Base/BankingDataViewController.swift#L6)。
- 可注入时钟、存储和失败场景，检查脚本使用隔离的数据域，关键业务规则可以脱离 UIKit 检查。

需要注意的边界：共享账本物理位置仍在 `Features/Mine`，却承担跨域职责；路由虽能注入账本，但部分页面仍直接使用 `.shared`，依赖注入没有贯穿全部页面。每次 `load()` 都会解码整份 JSON，多张卡片/列表反复读取会增加工作量；这是后续数据增长时的优化候选，本次没有性能测量。

## 功能覆盖

| 领域 | 已在代码中接通 | 当前边界 |
| --- | --- | --- |
| 账户/收支 | 账户、借记卡、交易明细、分类备注、账本归属、搜索、月度统计、资产负债、别名和权限 | 旧编辑路径错误处理存在缺口，见下文 |
| 转账 | 账号/手机号、收款伙伴、确认、结果、历史、限额、模拟回单分享 | 多人、预约、跨境、撤销等仍规划中 |
| 财富 | 产品列表、详情、风险测评、购买、赎回、持仓、订单 | 存款/基金仍为“M7 扩展”；财富首页若干专区仅提示 |
| 安全 | 登录/支付设置、设备与移除、转账限额、金额隐藏 | 属于模拟设置，不代表系统级认证或银行风控 |
| 网点 | 城市、列表、详情、营业时间、取号、预约、取消和历史 | 本地网点与示意图 |
| 权益/订单 | 积分、小豆、领取兑换、卡券、订单；合并展示充值缴费订单 | 理财订单单独由理财页面管理，不能称作所有领域订单完全聚合 |
| 充值缴费 | 手机充值、优惠券、模拟水电燃气账单、确认和结果 | 固定模拟账户；跨 Store 卡券使用通过失败补偿处理 |
| 贷款 | 任务、进度、证明、还款计划、提前还款结果 | 模拟合同与计算，无真实审批或还款 |
| 资讯 | 4 个公开 RSS 频道、并发加载、缓存、筛选、搜索、原文浏览 | 本轮检查用模拟网络，未验证当前 RSS 在线返回 |
| 桌面入口 | 快捷操作、演示扫码、本地关键词助手、小中号余额 Widget | 扫码用固定示例；助手为规则匹配；Widget 实机体验待验 |

目录状态依据：[FeatureCatalog.swift:106](../../ABank/Features/AllFeatures/Models/FeatureCatalog.swift#L106)。订单聚合依据：[OrdersViewController.swift:38](../../ABank/Features/Benefits/OrdersViewController.swift#L38)。资讯依据：[NewsRepository.swift:34](../../ABank/Features/News/Data/NewsRepository.swift#L34)。

## 优先问题

### 1. 旧编辑路径会覆盖损坏账本，应优先修复

`load()` 遇到不可解码的持久化数据时返回种子账本；`update()` 随后修改、重算并调用 `save()`，没有采用主要交易提交所用的严格读取。分类、备注和账本归属正使用这条路径。

本轮在独立 UserDefaults suite 中写入损坏 JSON，调用 `load()` 后确认原字节仍在，再调用 `updateTransactionDetail(...note:)`。结果原字节被一份可解码的种子衍生账本覆盖，问题已复现。临时 suite 在进程退出前删除，正常 App 数据未改动。

另外，`save()` 的 Bool 结果被 `update()` 丢弃，页面无法知道备注等修改是否保存失败。建议所有修改使用严格读取并向页面抛出错误或返回结果；损坏账本应阻止写回并提供明确恢复入口。修复时需增加针对“旧编辑路径”的检查，现有转账损坏数据检查覆盖不到这里。

证据：[读取:45](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L45)、[更新:200](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L200)、[详情修改:233](../../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L233)、[备注提交:429](../../ABank/Features/Mine/IncomeExpense/IncomeExpenseDetailViewController.swift#L429)。

### 2. 首页入口体验仍有明显断点

默认 9 个常用功能中，只有理财产品、贷款、生活缴费 3 个标记可用，其余 6 个仍进入规划页。这不影响目录的明确状态设计，但会让首次使用者高频遇到未完成入口。财富首页搜索和生活首页搜索也仍只显示 Toast，而首页已接入真正的功能目录搜索。

建议默认常用优先放已可用入口，再统一搜索与专区的行为。仍在规划的业务继续明确显示状态，不需要一次性扩展所有业务。

证据：[默认常用:75](../../ABank/Features/AllFeatures/Models/FeatureCatalog.swift#L75)、[首页搜索:247](../../ABank/Features/Home/HomeViewController.swift#L247)、[财富搜索:186](../../ABank/Features/Finance/FinanceViewController.swift#L186)、[生活搜索:167](../../ABank/Features/Life/LifeViewController.swift#L167)。

### 3. 构建通过，但 actor 隔离警告需要收敛

本次完整构建日志按源码路径/行列去重后有 33 处警告：23 处涉及 actor 隔离，10 处为旧按钮 inset API。当前 Swift 5 模式允许构建，编译器明确指出部分隔离调用在 Swift 6 模式下将成为错误。应先梳理默认参数读取 `.shared`、非隔离回调调用隔离方法等问题，再考虑切换语言模式。

示例：[路由初始化:30](../../ABank/Core/Routing/AppRouter.swift#L30)、[订单页初始化:17](../../ABank/Features/Benefits/OrdersViewController.swift#L17)。这不是本次已发现的运行崩溃，不能把未来兼容风险说成当前编译失败。

### 4. Widget 的代码完成度高于验收完成度

当前 App 会在账本变化和回到前台时更新 App Group 快照；Widget 小中号读取快照，点击经白名单路由进入 App。无姓名和卡号出现在快照中。扩展已随本次构建成功，但本轮没有桌面添加、点击跳转、转账后刷新及真机 App Group 签名证据。

时间线使用 `.never`，月度收支归零规则在视图计算时生效。仍需实测 App 不打开、跨月期间系统实际何时重绘，不能仅凭纯函数检查认定桌面内容会准时更新。此外，工程对 Foundation 有写死 iPhoneOS18.0 SDK 的引用，是可移植性清理候选，本机本次构建未受阻。

证据：[同步:25](../../ABank/Core/Widget/WidgetSnapshotWriter.swift#L25)、[时间线:31](../../ABankWidget/ABankWidget.swift#L31)、[月份判断:71](../../ABankWidget/WidgetViews.swift#L71)、[App Group](../../Config/ABank.entitlements)、[SDK 引用:47](../../ABank.xcodeproj/project.pbxproj#L47)。

## 本轮验证

| 验证 | 结果 | 边界 |
| --- | --- | --- |
| `zsh scripts/check_banking_data.sh` | 12 组数据检查与卡名检查全部通过 | 数据/规则检查，非完整 UI 操作 |
| `docs/news-data.md` 中独立 Swift 编译命令 | 解析、分类、缓存、部分失败、过期和取消检查通过 | 模拟网络，不是当前网络实测 |
| Debug 模拟器无签名构建 | `BUILD SUCCEEDED`，包含 Widget 扩展 | 未签名、未安装运行，不证明真机能力 |
| 损坏数据后的旧备注编辑 | 在独立数据域复现覆盖问题 | 临时检查位于 `/private/tmp` |
| ArchAtlas profile 校验 | 0 个结构错误，来源文件与行号存在 | 结构校验不能替代语义审阅 |

构建命令：

```sh
xcodebuild -workspace ABank.xcworkspace -scheme ABank \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/ABank-Analysis-20261110 \
  CODE_SIGNING_ALLOWED=NO build
```

沙箱内首次 Xcode 调用因 CoreSimulator/访问权限失败，工具审批后在沙箱外按相同配置成功；首次环境错误不应记作工程编译缺陷。日志保留在 `/private/tmp/abank-analysis-{data,news,build-unrestricted}.log`，临时路径不保证长期留存。

本轮未覆盖：逐页 UI、手势、分享最终保存、小屏/大字体/暗色模式、真机签名、Widget 桌面行为、当前公开 RSS 在线表现、启动性能和内存。项目目前没有独立 XCTest target，也未发现仓库内 CI 配置；已有脚本是有效的规则验证基础。

## 建议实施顺序

1. 统一账本修改的严格读取与失败反馈，补上旧编辑路径的损坏数据/写入失败检查。
2. 完成 Widget 添加、点击、账本刷新、跨月和真机 App Group 验证。
3. 调整默认常用和搜索/活动入口，减少首次体验的断点。
4. 收敛 actor 隔离与旧 UI API 警告，统一共享服务的归属与注入边界。
5. 建立最小持续检查入口，再按实际测量决定缓存解码、金额模型及素材管理的优化范围。

有来源的结构档案：[project-profile-20261110.json](project-profile-20261110.json)。上述建议未在本轮实施。
