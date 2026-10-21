# Sim balance td_fin_a

Runs: 4000, wall 231.6s (0.06s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 13.3% -> CHUA DAT
- attack_spam <= 5%: 15.1% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=2000): r3 battle -2 (con 100%); r4 battle -135 (con 93%); r5 elite -290 (con 79%); r5 battle -40 (con 77%); r6 boss -183 (con 68%); r7 battle -16 (con 67%); r8 battle -44 (con 64%); r9 battle -19 (con 64%); r9 elite -182 (con 54%); r10 battle -14 (con 54%); r11 battle -25 (con 52%); r12 boss -228 (con 41%); r13 battle -19 (con 40%); r14 battle -8 (con 40%); r15 battle -12 (con 39%); r15 elite -169 (con 31%); r16 battle -11 (con 30%); r17 battle -11 (con 30%); r18 boss -325 (con 13%)
- **attack_spam** (n=2000): r4 battle -76 (con 96%); r5 elite -264 (con 83%); r5 battle -16 (con 82%); r6 boss -239 (con 70%); r7 battle -8 (con 70%); r8 battle -27 (con 68%); r9 battle -8 (con 68%); r9 elite -184 (con 59%); r10 battle -7 (con 59%); r11 battle -18 (con 58%); r12 boss -297 (con 43%); r13 battle -12 (con 42%); r14 battle -9 (con 42%); r15 battle -7 (con 41%); r15 elite -166 (con 33%); r16 battle -2 (con 33%); r17 battle -5 (con 33%); r18 boss -354 (con 15%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 15.1% (301/2000) |
| random_legal | 0 | 13.3% (267/2000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 7.3% (21/286) |
| attack_spam | beast_bird | 15.0% (43/286) |
| attack_spam | mixed_dmg | 15.4% (44/286) |
| attack_spam | mixed_std | 12.9% (37/286) |
| attack_spam | reptile_bug | 23.1% (66/286) |
| attack_spam | tank_heavy | 14.7% (42/285) |
| attack_spam | thorn_shield | 16.8% (48/285) |
| random_legal | aqua_plant | 4.2% (12/286) |
| random_legal | beast_bird | 14.0% (40/286) |
| random_legal | mixed_dmg | 13.6% (39/286) |
| random_legal | mixed_std | 11.5% (33/286) |
| random_legal | reptile_bug | 19.6% (56/286) |
| random_legal | tank_heavy | 12.3% (35/285) |
| random_legal | thorn_shield | 18.2% (52/285) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 15.5% (103/665) |
| attack_spam | greedy_axis | 15.5% (103/665) |
| attack_spam | random | 14.2% (95/670) |
| random_legal | combo | 16.4% (109/665) |
| random_legal | greedy_axis | 9.6% (64/665) |
| random_legal | random | 14.0% (94/670) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.6 luot (n=13366)
- attack_spam|boss: 6.4 luot (n=3452)
- attack_spam|elite: 4.9 luot (n=1957)
- random_legal|battle: 3.4 luot (n=12991)
- random_legal|boss: 6.0 luot (n=3175)
- random_legal|elite: 4.5 luot (n=1813)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 7
- attack_spam|battle r11: 18
- attack_spam|battle r13: 12
- attack_spam|battle r14: 9
- attack_spam|battle r15: 7
- attack_spam|battle r16: 2
- attack_spam|battle r17: 5
- attack_spam|battle r4: 76
- attack_spam|battle r5: 16
- attack_spam|battle r7: 8
- attack_spam|battle r8: 27
- attack_spam|battle r9: 8
- attack_spam|boss r12: 297
- attack_spam|boss r18: 354
- attack_spam|boss r6: 239
- attack_spam|elite r15: 166
- attack_spam|elite r5: 264
- attack_spam|elite r9: 184
- random_legal|battle r10: 14
- random_legal|battle r11: 25
- random_legal|battle r13: 19
- random_legal|battle r14: 8
- random_legal|battle r15: 12
- random_legal|battle r16: 11
- random_legal|battle r17: 11
- random_legal|battle r3: 2
- random_legal|battle r4: 135
- random_legal|battle r5: 40
- random_legal|battle r7: 16
- random_legal|battle r8: 44
- random_legal|battle r9: 19
- random_legal|boss r12: 228
- random_legal|boss r18: 325
- random_legal|boss r6: 183
- random_legal|elite r15: 169
- random_legal|elite r5: 290
- random_legal|elite r9: 182

Tran ket > 20 luot hoac khong ket thuc: 38 / 36754

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 42.0% | 9.9% | 9.9% | 100% |  |
| c_dewdrop | stat | 0 | 43.1% | 15.1% | 15.1% | 100% |  |
| c_elder_trunk | stat | 0 | 40.3% | 14.0% | 14.0% | 100% |  |
| c_prime_chain | dice | 0 | 43.0% | 14.5% | 12.8% | 88% |  |
| c_finisher | dice | 0 | 43.8% | 16.1% | 15.9% | 98% |  |
| c_bastion | pos | 0 | 65.2% | 24.4% | 24.3% | 99% |  |
| c_tidecaller | mana | 0 | 45.5% | 9.3% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.2% | 12.8% | 10.8% | 85% |  |
| c_nest | rule | 0 | 46.2% | 16.6% | 16.6% | 100% |  |
| c_spore_burst | rule | 0 | 43.1% | 14.5% | 14.2% | 98% |  |
| c_fossil | rule | 0 | 33.4% | 7.7% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.6% | 3.4% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.2% | 7.0% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 12.2% | 6.9% | 0.4% | 5% |  |
| rule_quick_beat | run_rule | 0 | 12.8% | 6.8% | 5.5% | 82% |  |
| rule_starfall | run_rule | 0 | 13.4% | 7.5% | 7.5% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 11.8% | 6.2% | 6.2% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.9% | 5.7% | 5.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 12.4% | 6.2% | 6.2% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.3% | 6.4% | 6.4% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.7% | 5.8% | 5.8% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.2% | 12.3% | 12.3% | 100% |  |
| rule_crow | run_rule | 0 | 13.3% | 5.0% | 4.2% | 84% |  |
| rule_hard_shell | run_rule | 0 | 21.1% | 8.2% | 8.2% | 100% |  |
| rule_balance | run_rule | 0 | 23.1% | 12.8% | 12.8% | 100% |  |
| c_prism | dice | 1 | 10.7% | 4.8% | 3.1% | 66% |  |
| c_steady_hold | dice | 1 | 9.6% | 2.2% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 10.2% | 4.6% | 0.6% | 12% |  |
| c_sonic_shield | dice | 1 | 10.8% | 4.5% | 4.3% | 94% |  |
| c_fissure | dice | 1 | 7.3% | 3.5% | 3.2% | 93% | LOW |
| c_field_medic | dice | 1 | 9.9% | 2.8% | 2.8% | 100% | LOW |
| c_plague_spread | dice | 1 | 6.9% | 2.9% | 2.8% | 97% | LOW |
| c_gatekeeper | pos | 1 | 19.9% | 9.6% | 9.4% | 98% |  |
| c_thorn_growth | pos | 1 | 22.0% | 5.8% | 5.7% | 99% |  |
| c_thorn_shield | stat | 1 | 62.3% | 12.6% | 12.6% | 100% |  |
| c_backline_glow | pos | 1 | 25.6% | 13.8% | 12.3% | 89% |  |
| c_growing_shell | pos | 1 | 19.8% | 10.2% | 8.3% | 81% |  |
| c_mana_ward | mana | 1 | 24.2% | 6.0% | 4.4% | 74% |  |
| c_overflow | mana | 1 | 20.8% | 8.4% | 5.1% | 61% |  |
| c_thorn_pact | mana | 1 | 17.8% | 7.7% | 7.5% | 97% |  |
| c_dry_well | quest | 1 | 21.1% | 2.4% | 2.4% | 100% |  |
| c_night_watch | quest | 1 | 19.5% | 2.2% | 2.2% | 100% |  |
| c_key_strike | quest | 1 | 20.8% | 2.4% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 20.1% | 4.8% | 4.8% | 100% |  |
| c_chimera_hunt | quest | 1 | 20.6% | 5.1% | 3.0% | 58% |  |
| c_golden_egg | rule | 1 | 8.7% | 7.3% | 4.5% | 61% | LOW |
| c_dim_stone | rule | 1 | 12.0% | 2.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 8.6% | 3.1% | 3.2% | 100% | LOW |
| c_sixth_die | dice | 2 | 9.5% | 4.2% | 4.3% | 100% | LOW |
| c_whittle | dice | 2 | 8.4% | 1.9% | 2.1% | 100% | LOW |
| c_three_dice | dice | 2 | 9.0% | 4.1% | 4.2% | 100% | LOW |
| c_concord | dice | 2 | 6.5% | 1.4% | 1.5% | 100% | LOW |
| c_toxic_still | dice | 2 | 6.2% | 1.4% | 1.5% | 100% | LOW |
| c_living_wall | pos | 2 | 24.4% | 11.3% | 11.4% | 100% |  |
| c_thorn_rebound | rule | 2 | 12.5% | 3.8% | 3.5% | 83% |  |
| c_open_ranks | pos | 2 | 4.7% | 1.9% | 1.9% | 100% | LOW |
| c_descend | pos | 2 | 13.2% | 6.0% | 6.0% | 98% |  |
| c_hollow_core | mana | 2 | 18.6% | 6.9% | 5.0% | 69% |  |
| c_deep_current | mana | 2 | 24.8% | 6.7% | 4.8% | 71% |  |
| c_blood_sign | rule | 2 | 8.7% | 4.2% | 4.5% | 100% | LOW |
| c_loop | rule | 2 | 10.3% | 4.9% | 4.4% | 86% |  |
| c_cascade | rule | 2 | 11.8% | 5.8% | 5.9% | 98% |  |
| c_sacrifice | rule | 2 | 13.4% | 4.5% | 4.5% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 61.9% (2474/4000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 42.9% (243/566)
- c_cascade: 39.7% (96/242)
- c_golden_egg: 36.9% (108/293)
- c_blood_sign: 36.7% (65/177)
- c_mirror_face: 33.1% (43/130)
- c_plague_spread: 31.0% (36/116)
- c_loop: 29.8% (61/205)
- c_nest: 28.2% (183/650)
- c_sixth_die: 28.1% (48/171)
- c_fissure: 25.4% (35/138)

Bottom 10:
- c_fossil: 0.0% (0/73)
- c_three_dice: 10.7% (18/169)
- c_tidecaller: 11.1% (41/368)
- c_bastion: 12.0% (115/960)
- c_mana_pool: 12.7% (63/497)
- c_kindle: 13.2% (24/182)
- c_deep_current: 13.9% (38/273)
- c_thorn_pact: 14.6% (45/308)
- c_prime_chain: 14.7% (84/571)
- c_toxic_still: 14.8% (9/61)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_cascade + c_hollow_core: 80.0% (8/10)
- c_golden_egg + c_sixth_die: 75.0% (6/8)
- c_prism + c_spore_burst: 72.7% (8/11)
- c_mirror_face + c_plague_spread: 66.7% (8/12)
- c_collector + c_golden_egg: 66.7% (6/9)
- c_overflow + c_three_dice: 0.0% (0/9)
- c_living_wall + c_night_watch: 0.0% (0/9)
- c_fossil + c_nest: 0.0% (0/10)
- c_hollow_core + c_three_dice: 0.0% (0/8)
- c_backline_glow + c_steady_hold: 0.0% (0/8)
