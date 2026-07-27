#!/usr/bin/env bash
# Install chyron statusline: copy script, chmod, wire ~/.claude/settings.json.
set -euo pipefail

command -v jq >/dev/null || { echo "need jq" >&2; exit 1; }

raw="https://raw.githubusercontent.com/mrlemoos/chyron/main/chyron.sh"
src="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/chyron.sh"
dst="$HOME/.claude/chyron.sh"
settings="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"
if [ -f "$src" ]; then           # local clone
  install -m 0755 "$src" "$dst"
else                             # piped: curl | bash
  curl -fsSL "$raw" -o "$dst"
  chmod 0755 "$dst"
fi

# Wizard: which extra segments to show. Reads from /dev/tty so it works under curl|bash.
# Default yes for both; any non-tty (no /dev/tty) keeps the defaults.
ask() {  # ask "prompt" -> 0 if yes
  local reply=y
  [ -e /dev/tty ] && { printf '  %s [Y/n] ' "$1" >/dev/tty; read -r reply </dev/tty; }
  case ${reply:-y} in [Nn]*) return 1;; *) return 0;; esac
}
conf="$HOME/.claude/chyron.conf"
ask "Show model name?"         && sm=1 || sm=0
ask "Show project (dir) name?" && sp=1 || sp=0
printf 'show_model=%s\nshow_project=%s\n' "$sm" "$sp" > "$conf"

[ -f "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq --arg cmd "bash \"$dst\"" \
   '.statusLine = {type:"command", command:$cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"

# pretty output (falls back to plain if no color tty)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  b=$'\033[1m'; g=$'\033[32m'; d=$'\033[2m'; r=$'\033[0m'; ok=$'\033[32m✓'$'\033[0m'
else
  b=''; g=''; d=''; r=''; ok='✓'
fi

printf '\n  %schyron installed%s\n\n' "$b$g" "$r"
printf '  %s  script    %s%s%s\n' "$ok" "$d" "$dst" "$r"
printf '  %s  settings  %s%s%s\n' "$ok" "$d" "$settings" "$r"
printf '  %s  config    %s%s%s\n' "$ok" "$d" "$conf" "$r"
printf '\n  %sRestart Claude Code or run %s/statusline%s%s to see it.%s\n\n' "$d" "$r$b" "$r" "$d" "$r"
