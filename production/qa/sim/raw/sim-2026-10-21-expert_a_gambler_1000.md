# Sim balance expert_a_gambler_1000

Runs: 40, wall 70.4s (1.76s/run).

## Muc tieu (Short A0)

- expert 15-25%: 15.0% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 40 | 100.0 | 15.0 +-11.1 | 35.0 | 6.6 | 16.5 | 26.51 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.0% | 0.0% |
| expert | h_gambler | 15.0% | 2.5% |
| expert | h_mana_mine | 2.5% | 0.0% |
| expert | h_kin | 2.5% | 2.5% |
| expert | h_embers | 2.5% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.23 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r3 battle -2 (con 95%); r4 battle -1 (con 92%); r5 elite -3 (con 85%); r5 battle -1 (con 82%); r6 boss -2 (con 78%); r8 battle -1 (con 75%); r9 battle -1 (con 72%); r9 elite -2 (con 68%); r10 battle -1 (con 65%); r12 boss -9 (con 42%); r15 elite -3 (con 35%); r16 battle -1 (con 32%); r18 boss -7 (con 15%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 24.41 +-2.82 | 19.57 +-1.78 | 25.38 +-2.65 | 19.28 +-2.75 | 5.04 +-0.52 | 0.54 +-0.11 | 15.0 +-11.2 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 34.48 | 1.46 | 1.33 | 4.97 | 91 | 341 | 0.55 | 0.00 | 0.13 | 0.03 | 0.74 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 5 | 20 | 25 | 37 | 5.60 | 1.25 | 22.57 | 4.53 | 5.80 | 9.47 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (181) | 0% (0) | 33.2 | 20.4 | 12.5 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 15.0% (6/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 33.3% (2/6) |
| expert | beast_bird | 0.0% (0/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
| expert | reptile_bug | 33.3% (2/6) |
| expert | tank_heavy | 20.0% (1/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 0.0% (0/12) |
| expert | greedy_axis | 28.6% (4/14) |
| expert | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=282)
- expert|boss: 5.0 luot (n=72)
- expert|elite: 4.9 luot (n=31)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r16: 1
- expert|battle r3: 2
- expert|battle r4: 1
- expert|battle r5: 1
- expert|battle r8: 1
- expert|battle r9: 1
- expert|boss r12: 9
- expert|boss r18: 7
- expert|boss r6: 2
- expert|elite r15: 3
- expert|elite r5: 3
- expert|elite r9: 2

Tran ket > 20 luot hoac khong ket thuc: 0 / 385

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 47.5% | 15.0% | 32% | 15.0% | 100% | 16.7% (1/6) |  |
| c_dewdrop | stat | 0 | 42.5% | 22.5% | 53% | 22.5% | 100% | 11.1% (1/9) |  |
| c_elder_trunk | stat | 0 | 62.5% | 35.0% | 56% | 35.0% | 100% | 7.1% (1/14) |  |
| c_prime_chain | dice | 0 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_finisher | dice | 0 | 27.5% | 7.5% | 27% | 7.5% | 100% | 0.0% (0/3) |  |
| c_bastion | pos | 0 | 57.5% | 20.0% | 35% | 20.0% | 100% | 37.5% (3/8) |  |
| c_tidecaller | mana | 0 | 50.0% | 7.5% | 15% | 2.5% | 33% | 0.0% (0/3) |  |
| c_mana_pool | mana | 0 | 50.0% | 17.5% | 35% | 17.5% | 100% | 0.0% (0/7) |  |
| c_nest | rule | 0 | 42.5% | 17.5% | 41% | 17.5% | 100% | 42.9% (3/7) |  |
| c_spore_burst | rule | 0 | 32.5% | 15.0% | 46% | 15.0% | 100% | 66.7% (4/6) |  |
| c_fossil | rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 50.0% (2/4) |  |
| c_meme_copycat | dice | 0 | 25.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_meme_nametag | rule | 0 | 45.0% | 17.5% | 39% | 17.5% | 100% | 28.6% (2/7) |  |
| c_meme_jumpy | dice | 0 | 22.5% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 5.0% | 100% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 66.7% (2/3) |  |
| rule_tundra | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 15.0% | 12.5% | 83% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_dry_steppe | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_old_forest | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 15.0% | 10.0% | 67% | 7.5% | 75% | 25.0% (1/4) |  |
| rule_hard_shell | run_rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_balance | run_rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 20.0% (1/5) |  |
| c_prism | dice | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_steady_hold | dice | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_kindle | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sonic_shield | dice | 1 | 2.5% | 2.5% | 100% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_fissure | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_field_medic | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_growth | pos | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_thorn_shield | stat | 1 | 77.5% | 30.0% | 39% | 30.0% | 100% | 8.3% (1/12) |  |
| c_growing_shell | pos | 1 | 25.0% | 2.5% | 10% | 2.5% | 100% | 100.0% (1/1) |  |
| c_backline_glow | pos | 1 | 25.0% | 12.5% | 50% | 12.5% | 100% | 20.0% (1/5) |  |
| c_mana_ward | mana | 1 | 32.5% | 15.0% | 46% | 12.5% | 83% | 0.0% (0/6) |  |
| c_overflow | mana | 1 | 27.5% | 10.0% | 36% | 5.0% | 50% | 0.0% (0/4) |  |
| c_thorn_pact | mana | 1 | 20.0% | 15.0% | 75% | 15.0% | 100% | 0.0% (0/6) |  |
| c_dry_well | quest | 1 | 22.5% | 2.5% | 11% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 35.0% | 2.5% | 7% | 2.5% | 100% | 100.0% (1/1) |  |
| c_key_strike | quest | 1 | 22.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 20.0% | 5.0% | 25% | 5.0% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 20.0% | 7.5% | 38% | 7.5% | 100% | 0.0% (0/3) |  |
| c_golden_egg | rule | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_dim_stone | rule | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_mirror_face | dice | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_sixth_die | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_three_dice | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 20.0% | 10.0% | 50% | 10.0% | 100% | 50.0% (2/4) |  |
| c_thorn_rebound | rule | 2 | 10.0% | 7.5% | 75% | 5.0% | 67% | 66.7% (2/3) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_hollow_core | mana | 2 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| c_deep_current | mana | 2 | 35.0% | 10.0% | 29% | 5.0% | 50% | 25.0% (1/4) |  |
| c_blood_sign | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_loop | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_cascade | rule | 2 | 17.5% | 12.5% | 71% | 12.5% | 100% | 20.0% (1/5) |  |
| c_sacrifice | rule | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 47.5% (19/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_bastion: 37.5% (3/8)
- c_dewdrop: 11.1% (1/9)
- c_thorn_shield: 8.3% (1/12)
- c_elder_trunk: 7.1% (1/14)

Bottom 10:
- c_elder_trunk: 7.1% (1/14)
- c_thorn_shield: 8.3% (1/12)
- c_dewdrop: 11.1% (1/9)
- c_bastion: 37.5% (3/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_elder_trunk + c_thorn_shield: 12.5% (1/8)
- c_elder_trunk + c_thorn_shield: 12.5% (1/8)
