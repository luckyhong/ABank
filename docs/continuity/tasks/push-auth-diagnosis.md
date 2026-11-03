# 推送身份验证故障排查

- 更新时间：2026-11-02（America/Los_Angeles）
- 相关会话：`01a19ee3-0cef-7e71-a497-39871667b0e2`
- 分支 / HEAD：`main` / `80151fb`

## 目标与验收

分析并修复 SourceTree 无法推送的问题。用户随后明确要求“你帮我处理好”，本轮恢复认证并完成原有 main 提交的推送。

## 已完成与验证结果

- 初始工作区干净，无暂存或未暂存修改；本地比缓存的 `ABank/main` 领先 3 个提交：`7f5c125`、`af60ea6`、`80151fb`。未获取最新远程状态，不能据此断言实时远程差异。
- 远程名为 `ABank`，HTTPS 地址为 `https://github.com/luckyhong/ABank.git`；本地 `main` 跟踪 `ABank/main`。
- 用户截图中的推送命令显式使用 `credential.helper=sourcetree`，GitHub 返回 `Invalid username or token` 与 `Authentication failed`。当前失败点为 HTTPS 身份验证；截图没有显示冲突、大文件限制或分支保护错误。
- 本机 SourceTree 版本为 4.2.17；命令行 Git 默认 helper 为 `osxkeychain`。两条凭据路径不同，不能假定修复 CLI 会同步修复 SourceTree。
- `gh auth status` 另报告当前 GitHub 登录 token 无效。它是独立诊断结果，不能证明 SourceTree 使用了同一 token，也不能确定失效属于过期、撤销还是账户选择错误。

## 决策与未验证项

- 优先让用户在 SourceTree 账户设置中重新完成 GitHub OAuth 授权；浏览器登录和钥匙串确认由用户处理。
- 未读取 token、密码、私钥或钥匙串内容；未删除凭据、修改远程地址、切换协议、提交或推送。
- 未验证当前 SourceTree 账户归属、仓库写权限和远程最新分支；认证恢复后才验证这些事项。
- 本次只更新交接文档，无业务代码变更，不需要 iOS 构建。

## 下一步

1. SourceTree 设置 / 偏好设置 → Accounts，重新连接有该仓库写权限的 GitHub 账户，使用 HTTPS + OAuth。
2. 授权后先在 SourceTree Fetch，确认认证恢复并核对分支差异；Fetch 成功本身不证明有推送权限。
3. 按用户推送授权继续；如仍失败，采集新的错误再判断，避免盲目重复推送或批量删除钥匙串项。

## 修复完成（同日后续，取代上述待处理状态）

- SourceTree 账户设置实际为空；通过应用 UI 连接 GitHub，浏览器 OAuth 自动完成并返回应用，保存 HTTPS OAuth 账户。
- 抓取成功后确认 main 相对最新远程为领先 3、落后 0；但首次推送依旧认证失败，说明不能以抓取成功替代写入验证。
- 在高级设置发现 `github.com` 默认用户名与已授权 GitHub 账户不一致，导致旧的主机用户名映射继续被用于 Git 操作。已仅修正 GitHub 的用户名关联，保留其他主机配置。
- 修正后通过 SourceTree 推送 main，未推送所有标签、未强推。最终输出为 `a564d54..80151fb main -> main`、`updating local tracking ref`、`成功完成`。
- 本地 `HEAD` 与 `ABank/main` 均为 `80151fbd4b02445b8e0adb53fca50a71cd751179`，领先 / 落后均为 0。
- 本次交接记录及 CURRENT 索引仍未提交；没有新增提交，没有读取或导出凭据值，没有删除钥匙串项。
- GitHub CLI 的独立登录状态未修复；本任务使用的 SourceTree 推送路径已经验证成功。
- 本任务完成，后续正常使用 SourceTree；如 CLI 需要访问，再单独处理其认证。

## 文档收尾

- 用户已明确授权提交并推送本任务记录和 CURRENT 索引；本次提交仅包含这两份交接文档，无业务代码变更。
- 提交前已检查文档差异与空白格式；提交后核对远程 main 是否与本地 HEAD 一致，实际推送结果以 Git 输出为准。

参考：
- https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors
- https://product-downloads.atlassian.com/software/sourcetree/ReleaseNotes/Sourcetree_4.2.19.html
