# Sim balance main_expert_3

Runs: 500, wall 602.1s (1.20s/run).

## Muc tieu (Short A0)

- expert 15-25%: 25.2% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -3 (con 99%); r5 elite -33 (con 93%); r5 battle -1 (con 93%); r6 boss -39 (con 85%); r7 battle -2 (con 84%); r8 battle -5 (con 83%); r9 elite -16 (con 80%); r9 battle -1 (con 80%); r10 battle -3 (con 79%); r11 battle -2 (con 79%); r12 boss -70 (con 65%); r14 battle -1 (con 65%); r15 elite -40 (con 57%); r15 battle -1 (con 57%); r18 boss -157 (con 25%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 25.2% (126/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 9.7% (7/72) |
| expert | beast_bird | 25.0% (18/72) |
| expert | mixed_dmg | 31.0% (22/71) |
| expert | mixed_std | 28.2% (20/71) |
| expert | reptile_bug | 34.7% (25/72) |
| expert | tank_heavy | 28.2% (20/71) |
| expert | thorn_shield | 19.7% (14/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 25.2% (126/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=3963)
- expert|boss: 6.4 luot (n=1141)
- expert|elite: 4.4 luot (n=571)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 3
- expert|battle r11: 2
- expert|battle r14: 1
- expert|battle r15: 1
- expert|battle r4: 3
- expert|battle r5: 1
- expert|battle r7: 2
- expert|battle r8: 5
- expert|battle r9: 1
- expert|boss r12: 70
- expert|boss r18: 157
- expert|boss r6: 39
- expert|elite r15: 40
- expert|elite r5: 33
- expert|elite r9: 16

Tran ket > 20 luot hoac khong ket thuc: 15 / 5675

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 67.4% | 0.2% | 0.2% | 100% |  |
| c_dewdrop | stat | 0 | 65.6% | 21.4% | 21.4% | 100% |  |
| c_elder_trunk | stat | 0 | 66.2% | 17.2% | 17.2% | 100% |  |
| c_prime_chain | dice | 0 | 52.0% | 22.4% | 22.4% | 100% |  |
| c_finisher | dice | 0 | 55.2% | 24.0% | 24.0% | 100% |  |
| c_bastion | pos | 0 | 67.4% | 28.8% | 28.8% | 100% |  |
| c_tidecaller | mana | 0 | 53.0% | 0.4% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.2% | 12.6% | 12.6% | 100% |  |
| c_collector | quest | 0 | 28.8% | 5.2% | 5.2% | 100% |  |
| c_nest | rule | 0 | 37.8% | 11.6% | 11.6% | 100% |  |
| c_spore_burst | rule | 0 | 33.2% | 8.8% | 8.8% | 100% |  |
| c_fossil | rule | 0 | 40.4% | 0.2% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.0% | 0.6% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 14.4% | 10.6% | 10.6% | 100% |  |
| rule_tundra | run_rule | 0 | 13.6% | 8.2% | 8.2% | 100% |  |
| rule_quick_beat | run_rule | 0 | 13.6% | 9.4% | 9.4% | 100% |  |
| rule_starfall | run_rule | 0 | 14.6% | 7.6% | 7.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 14.2% | 9.0% | 9.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 14.0% | 9.8% | 9.8% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 14.8% | 9.4% | 9.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 14.6% | 9.0% | 9.0% | 100% |  |
| rule_upside_down | run_rule | 0 | 16.6% | 9.4% | 9.4% | 100% |  |
| rule_old_forest | run_rule | 0 | 14.4% | 7.8% | 7.8% | 100% |  |
| rule_crow | run_rule | 0 | 14.8% | 1.0% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 16.8% | 0.4% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 14.6% | 7.8% | 7.8% | 100% |  |
| c_prism | dice | 1 | 14.6% | 8.4% | 8.4% | 100% |  |
| c_steady_hold | dice | 1 | 13.8% | 1.0% | 1.0% | 100% |  |
| c_kindle | dice | 1 | 14.6% | 8.8% | 8.8% | 100% |  |
| c_sonic_shield | dice | 1 | 14.0% | 7.6% | 7.6% | 100% |  |
| c_fissure | dice | 1 | 10.0% | 6.0% | 6.0% | 100% |  |
| c_field_medic | dice | 1 | 14.0% | 1.6% | 1.6% | 100% |  |
| c_plague_spread | dice | 1 | 9.0% | 4.6% | 4.6% | 100% | LOW |
| c_gatekeeper | pos | 1 | 43.8% | 31.8% | 31.8% | 100% |  |
| c_backline_glow | pos | 1 | 41.0% | 32.6% | 32.6% | 100% |  |
| c_growing_shell | pos | 1 | 40.8% | 32.8% | 32.8% | 100% |  |
| c_mana_ward | mana | 1 | 33.2% | 0.8% | 0.8% | 100% |  |
| c_overflow | mana | 1 | 27.0% | 12.8% | 12.8% | 100% |  |
| c_thorn_pact | mana | 1 | 18.6% | 11.6% | 11.6% | 100% |  |
| c_dry_well | quest | 1 | 30.4% | 0.8% | 0.8% | 100% |  |
| c_night_watch | quest | 1 | 27.8% | 0.2% | 0.2% | 100% |  |
| c_key_strike | quest | 1 | 29.4% | 0.8% | 0.8% | 100% |  |
| c_chimera_hunt | quest | 1 | 30.6% | 7.8% | 7.8% | 100% |  |
| c_golden_egg | rule | 1 | 6.4% | 6.2% | 6.2% | 100% | LOW |
| c_dim_stone | rule | 1 | 51.8% | 2.0% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 13.2% | 5.8% | 5.8% | 100% |  |
| c_sixth_die | dice | 2 | 13.0% | 6.8% | 6.8% | 100% |  |
| c_whittle | dice | 2 | 12.6% | 1.6% | 1.6% | 100% |  |
| c_three_dice | dice | 2 | 13.2% | 7.4% | 7.4% | 100% |  |
| c_concord | dice | 2 | 8.2% | 0.6% | 0.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 9.6% | 0.4% | 0.4% | 100% | LOW |
| c_living_wall | pos | 2 | 35.6% | 28.4% | 28.4% | 100% |  |
| c_open_ranks | pos | 2 | 10.8% | 1.0% | 1.0% | 100% |  |
| c_descend | pos | 2 | 20.8% | 13.2% | 13.2% | 100% |  |
| c_hollow_core | mana | 2 | 24.4% | 11.6% | 11.6% | 100% |  |
| c_deep_current | mana | 2 | 31.0% | 1.8% | 1.8% | 100% |  |
| c_blood_sign | rule | 2 | 12.0% | 6.6% | 6.6% | 100% |  |
| c_loop | rule | 2 | 12.4% | 7.6% | 7.6% | 100% |  |
| c_cascade | rule | 2 | 15.0% | 7.2% | 7.2% | 100% |  |
| c_sacrifice | rule | 2 | 17.6% | 0.4% | 0.4% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 83.8% (419/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 65.0% (26/40)
- c_dim_stone: 60.0% (6/10)
- c_whittle: 50.0% (4/8)
- c_loop: 48.6% (18/37)
- c_cascade: 44.4% (16/36)
- c_plague_spread: 43.5% (10/23)
- c_descend: 42.4% (28/66)
- c_golden_egg: 41.9% (13/31)
- c_sonic_shield: 37.8% (14/37)
- c_field_medic: 37.5% (3/8)

Bottom 10:
- c_prism: 14.3% (6/42)
- c_mana_pool: 19.4% (12/62)
- c_elder_trunk: 20.5% (17/83)
- c_three_dice: 21.6% (8/37)
- c_deep_current: 22.2% (2/9)
- c_hollow_core: 22.8% (13/57)
- c_finisher: 23.3% (27/116)
- c_overflow: 23.4% (15/64)
- c_bastion: 24.1% (33/137)
- c_mirror_face: 24.1% (7/29)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_cascade + c_spore_burst: 88.9% (8/9)
- c_golden_egg + c_spore_burst: 76.9% (10/13)
- c_blood_sign + c_spore_burst: 75.0% (6/8)
- c_loop + c_spore_burst: 66.7% (8/12)
- c_nest + c_spore_burst: 66.7% (14/21)
- c_chimera_hunt + c_overflow: 8.3% (1/12)
- c_hollow_core + c_living_wall: 8.3% (1/12)
- c_chimera_hunt + c_prime_chain: 10.0% (1/10)
- c_bastion + c_cascade: 11.1% (1/9)
- c_prime_chain + c_sixth_die: 11.8% (2/17)
