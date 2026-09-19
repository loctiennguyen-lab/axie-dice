#!/usr/bin/env bash
# Mở game để chơi thử. Không phải test, không phải headless — đây là bản chơi được.
#
#   ./godot/tools/play.sh
#
# Vì sao cần script này thay vì gõ tay: phải KHÔNG có --headless (headless không có màn hình),
# và phải trỏ --path vào thư mục `godot/` chứ không phải gốc repo (gốc repo là bản JS).
set -euo pipefail
GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

[[ -x "$GODOT" ]] || { echo "Không thấy Godot ở: $GODOT"; echo "Đặt biến GODOT=/đường/dẫn/Godot rồi chạy lại."; exit 1; }
echo "Đang mở Axie Dice Tactics (Godot port) — màn hình đầu là MAIN MENU."
exec "$GODOT" --path "$ROOT/godot"
