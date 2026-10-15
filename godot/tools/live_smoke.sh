#!/usr/bin/env bash
# LIVE SMOKE against the PRODUCTION Worker (see live_smoke.gd). Not a test: network is on.
#
#   godot/tools/live_smoke.sh            # runs under with_lock.sh, own user dir, 200 s kill timer
#
# Needs godot/override.cfg (custom_user_dir_name): the run uses THAT user dir, never the desktop app's. Only
# account.json, account_prefs.json, device_tokens.dat and acct/ are copied in from
#   ~/Library/Application Support/Godot/app_userdata/Axie Dice/
# device_tokens.dat is encrypted with OS.get_unique_id() (machine, not folder), so the copy decrypts here.
# Refresh tokens ROTATE: if the run refreshed, the desktop app's old token would be revoked after the grace
# window. So when the tool's token file changed AND the desktop app's file is still byte-identical to what we
# copied, the new file is written back (atomic mv). Set LIVE_SMOKE_NO_WRITEBACK=1 to skip.
# Token values are never printed. Costs one of the account's RUNS_PER_DAY (20) slots.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJ="$(cd "$HERE/.." && pwd -P)"
SRC="${LIVE_SMOKE_SRC_DIR:-$HOME/Library/Application Support/Godot/app_userdata/Axie Dice}"

if [[ "${1:-}" != "--inner" ]]; then
  exec "$HERE/with_lock.sh" bash "$HERE/live_smoke.sh" --inner
fi

# shellcheck source=userdir.sh
source "$HERE/userdir.sh"
axie_resolve_userdir "$PROJ" || { echo "live_smoke: cannot resolve user dir" >&2; exit 2; }
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
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json"
for f in account.json account_prefs.json device_tokens.dat; do
  [[ -e "$SRC/$f" ]] && cp -p "$SRC/$f" "$UD/$f"
done
[[ -d "$SRC/acct" ]] && cp -Rp "$SRC/acct" "$UD/acct"
COPIED_SUM="$(shasum "$SRC/device_tokens.dat" | cut -d' ' -f1)"

unset AXIE_TEST_NO_NET
"$GODOT" --headless --path "$PROJ" res://tools/live_smoke.tscn &
p=$!
( sleep 200; kill "$p" 2>/dev/null ) & w=$!
wait "$p"; code=$?
kill "$w" 2>/dev/null

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
rm -rf "$UD/acct" "$UD/account.json" "$UD/account_prefs.json" "$UD/device_tokens.dat" "$UD/account_sync.json" "$UD/meta_save.json" "$UD/run_save.json"
exit "$code"
