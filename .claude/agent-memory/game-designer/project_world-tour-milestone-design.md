---
name: world-tour-milestone-design
description: World Tour ("Lunacia Atlas") GDD design decisions — milestone axis choice, RNG-boss exclusion rule for landmarks, exclusivity requirement vs Echo Box, hybrid 2-map/gate structure (v2, 2026-09-07)
metadata:
  type: project
---

## SUPERSEDED — v2 revision (2026-09-07, same day as v1 below)

Product owner answered v1's 3 open questions and changed the design materially.
`design/gdd/world-tour.md` was rewritten in place (not a new file). The notes
below this point (the original v1 session) are **stale on the milestone-axis
point** — kept for historical reasoning, but do not apply "pure `META.runs`,
single 16-tile board" to any future session without re-reading the current file.

Key v2 changes:
- **Structure is now 2 separate maps/chapters** (v1 was one 16-tile board), based
  on 2 real confirmed art files (`Map1-new.png` downloaded, `Map2-new.png` known
  fileId but not yet downloaded/reviewed). Each map re-indexes from tile 1, 10
  tiles/map (down from 16), because splitting into 2 chapters at 16 each would
  nearly double total completion time past the Echo Point Tier-1 (~46h) reference
  the v1 design deliberately capped against.
- **Progression is now hybrid, not pure `META.runs`.** In-map axis is still
  participation (`T(i)=i(i+1)`, relative to a per-map baseline — Map1 baseline=0,
  Map2 baseline = a ONE-TIME snapshot of `META.runs` taken the moment the gate
  clears, stored in a new `META.tourMap2Base` nullable int). Between maps there
  is now a **hard skill gate**: `gateCleared() = progress(map1)>=T(10) AND
  META.ascMax>=3`. Chose `META.ascMax` (already tracked, `client.html:3869`)
  reused at a HIGHER threshold than Map1's own tile-10 landmark (`ascMax>=1`) —
  same field, two thresholds, no new tracking mechanic invented. Rejected
  requiring "Full Run specifically" because `ascMax` doesn't record which mode
  triggered it; adding that would require new tracking, which the brief said to
  avoid if possible.
  **Why:** product owner explicitly said the old "just enough runs" gate was too
  weak for a chapter transition and demanded a real difficulty requirement.
  **How to apply:** if `client.html:3869`'s `ascMax` increment logic ever splits
  by mode, `gateCleared()`'s formula must be re-examined — it currently assumes
  ascMax is mode-agnostic.
- **Cosmetic exclusive/reused ratio for non-landmark tiles is explicitly TBD** —
  product owner asked to defer this, so v2 does NOT lock a number (v1 had
  proposed 3 exclusive / 13 reused as a placeholder; that placeholder is now
  removed from the doc, not just relabeled).
- **Post-completion state changed**: v1 planned a static permanent "TOUR
  COMPLETE" screen. v2 requires a concrete "Next chapter — coming soon" screen
  after both maps are finished (product owner confirmed more chapters ARE
  planned later, just not built yet) — must show real copy, not a blank/error
  state.
- 3 new open questions replace the 3 old ones: (1) need `Map2-new.png` reviewed
  before finalizing Map 2's tile count/landmark placement, (2) confirm
  `ascMax>=3` is the right gate difficulty (too low duplicates the Map1 landmark,
  too high may permanently wall off most players), (3) "World Map Selection.PNG"
  (Drive fileId `1iD_IvtXonr93lxRQAoezgk7Pvl5mxySJ`, not yet fetched) may already
  be the intended chapter-select screen art — worth requesting before a
  `ux-designer` designs that screen from scratch.

---

## v1 session notes (2026-09-07, original — see SUPERSEDED note above)

Wrote `design/gdd/world-tour.md` (2026-09-07, draft, not yet product-owner-approved)
for a new persistent meta world-map progression feature, requested via the lead
in Vietnamese. Key decisions, in case of a follow-up revision session:

- **Milestone axis = `META.runs`** (lifetime run-start count, increments at
  `client.html:3402` regardless of win/loss), NOT `META.wins` and NOT a new
  cumulative counter. Chosen because it already exists (zero new tracking code
  needed besides a `META.tourClaimed:[]` claim-state array), and because it
  gives frequent guaranteed forward progress every single run — deliberately
  different from Lunacia Pass (`META.xp`, performance-based) and Echo Box
  (gacha). Threshold formula: `T(i) = i×(i+1)` for 16 tiles, i=1..16 (T(1)=2,
  T(16)=272 runs).
  **Why:** product owner explicitly asked to check what's already tracked
  before adding new variables, and to make this feature clearly distinct from
  the two existing meta systems (Battle Pass = linear XP, Echo Box = gacha).
  **How to apply:** if asked to revise the milestone axis to `wins` instead of
  `runs`, the entire T(i) threshold table needs recalculating (wins accrue far
  slower than runs-started) — don't just relabel the field.

- **Landmark tiles (4, 10, 16) must only gate on RNG-free data.** `data.js`
  `BOSS_ALT = ['frost_lord','mirror']` is a randomized substitute for the
  "middle boss" slot — defeating a specific one of that pair is NOT
  deterministic even after enough runs. Only `gooey_king` (always first boss,
  both modes) and `agony` (always final boss, both modes) are guaranteed
  encounters, so those are the only two bosses used as landmark conditions;
  tile 10 uses `META.ascMax>=1` instead of a third boss.
  **Why:** a milestone system whose entire value proposition is "deterministic,
  not gacha" (product owner's explicit requirement) cannot gate on an
  RNG-selected boss without contradicting itself.
  **How to apply:** before adding any new landmark condition to this system (or
  a future "Tour 2"), check whether the underlying field can have an RNG
  branch that blocks it (search `data.js` for `_ALT` arrays or similar
  randomized-selection patterns first).

- **Exclusivity rule**: the 3 landmark rewards (tile 4/10/16) must never be
  added to `COSMETIC_POOLS` (the Echo Box gacha roll pool) — this is the
  entire mechanism that keeps World Tour "deterministic" distinct from Echo
  Box "gacha" at the player-perception level, not just the code level. The
  other 13 (non-landmark) tiles are fine reusing existing Echo Box pool items
  since only the *acquisition path* differs there, not the item itself.

- `design/gdd/systems-index.md` did not exist before this session — created it
  fresh, listing all pre-existing GDD files with a best-effort one-line
  description (status left "Không rõ — xem file" where no `> **Status**:`
  header line was found, to avoid asserting unverified claims).

- Three open questions were left unresolved in the GDD (see its final section):
  (1) confirm `runs` vs `wins` as the milestone axis, (2) confirm the
  exclusive-vs-reused cosmetic asset ratio (currently 3 exclusive / 13 reused),
  (3) confirm whether v1 should stub a "next chapter coming soon" message after
  tile 16, or end silently. Check these were answered before treating the GDD
  as final in a later session.
