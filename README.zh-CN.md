# ABank

[English](README.md) · [中文](README.zh-CN.md)

纯前端 UI 层的 iOS 学习型银行 App，用假数据从 0 到 1 练习模块化架构、设计系统与可维护的页面结构。

> **学习项目，非真实银行应用。** 不含真实业务、网络请求或敏感数据持久化。

---

## 目录

- [项目定位](#项目定位)
- [技术栈](#技术栈)
- [功能一览](#功能一览)
- [项目结构](#项目结构)
- [架构说明](#架构说明)
- [快速开始](#快速开始)
- [命名规范](#命名规范)
- [开发进度](#开发进度)
- [贡献与免责](#贡献与免责)

---

## 项目定位

| 维度 | 说明 |
|------|------|
| 范围 | 仅 UI / 交互层，不接入真实网络、支付、风控 |
| 数据 | 内存模型 + `MockDataProvider` / 本地 Store 驱动界面 |
| 目标 | 可读、可扩展，便于练习架构、模块化、布局与命名 |

适合用来：

- 练习按功能域拆分模块与页面导航
- 搭建统一设计系统（颜色 / 字体 / 间距 / 圆角）
- 用 SnapKit 纯代码布局复杂银行类界面
- 用假数据模拟多页面业务流与本地状态刷新

---

## 技术栈

| 项目 | 选型 |
|------|------|
| 语言 | Swift 5 |
| 平台 | iOS 15.6+ |
| UI | UIKit · 纯代码布局 |
| 布局 | [SnapKit](https://github.com/SnapKit/SnapKit) `~> 5.6` |
| 依赖 | CocoaPods |
| 入口 | `ABank.xcworkspace`（请勿直接打开 `.xcodeproj`） |

---

## 功能一览

### 主框架（TabBar）

| Tab | 模块路径 | 状态 |
|-----|----------|------|
| 首页 | `Features/Home` | 已完成 |
| 财富 | `Features/Finance` | 已完成 |
| 生活 | `Features/Life` | 已完成 |
| 资讯 | `Features/News` | 已完成 |
| 我的 | `Features/Mine` | 核心流程已完成 |

从首页等入口可进入 **转账**（`Features/Transfer`）与 **我的账户**（`Features/MyAccount`）等二级页面。

### 模块说明

<details>
<summary><strong>首页 Home</strong></summary>

账户概览、搜索栏、公告滚动、快捷入口、宫格菜单、热门活动、财富精选、网点服务、消保宣导等区块。

</details>

<details>
<summary><strong>财富 Finance</strong></summary>

登录引导卡、功能宫格、热点、精选产品、稳健增长、收益先行、热门存款、债券指数、闲钱专区、理财学习等分区展示。

</details>

<details>
<summary><strong>生活 Life</strong></summary>

搜索、Banner、生活服务宫格、多彩活动、瀑布流内容等。

</details>

<details>
<summary><strong>资讯 News</strong></summary>

推荐 / 关注 Tab、搜索、Feed 列表、话题与 Banner 等资讯流 UI。

</details>

<details>
<summary><strong>我的 Mine</strong></summary>

个人中心首页，并串联以下子模块：

| 子模块 | 路径 | 能力 |
|--------|------|------|
| 客户信息 | `CustomerInfo` | 资料展示与编辑、修改手机号、涉税身份申报（本地 Store） |
| 资产负债 | `AssetLiability` | 汇总卡片、分类列表、提示与公告 |
| 收支明细 | `IncomeExpense` | 列表、详情、日期 / 账户 / 分类筛选与选择面板 |
| 我的贷款 | `MyLoan` | 贷款概览、合同、详情、应还 / 还款 / 提前还款、用款记录 |
| 财务账本 | `FinanceLedger` | `FinanceLedgerStore` 聚合资产负债、月度流水等数据 |

</details>

<details>
<summary><strong>转账 Transfer · 我的账户 MyAccount</strong></summary>

- **转账**：公告、主操作卡、功能宫格、最近收款人等页面级 UI（可继续扩展完整转账流程）
- **我的账户**：借记卡展示、信用卡广告、开户入口；支持借记卡详情、账户明细查询与筛选

</details>

---

## 项目结构

```text
ABank/
├── Core/
│   ├── Base/BaseViewController.swift   # 导航 / Loading / Toast 基类
│   └── MainTabBarController.swift      # 五 Tab 主框架
├── Features/
│   ├── Home/                           # 首页
│   ├── Finance/                        # 财富
│   ├── Life/                           # 生活
│   ├── News/                           # 资讯
│   ├── Mine/                           # 我的（含客户信息、资产负债等子域）
│   ├── Transfer/                       # 转账
│   └── MyAccount/                      # 我的账户
├── Shared/
│   ├── DesignSystem/                   # Color / Font / Spacing / CornerRadius
│   └── Utilities/                      # UIView、String 等扩展
├── Data/
│   └── MockDataProvider.swift          # 假数据入口
└── Assets.xcassets/
```

各功能模块通常按 `ViewController` + `Views/` + `Models/` 组织；`Mine` 等复杂域再按业务子目录拆分。

---

## 架构说明

```text
┌─────────────────────────────────────────┐
│              Features（按功能域）          │
│   ViewController  →  Views  →  Models   │
└──────────────────┬──────────────────────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
  Core/Base    Shared/DS     Data / Store
  基类能力      设计 Token    假数据 & 本地状态
```

- **分层**：`ViewController` + 自定义 `View` + `Models` + `MockDataProvider` / `*Store`
- **设计系统**：农业银行风格绿色系，统一颜色、字体、间距与圆角（`abank*` 前缀）
- **导航**：各 Tab 内嵌 `UINavigationController`，子页通过 `push` 进入
- **状态**：客户信息、财务账本等使用本地 Store，在 `viewWillAppear` 时刷新展示

---

## 快速开始

### 环境要求

- macOS + Xcode（支持 iOS 15.6 SDK）
- [CocoaPods](https://cocoapods.org/)

### 安装与运行

```bash
cd /path/to/ABank
export LANG=en_US.UTF-8   # 如遇 pod 编码问题可设置
pod install
open ABank.xcworkspace
```

在 Xcode 中选择模拟器或真机，按 `Cmd + R` 运行。全部数据来自本地，无需网络。

> `pod install` 失败多为网络问题，可重试或配置代理。

---

## 命名规范

| 类别 | 约定 | 示例 |
|------|------|------|
| 类型 | `PascalCase` | `MineViewController` |
| 变量 / 属性 | `camelCase` | `pageData` |
| 视图 | `View` / `Cell` / `Header` 后缀 | `MineProfileHeaderView` |
| 控制器 | `ViewController` 后缀 | `LoanDetailViewController` |
| Store | `SomethingStore` | `CustomerInfoStore` |
| 设计 Token | `abank*` 前缀 | `.abankPrimary` |

模型按业务域放在对应模块的 `Models/` 目录下。

---

## 开发进度

### 已完成

- [x] 工程骨架、CocoaPods、SnapKit、设计系统、基类控制器
- [x] TabBar：首页 / 财富 / 生活 / 资讯 / 我的
- [x] 首页、财富、生活、资讯完整 UI
- [x] 我的：个人中心、客户信息、资产负债、收支明细、我的贷款
- [x] 转账页、我的账户（借记卡详情、账户明细查询）
- [x] 财务账本 Store 与假数据驱动

### 待完善

- [ ] 转账完整业务流（确认、结果页等）
- [ ] 登录 / 注册引导
- [ ] 深色模式、本地化、无障碍
- [ ] 更多空态 / 错误态假数据场景
- [ ] 动画与微交互打磨

---

## 贡献与免责

欢迎通过 Issue / PR 讨论架构与实现，目标是把 UI 做对、把结构搭好。

**免责声明**：本项目仅供学习交流，界面与数据均为模拟，不构成任何金融服务建议，亦与任何真实银行机构无关。
