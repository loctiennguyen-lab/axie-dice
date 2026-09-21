#!/usr/bin/env bash
# Production build for Vercel. Invoked by vercel.json's buildCommand.
#
# The game is a Godot web export, and Vercel's build container has no Godot and no export
# templates. So the export is produced on a developer machine and COMMITTED under web/, and
# this script only stages it. Re-export before deploying:
#
#   godot --path godot --headless --export-release Web
#   git add -f web/ && git commit -m "web: re-export"
#
# Verify locally with:  bash tools/vercel-build.sh && ls -R build
set -euo pipefail

OUT=build
SRC=web

if [ ! -f "$SRC/index.html" ]; then
  echo "vercel-build: $SRC/index.html is missing. Export the Web preset and commit it." >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$SRC"/. "$OUT"/

# Godot's web export needs cross-origin isolation for SharedArrayBuffer (threads). Vercel
# reads these from vercel.json, not from here; this is the reminder that removing them breaks
# the build at runtime rather than at deploy time.
echo "vercel-build: staged $(find "$OUT" -type f | wc -l | tr -d ' ') file(s) -> $OUT"
