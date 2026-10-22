# Sim balance anchor-expert_none

Runs: 200, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 17.5% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=200): r4 battle -6 (con 97%); r5 elite -10 (con 92%); r6 boss -13 (con 86%); r7 battle -1 (con 85%); r8 battle -3 (con 84%); r9 battle -2 (con 82%); r9 elite -14 (con 76%); r10 battle -1 (con 75%); r11 battle -2 (con 74%); r12 boss -36 (con 56%); r13 battle -1 (con 56%); r15 elite -24 (con 44%); r15 battle -1 (con 43%); r17 battle -1 (con 42%); r18 boss -50 (con 18%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 200 | 28.01 +-1.65 | 23.45 +-1.06 | 29.52 +-1.40 | 21.17 +-1.45 | 5.10 +-0.31 | 0.51 +-0.06 | 17.5 +-5.3 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 200 | 34.59 | 1.48 | 1.31 | 4.65 | 89 | 315 | 0.63 | 0.00 | 0.19 | 0.04 | 0.61 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 5 | 19 | 22 | 41 | 5.38 | 1.11 | 17.83 | 4.28 | 5.07 | 10.31 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (856) | 0% (0) | 32.4 | 18.5 | 10.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 17.5% (35/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 10.0% (3/30) |
| expert | beast_bird | 33.3% (10/30) |
| expert | mixed_dmg | 13.3% (4/30) |
| expert | mixed_std | 10.0% (3/30) |
| expert | reptile_bug | 16.7% (5/30) |
| expert | tank_heavy | 24.0% (6/25) |
| expert | thorn_shield | 16.0% (4/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 20.0% (12/60) |
| expert | greedy_axis | 11.4% (8/70) |
| expert | random | 21.4% (15/70) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=1501)
- expert|boss: 4.9 luot (n=417)
- expert|elite: 3.9 luot (n=239)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r13: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r4: 6
- expert|battle r7: 1
- expert|battle r8: 3
- expert|battle r9: 2
- expert|boss r12: 36
- expert|boss r18: 50
- expert|boss r6: 13
- expert|elite r15: 24
- expert|elite r5: 10
- expert|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 0 / 2157

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.5% | 9.5% | 23% | 9.5% | 100% | 15.8% (3/19) |  |
| c_dewdrop | stat | 0 | 45.0% | 15.5% | 34% | 15.5% | 100% | 9.7% (3/31) |  |
| c_elder_trunk | stat | 0 | 49.5% | 17.5% | 35% | 17.5% | 100% | 11.4% (4/35) |  |
| c_prime_chain | dice | 0 | 27.0% | 8.0% | 30% | 7.5% | 94% | 18.8% (3/16) |  |
| c_finisher | dice | 0 | 29.5% | 11.0% | 37% | 10.5% | 95% | 27.3% (6/22) |  |
| c_bastion | pos | 0 | 63.5% | 22.0% | 35% | 22.0% | 100% | 15.9% (7/44) |  |
| c_tidecaller | mana | 0 | 49.5% | 11.5% | 23% | 5.0% | 43% | 8.7% (2/23) |  |
| c_mana_pool | mana | 0 | 43.0% | 15.0% | 35% | 13.5% | 90% | 20.0% (6/30) |  |
| c_nest | rule | 0 | 40.5% | 18.0% | 44% | 18.0% | 100% | 38.9% (14/36) |  |
| c_spore_burst | rule | 0 | 45.0% | 21.0% | 47% | 20.5% | 98% | 47.6% (20/42) |  |
| c_fossil | rule | 0 | 28.5% | 6.5% | 23% | 6.5% | 100% | 15.4% (2/13) |  |
| c_meme_copycat | dice | 0 | 23.5% | 5.0% | 21% | 5.0% | 100% | 30.0% (3/10) |  |
| c_meme_nametag | rule | 0 | 35.5% | 7.0% | 20% | 7.0% | 100% | 42.9% (6/14) |  |
| c_meme_jumpy | dice | 0 | 22.0% | 4.0% | 18% | 4.0% | 100% | 12.5% (1/8) |  |
| rule_none | run_rule | 0 | 9.0% | 5.0% | 56% | 0.0% | 0% | 20.0% (2/10) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.5% | 6.0% | 48% | 6.0% | 100% | 0.0% (0/12) |  |
| rule_tundra | run_rule | 0 | 12.0% | 6.0% | 50% | 6.0% | 100% | 8.3% (1/12) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.0% | 48% | 5.0% | 83% | 8.3% (1/12) |  |
| rule_starfall | run_rule | 0 | 11.5% | 8.0% | 70% | 8.0% | 100% | 25.0% (4/16) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.5% | 59% | 6.5% | 100% | 38.5% (5/13) |  |
| rule_wasteland | run_rule | 0 | 11.5% | 7.0% | 61% | 7.0% | 100% | 21.4% (3/14) |  |
| rule_dry_steppe | run_rule | 0 | 16.5% | 8.0% | 48% | 8.0% | 100% | 12.5% (2/16) |  |
| rule_rising_tide | run_rule | 0 | 8.5% | 4.5% | 53% | 4.5% | 100% | 22.2% (2/9) | LOW |
| rule_upside_down | run_rule | 0 | 14.0% | 8.5% | 61% | 8.5% | 100% | 17.6% (3/17) |  |
| rule_old_forest | run_rule | 0 | 24.0% | 10.5% | 44% | 10.5% | 100% | 4.8% (1/21) |  |
| rule_crow | run_rule | 0 | 11.5% | 5.0% | 43% | 5.0% | 100% | 20.0% (2/10) |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 6.5% | 32% | 6.5% | 100% | 23.1% (3/13) |  |
| rule_balance | run_rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 24.0% (6/25) |  |
| c_prism | dice | 1 | 9.0% | 3.0% | 33% | 1.5% | 50% | 0.0% (0/6) | LOW |
| c_steady_hold | dice | 1 | 13.0% | 4.5% | 35% | 4.5% | 100% | 0.0% (0/9) |  |
| c_kindle | dice | 1 | 13.5% | 7.0% | 52% | 6.5% | 93% | 21.4% (3/14) |  |
| c_sonic_shield | dice | 1 | 11.5% | 4.0% | 35% | 3.5% | 88% | 12.5% (1/8) |  |
| c_fissure | dice | 1 | 8.0% | 5.0% | 62% | 5.0% | 100% | 10.0% (1/10) | LOW |
| c_field_medic | dice | 1 | 14.0% | 3.5% | 25% | 3.5% | 100% | 14.3% (1/7) |  |
| c_plague_spread | dice | 1 | 6.5% | 1.5% | 23% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_gatekeeper | pos | 1 | 23.0% | 10.5% | 46% | 10.0% | 95% | 28.6% (6/21) |  |
| c_thorn_growth | pos | 1 | 20.5% | 7.0% | 34% | 7.0% | 100% | 35.7% (5/14) |  |
| c_thorn_shield | stat | 1 | 70.5% | 15.0% | 21% | 15.0% | 100% | 23.3% (7/30) |  |
| c_growing_shell | pos | 1 | 24.0% | 11.0% | 46% | 8.0% | 73% | 18.2% (4/22) |  |
| c_backline_glow | pos | 1 | 29.0% | 14.5% | 50% | 13.5% | 93% | 13.8% (4/29) |  |
| c_mana_ward | mana | 1 | 29.0% | 10.0% | 34% | 5.0% | 50% | 15.0% (3/20) |  |
| c_overflow | mana | 1 | 25.0% | 11.0% | 44% | 6.5% | 59% | 31.8% (7/22) |  |
| c_thorn_pact | mana | 1 | 20.0% | 9.0% | 45% | 9.0% | 100% | 22.2% (4/18) |  |
| c_dry_well | quest | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 60.0% (6/10) |  |
| c_night_watch | quest | 1 | 27.0% | 3.0% | 11% | 3.0% | 100% | 0.0% (0/6) |  |
| c_key_strike | quest | 1 | 22.5% | 2.5% | 11% | 1.0% | 40% | 0.0% (0/5) |  |
| c_collector | quest | 1 | 23.5% | 7.5% | 32% | 7.5% | 100% | 40.0% (6/15) |  |
| c_chimera_hunt | quest | 1 | 23.5% | 6.0% | 26% | 4.0% | 67% | 16.7% (2/12) |  |
| c_golden_egg | rule | 1 | 7.5% | 5.5% | 73% | 4.0% | 73% | 27.3% (3/11) | LOW |
| c_dim_stone | rule | 1 | 16.5% | 1.5% | 9% | 1.5% | 100% | 66.7% (2/3) |  |
| c_mirror_face | dice | 2 | 14.5% | 5.5% | 38% | 5.5% | 100% | 27.3% (3/11) |  |
| c_sixth_die | dice | 2 | 13.5% | 5.5% | 41% | 5.5% | 100% | 45.5% (5/11) |  |
| c_whittle | dice | 2 | 17.5% | 3.5% | 20% | 3.5% | 100% | 14.3% (1/7) |  |
| c_three_dice | dice | 2 | 6.5% | 2.5% | 38% | 2.5% | 100% | 0.0% (0/5) | LOW |
| c_concord | dice | 2 | 8.0% | 1.5% | 19% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_toxic_still | dice | 2 | 7.0% | 2.5% | 36% | 2.5% | 100% | 0.0% (0/5) | LOW |
| c_living_wall | pos | 2 | 28.5% | 14.0% | 49% | 14.0% | 100% | 21.4% (6/28) |  |
| c_thorn_rebound | rule | 2 | 16.5% | 6.5% | 39% | 5.5% | 85% | 30.8% (4/13) |  |
| c_open_ranks | pos | 2 | 5.0% | 0.5% | 10% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_descend | pos | 2 | 14.0% | 6.5% | 46% | 7.0% | 100% | 23.1% (3/13) |  |
| c_hollow_core | mana | 2 | 29.5% | 11.5% | 39% | 11.0% | 96% | 4.3% (1/23) |  |
| c_deep_current | mana | 2 | 29.5% | 10.5% | 36% | 7.0% | 67% | 9.5% (2/21) |  |
| c_blood_sign | rule | 2 | 7.0% | 2.5% | 36% | 3.5% | 100% | 20.0% (1/5) | LOW |
| c_loop | rule | 2 | 14.5% | 6.5% | 45% | 6.0% | 92% | 61.5% (8/13) |  |
| c_cascade | rule | 2 | 13.5% | 4.5% | 33% | 4.0% | 89% | 44.4% (4/9) |  |
| c_sacrifice | rule | 2 | 16.5% | 3.5% | 21% | 3.5% | 100% | 14.3% (1/7) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 71.5% (143/200)

Win-rate khi co Loi (n >= 8). Top 10:
- c_loop: 61.5% (8/13)
- c_dry_well: 60.0% (6/10)
- c_spore_burst: 47.6% (20/42)
- c_sixth_die: 45.5% (5/11)
- c_cascade: 44.4% (4/9)
- c_meme_nametag: 42.9% (6/14)
- c_collector: 40.0% (6/15)
- c_nest: 38.9% (14/36)
- c_thorn_growth: 35.7% (5/14)
- c_overflow: 31.8% (7/22)

Bottom 10:
- c_steady_hold: 0.0% (0/9)
- c_hollow_core: 4.3% (1/23)
- c_tidecaller: 8.7% (2/23)
- c_deep_current: 9.5% (2/21)
- c_dewdrop: 9.7% (3/31)
- c_fissure: 10.0% (1/10)
- c_elder_trunk: 11.4% (4/35)
- c_meme_jumpy: 12.5% (1/8)
- c_sonic_shield: 12.5% (1/8)
- c_backline_glow: 13.8% (4/29)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_loop + c_spore_burst: 70.0% (7/10)
- c_meme_nametag + c_spore_burst: 62.5% (5/8)
- c_meme_nametag + c_nest: 62.5% (5/8)
- c_nest + c_spore_burst: 59.1% (13/22)
- c_backline_glow + c_gatekeeper: 44.4% (4/9)
- c_hollow_core + c_mana_ward: 0.0% (0/8)
- c_dewdrop + c_thorn_shield: 6.7% (1/15)
- c_deep_current + c_mana_pool: 8.3% (1/12)
- c_mana_ward + c_tidecaller: 8.3% (1/12)
- c_bastion + c_growing_shell: 9.1% (1/11)
