# 41-daily · Daily (Should) · NEW in round 2

**Source:** A4 R2 Meta.dc.html → 41

**Purpose:** Claim daily reward, weekly bonus, Gem gift. Online only.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** daily.json (60 Shards + 500 Stone + 100 XP; weekly 4 days → 150 + 2000 Stone; 00:00 UTC), gem.json gift 300/day cap 900.

## Container tree
- Scrim + 3 cards 416 (title, sub, item rows, weekly day strip, button 72) + Close.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Sub-line | 80 | 368 | wrap |

## States
- claimable
- claimed
- weekly n of 4
- gift at cap
- guest
- offline

## Focus and Esc
- Focus: Cards → Close.
- Esc: Close (D).

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
