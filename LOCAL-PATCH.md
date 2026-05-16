# 本地安全补丁说明（勿删）

本 clone 对上游 `statusline.ps1` 打了 2 处本地补丁，目的：**Max 用户只用 Claude Code stdin 传入的 `rate_limits`（5h/7d），杜绝任何凭证读取与外联**。

审查版本：上游 v1.4.3 / commit `5ad839f`。

## 补丁内容

1. **`function Get-OAuthToken {` 之后插入 `return $null`**
   - 效果：永不读取 `~/.claude/.credentials.json` 或 `%LOCALAPPDATA%\Claude Code\credentials.json`，永不调用 `api.anthropic.com/api/oauth/usage`。
   - 代价：失去 `extra_usage`（额外购买额度）段——未购买额外额度时无意义。

2. **`$versionNeedsRefresh = $true` → `$false`**
   - 效果：关闭每 24h 对 `api.github.com` 的版本检查 phone-home。

3. **`Format-ResetTime` / `Format-EpochResetTime` 两函数整体重写为「剩余时间倒计时」**
   - 新增 `Format-Remaining([long]$secs)` 辅助函数；两个函数改为算 `resets_at - 现在` 的 Unix 时间戳差值，输出 `2h13m` / `4d5h` / `47m` / `now`。`$style` 形参保留不破坏调用处（不再使用）。
   - 效果：① 显示「还剩多久重置」而非绝对时刻；② 用纯 epoch 差值，**彻底无时区歧义**（原来是 `.LocalDateTime` 本机时区）；③ 输出纯 ASCII 数字，**zh-CN locale 乱码问题一并消除**（此补丁取代了早先的 InvariantCulture 强制英文方案）。

打补丁后本脚本**零外联、零凭证读取**，只解析 stdin JSON + 本地 `git`（取分支）+ 写 `%TEMP%\claude\` 缓存。

## 升级后如何重打

`git -C "%USERPROFILE%\.claude\statusline" pull` 后，重新执行上述 2 处修改即可（让 Claude 读本文件照做）。升级前务必重新审查 upstream diff。
