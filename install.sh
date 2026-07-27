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

[ -f "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq --arg cmd "bash \"$dst\"" \
   '.statusLine = {type:"command", command:$cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"

echo "installed -> $dst"
echo "settings patched -> $settings"
echo "restart Claude Code (or /statusline)"
