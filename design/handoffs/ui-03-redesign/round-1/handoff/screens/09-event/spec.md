# 09-event · Event node (Must)

**Source:** A4 Run Screens.dc.html → "09".

**Purpose:** Pick one choice (Rest, Forge, Pray, …), read the outcome.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Content centred, 720 + 48 + 720.

## Container tree
- Root: CenterContainer → HBox gap 48: art 720×720 · VBox 720 gap 24: header (icon 64 + title Rowdies 32 / sub), body Work Sans 18 wrap, VBox gap 12 of choice rows (min 88, icon 56, title Rowdies 24, text wrap), action HBox end (primary L).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Event title | 28 | — | no wrap |
| Body | 320 | 720 px | wrap |
| Choice text | 90 | 600 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- choices (button "Pick a choice" until one is picked, then "Choose Rest")
- outcome: other choices at 40%, body = result, button "Continue"

## Focus and Esc
- Focus: Choices ↑↓ → button.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

**Flag:** Choice text and outcomes are placeholders (not in game-data.md).
