# Sim balance bot2_expert_0

Runs: 126, wall 225.4s (1.79s/run).

## Muc tieu (Short A0)

- expert 15-25%: 24.6% -> DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -1 (con 99%); r5 elite -4 (con 96%); r6 boss -4 (con 93%); r8 battle -2 (con 91%); r9 elite -8 (con 85%); r11 battle -1 (con 84%); r12 boss -21 (con 67%); r15 elite -10 (con 60%); r16 battle -1 (con 59%); r17 battle -1 (con 58%); r18 boss -42 (con 25%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 24.6% (31/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (3/18) |
| expert | beast_bird | 27.8% (5/18) |
| expert | mixed_dmg | 16.7% (3/18) |
| expert | mixed_std | 22.2% (4/18) |
| expert | reptile_bug | 38.9% (7/18) |
| expert | tank_heavy | 22.2% (4/18) |
| expert | thorn_shield | 27.8% (5/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 35.7% (15/42) |
| expert | greedy_axis | 19.0% (8/42) |
| expert | random | 19.0% (8/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=1018)
- expert|boss: 4.8 luot (n=300)
- expert|elite: 3.8 luot (n=154)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 1
- expert|battle r16: 1
- expert|battle r17: 1
- expert|battle r4: 1
- expert|battle r8: 2
- expert|boss r12: 21
- expert|boss r18: 42
- expert|boss r6: 4
- expert|elite r15: 10
- expert|elite r5: 4
- expert|elite r9: 8

Tran ket > 20 luot hoac khong ket thuc: 1 / 1472

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 53.2% | 13.5% | 13.5% | 100% |  |
| c_dewdrop | stat | 0 | 57.1% | 25.4% | 25.4% | 100% |  |
| c_elder_trunk | stat | 0 | 47.6% | 16.7% | 16.7% | 100% |  |
| c_prime_chain | dice | 0 | 58.7% | 16.7% | 15.1% | 90% |  |
| c_finisher | dice | 0 | 46.8% | 15.1% | 13.5% | 89% |  |
| c_bastion | pos | 0 | 66.7% | 26.2% | 26.2% | 100% |  |
| c_tidecaller | mana | 0 | 51.6% | 9.5% | 0.0% | 0% | DEAD |
| c_mana_pool | mana | 0 | 42.1% | 13.5% | 11.9% | 88% |  |
| c_nest | rule | 0 | 54.0% | 19.0% | 19.0% | 100% |  |
| c_spore_burst | rule | 0 | 54.8% | 17.5% | 17.5% | 100% |  |
| c_fossil | rule | 0 | 31.7% | 6.3% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.3% | 1.6% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 11.9% | 6.3% | 0.0% | 0% | DEAD |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 0.8% | 20% | LOW |
| rule_quick_beat | run_rule | 0 | 14.3% | 7.9% | 7.9% | 100% |  |
| rule_starfall | run_rule | 0 | 13.5% | 7.9% | 7.9% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 10.3% | 5.6% | 5.6% | 100% |  |
| rule_wasteland | run_rule | 0 | 7.9% | 4.0% | 4.0% | 100% | LOW |
| rule_dry_steppe | run_rule | 0 | 15.1% | 9.5% | 9.5% | 100% |  |
| rule_rising_tide | run_rule | 0 | 12.7% | 6.3% | 6.3% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.3% | 5.6% | 5.6% | 100% |  |
| rule_old_forest | run_rule | 0 | 22.2% | 11.1% | 11.1% | 100% |  |
| rule_crow | run_rule | 0 | 11.9% | 6.3% | 4.8% | 75% |  |
| rule_hard_shell | run_rule | 0 | 24.6% | 11.9% | 11.9% | 100% |  |
| rule_balance | run_rule | 0 | 23.0% | 11.9% | 11.9% | 100% |  |
| c_prism | dice | 1 | 12.7% | 5.6% | 0.0% | 0% | DEAD |
| c_steady_hold | dice | 1 | 12.7% | 4.8% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 15.1% | 8.7% | 2.4% | 27% |  |
| c_sonic_shield | dice | 1 | 13.5% | 7.1% | 7.1% | 100% |  |
| c_fissure | dice | 1 | 10.3% | 5.6% | 4.8% | 86% |  |
| c_field_medic | dice | 1 | 19.8% | 4.8% | 4.8% | 100% |  |
| c_plague_spread | dice | 1 | 5.6% | 2.4% | 2.4% | 100% | LOW |
| c_gatekeeper | pos | 1 | 31.7% | 19.8% | 19.8% | 100% |  |
| c_thorn_growth | pos | 1 | 29.4% | 8.7% | 7.9% | 91% |  |
| c_thorn_shield | stat | 1 | 79.4% | 22.2% | 22.2% | 100% |  |
| c_backline_glow | pos | 1 | 37.3% | 19.8% | 16.7% | 84% |  |
| c_growing_shell | pos | 1 | 23.0% | 11.1% | 11.1% | 100% |  |
| c_mana_ward | mana | 1 | 34.1% | 6.3% | 3.2% | 50% |  |
| c_overflow | mana | 1 | 26.2% | 11.1% | 1.6% | 14% |  |
| c_thorn_pact | mana | 1 | 26.2% | 11.9% | 11.1% | 93% |  |
| c_dry_well | quest | 1 | 26.2% | 4.8% | 4.8% | 100% |  |
| c_night_watch | quest | 1 | 24.6% | 1.6% | 1.6% | 100% |  |
| c_key_strike | quest | 1 | 31.7% | 3.2% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 33.3% | 4.8% | 4.8% | 100% |  |
| c_chimera_hunt | quest | 1 | 31.7% | 4.0% | 3.2% | 80% |  |
| c_golden_egg | rule | 1 | 7.9% | 7.9% | 4.8% | 60% | LOW |
| c_dim_stone | rule | 1 | 12.7% | 1.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 14.3% | 7.1% | 7.9% | 100% |  |
| c_sixth_die | dice | 2 | 13.5% | 4.8% | 5.6% | 100% |  |
| c_whittle | dice | 2 | 16.7% | 4.0% | 4.0% | 100% |  |
| c_three_dice | dice | 2 | 11.9% | 6.3% | 6.3% | 100% |  |
| c_concord | dice | 2 | 8.7% | 4.0% | 4.0% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.1% | 2.4% | 2.4% | 100% | LOW |
| c_living_wall | pos | 2 | 36.5% | 19.0% | 19.0% | 100% |  |
| c_thorn_rebound | rule | 2 | 18.3% | 3.2% | 3.2% | 100% |  |
| c_open_ranks | pos | 2 | 7.9% | 2.4% | 2.4% | 100% | LOW |
| c_descend | pos | 2 | 27.0% | 15.1% | 15.1% | 100% |  |
| c_hollow_core | mana | 2 | 23.0% | 5.6% | 4.0% | 71% |  |
| c_deep_current | mana | 2 | 37.3% | 6.3% | 4.8% | 75% |  |
| c_blood_sign | rule | 2 | 14.3% | 7.1% | 7.1% | 100% |  |
| c_loop | rule | 2 | 15.1% | 4.8% | 4.8% | 100% |  |
| c_cascade | rule | 2 | 11.1% | 3.2% | 3.2% | 100% |  |
| c_sacrifice | rule | 2 | 23.8% | 7.1% | 7.1% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 78.6% (99/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 55.0% (11/20)
- c_living_wall: 45.8% (11/24)
- c_sonic_shield: 44.4% (4/9)
- c_nest: 41.7% (10/24)
- c_thorn_pact: 40.0% (6/15)
- c_mirror_face: 40.0% (4/10)
- c_gatekeeper: 40.0% (10/25)
- c_golden_egg: 40.0% (4/10)
- c_thorn_growth: 36.4% (4/11)
- c_overflow: 35.7% (5/14)

Bottom 10:
- c_mana_ward: 0.0% (0/8)
- c_early_scales: 5.9% (1/17)
- c_tidecaller: 8.3% (1/12)
- c_thorn_shield: 10.7% (3/28)
- c_deep_current: 12.5% (1/8)
- c_elder_trunk: 16.7% (3/18)
- c_finisher: 17.6% (3/17)
- c_bastion: 18.8% (6/32)
- c_kindle: 20.0% (2/10)
- c_descend: 21.1% (4/19)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_gatekeeper + c_living_wall: 53.8% (7/13)
- c_nest + c_spore_burst: 53.8% (7/13)
- c_golden_egg + c_nest: 40.0% (4/10)
- c_descend + c_living_wall: 37.5% (3/8)
- c_bastion + c_living_wall: 33.3% (4/12)
- c_bastion + c_growing_shell: 0.0% (0/10)
- c_early_scales + c_elder_trunk: 0.0% (0/9)
- c_dewdrop + c_elder_trunk: 0.0% (0/12)
- c_elder_trunk + c_thorn_shield: 0.0% (0/12)
- c_dewdrop + c_early_scales: 8.3% (1/12)
