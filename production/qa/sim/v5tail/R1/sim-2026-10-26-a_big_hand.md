# Sim balance a_big_hand

Runs: 126, wall 200.3s (1.59s/run).

## Muc tieu (Short A0)

- expert 15-25%: 12.7% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_big_hand | 126 | 100.0 | 12.7 +-5.8 | 42.9 | 4.9 | 9.9 | 25.95 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 2.4% | 0.0% |
| expert | h_gambler | 6.3% | 0.0% |
| expert | h_mana_mine | 5.6% | 0.8% |
| expert | h_kin | 7.1% | 4.8% |
| expert | h_embers | 11.9% | 1.6% |
| expert | h_big_hand | 9.5% | 4.0% |
| expert | combos formed avg | 0.49 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -5 (con 96%); r5 elite -8 (con 90%); r6 boss -12 (con 80%); r8 battle -2 (con 79%); r9 elite -14 (con 67%); r11 battle -2 (con 66%); r12 boss -30 (con 42%); r15 elite -7 (con 37%); r17 battle -1 (con 36%); r18 boss -29 (con 13%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 25.16 +-1.89 | 22.33 +-1.28 | 29.61 +-1.71 | 20.20 +-1.95 | 5.29 +-0.39 | 0.62 +-0.10 | 12.7 +-5.8 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 32.31 | 1.79 | 1.01 | 9.76 | 56 | 543 | 0.58 | 0.00 | 0.33 | 0.06 | 0.82 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 15 | 5 | 23 | 12 | 45 | 4.33 | 0.87 | 19.43 | 4.10 | 1.97 | 9.63 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (517) | 0% (0) | 34.2 | 18.3 | 15.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.02; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 12.7% (16/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (3/18) |
| expert | beast_bird | 16.7% (3/18) |
| expert | mixed_dmg | 5.6% (1/18) |
| expert | mixed_std | 11.1% (2/18) |
| expert | reptile_bug | 5.6% (1/18) |
| expert | tank_heavy | 27.8% (5/18) |
| expert | thorn_shield | 5.6% (1/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 14.3% (6/42) |
| expert | greedy_axis | 11.9% (5/42) |
| expert | random | 11.9% (5/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=871)
- expert|boss: 5.2 luot (n=241)
- expert|elite: 4.4 luot (n=122)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r17: 1
- expert|battle r4: 5
- expert|battle r8: 2
- expert|boss r12: 30
- expert|boss r18: 29
- expert|boss r6: 12
- expert|elite r15: 7
- expert|elite r5: 8
- expert|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 1 / 1234

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.5% | 10.3% | 25% | 10.3% | 100% | 23.1% (3/13) |  |
| c_dewdrop | stat | 0 | 38.1% | 9.5% | 25% | 9.5% | 100% | 25.0% (3/12) |  |
| c_elder_trunk | stat | 0 | 41.3% | 13.5% | 33% | 13.5% | 100% | 17.6% (3/17) |  |
| c_prime_chain | dice | 0 | 23.0% | 10.3% | 45% | 8.7% | 85% | 15.4% (2/13) |  |
| c_finisher | dice | 0 | 68.3% | 40.5% | 59% | 40.5% | 100% | 11.8% (6/51) |  |
| c_bastion | pos | 0 | 38.1% | 11.9% | 31% | 11.9% | 100% | 33.3% (5/15) |  |
| c_tidecaller | mana | 0 | 64.3% | 15.9% | 25% | 7.9% | 50% | 5.0% (1/20) |  |
| c_mana_pool | mana | 0 | 57.1% | 15.9% | 28% | 13.5% | 85% | 10.0% (2/20) |  |
| c_nest | rule | 0 | 49.2% | 13.5% | 27% | 13.5% | 100% | 29.4% (5/17) |  |
| c_spore_burst | rule | 0 | 49.2% | 12.7% | 26% | 12.7% | 100% | 31.2% (5/16) |  |
| c_fossil | rule | 0 | 23.0% | 8.7% | 38% | 7.9% | 91% | 0.0% (0/11) |  |
| c_meme_copycat | dice | 0 | 18.3% | 4.0% | 22% | 3.2% | 80% | 20.0% (1/5) |  |
| c_meme_nametag | rule | 0 | 42.9% | 11.1% | 26% | 11.1% | 100% | 7.1% (1/14) |  |
| c_meme_jumpy | dice | 0 | 14.3% | 4.0% | 28% | 4.0% | 100% | 0.0% (0/5) |  |
| c_bloodline_ward | pos | 0 | 37.3% | 5.6% | 15% | 2.4% | 43% | 28.6% (2/7) |  |
| c_smoldering | mana | 0 | 52.4% | 11.1% | 21% | 1.6% | 14% | 0.0% (0/14) |  |
| c_hunters_reward | dice | 0 | 58.7% | 30.2% | 51% | 15.9% | 53% | 21.1% (8/38) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 33.3% (1/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 16.7% (1/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 4.8% | 75% | 0.0% (0/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 28.6% (2/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 0.0% (0/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 50.0% (2/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 7.7% (1/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 23.1% (3/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 10.0% (2/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 14.3% (2/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 16.7% (1/6) | LOW |
| c_prism | dice | 1 | 11.9% | 4.8% | 40% | 2.4% | 50% | 16.7% (1/6) |  |
| c_steady_hold | dice | 1 | 13.5% | 5.6% | 41% | 5.6% | 100% | 0.0% (0/7) |  |
| c_kindle | dice | 1 | 13.5% | 9.5% | 71% | 8.7% | 92% | 8.3% (1/12) |  |
| c_sonic_shield | dice | 1 | 15.1% | 7.1% | 47% | 6.3% | 89% | 11.1% (1/9) |  |
| c_fissure | dice | 1 | 8.7% | 4.0% | 45% | 4.0% | 100% | 20.0% (1/5) | LOW |
| c_field_medic | dice | 1 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_plague_spread | dice | 1 | 7.1% | 1.6% | 22% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| c_gatekeeper | pos | 1 | 15.1% | 4.8% | 32% | 4.8% | 100% | 33.3% (2/6) |  |
| c_thorn_growth | pos | 1 | 17.5% | 3.2% | 18% | 3.2% | 100% | 25.0% (1/4) |  |
| c_thorn_shield | stat | 1 | 66.7% | 10.3% | 15% | 10.3% | 100% | 15.4% (2/13) |  |
| c_growing_shell | pos | 1 | 23.0% | 9.5% | 41% | 7.1% | 75% | 33.3% (4/12) |  |
| c_backline_glow | pos | 1 | 26.2% | 11.1% | 42% | 10.3% | 93% | 28.6% (4/14) |  |
| c_mana_ward | mana | 1 | 22.2% | 7.9% | 36% | 5.6% | 70% | 20.0% (2/10) |  |
| c_overflow | mana | 1 | 19.8% | 6.3% | 32% | 4.0% | 62% | 12.5% (1/8) |  |
| c_thorn_pact | mana | 1 | 25.4% | 11.9% | 47% | 11.1% | 93% | 6.7% (1/15) |  |
| c_dry_well | quest | 1 | 28.6% | 3.2% | 11% | 3.2% | 100% | 25.0% (1/4) |  |
| c_night_watch | quest | 1 | 31.0% | 4.0% | 13% | 4.0% | 100% | 20.0% (1/5) |  |
| c_key_strike | quest | 1 | 19.8% | 2.4% | 12% | 0.8% | 33% | 0.0% (0/3) |  |
| c_collector | quest | 1 | 27.0% | 5.6% | 21% | 5.6% | 100% | 0.0% (0/7) |  |
| c_chimera_hunt | quest | 1 | 32.5% | 13.5% | 41% | 7.1% | 53% | 17.6% (3/17) |  |
| c_golden_egg | rule | 1 | 7.9% | 6.3% | 80% | 6.3% | 100% | 25.0% (2/8) | LOW |
| c_dim_stone | rule | 1 | 11.9% | 3.2% | 27% | 3.2% | 100% | 0.0% (0/4) |  |
| c_cache_plate | dice | 1 | 12.7% | 4.0% | 31% | 1.6% | 40% | 0.0% (0/5) |  |
| c_golden_thread | mana | 1 | 69.8% | 27.0% | 39% | 18.3% | 68% | 5.9% (2/34) |  |
| c_melting_pot | pos | 1 | 10.3% | 1.6% | 15% | 0.8% | 50% | 100.0% (2/2) |  |
| c_support_hand | dice | 1 | 46.0% | 23.8% | 52% | 16.7% | 70% | 6.7% (2/30) |  |
| c_cracked_glass | dice | 1 | 15.1% | 4.8% | 32% | 1.6% | 33% | 16.7% (1/6) |  |
| c_mirror_face | dice | 2 | 7.1% | 4.8% | 67% | 4.8% | 100% | 33.3% (2/6) | LOW |
| c_sixth_die | dice | 2 | 46.0% | 23.8% | 52% | 23.8% | 100% | 23.3% (7/30) |  |
| c_whittle | dice | 2 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| c_three_dice | dice | 2 | 15.9% | 4.8% | 30% | 4.8% | 100% | 0.0% (0/6) |  |
| c_concord | dice | 2 | 7.1% | 3.2% | 44% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_toxic_still | dice | 2 | 3.2% | 0.8% | 25% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 20.6% | 7.1% | 35% | 7.1% | 100% | 55.6% (5/9) |  |
| c_thorn_rebound | rule | 2 | 11.9% | 4.0% | 33% | 2.4% | 60% | 0.0% (0/5) |  |
| c_open_ranks | pos | 2 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.7% | 4.0% | 31% | 4.0% | 100% | 60.0% (3/5) |  |
| c_hollow_core | mana | 2 | 25.4% | 6.3% | 25% | 6.3% | 88% | 12.5% (1/8) |  |
| c_deep_current | mana | 2 | 36.5% | 10.3% | 28% | 7.1% | 69% | 15.4% (2/13) |  |
| c_blood_sign | rule | 2 | 4.8% | 3.2% | 67% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_loop | rule | 2 | 11.9% | 4.8% | 40% | 5.6% | 100% | 16.7% (1/6) |  |
| c_cascade | rule | 2 | 14.3% | 7.9% | 56% | 7.9% | 100% | 40.0% (4/10) |  |
| c_sacrifice | rule | 2 | 11.1% | 4.0% | 36% | 4.0% | 100% | 0.0% (0/5) |  |
| c_last_testament | rule | 2 | 15.1% | 3.2% | 21% | 4.0% | 100% | 0.0% (0/4) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 83.3% (105/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_living_wall: 55.6% (5/9)
- c_cascade: 40.0% (4/10)
- c_growing_shell: 33.3% (4/12)
- c_bastion: 33.3% (5/15)
- c_spore_burst: 31.2% (5/16)
- c_nest: 29.4% (5/17)
- c_backline_glow: 28.6% (4/14)
- c_golden_egg: 25.0% (2/8)
- c_dewdrop: 25.0% (3/12)
- c_sixth_die: 23.3% (7/30)

Bottom 10:
- c_smoldering: 0.0% (0/14)
- c_fossil: 0.0% (0/11)
- c_tidecaller: 5.0% (1/20)
- c_golden_thread: 5.9% (2/34)
- c_support_hand: 6.7% (2/30)
- c_thorn_pact: 6.7% (1/15)
- c_meme_nametag: 7.1% (1/14)
- c_kindle: 8.3% (1/12)
- c_mana_pool: 10.0% (2/20)
- c_hollow_core: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_finisher + c_prime_chain: 25.0% (2/8)
- c_finisher + c_sixth_die: 25.0% (3/12)
- c_hunters_reward + c_sixth_die: 21.4% (3/14)
- c_chimera_hunt + c_finisher: 16.7% (2/12)
- c_golden_thread + c_mana_ward: 12.5% (1/8)
- c_golden_thread + c_support_hand: 0.0% (0/9)
- c_golden_thread + c_mana_pool: 0.0% (0/8)
- c_finisher + c_golden_thread: 0.0% (0/17)
- c_finisher + c_support_hand: 7.1% (1/14)
- c_finisher + c_hunters_reward: 7.7% (1/13)
