# Sim balance a_big_hand

Runs: 126, wall 205.5s (1.63s/run).

## Muc tieu (Short A0)

- expert 15-25%: 9.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_big_hand | 126 | 100.0 | 9.5 +-5.1 | 41.3 | 4.8 | 9.7 | 25.18 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 4.8% | 0.8% |
| expert | h_gambler | 7.1% | 0.0% |
| expert | h_mana_mine | 5.6% | 0.8% |
| expert | h_kin | 7.1% | 4.8% |
| expert | h_embers | 12.7% | 1.6% |
| expert | h_big_hand | 7.1% | 3.2% |
| expert | combos formed avg | 0.50 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -5 (con 96%); r5 elite -8 (con 90%); r5 battle -1 (con 89%); r6 boss -13 (con 79%); r8 battle -3 (con 76%); r9 elite -15 (con 64%); r10 battle -1 (con 63%); r12 boss -29 (con 40%); r15 elite -7 (con 35%); r17 battle -1 (con 34%); r18 boss -31 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 23.93 +-1.61 | 22.02 +-1.23 | 28.49 +-1.43 | 18.67 +-1.62 | 5.42 +-0.36 | 0.56 +-0.11 | 9.5 +-5.1 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 32.37 | 1.72 | 1.03 | 10.19 | 60 | 594 | 0.55 | 0.00 | 0.33 | 0.04 | 0.80 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 22 | 18 | 40 | 4.21 | 1.05 | 18.75 | 3.92 | 2.99 | 9.12 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (494) | 0% (0) | 32.8 | 17.7 | 13.9 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.02; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 9.5% (12/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 16.7% (3/18) |
| expert | mixed_dmg | 0.0% (0/18) |
| expert | mixed_std | 16.7% (3/18) |
| expert | reptile_bug | 5.6% (1/18) |
| expert | tank_heavy | 16.7% (3/18) |
| expert | thorn_shield | 5.6% (1/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 11.9% (5/42) |
| expert | greedy_axis | 11.9% (5/42) |
| expert | random | 4.8% (2/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=858)
- expert|boss: 5.4 luot (n=235)
- expert|elite: 4.4 luot (n=123)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r17: 1
- expert|battle r4: 5
- expert|battle r5: 1
- expert|battle r8: 3
- expert|boss r12: 29
- expert|boss r18: 31
- expert|boss r6: 13
- expert|elite r15: 7
- expert|elite r5: 8
- expert|elite r9: 15

Tran ket > 20 luot hoac khong ket thuc: 2 / 1216

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 38.9% | 9.5% | 24% | 9.5% | 100% | 0.0% (0/12) |  |
| c_dewdrop | stat | 0 | 39.7% | 7.9% | 20% | 7.9% | 100% | 0.0% (0/10) |  |
| c_elder_trunk | stat | 0 | 39.7% | 11.9% | 30% | 11.9% | 100% | 6.7% (1/15) |  |
| c_prime_chain | dice | 0 | 20.6% | 11.9% | 58% | 10.3% | 87% | 13.3% (2/15) |  |
| c_finisher | dice | 0 | 67.5% | 40.5% | 60% | 40.5% | 100% | 5.9% (3/51) |  |
| c_bastion | pos | 0 | 37.3% | 10.3% | 28% | 10.3% | 100% | 30.8% (4/13) |  |
| c_tidecaller | mana | 0 | 63.5% | 15.9% | 25% | 7.9% | 50% | 5.0% (1/20) |  |
| c_mana_pool | mana | 0 | 57.1% | 15.1% | 26% | 12.7% | 84% | 5.3% (1/19) |  |
| c_nest | rule | 0 | 48.4% | 12.7% | 26% | 12.7% | 100% | 25.0% (4/16) |  |
| c_spore_burst | rule | 0 | 50.8% | 11.9% | 23% | 11.9% | 100% | 26.7% (4/15) |  |
| c_fossil | rule | 0 | 24.6% | 8.7% | 35% | 7.9% | 91% | 9.1% (1/11) |  |
| c_meme_copycat | dice | 0 | 19.0% | 4.8% | 25% | 3.2% | 67% | 0.0% (0/6) |  |
| c_meme_nametag | rule | 0 | 40.5% | 11.1% | 27% | 10.3% | 93% | 21.4% (3/14) |  |
| c_meme_jumpy | dice | 0 | 14.3% | 4.0% | 28% | 4.0% | 100% | 20.0% (1/5) |  |
| c_bloodline_ward | pos | 0 | 34.9% | 5.6% | 16% | 2.4% | 43% | 0.0% (0/7) |  |
| c_smoldering | mana | 0 | 53.2% | 11.1% | 21% | 1.6% | 14% | 7.1% (1/14) |  |
| c_hunters_reward | dice | 0 | 58.7% | 28.6% | 49% | 14.3% | 50% | 16.7% (6/36) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 16.7% (1/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 4.8% | 75% | 0.0% (0/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 14.3% (1/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 0.0% (0/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 50.0% (2/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 7.7% (1/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 15.0% (3/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 7.1% (1/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/6) | LOW |
| c_prism | dice | 1 | 11.1% | 7.1% | 64% | 4.0% | 56% | 22.2% (2/9) |  |
| c_steady_hold | dice | 1 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/6) | LOW |
| c_kindle | dice | 1 | 15.9% | 9.5% | 60% | 9.5% | 100% | 0.0% (0/12) |  |
| c_sonic_shield | dice | 1 | 18.3% | 10.3% | 57% | 9.5% | 92% | 23.1% (3/13) |  |
| c_fissure | dice | 1 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_field_medic | dice | 1 | 9.5% | 4.0% | 42% | 4.0% | 100% | 0.0% (0/5) | LOW |
| c_plague_spread | dice | 1 | 4.8% | 0.8% | 17% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_gatekeeper | pos | 1 | 18.3% | 5.6% | 30% | 5.6% | 100% | 14.3% (1/7) |  |
| c_thorn_growth | pos | 1 | 16.7% | 2.4% | 14% | 2.4% | 100% | 33.3% (1/3) |  |
| c_thorn_shield | stat | 1 | 64.3% | 10.3% | 16% | 10.3% | 100% | 0.0% (0/13) |  |
| c_growing_shell | pos | 1 | 18.3% | 7.1% | 39% | 5.6% | 78% | 11.1% (1/9) |  |
| c_backline_glow | pos | 1 | 26.2% | 11.9% | 45% | 10.3% | 87% | 13.3% (2/15) |  |
| c_mana_ward | mana | 1 | 22.2% | 7.9% | 36% | 5.6% | 70% | 20.0% (2/10) |  |
| c_overflow | mana | 1 | 23.0% | 6.3% | 28% | 4.8% | 75% | 12.5% (1/8) |  |
| c_thorn_pact | mana | 1 | 24.6% | 12.7% | 52% | 12.7% | 100% | 0.0% (0/16) |  |
| c_dry_well | quest | 1 | 24.6% | 2.4% | 10% | 2.4% | 100% | 0.0% (0/3) |  |
| c_night_watch | quest | 1 | 28.6% | 4.0% | 14% | 4.0% | 100% | 0.0% (0/5) |  |
| c_key_strike | quest | 1 | 17.5% | 2.4% | 14% | 1.6% | 67% | 0.0% (0/3) |  |
| c_collector | quest | 1 | 29.4% | 5.6% | 19% | 5.6% | 100% | 0.0% (0/7) |  |
| c_chimera_hunt | quest | 1 | 34.1% | 14.3% | 42% | 9.5% | 67% | 16.7% (3/18) |  |
| c_golden_egg | rule | 1 | 9.5% | 6.3% | 67% | 6.3% | 100% | 25.0% (2/8) | LOW |
| c_dim_stone | rule | 1 | 10.3% | 4.0% | 38% | 4.0% | 100% | 20.0% (1/5) |  |
| c_cache_plate | dice | 1 | 12.7% | 4.0% | 31% | 0.8% | 20% | 0.0% (0/5) |  |
| c_golden_thread | mana | 1 | 62.7% | 21.4% | 34% | 13.5% | 63% | 7.4% (2/27) |  |
| c_melting_pot | pos | 1 | 8.7% | 1.6% | 18% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_support_hand | dice | 1 | 46.0% | 23.8% | 52% | 15.9% | 67% | 10.0% (3/30) |  |
| c_cracked_glass | dice | 1 | 11.9% | 4.0% | 33% | 1.6% | 40% | 0.0% (0/5) |  |
| c_mirror_face | dice | 2 | 7.9% | 4.8% | 60% | 4.8% | 100% | 33.3% (2/6) | LOW |
| c_sixth_die | dice | 2 | 43.7% | 22.2% | 51% | 22.2% | 100% | 21.4% (6/28) |  |
| c_whittle | dice | 2 | 13.5% | 4.8% | 35% | 4.8% | 100% | 0.0% (0/6) |  |
| c_three_dice | dice | 2 | 16.7% | 6.3% | 38% | 6.3% | 100% | 12.5% (1/8) |  |
| c_concord | dice | 2 | 6.3% | 3.2% | 50% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_toxic_still | dice | 2 | 3.2% | 0.8% | 25% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 20.6% | 5.6% | 27% | 5.6% | 100% | 28.6% (2/7) |  |
| c_thorn_rebound | rule | 2 | 11.9% | 4.0% | 33% | 4.0% | 100% | 20.0% (1/5) |  |
| c_open_ranks | pos | 2 | 8.7% | 0.0% | 0% | 0.8% | - | - | LOW |
| c_descend | pos | 2 | 12.7% | 3.2% | 25% | 3.2% | 100% | 50.0% (2/4) |  |
| c_hollow_core | mana | 2 | 25.4% | 5.6% | 22% | 5.6% | 86% | 28.6% (2/7) |  |
| c_deep_current | mana | 2 | 37.3% | 10.3% | 28% | 7.9% | 77% | 7.7% (1/13) |  |
| c_blood_sign | rule | 2 | 3.2% | 2.4% | 75% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_loop | rule | 2 | 9.5% | 4.0% | 42% | 4.0% | 100% | 20.0% (1/5) | LOW |
| c_cascade | rule | 2 | 15.1% | 7.1% | 47% | 7.9% | 100% | 33.3% (3/9) |  |
| c_sacrifice | rule | 2 | 11.9% | 6.3% | 53% | 6.3% | 100% | 0.0% (0/8) |  |
| c_last_testament | rule | 2 | 12.7% | 4.0% | 31% | 5.6% | 100% | 0.0% (0/5) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 87.3% (110/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_hollow_core: 37.5% (3/8)
- c_bastion: 30.8% (4/13)
- c_cascade: 30.0% (3/10)
- c_spore_burst: 26.7% (4/15)
- c_nest: 25.0% (4/16)
- c_golden_egg: 25.0% (2/8)
- c_sonic_shield: 23.1% (3/13)
- c_prism: 22.2% (2/9)
- c_meme_nametag: 21.4% (3/14)
- c_sixth_die: 21.4% (6/28)

Bottom 10:
- c_thorn_shield: 0.0% (0/13)
- c_kindle: 0.0% (0/12)
- c_dewdrop: 0.0% (0/10)
- c_early_scales: 0.0% (0/12)
- c_thorn_pact: 0.0% (0/16)
- c_sacrifice: 0.0% (0/8)
- c_tidecaller: 5.0% (1/20)
- c_mana_pool: 5.3% (1/19)
- c_finisher: 5.9% (3/51)
- c_elder_trunk: 6.7% (1/15)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_sixth_die + c_support_hand: 37.5% (3/8)
- c_hunters_reward + c_sixth_die: 27.3% (3/11)
- c_sonic_shield + c_support_hand: 25.0% (2/8)
- c_chimera_hunt + c_finisher: 21.4% (3/14)
- c_finisher + c_sixth_die: 18.2% (2/11)
- c_finisher + c_support_hand: 0.0% (0/12)
- c_finisher + c_golden_thread: 0.0% (0/11)
- c_finisher + c_hunters_reward: 7.1% (1/14)
- c_hunters_reward + c_support_hand: 9.1% (1/11)
- c_golden_thread + c_mana_ward: 12.5% (1/8)
