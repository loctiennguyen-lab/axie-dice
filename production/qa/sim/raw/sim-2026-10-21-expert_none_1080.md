# Sim balance expert_none_1080

Runs: 40, wall 65.0s (1.63s/run).

## Muc tieu (Short A0)

- expert 15-25%: 20.0% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -2 (con 95%); r6 boss -4 (con 85%); r8 battle -1 (con 82%); r9 elite -4 (con 72%); r10 battle -1 (con 70%); r12 boss -8 (con 50%); r15 elite -5 (con 38%); r18 boss -7 (con 20%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 28.20 +-3.95 | 23.43 +-2.59 | 30.10 +-3.27 | 20.96 +-3.48 | 5.17 +-0.76 | 0.45 +-0.13 | 20.0 +-12.6 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 31.98 | 1.35 | 1.32 | 3.97 | 98 | 293 | 0.63 | 0.00 | 0.16 | 0.03 | 0.54 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 20 | 22 | 39 | 5.40 | 1.18 | 18.65 | 4.17 | 4.72 | 9.57 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (167) | 0% (0) | 33.3 | 20.4 | 9.9 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 20.0% (8/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 50.0% (3/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
| expert | reptile_bug | 16.7% (1/6) |
| expert | tank_heavy | 20.0% (1/5) |
| expert | thorn_shield | 20.0% (1/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (2/12) |
| expert | greedy_axis | 14.3% (2/14) |
| expert | random | 28.6% (4/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.5 luot (n=283)
- expert|boss: 4.7 luot (n=81)
- expert|elite: 3.7 luot (n=50)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r4: 2
- expert|battle r8: 1
- expert|boss r12: 8
- expert|boss r18: 7
- expert|boss r6: 4
- expert|elite r15: 5
- expert|elite r9: 4

Tran ket > 20 luot hoac khong ket thuc: 0 / 414

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 50.0% | 10.0% | 20% | 10.0% | 100% | 25.0% (1/4) |  |
| c_dewdrop | stat | 0 | 50.0% | 10.0% | 20% | 10.0% | 100% | 0.0% (0/4) |  |
| c_elder_trunk | stat | 0 | 37.5% | 12.5% | 33% | 12.5% | 100% | 20.0% (1/5) |  |
| c_prime_chain | dice | 0 | 30.0% | 12.5% | 42% | 10.0% | 80% | 20.0% (1/5) |  |
| c_finisher | dice | 0 | 37.5% | 12.5% | 33% | 12.5% | 100% | 40.0% (2/5) |  |
| c_bastion | pos | 0 | 72.5% | 27.5% | 38% | 27.5% | 100% | 18.2% (2/11) |  |
| c_tidecaller | mana | 0 | 45.0% | 10.0% | 22% | 2.5% | 25% | 0.0% (0/4) |  |
| c_mana_pool | mana | 0 | 32.5% | 10.0% | 31% | 10.0% | 100% | 0.0% (0/4) |  |
| c_nest | rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 60.0% (3/5) |  |
| c_spore_burst | rule | 0 | 37.5% | 17.5% | 47% | 17.5% | 100% | 42.9% (3/7) |  |
| c_fossil | rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_meme_copycat | dice | 0 | 30.0% | 2.5% | 8% | 2.5% | 100% | 100.0% (1/1) |  |
| c_meme_nametag | rule | 0 | 30.0% | 5.0% | 17% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 2.5% | 14% | 2.5% | 100% | 100.0% (1/1) |  |
| rule_none | run_rule | 0 | 15.0% | 10.0% | 67% | 0.0% | 0% | 0.0% (0/4) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_tundra | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 5.0% | 40% | 2.5% | 50% | 50.0% (1/2) |  |
| rule_starfall | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_heavy_finish | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| rule_wasteland | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_dry_steppe | run_rule | 0 | 25.0% | 17.5% | 70% | 17.5% | 100% | 14.3% (1/7) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_upside_down | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (1/1) | LOW |
| rule_old_forest | run_rule | 0 | 30.0% | 10.0% | 33% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_hard_shell | run_rule | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_balance | run_rule | 0 | 22.5% | 12.5% | 56% | 12.5% | 100% | 60.0% (3/5) |  |
| c_prism | dice | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_steady_hold | dice | 1 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_kindle | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_sonic_shield | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_fissure | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_plague_spread | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_gatekeeper | pos | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 50.0% (2/4) |  |
| c_thorn_growth | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_shield | stat | 1 | 77.5% | 20.0% | 26% | 20.0% | 100% | 25.0% (2/8) |  |
| c_growing_shell | pos | 1 | 25.0% | 17.5% | 70% | 15.0% | 86% | 42.9% (3/7) |  |
| c_backline_glow | pos | 1 | 37.5% | 25.0% | 67% | 22.5% | 90% | 20.0% (2/10) |  |
| c_mana_ward | mana | 1 | 35.0% | 12.5% | 36% | 5.0% | 40% | 20.0% (1/5) |  |
| c_overflow | mana | 1 | 20.0% | 12.5% | 62% | 5.0% | 40% | 20.0% (1/5) |  |
| c_thorn_pact | mana | 1 | 17.5% | 12.5% | 71% | 12.5% | 100% | 20.0% (1/5) |  |
| c_dry_well | quest | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 50.0% (1/2) |  |
| c_night_watch | quest | 1 | 27.5% | 2.5% | 9% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 22.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 30.0% | 10.0% | 33% | 10.0% | 100% | 25.0% (1/4) |  |
| c_chimera_hunt | quest | 1 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_golden_egg | rule | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_dim_stone | rule | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_mirror_face | dice | 2 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_sixth_die | dice | 2 | 15.0% | 5.0% | 33% | 5.0% | 100% | 100.0% (2/2) |  |
| c_whittle | dice | 2 | 20.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_three_dice | dice | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_concord | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 32.5% | 17.5% | 54% | 17.5% | 100% | 28.6% (2/7) |  |
| c_thorn_rebound | rule | 2 | 15.0% | 10.0% | 67% | 7.5% | 75% | 25.0% (1/4) |  |
| c_open_ranks | pos | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_descend | pos | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 100.0% (2/2) |  |
| c_hollow_core | mana | 2 | 25.0% | 15.0% | 60% | 15.0% | 100% | 0.0% (0/6) |  |
| c_deep_current | mana | 2 | 22.5% | 7.5% | 33% | 5.0% | 67% | 0.0% (0/3) |  |
| c_blood_sign | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_loop | rule | 2 | 17.5% | 10.0% | 57% | 10.0% | 100% | 50.0% (2/4) |  |
| c_cascade | rule | 2 | 20.0% | 12.5% | 62% | 10.0% | 80% | 40.0% (2/5) |  |
| c_sacrifice | rule | 2 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 67.5% (27/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_thorn_shield: 25.0% (2/8)
- c_backline_glow: 20.0% (2/10)
- c_bastion: 18.2% (2/11)

Bottom 10:
- c_bastion: 18.2% (2/11)
- c_backline_glow: 20.0% (2/10)
- c_thorn_shield: 25.0% (2/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
