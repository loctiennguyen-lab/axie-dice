# 14-in-run-menu · In-run menu (Must)

**Source:** A4 Run Screens 2.dc.html → "14" + "15"; Save and quit row in A4 States.dc.html.

**Purpose:** Pause: resume, relics, map, settings, save and quit, abandon.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Centred pair.

## Container tree
- Root: scrim + CenterContainer → HBox gap 24: menu plate 480 (title "Paused" + sub, 6 rows 64 h: Resume primary, Relics owned, Run map, Settings, Save and quit, Abandon run red-8 text) · side panel 560×576 (title + rows).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Row label | 16 | — | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- resume (focused)
- settings / relics / map in side panel
- save and quit → quit confirm
- abandon run → destructive dialog (focus on Keep playing)

## Focus and Esc
- Focus: Resume → rows ↑↓.
- Esc: Resume.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
