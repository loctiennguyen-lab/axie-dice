---
name: music-design-rejection
description: Why the first procedural music pass was rejected (2026-09-04) and what to do differently — no real melody, harsh timbre, no groove, wrong "avoid loop recognition" premise
metadata:
  type: feedback
---

The first music design (bass root notes + static pad + arpeggio over the
same chord, square/sawtooth oscillators, kick every beat + hat every
half-beat) was rejected by the product owner: "khó nghe, không chill, không
gây nghiện, không kích thích." See [[procedural-audio-only]] for the
technical/format follow-up (music moved to real audio files).

**Rules to apply on any future music brief for this project:**

1. **Addictive game music IS a short recognizable loop, not the absence of
   one.** Do not write a brief that asks composers/AI to "avoid sounding
   like a loop" or "hold up for 35 minutes without repeating" — that
   actively prevents a hook from forming. Reference: Balatro's main theme
   is a ~2min loop repeated the whole run and that's exactly why it works.
2. **An arpeggio over a chord is NOT a melody.** Every track needs an
   explicit, singable motif/hook (a short phrase with real melodic contour
   — leaps, held notes, a memorable rhythm) distinct from the harmonic
   accompaniment. Call this out explicitly in briefs, don't assume it's
   implied by "add a lead instrument."
3. **Raw/unfiltered waveforms (square, sawtooth) read as harsh, not
   "synthetic/cool."** If synthesis is used, low-pass filter and shape
   envelopes; for real recordings this isn't an issue but still ask for
   "warm/filtered" over "bright/raw" in dark-mysterious contexts.
4. **Groove requires contrast, not density.** Percussion on literally every
   beat/subdivision reads as a metronome, not a groove. Ask for syncopation,
   rests, and dynamic accents instead of maximal hit density.
5. Game is turn-based/deterministic with 0% hidden info (player thinks,
   doesn't react) — combat music should support calm calculation, not push
   arcade urgency. "Dark/mysterious" was chosen as the target palette
   (matches Chimera/Lunacia theme, `#3c081b`) over "adrenaline/aggressive."

**How to apply:** when scoping any new music brief (for a composer or an
AI music service like Suno/Udio), explicitly require (1) a named motif/hook
description, (2) loop length framed as "this repeats for the whole run,
make it a hook" rather than "avoid repetition fatigue," and (3) filtered/
warm timbre language for dark-mysterious cues.
