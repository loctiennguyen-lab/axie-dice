#!/usr/bin/env bash
# SR-V: đọc thống kê verifier chạy bóng (GET /api/verify/stats, ký HMAC). Chỉ đọc.
#   bash verifier/stats.sh [n]      # n = số run lệch gần nhất (mặc định 20)
# Khoá: AXIE_VERIFY_KEY_FILE (mặc định ~/.axie-verifier/hmac_key, mode 600). Không in khoá.
set -euo pipefail
URL="${AXIE_VERIFY_URL:-https://axiedice.fun}"; URL="${URL%/}"
KEY_FILE="${AXIE_VERIFY_KEY_FILE:-$HOME/.axie-verifier/hmac_key}"
N="${1:-20}"
[[ "$N" =~ ^[0-9]+$ ]] || { echo "n phải là số"; exit 2; }
TS="$(date +%s)"
SIG="$(AXIE_KF="$KEY_FILE" TS="$TS" python3 -I -c '
import hmac, hashlib, os
key = open(os.environ["AXIE_KF"], "rb").read().strip()
msg = (os.environ["TS"] + "\nGET\n/api/verify/stats\n").encode()
print(hmac.new(key, msg, hashlib.sha256).hexdigest())')"
curl -sS --max-filesize 4M -H "X-Verify-Ts: $TS" -H "X-Verify-Sig: $SIG" "$URL/api/verify/stats?n=$N" | python3 -I -m json.tool
