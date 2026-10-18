# 08-shop · Shop node (Must)

**Source:** A4 Run Screens.dc.html → "08"; states A4 States.dc.html.

**Purpose:** Buy relics/actives with Shards, sell relics.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Middle column expands.

## Container tree
- Root: HBox gap 24, margin 24, bg neutral-1.
- Left VBox 384 fixed: shop plate (icon 48 + "Shop" / floor; Shards row 56) · Sell plate (rows 48: name / +value).
- Middle VBox expand: "Relics" Rowdies 32 + Grid 2 cols gap 16 of rows 176 h (art 128, name ellipsis, rarity, price) · "Actives" + same grid (art shows Mana + MP).
- Right VBox 416 fixed: detail plate pad 24 (art 200, name Rowdies 32 / rarity, description, reason red-8, Buy primary 72) · Leave shop secondary (end).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Item name | 18 | ≈330 px | ellipsis |
| Description | 178 | 368 px | wrap |
| Reason | 60 | 368 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- normal
- bought: row at 40%, price "Bought"
- sold out: row at 40%, "Sold out"
- not affordable: price red-8, reason on detail, Buy grey "Need 220 Shards"
- nothing affordable: notice "You can't afford anything here. Sell a relic or leave." + Leave shop focused

## Focus and Esc
- Focus: Rows (grid arrows) → Buy → Leave shop → sell list.
- Esc: Leave shop.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
