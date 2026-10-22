# Sim balance attack_spam_1040

Runs: 40, wall 2.6s (0.06s/run).

## Muc tieu (Short A0)

- attack_spam <= 5%: 15.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_gambler | 11 | 27.5 | 18.2 +-22.8 | 27.3 | 7.7 | 24.7 | 22.32 |
| attack_spam | a_mana_mine | 14 | 35.0 | 21.4 +-21.5 | 7.1 | 3.0 | 4.0 | 21.68 |
| attack_spam | a_volley | 15 | 37.5 | 6.7 +-12.6 | 6.7 | 12.0 | 26.0 | 17.41 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 0.0% | 0.0% |
| attack_spam | h_gambler | 7.5% | 0.0% |
| attack_spam | h_mana_mine | 5.0% | 0.0% |
| attack_spam | h_kin | 2.5% | 0.0% |
| attack_spam | h_embers | 0.0% | 0.0% |
| attack_spam | h_big_hand | 0.0% | 0.0% |
| attack_spam | combos formed avg | 0.15 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=40): r4 battle -2 (con 95%); r5 elite -9 (con 72%); r5 battle -1 (con 70%); r6 boss -8 (con 50%); r9 elite -6 (con 35%); r12 boss -5 (con 22%); r13 battle -1 (con 20%); r15 elite -1 (con 18%); r18 boss -1 (con 15%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 17.66 +-2.86 | 17.73 +-1.83 | 17.73 +-1.83 | 12.58 +-2.81 | 6.60 +-0.74 | 0.53 +-0.17 | 15.0 +-11.2 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 32.70 | 0.70 | 0.35 | 6.87 | 50 | 980 | 0.36 | 0.00 | 0.32 | 0.02 | 0.00 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 17.6 | 12.4 | 12.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 15.0% (6/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/6) |
| attack_spam | beast_bird | 16.7% (1/6) |
| attack_spam | mixed_dmg | 16.7% (1/6) |
| attack_spam | mixed_std | 16.7% (1/6) |
| attack_spam | reptile_bug | 16.7% (1/6) |
| attack_spam | tank_heavy | 20.0% (1/5) |
| attack_spam | thorn_shield | 20.0% (1/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 25.0% (3/12) |
| attack_spam | greedy_axis | 14.3% (2/14) |
| attack_spam | random | 7.1% (1/14) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.8 luot (n=214)
- attack_spam|boss: 6.5 luot (n=49)
- attack_spam|elite: 4.7 luot (n=39)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r13: 1
- attack_spam|battle r4: 2
- attack_spam|battle r5: 1
- attack_spam|boss r12: 5
- attack_spam|boss r18: 1
- attack_spam|boss r6: 8
- attack_spam|elite r15: 1
- attack_spam|elite r5: 9
- attack_spam|elite r9: 6

Tran ket > 20 luot hoac khong ket thuc: 0 / 302

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.0% | 12.5% | 31% | 12.5% | 100% | 20.0% (1/5) |  |
| c_dewdrop | stat | 0 | 37.5% | 12.5% | 33% | 12.5% | 100% | 20.0% (1/5) |  |
| c_elder_trunk | stat | 0 | 37.5% | 22.5% | 60% | 22.5% | 100% | 44.4% (4/9) |  |
| c_prime_chain | dice | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| c_finisher | dice | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_bastion | pos | 0 | 70.0% | 22.5% | 32% | 22.5% | 100% | 0.0% (0/9) |  |
| c_tidecaller | mana | 0 | 55.0% | 7.5% | 14% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| c_mana_pool | mana | 0 | 37.5% | 17.5% | 47% | 15.0% | 86% | 14.3% (1/7) |  |
| c_nest | rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 50.0% (2/4) |  |
| c_spore_burst | rule | 0 | 30.0% | 12.5% | 42% | 12.5% | 100% | 60.0% (3/5) |  |
| c_fossil | rule | 0 | 25.0% | 5.0% | 20% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_copycat | dice | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_nametag | rule | 0 | 30.0% | 5.0% | 17% | 5.0% | 100% | 50.0% (1/2) |  |
| c_meme_jumpy | dice | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_none | run_rule | 0 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| rule_tundra | run_rule | 0 | 10.0% | 7.5% | 75% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_quick_beat | run_rule | 0 | 7.5% | 5.0% | 67% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_starfall | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_wasteland | run_rule | 0 | 17.5% | 15.0% | 86% | 15.0% | 100% | 33.3% (2/6) |  |
| rule_dry_steppe | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 12.5% | 10.0% | 80% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_upside_down | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_old_forest | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 66.7% (2/3) |  |
| rule_crow | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_hard_shell | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| rule_balance | run_rule | 0 | 32.5% | 15.0% | 46% | 15.0% | 100% | 0.0% (0/6) |  |
| c_prism | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_steady_hold | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sonic_shield | dice | 1 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_fissure | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 7.5% | 7.5% | 100% | 7.5% | 100% | 33.3% (1/3) | LOW |
| c_plague_spread | dice | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_gatekeeper | pos | 1 | 17.5% | 10.0% | 57% | 10.0% | 100% | 50.0% (2/4) |  |
| c_thorn_growth | pos | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_thorn_shield | stat | 1 | 60.0% | 20.0% | 33% | 20.0% | 100% | 25.0% (2/8) |  |
| c_growing_shell | pos | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_backline_glow | pos | 1 | 22.5% | 7.5% | 33% | 5.0% | 67% | 33.3% (1/3) |  |
| c_mana_ward | mana | 1 | 17.5% | 2.5% | 14% | 0.0% | 0% | 100.0% (1/1) | DEAD |
| c_overflow | mana | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_pact | mana | 1 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dry_well | quest | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| c_night_watch | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 25.0% | 5.0% | 20% | 5.0% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 10.0% | 5.0% | 50% | 2.5% | 50% | 0.0% (0/2) |  |
| c_golden_egg | rule | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_dim_stone | rule | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_sixth_die | dice | 2 | 2.5% | 0.0% | 0% | 2.5% | - | - | LOW |
| c_whittle | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_three_dice | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_rebound | rule | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_open_ranks | pos | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_hollow_core | mana | 2 | 7.5% | 5.0% | 67% | 2.5% | 50% | 50.0% (1/2) | LOW |
| c_deep_current | mana | 2 | 20.0% | 5.0% | 25% | 2.5% | 50% | 0.0% (0/2) |  |
| c_blood_sign | rule | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_loop | rule | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cascade | rule | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_sacrifice | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 35.0% (14/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_elder_trunk: 44.4% (4/9)
- c_thorn_shield: 25.0% (2/8)
- c_bastion: 0.0% (0/9)

Bottom 10:
- c_bastion: 0.0% (0/9)
- c_thorn_shield: 25.0% (2/8)
- c_elder_trunk: 44.4% (4/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
