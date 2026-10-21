# Sim balance abl_base

Runs: 300, wall 353.0s (1.18s/run).

## Muc tieu (Short A0)

- expert 15-25%: 23.0% -> DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=300): r4 battle -6 (con 98%); r5 elite -17 (con 92%); r6 boss -23 (con 85%); r8 battle -4 (con 83%); r9 battle -1 (con 83%); r9 elite -14 (con 78%); r10 battle -1 (con 78%); r11 battle -4 (con 77%); r12 boss -46 (con 61%); r13 battle -1 (con 61%); r14 battle -1 (con 61%); r15 elite -20 (con 54%); r15 battle -1 (con 54%); r18 boss -92 (con 23%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 23.0% (69/300) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 20.9% (9/43) |
| expert | beast_bird | 14.0% (6/43) |
| expert | mixed_dmg | 27.9% (12/43) |
| expert | mixed_std | 27.9% (12/43) |
| expert | reptile_bug | 23.3% (10/43) |
| expert | tank_heavy | 20.9% (9/43) |
| expert | thorn_shield | 26.2% (11/42) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 23.0% (69/300) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=2350)
- expert|boss: 6.4 luot (n=668)
- expert|elite: 4.4 luot (n=326)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 4
- expert|battle r13: 1
- expert|battle r14: 1
- expert|battle r15: 1
- expert|battle r4: 6
- expert|battle r8: 4
- expert|battle r9: 1
- expert|boss r12: 46
- expert|boss r18: 92
- expert|boss r6: 23
- expert|elite r15: 20
- expert|elite r5: 17
- expert|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 7 / 3344

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 68.7% | 0.0% | 0.0% | - |  |
| c_dewdrop | stat | 0 | 68.0% | 23.3% | 23.3% | 100% |  |
| c_elder_trunk | stat | 0 | 66.3% | 19.0% | 19.0% | 100% |  |
| c_prime_chain | dice | 0 | 51.0% | 24.7% | 24.7% | 100% |  |
| c_finisher | dice | 0 | 51.3% | 22.7% | 22.7% | 100% |  |
| c_bastion | pos | 0 | 67.0% | 30.0% | 30.0% | 100% |  |
| c_tidecaller | mana | 0 | 50.7% | 0.0% | 0.0% | - |  |
| c_mana_pool | mana | 0 | 44.3% | 12.7% | 12.7% | 100% |  |
| c_collector | quest | 0 | 31.0% | 6.7% | 6.7% | 100% |  |
| c_nest | rule | 0 | 37.7% | 11.3% | 11.3% | 100% |  |
| c_spore_burst | rule | 0 | 39.3% | 12.0% | 12.0% | 100% |  |
| c_fossil | rule | 0 | 39.7% | 0.3% | 0.0% | 0% | DEAD |
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
| c_prism | dice | 1 | 14.3% | 8.3% | 8.3% | 100% |  |
| c_steady_hold | dice | 1 | 13.7% | 1.3% | 1.3% | 100% |  |
| c_kindle | dice | 1 | 14.3% | 7.3% | 7.3% | 100% |  |
| c_sonic_shield | dice | 1 | 13.7% | 8.3% | 8.3% | 100% |  |
| c_fissure | dice | 1 | 11.0% | 6.3% | 6.3% | 100% |  |
| c_field_medic | dice | 1 | 16.7% | 1.3% | 1.3% | 100% |  |
| c_plague_spread | dice | 1 | 9.3% | 6.0% | 6.0% | 100% | LOW |
| c_gatekeeper | pos | 1 | 35.3% | 26.7% | 26.7% | 100% |  |
| c_backline_glow | pos | 1 | 36.7% | 29.7% | 29.7% | 100% |  |
| c_growing_shell | pos | 1 | 37.3% | 28.7% | 28.7% | 100% |  |
| c_mana_ward | mana | 1 | 34.0% | 0.7% | 0.7% | 100% |  |
| c_overflow | mana | 1 | 26.3% | 11.0% | 11.0% | 100% |  |
| c_thorn_pact | mana | 1 | 23.7% | 15.3% | 15.3% | 100% |  |
| c_dry_well | quest | 1 | 30.7% | 0.3% | 0.3% | 100% |  |
| c_night_watch | quest | 1 | 32.0% | 0.0% | 0.0% | - |  |
| c_key_strike | quest | 1 | 28.0% | 0.0% | 0.0% | - |  |
| c_chimera_hunt | quest | 1 | 29.0% | 8.0% | 7.7% | 96% |  |
| c_golden_egg | rule | 1 | 5.0% | 4.7% | 4.7% | 100% | LOW |
| c_dim_stone | rule | 1 | 53.7% | 1.7% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 10.7% | 5.3% | 5.3% | 100% |  |
| c_sixth_die | dice | 2 | 15.0% | 8.7% | 8.7% | 100% |  |
| c_whittle | dice | 2 | 11.7% | 1.7% | 1.7% | 100% |  |
| c_three_dice | dice | 2 | 16.7% | 9.7% | 9.7% | 100% |  |
| c_concord | dice | 2 | 10.3% | 1.7% | 1.7% | 100% |  |
| c_toxic_still | dice | 2 | 6.3% | 0.0% | 0.0% | - | LOW |
| c_living_wall | pos | 2 | 35.3% | 28.3% | 28.3% | 100% |  |
| c_open_ranks | pos | 2 | 12.3% | 3.3% | 3.3% | 100% |  |
| c_descend | pos | 2 | 21.0% | 14.7% | 14.7% | 100% |  |
| c_hollow_core | mana | 2 | 20.7% | 9.3% | 9.3% | 100% |  |
| c_deep_current | mana | 2 | 31.3% | 0.7% | 0.7% | 100% |  |
| c_blood_sign | rule | 2 | 9.0% | 6.3% | 6.3% | 100% | LOW |
| c_loop | rule | 2 | 15.0% | 5.3% | 5.3% | 100% |  |
| c_cascade | rule | 2 | 19.0% | 8.0% | 8.0% | 100% |  |
| c_sacrifice | rule | 2 | 19.3% | 0.3% | 0.3% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 81.7% (245/300)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 71.9% (23/32)
- c_sixth_die: 57.7% (15/26)
- c_golden_egg: 57.1% (8/14)
- c_loop: 56.2% (9/16)
- c_sonic_shield: 48.0% (12/25)
- c_cascade: 45.8% (11/24)
- c_plague_spread: 44.4% (8/18)
- c_nest: 41.2% (14/34)
- c_overflow: 36.4% (12/33)
- c_thorn_pact: 33.3% (15/45)

Bottom 10:
- c_three_dice: 3.4% (1/29)
- c_hollow_core: 7.1% (2/28)
- c_bastion: 17.0% (15/88)
- c_prime_chain: 20.0% (14/70)
- c_growing_shell: 20.0% (17/85)
- c_chimera_hunt: 20.8% (5/24)
- c_dewdrop: 20.9% (14/67)
- c_living_wall: 21.4% (18/84)
- c_backline_glow: 21.8% (19/87)
- c_gatekeeper: 22.5% (18/80)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_gatekeeper + c_spore_burst: 80.0% (8/10)
- c_nest + c_spore_burst: 72.7% (8/11)
- c_bastion + c_overflow: 62.5% (5/8)
- c_finisher + c_plague_spread: 62.5% (5/8)
- c_growing_shell + c_spore_burst: 62.5% (5/8)
- c_dewdrop + c_gatekeeper: 0.0% (0/9)
- c_descend + c_prime_chain: 0.0% (0/8)
- c_dewdrop + c_hollow_core: 0.0% (0/12)
- c_backline_glow + c_hollow_core: 0.0% (0/9)
- c_backline_glow + c_prime_chain: 0.0% (0/8)
