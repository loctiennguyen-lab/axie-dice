# Sim balance attack_spam_1120

Runs: 40, wall 2.5s (0.06s/run).

## Muc tieu (Short A0)

- attack_spam <= 5%: 2.5% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_gambler | 16 | 40.0 | 6.2 +-11.9 | 31.2 | 4.8 | 16.0 | 16.33 |
| attack_spam | a_mana_mine | 15 | 37.5 | 0.0 +-0.0 | 6.7 | 5.0 | 9.0 | 20.33 |
| attack_spam | a_volley | 9 | 22.5 | 0.0 +-0.0 | 11.1 | 6.0 | 20.0 | 19.36 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 0.0% | 0.0% |
| attack_spam | h_gambler | 22.5% | 0.0% |
| attack_spam | h_mana_mine | 5.0% | 2.5% |
| attack_spam | h_kin | 5.0% | 0.0% |
| attack_spam | h_embers | 0.0% | 0.0% |
| attack_spam | h_big_hand | 0.0% | 0.0% |
| attack_spam | combos formed avg | 0.35 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=40): r3 battle -1 (con 98%); r4 battle -2 (con 92%); r5 elite -8 (con 72%); r6 boss -8 (con 52%); r9 elite -7 (con 35%); r11 battle -2 (con 30%); r12 boss -4 (con 20%); r13 battle -1 (con 18%); r15 elite -2 (con 12%); r16 battle -1 (con 10%); r18 boss -3 (con 2%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 16.57 +-2.35 | 16.72 +-1.19 | 16.72 +-1.19 | 11.39 +-1.98 | 6.82 +-0.92 | 0.38 +-0.11 | 2.5 +-4.9 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 32.17 | 0.66 | 0.39 | 6.10 | 58 | 924 | 0.39 | 0.00 | 0.13 | 0.14 | 0.00 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 13.6 | 10.6 | 10.6 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 2.5% (1/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/6) |
| attack_spam | beast_bird | 0.0% (0/6) |
| attack_spam | mixed_dmg | 0.0% (0/6) |
| attack_spam | mixed_std | 0.0% (0/6) |
| attack_spam | reptile_bug | 16.7% (1/6) |
| attack_spam | tank_heavy | 0.0% (0/5) |
| attack_spam | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 8.3% (1/12) |
| attack_spam | greedy_axis | 0.0% (0/14) |
| attack_spam | random | 0.0% (0/14) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.9 luot (n=224)
- attack_spam|boss: 6.4 luot (n=45)
- attack_spam|elite: 4.6 luot (n=28)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r11: 2
- attack_spam|battle r13: 1
- attack_spam|battle r16: 1
- attack_spam|battle r3: 1
- attack_spam|battle r4: 2
- attack_spam|boss r12: 4
- attack_spam|boss r18: 3
- attack_spam|boss r6: 8
- attack_spam|elite r15: 2
- attack_spam|elite r5: 8
- attack_spam|elite r9: 7

Tran ket > 20 luot hoac khong ket thuc: 0 / 297

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 50.0% | 7.5% | 15% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 40.0% | 12.5% | 31% | 12.5% | 100% | 0.0% (0/5) |  |
| c_elder_trunk | stat | 0 | 42.5% | 27.5% | 65% | 27.5% | 100% | 0.0% (0/11) |  |
| c_prime_chain | dice | 0 | 15.0% | 7.5% | 50% | 5.0% | 67% | 0.0% (0/3) |  |
| c_finisher | dice | 0 | 17.5% | 12.5% | 71% | 12.5% | 100% | 0.0% (0/5) |  |
| c_bastion | pos | 0 | 50.0% | 20.0% | 40% | 20.0% | 100% | 0.0% (0/8) |  |
| c_tidecaller | mana | 0 | 45.0% | 12.5% | 28% | 0.0% | 0% | 0.0% (0/5) | DEAD |
| c_mana_pool | mana | 0 | 42.5% | 10.0% | 24% | 10.0% | 100% | 0.0% (0/4) |  |
| c_nest | rule | 0 | 35.0% | 12.5% | 36% | 12.5% | 100% | 0.0% (0/5) |  |
| c_spore_burst | rule | 0 | 37.5% | 5.0% | 13% | 5.0% | 100% | 0.0% (0/2) |  |
| c_fossil | rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_copycat | dice | 0 | 20.0% | 7.5% | 38% | 5.0% | 67% | 0.0% (0/3) |  |
| c_meme_nametag | rule | 0 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_jumpy | dice | 0 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 15.0% | 7.5% | 50% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| rule_tundra | run_rule | 0 | 17.5% | 7.5% | 43% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_heavy_finish | run_rule | 0 | 12.5% | 12.5% | 100% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_old_forest | run_rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_hard_shell | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_balance | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_prism | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_steady_hold | dice | 1 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_kindle | dice | 1 | 7.5% | 7.5% | 100% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| c_sonic_shield | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_fissure | dice | 1 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_plague_spread | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_thorn_growth | pos | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_thorn_shield | stat | 1 | 45.0% | 22.5% | 50% | 22.5% | 100% | 0.0% (0/9) |  |
| c_growing_shell | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_backline_glow | pos | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_mana_ward | mana | 1 | 20.0% | 5.0% | 25% | 2.5% | 50% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 15.0% | 7.5% | 50% | 5.0% | 67% | 33.3% (1/3) |  |
| c_thorn_pact | mana | 1 | 17.5% | 10.0% | 57% | 10.0% | 100% | 25.0% (1/4) |  |
| c_dry_well | quest | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_night_watch | quest | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_key_strike | quest | 1 | 17.5% | 2.5% | 14% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_chimera_hunt | quest | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_golden_egg | rule | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_dim_stone | rule | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_mirror_face | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_sixth_die | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_three_dice | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_toxic_still | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_thorn_rebound | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_open_ranks | pos | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_hollow_core | mana | 2 | 20.0% | 10.0% | 50% | 7.5% | 75% | 0.0% (0/4) |  |
| c_deep_current | mana | 2 | 27.5% | 10.0% | 36% | 7.5% | 75% | 0.0% (0/4) |  |
| c_blood_sign | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_loop | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cascade | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_sacrifice | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 37.5% (15/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_thorn_shield: 0.0% (0/9)
- c_bastion: 0.0% (0/8)
- c_elder_trunk: 0.0% (0/11)

Bottom 10:
- c_elder_trunk: 0.0% (0/11)
- c_bastion: 0.0% (0/8)
- c_thorn_shield: 0.0% (0/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
