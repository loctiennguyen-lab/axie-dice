#!/usr/bin/env bash
# Khoá toàn cục cho MỌI lần chạy Godot trên máy này (mọi worktree dùng chung user://).
# Usage: godot/tools/with_lock.sh <lệnh> [đối số...]
#   godot/tools/with_lock.sh bash godot/tools/run_tests.sh
#   godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tests/t_codex.tscn
#   godot/tools/with_lock.sh "$GODOT" --headless --path godot --import
#   godot/tools/with_lock.sh "$GODOT" --path godot --editor        # mở editor cũng phải qua đây
#   godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tools/record_sample_run.tscn -- --seed=1
#
# Vì sao: save thật nằm ở user:// (tên theo config/name), chung cho mọi worktree. Hai lần chạy
# Godot cùng lúc giẫm lên save của nhau và làm test đỏ giả. macOS không có flock/timeout nên
# dùng mkdir (nguyên tử) làm khoá.
#
# Hành vi:
#   - Khoá là thư mục $AXIE_GODOT_LOCK (mặc định ~/Library/Caches/axie-dice-godot.lock), nằm ngoài repo.
#   - Trong khoá có file `pid` (pid của chính script này). pid đã chết -> khoá chết -> tiếp quản.
#   - Đang bị giữ: in ra ai giữ, giữ từ bao giờ, rồi chờ (mặc định tối đa 1800s, AXIE_LOCK_TIMEOUT).
#   - Chạy lệnh như tiến trình con (không exec, để còn nhả khoá), trả lại đúng exit code.
#   - AXIE_GODOT_LOCK_HELD=1 (tự đặt cho tiến trình con): lồng with_lock vào run_tests.sh không bị kẹt.
#   - AXIE_HANG_KILL=<giây> (tuỳ chọn, mặc định tắt): quá ngần đó thì kill lệnh. Lỗi parse GDScript làm
#     Godot treo, mac không có `timeout`; đặt cái này khi chạy lẻ để khỏi giữ khoá mãi.
set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <lệnh> [đối số...]" >&2
  exit 64
fi

# Đã giữ khoá ở tầng ngoài (vd run_tests.sh gọi script này) -> chạy thẳng.
if [[ "${AXIE_GODOT_LOCK_HELD:-}" == 1 ]]; then
  exec "$@"
fi

LOCK="${AXIE_GODOT_LOCK:-$HOME/Library/Caches/axie-dice-godot.lock}"
TIMEOUT="${AXIE_LOCK_TIMEOUT:-1800}"
mkdir -p "$(dirname "$LOCK")"

_age() {   # tuổi (giây) của thư mục khoá
  local m; m="$(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK" 2>/dev/null || echo 0)"
  echo $(( $(date +%s) - m ))
}

_try_take() {
  mkdir "$LOCK" 2>/dev/null || return 1
  printf '%s\n' "$$" > "$LOCK/pid"
  printf '%s\n' "${AXIE_LANE:-$(basename "$PWD")}: $*" > "$LOCK/owner"
  return 0
}

_stale() {
  [[ -d "$LOCK" ]] || return 1
  local p; p="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -z "$p" ]]; then
    # Chưa kịp ghi pid: coi là khoá mới, chỉ chết nếu treo quá 15s.
    [[ "$(_age)" -gt 15 ]]; return
  fi
  ! kill -0 "$p" 2>/dev/null
}

waited=0; told=0
until _try_take "$*"; do
  if _stale; then
    # mv nguyên tử: nếu nhiều bên cùng thấy khoá chết, chỉ một bên mv thắng.
    if mv "$LOCK" "$LOCK.dead.$$" 2>/dev/null; then
      echo "with_lock: khoá cũ của pid $(cat "$LOCK.dead.$$/pid" 2>/dev/null || echo '?') đã chết, tiếp quản." >&2
      rm -rf "$LOCK.dead.$$"
    fi
    continue
  fi
  if [[ $told -eq 0 || $((waited % 60)) -eq 0 ]]; then
    echo "with_lock: Godot đang bị giữ bởi [$(cat "$LOCK/owner" 2>/dev/null || echo '?')] pid $(cat "$LOCK/pid" 2>/dev/null || echo '?'), đã $(_age)s. Đang chờ (đã chờ ${waited}s/${TIMEOUT}s)..." >&2
    told=1
  fi
  if [[ $waited -ge $TIMEOUT ]]; then
    echo "with_lock: chờ quá ${TIMEOUT}s, bỏ. Nếu chắc khoá kẹt: rm -rf '$LOCK'" >&2
    exit 75
  fi
  sleep 2; waited=$((waited+2))
done

child=""
_release() { rm -rf "$LOCK"; }
_on_signal() { [[ -n "$child" ]] && kill "$child" 2>/dev/null; _release; exit 130; }
trap _release EXIT
trap _on_signal INT TERM HUP

export AXIE_GODOT_LOCK_HELD=1
"$@" &
child=$!
if [[ "${AXIE_HANG_KILL:-0}" -gt 0 ]]; then
  ( sleep "$AXIE_HANG_KILL"; kill "$child" 2>/dev/null; sleep 5; kill -9 "$child" 2>/dev/null ) &
  watcher=$!
fi
wait "$child"; code=$?
[[ -n "${watcher:-}" ]] && kill "$watcher" 2>/dev/null
exit $code
