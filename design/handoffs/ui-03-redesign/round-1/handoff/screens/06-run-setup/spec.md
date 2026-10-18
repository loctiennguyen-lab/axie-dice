# 06-run-setup · Run setup / Team select (Must)

**Source:** A4 Run Screens.dc.html → "06"; states A4 States.dc.html → "06".

**Purpose:** Pick mode, difficulty, party; start.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Extra width to the 3D party view.

**3D safe area:** 480,200 → 1896,840

## Container tree
- Root: Control (full rect) → SubViewportContainer (full rect, stretch, 3D stage) + CanvasLayer HUD (layer 20). HUD blocks are anchored, not in a container, because they float over 3D.
- Left · plate 432 w (anchor top-left, margin 24, pad 24) → VBox gap 16: header (IconButton ← + "Run setup" Rowdies 32), "Mode", 4 mode rows 56 h, "Difficulty", Grid 6 cols gap 8 of A0–A10 cells 48 h (lock icon when locked), rule line Work Sans 18 wrap.
- Party · HBox space-between in the 3D area: 5 × [Axie preview 168 square (≥160) + plate 200 w name / Max HP].
- BottomRight · HBox gap 16: Team presets secondary, Start run primary L.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Mode sub-line | 14 | — | no wrap |
| Difficulty rule | 90 | 384 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- normal (A4 locked picked → rule text)
- newcomer: difficulty grid replaced by one line, locked modes show their unlock rule
- empty party: dashed "+ Add Axie" slots, Start run disabled "Start run · 3 of 5" + line above
- starting: spinner in Start run, other controls locked; after 10 s "Still starting…" + Cancel
- offline: notice above actions; Daily/Ranked greyed "Needs connection"
- server rejected: red-2 notice "The server couldn't start this Ranked run…" + Try again

## Focus and Esc
- Focus: Modes → A0–A10 (arrows) → Team presets → Start run.
- Esc: Back to the Land.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
