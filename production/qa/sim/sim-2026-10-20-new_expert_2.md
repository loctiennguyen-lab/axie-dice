# Sim balance new_expert_2

Runs: 500, wall 635.5s (1.27s/run).

## Muc tieu (Short A0)

- expert 15-25%: 31.6% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -6 (con 99%); r5 battle -1 (con 99%); r5 elite -29 (con 93%); r6 boss -40 (con 85%); r7 battle -3 (con 84%); r8 battle -4 (con 83%); r9 elite -33 (con 77%); r11 battle -2 (con 76%); r12 boss -61 (con 64%); r13 battle -3 (con 64%); r14 battle -1 (con 63%); r15 battle -4 (con 63%); r15 elite -35 (con 56%); r16 battle -1 (con 55%); r18 boss -119 (con 32%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 31.6% (158/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 15.3% (11/72) |
| expert | beast_bird | 26.4% (19/72) |
| expert | mixed_dmg | 29.6% (21/71) |
| expert | mixed_std | 23.9% (17/71) |
| expert | reptile_bug | 48.6% (35/72) |
| expert | tank_heavy | 40.8% (29/71) |
| expert | thorn_shield | 36.6% (26/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 31.6% (158/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=3935)
- expert|boss: 6.3 luot (n=1123)
- expert|elite: 4.4 luot (n=556)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r13: 3
- expert|battle r14: 1
- expert|battle r15: 4
- expert|battle r16: 1
- expert|battle r4: 6
- expert|battle r5: 1
- expert|battle r7: 3
- expert|battle r8: 4
- expert|boss r12: 61
- expert|boss r18: 119
- expert|boss r6: 40
- expert|elite r15: 35
- expert|elite r5: 29
- expert|elite r9: 33

Tran ket > 20 luot hoac khong ket thuc: 20 / 5614

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 49.4% | 0.6% | 0.6% | 100% |  |
| c_dewdrop | stat | 0 | 50.2% | 17.8% | 17.8% | 100% |  |
| c_elder_trunk | stat | 0 | 46.8% | 15.4% | 15.4% | 100% |  |
| c_prime_chain | dice | 0 | 46.2% | 17.8% | 17.2% | 97% |  |
| c_finisher | dice | 0 | 45.2% | 18.2% | 17.8% | 98% |  |
| c_bastion | pos | 0 | 67.4% | 31.2% | 31.0% | 99% |  |
| c_tidecaller | mana | 0 | 50.0% | 0.2% | 0.2% | 100% |  |
| c_mana_pool | mana | 0 | 41.4% | 15.2% | 13.4% | 88% |  |
| c_nest | rule | 0 | 57.0% | 21.6% | 21.6% | 100% |  |
| c_spore_burst | rule | 0 | 53.4% | 16.6% | 15.8% | 95% |  |
| c_fossil | rule | 0 | 32.0% | 0.0% | 0.0% | - |  |
| rule_none | run_rule | 0 | 11.2% | 1.2% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 13.2% | 9.0% | 7.6% | 84% |  |
| rule_tundra | run_rule | 0 | 8.4% | 5.2% | 0.4% | 8% | LOW |
| rule_quick_beat | run_rule | 0 | 10.6% | 6.0% | 5.4% | 90% |  |
| rule_starfall | run_rule | 0 | 13.2% | 7.6% | 7.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 13.6% | 9.0% | 9.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 9.8% | 5.4% | 5.4% | 100% | LOW |
| rule_dry_steppe | run_rule | 0 | 10.2% | 5.6% | 5.6% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.0% | 8.4% | 8.4% | 100% |  |
| rule_upside_down | run_rule | 0 | 13.6% | 8.4% | 8.4% | 100% |  |
| rule_old_forest | run_rule | 0 | 24.0% | 16.6% | 16.6% | 100% |  |
| rule_crow | run_rule | 0 | 11.6% | 0.6% | 0.6% | 100% |  |
| rule_hard_shell | run_rule | 0 | 23.4% | 2.2% | 2.2% | 100% |  |
| rule_balance | run_rule | 0 | 25.2% | 14.8% | 14.8% | 100% |  |
| c_prism | dice | 1 | 12.0% | 8.0% | 4.2% | 52% |  |
| c_steady_hold | dice | 1 | 12.8% | 1.0% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 14.2% | 7.4% | 1.2% | 16% |  |
| c_sonic_shield | dice | 1 | 12.0% | 6.6% | 6.6% | 100% |  |
| c_fissure | dice | 1 | 7.8% | 4.6% | 4.4% | 96% | LOW |
| c_field_medic | dice | 1 | 12.4% | 0.6% | 0.6% | 100% |  |
| c_plague_spread | dice | 1 | 10.6% | 5.4% | 5.2% | 96% |  |
| c_gatekeeper | pos | 1 | 25.2% | 17.8% | 17.4% | 98% |  |
| c_thorn_growth | pos | 1 | 27.4% | 3.0% | 2.6% | 87% |  |
| c_thorn_shield | stat | 1 | 75.4% | 2.0% | 1.8% | 90% |  |
| c_backline_glow | pos | 1 | 34.0% | 25.6% | 23.0% | 90% |  |
| c_growing_shell | pos | 1 | 27.6% | 19.6% | 17.0% | 87% |  |
| c_mana_ward | mana | 1 | 29.4% | 1.8% | 1.4% | 78% |  |
| c_overflow | mana | 1 | 27.0% | 15.0% | 9.8% | 65% |  |
| c_thorn_pact | mana | 1 | 22.6% | 14.2% | 13.8% | 97% |  |
| c_dry_well | quest | 1 | 26.4% | 1.0% | 1.0% | 100% |  |
| c_night_watch | quest | 1 | 24.8% | 0.2% | 0.2% | 100% |  |
| c_key_strike | quest | 1 | 23.0% | 0.2% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 28.4% | 10.2% | 10.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 25.4% | 9.2% | 7.0% | 76% |  |
| c_golden_egg | rule | 1 | 13.2% | 13.0% | 7.6% | 58% |  |
| c_dim_stone | rule | 1 | 13.6% | 0.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.0% | 6.4% | 6.4% | 100% |  |
| c_sixth_die | dice | 2 | 12.4% | 7.2% | 7.2% | 100% |  |
| c_whittle | dice | 2 | 15.4% | 0.8% | 0.8% | 100% |  |
| c_three_dice | dice | 2 | 14.6% | 8.4% | 8.4% | 100% |  |
| c_concord | dice | 2 | 7.4% | 1.6% | 1.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 8.6% | 1.8% | 1.8% | 100% | LOW |
| c_living_wall | pos | 2 | 36.2% | 25.6% | 25.6% | 100% |  |
| c_thorn_rebound | rule | 2 | 19.0% | 1.8% | 1.0% | 56% |  |
| c_open_ranks | pos | 2 | 6.4% | 1.6% | 1.6% | 100% | LOW |
| c_descend | pos | 2 | 21.2% | 16.2% | 15.6% | 95% |  |
| c_hollow_core | mana | 2 | 22.4% | 8.0% | 5.2% | 65% |  |
| c_deep_current | mana | 2 | 30.4% | 2.0% | 1.6% | 80% |  |
| c_blood_sign | rule | 2 | 12.8% | 7.6% | 7.6% | 100% |  |
| c_loop | rule | 2 | 14.2% | 10.0% | 8.4% | 84% |  |
| c_cascade | rule | 2 | 13.4% | 7.6% | 7.8% | 100% |  |
| c_sacrifice | rule | 2 | 18.2% | 1.8% | 2.0% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 81.4% (407/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 75.3% (61/81)
- c_golden_egg: 63.1% (41/65)
- c_concord: 62.5% (5/8)
- c_cascade: 61.5% (24/39)
- c_sacrifice: 60.0% (6/10)
- c_nest: 53.8% (57/106)
- c_blood_sign: 50.0% (19/38)
- c_living_wall: 49.6% (63/127)
- c_loop: 48.0% (24/50)
- c_sonic_shield: 45.5% (15/33)

Bottom 10:
- c_thorn_pact: 19.7% (14/71)
- c_deep_current: 20.0% (2/10)
- c_mana_pool: 20.3% (15/74)
- c_toxic_still: 22.2% (2/9)
- c_three_dice: 23.8% (10/42)
- c_prism: 25.0% (10/40)
- c_mirror_face: 25.0% (8/32)
- c_plague_spread: 25.9% (7/27)
- c_bastion: 27.4% (40/146)
- c_overflow: 29.3% (22/75)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_living_wall + c_spore_burst: 94.1% (16/17)
- c_cascade + c_spore_burst: 90.5% (19/21)
- c_descend + c_spore_burst: 86.7% (13/15)
- c_golden_egg + c_spore_burst: 84.6% (33/39)
- c_blood_sign + c_golden_egg: 81.8% (9/11)
- c_mana_pool + c_prime_chain: 0.0% (0/8)
- c_finisher + c_mana_pool: 0.0% (0/8)
- c_loop + c_thorn_pact: 0.0% (0/9)
- c_kindle + c_sixth_die: 12.5% (1/8)
- c_growing_shell + c_mana_pool: 12.5% (1/8)
