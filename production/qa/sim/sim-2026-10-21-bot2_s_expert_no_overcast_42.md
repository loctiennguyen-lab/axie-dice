# Sim balance bot2_s_expert_no_overcast_42

Runs: 21, wall 41.6s (1.98s/run).

## Muc tieu (Short A0)



## Phieu chet theo node (song sot tich luy)

- **expert_no_overcast** (n=21): r4 battle -1 (con 95%); r5 elite -1 (con 90%); r9 elite -1 (con 86%); r12 boss -4 (con 67%); r15 elite -1 (con 62%); r18 boss -6 (con 33%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert_no_overcast | 0 | 33.3% (7/21) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert_no_overcast | aqua_plant | 33.3% (1/3) |
| expert_no_overcast | beast_bird | 33.3% (1/3) |
| expert_no_overcast | mixed_dmg | 33.3% (1/3) |
| expert_no_overcast | mixed_std | 33.3% (1/3) |
| expert_no_overcast | reptile_bug | 33.3% (1/3) |
| expert_no_overcast | tank_heavy | 33.3% (1/3) |
| expert_no_overcast | thorn_shield | 33.3% (1/3) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert_no_overcast | combo | 42.9% (3/7) |
| expert_no_overcast | greedy_axis | 0.0% (0/7) |
| expert_no_overcast | random | 57.1% (4/7) |


## So luot trung binh moi tran (chinh sach|loai)

- expert_no_overcast|battle: 2.8 luot (n=176)
- expert_no_overcast|boss: 4.7 luot (n=50)
- expert_no_overcast|elite: 3.8 luot (n=25)

## Chet theo node (chinh sach|loai row)

- expert_no_overcast|battle r4: 1
- expert_no_overcast|boss r12: 4
- expert_no_overcast|boss r18: 6
- expert_no_overcast|elite r15: 1
- expert_no_overcast|elite r5: 1
- expert_no_overcast|elite r9: 1

Tran ket > 20 luot hoac khong ket thuc: 0 / 251

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 71.4% | 23.8% | 23.8% | 100% |  |
| c_dewdrop | stat | 0 | 57.1% | 23.8% | 23.8% | 100% |  |
| c_elder_trunk | stat | 0 | 47.6% | 28.6% | 28.6% | 100% |  |
| c_prime_chain | dice | 0 | 57.1% | 23.8% | 23.8% | 100% |  |
| c_finisher | dice | 0 | 52.4% | 14.3% | 14.3% | 100% |  |
| c_bastion | pos | 0 | 76.2% | 23.8% | 19.0% | 80% |  |
| c_tidecaller | mana | 0 | 57.1% | 9.5% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 47.6% | 9.5% | 4.8% | 50% |  |
| c_nest | rule | 0 | 57.1% | 9.5% | 9.5% | 100% |  |
| c_spore_burst | rule | 0 | 47.6% | 19.0% | 19.0% | 100% |  |
| c_fossil | rule | 0 | 42.9% | 4.8% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 14.3% | 0.0% | 0.0% | - |  |
| rule_cheap_mana | run_rule | 0 | 4.8% | 4.8% | 0.0% | 0% | LOW DEAD |
| rule_tundra | run_rule | 0 | 14.3% | 4.8% | 0.0% | 0% | DEAD |
| rule_quick_beat | run_rule | 0 | 14.3% | 14.3% | 9.5% | 67% |  |
| rule_starfall | run_rule | 0 | 14.3% | 9.5% | 9.5% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 0.0% | 0.0% | 0.0% | - | LOW |
| rule_wasteland | run_rule | 0 | 9.5% | 4.8% | 4.8% | 100% | LOW |
| rule_dry_steppe | run_rule | 0 | 19.0% | 9.5% | 9.5% | 100% |  |
| rule_rising_tide | run_rule | 0 | 19.0% | 14.3% | 14.3% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.3% | 4.8% | 4.8% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.8% | 19.0% | 19.0% | 100% |  |
| rule_crow | run_rule | 0 | 4.8% | 0.0% | 0.0% | - | LOW |
| rule_hard_shell | run_rule | 0 | 23.8% | 4.8% | 4.8% | 100% |  |
| rule_balance | run_rule | 0 | 23.8% | 9.5% | 9.5% | 100% |  |
| c_prism | dice | 1 | 14.3% | 9.5% | 4.8% | 50% |  |
| c_steady_hold | dice | 1 | 9.5% | 4.8% | 0.0% | 0% | LOW DEAD |
| c_kindle | dice | 1 | 14.3% | 9.5% | 0.0% | 0% | DEAD |
| c_sonic_shield | dice | 1 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_fissure | dice | 1 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_field_medic | dice | 1 | 14.3% | 4.8% | 4.8% | 100% |  |
| c_plague_spread | dice | 1 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_gatekeeper | pos | 1 | 19.0% | 4.8% | 4.8% | 100% |  |
| c_thorn_growth | pos | 1 | 4.8% | 4.8% | 4.8% | 100% | LOW |
| c_thorn_shield | stat | 1 | 85.7% | 42.9% | 42.9% | 100% |  |
| c_backline_glow | pos | 1 | 23.8% | 9.5% | 9.5% | 100% |  |
| c_growing_shell | pos | 1 | 33.3% | 23.8% | 23.8% | 100% |  |
| c_mana_ward | mana | 1 | 33.3% | 0.0% | 0.0% | - |  |
| c_overflow | mana | 1 | 19.0% | 4.8% | 0.0% | 0% | DEAD |
| c_thorn_pact | mana | 1 | 9.5% | 9.5% | 9.5% | 100% | LOW |
| c_dry_well | quest | 1 | 28.6% | 0.0% | 0.0% | - |  |
| c_night_watch | quest | 1 | 38.1% | 9.5% | 9.5% | 100% |  |
| c_key_strike | quest | 1 | 19.0% | 4.8% | 4.8% | 100% |  |
| c_collector | quest | 1 | 23.8% | 0.0% | 0.0% | - |  |
| c_chimera_hunt | quest | 1 | 42.9% | 9.5% | 9.5% | 100% |  |
| c_golden_egg | rule | 1 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_dim_stone | rule | 1 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_mirror_face | dice | 2 | 9.5% | 4.8% | 4.8% | 100% | LOW |
| c_sixth_die | dice | 2 | 19.0% | 14.3% | 14.3% | 100% |  |
| c_whittle | dice | 2 | 14.3% | 4.8% | 4.8% | 100% |  |
| c_three_dice | dice | 2 | 14.3% | 9.5% | 9.5% | 100% |  |
| c_concord | dice | 2 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_toxic_still | dice | 2 | 4.8% | 4.8% | 4.8% | 100% | LOW |
| c_living_wall | pos | 2 | 42.9% | 23.8% | 23.8% | 100% |  |
| c_thorn_rebound | rule | 2 | 4.8% | 0.0% | 0.0% | - | LOW |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_descend | pos | 2 | 14.3% | 0.0% | 0.0% | - |  |
| c_hollow_core | mana | 2 | 38.1% | 0.0% | 0.0% | - |  |
| c_deep_current | mana | 2 | 23.8% | 0.0% | 0.0% | - |  |
| c_blood_sign | rule | 2 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_loop | rule | 2 | 19.0% | 4.8% | 4.8% | 100% |  |
| c_cascade | rule | 2 | 0.0% | 0.0% | 0.0% | - | LOW |
| c_sacrifice | rule | 2 | 23.8% | 9.5% | 9.5% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 61.9% (13/21)

Win-rate khi co Loi (n >= 8). Top 10:
- c_thorn_shield: 33.3% (3/9)

Bottom 10:
- c_thorn_shield: 33.3% (3/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
