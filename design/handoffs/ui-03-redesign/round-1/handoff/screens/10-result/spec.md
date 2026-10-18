# 10-result · Result (win / loss) (Must)

**Source:** A4 Run Screens.dc.html → "10" (win, new record, title unlock) and "11" (loss, offline).

**Purpose:** End of run summary.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Plate hugs content and is centred; rest stays 3D.

## Container tree
- Root: 3D + scrim + CenterContainer → plate 640 w pad 40 VBox gap 24: header (badge "New best · A5" if earned, title Rowdies 32 — "Run won" or "Defeated" in red-8, sub line) · title-unlock row (if earned) · Grid 3 cols stats (Rowdies 24 / label) · earnings rows 48 · network notice (offline only) · actions HBox (Run again secondary, Back to Land primary L expand).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Title unlock | 24 | — | no wrap (Vietnamese: "Người Giữ Ấn") |
| Sub line | 48 | 560 px | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- win
- win + new record + title unlock
- loss
- offline (score not submitted, Retry)

## Focus and Esc
- Focus: Back to Land → Run again → Retry.
- Esc: Back to Land.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

**Flag:** Pass XP icon missing; shown as an "XP" circle.
