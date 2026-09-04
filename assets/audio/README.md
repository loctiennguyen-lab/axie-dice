# Background music — drop files here

The client loads these lazily at runtime from `assets/audio/`. They are **not**
embedded in the HTML build: audio is the one asset class where the single-file
rule stops paying, since a usable loop is 1-3MB against a 2.4MB page.

## Filenames the client looks for

| File | Role |
|---|---|
| `lunacia-intro.m4a` | plays ONCE per session, then hands off |
| `lunacia-loop.m4a` | loops forever, on every screen |

All three moods (menu / combat / boss) currently point at this one pair, so a
single continuous take runs across the whole session — the way Balatro ships
five "themes" that are really one composition. Give a mood its own file when
there is a second piece of music worth switching to.

The table lives in `MUS`'s `TRACKS` in `src/client.html` (`music.js` section).
Change a name there, not here. A track's `w` trims one file that was mastered
hotter than the others without re-exporting it. `intro` is optional; a track
with no `intro` just starts on its loop.

**Drop a file in and rebuild — no code edit needed** for it to be *allowed*:
`build.py` scans this directory and injects `AUDIO_MANIFEST`, and `MUS` only
requests files the manifest lists. Pointing a mood at a new file is still a
one-line edit to `TRACKS`.

## Why intro + loop, and not one file

The composed build-up is the best part to arrive on and the worst part to hear
every 69 seconds. Measured on the source that shipped here: the body does not
reach full level until 17.2s, so a loop starting earlier sits 33-50% below the
body in RMS, and lifting it to match clips (peaks were already 30k of 32767,
needing a 2x boost). Splitting it solves both — the build plays once, the level
matched body loops.

## Cutting a new loop from a source track

Do these in order; skipping the first one is why the first two attempts here
had an audible seam.

1. **Find the beat grid first.** The shipped source is 117.719 BPM, bar =
   2.0387s, downbeats at 1.0900 + n x 2.0387. Cut only on downbeats and only in
   whole bars, or the groove trips every time the loop wraps.
2. **Match the level at both ends.** Compare a 2s RMS window at the start
   against one at the end. Over ~12% and you hear the loop breathe.
3. **Crossfade the CONTINUATION into the head** — take the audio just past the
   loop end and fade it into the loop's first samples. Fading the loop's tail
   into the audio just *before* the start sounds right on paper and is wrong:
   here that material was still in the quiet build-up and it manufactured a
   23.4% dip.
4. **Use equal-power (sqrt) weights, and keep the crossfade short.** Measured on
   this track: 50ms equal-power left a seam step of 1181 against a p95 of 1405
   for the track's own sample-to-sample steps, i.e. inaudible. A plain butt
   join on the downbeat measured 9438 — 6.7x p95, a clear click. 600ms was
   1484 and lost 3dB in the middle of the fade.

What shipped: intro 5.1675s-17.4000s (6 bars), loop 17.4000s-86.7174s (34
bars), 50ms equal-power crossfade at the loop head.

## Music is optional, by design

Every one of these ends in a silent game that still plays perfectly: no file
present, a `file://` load with no server, a codec the browser refuses, autoplay
denied. A track that fails is marked dead once and never retried — `MUS.sync()`
runs on every render, so retrying would hammer the network all session. The
MUSIC slider in Settings hides itself when no track is playable, rather than
offering a control over silence.

So committing nothing here is a valid state. It is the state today.

### Why the build-time manifest exists

A missing track must produce **no request at all**, not a 404. The browser logs
a failed `<audio>` load itself — that is a browser-level network error, not
something the game's own `try/catch` can swallow — and `verify.mjs` check A11
requires zero console errors. Measured: pointing `TRACKS` at files that do not
exist produced exactly 3 console errors and would have made a green gate
impossible until music shipped. Hence the manifest: the build states what
exists, and the client asks for nothing else.

## Requirements for the files themselves

- **Seamless loop.** No silence at the head or tail; the loop point must not
  click. The client sets `loop=true` and never crossfades a track with itself.
- **Quieter than the SFX.** The 26 SFX in `audio.js` are synthesised at
  `AU.vol` 0.28 and carry gameplay information (hit, crit, warn, kill). Master
  the music so it sits under them at `AU.mvol` 0.55 — if a player has to reach
  for the slider during the first battle, it was mastered too hot.
- **Format**: `.m4a` (AAC) is what shipped — it decodes everywhere including
  Safari, unlike Ogg Vorbis. `.mp3` is equally safe. 44.1kHz at ~128kbps is
  plenty: the music sits *under* the SFX, so it is not where fidelity gets
  noticed. `build.py` also accepts `.ogg` and `.wav`.
- **Repo weight**: 1.3MB shipped as plain git, not LFS. `src/cosmetics.js` is
  already 1.58MB in history, so this is consistent and smaller than what is
  there. Revisit LFS if the soundtrack grows past roughly 10MB, or if this repo
  ever starts being pushed and cloned by other people.
- **Budget**: keep each file at or under ~2MB. It is a separate request, so it
  does not slow first paint, but it is still a download a player on a phone pays
  for.

## Deploy

`vercel.json`'s buildCommand copies `assets/audio/*.mp3`, `*.ogg`, `*.m4a` and
`*.wav` into
`build/assets/audio/`. The copy is deliberately written to tolerate an empty
directory — it must never fail the production build just because no music has
shipped yet.

That extension list is kept identical to `AUDIO_EXT` in `build.py`. If they ever
drift, a file lands in `AUDIO_MANIFEST` but never reaches `build/`, and you get a
404 **in production only** while local dev works — change both or neither.

## Repo weight

`.gitignore` already carries commented-out `*.wav` / `*.mp3` / `*.ogg` rules
under a "use Git LFS instead" note. Committing a few MB of audio to plain git
puts it in history permanently, for every future clone. Decide between plain
git and Git LFS **before** the first audio file lands, because undoing it later
means rewriting history.

## Licensing

This game ships a public ranked leaderboard, so it is a commercial release.
Whatever music lands here needs a licence covering commercial use in a game, in
perpetuity. AI-generated music is a live question — terms differ per service on
whether output may be used commercially and who owns it. Confirm before
shipping, not after.
