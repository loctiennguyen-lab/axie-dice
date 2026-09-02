# Quick Design Spec: Import Axie Part-Name Variants

**Type**: Small System Tweak (Import Axie → Die mapping)
**System**: Import Axie (`src/engine.js` `axieToDie()`, `src/data.js` `SLOT_CLASS_TEMPLATE`)
**GDD Reference**: `design/gdd/economy-progression.md` §10.2b (free-vs-NFT economy scope this sits inside)
**Date**: 2026-09-03
**Author**: `game-designer` consult, implemented same session

---

## Overview

`axieToDie()` previously mapped every real Axie part to a face using ONLY `(slot, part's own class)` — a fixed 6×6 template. This meant two different real Axies of the same class, with completely different real parts, produced **byte-identical dice**: same 6 faces, same HP, same passive. Players importing multiple Axies of one class ended up with a Vault full of functionally duplicate entries, the only difference being the ID number shown on the card.

## Player Fantasy Problem

"My real Axie's genetics matter" (the entire point of Import Axie) broke down whenever two Axies shared a class — the feature felt pointless past the first import per class.

## Detailed Rules

1. `data.js` adds `PART_VARIANT_MODS`, keyed by face **type** (`dmg`/`shield`/`heal`/`poison`/`mana`/`debuff`/`buff`/`summon`), each holding 2-3 small variant tweaks (`{}`, `{addKw:'...'}`, or `{dv:±1}`).
2. `engine.js` adds `hashPartIdentity(str)` — a plain deterministic string hash (not RNG, not crypto) — and `applyPartVariant(face, part)`, which picks one variant from that face's type-bucket via `hashPartIdentity(part.name||part.id) % variants.length` and applies it (bump value by ≤1, or add one keyword if not already present).
3. `axieToDie()` calls `applyPartVariant(face, part)` right after cloning the `SLOT_CLASS_TEMPLATE` base face, before the existing Origin/`specialGenes` multipliers (unchanged, still applied on top).
4. Same real part name **always** produces the same variant — fully inspectable/reproducible, no hidden RNG, matching the "minh bạch triệt để" pillar. Two Axies of the same class with different real parts now differ across most of their 6 faces (verified: two synthetic Aqua Axies with different part names produced non-identical dice on every mismatched part).

## Formulas

`variantIndex = hashPartIdentity(part.name || part.id) mod variants.length`
`hashPartIdentity(s) = |Σ (h×31 + charCode(s[i])) as int32|` (standard small string hash)

Variant effect is either: no-op, `face.v = max(1, face.v + dv)` where `dv ∈ {-1,0,1}`, or append one keyword to `face.k` if absent. No variant changes `face.t` or `face.p` (slot/type never move) — still exactly 6 faces from 6 real parts.

## Edge Cases

- A face type with no entry in `PART_VARIANT_MODS` (none currently) → `applyPartVariant` no-ops, face unchanged.
- `part.name` missing → falls back to `part.id` for the hash input; a part with neither is effectively impossible (API always returns one of the two).
- Applies uniformly regardless of Origin/`specialGenes` status — those multipliers still run afterward, unchanged.

## Dependencies

- `design/gdd/economy-progression.md` §10.2b — this is additive to the existing free/ungated P0 Import Axie scope, does not touch gating/pricing/pre-select rules.
- Ranked Run (`design/gdd/leaderboard-system.md`) already blocks all Vault picks — this change has zero surface there.

## Tuning Knobs

| Knob | Value | Effect |
|---|---|---|
| Variants per face type | 2-3 | More variants = more differentiation, but wider than 3 risks visibly splitting a type's power band |
| `dv` magnitude | ±1 | Kept small deliberately — variance is flavor, not a balance lever |

## Acceptance Criteria

- **GIVEN** two real Axies of the same class with different real part names, **WHEN** both are imported, **THEN** their resulting dice are not identical (confirmed via `axieToDie()` unit check, 2026-09-03).
- **GIVEN** the same real Axie imported twice, **WHEN** compared, **THEN** the resulting die is byte-identical both times (pure function of part identity, no RNG).
- **GIVEN** a part with an Origin class or `specialGenes`, **WHEN** imported, **THEN** the existing rarity/value bump still applies on top of the variant, unchanged from before this spec.
