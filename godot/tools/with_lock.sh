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
#   - Khoá là thư mục $AXIE_GODOT_LOCK, nằm ngoài repo. Mặc định ~/Library/Caches/axie-dice-godot.lock
#     (chỉ còn dùng khi AXIE_REAL_USERDIR=1). Cây chính không có override.cfg: script ghi override.cfg TẠM
#     (user dir AxieDice-test-<repo>, khoá riêng axie-dice-godot-AxieDice-test-<repo>.lock), xoá khi xong.
#     Worktree có godot/override.cfg (use_custom_user_dir) dùng user dir riêng và
#     khoá riêng ~/Library/Caches/axie-dice-godot-<tên>.lock: các làn không còn xếp hàng chung. Xem userdir.sh.
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

TIMEOUT="${AXIE_LOCK_TIMEOUT:-1800}"
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# user:// sẽ dùng + đường dẫn khoá suy từ project này. Có override.cfg -> user dir riêng + khoá riêng;
# không có (cây chính) -> user dir test AxieDice-test-<repo> (override.cfg tạm), KHÔNG BAO GIỜ save thật.
# shellcheck source=userdir.sh
source "$PROJ/tools/userdir.sh"
if ! axie_effective_userdir "$PROJ" && [[ -z "${AXIE_SAVE_DIR:-}" || -z "${AXIE_GODOT_LOCK:-}" ]]; then
  echo "with_lock: không đọc được config/name trong project.godot, không chạy." >&2
  exit 2
fi
LOCK="${AXIE_GODOT_LOCK:-$AXIE_LOCK_DEFAULT}"
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

# --- PREFLIGHT (chong treo, 15/10) -------------------------------------------
# (a) Conflict marker trong .gd/.tscn/.tres/.cfg/project.godot -> Godot parse loi va TREO thay vi bao loi:
#     tu choi chay, exit 66. (b) Cache class_name cu hon file .gd moi nhat co class_name -> can --import,
#     tu import (toi da 240s) truoc khi chay tiep. Bo qua bang AXIE_SKIP_PREFLIGHT=1.
_preflight_conflicts() {
  grep -rIlE '^(<<<<<<< |=======$|>>>>>>> )' \
    --include='*.gd' --include='*.tscn' --include='*.tres' --include='*.cfg' --include='project.godot' \
    --exclude-dir=addons --exclude-dir=.godot "$PROJ" 2>/dev/null
}
_preflight_godot_bin() {
  local c
  for c in "${GODOT:-}" "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
           "$PROJ/../tools/bin/Godot_v4.7.2-stable_linux.arm64" "$PROJ/../tools/bin/Godot_v4.7.2-stable_linux.x86_64"; do
    [[ -n "$c" && -x "$c" ]] && { printf '%s' "$c"; return; }
  done
  command -v godot 2>/dev/null || true
}
_preflight_cache_stale() {
  local cache="$PROJ/.godot/global_script_class_cache.cfg" f
  [[ -f "$cache" ]] || return 0
  f="$(grep -rlE '^class_name ' --include='*.gd' --exclude-dir=addons --exclude-dir=.godot "$PROJ" 2>/dev/null \
       | while IFS= read -r x; do printf '%s %s\n' "$(stat -f %m "$x" 2>/dev/null || stat -c %Y "$x")" "$x"; done \
       | sort -rn | head -1 | cut -d' ' -f2-)"
  [[ -n "$f" && "$f" -nt "$cache" ]]
}
if [[ "${AXIE_SKIP_PREFLIGHT:-}" != 1 ]]; then
  bad="$(_preflight_conflicts)"
  if [[ -n "$bad" ]]; then
    echo "with_lock: PREFLIGHT tu choi chay Godot, co dau conflict git trong:" >&2
    printf '%s\n' "$bad" | sed 's/^/  /' >&2
    exit 66
  fi
fi

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
  USERDIR="${AXIE_SAVE_DIR:-$AXIE_USERDIR}"
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
# Cây chưa có user dir riêng (cây chính): ghi override.cfg tạm để Godot dùng AxieDice-test-<repo>, không chạm save thật.
axie_write_temp_override "$PROJ" || { echo "with_lock: không ghi được override.cfg tạm" >&2; rm -rf "$LOCK"; exit 1; }
if [[ "$GUARD" == 1 ]]; then
  if ! _snapshot_save "$LOCK/snap"; then
    echo "with_lock: không chụp được save, không chạy." >&2
    axie_remove_temp_override "$PROJ"
    rm -rf "$LOCK"
    exit 1
  fi
fi

_cleanup() {   # EXIT: dừng watcher, diệt cây còn sống, trả save, nhả khoá
  if [[ -n "$watcher" ]]; then kill "$watcher" 2>/dev/null; fi
  if [[ -n "$child" ]] && _alive "$child"; then _stop_tree "$child"; fi
  if [[ "$GUARD" == 1 ]]; then _restore_from "$LOCK/snap"; fi
  axie_remove_temp_override "$PROJ"
  rm -rf "$LOCK"
}
_on_signal() { trap '' INT TERM HUP; if [[ -n "$child" ]]; then _stop_tree "$child"; fi; exit "$1"; }
trap '_on_signal 130' INT
trap '_on_signal 143' TERM
trap '_on_signal 129' HUP
trap _cleanup EXIT


if [[ "${AXIE_SKIP_PREFLIGHT:-}" != 1 ]] && _preflight_cache_stale; then
  gb="$(_preflight_godot_bin)"
  if [[ -n "$gb" ]]; then
    echo "with_lock: cache class_name cu, tu chay --import (toi da 240s)..." >&2
    "$gb" --headless --path "$PROJ" --import >/dev/null 2>&1 & ip=$!
    # Watcher gets TERM when import finishes and kills its own sleep; stdout/stderr go to /dev/null so an
    # orphaned sleep can never hold a caller's $(...) pipe open for 240 s.
    ( trap 'kill "$s" 2>/dev/null; exit 0' TERM; sleep 240 & s=$!; wait "$s"; kill "$ip" 2>/dev/null ) >/dev/null 2>&1 & iw=$!
    wait "$ip" 2>/dev/null; ic=$?; kill "$iw" 2>/dev/null
    # Import xong mà không viết lại cache (vd checkout chỉ đổi mtime) thì chạm cache, để lần sau không import lại vô ích.
    [[ "$ic" == 0 && -f "$PROJ/.godot/global_script_class_cache.cfg" ]] && touch "$PROJ/.godot/global_script_class_cache.cfg"
  fi
fi
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
