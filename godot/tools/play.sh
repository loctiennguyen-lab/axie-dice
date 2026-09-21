#!/usr/bin/env bash
# Mở game để chơi thử. Không phải test, không phải headless — đây là bản chơi được.
#
#   ./godot/tools/play.sh
#
# Vì sao cần script này thay vì gõ tay: phải KHÔNG có --headless (headless không có màn hình),
# và phải trỏ --path vào thư mục `godot/` chứ không phải gốc repo (gốc repo là bản JS).
set -euo pipefail
# Godot binary: the Mac editor build when present, otherwise the Linux build vendored in
# tools/bin/ (container, CI, headless box). Override with GODOT=/path/to/godot.
_default_godot() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local c
  for c in "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
           "$root/tools/bin/Godot_v4.7.2-stable_linux.arm64" \
           "$root/tools/bin/Godot_v4.7.2-stable_linux.x86_64"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return; }
  done
  command -v godot 2>/dev/null || true
}
GODOT="${GODOT:-$(_default_godot)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

[[ -x "$GODOT" ]] || { echo "Không thấy Godot ở: $GODOT"; echo "Đặt biến GODOT=/đường/dẫn/Godot rồi chạy lại."; exit 1; }
# Một script .gd mới chưa được Godot quét thì `class_name` của nó KHÔNG nằm trong
# .godot/global_script_class_cache.cfg, và mọi file gọi tới nó chết bằng
#   Parse Error: Identifier "<Tên>" not declared in the current scope.
# Lỗi đó đọc như lỗi code — nó không phải. Dấu hiệu nhận biết rẻ nhất: file .gd nào
# chưa có .uid đi kèm thì Godot chưa bao giờ nhìn thấy nó. Quét lại trước khi mở game,
# mất vài giây và chỉ xảy ra sau khi có file mới.
unscanned=0
while IFS= read -r f; do
  [[ -f "$f.uid" ]] || { unscanned=$((unscanned+1)); }
done < <(find "$ROOT/godot" -name '*.gd' -not -path '*/addons/*' -not -path '*/.godot/*')

if [[ $unscanned -gt 0 ]]; then
  echo "Có $unscanned script Godot chưa quét — đang nhập lại project (chỉ lần này)..."
  "$GODOT" --headless --path "$ROOT/godot" --import >/dev/null 2>&1 \
    || "$GODOT" --headless --path "$ROOT/godot" --editor --quit >/dev/null 2>&1 || true
fi

echo "Đang mở Axie Dice (Godot port) — màn hình đầu là MAIN MENU."
exec "$GODOT" --path "$ROOT/godot"
