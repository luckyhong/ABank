# 项目续接说明

本目录由 Claude Code 与 Codex 共用，不依赖登录账号。

1. 开始：读根 AGENTS.md / CLAUDE.md、CURRENT.md、对应 tasks/ 记录，再核对实际文件与 Git 状态。
2. 关键节点：执行者更新自己的任务记录，分别标明已验证、历史叙述和未知事项。
3. 交接：`"$HOME/.local/bin/ac" checkpoint --project "$PWD" --task <任务>`；然后 `"$HOME/.local/bin/ac" context --project "$PWD" --task <任务> --tool codex` 或 `claude`。
4. 备份：检查点只保存文字与状态。完整备份使用 `"$HOME/.local/bin/ac" backup --destination <已有目录>`，快照校验使用 `"$HOME/.local/bin/ac" verify --snapshot <快照>`。
5. 恢复：`"$HOME/.local/bin/ac" restore --snapshot <快照> --target <不存在的新目录>`；先查看恢复报告，再安装依赖和重新认证。

## 环境和资产

项目专有环境、运行/测试/构建命令继续以根规范、README、依赖锁文件为准。本次没有运行各项目业务构建或发布验证。
参考目录保留了原有完整规范；其中代码块和行内路径仍以仓库根为基准，Markdown 相对链接已调整。

原始音频、原创素材、无法重下载的资源需要完整备份；被 Git 忽略不等于可以丢弃。
node_modules、虚拟环境等缓存从锁文件恢复。具体排除项以快照 exclusions.json 为准；未知资产不自动当作缓存删除。
Git remotes、MCP、第三方 SDK、浏览器登录、开发签名等须按恢复报告重新配置；不复制账号凭据。

自动记忆只作辅助，本目录与实际代码用于核对当前工作。原生聊天恢复另行验证，侧栏可见不等于资料完整。

恢复前阅读 [环境与资产恢复](RECOVERY.md)。
