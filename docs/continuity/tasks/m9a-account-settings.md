# m9a-account-settings

- branch: `feat/m9-account-loan`; base HEAD: `aaa6357` (main)
- Updated 2026-11-07: M9a implementation and simulator acceptance are done; the final whole-branch review is still pending. Not merged, not pushed.
- Session: the main session (inline execution)

## Goal and acceptance
M9a account settings, all on local mock data:
- Account alias.
- 查看/分享 page.
- 账户限额 entry that reuses the M4 转账设置 page.
- Simulated permissions 手机银行转账 and 网上支付 that really block transfer, recharge and utility payment.

Acceptance criteria are in `docs/superpowers/specs/2026-11-07-m9a-account-settings-design.md`.

## Confirmed decisions (user's choices)
- M9 is split into M9a (account) and M9b (loan); M9a goes first.
- Permissions really block: both the pre-confirm check and submit are blocked.
- Every place that shows a card name uses "别名（尾号）".
- Approach A: alias and permissions live on `LedgerAccount`, and writes go through `FinanceLedgerStore`.
- Execution is inline in this session; a fresh reviewer does the final whole-branch review.

## Progress and commits
- `045d0c1` design
- `5f10c9b` plan
- `9041888` data model
- `7c14326` permission blocking
- `12cd006` alias, share and permission pages
- `474a35a` alias display
- `e4683a3` blocked-action alert and "去开启" redirect
- Execution ledger: `.superpowers/sdd/2026-11-07-m9a-account-settings/progress.md` (ignored by Git).
- Verification details are in the "M9a 实施记录" section of `docs/development-plan.md`.

## Rulings (where the work departs from the plan)
- Recharge checks `onlinePayment` before validating the phone number or denomination, because the spec says permission comes first.
- The share page and the 查看/分享 entry were built in Task 3, because the exhaustive router switch needs the target in order to compile.
- 立即缴费 on a utility bill runs the full `validateUtilityPayment` before the confirm dialog, so already-paid and insufficient-balance also show up early as a toast.
- Simulator acceptance used the ASCII alias `Salary`, because the simulator cannot take Chinese input. Chinese and emoji aliases are covered by the check script.

## Verification
- `zsh scripts/check_banking_data.sh`: all 10 groups pass.
- The normal build passes.
- Simulator screenshots are `artifacts/abc-resources/verification/m9a-*.png`.
- After acceptance, the alias was cleared and both permissions were turned back on.

## Not verified
- Blocking at submit on the confirm page.
- The recharge-blocked screen.
- A screenshot of the "已复制" toast (the clipboard contents were checked).
- The rollback screen when a permission write fails.
- 320pt width.
- Calibration against screenshots of the original app.

## Next steps
1. Final whole-branch review (fresh reviewer); fix Critical/Important findings with TDD, and record Minor ones here.
2. The user decides whether to merge to main and push. Never push unless the user asks.
3. M9b loan extension: tasks, progress, certificates, early-repayment results.
