# Sim balance abl_nohold

Runs: 300, wall 364.0s (1.21s/run).

## Muc tieu (Short A0)

- expert 15-25%: 27.3% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=300): r4 battle -6 (con 98%); r5 elite -17 (con 92%); r6 boss -21 (con 85%); r8 battle -4 (con 84%); r9 elite -14 (con 79%); r11 battle -5 (con 78%); r12 boss -40 (con 64%); r13 battle -1 (con 64%); r14 battle -1 (con 64%); r15 elite -22 (con 56%); r15 battle -1 (con 56%); r17 battle -1 (con 56%); r18 boss -85 (con 27%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 27.3% (82/300) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 14.0% (6/43) |
| expert | beast_bird | 20.9% (9/43) |
| expert | mixed_dmg | 41.9% (18/43) |
| expert | mixed_std | 32.6% (14/43) |
| expert | reptile_bug | 25.6% (11/43) |
| expert | tank_heavy | 25.6% (11/43) |
| expert | thorn_shield | 31.0% (13/42) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 27.3% (82/300) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=2389)
- expert|boss: 6.2 luot (n=677)
- expert|elite: 4.4 luot (n=327)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 5
- expert|battle r13: 1
- expert|battle r14: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r4: 6
- expert|battle r8: 4
- expert|boss r12: 40
- expert|boss r18: 85
- expert|boss r6: 21
- expert|elite r15: 22
- expert|elite r5: 17
- expert|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 7 / 3393

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 65.0% | 0.0% | 0.0% | - |  |
| c_dewdrop | stat | 0 | 65.0% | 22.3% | 22.3% | 100% |  |
| c_elder_trunk | stat | 0 | 67.7% | 19.3% | 19.3% | 100% |  |
| c_prime_chain | dice | 0 | 50.7% | 24.3% | 24.3% | 100% |  |
| c_finisher | dice | 0 | 51.7% | 23.7% | 23.7% | 100% |  |
| c_bastion | pos | 0 | 68.3% | 30.3% | 30.3% | 100% |  |
| c_tidecaller | mana | 0 | 49.3% | 0.0% | 0.0% | - |  |
| c_mana_pool | mana | 0 | 43.0% | 12.0% | 12.0% | 100% |  |
| c_collector | quest | 0 | 30.0% | 7.0% | 7.0% | 100% |  |
| c_nest | rule | 0 | 39.0% | 11.3% | 11.3% | 100% |  |
| c_spore_burst | rule | 0 | 40.0% | 12.3% | 12.3% | 100% |  |
| c_fossil | rule | 0 | 41.0% | 0.3% | 0.0% | 0% | DEAD |
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
| c_prism | dice | 1 | 14.3% | 7.7% | 7.7% | 100% |  |
| c_steady_hold | dice | 1 | 11.7% | 1.0% | 1.0% | 100% |  |
| c_kindle | dice | 1 | 15.7% | 8.7% | 8.7% | 100% |  |
| c_sonic_shield | dice | 1 | 16.7% | 9.3% | 9.3% | 100% |  |
| c_fissure | dice | 1 | 9.3% | 6.7% | 6.7% | 100% | LOW |
| c_field_medic | dice | 1 | 15.7% | 0.3% | 0.3% | 100% |  |
| c_plague_spread | dice | 1 | 9.0% | 5.0% | 5.0% | 100% | LOW |
| c_gatekeeper | pos | 1 | 37.0% | 27.7% | 27.7% | 100% |  |
| c_backline_glow | pos | 1 | 34.0% | 27.7% | 27.7% | 100% |  |
| c_growing_shell | pos | 1 | 39.7% | 29.7% | 29.7% | 100% |  |
| c_mana_ward | mana | 1 | 35.0% | 0.0% | 0.0% | - |  |
| c_overflow | mana | 1 | 28.0% | 11.7% | 11.7% | 100% |  |
| c_thorn_pact | mana | 1 | 22.7% | 15.0% | 15.0% | 100% |  |
| c_dry_well | quest | 1 | 29.7% | 0.7% | 0.7% | 100% |  |
| c_night_watch | quest | 1 | 27.3% | 0.0% | 0.0% | - |  |
| c_key_strike | quest | 1 | 28.7% | 0.0% | 0.0% | - |  |
| c_chimera_hunt | quest | 1 | 30.0% | 9.0% | 9.0% | 100% |  |
| c_golden_egg | rule | 1 | 4.7% | 4.3% | 4.3% | 100% | LOW |
| c_dim_stone | rule | 1 | 57.7% | 1.7% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.7% | 6.7% | 6.7% | 100% |  |
| c_sixth_die | dice | 2 | 14.0% | 7.0% | 7.0% | 100% |  |
| c_whittle | dice | 2 | 12.3% | 1.0% | 1.0% | 100% |  |
| c_three_dice | dice | 2 | 17.3% | 9.0% | 9.0% | 100% |  |
| c_concord | dice | 2 | 9.0% | 1.3% | 1.3% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.3% | 0.7% | 0.7% | 100% | LOW |
| c_living_wall | pos | 2 | 34.7% | 27.7% | 27.7% | 100% |  |
| c_open_ranks | pos | 2 | 13.0% | 3.3% | 3.3% | 100% |  |
| c_descend | pos | 2 | 18.0% | 12.3% | 12.3% | 100% |  |
| c_hollow_core | mana | 2 | 19.7% | 10.7% | 10.7% | 100% |  |
| c_deep_current | mana | 2 | 30.7% | 1.3% | 1.3% | 100% |  |
| c_blood_sign | rule | 2 | 9.3% | 6.7% | 6.7% | 100% | LOW |
| c_loop | rule | 2 | 15.3% | 7.0% | 7.0% | 100% |  |
| c_cascade | rule | 2 | 17.3% | 6.0% | 6.0% | 100% |  |
| c_sacrifice | rule | 2 | 20.3% | 0.3% | 0.3% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 82.3% (247/300)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 68.8% (22/32)
- c_sonic_shield: 50.0% (14/28)
- c_loop: 47.6% (10/21)
- c_cascade: 44.4% (8/18)
- c_descend: 43.2% (16/37)
- c_elder_trunk: 39.7% (23/58)
- c_golden_egg: 38.5% (5/13)
- c_chimera_hunt: 37.0% (10/27)
- c_gatekeeper: 36.1% (30/83)
- c_backline_glow: 35.4% (29/82)

Bottom 10:
- c_prism: 13.0% (3/23)
- c_collector: 14.3% (3/21)
- c_three_dice: 14.8% (4/27)
- c_blood_sign: 15.0% (3/20)
- c_prime_chain: 18.6% (13/70)
- c_mirror_face: 20.0% (4/20)
- c_mana_pool: 22.2% (8/36)
- c_bastion: 27.0% (24/89)
- c_growing_shell: 28.4% (25/88)
- c_sixth_die: 28.6% (6/21)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_gatekeeper + c_spore_burst: 80.0% (8/10)
- c_loop + c_spore_burst: 75.0% (6/8)
- c_elder_trunk + c_thorn_pact: 68.8% (11/16)
- c_backline_glow + c_finisher: 66.7% (6/9)
- c_finisher + c_sonic_shield: 63.6% (7/11)
- c_prime_chain + c_prism: 0.0% (0/10)
- c_backline_glow + c_prime_chain: 0.0% (0/9)
- c_growing_shell + c_prime_chain: 7.1% (1/14)
- c_finisher + c_three_dice: 9.1% (1/11)
- c_prime_chain + c_sixth_die: 10.0% (1/10)
