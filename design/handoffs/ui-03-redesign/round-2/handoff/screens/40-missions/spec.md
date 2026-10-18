# 40-missions · Missions (Shard stake board) (Should) · NEW in round 2

**Source:** A4 R2 Meta.dc.html → 40 + state cards

**Purpose:** Stake Shards on a hard Short run. Replaces 22.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** missions.json N1–N3 (stake 300/500/800, ×2.15/2.4/3.6, Stone 4/8/14, unlock by win at A3/A4/A6, newcomer_runs 5, payout_cap 20000), mission_rules.json, starter Shards not stakeable.

## Container tree
- Header (title, explainer, stakeable vs starter Shards).
- Body HBox: tier table (grid 120/140/160/160/120/1fr, rows min 96) · detail 440 (stake, Win green-2, Lose red-2, extra rules, "No Continue and no Aid", reason, primary).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Rule row | 60 | 392 | wrap |

## States
- open
- escrow
- locked tier
- locked board (5 runs)
- confirm
- not enough stakeable
- settle won / lost

## Focus and Esc
- Focus: Rows → primary.
- Esc: Back.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- M6 and M7 have no names yet.

## Rule sets (ANSWERED)
Picked per day, per tier. Base on every Mission fight: enemy damage ×1.1, Elite HP ×1.1.

| Tier | Set A | Set B |
|---|---|---|
| N1, N2 | M5, M6 | M1, M7 |
| N3 | M2, M3, M4 | M1, M2, M4 |
| N4 (off) | M1, M5, M6 | M5, M6, M7 |
| N5 (off) | M1, M5, M6, M7 | M2, M4, M5, M6 |
| N6 (off) | M1, M4, M5, M6, M7 | same as A |

M1 Harsh clock: boss clock from turn 6, +20% a turn, max 5 steps · M2 Spike stack: spikes 1 turn sooner · M3 Hunted: +2 Elites (below A9 only) · M4 Heavy hits: enemy damage ×1.15 · M5 Thick boss: boss HP ×1.25 · M6 (unnamed): normal enemy HP ×1.2 · M7 (unnamed): Elite damage ×1.25.
