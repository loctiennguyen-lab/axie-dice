#!/usr/bin/env bash
# SR-V shadow runner (Liam's Mac, macOS + Linux). Kéo job từ Worker -> replay bằng Godot headless -> nộp kết quả.
# Chỉ GHI NHẬN, không đổi điểm / thưởng / bảng xếp hạng.
#
#   bash verifier/runner.sh           # vòng lặp, Ctrl-C hoặc kill để dừng
#   bash verifier/runner.sh --once    # hỏi đúng 1 lần; exit 0 = đã xử lý 1 job, 3 = không có job, khác = lỗi
#
# Env (đều tuỳ chọn):
#   AXIE_VERIFY_URL        mặc định https://axiedice.fun
#   AXIE_VERIFY_KEY_FILE   mặc định ~/.axie-verifier/hmac_key (PHẢI mode 600, nằm ngoài repo)
#   GODOT_BIN              mặc định /Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot
#   AXIE_VERIFY_ROOT       thư mục repo (có godot/). Mặc định: repo chứa file này
#   AXIE_VERIFY_POLL       giây nghỉ khi không có job / lỗi mạng (mặc định 15)
#   AXIE_VERIFY_JOB_KILL   giây tối đa cho 1 lần replay (mặc định 120, quá thì diệt cả cây tiến trình)
#
# An toàn:
#  - Khoá HMAC đọc từ file, không bao giờ in ra, không đưa vào argv (ps thấy được) hay env.
#  - Godot chạy qua godot/tools/with_lock.sh: user dir cô lập (override.cfg của worktree, hoặc override.cfg tạm
#    AxieDice-test-<repo> ở cây chính), tự chụp/trả save, hang-kill. KHÔNG đụng save thật.
#  - Godot không bị chặn mạng được trên macOS (xem verifier/README.md). Verifier không có code gọi mạng.
set -uo pipefail

ONCE=0
[ "${1:-}" = "--once" ] && ONCE=1

URL="${AXIE_VERIFY_URL:-https://axiedice.fun}"; URL="${URL%/}"
KEY_FILE="${AXIE_VERIFY_KEY_FILE:-$HOME/.axie-verifier/hmac_key}"
GODOT="${GODOT_BIN:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
ROOT="${AXIE_VERIFY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
POLL="${AXIE_VERIFY_POLL:-15}"
JOB_KILL="${AXIE_VERIFY_JOB_KILL:-120}"

log() { printf '%s runner: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

command -v curl >/dev/null || die "cần curl"
command -v python3 >/dev/null || die "cần python3"
[ -x "$GODOT" ] || die "không thấy Godot ở $GODOT (đặt GODOT_BIN)"
[ -f "$ROOT/godot/tools/with_lock.sh" ] || die "không thấy godot/tools/with_lock.sh trong $ROOT"
[ -f "$KEY_FILE" ] || die "không thấy file khoá $KEY_FILE"
MODE="$(stat -c %a "$KEY_FILE" 2>/dev/null || stat -f %Lp "$KEY_FILE" 2>/dev/null || echo '?')"
[ "$MODE" = "600" ] || die "file khoá phải mode 600 (đang là $MODE): chmod 600 '$KEY_FILE'"
case "$KEY_FILE" in "$ROOT"/*) die "file khoá không được nằm trong repo";; esac

W="$(mktemp -d "${TMPDIR:-/tmp}/axie-verifier.XXXXXX")"
trap 'rm -rf "$W"; exit' EXIT INT TERM HUP

# hex HMAC-SHA256(key, "ts\nMETHOD\npath\nbody"); body qua stdin, khoá đọc trong python.
sign() { # ts method path  (body on stdin)
  python3 -I -c '
import sys, hmac, hashlib, os
key = open(os.environ["AXIE_KF"], "rb").read().strip()
body = sys.stdin.buffer.read()
msg = ("%s\n%s\n%s\n" % (sys.argv[1], sys.argv[2], sys.argv[3])).encode() + body
print(hmac.new(key, msg, hashlib.sha256).hexdigest())' "$1" "$2" "$3"
}
export AXIE_KF="$KEY_FILE"

# post <path> <body-file> <out-file>; in ra mã HTTP (000 nếu lỗi mạng)
post() {
  local path="$1" bodyf="$2" outf="$3" ts sig
  ts="$(date +%s)"
  sig="$(sign "$ts" POST "$path" < "$bodyf")" || { echo 000; return; }
  curl -sS --max-time 30 -o "$outf" -w '%{http_code}' -X POST "$URL$path" \
    -H "X-Verify-Ts: $ts" -H "X-Verify-Sig: $sig" -H 'Content-Type: application/json' \
    --data-binary "@$bodyf" 2>>"$W/curl.err"
}

# Trả 0 = đã xử lý một job, 3 = không có job, 1 = lỗi (mạng / Worker)
one_round() {
  rm -f "$W/next.json" "$W/in.json" "$W/out.json" "$W/res.json" "$W/reply.json" "$W/curl.err"
  printf '{}' > "$W/req.json"
  local code; code="$(post /api/verify/next "$W/req.json" "$W/next.json")"
  if [ "$code" != "200" ]; then log "next -> HTTP $code $(head -c 200 "$W/curl.err" 2>/dev/null)"; return 1; fi
  local run_id
  run_id="$(python3 -I -c '
import json, re, sys
try:
    j = json.load(open(sys.argv[1])).get("job")
except Exception:
    j = None
if not j:
    sys.exit(0)
rid = j.get("run_id", "")
if not re.fullmatch(r"[a-f0-9]{32}", rid or ""):
    sys.exit(0)
json.dump(j["payload"], open(sys.argv[2], "w"))
print(rid)' "$W/next.json" "$W/in.json")"
  [ -n "$run_id" ] || return 3

  log "job $run_id"
  AXIE_HANG_KILL="$JOB_KILL" bash "$ROOT/godot/tools/with_lock.sh" "$GODOT" --headless --path "$ROOT/godot" \
    res://tools/verify_run.tscn -- --in="$W/in.json" --out="$W/out.json" >"$W/godot.log" 2>&1
  local gc=$?

  # Kết quả phải đúng 8 khoá (Worker cũng kiểm lại). Không có kết quả -> không nộp, lease hết hạn thì job được kéo lại.
  if ! python3 -I -c '
import json, sys
r = json.load(open(sys.argv[2]))
keys = ["ok","reason","rules_version","outcome","score","nodes","log_len","ms"]
assert isinstance(r, dict) and sorted(r) == sorted(keys)
json.dump({"run_id": sys.argv[1], "result": r}, open(sys.argv[3], "w"))' "$run_id" "$W/out.json" "$W/res.json" 2>/dev/null; then
    log "job $run_id: Godot exit $gc, không có kết quả hợp lệ (không nộp). Cuối log Godot:"
    tail -n 5 "$W/godot.log" | sed 's/^/    /'
    return 0
  fi
  code="$(post /api/verify/result "$W/res.json" "$W/reply.json")"
  log "job $run_id: godot exit $gc, nộp -> HTTP $code $(head -c 120 "$W/reply.json" 2>/dev/null)"
  return 0
}

log "bắt đầu: $URL (Godot: $GODOT)"
while true; do
  one_round; rc=$?
  if [ "$ONCE" = 1 ]; then exit "$rc"; fi
  [ "$rc" = 0 ] && continue   # còn job thì kéo tiếp luôn
  sleep "$POLL" & wait $!
done
