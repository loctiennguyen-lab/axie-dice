# UX Research: Faction & Threat-Tier Legibility (Combat/Boss Screens)

Status: research/options only — no code written, no decision made.
Author: ux-designer (subagent) · 2026-09-09

## 1. Problem Restatement

On `devGo('combat')` and `devGo('boss')`, a first-time viewer cannot quickly tell:
(a) which row is "mine" vs. "the enemy's", and
(b) which enemy card is the boss vs. a normal mob.

Confirmed by reading current source, not just the audit doc:

- `src/client.html` **does** already give `.unit.p` a 3px bottom border in
  `var(--cc)` (per-hero class color) and `.unit.e` a 3px top border in
  `var(--dmg)` (red). This is a real but *very subtle* faction cue — 3px on a
  ~280px-wide card, at opposite edges, easy to miss at a glance, and it reuses
  `--dmg` (the same red already used for damage numbers/crit), so it competes
  with other meanings rather than reading cleanly as "faction color."
- The HP bar itself (`.hpfill`, `--hp-full/--hp-low/--hp-crit`, `client.html`
  ~L107-847) is danger-tier-only (green→yellow→red by %HP) and is **identical
  on both rows** — this is exactly audit finding P0-3, and it is **still
  unresolved**.
- Boss styling (`.unit.big`, L781) is only `width:290px` + red border reused
  from `.unit.e` — no banner, no name-card, no distinct color identity, no
  screen-level framing. A boss currently reads as "a bigger mob," not "the
  boss."
- `design/gdd/onboarding-tutorial.md` was grepped for `boss|team|faction|VS`
  — zero matches. The mandatory tutorial teaches roll→reroll→execute→end
  turn, but never teaches "top row = enemy, bottom row = you, this centered
  card = the boss."

## 2. Reference Patterns (verified, not invented)

- **Clash Royale**: strict color theming — player side = blue troop
  outlines/UI, opponent side = red, reinforced by the lane/river split and a
  blue/red king-tower color at each end of the board. Color + spatial split
  are redundant with each other, not the only cue.
- **Hearthstone**: player's hero portrait/board sits at bottom, opponent's at
  top (same spatial convention this project already uses), but the two
  hero-power buttons and mana crystals are rendered with different frame
  art and physically separated by a large empty "battlefield" gutter — the
  empty middle band itself acts as a divider, not just row position.
- **Marvel Snap**: your cards are always laid out in the bottom half with a
  distinct card-back/frame color per side of the row split; card power/energy
  numbers use fixed white-on-black chips (not danger-color-coded), keeping
  "whose card is this" and "how much HP/power" as two separate visual
  channels.
- **Slay the Spire**: enemy intent icons (attack/defend/buff) appear above
  enemy heads in a fixed icon+number chip, and boss encounters get a unique,
  larger portrait plus a distinct room/floor visual treatment and an
  intro-beat before the fight starts — bosses are telegraphed before combat
  begins, not just styled bigger mid-fight.
- **AFK Arena / Archero**: boss units get a full-screen "BOSS" title-card
  interstitial (name + portrait) before the fight, plus a persistently larger
  health bar with the boss's name printed on it — the name label, not just
  size/color, is what disambiguates "boss" from "big mob."
- **Common thread across all five**: every one of them uses at least *two*
  redundant cues for faction (spatial position + color/frame), and treats
  "boss" as needing a distinct *label or intro moment*, not just a size bump.

## 3. Options for This Project (DOM/CSS-only, no canvas)

### Option A — Row background tint (CSS-only)
Give `.rowE`/`.rowP` containers (or wrapping divs, need to confirm exact row
class name) a faint full-width background wash: cool blue-gray for party row,
warm red-gray for enemy row, independent of HP color. Keep `.hpfill` exactly
as-is (danger-coded) since it's a *different* signal (health, not team).
- Stays the same: card shape, portraits, HP color semantics.
- Cost: CSS-only, ~1-2 hours. No new art.
- Tutorial interaction: could add one tutorial callout step pointing at the
  row backgrounds ("your team" / "enemy team") — small addition to existing
  step sequence.

### Option B — Stronger per-side frame + name label chip (CSS + tiny JS)
Upgrade the existing 3px border into a full card border (both long edges) in
a faction color distinct from `--dmg`/`--heal`/`--acc` (avoid reusing damage
red), and add a small "YOU" / "ENEMY" text chip above each row (once,
non-repeating per card) — echoes Marvel Snap/Hearthstone's frame approach.
- Stays the same: HP bar, portrait art, layout/positions.
- Cost: CSS + small JS to inject the two row labels once. No new art.
- Tutorial interaction: the "YOU"/"ENEMY" chips are self-teaching — may let
  you *remove* a tutorial line rather than add one.

### Option C — Boss banner/title-card treatment (CSS + small JS, no new art pipeline)
For boss encounters specifically: reuse existing boss portrait art already in
`art3.js`, but add a distinct card treatment — gold/purple accent border
(not `--dmg` red, which should stay "enemy" not "boss"), a printed name label
on/above the HP bar (AFK Arena pattern), and optionally a one-time
non-blocking intro banner ("BOSS: <name>") on `devGo('boss')` entry before
first input is accepted.
- Stays the same: HP color semantics, portrait art itself.
- Cost: CSS for the frame/label = small; the intro banner requires a small
  JS state flag (show once per boss node) — still no new asset pipeline.
- Tutorial interaction: complements the existing "read enemy intent" step;
  does not conflict with any existing tutorial step-lock.

### Option D — Combine A+B+C as one coherent "faction & threat" pass
Do all three together as a single reviewed CSS/small-JS changeset: row tint
(A) for faction-at-a-glance, upgraded frame+chip (B) for per-card
confirmation, boss banner (C) for threat-tier. Redundant cues, matching the
"every reference game uses 2+ redundant signals" pattern from Section 2.
- Cost: CSS + small JS, larger single changeset (~half day), one review pass
  instead of three.
- Tutorial interaction: single tutorial-doc update instead of three separate
  small edits — lower risk of the tutorial and UI drifting out of sync.

No option here picks a winner — sequencing (A/B/C piecemeal vs. D combined)
and exact color values are product-owner/art-director decisions.

## 4. Accessibility Notes (flag, not resolve)

- Do not let faction coding be color-only (WCAG SC 1.4.1). Options B/C's text
  chips and name labels already satisfy this by pairing color with a text
  label — Option A (tint-only) does **not**, on its own, and would need a
  secondary non-color cue (e.g., row label text, or an icon) to pass.
- Any new accent colors chosen for faction/boss framing must be checked
  against both `--hp-full/--hp-low/--hp-crit` and `--dmg`/`--heal`/`--acc`
  for colorblind confusability (protanopia/deuteranopia especially, since
  red/green HP semantics already exist) — this is the same debt tracked
  under `HANDOVER §2` per `technical-preferences.md`.
- No flashing: if Option C's boss banner includes any transition, it must be
  a fade/slide, not a flash, and must be skippable/instant for players who
  have already seen it (repeat encounters, speedrunning, replay).
- Any new text labels (row chips, boss name banner) must respect the
  project's existing font-size floor and remain legible at the smallest
  supported UI scale (3 breakpoints: 1199/899/599px).
