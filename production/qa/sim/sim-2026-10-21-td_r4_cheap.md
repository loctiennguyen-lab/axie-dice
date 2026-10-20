# Sim balance td_r4_cheap

Runs: 2000, wall 105.8s (0.05s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 13.1% -> CHUA DAT
- attack_spam <= 5%: 13.6% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=1000): r3 battle -1 (con 100%); r4 battle -71 (con 93%); r5 battle -22 (con 91%); r5 elite -157 (con 75%); r6 boss -96 (con 65%); r7 battle -8 (con 64%); r8 battle -25 (con 62%); r9 elite -88 (con 53%); r9 battle -7 (con 52%); r10 battle -8 (con 52%); r11 battle -22 (con 50%); r12 boss -95 (con 40%); r13 battle -5 (con 40%); r14 battle -2 (con 39%); r15 battle -16 (con 38%); r15 elite -75 (con 30%); r16 battle -3 (con 30%); r17 battle -6 (con 29%); r18 boss -162 (con 13%)
- **attack_spam** (n=1000): r4 battle -43 (con 96%); r5 elite -129 (con 83%); r5 battle -8 (con 82%); r6 boss -112 (con 71%); r7 battle -8 (con 70%); r8 battle -23 (con 68%); r9 elite -86 (con 59%); r9 battle -4 (con 59%); r10 battle -5 (con 58%); r11 battle -9 (con 57%); r12 boss -154 (con 42%); r13 battle -9 (con 41%); r14 battle -5 (con 40%); r15 elite -72 (con 33%); r15 battle -6 (con 33%); r16 battle -4 (con 32%); r17 battle -5 (con 32%); r18 boss -182 (con 14%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 13.6% (136/1000) |
| random_legal | 0 | 13.1% (131/1000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 5.6% (8/143) |
| attack_spam | beast_bird | 17.5% (25/143) |
| attack_spam | mixed_dmg | 10.5% (15/143) |
| attack_spam | mixed_std | 11.9% (17/143) |
| attack_spam | reptile_bug | 20.3% (29/143) |
| attack_spam | tank_heavy | 12.6% (18/143) |
| attack_spam | thorn_shield | 16.9% (24/142) |
| random_legal | aqua_plant | 5.6% (8/143) |
| random_legal | beast_bird | 18.2% (26/143) |
| random_legal | mixed_dmg | 12.6% (18/143) |
| random_legal | mixed_std | 6.3% (9/143) |
| random_legal | reptile_bug | 18.2% (26/143) |
| random_legal | tank_heavy | 9.8% (14/143) |
| random_legal | thorn_shield | 21.1% (30/142) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 13.7% (45/329) |
| attack_spam | greedy_axis | 14.0% (47/335) |
| attack_spam | random | 13.1% (44/336) |
| random_legal | combo | 14.9% (49/329) |
| random_legal | greedy_axis | 11.9% (40/335) |
| random_legal | random | 12.5% (42/336) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.6 luot (n=6669)
- attack_spam|boss: 6.1 luot (n=1711)
- attack_spam|elite: 4.9 luot (n=955)
- random_legal|battle: 3.5 luot (n=6399)
- random_legal|boss: 5.8 luot (n=1537)
- random_legal|elite: 4.5 luot (n=896)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 5
- attack_spam|battle r11: 9
- attack_spam|battle r13: 9
- attack_spam|battle r14: 5
- attack_spam|battle r15: 6
- attack_spam|battle r16: 4
- attack_spam|battle r17: 5
- attack_spam|battle r4: 43
- attack_spam|battle r5: 8
- attack_spam|battle r7: 8
- attack_spam|battle r8: 23
- attack_spam|battle r9: 4
- attack_spam|boss r12: 154
- attack_spam|boss r18: 182
- attack_spam|boss r6: 112
- attack_spam|elite r15: 72
- attack_spam|elite r5: 129
- attack_spam|elite r9: 86
- random_legal|battle r10: 8
- random_legal|battle r11: 22
- random_legal|battle r13: 5
- random_legal|battle r14: 2
- random_legal|battle r15: 16
- random_legal|battle r16: 3
- random_legal|battle r17: 6
- random_legal|battle r3: 1
- random_legal|battle r4: 71
- random_legal|battle r5: 22
- random_legal|battle r7: 8
- random_legal|battle r8: 25
- random_legal|battle r9: 7
- random_legal|boss r12: 95
- random_legal|boss r18: 162
- random_legal|boss r6: 96
- random_legal|elite r15: 75
- random_legal|elite r5: 157
- random_legal|elite r9: 88

Tran ket > 20 luot hoac khong ket thuc: 10 / 18167

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 41.1% | 9.4% | 9.4% | 100% |  |
| c_dewdrop | stat | 0 | 40.0% | 13.9% | 13.9% | 100% |  |
| c_elder_trunk | stat | 0 | 41.2% | 13.9% | 13.9% | 100% |  |
| c_prime_chain | dice | 0 | 43.2% | 14.3% | 12.7% | 88% |  |
| c_finisher | dice | 0 | 43.3% | 15.8% | 15.8% | 100% |  |
| c_bastion | pos | 0 | 66.8% | 26.4% | 26.1% | 99% |  |
| c_tidecaller | mana | 0 | 45.1% | 8.9% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 41.6% | 12.8% | 11.4% | 89% |  |
| c_nest | rule | 0 | 45.8% | 15.3% | 15.3% | 100% |  |
| c_spore_burst | rule | 0 | 44.5% | 14.7% | 14.3% | 97% |  |
| c_fossil | rule | 0 | 33.0% | 7.4% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.2% | 3.3% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 11.0% | 6.2% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 12.5% | 7.5% | 0.5% | 6% |  |
| rule_quick_beat | run_rule | 0 | 13.3% | 7.0% | 5.7% | 81% |  |
| rule_starfall | run_rule | 0 | 14.3% | 7.6% | 7.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 12.4% | 6.3% | 6.3% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.7% | 5.7% | 5.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 11.6% | 6.4% | 6.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.9% | 6.7% | 6.7% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.4% | 5.7% | 5.7% | 100% |  |
| rule_old_forest | run_rule | 0 | 21.9% | 12.3% | 12.3% | 100% |  |
| rule_crow | run_rule | 0 | 14.2% | 4.4% | 3.6% | 82% |  |
| rule_hard_shell | run_rule | 0 | 21.6% | 8.7% | 8.7% | 100% |  |
| rule_balance | run_rule | 0 | 22.0% | 12.2% | 12.2% | 100% |  |
| c_prism | dice | 1 | 9.1% | 3.9% | 2.4% | 60% | LOW |
| c_steady_hold | dice | 1 | 9.2% | 2.2% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 10.6% | 4.8% | 0.6% | 11% |  |
| c_sonic_shield | dice | 1 | 10.3% | 3.8% | 3.5% | 93% |  |
| c_fissure | dice | 1 | 7.5% | 3.0% | 2.8% | 95% | LOW |
| c_field_medic | dice | 1 | 11.6% | 3.1% | 3.1% | 100% |  |
| c_plague_spread | dice | 1 | 6.8% | 2.9% | 2.9% | 100% | LOW |
| c_gatekeeper | pos | 1 | 20.4% | 9.3% | 9.1% | 97% |  |
| c_thorn_growth | pos | 1 | 21.9% | 6.5% | 6.2% | 97% |  |
| c_thorn_shield | stat | 1 | 61.1% | 13.3% | 13.2% | 99% |  |
| c_backline_glow | pos | 1 | 26.0% | 15.2% | 13.2% | 87% |  |
| c_growing_shell | pos | 1 | 20.2% | 11.0% | 8.7% | 79% |  |
| c_mana_ward | mana | 1 | 24.2% | 5.7% | 4.3% | 76% |  |
| c_overflow | mana | 1 | 22.2% | 8.9% | 5.2% | 58% |  |
| c_thorn_pact | mana | 1 | 18.5% | 8.2% | 8.0% | 98% |  |
| c_dry_well | quest | 1 | 19.8% | 1.9% | 1.9% | 100% |  |
| c_night_watch | quest | 1 | 20.2% | 2.2% | 2.2% | 100% |  |
| c_key_strike | quest | 1 | 20.8% | 2.9% | 0.1% | 5% |  |
| c_collector | quest | 1 | 19.2% | 5.2% | 5.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 19.3% | 4.9% | 3.0% | 62% |  |
| c_golden_egg | rule | 1 | 8.0% | 6.2% | 3.5% | 56% | LOW |
| c_dim_stone | rule | 1 | 12.6% | 2.9% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 7.6% | 2.9% | 3.0% | 100% | LOW |
| c_sixth_die | dice | 2 | 9.2% | 4.0% | 4.0% | 100% | LOW |
| c_whittle | dice | 2 | 7.7% | 1.8% | 1.8% | 100% | LOW |
| c_three_dice | dice | 2 | 10.2% | 4.5% | 4.7% | 100% |  |
| c_concord | dice | 2 | 6.8% | 1.6% | 1.7% | 100% | LOW |
| c_toxic_still | dice | 2 | 5.5% | 1.1% | 1.2% | 100% | LOW |
| c_living_wall | pos | 2 | 24.4% | 11.1% | 11.2% | 100% |  |
| c_thorn_rebound | rule | 2 | 12.6% | 4.3% | 3.5% | 77% |  |
| c_open_ranks | pos | 2 | 4.5% | 1.9% | 1.9% | 100% | LOW |
| c_descend | pos | 2 | 14.1% | 7.0% | 6.8% | 97% |  |
| c_hollow_core | mana | 2 | 17.2% | 5.5% | 3.7% | 63% |  |
| c_deep_current | mana | 2 | 24.6% | 5.9% | 4.6% | 77% |  |
| c_blood_sign | rule | 2 | 8.2% | 4.3% | 4.7% | 100% | LOW |
| c_loop | rule | 2 | 9.9% | 5.0% | 4.3% | 81% | LOW |
| c_cascade | rule | 2 | 10.9% | 5.0% | 5.2% | 98% |  |
| c_sacrifice | rule | 2 | 12.2% | 4.1% | 4.2% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.3% (1246/2000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_golden_egg: 38.4% (48/125)
- c_spore_burst: 38.0% (108/284)
- c_cascade: 37.4% (40/107)
- c_sixth_die: 28.4% (23/81)
- c_mirror_face: 28.3% (17/60)
- c_blood_sign: 27.7% (26/94)
- c_concord: 26.5% (9/34)
- c_sacrifice: 26.2% (22/84)
- c_nest: 25.0% (75/300)
- c_chimera_hunt: 24.5% (24/98)

Bottom 10:
- c_fossil: 0.0% (0/40)
- c_three_dice: 5.3% (5/94)
- c_bastion: 10.8% (56/519)
- c_steady_hold: 11.4% (5/44)
- c_mana_ward: 11.5% (13/113)
- c_toxic_still: 12.5% (3/24)
- c_key_strike: 12.5% (7/56)
- c_tidecaller: 13.2% (23/174)
- c_mana_pool: 13.9% (35/252)
- c_finisher: 14.9% (46/308)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_kindle + c_thorn_shield: 75.0% (6/8)
- c_spore_burst + c_tidecaller: 66.7% (6/9)
- c_golden_egg + c_living_wall: 63.6% (7/11)
- c_prime_chain + c_spore_burst: 61.9% (13/21)
- c_living_wall + c_spore_burst: 61.5% (16/26)
- c_chimera_hunt + c_three_dice: 0.0% (0/9)
- c_finisher + c_thorn_pact: 0.0% (0/12)
- c_backline_glow + c_loop: 0.0% (0/9)
- c_early_scales + c_key_strike: 0.0% (0/8)
- c_gatekeeper + c_mana_pool: 0.0% (0/9)
