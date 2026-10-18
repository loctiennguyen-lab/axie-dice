# Handoff: Axie Dice UI-03 · A4 Blend · Round 2 (Godot)

Round 2 fills the gaps in round 1 (package design_handoff_axie_dice_ui03/). Same direction, tokens and rules. **Where this package and round 1 disagree, round 2 wins.**

## Start here
**AxieDice-UI03-A4-round2-all-screens.html** — one self-contained file (works offline) with every round 2 frame: Combat, Run, Account / Land / meta. The .dc.html sources are in design/round-a/a4-blend/ (A4 R2 Combat, A4 R2 Run, A4 R2 Meta; A4 Combat is included because the frames embed it).

## New components (listed first)
CostChip · TradeBox · SlotSwapSheet · IntentBadge · FloatText · StatusChip (extended) · PhaseBar · Tooltip · UnitInspector · AccountChip · SkyMavisBadge · StakeTableRow · Curtain · Undo button. Variants and states in components.md (top section). New tokens in tokens.json: color.gem_bg / gem_border / gem_text, trade_gain_bg / trade_cost_bg, intent_*, status_*_border, phase_tick; size.undo_btn, intent_badge_h, status_chip_h, float_0/1/2, float_stroke, cost_chip_h, tooltip_max_w, inspector_w, phase_bar_h, defeat_panel_w, slot_cell_min_h; motion.float_rise, phase_banner, tooltip_delay_ms, inspector_longpress_ms. motion.md is unchanged from round 1.

## Corrections to round 1
- Sign-in is required to play; dice are rolled on the server. No "Play as guest", no "Play offline". Signed out / expired: "Sign in to play". Guests can browse and read Echo Box rates.
- Session expired: "Your session expired. Sign in again to continue this run." (SIGN IN / BACK TO MENU). Same account → back into the run. Other account or run gone: "Your unfinished run is no longer open on the server, so it can't be continued." (BACK TO MENU).
- Crit: only party damage faces; chance = face crit keyword + relic bonuses, shown on the info panel.
- Rerolls are live n / max (base 2 + ascension + relics).
- Egg cap 4 by default (relics raise it). Keys: 1–5 Axie dice, R reroll, E or Space end turn, Z undo, A Aid, Esc menu. Egg dice by click.
- Boss has 3 phases; ticks from combat_tune.json phase_thresholds.
- Echo Box opens with Tickets (200 Shards, ×1.05 per buy). Season 1 Pass is free track only. Missions = Shard stake board (40); Daily claims are 41; round-1 22 is superseded.
- Aid hidden for the first 5 runs and in Mission runs. Moon Card shows "Coming soon" in L1.

## Screens
| # | Screen | Priority | Status |
|---|---|---|---|
| 30-defeat-panel | Defeat panel | Must | NEW |
| 31-reward-types | Reward types (Relic, HP, Reroll, Level, Ascend, Chaos, Curse) | Must | NEW |
| 32-slots-full | Slots full: swap / sell | Must | NEW |
| 33-axie-picker | Axie picker | Must | NEW |
| 34-presets-popup | Load / Save preset | Must | NEW |
| 35-leaderboard-popup | Leaderboard popup | Must | NEW |
| 36-toast-table | Copy by error code | Must | NEW |
| 37-tutorial-curtain | Tutorial curtain | Must | NEW |
| 38-tutorial-rewards | Tutorial rewards | Must | NEW |
| 39-aid-zone | Aid zone | Should | NEW |
| 40-missions | Missions stake board | Should | NEW (replaces 22) |
| 41-daily | Daily | Should | NEW |
| 42-unit-inspector | Unit inspector (right-click, I, long-press) | Should | NEW |
| 43-tooltips | Tooltips | Should | NEW |
| 44-preset-editor | Preset editor + slot picker | Should | NEW |
| 45-victory-march | Victory march | Could | NEW |
| 46-battle-backdrop | Battle backdrop (3D arena replaces 2D) | Could | NEW, spec only |
| 01, 02, 06, 10, 12, 13, 14, 16, 18, 20, 21, 22, 23, 24, 25, 26, 27, 29 | round-1 screens | — | UPDATED: full spec copied here, changes in "Round 2 changes (marked)" at the end |

## Data sources
assets/data/economy/*.json (aid_prices, missions, daily, gem, echobox, pass_v2, land_tiers, ascension_titles), rules/combat_tune.json, rules/mission_rules.json, atia/arenas.json, scripts aid_catalog.gd, reward_generator.gd, relic_slots.gd, combat_engine.gd, run_session.gd, desktop_auth.gd, plus Liam's answers (R5, rule sets, run length, unlocks, guides, session, Moon Card).

## Open flags
- M6 and M7 have no names yet.
- Unlock price currency not stated.
- Copy marked "mine" in specs (recap labels, fairness line, error toasts, tutorial curtain) needs review.
- Ticket, Pass XP, Sky Mavis badge art still missing.

## Files
- AxieDice-UI03-A4-round2-all-screens.html
- screens/<id>/spec.md (17 new + 18 updated)
- tokens.json · components.md · motion.md · slices.json (empty, no textures)
- design/round-a/a4-blend/A4 R2 Combat.dc.html · A4 R2 Run.dc.html · A4 R2 Meta.dc.html · A4 R2 All Screens.dc.html · A4 Combat.dc.html · support.js · a4-assets.js
- design/round-a/assets/ · design/_ds/…
