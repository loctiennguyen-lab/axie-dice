# 01-land-hub · Land hub (Must)

**Source:** A4 Blend.dc.html → "01-land-hub"; states in A4 States.dc.html → "01 Land hub"

**Purpose:** Home. The player walks their Axie around the Land, opens buildings, starts a run.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Extra width/height goes to the 3D view. HUD plates stay pinned to corners.

**3D safe area:** 96,128 → 1824,912

## Container tree
- Root: Control (full rect) → SubViewportContainer (full rect, stretch, 3D stage) + CanvasLayer HUD (layer 20). HUD blocks are anchored, not in a container, because they float over 3D.
- TopLeft · PanelContainer plate (anchor top-left, margin 24) → HBox gap 16: Avatar 48 circle, VBox [Name Label Rowdies 24 · Best Label Work Sans 18 muted]. Shrink, fixed.
- TopRight · PanelContainer plate (anchor top-right, margin 24) → HBox gap 24: 3× Currency pill (icon 32 + Rowdies 24), IconButton settings 48.
- BottomLeft · plate (anchor bottom-left, margin 24) → HBox gap 12: key chip "N" + Label "Show names".
- BottomRight · HBox gap 16 (anchor bottom-right, margin 24): Button secondary M "Daily run · 2 of 3", Button primary L "Start run".
- World labels · one name plate per building, positioned each frame from unproject_position(building.label_anchor); Rowdies 24 name + key chip; hover adds Work Sans 18 sub-line. Plate pad 8 16 when it has a sub-line.
- Player Axie · 3D, about 65×75 px on screen, walks freely (no fixed spot).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Player name | 16 | 220 px | ellipsis |
| Best line | 24 | 260 px | ellipsis |
| Building name | 14 | — | no wrap |
| Building sub-line | 36 | — | no wrap |
| Locked rule | 32 | — | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- normal (returning)
- first visit: coach card above Start run, Daily hidden, Start run focused with ring
- building locked: model at 60%, plate with lock + rule, click = same rule as toast
- signed out: profile "Guest", currencies hidden, primary "Sign in to play" + secondary "Play as guest"
- offline: network notice top centre x 660–1260, Daily disabled "Daily run · needs connection"
- hover label: building sub-line (e.g. Echo Box "2 Tickets")
- resume-run prompt: dialog "Continue your run?" Continue (primary, focused) / Abandon run

## Focus and Esc
- Focus: Start run → Daily run → buildings in key order (1–7, B) → settings.
- Esc: Closes the hover label; otherwise opens Settings.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
