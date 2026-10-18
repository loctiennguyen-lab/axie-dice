# 16-boot · Boot / sign-in (Must)

**Source:** A4 Boot and System.dc.html → "16" (tabs switch states).

**Purpose:** Load, sign in or play as guest.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Centred column over the 3D Land.

## Container tree
- Root: 3D Land at dusk + CenterContainer → VBox gap 48: logo 640×240 · plate 560 w pad 32 VBox gap 20 (state content).
- BottomRight: version label Work Sans 16 muted.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Loading step | 40 | 496 px | no wrap |
| Error body | 140 | 496 px | wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- loading: title + 12 h bar + step text ("Loading Axie models · 3 of 5")
- signed out: Sign in primary L + Play as guest secondary
- signing in: spinner + Cancel
- error: red-8 title, body, error code, Try again / Play as guest
- offline: Play offline / Retry connection

## Focus and Esc
- Focus: Primary → secondary.
- Esc: Nothing on Loading; Cancel on Signing in.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

**Flag:** Sign-in method and copy are placeholders.
