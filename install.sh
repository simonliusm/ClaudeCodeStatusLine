#!/usr/bin/env bash
# CC-Max statusline installer — Linux/macOS. Idempotent, safe to re-run.
# Does: clone/pull this fork into ~/.claude/statusline, ensure jq, chmod,
# self-test, then merge ONLY the statusLine key into ~/.claude/settings.json
# (never clobbers other keys). One-time supply-chain audit is recorded in
# LOCAL-PATCH.md, so no per-install diff review is needed.
set -euo pipefail

REPO_URL="https://github.com/simonliusm/ClaudeCodeStatusLine"
DEST="$HOME/.claude/statusline"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT="$DEST/statusline.sh"

log(){ printf '%s\n' "$*" >&2; }

if [ "$(id -u)" = "0" ]; then SUDO=""
elif command -v sudo >/dev/null 2>&1; then SUDO="sudo"
else SUDO=""; fi

# 1. ensure repo present & current at $DEST
if [ -d "$DEST/.git" ]; then
  log "[1/5] update $DEST"
  git -C "$DEST" pull --ff-only 2>/dev/null || log "  (pull skipped; using existing checkout)"
else
  log "[1/5] clone -> $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO_URL" "$DEST"
fi

# 2. jq (statusline.sh hard-depends on it)
if command -v jq >/dev/null 2>&1; then
  log "[2/5] jq present"
else
  log "[2/5] installing jq"
  if   command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update -y && $SUDO apt-get install -y jq
  elif command -v brew    >/dev/null 2>&1; then brew install jq
  elif command -v dnf     >/dev/null 2>&1; then $SUDO dnf install -y jq
  elif command -v yum     >/dev/null 2>&1; then $SUDO yum install -y jq
  elif command -v apk     >/dev/null 2>&1; then $SUDO apk add jq
  elif command -v pacman  >/dev/null 2>&1; then $SUDO pacman -S --noconfirm jq
  else log "  !! jq missing and no known package manager — install jq, then re-run"; exit 1
  fi
fi
chmod +x "$SCRIPT"

# 3. self-test BEFORE touching settings.json
log "[3/5] self-test"
now=$(date +%s)
tj='{"model":{"display_name":"Opus 4.7"},"cwd":"/tmp","context_window":{"context_window_size":200000,"current_usage":{"input_tokens":1200,"cache_creation_input_tokens":8000,"cache_read_input_tokens":35000}},"rate_limits":{"five_hour":{"used_percentage":41,"resets_at":'$((now+8000))'},"seven_day":{"used_percentage":73,"resets_at":'$((now+400000))'}}}'
out="$(printf '%s' "$tj" | timeout 10 bash "$SCRIPT" 2>/dev/null || true)"
if [ -z "$out" ]; then
  log "  !! self-test produced no output — aborting, $SETTINGS untouched"; exit 1
fi
log "  output: $out"

# 4. merge ONLY .statusLine into settings.json (preserve all other keys)
log "[4/5] configure $SETTINGS"
mkdir -p "$(dirname "$SETTINGS")"
[ -s "$SETTINGS" ] || printf '{}\n' > "$SETTINGS"
if ! jq empty "$SETTINGS" >/dev/null 2>&1; then
  log "  !! $SETTINGS is not valid JSON — back it up and fix, then re-run. Aborting (untouched)."; exit 1
fi
tmp="$(mktemp)"
jq --arg cmd "$SCRIPT" '.statusLine = {type:"command", command:$cmd}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

# 5. done
sha="$(git -C "$DEST" rev-parse --short HEAD 2>/dev/null || echo '?')"
log "[5/5] PASS"
log "RESULT: os=$(uname -s) sha=$sha cmd=$SCRIPT"
log "Restart Claude Code to load the statusline."
