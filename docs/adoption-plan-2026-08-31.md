# Adoption Plan

> **Generated**: 2026-08-31
> **Project phase**: Concept (heuristic) — see note below, actual state is closer to Production/Polish
> **Engine**: Custom — Vanilla JavaScript/HTML5, no game engine (see `.claude/docs/technical-preferences.md`)
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

> **Phase-detection note**: the template's naive heuristic (10+ src files → Production,
> stories → Pre-Production, ADRs → Technical Setup, systems-index → Systems Design,
> game-concept.md → Concept) landed on **Concept** only because this project has 9
> source files (just under the 10-file threshold) and no ADRs/stories/systems-index in
> the *template's* format yet. The actual game is playable end-to-end with a UI that
> has already been through a full audit pass (`docs/axiedice-source/UIUX_AUDIT_v0.9.md`,
> 29/30 checks passing) — realistically this project is in **Production/Polish**, just
> not yet expressed in this template's artifact formats. Treat the heuristic result as
> a formatting signal, not a judgment on the game's actual maturity.

---

## Step 1: Fix Blocking Gaps

None found. No ADRs exist yet (so no ADR-Status blocking case), and
`design/gdd/systems-index.md` does not exist yet (so no parenthetical-status
blocking case). This project is safe to run any `/adopt`-audited skill against
without silent-wrong-result risk — the gaps below are missing structure, not
broken structure.

---

## Step 2: Fix High-Priority Gaps

### 2.1–2.7 — Seven imported GDDs are missing all 8 required sections, including Acceptance Criteria

All seven files below were imported verbatim from the original project's own
documentation style (see `docs/axiedice-source/`) and do not use this
template's GDD structure at all — no `## Overview`, `## Player Fantasy`,
`## Formulas`, `## Edge Cases`, `## Dependencies`, `## Tuning Knobs`,
`## Acceptance Criteria`, and no `**Status**:` field. Without Acceptance
Criteria specifically, `/create-stories` cannot generate stories from them.

| File | Fix command | Time estimate |
|---|---|---|
| `design/gdd/game-concept.md` | `/design-system retrofit design/gdd/game-concept.md` | 1 session |
| `design/gdd/economy-progression.md` | `/design-system retrofit design/gdd/economy-progression.md` | 1 session |
| `design/gdd/bloodline-system.md` | `/design-system retrofit design/gdd/bloodline-system.md` | 1 session |
| `design/gdd/part-tier-system.md` | `/design-system retrofit design/gdd/part-tier-system.md` | 30 min |
| `design/gdd/axie-body-parts.md` | `/design-system retrofit design/gdd/axie-body-parts.md` | 30 min |
| `design/gdd/build-spec.md` | `/design-system retrofit design/gdd/build-spec.md` | 30 min |
| `design/gdd/combo-decision-memo.md` | `/design-system retrofit design/gdd/combo-decision-memo.md` | 30 min |

- [ ] game-concept.md retrofitted
- [ ] economy-progression.md retrofitted
- [ ] bloodline-system.md retrofitted
- [ ] part-tier-system.md retrofitted
- [ ] axie-body-parts.md retrofitted
- [ ] build-spec.md retrofitted
- [ ] combo-decision-memo.md retrofitted

**Recommendation**: don't do this mechanically for all seven right away. Three of
these (`build-spec.md`, `combo-decision-memo.md`, parts of `bloodline-system.md`)
read more like technical/implementation specs and design-rationale memos than
player-facing GDDs — forcing them into the 8-section format may strip out
exactly the content that makes them useful (acceptance tests, "do NOT do this"
lists, audit trails). Retrofit `game-concept.md`, `economy-progression.md`,
`part-tier-system.md`, and `axie-body-parts.md` first since those map cleanly
to GDD content; revisit the other three once you've decided whether they stay
as reference/spec docs or get split into GDD + ADR pairs.

### 2.8 — `design/gdd/systems-index.md` does not exist

No systems index means `/gate-check`, `/create-stories`, and `/architecture-review`
have nothing to key status tracking off of.

**Fix**: run `/map-systems` — it will read the 7 imported GDDs and produce a
systems index. Given the docs are already system-decomposed (part tiers,
bloodline, economy, combat), this should mostly be a matter of listing what
already exists rather than discovering new systems.
**Time**: 30 min
- [ ] systems-index.md created

### 2.9 — `docs/architecture/tr-registry.yaml` does not exist

**Fix**: handled by Step 3a below (bootstraps automatically via `/architecture-review`).
**Time**: part of Step 3
- [ ] tr-registry.yaml created

### 2.10 — `docs/architecture/control-manifest.md` does not exist

**Fix**: handled by Step 3b below.
**Time**: part of Step 3
- [ ] control-manifest.md created

---

## Step 3: Bootstrap Infrastructure

Run this after Step 2's GDD retrofits are far enough along that Acceptance
Criteria exist for at least the systems you plan to work on first.

### 3a. Register existing requirements (creates tr-registry.yaml)
Run `/architecture-review` — bootstraps the TR registry from your GDDs. No
ADRs exist yet, so this run will mostly register open requirements without
resolving them — that's expected for a project mid-migration.
**Time**: 1 session
- [ ] tr-registry.yaml created

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check [current-phase]` — given the note above, discuss with whoever
owns the project whether to gate-check as Production/Polish directly rather than
walking back through Concept → Systems Design → Architecture for a game that
already works end-to-end.
**Time**: 5 min
- [ ] production/stage.txt written

---

## Step 4: Medium-Priority Gaps

### 4.1 — All 7 GDDs missing `**Status**:` field
Add a `**Status**:` line (`In Design` / `Designed` / `In Review` / `Approved` /
`Needs Revision`) to each GDD's header as part of the retrofit in Step 2.
**Time**: 5 min per file (bundle with retrofit)
- [ ] Status fields added

### 4.2 — `production/sprint-status.yaml` missing
Covered by Step 3c.
- [ ] Resolved in Step 3c

### 4.3 — `production/stage.txt` missing
Covered by Step 3d.
- [ ] Resolved in Step 3d

### 4.4 — `docs/architecture/architecture-traceability.md` missing
Created as a byproduct of `/architecture-review` (Step 3a) once ADRs exist to trace.
**Time**: part of Step 3a
- [ ] Created in Step 3a

---

## Step 5: Optional Improvements

### 5.1 — `.claude/docs/technical-preferences.md` → Memory Ceiling still `[TO BE CONFIGURED]`
No documented memory budget exists in the original project (it's a lightweight
DOM/CSS game, unlikely to matter, but worth a deliberate "N/A" or a real number
rather than a placeholder).
**Time**: 5 min
- [ ] Filled in or explicitly marked N/A

### 5.2 — `docs/engine-reference/` (godot/unity/unreal) is present but not applicable
These reference dirs are template scaffolding for engines this project doesn't
use. Harmless to leave, but worth deleting or noting as unused so a future
contributor doesn't think the project runs on Godot.
**Time**: 5 min
- [ ] Left as-is / removed (your call)

---

## What to Expect from Existing Stories

No stories exist yet, so this section doesn't apply — nothing to preserve.

---

## Re-run

Run `/adopt` again after completing Step 2 to verify GDD gaps are resolved
before moving on to Step 3's infrastructure bootstrap.
