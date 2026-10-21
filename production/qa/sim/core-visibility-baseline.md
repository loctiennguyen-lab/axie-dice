# Core visibility baseline (nhom S, sim da sua, knob hien tai, RULES -r)

Nguon: sim rut the 5000 run Short (`core-visibility-draw-5000.md`), sim danh expert 400 run + random_legal 400 run (10 lo x 40, A0, doi `all`, chon Loi `random` de ty le chon khong bi lech). Raw: `sim-2026-10-21-cvb_{expert,random}_all.{csv,md}`.

## Sua sim
- S1: fire dem theo `_core_fired_seen` ca run (fossil, dim_stone nay dem dung). S4: win-khi-co tinh theo Loi da chon (fossil khong con 0/96).
- S2: expert Hold dice khi co c_steady_hold/c_kindle/rule_tundra (`--corehold=0` tat).
- S3, loi sim tim ra: sim mute `CoreHooks` quanh reroll/Mat Tam/Overcast that, nen moi core_fired do reroll bi nuot (c_tidecaller 0%); va khong mute use_die thu trong beam search nen fire gia. Da sua ca hai. Them `--force=id,..` de chan doan (ep so huu).

## Doi chieu c_toxic_still
Sim rut the: 42% run co hien (cot moi `% runs shown`). sim_balance ~7%: bot chet som nen khong toi het 4 moc chon, sim rut the thi ep du 4 pick + the Luat. Khong dem trung; khac nhau o ty le song sot toi moc chon.


## Bang moi Loi: expert (400 run)

| id | truc | bac | %run hien | %duoc chon khi hien | %run chon | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 51.2% | 32% | 16.2% | 100% | 27.7% (18/65) |  |
| c_dewdrop | stat | 0 | 49.2% | 30% | 15.0% | 100% | 18.3% (11/60) |  |
| c_elder_trunk | stat | 0 | 46.5% | 33% | 15.5% | 100% | 24.2% (15/62) |  |
| c_prime_chain | dice | 0 | 26.8% | 27% | 7.2% | 90% | 20.7% (6/29) |  |
| c_finisher | dice | 0 | 22.8% | 29% | 6.5% | 100% | 11.5% (3/26) |  |
| c_bastion | pos | 0 | 68.8% | 32% | 22.0% | 100% | 9.1% (8/88) |  |
| c_tidecaller | mana | 0 | 49.8% | 36% | 18.0% | 50% | 11.1% (8/72) |  |
| c_mana_pool | mana | 0 | 46.0% | 36% | 16.8% | 85% | 13.4% (9/67) |  |
| c_nest | rule | 0 | 43.2% | 39% | 16.8% | 100% | 20.9% (14/67) |  |
| c_spore_burst | rule | 0 | 34.5% | 30% | 10.2% | 100% | 61.0% (25/41) |  |
| c_fossil | rule | 0 | 25.8% | 30% | 7.8% | 97% | 12.9% (4/31) |  |
| c_meme_copycat | dice | 0 | 22.5% | 37% | 8.2% | 94% | 18.2% (6/33) |  |
| c_meme_nametag | rule | 0 | 37.5% | 35% | 13.0% | 94% | 19.2% (10/52) |  |
| c_meme_jumpy | dice | 0 | 21.5% | 29% | 6.2% | 100% | 16.0% (4/25) |  |
| rule_none | run_rule | 0 | 8.0% | 53% | 4.2% | 0% | 11.8% (2/17) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.5% | 54% | 6.2% | 84% | 8.0% (2/25) |  |
| rule_tundra | run_rule | 0 | 13.2% | 51% | 6.8% | 100% | 3.7% (1/27) |  |
| rule_quick_beat | run_rule | 0 | 12.0% | 52% | 6.2% | 96% | 4.0% (1/25) |  |
| rule_starfall | run_rule | 0 | 10.5% | 48% | 5.0% | 100% | 10.0% (2/20) |  |
| rule_heavy_finish | run_rule | 0 | 9.8% | 56% | 5.5% | 100% | 13.6% (3/22) | LOW |
| rule_wasteland | run_rule | 0 | 12.5% | 58% | 7.2% | 100% | 13.8% (4/29) |  |
| rule_dry_steppe | run_rule | 0 | 15.5% | 56% | 8.8% | 100% | 8.6% (3/35) |  |
| rule_rising_tide | run_rule | 0 | 15.5% | 52% | 8.0% | 100% | 18.8% (6/32) |  |
| rule_upside_down | run_rule | 0 | 12.8% | 57% | 7.2% | 100% | 20.7% (6/29) |  |
| rule_old_forest | run_rule | 0 | 20.5% | 45% | 9.2% | 100% | 21.6% (8/37) |  |
| rule_crow | run_rule | 0 | 11.8% | 38% | 4.5% | 100% | 16.7% (3/18) |  |
| rule_hard_shell | run_rule | 0 | 18.2% | 48% | 8.8% | 100% | 17.1% (6/35) |  |
| rule_balance | run_rule | 0 | 28.2% | 43% | 12.2% | 100% | 14.3% (7/49) |  |
| c_prism | dice | 1 | 9.8% | 31% | 3.0% | 33% | 0.0% (0/12) | LOW |
| c_steady_hold | dice | 1 | 10.8% | 28% | 3.0% | 100% | 8.3% (1/12) |  |
| c_kindle | dice | 1 | 11.0% | 45% | 5.0% | 95% | 15.0% (3/20) |  |
| c_sonic_shield | dice | 1 | 11.5% | 30% | 3.5% | 93% | 35.7% (5/14) |  |
| c_fissure | dice | 1 | 6.5% | 27% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_field_medic | dice | 1 | 10.2% | 32% | 3.2% | 100% | 7.7% (1/13) |  |
| c_plague_spread | dice | 1 | 5.5% | 32% | 1.8% | 86% | 28.6% (2/7) | LOW |
| c_gatekeeper | pos | 1 | 21.0% | 36% | 7.5% | 100% | 13.3% (4/30) |  |
| c_thorn_growth | pos | 1 | 25.8% | 36% | 9.2% | 97% | 18.9% (7/37) |  |
| c_thorn_shield | stat | 1 | 72.8% | 31% | 22.2% | 92% | 19.1% (17/89) |  |
| c_growing_shell | pos | 1 | 20.5% | 26% | 5.2% | 90% | 9.5% (2/21) |  |
| c_backline_glow | pos | 1 | 27.5% | 34% | 9.2% | 92% | 13.5% (5/37) |  |
| c_mana_ward | mana | 1 | 28.5% | 28% | 8.0% | 72% | 12.5% (4/32) |  |
| c_overflow | mana | 1 | 25.0% | 35% | 8.8% | 60% | 14.3% (5/35) |  |
| c_thorn_pact | mana | 1 | 23.2% | 29% | 6.8% | 89% | 14.8% (4/27) |  |
| c_dry_well | quest | 1 | 22.0% | 31% | 6.8% | 100% | 18.5% (5/27) |  |
| c_night_watch | quest | 1 | 24.5% | 35% | 8.5% | 100% | 29.4% (10/34) |  |
| c_key_strike | quest | 1 | 21.2% | 29% | 6.2% | 16% | 4.0% (1/25) |  |
| c_collector | quest | 1 | 18.5% | 32% | 6.0% | 100% | 16.7% (4/24) |  |
| c_chimera_hunt | quest | 1 | 24.2% | 31% | 7.5% | 63% | 10.0% (3/30) |  |
| c_golden_egg | rule | 1 | 8.2% | 30% | 2.5% | 60% | 30.0% (3/10) | LOW |
| c_dim_stone | rule | 1 | 13.8% | 33% | 4.5% | 100% | 5.6% (1/18) |  |
| c_mirror_face | dice | 2 | 11.2% | 40% | 4.5% | 100% | 22.2% (4/18) |  |
| c_sixth_die | dice | 2 | 9.2% | 41% | 3.8% | 100% | 20.0% (3/15) | LOW |
| c_whittle | dice | 2 | 13.0% | 33% | 4.2% | 100% | 23.5% (4/17) |  |
| c_three_dice | dice | 2 | 11.5% | 46% | 5.2% | 100% | 4.8% (1/21) |  |
| c_concord | dice | 2 | 8.0% | 38% | 3.0% | 100% | 0.0% (0/12) | LOW |
| c_toxic_still | dice | 2 | 6.8% | 11% | 0.8% | 100% | 0.0% (0/3) | LOW |
| c_living_wall | pos | 2 | 32.8% | 31% | 10.2% | 100% | 14.6% (6/41) |  |
| c_thorn_rebound | rule | 2 | 14.5% | 38% | 5.5% | 77% | 0.0% (0/22) |  |
| c_open_ranks | pos | 2 | 4.8% | 32% | 1.5% | 100% | 16.7% (1/6) | LOW |
| c_descend | pos | 2 | 15.8% | 29% | 4.5% | 94% | 11.1% (2/18) |  |
| c_hollow_core | mana | 2 | 23.2% | 28% | 6.5% | 85% | 23.1% (6/26) |  |
| c_deep_current | mana | 2 | 31.0% | 35% | 10.8% | 74% | 23.3% (10/43) |  |
| c_blood_sign | rule | 2 | 8.8% | 29% | 2.5% | 100% | 20.0% (2/10) | LOW |
| c_loop | rule | 2 | 13.0% | 31% | 4.0% | 94% | 12.5% (2/16) |  |
| c_cascade | rule | 2 | 15.5% | 40% | 6.2% | 100% | 20.0% (5/25) |  |
| c_sacrifice | rule | 2 | 14.8% | 39% | 5.8% | 100% | 4.3% (1/23) |  |

## Bang moi Loi: random_legal (400 run)

| id | truc | bac | %run hien | %duoc chon khi hien | %run chon | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 39.5% | 28% | 11.0% | 100% | 20.5% (9/44) |  |
| c_dewdrop | stat | 0 | 38.8% | 37% | 14.2% | 100% | 10.5% (6/57) |  |
| c_elder_trunk | stat | 0 | 40.5% | 28% | 11.5% | 100% | 19.6% (9/46) |  |
| c_prime_chain | dice | 0 | 22.2% | 31% | 7.0% | 100% | 7.1% (2/28) |  |
| c_finisher | dice | 0 | 22.2% | 35% | 7.8% | 97% | 3.2% (1/31) |  |
| c_bastion | pos | 0 | 65.2% | 33% | 21.2% | 99% | 9.4% (8/85) |  |
| c_tidecaller | mana | 0 | 47.2% | 42% | 19.8% | 8% | 10.1% (8/79) |  |
| c_mana_pool | mana | 0 | 38.5% | 31% | 11.8% | 94% | 8.5% (4/47) |  |
| c_nest | rule | 0 | 34.8% | 31% | 10.8% | 100% | 14.0% (6/43) |  |
| c_spore_burst | rule | 0 | 31.0% | 30% | 9.2% | 100% | 35.1% (13/37) |  |
| c_fossil | rule | 0 | 24.0% | 32% | 7.8% | 81% | 9.7% (3/31) |  |
| c_meme_copycat | dice | 0 | 23.8% | 36% | 8.5% | 79% | 11.8% (4/34) |  |
| c_meme_nametag | rule | 0 | 26.8% | 35% | 9.2% | 95% | 13.5% (5/37) |  |
| c_meme_jumpy | dice | 0 | 22.0% | 30% | 6.5% | 100% | 11.5% (3/26) |  |
| rule_none | run_rule | 0 | 8.8% | 37% | 3.2% | 0% | 7.7% (1/13) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.8% | 57% | 7.2% | 93% | 3.4% (1/29) |  |
| rule_tundra | run_rule | 0 | 11.5% | 50% | 5.8% | 0% | 4.3% (1/23) | DEAD |
| rule_quick_beat | run_rule | 0 | 15.8% | 54% | 8.5% | 85% | 11.8% (4/34) |  |
| rule_starfall | run_rule | 0 | 12.8% | 55% | 7.0% | 100% | 14.3% (4/28) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 55% | 6.0% | 100% | 8.3% (2/24) |  |
| rule_wasteland | run_rule | 0 | 11.2% | 44% | 5.0% | 100% | 10.0% (2/20) |  |
| rule_dry_steppe | run_rule | 0 | 11.8% | 51% | 6.0% | 100% | 4.2% (1/24) |  |
| rule_rising_tide | run_rule | 0 | 12.0% | 60% | 7.2% | 100% | 17.2% (5/29) |  |
| rule_upside_down | run_rule | 0 | 11.8% | 47% | 5.5% | 100% | 9.1% (2/22) |  |
| rule_old_forest | run_rule | 0 | 21.5% | 49% | 10.5% | 100% | 11.9% (5/42) |  |
| rule_crow | run_rule | 0 | 11.0% | 45% | 5.0% | 70% | 5.0% (1/20) |  |
| rule_hard_shell | run_rule | 0 | 21.2% | 35% | 7.5% | 100% | 16.7% (5/30) |  |
| rule_balance | run_rule | 0 | 27.0% | 57% | 15.5% | 100% | 4.8% (3/62) |  |
| c_prism | dice | 1 | 9.5% | 45% | 4.2% | 65% | 11.8% (2/17) | LOW |
| c_steady_hold | dice | 1 | 9.0% | 25% | 2.2% | 0% | 11.1% (1/9) | LOW DEAD |
| c_kindle | dice | 1 | 8.2% | 33% | 2.8% | 0% | 0.0% (0/11) | LOW DEAD |
| c_sonic_shield | dice | 1 | 8.0% | 25% | 2.0% | 100% | 37.5% (3/8) | LOW |
| c_fissure | dice | 1 | 8.5% | 26% | 2.2% | 100% | 11.1% (1/9) | LOW |
| c_field_medic | dice | 1 | 8.8% | 37% | 3.2% | 100% | 7.7% (1/13) | LOW |
| c_plague_spread | dice | 1 | 5.2% | 33% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_gatekeeper | pos | 1 | 17.0% | 24% | 4.0% | 100% | 18.8% (3/16) |  |
| c_thorn_growth | pos | 1 | 16.5% | 45% | 7.5% | 100% | 26.7% (8/30) |  |
| c_thorn_shield | stat | 1 | 57.5% | 26% | 14.8% | 98% | 23.7% (14/59) |  |
| c_growing_shell | pos | 1 | 19.8% | 35% | 7.0% | 61% | 17.9% (5/28) |  |
| c_backline_glow | pos | 1 | 18.5% | 34% | 6.2% | 92% | 16.0% (4/25) |  |
| c_mana_ward | mana | 1 | 22.2% | 39% | 8.8% | 77% | 22.9% (8/35) |  |
| c_overflow | mana | 1 | 19.5% | 33% | 6.5% | 65% | 7.7% (2/26) |  |
| c_thorn_pact | mana | 1 | 16.2% | 40% | 6.5% | 96% | 15.4% (4/26) |  |
| c_dry_well | quest | 1 | 16.5% | 41% | 6.8% | 100% | 14.8% (4/27) |  |
| c_night_watch | quest | 1 | 16.8% | 39% | 6.5% | 100% | 19.2% (5/26) |  |
| c_key_strike | quest | 1 | 18.5% | 31% | 5.8% | 0% | 4.3% (1/23) | DEAD |
| c_collector | quest | 1 | 14.8% | 31% | 4.5% | 100% | 16.7% (3/18) |  |
| c_chimera_hunt | quest | 1 | 19.0% | 34% | 6.5% | 73% | 30.8% (8/26) |  |
| c_golden_egg | rule | 1 | 4.5% | 28% | 1.2% | 100% | 0.0% (0/5) | LOW |
| c_dim_stone | rule | 1 | 8.8% | 34% | 3.0% | 100% | 8.3% (1/12) | LOW |
| c_mirror_face | dice | 2 | 6.5% | 50% | 3.2% | 100% | 23.1% (3/13) | LOW |
| c_sixth_die | dice | 2 | 7.8% | 26% | 2.0% | 100% | 37.5% (3/8) | LOW |
| c_whittle | dice | 2 | 7.8% | 39% | 3.0% | 100% | 8.3% (1/12) | LOW |
| c_three_dice | dice | 2 | 9.2% | 19% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_concord | dice | 2 | 7.5% | 37% | 2.8% | 82% | 0.0% (0/11) | LOW |
| c_toxic_still | dice | 2 | 6.2% | 48% | 3.0% | 100% | 25.0% (3/12) | LOW |
| c_living_wall | pos | 2 | 23.5% | 32% | 7.5% | 100% | 23.3% (7/30) |  |
| c_thorn_rebound | rule | 2 | 8.2% | 30% | 2.5% | 90% | 0.0% (0/10) | LOW |
| c_open_ranks | pos | 2 | 5.2% | 14% | 0.8% | 100% | 0.0% (0/3) | LOW |
| c_descend | pos | 2 | 10.8% | 30% | 3.2% | 100% | 38.5% (5/13) |  |
| c_hollow_core | mana | 2 | 23.8% | 34% | 8.0% | 91% | 12.5% (4/32) |  |
| c_deep_current | mana | 2 | 23.2% | 27% | 6.2% | 72% | 8.0% (2/25) |  |
| c_blood_sign | rule | 2 | 8.2% | 30% | 2.5% | 100% | 10.0% (1/10) | LOW |
| c_loop | rule | 2 | 6.5% | 35% | 2.2% | 67% | 11.1% (1/9) | LOW |
| c_cascade | rule | 2 | 7.8% | 45% | 3.5% | 93% | 14.3% (2/14) | LOW |
| c_sacrifice | rule | 2 | 11.5% | 26% | 3.0% | 100% | 16.7% (2/12) |  |
