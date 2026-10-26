#!/usr/bin/env bash
# Chuẩn bị đăng bản desktop lên R2 cho trang /download. KHÔNG upload, KHÔNG gọi wrangler.
#
# Usage:
#   bash tools/publish_desktop.sh <tên gói trong build/> [--prev <latest.json cũ>] [--allow-dirty]
#   bash tools/publish_desktop.sh AxieDice-0.1.0-L1-b1639-5ecc08f --prev build/old/latest.json
#
# Làm gì:
#   1. Kiểm hai zip build/<gói>-{macos,windows}.zip có mặt, cỡ < 300 MiB, tên gói đúng dạng.
#   2. Kiểm gói được build từ ĐÚNG commit HEAD (luôn kiểm, kể cả --allow-dirty).
#      --allow-dirty chỉ bỏ kiểm cờ -dirty trong tên (cây làm việc có sửa), không bỏ kiểm commit.
#   3. Tính sha256 và cỡ (không tin file .sha256 cũ), ghi build/publish/latest.json.
#   4. In kế hoạch lệnh wrangler cho làn I, dạng script có `set -e` để dán vào shell và dừng ở lỗi
#      đầu tiên. Thứ tự: lấy latest.json đang TRÊN R2 -> so với --prev (khác thì dừng) -> lưu file cũ
#      vào downloads/old/ và kiểm sha -> up zip mới -> up latest.json CUỐI -> xoá file cũ ở gốc
#      downloads/. Trang không bao giờ trỏ vào file chưa có.
#   5. Không có --prev: in cảnh báo "không có đường rollback desktop" và bỏ bước lưu bản cũ.
#
# Lưu ý:
#   - R2 không có lệnh đổi tên. "Dời bản cũ sang downloads/old/" là tải về rồi up lại (tốn băng thông
#     ~ cỡ hai zip). Rollback desktop chỉ có khi đã chạy đợt này với --prev.
#   - Chỉ đăng macOS .zip và Windows .zip. .dmg không đăng.
#   - Gói chưa ký số (macOS ad-hoc, Windows unsigned). sha256 trên trang cùng nguồn với file: chỉ chống
#     hỏng tải, không chống bị thay.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
OUT_DIR="$ROOT/build"
PUB_DIR="$OUT_DIR/publish"
BUCKET="${BUCKET:-axie-dice}"
WRANGLER="npx --yes wrangler@4.151.3"   # ghim: cùng bản đã dùng ở deploy 23/10. Đổi cả ở deploy-r2.sh.
MAX_BYTES=$((300 * 1024 * 1024))

die() { echo "publish_desktop: $*" >&2; exit 1; }

STAMP=""; PREV=""; ALLOW_DIRTY=0
while (( $# )); do
  case "$1" in
    --prev) [[ -n "${2:-}" ]] || die "--prev cần đường dẫn"; PREV="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    -*) die "tham số lạ: $1 (usage: publish_desktop.sh <gói> [--prev f] [--allow-dirty])" ;;
    *) [[ -z "$STAMP" ]] || die "chỉ nhận một tên gói"; STAMP="$1"; shift ;;
  esac
done
[[ -n "$STAMP" ]] || die "thiếu tên gói (ví dụ AxieDice-0.1.0-L1-b1639-5ecc08f)"
[[ "$STAMP" =~ ^[A-Za-z0-9._-]+$ ]] || die "tên gói chỉ được [A-Za-z0-9._-]: $STAMP"
if [[ -n "$PREV" ]]; then
  [[ -f "$PREV" ]] || die "--prev không tìm thấy: $PREV"
  python3 -I -c 'import json,sys; m=json.load(open(sys.argv[1],encoding="utf-8")); assert {"macos","windows"} <= set(m["platforms"])' "$PREV" \
    || die "--prev không phải latest.json hợp lệ: $PREV"
fi

MAC_ZIP="$OUT_DIR/${STAMP}-macos.zip"
WIN_ZIP="$OUT_DIR/${STAMP}-windows.zip"
[[ -f "$MAC_ZIP" ]] || die "thiếu $MAC_ZIP (chạy tools/build_desktop.sh trước)"
[[ -f "$WIN_ZIP" ]] || die "thiếu $WIN_ZIP"
if [[ "$STAMP" == *-dirty* && $ALLOW_DIRTY -ne 1 ]]; then
  die "gói có -dirty (cây làm việc có sửa godot/ hoặc tools/). Build lại từ cây sạch. --allow-dirty chỉ để thử"
fi

# Commit: luôn kiểm, so với commit đầy đủ trong BUILD_INFO. --allow-dirty không bỏ việc này.
FULL_HEAD="$(git rev-parse HEAD 2>/dev/null)" || die "không đọc được HEAD"
INFO="$OUT_DIR/${STAMP}.BUILD_INFO.txt"
VERSION="$(sed -n 's/^version: *//p' "$INFO" 2>/dev/null | head -1)"
BUILD_NO="$(sed -n 's/^build: *\([0-9]*\).*/\1/p' "$INFO" 2>/dev/null | head -1)"
COMMIT="$(sed -n 's/^commit: *\([0-9a-f]\{40\}\).*/\1/p' "$INFO" 2>/dev/null | head -1)"
[[ -n "$VERSION" && -n "$COMMIT" ]] || die "BUILD_INFO thiếu version hoặc commit đầy đủ: $INFO"
[[ "$COMMIT" == "$FULL_HEAD" ]] || die "gói build từ ${COMMIT:0:7}, HEAD là ${FULL_HEAD:0:7}. Build lại từ HEAD."
RULES="$(grep -o 'const RULES_VERSION := "[^"]*"' godot/scripts/core/action_log.gd 2>/dev/null | head -1 | sed 's/.*"\(.*\)"/\1/')"
[[ -n "$RULES" ]] || die "không đọc được RULES_VERSION trong godot/scripts/core/action_log.gd"

mkdir -p "$PUB_DIR"
MAC_NAME="$(basename "$MAC_ZIP")"; WIN_NAME="$(basename "$WIN_ZIP")"
for f in "$MAC_ZIP" "$WIN_ZIP"; do
  sz=$(stat -f %z "$f")
  (( sz <= MAX_BYTES )) || die "$(basename "$f") $sz byte > 300 MiB, Wrangler sẽ từ chối"
done
MAC_SHA="$(shasum -a 256 "$MAC_ZIP" | cut -d' ' -f1)"
WIN_SHA="$(shasum -a 256 "$WIN_ZIP" | cut -d' ' -f1)"
MAC_SZ=$(stat -f %z "$MAC_ZIP"); WIN_SZ=$(stat -f %z "$WIN_ZIP")

NOW="$(date '+%Y-%m-%dT%H:%M:%S%z')"
python3 -I - "$PUB_DIR/latest.json" "$VERSION" "$BUILD_NO" "$COMMIT" "$RULES" "$NOW" \
  "$MAC_NAME" "$MAC_SZ" "$MAC_SHA" "$WIN_NAME" "$WIN_SZ" "$WIN_SHA" <<'PY' || die "không ghi được latest.json"
import json, sys
out, version, build, commit, rules, now, mn, ms, msha, wn, ws, wsha = sys.argv[1:]
m = {
    "version": version,
    "build": int(build) if build.isdigit() else build,
    "commit": commit,
    "rules_version": rules,
    "published_at": now,
    "platforms": {
        "macos": {"file": mn, "size": int(ms), "sha256": msha},
        "windows": {"file": wn, "size": int(ws), "sha256": wsha},
    },
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(m, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "== gói $STAMP"
echo "   version $VERSION  build ${BUILD_NO:-?}  commit ${COMMIT:0:7}  luật $RULES"
echo "   macos   $MAC_NAME  $MAC_SZ byte  sha256 $MAC_SHA"
echo "   windows $WIN_NAME  $WIN_SZ byte  sha256 $WIN_SHA"
echo "   manifest $PUB_DIR/latest.json"
if [[ -z "$PREV" ]]; then
  echo "   CẢNH BÁO: không có --prev. Không có đường rollback desktop cho đợt này." >&2
fi

# --- Kế hoạch cho làn I (KHÔNG chạy ở đây) ------------------------------------------------------
echo
echo "# ---- Kế hoạch đăng. Dán vào shell theo thứ tự; set -e dừng ở lỗi đầu tiên. ----"
echo "# Cần 'npx wrangler login' bằng tay trước. Mọi lệnh --remote. Đọc trước, ghi sau."
echo "set -e"
echo "mkdir -p $PUB_DIR/prev"
echo "$WRANGLER r2 object get $BUCKET/downloads/latest.json --file $PUB_DIR/prev/live-latest.json --remote"
if [[ -n "$PREV" ]]; then
  echo "# Manifest trên R2 phải đúng bản --prev. Khác nhau thì DỪNG: có người đăng đè."
  echo "cmp $PREV $PUB_DIR/prev/live-latest.json"
  echo "# Lưu bản cũ vào downloads/old/: tải về, kiểm sha theo manifest TRÊN R2, rồi mới up."
  # File names/sha come from --prev at plan time (live-latest.json is only fetched when the plan runs; the cmp above
  # stops the plan if R2 differs from --prev).
  python3 -I - "$PREV" <<'PY' | while IFS=$'\t' read -r name sha; do
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
for p in ("macos", "windows"):
    e = m["platforms"][p]
    print(f'{e["file"]}\t{e["sha256"]}')
PY
    [[ -n "$name" ]] || continue
    echo "$WRANGLER r2 object get $BUCKET/downloads/$name --file $PUB_DIR/prev/$name --remote"
    echo "echo '$sha  $PUB_DIR/prev/$name' | shasum -a 256 -c -"
    echo "$WRANGLER r2 object put $BUCKET/downloads/old/$name --file $PUB_DIR/prev/$name --content-type application/octet-stream --remote"
  done
  OLD_LIST="$(python3 -I - "$PREV" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
print(" ".join(m["platforms"][p]["file"] for p in ("macos", "windows")))
PY
)"
else
  echo "# [không có --prev] bỏ bước lưu bản cũ. KHÔNG CÓ đường rollback desktop cho đợt này."
  OLD_LIST=""
fi
echo "# Up zip mới (không dmg). Mỗi file < 300 MiB."
echo "$WRANGLER r2 object put $BUCKET/downloads/$MAC_NAME --file $MAC_ZIP --content-type application/octet-stream --remote"
echo "$WRANGLER r2 object put $BUCKET/downloads/$WIN_NAME --file $WIN_ZIP --content-type application/octet-stream --remote"
echo "# Manifest LAST: từ đây trang /download trỏ vào bản mới."
echo "$WRANGLER r2 object put $BUCKET/downloads/latest.json --file $PUB_DIR/latest.json --content-type application/json --remote"
if [[ -n "$OLD_LIST" ]]; then
  echo "# Xoá file cũ ở gốc downloads/ (đã nằm trong downloads/old/, sha đã kiểm ở trên)."
  for f in $OLD_LIST; do
    [[ "$f" == "$MAC_NAME" || "$f" == "$WIN_NAME" ]] && continue
    echo "$WRANGLER r2 object delete $BUCKET/downloads/$f --remote"
  done
fi
echo "# Kiểm sau khi up: curl -sI https://axiedice.fun/download/$MAC_NAME (200, Content-Length $MAC_SZ);"
echo "# tải https://axiedice.fun/download, so version và sha256 với latest.json; tải một zip và shasum -a 256."
exit 0
