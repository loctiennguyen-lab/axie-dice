# 13-treasure · Treasure (Must)

**Source:** A4 Run Screens 2.dc.html → "13"; closed state A4 States.dc.html.

**Purpose:** Open a chest, take the relic.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Centred.

**3D safe area:** chest model ≈ 512×384 centred above y 560

## Container tree
- Root: 3D chest + VBox centred at y 600 gap 24: relic row plate 768 w (art 128 + name/rarity + description) · Shards pill · primary L "Take and continue".

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Relic description | 178 | 560 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- closed: chest idle + "Open chest"
- opened

## Focus and Esc
- Focus: Take and continue.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Round 2 changes (marked)
- NEW: slots-full → 32.
