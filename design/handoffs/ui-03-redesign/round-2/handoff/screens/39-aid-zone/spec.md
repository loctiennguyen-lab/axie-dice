# 39-aid-zone · Aid zone (Should) · NEW in round 2

**Source:** A4 R2 Combat.dc.html → 39

**Purpose:** Buy in-fight help with Gem. Hidden for the first 5 runs and in Mission runs.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** aid_prices.json (R2 15 / 3 for 38, R4 60, run caps 6 / 4), aid_catalog.gd.

## Container tree
- Closed: Aid button 288×48 above Actives, key A; offer card (violet border) pops above when an offer shows.
- Open: tray 420 wood-1 pad 20 bottom-left (ends left of the dice tray, ≈ x 444): header (used n of cap) · rows 64 (name, sub-line, CostChip) · footer.
- First-purchase confirm 560 over a neutral-1 @ 80% scrim, focus on Cancel.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Row name | 24 | ≈360 | no wrap |
| Reason | 60 | ≈360 | no wrap |

## States
- hidden
- closed + offer
- tray open
- disabled rows keep price + reason
- Coming soon (R4)
- first-purchase confirm

## Focus and Esc
- Focus: Rows → Buy.
- Esc: Close tray.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Fairness line copy is mine.
