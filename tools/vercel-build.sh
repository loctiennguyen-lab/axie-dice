#!/usr/bin/env bash
# Production build for Vercel. Invoked by vercel.json's buildCommand.
#
# The game is a Godot web export, and Vercel's build container has no Godot and no export
# templates, so the export is produced on a developer machine and this script only stages it.
#
# The export is NOT in git. GitHub rejects any single file over 100 MB and index.pck is around
# 190 MB, so the repository stays source-only and the build is uploaded straight to Vercel:
#
#   godot --path godot --headless --export-release Web    # writes web/
#   vercel --prod                                         # uploads the working directory
#
# `vercel --prod` sends the local working directory, not the git tree, so web/ goes up even
# though git ignores it. api/axie.js ships in the same deploy as a serverless function, which
# is what the browser build needs for Axie import (the GraphQL gateway sends no CORS headers).
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
