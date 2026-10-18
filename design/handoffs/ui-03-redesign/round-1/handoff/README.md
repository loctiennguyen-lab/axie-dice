# Handoff: Axie Dice UI-03 · A4 Blend (Godot)

## Overview
Full UI redesign for Axie Dice (dice roguelite, Godot 4). Direction **A4 Blend**, approved by Liam: full-screen 3D with HUD plates floating over it (wood-1 at 90%), Amber primary buttons, ivory dice, cream "selected" outline. Covers every screen and state in the brief (00-PROMPT.md §5): Must (run loop), Should (meta) and Could (Codex).

## Start here
**AxieDice-UI03-A4-all-screens.html** — one self-contained file (works offline) with every mockup and state in order: style tile, Land hub, Combat (interactive), Run map, Run setup → Result, Pact, Treasure, menu, Boot, tutorial, system, remaining Must states, and all meta screens. Open it in a browser; use the buttons at the top to jump to a part.

## About the design files
The .dc.html files in design/ are **design references built in HTML**, not code to ship. Recreate them in the game's Godot project with Control nodes, Theme resources and StyleBoxFlat, following the container trees in each screens/<id>/spec.md. Open any file in a browser (keep the folder structure; they load ../../_ds and ../assets). Combat is interactive and shows the intended dice behaviour.

## Fidelity
**High-fidelity** for layout, sizes, colours, type, states and copy structure. Exceptions: all art (relic, event, chest, logo, avatars) and every 3D area are grey placeholders; content marked placeholder in a spec "Flag" line must be replaced with real data.

## Global rules
- Base 1920×1080, stretch mode canvas_items, aspect expand. Scale = min(w/1920, h/1080). Extra space goes to the 3D view or panel body, never to a stretched HUD element. 1280×720 is a uniform 0.667 scale (see the 05-combat-1280 frame in A4 Blend).
- 8 px grid (4 px for hairlines and icon padding). Screen margin 24.
- Fonts: Rowdies 700 (titles, numbers, buttons, tabs) + Work Sans 400 (everything read). Never mixed in one label. Sizes 16 (key hints only) / 18 / 24 / 32 (+36 turn banner, die numerals 28/20).
- Text: cream #FFE5B4, never white. Min 18 px for anything the player must read. Contrast ≥ 4.5:1 (table in tokens.json → contrast).
- Hit areas ≥ 44 px. One primary per screen, ≤ 2 secondary, ≤ 7 groups.
- Selected = 4 px cream outline (+ lift on cards and dice). Focus = 2 px amber ring, 4 px offset. Disabled controls say why in text.
- Effects: flat StyleBoxes, hard offset shadows, one translucent fill per panel, modal scrim neutral-1 @ 80%. No blur, gradients, masks or shaders. (Design files use a few dashed borders for empty/missing slots; build them as a 2 px solid neutral-5 border instead, or a small dashed texture.)
- Esc: in combat and on the run map opens the in-run menu; every spec states its own Esc.

## Screens
| # | Screen | Priority | Spec |
|---|---|---|---|
| 01-land-hub | Land hub | Must | screens/01-land-hub/spec.md |
| 02-combat | Combat HUD | Must | screens/02-combat/spec.md |
| 03-run-map | Run map | Must | screens/03-run-map/spec.md |
| 06-run-setup | Run setup / Team select | Must | screens/06-run-setup/spec.md |
| 07-reward | Reward | Must | screens/07-reward/spec.md |
| 08-shop | Shop node | Must | screens/08-shop/spec.md |
| 09-event | Event node | Must | screens/09-event/spec.md |
| 10-result | Result (win / loss) | Must | screens/10-result/spec.md |
| 12-pact | Pact | Must | screens/12-pact/spec.md |
| 13-treasure | Treasure | Must | screens/13-treasure/spec.md |
| 14-in-run-menu | In-run menu | Must | screens/14-in-run-menu/spec.md |
| 16-boot | Boot / sign-in | Must | screens/16-boot/spec.md |
| 17-tutorial | Tutorial coach overlay | Must | screens/17-tutorial/spec.md |
| 18-system | System parts | Must | screens/18-system/spec.md |
| 19-store | Store | Should | screens/19-store/spec.md |
| 20-echo-box | Echo Box | Should | screens/20-echo-box/spec.md |
| 21-season-pass | Season Pass | Should | screens/21-season-pass/spec.md |
| 22-missions | Missions and Daily | Should | screens/22-missions/spec.md |
| 23-leaderboard | Leaderboard | Should | screens/23-leaderboard/spec.md |
| 24-profile | Profile and Cosmetics | Should | screens/24-profile/spec.md |
| 25-vault | Vault | Should | screens/25-vault/spec.md |
| 26-settings | Account and Settings | Should | screens/26-settings/spec.md |
| 27-team-presets | Team Presets | Should | screens/27-team-presets/spec.md |
| 28-land-upgrade | Land Upgrade | Should | screens/28-land-upgrade/spec.md |
| 29-codex | Codex, Guides, Unlocks | Could | screens/29-codex/spec.md |

Each spec has: source frame, container tree with anchors and fixed/expand flags, string limits (max chars, width budget, wrap/ellipsis), every state, focus order, Esc, checklist, flags.

## Interactions and behaviour
- **Combat loop:** turn start throws one die per Axie and Egg (3D RigidBody3D), dice fly into the tray. Click a die (or 1–5, 6–0 for Eggs) to pick it: info panel shows what it does, legal targets get "Target · Name" labels and outlined enemy rows. Click a target to use the die (used = 40%). MANA and SUMMON are self-use: click the picked die again. SUMMON hatches an Egg (max 6) that throws its own die. R rerolls every unused die (2 per turn). Space ends the turn. Click the stage while dice fly to skip. Crit = 20%, ×2, heavy landing + 6 px camera shake.
- **Run loop:** Land hub → Run setup → Run map → node (Battle/Elite → Combat → Reward; Shop; Event; Treasure; Boss → Combat → Pact) → … → Result. In-run menu from Esc anywhere in the run.
- **Loading / error / offline:** every network screen has the same three patterns from 18-system: skeleton rows, inline network notice with Retry, error card with red-8 title and a retry button. Offline never blocks Normal runs.
- Motion: motion.md (combat roll, HUD, run screens, 3D ↔ HUD hand-offs, reduce-motion column).

## State management (minimum)
- Combat: results[n], used[n], selected die, rerolls left, turn, mana, rolling flag, eggHp[], enemyHp[], enemy intents, phase (player / enemy / banner / defeat).
- Run: mode, ascension, party[5], act, floor, map nodes + reachable set, Shards, relics[], actives[3], pacts[].
- Meta: currencies (Gem, Shard, Stone), signed-in / guest / offline, per-screen tab + selected item, Daily tries, pass tier + XP, presets[6].

## Design tokens
tokens.json (fixed schema from the brief: color, font, size, radius, space, stroke, shadow, motion, z + Godot theme items + contrast table). Key values:
- wood-1 #2B1E17 (plates at 90% = #2B1E17E6), wood-2 #3E2618 (rows), wood-3 #58321D (secondary), kam-6 #FFB444 (primary / focus), kam-1 #291808 (text on primary), kam-9 #FFE5B4 (text / selected / die), neutral-1 #13161B, neutral-4 #3C424D (disabled), neutral-8 #B4BCCB (muted), red-4 #B81221 (danger), red-8 #FF8986 (error text), green-6 #3FCD3C (HP), blue-7 #31C6FF (shield), purple-7 #AF7DFF (mana).
- Radius 4 / 8 / 12 (+20 / 14 dice). Shadows: button 0 4 0 wood-1, pressed 0 2; dialog 0 16 48 #000000A0.
- components.md: every component with variants and states.
- slices.json: empty on purpose. A4 uses no textures.

## Assets
design/round-a/assets/: face glyphs (face_*.png/svg), node icons (node_*.png), currencies (cur_gem, cur_shard, cur_stone), UI icons (ui_lock, ui_reroll, ui_settings, ui_undo, ui_mooncard). Sources: the game's art/ folder in the UI-03 upload. **Still to draw:** Stone (stand-in used), Pass XP, Echo Box ticket, fragments, all relic/event/chest art, logo. Fonts: Rowdies and Work Sans (OFL, Google Fonts); ship static TTF per weight + licence.

## Combat 3D layout (engine reference)
Model sizes on screen follow the engine (Axie 190×250, enemy 155×140, boss 280×255) at 0.86 inside the A4 layout: Axie 163×214, enemy 133×120, Elite 210×190 (estimate), Egg 88. Land hub Axie ≈ 65×75. Axie preview frames (Run setup, Presets, Vault, Profile) are square, min 160; camera zoom is matched in code.

## Open items
1. Placeholder content: Gem/Moon Card prices, Echo Box rates, Pass rewards, mission text, Aid list, event choices, player names, Axie IDs, upgrade effects, sign-in method/copy.
2. Elite on-screen size is an estimate (not in the engine table).
3. Combat is at the 7-group cap; 1280×720 body text is exactly 12 px.
4. PNG exports and contact sheet not included (ask if needed); the .dc.html files are the source of truth together with the specs, and the spec wins if they disagree.

## Files
- design/round-a/a4-blend/A4 Blend.dc.html — style tile, 01 Land hub, 02 Combat (+ Eggs, 1280), 03 Run map, 04 Store study, Land placement rules, motion table
- design/round-a/a4-blend/A4 Combat.dc.html — interactive Combat HUD component
- design/round-a/a4-blend/A4 Run Screens.dc.html — 06 Run setup, 07 Reward, 08 Shop, 09 Event, 10/11 Result
- design/round-a/a4-blend/A4 Run Screens 2.dc.html — 12 Pact, 13 Treasure, 14 In-run menu, 15 Abandon dialog
- design/round-a/a4-blend/A4 Boot and System.dc.html — 16 Boot, 17 Tutorial, 18 System
- design/round-a/a4-blend/A4 States.dc.html — remaining Must states as crops
- design/round-a/a4-blend/A4 Meta Screens.dc.html — 19–29 Should + Could
- design/round-a/assets/ — icons used by the frames
- design/_ds/… — Terrariums styles + bundle (fonts and tokens for the HTML preview)
- tokens.json · slices.json · motion.md · components.md · screens/<id>/spec.md
