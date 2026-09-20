#!/usr/bin/env bash
# Chụp màn hình QA — một entry point cho vòng lặp "sửa → chạy → nhìn".
#
#   godot/tools/shot.sh res://tests/qa_meta_v2_capture.tscn [WIDTHxHEIGHT]
#
# Vì sao cần script này: scene chụp ảnh KHÔNG chạy được với --headless (dummy rasterizer trả về
# ảnh trắng, hỏng mà không có triệu chứng nào khác). Trên máy không có màn hình thật thì phải có
# X server ảo. Script tự chọn: có DISPLAY thì chạy thẳng, không thì bọc xvfb-run.
set -uo pipefail

SCENE="${1:?usage: shot.sh res://tests/qa_*.tscn [1920x1080]}"
RES="${2:-1920x1080}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJ="$ROOT/godot"

_default_godot() {
  local c
  for c in "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
           "$ROOT/tools/bin/Godot_v4.7.2-stable_linux.arm64" \
           "$ROOT/tools/bin/Godot_v4.7.2-stable_linux.x86_64"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return; }
  done
  command -v godot 2>/dev/null || true
}
GODOT="${GODOT:-$(_default_godot)}"
[[ -x "$GODOT" ]] || { echo "Không thấy Godot: $GODOT"; exit 1; }

export ADT_EVIDENCE_DIR="${ADT_EVIDENCE_DIR:-$ROOT/production/qa/evidence}"
mkdir -p "$ADT_EVIDENCE_DIR"

args=(--path "$PROJ" --resolution "$RES" --position 0,0 "$SCENE")

if [[ -n "${DISPLAY:-}" ]] || [[ "$(uname)" == "Darwin" ]]; then
  "$GODOT" "${args[@]}"
else
  command -v xvfb-run >/dev/null || { echo "Cần xvfb-run trên máy không màn hình."; exit 1; }
  # llvmpipe: không có GPU thì Vulkan không lên, OpenGL phần mềm thì lên.
  LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 2560x1600x24" \
    "$GODOT" --rendering-driver opengl3 "${args[@]}"
fi
