# Sim balance r3-a_volley

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 10.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_volley | 80 | 100.0 | 10.0 +-6.6 | 21.2 | 7.1 | 14.2 | 30.15 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 10.0% | 1.2% |
| expert | h_gambler | 10.0% | 0.0% |
| expert | h_mana_mine | 3.8% | 0.0% |
| expert | h_kin | 7.5% | 3.8% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.33 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -2 (con 98%); r4 battle -1 (con 96%); r5 elite -8 (con 86%); r6 boss -6 (con 79%); r9 elite -11 (con 65%); r10 battle -1 (con 64%); r11 battle -1 (con 62%); r12 boss -22 (con 35%); r15 elite -6 (con 28%); r18 boss -14 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 29.21 +-2.90 | 21.57 +-1.56 | 27.81 +-2.17 | 21.09 +-2.36 | 5.02 +-0.49 | 0.52 +-0.12 | 10.0 +-6.6 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 29.15 | 1.55 | 1.23 | 5.05 | 80 | 326 | 0.64 | 0.00 | 0.21 | 0.03 | 0.67 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 20 | 23 | 38 | 4.38 | 0.93 | 14.79 | 3.64 | 4.06 | 9.74 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (291) | 0% (0) | 30.9 | 16.4 | 10.0 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 10.0% (8/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (2/12) |
| expert | beast_bird | 8.3% (1/12) |
| expert | mixed_dmg | 0.0% (0/12) |
| expert | mixed_std | 0.0% (0/12) |
| expert | reptile_bug | 8.3% (1/12) |
| expert | tank_heavy | 10.0% (1/10) |
| expert | thorn_shield | 30.0% (3/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (4/24) |
| expert | greedy_axis | 14.3% (4/28) |
| expert | random | 0.0% (0/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.5 luot (n=541)
- expert|boss: 5.0 luot (n=141)
- expert|elite: 3.8 luot (n=72)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 1
- expert|battle r3: 2
- expert|battle r4: 1
- expert|boss r12: 22
- expert|boss r18: 14
- expert|boss r6: 6
- expert|elite r15: 6
- expert|elite r5: 8
- expert|elite r9: 11

Tran ket > 20 luot hoac khong ket thuc: 0 / 754

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 46.2% | 13.8% | 30% | 13.8% | 100% | 9.1% (1/11) |  |
| c_dewdrop | stat | 0 | 47.5% | 21.2% | 45% | 21.2% | 100% | 5.9% (1/17) |  |
| c_elder_trunk | stat | 0 | 48.8% | 18.8% | 38% | 18.8% | 100% | 6.7% (1/15) |  |
| c_prime_chain | dice | 0 | 37.5% | 10.0% | 27% | 10.0% | 100% | 37.5% (3/8) |  |
| c_finisher | dice | 0 | 30.0% | 10.0% | 33% | 10.0% | 100% | 25.0% (2/8) |  |
| c_bastion | pos | 0 | 78.8% | 25.0% | 32% | 23.8% | 95% | 0.0% (0/20) |  |
| c_tidecaller | mana | 0 | 30.0% | 7.5% | 25% | 1.2% | 17% | 0.0% (0/6) |  |
| c_mana_pool | mana | 0 | 21.2% | 7.5% | 35% | 7.5% | 100% | 16.7% (1/6) |  |
| c_nest | rule | 0 | 28.8% | 11.2% | 39% | 11.2% | 100% | 33.3% (3/9) |  |
| c_spore_burst | rule | 0 | 23.8% | 6.2% | 26% | 6.2% | 100% | 40.0% (2/5) |  |
| c_fossil | rule | 0 | 16.2% | 3.8% | 23% | 2.5% | 67% | 0.0% (0/3) |  |
| c_meme_copycat | dice | 0 | 31.2% | 8.8% | 28% | 6.2% | 71% | 14.3% (1/7) |  |
| c_meme_nametag | rule | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/4) |  |
| c_meme_jumpy | dice | 0 | 31.2% | 3.8% | 12% | 3.8% | 100% | 0.0% (0/3) |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 14.3% (1/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 22.2% (2/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 0.0% (0/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 16.7% (1/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 5.0% | 57% | 28.6% (2/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 9.1% (1/11) |  |
| c_prism | dice | 1 | 12.5% | 3.8% | 30% | 1.2% | 33% | 33.3% (1/3) |  |
| c_steady_hold | dice | 1 | 12.5% | 3.8% | 30% | 3.8% | 100% | 0.0% (0/3) |  |
| c_kindle | dice | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sonic_shield | dice | 1 | 36.2% | 16.2% | 45% | 16.2% | 100% | 23.1% (3/13) |  |
| c_fissure | dice | 1 | 6.2% | 3.8% | 60% | 3.8% | 100% | 33.3% (1/3) | LOW |
| c_field_medic | dice | 1 | 3.8% | 1.2% | 33% | 1.2% | 100% | 100.0% (1/1) | LOW |
| c_plague_spread | dice | 1 | 7.5% | 3.8% | 50% | 3.8% | 100% | 0.0% (0/3) | LOW |
| c_gatekeeper | pos | 1 | 21.2% | 10.0% | 47% | 10.0% | 100% | 12.5% (1/8) |  |
| c_thorn_growth | pos | 1 | 13.8% | 3.8% | 27% | 3.8% | 100% | 0.0% (0/3) |  |
| c_thorn_shield | stat | 1 | 71.2% | 25.0% | 35% | 25.0% | 100% | 15.0% (3/20) |  |
| c_growing_shell | pos | 1 | 26.2% | 12.5% | 48% | 10.0% | 80% | 20.0% (2/10) |  |
| c_backline_glow | pos | 1 | 58.8% | 26.2% | 45% | 22.5% | 86% | 9.5% (2/21) |  |
| c_mana_ward | mana | 1 | 15.0% | 3.8% | 25% | 2.5% | 67% | 0.0% (0/3) |  |
| c_overflow | mana | 1 | 22.5% | 8.8% | 39% | 5.0% | 57% | 0.0% (0/7) |  |
| c_thorn_pact | mana | 1 | 16.2% | 6.2% | 38% | 6.2% | 100% | 0.0% (0/5) |  |
| c_dry_well | quest | 1 | 18.8% | 1.2% | 7% | 1.2% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 8.8% | 1.2% | 14% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_collector | quest | 1 | 18.8% | 2.5% | 13% | 2.5% | 100% | 0.0% (0/2) |  |
| c_chimera_hunt | quest | 1 | 18.8% | 0.0% | 0% | 0.0% | - | - |  |
| c_golden_egg | rule | 1 | 7.5% | 6.2% | 83% | 3.8% | 60% | 40.0% (2/5) | LOW |
| c_dim_stone | rule | 1 | 18.8% | 1.2% | 7% | 1.2% | 100% | 0.0% (0/1) |  |
| c_mirror_face | dice | 2 | 7.5% | 3.8% | 50% | 3.8% | 100% | 0.0% (0/3) | LOW |
| c_sixth_die | dice | 2 | 12.5% | 3.8% | 30% | 3.8% | 100% | 33.3% (1/3) |  |
| c_whittle | dice | 2 | 12.5% | 3.8% | 30% | 3.8% | 100% | 33.3% (1/3) |  |
| c_three_dice | dice | 2 | 5.0% | 0.0% | 0% | 1.2% | - | - | LOW |
| c_concord | dice | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 8.8% | 1.2% | 14% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 30.0% | 13.8% | 46% | 13.8% | 100% | 18.2% (2/11) |  |
| c_thorn_rebound | rule | 2 | 8.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_open_ranks | pos | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_descend | pos | 2 | 22.5% | 8.8% | 39% | 8.8% | 100% | 0.0% (0/7) |  |
| c_hollow_core | mana | 2 | 17.5% | 7.5% | 43% | 6.2% | 83% | 0.0% (0/6) |  |
| c_deep_current | mana | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/2) |  |
| c_blood_sign | rule | 2 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_loop | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_cascade | rule | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 100.0% (1/1) | LOW |
| c_sacrifice | rule | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 0.0% (0/1) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.5% (50/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_prime_chain: 37.5% (3/8)
- c_nest: 33.3% (3/9)
- c_finisher: 25.0% (2/8)
- c_sonic_shield: 23.1% (3/13)
- c_growing_shell: 20.0% (2/10)
- c_living_wall: 18.2% (2/11)
- c_thorn_shield: 15.0% (3/20)
- c_gatekeeper: 12.5% (1/8)
- c_backline_glow: 9.5% (2/21)
- c_early_scales: 9.1% (1/11)

Bottom 10:
- c_bastion: 0.0% (0/20)
- c_dewdrop: 5.9% (1/17)
- c_elder_trunk: 6.7% (1/15)
- c_early_scales: 9.1% (1/11)
- c_backline_glow: 9.5% (2/21)
- c_gatekeeper: 12.5% (1/8)
- c_thorn_shield: 15.0% (3/20)
- c_living_wall: 18.2% (2/11)
- c_growing_shell: 20.0% (2/10)
- c_sonic_shield: 23.1% (3/13)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_elder_trunk + c_thorn_shield: 12.5% (1/8)
- c_early_scales + c_thorn_shield: 12.5% (1/8)
- c_dewdrop + c_thorn_shield: 8.3% (1/12)
- c_dewdrop + c_thorn_shield: 8.3% (1/12)
- c_early_scales + c_thorn_shield: 12.5% (1/8)
- c_elder_trunk + c_thorn_shield: 12.5% (1/8)
