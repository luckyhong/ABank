# 农行素材在 ABank 中的组织与首页接入

该项目用于 UIKit 界面练习，页面数据继续来自本地 MockDataProvider。

## 目录

`ABank/Assets.xcassets/ABCImported/` 已由现有 Assets.xcassets 纳入 target，不需要修改 Xcode 工程文件。

| 分组 | 内容 |
| --- | --- |
| Home | 25 个首页语义资源集，命名为 abc_home_* |
| TabBar | 5 个 Tab 的普通态与选中态，共 10 个资源集，均提供 2x / 3x |
| Loose/Main | 主应用路径的独立图像 |
| Loose/Bundles | 嵌套 bundle / framework / extension 路径的独立图像 |
| Catalog/Main | 主 Assets.car 导出图像 |
| Catalog/Bundles | 嵌套资源库导出图像 |

已导入 3871 张成功解码源图像，内容重复的资源共用 imageset，2x/3x 首页图像合并到对应资源集，共 3021 个 imageset，约 55 MB。其他资源命名为 `abc_resource_<文件名片段>_<内容哈希>`，防止中文、嵌套路径、SDK 同名素材冲突。分组是包内路径分组，不能作为版权归属或实际使用位置的判断。

`abc-resource-manifest.json` 记录原文件名、原内容哈希、目标 imageset、尺度和首页对应关系；后续页面先从此映射查找图像，再按用途新增语义命名。原始 IPA、Assets.car 和提取预览保留在本地 `artifacts/abc-resources/`，由 .gitignore 排除；不将下载包、认证状态、压缩包或临时解包工程带入 GitHub。

## 首页对应

- 四个快捷入口：我的账户、转账、收支、扫一扫，采用完整彩色叠层切图；显示框为 42 pt，不再额外叠加人工底色。
- 十个功能入口：信用卡、养老社区、普惠金融、存款、理财产品、贷款、生活缴费、热门活动、城市专区、全部。
- 顶部：抽奖、版本、客服、消息、搜索、麦克风。单色图标使用 template rendering，随滚动切换白色/深色；功能入口保持原始多色。
- 网点服务：农行标志、刷新、我要开卡、纪念币预约、同号换卡。

普惠金融使用包内惠农 e 贷类图像、养老社区使用养老服务图像，作为当前假数据入口的合理视觉对应；没有通过运行原始 App 验证此版本首页对这两个入口的精确资源引用。收支使用原文件 `income_detail_kk.png`，保留当前项目入口标题。

`UIImage.abankAsset` 保留 SF Symbols 作为缺失资源时的回退。页面动作、Mock 数据流和路由未增加真实接口。

## 导入政策

- 颜色及透明通道保留，导入 image sets 设置 original rendering；顶部图标在调用处明确设置 template。
- 文件名包含 @2x / @3x 时沿用尺度；96px native500 菜单和 kk 快捷入口按 3x 导入；其他没有尺度线索的图片不凭空生成高分辨率版本。
- GIF 导入帧零作为静态图；动画原文件留在本地提取目录，未引入动画播放。
- 解码失败的 `yw_1222.jpg` 及没有可用导出图像的资源库记录未导入。PackedImage / MultiSized 详情见本地提取报告。
- 可用本地解码目录通过 `python3 scripts/import_abc_assets.py` 重新生成；脚本依赖 Pillow，不访问网络和账户资料。

## 验证

所有首页引用与 imageset 文件关系检查通过。使用现有工作区 ABank.xcworkspace 构建通过，并在 iOS 18.3 / iPhone 16 Pro 模拟器安装运行，截图确认首屏四个快捷入口、十个功能入口及顶部图标正常显示。

构建命令使用临时 `IPHONEOS_DEPLOYMENT_TARGET=15.6` 覆盖：当前 Xcode 的 iOS Simulator SDK 27 不接受已有 Pods 工程的 iOS 13 部署版本。此次没有修改依赖工程。已有 AccentColor.colorset 中 PNG 引用产生编译警告，此次未处理。滚动后的深色工具栏和网点区域尚未完成交互截图验证。

```sh
xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/ABank-ResourceBuild \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.6 build
```

## 底部 TabBar 补齐

首页 main、财富 invest、生活 mall、资讯 news、我的 my 分别使用包内 `*_native_600` 普通态与 `*_native_600_s` 选中态，映射为 `abc_tab_<页面>_normal/selected`。每组 58×58（2x）与 87×87（3x），逻辑尺寸均为 29 pt。普通态黑色轮廓、选中态青绿色实心，使用 original rendering 保留原图。资讯使用 news 星球图标，保留当前项目的资讯页面与标题。
