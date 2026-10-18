# 07-reward · Reward (Must)

**Source:** A4 Run Screens.dc.html → "07"; states A4 States.dc.html.

**Purpose:** After a Battle/Elite: pick 1 of 3 relics.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Centred column; extra space stays 3D behind the scrim.

## Container tree
- Root: 3D stage + scrim (neutral-1 @ 80%) + CenterContainer → VBox gap 40 centre: [title Rowdies 32 + Shards pill] · HBox gap 32 of 3 cards 384 w (art 160, name/rarity, description wrap) · HBox gap 16 actions (Reroll secondary, Skip secondary, Take primary L).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Relic name | 18 | ≈240 px | no wrap (longest: Lone Wolf Contract) |
| Relic description | 178 | 336 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- normal
- rerolled: button "Reroll · 0 left" disabled
- skip: inline confirm row "Skip this reward? You keep the 40 Shards." Back / Skip
- Scavenger's Eye: 4 cards at 336 w

## Focus and Esc
- Focus: Cards ←→ → Take → Reroll → Skip.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
