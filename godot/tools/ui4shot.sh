#!/usr/bin/env bash
# ui4shot.sh <screen> -> production/qa/evidence/ui4-meta/<screen>-1920.png and -1280.png
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
G=/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot
OUT="$ROOT/production/qa/evidence/ui4-meta"
mkdir -p "$OUT"
for r in 1920x1080:1920 1280x720:1280; do
  AXIE_TEST_NO_NET=1 AXIE_HANG_KILL=120 bash "$ROOT/godot/tools/with_lock.sh" "$G" --path "$ROOT/godot" \
    --resolution "${r%%:*}" --position 0,0 res://tests/qa_ui4_meta_capture.tscn -- --screen="$1" --out="$OUT/$1-${r##*:}.png" 2>&1 | grep -E "UI4_CAPTURE|ERROR|SCRIPT"
done
