#!/usr/bin/env bash
# Web export with web-only texture slimming (dedupe, lossy 2D, 1024 cap). See godot/tools/web_slim.py.
# Desktop builds are NOT affected: this works on a throw-away copy of godot/, the real tree and the
# macOS/Windows presets are never touched.
#
#   bash godot/tools/export_web_slim.sh [--keep-stage] [out_dir]   # default out_dir = <repo>/web
#
# Quit the Godot editor first. Does not deploy. Env: GODOT_OVERRIDE=/path/to/Godot picks a binary.
# build/web-stage is removed on every exit path; --keep-stage keeps it for inspection.
# The stage always runs with its own user dir (AxieDice-web-stage), never the real "Axie Dice" one
# (that dir holds Liam's desktop save and sign-in).
set -uo pipefail
TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$TOOLS/../.." && pwd -P)"
REAL_GODOT="$ROOT/godot"
STAGE="$ROOT/build/web-stage"
STAGE_GODOT="$STAGE/godot"
STAGE_USERDIR_NAME="AxieDice-web-stage"
MARKER=".web_stage_marker"
KEEP=0
OUT=""
for a in "$@"; do
  case "$a" in
    --keep-stage) KEEP=1 ;;
    -*) echo "unknown flag: $a" >&2; exit 64 ;;
    *) OUT="$a" ;;
  esac
done
OUT="${OUT:-$ROOT/web}"

# Every exit path (success, failure, INT/TERM/HUP) goes through here.
_cleanup() {
  if [[ "$KEEP" == 0 ]]; then rm -rf "$STAGE"; fi
}
trap _cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

GODOT="${GODOT_OVERRIDE:-}"
if [[ -z "$GODOT" ]]; then
  for c in "$HOME/Desktop/Godot.app/Contents/MacOS/Godot" /Applications/Godot.app/Contents/MacOS/Godot \
           "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
    [[ -x "$c" ]] && { GODOT="$c"; break; }
  done
fi
[[ -x "$GODOT" ]] || { echo "Godot not found, set GODOT_OVERRIDE" >&2; exit 1; }

echo "=== 1/5  Staging copy of godot/ -> $STAGE_GODOT"
rm -rf "$STAGE"
mkdir -p "$STAGE"
# cp -c = APFS clone (instant, no extra disk); -p keeps mtimes so the import cache stays valid.
cp -cpR "$REAL_GODOT" "$STAGE_GODOT" || { echo "stage copy failed" >&2; exit 1; }
rm -rf "$STAGE_GODOT/.godot/editor"
# The copy may carry the worktree's own override.cfg, or none. The stage always gets this one.
cat > "$STAGE_GODOT/override.cfg" <<EOF
; Written by godot/tools/export_web_slim.sh. Keeps the stage off the real user dir.
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="$STAGE_USERDIR_NAME"
EOF
printf 'web-stage %s\n' "$STAGE_GODOT" > "$STAGE_GODOT/$MARKER"

# Refuse to run Godot if the stage would use a real user dir. userdir.sh is the same resolver
# with_lock.sh uses, so this checks the dir Godot will actually open.
# shellcheck source=userdir.sh
source "$TOOLS/userdir.sh"
NAME="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$REAL_GODOT/project.godot" | head -1)"
[[ -n "$NAME" ]] || { echo "config/name not found in project.godot" >&2; exit 1; }
REAL_USERDIR="$HOME/Library/Application Support/Godot/app_userdata/$NAME"
axie_resolve_userdir "$STAGE_GODOT" || { echo "cannot resolve the stage user dir" >&2; exit 1; }
STAGE_USERDIR="$AXIE_USERDIR"
axie_resolve_userdir "$REAL_GODOT" || true
REAL_TREE_USERDIR="${AXIE_USERDIR:-}"
if [[ -z "$STAGE_USERDIR" || "$STAGE_USERDIR" == "$REAL_USERDIR" || "$STAGE_USERDIR" == "$REAL_TREE_USERDIR" ]]; then
  echo "REFUSING: stage user dir [$STAGE_USERDIR] is a real one [$REAL_USERDIR | $REAL_TREE_USERDIR]" >&2
  exit 1
fi
echo "stage user dir: $STAGE_USERDIR"

echo "=== 2/5  Slimming staged copy"
python3 -I "$TOOLS/web_slim.py" "$STAGE_GODOT" || exit 1

# with_lock.sh is taken from the STAGE so it resolves the stage's own user dir and lock.
STAGE_LOCK="$STAGE_GODOT/tools/with_lock.sh"

echo "=== 3/5  Re-import staged copy"
AXIE_HANG_KILL=300 bash "$STAGE_LOCK" "$GODOT" --headless --path "$STAGE_GODOT" --import \
  || { echo "import failed" >&2; exit 1; }

echo "=== 4/5  Export Web preset from staged copy -> $OUT"
mkdir -p "$OUT"
rm -f "$OUT/index.pck"   # so a stale pck can never pass the size check below
AXIE_HANG_KILL=900 bash "$STAGE_LOCK" "$GODOT" --headless --path "$STAGE_GODOT" --export-release Web "$OUT/index.html"
rc=$?
if [[ $rc -ne 0 ]]; then echo "godot exit code: $rc" >&2; exit $rc; fi

echo "=== 5/5  Checking index.pck"
PCK="$OUT/index.pck"
if [[ ! -f "$PCK" ]]; then echo "FAILED: $PCK was not written. Read the Godot output above." >&2; exit 1; fi
ls -lh "$PCK"
# Same threshold as export-web.sh (100 MB, du -sm). It is applied here to index.pck alone.
PCK_MB=$(du -sm "$PCK" | cut -f1)
echo "index.pck: ${PCK_MB} MB"
if [[ "$PCK_MB" -lt 100 ]]; then
  echo "TOO SMALL: index.pck under 100 MB, the Axie asset pack did not make it into the pck. Do not deploy." >&2
  exit 1
fi
echo "Looks right."
