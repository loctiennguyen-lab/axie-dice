# Sim balance expert_none_1160

Runs: 40, wall 68.9s (1.72s/run).

## Muc tieu (Short A0)

- expert 15-25%: 15.0% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -1 (con 98%); r5 elite -2 (con 92%); r6 boss -2 (con 88%); r9 elite -1 (con 85%); r9 battle -1 (con 82%); r11 battle -1 (con 80%); r12 boss -6 (con 65%); r13 battle -1 (con 62%); r15 elite -6 (con 48%); r17 battle -1 (con 45%); r18 boss -12 (con 15%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 28.17 +-3.29 | 23.31 +-2.18 | 28.72 +-2.46 | 21.18 +-2.70 | 5.08 +-0.63 | 0.60 +-0.16 | 15.0 +-11.2 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 37.25 | 1.50 | 1.36 | 4.20 | 91 | 281 | 0.72 | 0.00 | 0.18 | 0.00 | 0.60 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 3 | 17 | 21 | 46 | 6.08 | 0.93 | 18.30 | 4.30 | 5.28 | 10.97 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (172) | 0% (0) | 30.9 | 17.6 | 9.8 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 15.0% (6/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/6) |
| expert | beast_bird | 50.0% (3/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 16.7% (1/6) |
| expert | reptile_bug | 0.0% (0/6) |
| expert | tank_heavy | 20.0% (1/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 25.0% (3/12) |
| expert | greedy_axis | 14.3% (2/14) |
| expert | random | 7.1% (1/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=325)
- expert|boss: 4.9 luot (n=87)
- expert|elite: 3.9 luot (n=46)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 1
- expert|battle r13: 1
- expert|battle r17: 1
- expert|battle r4: 1
- expert|battle r9: 1
- expert|boss r12: 6
- expert|boss r18: 12
- expert|boss r6: 2
- expert|elite r15: 6
- expert|elite r5: 2
- expert|elite r9: 1

Tran ket > 20 luot hoac khong ket thuc: 0 / 458

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 45.0% | 10.0% | 22% | 10.0% | 100% | 0.0% (0/4) |  |
| c_dewdrop | stat | 0 | 50.0% | 15.0% | 30% | 15.0% | 100% | 0.0% (0/6) |  |
| c_elder_trunk | stat | 0 | 45.0% | 20.0% | 44% | 20.0% | 100% | 12.5% (1/8) |  |
| c_prime_chain | dice | 0 | 27.5% | 7.5% | 27% | 7.5% | 100% | 33.3% (1/3) |  |
| c_finisher | dice | 0 | 37.5% | 15.0% | 40% | 12.5% | 83% | 16.7% (1/6) |  |
| c_bastion | pos | 0 | 67.5% | 25.0% | 37% | 25.0% | 100% | 0.0% (0/10) |  |
| c_tidecaller | mana | 0 | 50.0% | 17.5% | 35% | 7.5% | 43% | 0.0% (0/7) |  |
| c_mana_pool | mana | 0 | 45.0% | 7.5% | 17% | 7.5% | 100% | 33.3% (1/3) |  |
| c_nest | rule | 0 | 40.0% | 17.5% | 44% | 17.5% | 100% | 71.4% (5/7) |  |
| c_spore_burst | rule | 0 | 47.5% | 17.5% | 37% | 17.5% | 100% | 71.4% (5/7) |  |
| c_fossil | rule | 0 | 32.5% | 2.5% | 8% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_copycat | dice | 0 | 30.0% | 7.5% | 25% | 7.5% | 100% | 0.0% (0/3) |  |
| c_meme_nametag | rule | 0 | 47.5% | 15.0% | 32% | 15.0% | 100% | 50.0% (3/6) |  |
| c_meme_jumpy | dice | 0 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_none | run_rule | 0 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_cheap_mana | run_rule | 0 | 20.0% | 10.0% | 50% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_tundra | run_rule | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 7.5% | 75% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_heavy_finish | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 100.0% (2/2) |  |
| rule_wasteland | run_rule | 0 | 7.5% | 7.5% | 100% | 7.5% | 100% | 0.0% (0/3) | LOW |
| rule_dry_steppe | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_rising_tide | run_rule | 0 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 15.0% | 100% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 27.5% | 15.0% | 55% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_crow | run_rule | 0 | 15.0% | 2.5% | 17% | 2.5% | 100% | 100.0% (1/1) |  |
| rule_hard_shell | run_rule | 0 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_balance | run_rule | 0 | 25.0% | 15.0% | 60% | 15.0% | 100% | 16.7% (1/6) |  |
| c_prism | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_steady_hold | dice | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_kindle | dice | 1 | 20.0% | 10.0% | 50% | 10.0% | 100% | 25.0% (1/4) |  |
| c_sonic_shield | dice | 1 | 7.5% | 5.0% | 67% | 2.5% | 50% | 0.0% (0/2) | LOW |
| c_fissure | dice | 1 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| c_field_medic | dice | 1 | 20.0% | 12.5% | 62% | 12.5% | 100% | 20.0% (1/5) |  |
| c_plague_spread | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_gatekeeper | pos | 1 | 30.0% | 15.0% | 50% | 15.0% | 100% | 33.3% (2/6) |  |
| c_thorn_growth | pos | 1 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| c_thorn_shield | stat | 1 | 75.0% | 5.0% | 7% | 5.0% | 100% | 0.0% (0/2) |  |
| c_growing_shell | pos | 1 | 22.5% | 12.5% | 56% | 10.0% | 80% | 0.0% (0/5) |  |
| c_backline_glow | pos | 1 | 37.5% | 7.5% | 20% | 7.5% | 100% | 0.0% (0/3) |  |
| c_mana_ward | mana | 1 | 15.0% | 10.0% | 67% | 5.0% | 50% | 0.0% (0/4) |  |
| c_overflow | mana | 1 | 27.5% | 10.0% | 36% | 10.0% | 100% | 25.0% (1/4) |  |
| c_thorn_pact | mana | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_dry_well | quest | 1 | 20.0% | 5.0% | 25% | 5.0% | 100% | 50.0% (1/2) |  |
| c_night_watch | quest | 1 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 27.5% | 5.0% | 18% | 2.5% | 50% | 0.0% (0/2) |  |
| c_collector | quest | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_chimera_hunt | quest | 1 | 27.5% | 7.5% | 27% | 5.0% | 67% | 0.0% (0/3) |  |
| c_golden_egg | rule | 1 | 2.5% | 2.5% | 100% | 0.0% | 0% | 100.0% (1/1) | LOW DEAD |
| c_dim_stone | rule | 1 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_sixth_die | dice | 2 | 15.0% | 7.5% | 50% | 7.5% | 100% | 33.3% (1/3) |  |
| c_whittle | dice | 2 | 20.0% | 7.5% | 38% | 7.5% | 100% | 0.0% (0/3) |  |
| c_three_dice | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_living_wall | pos | 2 | 25.0% | 12.5% | 50% | 12.5% | 100% | 0.0% (0/5) |  |
| c_thorn_rebound | rule | 2 | 15.0% | 5.0% | 33% | 2.5% | 50% | 50.0% (1/2) |  |
| c_open_ranks | pos | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 20.0% | 10.0% | 50% | 10.0% | 100% | 0.0% (0/4) |  |
| c_hollow_core | mana | 2 | 30.0% | 12.5% | 42% | 10.0% | 80% | 0.0% (0/5) |  |
| c_deep_current | mana | 2 | 32.5% | 7.5% | 23% | 5.0% | 67% | 0.0% (0/3) |  |
| c_blood_sign | rule | 2 | 7.5% | 5.0% | 67% | 7.5% | 100% | 0.0% (0/2) | LOW |
| c_loop | rule | 2 | 22.5% | 10.0% | 44% | 7.5% | 75% | 75.0% (3/4) |  |
| c_cascade | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_sacrifice | rule | 2 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 77.5% (31/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_elder_trunk: 12.5% (1/8)
- c_bastion: 0.0% (0/10)

Bottom 10:
- c_bastion: 0.0% (0/10)
- c_elder_trunk: 12.5% (1/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
