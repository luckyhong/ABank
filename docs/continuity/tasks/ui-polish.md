# ui-polish

- branch: `feat/m3-feature-catalog`；起点 HEAD：`121a35e`；全部改动未提交、未推送
- 更新：2026-11-06

## 目标与验收
整体走查各页面 UI 布局规范，图标从已提取的农行资源中选取，接近生产效果。验收：构建通过、数据检查通过、模拟器逐页无布局/导航异常。

## 发现的问题
- 导航栏样式散落在各页面：直接改共享 `navigationBar`（tint/appearance），样式泄漏到后续页面；各页面自行 `setNavigationBarHidden`，Tab 根页返回时易出现空白导航栏。
- 返回按钮不统一：系统箭头 + 英文/中文返回文字、SF Symbol `chevron.left` 与系统指示器位置差约 10pt。
- 全部功能页首次布局时分类索引越界查询，偶发崩溃。
- 网点服务、资产负债公告、借记卡详情眼睛图标用 SF Symbol，与其余页面农行素材不一致；借记卡眼睛语义与“我的”页相反。

## 已完成
- 新增 `Core/Base/ABankNavigationController.swift`：统一外观（白底、无阴影、17pt 中粗标题、农行返回箭头）、隐藏返回文字、按 `BaseViewController.prefersNavigationBarHidden` 在转场前切换显隐（右滑取消时恢复）、自定义左按钮时保留右滑返回。
- `MainTabBarController` 与三个筛选弹窗改用 `ABankNavigationController`；32 个页面移除直接改共享导航栏/显隐的代码，外观改为 `navigationItem.*Appearance`；删除与标准外观相同的重复配置；五个 Tab 根页声明隐藏导航栏。
- 全部功能页 `scroll(to:)`、`syncIndexWithScroll()` 增加分区数保护。编辑常用页取消/完成按钮配色。
- 图标：`scripts/import_common_ui_assets.py` 导入 `ABCImported/Common/`（哈希清单 `docs/abc-common-resource-manifest.json`）：`abc_nav_back`←UPSDK_icon_back（有 @2x/@3x；mPaaS back_button 仅 @2x 弃用）、`abc_branch_phone`、`abc_branch_location`←hp_mine_nearbyoutlets_*。公告喇叭改用 `abc_transfer_notice_speaker`，借记卡眼睛改用 `abc_mine_detail_amount_eye_*`（睁眼=可见）。
- 临时 UIQA 钩子已删除（`grep -rn UIQA ABank` 无结果）。

## 决策理由
- 资源中 nav more 候选（large_nav_more 等）为圆圈加号，语义不符，“…”保留 SF Symbol。
- 列表箭头、关闭、勾选、三角等通用符号保留 SF Symbol；已按参考截图校准的页面按钮配色（我的表单橙色、转账绿色）不改。

## 验证结果
- 构建通过；`zsh scripts/check_banking_data.sh` 退出码 0；`git diff --check` 通过（删除钩子后复验）。
- 模拟器 iPhone 16 Pro：33 个页面逐页渲染，无英文 Back，返回箭头位置一致；修改手机号、税收居民身份有标题栏；首页→我的账户 push、取消右滑、完整右滑返回首页（导航栏重新隐藏）均正常。

## 未验证项
- 320pt 宽度；中文输入；未按原版截图校准的页面布局；财富/生活 push 返回与筛选弹窗本轮仅抽查/代码核对。

## 下一步
用户决定是否提交 → 可选：剩余 SF Symbol 替换、按钮配色规范统一。
