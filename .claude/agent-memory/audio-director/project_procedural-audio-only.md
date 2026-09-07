---
name: procedural-audio-only
description: SFX stay procedural (Web Audio) in src/client.html; MUSIC is no longer procedural-only — real .ogg/.mp3 files lazy-loaded from server are now approved (reversed 2026-09-04)
metadata:
  type: project
---

**UPDATE 2026-09-04 — reversed for music.** The product owner playtested the
procedural music system (oscillator bass/pad/arpeggio, 0-byte asset) and
rejected it: "khó nghe, không chill, không gây nghiện, không kích thích."
Diagnosis: no real melody (arpeggios ≠ motif), harsh raw-waveform timbre, no
groove, and the "must not be recognizable as a loop" brief was backwards —
addictive game music (Balatro, Hades) IS a short recognizable loop repeated
for the whole run.

**Current rule:** music may now ship as real audio files (`.ogg`/`.mp3`),
lazy-loaded from the server, NOT embedded/base64'd into `src/client.html`.
This keeps the single-HTML-file budget intact for the client shell while
lifting the constraint specifically for music. **SFX remain procedural** —
the 26 existing `SFX` one-shots via `AU`/`ac()`/`env()`/`tone()`/`noise()`
stay as Web Audio synthesis; do not propose replacing them with files.

Original rationale below (still applies to SFX and to the HTML shell itself,
not to music anymore):

The game ships as a single self-contained HTML file (`src/client.html`,
~2.4MB as of 2026-09). There is no audio asset pipeline for SFX and none
should be added there: no mp3/wav/ogg, no base64-embedded audio, no
`<audio>` tags with external sources for SFX. Every SFX must be generated at
runtime with the Web Audio API.

Existing infra to reuse, not rewrite (`src/client.html` around line 1409-1459):
`AU` (state: `ctx`, `on`, `vol`), `ac()` (lazy AudioContext init, gesture-gated
per browser autoplay policy), `env()` (ADSR gain envelope), `tone()`/`noise()`
(oscillator/filtered-noise one-shots used by the `SFX` object), and `SFX`
itself (26 named one-shot cues).

**Why:** the project's explicit architectural goal is a single portable HTML
file with no bundler/build dependency for the client half; any embedded audio
media would blow the file-size budget disproportionately (a single music loop
would add several MB against a 2.4MB baseline) and contradicts the pinned
"Custom — no game engine" / vanilla-JS-single-file stance in
`.claude/docs/technical-preferences.md`.

**How to apply:** new SFX must still be proposed as procedural Web Audio
synthesis (route through `AU`/`ac()`/`env()`, not a file). New MUSIC should
be scoped as real audio files (dark/mysterious tone, Chimera/Lunacia theme,
`#3c081b` palette) with its own gain bus separate from SFX's `AU.vol` so
combat-critical SFX always cut through. The superseded 2026-09-04 procedural
music design (D Mixolydian/Aeolian/Phrygian-Dominant modes, `MUS.sync()` in
`render()`) is historical context only — do not re-propose it as-is; its
"avoid a recognizable loop" premise was the root cause of the rejection.
Any code to load/mix the new audio files should still be handed over as a
paste-in code block, not written directly, per
[[no-direct-edit-when-user-editing]].
