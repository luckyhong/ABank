# 我的账户、明细查询、转账页面还原

依据用户于 2026-10-16 提供的三张真实页面截图调整。使用原生可伸缩布局和文字，保留本地模拟数据与现有导航、筛选及展开逻辑。截图中的余额、日期、交易数量与联系人日期不作为静态图片或固定值复制到页面。

## 资源规范

资源位于 `ABank/Assets.xcassets/ABCImported/Account/` 与 `Transfer/`，分别采用 `abc_account_*`、`abc_transfer_*` 命名。共 21 个 imageset、35 张图片：Account 5 个 / 9 张，Transfer 16 个 / 26 张。

- `scripts/import_account_transfer_assets.py`：导入已核对的 9 个原始资源（11 张图片）。切图来源、内容哈希、实际尺寸和倍率记录在 `abc-account-transfer-resource-manifest.json`。
- `scripts/generate_account_transfer_reference_assets.py`：重绘缺少完全匹配原始切图的 12 个资源，输出 2x/3x PNG（24 张），清单为 `abc-account-transfer-reference-manifest.json`；`origin` 明确为 `reconstructed_from_user_screenshots`。
- 每个资源文件夹有 Xcode `Contents.json`，彩色图标默认 original，原生控件设置所需尺寸。账户编辑图标归 Account，转账功能入口归 Transfer。

| 来源 | 接入内容 |
| --- | --- |
| 农行安装包已有提取图 | 农行独立标志（`credit_nong_logo.png`）、客服、公告喇叭、转账记录、双人、握手、联系人头像 |
| 工程已有资源 | 相同主题的信用卡横幅；完整复制已有 1x/2x/3x 文件，统一为 `abc_account_credit_banner`，原资源保留避免影响其他引用 |
| 建设银行官网 | [官网原始标志](https://www.ccb.com/chn/fileDir/bg_image/2020031015231379393.png)，来自[官网首页](https://www.ccb.com/chn/home/index.shtml)的 logo；资源保留完整原文件，显示时取左侧独立标志并按参考页白色图形、蓝色圆底呈现 |
| 依据截图重绘 | 账号/手机号转账、转账设置、信用卡还款、预约、他行卡转入、跨境、手机号收款、撤销、浅绿色纹理背景、账户别名编辑、明细导航回单 |

双人切图在转账网格中水平镜像以接近截图的人物前后关系。原始握手素材原名为 `hospitalizing_service_native500.png`，本轮复用相同的握手造型，并没有把原文件名作为转账业务名称。未给出真实银行标志的其他模拟账户保留原文字徽标作为后备，不根据卡号推断银行。

## 字体与布局

截图按约 393pt 宽页面换算，模拟器为 iPhone 16 Pro；实际渲染宽度略有差异。字号为原生逻辑点，不把截图像素直接用作 point。

| 页面 | 调整 |
| --- | --- |
| 我的账户 | 借记卡/信用卡标题 20pt medium；卡号 19pt regular，可在窄屏缩小；I 类圆徽标 30pt；分享按钮细描边；别名 14pt，原始文字配独立编辑图标；余额说明 17pt、金额 26pt medium；详情为金额下方右侧的浅绿色侧边入口；底栏三等分、16pt 文本及满高细分隔，活钱理财渐变和时时付标签；银行卡卡片顶部留白、信用卡横幅比例和电子账户虚线框按截图调整 |
| 明细查询 | 农行标志与卡号水平对齐，卡号 17pt、币种 15pt；筛选区 64pt 高、32pt 高胶囊、14pt 文本、前三项等宽；明细标题和金额 17pt regular，日期与余额 14pt 深灰，收入用金色；标题截尾、金额和余额右对齐，避免长商户名挤压金额；保留单行正文与约 70pt 行高 |
| 转账 | 白底通知条和黄色喇叭；主卡绿色区 108pt、下方白色操作区 44pt；主入口 44pt 图像框、14pt regular 标题，下方操作 17pt；八入口默认两行展开，网格 14pt 标题和 32pt 图像框；伙伴区 17pt 标题、16pt 姓名、14pt 银行说明、灰色计数和 NEW 标记；联系人头像与银行标志替换文字/系统占位图 |

字体和颜色仅在这三个页面作用范围内调整，未修改全局 `abankText*` 或其他模块字号。账户卡片按最终子视图尺寸更新渐变；圆角、背景、装饰与实际文字分开绘制，点击回调保持原有动作。

## 验证与边界

- 使用 `ABank.xcworkspace`、ABank scheme、Debug、通用 iOS Simulator 正常构建。
- 资源集 JSON、PNG/JPEG 解码、命名与重复名称检查；`git diff --check`。
- 模拟器截图：`artifacts/abc-resources/verification/account-transfer-account.png`、`account-transfer-query.png`、`account-transfer-queryMonth.png`、`account-transfer-transfer.png`。一周与一月状态分别检查少量流水、长商户名、收入色和多行列表显示。
- 通过临时预览直接触发已有回调，检查转账功能收起、首位伙伴展开及通知关闭后的布局，截图分别为 `account-transfer-transferCollapsed.png`、`account-transfer-transferExpandedPartner.png`、`account-transfer-transferNoticeHidden.png`。这属于回调状态检查，没有模拟真实手指点击。
- 临时预览入口和月范围覆盖在验证后移除；最终正常启动仍为首页。截图检查不代表完成所有按钮、关闭提示、筛选弹窗与返回路径的真实点击回归。

现有信用卡横幅本身分辨率有限，复用资源清晰度受原文件限制；重绘素材与文字细节以截图尽量接近，不能宣称完全逐像素一致。没有从截图复制状态栏、真实卡号或金融数值，没有增加真实转账或其他接口。

原始资源重新导入需要本地 `artifacts/abc-resources/analysis/resources.json`、预览文件及 `external/ccb-official-logo.png`。官方图片下载地址已记录在清单；脚本只读取本地文件，不自动联网。重绘脚本需要 Pillow 和 macOS 字体。正常工程编译仅依赖已导入的 xcassets。
