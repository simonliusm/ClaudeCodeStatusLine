# 本地补丁说明（勿删）

本 fork 对上游 **`statusline.ps1`（Windows）与 `statusline.sh`（Linux/macOS）各打了 3 处等效补丁**，目的：**Max 用户只用 Claude Code stdin 传入的 `rate_limits`（5h/7d），杜绝任何凭证读取与外联；重置显示为剩余倒计时**。

审查版本：上游 daniel3303/ClaudeCodeStatusLine v1.4.3 / commit `5ad839f`。
本 fork：`github.com/simonliusm/ClaudeCodeStatusLine`（`upstream` remote 指向原仓库便于同步）。

## 3 处补丁（两脚本一一对应）

| # | statusline.ps1 (PowerShell) | statusline.sh (bash) | 效果 |
|---|---|---|---|
| 1 | `Get-OAuthToken` 首行 `return $null` | `get_oauth_token()` 首行 `echo ""; return 0` | 永不读 `~/.claude/.credentials.json` / keychain，永不调 `api.anthropic.com`。代价：失去 `extra_usage` 段（未购买额外额度时无意义） |
| 2 | `$versionNeedsRefresh = $false` | `version_needs_refresh=false` | 关闭每 24h 对 `api.github.com` 的版本检查 phone-home |
| 3 | `Format-ResetTime`/`Format-EpochResetTime` 重写 + 新增 `Format-Remaining` | `format_reset_time` 重写 + 新增 `format_remaining`，并把 builtin 分支两行内联 `date` 改为 `format_remaining` | 重置显示「还剩多久」倒计时（`2h13m`/`4d5h`/`now`）；纯 epoch 差值**无时区歧义**；纯 ASCII**消除 zh-CN locale 乱码** |

打补丁后两脚本均**零外联、零凭证读取**：只解析 stdin JSON + 本地 `git`（取分支）+ 写临时缓存（`%TEMP%\claude\` / `/tmp/claude/`）。

## 升级上游后如何重打

```
git fetch upstream && git rebase upstream/main   # 或 merge
```
冲突/重置后，按上表对 `statusline.ps1` 与 `statusline.sh` 重新施加 3 处补丁，`git push origin main`。**升级前务必重新审查 upstream diff**（供应链卫生）。
