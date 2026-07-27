#!/usr/bin/env bash
# Install chyron statusline: copy script, chmod, wire ~/.claude/settings.json.
set -euo pipefail

command -v jq >/dev/null || { echo "need jq" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/chyron.sh"
dst="$HOME/.claude/chyron.sh"
settings="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"
install -m 0755 "$src" "$dst"

[ -f "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq --arg cmd "bash \"$dst\"" \
   '.statusLine = {type:"command", command:$cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"

echo "installed -> $dst"
echo "settings patched -> $settings"
echo "restart Claude Code (or /statusline)"
