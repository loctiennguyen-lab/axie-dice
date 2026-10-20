# Sim balance td_fin_b

Runs: 2000, wall 53.7s (0.03s/run).

## Muc tieu (Short A0)

- attack_only <= 5%: 3.4% -> DAT


## Phieu chet theo node (song sot tich luy)

- **attack_only** (n=2000): r1 battle -6 (con 100%); r2 battle -1 (con 100%); r3 battle -28 (con 98%); r4 battle -199 (con 88%); r5 elite -551 (con 61%); r5 battle -67 (con 57%); r6 boss -748 (con 20%); r7 battle -3 (con 20%); r8 battle -12 (con 19%); r9 elite -63 (con 16%); r9 battle -6 (con 16%); r10 battle -1 (con 16%); r11 battle -13 (con 15%); r12 boss -103 (con 10%); r13 battle -2 (con 10%); r14 battle -8 (con 9%); r15 elite -34 (con 8%); r15 battle -2 (con 8%); r17 battle -3 (con 8%); r18 boss -82 (con 3%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_only | 0 | 3.4% (68/2000) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_only | aqua_plant | 0.7% (2/286) |
| attack_only | beast_bird | 14.3% (41/286) |
| attack_only | mixed_dmg | 3.1% (9/286) |
| attack_only | mixed_std | 1.7% (5/286) |
| attack_only | reptile_bug | 0.7% (2/286) |
| attack_only | tank_heavy | 3.2% (9/285) |
| attack_only | thorn_shield | 0.0% (0/285) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_only | combo | 4.7% (31/665) |
| attack_only | greedy_axis | 3.6% (24/665) |
| attack_only | random | 1.9% (13/670) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_only|battle: 4.3 luot (n=8504)
- attack_only|boss: 6.6 luot (n=1600)
- attack_only|elite: 5.0 luot (n=1132)

## Chet theo node (chinh sach|loai row)

- attack_only|battle r1: 6
- attack_only|battle r10: 1
- attack_only|battle r11: 13
- attack_only|battle r13: 2
- attack_only|battle r14: 8
- attack_only|battle r15: 2
- attack_only|battle r17: 3
- attack_only|battle r2: 1
- attack_only|battle r3: 28
- attack_only|battle r4: 199
- attack_only|battle r5: 67
- attack_only|battle r7: 3
- attack_only|battle r8: 12
- attack_only|battle r9: 6
- attack_only|boss r12: 103
- attack_only|boss r18: 82
- attack_only|boss r6: 748
- attack_only|elite r15: 34
- attack_only|elite r5: 551
- attack_only|elite r9: 63

Tran ket > 20 luot hoac khong ket thuc: 13 / 11236

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 29.1% | 6.0% | 6.0% | 100% |  |
| c_dewdrop | stat | 0 | 28.4% | 9.6% | 9.6% | 100% |  |
| c_elder_trunk | stat | 0 | 27.9% | 9.8% | 9.8% | 100% |  |
| c_prime_chain | dice | 0 | 36.0% | 11.8% | 9.6% | 81% |  |
| c_finisher | dice | 0 | 37.6% | 13.7% | 8.8% | 65% |  |
| c_bastion | pos | 0 | 60.9% | 23.2% | 23.2% | 100% |  |
| c_tidecaller | mana | 0 | 38.6% | 7.5% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 36.8% | 10.8% | 8.7% | 81% |  |
| c_nest | rule | 0 | 35.5% | 14.4% | 14.4% | 100% |  |
| c_spore_burst | rule | 0 | 32.1% | 12.2% | 12.1% | 99% |  |
| c_fossil | rule | 0 | 30.2% | 7.2% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.6% | 3.4% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.2% | 7.0% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 12.2% | 6.9% | 0.0% | 0% | DEAD |
| rule_quick_beat | run_rule | 0 | 12.8% | 6.8% | 3.6% | 54% |  |
| rule_starfall | run_rule | 0 | 13.4% | 7.5% | 7.5% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 11.8% | 6.2% | 6.2% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.9% | 5.7% | 5.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 12.4% | 6.2% | 6.2% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.3% | 6.4% | 6.4% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.7% | 5.8% | 5.8% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.2% | 12.3% | 12.3% | 100% |  |
| rule_crow | run_rule | 0 | 13.3% | 5.0% | 3.2% | 65% |  |
| rule_hard_shell | run_rule | 0 | 21.1% | 8.2% | 8.2% | 100% |  |
| rule_balance | run_rule | 0 | 23.1% | 12.8% | 12.6% | 98% |  |
| c_prism | dice | 1 | 5.3% | 2.1% | 0.0% | 0% | LOW DEAD |
| c_steady_hold | dice | 1 | 5.2% | 1.0% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 5.5% | 2.4% | 0.0% | 0% | LOW DEAD |
| c_sonic_shield | dice | 1 | 4.6% | 1.6% | 0.0% | 0% | LOW DEAD |
| c_fissure | dice | 1 | 2.9% | 1.1% | 0.0% | 0% | LOW DEAD |
| c_field_medic | dice | 1 | 5.5% | 1.6% | 1.6% | 100% | LOW |
| c_plague_spread | dice | 1 | 2.1% | 0.9% | 0.2% | 28% | LOW |
| c_gatekeeper | pos | 1 | 10.9% | 4.8% | 4.5% | 95% |  |
| c_thorn_growth | pos | 1 | 10.2% | 2.3% | 2.3% | 100% |  |
| c_thorn_shield | stat | 1 | 34.6% | 7.3% | 2.6% | 36% |  |
| c_backline_glow | pos | 1 | 15.1% | 8.5% | 7.6% | 89% |  |
| c_growing_shell | pos | 1 | 9.8% | 5.2% | 2.6% | 50% | LOW |
| c_mana_ward | mana | 1 | 13.2% | 3.3% | 2.5% | 77% |  |
| c_overflow | mana | 1 | 11.2% | 4.3% | 2.5% | 57% |  |
| c_thorn_pact | mana | 1 | 8.4% | 3.3% | 3.0% | 91% | LOW |
| c_dry_well | quest | 1 | 10.0% | 1.1% | 1.1% | 100% |  |
| c_night_watch | quest | 1 | 9.8% | 0.8% | 0.8% | 100% | LOW |
| c_key_strike | quest | 1 | 8.8% | 1.2% | 0.1% | 8% | LOW |
| c_collector | quest | 1 | 9.1% | 2.8% | 2.8% | 100% | LOW |
| c_chimera_hunt | quest | 1 | 9.6% | 2.8% | 1.1% | 38% | LOW |
| c_golden_egg | rule | 1 | 6.0% | 5.2% | 3.2% | 62% | LOW |
| c_dim_stone | rule | 1 | 3.1% | 0.8% | 0.0% | 0% | LOW DEAD |
| c_mirror_face | dice | 2 | 3.2% | 1.2% | 1.2% | 100% | LOW |
| c_sixth_die | dice | 2 | 3.2% | 1.4% | 1.6% | 100% | LOW |
| c_whittle | dice | 2 | 3.0% | 0.9% | 0.9% | 100% | LOW |
| c_three_dice | dice | 2 | 3.4% | 1.2% | 1.2% | 100% | LOW |
| c_concord | dice | 2 | 2.5% | 0.7% | 0.8% | 100% | LOW |
| c_toxic_still | dice | 2 | 1.6% | 0.4% | 0.4% | 100% | LOW |
| c_living_wall | pos | 2 | 9.6% | 4.3% | 4.4% | 100% | LOW |
| c_thorn_rebound | rule | 2 | 5.3% | 2.0% | 1.0% | 50% | LOW |
| c_open_ranks | pos | 2 | 1.9% | 0.8% | 0.8% | 100% | LOW |
| c_descend | pos | 2 | 3.9% | 1.6% | 1.6% | 100% | LOW |
| c_hollow_core | mana | 2 | 7.0% | 2.2% | 1.6% | 71% | LOW |
| c_deep_current | mana | 2 | 9.3% | 2.6% | 1.9% | 64% | LOW |
| c_blood_sign | rule | 2 | 2.3% | 0.8% | 0.8% | 100% | LOW |
| c_loop | rule | 2 | 5.3% | 3.0% | 2.4% | 77% | LOW |
| c_cascade | rule | 2 | 4.1% | 2.1% | 2.2% | 100% | LOW |
| c_sacrifice | rule | 2 | 4.8% | 1.6% | 1.6% | 100% | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 39.9% (798/2000)

Win-rate khi co Loi (n >= 8). Top 10:
- c_mirror_face: 36.0% (9/25)
- c_cascade: 31.8% (14/44)
- c_thorn_rebound: 31.0% (13/42)
- c_loop: 29.0% (18/62)
- c_whittle: 26.3% (5/19)
- c_golden_egg: 25.0% (26/104)
- c_blood_sign: 25.0% (4/16)
- c_sixth_die: 22.6% (7/31)
- c_sacrifice: 21.9% (7/32)
- c_sonic_shield: 19.4% (6/31)

Bottom 10:
- c_toxic_still: 0.0% (0/8)
- c_field_medic: 0.0% (0/31)
- c_dry_well: 0.0% (0/21)
- c_steady_hold: 0.0% (0/20)
- c_fossil: 0.0% (0/77)
- c_bastion: 1.3% (6/463)
- c_finisher: 1.8% (5/274)
- c_thorn_growth: 2.2% (1/46)
- c_prism: 2.3% (1/43)
- c_tidecaller: 3.3% (5/150)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_loop + c_thorn_rebound: 87.5% (7/8)
- c_golden_egg + c_thorn_rebound: 73.3% (11/15)
- c_cascade + c_spore_burst: 66.7% (14/21)
- c_cascade + c_golden_egg: 58.8% (10/17)
- c_dewdrop + c_nest: 54.5% (6/11)
- c_backline_glow + c_thorn_growth: 0.0% (0/9)
- c_thorn_shield + c_tidecaller: 0.0% (0/10)
- c_bastion + c_collector: 0.0% (0/13)
- c_field_medic + c_prime_chain: 0.0% (0/12)
- c_fossil + c_spore_burst: 0.0% (0/13)
