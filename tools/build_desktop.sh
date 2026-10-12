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
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-macos.zip   (AxieDice.app, x86_64)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-macos.dmg   (same app, disk image)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty]-windows.zip (AxieDice.exe, x86_64, pck embedded)
#   build/AxieDice-<version>-b<build>-<hash>[-dirty].sha256
#   build/AxieDice-<version>-b<build>-<hash>[-dirty].BUILD_INFO.txt
#
# Nothing here signs, notarizes, uploads or deploys. Every artifact is unsigned (macOS gets an
# ad-hoc signature, which Apple Silicon needs in order to run the binary at all). Testers open
# them by hand; see production/qa/l1-install-guide.md.
#
# Every Godot call goes through godot/tools/with_lock.sh (one global lock for all worktrees,
# because they share user://). Hang watchdog: AXIE_HANG_KILL, default 1200s per Godot call.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

APP_VERSION="${APP_VERSION:-0.1.0}"          # marketing version, written into the presets
LABEL="${BUILD_LABEL:-L1}"                    # prefix tag for the artifact name
WHAT="${1:-all}"
case "$WHAT" in all|macos|windows) ;; *) echo "usage: $0 [all|macos|windows]" >&2; exit 64 ;; esac

GODOT="${GODOT_OVERRIDE:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
LOCK_WRAP="$ROOT/godot/tools/with_lock.sh"
export AXIE_SKIP_RULES_FINGERPRINT=1
export AXIE_LANE="${AXIE_LANE:-R}"
HANG="${AXIE_HANG_KILL:-1200}"

die() { echo "build_desktop: $*" >&2; exit 1; }

[[ -x "$GODOT" ]] || die "Godot binary not found at $GODOT (set GODOT_OVERRIDE)"
[[ -f "$LOCK_WRAP" ]] || die "missing $LOCK_WRAP"

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

# --- 1. export templates present? ------------------------------------------------------------
TPL="$HOME/Library/Application Support/Godot/export_templates/$("$GODOT" --version 2>/dev/null | head -1 | cut -d. -f1-3).stable"
[[ -f "$TPL/macos.zip" ]] || die "macOS export template missing at $TPL/macos.zip (Editor > Manage Export Templates)"
[[ -f "$TPL/windows_release_x86_64.exe" ]] || die "Windows export template missing at $TPL/windows_release_x86_64.exe"

# --- 2. import (a fresh worktree has no .godot/ cache; exports fail without it) ---------------
if [[ ! -f "$ROOT/godot/.godot/global_script_class_cache.cfg" ]]; then
  echo "-- import (no .godot cache yet)"
  AXIE_HANG_KILL="$HANG" "$LOCK_WRAP" "$GODOT" --headless --path "$ROOT/godot" --import \
    > "$STAGE/import.log" 2>&1 || true
fi

export_one() {   # $1 = preset name, $2 = output path (.app or .exe)
  local preset="$1" dest="$2" log="$STAGE/export-$1.log"
  AXIE_HANG_KILL="$HANG" "$LOCK_WRAP" "$GODOT" --headless --path "$ROOT/godot" \
    --export-release "$preset" "$dest" > "$log" 2>&1
  local rc=$?
  if grep -qiE "SCRIPT ERROR|Parse Error|ERROR:" "$log"; then
    echo "   export log has errors, see $log" >&2
    grep -iE "SCRIPT ERROR|Parse Error|ERROR:" "$log" | head -5 >&2
    return 1
  fi
  [[ $rc -eq 0 ]] || { echo "   godot exit $rc, see $log" >&2; return 1; }
  [[ -e "$dest" ]] || { echo "   no output at $dest, see $log" >&2; return 1; }
  return 0
}

# --- 3. macOS --------------------------------------------------------------------------------
if [[ "$WHAT" == all || "$WHAT" == macos ]]; then
  echo "-- macOS export (x86_64, ad-hoc signed; runs on Apple Silicon via Rosetta)"
  MAC_APP="$STAGE/AxieDice.app"
  export_one macOS "$MAC_APP" || die "macOS export failed"
  # Sanity: both slices present, and the ad-hoc signature verifies.
  ARCHS="$(lipo -archs "$MAC_APP/Contents/MacOS/"* 2>/dev/null)"
  echo "   archs: ${ARCHS:-unknown}"
  codesign --verify --deep --strict "$MAC_APP" 2>>"$STAGE/codesign.log" \
    && echo "   codesign verify: ok (ad-hoc)" || echo "   codesign verify: FAILED, see $STAGE/codesign.log" >&2
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
  WZIP="$OUT/${STAMP}-windows.zip"; rm -f "$WZIP"
  ( cd "$WIN_DIR" && zip -q -9 "$WZIP" AxieDice.exe ) || die "zip (windows) failed"
  echo "   zip: $(du -h "$WZIP" | cut -f1)  $WZIP"
fi

# --- 5. checksums + build info ---------------------------------------------------------------
( cd "$OUT" && shasum -a 256 "${STAMP}"-*.zip "${STAMP}"-*.dmg 2>/dev/null > "${STAMP}.sha256" )
cat > "$OUT/${STAMP}.BUILD_INFO.txt" <<EOF
Axie Dice L1 internal build (unsigned)
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
