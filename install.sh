#!/usr/bin/env bash
# Install chyron statusline: copy script, chmod, wire ~/.claude/settings.json.
set -euo pipefail

# Ask a Y/n question on the real tty. Silent+default-yes when no usable tty
# (curl | bash with no terminal). `: >/dev/tty` probes an actually-openable tty.
ask() {  # ask "prompt" -> 0 if yes
  local reply=y
  if { : >/dev/tty; } 2>/dev/null; then
    printf '  %s [Y/n] ' "$1" >/dev/tty; read -r reply </dev/tty
  fi
  case ${reply:-y} in [Nn]*) return 1;; *) return 0;; esac
}

# Best-guess install command for a missing dep, or empty if no known pm.
# ponytail: assumes package name == command name (true for jq/awk/curl on the
# common pms); special-case if a distro ever names them differently.
pm_install() {  # pm_install <dep> -> echoes command
  local d=$1
  if   command -v brew    >/dev/null; then echo "brew install $d"
  elif command -v apt-get >/dev/null; then echo "sudo apt-get install -y $d"
  elif command -v dnf     >/dev/null; then echo "sudo dnf install -y $d"
  elif command -v pacman  >/dev/null; then echo "sudo pacman -S --noconfirm $d"
  elif command -v apk     >/dev/null; then echo "sudo apk add $d"
  fi
}

for dep in jq awk curl; do
  command -v "$dep" >/dev/null && continue
  cmd=$(pm_install "$dep")
  # Only offer to install when a real tty can confirm — never run sudo unattended.
  if [ -n "$cmd" ] && { : >/dev/tty; } 2>/dev/null && ask "$dep not found. Install with '$cmd'?"; then
    eval "$cmd" && command -v "$dep" >/dev/null || { echo "could not install $dep" >&2; exit 1; }
  else
    echo "need $dep" >&2; exit 1
  fi
done

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

# Wizard: which extra segments to show. Reads from /dev/tty so it works under
# curl|bash; no usable tty keeps the defaults (see ask() at top).
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
