# Claude Code Status Line

A custom status line for [Claude Code](https://claude.com/claude-code) that displays model info, token usage, rate limits, and reset times in a single compact line. It runs as an external shell command, so it does not slow down Claude Code or consume any extra tokens.

> **This is a patched fork** for Claude Max users: zero outbound calls, zero credential reads, reset shown as a remaining-time countdown. What changed vs. upstream `daniel3303/ClaudeCodeStatusLine` (and the one-time supply-chain audit) is documented in **[LOCAL-PATCH.md](LOCAL-PATCH.md)**.

## 🚀 Quickstart

One command. It clones/updates into `~/.claude/statusline`, installs deps, self-tests, and merges **only** the `statusLine` key into your `settings.json` (other keys untouched). It aborts without touching `settings.json` if the self-test fails. Then **restart Claude Code**.

**Linux / macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/simonliusm/ClaudeCodeStatusLine/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/simonliusm/ClaudeCodeStatusLine/main/install.ps1 | iex
```

Prefer not to pipe to a shell? Clone first, then run the installer:
```bash
# Linux / macOS
git clone https://github.com/simonliusm/ClaudeCodeStatusLine ~/.claude/statusline 2>/dev/null || git -C ~/.claude/statusline pull --ff-only
bash ~/.claude/statusline/install.sh
```
```powershell
# Windows
$d="$env:USERPROFILE\.claude\statusline"; if (Test-Path "$d\.git") { git -C $d pull --ff-only } else { git clone https://github.com/simonliusm/ClaudeCodeStatusLine $d }
powershell -NoProfile -ExecutionPolicy Bypass -File "$d\install.ps1"
```

The installer prints a final `RESULT: os=… sha=… cmd=…` line; paste that back if a CC ran it for you.

## Screenshot

![Status Line Screenshot](screenshot.png)

## What it shows

| Segment | Description |
|---------|-------------|
| **Model** | Current model name (e.g., Opus 4.7) |
| **CWD@Branch** | Current folder name, git branch, and file changes (+/-) |
| **Tokens** | Used / total context window tokens (% used) |
| **Effort** | Reasoning effort level (low, med, high, xhigh) |
| **5h** | 5-hour rate limit usage percentage and reset time |
| **7d** | 7-day rate limit usage percentage and reset time |
| **Extra** | Extra usage credits spent / limit (if enabled) |
| **Update** | Appears when a new version is available (checked every 24h) |

Usage percentages are color-coded: green (<50%) → yellow (≥50%) → orange (≥70%) → red (≥90%).

## Installation

Ask Claude Code:

> Clone https://github.com/daniel3303/ClaudeCodeStatusLine to `~/.claude/statusline/` (or `%USERPROFILE%\.claude\statusline\` on Windows) and configure it as my status bar by following its INSTALL.md.

Claude will clone the repo to that path, pick the right script for your OS, and update `settings.json`. Full step-by-step instructions Claude follows live in [INSTALL.md](INSTALL.md).

Restart Claude Code after Claude saves the configuration.

### Updating

When the status line shows a new release is available, ask Claude:

> Find my installed status bar and update it.

Or update it yourself:

```bash
git -C ~/.claude/statusline pull
```

No `settings.json` changes are needed — the path stays valid across versions.

## Requirements

- Claude Code with OAuth authentication (Pro/Max subscription for rate-limit and extra-usage data)
- `git` in `PATH`
- macOS / Linux: `jq` and `curl`
- Windows: PowerShell 5.1+ (default on Windows 10/11)

## Caching

Usage data from the Anthropic API is cached for 60 seconds at `/tmp/claude/statusline-usage-cache-<hash>.json` (or `%TEMP%\claude\...` on Windows). Release checks are cached for 24 hours. Both caches are shared across concurrent Claude Code instances to avoid rate limits.

## Update Notifications

The status line checks GitHub for new releases once every 24 hours. When a newer version is available, a second line appears below the status line. The check fails silently if the API is unreachable.

## License

MIT

## Author

Daniel Oliveira

[![Website](https://img.shields.io/badge/Website-FF6B6B?style=for-the-badge&logo=safari&logoColor=white)](https://danielapoliveira.com/)
[![X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/daniel_not_nerd)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/daniel-ap-oliveira/)
