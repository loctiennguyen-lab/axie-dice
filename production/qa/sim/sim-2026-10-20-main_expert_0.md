# Sim balance main_expert_0

Runs: 500, wall 631.0s (1.26s/run).

## Muc tieu (Short A0)

- expert 15-25%: 28.0% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -3 (con 99%); r5 elite -32 (con 93%); r5 battle -2 (con 93%); r6 boss -33 (con 86%); r8 battle -2 (con 86%); r9 elite -35 (con 79%); r9 battle -2 (con 78%); r10 battle -1 (con 78%); r11 battle -2 (con 78%); r12 boss -71 (con 63%); r13 battle -1 (con 63%); r14 battle -2 (con 63%); r15 battle -1 (con 63%); r15 elite -33 (con 56%); r16 battle -1 (con 56%); r17 battle -1 (con 56%); r18 boss -138 (con 28%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 28.0% (140/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 11.1% (8/72) |
| expert | beast_bird | 25.0% (18/72) |
| expert | mixed_dmg | 21.1% (15/71) |
| expert | mixed_std | 23.9% (17/71) |
| expert | reptile_bug | 30.6% (22/72) |
| expert | tank_heavy | 39.4% (28/71) |
| expert | thorn_shield | 45.1% (32/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 28.0% (140/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=3858)
- expert|boss: 6.3 luot (n=1129)
- expert|elite: 4.3 luot (n=611)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r13: 1
- expert|battle r14: 2
- expert|battle r15: 1
- expert|battle r16: 1
- expert|battle r17: 1
- expert|battle r4: 3
- expert|battle r5: 2
- expert|battle r8: 2
- expert|battle r9: 2
- expert|boss r12: 71
- expert|boss r18: 138
- expert|boss r6: 33
- expert|elite r15: 33
- expert|elite r5: 32
- expert|elite r9: 35

Tran ket > 20 luot hoac khong ket thuc: 8 / 5598

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 71.0% | 0.2% | 0.2% | 100% |  |
| c_dewdrop | stat | 0 | 69.8% | 21.8% | 21.8% | 100% |  |
| c_elder_trunk | stat | 0 | 68.0% | 19.4% | 19.4% | 100% |  |
| c_prime_chain | dice | 0 | 51.2% | 20.2% | 20.2% | 100% |  |
| c_finisher | dice | 0 | 52.4% | 23.8% | 23.8% | 100% |  |
| c_bastion | pos | 0 | 66.2% | 30.2% | 30.2% | 100% |  |
| c_tidecaller | mana | 0 | 53.4% | 0.4% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 48.4% | 15.6% | 15.6% | 100% |  |
| c_collector | quest | 0 | 30.0% | 4.8% | 4.8% | 100% |  |
| c_nest | rule | 0 | 40.8% | 13.8% | 13.8% | 100% |  |
| c_spore_burst | rule | 0 | 38.0% | 10.6% | 10.6% | 100% |  |
| c_fossil | rule | 0 | 40.8% | 0.2% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 11.6% | 1.2% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 11.4% | 6.6% | 6.6% | 100% |  |
| rule_tundra | run_rule | 0 | 14.2% | 9.0% | 9.0% | 100% |  |
| rule_quick_beat | run_rule | 0 | 14.6% | 8.8% | 8.8% | 100% |  |
| rule_starfall | run_rule | 0 | 14.8% | 8.6% | 8.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 15.2% | 8.8% | 8.8% | 100% |  |
| rule_wasteland | run_rule | 0 | 13.4% | 8.6% | 8.6% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 13.6% | 7.6% | 7.6% | 100% |  |
| rule_rising_tide | run_rule | 0 | 15.0% | 9.6% | 9.6% | 100% |  |
| rule_upside_down | run_rule | 0 | 17.6% | 12.4% | 12.4% | 100% |  |
| rule_old_forest | run_rule | 0 | 14.6% | 9.0% | 9.0% | 100% |  |
| rule_crow | run_rule | 0 | 13.2% | 1.4% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 13.6% | 0.8% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 17.2% | 7.6% | 7.6% | 100% |  |
| c_prism | dice | 1 | 15.8% | 9.0% | 9.0% | 100% |  |
| c_steady_hold | dice | 1 | 13.4% | 1.6% | 1.6% | 100% |  |
| c_kindle | dice | 1 | 13.0% | 7.6% | 7.6% | 100% |  |
| c_sonic_shield | dice | 1 | 15.0% | 8.2% | 8.2% | 100% |  |
| c_fissure | dice | 1 | 9.6% | 4.8% | 4.8% | 100% | LOW |
| c_field_medic | dice | 1 | 14.4% | 2.2% | 2.2% | 100% |  |
| c_plague_spread | dice | 1 | 8.8% | 4.6% | 4.6% | 100% | LOW |
| c_gatekeeper | pos | 1 | 35.2% | 24.4% | 24.4% | 100% |  |
| c_backline_glow | pos | 1 | 41.8% | 34.6% | 34.6% | 100% |  |
| c_growing_shell | pos | 1 | 35.0% | 26.2% | 26.2% | 100% |  |
| c_mana_ward | mana | 1 | 31.6% | 2.8% | 2.8% | 100% |  |
| c_overflow | mana | 1 | 25.0% | 14.2% | 14.2% | 100% |  |
| c_thorn_pact | mana | 1 | 23.6% | 15.4% | 15.4% | 100% |  |
| c_dry_well | quest | 1 | 26.6% | 0.0% | 0.0% | - |  |
| c_night_watch | quest | 1 | 24.6% | 0.0% | 0.0% | - |  |
| c_key_strike | quest | 1 | 30.2% | 0.2% | 0.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 29.0% | 9.0% | 8.8% | 98% |  |
| c_golden_egg | rule | 1 | 5.8% | 5.8% | 5.8% | 100% | LOW |
| c_dim_stone | rule | 1 | 53.4% | 1.4% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 10.6% | 8.0% | 8.0% | 100% |  |
| c_sixth_die | dice | 2 | 14.2% | 7.4% | 7.4% | 100% |  |
| c_whittle | dice | 2 | 13.2% | 1.2% | 1.2% | 100% |  |
| c_three_dice | dice | 2 | 12.6% | 6.4% | 6.4% | 100% |  |
| c_concord | dice | 2 | 8.4% | 0.8% | 0.8% | 100% | LOW |
| c_toxic_still | dice | 2 | 9.0% | 0.6% | 0.6% | 100% | LOW |
| c_living_wall | pos | 2 | 32.6% | 25.8% | 25.8% | 100% |  |
| c_open_ranks | pos | 2 | 9.8% | 2.2% | 2.2% | 100% | LOW |
| c_descend | pos | 2 | 18.6% | 12.6% | 12.6% | 100% |  |
| c_hollow_core | mana | 2 | 22.8% | 10.2% | 10.2% | 100% |  |
| c_deep_current | mana | 2 | 33.4% | 2.2% | 2.2% | 100% |  |
| c_blood_sign | rule | 2 | 10.8% | 6.0% | 6.0% | 100% |  |
| c_loop | rule | 2 | 14.6% | 6.8% | 6.8% | 100% |  |
| c_cascade | rule | 2 | 15.2% | 7.8% | 7.8% | 100% |  |
| c_sacrifice | rule | 2 | 15.8% | 0.2% | 0.2% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 84.0% (420/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 63.5% (33/52)
- c_golden_egg: 58.6% (17/29)
- c_cascade: 51.3% (20/39)
- c_collector: 50.0% (12/24)
- c_sixth_die: 48.6% (18/37)
- c_blood_sign: 46.7% (14/30)
- c_fissure: 41.7% (10/24)
- c_descend: 39.7% (25/63)
- c_nest: 39.1% (25/64)
- c_sonic_shield: 39.0% (16/41)

Bottom 10:
- c_open_ranks: 0.0% (0/11)
- c_three_dice: 12.5% (4/32)
- c_steady_hold: 25.0% (2/8)
- c_bastion: 25.4% (36/142)
- c_mana_pool: 25.6% (20/78)
- c_overflow: 26.8% (19/71)
- c_deep_current: 27.3% (3/11)
- c_dewdrop: 27.8% (30/108)
- c_finisher: 29.1% (34/117)
- c_hollow_core: 29.4% (15/51)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_spore_burst + c_thorn_pact: 90.0% (9/10)
- c_golden_egg + c_spore_burst: 80.0% (12/15)
- c_cascade + c_spore_burst: 76.9% (10/13)
- c_blood_sign + c_spore_burst: 75.0% (6/8)
- c_collector + c_sixth_die: 75.0% (6/8)
- c_gatekeeper + c_open_ranks: 0.0% (0/8)
- c_growing_shell + c_open_ranks: 0.0% (0/8)
- c_prime_chain + c_three_dice: 5.6% (1/18)
- c_finisher + c_three_dice: 7.1% (1/14)
- c_dewdrop + c_prism: 11.1% (1/9)
