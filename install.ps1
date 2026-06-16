# CC-Max statusline installer - Windows (PowerShell 5.1+). Idempotent.
# Does: clone/pull this fork into %USERPROFILE%\.claude\statusline, self-test,
# then merge ONLY the statusLine key into settings.json (never clobbers other
# keys), using a FORWARD-SLASH command path (Claude Code runs the statusLine
# command via Git Bash on Windows when it is installed; backslashes get eaten).
# One-time supply-chain audit is recorded in LOCAL-PATCH.md.
$ErrorActionPreference = 'Stop'

$RepoUrl  = 'https://github.com/simonliusm/ClaudeCodeStatusLine'
$Dest     = Join-Path $env:USERPROFILE '.claude\statusline'
$Settings = Join-Path $env:USERPROFILE '.claude\settings.json'
$ScriptPs = Join-Path $Dest 'statusline.ps1'

# 1. ensure repo present & current
if (Test-Path (Join-Path $Dest '.git')) {
  Write-Host "[1/4] update $Dest"
  git -C $Dest pull --ff-only 2>$null
} else {
  Write-Host "[1/4] clone -> $Dest"
  New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
  git clone $RepoUrl $Dest
}

# 2. self-test BEFORE touching settings.json
Write-Host '[2/4] self-test'
$now  = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$json = '{"model":{"display_name":"Opus 4.7"},"cwd":"C:/tmp","context_window":{"context_window_size":200000,"current_usage":{"input_tokens":1200,"cache_creation_input_tokens":8000,"cache_read_input_tokens":35000}},"rate_limits":{"five_hour":{"used_percentage":41,"resets_at":' + ($now + 8000) + '},"seven_day":{"used_percentage":73,"resets_at":' + ($now + 400000) + '}}}'
$out = $json | powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPs
if (-not $out) { Write-Error "self-test produced no output - aborting, $Settings untouched"; exit 1 }
Write-Host "  output: $out"

# 3. merge ONLY .statusLine into settings.json (forward-slash path; preserve other keys)
Write-Host "[3/4] configure $Settings"
$CmdPath = $ScriptPs -replace '\\','/'
$Command = "powershell -NoProfile -ExecutionPolicy Bypass -File $CmdPath"

if ((Test-Path $Settings) -and ((Get-Item $Settings).Length -gt 0)) {
  # 按 UTF-8 读取，避免 zh-CN Windows 默认 GBK 把中文设置值读成乱码导致 JSON 解析失败
  try { $cfg = [System.IO.File]::ReadAllText($Settings) | ConvertFrom-Json }
  catch { Write-Error "$Settings is not valid JSON - back it up and fix, then re-run. Aborting (untouched)."; exit 1 }
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path $Settings) | Out-Null
  $cfg = [pscustomobject]@{}
}
$sl = [pscustomobject]@{ type = 'command'; command = $Command }
if ($cfg.PSObject.Properties.Name -contains 'statusLine') { $cfg.statusLine = $sl }
else { $cfg | Add-Member -NotePropertyName statusLine -NotePropertyValue $sl }

$jsonOut = $cfg | ConvertTo-Json -Depth 32
[System.IO.File]::WriteAllText($Settings, $jsonOut, (New-Object System.Text.UTF8Encoding $false))

# 4. done
$sha = (git -C $Dest rev-parse --short HEAD 2>$null)
Write-Host '[4/4] PASS'
Write-Host "RESULT: os=Windows sha=$sha cmd=$Command"
Write-Host 'Restart Claude Code to load the statusline.'
