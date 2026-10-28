#!/usr/bin/env bash
# LIVE SMOKE against the PRODUCTION Worker (see live_smoke.gd). Not a test: network is on.
#
#   godot/tools/live_smoke.sh            # runs under with_lock.sh, own user dir, 200 s kill timer
#   godot/tools/live_smoke.sh --full     # + resume after quit, offline RETRY, Daily (1 of 3 daily tries); 280 s kill timer
#
# Needs godot/override.cfg (custom_user_dir_name): the run uses THAT user dir, never the desktop app's.
#
# SESSION (28/10 fix): the smoke tool has its OWN device session (its own device_sessions row, its own
# refresh-token chain). It NEVER reads, copies or writes anything of the desktop app's session. History: until
# 27/10 it copied the app's device_tokens.dat and wrote the rotated file back. A refresh token has exactly one
# owner; any rotation whose result is not stored (kill timer / lost response / app file changed -> no write-back,
# --cleanup-only pass, or the app reusing the old token after GRACE_S=45 s) makes the server see a superseded token
# come back and revoke the device (worker/src/desktop_auth.js ~l.103-110) -> Liam signed out, 4 times.
#
# One-time step:   godot/tools/live_smoke.sh --login    (browser opens, sign in with Google, once)
# The smoke tokens live in ${LIVE_SMOKE_TOKENS_DIR:-$HOME/.axie-live-smoke}/device_tokens.dat (encrypted with
# OS.get_unique_id(), this machine only). Each run copies them into the tool's user dir, and copies the rotated
# file back afterwards. If that is ever lost the worst case is that only the smoke device must be re-logged
# (--login); the desktop app stays signed in. The smoke device shows up in the app's device list (/auth/devices).
# Token values are never printed. Costs one of the account's RUNS_PER_DAY (20) slots (two if a fight is lost and retried).
#
# Safety: refuses to start while the desktop app is running (pgrep -f AxieDice.app), on the user dir "Axie Dice", or
# on the real user dir. The tool itself refuses (exit 2) if the account already has an open run (the player's own).
# If Godot dies / is killed / exits non-zero AFTER preflight proved the account clean, a second pass
# (`live_smoke.tscn -- --cleanup-only`, 60 s kill timer) abandons whatever run is still open.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJ="$(cd "$HERE/.." && pwd -P)"
SRC="$HOME/Library/Application Support/Godot/app_userdata/Axie Dice"   # the app's dir: only used to REFUSE, never read
TOK_DIR="${LIVE_SMOKE_TOKENS_DIR:-$HOME/.axie-live-smoke}"
TOK="$TOK_DIR/device_tokens.dat"

if [[ "${1:-}" != "--inner" ]]; then
  exec "$HERE/with_lock.sh" bash "$HERE/live_smoke.sh" --inner "$@"
fi
shift
FULL=0
LOGIN=0
for a in "$@"; do
  case "$a" in
    --full) FULL=1 ;;
    --login) LOGIN=1 ;;
    *) echo "usage: live_smoke.sh [--full | --login]" >&2; exit 2 ;;
  esac
done
KILL_S=200
GODOT_ARGS=()
if [[ "$FULL" == 1 ]]; then
  KILL_S=280   # tool: soft 245 s, hard 255 s (+8 s cleanup), last-resort quit 270 s
  GODOT_ARGS=(-- --full)
  echo "live_smoke: --full also runs resume-after-quit, offline RETRY and Daily (spends 1 of 3 Daily tries)"
fi

# shellcheck source=userdir.sh
source "$HERE/userdir.sh"
axie_resolve_userdir "$PROJ" || { echo "live_smoke: cannot resolve user dir" >&2; exit 2; }
if pgrep -f "AxieDice[.]app/Contents/MacOS/" >/dev/null 2>&1; then   # binary path only: a bare name matches any shell mentioning it
  echo "live_smoke: refusing to run while the desktop app (AxieDice.app) is running; close it first" >&2
  exit 2
fi
if [[ "$(basename "$AXIE_USERDIR")" == "Axie Dice" ]]; then
  echo "live_smoke: refusing to run on the user dir named 'Axie Dice' (the real player's)" >&2
  exit 2
fi
if [[ ! -f "$PROJ/override.cfg" || "$AXIE_USERDIR" == "$SRC" ]]; then
  echo "live_smoke: refusing to run on the real user dir (need godot/override.cfg with custom_user_dir_name)" >&2
  exit 2
fi
for c in "${GODOT:-}" "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" "$PROJ/../tools/bin/Godot_v4.7.2-stable_linux.arm64"; do
  [[ -n "$c" && -x "$c" ]] && { GODOT="$c"; break; }
done
[[ -x "${GODOT:-}" ]] || { echo "live_smoke: Godot not found (set GODOT=)" >&2; exit 2; }
if [[ "$TOK_DIR" == "$SRC" || "$TOK_DIR" == "$SRC"/* ]]; then
  echo "live_smoke: LIVE_SMOKE_TOKENS_DIR must not be the desktop app's dir" >&2; exit 2
fi

UD="$AXIE_USERDIR"
mkdir -p "$UD" "$TOK_DIR"
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json" "$UD/live_smoke_preflight_ok"
if [[ "$LOGIN" == 0 ]]; then
  [[ -f "$TOK" ]] || { echo "live_smoke: no smoke session yet. One-time: godot/tools/live_smoke.sh --login" >&2; exit 2; }
  # Belt and braces: the smoke file must never be a copy of the app's file.
  if [[ -f "$SRC/device_tokens.dat" && "$(shasum "$TOK" | cut -d' ' -f1)" == "$(shasum "$SRC/device_tokens.dat" | cut -d' ' -f1)" ]]; then
    echo "live_smoke: $TOK is identical to the desktop app's token file; refusing (delete it and run --login)" >&2; exit 2
  fi
  cp -p "$TOK" "$UD/device_tokens.dat"
fi
COPIED_SUM="$(shasum "$UD/device_tokens.dat" 2>/dev/null | cut -d' ' -f1)"

if [[ "$LOGIN" == 1 ]]; then
  unset AXIE_TEST_NO_NET
  "$GODOT" --path "$PROJ" res://tools/live_smoke.tscn -- --login
  code=$?
  if [[ "$code" -eq 0 && -f "$UD/device_tokens.dat" ]]; then
    cp -p "$UD/device_tokens.dat" "$TOK.tmp.$$" && mv "$TOK.tmp.$$" "$TOK" && echo "live_smoke: smoke session saved to $TOK"
  fi
  rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json"
  exit "$code"
fi

unset AXIE_TEST_NO_NET
"$GODOT" --headless --path "$PROJ" res://tools/live_smoke.tscn ${GODOT_ARGS[@]+"${GODOT_ARGS[@]}"} &
p=$!
( sleep "$KILL_S"; kill "$p" 2>/dev/null ) & w=$!
wait "$p"; code=$?
kill "$w" 2>/dev/null

# Second pass: first pass died / was killed / failed AFTER preflight proved the account had no open run, so any open
# run is ours. Never after exit 2 (open run = the player's) and never without the marker (preflight not proven).
if [[ "$code" -ne 0 && "$code" -ne 2 && -f "$UD/live_smoke_preflight_ok" ]]; then
  echo "live_smoke: first pass exited $code, running --cleanup-only pass"
  "$GODOT" --headless --path "$PROJ" res://tools/live_smoke.tscn -- --cleanup-only &
  p2=$!
  ( sleep 60; kill "$p2" 2>/dev/null ) & w2=$!
  wait "$p2"; code2=$?
  kill "$w2" 2>/dev/null
  [[ "$code2" -ne 0 ]] && echo "live_smoke: WARNING cleanup-only pass exited $code2; check the account for an open run" >&2
fi

# Token write-back: only into the smoke session's own file (atomic). The desktop app is never involved.
if [[ -f "$UD/device_tokens.dat" ]]; then
  NEW_SUM="$(shasum "$UD/device_tokens.dat" | cut -d' ' -f1)"
  if [[ "$NEW_SUM" != "$COPIED_SUM" ]]; then
    cp -p "$UD/device_tokens.dat" "$TOK.tmp.$$" && mv "$TOK.tmp.$$" "$TOK" && echo "live_smoke: rotated smoke token stored"
  fi
fi
# Leave no session copy behind.
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json" "$UD/live_smoke_preflight_ok"
exit "$code"
