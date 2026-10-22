# Sim balance r3-a_mana_mine

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 15.0% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 80 | 100.0 | 15.0 +-7.8 | 40.0 | 6.1 | 13.2 | 28.42 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 3.8% | 0.0% |
| expert | h_gambler | 11.2% | 0.0% |
| expert | h_mana_mine | 23.8% | 10.0% |
| expert | h_kin | 6.2% | 3.8% |
| expert | h_embers | 2.5% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.53 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -2 (con 98%); r4 battle -2 (con 95%); r5 elite -7 (con 86%); r6 boss -7 (con 78%); r7 battle -1 (con 76%); r9 elite -3 (con 72%); r10 battle -1 (con 71%); r11 battle -1 (con 70%); r12 boss -21 (con 44%); r15 elite -4 (con 39%); r15 battle -1 (con 38%); r17 battle -1 (con 36%); r18 boss -17 (con 15%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 26.72 +-2.21 | 21.41 +-1.24 | 28.35 +-1.57 | 19.38 +-1.87 | 5.12 +-0.41 | 0.50 +-0.11 | 15.0 +-7.9 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 33.10 | 1.71 | 1.45 | 5.36 | 85 | 313 | 0.61 | 0.00 | 0.22 | 0.29 | 0.59 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 6 | 19 | 22 | 39 | 5.83 | 1.39 | 16.34 | 4.69 | 7.80 | 8.07 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (375) | 0% (0) | 32.5 | 25.8 | 15.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 15.0% (12/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (2/12) |
| expert | beast_bird | 8.3% (1/12) |
| expert | mixed_dmg | 16.7% (2/12) |
| expert | mixed_std | 25.0% (3/12) |
| expert | reptile_bug | 16.7% (2/12) |
| expert | tank_heavy | 0.0% (0/10) |
| expert | thorn_shield | 20.0% (2/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 12.5% (3/24) |
| expert | greedy_axis | 14.3% (4/28) |
| expert | random | 17.9% (5/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=557)
- expert|boss: 5.1 luot (n=154)
- expert|elite: 4.0 luot (n=75)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r3: 2
- expert|battle r4: 2
- expert|battle r7: 1
- expert|boss r12: 21
- expert|boss r18: 17
- expert|boss r6: 7
- expert|elite r15: 4
- expert|elite r5: 7
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 786

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 46.2% | 12.5% | 27% | 12.5% | 100% | 10.0% (1/10) |  |
| c_dewdrop | stat | 0 | 73.8% | 33.8% | 46% | 33.8% | 100% | 11.1% (3/27) |  |
| c_elder_trunk | stat | 0 | 41.2% | 12.5% | 30% | 12.5% | 100% | 10.0% (1/10) |  |
| c_prime_chain | dice | 0 | 21.2% | 3.8% | 18% | 3.8% | 100% | 0.0% (0/3) |  |
| c_finisher | dice | 0 | 16.2% | 5.0% | 31% | 5.0% | 100% | 25.0% (1/4) |  |
| c_bastion | pos | 0 | 50.0% | 6.2% | 12% | 6.2% | 100% | 0.0% (0/5) |  |
| c_tidecaller | mana | 0 | 67.5% | 26.2% | 39% | 12.5% | 48% | 23.8% (5/21) |  |
| c_mana_pool | mana | 0 | 62.5% | 31.2% | 50% | 26.2% | 84% | 28.0% (7/25) |  |
| c_nest | rule | 0 | 35.0% | 10.0% | 29% | 10.0% | 100% | 12.5% (1/8) |  |
| c_spore_burst | rule | 0 | 37.5% | 13.8% | 37% | 13.8% | 100% | 36.4% (4/11) |  |
| c_fossil | rule | 0 | 22.5% | 7.5% | 33% | 6.2% | 83% | 0.0% (0/6) |  |
| c_meme_copycat | dice | 0 | 16.2% | 2.5% | 15% | 2.5% | 100% | 50.0% (1/2) |  |
| c_meme_nametag | rule | 0 | 27.5% | 6.2% | 23% | 6.2% | 100% | 40.0% (2/5) |  |
| c_meme_jumpy | dice | 0 | 21.2% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 25.0% (1/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 14.3% (1/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 25.0% (1/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 11.1% (1/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 40.0% (2/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 42.9% (3/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 0.0% (0/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 18.2% (2/11) |  |
| c_prism | dice | 1 | 8.8% | 2.5% | 29% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| c_steady_hold | dice | 1 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 15.0% | 3.8% | 25% | 3.8% | 100% | 0.0% (0/3) |  |
| c_sonic_shield | dice | 1 | 13.8% | 7.5% | 55% | 7.5% | 100% | 33.3% (2/6) |  |
| c_fissure | dice | 1 | 10.0% | 3.8% | 38% | 3.8% | 100% | 33.3% (1/3) |  |
| c_field_medic | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 8.8% | 1.2% | 14% | 1.2% | 100% | 100.0% (1/1) | LOW |
| c_gatekeeper | pos | 1 | 16.2% | 3.8% | 23% | 3.8% | 100% | 33.3% (1/3) |  |
| c_thorn_growth | pos | 1 | 16.2% | 5.0% | 31% | 5.0% | 100% | 50.0% (2/4) |  |
| c_thorn_shield | stat | 1 | 71.2% | 17.5% | 25% | 17.5% | 100% | 21.4% (3/14) |  |
| c_growing_shell | pos | 1 | 18.8% | 2.5% | 13% | 2.5% | 100% | 0.0% (0/2) |  |
| c_backline_glow | pos | 1 | 26.2% | 12.5% | 48% | 12.5% | 100% | 30.0% (3/10) |  |
| c_mana_ward | mana | 1 | 30.0% | 8.8% | 29% | 6.2% | 71% | 28.6% (2/7) |  |
| c_overflow | mana | 1 | 62.5% | 35.0% | 56% | 27.5% | 79% | 17.9% (5/28) |  |
| c_thorn_pact | mana | 1 | 21.2% | 10.0% | 47% | 8.8% | 88% | 25.0% (2/8) |  |
| c_dry_well | quest | 1 | 25.0% | 1.2% | 5% | 1.2% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 18.8% | 2.5% | 13% | 2.5% | 100% | 50.0% (1/2) |  |
| c_key_strike | quest | 1 | 12.5% | 1.2% | 10% | 1.2% | 100% | 0.0% (0/1) |  |
| c_collector | quest | 1 | 17.5% | 6.2% | 36% | 6.2% | 100% | 0.0% (0/5) |  |
| c_chimera_hunt | quest | 1 | 23.8% | 10.0% | 42% | 6.2% | 62% | 25.0% (2/8) |  |
| c_golden_egg | rule | 1 | 6.2% | 5.0% | 80% | 1.2% | 25% | 25.0% (1/4) | LOW |
| c_dim_stone | rule | 1 | 13.8% | 1.2% | 9% | 1.2% | 100% | 100.0% (1/1) |  |
| c_mirror_face | dice | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_sixth_die | dice | 2 | 12.5% | 1.2% | 10% | 1.2% | 100% | 100.0% (1/1) |  |
| c_whittle | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 50.0% (1/2) |  |
| c_three_dice | dice | 2 | 11.2% | 0.0% | 0% | 0.0% | - | - |  |
| c_concord | dice | 2 | 5.0% | 1.2% | 25% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 25.0% (1/4) |  |
| c_thorn_rebound | rule | 2 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 16.2% | 2.5% | 15% | 2.5% | 100% | 0.0% (0/2) |  |
| c_hollow_core | mana | 2 | 21.2% | 13.8% | 65% | 10.0% | 73% | 18.2% (2/11) |  |
| c_deep_current | mana | 2 | 50.0% | 21.2% | 42% | 18.8% | 82% | 23.5% (4/17) |  |
| c_blood_sign | rule | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_loop | rule | 2 | 13.8% | 7.5% | 55% | 5.0% | 67% | 33.3% (2/6) |  |
| c_cascade | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (2/2) | LOW |
| c_sacrifice | rule | 2 | 8.8% | 3.8% | 43% | 3.8% | 100% | 33.3% (1/3) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 61.2% (49/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 36.4% (4/11)
- c_backline_glow: 30.0% (3/10)
- c_mana_pool: 28.0% (7/25)
- c_deep_current: 27.8% (5/18)
- c_thorn_pact: 25.0% (2/8)
- c_chimera_hunt: 25.0% (2/8)
- c_tidecaller: 23.8% (5/21)
- c_thorn_shield: 21.4% (3/14)
- c_hollow_core: 18.2% (2/11)
- c_overflow: 17.9% (5/28)

Bottom 10:
- c_elder_trunk: 10.0% (1/10)
- c_early_scales: 10.0% (1/10)
- c_dewdrop: 11.1% (3/27)
- c_nest: 12.5% (1/8)
- c_overflow: 17.9% (5/28)
- c_hollow_core: 18.2% (2/11)
- c_thorn_shield: 21.4% (3/14)
- c_tidecaller: 23.8% (5/21)
- c_chimera_hunt: 25.0% (2/8)
- c_thorn_pact: 25.0% (2/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_deep_current + c_mana_pool: 40.0% (4/10)
- c_mana_pool + c_overflow: 35.7% (5/14)
- c_mana_pool + c_tidecaller: 33.3% (3/9)
- c_deep_current + c_overflow: 27.3% (3/11)
- c_overflow + c_tidecaller: 25.0% (3/12)
- c_dewdrop + c_overflow: 9.1% (1/11)
- c_dewdrop + c_thorn_shield: 11.1% (1/9)
- c_dewdrop + c_early_scales: 11.1% (1/9)
- c_overflow + c_tidecaller: 25.0% (3/12)
- c_deep_current + c_overflow: 27.3% (3/11)
