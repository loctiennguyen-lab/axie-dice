#!/usr/bin/env bash
# Xuất verifier.pck từ godot/ (cần export preset "Linux"/pck-only; chưa có, lane I tạo hoặc dùng --export-pack với preset hiện có).
# DỰ THẢO: chưa chạy. Chạy Godot qua godot/tools/with_lock.sh, tắt editor trước.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
bash godot/tools/with_lock.sh "$GODOT" --headless --path godot --export-pack "${PRESET:-Web}" "$PWD/verifier/verifier.pck"
