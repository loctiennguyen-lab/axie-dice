#!/usr/bin/env bash
# Ký Authenticode cho AxieDice.exe bằng osslsigncode (chạy được trên Mac). KHÔNG upload. SKELETON: chưa thử
# với cert thật (chưa có cert), chỉ dry-run đã được kiểm.
#
# Usage:
#   bash tools/sign_windows.sh --dry-run [<AxieDice.exe>]   # chỉ kiểm điều kiện
#   bash tools/sign_windows.sh <AxieDice.exe>               # ký tại chỗ (giữ bản gốc .unsigned cạnh file)
#
# Hai kiểu cert (chọn bằng env, xem production/release/signing-setup.md mục 5):
#   A) file .pfx:   AXIE_WIN_CERT=/đường/dẫn/cert.pfx   (ngoài repo, không commit)
#                   mật khẩu: env AXIE_WIN_CERT_PASSWORD, hoặc keychain macOS:
#                   security add-generic-password -a "$USER" -s axie-win-cert -w   (nhập mật khẩu khi hỏi)
#   B) token/HSM qua PKCS#11 (cert EV/OV mới thường bắt buộc kiểu này): UNTESTED
#                   AXIE_WIN_PKCS11_MODULE=/đường/dẫn/libxxx.dylib  AXIE_WIN_PKCS11_CERTS=chain.pem
#                   AXIE_WIN_PKCS11_KEY='pkcs11:...'  PIN: AXIE_WIN_CERT_PASSWORD hoặc keychain như trên
# Chung:
#   AXIE_WIN_TIMESTAMP_URL  (mặc định http://timestamp.digicert.com)
#   AXIE_WIN_NAME           tên hiển thị trong hộp thoại UAC (mặc định "Axie Dice")
#
# Bí mật: mật khẩu không bao giờ nằm trên dòng lệnh (không lộ qua `ps`), không bị in ra. Đưa cho osslsigncode
# qua -readpass trên một đường ống (file descriptor), không ghi ra đĩa.
set -uo pipefail

TS_URL="${AXIE_WIN_TIMESTAMP_URL:-http://timestamp.digicert.com}"
NAME="${AXIE_WIN_NAME:-Axie Dice}"
KC_SERVICE="axie-win-cert"
EXE=""; DRY=0

die() { echo "sign_windows: $*" >&2; exit 1; }

while (( $# )); do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) die "tham số lạ: $1" ;;
    *) [[ -z "$EXE" ]] || die "chỉ nhận một file .exe"; EXE="$1"; shift ;;
  esac
done

MISSING=0
ok()   { echo "   ok       $*"; }
miss() { echo "   THIẾU    $*" >&2; MISSING=$((MISSING+1)); }

echo "== sign_windows ($([[ $DRY -eq 1 ]] && echo dry-run || echo that))"

command -v osslsigncode >/dev/null 2>&1 && ok "osslsigncode ($(osslsigncode --version 2>&1 | head -1))" \
  || miss "osslsigncode (brew install osslsigncode)"

# Mật khẩu: chỉ kiểm CÓ hay không, không đọc ra màn hình.
have_password() {
  [[ -n "${AXIE_WIN_CERT_PASSWORD:-}" ]] && return 0
  security find-generic-password -s "$KC_SERVICE" >/dev/null 2>&1   # không có -w: không in mật khẩu
}
get_password() {   # in mật khẩu ra stdout, chỉ dùng trong ống nội bộ
  if [[ -n "${AXIE_WIN_CERT_PASSWORD:-}" ]]; then printf '%s' "$AXIE_WIN_CERT_PASSWORD"
  else security find-generic-password -s "$KC_SERVICE" -w 2>/dev/null; fi
}

MODE=""
if [[ -n "${AXIE_WIN_CERT:-}" ]]; then
  MODE=pfx
  [[ -f "$AXIE_WIN_CERT" ]] && ok "cert pfx: $AXIE_WIN_CERT" || miss "AXIE_WIN_CERT không phải file: $AXIE_WIN_CERT"
  case "$AXIE_WIN_CERT" in "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"/*) miss "cert nằm TRONG repo, dời ra ngoài (không được commit)";; esac
elif [[ -n "${AXIE_WIN_PKCS11_MODULE:-}" ]]; then
  MODE=pkcs11
  [[ -f "$AXIE_WIN_PKCS11_MODULE" ]] && ok "pkcs11 module: $AXIE_WIN_PKCS11_MODULE" || miss "không thấy AXIE_WIN_PKCS11_MODULE: $AXIE_WIN_PKCS11_MODULE"
  [[ -n "${AXIE_WIN_PKCS11_CERTS:-}" && -f "${AXIE_WIN_PKCS11_CERTS:-}" ]] && ok "chain: $AXIE_WIN_PKCS11_CERTS" || miss "AXIE_WIN_PKCS11_CERTS (file chain .pem) thiếu"
  [[ -n "${AXIE_WIN_PKCS11_KEY:-}" ]] && ok "pkcs11 key uri đã đặt" || miss "AXIE_WIN_PKCS11_KEY thiếu"
else
  miss "chưa chọn cert: đặt AXIE_WIN_CERT (pfx) hoặc AXIE_WIN_PKCS11_MODULE (token)"
fi
if [[ -n "$MODE" ]]; then
  have_password && ok "mật khẩu/PIN có (env hoặc keychain '$KC_SERVICE'), không in ra" || miss "mật khẩu/PIN: đặt AXIE_WIN_CERT_PASSWORD hoặc keychain '$KC_SERVICE'"
fi
ok "timestamp server: $TS_URL"

if [[ -n "$EXE" ]]; then
  if [[ -f "$EXE" ]]; then
    file "$EXE" | grep -q "PE32+" && ok "exe: $EXE (PE32+)" || miss "không phải PE32+: $EXE"
  else miss "không thấy exe: $EXE"; fi
elif [[ $DRY -eq 0 ]]; then die "thiếu <AxieDice.exe>"
else echo "   bỏ qua   kiểm exe (không truyền đường dẫn)"; fi

if [[ $DRY -eq 1 ]]; then
  if [[ $MISSING -eq 0 ]]; then echo "== dry-run: đủ điều kiện. Không ký gì."; exit 0
  else echo "== dry-run: còn $MISSING điều kiện thiếu. Không ký gì." >&2; exit 1; fi
fi
[[ $MISSING -eq 0 ]] || die "còn $MISSING điều kiện thiếu, dừng (chạy --dry-run để xem)"

OUT="$EXE.signing.tmp"
rm -f "$OUT"
COMMON=(-h sha256 -n "$NAME" -ts "$TS_URL" -in "$EXE" -out "$OUT")
if [[ "$MODE" == pfx ]]; then
  osslsigncode sign -pkcs12 "$AXIE_WIN_CERT" -readpass <(get_password) "${COMMON[@]}" || { rm -f "$OUT"; die "osslsigncode sign thất bại"; }
else
  osslsigncode sign -pkcs11module "$AXIE_WIN_PKCS11_MODULE" -certs "$AXIE_WIN_PKCS11_CERTS" -key "$AXIE_WIN_PKCS11_KEY" \
    -readpass <(get_password) "${COMMON[@]}" || { rm -f "$OUT"; die "osslsigncode sign (pkcs11) thất bại"; }
fi
# Kiểm chữ ký còn đủ và có timestamp trước khi thay file. (-CAfile hệ thống có thể cần cho verify: nếu chỉ báo
# lỗi chuỗi tin cậy trên Mac thì chữ ký vẫn đúng, kiểm thật trên Windows.)
osslsigncode verify -in "$OUT" 2>&1 | tail -n 12
mv "$EXE" "$EXE.unsigned" && mv "$OUT" "$EXE" || die "không thay được file"
echo "== xong: $EXE đã ký (bản gốc: $EXE.unsigned, xoá trước khi zip). PHẢI thử mở bản đã ký trên máy Windows thật."
