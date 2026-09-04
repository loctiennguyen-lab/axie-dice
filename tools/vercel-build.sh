#!/usr/bin/env bash
# Production build for Vercel. Invoked by vercel.json's buildCommand.
#
# This lives in a file rather than inline in vercel.json because Vercel caps
# `projectSettings.buildCommand` at 256 characters, and the inline chain hit 293
# once the audio copy was added — the deploy failed with "Invalid request:
# projectSettings.buildCommand should NOT be longer than 256 characters".
# Being a real script also means it can be run and verified locally, which the
# inline version could not.
#
# Verify locally with:  bash tools/vercel-build.sh && ls -R build
set -euo pipefail

OUT=build

mkdir -p "$OUT"

# `public` strips src/devtools.js — devGo() can jump to any screen and grant
# shards/relics, so it must never reach a build serving the ranked leaderboard.
python3 build.py public
mv -f index.html "$OUT/index.html"

cp tools/admin-dashboard.html "$OUT/admin-dashboard.html"

# Music is an external asset (see assets/audio/README.md), so it is copied rather
# than embedded. The extension list must stay identical to AUDIO_EXT in build.py:
# if they drift, a file lands in AUDIO_MANIFEST but never reaches the output, and
# the 404 shows up in production only while local dev looks fine.
#
# The copy tolerates an empty directory on purpose. No music shipped is a valid
# state, and it must never fail the production build.
mkdir -p "$OUT/assets/audio"
shopt -s nullglob
audio=(assets/audio/*.mp3 assets/audio/*.ogg assets/audio/*.m4a assets/audio/*.wav)
if [ ${#audio[@]} -gt 0 ]; then
  cp "${audio[@]}" "$OUT/assets/audio/"
  echo "vercel-build: copied ${#audio[@]} audio file(s)"
else
  echo "vercel-build: no audio files present (valid — the game plays silently)"
fi
shopt -u nullglob

echo "vercel-build: done -> $OUT"
