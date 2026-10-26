#!/usr/bin/env bash
# Chuẩn bị đăng bản desktop lên R2 cho trang /download. KHÔNG upload, KHÔNG gọi wrangler.
#
# Usage:
#   bash tools/publish_desktop.sh <tên gói trong build/>  [--prev <latest.json cũ đã tải về>] [--allow-dirty]
#   bash tools/publish_desktop.sh AxieDice-0.1.0-L1-b1639-5ecc08f
#
# Làm gì:
#   1. Kiểm hai file build/<gói>-macos.zip và build/<gói>-windows.zip có mặt, không có -dirty
#      (trừ khi --allow-dirty), và đọc được version, rules_version.
#   2. Tính sha256 và cỡ từng file (không tin file .sha256 cũ).
#   3. Ghi build/publish/latest.json (manifest, Worker đọc ở downloads/latest.json).
#   4. In ra danh sách lệnh `wrangler r2 object put/get/delete` theo đúng thứ tự an toàn, để LÀN I
#      chạy khi deploy. Thứ tự: lưu bản cũ vào downloads/old/ -> up file mới -> up latest.json
#      CUỐI CÙNG -> xoá file cũ ở gốc downloads/. Trang không bao giờ trỏ vào file chưa có.
#
# Lưu ý:
#   - R2 không có lệnh đổi tên. "Dời bản cũ sang downloads/old/" nghĩa là tải về rồi up lại, nên
#     tốn băng thông ~ cỡ hai file zip. Muốn bỏ bước này thì bỏ --prev, script sẽ không in bước
#     lưu bản cũ (và cảnh báo).
#   - Chỉ đăng macOS .zip và Windows .zip. .dmg không đăng (trùng nội dung, thêm 277 MB).
#   - Mọi put đều dưới 300 MiB (giới hạn Wrangler). Script kiểm điều này trước.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
OUT_DIR="$ROOT/build"
PUB_DIR="$OUT_DIR/publish"
BUCKET="${BUCKET:-axie-dice}"
MAX_BYTES=$((300 * 1024 * 1024))

die() { echo "publish_desktop: $*" >&2; exit 1; }

STAMP=""; PREV=""; ALLOW_DIRTY=0
while (( $# )); do
  case "$1" in
    --prev) PREV="${2:-}"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    -*) die "cờ lạ: $1" ;;
    *) [[ -z "$STAMP" ]] || die "chỉ nhận một tên gói"; STAMP="$1"; shift ;;
  esac
done
[[ -n "$STAMP" ]] || die "thiếu tên gói (ví dụ AxieDice-0.1.0-L1-b1639-5ecc08f)"
[[ -z "$PREV" || -f "$PREV" ]] || die "--prev không tìm thấy: $PREV"

MAC_ZIP="$OUT_DIR/${STAMP}-macos.zip"
WIN_ZIP="$OUT_DIR/${STAMP}-windows.zip"
[[ -f "$MAC_ZIP" ]] || die "thiếu $MAC_ZIP (chạy tools/build_desktop.sh trước)"
[[ -f "$WIN_ZIP" ]] || die "thiếu $WIN_ZIP"
if [[ "$STAMP" == *-dirty* && $ALLOW_DIRTY -ne 1 ]]; then
  die "gói có -dirty (cây làm việc có sửa godot/ hoặc tools/). Build lại từ cây sạch, hoặc --allow-dirty khi chỉ để thử"
fi

# Version và rules_version lấy từ chính gói, không đoán từ tên.
VERSION="$(sed -n 's/^version: *//p' "$OUT_DIR/${STAMP}.BUILD_INFO.txt" 2>/dev/null | head -1)"
[[ -n "$VERSION" ]] || VERSION="$(echo "$STAMP" | sed -n 's/^AxieDice-\([0-9.]*\)-.*/\1/p')"
BUILD_NO="$(sed -n 's/^build: *\([0-9]*\).*/\1/p' "$OUT_DIR/${STAMP}.BUILD_INFO.txt" 2>/dev/null | head -1)"
COMMIT="$(sed -n 's/^commit: *\([0-9a-f]*\).*/\1/p' "$OUT_DIR/${STAMP}.BUILD_INFO.txt" 2>/dev/null | head -1)"
RULES="$(grep -o 'const RULES_VERSION := "[^"]*"' godot/scripts/core/action_log.gd 2>/dev/null | head -1 | sed 's/.*"\(.*\)"/\1/')"
[[ -n "$RULES" ]] || die "không đọc được RULES_VERSION trong godot/scripts/core/action_log.gd"
# Gói phải được build từ đúng RULES_VERSION hiện tại của cây (cùng commit).
[[ "$COMMIT" == "$(git rev-parse --short HEAD 2>/dev/null)"* || $ALLOW_DIRTY -eq 1 ]] \
  || die "gói build từ commit $COMMIT, HEAD là $(git rev-parse --short HEAD). Build lại."

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
echo "   version $VERSION  build ${BUILD_NO:-?}  commit ${COMMIT:-?}  luật $RULES"
echo "   macos   $MAC_NAME  $MAC_SZ byte  sha256 $MAC_SHA"
echo "   windows $WIN_NAME  $WIN_SZ byte  sha256 $WIN_SHA"
echo "   manifest $PUB_DIR/latest.json"

# --- Lệnh cho làn I (KHÔNG chạy ở đây) -----------------------------------------------------------
W="npx wrangler"
R2="$BUCKET"
echo
echo "# ---- Lệnh đăng (làn I chạy khi deploy, theo thứ tự; dừng ở lỗi đầu tiên) ----"
echo "# Chuẩn bị: đã 'npx wrangler login' bằng tay. Lệnh dưới đều --remote."
step=1
if [[ -n "$PREV" ]]; then
  PREV_DIR="$PUB_DIR/prev"
  echo "# [$step] Lưu manifest cũ (chỉ đọc)."
  echo "mkdir -p $PREV_DIR"
  echo "$W r2 object get $R2/downloads/latest.json --file $PREV_DIR/latest.json --remote"
  step=$((step+1))
  echo "# [$step] Bản cũ -> downloads/old/ (đọc từng file đang có trong manifest cũ, rồi up lại)."
  python3 -I - "$PREV" <<'PY' | while IFS='|' read -r name; do
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
for p in ("macos", "windows"):
    f = m.get("platforms", {}).get(p, {}).get("file", "")
    if f and "/" not in f and ".." not in f:
        print(f"{f}|")
PY
    [[ -z "$name" ]] && continue
    echo "$W r2 object get $R2/downloads/$name --file $PUB_DIR/prev/$name --remote"
    echo "$W r2 object put $R2/downloads/old/$name --file $PUB_DIR/prev/$name --content-type application/octet-stream --remote"
  done
  echo "# (Nếu lệnh get đầu bước này lỗi, DỪNG. Không up file mới khi chưa lưu được bản cũ.)"
  step=$((step+1))
  OLD_TOP_FILES="$(python3 -I - "$PREV" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
print(" ".join(m.get("platforms", {}).get(p, {}).get("file", "") for p in ("macos", "windows")))
PY
)"
else
  echo "# [$step] KHÔNG có --prev: bỏ bước lưu bản cũ. Bản cũ vẫn nằm ở gốc downloads/ cho tới khi xoá tay."
  step=$((step+1))
  OLD_TOP_FILES=""
fi
echo "# [$step] Up file zip mới (không dmg). Mỗi file < 300 MiB."
echo "$W r2 object put $R2/downloads/$MAC_NAME --file $MAC_ZIP --content-type application/octet-stream --remote"
echo "$W r2 object put $R2/downloads/$WIN_NAME --file $WIN_ZIP --content-type application/octet-stream --remote"
step=$((step+1))
echo "# [$step] Manifest LAST: từ đây trang /download trỏ vào bản mới."
echo "$W r2 object put $R2/downloads/latest.json --file $PUB_DIR/latest.json --content-type application/json --remote"
step=$((step+1))
if [[ -n "$OLD_TOP_FILES" ]]; then
  echo "# [$step] Xoá file cũ ở gốc downloads/ (đã có trong downloads/old/). Bỏ qua tên trùng bản mới."
  for f in $OLD_TOP_FILES; do
    [[ -z "$f" || "$f" == "$MAC_NAME" || "$f" == "$WIN_NAME" ]] && continue
    echo "$W r2 object delete $R2/downloads/$f --remote"
  done
  step=$((step+1))
fi
echo "# [$step] Kiểm sau khi up: curl -sI https://axiedice.fun/download/$MAC_NAME (200, Content-Length $MAC_SZ), tải trang /download, so sha256 với latest.json."
echo "# Sau đó link cố định https://axiedice.fun/download là bản mới. Không đổi link trong client."
exit 0
