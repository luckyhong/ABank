# m10a-shortcuts

- branch: `feat/m10a-shortcuts`；起点 HEAD：`b796ca8`（main，M9 已合并并推送）
- 更新：2026-11-08（规格已确认；意图得分改为命中触发词字符数之和；计划已写，待审阅并选择执行方式）
- 会话：主会话

## 目标与验收
M10a：桌面快捷操作（固定 4 个）、演示扫码（示例码，先确认再跳转）、本地关键词助手（对话式，客服入口进入）。只跳转已完成页面，统一经 `AppRouter`。验收标准见 `docs/superpowers/specs/2026-11-08-m10a-shortcuts-scan-assistant-design.md` §1。

## 已确认决策（用户选择）
- 扫一扫：演示扫码，不调用相机；识别后先显示结果卡片，点“前往”才跳转；永不自动付款。
- 助手：对话式，会话只在页面内存。
- 快捷操作：固定 4 个（扫一扫、转账、收支明细、在线助手）。
- 方案 A：纯 Foundation 解析器 → `AppRoute`，入口统一走 `AppRouter`。
- Widget 留给 M10b。

## 下一步
1. 用户审阅计划 `docs/superpowers/plans/2026-11-08-m10a-shortcuts-scan-assistant.md` 并选择执行方式。
2. 未经要求不合并、不推送。
