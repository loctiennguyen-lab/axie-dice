# Sim balance td_base_cheap

Runs: 1000, wall 74.9s (0.07s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 20.8% -> CHUA DAT
- attack_spam <= 5%: 24.0% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=500): r4 battle -17 (con 97%); r5 elite -79 (con 81%); r5 battle -2 (con 80%); r6 boss -28 (con 75%); r7 battle -5 (con 74%); r8 battle -7 (con 72%); r9 elite -35 (con 65%); r9 battle -1 (con 65%); r10 battle -2 (con 65%); r11 battle -4 (con 64%); r12 boss -46 (con 55%); r13 battle -3 (con 54%); r15 elite -59 (con 42%); r15 battle -1 (con 42%); r16 battle -1 (con 42%); r18 boss -106 (con 21%)
- **attack_spam** (n=500): r4 battle -13 (con 97%); r5 battle -3 (con 97%); r5 elite -42 (con 88%); r6 boss -31 (con 82%); r7 battle -3 (con 82%); r8 battle -8 (con 80%); r9 elite -28 (con 74%); r9 battle -1 (con 74%); r10 battle -1 (con 74%); r11 battle -4 (con 73%); r12 boss -67 (con 60%); r13 battle -2 (con 59%); r14 battle -2 (con 59%); r15 elite -52 (con 49%); r15 battle -5 (con 48%); r17 battle -2 (con 47%); r18 boss -116 (con 24%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 24.0% (120/500) |
| random_legal | 0 | 20.8% (104/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 13.9% (10/72) |
| attack_spam | beast_bird | 26.4% (19/72) |
| attack_spam | mixed_dmg | 25.4% (18/71) |
| attack_spam | mixed_std | 19.7% (14/71) |
| attack_spam | reptile_bug | 29.2% (21/72) |
| attack_spam | tank_heavy | 26.8% (19/71) |
| attack_spam | thorn_shield | 26.8% (19/71) |
| random_legal | aqua_plant | 13.9% (10/72) |
| random_legal | beast_bird | 18.1% (13/72) |
| random_legal | mixed_dmg | 15.5% (11/71) |
| random_legal | mixed_std | 8.5% (6/71) |
| random_legal | reptile_bug | 38.9% (28/72) |
| random_legal | tank_heavy | 23.9% (17/71) |
| random_legal | thorn_shield | 26.8% (19/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 23.2% (38/164) |
| attack_spam | greedy_axis | 24.4% (41/168) |
| attack_spam | random | 24.4% (41/168) |
| random_legal | combo | 22.6% (37/164) |
| random_legal | greedy_axis | 20.8% (35/168) |
| random_legal | random | 19.0% (32/168) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=3781)
- attack_spam|boss: 6.4 luot (n=1044)
- attack_spam|elite: 5.1 luot (n=543)
- random_legal|battle: 3.4 luot (n=3560)
- random_legal|boss: 6.1 luot (n=932)
- random_legal|elite: 4.9 luot (n=561)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 1
- attack_spam|battle r11: 4
- attack_spam|battle r13: 2
- attack_spam|battle r14: 2
- attack_spam|battle r15: 5
- attack_spam|battle r17: 2
- attack_spam|battle r4: 13
- attack_spam|battle r5: 3
- attack_spam|battle r7: 3
- attack_spam|battle r8: 8
- attack_spam|battle r9: 1
- attack_spam|boss r12: 67
- attack_spam|boss r18: 116
- attack_spam|boss r6: 31
- attack_spam|elite r15: 52
- attack_spam|elite r5: 42
- attack_spam|elite r9: 28
- random_legal|battle r10: 2
- random_legal|battle r11: 4
- random_legal|battle r13: 3
- random_legal|battle r15: 1
- random_legal|battle r16: 1
- random_legal|battle r4: 17
- random_legal|battle r5: 2
- random_legal|battle r7: 5
- random_legal|battle r8: 7
- random_legal|battle r9: 1
- random_legal|boss r12: 46
- random_legal|boss r18: 106
- random_legal|boss r6: 28
- random_legal|elite r15: 59
- random_legal|elite r5: 79
- random_legal|elite r9: 35

Tran ket > 20 luot hoac khong ket thuc: 13 / 10421

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 45.7% | 11.3% | 11.3% | 100% |  |
| c_dewdrop | stat | 0 | 47.7% | 16.7% | 16.7% | 100% |  |
| c_elder_trunk | stat | 0 | 48.0% | 16.6% | 16.6% | 100% |  |
| c_prime_chain | dice | 0 | 44.6% | 13.0% | 11.4% | 88% |  |
| c_finisher | dice | 0 | 45.8% | 16.7% | 16.1% | 96% |  |
| c_bastion | pos | 0 | 66.9% | 25.9% | 25.7% | 99% |  |
| c_tidecaller | mana | 0 | 46.5% | 9.7% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 40.9% | 13.3% | 12.3% | 92% |  |
| c_nest | rule | 0 | 50.2% | 16.9% | 16.9% | 100% |  |
| c_spore_burst | rule | 0 | 48.5% | 15.4% | 15.1% | 98% |  |
| c_fossil | rule | 0 | 34.9% | 8.0% | 0.0% | 0% | DEAD |
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
| c_prism | dice | 1 | 9.7% | 4.0% | 2.7% | 68% | LOW |
| c_steady_hold | dice | 1 | 11.6% | 2.4% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 14.0% | 6.9% | 0.7% | 10% |  |
| c_sonic_shield | dice | 1 | 11.9% | 4.6% | 4.6% | 100% |  |
| c_fissure | dice | 1 | 8.6% | 3.4% | 3.0% | 88% | LOW |
| c_field_medic | dice | 1 | 12.6% | 3.6% | 3.6% | 100% |  |
| c_plague_spread | dice | 1 | 9.1% | 3.3% | 3.3% | 100% | LOW |
| c_gatekeeper | pos | 1 | 24.3% | 11.0% | 10.5% | 95% |  |
| c_thorn_growth | pos | 1 | 24.9% | 6.8% | 6.5% | 96% |  |
| c_thorn_shield | stat | 1 | 68.2% | 15.6% | 15.5% | 99% |  |
| c_backline_glow | pos | 1 | 28.7% | 15.5% | 13.9% | 90% |  |
| c_growing_shell | pos | 1 | 25.2% | 14.1% | 11.5% | 82% |  |
| c_mana_ward | mana | 1 | 29.6% | 8.2% | 6.2% | 76% |  |
| c_overflow | mana | 1 | 26.2% | 10.2% | 6.7% | 66% |  |
| c_thorn_pact | mana | 1 | 24.4% | 11.5% | 11.3% | 98% |  |
| c_dry_well | quest | 1 | 25.7% | 2.8% | 2.8% | 100% |  |
| c_night_watch | quest | 1 | 22.2% | 2.4% | 2.4% | 100% |  |
| c_key_strike | quest | 1 | 24.2% | 3.7% | 0.1% | 3% |  |
| c_collector | quest | 1 | 22.3% | 6.7% | 6.7% | 100% |  |
| c_chimera_hunt | quest | 1 | 25.7% | 5.6% | 3.4% | 61% |  |
| c_golden_egg | rule | 1 | 9.1% | 7.6% | 4.4% | 58% | LOW |
| c_dim_stone | rule | 1 | 14.8% | 3.1% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.6% | 4.7% | 5.0% | 100% |  |
| c_sixth_die | dice | 2 | 10.4% | 4.0% | 4.1% | 100% |  |
| c_whittle | dice | 2 | 9.4% | 2.4% | 2.4% | 100% | LOW |
| c_three_dice | dice | 2 | 9.6% | 3.6% | 3.6% | 100% | LOW |
| c_concord | dice | 2 | 8.3% | 2.0% | 2.2% | 100% | LOW |
| c_toxic_still | dice | 2 | 6.6% | 1.5% | 1.5% | 100% | LOW |
| c_living_wall | pos | 2 | 31.2% | 13.9% | 14.3% | 100% |  |
| c_thorn_rebound | rule | 2 | 14.2% | 5.2% | 4.1% | 73% |  |
| c_open_ranks | pos | 2 | 5.2% | 2.0% | 2.0% | 100% | LOW |
| c_descend | pos | 2 | 15.1% | 7.0% | 6.8% | 97% |  |
| c_hollow_core | mana | 2 | 22.9% | 8.1% | 6.0% | 73% |  |
| c_deep_current | mana | 2 | 28.4% | 8.0% | 5.8% | 72% |  |
| c_blood_sign | rule | 2 | 8.8% | 3.1% | 3.4% | 100% | LOW |
| c_loop | rule | 2 | 12.4% | 5.9% | 5.4% | 86% |  |
| c_cascade | rule | 2 | 11.8% | 5.5% | 6.0% | 100% |  |
| c_sacrifice | rule | 2 | 16.6% | 4.4% | 4.7% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 66.6% (666/1000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_toxic_still: 53.3% (8/15)
- c_spore_burst: 49.7% (75/151)
- c_mirror_face: 44.0% (22/50)
- c_sixth_die: 42.5% (17/40)
- c_golden_egg: 42.1% (32/76)
- c_cascade: 41.7% (25/60)
- c_sonic_shield: 41.3% (19/46)
- c_thorn_growth: 37.3% (25/67)
- c_nest: 36.6% (60/164)
- c_loop: 35.5% (22/62)

Bottom 10:
- c_fossil: 0.0% (0/13)
- c_bastion: 15.0% (38/253)
- c_prism: 17.5% (7/40)
- c_tidecaller: 18.3% (17/93)
- c_three_dice: 19.4% (7/36)
- c_night_watch: 20.8% (5/24)
- c_field_medic: 22.2% (8/36)
- c_mana_ward: 23.2% (19/82)
- c_blood_sign: 23.5% (8/34)
- c_prime_chain: 24.4% (31/127)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_elder_trunk + c_spore_burst: 83.3% (10/12)
- c_dewdrop + c_spore_burst: 73.3% (11/15)
- c_mana_pool + c_spore_burst: 71.4% (10/14)
- c_cascade + c_sacrifice: 70.0% (7/10)
- c_backline_glow + c_spore_burst: 66.7% (12/18)
- c_bastion + c_mana_ward: 0.0% (0/10)
- c_finisher + c_overflow: 0.0% (0/8)
- c_cascade + c_thorn_shield: 0.0% (0/8)
- c_prime_chain + c_prism: 0.0% (0/13)
- c_early_scales + c_mana_ward: 0.0% (0/8)
