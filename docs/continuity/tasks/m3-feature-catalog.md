# m3-feature-catalog

- project_id: `c972f5dc-d82d-4f58-94b1-580699d5a9a3`
- updated_at: `2026-11-06T15:48:45.366408+00:00`
- branch: `main`
- HEAD: `75d3a68ed766d8950bbf77a5fb60723f2530569c`
- evidence: 本次 Git 检查；业务结论仅按下方记录

<!-- NOTES -->
# m3-feature-catalog

- branch: `main`；起点 HEAD：`75d3a68`；全部改动未提交、未推送
- 更新：2026-11-06

## 目标与验收
M3：全部功能目录、功能搜索、常用编辑（驱动首页宫格）、最近使用，以及统一的类型化路由。验收标准见设计文档 §1。

## 已确认决策
- 常用驱动首页宫格前 9 格，第 10 格固定“全部”；默认常用 = 原首页 9 项。
- 未完成入口进入统一“即将上线”页，显示计划阶段。
- 路由覆盖各 Tab 功能宫格；广告、产品卡片、客服、消息、公告保持 toast。
- 无原版截图，按现有设计系统，标注待截图校准。
- 方案：枚举 `AppRoute` + 静态 `FeatureCatalog` + 可注入 `AppRouter`。

## 已完成（计划 Task 1–10）
- 设计：`docs/superpowers/specs/2026-11-06-m3-feature-catalog-routing-design.md`；计划：`docs/superpowers/plans/2026-11-06-m3-feature-catalog-routing.md`（用户选择本会话直接执行）。
- 新增：`Core/Routing/AppRoute.swift`、`AppRouter.swift`；`Features/AllFeatures/`（目录模型、搜索、偏好存储与草稿、全部功能页、编辑常用页、即将上线页、宫格单元与分类索引）；`Shared/Utilities/FeatureDescriptor+UI.swift`；全部功能素材与导入脚本；`scripts/check_feature_catalog.swift`。
- 改接：首页（宫格由常用驱动、快捷入口、搜索、取号、网点服务）、财富/生活宫格、我的（搜索、权益、等级、网点、安全、订单、头像、资产负债、收支、账单）、转账（功能宫格、记录、限额）、我的账户（转账、明细查询）、资产负债（收支、贷款）。
- 执行中裁定（详见计划工作区台账）：iconImage 改为带字号函数；素材以工程内图片哈希校验；分类区 3 列；新页面在 viewWillAppear 恢复导航栏（首页隐藏导航栏导致无返回按钮，模拟器发现）；转账主按钮与收支→月度账单保留带上下文的原调用。

## 验证结果
- `zsh scripts/check_banking_data.sh` 退出码 0（M0/M1/M2/功能目录检查全部通过）；正常构建通过；`git diff --check` 通过。
- 模拟器 iPhone 16 Pro / iOS 18.3 十项验收见 `artifacts/abc-resources/verification/m3-qa-results.txt`（Git 忽略），截图 `m3-home.png`、`m3-routes-sheet.png`、`m3-axxxl.png`。临时 QA 包已卸载、钩子已删除，正常 App 常用偏好已恢复默认。

## 最终全分支审查（2026-11-06）
- 结论：可合并（需修复），无 Critical；计划 Review Focus 5 项均通过。
- Important 已修复：财富/生活 Tab 只在 viewDidLoad 隐藏导航栏，从 M3 新页面返回后出现空白系统导航栏（内容下移约 44pt）。两页加 viewWillAppear 重新隐藏；模拟器复现后验证修复，构建与数据检查通过。
- 延后的 Minor：全部功能页改共享导航栏 tintColor；连点重复记录最近使用；我的页直达路由不记最近使用；部分页面监听默认通知中心；草稿去重重复/toast 硬编码 9；拖放空草稿缺 guard。

## 未验证项
- 320pt 宽度（iOS 18 无对应模拟器）；中文搜索词仅由脚本覆盖（模拟器无法键入中文）；资产负债子项→收支带账户仅代码核对；连点为工具间隔数百毫秒，非同帧双击。
- 无原版截图，全部功能/编辑常用/即将上线布局待截图校准。

## 下一步
已提交为 `121a35e`（分支 feat/m3-feature-catalog，未推送）→ 可选处理延后的 Minor → 下一阶段 M4 安全中心。
