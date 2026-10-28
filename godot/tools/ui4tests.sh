#!/usr/bin/env bash
# ui4tests.sh <glob-prefix>... : run the matching tests/t_*.tscn headless, print PASS/FAIL per test.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
G=/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot
for pat in "$@"; do
  for f in "$ROOT"/godot/tests/${pat}*.tscn; do
    n=$(basename "$f" .tscn)
    out=$(AXIE_TEST_NO_NET=1 AXIE_SKIP_RULES_FINGERPRINT=1 AXIE_HANG_KILL=240 bash "$ROOT/godot/tools/with_lock.sh" "$G" --headless --path "$ROOT/godot" "res://tests/$n.tscn" 2>&1)
    rc=$?
    bad=$(echo "$out" | grep -cE "SCRIPT ERROR|Parse Error|FAIL")
    echo "$n rc=$rc bad=$bad $(echo "$out" | grep -E "PASS|passed|checks" | tail -1)"
    [ "$bad" != "0" ] && echo "$out" | grep -E "SCRIPT ERROR|Parse Error|FAIL" | head -8
  done
done
