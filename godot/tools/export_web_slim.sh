#!/usr/bin/env bash
# Web export with web-only texture slimming (dedupe, lossy 2D, 1024 cap). See godot/tools/web_slim.py.
# Desktop builds are NOT affected: this works on a throw-away copy of godot/, the real tree and the
# macOS/Windows presets are never touched.
#
#   bash godot/tools/export_web_slim.sh [out_dir]      # default out_dir = <repo>/web
#
# Quit the Godot editor first. Does not deploy. Env: GODOT_OVERRIDE=/path/to/Godot to pick a binary,
# KEEP_STAGE=1 to keep build/web-stage for inspection (it is always rebuilt next run anyway).
set -uo pipefail
TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$TOOLS/../.." && pwd -P)"
OUT="${1:-$ROOT/web}"
STAGE="$ROOT/build/web-stage"

GODOT="${GODOT_OVERRIDE:-}"
if [[ -z "$GODOT" ]]; then
  for c in "$HOME/Desktop/Godot.app/Contents/MacOS/Godot" /Applications/Godot.app/Contents/MacOS/Godot \
           "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
    [[ -x "$c" ]] && { GODOT="$c"; break; }
  done
fi
[[ -x "$GODOT" ]] || { echo "Godot not found, set GODOT_OVERRIDE" >&2; exit 1; }

echo "=== 1/4  Staging copy of godot/ -> $STAGE"
rm -rf "$STAGE"
mkdir -p "$STAGE"
# cp -c = APFS clone (instant, no extra disk); -p keeps mtimes so the import cache stays valid.
cp -cpR "$ROOT/godot" "$STAGE/godot" || { echo "stage copy failed" >&2; exit 1; }
rm -rf "$STAGE/godot/.godot/editor"

echo "=== 2/4  Slimming staged copy"
python3 -I "$TOOLS/web_slim.py" "$STAGE/godot" || exit 1

echo "=== 3/4  Re-import staged copy"
"$TOOLS/with_lock.sh" "$GODOT" --headless --path "$STAGE/godot" --import || { echo "import failed" >&2; exit 1; }

echo "=== 4/4  Export Web preset from staged copy -> $OUT"
mkdir -p "$OUT"
"$TOOLS/with_lock.sh" "$GODOT" --headless --path "$STAGE/godot" --export-release Web "$OUT/index.html"
rc=$?
ls -l "$OUT/index.pck" 2>/dev/null
[[ "${KEEP_STAGE:-0}" == 1 ]] || rm -rf "$STAGE"
exit $rc
