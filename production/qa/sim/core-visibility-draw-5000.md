# Combo draw sim (gacha lane GD)

5000 Short runs per policy, seed base 1, real RunState + CoreOffer + tier chain, 4 milestone Core picks + Run Rule card, no fights. Quest bonus / shop / event Cores are not simulated (they only add draws, so these are lower bounds). Rerolls: 2 base + combo bonus.

## Policy: random

- Runs with >=1 combo (Pair or better): **28.8%**
- Runs with >=1 Full: **2.1%**
- Jackpot (Lunacia Rain): **0.00%**
- Runs holding 2 of the 3 jackpot Cores: 0.70%
- Avg combos formed per run: 0.32

| Combo | Formed % | Full % |
|---|---|---|
| Lunacia Rain | 0.0 | 0.0 |
| Golden Turtle Fortress | 1.9 | 0.0 |
| Toxic Bloom Guard | 4.9 | 0.2 |
| Golden Egg Blast | 1.5 | 0.1 |
| Rising Tide | 2.0 | 0.5 |
| Lakebed Fishing Rod | 1.4 | 0.0 |
| Shield Engine | 3.2 | 0.0 |
| Finishing Stroke | 0.9 | 0.1 |
| Ancient Turtle | 1.1 | 0.0 |
| Molting | 2.4 | 0.6 |
| Bramble Hide | 4.7 | 0.1 |
| Dice Rainbow | 2.5 | 0.3 |
| Slow Burn | 1.2 | 0.1 |
| Endless Mana Loop | 3.8 | 0.0 |

Cores picked in more than 60% of the offers where they appeared (shown >= 30):

- none

Every Core: tier / axis / cards shown per run (a Core can show twice in one run through rerolls):

| Core | Tier | Axis | Shown per 100 runs | % runs shown >=1 | Picked % of runs |
|---|---|---|---|---|---|
| c_backline_glow | H | pos | 89.3 | 89.3 | 30.1 |
| c_thorn_shield | H | stat | 76.6 | 76.6 | 25.0 |
| c_bastion | R | pos | 69.7 | 69.7 | 22.8 |
| c_collector | H | quest | 59.6 | 59.6 | 19.8 |
| c_mana_ward | H | mana | 57.7 | 57.7 | 18.4 |
| c_deep_current | T | mana | 50.8 | 50.8 | 15.9 |
| c_mana_pool | R | mana | 45.9 | 45.9 | 15.3 |
| c_toxic_still | T | dice | 42.0 | 42.0 | 14.0 |
| c_tidecaller | R | mana | 41.7 | 41.7 | 14.3 |
| c_early_scales | R | stat | 41.6 | 41.6 | 14.1 |
| c_sonic_shield | H | dice | 40.7 | 40.7 | 13.8 |
| c_living_wall | T | pos | 37.3 | 37.3 | 11.7 |
| c_elder_trunk | R | stat | 36.0 | 36.0 | 12.2 |
| c_three_dice | T | dice | 29.8 | 29.8 | 9.8 |
| c_overflow | H | mana | 29.7 | 29.7 | 9.6 |
| c_gatekeeper | H | pos | 28.9 | 28.9 | 9.2 |
| c_fossil | R | rule | 28.1 | 28.1 | 8.4 |
| c_dewdrop | R | stat | 27.2 | 27.2 | 8.5 |
| c_nest | R | rule | 27.2 | 27.2 | 8.8 |
| c_descend | T | pos | 26.9 | 26.9 | 8.6 |
| c_hollow_core | T | mana | 24.7 | 24.7 | 8.0 |
| c_chimera_hunt | H | quest | 24.5 | 24.5 | 8.5 |
| c_finisher | R | dice | 22.0 | 22.0 | 6.5 |
| c_spore_burst | R | rule | 21.3 | 21.3 | 7.0 |
| c_growing_shell | H | pos | 20.2 | 20.2 | 6.1 |
| c_prime_chain | R | dice | 18.4 | 18.4 | 5.8 |
| c_thorn_pact | H | mana | 16.8 | 16.8 | 5.0 |
| c_sixth_die | T | dice | 16.6 | 16.6 | 5.7 |
| c_meme_nametag | R | rule | 16.4 | 16.4 | 5.3 |
| c_meme_copycat | R | dice | 16.3 | 16.3 | 5.3 |
| c_sacrifice | T | rule | 15.6 | 15.6 | 5.0 |
| c_meme_jumpy | R | dice | 15.2 | 15.2 | 5.1 |
| c_prism | H | dice | 15.1 | 15.1 | 5.1 |
| c_blood_sign | T | rule | 10.4 | 10.4 | 3.3 |
| c_fissure | H | dice | 9.8 | 9.8 | 3.0 |
| c_dim_stone | H | rule | 8.1 | 8.1 | 2.8 |
| c_cascade | T | rule | 8.0 | 8.0 | 2.2 |
| c_mirror_face | T | dice | 7.4 | 7.4 | 2.8 |
| c_plague_spread | H | dice | 7.0 | 7.0 | 2.4 |
| c_night_watch | H | quest | 6.5 | 6.5 | 2.2 |
| c_thorn_growth | H | pos | 5.6 | 5.6 | 2.0 |
| c_kindle | H | dice | 5.5 | 5.5 | 1.5 |
| c_loop | T | rule | 5.4 | 5.4 | 1.9 |
| c_field_medic | H | dice | 4.8 | 4.8 | 1.7 |
| c_whittle | T | dice | 4.8 | 4.8 | 1.5 |
| c_golden_egg | H | rule | 4.1 | 4.1 | 1.5 |
| c_steady_hold | H | dice | 2.5 | 2.5 | 0.7 |
| c_open_ranks | T | pos | 2.0 | 2.0 | 0.6 |
| c_key_strike | H | quest | 1.8 | 1.8 | 0.7 |
| c_thorn_rebound | T | rule | 0.8 | 0.8 | 0.3 |
| c_concord | T | dice | 0.8 | 0.8 | 0.3 |
| c_dry_well | H | quest | 0.1 | 0.1 | 0.0 |

## Policy: hunt

- Runs with >=1 combo (Pair or better): **69.0%**
- Runs with >=1 Full: **12.2%**
- Jackpot (Lunacia Rain): **0.12%**
- Runs holding 2 of the 3 jackpot Cores: 2.76%
- Avg combos formed per run: 0.86

| Combo | Formed % | Full % |
|---|---|---|
| Lunacia Rain | 0.1 | 0.1 |
| Golden Turtle Fortress | 6.9 | 0.0 |
| Toxic Bloom Guard | 11.9 | 1.9 |
| Golden Egg Blast | 4.9 | 1.1 |
| Rising Tide | 6.2 | 4.6 |
| Lakebed Fishing Rod | 3.5 | 0.0 |
| Shield Engine | 10.4 | 0.0 |
| Finishing Stroke | 2.6 | 0.1 |
| Ancient Turtle | 3.0 | 0.0 |
| Molting | 5.9 | 1.2 |
| Bramble Hide | 12.9 | 0.9 |
| Dice Rainbow | 4.1 | 1.3 |
| Slow Burn | 3.6 | 0.6 |
| Endless Mana Loop | 10.5 | 0.2 |

Cores picked in more than 60% of the offers where they appeared (shown >= 30):

- c_golden_egg: 246/249 = 99%

Every Core: tier / axis / cards shown per run (a Core can show twice in one run through rerolls):

| Core | Tier | Axis | Shown per 100 runs | % runs shown >=1 | Picked % of runs |
|---|---|---|---|---|---|
| c_backline_glow | H | pos | 90.2 | 90.2 | 30.9 |
| c_thorn_shield | H | stat | 81.9 | 81.9 | 35.4 |
| c_bastion | R | pos | 69.4 | 69.4 | 10.9 |
| c_mana_ward | H | mana | 63.0 | 63.0 | 15.9 |
| c_collector | H | quest | 52.3 | 52.3 | 14.5 |
| c_deep_current | T | mana | 47.3 | 47.3 | 18.2 |
| c_sonic_shield | H | dice | 43.6 | 43.6 | 24.5 |
| c_early_scales | R | stat | 42.0 | 42.0 | 9.6 |
| c_toxic_still | T | dice | 41.2 | 41.2 | 7.4 |
| c_mana_pool | R | mana | 38.1 | 38.1 | 14.0 |
| c_tidecaller | R | mana | 37.2 | 37.2 | 12.8 |
| c_elder_trunk | R | stat | 36.3 | 36.3 | 14.6 |
| c_living_wall | T | pos | 35.2 | 35.2 | 12.9 |
| c_dewdrop | R | stat | 32.4 | 32.4 | 9.7 |
| c_overflow | H | mana | 29.8 | 29.8 | 14.2 |
| c_hollow_core | T | mana | 28.9 | 28.9 | 7.1 |
| c_three_dice | T | dice | 28.8 | 28.8 | 7.8 |
| c_gatekeeper | H | pos | 27.2 | 27.2 | 5.4 |
| c_fossil | R | rule | 26.7 | 26.7 | 10.2 |
| c_nest | R | rule | 26.3 | 26.3 | 9.0 |
| c_descend | T | pos | 23.9 | 23.9 | 10.2 |
| c_chimera_hunt | H | quest | 22.2 | 22.2 | 7.1 |
| c_finisher | R | dice | 21.5 | 21.5 | 8.8 |
| c_spore_burst | R | rule | 20.7 | 20.7 | 8.4 |
| c_meme_nametag | R | rule | 19.8 | 19.8 | 5.6 |
| c_prime_chain | R | dice | 18.2 | 18.2 | 6.4 |
| c_thorn_pact | H | mana | 18.1 | 18.1 | 5.0 |
| c_meme_copycat | R | dice | 17.3 | 17.3 | 5.9 |
| c_sixth_die | T | dice | 16.3 | 16.3 | 7.3 |
| c_growing_shell | H | pos | 15.9 | 15.9 | 2.2 |
| c_meme_jumpy | R | dice | 15.8 | 15.8 | 6.0 |
| c_prism | H | dice | 14.7 | 14.7 | 6.5 |
| c_blood_sign | T | rule | 13.7 | 13.7 | 6.2 |
| c_sacrifice | T | rule | 12.7 | 12.7 | 2.8 |
| c_dim_stone | H | rule | 11.0 | 11.0 | 1.3 |
| c_fissure | H | dice | 10.9 | 10.9 | 3.4 |
| c_cascade | T | rule | 10.6 | 10.6 | 3.2 |
| c_mirror_face | T | dice | 8.7 | 8.7 | 2.2 |
| c_loop | T | rule | 6.9 | 6.9 | 2.3 |
| c_plague_spread | H | dice | 6.9 | 6.9 | 1.4 |
| c_kindle | H | dice | 6.0 | 6.0 | 1.3 |
| c_field_medic | H | dice | 5.7 | 5.7 | 1.7 |
| c_key_strike | H | quest | 5.5 | 5.5 | 0.9 |
| c_whittle | T | dice | 5.3 | 5.3 | 0.8 |
| c_golden_egg | H | rule | 5.0 | 5.0 | 4.9 |
| c_night_watch | H | quest | 4.1 | 4.1 | 0.8 |
| c_thorn_growth | H | pos | 3.0 | 3.0 | 0.7 |
| c_steady_hold | H | dice | 2.5 | 2.5 | 0.5 |
| c_dry_well | H | quest | 2.4 | 2.4 | 0.2 |
| c_concord | T | dice | 0.7 | 0.7 | 0.1 |
| c_thorn_rebound | T | rule | 0.6 | 0.6 | 0.5 |
| c_open_ranks | T | pos | 0.6 | 0.6 | 0.1 |

