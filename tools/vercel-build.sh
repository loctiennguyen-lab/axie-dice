#!/usr/bin/env bash
# Vercel build. Invoked by vercel.json's buildCommand.
#
# VERCEL SERVES THE API, NOT THE GAME. Both GitHub and Vercel refuse any single file over
# 100 MB, and the Godot web export's index.pck is 189 MB, so the playable build lives on
# itch.io instead. What stays here is api/axie.js, the Axie lookup proxy the browser build
# cannot do without: the Axie GraphQL gateway sends no CORS headers, so the game calls this
# instead. It answers with Access-Control-Allow-Origin: *, which is why the game can be
# hosted on a completely different domain.
#
# So this build produces an almost-empty static directory on purpose. Vercel picks up
# api/*.js as serverless functions by itself; `build/` only exists because a static output
# directory has to.
set -euo pipefail

OUT=build
rm -rf "$OUT"
mkdir -p "$OUT"

cat > "$OUT/index.html" <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>Axie Dice</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  :root { color-scheme: dark; }
  body { margin:0; min-height:100vh; display:grid; place-items:center;
         background:#13161B; color:#EDEFF5;
         font:16px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif; }
  main { max-width:32rem; padding:2rem; text-align:center; }
  h1 { font-size:1.75rem; margin:0 0 .5rem; color:#FF9345; }
  p { color:#EDEFF5B0; margin:.5rem 0; }
  code { background:#1B1F27; padding:.15em .4em; border-radius:4px; }
</style>
<main>
  <h1>Axie Dice</h1>
  <p>This host runs the Axie lookup proxy at <code>/api/axie</code>. It does not serve the game.</p>
  <p>The playable build is on itch.io, and the source is on GitHub.</p>
</main>
HTML

echo "vercel-build: api-only deployment staged -> $OUT"
