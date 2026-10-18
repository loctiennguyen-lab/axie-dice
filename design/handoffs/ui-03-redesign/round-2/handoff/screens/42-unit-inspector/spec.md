# 42-unit-inspector · Unit inspector (Should) · NEW in round 2

**Source:** A4 R2 Combat.dc.html → 42

**Purpose:** Read a unit without changing state.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** Unit status, intent, passive, faces.

## Container tree
- Panel 520 beside the unit (flips at edges): name + HP, bar, rows, close hint.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Row value | 120 | ≈320 | wrap |

## States
- enemy
- party Axie
- egg

## Focus and Esc
- Focus: Panel; Tab cycles rows.
- Esc: Close. Openers: right-click, I, long-press 500 ms.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
