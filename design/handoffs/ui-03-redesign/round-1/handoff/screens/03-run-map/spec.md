# 03-run-map · Run map (Must)

**Source:** A4 Blend.dc.html → "03-run-map"; states A4 States.dc.html → "03 Run map".

**Purpose:** Pick the next node on the act map.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Map stays centred; extra width goes around it. Long acts scroll horizontally.

## Container tree
- Root: Control full rect, bg neutral-1.
- Map · Control 1024×640 centred (custom-drawn: nodes from data, edges with draw_line). Node = circle (size by type) + icon + label Work Sans 18 under it. This is the one region with absolute positions inside.
- TopLeft · plate 384 w (margin 24) → VBox gap 12: header HBox [IconButton ≡ 48, VBox act/floor Rowdies 24 + Ascension · Shards Work Sans 18] + 5 party rows (name / HP Rowdies 24 / bar 12).
- BottomLeft · plate 384 w → "Relics · 6" + rows 44 h (name / rarity).
- TopRight · plate 416 w pad 24 → node detail: icon 64 + title Rowdies 32, description, "If you win" rows, path note, Travel primary L.
- BottomRight · key hint "Arrows pick · Enter travels · Esc menu".

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Node label | 12 | 128 px | no wrap |
| Node description | 140 | 368 px | wrap |
| Relic name | 18 | ≈230 px | ellipsis |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- mid-run, Elite selected (normal)
- start: only Floor 1 lit
- boss next: Boss node 1.25×, red ring, button "Face the Boss"
- node hover: node 1.1×, name under it; unreachable = red-8 note + disabled "Not on your path"
- locked / passed node: 40% + lock, edges grey, "Already passed"

## Focus and Esc
- Focus: Reachable nodes → Travel → relics.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
