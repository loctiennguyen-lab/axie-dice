#!/usr/bin/env bash
# Test cho cô lập user dir (19/10): cây không có override.cfg không bao giờ chạy trên save thật.
# KHÔNG chạy Godot. Dùng HOME giả + AXIE_GODOT_LOCK riêng.
# Usage: bash godot/tools/tests/userdir_isolation_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS="$(cd "$HERE/.." && pwd -P)"
S="$(mktemp -d "${TMPDIR:-/tmp}/uditest.XXXXXX")"
trap 'rm -rf "$S"' EXIT
unset AXIE_GODOT_LOCK_HELD AXIE_HANG_KILL AXIE_SKIP_RULES_FINGERPRINT AXIE_GUARD_SAVE AXIE_SAVE_DIR AXIE_REAL_USERDIR CI AXIE_LANE
export AXIE_GODOT_LOCK="$S/lock" AXIE_SKIP_PREFLIGHT=1 HOME="$S/home"
mkdir -p "$HOME"

PASS=0; FAIL=0
check() { local n="$1"; shift; if "$@"; then PASS=$((PASS+1)); printf '  pass  %s\n' "$n"; else FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$n"; fi; }

# Cây giả giống cây chính: <repo>/godot/{project.godot,tools/}, không override.cfg.
R="$S/my-fake-repo"
mkdir -p "$R/godot/tools"
cp "$TOOLS/with_lock.sh" "$TOOLS/run_tests.sh" "$TOOLS/userdir.sh" "$R/godot/tools/"
printf 'config/name="Axie Zz"\n' > "$R/godot/project.godot"

# shellcheck source=../userdir.sh
source "$TOOLS/userdir.sh"
axie_effective_userdir "$R/godot"
check "cây không override: user dir là AxieDice-test-<repo>" grep -q "/AxieDice-test-my-fake-repo$" <<<"$AXIE_USERDIR"
check "cây không override: không nằm trong app_userdata" bash -c '! grep -q app_userdata <<<"$1"' _ "$AXIE_USERDIR"
check "cây không override: khoá riêng theo user dir test" grep -q "axie-dice-godot-AxieDice-test-my-fake-repo.lock$" <<<"$AXIE_LOCK_DEFAULT"
check "cây không override: cần ghi override tạm" test "$AXIE_NEED_TEMP_OVERRIDE" = 1
AXIE_REAL_USERDIR=1 axie_effective_userdir "$R/godot"
check "AXIE_REAL_USERDIR=1: về user dir thật" grep -q "app_userdata/Axie Zz$" <<<"$AXIE_USERDIR"
check "AXIE_REAL_USERDIR=1: không ghi override" test "$AXIE_NEED_TEMP_OVERRIDE" = 0

# with_lock.sh: lệnh con thấy override.cfg tạm, sau đó file bị xoá.
seen="$S/seen"
bash "$R/godot/tools/with_lock.sh" bash -c "cat '$R/godot/override.cfg' > '$seen'" >/dev/null 2>&1
check "with_lock: lệnh con thấy use_custom_user_dir=true" grep -q "config/use_custom_user_dir=true" "$seen"
check "with_lock: lệnh con thấy tên AxieDice-test-my-fake-repo" grep -q 'custom_user_dir_name="AxieDice-test-my-fake-repo"' "$seen"
check "with_lock: override.cfg tạm bị xoá sau khi xong" test ! -e "$R/godot/override.cfg"
bash "$R/godot/tools/with_lock.sh" bash -c 'exit 7' >/dev/null 2>&1; rc=$?
check "with_lock: exit code trả đúng, override vẫn bị xoá" bash -c '[[ "$1" -eq 7 && ! -e "$2" ]]' _ "$rc" "$R/godot/override.cfg"

# override tạm còn sót (SIGKILL): lần sau nhận lại và xoá.
printf '%s\n[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AxieDice-test-my-fake-repo"\n' "$AXIE_TEMP_OVERRIDE_MARK" > "$R/godot/override.cfg"
bash "$R/godot/tools/with_lock.sh" true >/dev/null 2>&1
check "override tạm sót: lần sau xoá" test ! -e "$R/godot/override.cfg"

# override.cfg của người dùng (không có dấu tạm): không bao giờ bị ghi đè hay xoá.
printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="Mine"\n' > "$R/godot/override.cfg"
bash "$R/godot/tools/with_lock.sh" true >/dev/null 2>&1
check "override.cfg của làn: giữ nguyên sau with_lock" grep -q 'custom_user_dir_name="Mine"' "$R/godot/override.cfg"
rm -f "$R/godot/override.cfg"

# override.cfg lạ không đặt user dir riêng: từ chối, không ghi đè.
printf '[display]\nwindow/size/viewport_width=1\n' > "$R/godot/override.cfg"
bash "$R/godot/tools/with_lock.sh" true >/dev/null 2>&1; rc=$?
check "override.cfg lạ: with_lock từ chối (exit 2)" test "$rc" -eq 2
check "override.cfg lạ: file giữ nguyên" grep -q viewport_width "$R/godot/override.cfg"
rm -f "$R/godot/override.cfg"

# clean_stale_override.sh: chỉ xoá override tạm khi không khoá nào giữ; không bao giờ đụng override của làn.
cp "$TOOLS/clean_stale_override.sh" "$R/godot/tools/"
CLEAN="$R/godot/tools/clean_stale_override.sh"
temp_ov() { printf '%s\n[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AxieDice-test-my-fake-repo"\n' "$AXIE_TEMP_OVERRIDE_MARK" > "$R/godot/override.cfg"; }
temp_ov; rm -rf "$AXIE_GODOT_LOCK"
bash "$CLEAN" >/dev/null 2>&1; rc=$?
check "clean: override tạm sót, không khoá -> xoá, rc 0" bash -c '[[ "$1" -eq 0 && ! -e "$2" ]]' _ "$rc" "$R/godot/override.cfg"
sleep 0 & dp=$!; wait "$dp" 2>/dev/null
temp_ov; mkdir -p "$AXIE_GODOT_LOCK"; printf '%s|%s\n' "$dp" "Mon Jan  1 00:00:00 2001" > "$AXIE_GODOT_LOCK/pid"
bash "$CLEAN" >/dev/null 2>&1; rc=$?
check "clean: khoá của pid chết -> tiếp quản, xoá override, rc 0" bash -c '[[ "$1" -eq 0 && ! -e "$2" && ! -d "$3" ]]' _ "$rc" "$R/godot/override.cfg" "$AXIE_GODOT_LOCK"
sleep 60 & lp=$!
lst="$(ps -o lstart= -p "$lp" | tr -s ' ' | sed 's/^ //; s/ $//')"
temp_ov; mkdir -p "$AXIE_GODOT_LOCK"; printf '%s|%s\n' "$lp" "$lst" > "$AXIE_GODOT_LOCK/pid"
bash "$CLEAN" >/dev/null 2>&1; rc=$?
check "clean: khoá của lần chạy đang sống -> giữ override, rc 1" bash -c '[[ "$1" -eq 1 && -e "$2" ]]' _ "$rc" "$R/godot/override.cfg"
kill "$lp" 2>/dev/null; wait "$lp" 2>/dev/null; rm -rf "$AXIE_GODOT_LOCK"
printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="Mine"\n' > "$R/godot/override.cfg"
bash "$CLEAN" >/dev/null 2>&1; rc=$?
check "clean: override.cfg của làn không đụng, rc 0" bash -c '[[ "$1" -eq 0 && -e "$2" ]] && grep -q Mine "$2"' _ "$rc" "$R/godot/override.cfg"
rm -f "$R/godot/override.cfg"

echo
echo "================ userdir_isolation_test: $PASS passed, $FAIL failed ================"
[[ $FAIL -eq 0 ]]
