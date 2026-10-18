# 02-combat · Combat HUD (Must)

**Source:** A4 Combat.dc.html (interactive; props eggs, reduceMotion, interactive, sound). Shown in A4 Blend.dc.html 02 / 02b / 02c / 05 (1280). States: A4 States.dc.html → "02 Combat".

**Purpose:** Roll 5 dice (one per Axie, plus Egg dice), assign each to a target, reroll, end turn.

**Base:** 1920×1080, Godot stretch canvas_items / expand. 1280×720 = uniform 0.667 scale (18 px → 12 px). Extra space goes to the 3D stage. HUD anchors keep their margins.

**3D safe area:** 96,112 → 1552,748 with Eggs (→ 850 without). Units never overlap: footprint = model + 20 px.

## Container tree
- Root: Control (full rect) → SubViewportContainer (full rect, stretch, 3D stage) + CanvasLayer HUD (layer 20). HUD blocks are anchored, not in a container, because they float over 3D.
- 3D units (screen px at 1920): Axie 163×214 at x 118 + i·104, y 386 (front: 1, 3, 5) / 132 (back: 2, 4) · Egg 88 at x 116 + j·128, y 640 · Enemy 133×120 at (798,340) and (1338,370) · Elite 210×190 at (1029,175). Sizes follow the engine ratio (Axie 190×250, enemy 155×140, boss 280×255) at 0.86. Boss: 280×255 class, place centre-right inside the safe area.
- World labels (unproject): status chip centred above each Axie head (Shield/Poison icon 22 + Rowdies 20, wood-2, radius 8), Target label 36 h 40 px above each legal target.
- TopLeft · plate (margin 24) → HBox gap 12: IconButton ≡ 40, Label "Fight 4 of 12" Rowdies 20, Label "A3 · Turn 2" Work Sans 18 muted.
- TopRight · plate 320 w (margin 24) → VBox gap 6: enemy rows (wood-2, pad 6 10) → [HBox name / HP] + [HBox HP bar 8 h (expand) · intent icon 20 · intent text]. Rows are clickable when a foe-target die is picked.
- Bottom · HBox (anchor bottom-wide, margin 24, align end) → [Left VBox expand: Info panel 288 (only when a die is picked) + Actives plate 288 (Mana Rowdies 24 + 3 rows 40 h)] · [Centre VBox shrink: Egg dice plate (if Eggs) + Party tray plate pad 8 16 12, HBox gap 16 of 5 Axie card columns 152 w] · [Right HBox expand, end: VBox 240 w gap 12: Reroll secondary 48, End turn primary 64 (Rowdies 28), hint label].
- Flying dice layer (z 30): 88 / 56 die tiles tweened from the 3D throw to their tray slot.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Axie name | 12 | ≈100 px | ellipsis |
| Enemy name | 16 | ≈180 px | no wrap |
| Intent | 10 | — | no wrap |
| Info title | 40 | 264 px | wrap |
| Info text | 120 | 264 px | wrap |
| Active name | 16 | ≈150 px | no wrap |
| Hint | 28 | ≤ 240 px | no wrap |

Test every label with strings 40% longer; Vietnamese titles render as given.

## States
- player turn (normal)
- die selected with legal targets: die lifted + outline, info panel, Target labels, enemy rows outlined
- illegal target: hover shows red-2 reason label "ATTACK can only target enemies", cursor not-allowed, die stays picked
- enemy turn + intents: acting row outlined, line becomes result, tray at 40%, End turn reads "Enemy turn…"
- boss fight: single wide enemy row, 16 h bar, "Phase 1 of 2"
- turn banner: full-width 120 h band, "Enemy turn" / "Your turn"
- Aid tray (newcomer): free Aid only, no Gem prices
- Defeat panel: "Party down" + "See results" (live after 1 s)
- quit confirm: "Quit this fight?" Keep playing (focused) / Save and quit
- Eggs: 1–6 Egg dice in a plate above the tray (max 6, 612 px wide), keys 6–9, 0

## Focus and Esc
- Focus: Dice 1→5 → Egg dice → Reroll → End turn → enemies → actives.
- Esc: Puts the picked die back; otherwise opens the in-run menu.
- Keys: 1–5 pick Axie dice, 6–9 / 0 pick Egg dice 1–5, R reroll all unused, Space end turn, click stage to skip the roll.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

**Flag:** 7 groups (run plate, enemies, target markers, die info, actives, tray, actions) — at the cap. At 1280×720 body text renders at 12 px (the floor).

## Round 2 changes (marked)
- CHANGED: keys 1–5 (Axie dice), R, E/Space, Z undo, A Aid, Esc. Egg dice by click; "6–0" removed.
- CHANGED: Egg cap 4 (relic tokenCap can raise it).
- CHANGED: crit chance = face crit keyword + relic critBonus, party damage faces only, shown on the info panel.
- CHANGED: Rerolls live "n / max".
- NEW: Undo 88×48 left of Reroll; disabled when the turn's undo stack is empty.
- NEW: IntentBadge; status chips burn/weaken/vulnerable/blind/thorns(8)/regen/stun/enrage.
- NEW: FloatText classes and sizes.
- CHANGED: 3 boss phases; ticks from phase_thresholds; phase banner.
- NEW: reconnect notice (input not locked) + Session expired / Update needed dialog.
- CHANGED: Aid hidden for newcomers and Mission runs (39). Defeat → 30.
- ANSWERED: session expired mid-run uses the 16 copy; re-sign-in with the same account resumes the run.
