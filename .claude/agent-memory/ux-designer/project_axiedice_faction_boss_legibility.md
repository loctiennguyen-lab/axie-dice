---
name: project-axiedice-faction-boss-legibility
description: Faction (party vs enemy) and boss-tier legibility research for Axie Dice Tactics combat/boss screens, 2026-09-09
metadata:
  type: project
---

Confirmed live (via devGo('combat') / devGo('boss') screenshots) that a first-time
viewer cannot quickly tell which row is the player's vs. the enemy's, or which
enemy is the boss. This is the same class of issue as [[project-axiedice-combat-hierarchy]]
(cards all use identical treatment regardless of importance/role) but a distinct
finding: that memory is about *size/weight* hierarchy within a side; this one is
about *cross-side* (faction) and *threat-tier* (boss) legibility.

Grounded in `src/client.html` on 2026-09-09:
- `.unit.p` already has a 3px bottom border in `var(--cc)` and `.unit.e` a 3px
  top border in `var(--dmg)` — a real but too-subtle partial mitigation that's
  easy to miss when eyeballing a screenshot and easy to assume "doesn't exist."
  Reuses `--dmg` (already meaning "damage/crit") for the enemy border, so it
  doesn't read cleanly as a dedicated faction color.
- HP bar color (`--hp-full/--hp-low/--hp-crit`) is danger-tier-only and
  identical on both rows — audit finding P0-3 from
  `docs/axiedice-source/uiux/UIUX_AUDIT_v0.9.md` is confirmed **still
  unresolved** as of this date.
- `.unit.big` (boss) only gets `width:290px` + reused `--dmg` red border — no
  name label, banner, or distinct color identity.
- `design/gdd/onboarding-tutorial.md` never teaches faction/boss identification
  (grepped for boss|team|faction|VS — zero matches).

**Why this matters:** before touching this area again, don't assume "no faction
cue exists at all" (there's a subtle one) or "P0-3 was fixed" (it wasn't) —
verify by grepping `.unit.p`, `.unit.e`, `.hpfill` in `src/client.html` first,
since both wrong assumptions are easy to make from a screenshot alone.

**How to apply:** Full options writeup (4 CSS/small-JS options, reference
patterns from Clash Royale/Hearthstone/Marvel Snap/Slay the Spire/AFK Arena,
accessibility notes) is at
`production/session-state/uiux-faction-clarity-options.md`. This was a
research/options deliverable only (parent session explicitly waived the
normal write-approval step for this file since it's a scratch artifact, not a
shipped design doc) — no option was chosen yet; when the product owner picks
one, promote the decision into a real `design/gdd/` or `design/ux/` doc
following the 8-section standard, and update this memory with the outcome.
