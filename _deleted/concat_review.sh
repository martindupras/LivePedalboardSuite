#!/usr/bin/env bash
# run from your repo root

OUT=~/Desktop/review_$(date +%Y%m%d-%H%M).txt
FILES=(
  "CommandTree/CommandManager.sc"
  "MagicPedalboard/MagicDisplayGUI_GridDemo.sc"
  "MagicPedalboard/MagicDisplayGUI_GridDemo_Ext_ShowExpectation.sc"  # remove if you didn't add it
)

: > "$OUT"
for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    printf '\n===== %s =====\n' "$f" >> "$OUT"
    cat "$f" >> "$OUT"
  else
    printf '\n===== %s (MISSING) =====\n' "$f" >> "$OUT"
  fi
done

# macOS viewer:
if command -v open >/dev/null 2>&1; then open "$OUT"; fi
# Linux viewer (uncomment if you prefer):
# if command -v xdg-open >/dev/null 2>&1; then xdg-open "$OUT"; fi

echo "Wrote: $OUT"

