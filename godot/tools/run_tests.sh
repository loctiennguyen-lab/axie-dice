#!/usr/bin/env bash
# Godot test suite runner — single entry point for the godot-port branch.
# Usage: godot/tools/run_tests.sh [godot-binary]
# Runs every res://tests/t_*.tscn headless; a test signals failure by printing
# a line containing "FAIL" (tests also set exit codes via quit(1) where they can).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROJ="$ROOT/godot"
# shellcheck source=userdir.sh
source "$ROOT/godot/tools/userdir.sh"
axie_resolve_userdir "$PROJ" || { echo "run_tests: không đọc được config/name trong project.godot" >&2; exit 2; }
LOCK="${AXIE_GODOT_LOCK:-$AXIE_LOCK_DEFAULT}"

# Cờ cho worktree của làn (không phải làn I): AXIE_SKIP_RULES_FINGERPRINT=1 -> t_rules_version
# báo SKIP thay vì FAIL (FINGERPRINT chỉ làn I được tính lại, nên nó đỏ trong mọi worktree đã
# sửa scripts/core/ hoặc autoload/). Làn I và CI KHÔNG BAO GIỜ đặt cờ này. Mặc định: chạy như cũ.
# Cờ bị TỪ CHỐI (exit 2) ở worktree chính (làn I) hoặc khi có biến CI, trước khi xin khoá.
SKIP_FP="${AXIE_SKIP_RULES_FINGERPRINT:-}"
if [[ "$SKIP_FP" == 1 ]]; then
  main_wt="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')"
  if [[ -z "$main_wt" || "$main_wt" == "$ROOT" || -n "${CI:-}" ]]; then
    printf '\033[31mAXIE_SKIP_RULES_FINGERPRINT=1 bị TỪ CHỐI: đang ở worktree chính (làn I), không xác định được worktree chính, hoặc có biến CI. Cờ này chỉ dành cho worktree của làn.\033[0m\n' >&2
    exit 2
  fi
fi

# KHOÁ TOÀN CỤC (L1, 12/10): mọi lần chạy Godot trên máy này phải qua with_lock.sh, vì mọi worktree
# dùng chung user://. Chạy thẳng script này sẽ tự xin khoá rồi chạy lại chính nó trong khoá.
# Xem production/l1-lanes.md. Lồng khoá hợp lệ khi AXIE_GODOT_LOCK_HELD khớp pid chủ khoá.
# Watchdog mặc định 900s cho cả suite: lỗi parse làm Godot treo, không để giữ khoá mãi.
_held_ok() {
  local o; o="$(cat "$LOCK/pid" 2>/dev/null || true)"
  [[ -n "${AXIE_GODOT_LOCK_HELD:-}" && "${o%%|*}" == "$AXIE_GODOT_LOCK_HELD" ]]
}
if ! _held_ok; then
  export AXIE_HANG_KILL="${AXIE_HANG_KILL:-600}"   # cả suite (~90–150s), chừa dư cho máy chậm
  exec bash "$ROOT/godot/tools/with_lock.sh" bash "$ROOT/godot/tools/run_tests.sh" "$@"
fi


# Godot binary: the Mac editor build when present, otherwise the Linux build vendored in
# tools/bin/ (container, CI, headless box). Override with GODOT=/path/to/godot.
_default_godot() {
  local c
  for c in "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
           "$ROOT/tools/bin/Godot_v4.7.2-stable_linux.arm64" \
           "$ROOT/tools/bin/Godot_v4.7.2-stable_linux.x86_64"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return; }
  done
  command -v godot 2>/dev/null || true
}
GODOT="${1:-${GODOT:-$(_default_godot)}}"

# Godot chỉ đăng ký `class_name` cho script nó đã quét. Một file .gd mới chưa quét làm
# MỌI test tham chiếu tới nó đỏ bằng "Identifier ... not declared in the current scope",
# tức là một lỗi hạ tầng đội lốt 20 lỗi code. Dấu hiệu: .gd không có .uid đi kèm.
unscanned=0
while IFS= read -r f; do
  [[ -f "$f.uid" ]] || unscanned=$((unscanned+1))
done < <(find "$PROJ" -name '*.gd' -not -path '*/addons/*' -not -path '*/.godot/*')
# Worktree mới tạo (git worktree add) không có godot/.godot (cache import, không nằm trong git):
# .uid đủ cả nhưng class_name chưa đăng ký -> test treo. Thiếu cache cũng phải import.
if [[ ! -f "$PROJ/.godot/global_script_class_cache.cfg" ]]; then unscanned=$((unscanned+1)); fi
if [[ $unscanned -gt 0 ]]; then
  echo "$unscanned script chưa được Godot quét — nhập lại project trước khi chạy test..."
  "$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 \
    || "$GODOT" --headless --path "$PROJ" --editor --quit >/dev/null 2>&1 || true
fi

# Bảo vệ save THẬT của người chơi (2026-10-10). Với lệnh chạy qua with_lock.sh, save đã được
# chụp và trả lại ở tầng with_lock (kể cả khi bị kill). Lớp này vẫn đo từng test: test nào để
# lại thay đổi thì FAIL, và save được chép lại từ bản chụp đầu suite.
USERDIR="$AXIE_USERDIR"   # theo override.cfg của worktree nếu có (xem userdir.sh)
SAVE_SNAP="$(mktemp -d)"
# The desktop app and the main-tree suite share user:// (config/name "Axie Dice"): the sign-in files must be
# guarded too, or account tests delete Liam's real desktop session (happened 15/10).
_save_items=(meta_save.json run_save.json acct account.json account_prefs.json account_sync.json device_tokens.dat)
for it in "${_save_items[@]}"; do
  [[ -e "$USERDIR/$it" ]] && cp -Rp "$USERDIR/$it" "$SAVE_SNAP/"
done
_save_fp() {   # dấu vân tay nội dung các file save (bỏ qua thư mục rỗng)
  (cd "$1" 2>/dev/null && find meta_save.json run_save.json acct account.json account_prefs.json account_sync.json device_tokens.dat -type f 2>/dev/null \
     | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum < "$f"; done)
}
_save_restore() {
  for it in "${_save_items[@]}"; do
    rm -rf "${USERDIR:?}/$it"
    [[ -e "$SAVE_SNAP/$it" ]] && cp -Rp "$SAVE_SNAP/$it" "$USERDIR/"
  done
  return 0
}
SAVE_FP0="$(_save_fp "$SAVE_SNAP")"
trap '_save_restore; rm -rf "$SAVE_SNAP"' EXIT
# bash không chạy EXIT trap khi bị TERM/INT/HUP mặc định: đổi thành exit để EXIT trap vẫn trả save.
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# L1: tests never open real sockets/HTTP (see scripts/net/net_guard.gd).
export AXIE_TEST_NO_NET=1

pass=0; fail=0; skip=0; failed_names=()
if [[ "$SKIP_FP" == 1 ]]; then
  printf '\033[33m!! AXIE_SKIP_RULES_FINGERPRINT=1: t_rules_version BỊ BỎ QUA. Xanh ở đây KHÔNG có nghĩa là xanh ở godot-port; làn I chạy đủ sau merge.\033[0m\n'
fi

# Two kinds of test live side by side: scene tests (t_*.tscn, a Node _ready())
# and SceneTree tests (t_*.gd with no .tscn, run via --script). Run both.
targets=()
for scene in "$PROJ"/tests/t_*.tscn; do [[ -e "$scene" ]] || continue; targets+=("scene:$(basename "$scene" .tscn)"); done
for gd in "$PROJ"/tests/t_*.gd; do [[ -e "$gd" ]] || continue
  b="$(basename "$gd" .gd)"
  [[ -f "$PROJ/tests/$b.tscn" ]] || targets+=("script:$b")
done

for target in "${targets[@]}"; do
  kind="${target%%:*}"; name="${target#*:}"
  if [[ "$SKIP_FP" == 1 && "$name" == t_rules_version ]]; then
    skip=$((skip+1)); printf '  \033[33mSKIP\033[0m  %s — AXIE_SKIP_RULES_FINGERPRINT=1 (chỉ làn I được chạy gate này)\n' "$name"
    continue
  fi
  if [[ "$kind" == scene ]]; then
    out="$("$GODOT" --headless --path "$PROJ" "res://tests/$name.tscn" 2>&1)"
  else
    out="$("$GODOT" --headless --path "$PROJ" --script "tests/$name.gd" 2>&1)"
  fi
  code=$?
  leak=""
  if [[ "$(_save_fp "$USERDIR")" != "$SAVE_FP0" ]]; then
    leak="$name để lại save thật của người chơi bị đổi (meta/run/acct) — dùng SaveGuard. Đã chép lại save."
    _save_restore
  fi
  # A test fails on a non-zero exit, an engine-level script error, or an explicit
  # "FAIL" verdict. "0 failure(s)" in a passing summary must NOT trip this, hence the
  # word-boundary + explicit-verdict matching rather than a bare `grep -i fail`.
  if [[ $code -ne 0 || -n "$leak" ]] \
     || grep -qE "SCRIPT ERROR|Parse Error|^ *FAIL|: FAIL|FAILED" <<<"$out" \
     || grep -qE "[^0-9]([1-9][0-9]*) failure" <<<"$out" \
     || ! grep -qi "PASS" <<<"$out"; then
    fail=$((fail+1)); failed_names+=("$name")
    printf '  \033[31mFAIL\033[0m  %s\n' "$name"
    [[ -n "$leak" ]] && printf '        %s\n' "$leak"
    sed -n '1,25p' <<<"$out" | sed 's/^/        /'
  else
    pass=$((pass+1))
    printf '  \033[32mpass\033[0m  %s — %s\n' "$name" "$(grep -m1 -i 'PASS' <<<"$out" | cut -c1-110)"
  fi
done

echo
if [[ $skip -gt 0 ]]; then
  echo "================ $((pass+fail)) tests: $pass passed, $fail failed, $skip SKIPPED (t_rules_version — KHÔNG phải bản xanh đủ) ================"
else
  echo "================ $((pass+fail)) tests: $pass passed, $fail failed ================"
fi
if [[ $fail -gt 0 ]]; then printf 'failed: %s\n' "${failed_names[*]}"; exit 1; fi
