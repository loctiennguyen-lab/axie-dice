# Motion ids (UI-04 round 1)

Play with `UI3Motion.play("<id>", node, opts)` (opts: `hold_ms`, `skip`, `on_done`, `scale_ms`, `reduced`).
Table: `motion_ui3.json`. Every row carries `trigger`, `skip`, `reduce_flash`, `sfx_name` (design name, not played yet) and
`_note` with the motion.md text. `star` = a moment: any click or Space must call it again with `opts.skip = true`
(or pass `skip` on the first call). Reduce motion is applied inside `play()`.
Fields the engine does NOT run yet (the screen plays them): `delay_per_index_ms`, `fly_to*`, `count_up_ms`, `number_pop`,
`slowmo`, `camera_push_in`, `rays`, `wobble`, `hop`, `squash`, `pulse`, `flip_x`, `scrim_*`, `reveal_card`.
Helpers: `UI3Motion.hitstop(node, ms)`, `UI3Motion.sweep(parent, delay_ms)`.

## 02-combat / 30-defeat-panel
- `die_select`, `die_drop`, `die_used`
- `hit`, `crit`, `big_hit`
- `axie_ko`, `shield_gain`
- `turn_banner_player`, `turn_banner_enemy` (the old `turn_banner` and `combo_banner` stay as they were)
- `intent_reveal`, `attrition_card`
- `boss_phase`, `waiting_server`
- `victory`, `defeat`

## 03-run-map / 47-core-offer / 48-anchor-pick / 49-anchor-awaken (run)
- `core_reveal_moss`, `core_reveal_amber`, `core_reveal_crystal`
- `gacha_flip`, `core_take`
- `anchor_awaken`
- `level_up`, `reward_take`, `treasure_open`

## 20-echo-box
- `echo_idle`, `echo_open`, `echo_dupe`, `echo_rare`, `echo_open10`

## 21-season-pass / 40-missions / 10-result / 01-land-hub
- `pass_level_up`
- `daily_claim` (01-land-hub / daily)
- `land_tier_up` (01-land-hub)
- `currency_gain` (any HUD chip)
- `run_end_win`, `run_end_lose` (10-result)

## 18-system
- `toast`, `net_notice`, `update_bar`
