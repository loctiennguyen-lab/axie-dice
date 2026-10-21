# Sim balance expert_a_mana_mine_1120

Runs: 40, wall 58.6s (1.47s/run).

## Muc tieu (Short A0)

- expert 15-25%: 5.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 40 | 100.0 | 5.0 +-6.8 | 27.5 | 5.0 | 10.6 | 26.50 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.0% | 0.0% |
| expert | h_gambler | 7.5% | 0.0% |
| expert | h_mana_mine | 25.0% | 7.5% |
| expert | h_kin | 5.0% | 0.0% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.42 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r5 battle -1 (con 98%); r5 elite -6 (con 82%); r6 boss -8 (con 62%); r7 battle -1 (con 60%); r8 battle -1 (con 58%); r9 elite -3 (con 50%); r11 battle -2 (con 45%); r12 boss -3 (con 38%); r15 elite -6 (con 22%); r18 boss -7 (con 5%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 24.51 +-3.32 | 19.28 +-1.72 | 26.15 +-2.39 | 17.81 +-2.87 | 5.77 +-0.79 | 0.47 +-0.16 | 5.0 +-6.8 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 29.77 | 1.59 | 1.29 | 4.54 | 81 | 286 | 0.50 | 0.00 | 0.14 | 0.16 | 0.78 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 3 | 24 | 25 | 33 | 4.95 | 0.50 | 18.05 | 3.10 | 6.90 | 9.35 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (124) | 0% (0) | 32.5 | 23.8 | 12.8 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 5.0% (2/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 0.0% (0/6) |
| expert | mixed_dmg | 0.0% (0/6) |
| expert | mixed_std | 16.7% (1/6) |
| expert | reptile_bug | 0.0% (0/6) |
| expert | tank_heavy | 0.0% (0/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 0.0% (0/12) |
| expert | greedy_axis | 7.1% (1/14) |
| expert | random | 7.1% (1/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=244)
- expert|boss: 5.3 luot (n=60)
- expert|elite: 4.2 luot (n=46)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r5: 1
- expert|battle r7: 1
- expert|battle r8: 1
- expert|boss r12: 3
- expert|boss r18: 7
- expert|boss r6: 8
- expert|elite r15: 6
- expert|elite r5: 6
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 350

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 35.0% | 5.0% | 14% | 5.0% | 100% | 0.0% (0/2) |  |
| c_dewdrop | stat | 0 | 47.5% | 17.5% | 37% | 17.5% | 100% | 0.0% (0/7) |  |
| c_elder_trunk | stat | 0 | 40.0% | 15.0% | 38% | 15.0% | 100% | 0.0% (0/6) |  |
| c_prime_chain | dice | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_bastion | pos | 0 | 42.5% | 5.0% | 12% | 5.0% | 100% | 0.0% (0/2) |  |
| c_tidecaller | mana | 0 | 50.0% | 27.5% | 55% | 10.0% | 36% | 0.0% (0/11) |  |
| c_mana_pool | mana | 0 | 45.0% | 27.5% | 61% | 20.0% | 73% | 0.0% (0/11) |  |
| c_nest | rule | 0 | 40.0% | 12.5% | 31% | 12.5% | 100% | 20.0% (1/5) |  |
| c_spore_burst | rule | 0 | 32.5% | 7.5% | 23% | 7.5% | 100% | 66.7% (2/3) |  |
| c_fossil | rule | 0 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_meme_copycat | dice | 0 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_nametag | rule | 0 | 35.0% | 7.5% | 21% | 7.5% | 100% | 33.3% (1/3) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_none | run_rule | 0 | 15.0% | 7.5% | 50% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_tundra | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_heavy_finish | run_rule | 0 | 12.5% | 12.5% | 100% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_old_forest | run_rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| rule_hard_shell | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_balance | run_rule | 0 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_prism | dice | 1 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_steady_hold | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sonic_shield | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_fissure | dice | 1 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 0.0% (0/4) |  |
| c_plague_spread | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_growth | pos | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_thorn_shield | stat | 1 | 70.0% | 17.5% | 25% | 17.5% | 100% | 0.0% (0/7) |  |
| c_growing_shell | pos | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_backline_glow | pos | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 0.0% (0/4) |  |
| c_mana_ward | mana | 1 | 22.5% | 12.5% | 56% | 10.0% | 80% | 20.0% (1/5) |  |
| c_overflow | mana | 1 | 37.5% | 22.5% | 60% | 15.0% | 67% | 11.1% (1/9) |  |
| c_thorn_pact | mana | 1 | 30.0% | 17.5% | 58% | 17.5% | 100% | 0.0% (0/7) |  |
| c_dry_well | quest | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 20.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 27.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_chimera_hunt | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_golden_egg | rule | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_dim_stone | rule | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_mirror_face | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sixth_die | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_three_dice | dice | 2 | 7.5% | 7.5% | 100% | 7.5% | 100% | 0.0% (0/3) | LOW |
| c_concord | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_rebound | rule | 2 | 12.5% | 2.5% | 20% | 5.0% | 100% | 0.0% (0/1) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_hollow_core | mana | 2 | 25.0% | 5.0% | 20% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_deep_current | mana | 2 | 37.5% | 22.5% | 60% | 12.5% | 56% | 0.0% (0/9) |  |
| c_blood_sign | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_loop | rule | 2 | 12.5% | 5.0% | 40% | 2.5% | 50% | 0.0% (0/2) |  |
| c_cascade | rule | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_sacrifice | rule | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.5% (25/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_overflow: 11.1% (1/9)
- c_deep_current: 0.0% (0/9)
- c_tidecaller: 0.0% (0/11)
- c_mana_pool: 0.0% (0/11)

Bottom 10:
- c_mana_pool: 0.0% (0/11)
- c_tidecaller: 0.0% (0/11)
- c_deep_current: 0.0% (0/9)
- c_overflow: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
