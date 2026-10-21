# Sim balance td_r3_cheap

Runs: 2000, wall 98.2s (0.05s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 12.6% -> CHUA DAT
- attack_spam <= 5%: 11.8% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=1000): r3 battle -2 (con 100%); r4 battle -76 (con 92%); r5 battle -22 (con 90%); r5 elite -167 (con 73%); r6 boss -115 (con 62%); r7 battle -10 (con 61%); r8 battle -27 (con 58%); r9 elite -80 (con 50%); r9 battle -11 (con 49%); r10 battle -8 (con 48%); r11 battle -17 (con 46%); r12 boss -104 (con 36%); r13 battle -8 (con 35%); r14 battle -5 (con 35%); r15 battle -1 (con 35%); r15 elite -65 (con 28%); r16 battle -1 (con 28%); r17 battle -4 (con 28%); r18 boss -151 (con 13%)
- **attack_spam** (n=1000): r4 battle -46 (con 95%); r5 elite -132 (con 82%); r5 battle -8 (con 81%); r6 boss -151 (con 66%); r7 battle -5 (con 66%); r8 battle -16 (con 64%); r9 battle -3 (con 64%); r9 elite -88 (con 55%); r10 battle -5 (con 55%); r11 battle -14 (con 53%); r12 boss -125 (con 41%); r13 battle -11 (con 40%); r14 battle -8 (con 39%); r15 battle -11 (con 38%); r15 elite -91 (con 29%); r16 battle -3 (con 28%); r17 battle -2 (con 28%); r18 boss -163 (con 12%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 11.8% (118/1000) |
| random_legal | 0 | 12.6% (126/1000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 4.2% (6/143) |
| attack_spam | beast_bird | 20.3% (29/143) |
| attack_spam | mixed_dmg | 11.9% (17/143) |
| attack_spam | mixed_std | 8.4% (12/143) |
| attack_spam | reptile_bug | 16.8% (24/143) |
| attack_spam | tank_heavy | 11.9% (17/143) |
| attack_spam | thorn_shield | 9.2% (13/142) |
| random_legal | aqua_plant | 4.9% (7/143) |
| random_legal | beast_bird | 14.7% (21/143) |
| random_legal | mixed_dmg | 12.6% (18/143) |
| random_legal | mixed_std | 8.4% (12/143) |
| random_legal | reptile_bug | 18.2% (26/143) |
| random_legal | tank_heavy | 8.4% (12/143) |
| random_legal | thorn_shield | 21.1% (30/142) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 11.9% (39/329) |
| attack_spam | greedy_axis | 13.1% (44/335) |
| attack_spam | random | 10.4% (35/336) |
| random_legal | combo | 15.2% (50/329) |
| random_legal | greedy_axis | 9.9% (33/335) |
| random_legal | random | 12.8% (43/336) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.6 luot (n=6468)
- attack_spam|boss: 6.3 luot (n=1627)
- attack_spam|elite: 4.9 luot (n=933)
- random_legal|battle: 3.4 luot (n=6171)
- random_legal|boss: 6.1 luot (n=1475)
- random_legal|elite: 4.4 luot (n=863)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 5
- attack_spam|battle r11: 14
- attack_spam|battle r13: 11
- attack_spam|battle r14: 8
- attack_spam|battle r15: 11
- attack_spam|battle r16: 3
- attack_spam|battle r17: 2
- attack_spam|battle r4: 46
- attack_spam|battle r5: 8
- attack_spam|battle r7: 5
- attack_spam|battle r8: 16
- attack_spam|battle r9: 3
- attack_spam|boss r12: 125
- attack_spam|boss r18: 163
- attack_spam|boss r6: 151
- attack_spam|elite r15: 91
- attack_spam|elite r5: 132
- attack_spam|elite r9: 88
- random_legal|battle r10: 8
- random_legal|battle r11: 17
- random_legal|battle r13: 8
- random_legal|battle r14: 5
- random_legal|battle r15: 1
- random_legal|battle r16: 1
- random_legal|battle r17: 4
- random_legal|battle r3: 2
- random_legal|battle r4: 76
- random_legal|battle r5: 22
- random_legal|battle r7: 10
- random_legal|battle r8: 27
- random_legal|battle r9: 11
- random_legal|boss r12: 104
- random_legal|boss r18: 151
- random_legal|boss r6: 115
- random_legal|elite r15: 65
- random_legal|elite r5: 167
- random_legal|elite r9: 80

Tran ket > 20 luot hoac khong ket thuc: 13 / 17537

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.5% | 9.7% | 9.7% | 100% |  |
| c_dewdrop | stat | 0 | 39.4% | 13.3% | 13.3% | 100% |  |
| c_elder_trunk | stat | 0 | 39.2% | 13.5% | 13.5% | 100% |  |
| c_prime_chain | dice | 0 | 42.3% | 13.3% | 11.8% | 89% |  |
| c_finisher | dice | 0 | 42.2% | 15.7% | 15.4% | 98% |  |
| c_bastion | pos | 0 | 66.4% | 26.4% | 26.1% | 99% |  |
| c_tidecaller | mana | 0 | 44.9% | 8.8% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.1% | 13.1% | 11.5% | 88% |  |
| c_nest | rule | 0 | 44.8% | 15.1% | 15.1% | 100% |  |
| c_spore_burst | rule | 0 | 42.8% | 14.2% | 14.0% | 99% |  |
| c_fossil | rule | 0 | 32.9% | 7.5% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.2% | 3.3% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 11.0% | 6.2% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 12.5% | 7.5% | 0.3% | 4% |  |
| rule_quick_beat | run_rule | 0 | 13.3% | 7.0% | 5.5% | 79% |  |
| rule_starfall | run_rule | 0 | 14.3% | 7.6% | 7.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 12.4% | 6.3% | 6.3% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.7% | 5.7% | 5.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 11.6% | 6.4% | 6.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.9% | 6.7% | 6.7% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.4% | 5.7% | 5.7% | 100% |  |
| rule_old_forest | run_rule | 0 | 21.9% | 12.3% | 12.3% | 100% |  |
| rule_crow | run_rule | 0 | 14.2% | 4.4% | 3.4% | 77% |  |
| rule_hard_shell | run_rule | 0 | 21.6% | 8.7% | 8.7% | 100% |  |
| rule_balance | run_rule | 0 | 22.0% | 12.2% | 12.2% | 100% |  |
| c_prism | dice | 1 | 8.7% | 3.6% | 2.3% | 63% | LOW |
| c_steady_hold | dice | 1 | 9.7% | 2.4% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 10.3% | 5.2% | 0.3% | 6% |  |
| c_sonic_shield | dice | 1 | 9.7% | 3.8% | 3.5% | 92% | LOW |
| c_fissure | dice | 1 | 7.5% | 3.1% | 3.0% | 94% | LOW |
| c_field_medic | dice | 1 | 11.2% | 3.0% | 3.0% | 100% |  |
| c_plague_spread | dice | 1 | 6.5% | 2.6% | 2.5% | 98% | LOW |
| c_gatekeeper | pos | 1 | 19.0% | 9.3% | 9.2% | 98% |  |
| c_thorn_growth | pos | 1 | 20.6% | 5.6% | 5.5% | 97% |  |
| c_thorn_shield | stat | 1 | 59.6% | 12.3% | 12.2% | 99% |  |
| c_backline_glow | pos | 1 | 25.2% | 13.9% | 12.7% | 91% |  |
| c_growing_shell | pos | 1 | 19.4% | 10.3% | 8.3% | 81% |  |
| c_mana_ward | mana | 1 | 22.6% | 5.3% | 3.9% | 73% |  |
| c_overflow | mana | 1 | 21.6% | 8.7% | 5.4% | 62% |  |
| c_thorn_pact | mana | 1 | 17.9% | 8.2% | 7.7% | 93% |  |
| c_dry_well | quest | 1 | 19.0% | 1.9% | 1.9% | 100% |  |
| c_night_watch | quest | 1 | 19.4% | 2.4% | 2.4% | 100% |  |
| c_key_strike | quest | 1 | 19.8% | 2.8% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 19.4% | 5.0% | 5.0% | 100% |  |
| c_chimera_hunt | quest | 1 | 19.2% | 5.5% | 3.0% | 55% |  |
| c_golden_egg | rule | 1 | 8.6% | 6.9% | 3.8% | 55% | LOW |
| c_dim_stone | rule | 1 | 11.6% | 2.5% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 7.3% | 2.9% | 3.0% | 100% | LOW |
| c_sixth_die | dice | 2 | 8.7% | 4.0% | 4.0% | 100% | LOW |
| c_whittle | dice | 2 | 7.2% | 1.9% | 1.9% | 100% | LOW |
| c_three_dice | dice | 2 | 8.2% | 3.2% | 3.4% | 100% | LOW |
| c_concord | dice | 2 | 6.6% | 1.6% | 1.6% | 97% | LOW |
| c_toxic_still | dice | 2 | 5.5% | 1.1% | 1.1% | 100% | LOW |
| c_living_wall | pos | 2 | 22.5% | 10.6% | 10.7% | 100% |  |
| c_thorn_rebound | rule | 2 | 11.6% | 4.2% | 3.6% | 79% |  |
| c_open_ranks | pos | 2 | 4.8% | 2.3% | 2.3% | 100% | LOW |
| c_descend | pos | 2 | 12.9% | 6.6% | 6.5% | 98% |  |
| c_hollow_core | mana | 2 | 17.1% | 5.2% | 3.8% | 67% |  |
| c_deep_current | mana | 2 | 22.9% | 5.1% | 3.6% | 70% |  |
| c_blood_sign | rule | 2 | 7.5% | 3.5% | 3.8% | 100% | LOW |
| c_loop | rule | 2 | 10.2% | 5.2% | 4.5% | 81% |  |
| c_cascade | rule | 2 | 10.2% | 4.8% | 5.1% | 98% |  |
| c_sacrifice | rule | 2 | 11.2% | 3.2% | 3.3% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 60.5% (1210/2000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 35.5% (97/273)
- c_blood_sign: 34.7% (26/75)
- c_cascade: 34.6% (36/104)
- c_golden_egg: 30.4% (42/138)
- c_sixth_die: 30.0% (24/80)
- c_dry_well: 27.0% (10/37)
- c_nest: 25.0% (75/300)
- c_mirror_face: 24.6% (15/61)
- c_sacrifice: 24.2% (16/66)
- c_plague_spread: 23.1% (12/52)

Bottom 10:
- c_fossil: 0.0% (0/48)
- c_tidecaller: 8.5% (15/176)
- c_three_dice: 9.0% (6/67)
- c_prism: 9.6% (7/73)
- c_hollow_core: 10.1% (11/109)
- c_bastion: 10.6% (55/519)
- c_mana_pool: 12.1% (31/257)
- c_mana_ward: 12.3% (13/106)
- c_dewdrop: 12.9% (34/264)
- c_deep_current: 13.5% (14/104)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_prime_chain + c_thorn_pact: 63.6% (7/11)
- c_elder_trunk + c_golden_egg: 62.5% (5/8)
- c_mana_pool + c_sixth_die: 62.5% (5/8)
- c_bastion + c_golden_egg: 60.0% (6/10)
- c_sixth_die + c_spore_burst: 58.3% (7/12)
- c_elder_trunk + c_fissure: 0.0% (0/9)
- c_kindle + c_overflow: 0.0% (0/8)
- c_bastion + c_prime_chain: 0.0% (0/10)
- c_kindle + c_sonic_shield: 0.0% (0/8)
- c_growing_shell + c_hollow_core: 0.0% (0/8)
