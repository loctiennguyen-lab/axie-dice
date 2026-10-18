# 44-preset-editor · Team preset editor (Should) · NEW in round 2

**Source:** A4 R2 Meta.dc.html → 44

**Purpose:** Rename and edit a preset.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** team_presets.gd.

## Container tree
- Modal 720: name field · 5 slot rows (preview 160, opens 33) · Rename / Save / Delete (destructive).

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Name | 20 | — | — |

## States
- editing
- empty slot
- missing Axie

## Focus and Esc
- Focus: Name → slots → Save.
- Esc: Cancel (asks if unsaved).

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
