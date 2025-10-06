#!/usr/bin/env bash
# rename_orphan_scd.sh
# Renames orphaned .scd scripts reported by the "Global Unused Report"
# from: <path>.scd  ->  <path>.scd_UNUSED
#
# Usage:
#   bash rename_orphan_scd.sh "/absolute/path/to/Find_Unused_Classes_And_Scripts — 251006_092611.txt"
# Optional env:
#   DRY_RUN=0 to actually rename (default is 1 for preview)
#   ROOT=/custom/suite/root to override the default

set -euo pipefail

# ---- configuration ----
ROOT_DEFAULT="/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite"
ROOT="${ROOT:-$ROOT_DEFAULT}"
REPORT="${1:-}"
DRY_RUN="${DRY_RUN:-1}"   # 1 = preview only; 0 = actually rename

if [[ -z "${REPORT}" ]]; then
  echo "ERROR: Please pass the path to your Global Unused Report (.txt)."
  echo "Example:"
  echo "  bash $(basename "$0") \"$ROOT/Find_Unused_Classes_And_Scripts — 251006_092611.txt\""
  exit 2
fi
if [[ ! -f "$REPORT" ]]; then
  echo "ERROR: Report file not found: $REPORT"
  exit 2
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
logdir="$ROOT/_archived"
mkdir -p "$logdir"
logfile="$logdir/rename_orphan_scd_${timestamp}.log"

echo "Suite root: $ROOT"
echo "Report:     $REPORT"
echo "Dry run:    $DRY_RUN (1=preview; 0=rename)"
echo "Log:        $logfile"
echo "Parsing the '== ORPHAN .SCD SCRIPTS' section..."
echo

# Extract the orphan .scd list into a temp file (Bash 3.2 friendly)
orphans_tmp="$(mktemp -t orphan_scd.XXXXXXXX)" || { echo "mktemp failed"; exit 2; }

# Pull only the lines within the ORPHAN section, strip " - " prefix, keep *.scd
awk '
  BEGIN { flag = 0 }
  /^== ORPHAN .SCD SCRIPTS/ { flag = 1; next }
  /^== / { flag = 0 }
  flag && $0 ~ /^ - / { sub(/^ - /, "", $0); print $0 }
' "$REPORT" \
| sed -e 's/\r$//' \
| grep -E '\.scd$' > "$orphans_tmp"

# Stats
count="$(wc -l < "$orphans_tmp" | tr -d ' ')"
if [[ "${count}" == "0" ]]; then
  echo "No orphan .scd entries found in the report. Exiting."
  rm -f "$orphans_tmp"
  exit 0
fi

echo "Found $count orphan .scd path(s) in the report."
echo

# Process each orphan path
renamed=0
skipped=0
missing=0
exists=0

# Read line-by-line, preserving spaces
while IFS= read -r rel; do
  # Skip empty lines, just in case
  [[ -z "$rel" ]] && continue

  # Only act on .scd files (defensive)
  case "$rel" in
    *.scd) : ;;
    *) continue ;;
  esac

  src="$ROOT/$rel"
  dst="${src}_UNUSED"

  if [[ ! -e "$src" ]]; then
    echo "SKIP (missing): $rel" | tee -a "$logfile"
    ((missing++)) || true
    continue
  fi

  if [[ -e "$dst" ]]; then
    echo "SKIP (dest exists): $rel -> $(basename "$rel")_UNUSED" | tee -a "$logfile"
    ((exists++)) || true
    continue
  fi

  echo "RENAME: $rel -> $(basename "$rel")_UNUSED" | tee -a "$logfile"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    mv -- "$src" "$dst"
  fi
  ((renamed++)) || true
done < "$orphans_tmp"

rm -f "$orphans_tmp"

echo
echo "Summary: renamed=$renamed, skipped_missing=$missing, skipped_dest_exists=$exists, total_listed=$count" | tee -a "$logfile"
echo "Done. Log written to: $logfile"
