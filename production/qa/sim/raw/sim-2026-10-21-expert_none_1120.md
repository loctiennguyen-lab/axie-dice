# Sim balance expert_none_1120

Runs: 40, wall 75.6s (1.89s/run).

## Muc tieu (Short A0)

- expert 15-25%: 17.5% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -1 (con 98%); r5 elite -4 (con 88%); r6 boss -1 (con 85%); r9 elite -3 (con 78%); r11 battle -1 (con 75%); r12 boss -8 (con 55%); r15 elite -5 (con 42%); r18 boss -10 (con 18%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 29.20 +-3.97 | 24.11 +-2.33 | 30.69 +-3.03 | 21.80 +-3.24 | 5.07 +-0.88 | 0.58 +-0.14 | 17.5 +-11.9 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 33.80 | 1.47 | 1.31 | 4.36 | 89 | 297 | 0.64 | 0.00 | 0.15 | 0.01 | 0.67 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 12 | 5 | 19 | 23 | 41 | 5.12 | 1.25 | 16.73 | 4.15 | 5.08 | 10.47 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (166) | 0% (0) | 33.9 | 18.8 | 10.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 17.5% (7/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 33.3% (2/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
| expert | reptile_bug | 16.7% (1/6) |
| expert | tank_heavy | 40.0% (2/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 25.0% (3/12) |
| expert | greedy_axis | 0.0% (0/14) |
| expert | random | 28.6% (4/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.5 luot (n=304)
- expert|boss: 4.9 luot (n=82)
- expert|elite: 3.7 luot (n=52)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 1
- expert|battle r4: 1
- expert|boss r12: 8
- expert|boss r18: 10
- expert|boss r6: 1
- expert|elite r15: 5
- expert|elite r5: 4
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 438

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.0% | 7.5% | 19% | 7.5% | 100% | 33.3% (1/3) |  |
| c_dewdrop | stat | 0 | 45.0% | 15.0% | 33% | 15.0% | 100% | 16.7% (1/6) |  |
| c_elder_trunk | stat | 0 | 50.0% | 17.5% | 35% | 17.5% | 100% | 0.0% (0/7) |  |
| c_prime_chain | dice | 0 | 27.5% | 5.0% | 18% | 5.0% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 22.5% | 15.0% | 67% | 15.0% | 100% | 16.7% (1/6) |  |
| c_bastion | pos | 0 | 45.0% | 10.0% | 22% | 10.0% | 100% | 50.0% (2/4) |  |
| c_tidecaller | mana | 0 | 45.0% | 10.0% | 22% | 5.0% | 50% | 25.0% (1/4) |  |
| c_mana_pool | mana | 0 | 45.0% | 20.0% | 44% | 15.0% | 75% | 12.5% (1/8) |  |
| c_nest | rule | 0 | 40.0% | 20.0% | 50% | 20.0% | 100% | 0.0% (0/8) |  |
| c_spore_burst | rule | 0 | 47.5% | 27.5% | 58% | 25.0% | 91% | 54.5% (6/11) |  |
| c_fossil | rule | 0 | 27.5% | 5.0% | 18% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_copycat | dice | 0 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_nametag | rule | 0 | 35.0% | 7.5% | 21% | 7.5% | 100% | 0.0% (0/3) |  |
| c_meme_jumpy | dice | 0 | 27.5% | 10.0% | 36% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_none | run_rule | 0 | 15.0% | 7.5% | 50% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_tundra | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| rule_heavy_finish | run_rule | 0 | 12.5% | 12.5% | 100% | 12.5% | 100% | 40.0% (2/5) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 50.0% (2/4) |  |
| rule_old_forest | run_rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_hard_shell | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_balance | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_prism | dice | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| c_steady_hold | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 15.0% | 7.5% | 50% | 5.0% | 67% | 0.0% (0/3) |  |
| c_sonic_shield | dice | 1 | 15.0% | 7.5% | 50% | 7.5% | 100% | 33.3% (1/3) |  |
| c_fissure | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| c_plague_spread | dice | 1 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 15.0% | 10.0% | 67% | 7.5% | 75% | 25.0% (1/4) |  |
| c_thorn_growth | pos | 1 | 27.5% | 2.5% | 9% | 2.5% | 100% | 100.0% (1/1) |  |
| c_thorn_shield | stat | 1 | 55.0% | 12.5% | 23% | 12.5% | 100% | 20.0% (1/5) |  |
| c_growing_shell | pos | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| c_backline_glow | pos | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 25.0% (1/4) |  |
| c_mana_ward | mana | 1 | 32.5% | 10.0% | 31% | 5.0% | 50% | 0.0% (0/4) |  |
| c_overflow | mana | 1 | 27.5% | 17.5% | 64% | 15.0% | 86% | 42.9% (3/7) |  |
| c_thorn_pact | mana | 1 | 20.0% | 5.0% | 25% | 5.0% | 100% | 50.0% (1/2) |  |
| c_dry_well | quest | 1 | 25.0% | 5.0% | 20% | 5.0% | 100% | 100.0% (2/2) |  |
| c_night_watch | quest | 1 | 32.5% | 5.0% | 15% | 5.0% | 100% | 0.0% (0/2) |  |
| c_key_strike | quest | 1 | 17.5% | 2.5% | 14% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 25.0% | 12.5% | 50% | 12.5% | 100% | 60.0% (3/5) |  |
| c_chimera_hunt | quest | 1 | 22.5% | 2.5% | 11% | 2.5% | 100% | 0.0% (0/1) |  |
| c_golden_egg | rule | 1 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dim_stone | rule | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_mirror_face | dice | 2 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_sixth_die | dice | 2 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| c_whittle | dice | 2 | 20.0% | 10.0% | 50% | 10.0% | 100% | 25.0% (1/4) |  |
| c_three_dice | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_toxic_still | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 25.0% | 10.0% | 40% | 10.0% | 100% | 25.0% (1/4) |  |
| c_thorn_rebound | rule | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_open_ranks | pos | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_hollow_core | mana | 2 | 35.0% | 15.0% | 43% | 15.0% | 100% | 0.0% (0/6) |  |
| c_deep_current | mana | 2 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |
| c_blood_sign | rule | 2 | 5.0% | 2.5% | 50% | 5.0% | 100% | 100.0% (1/1) | LOW |
| c_loop | rule | 2 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_cascade | rule | 2 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_sacrifice | rule | 2 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 72.5% (29/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 54.5% (6/11)
- c_mana_pool: 12.5% (1/8)
- c_nest: 0.0% (0/8)

Bottom 10:
- c_nest: 0.0% (0/8)
- c_mana_pool: 12.5% (1/8)
- c_spore_burst: 54.5% (6/11)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
