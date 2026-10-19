#!/usr/bin/env bash
# Test cho with_lock.sh và cờ skip trong run_tests.sh. KHÔNG chạy Godot.
# Dùng AXIE_GODOT_LOCK và AXIE_SAVE_DIR riêng trong thư mục tạm, không đụng khoá thật hay save thật.
# Usage: bash godot/tools/tests/with_lock_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS="$(cd "$HERE/.." && pwd -P)"
WL="$TOOLS/with_lock.sh"
RT="$TOOLS/run_tests.sh"

S="$(mktemp -d "${TMPDIR:-/tmp}/wltest.XXXXXX")"
trap 'rm -rf "$S"' EXIT
export AXIE_GODOT_LOCK="$S/lock"
export AXIE_SAVE_DIR="$S/save"
unset AXIE_GODOT_LOCK_HELD AXIE_HANG_KILL AXIE_SKIP_RULES_FINGERPRINT AXIE_GUARD_SAVE CI AXIE_LANE

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  pass  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
no_procs() { ! pgrep -f "$1" >/dev/null 2>&1; }      # không còn tiến trình nào khớp
lock_gone() { [[ ! -e "$AXIE_GODOT_LOCK" ]]; }
lock_has() { [[ -d "$AXIE_GODOT_LOCK" ]]; }
# Chờ có điều kiện, tối đa 10s (50 x 0.2s). Không chờ vô hạn. Hết giờ thì trả 1 để test báo FAIL.
wait_until() { local i; for i in $(seq 1 50); do "$@" && return 0; sleep 0.2; done; return 1; }
proc_up() { pgrep -f "$1" >/dev/null 2>&1; }          # có tiến trình khớp chuỗi $1
save_changed() { [[ "$(cat "$AXIE_SAVE_DIR/meta_save.json" 2>/dev/null)" == CHANGED ]]; }

reset_save() {   # save giả: meta_save.json, acct/x
  rm -rf "$AXIE_GODOT_LOCK" "$AXIE_SAVE_DIR" "$S/par" "$S/fake"
  mkdir -p "$AXIE_SAVE_DIR/acct" "$S/fake"
  printf 'ORIG' > "$AXIE_SAVE_DIR/meta_save.json"
  printf 'acct-orig' > "$AXIE_SAVE_DIR/acct/x"
}
meta_is_orig() { [[ "$(cat "$AXIE_SAVE_DIR/meta_save.json" 2>/dev/null)" == ORIG ]]; }
acct_is_orig() { [[ "$(cat "$AXIE_SAVE_DIR/acct/x" 2>/dev/null)" == acct-orig ]]; }
no_run_save() { [[ ! -e "$AXIE_SAVE_DIR/run_save.json" ]]; }

# Tiến trình "game" giả: ghi đè save rồi ngủ N giây (N là số duy nhất, để pgrep đúng tiến trình).
cat > "$S/writer.sh" <<'EOS'
#!/usr/bin/env bash
printf 'CHANGED' > "$AXIE_SAVE_DIR/meta_save.json"
rm -rf "$AXIE_SAVE_DIR/acct"
printf 'run' > "$AXIE_SAVE_DIR/run_save.json"
sleep "$1"
EOS
# Tiến trình giống run_tests.sh: lệnh nằm trong $(...) rồi mới tới "godot" (sleep).
cat > "$S/suite.sh" <<'EOS'
#!/usr/bin/env bash
out="$(sleep "$1" 2>&1)"
echo done
EOS

echo "== exit code, lock nhả, save trả lại khi chạy xong bình thường"
reset_save
"$WL" bash -c 'exit 7'; rc=$?
check "exit code lệnh được trả lại (7)" test "$rc" -eq 7
check "khoá được nhả sau khi xong" lock_gone
reset_save
"$WL" bash "$S/writer.sh" 0 >/dev/null 2>&1
check "save được trả lại sau lệnh thành công (meta)" meta_is_orig
check "save được trả lại (acct/)" acct_is_orig
check "run_save.json do lệnh tạo bị xoá" no_run_save

echo "== song song: không hai tiến trình cùng giữ khoá (có khoá chết sẵn)"
reset_save
mkdir -p "$AXIE_GODOT_LOCK"
sleep 0 & dp_sleep=$!; wait "$dp_sleep" 2>/dev/null
printf '%s|%s\n' "$dp_sleep" "Mon Jan  1 00:00:00 2001" > "$AXIE_GODOT_LOCK/pid"
mkdir -p "$S/par"; : > "$S/par/done"
for i in 1 2 3 4 5 6; do
  ( "$WL" bash -c "if ! mkdir '$S/par/in' 2>/dev/null; then echo overlap >> '$S/par/bad'; fi; sleep 0.3; rmdir '$S/par/in' 2>/dev/null; echo ok >> '$S/par/done'" ) >/dev/null 2>&1 &
done
wait
check "6 tiến trình song song, không overlap" test ! -e "$S/par/bad"
check "cả 6 lượt đều chạy xong" test "$(wc -l < "$S/par/done" | tr -d ' ')" -eq 6
check "khoá nhả hết sau song song" lock_gone

echo "== tiếp quản khoá của pid đã chết"
reset_save
mkdir -p "$AXIE_GODOT_LOCK"
sleep 0 & dp=$!; wait "$dp" 2>/dev/null
printf '%s|%s\n' "$dp" "Mon Jan  1 00:00:00 2001" > "$AXIE_GODOT_LOCK/pid"
out="$("$WL" bash -c 'echo ran' 2>&1)"
check "chạy được khi khoá của pid chết" test "$(grep -c '^ran$' <<<"$out")" -eq 1
check "báo đã tiếp quản" grep -q "tiếp quản" <<<"$out"

echo "== pid bị tái dùng (pid còn sống nhưng lstart khác) coi là khoá chết"
reset_save
sleep 60 & rp=$!
mkdir -p "$AXIE_GODOT_LOCK"
printf '%s|%s\n' "$rp" "Mon Jan  1 00:00:00 2001" > "$AXIE_GODOT_LOCK/pid"
out="$("$WL" bash -c 'echo ran' 2>&1)"; rc=$?
check "tiếp quản được khi pid bị tái dùng" test "$rc" -eq 0
kill "$rp" 2>/dev/null; wait "$rp" 2>/dev/null

echo "== chủ khoá còn sống, đúng lstart: không được cướp"
reset_save
sleep 60 & lp=$!
lst="$(ps -o lstart= -p "$lp" | tr -s ' ' | sed 's/^ //; s/ $//')"
mkdir -p "$AXIE_GODOT_LOCK"
printf '%s|%s\n' "$lp" "$lst" > "$AXIE_GODOT_LOCK/pid"
AXIE_LOCK_TIMEOUT=3 "$WL" bash -c 'echo should-not-run' >/dev/null 2>&1; rc=$?
check "hết giờ chờ thì thoát 75" test "$rc" -eq 75
check "khoá của chủ sống vẫn còn nguyên" test "$(cut -d'|' -f1 "$AXIE_GODOT_LOCK/pid")" = "$lp"
kill "$lp" 2>/dev/null; wait "$lp" 2>/dev/null
rm -rf "$AXIE_GODOT_LOCK"

echo "== TERM vào with_lock: diệt cả cây (sleep cháu), nhả khoá, trả save"
reset_save
"$WL" bash "$S/suite.sh" 317 >/dev/null 2>&1 & wp=$!
wait_until proc_up "sleep 317" || bad "sleep 317 chưa lên sau 10s"
kill -TERM "$wp" 2>/dev/null; wait "$wp"; rc=$?
check "thoát 143 khi bị TERM" test "$rc" -eq 143
check "không còn 'sleep 317' mồ côi" no_procs "sleep 317"
check "khoá được nhả" lock_gone

echo "== Ctrl-C (INT, foreground) vào with_lock: không mồ côi"
reset_save
python3 -c 'import signal,os,sys
signal.signal(signal.SIGINT, signal.SIG_DFL)
os.execvp("bash", ["bash", sys.argv[1], "bash", sys.argv[2], "318"])' "$WL" "$S/suite.sh" >/dev/null 2>&1 & ip=$!
wait_until proc_up "sleep 318" || bad "sleep 318 chưa lên sau 10s"
kill -INT "$ip" 2>/dev/null; wait "$ip"; rc=$?
check "thoát 130 khi bị INT" test "$rc" -eq 130
check "không còn 'sleep 318' mồ côi" no_procs "sleep 318"
check "khoá được nhả sau INT" lock_gone

echo "== hang-kill: quá AXIE_HANG_KILL thì diệt cây, thoát 124"
reset_save
AXIE_HANG_KILL=2 "$WL" bash "$S/suite.sh" 319 >/dev/null 2>&1; rc=$?
check "thoát 124" test "$rc" -eq 124
check "không còn 'sleep 319' mồ côi" no_procs "sleep 319"
check "khoá được nhả" lock_gone

echo "== save được trả lại khi bị TERM giữa chừng"
reset_save
"$WL" bash "$S/writer.sh" 320 >/dev/null 2>&1 & wp=$!
wait_until save_changed || bad "game giả chưa ghi save sau 10s"
check "trong lúc chạy, save đã bị game ghi đè" test "$(cat "$AXIE_SAVE_DIR/meta_save.json")" = CHANGED
kill -TERM "$wp" 2>/dev/null; wait "$wp" 2>/dev/null
check "sau TERM: meta_save.json trả về ORIG" meta_is_orig
check "sau TERM: acct/ trả lại" acct_is_orig
check "sau TERM: run_save.json bị xoá" no_run_save
check "không còn 'sleep 320' mồ côi" no_procs "sleep 320"

echo "== chủ khoá bị SIGKILL: người tiếp quản trả save trước khi chạy"
reset_save
"$WL" bash "$S/writer.sh" 321 >/dev/null 2>&1 & wp=$!
wait_until save_changed || bad "game giả chưa ghi save sau 10s"
kill -9 "$wp" 2>/dev/null; wait "$wp" 2>/dev/null
check "sau SIGKILL, save còn bị ghi (chưa ai trả)" test "$(cat "$AXIE_SAVE_DIR/meta_save.json")" = CHANGED
out="$("$WL" bash -c 'echo next' 2>&1)"
check "người tiếp quản chạy được" grep -q '^next$' <<<"$out"
check "người tiếp quản trả meta_save.json về ORIG" meta_is_orig
check "người tiếp quản trả acct/ về" acct_is_orig
pkill_pids="$(pgrep -f 'sleep 321' || true)"; [[ -n "$pkill_pids" ]] && kill $pkill_pids 2>/dev/null
sleep 0.3

echo "== lồng khoá: AXIE_GODOT_LOCK_HELD=1 tuỳ tiện không được bỏ qua khoá"
reset_save
check "không có khoá trước khi chạy" lock_gone
AXIE_GODOT_LOCK_HELD=1 "$WL" bash -c "test -d '$AXIE_GODOT_LOCK'"; rc=$?
check "HELD=1 không khớp: vẫn giữ khoá (lệnh thấy khoá)" test "$rc" -eq 0

echo "== lồng khoá hợp lệ: lệnh con được chạy thẳng khi pid khớp"
reset_save
out="$(AXIE_LOCK_TIMEOUT=5 "$WL" bash -c "\"$WL\" bash -c 'echo nested-ok'" 2>&1)"; rc=$?
check "lồng đúng pid chạy được không chờ" grep -q 'nested-ok' <<<"$out"
check "lồng đúng pid thoát 0" test "$rc" -eq 0

echo "== cờ skip AXIE_SKIP_RULES_FINGERPRINT bị từ chối ở worktree chính và khi có CI"
R="$S/repo"
mkdir -p "$R/godot/tools" "$R/godot/tests"
cp "$RT" "$WL" "$TOOLS/userdir.sh" "$R/godot/tools/"
printf 'config/name="axie-test-zz"\n' > "$R/godot/project.godot"
: > "$R/godot/tests/t_rules_version.gd"
git -C "$R" init -q
git -C "$R" add godot >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -q -m init >/dev/null 2>&1
out="$(AXIE_SKIP_RULES_FINGERPRINT=1 GODOT=/usr/bin/true bash "$R/godot/tools/run_tests.sh" 2>&1)"; rc=$?
check "worktree chính: cờ bị từ chối (exit 2)" test "$rc" -eq 2
check "worktree chính: có thông báo TỪ CHỐI" grep -q "TỪ CHỐI" <<<"$out"
git -C "$R" worktree add -q "$S/wt" -b wt-test >/dev/null 2>&1
out="$(CI=1 AXIE_SKIP_RULES_FINGERPRINT=1 GODOT=/usr/bin/true bash "$S/wt/godot/tools/run_tests.sh" 2>&1)"; rc=$?
check "có biến CI: cờ bị từ chối ở cả worktree của làn" test "$rc" -eq 2
out="$(AXIE_SKIP_RULES_FINGERPRINT=1 GODOT=/usr/bin/true bash "$S/wt/godot/tools/run_tests.sh" 2>&1)"; rc=$?
check "worktree của làn: cờ được chấp nhận (exit 0)" test "$rc" -eq 0
check "worktree của làn: dòng SKIPPED hiện ra" grep -q "SKIPPED" <<<"$out"
check "khoá nhả sau suite giả" lock_gone

# --- user dir riêng theo override.cfg ---------------------------------------
echo "-- override.cfg / user dir riêng --"
source "$TOOLS/userdir.sh"
P="$S/proj"; mkdir -p "$P"; printf 'config/name="Axie Zz"\n' > "$P/project.godot"
axie_resolve_userdir "$P"
check "không override.cfg: user dir = app_userdata/<config/name>" grep -q "app_userdata/Axie Zz$" <<<"$AXIE_USERDIR"
check "không override.cfg: khoá chung axie-dice-godot.lock" grep -q "axie-dice-godot.lock$" <<<"$AXIE_LOCK_DEFAULT"
printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AxieDice-wt-Q"\n' > "$P/override.cfg"
axie_resolve_userdir "$P"
check "override.cfg: user dir = <base>/AxieDice-wt-Q" grep -Eq "/AxieDice-wt-Q$" <<<"$AXIE_USERDIR"
check "override.cfg: không nằm trong app_userdata" bash -c '! grep -q app_userdata <<<"$1"' _ "$AXIE_USERDIR"
check "override.cfg: khoá riêng axie-dice-godot-AxieDice-wt-Q.lock" grep -q "axie-dice-godot-AxieDice-wt-Q.lock$" <<<"$AXIE_LOCK_DEFAULT"
printf '[application]\nconfig/use_custom_user_dir=false\nconfig/custom_user_dir_name="AxieDice-wt-Q"\n' > "$P/override.cfg"
axie_resolve_userdir "$P"
check "use_custom_user_dir=false: quay về user dir mặc định" grep -q "app_userdata/Axie Zz$" <<<"$AXIE_USERDIR"
# with_lock.sh trong project giả có override.cfg: chụp/trả save ở user dir riêng, không đụng AXIE_*.
FB="$S/fakehome"; mkdir -p "$FB/Library/Caches" "$S/wt2/godot/tools"
cp "$WL" "$TOOLS/userdir.sh" "$S/wt2/godot/tools/"
printf 'config/name="Axie Zz"\n' > "$S/wt2/godot/project.godot"
printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AxieDice-wt-Q"\n' > "$S/wt2/godot/override.cfg"
ud="$FB/Library/Application Support/AxieDice-wt-Q"; [[ "$(uname)" == Darwin ]] || ud="$FB/.local/share/AxieDice-wt-Q"
mkdir -p "$ud"; printf 'WT' > "$ud/meta_save.json"
cat > "$S/wt_writer.sh" <<'EOS'
#!/usr/bin/env bash
printf 'CHANGED' > "$1/meta_save.json"
EOS
( unset AXIE_GODOT_LOCK AXIE_SAVE_DIR; HOME="$FB" XDG_DATA_HOME="$FB/.local/share" bash "$S/wt2/godot/tools/with_lock.sh" bash "$S/wt_writer.sh" "$ud" ) >/dev/null 2>&1
check "worktree override: save của user dir riêng được trả lại" test "$(cat "$ud/meta_save.json")" = WT
check "worktree override: khoá riêng đã nhả" bash -c '[[ ! -e "$1/Library/Caches/axie-dice-godot-AxieDice-wt-Q.lock" ]]' _ "$FB"

echo
echo "================ with_lock_test: $PASS passed, $FAIL failed ================"
[[ $FAIL -eq 0 ]]
