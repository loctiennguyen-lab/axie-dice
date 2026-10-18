# 32-slots-full · Slots full (swap / sell) (Must) · NEW in round 2

**Source:** A4 R2 Run.dc.html → 32 (tabs: passive, active, forced pact)

**Purpose:** Make room when taking a relic, active or forced pact with no free slot, on Reward and Treasure.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** relic_slots.gd: passive 8 (7 cramped), active 3 (+1 Hollow Chalice), G 1, A 2; Eternal = never sellable; forced pact = no cancel.

## Container tree
- Scrim + panel 1200 pad 40 VBox gap 24: header · new item row (amber 2 px outline) · Grid 4 cols (3 for active) of SlotCells min 120 (name, kind, sell value / "Can't sell") · actions: Leave it (hidden when forced) + "Sell X and take".

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Relic name | 24 | cell | wrap 2 |
| Rule line | 120 | 1120 | wrap |

## States
- passive full
- active full
- forced pact
- all candidates Eternal: card greyed

## Focus and Esc
- Focus: Slots → primary → Leave it.
- Esc: Leave it (not when forced).

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Sell values illustrative.
