# 我的子页面资源更新第一批

静态资源位于 `ABank/Assets.xcassets/ABCImported/MineDetails/`，统一前缀 `abc_mine_detail_`。共 6 个 imageset、8 张 PNG：睁眼/闭眼、信息提示、财富体检、客服、搜索。原名、哈希及尺寸见 `abc-mine-detail-resource-manifest.json`；独立导入脚本为 `scripts/import_mine_detail_assets.py`。

| 页面链 | 此次接入 |
| --- | --- |
| 资产负债 | 摘要财富体检图标、分类旁信息图标 |
| 收支 | 导航搜索图标、摘要信息图标 |
| 我的贷款 | 未还本金睁眼/闭眼双态图标、合同报税信息图标 |
| 合同详情 | 客服图标、条目信息图标 |
| 提前还款 | 信息按钮图标 |

通过 `UIImage.abankAsset` 的可选 pointSize 按原控件 10–18pt 等尺寸渲染，防止 32pt 的图片 intrinsic size 扩大按钮。未传该参数的既有调用保持原路径；单色信息/客服/眼睛按调用处 tint 显示，财富体检保持多色。

客户信息、手机号、税收身份页已检查；证件拍摄、表单箭头、税收选择框没有找到用途和状态均可确认的替代素材，保留标准控件。贷款四个功能入口、合同展开、还款筛选、日期 picker、交易方向和账户选择状态也未强行替换为不相关资源。原版 App 的当前子页截图尚未提供，不能把此次素材接入描述为整页逐像素还原。

数据和动作继续使用本地 CustomerInfoStore / FinanceLedgerStore，未接入接口、修改合同/交易数据或增加真实业务。

验证：常规构建，资产负债、我的贷款及收支模拟器渲染检查；清单、文件引用和图片解码检查。贷款隐藏态图片已导入并在状态分支中使用，未做点击切换/全部子页返回的运行交互测试。临时直接导航代码最终恢复。

本地验证截图：artifacts/abc-resources/verification/asset-liability-resources.png、my-loan-resources.png、income-expense-resources.png。
