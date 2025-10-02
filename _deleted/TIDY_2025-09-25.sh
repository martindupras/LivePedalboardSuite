# TIDY_2025-09-25.sh  — run from project root

set -euo pipefail

echo "== Create archive folder =="
mkdir -p "temp files/_archive_2025-09-25"

echo "== Archive large inventories (reversible) =="
[ -f 20250925-1129_allSCfiles.txt ] && mv -v 20250925-1129_allSCfiles.txt "temp files/_archive_2025-09-25"/ || true
[ -f 20250925-1129_allSCDfiles.txt ] && mv -v 20250925-1129_allSCDfiles.txt "temp files/_archive_2025-09-25"/ || true

echo "== Remove empty listing file (0 bytes) =="
[ -f lslr_202509251302.txt ] && [ ! -s lslr_202509251302.txt ] && rm -v lslr_202509251302.txt || true

echo "== Fix folder typo if present (troubeshooting -> troubleshooting) =="
if [ -d "MagicPedalboard/troubeshooting" ] && [ ! -d "MagicPedalboard/troubleshooting" ]; then
  mv -v "MagicPedalboard/troubeshooting" "MagicPedalboard/troubleshooting"
fi

echo "== Ensure canonical troubleshooting folder exists =="
mkdir -p "MagicPedalboard/troubleshooting"

echo "== Consolidate latest GUI scripts into canonical folder =="
# Move only if files exist in current dir (or add your actual paths if different)
for f in \
  MagicDisplayGUI_New_ServerBootAndProbe_v0.3.5.scd \
  MagicDisplayGUI_New_Window_v0.3.5.scd \
  MagicDisplayGUI_New_Cleanup_v0.3.6.scd
do
  if [ -f "$f" ]; then
    mv -v "$f" "MagicPedalboard/troubleshooting"/
  fi
done
echo "== Find older GUI script versions (v0.3.1–v0.3.4) =="
find "MagicPedalboard" -type f -name 'MagicDisplayGUI_New_*_v0.3.[1-4].scd' -print

echo "== Interactively delete older GUI versions (y to confirm each) =="
# Remove -i if you want non-interactive
find "MagicPedalboard" -type f -name 'MagicDisplayGUI_New_*_v0.3.[1-4].scd' -exec rm -iv {} +

# OPTIONAL: adopt Markdown as canonical docs at repo root
# Uncomment the next line if you want to delete the .txt duplicates:
# rm -iv README.txt StartHere.txt

echo "== Done =="

