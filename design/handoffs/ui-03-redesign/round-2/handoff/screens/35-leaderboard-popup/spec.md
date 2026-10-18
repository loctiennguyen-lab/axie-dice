# 35-leaderboard-popup · Leaderboard popup (Must) · NEW in round 2

**Source:** A4 R2 Run.dc.html → 35

**Purpose:** Quick top 5 for the picked kind.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** remote_leaderboard_source.gd.

## Container tree
- Modal 640 pad 32: header + reset line · rows 56 (rank, name, score), own row pinned with cream outline · Full Leaderboard / Close.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Name | 20 | — | ellipsis |

## States
- normal
- loading
- error

## Focus and Esc
- Focus: Rows → buttons.
- Esc: Close.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Names and scores placeholders.
