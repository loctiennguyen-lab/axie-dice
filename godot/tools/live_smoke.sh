#!/usr/bin/env bash
# LIVE SMOKE against the PRODUCTION Worker (see live_smoke.gd). Not a test: network is on.
#
#   godot/tools/live_smoke.sh            # runs under with_lock.sh, own user dir, 200 s kill timer
#   godot/tools/live_smoke.sh --full     # + resume after quit, offline RETRY, Daily (1 of 3 daily tries); 280 s kill timer
#
# Needs godot/override.cfg (custom_user_dir_name): the run uses THAT user dir, never the desktop app's. Only
# account.json, account_prefs.json, device_tokens.dat and acct/ are copied in from
#   ~/Library/Application Support/Godot/app_userdata/Axie Dice/
# device_tokens.dat is encrypted with OS.get_unique_id() (machine, not folder), so the copy decrypts here.
# Refresh tokens ROTATE: if the run refreshed, the desktop app's old token would be revoked after the grace
# window. So when the tool's token file changed AND the desktop app's file is still byte-identical to what we
# copied, the new file is written back (atomic mv). Set LIVE_SMOKE_NO_WRITEBACK=1 to skip.
# Token values are never printed. Costs one of the account's RUNS_PER_DAY (20) slots (two if a fight is lost and retried).
#
# Safety: refuses to start while the desktop app is running (pgrep -f AxieDice.app), on the user dir "Axie Dice", or
# on the real user dir. The tool itself refuses (exit 2) if the account already has an open run (the player's own).
# If Godot dies / is killed / exits non-zero AFTER preflight proved the account clean, a second pass
# (`live_smoke.tscn -- --cleanup-only`, 60 s kill timer) abandons whatever run is still open.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJ="$(cd "$HERE/.." && pwd -P)"
SRC="${LIVE_SMOKE_SRC_DIR:-$HOME/Library/Application Support/Godot/app_userdata/Axie Dice}"

if [[ "${1:-}" != "--inner" ]]; then
  exec "$HERE/with_lock.sh" bash "$HERE/live_smoke.sh" --inner "$@"
fi
shift
FULL=0
for a in "$@"; do
  case "$a" in
    --full) FULL=1 ;;
    *) echo "usage: live_smoke.sh [--full]" >&2; exit 2 ;;
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
[[ -f "$SRC/device_tokens.dat" ]] || { echo "live_smoke: no session to copy: $SRC/device_tokens.dat (sign in on the desktop app first)" >&2; exit 2; }

UD="$AXIE_USERDIR"
mkdir -p "$UD"
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json" "$UD/live_smoke_preflight_ok"
for f in account.json account_prefs.json device_tokens.dat; do
  [[ -e "$SRC/$f" ]] && cp -p "$SRC/$f" "$UD/$f"
done
[[ -d "$SRC/acct" ]] && cp -Rp "$SRC/acct" "$UD/acct"
COPIED_SUM="$(shasum "$SRC/device_tokens.dat" | cut -d' ' -f1)"

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

# Token write-back (see header).
if [[ "${LIVE_SMOKE_NO_WRITEBACK:-}" != 1 && -f "$UD/device_tokens.dat" ]]; then
  NEW_SUM="$(shasum "$UD/device_tokens.dat" | cut -d' ' -f1)"
  NOW_SUM="$(shasum "$SRC/device_tokens.dat" | cut -d' ' -f1)"
  if [[ "$NEW_SUM" != "$COPIED_SUM" ]]; then
    if [[ "$NOW_SUM" == "$COPIED_SUM" ]]; then
      cp -p "$UD/device_tokens.dat" "$SRC/device_tokens.dat.tmp.$$" && mv "$SRC/device_tokens.dat.tmp.$$" "$SRC/device_tokens.dat" \
        && echo "live_smoke: rotated device token written back to the desktop app"
    else
      echo "live_smoke: WARNING token rotated but the desktop app's file changed meanwhile; not overwriting. The app may need a new sign-in." >&2
    fi
  fi
fi
# Leave no session copy behind.
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json" "$UD/live_smoke_preflight_ok"
exit "$code"
