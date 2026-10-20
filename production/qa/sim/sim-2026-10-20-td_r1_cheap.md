# Sim balance td_r1_cheap

Runs: 1000, wall 66.6s (0.07s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 23.2% -> CHUA DAT
- attack_spam <= 5%: 25.6% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=500): r4 battle -16 (con 97%); r5 elite -76 (con 82%); r5 battle -2 (con 81%); r6 boss -27 (con 76%); r7 battle -4 (con 75%); r8 battle -4 (con 74%); r9 elite -41 (con 66%); r9 battle -3 (con 65%); r11 battle -3 (con 65%); r12 boss -47 (con 55%); r13 battle -4 (con 55%); r14 battle -1 (con 54%); r15 elite -39 (con 47%); r15 battle -3 (con 46%); r16 battle -2 (con 46%); r18 boss -112 (con 23%)
- **attack_spam** (n=500): r4 battle -13 (con 97%); r5 battle -2 (con 97%); r5 elite -38 (con 89%); r6 boss -25 (con 84%); r7 battle -2 (con 84%); r8 battle -7 (con 83%); r9 elite -28 (con 77%); r9 battle -1 (con 77%); r10 battle -2 (con 76%); r11 battle -6 (con 75%); r12 boss -65 (con 62%); r13 battle -2 (con 62%); r14 battle -3 (con 61%); r15 elite -38 (con 54%); r15 battle -4 (con 53%); r17 battle -2 (con 52%); r18 boss -134 (con 26%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 25.6% (128/500) |
| random_legal | 0 | 23.2% (116/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 13.9% (10/72) |
| attack_spam | beast_bird | 36.1% (26/72) |
| attack_spam | mixed_dmg | 22.5% (16/71) |
| attack_spam | mixed_std | 22.5% (16/71) |
| attack_spam | reptile_bug | 29.2% (21/72) |
| attack_spam | tank_heavy | 25.4% (18/71) |
| attack_spam | thorn_shield | 29.6% (21/71) |
| random_legal | aqua_plant | 11.1% (8/72) |
| random_legal | beast_bird | 20.8% (15/72) |
| random_legal | mixed_dmg | 21.1% (15/71) |
| random_legal | mixed_std | 12.7% (9/71) |
| random_legal | reptile_bug | 40.3% (29/72) |
| random_legal | tank_heavy | 22.5% (16/71) |
| random_legal | thorn_shield | 33.8% (24/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 23.8% (39/164) |
| attack_spam | greedy_axis | 24.4% (41/168) |
| attack_spam | random | 28.6% (48/168) |
| random_legal | combo | 18.9% (31/164) |
| random_legal | greedy_axis | 28.6% (48/168) |
| random_legal | random | 22.0% (37/168) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=3835)
- attack_spam|boss: 6.3 luot (n=1085)
- attack_spam|elite: 5.1 luot (n=561)
- random_legal|battle: 3.4 luot (n=3626)
- random_legal|boss: 6.1 luot (n=958)
- random_legal|elite: 4.9 luot (n=533)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 2
- attack_spam|battle r11: 6
- attack_spam|battle r13: 2
- attack_spam|battle r14: 3
- attack_spam|battle r15: 4
- attack_spam|battle r17: 2
- attack_spam|battle r4: 13
- attack_spam|battle r5: 2
- attack_spam|battle r7: 2
- attack_spam|battle r8: 7
- attack_spam|battle r9: 1
- attack_spam|boss r12: 65
- attack_spam|boss r18: 134
- attack_spam|boss r6: 25
- attack_spam|elite r15: 38
- attack_spam|elite r5: 38
- attack_spam|elite r9: 28
- random_legal|battle r11: 3
- random_legal|battle r13: 4
- random_legal|battle r14: 1
- random_legal|battle r15: 3
- random_legal|battle r16: 2
- random_legal|battle r4: 16
- random_legal|battle r5: 2
- random_legal|battle r7: 4
- random_legal|battle r8: 4
- random_legal|battle r9: 3
- random_legal|boss r12: 47
- random_legal|boss r18: 112
- random_legal|boss r6: 27
- random_legal|elite r15: 39
- random_legal|elite r5: 76
- random_legal|elite r9: 41

Tran ket > 20 luot hoac khong ket thuc: 11 / 10598

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 47.1% | 11.6% | 11.6% | 100% |  |
| c_dewdrop | stat | 0 | 49.2% | 16.7% | 16.7% | 100% |  |
| c_elder_trunk | stat | 0 | 48.0% | 16.7% | 16.7% | 100% |  |
| c_prime_chain | dice | 0 | 45.0% | 13.8% | 11.9% | 86% |  |
| c_finisher | dice | 0 | 44.5% | 15.7% | 15.4% | 98% |  |
| c_bastion | pos | 0 | 68.1% | 26.5% | 26.3% | 99% |  |
| c_tidecaller | mana | 0 | 46.6% | 9.9% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 40.5% | 13.0% | 11.8% | 91% |  |
| c_nest | rule | 0 | 49.4% | 16.1% | 16.1% | 100% |  |
| c_spore_burst | rule | 0 | 49.7% | 16.6% | 16.3% | 98% |  |
| c_fossil | rule | 0 | 34.7% | 8.0% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.0% | 3.0% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.6% | 7.2% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 10.6% | 7.0% | 0.8% | 11% |  |
| rule_quick_beat | run_rule | 0 | 13.4% | 7.4% | 6.0% | 81% |  |
| rule_starfall | run_rule | 0 | 14.6% | 8.0% | 8.0% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 10.6% | 5.4% | 5.4% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.4% | 5.8% | 5.8% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 12.0% | 7.2% | 7.2% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.0% | 6.0% | 6.0% | 100% |  |
| rule_upside_down | run_rule | 0 | 12.6% | 6.0% | 6.0% | 100% |  |
| rule_old_forest | run_rule | 0 | 21.0% | 9.2% | 9.2% | 100% |  |
| rule_crow | run_rule | 0 | 15.6% | 5.2% | 4.4% | 85% |  |
| rule_hard_shell | run_rule | 0 | 22.2% | 8.8% | 8.8% | 100% |  |
| rule_balance | run_rule | 0 | 23.4% | 13.8% | 13.8% | 100% |  |
| c_prism | dice | 1 | 10.2% | 4.3% | 2.8% | 65% |  |
| c_steady_hold | dice | 1 | 11.6% | 2.3% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 13.4% | 6.5% | 0.4% | 6% |  |
| c_sonic_shield | dice | 1 | 12.5% | 5.0% | 5.0% | 100% |  |
| c_fissure | dice | 1 | 8.4% | 3.6% | 3.3% | 92% | LOW |
| c_field_medic | dice | 1 | 12.1% | 3.3% | 3.3% | 100% |  |
| c_plague_spread | dice | 1 | 8.9% | 3.4% | 3.3% | 97% | LOW |
| c_gatekeeper | pos | 1 | 24.6% | 11.4% | 11.1% | 97% |  |
| c_thorn_growth | pos | 1 | 26.0% | 6.7% | 6.4% | 96% |  |
| c_thorn_shield | stat | 1 | 69.5% | 14.7% | 14.6% | 99% |  |
| c_backline_glow | pos | 1 | 28.3% | 15.9% | 14.0% | 88% |  |
| c_growing_shell | pos | 1 | 25.5% | 13.3% | 11.6% | 87% |  |
| c_mana_ward | mana | 1 | 29.5% | 8.0% | 6.2% | 78% |  |
| c_overflow | mana | 1 | 25.2% | 9.6% | 5.7% | 59% |  |
| c_thorn_pact | mana | 1 | 24.4% | 12.1% | 11.9% | 98% |  |
| c_dry_well | quest | 1 | 24.4% | 2.4% | 2.4% | 100% |  |
| c_night_watch | quest | 1 | 23.8% | 3.1% | 3.1% | 100% |  |
| c_key_strike | quest | 1 | 25.0% | 4.3% | 0.1% | 2% |  |
| c_collector | quest | 1 | 23.3% | 6.8% | 6.8% | 100% |  |
| c_chimera_hunt | quest | 1 | 24.4% | 4.8% | 3.5% | 73% |  |
| c_golden_egg | rule | 1 | 9.5% | 7.7% | 4.5% | 58% | LOW |
| c_dim_stone | rule | 1 | 14.7% | 3.1% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.3% | 4.4% | 4.8% | 100% |  |
| c_sixth_die | dice | 2 | 10.3% | 4.2% | 4.4% | 100% |  |
| c_whittle | dice | 2 | 8.8% | 2.4% | 2.5% | 100% | LOW |
| c_three_dice | dice | 2 | 10.4% | 4.0% | 4.0% | 100% |  |
| c_concord | dice | 2 | 8.4% | 2.0% | 2.1% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.3% | 1.9% | 1.9% | 100% | LOW |
| c_living_wall | pos | 2 | 32.2% | 14.4% | 14.6% | 100% |  |
| c_thorn_rebound | rule | 2 | 13.9% | 4.7% | 4.2% | 79% |  |
| c_open_ranks | pos | 2 | 6.3% | 2.6% | 2.6% | 100% | LOW |
| c_descend | pos | 2 | 16.2% | 7.6% | 7.4% | 97% |  |
| c_hollow_core | mana | 2 | 25.1% | 8.9% | 6.0% | 66% |  |
| c_deep_current | mana | 2 | 29.5% | 7.9% | 5.5% | 70% |  |
| c_blood_sign | rule | 2 | 10.6% | 3.9% | 4.1% | 100% |  |
| c_loop | rule | 2 | 12.4% | 5.8% | 5.4% | 88% |  |
| c_cascade | rule | 2 | 11.1% | 5.4% | 6.0% | 100% |  |
| c_sacrifice | rule | 2 | 16.6% | 5.2% | 5.2% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 68.2% (682/1000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_mirror_face: 52.1% (25/48)
- c_spore_burst: 50.9% (83/163)
- c_sonic_shield: 50.0% (25/50)
- c_night_watch: 48.4% (15/31)
- c_cascade: 48.3% (29/60)
- c_concord: 47.6% (10/21)
- c_sixth_die: 46.5% (20/43)
- c_golden_egg: 44.2% (34/77)
- c_plague_spread: 44.1% (15/34)
- c_nest: 39.9% (63/158)

Bottom 10:
- c_fossil: 0.0% (0/12)
- c_three_dice: 15.0% (6/40)
- c_bastion: 16.6% (43/259)
- c_tidecaller: 18.1% (17/94)
- c_descend: 21.1% (16/76)
- c_blood_sign: 22.0% (9/41)
- c_kindle: 23.1% (15/65)
- c_collector: 23.5% (16/68)
- c_field_medic: 24.2% (8/33)
- c_backline_glow: 24.8% (39/157)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_early_scales + c_spore_burst: 90.0% (9/10)
- c_spore_burst + c_thorn_growth: 75.0% (6/8)
- c_collector + c_sixth_die: 75.0% (6/8)
- c_mana_pool + c_spore_burst: 75.0% (9/12)
- c_elder_trunk + c_night_watch: 75.0% (6/8)
- c_chimera_hunt + c_living_wall: 0.0% (0/9)
- c_backline_glow + c_deep_current: 0.0% (0/8)
- c_bastion + c_loop: 0.0% (0/8)
- c_bastion + c_tidecaller: 0.0% (0/8)
- c_collector + c_hollow_core: 0.0% (0/9)
