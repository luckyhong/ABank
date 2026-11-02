# 项目工作入口

<!-- agent-continuity:v1 -->

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

## 后续开发与交接

功能完善按 [docs/development-plan.md](docs/development-plan.md) 的阶段和最新交接记录推进。新会话先核对 Git 状态与实际实现，默认完成一个阶段或可独立验收的子任务，并更新计划中的验证结果和下一步。

## 项目进度与工作续接

开始工作时：读取 `docs/continuity/CURRENT.md`，选择本任务记录，核对分支、HEAD、暂存/未暂存修改及实际代码。
记录中的“历史会话曾报告”不等于当前已验证；不要据此重复实现、回滚、发布或上传。

在确认目标、关键决策改变、完成可验证阶段、阻塞、准备换号/交接时，更新 `docs/continuity/tasks/<task>.md`：
目标与验收、已完成内容、决策理由、验证结果、未验证项、下一步及相关会话编号。
一个任务一份记录；多会话各自维护自己的任务，不相互覆盖。不要把 token、Cookie、个人敏感数据写进交接文档。

安装了本机维护工具时可运行 `"$HOME/.local/bin/ac" checkpoint --project "$PWD" --task <task>`，并用
`"$HOME/.local/bin/ac" context --project "$PWD" --task <task> --tool claude`（或 `codex`）取得续接提示。
工具不可用时直接读写上述文档。检查点不等于完整备份；任务记录不会自动获得提交、推送、发布或签署授权。
用户说“保存进度”“先到这里”或“准备交接”时，根据当前会话更新自己的任务记录并生成检查点，不让用户挑选技术文件或参数；不自动提交、推送或进行全量备份。
用户说“继续工作”“接着上次继续”或“继续上次”时，先读索引与任务并核对实际代码；多个任务时结合当前会话判断，仅在业务目标确实无法判断时询问。
兼容原有“准备换号/交接”的说法；续接只处理项目进度，不操作登录账号。
上传/发布/签署/远程写入中断后先查实际结果，不能因切换账号或工具而自动重试。
