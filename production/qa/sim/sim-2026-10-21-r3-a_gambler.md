# Sim balance r3-a_gambler

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 16.2% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 80 | 100.0 | 16.2 +-8.1 | 48.8 | 5.9 | 14.9 | 25.92 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 2.5% | 2.5% |
| expert | h_gambler | 23.8% | 3.8% |
| expert | h_mana_mine | 3.8% | 0.0% |
| expert | h_kin | 2.5% | 1.2% |
| expert | h_embers | 2.5% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.39 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -1 (con 99%); r4 battle -1 (con 98%); r5 elite -6 (con 90%); r5 battle -1 (con 89%); r6 boss -11 (con 75%); r9 elite -4 (con 70%); r9 battle -1 (con 69%); r11 battle -2 (con 66%); r12 boss -21 (con 40%); r15 elite -9 (con 29%); r18 boss -10 (con 16%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 24.59 +-2.13 | 19.72 +-1.30 | 25.52 +-1.47 | 18.66 +-1.83 | 5.66 +-0.51 | 0.47 +-0.13 | 16.2 +-8.1 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 35.42 | 1.37 | 1.25 | 6.03 | 92 | 442 | 0.55 | 0.00 | 0.18 | 0.03 | 0.60 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 4 | 19 | 23 | 41 | 5.24 | 1.18 | 19.36 | 4.16 | 5.16 | 9.50 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (333) | 0% (0) | 31.0 | 17.6 | 10.7 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 16.2% (13/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/12) |
| expert | beast_bird | 8.3% (1/12) |
| expert | mixed_dmg | 25.0% (3/12) |
| expert | mixed_std | 8.3% (1/12) |
| expert | reptile_bug | 41.7% (5/12) |
| expert | tank_heavy | 20.0% (2/10) |
| expert | thorn_shield | 10.0% (1/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (4/24) |
| expert | greedy_axis | 17.9% (5/28) |
| expert | random | 14.3% (4/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.1 luot (n=546)
- expert|boss: 5.5 luot (n=147)
- expert|elite: 4.5 luot (n=75)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r3: 1
- expert|battle r4: 1
- expert|battle r5: 1
- expert|battle r9: 1
- expert|boss r12: 21
- expert|boss r18: 10
- expert|boss r6: 11
- expert|elite r15: 9
- expert|elite r5: 6
- expert|elite r9: 4

Tran ket > 20 luot hoac khong ket thuc: 0 / 768

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 35.0% | 13.8% | 39% | 13.8% | 100% | 27.3% (3/11) |  |
| c_dewdrop | stat | 0 | 40.0% | 17.5% | 44% | 17.5% | 100% | 21.4% (3/14) |  |
| c_elder_trunk | stat | 0 | 82.5% | 42.5% | 52% | 42.5% | 100% | 17.6% (6/34) |  |
| c_prime_chain | dice | 0 | 22.5% | 6.2% | 28% | 6.2% | 100% | 20.0% (1/5) |  |
| c_finisher | dice | 0 | 20.0% | 7.5% | 38% | 7.5% | 100% | 0.0% (0/6) |  |
| c_bastion | pos | 0 | 51.2% | 13.8% | 27% | 13.8% | 100% | 45.5% (5/11) |  |
| c_tidecaller | mana | 0 | 63.8% | 12.5% | 20% | 7.5% | 60% | 10.0% (1/10) |  |
| c_mana_pool | mana | 0 | 53.8% | 20.0% | 37% | 17.5% | 88% | 12.5% (2/16) |  |
| c_nest | rule | 0 | 33.8% | 15.0% | 44% | 15.0% | 100% | 25.0% (3/12) |  |
| c_spore_burst | rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 50.0% (5/10) |  |
| c_fossil | rule | 0 | 22.5% | 3.8% | 17% | 3.8% | 100% | 33.3% (1/3) |  |
| c_meme_copycat | dice | 0 | 16.2% | 1.2% | 8% | 1.2% | 100% | 0.0% (0/1) |  |
| c_meme_nametag | rule | 0 | 30.0% | 8.8% | 29% | 8.8% | 100% | 42.9% (3/7) |  |
| c_meme_jumpy | dice | 0 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 33.3% (3/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 0.0% (0/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 27.3% (3/11) |  |
| c_prism | dice | 1 | 12.5% | 3.8% | 30% | 1.2% | 33% | 0.0% (0/3) |  |
| c_steady_hold | dice | 1 | 6.2% | 1.2% | 20% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_sonic_shield | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_fissure | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_field_medic | dice | 1 | 3.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 3.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 5.0% | 21% | 5.0% | 100% | 25.0% (1/4) |  |
| c_thorn_growth | pos | 1 | 10.0% | 1.2% | 12% | 1.2% | 100% | 0.0% (0/1) |  |
| c_thorn_shield | stat | 1 | 80.0% | 32.5% | 41% | 31.2% | 96% | 15.4% (4/26) |  |
| c_growing_shell | pos | 1 | 13.8% | 1.2% | 9% | 1.2% | 100% | 0.0% (0/1) |  |
| c_backline_glow | pos | 1 | 22.5% | 5.0% | 22% | 3.8% | 75% | 0.0% (0/4) |  |
| c_mana_ward | mana | 1 | 45.0% | 18.8% | 42% | 12.5% | 67% | 26.7% (4/15) |  |
| c_overflow | mana | 1 | 17.5% | 6.2% | 36% | 1.2% | 20% | 20.0% (1/5) |  |
| c_thorn_pact | mana | 1 | 40.0% | 30.0% | 75% | 30.0% | 100% | 16.7% (4/24) |  |
| c_dry_well | quest | 1 | 17.5% | 1.2% | 7% | 1.2% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 18.8% | 3.8% | 20% | 3.8% | 100% | 33.3% (1/3) |  |
| c_key_strike | quest | 1 | 13.8% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 18.8% | 2.5% | 13% | 2.5% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 21.2% | 8.8% | 41% | 3.8% | 43% | 14.3% (1/7) |  |
| c_golden_egg | rule | 1 | 2.5% | 1.2% | 50% | 0.0% | 0% | 100.0% (1/1) | LOW DEAD |
| c_dim_stone | rule | 1 | 13.8% | 1.2% | 9% | 1.2% | 100% | 100.0% (1/1) |  |
| c_mirror_face | dice | 2 | 3.8% | 1.2% | 33% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_sixth_die | dice | 2 | 10.0% | 1.2% | 12% | 1.2% | 100% | 100.0% (1/1) |  |
| c_whittle | dice | 2 | 6.2% | 1.2% | 20% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_three_dice | dice | 2 | 8.8% | 3.8% | 43% | 3.8% | 100% | 0.0% (0/3) | LOW |
| c_concord | dice | 2 | 3.8% | 1.2% | 33% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 22.5% | 8.8% | 39% | 8.8% | 100% | 0.0% (0/7) |  |
| c_thorn_rebound | rule | 2 | 13.8% | 3.8% | 27% | 2.5% | 67% | 33.3% (1/3) |  |
| c_open_ranks | pos | 2 | 1.2% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 7.5% | 2.5% | 33% | 3.8% | 100% | 0.0% (0/2) | LOW |
| c_hollow_core | mana | 2 | 31.2% | 8.8% | 28% | 7.5% | 86% | 57.1% (4/7) |  |
| c_deep_current | mana | 2 | 25.0% | 6.2% | 25% | 6.2% | 100% | 0.0% (0/5) |  |
| c_blood_sign | rule | 2 | 7.5% | 1.2% | 17% | 1.2% | 100% | 100.0% (1/1) | LOW |
| c_loop | rule | 2 | 6.2% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cascade | rule | 2 | 6.2% | 1.2% | 20% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_sacrifice | rule | 2 | 5.0% | 1.2% | 25% | 1.2% | 100% | 100.0% (1/1) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 55.0% (44/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 50.0% (5/10)
- c_bastion: 45.5% (5/11)
- c_early_scales: 27.3% (3/11)
- c_mana_ward: 26.7% (4/15)
- c_nest: 25.0% (3/12)
- c_dewdrop: 21.4% (3/14)
- c_elder_trunk: 17.6% (6/34)
- c_thorn_pact: 16.7% (4/24)
- c_thorn_shield: 15.4% (4/26)
- c_mana_pool: 12.5% (2/16)

Bottom 10:
- c_tidecaller: 10.0% (1/10)
- c_mana_pool: 12.5% (2/16)
- c_thorn_shield: 15.4% (4/26)
- c_thorn_pact: 16.7% (4/24)
- c_elder_trunk: 17.6% (6/34)
- c_dewdrop: 21.4% (3/14)
- c_nest: 25.0% (3/12)
- c_mana_ward: 26.7% (4/15)
- c_early_scales: 27.3% (3/11)
- c_bastion: 45.5% (5/11)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_dewdrop + c_early_scales: 37.5% (3/8)
- c_early_scales + c_thorn_shield: 33.3% (3/9)
- c_early_scales + c_elder_trunk: 33.3% (3/9)
- c_dewdrop + c_thorn_shield: 25.0% (3/12)
- c_dewdrop + c_elder_trunk: 23.1% (3/13)
- c_mana_ward + c_thorn_pact: 20.0% (2/10)
- c_elder_trunk + c_thorn_shield: 22.2% (4/18)
- c_elder_trunk + c_thorn_pact: 23.1% (3/13)
- c_dewdrop + c_elder_trunk: 23.1% (3/13)
- c_dewdrop + c_thorn_shield: 25.0% (3/12)
