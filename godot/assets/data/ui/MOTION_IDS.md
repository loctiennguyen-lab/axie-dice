# Motion ids (UI-04 round 1)

Play with `UI3Motion.play("<id>", node, opts)` (opts: `hold_ms`, `skip`, `on_done`, `scale_ms`, `reduced`).
Table: `motion_ui3.json`. Every row carries `trigger`, `skip`, `reduce_flash`, `sfx_name` (design name, not played yet) and
`_note` with the motion.md text. `star` = a moment: any click or Space must call it again with `opts.skip = true`
(or pass `skip` on the first call). Reduce motion is applied inside `play()`.
Fields the engine does NOT run yet (the screen plays them): `delay_per_index_ms`, `fly_to*`, `count_up_ms`, `number_pop`,
`slowmo`, `camera_push_in`, `rays`, `wobble`, `hop`, `squash`, `pulse`, `flip_x`, `scrim_*`, `reveal_card`.
Helpers: `UI3Motion.hitstop(node, ms)` (restore timer on the SceneTree, capped at 200 ms; `end_hitstop()` restores
at once), `UI3Motion.sweep(parent, delay_ms, ms, width, alpha, color_token, fade)`.

## UI-05 timelines (batch 1 combat moments)
The ten combat moments (`hit`, `crit`, `big_hit`, `axie_ko`, `shield_gain`, `turn_banner_player`,
`turn_banner_enemy`, `intent_reveal`, `boss_phase`, `victory`, `defeat`) carry a `layers` array: one row per layer of
`design/handoffs/ui-05-figma/round-1/motion-batch1.md`, same ms / delay / trans / ease / values / Reduce-motion rule.
Play with `UI3Motion.play_timeline(id, {target: node}, opts)` (opts: `host`, `shake` Callable(px, sec), `only` /
`except` layer names, `reduced`, `skip`, `on_done`); it returns a `UI3Motion.Timeline` (`skip()`, `done`, `finished`).
Keyframe `t` is a share of the layer's time; trans/ease shape each segment. Layers whose target is a 3D node or
another lane's node (`enemy_3d`, `hp_fill`, `card`, ...) are data only. The combat screen plays them through
`scenes/combat/ui5/U5Moments.gd` (+ `U5TurnBanner`, `U5VictoryBand`, `U5KoStamp`, `U5SkipCatcher`).
Gate: `t_reduce_motion_rest` checks every row against the tables.

## 02-combat / 30-defeat-panel
- `die_select`, `die_drop`, `die_used`
- `hit`, `crit`, `big_hit`
- `axie_ko`, `shield_gain`
- `turn_banner_player`, `turn_banner_enemy` (the old `turn_banner` and `combo_banner` stay as they were)
- `intent_reveal`, `attrition_card`
- `boss_phase`, `waiting_server`
- `boss_intro_band` (boss fight start, before Your turn; `U5BossBand`)
- `victory`, `defeat`

## 03-run-map / 47-core-offer / 48-anchor-pick / 49-anchor-awaken (run) - UI-05 b23 lane M2
Six timeline ids (`layers` rows from `round-2/motion-batch2.md`), played with `UI3Motion.play_timeline`:
- `core-reveal` (47: name punch, sparks, Crystal shake; GachaReveal still owns backs / aura / flips; `RunMapOffers._play_reveal_moment`)
- `core-taken` (47 take beat; `RunMapController._apply_and_finish`)
- `reward-taken` (31 take beat; same hook)
- `treasure-open` (treasure chest; `RunMapTreasure._build_treasure`)
- `level-up` (level-up banner)
- `anchor-awaken` (49; `AnchorFx`)
Rows with `"flash": true` are dropped with Reduce flashing (sparks, shakes, rays, screen flash).
Legacy (single-row ids, nobody calls them any more; kept only because tests read the table):
`core_reveal_moss`, `core_reveal_amber`, `core_reveal_crystal`, `gacha_flip`, `core_take`, `anchor_awaken`,
`level_up`, `reward_take`, `treasure_open`.

## 20-echo-box
- `echo_idle`, `echo_open`, `echo_dupe`, `echo_rare`, `echo_open10`

## 21-season-pass / 40-missions / 10-result / 01-land-hub
- `pass_level_up`
- `daily_claim` (01-land-hub / daily)
- `land_tier_up` (01-land-hub)
- `currency_gain` (any HUD chip)
- `run_end_win`, `run_end_lose` (10-result)

## Meta moments (UI-05 b23 lane M3, `round-3/motion-batch3.md`)
Eleven timeline ids, played with `UI3Motion.play_timeline` (screen in brackets):
- `land-tier-up` (Land banner: `LandHud.show_tier_banner`; the Upgrade-screen layers press / confirm_out / stone_count / stone_pulse
  are data because the scene changes at once), `currency-gain` (data + helper; no HUD chip hook yet)
- `run-end-win`, `run-end-lose` (`ResultView`)
- `echo-open-normal`, `echo-open-dup`, `echo-open-rare`, `echo-open-mythic`, `open-10` (`EchoBoxCeremony`; the chest tint and
  title swap times are read from the row)
- `pass-level-up` (`PassView`), `daily-claim` (`DailyScreen`)
New layer kind `count`: number tween on a Label (`prefix` + thousands comma + `suffix`). The screen passes the numbers:
`opts.counts = {layer_name: [from, to]}` (or `opts.count_cb` Callable(layer_name, int)); the row owns ms / delay / easing.
Rows with `"proposal": true` are PROPOSAL (rays, sparks, gold ring, Mythic hit-stop + shake, Rare+ rays/sparks): they never run
unless `UI3Motion.proposals_enabled` is set (tests only). Reduce flashing drops rows with `"flash": true`.
Layers with `"owner": "data"` have no node in Godot yet (XP bar, Fragment meter, Back button unlock).

## 18-system
- `toast`, `net_notice`, `update_bar`
