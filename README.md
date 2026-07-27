# claude-context-statusline

A [Claude Code](https://claude.com/claude-code) status line that shows how much of the model's context window you've consumed: a colored progress bar, a grouped token count, and a percentage.

```
████████░░░░ 130.000 tok 65%
```

- **Grey** ≤ 50%
- **Yellow** 51–80%
- **Red** ≥ 80%

## How it works

Claude Code passes each status line command a JSON object on stdin containing `transcript_path`. The script reads the last main-chain assistant message's `usage` and sums the tokens actually held in context:

```
input_tokens + cache_read_input_tokens + cache_creation_input_tokens
```

(Output tokens are not carried into the next turn, so they're excluded.) That total is divided by the context window to get the percentage.

## Requirements

- `jq`
- `awk` (built in on macOS/Linux)

## Install

1. Copy the script somewhere stable:

   ```sh
   cp statusline-context.sh ~/.claude/statusline-context.sh
   chmod +x ~/.claude/statusline-context.sh
   ```

2. Point your `~/.claude/settings.json` at it:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash \"/Users/YOU/.claude/statusline-context.sh\""
     }
   }
   ```

3. Restart Claude Code (or reload via the `/statusline` menu).

## Configuration

The context window is hardcoded near the top of the script:

```sh
WINDOW=200000
```

Bump it to `1000000` if you run a 1M-context model. Colors, bar width (`width=12`), and thresholds are plain values in the `awk` block — edit to taste.

## License

MIT
