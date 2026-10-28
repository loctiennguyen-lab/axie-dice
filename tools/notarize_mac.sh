#!/usr/bin/env bash
# Ký (Developer ID + hardened runtime), notarize, staple và kiểm AxieDice.app. KHÔNG upload, KHÔNG deploy.
#
# Usage:
#   bash tools/notarize_mac.sh --dry-run [--app <AxieDice.app>]   # chỉ kiểm điều kiện, không ký gì
#   bash tools/notarize_mac.sh --app <AxieDice.app>               # ký + notarize + staple tại chỗ
#   bash tools/notarize_mac.sh --dry-run --check-profile          # thêm: hỏi Apple xem profile dùng được (cần mạng)
#
# Env:
#   AXIE_SIGN_IDENTITY   tên identity, vd "Developer ID Application: Sky Mavis (ABCDE12345)".
#                        Bỏ trống thì tự lấy nếu keychain chỉ có ĐÚNG MỘT identity Developer ID Application.
#   AXIE_NOTARY_PROFILE  tên keychain profile của notarytool (mặc định: axie-notary), tạo một lần bằng
#                        `xcrun notarytool store-credentials` (xem production/release/signing-setup.md).
#   AXIE_ENTITLEMENTS    file entitlements (mặc định: tools/signing/macos.entitlements)
#
# Bí mật: script không đọc, không in, không nhận mật khẩu hay app-specific password. Apple ID và mật khẩu chỉ
# nằm trong keychain profile do notarytool giữ. Private key của cert nằm trong keychain, codesign tự gọi.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${AXIE_NOTARY_PROFILE:-axie-notary}"
ENTITLEMENTS="${AXIE_ENTITLEMENTS:-$ROOT/tools/signing/macos.entitlements}"
IDENTITY="${AXIE_SIGN_IDENTITY:-}"
APP=""; DRY=0; CHECK_PROFILE=0

die() { echo "notarize_mac: $*" >&2; exit 1; }

while (( $# )); do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --check-profile) CHECK_PROFILE=1; shift ;;
    --app) [[ -n "${2:-}" ]] || die "--app cần đường dẫn"; APP="$2"; shift 2 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) die "tham số lạ: $1 (usage: notarize_mac.sh [--dry-run] [--check-profile] --app <AxieDice.app>)" ;;
  esac
done

MISSING=0
ok()   { echo "   ok       $*"; }
miss() { echo "   THIẾU    $*" >&2; MISSING=$((MISSING+1)); }

echo "== notarize_mac ($([[ $DRY -eq 1 ]] && echo dry-run || echo that))"

# --- 1. công cụ ---------------------------------------------------------------------------------
for t in codesign xcrun ditto spctl security lipo; do
  command -v "$t" >/dev/null 2>&1 && ok "công cụ $t" || miss "công cụ $t (cài Xcode Command Line Tools: xcode-select --install)"
done
xcrun --find notarytool >/dev/null 2>&1 && ok "xcrun notarytool" || miss "xcrun notarytool (cần Xcode 13+ / Command Line Tools mới)"
xcrun --find stapler    >/dev/null 2>&1 && ok "xcrun stapler"    || miss "xcrun stapler"

# --- 2. entitlements ----------------------------------------------------------------------------
if [[ -f "$ENTITLEMENTS" ]]; then
  plutil -lint "$ENTITLEMENTS" >/dev/null 2>&1 && ok "entitlements $ENTITLEMENTS" || miss "entitlements không hợp lệ (plutil -lint): $ENTITLEMENTS"
else
  miss "không thấy entitlements: $ENTITLEMENTS"
fi

# --- 3. identity Developer ID Application -------------------------------------------------------
IDS="$(security find-identity -v -p codesigning 2>/dev/null | grep 'Developer ID Application' || true)"
NIDS=$(printf '%s' "$IDS" | grep -c . || true)
if [[ -n "$IDENTITY" ]]; then
  if printf '%s' "$IDS" | grep -qF "$IDENTITY"; then ok "identity: $IDENTITY"
  else miss "identity '$IDENTITY' không có trong keychain (security find-identity -v -p codesigning)"; fi
elif [[ "$NIDS" -eq 1 ]]; then
  IDENTITY="$(printf '%s' "$IDS" | sed -E 's/^[^"]*"([^"]+)".*/\1/')"
  ok "identity (tự lấy, chỉ có một): $IDENTITY"
elif [[ "$NIDS" -gt 1 ]]; then
  miss "có $NIDS identity Developer ID Application, đặt AXIE_SIGN_IDENTITY để chọn một"
else
  miss "chưa có cert 'Developer ID Application' trong keychain (xem signing-setup.md mục 2)"
fi

# --- 4. keychain profile của notarytool ---------------------------------------------------------
if [[ $CHECK_PROFILE -eq 1 ]]; then
  # `history` chỉ liệt kê các lần submit, không in bí mật. Cần mạng.
  xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 \
    && ok "keychain profile '$PROFILE' dùng được (Apple trả lời)" \
    || miss "keychain profile '$PROFILE' không dùng được (chưa tạo, sai, hoặc mất mạng). Tạo: signing-setup.md mục 3"
else
  echo "   bỏ qua   kiểm profile '$PROFILE' (thêm --check-profile để hỏi Apple, cần mạng)"
fi

# --- 5. app -------------------------------------------------------------------------------------
if [[ -n "$APP" ]]; then
  if [[ -d "$APP/Contents/MacOS" ]]; then
    ok "app: $APP (archs: $(lipo -archs "$APP"/Contents/MacOS/* 2>/dev/null | tr '\n' ' '))"
  else
    miss "không phải .app hợp lệ: $APP"
  fi
elif [[ $DRY -eq 0 ]]; then
  die "thiếu --app <AxieDice.app>"
else
  echo "   bỏ qua   kiểm app (không truyền --app)"
fi

if [[ $DRY -eq 1 ]]; then
  if [[ $MISSING -eq 0 ]]; then echo "== dry-run: đủ điều kiện. Không ký gì."; exit 0
  else echo "== dry-run: còn $MISSING điều kiện thiếu. Không ký gì." >&2; exit 1; fi
fi
[[ $MISSING -eq 0 ]] || die "còn $MISSING điều kiện thiếu, dừng (chạy --dry-run để xem)"

# --- 6. ký (trong ra ngoài, không dùng --deep) --------------------------------------------------
WORK="$(mktemp -d "${TMPDIR:-/tmp}/axie-notarize.XXXXXX")" || die "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SIGN=(codesign --force --timestamp --options runtime --sign "$IDENTITY")

echo "-- ký code lồng bên trong (Frameworks, dylib, binary phụ)"
MAIN_COUNT=0
while IFS= read -r -d '' f; do
  file -b "$f" | grep -q "Mach-O" || continue
  [[ "$f" == "$APP/Contents/MacOS/"* ]] && { MAIN_COUNT=$((MAIN_COUNT+1)); continue; }   # file chạy chính: ký cùng bundle ở dưới
  echo "   $f"
  "${SIGN[@]}" "$f" || die "ký thất bại: $f"
done < <(find "$APP/Contents" -type f -print0)

echo "-- ký bundle (hardened runtime + entitlements)"
"${SIGN[@]}" --entitlements "$ENTITLEMENTS" "$APP" || die "ký bundle thất bại"
codesign --verify --deep --strict --verbose=2 "$APP" 2>"$WORK/verify.log" \
  || { cat "$WORK/verify.log" >&2; die "codesign verify thất bại sau khi ký"; }
codesign -dv "$APP" 2>&1 | grep -q "flags=.*runtime" || die "bundle không có cờ hardened runtime"
echo "   codesign verify: ok (Developer ID, hardened runtime)"

# --- 7. notarize --------------------------------------------------------------------------------
SUBMIT_ZIP="$WORK/AxieDice-notarize.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$SUBMIT_ZIP" || die "ditto zip thất bại"
echo "-- gửi Apple notarize (có thể mất vài phút đến vài chục phút), profile: $PROFILE"
if ! xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$PROFILE" --wait > "$WORK/submit.log" 2>&1; then
  cat "$WORK/submit.log" >&2
  die "notarytool submit thất bại"
fi
cat "$WORK/submit.log"
grep -q "status: Accepted" "$WORK/submit.log" || {
  SID="$(grep -m1 -E '^ *id: ' "$WORK/submit.log" | sed -E 's/^ *id: *//')"
  [[ -n "$SID" ]] && echo "   xem lý do: xcrun notarytool log $SID --keychain-profile $PROFILE" >&2
  die "Apple không Accept"
}

# --- 8. staple + kiểm ---------------------------------------------------------------------------
echo "-- staple"
xcrun stapler staple "$APP" || die "stapler staple thất bại"
xcrun stapler validate "$APP" || die "stapler validate thất bại"
echo "-- spctl (Gatekeeper)"
spctl -a -vv -t exec "$APP" 2>&1 | tee "$WORK/spctl.log"
grep -q "source=Notarized Developer ID" "$WORK/spctl.log" || die "spctl không báo 'Notarized Developer ID'"
echo "== xong: $APP đã ký + notarize + staple. Zip/dmg phải làm LẠI từ app này (build_desktop.sh làm sẵn)."
