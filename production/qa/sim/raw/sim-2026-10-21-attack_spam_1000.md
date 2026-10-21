# Sim balance attack_spam_1000

Runs: 40, wall 2.6s (0.06s/run).

## Muc tieu (Short A0)

- attack_spam <= 5%: 7.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_gambler | 9 | 22.5 | 11.1 +-20.5 | 22.2 | 9.5 | 22.0 | 22.30 |
| attack_spam | a_mana_mine | 12 | 30.0 | 0.0 +-0.0 | 25.0 | 4.3 | 17.0 | 16.04 |
| attack_spam | a_volley | 19 | 47.5 | 10.5 +-13.8 | 5.3 | 5.0 | 15.0 | 19.47 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 0.0% | 0.0% |
| attack_spam | h_gambler | 7.5% | 0.0% |
| attack_spam | h_mana_mine | 7.5% | 0.0% |
| attack_spam | h_kin | 7.5% | 5.0% |
| attack_spam | h_embers | 5.0% | 2.5% |
| attack_spam | h_big_hand | 0.0% | 0.0% |
| attack_spam | combos formed avg | 0.28 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=40): r4 battle -1 (con 98%); r5 elite -7 (con 80%); r5 battle -1 (con 78%); r6 boss -12 (con 48%); r7 battle -1 (con 45%); r8 battle -1 (con 42%); r9 elite -3 (con 35%); r11 battle -1 (con 32%); r12 boss -4 (con 22%); r15 elite -3 (con 15%); r18 boss -3 (con 8%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 17.11 +-2.54 | 18.53 +-1.82 | 18.53 +-1.82 | 11.80 +-2.20 | 6.82 +-1.03 | 0.49 +-0.14 | 7.5 +-8.3 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 40 | 32.40 | 0.53 | 0.39 | 7.28 | 73 | 1370 | 0.40 | 0.00 | 0.08 | 0.05 | 0.00 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 16.0 | 10.3 | 10.3 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 7.5% (3/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/6) |
| attack_spam | beast_bird | 0.0% (0/6) |
| attack_spam | mixed_dmg | 16.7% (1/6) |
| attack_spam | mixed_std | 0.0% (0/6) |
| attack_spam | reptile_bug | 33.3% (2/6) |
| attack_spam | tank_heavy | 0.0% (0/5) |
| attack_spam | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 16.7% (2/12) |
| attack_spam | greedy_axis | 7.1% (1/14) |
| attack_spam | random | 0.0% (0/14) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.8 luot (n=217)
- attack_spam|boss: 6.5 luot (n=50)
- attack_spam|elite: 5.0 luot (n=32)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r11: 1
- attack_spam|battle r4: 1
- attack_spam|battle r5: 1
- attack_spam|battle r7: 1
- attack_spam|battle r8: 1
- attack_spam|boss r12: 4
- attack_spam|boss r18: 3
- attack_spam|boss r6: 12
- attack_spam|elite r15: 3
- attack_spam|elite r5: 7
- attack_spam|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 299

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 37.5% | 7.5% | 20% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 37.5% | 17.5% | 47% | 17.5% | 100% | 14.3% (1/7) |  |
| c_elder_trunk | stat | 0 | 55.0% | 20.0% | 36% | 20.0% | 100% | 0.0% (0/8) |  |
| c_prime_chain | dice | 0 | 20.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_finisher | dice | 0 | 20.0% | 5.0% | 25% | 5.0% | 100% | 50.0% (1/2) |  |
| c_bastion | pos | 0 | 57.5% | 25.0% | 43% | 25.0% | 100% | 10.0% (1/10) |  |
| c_tidecaller | mana | 0 | 47.5% | 17.5% | 37% | 0.0% | 0% | 0.0% (0/7) | DEAD |
| c_mana_pool | mana | 0 | 37.5% | 15.0% | 40% | 15.0% | 100% | 0.0% (0/6) |  |
| c_nest | rule | 0 | 37.5% | 15.0% | 40% | 15.0% | 100% | 16.7% (1/6) |  |
| c_spore_burst | rule | 0 | 27.5% | 7.5% | 27% | 7.5% | 100% | 33.3% (1/3) |  |
| c_fossil | rule | 0 | 20.0% | 2.5% | 12% | 2.5% | 100% | 100.0% (1/1) |  |
| c_meme_copycat | dice | 0 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_nametag | rule | 0 | 22.5% | 12.5% | 56% | 10.0% | 80% | 0.0% (0/5) |  |
| c_meme_jumpy | dice | 0 | 25.0% | 2.5% | 10% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 5.0% | 5.0% | 100% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 15.0% | 7.5% | 50% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_tundra | run_rule | 0 | 7.5% | 5.0% | 67% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_quick_beat | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 15.0% | 12.5% | 83% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_dry_steppe | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (1/1) | LOW |
| rule_upside_down | run_rule | 0 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_old_forest | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_crow | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_hard_shell | run_rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_balance | run_rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_steady_hold | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_sonic_shield | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_fissure | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_growth | pos | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_thorn_shield | stat | 1 | 65.0% | 12.5% | 19% | 12.5% | 100% | 0.0% (0/5) |  |
| c_growing_shell | pos | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| c_backline_glow | pos | 1 | 35.0% | 15.0% | 43% | 15.0% | 100% | 16.7% (1/6) |  |
| c_mana_ward | mana | 1 | 20.0% | 10.0% | 50% | 5.0% | 50% | 0.0% (0/4) |  |
| c_overflow | mana | 1 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| c_thorn_pact | mana | 1 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dry_well | quest | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_night_watch | quest | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 17.5% | 2.5% | 14% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_golden_egg | rule | 1 | 7.5% | 7.5% | 100% | 2.5% | 33% | 33.3% (1/3) | LOW |
| c_dim_stone | rule | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sixth_die | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_three_dice | dice | 2 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_concord | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_thorn_rebound | rule | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_open_ranks | pos | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_hollow_core | mana | 2 | 17.5% | 7.5% | 43% | 2.5% | 33% | 0.0% (0/3) |  |
| c_deep_current | mana | 2 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_blood_sign | rule | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_loop | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 0% | 0.0% (0/1) | LOW DEAD |
| c_cascade | rule | 2 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_sacrifice | rule | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 47.5% (19/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_bastion: 10.0% (1/10)
- c_elder_trunk: 0.0% (0/8)

Bottom 10:
- c_elder_trunk: 0.0% (0/8)
- c_bastion: 10.0% (1/10)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
