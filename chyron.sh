#!/usr/bin/env bash
# Context-window usage statusline: colored progress bar + grouped token count + percent.
# Grey <=50%, yellow 51-80%, red >=80%. Window hardcoded to 200k; bump to 1000000 for a 1M model.
WINDOW=200000

in=$(cat)
tp=$(printf '%s' "$in" | jq -r '.transcript_path // empty')
used=0
if [ -n "$tp" ] && [ -f "$tp" ]; then
  # Fold in document order: a compact_boundary resets context to postTokens (the
  # last assistant usage is pre-compact and stale until the next reply lands).
  used=$(jq -s '
    reduce .[] as $e (0;
      if ($e.type=="system" and $e.subtype=="compact_boundary" and $e.compactMetadata.postTokens)
      then $e.compactMetadata.postTokens
      elif ($e.type=="assistant" and ($e.isSidechain|not) and $e.message.usage)
      then ($e.message.usage
            | (.input_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0))
      else . end)' "$tp" 2>/dev/null)
fi
[ -z "$used" ] && used=0

awk -v u="$used" -v w="$WINDOW" 'BEGIN{
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
