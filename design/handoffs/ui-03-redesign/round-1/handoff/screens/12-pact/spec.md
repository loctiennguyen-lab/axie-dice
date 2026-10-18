# 12-pact · Pact (Must)

**Source:** A4 Run Screens 2.dc.html → "12"; states A4 States.dc.html.

**Purpose:** After a Boss: pick 1 of 3 Pacts (buff + drawback). Required.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Centred.

## Container tree
- Root: 3D + scrim + CenterContainer → VBox gap 40: title + sub · HBox gap 32 of 3 cards 416 w (art 144, name/rarity, Gain box green-2 + label green-7, Drawback box red-2 + label red-8) · Accept primary L.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Gain text | 120 | 368 px | wrap |
| Drawback text | 100 | 368 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- three cards
- swap a card: secondary "Swap a card · 1 left"
- confirm: dialog repeats only the drawback, Back (focused) / Make pact

## Focus and Esc
- Focus: Cards ←→ → Accept.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
