# CLAUDE.md

本文件为在此仓库中工作的 AI 助手提供指引。

## 仓库现状

ABank 已是可运行的 UIKit + CocoaPods 工程：

- 入口：打开 **`ABank.xcworkspace`**（勿直接打开 `.xcodeproj`）
- 依赖：`Podfile` 中 SnapKit `~> 5.6`；首次或变更后执行 `pod install`
- 平台：App Target **iOS 15.6+**，Swift 5
- 源码根目录：`ABank/`（`Core` / `Features` / `Shared` / `Data` / `Assets.xcassets`）

动手前请以工作区真实文件为准，不要假设不存在的工具链（如尚未引入的 SPM、测试 Target 等）。

## 项目定位

纯前端 UI 学习项目：银行类 App 的界面与交互结构，**全部假数据**（`MockDataProvider`、本地 `*Store`）。不涉及真实银行业务。

重点能力练习：架构设计、模块化、UI 布局、命名规范。

**不要**为银行业务引入真实网络请求、敏感数据持久化或后端集成。

资讯模块例外（用户明确授权）：可读取中国新闻网的公开 RSS 及新闻配图，缓存公开新闻元数据，原文通过系统浏览器组件打开。其余账户、转账、贷款等模块继续使用本地模拟数据。

## 常用命令

```bash
# 安装 / 更新 Pods
export LANG=en_US.UTF-8
pod install

# 用 Xcode 打开
open ABank.xcworkspace
```

若需命令行构建，在本机配置好签名与模拟器后可使用 `xcodebuild`，scheme 一般为 `ABank`（以 Xcode 中实际 scheme 为准）。当前仓库**未**配置独立测试 Target / CI——新增后再补充此处说明。

## 模块速览

| 区域 | 说明 |
|------|------|
| `Core/` | `BaseViewController`、`MainTabBarController`（五 Tab） |
| `Features/Home` · `Finance` · `Life` · `News` · `Mine` | 五个主 Tab |
| `Features/Transfer` · `MyAccount` | 二级业务页（从首页等入口进入） |
| `Shared/DesignSystem` | Color / Font / Spacing / CornerRadius（`abank*`） |
| `Data/MockDataProvider.swift` | 假数据入口 |

文档：英文 [README.md](README.md)（默认）· 中文 [README.zh-CN.md](README.zh-CN.md)。
