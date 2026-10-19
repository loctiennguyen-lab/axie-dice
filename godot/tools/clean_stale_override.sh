#!/usr/bin/env bash
# Xoá godot/override.cfg TẠM (dấu axie-temp-override) còn sót sau SIGKILL, chỉ khi không lần chạy nào giữ khoá.
# Không viết lại logic khoá: gọi chính with_lock.sh với AXIE_LOCK_TIMEOUT=0 (không chờ). with_lock.sh tự tiếp
# quản khoá chết và tự xoá override tạm khi xong. Khoá còn sống -> with_lock thoát 75 ngay, override giữ nguyên.
# Usage: godot/tools/clean_stale_override.sh
#   exit 0: không có gì để làm, hoặc đã xoá. exit 1: còn override tạm vì một lần chạy đang giữ khoá.
set -uo pipefail
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CFG="$PROJ/override.cfg"
grep -qF "axie-temp-override" "$CFG" 2>/dev/null || exit 0
AXIE_LOCK_TIMEOUT=0 AXIE_GUARD_SAVE=0 AXIE_SKIP_PREFLIGHT=1 "$PROJ/tools/with_lock.sh" true >/dev/null 2>&1
if grep -qF "axie-temp-override" "$CFG" 2>/dev/null; then
  echo "clean_stale_override: godot/override.cfg tạm còn đó: một lần chạy đang giữ khoá. Không xoá." >&2
  exit 1
fi
echo "clean_stale_override: đã xoá godot/override.cfg tạm sót lại." >&2
