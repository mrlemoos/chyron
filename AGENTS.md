# AGENTS.md

Guidance for coding agents working in **chyron** — a context-window usage statusline for Claude Code.

## What this is

Three files, no build, no deps beyond `jq` and coreutils:

- `chyron.sh` — the statusline. Reads harness JSON on **stdin**, prints a colored bar + token count + percent to stdout. One `awk` does the rendering.
- `install.sh` — copies `chyron.sh` to `~/.claude/`, chmods it, patches `~/.claude/settings.json` via `jq`. Works both from a local clone and piped (`curl | bash`).
- `.github/workflows/bump-homebrew.yml` — on release published, bumps the formula in the `mrlemoos/homebrew-chyron` tap (url + sha256). Pushes with `secrets.COMMITTER_TOKEN` (a PAT with **Contents: write** on the tap repo — the default `GITHUB_TOKEN` can't push cross-repo).

## Message beauty pattern

Any user-facing script output uses this. Detect a color-capable tty, honor `NO_COLOR`, and fall back to plain text otherwise — never emit raw escape codes into a pipe or log.

```bash
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  b=$'\033[1m'; g=$'\033[32m'; d=$'\033[2m'; r=$'\033[0m'; ok=$'\033[32m✓'$'\033[0m'
else
  b=''; g=''; d=''; r=''; ok='✓'
fi

printf '\n  %schyron installed%s\n\n' "$b$g" "$r"
printf '  %s  script    %s%s%s\n' "$ok" "$d" "$dst" "$r"
printf '  %s  settings  %s%s%s\n' "$ok" "$d" "$settings" "$r"
```

Rules:
- `[ -t 1 ]` (stdout is a tty) **and** `[ -z "${NO_COLOR:-}" ]` gate all color. Both must pass.
- Color vars empty-string in the plain branch, so the same `printf` lines work either way — no branching in the output itself.
- Two-space left indent, blank line above and below the block, `✓` per item, dim (`\033[2m`) for paths/hints, bold+green for the headline.
- `printf`, never `echo -e`.

## Conventions

- `set -euo pipefail` at the top of every script.
- Check hard deps up front (`command -v jq >/dev/null || { echo "need jq" >&2; exit 1; }`).
- Colors are raw ANSI escapes; keep the `chyron.sh` thresholds in sync with its header comment (grey ≤50%, yellow 51–80%, red ≥80%).
- One header comment per script saying what it does and any non-obvious *why* (see `chyron.sh` lines on why it reads stdin, not the transcript file).

## Release flow

1. Commit + push to `main`.
2. `gh release create vX.Y.Z --title vX.Y.Z --notes "..."` — this triggers the bump workflow.
3. Confirm: `gh run list -L 1`, then check the tap: `gh api repos/mrlemoos/homebrew-chyron/contents/Formula/chyron.rb --jq '.content' | base64 -d`.
4. If the bump 403s with `denied to mrlemoos`, the `COMMITTER_TOKEN` PAT lacks write on the tap — fix the token scope, not the workflow.

## Testing

No framework. Verify by piping sample JSON:

```bash
echo '{"context_window":{"total_input_tokens":120000,"context_window_size":200000}}' | bash chyron.sh
```
