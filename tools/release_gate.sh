#!/usr/bin/env bash
# Cổng phát hành cho mọi đợt có Nhiệm vụ (R1+). Dừng (exit 1) nếu bảng Nhiệm vụ còn số tạm.
# Usage:
#   bash tools/release_gate.sh           chỉ kiểm bảng số (nhanh)
#   bash tools/release_gate.sh --suite   thêm: suite Godot với AXIE_RELEASE=1 + Worker test (~20 phút)
# Gọi từ export-web.sh và trước `wrangler deploy` (xem production/release/release-steps-beta.md).
set -uo pipefail

case "${1:-}" in
  ""|--suite) ;;
  *) echo "release_gate: tham số lạ: $1 (usage: release_gate.sh [--suite])" >&2; exit 2 ;;
esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
F="godot/assets/data/economy/missions.json"

[[ -f "$F" ]] || { echo "release_gate: thiếu $F" >&2; exit 1; }
n=$(grep -c '_tmp' "$F")
if [[ "$n" -ne 0 ]]; then
  echo "release_gate: FAIL, $F còn $n dòng _tmp (số tạm chưa thay bằng số N-S)." >&2
  grep -n '_tmp' "$F" | head -10 >&2
  exit 1
fi
echo "release_gate: missions.json không còn _tmp"

if [[ "${1:-}" == "--suite" ]]; then
  export AXIE_RELEASE=1 AXIE_HANG_KILL="${AXIE_HANG_KILL:-1200}"
  bash godot/tools/run_tests.sh || { echo "release_gate: FAIL suite Godot (AXIE_RELEASE=1)" >&2; exit 1; }
  mkdir -p "$ROOT/build"
  ( cd worker && node --test test/*.test.mjs > "$ROOT/build/worker_test.log" 2>&1 ) || { echo "release_gate: FAIL worker test, xem build/worker_test.log" >&2; exit 1; }
  echo "release_gate: suite + worker xanh"
fi
exit 0
