# Sim balance random_legal_1120

Runs: 40, wall 3.0s (0.08s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 10.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| random_legal | a_gambler | 16 | 40.0 | 0.0 +-0.0 | 25.0 | 5.5 | 20.8 | 15.81 |
| random_legal | a_mana_mine | 15 | 37.5 | 13.3 +-17.2 | 13.3 | 8.5 | 22.0 | 17.93 |
| random_legal | a_volley | 9 | 22.5 | 22.2 +-27.2 | 0.0 | - | - | 23.44 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| random_legal | h_volley | 0.0% | 0.0% |
| random_legal | h_gambler | 10.0% | 2.5% |
| random_legal | h_mana_mine | 7.5% | 0.0% |
| random_legal | h_kin | 5.0% | 0.0% |
| random_legal | h_embers | 2.5% | 0.0% |
| random_legal | h_big_hand | 0.0% | 0.0% |
| random_legal | combos formed avg | 0.25 | |


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=40): r4 battle -1 (con 98%); r5 battle -1 (con 95%); r5 elite -9 (con 72%); r6 boss -9 (con 50%); r8 battle -1 (con 48%); r9 elite -7 (con 30%); r11 battle -1 (con 28%); r12 boss -4 (con 18%); r15 elite -2 (con 12%); r18 boss -1 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 17.11 +-2.62 | 17.08 +-1.70 | 17.08 +-1.70 | 11.84 +-2.48 | 7.83 +-1.44 | 0.56 +-0.13 | 10.0 +-9.4 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 40 | 30.98 | 1.18 | 0.88 | 8.16 | 75 | 694 | 0.64 | 0.00 | 0.15 | 0.03 | 0.35 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 7 | 1 | 6 | 6 | 81 | 1.77 | 0.05 | 5.78 | 0.70 | 0.93 | 8.82 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| random_legal | 0% (0) | 100% (28) | 0% (0) | 13.7 | 7.5 | 7.5 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: random_legal 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| random_legal | 0 | 10.0% (4/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| random_legal | aqua_plant | 0.0% (0/6) |
| random_legal | beast_bird | 16.7% (1/6) |
| random_legal | mixed_dmg | 16.7% (1/6) |
| random_legal | mixed_std | 16.7% (1/6) |
| random_legal | reptile_bug | 0.0% (0/6) |
| random_legal | tank_heavy | 20.0% (1/5) |
| random_legal | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| random_legal | combo | 8.3% (1/12) |
| random_legal | greedy_axis | 7.1% (1/14) |
| random_legal | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- random_legal|battle: 3.8 luot (n=205)
- random_legal|boss: 7.1 luot (n=45)
- random_legal|elite: 4.5 luot (n=33)

## Chet theo node (chinh sach|loai row)

- random_legal|battle r11: 1
- random_legal|battle r4: 1
- random_legal|battle r5: 1
- random_legal|battle r8: 1
- random_legal|boss r12: 4
- random_legal|boss r18: 1
- random_legal|boss r6: 9
- random_legal|elite r15: 2
- random_legal|elite r5: 9
- random_legal|elite r9: 7

Tran ket > 20 luot hoac khong ket thuc: 1 / 283

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 42.5% | 7.5% | 18% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 47.5% | 17.5% | 37% | 17.5% | 100% | 14.3% (1/7) |  |
| c_elder_trunk | stat | 0 | 37.5% | 30.0% | 80% | 30.0% | 100% | 8.3% (1/12) |  |
| c_prime_chain | dice | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 22.5% | 12.5% | 56% | 12.5% | 100% | 20.0% (1/5) |  |
| c_bastion | pos | 0 | 50.0% | 20.0% | 40% | 20.0% | 100% | 12.5% (1/8) |  |
| c_tidecaller | mana | 0 | 52.5% | 15.0% | 29% | 2.5% | 17% | 16.7% (1/6) |  |
| c_mana_pool | mana | 0 | 45.0% | 12.5% | 28% | 7.5% | 60% | 20.0% (1/5) |  |
| c_nest | rule | 0 | 37.5% | 10.0% | 27% | 10.0% | 100% | 0.0% (0/4) |  |
| c_spore_burst | rule | 0 | 27.5% | 7.5% | 27% | 7.5% | 100% | 66.7% (2/3) |  |
| c_fossil | rule | 0 | 17.5% | 5.0% | 29% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_copycat | dice | 0 | 20.0% | 5.0% | 25% | 2.5% | 50% | 50.0% (1/2) |  |
| c_meme_nametag | rule | 0 | 30.0% | 5.0% | 17% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_jumpy | dice | 0 | 20.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 15.0% | 7.5% | 50% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_tundra | run_rule | 0 | 17.5% | 7.5% | 43% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_heavy_finish | run_rule | 0 | 12.5% | 12.5% | 100% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_old_forest | run_rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 10.0% | 5.0% | 50% | 2.5% | 50% | 0.0% (0/2) |  |
| rule_hard_shell | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_balance | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_prism | dice | 1 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_steady_hold | dice | 1 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_kindle | dice | 1 | 10.0% | 7.5% | 75% | 2.5% | 33% | 0.0% (0/3) |  |
| c_sonic_shield | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_fissure | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_field_medic | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_growth | pos | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_shield | stat | 1 | 50.0% | 12.5% | 25% | 12.5% | 100% | 0.0% (0/5) |  |
| c_growing_shell | pos | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_backline_glow | pos | 1 | 22.5% | 7.5% | 33% | 7.5% | 100% | 33.3% (1/3) |  |
| c_mana_ward | mana | 1 | 12.5% | 5.0% | 40% | 2.5% | 50% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 20.0% | 10.0% | 50% | 2.5% | 25% | 25.0% (1/4) |  |
| c_thorn_pact | mana | 1 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_dry_well | quest | 1 | 15.0% | 2.5% | 17% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_collector | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_chimera_hunt | quest | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_golden_egg | rule | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_dim_stone | rule | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_mirror_face | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_sixth_die | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_three_dice | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_concord | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_thorn_rebound | rule | 2 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_open_ranks | pos | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_descend | pos | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_hollow_core | mana | 2 | 17.5% | 5.0% | 29% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_deep_current | mana | 2 | 15.0% | 10.0% | 67% | 7.5% | 75% | 25.0% (1/4) |  |
| c_blood_sign | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_loop | rule | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_cascade | rule | 2 | 5.0% | 5.0% | 100% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_sacrifice | rule | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 47.5% (19/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_bastion: 12.5% (1/8)
- c_elder_trunk: 8.3% (1/12)

Bottom 10:
- c_elder_trunk: 8.3% (1/12)
- c_bastion: 12.5% (1/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
