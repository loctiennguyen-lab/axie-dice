# Sim balance a_mana_mine

Runs: 126, wall 196.7s (1.56s/run).

## Muc tieu (Short A0)

- expert 15-25%: 17.5% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 126 | 100.0 | 17.5 +-6.6 | 57.9 | 4.7 | 9.3 | 26.36 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 4.0% | 0.0% |
| expert | h_gambler | 13.5% | 0.8% |
| expert | h_mana_mine | 30.2% | 6.3% |
| expert | h_kin | 7.1% | 5.6% |
| expert | h_embers | 3.2% | 1.6% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.64 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -4 (con 97%); r5 elite -5 (con 93%); r6 boss -14 (con 82%); r7 battle -1 (con 81%); r8 battle -1 (con 80%); r9 elite -9 (con 73%); r9 battle -1 (con 72%); r11 battle -2 (con 71%); r12 boss -31 (con 46%); r14 battle -1 (con 45%); r15 elite -11 (con 37%); r18 boss -24 (con 17%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 25.69 +-1.93 | 21.59 +-1.19 | 29.84 +-1.80 | 20.63 +-1.93 | 5.57 +-0.38 | 0.50 +-0.09 | 17.5 +-6.7 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 33.52 | 1.78 | 1.58 | 4.93 | 89 | 277 | 0.66 | 0.00 | 0.22 | 0.28 | 0.62 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 6 | 21 | 22 | 37 | 6.68 | 1.46 | 20.63 | 5.83 | 8.06 | 8.79 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (735) | 0% (0) | 32.7 | 27.1 | 17.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 17.5% (22/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 27.8% (5/18) |
| expert | mixed_dmg | 11.1% (2/18) |
| expert | mixed_std | 11.1% (2/18) |
| expert | reptile_bug | 11.1% (2/18) |
| expert | tank_heavy | 38.9% (7/18) |
| expert | thorn_shield | 16.7% (3/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 21.4% (9/42) |
| expert | greedy_axis | 14.3% (6/42) |
| expert | random | 16.7% (7/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=891)
- expert|boss: 5.5 luot (n=252)
- expert|elite: 4.3 luot (n=127)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r14: 1
- expert|battle r4: 4
- expert|battle r7: 1
- expert|battle r8: 1
- expert|battle r9: 1
- expert|boss r12: 31
- expert|boss r18: 24
- expert|boss r6: 14
- expert|elite r15: 11
- expert|elite r5: 5
- expert|elite r9: 9

Tran ket > 20 luot hoac khong ket thuc: 0 / 1270

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 54.8% | 18.3% | 33% | 18.3% | 100% | 17.4% (4/23) |  |
| c_dewdrop | stat | 0 | 88.9% | 50.0% | 56% | 50.0% | 100% | 22.2% (14/63) |  |
| c_elder_trunk | stat | 0 | 58.7% | 23.0% | 39% | 23.0% | 100% | 20.7% (6/29) |  |
| c_prime_chain | dice | 0 | 26.2% | 7.9% | 30% | 7.9% | 100% | 10.0% (1/10) |  |
| c_finisher | dice | 0 | 31.0% | 7.9% | 26% | 7.9% | 100% | 20.0% (2/10) |  |
| c_bastion | pos | 0 | 49.2% | 10.3% | 21% | 9.5% | 92% | 15.4% (2/13) |  |
| c_tidecaller | mana | 0 | 73.8% | 34.9% | 47% | 24.6% | 70% | 11.4% (5/44) |  |
| c_mana_pool | mana | 0 | 73.8% | 36.5% | 49% | 33.3% | 91% | 19.6% (9/46) |  |
| c_nest | rule | 0 | 51.6% | 15.9% | 31% | 15.9% | 100% | 35.0% (7/20) |  |
| c_spore_burst | rule | 0 | 44.4% | 12.7% | 29% | 12.7% | 100% | 56.2% (9/16) |  |
| c_fossil | rule | 0 | 17.5% | 4.8% | 27% | 4.0% | 83% | 50.0% (3/6) |  |
| c_meme_copycat | dice | 0 | 19.8% | 4.8% | 24% | 2.4% | 50% | 16.7% (1/6) |  |
| c_meme_nametag | rule | 0 | 52.4% | 7.9% | 15% | 7.9% | 100% | 30.0% (3/10) |  |
| c_meme_jumpy | dice | 0 | 13.5% | 1.6% | 12% | 1.6% | 100% | 0.0% (0/2) |  |
| c_bloodline_ward | pos | 0 | 35.7% | 6.3% | 18% | 1.6% | 25% | 25.0% (2/8) |  |
| c_smoldering | mana | 0 | 39.7% | 9.5% | 24% | 2.4% | 25% | 8.3% (1/12) |  |
| c_hunters_reward | dice | 0 | 26.2% | 2.4% | 9% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 0.0% (0/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 6.3% | 100% | 12.5% (1/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 14.3% (1/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 22.2% (2/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 38.5% (5/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 25.0% (5/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 14.3% (2/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 16.7% (1/6) | LOW |
| c_prism | dice | 1 | 8.7% | 2.4% | 27% | 1.6% | 67% | 33.3% (1/3) | LOW |
| c_steady_hold | dice | 1 | 9.5% | 2.4% | 25% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_kindle | dice | 1 | 9.5% | 3.2% | 33% | 3.2% | 100% | 75.0% (3/4) | LOW |
| c_sonic_shield | dice | 1 | 16.7% | 5.6% | 33% | 4.8% | 86% | 42.9% (3/7) |  |
| c_fissure | dice | 1 | 6.3% | 2.4% | 38% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_field_medic | dice | 1 | 12.7% | 0.8% | 6% | 0.8% | 100% | 0.0% (0/1) |  |
| c_plague_spread | dice | 1 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 17.5% | 5.6% | 32% | 5.6% | 100% | 57.1% (4/7) |  |
| c_thorn_growth | pos | 1 | 19.8% | 1.6% | 8% | 0.8% | 50% | 50.0% (1/2) |  |
| c_thorn_shield | stat | 1 | 77.0% | 22.2% | 29% | 21.4% | 96% | 14.3% (4/28) |  |
| c_growing_shell | pos | 1 | 21.4% | 4.8% | 22% | 4.8% | 100% | 50.0% (3/6) |  |
| c_backline_glow | pos | 1 | 28.6% | 9.5% | 33% | 7.1% | 75% | 33.3% (4/12) |  |
| c_mana_ward | mana | 1 | 33.3% | 11.1% | 33% | 10.3% | 93% | 14.3% (2/14) |  |
| c_overflow | mana | 1 | 75.4% | 43.7% | 58% | 31.7% | 73% | 20.0% (11/55) |  |
| c_thorn_pact | mana | 1 | 28.6% | 16.7% | 58% | 16.7% | 100% | 14.3% (3/21) |  |
| c_dry_well | quest | 1 | 27.0% | 3.2% | 12% | 3.2% | 100% | 0.0% (0/4) |  |
| c_night_watch | quest | 1 | 25.4% | 4.0% | 16% | 4.0% | 100% | 0.0% (0/5) |  |
| c_key_strike | quest | 1 | 23.0% | 5.6% | 24% | 4.8% | 86% | 14.3% (1/7) |  |
| c_collector | quest | 1 | 34.9% | 7.9% | 23% | 7.9% | 100% | 10.0% (1/10) |  |
| c_chimera_hunt | quest | 1 | 29.4% | 7.1% | 24% | 4.0% | 56% | 0.0% (0/9) |  |
| c_golden_egg | rule | 1 | 7.1% | 5.6% | 78% | 4.8% | 86% | 42.9% (3/7) | LOW |
| c_dim_stone | rule | 1 | 13.5% | 4.8% | 35% | 4.8% | 100% | 50.0% (3/6) |  |
| c_cache_plate | dice | 1 | 8.7% | 1.6% | 18% | 0.8% | 50% | 0.0% (0/2) | LOW |
| c_golden_thread | mana | 1 | 31.0% | 12.7% | 41% | 12.7% | 100% | 12.5% (2/16) |  |
| c_melting_pot | pos | 1 | 7.1% | 1.6% | 22% | 0.8% | 50% | 50.0% (1/2) | LOW |
| c_support_hand | dice | 1 | 9.5% | 1.6% | 17% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_cracked_glass | dice | 1 | 9.5% | 2.4% | 25% | 0.0% | 0% | 33.3% (1/3) | LOW DEAD |
| c_mirror_face | dice | 2 | 5.6% | 0.8% | 14% | 0.8% | 100% | 100.0% (1/1) | LOW |
| c_sixth_die | dice | 2 | 7.9% | 0.8% | 10% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 7.9% | 1.6% | 20% | 2.4% | 100% | 0.0% (0/2) | LOW |
| c_three_dice | dice | 2 | 19.8% | 6.3% | 32% | 6.3% | 100% | 0.0% (0/8) |  |
| c_concord | dice | 2 | 6.3% | 2.4% | 38% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_toxic_still | dice | 2 | 2.4% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 15.1% | 3.2% | 21% | 3.2% | 100% | 50.0% (2/4) |  |
| c_thorn_rebound | rule | 2 | 11.9% | 3.2% | 27% | 2.4% | 50% | 25.0% (1/4) |  |
| c_open_ranks | pos | 2 | 19.8% | 4.0% | 20% | 4.8% | 100% | 40.0% (2/5) |  |
| c_descend | pos | 2 | 10.3% | 1.6% | 15% | 1.6% | 100% | 50.0% (1/2) |  |
| c_hollow_core | mana | 2 | 23.8% | 13.5% | 57% | 9.5% | 71% | 41.2% (7/17) |  |
| c_deep_current | mana | 2 | 61.1% | 29.4% | 48% | 23.0% | 78% | 24.3% (9/37) |  |
| c_blood_sign | rule | 2 | 14.3% | 4.0% | 28% | 5.6% | 100% | 20.0% (1/5) |  |
| c_loop | rule | 2 | 13.5% | 7.1% | 53% | 6.3% | 89% | 22.2% (2/9) |  |
| c_cascade | rule | 2 | 10.3% | 4.0% | 38% | 4.0% | 100% | 20.0% (1/5) |  |
| c_sacrifice | rule | 2 | 9.5% | 1.6% | 17% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_last_testament | rule | 2 | 7.9% | 1.6% | 20% | 2.4% | 100% | 50.0% (1/2) | LOW |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 74.6% (94/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 56.2% (9/16)
- c_hollow_core: 41.2% (7/17)
- c_nest: 35.0% (7/20)
- c_backline_glow: 33.3% (4/12)
- c_meme_nametag: 30.0% (3/10)
- c_bloodline_ward: 25.0% (2/8)
- c_deep_current: 24.3% (9/37)
- c_loop: 22.2% (2/9)
- c_dewdrop: 22.2% (14/63)
- c_elder_trunk: 20.7% (6/29)

Bottom 10:
- c_chimera_hunt: 0.0% (0/9)
- c_three_dice: 0.0% (0/8)
- c_smoldering: 8.3% (1/12)
- c_prime_chain: 10.0% (1/10)
- c_collector: 10.0% (1/10)
- c_tidecaller: 11.4% (5/44)
- c_golden_thread: 12.5% (2/16)
- c_thorn_shield: 14.3% (4/28)
- c_mana_ward: 14.3% (2/14)
- c_thorn_pact: 14.3% (3/21)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_hollow_core + c_overflow: 60.0% (6/10)
- c_deep_current + c_dewdrop: 30.0% (3/10)
- c_nest + c_overflow: 30.0% (3/10)
- c_deep_current + c_overflow: 25.9% (7/27)
- c_deep_current + c_mana_ward: 25.0% (2/8)
- c_thorn_pact + c_tidecaller: 0.0% (0/10)
- c_deep_current + c_mana_pool: 6.7% (1/15)
- c_overflow + c_thorn_pact: 7.1% (1/14)
- c_mana_pool + c_tidecaller: 7.1% (1/14)
- c_dewdrop + c_mana_pool: 9.1% (1/11)
