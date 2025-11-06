## ABank（iOS 学习型项目 - 纯前端 UI 层）

ABank 是一个纯前端 UI 层实现的 iOS 学习型项目，用于自学并展示如何从 0 到 1 搭建一个银行类 App 的界面与交互结构。项目不涉及真实银行业务，仅使用假数据模拟界面与逻辑，旨在帮助 iOS 开发者在以下方面提升实战能力：

- **架构**：模块拆分、依赖边界、可测试性与可扩展性
- **模块化**：功能模块、组件复用、资源管理
- **UI 布局**：Auto Layout/Storyboard/代码布局实践与约束管理
- **命名规范**：统一的类型、变量、资源与文件命名规则


### 项目定位与范围
- **仅 UI/交互层**：不接入真实网络/支付/风控等服务
- **假数据驱动**：通过本地 JSON/内存模型模拟接口数据
- **学习优先**：重视代码可读性与可维护性，适度留白给练习


### 目标功能（示例）
- 启动与登录引导（纯前端校验）
- 首页账户概览（余额、账单条目假数据）
- 转账/卡片管理/交易明细列表（分页与筛选交互）
- 通知中心与设置页（本地化与深浅色模式）


### 架构建议（可按需调整）
- 分层建议：`UI`（View/ViewController） + `Presentation`（ViewModel/Presenter） + `DataProvider`（本地假数据）
- 事件流：`View` -> `ViewModel` -> `DataProvider` -> 更新 `ViewModel State` -> 绑定刷新 `View`
- 导航管理：集中管理页面路由与参数，避免在 `ViewController` 中散落跳转逻辑


### 模块化建议
- `Features/`：按功能域拆分（如 `Home`、`Transfer`、`Cards`、`Settings`）
- `Shared/`：可复用组件（如 `UIComponents`、`DesignSystem`、`Utilities`、`NetworkingMocks`）
- `Resources/`：图片、颜色、字符串、本地化等

### 当前项目结构

项目已完全迁移到纯代码布局，采用模块化架构：

```
ABank/
├── Core/                    # 核心控制器
│   └── MainTabBarController.swift  # TabBar主框架（首页、财富、生活、乡村振兴、我的）
├── Features/                # 功能模块
│   ├── Home/               # 首页模块（已完成）
│   │   ├── HomeViewController.swift
│   │   └── Views/
│   │       ├── AccountCardView.swift      # 账户卡片
│   │       ├── QuickActionsView.swift     # 快捷功能
│   │       └── NoticeView.swift           # 公告栏
│   ├── Finance/            # 财富模块（基础占位）
│   │   └── FinanceViewController.swift（类名：WealthViewController）
│   ├── Life/               # 生活模块（基础占位）
│   │   └── LifeViewController.swift
│   ├── Rural/              # 乡村振兴模块（基础占位）
│   │   └── RuralRevitalizationViewController.swift
│   └── Mine/               # 我的模块（待完善）
├── Shared/                 # 共享资源
│   ├── DesignSystem/       # 设计系统
│   │   ├── Color.swift     # 颜色规范（参考农业银行绿色系）
│   │   ├── Font.swift      # 字体规范
│   │   └── Spacing.swift   # 间距规范
│   └── Utilities/          # 工具类扩展
│       ├── UIView+Extensions.swift
│       └── String+Extensions.swift
├── Data/                   # 数据层
│   └── MockDataProvider.swift  # 假数据提供者
└── Assets.xcassets/        # 资源文件
```

**技术栈**：
- ✅ 纯代码布局（SnapKit）
- ✅ CocoaPods 依赖管理
- ✅ 模块化架构设计
- ✅ 设计系统统一管理
 - ✅ 基类控制器（`BaseViewController`）统一导航、Loading、Toast


### 命名规范（建议）
- 类型名使用 `PascalCase`，实例/变量使用 `camelCase`
- 视图后缀：`View`、`Cell`、`Header`；控制器后缀：`ViewController`
- ViewModel 以 `SomethingViewModel` 命名，状态以 `State` 命名，事件以 `Action` 命名
- 资源命名具备语义且可检索，如颜色 `Color.primaryBackground`，图片 `img_card_visa`


### 假数据策略
- 使用本地 `JSON` 文件与 `MockDataProvider` 提供数据
- 分层模拟：列表分页、空态、错误态（本地触发不同分支）
- 保持模型与 UI 解耦：`Decodable` 模型 -> `ViewModel` 映射


### 运行方式

**重要**：项目已迁移到纯代码布局，使用 CocoaPods 管理依赖。

1. **安装依赖**（首次运行必须执行）：
   ```bash
   cd /Users/hanjihong/workspace/ABank
   export LANG=en_US.UTF-8  # 如果遇到编码问题
   pod install
   ```

2. **打开项目**：
   - 必须使用 `ABank.xcworkspace` 打开（不是 `.xcodeproj`）
   - 在 Xcode 中：File -> Open -> 选择 `ABank.xcworkspace`

3. **运行项目**：
   - 选择目标设备（模拟器或真机）
   - 按 `Cmd + R` 运行
   - 所有数据来自本地假数据，运行不依赖网络

> 如果 `pod install` 失败，可能是网络问题，请稍后重试或使用代理。


### 代码风格
- 保持清晰的分层边界与依赖方向
- 减少控制器体积：将状态与业务 UI 逻辑沉淀到 ViewModel/Presenter
- 仅为非显而易见的逻辑添加注释；命名应自解释


### 开发进度

#### ✅ 已完成（v0.2）
- [x] 项目框架搭建（纯代码布局）
- [x] CocoaPods 集成（SnapKit）
- [x] 设计系统（颜色、字体、间距）
- [x] TabBar 主框架（首页、财富、生活、乡村振兴、我的）
 - [x] 首页模块完整实现
  - [x] 账户卡片（余额显示/隐藏）
  - [x] 快捷功能（8个功能入口）
  - [x] 公告栏
- [x] 假数据提供层（MockDataProvider）

#### 🚧 进行中 / 待完善
- [ ] 转账模块详细实现
- [ ] 理财模块（产品列表、详情）
- [ ] 我的模块（个人中心、设置）
- [ ] 交易记录列表（分页、筛选）
- [ ] 更多假数据场景

#### 📋 计划中
- [ ] 登录/注册流程
- [ ] 动画过渡与交互反馈
- [ ] 深色模式支持
- [ ] 本地化（多语言）
- [ ] 无障碍支持


### 贡献
欢迎通过 Issue/PR 讨论架构与实现方式，目标是让更多初学者从中学到“如何把 UI 做对、把结构搭好”。


### 免责声明
本项目仅供学习交流，不包含任何真实银行业务与数据。


