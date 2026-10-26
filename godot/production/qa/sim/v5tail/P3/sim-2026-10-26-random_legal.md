# Sim balance random_legal

Runs: 126, wall 8.2s (0.06s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 8.7% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| random_legal | a_big_hand | 19 | 15.1 | 0.0 +-0.0 | 26.3 | 5.8 | 17.4 | 19.86 |
| random_legal | a_embers | 18 | 14.3 | 5.6 +-10.6 | 5.6 | 5.0 | 17.0 | 16.77 |
| random_legal | a_gambler | 21 | 16.7 | 14.3 +-15.0 | 42.9 | 7.0 | 24.8 | 17.74 |
| random_legal | a_kin | 25 | 19.8 | 16.0 +-14.4 | 40.0 | 5.9 | 15.4 | 21.58 |
| random_legal | a_mana_mine | 24 | 19.0 | 4.2 +-8.0 | 41.7 | 4.9 | 12.4 | 19.70 |
| random_legal | a_volley | 19 | 15.1 | 10.5 +-13.8 | 10.5 | 7.5 | 30.5 | 19.52 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| random_legal | h_volley | 4.8% | 0.0% |
| random_legal | h_gambler | 7.9% | 0.0% |
| random_legal | h_mana_mine | 7.9% | 0.8% |
| random_legal | h_kin | 15.9% | 12.7% |
| random_legal | h_embers | 3.2% | 0.8% |
| random_legal | h_big_hand | 0.0% | 0.0% |
| random_legal | combos formed avg | 0.43 | |


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=126): r4 battle -8 (con 94%); r5 elite -25 (con 74%); r5 battle -2 (con 72%); r6 boss -20 (con 56%); r7 battle -2 (con 55%); r8 battle -3 (con 52%); r9 elite -11 (con 44%); r9 battle -3 (con 41%); r10 battle -1 (con 40%); r12 boss -13 (con 30%); r13 battle -1 (con 29%); r14 battle -1 (con 29%); r15 elite -6 (con 24%); r15 battle -2 (con 22%); r18 boss -17 (con 9%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| random_legal | 126 | 17.13 +-1.61 | 19.59 +-1.18 | 19.59 +-1.18 | 13.83 +-1.61 | 7.10 +-0.63 | 0.41 +-0.09 | 8.7 +-4.9 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 126 | 31.29 | 1.57 | 0.99 | 9.28 | 63 | 592 | 0.79 | 0.00 | 0.31 | 0.11 | 0.36 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 5 | 1 | 5 | 5 | 84 | 1.44 | 0.10 | 5.48 | 0.86 | 0.85 | 8.67 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| random_legal | 0% (0) | 100% (108) | 0% (0) | 16.8 | 9.3 | 9.3 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: random_legal 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| random_legal | 0 | 8.7% (11/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| random_legal | aqua_plant | 11.1% (2/18) |
| random_legal | beast_bird | 16.7% (3/18) |
| random_legal | mixed_dmg | 5.6% (1/18) |
| random_legal | mixed_std | 5.6% (1/18) |
| random_legal | reptile_bug | 16.7% (3/18) |
| random_legal | tank_heavy | 5.6% (1/18) |
| random_legal | thorn_shield | 0.0% (0/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| random_legal | combo | 11.9% (5/42) |
| random_legal | greedy_axis | 2.4% (1/42) |
| random_legal | random | 11.9% (5/42) |


## So luot trung binh moi tran (chinh sach|loai)

- random_legal|battle: 3.2 luot (n=727)
- random_legal|boss: 6.6 luot (n=170)
- random_legal|elite: 5.1 luot (n=91)

## Chet theo node (chinh sach|loai row)

- random_legal|battle r10: 1
- random_legal|battle r13: 1
- random_legal|battle r14: 1
- random_legal|battle r15: 2
- random_legal|battle r4: 8
- random_legal|battle r5: 2
- random_legal|battle r7: 2
- random_legal|battle r8: 3
- random_legal|battle r9: 3
- random_legal|boss r12: 13
- random_legal|boss r18: 17
- random_legal|boss r6: 20
- random_legal|elite r15: 6
- random_legal|elite r5: 25
- random_legal|elite r9: 11

Tran ket > 20 luot hoac khong ket thuc: 1 / 988

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 51.6% | 11.9% | 23% | 11.9% | 100% | 6.7% (1/15) |  |
| c_dewdrop | stat | 0 | 45.2% | 19.8% | 44% | 19.8% | 100% | 8.0% (2/25) |  |
| c_elder_trunk | stat | 0 | 50.8% | 20.6% | 41% | 20.6% | 100% | 3.8% (1/26) |  |
| c_prime_chain | dice | 0 | 27.0% | 10.3% | 38% | 10.3% | 100% | 0.0% (0/13) |  |
| c_finisher | dice | 0 | 32.5% | 11.1% | 34% | 11.1% | 100% | 0.0% (0/14) |  |
| c_bastion | pos | 0 | 52.4% | 17.5% | 33% | 15.9% | 91% | 13.6% (3/22) |  |
| c_tidecaller | mana | 0 | 46.0% | 11.9% | 26% | 1.6% | 13% | 20.0% (3/15) |  |
| c_mana_pool | mana | 0 | 50.0% | 19.8% | 40% | 17.5% | 88% | 12.0% (3/25) |  |
| c_nest | rule | 0 | 50.0% | 22.2% | 44% | 22.2% | 100% | 21.4% (6/28) |  |
| c_spore_burst | rule | 0 | 45.2% | 26.2% | 58% | 26.2% | 100% | 30.3% (10/33) |  |
| c_fossil | rule | 0 | 15.9% | 1.6% | 10% | 1.6% | 100% | 0.0% (0/2) |  |
| c_meme_copycat | dice | 0 | 20.6% | 7.1% | 35% | 6.3% | 89% | 11.1% (1/9) |  |
| c_meme_nametag | rule | 0 | 41.3% | 12.7% | 31% | 12.7% | 100% | 6.2% (1/16) |  |
| c_meme_jumpy | dice | 0 | 20.6% | 4.8% | 23% | 4.8% | 100% | 0.0% (0/6) |  |
| c_bloodline_ward | pos | 0 | 37.3% | 6.3% | 17% | 0.0% | 0% | 25.0% (2/8) | DEAD |
| c_smoldering | mana | 0 | 42.1% | 11.9% | 28% | 0.0% | 0% | 6.7% (1/15) | DEAD |
| c_hunters_reward | dice | 0 | 31.7% | 7.1% | 22% | 0.8% | 11% | 0.0% (0/9) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 16.7% (1/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 0.0% | 0% | 0.0% (0/5) | LOW DEAD |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 3.2% | 50% | 0.0% (0/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 0.0% (0/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 50.0% (1/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 22.2% (2/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 7.7% (1/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 50.0% (1/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 0.0% (0/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 10.0% (2/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 7.1% (1/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.0% | 83% | 16.7% (1/6) | LOW |
| c_prism | dice | 1 | 6.3% | 4.0% | 62% | 0.8% | 20% | 0.0% (0/5) | LOW |
| c_steady_hold | dice | 1 | 5.6% | 2.4% | 43% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| c_kindle | dice | 1 | 8.7% | 2.4% | 27% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| c_sonic_shield | dice | 1 | 17.5% | 10.3% | 59% | 10.3% | 100% | 23.1% (3/13) |  |
| c_fissure | dice | 1 | 3.2% | 1.6% | 50% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_field_medic | dice | 1 | 7.9% | 2.4% | 30% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_plague_spread | dice | 1 | 3.2% | 1.6% | 50% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_gatekeeper | pos | 1 | 13.5% | 5.6% | 41% | 4.8% | 86% | 14.3% (1/7) |  |
| c_thorn_growth | pos | 1 | 15.9% | 3.2% | 20% | 3.2% | 100% | 0.0% (0/4) |  |
| c_thorn_shield | stat | 1 | 60.3% | 14.3% | 24% | 14.3% | 100% | 22.2% (4/18) |  |
| c_growing_shell | pos | 1 | 13.5% | 4.0% | 29% | 4.0% | 100% | 40.0% (2/5) |  |
| c_backline_glow | pos | 1 | 19.0% | 8.7% | 46% | 8.7% | 100% | 0.0% (0/11) |  |
| c_mana_ward | mana | 1 | 19.0% | 7.1% | 38% | 4.8% | 67% | 22.2% (2/9) |  |
| c_overflow | mana | 1 | 27.0% | 9.5% | 35% | 6.3% | 67% | 25.0% (3/12) |  |
| c_thorn_pact | mana | 1 | 27.8% | 11.9% | 43% | 11.1% | 93% | 0.0% (0/15) |  |
| c_dry_well | quest | 1 | 19.8% | 0.8% | 4% | 0.8% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 22.2% | 3.2% | 14% | 3.2% | 100% | 25.0% (1/4) |  |
| c_key_strike | quest | 1 | 22.2% | 1.6% | 7% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_collector | quest | 1 | 24.6% | 4.8% | 19% | 4.8% | 100% | 16.7% (1/6) |  |
| c_chimera_hunt | quest | 1 | 27.0% | 6.3% | 24% | 4.8% | 75% | 25.0% (2/8) |  |
| c_golden_egg | rule | 1 | 17.5% | 15.1% | 86% | 14.3% | 95% | 21.1% (4/19) |  |
| c_dim_stone | rule | 1 | 9.5% | 3.2% | 33% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_cache_plate | dice | 1 | 11.1% | 0.8% | 7% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_golden_thread | mana | 1 | 23.8% | 5.6% | 23% | 2.4% | 43% | 0.0% (0/7) |  |
| c_melting_pot | pos | 1 | 10.3% | 2.4% | 23% | 0.8% | 33% | 0.0% (0/3) |  |
| c_support_hand | dice | 1 | 9.5% | 2.4% | 25% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_cracked_glass | dice | 1 | 7.1% | 2.4% | 33% | 0.8% | 33% | 0.0% (0/3) | LOW |
| c_mirror_face | dice | 2 | 5.6% | 2.4% | 43% | 3.2% | 100% | 0.0% (0/3) | LOW |
| c_sixth_die | dice | 2 | 9.5% | 3.2% | 33% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_whittle | dice | 2 | 7.1% | 3.2% | 44% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_three_dice | dice | 2 | 15.1% | 4.8% | 32% | 4.8% | 100% | 0.0% (0/6) |  |
| c_concord | dice | 2 | 3.2% | 0.8% | 25% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 0.8% | 20% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 10.3% | 2.4% | 23% | 2.4% | 100% | 33.3% (1/3) |  |
| c_thorn_rebound | rule | 2 | 10.3% | 4.8% | 46% | 4.0% | 83% | 0.0% (0/6) |  |
| c_open_ranks | pos | 2 | 12.7% | 0.8% | 6% | 0.8% | 100% | 100.0% (1/1) |  |
| c_descend | pos | 2 | 5.6% | 1.6% | 29% | 2.4% | 100% | 0.0% (0/2) | LOW |
| c_hollow_core | mana | 2 | 19.8% | 9.5% | 48% | 4.8% | 50% | 41.7% (5/12) |  |
| c_deep_current | mana | 2 | 31.7% | 11.1% | 35% | 10.3% | 93% | 7.1% (1/14) |  |
| c_blood_sign | rule | 2 | 5.6% | 2.4% | 43% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_loop | rule | 2 | 11.1% | 6.3% | 57% | 6.3% | 100% | 12.5% (1/8) |  |
| c_cascade | rule | 2 | 6.3% | 3.2% | 50% | 4.0% | 100% | 25.0% (1/4) | LOW |
| c_sacrifice | rule | 2 | 7.9% | 4.0% | 50% | 4.8% | 100% | 20.0% (1/5) | LOW |
| c_last_testament | rule | 2 | 13.5% | 5.6% | 41% | 5.6% | 100% | 28.6% (2/7) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 73.0% (92/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_hollow_core: 41.7% (5/12)
- c_spore_burst: 30.3% (10/33)
- c_bloodline_ward: 25.0% (2/8)
- c_chimera_hunt: 25.0% (2/8)
- c_overflow: 25.0% (3/12)
- c_sonic_shield: 23.1% (3/13)
- c_thorn_shield: 22.2% (4/18)
- c_mana_ward: 22.2% (2/9)
- c_nest: 21.4% (6/28)
- c_golden_egg: 21.1% (4/19)

Bottom 10:
- c_backline_glow: 0.0% (0/11)
- c_finisher: 0.0% (0/14)
- c_prime_chain: 0.0% (0/13)
- c_thorn_pact: 0.0% (0/15)
- c_hunters_reward: 0.0% (0/9)
- c_elder_trunk: 3.8% (1/26)
- c_meme_nametag: 6.2% (1/16)
- c_early_scales: 6.7% (1/15)
- c_smoldering: 6.7% (1/15)
- c_deep_current: 7.1% (1/14)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_golden_egg + c_spore_burst: 36.4% (4/11)
- c_nest + c_spore_burst: 35.7% (5/14)
- c_golden_egg + c_nest: 21.4% (3/14)
- c_mana_pool + c_smoldering: 12.5% (1/8)
- c_early_scales + c_thorn_shield: 11.1% (1/9)
- c_deep_current + c_mana_pool: 0.0% (0/8)
- c_dewdrop + c_elder_trunk: 0.0% (0/13)
- c_early_scales + c_elder_trunk: 0.0% (0/8)
- c_mana_pool + c_tidecaller: 10.0% (1/10)
- c_early_scales + c_thorn_shield: 11.1% (1/9)
