# Sim balance new_expert_1

Runs: 500, wall 686.0s (1.37s/run).

## Muc tieu (Short A0)

- expert 15-25%: 32.0% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=500): r4 battle -2 (con 100%); r5 elite -26 (con 94%); r6 boss -34 (con 88%); r8 battle -2 (con 87%); r9 elite -22 (con 83%); r11 battle -2 (con 82%); r12 boss -62 (con 70%); r15 elite -52 (con 60%); r15 battle -3 (con 59%); r17 battle -1 (con 59%); r18 boss -134 (con 32%)


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 32.0% (160/500) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 18.1% (13/72) |
| expert | beast_bird | 26.4% (19/72) |
| expert | mixed_dmg | 38.0% (27/71) |
| expert | mixed_std | 36.6% (26/71) |
| expert | reptile_bug | 38.9% (28/72) |
| expert | tank_heavy | 33.8% (24/71) |
| expert | thorn_shield | 32.4% (23/71) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 32.0% (160/500) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=4042)
- expert|boss: 6.1 luot (n=1178)
- expert|elite: 4.4 luot (n=612)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r15: 3
- expert|battle r17: 1
- expert|battle r4: 2
- expert|battle r8: 2
- expert|boss r12: 62
- expert|boss r18: 134
- expert|boss r6: 34
- expert|elite r15: 52
- expert|elite r5: 26
- expert|elite r9: 22

Tran ket > 20 luot hoac khong ket thuc: 15 / 5832

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 52.2% | 0.4% | 0.4% | 100% |  |
| c_dewdrop | stat | 0 | 47.8% | 16.6% | 16.6% | 100% |  |
| c_elder_trunk | stat | 0 | 47.0% | 16.4% | 16.4% | 100% |  |
| c_prime_chain | dice | 0 | 43.8% | 20.2% | 20.0% | 99% |  |
| c_finisher | dice | 0 | 52.4% | 23.0% | 22.6% | 98% |  |
| c_bastion | pos | 0 | 66.6% | 27.2% | 27.0% | 99% |  |
| c_tidecaller | mana | 0 | 53.6% | 0.0% | 0.0% | - |  |
| c_mana_pool | mana | 0 | 45.8% | 16.2% | 14.8% | 91% |  |
| c_nest | rule | 0 | 56.2% | 19.8% | 19.8% | 100% |  |
| c_spore_burst | rule | 0 | 53.4% | 18.4% | 17.2% | 93% |  |
| c_fossil | rule | 0 | 34.2% | 0.0% | 0.0% | - |  |
| rule_none | run_rule | 0 | 9.8% | 0.8% | 0.0% | 0% | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 13.0% | 6.8% | 5.8% | 85% |  |
| rule_tundra | run_rule | 0 | 12.0% | 4.8% | 0.2% | 4% |  |
| rule_quick_beat | run_rule | 0 | 9.0% | 5.8% | 5.6% | 97% | LOW |
| rule_starfall | run_rule | 0 | 10.2% | 5.8% | 5.8% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 17.4% | 12.0% | 12.0% | 100% |  |
| rule_wasteland | run_rule | 0 | 11.2% | 6.2% | 6.2% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 11.0% | 6.4% | 6.4% | 100% |  |
| rule_rising_tide | run_rule | 0 | 13.0% | 9.0% | 9.0% | 100% |  |
| rule_upside_down | run_rule | 0 | 11.6% | 6.2% | 6.2% | 100% |  |
| rule_old_forest | run_rule | 0 | 26.6% | 16.4% | 16.4% | 100% |  |
| rule_crow | run_rule | 0 | 11.2% | 1.2% | 1.2% | 100% |  |
| rule_hard_shell | run_rule | 0 | 18.4% | 1.2% | 1.2% | 100% |  |
| rule_balance | run_rule | 0 | 25.6% | 17.4% | 17.4% | 100% |  |
| c_prism | dice | 1 | 14.0% | 7.0% | 3.2% | 46% |  |
| c_steady_hold | dice | 1 | 12.8% | 1.6% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 14.8% | 8.6% | 1.0% | 12% |  |
| c_sonic_shield | dice | 1 | 14.8% | 10.2% | 10.0% | 98% |  |
| c_fissure | dice | 1 | 8.6% | 4.4% | 4.2% | 95% | LOW |
| c_field_medic | dice | 1 | 13.2% | 0.8% | 0.8% | 100% |  |
| c_plague_spread | dice | 1 | 8.8% | 5.4% | 5.2% | 96% | LOW |
| c_gatekeeper | pos | 1 | 25.2% | 17.6% | 17.2% | 98% |  |
| c_thorn_growth | pos | 1 | 29.4% | 2.6% | 2.4% | 92% |  |
| c_thorn_shield | stat | 1 | 74.2% | 2.2% | 2.0% | 91% |  |
| c_backline_glow | pos | 1 | 33.6% | 26.4% | 24.8% | 94% |  |
| c_growing_shell | pos | 1 | 29.4% | 22.0% | 19.6% | 89% |  |
| c_mana_ward | mana | 1 | 30.2% | 1.8% | 1.8% | 100% |  |
| c_overflow | mana | 1 | 28.0% | 15.8% | 11.0% | 70% |  |
| c_thorn_pact | mana | 1 | 21.6% | 11.4% | 11.2% | 98% |  |
| c_dry_well | quest | 1 | 29.4% | 0.2% | 0.2% | 100% |  |
| c_night_watch | quest | 1 | 26.4% | 0.0% | 0.0% | - |  |
| c_key_strike | quest | 1 | 25.2% | 0.0% | 0.0% | - |  |
| c_collector | quest | 1 | 28.8% | 9.4% | 9.4% | 100% |  |
| c_chimera_hunt | quest | 1 | 30.6% | 11.8% | 9.2% | 78% |  |
| c_golden_egg | rule | 1 | 13.6% | 13.4% | 7.4% | 55% |  |
| c_dim_stone | rule | 1 | 12.8% | 1.0% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.8% | 6.6% | 6.6% | 100% |  |
| c_sixth_die | dice | 2 | 14.2% | 9.6% | 9.6% | 100% |  |
| c_whittle | dice | 2 | 10.2% | 0.4% | 0.6% | 100% |  |
| c_three_dice | dice | 2 | 11.6% | 6.0% | 6.0% | 100% |  |
| c_concord | dice | 2 | 7.2% | 0.6% | 0.6% | 100% | LOW |
| c_toxic_still | dice | 2 | 10.2% | 0.6% | 0.6% | 100% |  |
| c_living_wall | pos | 2 | 37.0% | 27.2% | 27.2% | 100% |  |
| c_thorn_rebound | rule | 2 | 21.2% | 2.2% | 2.0% | 91% |  |
| c_open_ranks | pos | 2 | 5.4% | 1.2% | 1.2% | 100% | LOW |
| c_descend | pos | 2 | 20.0% | 15.2% | 14.8% | 97% |  |
| c_hollow_core | mana | 2 | 25.6% | 12.6% | 9.8% | 78% |  |
| c_deep_current | mana | 2 | 34.2% | 3.8% | 3.0% | 74% |  |
| c_blood_sign | rule | 2 | 14.0% | 7.2% | 7.6% | 100% |  |
| c_loop | rule | 2 | 9.6% | 5.4% | 5.4% | 96% | LOW |
| c_cascade | rule | 2 | 14.0% | 7.8% | 7.8% | 100% |  |
| c_sacrifice | rule | 2 | 17.4% | 1.8% | 1.8% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 83.4% (417/500)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 68.1% (62/91)
- c_golden_egg: 64.2% (43/67)
- c_cascade: 61.5% (24/39)
- c_sonic_shield: 60.8% (31/51)
- c_nest: 57.1% (56/98)
- c_fissure: 50.0% (11/22)
- c_loop: 46.4% (13/28)
- c_mana_ward: 44.4% (4/9)
- c_sixth_die: 43.8% (21/48)
- c_blood_sign: 42.1% (16/38)

Bottom 10:
- c_thorn_shield: 18.2% (2/11)
- c_thorn_rebound: 18.2% (2/11)
- c_sacrifice: 22.2% (2/9)
- c_mana_pool: 24.7% (19/77)
- c_bastion: 24.8% (33/133)
- c_deep_current: 25.0% (5/20)
- c_hollow_core: 27.0% (17/63)
- c_collector: 27.7% (13/47)
- c_growing_shell: 28.2% (31/110)
- c_finisher: 28.3% (32/113)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_cascade + c_golden_egg: 92.9% (13/14)
- c_overflow + c_spore_burst: 88.9% (8/9)
- c_backline_glow + c_cascade: 88.9% (8/9)
- c_spore_burst + c_thorn_pact: 88.9% (8/9)
- c_elder_trunk + c_spore_burst: 87.5% (7/8)
- c_elder_trunk + c_gatekeeper: 0.0% (0/9)
- c_hollow_core + c_kindle: 7.7% (1/13)
- c_prime_chain + c_prism: 7.7% (1/13)
- c_bastion + c_finisher: 11.1% (1/9)
- c_gatekeeper + c_hollow_core: 12.5% (1/8)
