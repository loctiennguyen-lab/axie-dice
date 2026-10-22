# Sim balance expert_a_mana_mine_1000

Runs: 40, wall 67.4s (1.68s/run).

## Muc tieu (Short A0)

- expert 15-25%: 17.5% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 40 | 100.0 | 17.5 +-11.8 | 32.5 | 4.9 | 10.6 | 28.18 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.0% | 0.0% |
| expert | h_gambler | 12.5% | 0.0% |
| expert | h_mana_mine | 17.5% | 5.0% |
| expert | h_kin | 7.5% | 2.5% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.40 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r3 battle -1 (con 98%); r5 elite -2 (con 92%); r6 boss -4 (con 82%); r8 battle -1 (con 80%); r9 elite -3 (con 72%); r10 battle -1 (con 70%); r11 battle -2 (con 65%); r12 boss -11 (con 38%); r14 battle -1 (con 35%); r15 elite -3 (con 28%); r17 battle -1 (con 25%); r18 boss -3 (con 18%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 27.43 +-3.71 | 21.28 +-1.93 | 28.73 +-3.19 | 21.18 +-3.61 | 5.02 +-0.70 | 0.62 +-0.16 | 17.5 +-11.9 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 32.30 | 1.79 | 1.49 | 4.82 | 83 | 269 | 0.59 | 0.00 | 0.11 | 0.21 | 0.88 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 6 | 22 | 24 | 34 | 6.50 | 1.73 | 22.02 | 3.50 | 8.20 | 9.18 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (140) | 0% (0) | 35.2 | 25.7 | 15.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 17.5% (7/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 33.3% (2/6) |
| expert | beast_bird | 16.7% (1/6) |
| expert | mixed_dmg | 33.3% (2/6) |
| expert | mixed_std | 16.7% (1/6) |
| expert | reptile_bug | 16.7% (1/6) |
| expert | tank_heavy | 0.0% (0/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 8.3% (1/12) |
| expert | greedy_axis | 14.3% (2/14) |
| expert | random | 28.6% (4/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=281)
- expert|boss: 5.1 luot (n=73)
- expert|elite: 3.9 luot (n=35)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r14: 1
- expert|battle r17: 1
- expert|battle r3: 1
- expert|battle r8: 1
- expert|boss r12: 11
- expert|boss r18: 3
- expert|boss r6: 4
- expert|elite r15: 3
- expert|elite r5: 2
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 389

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 45.0% | 17.5% | 39% | 17.5% | 100% | 14.3% (1/7) |  |
| c_dewdrop | stat | 0 | 37.5% | 22.5% | 60% | 22.5% | 100% | 11.1% (1/9) |  |
| c_elder_trunk | stat | 0 | 52.5% | 15.0% | 29% | 15.0% | 100% | 16.7% (1/6) |  |
| c_prime_chain | dice | 0 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_finisher | dice | 0 | 22.5% | 5.0% | 22% | 5.0% | 100% | 50.0% (1/2) |  |
| c_bastion | pos | 0 | 57.5% | 12.5% | 22% | 12.5% | 100% | 60.0% (3/5) |  |
| c_tidecaller | mana | 0 | 62.5% | 32.5% | 52% | 12.5% | 38% | 7.7% (1/13) |  |
| c_mana_pool | mana | 0 | 55.0% | 27.5% | 50% | 27.5% | 100% | 18.2% (2/11) |  |
| c_nest | rule | 0 | 42.5% | 10.0% | 24% | 10.0% | 100% | 25.0% (1/4) |  |
| c_spore_burst | rule | 0 | 42.5% | 20.0% | 47% | 20.0% | 100% | 37.5% (3/8) |  |
| c_fossil | rule | 0 | 17.5% | 10.0% | 57% | 5.0% | 50% | 0.0% (0/4) |  |
| c_meme_copycat | dice | 0 | 20.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_meme_nametag | rule | 0 | 30.0% | 12.5% | 42% | 10.0% | 80% | 40.0% (2/5) |  |
| c_meme_jumpy | dice | 0 | 32.5% | 2.5% | 8% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 5.0% | 5.0% | 100% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_tundra | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 15.0% | 12.5% | 83% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_dry_steppe | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_old_forest | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 50.0% (2/4) |  |
| rule_crow | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_hard_shell | run_rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_balance | run_rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 100.0% (1/1) | DEAD |
| c_steady_hold | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_sonic_shield | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_fissure | dice | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_field_medic | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_gatekeeper | pos | 1 | 12.5% | 10.0% | 80% | 10.0% | 100% | 50.0% (2/4) |  |
| c_thorn_growth | pos | 1 | 17.5% | 7.5% | 43% | 7.5% | 100% | 33.3% (1/3) |  |
| c_thorn_shield | stat | 1 | 87.5% | 20.0% | 23% | 20.0% | 100% | 25.0% (2/8) |  |
| c_growing_shell | pos | 1 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_backline_glow | pos | 1 | 32.5% | 12.5% | 38% | 12.5% | 100% | 20.0% (1/5) |  |
| c_mana_ward | mana | 1 | 42.5% | 15.0% | 35% | 10.0% | 67% | 16.7% (1/6) |  |
| c_overflow | mana | 1 | 40.0% | 20.0% | 50% | 10.0% | 50% | 12.5% (1/8) |  |
| c_thorn_pact | mana | 1 | 35.0% | 17.5% | 50% | 17.5% | 100% | 14.3% (1/7) |  |
| c_dry_well | quest | 1 | 25.0% | 2.5% | 10% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 25.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 30.0% | 5.0% | 17% | 5.0% | 100% | 50.0% (1/2) |  |
| c_chimera_hunt | quest | 1 | 20.0% | 5.0% | 25% | 2.5% | 50% | 50.0% (1/2) |  |
| c_golden_egg | rule | 1 | 5.0% | 5.0% | 100% | 2.5% | 50% | 50.0% (1/2) | LOW |
| c_dim_stone | rule | 1 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sixth_die | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_three_dice | dice | 2 | 10.0% | 2.5% | 25% | 5.0% | 100% | 0.0% (0/1) |  |
| c_concord | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_living_wall | pos | 2 | 22.5% | 15.0% | 67% | 15.0% | 100% | 33.3% (2/6) |  |
| c_thorn_rebound | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_open_ranks | pos | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| c_hollow_core | mana | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 50.0% (1/2) |  |
| c_deep_current | mana | 2 | 37.5% | 17.5% | 47% | 12.5% | 71% | 14.3% (1/7) |  |
| c_blood_sign | rule | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_loop | rule | 2 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_cascade | rule | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_sacrifice | rule | 2 | 2.5% | 2.5% | 100% | 2.5% | 100% | 0.0% (0/1) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 72.5% (29/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 37.5% (3/8)
- c_thorn_shield: 25.0% (2/8)
- c_mana_pool: 18.2% (2/11)
- c_overflow: 12.5% (1/8)
- c_dewdrop: 11.1% (1/9)
- c_tidecaller: 7.7% (1/13)

Bottom 10:
- c_tidecaller: 7.7% (1/13)
- c_dewdrop: 11.1% (1/9)
- c_overflow: 12.5% (1/8)
- c_mana_pool: 18.2% (2/11)
- c_thorn_shield: 25.0% (2/8)
- c_spore_burst: 37.5% (3/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_mana_pool + c_tidecaller: 11.1% (1/9)
- c_mana_pool + c_tidecaller: 11.1% (1/9)
