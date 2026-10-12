# 财富页资源接入

财富页使用 `ABank/Assets.xcassets/ABCImported/Wealth/` 中的语义资源，统一前缀 `abc_wealth_`。Menu、Toolbar、Decorations 分组对应功能入口、顶部工具和页面装饰，共 27 个资源集、32 张 PNG。

- 十个入口：存款、理财产品、基金、贵金属、债券、保险、证券期货、外汇、个人养老金、全部。选择包内 native500 资源，与已下载商店财富截图的业务类型及轮廓风格对应。
- 顶部：扫一扫、搜索、麦克风、客服、消息，2x/3x 配套；使用 template rendering 随当前界面 tint 显示。其他业务图片保留 original rendering 的青绿、珊瑚红点缀。
- 五个栏目标题：活钱专区、稳健增长、收益进阶、热门存款、债券指数。真实标题图覆盖原文字位置，同时保留文字的布局尺寸与图片 accessibilityLabel。
- 热点标识、热销与优选三角角标使用真实素材，取消原先旋转方块的近似绘制。
- 登录卡及三个活钱区背景使用不含旧产品数据的原始背景图，业务文案和收益仍由 MockDataProvider 渲染。没有引入真实接口。

`abc-wealth-resource-manifest.json` 记录每个语义资源的原始路径、SHA-256、尺寸和导入尺度。`scripts/import_wealth_assets.py` 仅更新 Wealth 分组，不重写首页、TabBar 和其他资源配置；依赖本地已解码素材与 Pillow。没有尺度后缀的财富菜单及装饰图按本次 3x 包导入，不插值伪造高分辨率版本。

验证：最终代码模拟器构建；引用名称、Contents.json 和图像文件对应检查；iPhone 16 Pro / iOS 18.3 首屏与中段渲染截图检查。截图保存到本地 artifacts/abc-resources/verification/wealth-top.png、wealth-middle.png。截图期间临时选中财富页和滚动定位，临时代码均已恢复。最终优选角标与热销使用同类 42pt 三角原图布局，优选修正后尚未重新截图。

限制：商店截图可能来自旧版本；安装包中也包含占位、远程图片回退和多套主题素材。此次还原已确认的静态图标及装饰风格，并非对当前原版 App 全部线上版式逐像素验证。产品、广告和财富研习所的整幅运营内容不以静态旧截图替代当前项目文案。
