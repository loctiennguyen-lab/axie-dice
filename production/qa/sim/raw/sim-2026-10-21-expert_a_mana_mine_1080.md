# Sim balance expert_a_mana_mine_1080

Runs: 40, wall 55.6s (1.39s/run).

## Muc tieu (Short A0)

- expert 15-25%: 5.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 40 | 100.0 | 5.0 +-6.8 | 27.5 | 6.1 | 14.6 | 26.31 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.0% | 0.0% |
| expert | h_gambler | 12.5% | 0.0% |
| expert | h_mana_mine | 15.0% | 2.5% |
| expert | h_kin | 2.5% | 2.5% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.33 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r3 battle -1 (con 98%); r4 battle -2 (con 92%); r5 elite -4 (con 82%); r6 boss -5 (con 70%); r9 elite -5 (con 58%); r12 boss -12 (con 28%); r13 battle -1 (con 25%); r15 elite -3 (con 18%); r15 battle -1 (con 15%); r18 boss -4 (con 5%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 24.34 +-2.85 | 19.57 +-1.64 | 27.03 +-2.86 | 18.34 +-2.97 | 5.15 +-0.78 | 0.69 +-0.20 | 5.0 +-6.8 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 29.15 | 1.80 | 1.70 | 4.91 | 94 | 272 | 0.81 | 0.00 | 0.07 | 0.19 | 0.74 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 12 | 4 | 22 | 22 | 39 | 5.53 | 1.25 | 18.68 | 3.67 | 7.38 | 7.97 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (147) | 0% (0) | 35.2 | 28.0 | 15.8 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 5.0% (2/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 0.0% (0/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
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

- expert|battle: 2.7 luot (n=251)
- expert|boss: 5.0 luot (n=62)
- expert|elite: 4.0 luot (n=42)

## Chet theo node (chinh sach|loai row)

- expert|battle r13: 1
- expert|battle r15: 1
- expert|battle r3: 1
- expert|battle r4: 2
- expert|boss r12: 12
- expert|boss r18: 4
- expert|boss r6: 5
- expert|elite r15: 3
- expert|elite r5: 4
- expert|elite r9: 5

Tran ket > 20 luot hoac khong ket thuc: 0 / 355

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 32.5% | 5.0% | 15% | 5.0% | 100% | 50.0% (1/2) |  |
| c_dewdrop | stat | 0 | 47.5% | 27.5% | 58% | 27.5% | 100% | 9.1% (1/11) |  |
| c_elder_trunk | stat | 0 | 50.0% | 20.0% | 40% | 20.0% | 100% | 12.5% (1/8) |  |
| c_prime_chain | dice | 0 | 30.0% | 5.0% | 17% | 5.0% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| c_bastion | pos | 0 | 67.5% | 22.5% | 33% | 22.5% | 100% | 0.0% (0/9) |  |
| c_tidecaller | mana | 0 | 45.0% | 20.0% | 44% | 10.0% | 50% | 0.0% (0/8) |  |
| c_mana_pool | mana | 0 | 42.5% | 20.0% | 47% | 17.5% | 88% | 0.0% (0/8) |  |
| c_nest | rule | 0 | 25.0% | 10.0% | 40% | 10.0% | 100% | 25.0% (1/4) |  |
| c_spore_burst | rule | 0 | 32.5% | 10.0% | 31% | 10.0% | 100% | 25.0% (1/4) |  |
| c_fossil | rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| c_meme_copycat | dice | 0 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_meme_nametag | rule | 0 | 27.5% | 10.0% | 36% | 10.0% | 100% | 25.0% (1/4) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 15.0% | 10.0% | 67% | 0.0% | 0% | 25.0% (1/4) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_tundra | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 5.0% | 40% | 2.5% | 50% | 0.0% (0/2) |  |
| rule_starfall | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_heavy_finish | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_wasteland | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_dry_steppe | run_rule | 0 | 25.0% | 17.5% | 70% | 17.5% | 100% | 0.0% (0/7) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_upside_down | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_old_forest | run_rule | 0 | 30.0% | 10.0% | 33% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_hard_shell | run_rule | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_balance | run_rule | 0 | 22.5% | 12.5% | 56% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_steady_hold | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_kindle | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sonic_shield | dice | 1 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_fissure | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_plague_spread | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 22.5% | 7.5% | 33% | 5.0% | 67% | 33.3% (1/3) |  |
| c_thorn_growth | pos | 1 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| c_thorn_shield | stat | 1 | 55.0% | 10.0% | 18% | 10.0% | 100% | 25.0% (1/4) |  |
| c_growing_shell | pos | 1 | 22.5% | 7.5% | 33% | 7.5% | 100% | 0.0% (0/3) |  |
| c_backline_glow | pos | 1 | 15.0% | 7.5% | 50% | 2.5% | 33% | 0.0% (0/3) |  |
| c_mana_ward | mana | 1 | 32.5% | 12.5% | 38% | 5.0% | 40% | 0.0% (0/5) |  |
| c_overflow | mana | 1 | 22.5% | 17.5% | 78% | 10.0% | 57% | 14.3% (1/7) |  |
| c_thorn_pact | mana | 1 | 17.5% | 7.5% | 43% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dry_well | quest | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_night_watch | quest | 1 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/3) |  |
| c_key_strike | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 27.5% | 2.5% | 9% | 2.5% | 100% | 0.0% (0/1) |  |
| c_chimera_hunt | quest | 1 | 15.0% | 5.0% | 33% | 2.5% | 50% | 0.0% (0/2) |  |
| c_golden_egg | rule | 1 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_dim_stone | rule | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_mirror_face | dice | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_sixth_die | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 17.5% | 2.5% | 14% | 2.5% | 100% | 0.0% (0/1) |  |
| c_three_dice | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_thorn_rebound | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_open_ranks | pos | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_descend | pos | 2 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_hollow_core | mana | 2 | 22.5% | 10.0% | 44% | 10.0% | 100% | 0.0% (0/4) |  |
| c_deep_current | mana | 2 | 35.0% | 17.5% | 50% | 10.0% | 57% | 14.3% (1/7) |  |
| c_blood_sign | rule | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_loop | rule | 2 | 17.5% | 10.0% | 57% | 10.0% | 100% | 25.0% (1/4) |  |
| c_cascade | rule | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sacrifice | rule | 2 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.5% (25/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_elder_trunk: 12.5% (1/8)
- c_dewdrop: 9.1% (1/11)
- c_mana_pool: 0.0% (0/8)
- c_bastion: 0.0% (0/9)
- c_tidecaller: 0.0% (0/8)

Bottom 10:
- c_tidecaller: 0.0% (0/8)
- c_bastion: 0.0% (0/9)
- c_mana_pool: 0.0% (0/8)
- c_dewdrop: 9.1% (1/11)
- c_elder_trunk: 12.5% (1/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
