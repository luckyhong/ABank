# 个人中心账户页面资源

资源目录：`ABank/Assets.xcassets/ABCImported/MineDetails/`。统一使用 `abc_mine_detail_` 前缀，按用途命名，不把原包散乱文件名直接传到业务页。

## 来源与生成

| 类型 | 清单 | 维护脚本 |
| --- | --- | --- |
| 安装包原始切图 | `abc-mine-detail-resource-manifest.json`，记录原名、哈希、尺寸及倍率 | `scripts/import_mine_detail_assets.py` |
| 参考图重绘 | `abc-mine-reference-resource-manifest.json`，明确标为 `reconstructed_from_user_screenshots` | `scripts/generate_mine_reference_assets.py` |

原始资源 8 个 imageset / 11 张 PNG；参考图重绘 15 个 imageset / 30 张 PNG。合计 23 个 imageset / 41 张 PNG。每个资源文件夹都有 Xcode `Contents.json`；重绘图标采用统一 32pt 画布、透明背景及 2x/3x 版本。原始资源按其自身比例显示。

本轮以用户 2026-10-16 提供的 7 张真实页面截图为参照。贷款四入口、操作栏、交易类型、财富体检、信息提示及页面背景没有在本地提取资源中确认完全匹配的原图，因此单独重绘，不能将这些文件称为安装包原图。页面背景只含浅金色波纹，无文字、金额或日期。截图中的状态栏、个人数据不作为整张图片嵌入。

## 页面映射

| 页面 | 资源与样式 |
| --- | --- |
| 我的页面下部 | 原始网点定位符号、客户经理头像；保留已经接入的网点四入口、安全中心四入口和企业微信原图；客户经理移除多余圆底，角色标记改为细描边 |
| 资产负债（资产/负债） | 浅金背景、相册入口、财富体检线框、统一信息提示；公告箭头靠右；摘要去掉中间横线，调整上下留白和标题字号；财富体检仅在资产态出现 |
| 我的贷款 | 待办任务、进度查询、贷款续贷、结清证明统一灰色线框配绿色点缀；应还详情金色按钮贴右边；金额眼睛保持原始双态切图 |
| 贷款详情 | 原始客服、重绘提前还款/使用记录/信息图标；圆环浅金色，环内金额用系统字体；条目保留首行分隔，收紧行距 |
| 收支列表 | 浅金汇总背景；工资、第三方付款、他人转账、本人互转分别使用对应线框；移除彩色方块底；日期标签为空心圆角描边；收入金额右对齐 |
| 收支详情 | 复用列表同一交易图标解析；移除彩色方块底，金额字号调整；保留开关、分类、账本、备注和查看更多交互 |

`LedgerTransactionArtwork` 以 `categoryId` 选择图标。付款不区分抖音/支付宝/微信商户品牌。本人互转只匹配 `self_transfer`，不从 `includeInFlow` 推断交易类型。参考图未覆盖的交易分类继续显示有方向含义的灰色系统线框。用户修改分类后，列表和详情会依据同一分类规则更新图标。

`UIImage.abankAsset` 的 `pointSize` 适配按钮实际图像尺寸；多色图标使用 original，单色图标按页面需要 template。通用返回箭头、展开箭头、筛选、原生开关继续由系统控件绘制。新增图标所在按钮保留原文字标题和已有点击行为。

## 范围与验证

继续使用本地 CustomerInfoStore / FinanceLedgerStore。没有修改模拟交易、余额、日期、贷款数据或引入接口；因此数值不照抄截图。客户信息、手机号、税收身份页面不在这组截图内，本轮没有重做这些表单。

本地模拟器截图位于 `artifacts/abc-resources/verification/reference-*.png`，包括资产、负债、贷款、贷款详情、收支、工资详情和我的页面下部。截图验证检查显示和布局，不等同于完成所有按钮、筛选、返回和金额隐藏态的交互回归。临时预览入口验证后移除，正常启动仍为首页。

重绘使用 Pillow、macOS 系统字体（仅用于极少量图标内的字形）。修改绘图脚本后执行 `python3 scripts/generate_mine_reference_assets.py`；原始导入脚本需要本地已提取的 `artifacts/abc-resources/analysis/resources.json` 和相应预览文件。日常构建仅需要已入库的 xcassets，不需要 IPA 或提取目录。
