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
#     File `pid` ghi "pid|lstart" của chủ khoá. Chủ đã chết, hoặc pid bị tái dùng (lstart khác) -> khoá chết.
#   - Tiếp quản qua gate mkdir theo pid chết: đúng một bên được mv khoá cũ đi.
#   - Trước khi chạy: chụp save thật (meta_save.json, run_save.json, acct/) vào $LOCK/snap và trả lại
#     khi xong, kể cả khi bị INT/TERM/HUP hay hang-kill. Người tiếp quản một khoá của chủ bị SIGKILL
#     trả save từ snap đó trước khi chạy. AXIE_GUARD_SAVE=0 để tắt. AXIE_SAVE_DIR ghi đè thư mục save
#     (chỉ dùng trong test).
#   - Ngắt: diệt cả cây tiến trình (TERM, chờ 5s, KILL phần còn sống), rồi mới trả save và nhả khoá.
#   - AXIE_HANG_KILL=<giây> (0 = tắt): quá thời gian thì diệt cả cây và thoát 124.
#   - AXIE_GODOT_LOCK_HELD=<pid chủ khoá>: lồng khoá. Chỉ bỏ qua khoá khi pid khớp chủ khoá đang giữ.
#   - Trả đúng exit code của lệnh.
#   - Lưu ý: tiến trình chạy nền (`&`, run_in_background) bị bỏ qua SIGINT từ lúc khởi động nên không
#     bắt được INT. Dùng TERM để dừng.
set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <lệnh> [đối số...]" >&2
  exit 64
fi

LOCK="${AXIE_GODOT_LOCK:-$HOME/Library/Caches/axie-dice-godot.lock}"
TIMEOUT="${AXIE_LOCK_TIMEOUT:-1800}"
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SAVE_ITEMS=(meta_save.json run_save.json acct)
GUARD="${AXIE_GUARD_SAVE:-1}"

_now() { date +%s; }
_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
_owner() { cat "$LOCK/pid" 2>/dev/null || true; }
_owner_pid() { local o; o="$(_owner)"; printf '%s' "${o%%|*}"; }
_pid_start() { ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' | sed 's/^ //; s/ $//'; }
_alive() {   # còn sống và không phải zombie
  local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"
  [[ -n "$s" && "$s" != Z* ]]
}
_owner_alive() {   # $1 = nội dung file pid, dạng "pid|lstart"
  local p="${1%%|*}" want="${1#*|}"
  [[ -n "$p" ]] && _alive "$p" || return 1
  [[ -z "$want" || "$(_pid_start "$p")" == "$want" ]]
}

# Lồng khoá: chỉ hợp lệ khi pid trong file khoá khớp với AXIE_GODOT_LOCK_HELD.
# Một AXIE_GODOT_LOCK_HELD=1 tuỳ tiện trong shell không còn tắt được khoá.
_held_ok() { [[ -n "${AXIE_GODOT_LOCK_HELD:-}" && "$(_owner_pid)" == "$AXIE_GODOT_LOCK_HELD" ]]; }
if _held_ok; then exec "$@"; fi

_stale() {
  [[ -d "$LOCK" ]] || return 1
  local o; o="$(_owner)"
  if [[ -z "$o" ]]; then   # chưa ghi xong pid: chỉ coi là chết nếu treo quá 15s
    [[ $(( $(_now) - $(_mtime "$LOCK") )) -gt 15 ]]; return
  fi
  ! _owner_alive "$o"
}

_try_take() {
  mkdir "$LOCK" 2>/dev/null || return 1
  printf '%s|%s\n' "$$" "$(_pid_start "$$")" > "$LOCK/pid"
  printf '%s\n' "${AXIE_LANE:-$(basename "$PWD")}: $1" > "$LOCK/owner"
}

# --- save guard -------------------------------------------------------------
if [[ "$GUARD" == 1 ]]; then
  if [[ -n "${AXIE_SAVE_DIR:-}" ]]; then
    USERDIR="$AXIE_SAVE_DIR"
  else
    _app="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$PROJ/project.godot" 2>/dev/null | head -1)"
    if [[ -z "$_app" ]]; then
      echo "with_lock: không đọc được config/name trong project.godot, không chạy (không bảo vệ được save)." >&2
      exit 2
    fi
    if [[ "$(uname)" == Darwin ]]; then
      USERDIR="$HOME/Library/Application Support/Godot/app_userdata/$_app"
    else
      USERDIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/$_app"
    fi
  fi
fi

_snapshot_save() {   # $1 = thư mục snap
  local s="$1" it
  mkdir -p "$s/data" || return 1
  printf '%s\n' "$USERDIR" > "$s/userdir"
  for it in "${SAVE_ITEMS[@]}"; do
    if [[ -e "$USERDIR/$it" ]]; then cp -Rp "$USERDIR/$it" "$s/data/" || return 1; fi
  done
}

_restore_from() {   # $1 = thư mục snap; đưa save về đúng trạng thái lúc chụp
  local s="$1" ud it
  [[ -f "$s/userdir" ]] || return 0
  ud="$(cat "$s/userdir")"
  [[ -n "$ud" ]] || return 0
  for it in "${SAVE_ITEMS[@]}"; do
    rm -rf "${ud:?}/$it"
    if [[ -e "$s/data/$it" ]]; then mkdir -p "$ud"; cp -Rp "$s/data/$it" "$ud/"; fi
  done
}

# --- tiếp quản khoá chết ----------------------------------------------------
_takeover() {
  local seen gate dead
  seen="$(_owner)"
  gate="$LOCK.gate.$(printf '%s' "${seen:-none}" | cksum | cut -d' ' -f1)"
  if ! mkdir "$gate" 2>/dev/null; then
    # Gate còn lại từ một bên tiếp quản đã chết giữa chừng: dọn sau 10s.
    if [[ $(( $(_now) - $(_mtime "$gate") )) -gt 10 ]]; then rmdir "$gate" 2>/dev/null; fi
    return 0
  fi
  # Đã giữ gate: kiểm lại dưới gate. Chỉ có bên giữ gate mới mv khoá, nên khoá không đổi trong lúc này.
  if [[ "$(_owner)" == "$seen" ]] && _stale; then
    dead="$LOCK.dead.$$"
    if mv "$LOCK" "$dead" 2>/dev/null; then
      echo "with_lock: khoá cũ [${seen:-chưa ghi pid}] đã chết, tiếp quản." >&2
      _restore_from "$dead/snap"   # chủ cũ có thể đã bị SIGKILL trước khi trả save
      rm -rf "$dead"
    fi
  fi
  rmdir "$gate" 2>/dev/null
  return 0
}

# --- diệt cây tiến trình ----------------------------------------------------
_tree_pids() {
  local p
  echo "$1"
  for p in $(pgrep -P "$1" 2>/dev/null); do _tree_pids "$p"; done
}
_stop_tree() {   # TERM cả cây, chờ tối đa 5s, KILL phần còn sống
  local root="$1" all p i any
  all="$(_tree_pids "$root")"
  kill -TERM $all 2>/dev/null
  for i in $(seq 1 25); do
    all="$all $(_tree_pids "$root")"
    any=0
    for p in $all; do if _alive "$p"; then any=1; break; fi; done
    [[ $any -eq 0 ]] && return 0
    sleep 0.2
  done
  for p in $all; do if _alive "$p"; then kill -KILL "$p" 2>/dev/null; fi; done
  return 0
}

# --- acquire ----------------------------------------------------------------
mkdir -p "$(dirname "$LOCK")"
waited=0; told=0
until _try_take "$*"; do
  if _stale; then
    _takeover
    sleep 0.2
    continue
  fi
  if [[ $told -eq 0 || $((waited % 60)) -eq 0 ]]; then
    echo "with_lock: Godot đang bị giữ bởi [$(cat "$LOCK/owner" 2>/dev/null || echo '?')] pid $(_owner_pid), đã $(( $(_now) - $(_mtime "$LOCK") ))s. Đang chờ (đã chờ ${waited}s/${TIMEOUT}s)..." >&2
    told=1
  fi
  if [[ $waited -ge $TIMEOUT ]]; then
    echo "with_lock: chờ quá ${TIMEOUT}s, bỏ. Nếu chắc khoá kẹt: rm -rf '$LOCK'" >&2
    exit 75
  fi
  sleep 2; waited=$((waited+2))
done

child=""; watcher=""
if [[ "$GUARD" == 1 ]]; then
  if ! _snapshot_save "$LOCK/snap"; then
    echo "with_lock: không chụp được save, không chạy." >&2
    rm -rf "$LOCK"
    exit 1
  fi
fi

_cleanup() {   # EXIT: dừng watcher, diệt cây còn sống, trả save, nhả khoá
  if [[ -n "$watcher" ]]; then kill "$watcher" 2>/dev/null; fi
  if [[ -n "$child" ]] && _alive "$child"; then _stop_tree "$child"; fi
  if [[ "$GUARD" == 1 ]]; then _restore_from "$LOCK/snap"; fi
  rm -rf "$LOCK"
}
_on_signal() { trap '' INT TERM HUP; if [[ -n "$child" ]]; then _stop_tree "$child"; fi; exit "$1"; }
trap '_on_signal 130' INT
trap '_on_signal 143' TERM
trap '_on_signal 129' HUP
trap _cleanup EXIT

export AXIE_GODOT_LOCK_HELD="$$"
"$@" &
child=$!
if [[ "${AXIE_HANG_KILL:-0}" -gt 0 ]]; then
  (
    trap 'kill "$s" 2>/dev/null; exit 0' TERM
    sleep "$AXIE_HANG_KILL" & s=$!
    wait "$s" 2>/dev/null
    echo "with_lock: quá ${AXIE_HANG_KILL}s, diệt cả cây tiến trình." >&2
    : > "$LOCK/hang"
    _stop_tree "$child"
  ) &
  watcher=$!
fi
wait "$child"; code=$?
if [[ -f "$LOCK/hang" ]]; then code=124; fi
exit $code
