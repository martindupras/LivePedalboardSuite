#!/usr/bin/env bash
#
# concat-files.sh — Recursively concatenate files of a given type, with path headers
# Usage:
#   ./concat-files.sh -p '*.txt' [-o out.txt] [-x dirToExclude ...] [--mode header|tsv] [--absolute] [--no-sort]
#
# Defaults:
#   - pattern:     '*.txt'
#   - output:      stdout
#   - excludes:    .git, node_modules
#   - mode:        header   (prints a banner line with the path, then the file contents)
#   - path style:  relative (use --absolute for full absolute paths)
#   - sorting:     NUL-safe if GNU sort/gsort is available; otherwise falls back to unsorted
#
# Notes:
#   - NUL-safe (handles any filenames).
#   - Assumes text files. For binary data, consider filtering or adjusting.
#   - If -o is inside the tree, the script will avoid including the output file in its own output.
set -Eeuo pipefail

print_help() {
  sed -n '2,60p' "$0"
  cat <<'EOF'

Examples:
  # Concatenate all .sc files to out.txt with headers
  ./concat-files.sh -p '*.sc' -o out.txt

  # TSV mode: each line = "<path>\t<content with newlines collapsed>"
  ./concat-files.sh -p '*.md' --mode tsv -o files.tsv

  # Exclude extra directories
  ./concat-files.sh -p '*.py' -x build -x dist -o py-all.txt

  # Absolute paths in headers
  ./concat-files.sh -p '*.txt' --absolute -o abs.txt
EOF
}

# --- Defaults ---
pattern='*.txt'
out=''
mode='header'     # 'header' or 'tsv'
absolute=0
no_sort=0
# Default excludes (directory names, matched anywhere in the tree)
excludes=( ".git" "node_modules" )

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--pattern)
      [[ $# -ge 2 ]] || { echo "Error: -p|--pattern requires a value" >&2; exit 2; }
      pattern=$2; shift 2;;
    -o|--out)
      [[ $# -ge 2 ]] || { echo "Error: -o|--out requires a value" >&2; exit 2; }
      out=$2; shift 2;;
    -x|--exclude)
      [[ $# -ge 2 ]] || { echo "Error: -x|--exclude requires a value" >&2; exit 2; }
      excludes+=("$2"); shift 2;;
    --mode)
      [[ $# -ge 2 ]] || { echo "Error: --mode requires a value" >&2; exit 2; }
      case "$2" in header|tsv) mode=$2;; *) echo "Error: --mode must be 'header' or 'tsv'." >&2; exit 2;; esac
      shift 2;;
    --absolute)
      absolute=1; shift;;
    --no-sort)
      no_sort=1; shift;;
    -h|--help)
      print_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; print_help; exit 2;;
  esac
done
# Compute absolute path of output (if any) to avoid including it
out_abs=""
if [[ -n "$out" ]]; then
  case "$out" in
    /*) out_abs="$out";;
     *) out_abs="$PWD/$out";;
  esac
fi

# Pick a NUL-safe sort if available: prefer gsort (Homebrew coreutils) then GNU sort; else no sorting.
sort_bin=""
if [[ "$no_sort" -eq 0 ]]; then
  if command -v gsort >/dev/null 2>&1; then
    sort_bin="gsort"
  elif sort -z </dev/null >/dev/null 2>&1; then
    sort_bin="sort"
  else
    echo "Note: No NUL-safe sort ('gsort' or 'sort -z') available; output not sorted." >&2
  fi
fi

# Build the find(1) command with prunes and NUL-separated output
# Correct structure:
#   find . -type d \( -name ex1 -o -name ex2 ... \) -prune -o -type f -name "$pattern" -print0
find_cmd=(find .)

if [[ "${#excludes[@]}" -gt 0 ]]; then
  find_cmd+=(-type d '(')
  first=1
  for ex in "${excludes[@]}"; do
    if [[ $first -eq 1 ]]; then
      find_cmd+=(-name "$ex")
      first=0
    else
      find_cmd+=(-o -name "$ex")
    fi
  done
  find_cmd+=(')' -prune -o)
fi

# Always match files by pattern and print NUL-terminated names
find_cmd+=(-type f -name "$pattern" -print0)

# Function to emit the NUL-separated file list (optionally sorted)
find_out_stream() {
  if [[ -n "$sort_bin" ]]; then
    "${find_cmd[@]}" | "$sort_bin" -z
  else
    "${find_cmd[@]}"
  fi
}

# Stream NUL-terminated file names and format output
{
  find_out_stream
} | while IFS= read -r -d '' f; do
  # Normalize absolute path for comparison and optional display
  file_abs="$PWD/${f#./}"

  # Skip the output file itself if it appears
  if [[ -n "$out_abs" && "$file_abs" -ef "$out_abs" ]]; then
    continue
  fi

  if [[ $absolute -eq 1 ]]; then
    display_path="$file_abs"
  else
    display_path="${f#./}"
  fi

  if [[ "$mode" == "tsv" ]]; then
    # One line per file: <path>\t<content with newlines collapsed>
    printf '%s\t' "$display_path"
    tr '\n' ' ' < "$f" | sed -E 's/[[:space:]]+$//'
    printf '\n'
  else
    # Header banner + full content + blank line
    printf '===== %s =====\n' "$display_path"
    cat -- "$f"
    printf '\n'
  fi
done > "${out:-/dev/stdout}"

