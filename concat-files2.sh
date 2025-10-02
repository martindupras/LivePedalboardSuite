#!/usr/bin/env bash
#
# concat-files2.sh — Recursively concatenate files, with path headers
# Usage:
#   ./concat-files2.sh [-p '<glob>'] [-o out.txt] [-x dirToExclude ...] \
#                      [--mode header|tsv] [--absolute] [--no-sort] \
#                      [--include-underscore] [--include-dotfiles]
#
# Defaults:
#   - pattern: '*'             (match ALL files; no filetype filtering)
#   - output: stdout           (prefer -o to avoid self-inclusion)
#   - excludes: .git, node_modules, _*  (ignore underscore-prefixed directories)
#   - dotfiles: ignored by default (basenames starting with '.')
#   - mode: header             (prints a banner line with the path, then contents)
#   - path style: relative     (use --absolute for full absolute paths)
#   - sorting: NUL-safe if GNU sort/gsort is available; otherwise unsorted
#
# Notes:
#   - To avoid self-inclusion, prefer:  ./concat-files2.sh -o out.txt
#     (Avoid: ./concat-files2.sh > out.txt — the shell redirect creates the file inside the tree.)
#   - NUL-safe (handles any filenames).
#   - If -o is inside the tree, we prune it from find and write to /tmp first, then move.

set -Eeuo pipefail

print_help() {
  cat <<'EOF'
Examples:
  # Concatenate ALL files to out.txt with headers (underscore dirs ignored; dotfiles ignored)
  ./concat-files2.sh -o out.txt

  # TSV mode: each line = "<path>\t<content with newlines collapsed>"
  ./concat-files2.sh --mode tsv -o files.tsv

  # Exclude extra directories
  ./concat-files2.sh -x build -x dist -o all.txt

  # Absolute paths in headers
  ./concat-files2.sh --absolute -o abs.txt

  # Include underscore-prefixed dirs (override default ignore)
  ./concat-files2.sh --include-underscore -o all_including_underscores.txt

  # Include dotfiles as well (override default ignore of .* files)
  ./concat-files2.sh --include-dotfiles -o all_including_dotfiles.txt

  # Filter to a specific glob (e.g., only .sc files)
  ./concat-files2.sh -p '*.sc' -o sc_all.txt
EOF
}

# --- Defaults ---
pattern='*'       # match ALL files by default
out=''
mode='header'     # 'header' or 'tsv'
absolute=0
no_sort=0
ignore_underscore=1   # default: ignore _* directories
ignore_dotfiles=1     # default: ignore files whose basenames start with '.'

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
    --include-underscore)
      ignore_underscore=0; shift;;
    --include-dotfiles)
      ignore_dotfiles=0; shift;;
    -h|--help)
      print_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; print_help; exit 2;;
  esac
done

# Add the "_*" ignore (underscore-prefixed directories) unless overridden
if [[ $ignore_underscore -eq 1 ]]; then
  excludes+=("_*")
fi

# Compute absolute path of output (if any)
out_abs=""
out_rel_in_tree=""
if [[ -n "$out" ]]; then
  case "$out" in
    /*) out_abs="$out";;
    *)  out_abs="$PWD/$out";;
  esac
  # If the output path sits under $PWD, compute a "./relative" path for find -path pruning
  if [[ "${out_abs#$PWD/}" != "$out_abs" ]]; then
    out_rel_in_tree="./${out_abs#$PWD/}"
  fi
fi

# Pick a NUL-safe sort if available
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

# Build the find(1) command with explicit prunes and NUL-separated output.
# Structure:
#   find . \
#     \( -type d \( -name ex1 -o -name ex2 ... \) -prune \
#        -o -path "./rel/out.txt" -prune \
#        -o -type f -name "$pattern" [ -not -name '.*' ] -print0 \)
find_cmd=(find .)
find_cmd+=( '(' )
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
  find_cmd+=(')' -prune)
fi

# Prune the output file itself if it's inside the tree
if [[ -n "$out_rel_in_tree" ]]; then
  if [[ "${#excludes[@]}" -gt 0 ]]; then
    find_cmd+=( -o )
  fi
  find_cmd+=( -path "$out_rel_in_tree" -prune )
fi

# File match branch
if [[ "${#excludes[@]}" -gt 0 || -n "$out_rel_in_tree" ]]; then
  find_cmd+=( -o )
fi
find_cmd+=( -type f -name "$pattern" )
if [[ $ignore_dotfiles -eq 1 ]]; then
  find_cmd+=( -not -name '.*' )
fi
find_cmd+=( -print0 ')' )

# Function to emit the NUL-separated file list (optionally sorted)
find_out_stream() {
  if [[ -n "$sort_bin" ]]; then
    "${find_cmd[@]}" | "$sort_bin" -z
  else
    "${find_cmd[@]}"
  fi
}

# Choose output destination:
# - If -o is given: write to a temp file outside the tree, then move to final path.
# - If no -o: write to stdout (NOTE: avoid shell redirection to a file inside the tree).
tmp_out=""
redirect_target="/dev/stdout"
if [[ -n "$out" ]]; then
  tmp_out="$(mktemp "${TMPDIR:-/tmp}/concat-files2.XXXXXXXX")"
  redirect_target="$tmp_out"
fi

# Stream NUL-terminated file names and format output
{
  find_out_stream
} | while IFS= read -r -d $'\0' f; do
  # Normalize absolute path for comparison and optional display
  file_abs="$PWD/${f#./}"

  # Extra guard: skip the final output path if seen (double-protection)
  if [[ -n "$out_abs" && -e "$out_abs" && "$file_abs" -ef "$out_abs" ]]; then
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
done > "$redirect_target"

# Finalize: if using -o, move the temp file into place
if [[ -n "$out" ]]; then
  mv -f -- "$tmp_out" "$out"
fi
