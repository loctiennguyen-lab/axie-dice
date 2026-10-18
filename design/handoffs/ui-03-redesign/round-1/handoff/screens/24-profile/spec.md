# 24-profile · Profile and Cosmetics (Should)

**Source:** A4 Meta Screens.dc.html → "24-profile" (tabs and tiles clickable; states as cards under the frame).

**Purpose:** Equip cosmetics and titles, see stats.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Content column expands; detail plate fixed 440. Tiles/rows stretch to fill the height (Grid rows 1fr / list rows min 96).

## Container tree
- Root: VBox gap 24, margin 24, bg neutral-1.
- Header HBox gap 24: title plate (IconButton ← 48 + Rowdies 32) · tabs HBox gap 8 (Tab 56) · spacer expand · currency plate (Gem, Shard, Stone).
- Notice row (if any).
- Body HBox gap 24 expand: content VBox expand [optional header plate: title + progress bar / search field + sub] + Grid (n cols) of tiles or VBox list of rows · detail plate 440 (art expand min 200, title Rowdies 32 + badge, body wrap, rows 48, reason red-8, primary 72).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Tile name | 18 | tile width − badge | ellipsis |
| Detail body | 160 | 392 px | wrap |
| Row title | 40 | — | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- tiles: Equipped / Owned / Locked / Season 1 (state in badge text, locked art 40%)
- guest

## Focus and Esc
- Focus: Tabs → tiles → Equip.
- Esc: Back to the Land (Codex: clears search first).

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
