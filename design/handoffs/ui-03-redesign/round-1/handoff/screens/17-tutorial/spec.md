# 17-tutorial · Tutorial coach overlay (Must)

**Source:** A4 Boot and System.dc.html → "17".

**Purpose:** Teach combat step by step.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). —

## Container tree
- Over Combat: scrim with one hole (radius 12, 4 px cream outline) around the target control; only the hole takes input.
- Coach card 640 w (wood-1, radius 12, pad 24) between the hole and the stage, arrow 32×20 pointing at the hole: title + "Step 2 of 5", body, Skip tutorial (quiet) + Got it (secondary, read-only steps only).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Step body | 140 | 592 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- step n of 5 (hole on Beast's die column 694,854 168×204)

## Focus and Esc
- Focus: The highlighted control → Got it.
- Esc: Skip tutorial (asks to confirm).

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
