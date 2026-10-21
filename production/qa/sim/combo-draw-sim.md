# Combo draw sim (gacha lane GD)

5000 Short runs per policy, seed base 1, real RunState + CoreOffer + tier chain, 4 milestone Core picks + Run Rule card, no fights. Quest bonus / shop / event Cores are not simulated (they only add draws, so these are lower bounds). Rerolls: 2 base + combo bonus.

## Policy: random

- Runs with >=1 combo (Pair or better): **29.6%**
- Runs with >=1 Full: **2.5%**
- Jackpot (Lunacia Rain): **0.00%**
- Avg combos formed per run: 0.33

| Combo | Formed % | Full % |
|---|---|---|
| Lunacia Rain | 0.0 | 0.0 |
| Golden Turtle Fortress | 2.0 | 0.0 |
| Toxic Bloom Guard | 4.9 | 0.2 |
| Golden Egg Blast | 1.7 | 0.1 |
| Rising Tide | 2.0 | 0.5 |
| Lakebed Fishing Rod | 1.4 | 0.0 |
| Shield Engine | 3.2 | 0.0 |
| Finishing Stroke | 1.6 | 0.6 |
| Ancient Turtle | 1.1 | 0.0 |
| Molting | 2.5 | 0.6 |
| Bramble Hide | 4.7 | 0.1 |
| Dice Rainbow | 2.5 | 0.3 |
| Slow Burn | 1.3 | 0.1 |
| Endless Mana Loop | 3.7 | 0.0 |

Cores picked in more than 60% of the offers where they appeared (shown >= 30):

- none

Every Core: tier / axis / cards shown per run (a Core can show twice in one run through rerolls):

| Core | Tier | Axis | Shown per 100 runs |
|---|---|---|---|
| c_backline_glow | H | pos | 89.0 |
| c_thorn_shield | H | stat | 76.6 |
| c_bastion | R | pos | 69.5 |
| c_collector | H | quest | 59.6 |
| c_mana_ward | H | mana | 57.6 |
| c_deep_current | T | mana | 51.1 |
| c_mana_pool | R | mana | 45.5 |
| c_toxic_still | T | dice | 41.9 |
| c_early_scales | R | stat | 41.7 |
| c_tidecaller | R | mana | 41.5 |
| c_sonic_shield | H | dice | 40.8 |
| c_living_wall | T | pos | 37.7 |
| c_prime_chain | R | dice | 36.1 |
| c_elder_trunk | R | stat | 35.9 |
| c_finisher | R | dice | 35.8 |
| c_spore_burst | R | rule | 31.1 |
| c_fossil | R | rule | 30.3 |
| c_three_dice | T | dice | 29.7 |
| c_overflow | H | mana | 29.7 |
| c_nest | R | rule | 29.1 |
| c_gatekeeper | H | pos | 28.5 |
| c_dewdrop | R | stat | 27.2 |
| c_descend | T | pos | 27.1 |
| c_chimera_hunt | H | quest | 25.1 |
| c_hollow_core | T | mana | 25.1 |
| c_growing_shell | H | pos | 20.4 |
| c_thorn_pact | H | mana | 17.0 |
| c_sixth_die | T | dice | 16.6 |
| c_sacrifice | T | rule | 15.4 |
| c_prism | H | dice | 15.2 |
| c_blood_sign | T | rule | 11.0 |
| c_fissure | H | dice | 9.8 |
| c_dim_stone | H | rule | 8.3 |
| c_cascade | T | rule | 8.0 |
| c_mirror_face | T | dice | 7.4 |
| c_plague_spread | H | dice | 7.0 |
| c_night_watch | H | quest | 6.5 |
| c_thorn_growth | H | pos | 5.6 |
| c_kindle | H | dice | 5.5 |
| c_golden_egg | H | rule | 5.4 |
| c_loop | T | rule | 5.3 |
| c_whittle | T | dice | 4.9 |
| c_field_medic | H | dice | 4.8 |
| c_steady_hold | H | dice | 2.5 |
| c_open_ranks | T | pos | 2.0 |
| c_key_strike | H | quest | 1.7 |
| c_concord | T | dice | 0.8 |
| c_thorn_rebound | T | rule | 0.8 |
| c_dry_well | H | quest | 0.0 |

## Policy: hunt

- Runs with >=1 combo (Pair or better): **71.9%**
- Runs with >=1 Full: **13.7%**
- Jackpot (Lunacia Rain): **0.00%**
- Avg combos formed per run: 0.89

| Combo | Formed % | Full % |
|---|---|---|
| Lunacia Rain | 0.0 | 0.0 |
| Golden Turtle Fortress | 7.2 | 0.0 |
| Toxic Bloom Guard | 11.2 | 1.8 |
| Golden Egg Blast | 7.3 | 2.7 |
| Rising Tide | 6.1 | 4.6 |
| Lakebed Fishing Rod | 3.1 | 0.0 |
| Shield Engine | 10.2 | 0.0 |
| Finishing Stroke | 3.3 | 0.1 |
| Ancient Turtle | 3.0 | 0.0 |
| Molting | 6.8 | 1.1 |
| Bramble Hide | 13.4 | 1.1 |
| Dice Rainbow | 3.8 | 1.4 |
| Slow Burn | 3.7 | 0.7 |
| Endless Mana Loop | 10.1 | 0.2 |

Cores picked in more than 60% of the offers where they appeared (shown >= 30):

- c_golden_egg: 363/365 = 99%
- c_thorn_rebound: 32/43 = 74%

Every Core: tier / axis / cards shown per run (a Core can show twice in one run through rerolls):

| Core | Tier | Axis | Shown per 100 runs |
|---|---|---|---|
| c_backline_glow | H | pos | 90.2 |
| c_thorn_shield | H | stat | 82.6 |
| c_bastion | R | pos | 69.3 |
| c_mana_ward | H | mana | 62.1 |
| c_collector | H | quest | 52.3 |
| c_deep_current | T | mana | 46.1 |
| c_early_scales | R | stat | 43.6 |
| c_sonic_shield | H | dice | 43.3 |
| c_toxic_still | T | dice | 41.2 |
| c_mana_pool | R | mana | 38.1 |
| c_tidecaller | R | mana | 37.2 |
| c_elder_trunk | R | stat | 37.2 |
| c_living_wall | T | pos | 34.2 |
| c_prime_chain | R | dice | 33.7 |
| c_finisher | R | dice | 33.5 |
| c_dewdrop | R | stat | 32.6 |
| c_spore_burst | R | rule | 29.7 |
| c_hollow_core | T | mana | 29.7 |
| c_nest | R | rule | 29.3 |
| c_overflow | H | mana | 29.1 |
| c_fossil | R | rule | 28.7 |
| c_three_dice | T | dice | 28.2 |
| c_gatekeeper | H | pos | 27.8 |
| c_descend | T | pos | 24.6 |
| c_chimera_hunt | H | quest | 20.6 |
| c_thorn_pact | H | mana | 19.5 |
| c_sixth_die | T | dice | 16.2 |
| c_prism | H | dice | 15.4 |
| c_growing_shell | H | pos | 14.8 |
| c_blood_sign | T | rule | 14.0 |
| c_sacrifice | T | rule | 14.0 |
| c_fissure | H | dice | 13.8 |
| c_dim_stone | H | rule | 12.1 |
| c_cascade | T | rule | 11.8 |
| c_mirror_face | T | dice | 8.5 |
| c_loop | T | rule | 7.9 |
| c_plague_spread | H | dice | 7.5 |
| c_golden_egg | H | rule | 7.3 |
| c_field_medic | H | dice | 6.8 |
| c_key_strike | H | quest | 6.0 |
| c_kindle | H | dice | 5.4 |
| c_whittle | T | dice | 5.1 |
| c_night_watch | H | quest | 3.5 |
| c_steady_hold | H | dice | 2.9 |
| c_thorn_growth | H | pos | 2.5 |
| c_dry_well | H | quest | 2.4 |
| c_thorn_rebound | T | rule | 0.9 |
| c_concord | T | dice | 0.7 |
| c_open_ranks | T | pos | 0.5 |


## Notes (GD lane)

- 5000 runs per policy, seed base 1. `random` = lower bound for a player who ignores combos; `hunt` = upper bound for one who always sees a completing card. Real players sit between: ~30% to ~70% of runs form at least one Pair, 2-14% a Full. Target was ~50% / ~10%: on target.
- First draft of `core_combos.json` (the 2.B table as written) formed under 1% for 7 of 14 combos when hunting, because their members are rarely offered (Kindle 4 per 100 runs, Key Strike 2.5, Plague Spread 8, Loop 8, and Moss Cores only show at pick 1 and sometimes 2). Members were swapped for Cores the offer shows often; every combo now forms in >= 3% of hunted runs (Lakebed 3.1, Ancient Turtle 3.0 are the lowest).
- Rewritten: Turtle Fortress (Living Wall + Thorn Shield, third Gatekeeper), Lakebed Fishing Rod (Hollow Core + Mana Ward, third Kindle), Shield Engine (was Lo Ru Tia Lua: Shield Wave + Thorn Shield, third Prime Chain), Ancient Turtle (Living Wall + Early Scales), Molting (Take The Field + Thorn Shield, third Bastion), Bramble Hide (was Blood Bargain: Elder Trunk + Thorn Shield), Dice Rainbow (Collector + Sixth Die, third Prism), Slow Burn (replaces Poison Garden: Overflow + Three Dice, third Dewdrop), Endless Mana Loop (Mana Pool + Deep Current, third Loop), Rising Tide (Rising Wave + Overflow). Poison Garden was dropped: the poison Cores need a poison-face team, so no poison Pair reached 1%.
- Names/themes for narrative to re-check. Thorn Shield now sits in 4 combos (Turtle, Shield Engine, Molting, Bramble): it is also the most shown Core, so the 60% pick check matters in playtests.
- Jackpot Lunacia Rain (Cascade + Sixth Die + Mirror Face, all Crystal) is ~0.0% from milestone picks alone (3 specific Crystal Cores out of a pool of 13 with a cap of 3). It is a real "someday" jackpot. CoreCombos counts any owned Core whatever its source (quest, shop, event), so those extra draws help, but this sim does not include them. Decision for Liam: keep as a legend, or lower it to 2 Crystal + 1 Amber.
- Cores picked in >60% of offers: only Golden Egg (99%, but it is shown mostly when a Pair needs it, 7 per 100 runs) under the hunt policy; no common Core over 60%.
- Hunter bias: ignore absolute shown% in the table for Cores that the hunter keeps completing.
