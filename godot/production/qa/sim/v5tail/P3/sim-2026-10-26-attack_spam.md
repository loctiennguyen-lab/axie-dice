# Sim balance attack_spam

Runs: 21, wall 1.5s (0.07s/run).

## Muc tieu (Short A0)

- attack_spam <= 5%: 4.8% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_big_hand | 1 | 4.8 | 0.0 +-0.0 | 100.0 | 5.0 | 10.0 | 25.00 |
| attack_spam | a_embers | 4 | 19.0 | 25.0 +-42.4 | 0.0 | - | - | 19.04 |
| attack_spam | a_gambler | 7 | 33.3 | 0.0 +-0.0 | 42.9 | 5.0 | 18.3 | 15.61 |
| attack_spam | a_kin | 6 | 28.6 | 0.0 +-0.0 | 16.7 | 5.0 | 15.0 | 24.44 |
| attack_spam | a_mana_mine | 3 | 14.3 | 0.0 +-0.0 | 66.7 | 7.0 | 24.0 | 22.42 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 4.8% | 0.0% |
| attack_spam | h_gambler | 9.5% | 4.8% |
| attack_spam | h_mana_mine | 14.3% | 0.0% |
| attack_spam | h_kin | 9.5% | 4.8% |
| attack_spam | h_embers | 0.0% | 0.0% |
| attack_spam | h_big_hand | 0.0% | 0.0% |
| attack_spam | combos formed avg | 0.38 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=21): r5 elite -3 (con 86%); r6 boss -1 (con 81%); r9 elite -4 (con 62%); r12 boss -5 (con 38%); r18 boss -7 (con 5%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 21 | 19.32 +-3.78 | 22.41 +-3.60 | 22.41 +-3.60 | 15.95 +-4.25 | 7.14 +-1.48 | 0.61 +-0.16 | 4.8 +-9.3 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 21 | 41.43 | 0.49 | 0.28 | 5.24 | 57 | 1075 | 0.35 | 0.00 | 0.09 | 0.05 | 0.00 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 16.3 | 9.7 | 9.7 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.02; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 4.8% (1/21) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/3) |
| attack_spam | beast_bird | 0.0% (0/3) |
| attack_spam | mixed_dmg | 0.0% (0/3) |
| attack_spam | mixed_std | 33.3% (1/3) |
| attack_spam | reptile_bug | 0.0% (0/3) |
| attack_spam | tank_heavy | 0.0% (0/3) |
| attack_spam | thorn_shield | 0.0% (0/3) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 0.0% (0/7) |
| attack_spam | greedy_axis | 14.3% (1/7) |
| attack_spam | random | 0.0% (0/7) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=140)
- attack_spam|boss: 6.6 luot (n=39)
- attack_spam|elite: 5.3 luot (n=24)

## Chet theo node (chinh sach|loai row)

- attack_spam|boss r12: 5
- attack_spam|boss r18: 7
- attack_spam|boss r6: 1
- attack_spam|elite r5: 3
- attack_spam|elite r9: 4

Tran ket > 20 luot hoac khong ket thuc: 0 / 203

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 61.9% | 4.8% | 8% | 4.8% | 100% | 0.0% (0/1) |  |
| c_dewdrop | stat | 0 | 47.6% | 14.3% | 30% | 14.3% | 100% | 0.0% (0/3) |  |
| c_elder_trunk | stat | 0 | 47.6% | 28.6% | 60% | 28.6% | 100% | 0.0% (0/6) |  |
| c_prime_chain | dice | 0 | 47.6% | 19.0% | 40% | 14.3% | 75% | 0.0% (0/4) |  |
| c_finisher | dice | 0 | 38.1% | 28.6% | 75% | 28.6% | 100% | 0.0% (0/6) |  |
| c_bastion | pos | 0 | 38.1% | 9.5% | 25% | 9.5% | 100% | 50.0% (1/2) |  |
| c_tidecaller | mana | 0 | 57.1% | 14.3% | 25% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| c_mana_pool | mana | 0 | 57.1% | 23.8% | 42% | 19.0% | 80% | 0.0% (0/5) |  |
| c_nest | rule | 0 | 61.9% | 9.5% | 15% | 9.5% | 100% | 0.0% (0/2) |  |
| c_spore_burst | rule | 0 | 61.9% | 14.3% | 23% | 14.3% | 100% | 0.0% (0/3) |  |
| c_fossil | rule | 0 | 28.6% | 4.8% | 17% | 4.8% | 100% | 0.0% (0/1) |  |
| c_meme_copycat | dice | 0 | 14.3% | 4.8% | 33% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_meme_nametag | rule | 0 | 38.1% | 0.0% | 0% | 0.0% | - | - |  |
| c_meme_jumpy | dice | 0 | 19.0% | 14.3% | 75% | 14.3% | 100% | 0.0% (0/3) |  |
| c_bloodline_ward | pos | 0 | 28.6% | 0.0% | 0% | 0.0% | - | - |  |
| c_smoldering | mana | 0 | 28.6% | 9.5% | 33% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_hunters_reward | dice | 0 | 19.0% | 4.8% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| rule_none | run_rule | 0 | 19.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_cheap_mana | run_rule | 0 | 9.5% | 4.8% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| rule_tundra | run_rule | 0 | 9.5% | 9.5% | 100% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_quick_beat | run_rule | 0 | 14.3% | 9.5% | 67% | 4.8% | 50% | 0.0% (0/2) |  |
| rule_starfall | run_rule | 0 | 9.5% | 9.5% | 100% | 9.5% | 100% | 0.0% (0/2) | LOW |
| rule_heavy_finish | run_rule | 0 | 14.3% | 14.3% | 100% | 14.3% | 100% | 0.0% (0/3) |  |
| rule_wasteland | run_rule | 0 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_dry_steppe | run_rule | 0 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_old_forest | run_rule | 0 | 19.0% | 14.3% | 75% | 14.3% | 100% | 0.0% (0/3) |  |
| rule_crow | run_rule | 0 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_hard_shell | run_rule | 0 | 19.0% | 9.5% | 50% | 9.5% | 100% | 50.0% (1/2) |  |
| rule_balance | run_rule | 0 | 14.3% | 9.5% | 67% | 9.5% | 100% | 0.0% (0/2) |  |
| rule_pack_alpha | run_rule | 0 | 14.3% | 9.5% | 67% | 9.5% | 100% | 0.0% (0/2) |  |
| rule_high_stakes | run_rule | 0 | 19.0% | 4.8% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_prism | dice | 1 | 4.8% | 4.8% | 100% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_steady_hold | dice | 1 | 14.3% | 4.8% | 33% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_kindle | dice | 1 | 14.3% | 0.0% | 0% | 0.0% | - | - |  |
| c_sonic_shield | dice | 1 | 14.3% | 0.0% | 0% | 0.0% | - | - |  |
| c_fissure | dice | 1 | 4.8% | 4.8% | 100% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 14.3% | 60% | 14.3% | 100% | 33.3% (1/3) |  |
| c_thorn_growth | pos | 1 | 19.0% | 4.8% | 25% | 4.8% | 100% | 0.0% (0/1) |  |
| c_thorn_shield | stat | 1 | 71.4% | 14.3% | 20% | 14.3% | 100% | 0.0% (0/3) |  |
| c_growing_shell | pos | 1 | 23.8% | 19.0% | 80% | 14.3% | 75% | 0.0% (0/4) |  |
| c_backline_glow | pos | 1 | 28.6% | 19.0% | 67% | 19.0% | 100% | 25.0% (1/4) |  |
| c_mana_ward | mana | 1 | 23.8% | 9.5% | 40% | 9.5% | 100% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 38.1% | 23.8% | 62% | 4.8% | 20% | 0.0% (0/5) |  |
| c_thorn_pact | mana | 1 | 38.1% | 23.8% | 62% | 23.8% | 100% | 0.0% (0/5) |  |
| c_dry_well | quest | 1 | 23.8% | 0.0% | 0% | 0.0% | - | - |  |
| c_night_watch | quest | 1 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_key_strike | quest | 1 | 23.8% | 4.8% | 20% | 4.8% | 100% | 0.0% (0/1) |  |
| c_collector | quest | 1 | 33.3% | 4.8% | 14% | 4.8% | 100% | 0.0% (0/1) |  |
| c_chimera_hunt | quest | 1 | 19.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_golden_egg | rule | 1 | 4.8% | 4.8% | 100% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_dim_stone | rule | 1 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cache_plate | dice | 1 | 23.8% | 4.8% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_golden_thread | mana | 1 | 23.8% | 4.8% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_melting_pot | pos | 1 | 4.8% | 4.8% | 100% | 4.8% | 100% | 100.0% (1/1) | LOW |
| c_support_hand | dice | 1 | 19.0% | 9.5% | 50% | 9.5% | 100% | 0.0% (0/2) |  |
| c_cracked_glass | dice | 1 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_mirror_face | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_sixth_die | dice | 2 | 19.0% | 4.8% | 25% | 4.8% | 100% | 0.0% (0/1) |  |
| c_whittle | dice | 2 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_three_dice | dice | 2 | 19.0% | 9.5% | 50% | 9.5% | 100% | 0.0% (0/2) |  |
| c_concord | dice | 2 | 4.8% | 4.8% | 100% | 4.8% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 33.3% | 19.0% | 57% | 19.0% | 100% | 25.0% (1/4) |  |
| c_thorn_rebound | rule | 2 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_open_ranks | pos | 2 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 9.5% | 9.5% | 100% | 9.5% | 100% | 50.0% (1/2) | LOW |
| c_hollow_core | mana | 2 | 23.8% | 4.8% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_deep_current | mana | 2 | 38.1% | 23.8% | 62% | 19.0% | 80% | 0.0% (0/5) |  |
| c_blood_sign | rule | 2 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_loop | rule | 2 | 9.5% | 9.5% | 100% | 9.5% | 100% | 0.0% (0/2) | LOW |
| c_cascade | rule | 2 | 14.3% | 0.0% | 0% | 0.0% | - | - |  |
| c_sacrifice | rule | 2 | 14.3% | 0.0% | 0% | 0.0% | - | - |  |
| c_last_testament | rule | 2 | 28.6% | 9.5% | 33% | 9.5% | 100% | 0.0% (0/2) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 81.0% (17/21)

Win-rate khi co Loi (n >= 8). Top 10:

Bottom 10:

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
