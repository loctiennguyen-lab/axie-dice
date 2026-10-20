# Sim balance main_final_A0

Runs: 10000, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 20.6% -> CHUA DAT
- attack_spam <= 5%: 22.8% -> CHUA DAT
- attack_only <= 5%: 5.0% -> CHUA DAT
- expert 15-25%: 28.6% -> CHUA DAT
- expert - random >= 15 diem: 7.9 diem -> CHUA DAT
- (tham khao) greedy: 23.9%


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=2000): r4 battle -70 (con 96%); r5 elite -209 (con 86%); r5 battle -21 (con 85%); r6 boss -106 (con 80%); r7 battle -7 (con 79%); r8 battle -29 (con 78%); r9 elite -150 (con 70%); r9 battle -14 (con 70%); r10 battle -10 (con 69%); r11 battle -17 (con 68%); r12 boss -214 (con 58%); r13 battle -13 (con 57%); r14 battle -14 (con 56%); r15 elite -190 (con 47%); r15 battle -12 (con 46%); r16 battle -4 (con 46%); r17 battle -9 (con 46%); r18 boss -499 (con 21%)
- **attack_spam** (n=2000): r4 battle -54 (con 97%); r5 battle -12 (con 97%); r5 elite -186 (con 87%); r6 boss -120 (con 81%); r7 battle -2 (con 81%); r8 battle -13 (con 81%); r9 battle -3 (con 80%); r9 elite -125 (con 74%); r10 battle -2 (con 74%); r11 battle -11 (con 74%); r12 boss -275 (con 60%); r13 battle -2 (con 60%); r14 battle -5 (con 60%); r15 battle -8 (con 59%); r15 elite -181 (con 50%); r17 battle -6 (con 50%); r18 boss -539 (con 23%)
- **attack_only** (n=2000): r1 battle -1 (con 100%); r3 battle -12 (con 99%); r4 battle -181 (con 90%); r5 elite -456 (con 68%); r5 battle -40 (con 66%); r6 boss -758 (con 28%); r7 battle -5 (con 27%); r8 battle -6 (con 27%); r9 elite -71 (con 24%); r9 battle -5 (con 23%); r10 battle -12 (con 23%); r11 battle -9 (con 22%); r12 boss -141 (con 15%); r13 battle -4 (con 15%); r14 battle -4 (con 15%); r15 battle -6 (con 14%); r15 elite -34 (con 13%); r16 battle -2 (con 13%); r17 battle -6 (con 12%); r18 boss -146 (con 5%)
- **greedy** (n=2000): r4 battle -47 (con 98%); r5 elite -157 (con 90%); r5 battle -10 (con 89%); r6 boss -56 (con 86%); r7 battle -6 (con 86%); r8 battle -10 (con 86%); r9 elite -110 (con 80%); r9 battle -4 (con 80%); r10 battle -7 (con 80%); r11 battle -7 (con 79%); r12 boss -254 (con 67%); r13 battle -12 (con 66%); r14 battle -10 (con 66%); r15 elite -161 (con 57%); r15 battle -8 (con 57%); r16 battle -4 (con 57%); r17 battle -7 (con 56%); r18 boss -651 (con 24%)
- **expert** (n=2000): r4 battle -21 (con 99%); r5 battle -4 (con 99%); r5 elite -109 (con 93%); r6 boss -126 (con 87%); r7 battle -4 (con 87%); r8 battle -18 (con 86%); r9 elite -105 (con 81%); r9 battle -7 (con 80%); r10 battle -4 (con 80%); r11 battle -9 (con 80%); r12 boss -274 (con 66%); r13 battle -2 (con 66%); r14 battle -4 (con 66%); r15 elite -142 (con 59%); r15 battle -4 (con 58%); r16 battle -3 (con 58%); r17 battle -3 (con 58%); r18 boss -590 (con 29%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_only | 0 | 5.0% (101/2000) |
| attack_spam | 0 | 22.8% (456/2000) |
| expert | 0 | 28.6% (571/2000) |
| greedy | 0 | 23.9% (479/2000) |
| random_legal | 0 | 20.6% (412/2000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_only | aqua_plant | 1.0% (3/286) |
| attack_only | beast_bird | 23.8% (68/286) |
| attack_only | mixed_dmg | 4.9% (14/286) |
| attack_only | mixed_std | 0.3% (1/286) |
| attack_only | reptile_bug | 1.4% (4/286) |
| attack_only | tank_heavy | 3.9% (11/285) |
| attack_only | thorn_shield | 0.0% (0/285) |
| attack_spam | aqua_plant | 10.5% (30/286) |
| attack_spam | beast_bird | 21.3% (61/286) |
| attack_spam | mixed_dmg | 24.1% (69/286) |
| attack_spam | mixed_std | 19.9% (57/286) |
| attack_spam | reptile_bug | 33.9% (97/286) |
| attack_spam | tank_heavy | 23.2% (66/285) |
| attack_spam | thorn_shield | 26.7% (76/285) |
| expert | aqua_plant | 13.5% (39/288) |
| expert | beast_bird | 27.1% (78/288) |
| expert | mixed_dmg | 27.1% (77/284) |
| expert | mixed_std | 28.5% (81/284) |
| expert | reptile_bug | 37.8% (109/288) |
| expert | tank_heavy | 33.8% (96/284) |
| expert | thorn_shield | 32.0% (91/284) |
| greedy | aqua_plant | 9.8% (28/286) |
| greedy | beast_bird | 23.1% (66/286) |
| greedy | mixed_dmg | 22.0% (63/286) |
| greedy | mixed_std | 23.8% (68/286) |
| greedy | reptile_bug | 37.4% (107/286) |
| greedy | tank_heavy | 22.1% (63/285) |
| greedy | thorn_shield | 29.5% (84/285) |
| random_legal | aqua_plant | 8.7% (25/286) |
| random_legal | beast_bird | 19.6% (56/286) |
| random_legal | mixed_dmg | 20.3% (58/286) |
| random_legal | mixed_std | 20.6% (59/286) |
| random_legal | reptile_bug | 29.4% (84/286) |
| random_legal | tank_heavy | 20.4% (58/285) |
| random_legal | thorn_shield | 25.3% (72/285) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_only | combo | 5.9% (39/665) |
| attack_only | greedy_axis | 4.7% (31/665) |
| attack_only | random | 4.6% (31/670) |
| attack_spam | combo | 25.3% (168/665) |
| attack_spam | greedy_axis | 20.9% (139/665) |
| attack_spam | random | 22.2% (149/670) |
| expert | combo | 28.6% (571/2000) |
| greedy | combo | 25.7% (171/665) |
| greedy | greedy_axis | 22.1% (147/665) |
| greedy | random | 24.0% (161/670) |
| random_legal | combo | 22.4% (149/665) |
| random_legal | greedy_axis | 19.1% (127/665) |
| random_legal | random | 20.3% (136/670) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_only|battle: 4.0 luot (n=9400)
- attack_only|boss: 6.9 luot (n=2001)
- attack_only|elite: 5.2 luot (n=1208)
- attack_spam|battle: 3.5 luot (n=15088)
- attack_spam|boss: 6.4 luot (n=4215)
- attack_spam|elite: 5.0 luot (n=2241)
- expert|battle: 3.0 luot (n=15847)
- expert|boss: 6.2 luot (n=4620)
- expert|elite: 4.4 luot (n=2382)
- greedy|battle: 3.3 luot (n=15915)
- greedy|boss: 6.0 luot (n=4502)
- greedy|elite: 4.7 luot (n=2312)
- random_legal|battle: 3.4 luot (n=14775)
- random_legal|boss: 6.2 luot (n=3978)
- random_legal|elite: 4.7 luot (n=2171)

## Chet theo node (chinh sach|loai row)

- attack_only|battle r1: 1
- attack_only|battle r10: 12
- attack_only|battle r11: 9
- attack_only|battle r13: 4
- attack_only|battle r14: 4
- attack_only|battle r15: 6
- attack_only|battle r16: 2
- attack_only|battle r17: 6
- attack_only|battle r3: 12
- attack_only|battle r4: 181
- attack_only|battle r5: 40
- attack_only|battle r7: 5
- attack_only|battle r8: 6
- attack_only|battle r9: 5
- attack_only|boss r12: 141
- attack_only|boss r18: 146
- attack_only|boss r6: 758
- attack_only|elite r15: 34
- attack_only|elite r5: 456
- attack_only|elite r9: 71
- attack_spam|battle r10: 2
- attack_spam|battle r11: 11
- attack_spam|battle r13: 2
- attack_spam|battle r14: 5
- attack_spam|battle r15: 8
- attack_spam|battle r17: 6
- attack_spam|battle r4: 54
- attack_spam|battle r5: 12
- attack_spam|battle r7: 2
- attack_spam|battle r8: 13
- attack_spam|battle r9: 3
- attack_spam|boss r12: 275
- attack_spam|boss r18: 539
- attack_spam|boss r6: 120
- attack_spam|elite r15: 181
- attack_spam|elite r5: 186
- attack_spam|elite r9: 125
- expert|battle r10: 4
- expert|battle r11: 9
- expert|battle r13: 2
- expert|battle r14: 4
- expert|battle r15: 4
- expert|battle r16: 3
- expert|battle r17: 3
- expert|battle r4: 21
- expert|battle r5: 4
- expert|battle r7: 4
- expert|battle r8: 18
- expert|battle r9: 7
- expert|boss r12: 274
- expert|boss r18: 590
- expert|boss r6: 126
- expert|elite r15: 142
- expert|elite r5: 109
- expert|elite r9: 105
- greedy|battle r10: 7
- greedy|battle r11: 7
- greedy|battle r13: 12
- greedy|battle r14: 10
- greedy|battle r15: 8
- greedy|battle r16: 4
- greedy|battle r17: 7
- greedy|battle r4: 47
- greedy|battle r5: 10
- greedy|battle r7: 6
- greedy|battle r8: 10
- greedy|battle r9: 4
- greedy|boss r12: 254
- greedy|boss r18: 651
- greedy|boss r6: 56
- greedy|elite r15: 161
- greedy|elite r5: 157
- greedy|elite r9: 110
- random_legal|battle r10: 10
- random_legal|battle r11: 17
- random_legal|battle r13: 13
- random_legal|battle r14: 14
- random_legal|battle r15: 12
- random_legal|battle r16: 4
- random_legal|battle r17: 9
- random_legal|battle r4: 70
- random_legal|battle r5: 21
- random_legal|battle r7: 7
- random_legal|battle r8: 29
- random_legal|battle r9: 14
- random_legal|boss r12: 214
- random_legal|boss r18: 499
- random_legal|boss r6: 106
- random_legal|elite r15: 190
- random_legal|elite r5: 209
- random_legal|elite r9: 150

Tran ket > 20 luot hoac khong ket thuc: 104 / 100655

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 62.7% | 10.1% | 10.1% | 100% |  |
| c_dewdrop | stat | 0 | 61.6% | 18.5% | 18.5% | 100% |  |
| c_elder_trunk | stat | 0 | 61.0% | 18.2% | 18.2% | 100% |  |
| c_prime_chain | dice | 0 | 47.2% | 18.3% | 18.3% | 100% |  |
| c_finisher | dice | 0 | 48.3% | 18.7% | 18.7% | 100% |  |
| c_bastion | pos | 0 | 66.9% | 24.0% | 24.0% | 100% |  |
| c_tidecaller | mana | 0 | 49.7% | 9.4% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.8% | 13.9% | 13.9% | 100% |  |
| c_collector | quest | 0 | 23.7% | 4.1% | 4.1% | 100% |  |
| c_nest | rule | 0 | 38.1% | 13.2% | 13.2% | 100% |  |
| c_spore_burst | rule | 0 | 34.1% | 11.7% | 11.7% | 100% |  |
| c_fossil | rule | 0 | 37.4% | 6.7% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.6% | 2.5% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 14.6% | 7.9% | 7.9% | 100% |  |
| rule_tundra | run_rule | 0 | 15.7% | 8.6% | 8.6% | 100% |  |
| rule_quick_beat | run_rule | 0 | 15.0% | 8.3% | 8.3% | 100% |  |
| rule_starfall | run_rule | 0 | 16.4% | 9.3% | 9.3% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 14.3% | 8.0% | 8.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 14.8% | 8.3% | 8.3% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 14.1% | 7.6% | 7.6% | 100% |  |
| rule_rising_tide | run_rule | 0 | 14.3% | 7.8% | 7.8% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.5% | 7.8% | 7.8% | 100% |  |
| rule_old_forest | run_rule | 0 | 14.4% | 7.9% | 7.9% | 100% |  |
| rule_crow | run_rule | 0 | 14.2% | 4.0% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 13.4% | 4.2% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 14.6% | 7.8% | 7.8% | 100% |  |
| c_prism | dice | 1 | 12.3% | 5.6% | 5.6% | 100% |  |
| c_steady_hold | dice | 1 | 11.4% | 2.6% | 2.6% | 100% |  |
| c_kindle | dice | 1 | 12.6% | 5.9% | 5.9% | 100% |  |
| c_sonic_shield | dice | 1 | 12.2% | 5.8% | 5.8% | 100% |  |
| c_fissure | dice | 1 | 7.9% | 3.5% | 3.5% | 100% | LOW |
| c_field_medic | dice | 1 | 12.4% | 2.7% | 2.7% | 100% |  |
| c_plague_spread | dice | 1 | 7.9% | 3.8% | 3.8% | 100% | LOW |
| c_gatekeeper | pos | 1 | 33.0% | 18.2% | 18.2% | 100% |  |
| c_backline_glow | pos | 1 | 32.6% | 19.7% | 19.7% | 100% |  |
| c_growing_shell | pos | 1 | 31.8% | 18.1% | 18.1% | 100% |  |
| c_mana_ward | mana | 1 | 28.6% | 6.5% | 6.5% | 100% |  |
| c_overflow | mana | 1 | 25.1% | 11.1% | 11.1% | 100% |  |
| c_thorn_pact | mana | 1 | 19.7% | 9.2% | 9.2% | 100% |  |
| c_dry_well | quest | 1 | 24.3% | 2.3% | 2.3% | 100% |  |
| c_night_watch | quest | 1 | 23.2% | 2.0% | 2.0% | 100% |  |
| c_key_strike | quest | 1 | 23.7% | 1.9% | 1.9% | 100% |  |
| c_chimera_hunt | quest | 1 | 24.4% | 5.6% | 5.5% | 99% |  |
| c_golden_egg | rule | 1 | 5.6% | 4.8% | 4.8% | 100% | LOW |
| c_dim_stone | rule | 1 | 48.9% | 9.1% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 10.0% | 4.5% | 4.5% | 100% |  |
| c_sixth_die | dice | 2 | 11.2% | 5.3% | 5.3% | 100% |  |
| c_whittle | dice | 2 | 11.2% | 2.3% | 2.3% | 100% |  |
| c_three_dice | dice | 2 | 10.3% | 4.7% | 4.7% | 100% |  |
| c_concord | dice | 2 | 7.5% | 1.6% | 1.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.0% | 1.6% | 1.6% | 100% | LOW |
| c_living_wall | pos | 2 | 27.7% | 14.8% | 14.8% | 100% |  |
| c_open_ranks | pos | 2 | 8.1% | 2.7% | 2.7% | 100% | LOW |
| c_descend | pos | 2 | 16.0% | 8.5% | 8.5% | 100% |  |
| c_hollow_core | mana | 2 | 21.2% | 7.8% | 7.8% | 100% |  |
| c_deep_current | mana | 2 | 29.4% | 6.0% | 6.0% | 100% |  |
| c_blood_sign | rule | 2 | 10.4% | 5.0% | 5.0% | 100% |  |
| c_loop | rule | 2 | 13.4% | 6.0% | 6.0% | 100% |  |
| c_cascade | rule | 2 | 14.5% | 6.2% | 6.2% | 100% |  |
| c_sacrifice | rule | 2 | 16.5% | 3.7% | 3.7% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 71.0% (7103/10000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 51.3% (570/1111)
- c_cascade: 41.7% (258/618)
- c_golden_egg: 39.3% (187/476)
- c_sixth_die: 38.5% (203/527)
- c_fissure: 37.6% (129/343)
- c_mirror_face: 37.4% (168/449)
- c_blood_sign: 35.9% (179/498)
- c_sonic_shield: 34.6% (200/578)
- c_nest: 33.5% (429/1280)
- c_living_wall: 32.5% (480/1477)

Bottom 10:
- c_three_dice: 12.9% (61/474)
- c_tidecaller: 17.3% (160/923)
- c_mana_pool: 18.1% (243/1346)
- c_bastion: 18.8% (434/2305)
- c_field_medic: 20.6% (56/272)
- c_prime_chain: 21.3% (380/1781)
- c_early_scales: 21.5% (215/999)
- c_finisher: 21.5% (393/1825)
- c_steady_hold: 21.5% (56/260)
- c_dry_well: 21.9% (49/224)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_fissure + c_spore_burst: 81.1% (30/37)
- c_fissure + c_golden_egg: 76.9% (10/13)
- c_mirror_face + c_spore_burst: 76.3% (29/38)
- c_fissure + c_nest: 76.0% (19/25)
- c_sonic_shield + c_spore_burst: 74.4% (29/39)
- c_open_ranks + c_tidecaller: 0.0% (0/9)
- c_three_dice + c_toxic_still: 0.0% (0/10)
- c_blood_sign + c_key_strike: 0.0% (0/10)
- c_collector + c_open_ranks: 0.0% (0/8)
- c_steady_hold + c_tidecaller: 0.0% (0/14)
