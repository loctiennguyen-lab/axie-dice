# Sim balance new_expert_3

Runs: 500, wall 641.1s (1.28s/run).

## Muc tieu (Short A0)

- expert 15-25%: 32.0% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -7 (con 99%); r5 elite -34 (con 92%); r6 boss -35 (con 85%); r7 battle -1 (con 85%); r8 battle -2 (con 84%); r9 elite -31 (con 78%); r10 battle -1 (con 78%); r11 battle -2 (con 77%); r12 boss -58 (con 66%); r13 battle -3 (con 65%); r14 battle -1 (con 65%); r15 elite -40 (con 57%); r17 battle -1 (con 57%); r18 boss -124 (con 32%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 32.0% (160/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 18.1% (13/72) |
| expert | beast_bird | 34.7% (25/72) |
| expert | mixed_dmg | 35.2% (25/71) |
| expert | mixed_std | 36.6% (26/71) |
| expert | reptile_bug | 34.7% (25/72) |
| expert | tank_heavy | 38.0% (27/71) |
| expert | thorn_shield | 26.8% (19/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 32.0% (160/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.0 luot (n=3968)
- expert|boss: 6.3 luot (n=1130)
- expert|elite: 4.3 luot (n=587)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r13: 3
- expert|battle r14: 1
- expert|battle r17: 1
- expert|battle r4: 7
- expert|battle r7: 1
- expert|battle r8: 2
- expert|boss r12: 58
- expert|boss r18: 124
- expert|boss r6: 35
- expert|elite r15: 40
- expert|elite r5: 34
- expert|elite r9: 31

Tran ket > 20 luot hoac khong ket thuc: 11 / 5685

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 52.6% | 0.8% | 0.8% | 100% |  |
| c_dewdrop | stat | 0 | 51.0% | 18.2% | 18.2% | 100% |  |
| c_elder_trunk | stat | 0 | 44.2% | 12.6% | 12.6% | 100% |  |
| c_prime_chain | dice | 0 | 49.0% | 21.2% | 21.2% | 100% |  |
| c_finisher | dice | 0 | 50.2% | 22.4% | 21.8% | 97% |  |
| c_bastion | pos | 0 | 71.0% | 31.0% | 31.0% | 100% |  |
| c_tidecaller | mana | 0 | 51.2% | 0.0% | 0.0% | - |  |
| c_mana_pool | mana | 0 | 39.8% | 10.8% | 9.6% | 89% |  |
| c_nest | rule | 0 | 55.0% | 17.8% | 17.8% | 100% |  |
| c_spore_burst | rule | 0 | 52.6% | 18.4% | 17.8% | 97% |  |
| c_fossil | rule | 0 | 36.6% | 0.4% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 9.6% | 0.8% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 10.8% | 4.6% | 4.4% | 96% |  |
| rule_tundra | run_rule | 0 | 10.2% | 6.6% | 1.0% | 15% |  |
| rule_quick_beat | run_rule | 0 | 14.6% | 7.2% | 6.8% | 94% |  |
| rule_starfall | run_rule | 0 | 11.0% | 6.6% | 6.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 13.8% | 9.2% | 9.2% | 100% |  |
| rule_wasteland | run_rule | 0 | 15.2% | 8.6% | 8.6% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 13.0% | 8.4% | 8.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 11.6% | 7.4% | 7.4% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.2% | 8.0% | 8.0% | 100% |  |
| rule_old_forest | run_rule | 0 | 24.6% | 17.0% | 17.0% | 100% |  |
| rule_crow | run_rule | 0 | 11.0% | 1.0% | 0.6% | 60% |  |
| rule_hard_shell | run_rule | 0 | 18.8% | 0.2% | 0.2% | 100% |  |
| rule_balance | run_rule | 0 | 21.6% | 14.4% | 14.4% | 100% |  |
| c_prism | dice | 1 | 14.0% | 8.2% | 4.4% | 54% |  |
| c_steady_hold | dice | 1 | 13.0% | 1.4% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 12.6% | 7.2% | 0.8% | 11% |  |
| c_sonic_shield | dice | 1 | 14.8% | 8.6% | 8.4% | 98% |  |
| c_fissure | dice | 1 | 9.6% | 5.4% | 5.4% | 100% | LOW |
| c_field_medic | dice | 1 | 14.8% | 2.2% | 2.2% | 100% |  |
| c_plague_spread | dice | 1 | 10.2% | 5.6% | 5.2% | 93% |  |
| c_gatekeeper | pos | 1 | 30.0% | 21.2% | 21.2% | 100% |  |
| c_thorn_growth | pos | 1 | 27.6% | 3.4% | 3.4% | 100% |  |
| c_thorn_shield | stat | 1 | 71.0% | 1.6% | 1.6% | 100% |  |
| c_backline_glow | pos | 1 | 35.0% | 26.0% | 23.6% | 91% |  |
| c_growing_shell | pos | 1 | 29.8% | 20.0% | 18.4% | 92% |  |
| c_mana_ward | mana | 1 | 28.4% | 1.4% | 1.0% | 71% |  |
| c_overflow | mana | 1 | 25.0% | 13.8% | 8.6% | 62% |  |
| c_thorn_pact | mana | 1 | 21.8% | 14.4% | 14.2% | 99% |  |
| c_dry_well | quest | 1 | 26.0% | 0.2% | 0.2% | 100% |  |
| c_night_watch | quest | 1 | 26.8% | 0.2% | 0.2% | 100% |  |
| c_key_strike | quest | 1 | 27.8% | 0.0% | 0.0% | - |  |
| c_collector | quest | 1 | 30.2% | 10.4% | 10.4% | 100% |  |
| c_chimera_hunt | quest | 1 | 27.4% | 11.8% | 9.2% | 78% |  |
| c_golden_egg | rule | 1 | 8.8% | 8.8% | 6.0% | 68% | LOW |
| c_dim_stone | rule | 1 | 14.8% | 1.4% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.2% | 4.8% | 5.2% | 100% |  |
| c_sixth_die | dice | 2 | 13.4% | 7.6% | 7.6% | 100% |  |
| c_whittle | dice | 2 | 10.4% | 1.0% | 1.2% | 100% |  |
| c_three_dice | dice | 2 | 14.0% | 8.6% | 8.6% | 100% |  |
| c_concord | dice | 2 | 9.0% | 1.4% | 1.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 8.6% | 1.0% | 1.0% | 100% | LOW |
| c_living_wall | pos | 2 | 30.0% | 22.8% | 23.0% | 100% |  |
| c_thorn_rebound | rule | 2 | 15.2% | 1.6% | 1.4% | 75% |  |
| c_open_ranks | pos | 2 | 7.6% | 1.4% | 1.4% | 100% | LOW |
| c_descend | pos | 2 | 17.6% | 14.0% | 13.6% | 97% |  |
| c_hollow_core | mana | 2 | 23.8% | 12.0% | 10.0% | 83% |  |
| c_deep_current | mana | 2 | 29.4% | 2.6% | 2.0% | 77% |  |
| c_blood_sign | rule | 2 | 10.2% | 5.4% | 5.4% | 100% |  |
| c_loop | rule | 2 | 12.2% | 7.4% | 7.0% | 92% |  |
| c_cascade | rule | 2 | 14.4% | 8.4% | 8.4% | 100% |  |
| c_sacrifice | rule | 2 | 14.0% | 0.8% | 0.8% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 80.2% (401/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 72.2% (65/90)
- c_golden_egg: 68.2% (30/44)
- c_blood_sign: 63.0% (17/27)
- c_cascade: 59.5% (25/42)
- c_nest: 57.5% (50/87)
- c_sixth_die: 52.6% (20/38)
- c_descend: 47.1% (33/70)
- c_field_medic: 45.5% (5/11)
- c_thorn_rebound: 44.4% (4/9)
- c_sonic_shield: 44.2% (19/43)

Bottom 10:
- c_concord: 25.0% (2/8)
- c_thorn_shield: 25.0% (2/8)
- c_three_dice: 25.6% (11/43)
- c_finisher: 26.1% (29/111)
- c_dewdrop: 27.8% (25/90)
- c_prism: 29.3% (12/41)
- c_backline_glow: 30.5% (39/128)
- c_chimera_hunt: 30.5% (18/59)
- c_bastion: 31.0% (45/145)
- c_mana_pool: 31.4% (16/51)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_elder_trunk + c_spore_burst: 100.0% (10/10)
- c_spore_burst + c_thorn_pact: 100.0% (8/8)
- c_blood_sign + c_spore_burst: 90.9% (10/11)
- c_dewdrop + c_spore_burst: 88.9% (8/9)
- c_elder_trunk + c_nest: 87.5% (7/8)
- c_finisher + c_hollow_core: 0.0% (0/8)
- c_gatekeeper + c_thorn_pact: 10.0% (1/10)
- c_prism + c_three_dice: 12.5% (1/8)
- c_prime_chain + c_three_dice: 13.0% (3/23)
- c_dewdrop + c_gatekeeper: 16.7% (2/12)
