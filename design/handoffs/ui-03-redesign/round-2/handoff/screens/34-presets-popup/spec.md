# 34-presets-popup · Load / Save preset popup (Must) · NEW in round 2

**Source:** A4 R2 Run.dc.html → 34

**Purpose:** Load a saved party or save the current one.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** team_presets.gd.

## Container tree
- Modal 640 pad 32: tabs Load / Save current · rows 72 · Cancel / primary.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Preset name | 20 | — | ellipsis |

## States
- load
- save (name + slot, overwrite confirm)
- missing Axie row
- empty slot

## Focus and Esc
- Focus: Tabs → rows → primary.
- Esc: Cancel.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.
