# m9a-account-settings

- branch: `feat/m9-account-loan`；起点 HEAD：`e5250dc`（main）
- 更新：2026-11-07（M9a 实现与模拟器验收完成，全分支审查进行中；未合并、未推送）
- 会话：主会话内联执行

## 目标与验收
M9a 账户设置：账户别名、查看/分享、账户限额入口（复用 M4 转账设置）、手机银行转账与网上支付两项模拟权限真实拦截转账与充值缴费；全部本地假数据。验收标准见 `docs/superpowers/specs/2026-11-07-m9a-account-settings-design.md`。

## 已确认决策（用户选择）
- M9 拆为 M9a（账户）与 M9b（贷款），先做 M9a。
- 权限真实拦截：确认前校验与提交时都拦。
- 所有显示卡名处统一为“别名（尾号）”。
- 方案 A：别名与权限存于 `LedgerAccount`，写入经 `FinanceLedgerStore`。
- 本会话内联执行，最后由新审查者做全分支审查。

## 进度与提交
- `045d0c1` 设计、`5f10c9b` 计划、`9041888` 数据模型、`7c14326` 权限拦截、`12cd006` 别名/分享/权限页、`474a35a` 别名展示、`e4683a3` 拦截提示与去开启、`fefd83e` 文档。
- 执行台账：`.superpowers/sdd/2026-11-07-m9a-account-settings/progress.md`（被 Git 忽略，含裁定）。
- 验证详情见 `docs/development-plan.md` “M9a 实施记录”。

## 裁定（偏离计划处）
- 手机充值先查 `onlinePayment` 再校验号码与面额（规格要求权限优先）。
- 分享页与“查看/分享”入口提前到 Task 3 完成（路由穷举 switch 需目标页才能编译）。
- 缴费“立即缴费”在弹窗前执行完整 `validateUtilityPayment`，已缴清/余额不足也会提前以提示呈现。
- 模拟器验收别名用 `Salary`（模拟器无法输入中文），中文与 emoji 别名由检查脚本覆盖。

## 验证
`zsh scripts/check_banking_data.sh` 10 组全部通过；正常构建通过；模拟器截图 `artifacts/abc-resources/verification/m9a-*.png`。验收后别名已清空、两项权限已恢复开启。

## 未验证
确认页提交时被拦截、手机充值拦截界面、“已复制”提示截图（剪贴板已核对）、权限写入失败回滚界面、320pt 宽度；无原版截图校准。

## 下一步
1. 全分支审查（新审查者），Critical/Important 以 TDD 修复，Minor 记入本文件。
2. 是否合并到 main、是否推送由用户决定；未经要求不推送。
3. M9b 贷款扩展：任务、进度、证明、提前还款结果。
