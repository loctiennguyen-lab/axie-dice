# Sim balance new_final_A0

Runs: 8000, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 23.9% -> CHUA DAT
- attack_spam <= 5%: 25.2% -> CHUA DAT
- attack_only <= 5%: 4.7% -> DAT
- expert 15-25%: 30.9% -> CHUA DAT
- expert - random >= 15 diem: 7.0 diem -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=2000): r4 battle -73 (con 96%); r5 battle -24 (con 95%); r5 elite -229 (con 84%); r6 boss -103 (con 79%); r7 battle -8 (con 78%); r8 battle -31 (con 77%); r9 elite -173 (con 68%); r9 battle -12 (con 67%); r10 battle -10 (con 67%); r11 battle -14 (con 66%); r12 boss -195 (con 56%); r13 battle -11 (con 56%); r14 battle -6 (con 56%); r15 elite -174 (con 47%); r15 battle -22 (con 46%); r16 battle -7 (con 45%); r17 battle -8 (con 45%); r18 boss -423 (con 24%)
- **attack_spam** (n=2000): r3 battle -1 (con 100%); r4 battle -31 (con 98%); r5 elite -189 (con 89%); r5 battle -8 (con 89%); r6 boss -123 (con 82%); r7 battle -6 (con 82%); r8 battle -19 (con 81%); r9 elite -135 (con 74%); r9 battle -7 (con 74%); r10 battle -5 (con 74%); r11 battle -11 (con 73%); r12 boss -220 (con 62%); r13 battle -9 (con 62%); r14 battle -8 (con 61%); r15 battle -11 (con 61%); r15 elite -197 (con 51%); r16 battle -3 (con 51%); r17 battle -4 (con 51%); r18 boss -508 (con 25%)
- **attack_only** (n=2000): r3 battle -9 (con 100%); r4 battle -142 (con 92%); r5 elite -514 (con 67%); r5 battle -47 (con 64%); r6 boss -782 (con 25%); r7 battle -4 (con 25%); r8 battle -11 (con 25%); r9 elite -58 (con 22%); r9 battle -5 (con 21%); r10 battle -4 (con 21%); r11 battle -16 (con 20%); r12 boss -123 (con 14%); r13 battle -1 (con 14%); r14 battle -9 (con 14%); r15 battle -2 (con 14%); r15 elite -43 (con 12%); r16 battle -5 (con 11%); r17 battle -2 (con 11%); r18 boss -129 (con 5%)
- **expert** (n=2000): r3 battle -1 (con 100%); r4 battle -22 (con 99%); r5 elite -130 (con 92%); r5 battle -4 (con 92%); r6 boss -137 (con 85%); r7 battle -6 (con 85%); r8 battle -9 (con 85%); r9 elite -130 (con 78%); r10 battle -1 (con 78%); r11 battle -6 (con 78%); r12 boss -242 (con 66%); r13 battle -6 (con 65%); r14 battle -4 (con 65%); r15 battle -9 (con 65%); r15 elite -183 (con 56%); r16 battle -1 (con 55%); r17 battle -2 (con 55%); r18 boss -490 (con 31%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_only | 0 | 4.7% (94/2000) |
| attack_spam | 0 | 25.2% (505/2000) |
| expert | 0 | 30.9% (617/2000) |
| random_legal | 0 | 23.9% (477/2000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_only | aqua_plant | 0.0% (0/286) |
| attack_only | beast_bird | 21.7% (62/286) |
| attack_only | mixed_dmg | 4.5% (13/286) |
| attack_only | mixed_std | 1.0% (3/286) |
| attack_only | reptile_bug | 0.3% (1/286) |
| attack_only | tank_heavy | 3.5% (10/285) |
| attack_only | thorn_shield | 1.8% (5/285) |
| attack_spam | aqua_plant | 9.4% (27/286) |
| attack_spam | beast_bird | 21.7% (62/286) |
| attack_spam | mixed_dmg | 22.0% (63/286) |
| attack_spam | mixed_std | 24.8% (71/286) |
| attack_spam | reptile_bug | 41.6% (119/286) |
| attack_spam | tank_heavy | 25.6% (73/285) |
| attack_spam | thorn_shield | 31.6% (90/285) |
| expert | aqua_plant | 16.7% (48/288) |
| expert | beast_bird | 28.5% (82/288) |
| expert | mixed_dmg | 33.8% (96/284) |
| expert | mixed_std | 30.6% (87/284) |
| expert | reptile_bug | 38.5% (111/288) |
| expert | tank_heavy | 34.9% (99/284) |
| expert | thorn_shield | 33.1% (94/284) |
| random_legal | aqua_plant | 10.1% (29/286) |
| random_legal | beast_bird | 22.0% (63/286) |
| random_legal | mixed_dmg | 23.1% (66/286) |
| random_legal | mixed_std | 24.5% (70/286) |
| random_legal | reptile_bug | 34.6% (99/286) |
| random_legal | tank_heavy | 21.4% (61/285) |
| random_legal | thorn_shield | 31.2% (89/285) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_only | combo | 6.3% (42/665) |
| attack_only | greedy_axis | 4.4% (29/665) |
| attack_only | random | 3.4% (23/670) |
| attack_spam | combo | 28.1% (187/665) |
| attack_spam | greedy_axis | 23.0% (153/665) |
| attack_spam | random | 24.6% (165/670) |
| expert | combo | 30.9% (617/2000) |
| random_legal | combo | 25.4% (169/665) |
| random_legal | greedy_axis | 21.4% (142/665) |
| random_legal | random | 24.8% (166/670) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_only|battle: 4.1 luot (n=9135)
- attack_only|boss: 7.0 luot (n=1919)
- attack_only|elite: 5.3 luot (n=1259)
- attack_spam|battle: 3.5 luot (n=15287)
- attack_spam|boss: 6.3 luot (n=4249)
- attack_spam|elite: 5.1 luot (n=2262)
- expert|battle: 3.1 luot (n=15733)
- expert|boss: 6.2 luot (n=4504)
- expert|elite: 4.4 luot (n=2333)
- random_legal|battle: 3.4 luot (n=14748)
- random_legal|boss: 6.1 luot (n=3897)
- random_legal|elite: 4.7 luot (n=2139)

## Chet theo node (chinh sach|loai row)

- attack_only|battle r10: 4
- attack_only|battle r11: 16
- attack_only|battle r13: 1
- attack_only|battle r14: 9
- attack_only|battle r15: 2
- attack_only|battle r16: 5
- attack_only|battle r17: 2
- attack_only|battle r3: 9
- attack_only|battle r4: 142
- attack_only|battle r5: 47
- attack_only|battle r7: 4
- attack_only|battle r8: 11
- attack_only|battle r9: 5
- attack_only|boss r12: 123
- attack_only|boss r18: 129
- attack_only|boss r6: 782
- attack_only|elite r15: 43
- attack_only|elite r5: 514
- attack_only|elite r9: 58
- attack_spam|battle r10: 5
- attack_spam|battle r11: 11
- attack_spam|battle r13: 9
- attack_spam|battle r14: 8
- attack_spam|battle r15: 11
- attack_spam|battle r16: 3
- attack_spam|battle r17: 4
- attack_spam|battle r3: 1
- attack_spam|battle r4: 31
- attack_spam|battle r5: 8
- attack_spam|battle r7: 6
- attack_spam|battle r8: 19
- attack_spam|battle r9: 7
- attack_spam|boss r12: 220
- attack_spam|boss r18: 508
- attack_spam|boss r6: 123
- attack_spam|elite r15: 197
- attack_spam|elite r5: 189
- attack_spam|elite r9: 135
- expert|battle r10: 1
- expert|battle r11: 6
- expert|battle r13: 6
- expert|battle r14: 4
- expert|battle r15: 9
- expert|battle r16: 1
- expert|battle r17: 2
- expert|battle r3: 1
- expert|battle r4: 22
- expert|battle r5: 4
- expert|battle r7: 6
- expert|battle r8: 9
- expert|boss r12: 242
- expert|boss r18: 490
- expert|boss r6: 137
- expert|elite r15: 183
- expert|elite r5: 130
- expert|elite r9: 130
- random_legal|battle r10: 10
- random_legal|battle r11: 14
- random_legal|battle r13: 11
- random_legal|battle r14: 6
- random_legal|battle r15: 22
- random_legal|battle r16: 7
- random_legal|battle r17: 8
- random_legal|battle r4: 73
- random_legal|battle r5: 24
- random_legal|battle r7: 8
- random_legal|battle r8: 31
- random_legal|battle r9: 12
- random_legal|boss r12: 195
- random_legal|boss r18: 423
- random_legal|boss r6: 103
- random_legal|elite r15: 174
- random_legal|elite r5: 229
- random_legal|elite r9: 173

Tran ket > 20 luot hoac khong ket thuc: 106 / 77465

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 44.6% | 7.5% | 7.5% | 100% |  |
| c_dewdrop | stat | 0 | 42.7% | 14.8% | 14.8% | 100% |  |
| c_elder_trunk | stat | 0 | 41.5% | 13.3% | 13.3% | 100% |  |
| c_prime_chain | dice | 0 | 45.5% | 17.1% | 15.4% | 90% |  |
| c_finisher | dice | 0 | 45.0% | 17.2% | 15.7% | 92% |  |
| c_bastion | pos | 0 | 67.2% | 24.8% | 24.7% | 99% |  |
| c_tidecaller | mana | 0 | 48.0% | 8.3% | 0.0% | 0% |  |
| c_mana_pool | mana | 0 | 41.7% | 14.4% | 12.6% | 87% |  |
| c_nest | rule | 0 | 49.3% | 16.8% | 16.8% | 100% |  |
| c_spore_burst | rule | 0 | 46.3% | 15.2% | 14.8% | 97% |  |
| c_fossil | rule | 0 | 33.9% | 5.3% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.5% | 3.0% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 13.0% | 6.9% | 1.5% | 22% |  |
| rule_tundra | run_rule | 0 | 12.1% | 7.0% | 0.3% | 4% |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.3% | 5.2% | 82% |  |
| rule_starfall | run_rule | 0 | 12.6% | 6.8% | 6.8% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 12.2% | 7.2% | 7.2% | 100% |  |
| rule_wasteland | run_rule | 0 | 11.4% | 6.1% | 6.1% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 13.0% | 6.5% | 6.5% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.3% | 7.1% | 7.1% | 100% |  |
| rule_upside_down | run_rule | 0 | 12.0% | 6.6% | 6.6% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.1% | 13.8% | 13.8% | 100% |  |
| rule_crow | run_rule | 0 | 12.4% | 3.7% | 2.9% | 79% |  |
| rule_hard_shell | run_rule | 0 | 19.9% | 5.5% | 5.5% | 100% |  |
| rule_balance | run_rule | 0 | 23.9% | 13.4% | 13.4% | 100% |  |
| c_prism | dice | 1 | 11.3% | 5.9% | 3.1% | 53% |  |
| c_steady_hold | dice | 1 | 10.3% | 2.1% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 10.8% | 5.4% | 0.6% | 11% |  |
| c_sonic_shield | dice | 1 | 11.1% | 5.6% | 4.8% | 86% |  |
| c_fissure | dice | 1 | 7.5% | 3.7% | 3.1% | 84% | LOW |
| c_field_medic | dice | 1 | 10.9% | 2.5% | 2.5% | 100% |  |
| c_plague_spread | dice | 1 | 7.4% | 3.7% | 3.2% | 86% | LOW |
| c_gatekeeper | pos | 1 | 22.1% | 12.2% | 12.0% | 98% |  |
| c_thorn_growth | pos | 1 | 22.0% | 4.8% | 4.7% | 97% |  |
| c_thorn_shield | stat | 1 | 62.4% | 9.3% | 8.0% | 86% |  |
| c_backline_glow | pos | 1 | 27.6% | 15.6% | 13.9% | 89% |  |
| c_growing_shell | pos | 1 | 23.2% | 13.2% | 11.0% | 83% |  |
| c_mana_ward | mana | 1 | 26.0% | 5.2% | 4.0% | 77% |  |
| c_overflow | mana | 1 | 22.4% | 10.6% | 6.3% | 59% |  |
| c_thorn_pact | mana | 1 | 18.4% | 8.5% | 8.2% | 97% |  |
| c_dry_well | quest | 1 | 22.1% | 2.0% | 2.0% | 100% |  |
| c_night_watch | quest | 1 | 20.4% | 1.7% | 1.7% | 100% |  |
| c_key_strike | quest | 1 | 20.4% | 1.6% | 0.1% | 3% |  |
| c_collector | quest | 1 | 22.2% | 6.2% | 6.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 22.1% | 6.7% | 4.4% | 65% |  |
| c_golden_egg | rule | 1 | 9.2% | 8.1% | 4.6% | 57% | LOW |
| c_dim_stone | rule | 1 | 11.3% | 2.0% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 9.3% | 4.4% | 4.6% | 100% | LOW |
| c_sixth_die | dice | 2 | 10.1% | 5.2% | 5.2% | 100% |  |
| c_whittle | dice | 2 | 10.1% | 2.1% | 2.2% | 100% |  |
| c_three_dice | dice | 2 | 10.3% | 5.1% | 5.2% | 100% |  |
| c_concord | dice | 2 | 6.6% | 1.6% | 1.6% | 99% | LOW |
| c_toxic_still | dice | 2 | 6.5% | 1.2% | 1.4% | 100% | LOW |
| c_living_wall | pos | 2 | 25.8% | 14.3% | 14.3% | 100% |  |
| c_thorn_rebound | rule | 2 | 14.0% | 3.1% | 2.7% | 80% |  |
| c_open_ranks | pos | 2 | 4.9% | 1.8% | 1.8% | 100% | LOW |
| c_descend | pos | 2 | 14.4% | 7.9% | 7.7% | 97% |  |
| c_hollow_core | mana | 2 | 19.9% | 7.3% | 5.6% | 77% |  |
| c_deep_current | mana | 2 | 26.5% | 5.4% | 4.0% | 71% |  |
| c_blood_sign | rule | 2 | 9.1% | 4.4% | 4.5% | 100% | LOW |
| c_loop | rule | 2 | 11.2% | 5.7% | 5.1% | 87% |  |
| c_cascade | rule | 2 | 12.1% | 6.5% | 6.6% | 99% |  |
| c_sacrifice | rule | 2 | 13.0% | 2.9% | 3.2% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 65.9% (5272/8000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 52.2% (617/1182)
- c_golden_egg: 47.8% (309/646)
- c_cascade: 47.2% (251/532)
- c_blood_sign: 40.9% (148/362)
- c_sixth_die: 39.9% (165/414)
- c_nest: 39.4% (521/1324)
- c_mirror_face: 37.5% (138/368)
- c_loop: 37.4% (175/468)
- c_sonic_shield: 34.8% (155/445)
- c_living_wall: 34.7% (397/1143)

Bottom 10:
- c_fossil: 0.0% (0/96)
- c_tidecaller: 14.8% (98/660)
- c_three_dice: 16.3% (68/417)
- c_mana_pool: 17.9% (202/1126)
- c_bastion: 19.3% (370/1914)
- c_prime_chain: 22.4% (298/1328)
- c_mana_ward: 22.5% (94/417)
- c_thorn_rebound: 22.8% (62/272)
- c_open_ranks: 23.6% (34/144)
- c_finisher: 23.8% (319/1340)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_gatekeeper + c_night_watch: 77.8% (7/9)
- c_mana_ward + c_spore_burst: 74.3% (26/35)
- c_mirror_face + c_nest: 73.1% (38/52)
- c_golden_egg + c_prism: 71.4% (10/14)
- c_mirror_face + c_spore_burst: 70.9% (39/55)
- c_descend + c_three_dice: 0.0% (0/8)
- c_fossil + c_nest: 0.0% (0/13)
- c_elder_trunk + c_open_ranks: 0.0% (0/9)
- c_concord + c_mana_pool: 0.0% (0/8)
- c_mana_pool + c_steady_hold: 0.0% (0/10)
