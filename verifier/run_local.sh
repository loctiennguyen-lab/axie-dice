#!/usr/bin/env bash
# Runner bóng trên máy riêng (V2) hoặc máy dev: kéo MỘT job -> chạy CLI verifier -> nộp kết quả. Gọi lại (cron/loop) để kéo tiếp.
# DỰ THẢO: chưa chạy với Worker thật. Cần: curl, openssl, python3 (chỉ để đọc/ghi JSON), Godot hoặc docker.
#   VERIFY_URL       vd https://axiedice.fun   (bắt buộc)
#   VERIFY_HMAC_KEY  khoá ký, đặt qua env của máy runner, KHÔNG ghi vào file/repo (bắt buộc)
#   VERIFY_RUNNER    lệnh chạy verifier, nhận 2 đối số: <in.json> <out.json>. Mặc định: Godot cục bộ.
#                    Để chạy không mạng: VERIFY_RUNNER='docker run --rm --network none ...' (xem README)
# Exit: 0 đã xử lý một job, 3 không có job, khác 0 lỗi.
set -euo pipefail
: "${VERIFY_URL:?}" "${VERIFY_HMAC_KEY:?}"
GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# Chữ ký: hex HMAC-SHA256(key, "ts\nPOST\npath\nbody")
post() { # path body
  local ts sig; ts=$(date +%s)
  sig=$(printf '%s\nPOST\n%s\n%s' "$ts" "$1" "$2" | openssl dgst -sha256 -hmac "$VERIFY_HMAC_KEY" -hex | sed 's/^.* //')
  curl -fsS -X POST "$VERIFY_URL$1" -H "x-verify-ts: $ts" -H "x-verify-sig: $sig" -H 'content-type: application/json' --data-binary "$2"
}

post /api/verify/next '{}' > "$W/job.json"
RUN_ID=$(python3 -I -c 'import json,sys;j=json.load(open(sys.argv[1]))["job"];print(j["run_id"] if j else "")' "$W/job.json")
[ -n "$RUN_ID" ] || { echo "no job"; exit 3; }
python3 -I -c 'import json,sys;json.dump(json.load(open(sys.argv[1]))["job"]["payload"],open(sys.argv[2],"w"))' "$W/job.json" "$W/in.json"

if [ -n "${VERIFY_RUNNER:-}" ]; then $VERIFY_RUNNER "$W/in.json" "$W/out.json" || true
else bash "$ROOT/godot/tools/with_lock.sh" "$GODOT" --headless --path "$ROOT/godot" res://tools/verify_run.tscn -- --in="$W/in.json" --out="$W/out.json" >/dev/null || true; fi

BODY=$(python3 -I -c 'import json,sys;print(json.dumps({"run_id":sys.argv[1],"result":json.load(open(sys.argv[2]))}))' "$RUN_ID" "$W/out.json")
post /api/verify/result "$BODY"; echo
