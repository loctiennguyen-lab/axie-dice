# Sim balance random_legal_1160

Runs: 40, wall 2.9s (0.07s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 7.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| random_legal | a_gambler | 16 | 40.0 | 18.8 +-19.1 | 18.8 | 4.0 | 10.7 | 21.18 |
| random_legal | a_mana_mine | 12 | 30.0 | 0.0 +-0.0 | 33.3 | 7.5 | 16.5 | 19.52 |
| random_legal | a_volley | 12 | 30.0 | 0.0 +-0.0 | 8.3 | 10.0 | 41.0 | 20.83 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| random_legal | h_volley | 2.5% | 0.0% |
| random_legal | h_gambler | 10.0% | 2.5% |
| random_legal | h_mana_mine | 5.0% | 0.0% |
| random_legal | h_kin | 2.5% | 2.5% |
| random_legal | h_embers | 0.0% | 0.0% |
| random_legal | h_big_hand | 0.0% | 0.0% |
| random_legal | combos formed avg | 0.23 | |


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=40): r2 battle -1 (con 98%); r3 battle -2 (con 92%); r4 battle -3 (con 85%); r5 elite -5 (con 72%); r5 battle -4 (con 62%); r6 boss -8 (con 42%); r8 battle -1 (con 40%); r9 battle -1 (con 38%); r9 elite -2 (con 32%); r11 battle -2 (con 28%); r15 elite -2 (con 22%); r18 boss -6 (con 8%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 17.87 +-3.75 | 17.69 +-2.41 | 17.69 +-2.41 | 13.25 +-3.38 | 6.51 +-1.11 | 0.40 +-0.22 | 7.5 +-8.3 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 29.23 | 1.21 | 0.79 | 6.34 | 66 | 524 | 0.62 | 0.00 | 0.19 | 0.10 | 0.31 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 8 | 0 | 6 | 5 | 80 | 1.75 | 0.03 | 4.28 | 0.62 | 0.78 | 7.50 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| random_legal | 0% (0) | 100% (25) | 0% (0) | 15.3 | 7.5 | 7.5 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: random_legal 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| random_legal | 0 | 7.5% (3/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| random_legal | aqua_plant | 0.0% (0/6) |
| random_legal | beast_bird | 33.3% (2/6) |
| random_legal | mixed_dmg | 16.7% (1/6) |
| random_legal | mixed_std | 0.0% (0/6) |
| random_legal | reptile_bug | 0.0% (0/6) |
| random_legal | tank_heavy | 0.0% (0/5) |
| random_legal | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| random_legal | combo | 0.0% (0/12) |
| random_legal | greedy_axis | 7.1% (1/14) |
| random_legal | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- random_legal|battle: 3.7 luot (n=211)
- random_legal|boss: 5.8 luot (n=45)
- random_legal|elite: 4.9 luot (n=24)

## Chet theo node (chinh sach|loai row)

- random_legal|battle r11: 2
- random_legal|battle r2: 1
- random_legal|battle r3: 2
- random_legal|battle r4: 3
- random_legal|battle r5: 4
- random_legal|battle r8: 1
- random_legal|battle r9: 1
- random_legal|boss r18: 6
- random_legal|boss r6: 8
- random_legal|elite r15: 2
- random_legal|elite r5: 5
- random_legal|elite r9: 2

Tran ket > 20 luot hoac khong ket thuc: 0 / 280

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 35.0% | 5.0% | 14% | 5.0% | 100% | 50.0% (1/2) |  |
| c_dewdrop | stat | 0 | 40.0% | 17.5% | 44% | 17.5% | 100% | 14.3% (1/7) |  |
| c_elder_trunk | stat | 0 | 40.0% | 25.0% | 62% | 25.0% | 100% | 10.0% (1/10) |  |
| c_prime_chain | dice | 0 | 20.0% | 10.0% | 50% | 10.0% | 100% | 50.0% (2/4) |  |
| c_finisher | dice | 0 | 30.0% | 2.5% | 8% | 2.5% | 100% | 0.0% (0/1) |  |
| c_bastion | pos | 0 | 52.5% | 15.0% | 29% | 15.0% | 100% | 0.0% (0/6) |  |
| c_tidecaller | mana | 0 | 42.5% | 15.0% | 35% | 2.5% | 17% | 16.7% (1/6) |  |
| c_mana_pool | mana | 0 | 40.0% | 12.5% | 31% | 10.0% | 80% | 0.0% (0/5) |  |
| c_nest | rule | 0 | 25.0% | 2.5% | 10% | 2.5% | 100% | 0.0% (0/1) |  |
| c_spore_burst | rule | 0 | 35.0% | 10.0% | 29% | 10.0% | 100% | 25.0% (1/4) |  |
| c_fossil | rule | 0 | 25.0% | 2.5% | 10% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_copycat | dice | 0 | 30.0% | 7.5% | 25% | 7.5% | 100% | 0.0% (0/3) |  |
| c_meme_nametag | rule | 0 | 27.5% | 12.5% | 45% | 10.0% | 80% | 20.0% (1/5) |  |
| c_meme_jumpy | dice | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_none | run_rule | 0 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_cheap_mana | run_rule | 0 | 20.0% | 10.0% | 50% | 7.5% | 75% | 25.0% (1/4) |  |
| rule_tundra | run_rule | 0 | 15.0% | 5.0% | 33% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 5.0% | 50% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_heavy_finish | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_wasteland | run_rule | 0 | 7.5% | 7.5% | 100% | 7.5% | 100% | 0.0% (0/3) | LOW |
| rule_dry_steppe | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_rising_tide | run_rule | 0 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 15.0% | 100% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 27.5% | 15.0% | 55% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_crow | run_rule | 0 | 15.0% | 2.5% | 17% | 2.5% | 100% | 100.0% (1/1) |  |
| rule_hard_shell | run_rule | 0 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_balance | run_rule | 0 | 25.0% | 15.0% | 60% | 15.0% | 100% | 0.0% (0/6) |  |
| c_prism | dice | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_steady_hold | dice | 1 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_kindle | dice | 1 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_sonic_shield | dice | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| c_fissure | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_plague_spread | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_gatekeeper | pos | 1 | 20.0% | 10.0% | 50% | 10.0% | 100% | 0.0% (0/4) |  |
| c_thorn_growth | pos | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_thorn_shield | stat | 1 | 60.0% | 12.5% | 21% | 12.5% | 100% | 20.0% (1/5) |  |
| c_growing_shell | pos | 1 | 17.5% | 7.5% | 43% | 5.0% | 67% | 33.3% (1/3) |  |
| c_backline_glow | pos | 1 | 25.0% | 12.5% | 50% | 7.5% | 60% | 0.0% (0/5) |  |
| c_mana_ward | mana | 1 | 32.5% | 12.5% | 38% | 10.0% | 80% | 0.0% (0/5) |  |
| c_overflow | mana | 1 | 15.0% | 12.5% | 83% | 2.5% | 20% | 0.0% (0/5) |  |
| c_thorn_pact | mana | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_dry_well | quest | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 100.0% (1/1) |  |
| c_night_watch | quest | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 15.0% | 2.5% | 17% | 0.0% | 0% | 100.0% (1/1) | DEAD |
| c_collector | quest | 1 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_chimera_hunt | quest | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_golden_egg | rule | 1 | 2.5% | 2.5% | 100% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_dim_stone | rule | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_mirror_face | dice | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_sixth_die | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 0.0% | 0.0% | - | 2.5% | - | - | LOW |
| c_three_dice | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_thorn_rebound | rule | 2 | 12.5% | 7.5% | 60% | 2.5% | 33% | 0.0% (0/3) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| c_hollow_core | mana | 2 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| c_deep_current | mana | 2 | 27.5% | 7.5% | 27% | 7.5% | 100% | 33.3% (1/3) |  |
| c_blood_sign | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_loop | rule | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_cascade | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sacrifice | rule | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 55.0% (22/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_elder_trunk: 10.0% (1/10)

Bottom 10:
- c_elder_trunk: 10.0% (1/10)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
