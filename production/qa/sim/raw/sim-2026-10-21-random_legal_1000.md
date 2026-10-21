# Sim balance random_legal_1000

Runs: 40, wall 2.8s (0.07s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 5.0% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| random_legal | a_gambler | 9 | 22.5 | 0.0 +-0.0 | 11.1 | 5.0 | 11.0 | 15.33 |
| random_legal | a_mana_mine | 12 | 30.0 | 8.3 +-15.6 | 16.7 | 6.0 | 19.5 | 20.76 |
| random_legal | a_volley | 19 | 47.5 | 5.3 +-10.0 | 0.0 | - | - | 17.38 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| random_legal | h_volley | 0.0% | 0.0% |
| random_legal | h_gambler | 5.0% | 0.0% |
| random_legal | h_mana_mine | 5.0% | 0.0% |
| random_legal | h_kin | 0.0% | 0.0% |
| random_legal | h_embers | 2.5% | 2.5% |
| random_legal | h_big_hand | 0.0% | 0.0% |
| random_legal | combos formed avg | 0.12 | |


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=40): r3 battle -4 (con 90%); r4 battle -5 (con 78%); r5 elite -6 (con 62%); r6 boss -9 (con 40%); r9 elite -3 (con 32%); r9 battle -1 (con 30%); r12 boss -7 (con 12%); r18 boss -3 (con 5%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 16.08 +-3.03 | 17.35 +-1.99 | 17.35 +-1.99 | 11.39 +-2.77 | 7.03 +-1.53 | 0.43 +-0.22 | 5.0 +-6.8 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 28.20 | 1.02 | 0.84 | 5.59 | 82 | 547 | 0.60 | 0.00 | 0.08 | 0.01 | 0.34 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 7 | 0 | 6 | 6 | 81 | 1.57 | 0.07 | 4.42 | 0.60 | 0.82 | 7.60 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| random_legal | 0% (0) | 100% (24) | 0% (0) | 14.3 | 8.4 | 8.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: random_legal 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| random_legal | 0 | 5.0% (2/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| random_legal | aqua_plant | 0.0% (0/6) |
| random_legal | beast_bird | 16.7% (1/6) |
| random_legal | mixed_dmg | 0.0% (0/6) |
| random_legal | mixed_std | 0.0% (0/6) |
| random_legal | reptile_bug | 0.0% (0/6) |
| random_legal | tank_heavy | 0.0% (0/5) |
| random_legal | thorn_shield | 20.0% (1/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| random_legal | combo | 8.3% (1/12) |
| random_legal | greedy_axis | 7.1% (1/14) |
| random_legal | random | 0.0% (0/14) |


## So luot trung binh moi tran (chinh sach|loai)

- random_legal|battle: 3.7 luot (n=194)
- random_legal|boss: 6.8 luot (n=42)
- random_legal|elite: 4.8 luot (n=24)

## Chet theo node (chinh sach|loai row)

- random_legal|battle r3: 4
- random_legal|battle r4: 5
- random_legal|battle r9: 1
- random_legal|boss r12: 7
- random_legal|boss r18: 3
- random_legal|boss r6: 9
- random_legal|elite r5: 6
- random_legal|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 260

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 37.5% | 7.5% | 20% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 27.5% | 17.5% | 64% | 17.5% | 100% | 0.0% (0/7) |  |
| c_elder_trunk | stat | 0 | 55.0% | 20.0% | 36% | 20.0% | 100% | 0.0% (0/8) |  |
| c_prime_chain | dice | 0 | 17.5% | 2.5% | 14% | 2.5% | 100% | 100.0% (1/1) |  |
| c_finisher | dice | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_bastion | pos | 0 | 50.0% | 22.5% | 45% | 22.5% | 100% | 0.0% (0/9) |  |
| c_tidecaller | mana | 0 | 40.0% | 10.0% | 25% | 0.0% | 0% | 0.0% (0/4) | DEAD |
| c_mana_pool | mana | 0 | 47.5% | 15.0% | 32% | 15.0% | 100% | 0.0% (0/6) |  |
| c_nest | rule | 0 | 32.5% | 15.0% | 46% | 15.0% | 100% | 16.7% (1/6) |  |
| c_spore_burst | rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 25.0% (1/4) |  |
| c_fossil | rule | 0 | 15.0% | 5.0% | 33% | 2.5% | 50% | 0.0% (0/2) |  |
| c_meme_copycat | dice | 0 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_nametag | rule | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_jumpy | dice | 0 | 25.0% | 5.0% | 20% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_none | run_rule | 0 | 5.0% | 5.0% | 100% | 0.0% | 0% | 50.0% (1/2) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_tundra | run_rule | 0 | 7.5% | 5.0% | 67% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_quick_beat | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 15.0% | 12.5% | 83% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_dry_steppe | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_old_forest | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_crow | run_rule | 0 | 15.0% | 10.0% | 67% | 2.5% | 25% | 0.0% (0/4) |  |
| rule_hard_shell | run_rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_balance | run_rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_steady_hold | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_sonic_shield | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_fissure | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_gatekeeper | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_growth | pos | 1 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| c_thorn_shield | stat | 1 | 40.0% | 5.0% | 12% | 5.0% | 100% | 0.0% (0/2) |  |
| c_growing_shell | pos | 1 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_backline_glow | pos | 1 | 20.0% | 10.0% | 50% | 10.0% | 100% | 25.0% (1/4) |  |
| c_mana_ward | mana | 1 | 17.5% | 5.0% | 29% | 2.5% | 50% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 20.0% | 5.0% | 25% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_thorn_pact | mana | 1 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| c_dry_well | quest | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_night_watch | quest | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_key_strike | quest | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_chimera_hunt | quest | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 50.0% (1/2) |  |
| c_golden_egg | rule | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_dim_stone | rule | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_sixth_die | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_three_dice | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_rebound | rule | 2 | 10.0% | 2.5% | 25% | 5.0% | 100% | 100.0% (1/1) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_hollow_core | mana | 2 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_deep_current | mana | 2 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_blood_sign | rule | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_loop | rule | 2 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_cascade | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_sacrifice | rule | 2 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 42.5% (17/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_bastion: 0.0% (0/9)
- c_elder_trunk: 0.0% (0/8)

Bottom 10:
- c_elder_trunk: 0.0% (0/8)
- c_bastion: 0.0% (0/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
