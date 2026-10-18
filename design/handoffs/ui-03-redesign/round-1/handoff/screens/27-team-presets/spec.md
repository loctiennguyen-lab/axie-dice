# 27-team-presets · Team Presets (Should)

**Source:** A4 Meta Screens.dc.html → "27-team-presets".

**Purpose:** Save and reuse parties.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Grid fills the height.

## Container tree
- Root: same header as meta screens, no detail plate.
- Grid 2 cols × 3 rows gap 16: preset tile → HBox of 5 square Axie previews 160×160 gap 8, name Rowdies 24 + "5 / 5", party line.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Preset name | 20 | — | ellipsis |
| Party line | 60 | — | ellipsis |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- normal (4 / 6)
- empty
- full (6 / 6)
- missing Axie (dashed red-8 "Missing" frame + reason)
- delete confirm (destructive)

## Focus and Esc
- Focus: Tiles (grid arrows) → Enter uses.
- Esc: Back.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
