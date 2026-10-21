# Sim balance td_r2_cheap

Runs: 2000, wall 110.4s (0.06s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 12.7% -> CHUA DAT
- attack_spam <= 5%: 14.6% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=1000): r3 battle -1 (con 100%); r4 battle -72 (con 93%); r5 elite -155 (con 77%); r5 battle -17 (con 76%); r6 boss -98 (con 66%); r7 battle -8 (con 65%); r8 battle -19 (con 63%); r9 battle -10 (con 62%); r9 elite -95 (con 52%); r10 battle -6 (con 52%); r11 battle -12 (con 51%); r12 boss -111 (con 40%); r13 battle -7 (con 39%); r14 battle -4 (con 38%); r15 battle -5 (con 38%); r15 elite -89 (con 29%); r16 battle -4 (con 29%); r17 battle -4 (con 28%); r18 boss -156 (con 13%)
- **attack_spam** (n=1000): r4 battle -38 (con 96%); r5 elite -125 (con 84%); r5 battle -8 (con 83%); r6 boss -128 (con 70%); r7 battle -6 (con 70%); r8 battle -18 (con 68%); r9 battle -1 (con 68%); r9 elite -93 (con 58%); r10 battle -1 (con 58%); r11 battle -8 (con 57%); r12 boss -151 (con 42%); r13 battle -8 (con 42%); r14 battle -6 (con 41%); r15 battle -4 (con 40%); r15 elite -84 (con 32%); r16 battle -1 (con 32%); r17 battle -2 (con 32%); r18 boss -172 (con 15%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 14.6% (146/1000) |
| random_legal | 0 | 12.7% (127/1000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 7.0% (10/143) |
| attack_spam | beast_bird | 17.5% (25/143) |
| attack_spam | mixed_dmg | 14.0% (20/143) |
| attack_spam | mixed_std | 10.5% (15/143) |
| attack_spam | reptile_bug | 21.7% (31/143) |
| attack_spam | tank_heavy | 14.0% (20/143) |
| attack_spam | thorn_shield | 17.6% (25/142) |
| random_legal | aqua_plant | 3.5% (5/143) |
| random_legal | beast_bird | 15.4% (22/143) |
| random_legal | mixed_dmg | 11.9% (17/143) |
| random_legal | mixed_std | 9.8% (14/143) |
| random_legal | reptile_bug | 21.7% (31/143) |
| random_legal | tank_heavy | 8.4% (12/143) |
| random_legal | thorn_shield | 18.3% (26/142) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 14.3% (47/329) |
| attack_spam | greedy_axis | 15.2% (51/335) |
| attack_spam | random | 14.3% (48/336) |
| random_legal | combo | 14.9% (49/329) |
| random_legal | greedy_axis | 9.3% (31/335) |
| random_legal | random | 14.0% (47/336) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.6 luot (n=6676)
- attack_spam|boss: 6.5 luot (n=1721)
- attack_spam|elite: 4.9 luot (n=979)
- random_legal|battle: 3.4 luot (n=6348)
- random_legal|boss: 6.0 luot (n=1545)
- random_legal|elite: 4.6 luot (n=914)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 1
- attack_spam|battle r11: 8
- attack_spam|battle r13: 8
- attack_spam|battle r14: 6
- attack_spam|battle r15: 4
- attack_spam|battle r16: 1
- attack_spam|battle r17: 2
- attack_spam|battle r4: 38
- attack_spam|battle r5: 8
- attack_spam|battle r7: 6
- attack_spam|battle r8: 18
- attack_spam|battle r9: 1
- attack_spam|boss r12: 151
- attack_spam|boss r18: 172
- attack_spam|boss r6: 128
- attack_spam|elite r15: 84
- attack_spam|elite r5: 125
- attack_spam|elite r9: 93
- random_legal|battle r10: 6
- random_legal|battle r11: 12
- random_legal|battle r13: 7
- random_legal|battle r14: 4
- random_legal|battle r15: 5
- random_legal|battle r16: 4
- random_legal|battle r17: 4
- random_legal|battle r3: 1
- random_legal|battle r4: 72
- random_legal|battle r5: 17
- random_legal|battle r7: 8
- random_legal|battle r8: 19
- random_legal|battle r9: 10
- random_legal|boss r12: 111
- random_legal|boss r18: 156
- random_legal|boss r6: 98
- random_legal|elite r15: 89
- random_legal|elite r5: 155
- random_legal|elite r9: 95

Tran ket > 20 luot hoac khong ket thuc: 14 / 18183

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 42.0% | 9.6% | 9.6% | 100% |  |
| c_dewdrop | stat | 0 | 41.0% | 14.6% | 14.6% | 100% |  |
| c_elder_trunk | stat | 0 | 41.0% | 14.3% | 14.3% | 100% |  |
| c_prime_chain | dice | 0 | 43.0% | 13.7% | 12.2% | 89% |  |
| c_finisher | dice | 0 | 42.7% | 15.9% | 15.8% | 99% |  |
| c_bastion | pos | 0 | 66.6% | 26.6% | 26.4% | 99% |  |
| c_tidecaller | mana | 0 | 44.2% | 8.7% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.4% | 12.6% | 10.9% | 87% |  |
| c_nest | rule | 0 | 45.1% | 14.9% | 14.9% | 100% |  |
| c_spore_burst | rule | 0 | 44.1% | 14.1% | 13.9% | 99% |  |
| c_fossil | rule | 0 | 33.0% | 7.7% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.2% | 3.3% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 11.0% | 6.2% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 12.5% | 7.5% | 0.5% | 7% |  |
| rule_quick_beat | run_rule | 0 | 13.3% | 7.0% | 5.8% | 82% |  |
| rule_starfall | run_rule | 0 | 14.3% | 7.6% | 7.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 12.4% | 6.3% | 6.3% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.7% | 5.7% | 5.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 11.6% | 6.4% | 6.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.9% | 6.7% | 6.7% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.4% | 5.7% | 5.7% | 100% |  |
| rule_old_forest | run_rule | 0 | 21.9% | 12.3% | 12.3% | 100% |  |
| rule_crow | run_rule | 0 | 14.2% | 4.4% | 3.5% | 80% |  |
| rule_hard_shell | run_rule | 0 | 21.6% | 8.7% | 8.7% | 100% |  |
| rule_balance | run_rule | 0 | 22.0% | 12.2% | 12.2% | 100% |  |
| c_prism | dice | 1 | 9.8% | 4.5% | 2.7% | 60% | LOW |
| c_steady_hold | dice | 1 | 9.8% | 2.3% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 10.4% | 5.2% | 0.5% | 9% |  |
| c_sonic_shield | dice | 1 | 10.4% | 4.2% | 3.9% | 93% |  |
| c_fissure | dice | 1 | 7.6% | 3.2% | 2.9% | 91% | LOW |
| c_field_medic | dice | 1 | 11.1% | 3.0% | 3.0% | 100% |  |
| c_plague_spread | dice | 1 | 7.0% | 3.0% | 3.0% | 100% | LOW |
| c_gatekeeper | pos | 1 | 19.6% | 9.8% | 9.6% | 98% |  |
| c_thorn_growth | pos | 1 | 22.0% | 6.6% | 6.5% | 98% |  |
| c_thorn_shield | stat | 1 | 62.2% | 12.6% | 12.5% | 100% |  |
| c_backline_glow | pos | 1 | 25.4% | 14.3% | 12.7% | 88% |  |
| c_growing_shell | pos | 1 | 20.0% | 10.6% | 8.8% | 83% |  |
| c_mana_ward | mana | 1 | 24.1% | 5.8% | 4.5% | 76% |  |
| c_overflow | mana | 1 | 21.0% | 8.2% | 4.8% | 59% |  |
| c_thorn_pact | mana | 1 | 18.9% | 8.4% | 8.3% | 98% |  |
| c_dry_well | quest | 1 | 20.0% | 1.9% | 1.9% | 100% |  |
| c_night_watch | quest | 1 | 20.1% | 2.1% | 2.1% | 100% |  |
| c_key_strike | quest | 1 | 21.5% | 3.0% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 19.2% | 5.2% | 5.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 20.2% | 5.3% | 3.0% | 58% |  |
| c_golden_egg | rule | 1 | 7.8% | 6.1% | 3.5% | 57% | LOW |
| c_dim_stone | rule | 1 | 12.4% | 2.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 7.9% | 3.0% | 3.2% | 100% | LOW |
| c_sixth_die | dice | 2 | 9.1% | 4.3% | 4.3% | 100% | LOW |
| c_whittle | dice | 2 | 8.4% | 2.0% | 2.0% | 100% | LOW |
| c_three_dice | dice | 2 | 9.1% | 4.2% | 4.5% | 100% | LOW |
| c_concord | dice | 2 | 6.6% | 1.8% | 1.9% | 100% | LOW |
| c_toxic_still | dice | 2 | 5.7% | 1.4% | 1.4% | 100% | LOW |
| c_living_wall | pos | 2 | 24.6% | 11.2% | 11.3% | 100% |  |
| c_thorn_rebound | rule | 2 | 11.6% | 3.5% | 3.1% | 79% |  |
| c_open_ranks | pos | 2 | 5.0% | 2.2% | 2.2% | 100% | LOW |
| c_descend | pos | 2 | 13.6% | 6.7% | 6.5% | 97% |  |
| c_hollow_core | mana | 2 | 17.6% | 6.0% | 4.2% | 65% |  |
| c_deep_current | mana | 2 | 24.1% | 6.0% | 4.3% | 72% |  |
| c_blood_sign | rule | 2 | 7.7% | 3.5% | 3.9% | 100% | LOW |
| c_loop | rule | 2 | 10.1% | 4.7% | 4.2% | 84% |  |
| c_cascade | rule | 2 | 11.6% | 5.3% | 5.8% | 100% |  |
| c_sacrifice | rule | 2 | 11.5% | 3.8% | 3.8% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.0% (1240/2000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 40.3% (112/278)
- c_cascade: 40.0% (46/115)
- c_mirror_face: 37.5% (24/64)
- c_golden_egg: 34.7% (42/121)
- c_night_watch: 31.0% (13/42)
- c_sixth_die: 29.9% (26/87)
- c_blood_sign: 29.9% (23/77)
- c_nest: 27.9% (83/297)
- c_plague_spread: 26.2% (16/61)
- c_loop: 25.3% (25/99)

Bottom 10:
- c_fossil: 0.0% (0/38)
- c_three_dice: 6.7% (6/89)
- c_kindle: 10.6% (11/104)
- c_bastion: 10.9% (57/525)
- c_open_ranks: 11.4% (5/44)
- c_collector: 11.4% (12/105)
- c_tidecaller: 11.6% (20/172)
- c_deep_current: 11.7% (14/120)
- c_key_strike: 12.1% (7/58)
- c_thorn_pact: 14.2% (24/169)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_mirror_face + c_spore_burst: 87.5% (7/8)
- c_early_scales + c_spore_burst: 80.0% (8/10)
- c_plague_spread + c_sixth_die: 75.0% (6/8)
- c_dewdrop + c_tidecaller: 70.0% (7/10)
- c_elder_trunk + c_spore_burst: 64.0% (16/25)
- c_collector + c_finisher: 0.0% (0/12)
- c_dry_well + c_tidecaller: 0.0% (0/9)
- c_finisher + c_three_dice: 0.0% (0/32)
- c_elder_trunk + c_steady_hold: 0.0% (0/8)
- c_descend + c_thorn_pact: 0.0% (0/11)
