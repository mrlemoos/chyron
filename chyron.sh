#!/usr/bin/env bash
# Context-window usage statusline: colored progress bar + grouped token count + percent.
# Grey <=50%, yellow 51-80%, red >=80%.
# Reads live usage straight from the harness stdin JSON (.context_window). The old
# approach parsed the transcript file, but Claude Code doesn't reliably flush it to
# the advertised path, so it read 0. Window size also comes from stdin (200k vs 1M).
in=$(cat)
read -r used window < <(printf '%s' "$in" | jq -r \
  '"\(.context_window.total_input_tokens // 0) \(.context_window.context_window_size // 200000)"')
[ -z "$used" ] && used=0
[ -z "$window" ] && window=200000

awk -v u="$used" -v w="$window" 'BEGIN{
  pct = (w>0)? (u/w)*100 : 0
  width = 12
  filled = int(pct*width/100 + 0.5); if(filled>width) filled=width; if(filled<0) filled=0
  grey="\033[90m"; yellow="\033[33m"; red="\033[31m"; reset="\033[0m"
  col = (pct>=80)? red : (pct>50)? yellow : grey
  fill=""; for(i=0;i<filled;i++) fill=fill "\xe2\x96\x88"    # full block
  empty=""; for(i=filled;i<width;i++) empty=empty "\xe2\x96\x91"  # light shade
  tok = (u>=1000)? sprintf("%.1fk", u/1000) : sprintf("%d", u)
  printf "%s%s%s%s%s %s tok %s%.0f%%%s", col, fill, grey, empty, reset, tok, col, pct, reset
}'
