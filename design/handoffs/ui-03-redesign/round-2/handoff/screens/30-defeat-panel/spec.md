# 30-defeat-panel · Defeat panel (Must) · NEW in round 2

**Source:** A4 R2 Combat.dc.html → 30 (tabs switch states)

**Purpose:** Whole party dead: offer a paid Continue once per fight, show the recap and the boss left, or end the run.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** aid_prices.json R1 (price 90, boss_price 180, free_continue per_account 1, max_asc 2, node_kinds elite/boss); ascension continue_heal_pct (40, 25 from A6); combat_tune.json phase_thresholds; engine can_continue / continue_after_wipe (boss keeps HP and phase; clock and attrition reset).

## Container tree
- Root: 3D stage + scrim neutral-1 @ 90% + CenterContainer.
- Panel 720 w, wood-1, radius 12, pad 40, VBox gap 24.
- Header VBox: "Party down" Rowdies 32 red-8 · context line Work Sans 18 muted.
- Boss block (when a boss/elite is alive): wood-2 pad 16 → HBox name / "% left · phase n of 3" + PhaseBar 16 h, ticks from data.
- Recap Grid 2 cols × 3 rows gap 8/24: label muted / value Rowdies 18.
- Continue block wood-2 pad 16: HBox [title + effect line] + CostChip; reason line; primary L 72 (expand).
- Footer HBox end: End run secondary M.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Context line | 60 | 640 | no wrap |
| Recap label | 20 | ≈200 | no wrap |
| Effect line | 120 | ≈480 | wrap |
| Reason | 80 | 640 | wrap |

## States
- can afford: "Continue · 180 Gem"
- free first time (A0–A2, Elite/Boss, once per account): chip "Free"
- cannot afford: grey "Need 60 more Gem" + reason, End run focused
- already used this fight: grey "Used this fight", End run focused
- loading: spinner "Reviving…", input locked
- error: "Couldn't reach the server. Nothing was charged." + Try again
- mission run: block replaced by "Mission runs have no Continue."; End run becomes primary

## Focus and Esc
- Focus: Continue → End run (End run when Continue is unavailable).
- Esc: None; the panel must be answered.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Recap labels are my copy.
- VIP prices exist in data but VIP is off in L1; not drawn.
