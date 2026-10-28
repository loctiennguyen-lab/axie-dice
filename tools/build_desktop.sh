#!/usr/bin/env bash
# Build the unsigned desktop artifacts for the L1 internal test (macOS + Windows).
#
# Usage:
#   bash tools/build_desktop.sh              # both platforms
#   bash tools/build_desktop.sh macos        # only the Mac build
#   bash tools/build_desktop.sh windows      # only the Windows build
#   GODOT_OVERRIDE=/path/to/Godot bash tools/build_desktop.sh
#
# Output goes to build/ (gitignored) at the repo root:
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-macos.zip   (AxieDice.app, universal)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-macos.dmg   (same app, disk image)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-windows.zip (AxieDice.exe, x86_64, pck embedded)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty].sha256
#   build/AxieDice-<version>-b<build>-<hash>[-dirty].BUILD_INFO.txt
#
# Optional signing (OFF by default; today's flow is unchanged when the flags are unset):
#   AXIE_NOTARIZE_MAC=1   Developer ID sign + notarize + staple the .app before zip/dmg (tools/notarize_mac.sh)
#   AXIE_SIGN_WINDOWS=1   Authenticode-sign AxieDice.exe before zip (tools/sign_windows.sh)
# Both run a prerequisite check BEFORE the long export, so a missing cert fails in seconds. Credentials
# come only from the keychain / env, never from this repo; see production/release/signing-setup.md.
#
# Nothing here uploads or deploys. Without the flags above every artifact is unsigned (macOS gets an
# ad-hoc signature, which Apple Silicon needs in order to run the binary at all). Testers open
# them by hand; see production/qa/l1-install-guide.md.
#
# Every Godot call goes through godot/tools/with_lock.sh (one global lock for all worktrees,
# because they share user://). Hang watchdog: AXIE_HANG_KILL, default 1200s per Godot call.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

APP_VERSION="${APP_VERSION:-0.1.0}"          # marketing version; must equal application/short_version in godot/export_presets.cfg (checked below)
LABEL="${BUILD_LABEL:-L1}"                    # prefix tag for the artifact name
WHAT="${1:-all}"
case "$WHAT" in all|macos|windows) ;; *) echo "usage: $0 [all|macos|windows]" >&2; exit 64 ;; esac

GODOT="${GODOT_OVERRIDE:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
LOCK_WRAP="$ROOT/godot/tools/with_lock.sh"
export AXIE_SKIP_RULES_FINGERPRINT=1
export AXIE_LANE="${AXIE_LANE:-R}"
HANG="${AXIE_HANG_KILL:-1200}"

die() { echo "build_desktop: $*" >&2; exit 1; }

# Guard: a temp override.cfg (written by with_lock.sh during a test run in the main tree) must never be
# packed into a shipped build. Its user dir is the test one, so the build would silently ignore Liam's save.
guard_no_temp_override() {
  local cfg="$ROOT/godot/override.cfg"
  if [[ -f "$cfg" ]] && grep -qF "axie-temp-override" "$cfg"; then
    die "godot/override.cfg is a TEMP test override (axie-temp-override) written by a running test. Wait for it to finish (it removes the file itself), then run again. Do not ship it."
  fi
}
"$ROOT/godot/tools/clean_stale_override.sh" || true
guard_no_temp_override

[[ -x "$GODOT" ]] || die "Godot binary not found at $GODOT (set GODOT_OVERRIDE)"
[[ -f "$LOCK_WRAP" ]] || die "missing $LOCK_WRAP"

# Optional signing flags (off unless exactly "1"). Preflight now, before the 10+ minute export.
SIGN_MAC=0; SIGN_WIN=0
[[ "${AXIE_NOTARIZE_MAC:-0}" == 1 ]] && SIGN_MAC=1
[[ "${AXIE_SIGN_WINDOWS:-0}" == 1 ]] && SIGN_WIN=1
if [[ $SIGN_MAC -eq 1 && ( "$WHAT" == all || "$WHAT" == macos ) ]]; then
  bash "$ROOT/tools/notarize_mac.sh" --dry-run --check-profile || die "AXIE_NOTARIZE_MAC=1 but prerequisites are missing (see above)"
fi
if [[ $SIGN_WIN -eq 1 && ( "$WHAT" == all || "$WHAT" == windows ) ]]; then
  bash "$ROOT/tools/sign_windows.sh" --dry-run || die "AXIE_SIGN_WINDOWS=1 but prerequisites are missing (see above)"
fi

# --- 0. version stamp ------------------------------------------------------------------------
HASH="$(git rev-parse --short HEAD 2>/dev/null)" || die "not a git checkout"
BUILD_NO="$(git rev-list --count HEAD)"
DIRTY=""
if [[ -n "$(git status --porcelain --untracked-files=no -- godot tools 2>/dev/null)" ]]; then
  DIRTY="-dirty"
fi
STAMP="AxieDice-${APP_VERSION}-${LABEL}-b${BUILD_NO}-${HASH}${DIRTY}"
OUT="$ROOT/build"
STAGE="$OUT/.stage-${HASH}"
mkdir -p "$OUT"
rm -rf "$STAGE"; mkdir -p "$STAGE"

echo "== $STAMP  ($WHAT)"
echo "   godot: $GODOT ($("$GODOT" --version 2>/dev/null | head -1))"

# Presets hold the version that ends up in Info.plist / the exe resources; the script does not edit
# them. Fail loudly instead of shipping a file name that disagrees with the app's own version.
grep -q "^application/short_version=\"${APP_VERSION}\"" "$ROOT/godot/export_presets.cfg" \
  || die "APP_VERSION=$APP_VERSION does not match application/short_version in godot/export_presets.cfg (edit both)"

# --- 1. export templates present? ------------------------------------------------------------
TPL="$HOME/Library/Application Support/Godot/export_templates/$("$GODOT" --version 2>/dev/null | head -1 | cut -d. -f1-3).stable"
[[ -f "$TPL/macos.zip" ]] || die "macOS export template missing at $TPL/macos.zip (Editor > Manage Export Templates)"
[[ -f "$TPL/windows_release_x86_64.exe" ]] || die "Windows export template missing at $TPL/windows_release_x86_64.exe"

# --- 2. import (a fresh worktree has no .godot/ cache; exports fail without it) ---------------
if [[ ! -f "$ROOT/godot/.godot/global_script_class_cache.cfg" ]]; then
  echo "-- import (no .godot cache yet)"
  AXIE_REAL_USERDIR=1 AXIE_GUARD_SAVE=0 AXIE_HANG_KILL="$HANG" "$LOCK_WRAP" "$GODOT" --headless --path "$ROOT/godot" --import \
    > "$STAGE/import.log" 2>&1 || true
fi

export_one() {   # $1 = preset name, $2 = output path (.app or .exe)
  local preset="$1" dest="$2" log="$STAGE/export-$1.log"
  guard_no_temp_override
  # Export does not run the game and needs no test isolation. AXIE_REAL_USERDIR=1 keeps with_lock.sh
  # from writing a temp override.cfg into godot/ during the export (the pck would carry it), and
  # AXIE_GUARD_SAVE=0 stops with_lock.sh from snapshotting and restoring Liam's real save around a
  # build, which could overwrite progress made while the build runs.
  AXIE_REAL_USERDIR=1 AXIE_GUARD_SAVE=0 AXIE_HANG_KILL="$HANG" "$LOCK_WRAP" "$GODOT" --headless --path "$ROOT/godot" \
    --export-release "$preset" "$dest" > "$log" 2>&1
  local rc=$?
  if grep -qiE "SCRIPT ERROR|Parse Error|ERROR:" "$log"; then
    echo "   export log has errors, see $log" >&2
    grep -iE "SCRIPT ERROR|Parse Error|ERROR:" "$log" | head -5 >&2
    return 1
  fi
  [[ $rc -eq 0 ]] || { echo "   godot exit $rc, see $log" >&2; return 1; }
  [[ -e "$dest" ]] || { echo "   no output at $dest, see $log" >&2; return 1; }
  # Backstop: preset loại override.cfg, nhưng test có thể ghi override tạm giữa guard và export
  # (build giữ khoá thật, test giữ khoá -test-). Quét chính gói vừa xuất.
  python3 -I "$ROOT/godot/tools/check_export_no_override.py" "$dest" || { echo "   backstop: override.cfg trong $dest, không đóng gói" >&2; return 1; }
  return 0
}

# --- 3. macOS --------------------------------------------------------------------------------
if [[ "$WHAT" == all || "$WHAT" == macos ]]; then
  echo "-- macOS export (universal, ad-hoc signed)"
  MAC_APP="$STAGE/AxieDice.app"
  export_one macOS "$MAC_APP" || die "macOS export failed"
  # Sanity: both slices present, and the ad-hoc signature verifies.
  ARCHS="$(lipo -archs "$MAC_APP/Contents/MacOS/"* 2>/dev/null)"
  echo "   archs: ${ARCHS:-unknown}"
  codesign --verify --deep --strict "$MAC_APP" 2>>"$STAGE/codesign.log" \
    && echo "   codesign verify: ok (ad-hoc)" || echo "   codesign verify: FAILED, see $STAGE/codesign.log" >&2
  if [[ $SIGN_MAC -eq 1 ]]; then
    echo "-- macOS: Developer ID sign + notarize + staple (tools/notarize_mac.sh)"
    bash "$ROOT/tools/notarize_mac.sh" --app "$MAC_APP" || die "notarization failed (the ad-hoc build is NOT shipped; fix and re-run)"
  fi
  # ditto keeps the exec bit, symlinks and resource forks; plain `zip` can break the .app.
  ZIP="$OUT/${STAMP}-macos.zip"
  rm -f "$ZIP"
  ditto -c -k --sequesterRsrc --keepParent "$MAC_APP" "$ZIP" || die "ditto zip failed"
  echo "   zip: $(du -h "$ZIP" | cut -f1)  $ZIP"
  # Disk image (optional, same app). hdiutil is part of macOS, nothing downloaded.
  DMG_DIR="$STAGE/dmg"; mkdir -p "$DMG_DIR"; cp -R "$MAC_APP" "$DMG_DIR/"
  ln -s /Applications "$DMG_DIR/Applications"
  DMG="$OUT/${STAMP}-macos.dmg"; rm -f "$DMG"
  if hdiutil create -volname "Axie Dice L1" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG" \
       > "$STAGE/hdiutil.log" 2>&1; then
    echo "   dmg: $(du -h "$DMG" | cut -f1)  $DMG"
  else
    echo "   dmg FAILED, see $STAGE/hdiutil.log (zip is still good)" >&2
  fi
fi

# --- 4. Windows ------------------------------------------------------------------------------
if [[ "$WHAT" == all || "$WHAT" == windows ]]; then
  echo "-- Windows export (x86_64, pck embedded, unsigned)"
  WIN_DIR="$STAGE/win"; mkdir -p "$WIN_DIR"
  export_one "Windows" "$WIN_DIR/AxieDice.exe" || die "Windows export failed"
  file "$WIN_DIR/AxieDice.exe" | grep -q "PE32+.*x86-64" \
    && echo "   PE check: x86_64 ok" || echo "   PE check: NOT x86_64 PE32+, check the file" >&2
  if [[ $SIGN_WIN -eq 1 ]]; then
    echo "-- Windows: Authenticode sign (tools/sign_windows.sh)"
    bash "$ROOT/tools/sign_windows.sh" "$WIN_DIR/AxieDice.exe" || die "Windows signing failed"
    rm -f "$WIN_DIR/AxieDice.exe.unsigned"
  fi
  WZIP="$OUT/${STAMP}-windows.zip"; rm -f "$WZIP"
  ( cd "$WIN_DIR" && zip -q -9 "$WZIP" AxieDice.exe ) || die "zip (windows) failed"
  echo "   zip: $(du -h "$WZIP" | cut -f1)  $WZIP"
fi

# --- 5. checksums + build info ---------------------------------------------------------------
( cd "$OUT" && shasum -a 256 "${STAMP}"-*.zip "${STAMP}"-*.dmg 2>/dev/null > "${STAMP}.sha256" )
cat > "$OUT/${STAMP}.BUILD_INFO.txt" <<EOF
Axie Dice L1 internal build (signing: mac=$([[ $SIGN_MAC -eq 1 ]] && echo notarized || echo ad-hoc), windows=$([[ $SIGN_WIN -eq 1 ]] && echo signed || echo unsigned))
version:   ${APP_VERSION}
build:     ${BUILD_NO}   (git rev-list --count HEAD)
commit:    $(git rev-parse HEAD)${DIRTY:+   (working tree had local changes under godot/ or tools/)}
built:     $(date '+%Y-%m-%d %H:%M:%S %z')
host:      $(sw_vers -productVersion 2>/dev/null) $(uname -m)
godot:     $("$GODOT" --version 2>/dev/null | head -1)
artifacts:
$(ls -1 "$OUT" | grep "^${STAMP}" | sed 's/^/  /')
EOF
rm -rf "$STAGE"
echo "== done. Artifacts in $OUT:"
ls -lh "$OUT" | grep "$STAMP" || true
