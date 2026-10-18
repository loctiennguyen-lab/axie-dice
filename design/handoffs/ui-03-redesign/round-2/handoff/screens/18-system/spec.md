# 18-system · System parts (Must)

**Source:** A4 Boot and System.dc.html → "18".

**Purpose:** Shared dialogs and feedback.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). —

## Container tree
- Dialog 560 w (see components.md). Toast stack top-centre, 24 from top, gap 8, max 3. Network notice inline at the top of the content or above actions. Skeleton rows match the real row height.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Dialog title | 40 | 496 px | wrap |
| Dialog body | 200 | 496 px | wrap |
| Toast | 48 | — | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- info (1 button)
- confirm (amber)
- destructive (red, focus Cancel)
- toast success / error
- network notice offline + Retry, reconnecting
- loading skeleton + scrim

## Focus and Esc
- Focus: Dialog: primary (destructive: Cancel) → other.
- Esc: Cancel / close.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Round 2 changes (marked)
- NEW: error-code table → 36.
- ANSWERED: add run_gone dialog copy (see 36).
