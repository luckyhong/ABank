# ABank 启动页

- 日期：2026-11-18。会话：`01a1edb9-e87d-73e1-9e4d-83a8b4e2e4a9`。基线：`main` / `cabb3c8`。开始时已有生活页暂存修改和工程、Info.plist 等未暂存修改。
- 目标：找回先前 REA 分析的启动图，并将启动视觉接入 ABank 的 iOS 冷启动入口。
- 来源：本机 `artifacts/abc-resources/originals/default_launch_gb1020.png`，1125 × 2436，原图 SHA-256 为 `fa47c9b819ca2f71d3538915c6d347b36b2245cb804c05463196f70022c3b138`，与[导入清单](../../abc-resource-manifest.json)相符。工程已有该图的导入资源。原图含农行标志、行名和备案信息。
- 实现：参考原图留白与层级，在现有 `LaunchScreen.storyboard` 中使用独立排版、ABank 字标和学习项目说明。借助安全区约束和系统颜色适配屏幕与深色模式，不引入额外启动流程。
- 构建：`ABank.xcworkspace` 的 Debug 模拟器构建通过。包内含编译后的 `LaunchScreen.storyboardc`，并且 `UILaunchStoryboardName` 指向 `LaunchScreen`。使用独立 Bundle ID 安装验证包。
- 验证：未签名包被 iOS 拒绝生成启动快照。仅对临时验证包做本地签名后，iPhone SE（第 3 代）浅色、iPad Pro 11 英寸（M4）深色均从 iOS 18.3 冷启动画面捕获到字标和说明，并确认随后进入首页。验证包已清理。真机启动及升级后启动快照刷新待验证。项目改动未提交。

## 按用户截图校准构图

- 当前基线为 `main` / `13f727d`。根据用户补充的启动截图，把绿色 A 标记与 ABank 字标置于屏幕横向中心、视觉中线偏上。底部安全区内放置「银行界面学习项目」「本地模拟数据」，并提高两行小字的明暗对比。保留系统浅色和深色背景。
- 截图为农行正式启动界面，仅参考背景留白和两组内容的位置。新版使用 ABank 字标、SF Symbols 和项目说明。
- 最终 Debug 构建和 `git diff --check` 通过。iOS 18.3 上复核 iPhone 16 Pro 与 iPhone SE 3 浅色、iPad Pro 11 英寸（M4）深色的冷启动快照及进入首页，验证包随后清理。
- 真机及覆盖安装场景待验。本次改动未提交。

## 切换为 REA 原图

- 用户确认可原样使用后，`LaunchScreen.storyboard` 直接引用工程内已有的 `abc_resource_default_launch_gb1020_fa47c9b819ca`。解码为 RGB24 后与 REA 原图的逐像素 SHA-256 一致，复用该 imageset 即可。未新增素材副本。
- 图片等比完整显示，剩余区域使用白色背景。启动 storyboard 沿用现有打包入口，无额外启动延时或 Swift 逻辑。
- Debug 模拟器构建与 `git diff --check` 通过。iOS 18.3 上验证 iPhone 16 Pro、iPhone SE 3 和深色模式 iPad Pro 11 英寸（M4）的冷启动画面完整，并观察到首页渲染。临时验证包已清理。真机和覆盖安装仍待验证，改动未提交。

## 本地提交节点

- 用户随后要求提交全部本地改动。启动页、工程配置、剩余分析文档及本索引新增引用的任务记录一并纳入本地提交，远程推送待确认。
