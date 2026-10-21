# Sim balance freqtest

Runs: 900, wall 73.1s (0.08s/run).

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 22.0% (66/300) |
| greedy | 0 | 24.0% (72/300) |
| random_legal | 0 | 21.3% (64/300) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 4.7% (2/43) |
| attack_spam | beast_bird | 27.9% (12/43) |
| attack_spam | mixed_dmg | 25.6% (11/43) |
| attack_spam | mixed_std | 20.9% (9/43) |
| attack_spam | reptile_bug | 34.9% (15/43) |
| attack_spam | tank_heavy | 20.9% (9/43) |
| attack_spam | thorn_shield | 19.0% (8/42) |
| greedy | aqua_plant | 4.7% (2/43) |
| greedy | beast_bird | 25.6% (11/43) |
| greedy | mixed_dmg | 30.2% (13/43) |
| greedy | mixed_std | 25.6% (11/43) |
| greedy | reptile_bug | 25.6% (11/43) |
| greedy | tank_heavy | 27.9% (12/43) |
| greedy | thorn_shield | 28.6% (12/42) |
| random_legal | aqua_plant | 9.3% (4/43) |
| random_legal | beast_bird | 16.3% (7/43) |
| random_legal | mixed_dmg | 30.2% (13/43) |
| random_legal | mixed_std | 18.6% (8/43) |
| random_legal | reptile_bug | 34.9% (15/43) |
| random_legal | tank_heavy | 16.3% (7/43) |
| random_legal | thorn_shield | 23.8% (10/42) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | greedy_axis | 19.7% (29/147) |
| attack_spam | random | 24.2% (37/153) |
| greedy | greedy_axis | 28.6% (42/147) |
| greedy | random | 19.6% (30/153) |
| random_legal | greedy_axis | 19.7% (29/147) |
| random_legal | random | 22.9% (35/153) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.6 luot (n=2310)
- attack_spam|boss: 6.5 luot (n=655)
- attack_spam|elite: 5.2 luot (n=348)
- greedy|battle: 3.4 luot (n=2383)
- greedy|boss: 6.1 luot (n=674)
- greedy|elite: 4.7 luot (n=330)
- random_legal|battle: 3.5 luot (n=2219)
- random_legal|boss: 6.4 luot (n=589)
- random_legal|elite: 4.6 luot (n=320)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r13: 2
- attack_spam|battle r14: 2
- attack_spam|battle r15: 3
- attack_spam|battle r16: 1
- attack_spam|battle r17: 1
- attack_spam|battle r4: 5
- attack_spam|battle r9: 1
- attack_spam|boss r12: 42
- attack_spam|boss r18: 92
- attack_spam|boss r6: 19
- attack_spam|elite r15: 21
- attack_spam|elite r5: 28
- attack_spam|elite r9: 17
- greedy|battle r10: 1
- greedy|battle r13: 2
- greedy|battle r17: 1
- greedy|battle r4: 9
- greedy|battle r5: 1
- greedy|battle r7: 2
- greedy|battle r8: 3
- greedy|battle r9: 2
- greedy|boss r12: 38
- greedy|boss r18: 101
- greedy|boss r6: 8
- greedy|elite r15: 22
- greedy|elite r5: 25
- greedy|elite r9: 13
- random_legal|battle r11: 2
- random_legal|battle r13: 1
- random_legal|battle r14: 1
- random_legal|battle r15: 4
- random_legal|battle r16: 1
- random_legal|battle r17: 1
- random_legal|battle r4: 12
- random_legal|battle r5: 3
- random_legal|battle r7: 3
- random_legal|battle r8: 3
- random_legal|battle r9: 2
- random_legal|boss r12: 29
- random_legal|boss r18: 70
- random_legal|boss r6: 16
- random_legal|elite r15: 31
- random_legal|elite r5: 32
- random_legal|elite r9: 25

Tran ket > 20 luot hoac khong ket thuc: 10 / 9828

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 64.9% | 17.3% | 17.3% | 100% |  |
| c_dewdrop | stat | 0 | 68.2% | 19.9% | 19.9% | 100% |  |
| c_elder_trunk | stat | 0 | 64.4% | 18.1% | 18.1% | 100% |  |
| c_prime_chain | dice | 0 | 50.8% | 17.6% | 17.6% | 100% |  |
| c_finisher | dice | 0 | 46.8% | 16.8% | 16.8% | 100% |  |
| c_bastion | pos | 0 | 64.2% | 20.9% | 20.9% | 100% |  |
| c_tidecaller | mana | 0 | 48.0% | 17.1% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 41.6% | 11.1% | 11.1% | 100% |  |
| c_collector | quest | 0 | 22.6% | 4.0% | 4.0% | 100% |  |
| c_nest | rule | 0 | 40.7% | 15.4% | 15.4% | 100% |  |
| c_spore_burst | rule | 0 | 41.2% | 14.7% | 14.7% | 100% |  |
| c_fossil | rule | 0 | 38.0% | 14.0% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 7.3% | 4.3% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 14.0% | 8.3% | 8.3% | 100% |  |
| rule_tundra | run_rule | 0 | 12.7% | 5.7% | 5.7% | 100% |  |
| rule_quick_beat | run_rule | 0 | 16.7% | 10.7% | 10.7% | 100% |  |
| rule_starfall | run_rule | 0 | 15.3% | 7.7% | 7.7% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 11.7% | 5.0% | 5.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 18.0% | 8.0% | 8.0% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 13.3% | 5.7% | 5.7% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.3% | 6.7% | 6.7% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.3% | 7.7% | 7.7% | 100% |  |
| rule_old_forest | run_rule | 0 | 15.0% | 7.0% | 7.0% | 100% |  |
| rule_crow | run_rule | 0 | 17.0% | 6.3% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 14.7% | 6.7% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 17.7% | 10.3% | 10.3% | 100% |  |
| c_prism | dice | 1 | 11.9% | 4.2% | 4.2% | 100% |  |
| c_steady_hold | dice | 1 | 15.4% | 5.1% | 5.1% | 100% |  |
| c_kindle | dice | 1 | 13.1% | 4.8% | 4.8% | 100% |  |
| c_sonic_shield | dice | 1 | 13.9% | 4.8% | 4.8% | 100% |  |
| c_fissure | dice | 1 | 10.2% | 4.4% | 4.4% | 100% |  |
| c_field_medic | dice | 1 | 12.3% | 4.7% | 4.7% | 100% |  |
| c_plague_spread | dice | 1 | 9.9% | 2.6% | 2.6% | 100% | LOW |
| c_gatekeeper | pos | 1 | 33.9% | 13.4% | 13.4% | 100% |  |
| c_backline_glow | pos | 1 | 31.3% | 12.8% | 12.8% | 100% |  |
| c_growing_shell | pos | 1 | 34.3% | 13.8% | 13.8% | 100% |  |
| c_mana_ward | mana | 1 | 31.3% | 9.7% | 9.7% | 100% |  |
| c_overflow | mana | 1 | 25.9% | 8.1% | 8.1% | 100% |  |
| c_thorn_pact | mana | 1 | 22.8% | 8.0% | 8.0% | 100% |  |
| c_dry_well | quest | 1 | 25.2% | 4.0% | 4.0% | 100% |  |
| c_night_watch | quest | 1 | 26.8% | 5.1% | 5.1% | 100% |  |
| c_key_strike | quest | 1 | 26.9% | 3.6% | 3.6% | 100% |  |
| c_chimera_hunt | quest | 1 | 28.1% | 5.1% | 5.1% | 100% |  |
| c_golden_egg | rule | 1 | 6.9% | 5.3% | 5.3% | 100% | LOW |
| c_dim_stone | rule | 1 | 55.1% | 17.2% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.2% | 3.8% | 3.8% | 100% |  |
| c_sixth_die | dice | 2 | 12.4% | 5.1% | 5.1% | 100% |  |
| c_whittle | dice | 2 | 12.7% | 4.3% | 4.3% | 100% |  |
| c_three_dice | dice | 2 | 11.7% | 3.4% | 3.4% | 100% |  |
| c_concord | dice | 2 | 7.9% | 3.2% | 3.2% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.4% | 3.2% | 3.2% | 100% | LOW |
| c_living_wall | pos | 2 | 29.4% | 9.8% | 9.8% | 100% |  |
| c_open_ranks | pos | 2 | 7.9% | 5.6% | 5.6% | 100% | LOW |
| c_descend | pos | 2 | 16.7% | 6.8% | 6.8% | 100% |  |
| c_hollow_core | mana | 2 | 26.4% | 7.7% | 7.7% | 100% |  |
| c_deep_current | mana | 2 | 31.0% | 10.6% | 10.6% | 100% |  |
| c_blood_sign | rule | 2 | 14.4% | 5.8% | 5.8% | 100% |  |
| c_loop | rule | 2 | 14.7% | 6.2% | 6.2% | 100% |  |
| c_cascade | rule | 2 | 16.9% | 5.8% | 5.8% | 100% |  |
| c_sacrifice | rule | 2 | 20.4% | 8.6% | 8.6% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 71.8% (646/900)

Win-rate khi co Loi (n >= 8). Top 10:
- c_mirror_face: 64.7% (22/34)
- c_spore_burst: 45.5% (56/123)
- c_dry_well: 44.4% (16/36)
- c_blood_sign: 39.2% (20/51)
- c_plague_spread: 39.1% (9/23)
- c_cascade: 38.5% (20/52)
- c_loop: 37.5% (21/56)
- c_sixth_die: 36.4% (16/44)
- c_field_medic: 35.7% (15/42)
- c_sonic_shield: 34.9% (15/43)

Bottom 10:
- c_collector: 13.9% (5/36)
- c_kindle: 14.0% (6/43)
- c_sacrifice: 15.6% (12/77)
- c_three_dice: 16.1% (5/31)
- c_deep_current: 17.9% (17/95)
- c_key_strike: 18.8% (6/32)
- c_tidecaller: 19.0% (29/153)
- c_thorn_pact: 19.7% (14/71)
- c_mana_pool: 20.4% (20/98)
- c_concord: 20.7% (6/29)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_gatekeeper + c_spore_burst: 62.5% (5/8)
- c_dewdrop + c_dry_well: 61.5% (8/13)
- c_mirror_face + c_prime_chain: 60.0% (12/20)
- c_cascade + c_loop: 60.0% (6/10)
- c_finisher + c_mirror_face: 57.9% (11/19)
- c_collector + c_tidecaller: 0.0% (0/9)
- c_dewdrop + c_growing_shell: 0.0% (0/10)
- c_prime_chain + c_sacrifice: 0.0% (0/8)
- c_early_scales + c_nest: 6.7% (1/15)
- c_bastion + c_key_strike: 7.1% (1/14)
