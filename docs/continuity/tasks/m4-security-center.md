# m4-security-center

- branch: `feat/m4-security-center`；起点 HEAD：`ef46672`（main，M3 已合并并推送）
- 更新：2026-11-06（Task 8 完成后）

## 目标与验收
M4 安全中心：登录/转账/支付设置、登录设备列表/详情/移除、全局金额隐私、可编辑模拟限额。验收标准见设计文档 §1。

## 已确认决策
- 设置深度：演示开关 + 少量联动（隐私全局、限额校验、设备移除）；面容/手势/免密只展示状态，不弹验证。
- 金额隐私：全局同一持久化状态，眼睛按钮与安全中心开关同步。借记卡详情的卡号眼睛不接入（语义不同）。
- 方案：新增 `SecuritySettingsStore`；账本改为闭包读取限额，不改账本存储结构。
- 图标：`artifacts/abc-resources/images/safecenter_*`（96px 单图，放 3x 槽位）。

## 进度
- 设计 `cb36383`、计划 `04e8a3d` 已通过；用户选择本会话直接执行。
- Task 1–7 已提交（`cb36383..cbc099d` 之后），最后一个功能提交 `cbc099d feat: 金额隐私改为全局同步`。
- Task 8 模拟器验收完成，结果与未验证项见 `docs/development-plan.md` 的“M4 实施记录”。
- 执行台账：`.superpowers/sdd/2026-11-06-m4-security-center/progress.md`（被 Git 忽略，含各任务裁定）。

## 下一步
全分支审查（新审查者）→ 修复 Critical/Important → 用户决定合并/推送。未经用户要求不推送。
