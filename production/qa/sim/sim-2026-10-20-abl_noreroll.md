# Sim balance abl_noreroll

Runs: 300, wall 254.3s (0.85s/run).

## Muc tieu (Short A0)

- expert 15-25%: 24.7% -> DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=300): r4 battle -9 (con 97%); r5 elite -21 (con 90%); r6 boss -29 (con 80%); r8 battle -5 (con 79%); r9 elite -17 (con 73%); r9 battle -1 (con 73%); r12 boss -45 (con 58%); r13 battle -1 (con 57%); r14 battle -1 (con 57%); r15 elite -19 (con 51%); r16 battle -1 (con 50%); r18 boss -77 (con 25%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 24.7% (74/300) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.3% (7/43) |
| expert | beast_bird | 14.0% (6/43) |
| expert | mixed_dmg | 34.9% (15/43) |
| expert | mixed_std | 25.6% (11/43) |
| expert | reptile_bug | 32.6% (14/43) |
| expert | tank_heavy | 20.9% (9/43) |
| expert | thorn_shield | 28.6% (12/42) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 24.7% (74/300) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.3 luot (n=2302)
- expert|boss: 6.7 luot (n=639)
- expert|elite: 4.6 luot (n=308)

## Chet theo node (chinh sach|loai row)

- expert|battle r13: 1
- expert|battle r14: 1
- expert|battle r16: 1
- expert|battle r4: 9
- expert|battle r8: 5
- expert|battle r9: 1
- expert|boss r12: 45
- expert|boss r18: 77
- expert|boss r6: 29
- expert|elite r15: 19
- expert|elite r5: 21
- expert|elite r9: 17

Tran ket > 20 luot hoac khong ket thuc: 2 / 3249

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 63.0% | 0.0% | 0.0% | - |  |
| c_dewdrop | stat | 0 | 71.7% | 22.7% | 22.7% | 100% |  |
| c_elder_trunk | stat | 0 | 61.0% | 19.7% | 19.7% | 100% |  |
| c_prime_chain | dice | 0 | 51.0% | 23.3% | 23.3% | 100% |  |
| c_finisher | dice | 0 | 52.0% | 21.7% | 21.7% | 100% |  |
| c_bastion | pos | 0 | 66.3% | 27.7% | 27.7% | 100% |  |
| c_tidecaller | mana | 0 | 46.7% | 0.0% | 0.0% | - |  |
| c_mana_pool | mana | 0 | 44.0% | 11.7% | 11.7% | 100% |  |
| c_collector | quest | 0 | 20.7% | 3.0% | 3.0% | 100% |  |
| c_nest | rule | 0 | 37.7% | 11.3% | 11.3% | 100% |  |
| c_spore_burst | rule | 0 | 34.3% | 12.7% | 12.7% | 100% |  |
| c_fossil | rule | 0 | 38.3% | 0.3% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 7.3% | 0.7% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 14.0% | 8.7% | 8.7% | 100% |  |
| rule_tundra | run_rule | 0 | 12.7% | 7.3% | 7.3% | 100% |  |
| rule_quick_beat | run_rule | 0 | 16.7% | 9.3% | 9.3% | 100% |  |
| rule_starfall | run_rule | 0 | 15.3% | 9.0% | 9.0% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 11.7% | 7.3% | 7.3% | 100% |  |
| rule_wasteland | run_rule | 0 | 18.0% | 10.7% | 10.7% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 13.3% | 9.0% | 9.0% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.3% | 9.0% | 9.0% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.3% | 8.3% | 8.3% | 100% |  |
| rule_old_forest | run_rule | 0 | 15.0% | 7.7% | 7.7% | 100% |  |
| rule_crow | run_rule | 0 | 17.0% | 1.3% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 14.7% | 1.3% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 17.7% | 10.3% | 10.3% | 100% |  |
| c_prism | dice | 1 | 13.7% | 8.0% | 8.0% | 100% |  |
| c_steady_hold | dice | 1 | 14.3% | 1.0% | 1.0% | 100% |  |
| c_kindle | dice | 1 | 13.3% | 9.0% | 9.0% | 100% |  |
| c_sonic_shield | dice | 1 | 14.0% | 8.7% | 8.7% | 100% |  |
| c_fissure | dice | 1 | 7.0% | 3.7% | 3.7% | 100% | LOW |
| c_field_medic | dice | 1 | 12.3% | 1.3% | 1.3% | 100% |  |
| c_plague_spread | dice | 1 | 11.0% | 8.0% | 8.0% | 100% |  |
| c_gatekeeper | pos | 1 | 34.0% | 22.3% | 22.3% | 100% |  |
| c_backline_glow | pos | 1 | 33.7% | 27.7% | 27.7% | 100% |  |
| c_growing_shell | pos | 1 | 33.7% | 24.7% | 24.7% | 100% |  |
| c_mana_ward | mana | 1 | 30.7% | 2.0% | 2.0% | 100% |  |
| c_overflow | mana | 1 | 22.3% | 12.7% | 12.7% | 100% |  |
| c_thorn_pact | mana | 1 | 23.7% | 14.0% | 14.0% | 100% |  |
| c_dry_well | quest | 1 | 27.7% | 0.3% | 0.3% | 100% |  |
| c_night_watch | quest | 1 | 28.7% | 0.0% | 0.0% | - |  |
| c_key_strike | quest | 1 | 27.0% | 0.3% | 0.3% | 100% |  |
| c_chimera_hunt | quest | 1 | 25.0% | 7.0% | 7.0% | 100% |  |
| c_golden_egg | rule | 1 | 5.7% | 5.3% | 5.3% | 100% | LOW |
| c_dim_stone | rule | 1 | 55.0% | 2.0% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.3% | 5.7% | 5.7% | 100% |  |
| c_sixth_die | dice | 2 | 11.3% | 7.0% | 7.0% | 100% |  |
| c_whittle | dice | 2 | 14.3% | 1.0% | 1.0% | 100% |  |
| c_three_dice | dice | 2 | 9.0% | 4.7% | 4.7% | 100% | LOW |
| c_concord | dice | 2 | 9.7% | 1.3% | 1.3% | 100% | LOW |
| c_toxic_still | dice | 2 | 10.0% | 1.0% | 1.0% | 100% |  |
| c_living_wall | pos | 2 | 29.0% | 24.0% | 24.0% | 100% |  |
| c_open_ranks | pos | 2 | 10.0% | 1.7% | 1.7% | 100% |  |
| c_descend | pos | 2 | 16.3% | 11.7% | 11.7% | 100% |  |
| c_hollow_core | mana | 2 | 20.7% | 9.0% | 9.0% | 100% |  |
| c_deep_current | mana | 2 | 29.0% | 1.7% | 1.7% | 100% |  |
| c_blood_sign | rule | 2 | 10.7% | 7.3% | 7.3% | 100% |  |
| c_loop | rule | 2 | 16.0% | 8.0% | 8.0% | 100% |  |
| c_cascade | rule | 2 | 12.3% | 7.3% | 7.3% | 100% |  |
| c_sacrifice | rule | 2 | 20.7% | 0.3% | 0.3% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 78.7% (236/300)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 52.8% (19/36)
- c_cascade: 50.0% (11/22)
- c_descend: 48.6% (17/35)
- c_nest: 42.4% (14/33)
- c_sonic_shield: 42.3% (11/26)
- c_living_wall: 40.3% (29/72)
- c_gatekeeper: 38.8% (26/67)
- c_chimera_hunt: 38.1% (8/21)
- c_thorn_pact: 35.7% (15/42)
- c_backline_glow: 31.3% (26/83)

Bottom 10:
- c_finisher: 19.0% (12/63)
- c_prism: 20.8% (5/24)
- c_three_dice: 21.4% (3/14)
- c_collector: 22.2% (2/9)
- c_blood_sign: 22.7% (5/22)
- c_dewdrop: 23.9% (16/67)
- c_elder_trunk: 24.1% (14/58)
- c_prime_chain: 25.0% (17/68)
- c_mana_pool: 25.7% (9/35)
- c_kindle: 25.9% (7/27)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_descend + c_living_wall: 72.7% (8/11)
- c_cascade + c_nest: 70.0% (7/10)
- c_bastion + c_elder_trunk: 70.0% (7/10)
- c_nest + c_spore_burst: 69.2% (9/13)
- c_backline_glow + c_descend: 66.7% (8/12)
- c_dewdrop + c_finisher: 0.0% (0/9)
- c_dewdrop + c_overflow: 9.1% (1/11)
- c_finisher + c_three_dice: 11.1% (1/9)
- c_elder_trunk + c_prime_chain: 11.1% (1/9)
- c_finisher + c_gatekeeper: 15.4% (2/13)
