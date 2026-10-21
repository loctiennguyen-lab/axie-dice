# Sim balance main_expert_1

Runs: 500, wall 613.2s (1.23s/run).

## Muc tieu (Short A0)

- expert 15-25%: 30.2% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -4 (con 99%); r5 elite -21 (con 95%); r6 boss -30 (con 89%); r7 battle -2 (con 89%); r8 battle -6 (con 87%); r9 elite -22 (con 83%); r9 battle -3 (con 82%); r11 battle -2 (con 82%); r12 boss -70 (con 68%); r14 battle -1 (con 68%); r15 battle -2 (con 67%); r15 elite -41 (con 59%); r18 boss -145 (con 30%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 30.2% (151/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 20.8% (15/72) |
| expert | beast_bird | 26.4% (19/72) |
| expert | mixed_dmg | 22.5% (16/71) |
| expert | mixed_std | 26.8% (19/71) |
| expert | reptile_bug | 45.8% (33/72) |
| expert | tank_heavy | 29.6% (21/71) |
| expert | thorn_shield | 39.4% (28/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 30.2% (151/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.0 luot (n=4003)
- expert|boss: 6.1 luot (n=1181)
- expert|elite: 4.4 luot (n=604)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r14: 1
- expert|battle r15: 2
- expert|battle r4: 4
- expert|battle r7: 2
- expert|battle r8: 6
- expert|battle r9: 3
- expert|boss r12: 70
- expert|boss r18: 145
- expert|boss r6: 30
- expert|elite r15: 41
- expert|elite r5: 21
- expert|elite r9: 22

Tran ket > 20 luot hoac khong ket thuc: 12 / 5788

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 72.4% | 0.4% | 0.4% | 100% |  |
| c_dewdrop | stat | 0 | 69.8% | 21.6% | 21.6% | 100% |  |
| c_elder_trunk | stat | 0 | 68.0% | 21.2% | 21.2% | 100% |  |
| c_prime_chain | dice | 0 | 48.4% | 22.0% | 22.0% | 100% |  |
| c_finisher | dice | 0 | 51.0% | 24.2% | 24.2% | 100% |  |
| c_bastion | pos | 0 | 68.0% | 30.2% | 30.2% | 100% |  |
| c_tidecaller | mana | 0 | 56.0% | 0.4% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.0% | 12.8% | 12.8% | 100% |  |
| c_collector | quest | 0 | 27.8% | 4.8% | 4.8% | 100% |  |
| c_nest | rule | 0 | 40.4% | 11.0% | 11.0% | 100% |  |
| c_spore_burst | rule | 0 | 37.4% | 11.8% | 11.6% | 98% |  |
| c_fossil | rule | 0 | 43.0% | 0.4% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 8.0% | 0.4% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 14.6% | 9.4% | 9.4% | 100% |  |
| rule_tundra | run_rule | 0 | 13.4% | 7.6% | 7.6% | 100% |  |
| rule_quick_beat | run_rule | 0 | 14.6% | 9.4% | 9.4% | 100% |  |
| rule_starfall | run_rule | 0 | 13.6% | 8.8% | 8.8% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 15.6% | 9.6% | 9.6% | 100% |  |
| rule_wasteland | run_rule | 0 | 15.0% | 9.6% | 9.6% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 17.4% | 10.0% | 10.0% | 100% |  |
| rule_rising_tide | run_rule | 0 | 13.4% | 8.6% | 8.6% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.0% | 8.2% | 8.2% | 100% |  |
| rule_old_forest | run_rule | 0 | 15.8% | 8.4% | 8.4% | 100% |  |
| rule_crow | run_rule | 0 | 14.8% | 1.6% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 17.6% | 0.6% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 12.2% | 7.8% | 7.8% | 100% |  |
| c_prism | dice | 1 | 14.4% | 8.8% | 8.8% | 100% |  |
| c_steady_hold | dice | 1 | 14.0% | 1.4% | 1.4% | 100% |  |
| c_kindle | dice | 1 | 15.2% | 7.6% | 7.6% | 100% |  |
| c_sonic_shield | dice | 1 | 15.0% | 8.8% | 8.8% | 100% |  |
| c_fissure | dice | 1 | 9.6% | 4.0% | 4.0% | 100% | LOW |
| c_field_medic | dice | 1 | 16.6% | 2.0% | 2.0% | 100% |  |
| c_plague_spread | dice | 1 | 10.0% | 6.8% | 6.8% | 100% |  |
| c_gatekeeper | pos | 1 | 40.8% | 28.8% | 28.8% | 100% |  |
| c_backline_glow | pos | 1 | 40.4% | 34.8% | 34.8% | 100% |  |
| c_growing_shell | pos | 1 | 38.6% | 29.6% | 29.6% | 100% |  |
| c_mana_ward | mana | 1 | 34.6% | 2.0% | 2.0% | 100% |  |
| c_overflow | mana | 1 | 29.0% | 14.4% | 14.4% | 100% |  |
| c_thorn_pact | mana | 1 | 23.0% | 14.4% | 14.4% | 100% |  |
| c_dry_well | quest | 1 | 34.2% | 0.2% | 0.2% | 100% |  |
| c_night_watch | quest | 1 | 24.4% | 0.2% | 0.2% | 100% |  |
| c_key_strike | quest | 1 | 28.8% | 0.4% | 0.4% | 100% |  |
| c_chimera_hunt | quest | 1 | 32.2% | 9.2% | 9.2% | 100% |  |
| c_golden_egg | rule | 1 | 6.2% | 6.0% | 6.0% | 100% | LOW |
| c_dim_stone | rule | 1 | 54.4% | 0.8% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 10.8% | 6.8% | 6.8% | 100% |  |
| c_sixth_die | dice | 2 | 15.6% | 7.8% | 7.8% | 100% |  |
| c_whittle | dice | 2 | 15.4% | 1.6% | 1.6% | 100% |  |
| c_three_dice | dice | 2 | 13.0% | 6.8% | 6.8% | 100% |  |
| c_concord | dice | 2 | 9.8% | 0.4% | 0.4% | 100% | LOW |
| c_toxic_still | dice | 2 | 8.8% | 1.0% | 1.0% | 100% | LOW |
| c_living_wall | pos | 2 | 30.4% | 23.4% | 23.4% | 100% |  |
| c_open_ranks | pos | 2 | 10.6% | 1.6% | 1.6% | 100% |  |
| c_descend | pos | 2 | 21.8% | 15.6% | 15.6% | 100% |  |
| c_hollow_core | mana | 2 | 25.0% | 11.4% | 11.4% | 100% |  |
| c_deep_current | mana | 2 | 34.0% | 0.8% | 0.8% | 100% |  |
| c_blood_sign | rule | 2 | 12.0% | 7.8% | 7.8% | 100% |  |
| c_loop | rule | 2 | 11.8% | 7.4% | 7.4% | 100% |  |
| c_cascade | rule | 2 | 17.4% | 7.8% | 7.8% | 100% |  |
| c_sacrifice | rule | 2 | 21.0% | 1.4% | 1.4% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 83.4% (417/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 81.0% (47/58)
- c_open_ranks: 75.0% (6/8)
- c_whittle: 62.5% (5/8)
- c_cascade: 61.5% (24/39)
- c_sixth_die: 53.8% (21/39)
- c_nest: 53.7% (29/54)
- c_plague_spread: 50.0% (17/34)
- c_golden_egg: 50.0% (15/30)
- c_fissure: 50.0% (10/20)
- c_loop: 45.9% (17/37)

Bottom 10:
- c_chimera_hunt: 19.6% (9/46)
- c_overflow: 20.8% (15/72)
- c_kindle: 21.1% (8/38)
- c_bastion: 25.7% (37/144)
- c_dewdrop: 26.2% (27/103)
- c_finisher: 26.3% (31/118)
- c_three_dice: 26.5% (9/34)
- c_thorn_pact: 27.8% (20/72)
- c_mana_pool: 27.9% (17/61)
- c_mirror_face: 29.4% (10/34)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_golden_egg + c_spore_burst: 100.0% (10/10)
- c_dewdrop + c_spore_burst: 100.0% (10/10)
- c_loop + c_spore_burst: 100.0% (11/11)
- c_nest + c_spore_burst: 100.0% (20/20)
- c_cascade + c_spore_burst: 93.8% (15/16)
- c_bastion + c_dewdrop: 0.0% (0/11)
- c_mana_pool + c_overflow: 8.0% (2/25)
- c_bastion + c_overflow: 9.1% (1/11)
- c_finisher + c_mirror_face: 9.1% (1/11)
- c_elder_trunk + c_mana_pool: 9.1% (1/11)
