# Sim balance main_expert_2

Runs: 500, wall 616.8s (1.23s/run).

## Muc tieu (Short A0)

- expert 15-25%: 30.8% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -11 (con 98%); r5 elite -23 (con 93%); r5 battle -1 (con 93%); r6 boss -24 (con 88%); r8 battle -5 (con 87%); r9 elite -32 (con 81%); r9 battle -1 (con 81%); r11 battle -3 (con 80%); r12 boss -63 (con 67%); r13 battle -1 (con 67%); r15 elite -28 (con 62%); r16 battle -2 (con 61%); r17 battle -2 (con 61%); r18 boss -150 (con 31%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 30.8% (154/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 12.5% (9/72) |
| expert | beast_bird | 31.9% (23/72) |
| expert | mixed_dmg | 33.8% (24/71) |
| expert | mixed_std | 35.2% (25/71) |
| expert | reptile_bug | 40.3% (29/72) |
| expert | tank_heavy | 38.0% (27/71) |
| expert | thorn_shield | 23.9% (17/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 30.8% (154/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.0 luot (n=4023)
- expert|boss: 6.1 luot (n=1169)
- expert|elite: 4.4 luot (n=596)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 3
- expert|battle r13: 1
- expert|battle r16: 2
- expert|battle r17: 2
- expert|battle r4: 11
- expert|battle r5: 1
- expert|battle r8: 5
- expert|battle r9: 1
- expert|boss r12: 63
- expert|boss r18: 150
- expert|boss r6: 24
- expert|elite r15: 28
- expert|elite r5: 23
- expert|elite r9: 32

Tran ket > 20 luot hoac khong ket thuc: 8 / 5788

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 71.8% | 0.4% | 0.4% | 100% |  |
| c_dewdrop | stat | 0 | 66.0% | 19.6% | 19.6% | 100% |  |
| c_elder_trunk | stat | 0 | 68.8% | 23.2% | 23.2% | 100% |  |
| c_prime_chain | dice | 0 | 51.0% | 20.6% | 20.6% | 100% |  |
| c_finisher | dice | 0 | 54.4% | 22.4% | 22.4% | 100% |  |
| c_bastion | pos | 0 | 68.4% | 28.0% | 28.0% | 100% |  |
| c_tidecaller | mana | 0 | 53.6% | 0.4% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 44.2% | 14.4% | 14.4% | 100% |  |
| c_collector | quest | 0 | 30.6% | 4.2% | 4.2% | 100% |  |
| c_nest | rule | 0 | 41.8% | 16.4% | 16.4% | 100% |  |
| c_spore_burst | rule | 0 | 38.8% | 13.6% | 13.6% | 100% |  |
| c_fossil | rule | 0 | 39.6% | 0.6% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.4% | 1.0% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 13.8% | 9.0% | 9.0% | 100% |  |
| rule_tundra | run_rule | 0 | 15.0% | 8.8% | 8.8% | 100% |  |
| rule_quick_beat | run_rule | 0 | 17.2% | 8.8% | 8.8% | 100% |  |
| rule_starfall | run_rule | 0 | 13.6% | 8.6% | 8.6% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 13.0% | 6.6% | 6.6% | 100% |  |
| rule_wasteland | run_rule | 0 | 15.2% | 9.0% | 9.0% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 17.6% | 9.2% | 9.2% | 100% |  |
| rule_rising_tide | run_rule | 0 | 14.4% | 10.2% | 10.2% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.8% | 9.0% | 9.0% | 100% |  |
| rule_old_forest | run_rule | 0 | 14.2% | 9.0% | 9.0% | 100% |  |
| rule_crow | run_rule | 0 | 14.6% | 0.6% | 0.0% | 0% | DEAD |
| rule_hard_shell | run_rule | 0 | 13.0% | 1.2% | 0.0% | 0% | DEAD |
| rule_balance | run_rule | 0 | 13.2% | 9.0% | 9.0% | 100% |  |
| c_prism | dice | 1 | 13.8% | 7.6% | 7.6% | 100% |  |
| c_steady_hold | dice | 1 | 14.8% | 1.2% | 1.2% | 100% |  |
| c_kindle | dice | 1 | 15.0% | 8.6% | 8.6% | 100% |  |
| c_sonic_shield | dice | 1 | 17.8% | 11.2% | 11.2% | 100% |  |
| c_fissure | dice | 1 | 9.6% | 5.4% | 5.4% | 100% | LOW |
| c_field_medic | dice | 1 | 16.0% | 0.6% | 0.6% | 100% |  |
| c_plague_spread | dice | 1 | 9.4% | 4.8% | 4.8% | 100% | LOW |
| c_gatekeeper | pos | 1 | 39.2% | 28.8% | 28.8% | 100% |  |
| c_backline_glow | pos | 1 | 37.0% | 31.0% | 31.0% | 100% |  |
| c_growing_shell | pos | 1 | 35.4% | 27.2% | 27.2% | 100% |  |
| c_mana_ward | mana | 1 | 30.2% | 2.0% | 2.0% | 100% |  |
| c_overflow | mana | 1 | 32.2% | 18.4% | 18.4% | 100% |  |
| c_thorn_pact | mana | 1 | 19.2% | 11.6% | 11.6% | 100% |  |
| c_dry_well | quest | 1 | 32.6% | 0.2% | 0.2% | 100% |  |
| c_night_watch | quest | 1 | 30.6% | 0.2% | 0.2% | 100% |  |
| c_key_strike | quest | 1 | 32.4% | 0.6% | 0.6% | 100% |  |
| c_chimera_hunt | quest | 1 | 33.4% | 10.4% | 9.8% | 94% |  |
| c_golden_egg | rule | 1 | 8.0% | 7.8% | 7.8% | 100% | LOW |
| c_dim_stone | rule | 1 | 57.2% | 2.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.2% | 6.4% | 6.4% | 100% |  |
| c_sixth_die | dice | 2 | 14.8% | 8.6% | 8.6% | 100% |  |
| c_whittle | dice | 2 | 16.6% | 2.0% | 2.0% | 100% |  |
| c_three_dice | dice | 2 | 11.0% | 7.6% | 7.6% | 100% |  |
| c_concord | dice | 2 | 8.2% | 0.6% | 0.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 9.0% | 0.4% | 0.4% | 100% | LOW |
| c_living_wall | pos | 2 | 32.4% | 24.0% | 24.0% | 100% |  |
| c_open_ranks | pos | 2 | 12.4% | 1.6% | 1.6% | 100% |  |
| c_descend | pos | 2 | 21.0% | 12.8% | 12.8% | 100% |  |
| c_hollow_core | mana | 2 | 24.0% | 11.4% | 11.4% | 100% |  |
| c_deep_current | mana | 2 | 35.6% | 1.4% | 1.4% | 100% |  |
| c_blood_sign | rule | 2 | 12.2% | 7.0% | 7.0% | 100% |  |
| c_loop | rule | 2 | 16.6% | 9.0% | 9.0% | 100% |  |
| c_cascade | rule | 2 | 19.2% | 10.0% | 10.0% | 100% |  |
| c_sacrifice | rule | 2 | 18.6% | 1.2% | 1.2% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 82.4% (412/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 76.6% (49/64)
- c_cascade: 52.0% (26/50)
- c_golden_egg: 51.3% (20/39)
- c_loop: 48.9% (22/45)
- c_blood_sign: 47.1% (16/34)
- c_living_wall: 46.7% (56/120)
- c_dim_stone: 46.2% (6/13)
- c_sonic_shield: 44.6% (25/56)
- c_sixth_die: 44.2% (19/43)
- c_descend: 43.8% (28/64)

Bottom 10:
- c_mana_ward: 0.0% (0/10)
- c_mirror_face: 15.6% (5/32)
- c_three_dice: 18.4% (7/38)
- c_kindle: 20.9% (9/43)
- c_open_ranks: 25.0% (2/8)
- c_mana_pool: 26.5% (18/68)
- c_prime_chain: 27.4% (26/95)
- c_bastion: 28.0% (37/132)
- c_overflow: 29.7% (27/91)
- c_elder_trunk: 29.7% (33/111)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_dewdrop + c_spore_burst: 100.0% (12/12)
- c_blood_sign + c_spore_burst: 90.9% (10/11)
- c_overflow + c_spore_burst: 90.0% (9/10)
- c_golden_egg + c_spore_burst: 88.2% (15/17)
- c_mana_pool + c_spore_burst: 87.5% (7/8)
- c_mana_ward + c_overflow: 0.0% (0/9)
- c_blood_sign + c_prime_chain: 0.0% (0/8)
- c_backline_glow + c_kindle: 0.0% (0/8)
- c_mirror_face + c_prime_chain: 7.1% (1/14)
- c_growing_shell + c_three_dice: 10.0% (1/10)
