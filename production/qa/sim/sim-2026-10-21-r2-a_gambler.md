# Sim balance r2-a_gambler

Runs: 80, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 13.8% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 80 | 100.0 | 13.8 +-7.5 | 40.0 | 6.2 | 15.9 | 25.96 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 6.2% | 3.8% |
| expert | h_gambler | 22.5% | 1.2% |
| expert | h_mana_mine | 5.0% | 0.0% |
| expert | h_kin | 6.2% | 6.2% |
| expert | h_embers | 2.5% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.46 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=80): r3 battle -3 (con 96%); r4 battle -3 (con 92%); r5 elite -5 (con 86%); r5 battle -1 (con 85%); r6 boss -10 (con 72%); r8 battle -1 (con 71%); r9 elite -6 (con 64%); r9 battle -2 (con 61%); r10 battle -1 (con 60%); r11 battle -2 (con 58%); r12 boss -15 (con 39%); r15 elite -7 (con 30%); r18 boss -13 (con 14%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 80 | 23.82 +-2.00 | 19.44 +-1.28 | 25.08 +-1.49 | 17.64 +-1.64 | 5.74 +-0.52 | 0.51 +-0.11 | 13.8 +-7.6 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 80 | 32.71 | 1.45 | 1.21 | 5.59 | 83 | 384 | 0.54 | 0.00 | 0.19 | 0.04 | 0.69 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 4 | 19 | 23 | 40 | 4.81 | 0.93 | 19.49 | 3.76 | 4.65 | 9.76 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (301) | 0% (0) | 32.1 | 17.1 | 10.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 13.8% (11/80) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/12) |
| expert | beast_bird | 0.0% (0/12) |
| expert | mixed_dmg | 16.7% (2/12) |
| expert | mixed_std | 16.7% (2/12) |
| expert | reptile_bug | 41.7% (5/12) |
| expert | tank_heavy | 10.0% (1/10) |
| expert | thorn_shield | 10.0% (1/10) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 12.5% (3/24) |
| expert | greedy_axis | 17.9% (5/28) |
| expert | random | 10.7% (3/28) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.0 luot (n=524)
- expert|boss: 5.5 luot (n=138)
- expert|elite: 4.1 luot (n=69)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r3: 3
- expert|battle r4: 3
- expert|battle r5: 1
- expert|battle r8: 1
- expert|battle r9: 2
- expert|boss r12: 15
- expert|boss r18: 13
- expert|boss r6: 10
- expert|elite r15: 7
- expert|elite r5: 5
- expert|elite r9: 6

Tran ket > 20 luot hoac khong ket thuc: 0 / 731

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 37.5% | 12.5% | 33% | 12.5% | 100% | 30.0% (3/10) |  |
| c_dewdrop | stat | 0 | 41.2% | 15.0% | 36% | 15.0% | 100% | 16.7% (2/12) |  |
| c_elder_trunk | stat | 0 | 78.8% | 38.8% | 49% | 38.8% | 100% | 16.1% (5/31) |  |
| c_prime_chain | dice | 0 | 21.2% | 6.2% | 29% | 6.2% | 100% | 0.0% (0/5) |  |
| c_finisher | dice | 0 | 21.2% | 7.5% | 35% | 7.5% | 100% | 0.0% (0/6) |  |
| c_bastion | pos | 0 | 56.2% | 17.5% | 31% | 17.5% | 100% | 21.4% (3/14) |  |
| c_tidecaller | mana | 0 | 68.8% | 13.8% | 20% | 5.0% | 36% | 9.1% (1/11) |  |
| c_mana_pool | mana | 0 | 50.0% | 20.0% | 40% | 18.8% | 94% | 6.2% (1/16) |  |
| c_nest | rule | 0 | 33.8% | 13.8% | 41% | 13.8% | 100% | 45.5% (5/11) |  |
| c_spore_burst | rule | 0 | 26.2% | 11.2% | 43% | 11.2% | 100% | 55.6% (5/9) |  |
| c_fossil | rule | 0 | 18.8% | 3.8% | 20% | 3.8% | 100% | 33.3% (1/3) |  |
| c_meme_copycat | dice | 0 | 16.2% | 1.2% | 8% | 1.2% | 100% | 0.0% (0/1) |  |
| c_meme_nametag | rule | 0 | 33.8% | 10.0% | 30% | 10.0% | 100% | 37.5% (3/8) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 3.8% | 75% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_tundra | run_rule | 0 | 8.8% | 6.2% | 71% | 6.2% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 12.5% | 8.8% | 70% | 8.8% | 100% | 14.3% (1/7) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/4) |  |
| rule_wasteland | run_rule | 0 | 15.0% | 11.2% | 75% | 11.2% | 100% | 33.3% (3/9) |  |
| rule_dry_steppe | run_rule | 0 | 15.0% | 3.8% | 25% | 3.8% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 6.2% | 62% | 6.2% | 100% | 0.0% (0/5) |  |
| rule_upside_down | run_rule | 0 | 16.2% | 7.5% | 46% | 7.5% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 18.8% | 8.8% | 47% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_crow | run_rule | 0 | 15.0% | 8.8% | 58% | 7.5% | 86% | 14.3% (1/7) |  |
| rule_hard_shell | run_rule | 0 | 22.5% | 8.8% | 39% | 8.8% | 100% | 28.6% (2/7) |  |
| rule_balance | run_rule | 0 | 30.0% | 13.8% | 46% | 13.8% | 100% | 9.1% (1/11) |  |
| c_prism | dice | 1 | 10.0% | 3.8% | 38% | 1.2% | 33% | 33.3% (1/3) |  |
| c_steady_hold | dice | 1 | 8.8% | 1.2% | 14% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 8.8% | 2.5% | 29% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_sonic_shield | dice | 1 | 13.8% | 5.0% | 36% | 5.0% | 100% | 25.0% (1/4) |  |
| c_fissure | dice | 1 | 6.2% | 2.5% | 40% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_field_medic | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_plague_spread | dice | 1 | 6.2% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 16.2% | 3.8% | 23% | 3.8% | 100% | 33.3% (1/3) |  |
| c_thorn_growth | pos | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/2) |  |
| c_thorn_shield | stat | 1 | 78.8% | 33.8% | 43% | 31.2% | 93% | 7.4% (2/27) |  |
| c_growing_shell | pos | 1 | 18.8% | 6.2% | 33% | 5.0% | 80% | 20.0% (1/5) |  |
| c_backline_glow | pos | 1 | 21.2% | 5.0% | 24% | 3.8% | 75% | 0.0% (0/4) |  |
| c_mana_ward | mana | 1 | 38.8% | 12.5% | 32% | 7.5% | 60% | 30.0% (3/10) |  |
| c_overflow | mana | 1 | 25.0% | 10.0% | 40% | 6.2% | 62% | 12.5% (1/8) |  |
| c_thorn_pact | mana | 1 | 35.0% | 20.0% | 57% | 20.0% | 100% | 18.8% (3/16) |  |
| c_dry_well | quest | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_night_watch | quest | 1 | 20.0% | 6.2% | 31% | 6.2% | 100% | 40.0% (2/5) |  |
| c_key_strike | quest | 1 | 21.2% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 16.2% | 3.8% | 23% | 3.8% | 100% | 0.0% (0/3) |  |
| c_chimera_hunt | quest | 1 | 18.8% | 6.2% | 33% | 3.8% | 60% | 0.0% (0/5) |  |
| c_golden_egg | rule | 1 | 6.2% | 5.0% | 80% | 2.5% | 50% | 50.0% (2/4) | LOW |
| c_dim_stone | rule | 1 | 11.2% | 1.2% | 11% | 1.2% | 100% | 100.0% (1/1) |  |
| c_mirror_face | dice | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_sixth_die | dice | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_whittle | dice | 2 | 7.5% | 1.2% | 17% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_three_dice | dice | 2 | 6.2% | 2.5% | 40% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_concord | dice | 2 | 2.5% | 1.2% | 50% | 1.2% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 23.8% | 8.8% | 37% | 8.8% | 100% | 0.0% (0/7) |  |
| c_thorn_rebound | rule | 2 | 11.2% | 2.5% | 22% | 2.5% | 100% | 50.0% (1/2) |  |
| c_open_ranks | pos | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 10.0% | 3.8% | 38% | 5.0% | 100% | 0.0% (0/3) |  |
| c_hollow_core | mana | 2 | 31.2% | 10.0% | 32% | 8.8% | 88% | 25.0% (2/8) |  |
| c_deep_current | mana | 2 | 22.5% | 6.2% | 28% | 6.2% | 100% | 0.0% (0/5) |  |
| c_blood_sign | rule | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 50.0% (1/2) | LOW |
| c_loop | rule | 2 | 8.8% | 2.5% | 29% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_cascade | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/2) | LOW |
| c_sacrifice | rule | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/2) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 51.2% (41/80)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 55.6% (5/9)
- c_nest: 45.5% (5/11)
- c_meme_nametag: 37.5% (3/8)
- c_early_scales: 30.0% (3/10)
- c_mana_ward: 30.0% (3/10)
- c_hollow_core: 25.0% (2/8)
- c_bastion: 21.4% (3/14)
- c_thorn_pact: 18.8% (3/16)
- c_dewdrop: 16.7% (2/12)
- c_elder_trunk: 16.1% (5/31)

Bottom 10:
- c_mana_pool: 6.2% (1/16)
- c_thorn_shield: 7.4% (2/27)
- c_tidecaller: 9.1% (1/11)
- c_overflow: 12.5% (1/8)
- c_elder_trunk: 16.1% (5/31)
- c_dewdrop: 16.7% (2/12)
- c_thorn_pact: 18.8% (3/16)
- c_bastion: 21.4% (3/14)
- c_hollow_core: 25.0% (2/8)
- c_mana_ward: 30.0% (3/10)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_early_scales + c_thorn_shield: 25.0% (2/8)
- c_elder_trunk + c_thorn_pact: 25.0% (2/8)
- c_dewdrop + c_thorn_shield: 20.0% (2/10)
- c_dewdrop + c_elder_trunk: 16.7% (2/12)
- c_elder_trunk + c_thorn_shield: 11.1% (2/18)
- c_elder_trunk + c_thorn_shield: 11.1% (2/18)
- c_dewdrop + c_elder_trunk: 16.7% (2/12)
- c_dewdrop + c_thorn_shield: 20.0% (2/10)
- c_elder_trunk + c_thorn_pact: 25.0% (2/8)
- c_early_scales + c_thorn_shield: 25.0% (2/8)
