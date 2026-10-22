# Sim balance expert_none_1040

Runs: 40, wall 72.5s (1.81s/run).

## Muc tieu (Short A0)

- expert 15-25%: 15.0% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -1 (con 98%); r5 elite -1 (con 95%); r6 boss -4 (con 85%); r8 battle -1 (con 82%); r9 elite -3 (con 75%); r12 boss -5 (con 62%); r15 elite -6 (con 48%); r15 battle -1 (con 45%); r18 boss -12 (con 15%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 28.57 +-3.37 | 23.45 +-2.48 | 29.24 +-3.30 | 21.94 +-3.30 | 5.01 +-0.60 | 0.49 +-0.14 | 15.0 +-11.2 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 34.83 | 1.66 | 1.36 | 5.57 | 82 | 336 | 0.63 | 0.00 | 0.37 | 0.07 | 0.59 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 6 | 19 | 22 | 39 | 5.58 | 1.32 | 16.20 | 4.45 | 5.30 | 11.45 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (178) | 0% (0) | 32.5 | 19.3 | 11.6 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 15.0% (6/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/6) |
| expert | beast_bird | 16.7% (1/6) |
| expert | mixed_dmg | 0.0% (0/6) |
| expert | mixed_std | 33.3% (2/6) |
| expert | reptile_bug | 33.3% (2/6) |
| expert | tank_heavy | 0.0% (0/5) |
| expert | thorn_shield | 20.0% (1/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (2/12) |
| expert | greedy_axis | 7.1% (1/14) |
| expert | random | 21.4% (3/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=291)
- expert|boss: 4.8 luot (n=86)
- expert|elite: 4.0 luot (n=54)

## Chet theo node (chinh sach|loai row)

- expert|battle r15: 1
- expert|battle r4: 1
- expert|battle r8: 1
- expert|boss r12: 5
- expert|boss r18: 12
- expert|boss r6: 4
- expert|elite r15: 6
- expert|elite r5: 1
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 431

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 32.5% | 7.5% | 23% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 40.0% | 15.0% | 38% | 15.0% | 100% | 16.7% (1/6) |  |
| c_elder_trunk | stat | 0 | 47.5% | 12.5% | 26% | 12.5% | 100% | 20.0% (1/5) |  |
| c_prime_chain | dice | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_finisher | dice | 0 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_bastion | pos | 0 | 72.5% | 25.0% | 34% | 25.0% | 100% | 10.0% (1/10) |  |
| c_tidecaller | mana | 0 | 55.0% | 10.0% | 18% | 7.5% | 75% | 0.0% (0/4) |  |
| c_mana_pool | mana | 0 | 50.0% | 15.0% | 30% | 12.5% | 83% | 16.7% (1/6) |  |
| c_nest | rule | 0 | 45.0% | 25.0% | 56% | 25.0% | 100% | 40.0% (4/10) |  |
| c_spore_burst | rule | 0 | 47.5% | 22.5% | 47% | 22.5% | 100% | 44.4% (4/9) |  |
| c_fossil | rule | 0 | 30.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_meme_copycat | dice | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_meme_nametag | rule | 0 | 37.5% | 5.0% | 13% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_tundra | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_quick_beat | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_wasteland | run_rule | 0 | 17.5% | 15.0% | 86% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_dry_steppe | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 12.5% | 10.0% | 80% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_upside_down | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_old_forest | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_crow | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_hard_shell | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| rule_balance | run_rule | 0 | 32.5% | 15.0% | 46% | 15.0% | 100% | 33.3% (2/6) |  |
| c_prism | dice | 1 | 7.5% | 5.0% | 67% | 2.5% | 50% | 0.0% (0/2) | LOW |
| c_steady_hold | dice | 1 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| c_kindle | dice | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 25.0% (1/4) |  |
| c_sonic_shield | dice | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_fissure | dice | 1 | 10.0% | 7.5% | 75% | 7.5% | 100% | 33.3% (1/3) |  |
| c_field_medic | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_gatekeeper | pos | 1 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| c_thorn_growth | pos | 1 | 40.0% | 15.0% | 38% | 15.0% | 100% | 33.3% (2/6) |  |
| c_thorn_shield | stat | 1 | 65.0% | 12.5% | 19% | 12.5% | 100% | 20.0% (1/5) |  |
| c_growing_shell | pos | 1 | 37.5% | 17.5% | 47% | 10.0% | 57% | 14.3% (1/7) |  |
| c_backline_glow | pos | 1 | 25.0% | 15.0% | 60% | 15.0% | 100% | 0.0% (0/6) |  |
| c_mana_ward | mana | 1 | 32.5% | 5.0% | 15% | 2.5% | 50% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 22.5% | 5.0% | 22% | 2.5% | 50% | 0.0% (0/2) |  |
| c_thorn_pact | mana | 1 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dry_well | quest | 1 | 20.0% | 5.0% | 25% | 5.0% | 100% | 50.0% (1/2) |  |
| c_night_watch | quest | 1 | 32.5% | 2.5% | 8% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 17.5% | 2.5% | 14% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 25.0% | 5.0% | 20% | 5.0% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 27.5% | 7.5% | 27% | 5.0% | 67% | 33.3% (1/3) |  |
| c_golden_egg | rule | 1 | 10.0% | 10.0% | 100% | 5.0% | 50% | 25.0% (1/4) |  |
| c_dim_stone | rule | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_mirror_face | dice | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_sixth_die | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_three_dice | dice | 2 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_concord | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_living_wall | pos | 2 | 35.0% | 20.0% | 57% | 20.0% | 100% | 25.0% (2/8) |  |
| c_thorn_rebound | rule | 2 | 22.5% | 12.5% | 56% | 12.5% | 100% | 40.0% (2/5) |  |
| c_open_ranks | pos | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 7.5% | 5.0% | 67% | 7.5% | 100% | 0.0% (0/2) | LOW |
| c_hollow_core | mana | 2 | 27.5% | 7.5% | 27% | 7.5% | 100% | 0.0% (0/3) |  |
| c_deep_current | mana | 2 | 35.0% | 12.5% | 36% | 7.5% | 60% | 20.0% (1/5) |  |
| c_blood_sign | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_loop | rule | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cascade | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_sacrifice | rule | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 72.5% (29/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 44.4% (4/9)
- c_nest: 40.0% (4/10)
- c_living_wall: 25.0% (2/8)
- c_bastion: 10.0% (1/10)

Bottom 10:
- c_bastion: 10.0% (1/10)
- c_living_wall: 25.0% (2/8)
- c_nest: 40.0% (4/10)
- c_spore_burst: 44.4% (4/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
