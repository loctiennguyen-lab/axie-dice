#!/usr/bin/env bash
# Chạy thử runner.sh với server giả cục bộ (stub_server.py), không mạng ngoài, không đụng Worker thật.
# Cần: Godot (GODOT_BIN), python3, curl. Mất ~20s. Exit 0 = mọi thứ đúng.
#   bash verifier/test_runner.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$HERE/.." && pwd -P)"
GODOT="${GODOT_BIN:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
T="$(mktemp -d "${TMPDIR:-/tmp}/axie-runner-test.XXXXXX")"
PORT="${PORT:-8765}"
trap 'kill "${SP:-0}" 2>/dev/null; rm -rf "$T"' EXIT
fail=0; chk() { if [ "$1" = 1 ]; then echo "  ok   $2"; else echo "FAIL $2"; fail=1; fi; }

printf 'test-key-not-a-secret' > "$T/key"; chmod 600 "$T/key"
bash "$ROOT/godot/tools/with_lock.sh" "$GODOT" --headless --path "$ROOT/godot" res://tools/record_sample_run.tscn -- \
  --seed=991237 --out="$T/sample.json" >/dev/null 2>&1
[ -s "$T/sample.json" ] || { echo "FAIL: không tạo được log mẫu"; exit 1; }
python3 -I "$HERE/stub_server.py" "$T/key" "$T/sample.json" "$T/results.json" "$PORT" >/dev/null 2>&1 &
SP=$!
sleep 1
export AXIE_VERIFY_URL="http://127.0.0.1:$PORT" AXIE_VERIFY_KEY_FILE="$T/key" GODOT_BIN="$GODOT"
bash "$HERE/runner.sh" --once >"$T/o1" 2>&1; r1=$?
bash "$HERE/runner.sh" --once >"$T/o2" 2>&1; r2=$?
AXIE_VERIFY_JOB_KILL=1 bash "$HERE/runner.sh" --once >"$T/o3" 2>&1; r3=$?
bash "$HERE/runner.sh" --once >"$T/o4" 2>&1; r4=$?
chk $([ $r1 = 0 ] && echo 1 || echo 0) "job 1 xử lý (rc=$r1)"
chk $([ $r2 = 0 ] && echo 1 || echo 0) "job 2 xử lý (rc=$r2)"
chk $([ $r3 = 0 ] && echo 1 || echo 0) "job 3 bị hang-kill vẫn xử lý (rc=$r3)"
chk $([ $r4 = 3 ] && echo 1 || echo 0) "hết job -> rc 3 (rc=$r4)"
chk $(python3 -I -c '
import json,sys
r=json.load(open(sys.argv[1]))
a=r.get("a"*32,{}); b=r.get("b"*32,{})
print(1 if a.get("ok") is True and a.get("reason")=="" and b.get("ok") is False and b.get("reason")=="header_mismatch" else 0)' "$T/results.json") \
  "job khớp -> ok; job lệch server_header -> header_mismatch"
chmod 644 "$T/key"; bash "$HERE/runner.sh" --once >/dev/null 2>&1; r5=$?
chk $([ $r5 != 0 ] && echo 1 || echo 0) "file khoá mode 644 bị từ chối"
chmod 600 "$T/key"
AXIE_VERIFY_URL=http://example.com bash "$HERE/runner.sh" --once >/dev/null 2>&1; r6=$?
chk $([ $r6 = 1 ] && echo 1 || echo 0) "URL http không phải localhost bị từ chối"
chk $(python3 -I -c 'import json,sys;c=json.load(open(sys.argv[1])).get("c"*32,{});print(1 if c.get("reason")=="timeout" and c.get("outcome")=="invalid" and c.get("ok") is False else 0)' "$T/results.json") "hang-kill -> nộp invalid/timeout"
chk $(grep -q 'test-key-not-a-secret' "$T/o1" "$T/o2" "$T/o3" && echo 0 || echo 1) "khoá không bị in ra"
[ $fail = 0 ] && echo "test_runner: PASS" || echo "test_runner: FAIL"
exit $fail
