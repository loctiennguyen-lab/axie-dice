# Sim balance r1-a_mana_mine

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 16.2% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 80 | 100.0 | 16.2 +-8.1 | 37.5 | 6.3 | 14.1 | 27.62 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 1.2% | 0.0% |
| expert | h_gambler | 10.0% | 1.2% |
| expert | h_mana_mine | 13.8% | 5.0% |
| expert | h_kin | 6.2% | 2.5% |
| expert | h_embers | 1.2% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.35 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -1 (con 99%); r4 battle -2 (con 96%); r5 elite -6 (con 89%); r6 boss -8 (con 79%); r7 battle -2 (con 76%); r9 battle -1 (con 75%); r9 elite -4 (con 70%); r10 battle -1 (con 69%); r11 battle -1 (con 68%); r12 boss -21 (con 41%); r15 elite -6 (con 34%); r17 battle -1 (con 32%); r18 boss -13 (con 16%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 26.37 +-2.19 | 21.44 +-1.31 | 28.39 +-1.81 | 19.65 +-1.95 | 5.07 +-0.37 | 0.49 +-0.11 | 16.2 +-8.1 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 33.50 | 1.70 | 1.41 | 5.47 | 83 | 321 | 0.60 | 0.00 | 0.21 | 0.28 | 0.61 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 6 | 19 | 24 | 38 | 5.78 | 1.45 | 17.04 | 4.50 | 8.29 | 8.64 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (360) | 0% (0) | 33.5 | 26.7 | 16.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 16.2% (13/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (2/12) |
| expert | beast_bird | 8.3% (1/12) |
| expert | mixed_dmg | 25.0% (3/12) |
| expert | mixed_std | 33.3% (4/12) |
| expert | reptile_bug | 16.7% (2/12) |
| expert | tank_heavy | 0.0% (0/10) |
| expert | thorn_shield | 10.0% (1/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 8.3% (2/24) |
| expert | greedy_axis | 21.4% (6/28) |
| expert | random | 17.9% (5/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.9 luot (n=560)
- expert|boss: 5.1 luot (n=151)
- expert|elite: 3.7 luot (n=75)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 1
- expert|battle r17: 1
- expert|battle r3: 1
- expert|battle r4: 2
- expert|battle r7: 2
- expert|battle r9: 1
- expert|boss r12: 21
- expert|boss r18: 13
- expert|boss r6: 8
- expert|elite r15: 6
- expert|elite r5: 6
- expert|elite r9: 4

Tran ket > 20 luot hoac khong ket thuc: 1 / 786

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 45.0% | 11.2% | 25% | 11.2% | 100% | 33.3% (3/9) |  |
| c_dewdrop | stat | 0 | 56.2% | 31.2% | 56% | 31.2% | 100% | 16.0% (4/25) |  |
| c_elder_trunk | stat | 0 | 46.2% | 20.0% | 43% | 20.0% | 100% | 12.5% (2/16) |  |
| c_prime_chain | dice | 0 | 21.2% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 16.2% | 5.0% | 31% | 5.0% | 100% | 25.0% (1/4) |  |
| c_bastion | pos | 0 | 65.0% | 10.0% | 15% | 10.0% | 100% | 12.5% (1/8) |  |
| c_tidecaller | mana | 0 | 57.5% | 26.2% | 46% | 12.5% | 48% | 19.0% (4/21) |  |
| c_mana_pool | mana | 0 | 50.0% | 23.8% | 48% | 21.2% | 89% | 21.1% (4/19) |  |
| c_nest | rule | 0 | 36.2% | 11.2% | 31% | 11.2% | 100% | 22.2% (2/9) |  |
| c_spore_burst | rule | 0 | 35.0% | 15.0% | 43% | 15.0% | 100% | 41.7% (5/12) |  |
| c_fossil | rule | 0 | 23.8% | 6.2% | 26% | 5.0% | 80% | 0.0% (0/5) |  |
| c_meme_copycat | dice | 0 | 18.8% | 5.0% | 27% | 3.8% | 75% | 50.0% (2/4) |  |
| c_meme_nametag | rule | 0 | 31.2% | 8.8% | 28% | 7.5% | 86% | 28.6% (2/7) |  |
| c_meme_jumpy | dice | 0 | 21.2% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 25.0% (1/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 25.0% (1/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 11.1% (1/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 0.0% (0/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 60.0% (3/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 27.3% (3/11) |  |
| c_prism | dice | 1 | 3.8% | 1.2% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_steady_hold | dice | 1 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 16.2% | 5.0% | 31% | 5.0% | 100% | 25.0% (1/4) |  |
| c_sonic_shield | dice | 1 | 15.0% | 3.8% | 25% | 3.8% | 100% | 0.0% (0/3) |  |
| c_fissure | dice | 1 | 6.2% | 1.2% | 20% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 6.2% | 1.2% | 20% | 1.2% | 100% | 100.0% (1/1) | LOW |
| c_gatekeeper | pos | 1 | 15.0% | 7.5% | 50% | 7.5% | 100% | 16.7% (1/6) |  |
| c_thorn_growth | pos | 1 | 16.2% | 6.2% | 38% | 6.2% | 100% | 40.0% (2/5) |  |
| c_thorn_shield | stat | 1 | 72.5% | 17.5% | 24% | 17.5% | 100% | 28.6% (4/14) |  |
| c_growing_shell | pos | 1 | 17.5% | 1.2% | 7% | 1.2% | 100% | 0.0% (0/1) |  |
| c_backline_glow | pos | 1 | 23.8% | 11.2% | 47% | 11.2% | 100% | 33.3% (3/9) |  |
| c_mana_ward | mana | 1 | 36.2% | 10.0% | 28% | 6.2% | 62% | 37.5% (3/8) |  |
| c_overflow | mana | 1 | 51.2% | 28.8% | 56% | 18.8% | 65% | 17.4% (4/23) |  |
| c_thorn_pact | mana | 1 | 31.2% | 13.8% | 44% | 12.5% | 91% | 9.1% (1/11) |  |
| c_dry_well | quest | 1 | 21.2% | 0.0% | 0% | 0.0% | - | - |  |
| c_night_watch | quest | 1 | 20.0% | 1.2% | 6% | 1.2% | 100% | 100.0% (1/1) |  |
| c_key_strike | quest | 1 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 22.5% | 6.2% | 28% | 6.2% | 100% | 20.0% (1/5) |  |
| c_chimera_hunt | quest | 1 | 18.8% | 6.2% | 33% | 3.8% | 60% | 40.0% (2/5) |  |
| c_golden_egg | rule | 1 | 6.2% | 5.0% | 80% | 2.5% | 50% | 50.0% (2/4) | LOW |
| c_dim_stone | rule | 1 | 15.0% | 2.5% | 17% | 2.5% | 100% | 50.0% (1/2) |  |
| c_mirror_face | dice | 2 | 3.8% | 2.5% | 67% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_sixth_die | dice | 2 | 5.0% | 0.0% | 0% | 1.2% | - | - | LOW |
| c_whittle | dice | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_three_dice | dice | 2 | 10.0% | 1.2% | 12% | 1.2% | 100% | 0.0% (0/1) |  |
| c_concord | dice | 2 | 3.8% | 1.2% | 33% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 6.2% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 17.5% | 6.2% | 36% | 6.2% | 100% | 20.0% (1/5) |  |
| c_thorn_rebound | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 50.0% (1/2) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.5% | 3.8% | 30% | 3.8% | 100% | 0.0% (0/3) |  |
| c_hollow_core | mana | 2 | 18.8% | 10.0% | 53% | 10.0% | 100% | 25.0% (2/8) |  |
| c_deep_current | mana | 2 | 42.5% | 16.2% | 38% | 13.8% | 77% | 15.4% (2/13) |  |
| c_blood_sign | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_loop | rule | 2 | 12.5% | 5.0% | 40% | 5.0% | 100% | 25.0% (1/4) |  |
| c_cascade | rule | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 100.0% (2/2) | LOW |
| c_sacrifice | rule | 2 | 8.8% | 5.0% | 57% | 5.0% | 100% | 25.0% (1/4) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 63.8% (51/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 41.7% (5/12)
- c_mana_ward: 37.5% (3/8)
- c_early_scales: 33.3% (3/9)
- c_backline_glow: 33.3% (3/9)
- c_thorn_shield: 28.6% (4/14)
- c_hollow_core: 25.0% (2/8)
- c_nest: 22.2% (2/9)
- c_deep_current: 21.4% (3/14)
- c_mana_pool: 21.1% (4/19)
- c_tidecaller: 19.0% (4/21)

Bottom 10:
- c_thorn_pact: 9.1% (1/11)
- c_bastion: 12.5% (1/8)
- c_elder_trunk: 12.5% (2/16)
- c_dewdrop: 16.0% (4/25)
- c_overflow: 17.4% (4/23)
- c_tidecaller: 19.0% (4/21)
- c_mana_pool: 21.1% (4/19)
- c_deep_current: 21.4% (3/14)
- c_nest: 22.2% (2/9)
- c_hollow_core: 25.0% (2/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_mana_pool + c_overflow: 33.3% (3/9)
- c_dewdrop + c_early_scales: 25.0% (2/8)
- c_mana_pool + c_tidecaller: 25.0% (2/8)
- c_dewdrop + c_thorn_shield: 22.2% (2/9)
- c_overflow + c_tidecaller: 22.2% (2/9)
- c_dewdrop + c_overflow: 10.0% (1/10)
- c_elder_trunk + c_thorn_shield: 11.1% (1/9)
- c_dewdrop + c_elder_trunk: 14.3% (2/14)
- c_overflow + c_tidecaller: 22.2% (2/9)
- c_dewdrop + c_thorn_shield: 22.2% (2/9)
