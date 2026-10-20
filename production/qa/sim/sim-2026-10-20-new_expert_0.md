# Sim balance new_expert_0

Runs: 500, wall 596.0s (1.19s/run).

## Muc tieu (Short A0)

- expert 15-25%: 27.8% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r3 battle -1 (con 100%); r4 battle -7 (con 98%); r5 elite -41 (con 90%); r5 battle -3 (con 90%); r6 boss -28 (con 84%); r7 battle -2 (con 84%); r8 battle -1 (con 83%); r9 elite -44 (con 75%); r12 boss -61 (con 62%); r14 battle -2 (con 62%); r15 elite -56 (con 51%); r15 battle -2 (con 50%); r18 boss -113 (con 28%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 27.8% (139/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 15.3% (11/72) |
| expert | beast_bird | 26.4% (19/72) |
| expert | mixed_dmg | 32.4% (23/71) |
| expert | mixed_std | 25.4% (18/71) |
| expert | reptile_bug | 31.9% (23/72) |
| expert | tank_heavy | 26.8% (19/71) |
| expert | thorn_shield | 36.6% (26/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 27.8% (139/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=3788)
- expert|boss: 6.2 luot (n=1073)
- expert|elite: 4.7 luot (n=578)

## Chet theo node (chinh sach|loai row)

- expert|battle r14: 2
- expert|battle r15: 2
- expert|battle r3: 1
- expert|battle r4: 7
- expert|battle r5: 3
- expert|battle r7: 2
- expert|battle r8: 1
- expert|boss r12: 61
- expert|boss r18: 113
- expert|boss r6: 28
- expert|elite r15: 56
- expert|elite r5: 41
- expert|elite r9: 44

Tran ket > 20 luot hoac khong ket thuc: 17 / 5439

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 47.8% | 0.2% | 0.2% | 100% |  |
| c_dewdrop | stat | 0 | 48.0% | 17.8% | 17.8% | 100% |  |
| c_elder_trunk | stat | 0 | 44.0% | 14.2% | 14.2% | 100% |  |
| c_prime_chain | dice | 0 | 50.6% | 21.2% | 20.2% | 95% |  |
| c_finisher | dice | 0 | 47.2% | 22.6% | 22.4% | 99% |  |
| c_bastion | pos | 0 | 66.2% | 26.8% | 26.2% | 98% |  |
| c_tidecaller | mana | 0 | 48.4% | 0.4% | 0.2% | 50% |  |
| c_mana_pool | mana | 0 | 45.0% | 16.4% | 14.6% | 89% |  |
| c_nest | rule | 0 | 53.4% | 18.4% | 18.4% | 100% |  |
| c_spore_burst | rule | 0 | 53.2% | 16.0% | 15.8% | 99% |  |
| c_fossil | rule | 0 | 35.4% | 0.0% | 0.0% | - |  |
| rule_none | run_rule | 0 | 9.8% | 0.6% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 13.0% | 7.4% | 6.8% | 92% |  |
| rule_tundra | run_rule | 0 | 13.8% | 9.4% | 0.8% | 9% |  |
| rule_quick_beat | run_rule | 0 | 11.8% | 7.0% | 6.2% | 89% |  |
| rule_starfall | run_rule | 0 | 12.6% | 7.2% | 7.2% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 11.6% | 7.0% | 7.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 11.0% | 6.4% | 6.4% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 14.2% | 7.2% | 7.2% | 100% |  |
| rule_rising_tide | run_rule | 0 | 9.8% | 7.0% | 7.0% | 100% | LOW |
| rule_upside_down | run_rule | 0 | 13.2% | 9.2% | 9.2% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.4% | 15.6% | 15.6% | 100% |  |
| rule_crow | run_rule | 0 | 12.8% | 0.6% | 0.6% | 100% |  |
| rule_hard_shell | run_rule | 0 | 19.6% | 0.4% | 0.4% | 100% |  |
| rule_balance | run_rule | 0 | 23.4% | 15.0% | 15.0% | 100% |  |
| c_prism | dice | 1 | 16.6% | 11.2% | 6.6% | 59% |  |
| c_steady_hold | dice | 1 | 11.4% | 0.0% | 0.0% | - |  |
| c_kindle | dice | 1 | 12.0% | 6.0% | 1.2% | 20% |  |
| c_sonic_shield | dice | 1 | 15.6% | 10.8% | 10.8% | 100% |  |
| c_fissure | dice | 1 | 10.8% | 6.8% | 6.4% | 94% |  |
| c_field_medic | dice | 1 | 13.8% | 1.6% | 1.6% | 100% |  |
| c_plague_spread | dice | 1 | 8.4% | 4.6% | 4.4% | 96% | LOW |
| c_gatekeeper | pos | 1 | 24.8% | 17.2% | 17.0% | 99% |  |
| c_thorn_growth | pos | 1 | 31.6% | 2.4% | 2.2% | 92% |  |
| c_thorn_shield | stat | 1 | 76.4% | 1.2% | 1.2% | 100% |  |
| c_backline_glow | pos | 1 | 34.8% | 26.2% | 23.6% | 90% |  |
| c_growing_shell | pos | 1 | 28.4% | 19.4% | 16.8% | 87% |  |
| c_mana_ward | mana | 1 | 31.0% | 1.4% | 1.4% | 100% |  |
| c_overflow | mana | 1 | 23.2% | 12.0% | 7.6% | 63% |  |
| c_thorn_pact | mana | 1 | 16.4% | 10.6% | 10.4% | 98% |  |
| c_dry_well | quest | 1 | 23.4% | 0.2% | 0.2% | 100% |  |
| c_night_watch | quest | 1 | 21.8% | 0.6% | 0.6% | 100% |  |
| c_key_strike | quest | 1 | 23.6% | 0.0% | 0.0% | - |  |
| c_collector | quest | 1 | 25.4% | 10.6% | 10.6% | 100% |  |
| c_chimera_hunt | quest | 1 | 28.0% | 12.0% | 8.8% | 73% |  |
| c_golden_egg | rule | 1 | 11.2% | 11.0% | 6.8% | 62% |  |
| c_dim_stone | rule | 1 | 14.0% | 0.8% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.8% | 8.4% | 8.8% | 100% |  |
| c_sixth_die | dice | 2 | 13.0% | 9.2% | 9.2% | 100% |  |
| c_whittle | dice | 2 | 11.6% | 1.2% | 1.2% | 100% |  |
| c_three_dice | dice | 2 | 13.8% | 8.4% | 8.4% | 100% |  |
| c_concord | dice | 2 | 9.4% | 1.0% | 1.0% | 100% | LOW |
| c_toxic_still | dice | 2 | 6.4% | 1.2% | 1.2% | 100% | LOW |
| c_living_wall | pos | 2 | 29.2% | 20.8% | 20.8% | 100% |  |
| c_thorn_rebound | rule | 2 | 16.4% | 0.8% | 0.8% | 75% |  |
| c_open_ranks | pos | 2 | 6.6% | 1.8% | 1.8% | 100% | LOW |
| c_descend | pos | 2 | 18.2% | 10.0% | 9.4% | 94% |  |
| c_hollow_core | mana | 2 | 22.0% | 10.0% | 8.6% | 86% |  |
| c_deep_current | mana | 2 | 30.6% | 3.0% | 2.0% | 67% |  |
| c_blood_sign | rule | 2 | 10.0% | 6.0% | 6.0% | 100% |  |
| c_loop | rule | 2 | 12.6% | 7.0% | 6.2% | 89% |  |
| c_cascade | rule | 2 | 13.6% | 8.8% | 8.8% | 100% |  |
| c_sacrifice | rule | 2 | 13.6% | 1.6% | 1.8% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 81.4% (407/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_cascade: 68.2% (30/44)
- c_spore_burst: 67.1% (53/79)
- c_golden_egg: 52.7% (29/55)
- c_nest: 51.1% (46/90)
- c_field_medic: 50.0% (4/8)
- c_loop: 48.6% (17/35)
- c_mirror_face: 47.7% (21/44)
- c_sacrifice: 44.4% (4/9)
- c_kindle: 43.3% (13/30)
- c_hollow_core: 42.0% (21/50)

Bottom 10:
- c_thorn_growth: 8.3% (1/12)
- c_open_ranks: 11.1% (1/9)
- c_bastion: 18.2% (24/132)
- c_backline_glow: 20.8% (27/130)
- c_three_dice: 21.4% (9/42)
- c_descend: 24.0% (12/50)
- c_mana_pool: 25.9% (21/81)
- c_gatekeeper: 26.7% (23/86)
- c_prism: 26.8% (15/56)
- c_prime_chain: 27.2% (28/103)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_golden_egg + c_hollow_core: 100.0% (8/8)
- c_mirror_face + c_spore_burst: 88.9% (8/9)
- c_overflow + c_spore_burst: 88.9% (8/9)
- c_cascade + c_loop: 87.5% (7/8)
- c_mirror_face + c_nest: 81.8% (9/11)
- c_sonic_shield + c_three_dice: 0.0% (0/8)
- c_backline_glow + c_chimera_hunt: 9.1% (1/11)
- c_bastion + c_nest: 11.1% (1/9)
- c_dewdrop + c_prism: 11.1% (1/9)
- c_growing_shell + c_mana_pool: 12.5% (1/8)
