# Sim balance bot2_s_expert_no_bo_hunt_84

Runs: 21, wall 33.1s (1.57s/run).

## Muc tieu (Short A0)



## Phieu chet theo node (song sot tich luy)

- **expert_no_bo_hunt** (n=21): r4 battle -1 (con 95%); r8 battle -1 (con 90%); r9 elite -3 (con 76%); r12 boss -7 (con 43%); r15 elite -2 (con 33%); r18 boss -2 (con 24%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert_no_bo_hunt | 0 | 23.8% (5/21) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert_no_bo_hunt | aqua_plant | 0.0% (0/3) |
| expert_no_bo_hunt | beast_bird | 33.3% (1/3) |
| expert_no_bo_hunt | mixed_dmg | 33.3% (1/3) |
| expert_no_bo_hunt | mixed_std | 33.3% (1/3) |
| expert_no_bo_hunt | reptile_bug | 0.0% (0/3) |
| expert_no_bo_hunt | tank_heavy | 66.7% (2/3) |
| expert_no_bo_hunt | thorn_shield | 0.0% (0/3) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert_no_bo_hunt | combo | 14.3% (1/7) |
| expert_no_bo_hunt | greedy_axis | 42.9% (3/7) |
| expert_no_bo_hunt | random | 14.3% (1/7) |


## So luot trung binh moi tran (chinh sach|loai)

- expert_no_bo_hunt|battle: 3.0 luot (n=155)
- expert_no_bo_hunt|boss: 5.2 luot (n=43)
- expert_no_bo_hunt|elite: 3.7 luot (n=19)

## Chet theo node (chinh sach|loai row)

- expert_no_bo_hunt|battle r4: 1
- expert_no_bo_hunt|battle r8: 1
- expert_no_bo_hunt|boss r12: 7
- expert_no_bo_hunt|boss r18: 2
- expert_no_bo_hunt|elite r15: 2
- expert_no_bo_hunt|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 217

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 38.1% | 14.3% | 14.3% | 100% |  |
| c_dewdrop | stat | 0 | 57.1% | 19.0% | 19.0% | 100% |  |
| c_elder_trunk | stat | 0 | 52.4% | 23.8% | 23.8% | 100% |  |
| c_prime_chain | dice | 0 | 42.9% | 19.0% | 14.3% | 75% |  |
| c_finisher | dice | 0 | 57.1% | 14.3% | 14.3% | 100% |  |
| c_bastion | pos | 0 | 57.1% | 19.0% | 19.0% | 100% |  |
| c_tidecaller | mana | 0 | 42.9% | 9.5% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 38.1% | 19.0% | 14.3% | 75% |  |
| c_nest | rule | 0 | 42.9% | 9.5% | 9.5% | 100% |  |
| c_spore_burst | rule | 0 | 57.1% | 14.3% | 14.3% | 100% |  |
| c_fossil | rule | 0 | 33.3% | 4.8% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 0.0% | 0.0% | 0.0% | - | LOW |
| rule_cheap_mana | run_rule | 0 | 14.3% | 4.8% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 0.0% | 0.0% | 0.0% | - | LOW |
| rule_quick_beat | run_rule | 0 | 23.8% | 4.8% | 4.8% | 100% |  |
| rule_starfall | run_rule | 0 | 23.8% | 19.0% | 19.0% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 9.5% | 4.8% | 4.8% | 100% | LOW |
| rule_wasteland | run_rule | 0 | 19.0% | 9.5% | 9.5% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 23.8% | 19.0% | 19.0% | 100% |  |
| rule_rising_tide | run_rule | 0 | 4.8% | 4.8% | 4.8% | 100% | LOW |
| rule_upside_down | run_rule | 0 | 19.0% | 9.5% | 9.5% | 100% |  |
| rule_old_forest | run_rule | 0 | 14.3% | 4.8% | 4.8% | 100% |  |
| rule_crow | run_rule | 0 | 14.3% | 9.5% | 9.5% | 100% |  |
| rule_hard_shell | run_rule | 0 | 23.8% | 9.5% | 9.5% | 100% |  |
| rule_balance | run_rule | 0 | 9.5% | 0.0% | 0.0% | - | LOW |
| c_prism | dice | 1 | 9.5% | 9.5% | 4.8% | 50% | LOW |
| c_steady_hold | dice | 1 | 19.0% | 0.0% | 0.0% | - |  |
| c_kindle | dice | 1 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_sonic_shield | dice | 1 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_fissure | dice | 1 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_field_medic | dice | 1 | 19.0% | 9.5% | 9.5% | 100% |  |
| c_plague_spread | dice | 1 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_gatekeeper | pos | 1 | 14.3% | 4.8% | 4.8% | 100% |  |
| c_thorn_growth | pos | 1 | 19.0% | 0.0% | 0.0% | - |  |
| c_thorn_shield | stat | 1 | 76.2% | 19.0% | 19.0% | 100% |  |
| c_backline_glow | pos | 1 | 23.8% | 19.0% | 19.0% | 100% |  |
| c_growing_shell | pos | 1 | 14.3% | 9.5% | 9.5% | 100% |  |
| c_mana_ward | mana | 1 | 28.6% | 4.8% | 0.0% | 0% | DEAD |
| c_overflow | mana | 1 | 28.6% | 14.3% | 4.8% | 33% |  |
| c_thorn_pact | mana | 1 | 42.9% | 33.3% | 33.3% | 100% |  |
| c_dry_well | quest | 1 | 23.8% | 0.0% | 0.0% | - |  |
| c_night_watch | quest | 1 | 33.3% | 4.8% | 4.8% | 100% |  |
| c_key_strike | quest | 1 | 14.3% | 0.0% | 0.0% | - |  |
| c_collector | quest | 1 | 14.3% | 0.0% | 0.0% | - |  |
| c_chimera_hunt | quest | 1 | 19.0% | 0.0% | 0.0% | - |  |
| c_golden_egg | rule | 1 | 9.5% | 4.8% | 4.8% | 100% | LOW |
| c_dim_stone | rule | 1 | 9.5% | 0.0% | 0.0% | - | LOW |
| c_mirror_face | dice | 2 | 14.3% | 4.8% | 4.8% | 100% |  |
| c_sixth_die | dice | 2 | 14.3% | 4.8% | 4.8% | 100% |  |
| c_whittle | dice | 2 | 33.3% | 4.8% | 4.8% | 100% |  |
| c_three_dice | dice | 2 | 14.3% | 9.5% | 9.5% | 100% |  |
| c_concord | dice | 2 | 9.5% | 4.8% | 4.8% | 100% | LOW |
| c_toxic_still | dice | 2 | 9.5% | 0.0% | 0.0% | - | LOW |
| c_living_wall | pos | 2 | 28.6% | 19.0% | 19.0% | 100% |  |
| c_thorn_rebound | rule | 2 | 19.0% | 9.5% | 9.5% | 100% |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_descend | pos | 2 | 38.1% | 19.0% | 19.0% | 100% |  |
| c_hollow_core | mana | 2 | 19.0% | 4.8% | 4.8% | 100% |  |
| c_deep_current | mana | 2 | 38.1% | 9.5% | 9.5% | 100% |  |
| c_blood_sign | rule | 2 | 14.3% | 0.0% | 0.0% | - |  |
| c_loop | rule | 2 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_cascade | rule | 2 | 9.5% | 9.5% | 9.5% | 100% | LOW |
| c_sacrifice | rule | 2 | 19.0% | 0.0% | 0.0% | - |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 71.4% (15/21)

Win-rate khi co Loi (n >= 8). Top 10:

Bottom 10:

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
