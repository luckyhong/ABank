# ABank（iOS 学习型项目 · 纯前端 UI）

ABank 是一个纯前端 UI 层实现的 iOS 学习项目，用于从 0 到 1 搭建银行类 App 的界面与交互结构。项目不接入真实银行业务，全部使用本地假数据，侧重模块化、设计系统与可维护的页面结构。

- **架构**：按功能域拆分模块，统一基类与设计系统
- **布局**：纯代码 + SnapKit Auto Layout
- **数据**：`MockDataProvider` / 本地 Store 驱动界面
- **目标**：可读、可扩展，方便练习与二次开发

## 项目定位

| 范围 | 说明 |
|------|------|
| 仅 UI / 交互层 | 不接入真实网络、支付、风控 |
| 假数据驱动 | 内存模型 + Store 模拟业务数据 |
| 学习优先 | 重视命名、分层与组件复用 |

## 技术栈

- **语言 / 平台**：Swift 5 · iOS 15.6+
- **布局**：纯代码（SnapKit `~> 5.6`）
- **依赖管理**：CocoaPods
- **工程入口**：`ABank.xcworkspace`（勿直接打开 `.xcodeproj`）

## 主框架（TabBar）

| Tab | 模块 | 状态 |
|-----|------|------|
| 首页 | `Features/Home` | ✅ 已完成 |
| 财富 | `Features/Finance` | ✅ 已完成 |
| 生活 | `Features/Life` | ✅ 已完成 |
| 资讯 | `Features/News` | ✅ 已完成 |
| 我的 | `Features/Mine` | ✅ 核心流程已完成 |

> `Features/Transfer` 仍为占位页，可从首页等入口扩展。

## 功能概览

### 首页 Home
账户概览、搜索栏、公告滚动、快捷入口、宫格菜单、热门活动、财富精选、网点服务、消保宣导等区块。

### 财富 Finance（Wealth）
登录引导卡、功能宫格、热点、精选产品、稳健增长、收益先行、热门存款、债券指数、闲钱专区、理财学习等分区展示。

### 生活 Life
搜索、Banner、生活服务宫格、多彩活动、瀑布流内容等。

### 资讯 News
推荐 / 关注 Tab、搜索、Feed 列表、话题与 Banner 等资讯流 UI。

### 我的 Mine（当前重点）
个人中心首页，并串联以下子模块：

| 子模块 | 能力 |
|--------|------|
| **客户信息** `CustomerInfo` | 资料展示与编辑、修改手机号、涉税身份申报（本地 Store） |
| **资产负债** `AssetLiability` | 汇总卡片、分类列表、提示与公告 |
| **收支明细** `IncomeExpense` | 列表、详情、日期 / 账户 / 分类筛选与选择面板 |
| **我的贷款** `MyLoan` | 贷款概览、合同列表、贷款详情、应还明细、还款详情、提前还款、用款记录、筛选与日期选择 |
| **财务账本** `FinanceLedger` | `FinanceLedgerStore` 统一提供资产负债、月度流水等聚合数据 |

## 项目结构

```
ABank/
├── Core/
│   ├── Base/BaseViewController.swift      # 导航 / Loading / Toast 基类
│   └── MainTabBarController.swift         # 五 Tab 主框架
├── Features/
│   ├── Home/                              # 首页
│   ├── Finance/                           # 财富（WealthViewController）
│   ├── Life/                              # 生活
│   ├── News/                              # 资讯
│   ├── Mine/                              # 我的
│   │   ├── Views/                         # 个人中心卡片组件
│   │   ├── Models/                        # 业务模型
│   │   ├── CustomerInfo/                  # 客户信息
│   │   ├── AssetLiability/                # 资产负债
│   │   ├── IncomeExpense/                 # 收支明细
│   │   ├── MyLoan/                        # 我的贷款
│   │   └── FinanceLedger/                 # 财务数据 Store
│   └── Transfer/                          # 转账（占位）
├── Shared/
│   ├── DesignSystem/                      # Color / Font / Spacing / CornerRadius
│   └── Utilities/                         # UIView、String 扩展
├── Data/
│   └── MockDataProvider.swift             # 假数据入口
└── Assets.xcassets/
```

## 架构说明

- **分层**：`ViewController` + 自定义 `View` + `Models` + `MockDataProvider` / `*Store`
- **设计系统**：统一农业银行风格绿色系颜色、字体、间距与圆角
- **导航**：各 Tab 内嵌 `UINavigationController`，子页通过 `push` 进入
- **状态**：客户信息、财务账本等使用本地 Store，在页面 `viewWillAppear` 时刷新展示

## 运行方式

1. **安装依赖**（首次或 Podfile 变更后）：

```bash
cd /path/to/ABank
export LANG=en_US.UTF-8   # 如遇编码问题
pod install
```

2. **打开工程**：使用 `ABank.xcworkspace`（不要用 `.xcodeproj`）。

3. **运行**：选择模拟器或真机，`Cmd + R`。全部数据来自本地，无需网络。

> `pod install` 失败多为网络问题，可重试或配置代理。

## 命名规范

- 类型：`PascalCase`；变量 / 属性：`camelCase`
- 视图后缀：`View`、`Cell`、`Header`；控制器：`ViewController`
- Store：`SomethingStore`；模型按业务域放在对应 `Models/`
- 颜色等设计 token：`abank*` 前缀（如 `.abankPrimary`）

## 开发进度

### 已完成
- [x] 工程骨架、CocoaPods、SnapKit、设计系统、基类控制器
- [x] TabBar：首页 / 财富 / 生活 / 资讯 / 我的
- [x] 首页、财富、生活、资讯完整 UI
- [x] 我的：个人中心、客户信息、资产负债、收支明细、我的贷款（含还款 / 提前还款 / 用款记录等）
- [x] 财务账本 Store 与假数据驱动

### 待完善
- [ ] 转账模块完整流程
- [ ] 登录 / 注册引导
- [ ] 深色模式、本地化、无障碍
- [ ] 更多空态 / 错误态假数据场景
- [ ] 动画与微交互打磨

## 贡献

欢迎通过 Issue / PR 讨论架构与实现，目标是把 UI 做对、把结构搭好。

## 免责声明

本项目仅供学习交流，不包含任何真实银行业务与数据。
