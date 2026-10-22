# Sim balance r1-a_volley

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 8.8% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_volley | 80 | 100.0 | 8.8 +-6.2 | 16.2 | 7.1 | 17.2 | 28.23 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 6.2% | 1.2% |
| expert | h_gambler | 15.0% | 0.0% |
| expert | h_mana_mine | 2.5% | 0.0% |
| expert | h_kin | 7.5% | 3.8% |
| expert | h_embers | 1.2% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.34 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -3 (con 96%); r4 battle -1 (con 95%); r5 elite -10 (con 82%); r6 boss -7 (con 74%); r7 battle -1 (con 72%); r9 battle -1 (con 71%); r9 elite -12 (con 56%); r10 battle -1 (con 55%); r11 battle -2 (con 52%); r12 boss -20 (con 28%); r15 elite -2 (con 25%); r18 boss -13 (con 9%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 26.59 +-2.20 | 20.52 +-1.37 | 26.09 +-1.76 | 19.06 +-1.97 | 5.07 +-0.46 | 0.56 +-0.11 | 8.8 +-6.2 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 27.69 | 1.49 | 1.23 | 4.06 | 83 | 273 | 0.61 | 0.00 | 0.20 | 0.02 | 0.65 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 15 | 4 | 20 | 23 | 39 | 4.45 | 0.79 | 15.07 | 3.36 | 3.88 | 8.46 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (269) | 0% (0) | 31.1 | 16.8 | 10.0 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 8.8% (7/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/12) |
| expert | beast_bird | 0.0% (0/12) |
| expert | mixed_dmg | 0.0% (0/12) |
| expert | mixed_std | 25.0% (3/12) |
| expert | reptile_bug | 16.7% (2/12) |
| expert | tank_heavy | 10.0% (1/10) |
| expert | thorn_shield | 10.0% (1/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 0.0% (0/24) |
| expert | greedy_axis | 10.7% (3/28) |
| expert | random | 14.3% (4/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=503)
- expert|boss: 5.0 luot (n=128)
- expert|elite: 3.6 luot (n=70)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r3: 3
- expert|battle r4: 1
- expert|battle r7: 1
- expert|battle r9: 1
- expert|boss r12: 20
- expert|boss r18: 13
- expert|boss r6: 7
- expert|elite r15: 2
- expert|elite r5: 10
- expert|elite r9: 12

Tran ket > 20 luot hoac khong ket thuc: 0 / 701

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.0% | 11.2% | 28% | 11.2% | 100% | 22.2% (2/9) |  |
| c_dewdrop | stat | 0 | 46.2% | 21.2% | 46% | 21.2% | 100% | 17.6% (3/17) |  |
| c_elder_trunk | stat | 0 | 46.2% | 20.0% | 43% | 20.0% | 100% | 12.5% (2/16) |  |
| c_prime_chain | dice | 0 | 27.5% | 8.8% | 32% | 8.8% | 100% | 0.0% (0/7) |  |
| c_finisher | dice | 0 | 31.2% | 6.2% | 20% | 6.2% | 100% | 20.0% (1/5) |  |
| c_bastion | pos | 0 | 73.8% | 30.0% | 41% | 27.5% | 92% | 4.2% (1/24) |  |
| c_tidecaller | mana | 0 | 43.8% | 8.8% | 20% | 5.0% | 57% | 14.3% (1/7) |  |
| c_mana_pool | mana | 0 | 25.0% | 8.8% | 35% | 8.8% | 100% | 0.0% (0/7) |  |
| c_nest | rule | 0 | 35.0% | 15.0% | 43% | 15.0% | 100% | 25.0% (3/12) |  |
| c_spore_burst | rule | 0 | 31.2% | 10.0% | 32% | 10.0% | 100% | 50.0% (4/8) |  |
| c_fossil | rule | 0 | 17.5% | 2.5% | 14% | 2.5% | 100% | 50.0% (1/2) |  |
| c_meme_copycat | dice | 0 | 30.0% | 7.5% | 25% | 5.0% | 67% | 0.0% (0/6) |  |
| c_meme_nametag | rule | 0 | 22.5% | 6.2% | 28% | 6.2% | 100% | 40.0% (2/5) |  |
| c_meme_jumpy | dice | 0 | 28.8% | 2.5% | 9% | 2.5% | 100% | 0.0% (0/2) |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 25.0% (1/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 0.0% (0/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 0.0% (0/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 0.0% (0/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 14.3% (1/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 6.2% | 71% | 14.3% (1/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 18.2% (2/11) |  |
| c_prism | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_steady_hold | dice | 1 | 10.0% | 3.8% | 38% | 3.8% | 100% | 33.3% (1/3) |  |
| c_kindle | dice | 1 | 10.0% | 3.8% | 38% | 3.8% | 100% | 33.3% (1/3) |  |
| c_sonic_shield | dice | 1 | 23.8% | 8.8% | 37% | 8.8% | 100% | 14.3% (1/7) |  |
| c_fissure | dice | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/4) | LOW |
| c_field_medic | dice | 1 | 3.8% | 1.2% | 33% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_gatekeeper | pos | 1 | 15.0% | 6.2% | 42% | 6.2% | 100% | 0.0% (0/5) |  |
| c_thorn_growth | pos | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 25.0% (1/4) |  |
| c_thorn_shield | stat | 1 | 66.2% | 27.5% | 42% | 27.5% | 100% | 18.2% (4/22) |  |
| c_growing_shell | pos | 1 | 18.8% | 7.5% | 40% | 6.2% | 83% | 0.0% (0/6) |  |
| c_backline_glow | pos | 1 | 40.0% | 15.0% | 38% | 13.8% | 92% | 0.0% (0/12) |  |
| c_mana_ward | mana | 1 | 18.8% | 2.5% | 13% | 2.5% | 100% | 0.0% (0/2) |  |
| c_overflow | mana | 1 | 20.0% | 8.8% | 44% | 6.2% | 71% | 0.0% (0/7) |  |
| c_thorn_pact | mana | 1 | 12.5% | 3.8% | 30% | 3.8% | 100% | 0.0% (0/3) |  |
| c_dry_well | quest | 1 | 16.2% | 1.2% | 8% | 1.2% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 13.8% | 1.2% | 9% | 1.2% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 16.2% | 2.5% | 15% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_collector | quest | 1 | 13.8% | 3.8% | 27% | 3.8% | 100% | 66.7% (2/3) |  |
| c_chimera_hunt | quest | 1 | 18.8% | 2.5% | 13% | 0.0% | 0% | 50.0% (1/2) | DEAD |
| c_golden_egg | rule | 1 | 7.5% | 7.5% | 100% | 5.0% | 67% | 33.3% (2/6) | LOW |
| c_dim_stone | rule | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_mirror_face | dice | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_sixth_die | dice | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_whittle | dice | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_three_dice | dice | 2 | 8.8% | 1.2% | 14% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 3.8% | 2.5% | 67% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 23.8% | 8.8% | 37% | 8.8% | 100% | 14.3% (1/7) |  |
| c_thorn_rebound | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_open_ranks | pos | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_descend | pos | 2 | 18.8% | 8.8% | 47% | 8.8% | 100% | 0.0% (0/7) |  |
| c_hollow_core | mana | 2 | 17.5% | 5.0% | 29% | 3.8% | 75% | 25.0% (1/4) |  |
| c_deep_current | mana | 2 | 20.0% | 6.2% | 31% | 5.0% | 80% | 0.0% (0/5) |  |
| c_blood_sign | rule | 2 | 11.2% | 5.0% | 44% | 5.0% | 100% | 50.0% (2/4) |  |
| c_loop | rule | 2 | 6.2% | 3.8% | 60% | 2.5% | 67% | 0.0% (0/3) | LOW |
| c_cascade | rule | 2 | 3.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sacrifice | rule | 2 | 6.2% | 2.5% | 40% | 2.5% | 100% | 0.0% (0/2) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 56.2% (45/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 50.0% (4/8)
- c_nest: 25.0% (3/12)
- c_early_scales: 22.2% (2/9)
- c_thorn_shield: 18.2% (4/22)
- c_dewdrop: 17.6% (3/17)
- c_elder_trunk: 12.5% (2/16)
- c_bastion: 4.2% (1/24)
- c_backline_glow: 0.0% (0/12)

Bottom 10:
- c_backline_glow: 0.0% (0/12)
- c_bastion: 4.2% (1/24)
- c_elder_trunk: 12.5% (2/16)
- c_dewdrop: 17.6% (3/17)
- c_thorn_shield: 18.2% (4/22)
- c_early_scales: 22.2% (2/9)
- c_nest: 25.0% (3/12)
- c_spore_burst: 50.0% (4/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_dewdrop + c_thorn_shield: 25.0% (3/12)
- c_dewdrop + c_elder_trunk: 22.2% (2/9)
- c_elder_trunk + c_thorn_shield: 16.7% (2/12)
- c_elder_trunk + c_thorn_shield: 16.7% (2/12)
- c_dewdrop + c_elder_trunk: 22.2% (2/9)
- c_dewdrop + c_thorn_shield: 25.0% (3/12)
