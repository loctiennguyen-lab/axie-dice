# 33-axie-picker · Axie picker (Must) · NEW in round 2

**Source:** A4 R2 Run.dc.html → 33

**Purpose:** Choose the Axie for a party slot.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** Roster / Vault. Previews ≥ 160 square.

## Container tree
- Modal 1120 pad 32: header · class filter chips 44 · Grid 5 cols (square preview ≈188, name, tier/HP) · Cancel / "Put in slot n".

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Axie name | 20 | ≈180 | ellipsis |

## States
- normal
- in another slot (50%, swaps)
- empty roster

## Focus and Esc
- Focus: Filters → grid → primary.
- Esc: Cancel.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Axie names are placeholders.
