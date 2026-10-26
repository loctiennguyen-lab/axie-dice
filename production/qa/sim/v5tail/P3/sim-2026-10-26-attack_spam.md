# Sim balance attack_spam

Runs: 126, wall 9.1s (0.07s/run).

## Muc tieu (Short A0)

- attack_spam <= 5%: 7.1% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_big_hand | 19 | 15.1 | 0.0 +-0.0 | 26.3 | 7.4 | 22.0 | 16.70 |
| attack_spam | a_embers | 18 | 14.3 | 22.2 +-19.2 | 16.7 | 7.0 | 24.7 | 18.04 |
| attack_spam | a_gambler | 21 | 16.7 | 4.8 +-9.1 | 47.6 | 6.0 | 18.6 | 19.05 |
| attack_spam | a_kin | 25 | 19.8 | 4.0 +-7.7 | 28.0 | 4.7 | 13.3 | 17.87 |
| attack_spam | a_mana_mine | 24 | 19.0 | 8.3 +-11.1 | 50.0 | 5.0 | 17.0 | 19.67 |
| attack_spam | a_volley | 19 | 15.1 | 5.3 +-10.0 | 21.1 | 6.8 | 20.5 | 20.81 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 4.0% | 0.0% |
| attack_spam | h_gambler | 9.5% | 1.6% |
| attack_spam | h_mana_mine | 7.9% | 0.8% |
| attack_spam | h_kin | 17.5% | 11.9% |
| attack_spam | h_embers | 4.0% | 0.8% |
| attack_spam | h_big_hand | 0.8% | 0.0% |
| attack_spam | combos formed avg | 0.51 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=126): r4 battle -5 (con 96%); r5 elite -19 (con 81%); r6 boss -22 (con 63%); r8 battle -1 (con 63%); r9 elite -14 (con 52%); r12 boss -26 (con 31%); r14 battle -1 (con 30%); r15 battle -2 (con 29%); r15 elite -2 (con 27%); r18 boss -25 (con 7%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 126 | 17.02 +-1.45 | 19.87 +-1.20 | 19.87 +-1.20 | 13.56 +-1.57 | 7.54 +-0.63 | 0.48 +-0.10 | 7.1 +-4.5 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 126 | 37.28 | 0.77 | 0.39 | 7.17 | 51 | 926 | 0.41 | 0.00 | 0.26 | 0.11 | 0.00 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 17.2 | 10.5 | 10.5 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 7.1% (9/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/18) |
| attack_spam | beast_bird | 0.0% (0/18) |
| attack_spam | mixed_dmg | 5.6% (1/18) |
| attack_spam | mixed_std | 11.1% (2/18) |
| attack_spam | reptile_bug | 11.1% (2/18) |
| attack_spam | tank_heavy | 16.7% (3/18) |
| attack_spam | thorn_shield | 5.6% (1/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 2.4% (1/42) |
| attack_spam | greedy_axis | 14.3% (6/42) |
| attack_spam | random | 4.8% (2/42) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=784)
- attack_spam|boss: 7.0 luot (n=201)
- attack_spam|elite: 5.0 luot (n=107)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r14: 1
- attack_spam|battle r15: 2
- attack_spam|battle r4: 5
- attack_spam|battle r8: 1
- attack_spam|boss r12: 26
- attack_spam|boss r18: 25
- attack_spam|boss r6: 22
- attack_spam|elite r15: 2
- attack_spam|elite r5: 19
- attack_spam|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 1 / 1092

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 55.6% | 11.1% | 20% | 11.1% | 100% | 14.3% (2/14) |  |
| c_dewdrop | stat | 0 | 44.4% | 15.9% | 36% | 15.9% | 100% | 10.0% (2/20) |  |
| c_elder_trunk | stat | 0 | 41.3% | 22.2% | 54% | 22.2% | 100% | 7.1% (2/28) |  |
| c_prime_chain | dice | 0 | 24.6% | 7.9% | 32% | 5.6% | 70% | 0.0% (0/10) |  |
| c_finisher | dice | 0 | 38.1% | 13.5% | 35% | 13.5% | 100% | 5.9% (1/17) |  |
| c_bastion | pos | 0 | 48.4% | 15.9% | 33% | 15.1% | 95% | 5.0% (1/20) |  |
| c_tidecaller | mana | 0 | 54.8% | 12.7% | 23% | 0.0% | 0% | 0.0% (0/16) | DEAD |
| c_mana_pool | mana | 0 | 46.0% | 18.3% | 40% | 15.9% | 87% | 4.3% (1/23) |  |
| c_nest | rule | 0 | 53.2% | 22.2% | 42% | 22.2% | 100% | 14.3% (4/28) |  |
| c_spore_burst | rule | 0 | 45.2% | 19.8% | 44% | 19.8% | 100% | 24.0% (6/25) |  |
| c_fossil | rule | 0 | 19.8% | 5.6% | 28% | 4.8% | 86% | 0.0% (0/7) |  |
| c_meme_copycat | dice | 0 | 22.2% | 6.3% | 29% | 4.0% | 62% | 0.0% (0/8) |  |
| c_meme_nametag | rule | 0 | 43.7% | 11.1% | 25% | 10.3% | 93% | 28.6% (4/14) |  |
| c_meme_jumpy | dice | 0 | 19.8% | 6.3% | 32% | 6.3% | 100% | 0.0% (0/8) |  |
| c_bloodline_ward | pos | 0 | 35.7% | 7.1% | 20% | 0.8% | 11% | 0.0% (0/9) |  |
| c_smoldering | mana | 0 | 48.4% | 13.5% | 28% | 0.0% | 0% | 11.8% (2/17) | DEAD |
| c_hunters_reward | dice | 0 | 32.5% | 4.8% | 15% | 0.0% | 0% | 0.0% (0/6) | DEAD |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 0.0% | 0% | 0.0% (0/6) | LOW DEAD |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 0.0% | 0% | 0.0% (0/5) | LOW DEAD |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 3.2% | 50% | 0.0% (0/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 0.0% (0/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 0.0% (0/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 7.7% (1/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 50.0% (1/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 15.0% (3/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 0.0% (0/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 0.0% | 0% | 16.7% (1/6) | LOW DEAD |
| c_prism | dice | 1 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_steady_hold | dice | 1 | 6.3% | 1.6% | 25% | 0.0% | 0% | 0.0% (0/2) | LOW DEAD |
| c_kindle | dice | 1 | 7.9% | 2.4% | 30% | 0.0% | 0% | 33.3% (1/3) | LOW DEAD |
| c_sonic_shield | dice | 1 | 14.3% | 4.0% | 28% | 4.0% | 100% | 0.0% (0/5) |  |
| c_fissure | dice | 1 | 2.4% | 2.4% | 100% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_field_medic | dice | 1 | 5.6% | 0.8% | 14% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 7.1% | 3.2% | 44% | 2.4% | 75% | 0.0% (0/4) | LOW |
| c_gatekeeper | pos | 1 | 24.6% | 10.3% | 42% | 8.7% | 85% | 15.4% (2/13) |  |
| c_thorn_growth | pos | 1 | 12.7% | 1.6% | 12% | 1.6% | 100% | 0.0% (0/2) |  |
| c_thorn_shield | stat | 1 | 68.3% | 15.9% | 23% | 15.9% | 100% | 15.0% (3/20) |  |
| c_growing_shell | pos | 1 | 21.4% | 9.5% | 44% | 6.3% | 67% | 0.0% (0/12) |  |
| c_backline_glow | pos | 1 | 31.7% | 15.1% | 48% | 14.3% | 95% | 5.3% (1/19) |  |
| c_mana_ward | mana | 1 | 20.6% | 7.9% | 38% | 5.6% | 70% | 10.0% (1/10) |  |
| c_overflow | mana | 1 | 27.0% | 16.7% | 62% | 10.3% | 62% | 0.0% (0/21) |  |
| c_thorn_pact | mana | 1 | 25.4% | 13.5% | 53% | 13.5% | 100% | 5.9% (1/17) |  |
| c_dry_well | quest | 1 | 21.4% | 3.2% | 15% | 3.2% | 100% | 0.0% (0/4) |  |
| c_night_watch | quest | 1 | 23.8% | 4.8% | 20% | 4.8% | 100% | 0.0% (0/6) |  |
| c_key_strike | quest | 1 | 21.4% | 4.8% | 22% | 0.8% | 17% | 16.7% (1/6) |  |
| c_collector | quest | 1 | 19.0% | 3.2% | 17% | 3.2% | 100% | 25.0% (1/4) |  |
| c_chimera_hunt | quest | 1 | 21.4% | 6.3% | 30% | 4.0% | 62% | 0.0% (0/8) |  |
| c_golden_egg | rule | 1 | 15.9% | 12.7% | 80% | 12.7% | 100% | 25.0% (4/16) |  |
| c_dim_stone | rule | 1 | 7.1% | 2.4% | 33% | 2.4% | 100% | 66.7% (2/3) | LOW |
| c_cache_plate | dice | 1 | 15.9% | 2.4% | 15% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| c_golden_thread | mana | 1 | 20.6% | 7.1% | 35% | 0.0% | 0% | 11.1% (1/9) | DEAD |
| c_melting_pot | pos | 1 | 7.1% | 2.4% | 33% | 1.6% | 67% | 33.3% (1/3) | LOW |
| c_support_hand | dice | 1 | 17.5% | 4.8% | 27% | 4.0% | 83% | 0.0% (0/6) |  |
| c_cracked_glass | dice | 1 | 4.8% | 0.8% | 17% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_mirror_face | dice | 2 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/6) | LOW |
| c_sixth_die | dice | 2 | 12.7% | 6.3% | 50% | 6.3% | 100% | 0.0% (0/8) |  |
| c_whittle | dice | 2 | 7.1% | 2.4% | 33% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_three_dice | dice | 2 | 15.1% | 4.0% | 26% | 4.0% | 100% | 0.0% (0/5) |  |
| c_concord | dice | 2 | 2.4% | 0.8% | 33% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 7.1% | 0.8% | 11% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 20.6% | 8.7% | 42% | 9.5% | 100% | 9.1% (1/11) |  |
| c_thorn_rebound | rule | 2 | 7.9% | 1.6% | 20% | 0.8% | 50% | 0.0% (0/2) | LOW |
| c_open_ranks | pos | 2 | 8.7% | 0.8% | 9% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_descend | pos | 2 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_hollow_core | mana | 2 | 23.0% | 9.5% | 41% | 4.8% | 50% | 33.3% (4/12) |  |
| c_deep_current | mana | 2 | 34.9% | 11.9% | 34% | 9.5% | 73% | 13.3% (2/15) |  |
| c_blood_sign | rule | 2 | 8.7% | 4.8% | 55% | 4.8% | 100% | 66.7% (4/6) | LOW |
| c_loop | rule | 2 | 8.7% | 4.0% | 45% | 4.8% | 100% | 0.0% (0/5) | LOW |
| c_cascade | rule | 2 | 11.1% | 4.8% | 43% | 4.8% | 100% | 0.0% (0/6) |  |
| c_sacrifice | rule | 2 | 9.5% | 1.6% | 17% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_last_testament | rule | 2 | 20.6% | 7.9% | 38% | 7.9% | 100% | 20.0% (2/10) |  |
| c_high_roller | rule | 2 | 1.6% | 0.0% | 0% | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 75.4% (95/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_hollow_core: 33.3% (4/12)
- c_meme_nametag: 28.6% (4/14)
- c_golden_egg: 25.0% (4/16)
- c_spore_burst: 24.0% (6/25)
- c_last_testament: 20.0% (2/10)
- c_living_wall: 16.7% (2/12)
- c_gatekeeper: 15.4% (2/13)
- c_thorn_shield: 15.0% (3/20)
- c_nest: 14.3% (4/28)
- c_early_scales: 14.3% (2/14)

Bottom 10:
- c_prime_chain: 0.0% (0/10)
- c_growing_shell: 0.0% (0/12)
- c_meme_jumpy: 0.0% (0/8)
- c_overflow: 0.0% (0/21)
- c_tidecaller: 0.0% (0/16)
- c_meme_copycat: 0.0% (0/8)
- c_sixth_die: 0.0% (0/8)
- c_bloodline_ward: 0.0% (0/9)
- c_chimera_hunt: 0.0% (0/8)
- c_mana_pool: 4.3% (1/23)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_golden_egg + c_meme_nametag: 37.5% (3/8)
- c_golden_egg + c_spore_burst: 33.3% (3/9)
- c_meme_nametag + c_nest: 30.0% (3/10)
- c_golden_egg + c_nest: 25.0% (4/16)
- c_early_scales + c_elder_trunk: 25.0% (2/8)
- c_dewdrop + c_elder_trunk: 0.0% (0/8)
- c_mana_pool + c_overflow: 0.0% (0/8)
- c_deep_current + c_overflow: 0.0% (0/8)
- c_deep_current + c_mana_pool: 0.0% (0/8)
- c_backline_glow + c_bastion: 11.1% (1/9)
