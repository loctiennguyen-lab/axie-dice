# Sim balance a_embers

Runs: 126, wall 105.9s (0.84s/run).

## Muc tieu (Short A0)

- expert 15-25%: 14.3% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_embers | 126 | 100.0 | 14.3 +-6.1 | 41.3 | 5.8 | 12.6 | 24.07 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.8% | 0.0% |
| expert | h_gambler | 4.8% | 0.0% |
| expert | h_mana_mine | 10.3% | 0.8% |
| expert | h_kin | 7.9% | 4.0% |
| expert | h_embers | 19.0% | 2.4% |
| expert | h_big_hand | 1.6% | 0.0% |
| expert | combos formed avg | 0.48 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -3 (con 98%); r5 elite -12 (con 88%); r6 boss -9 (con 81%); r7 battle -1 (con 80%); r8 battle -5 (con 76%); r9 elite -12 (con 67%); r9 battle -2 (con 65%); r10 battle -1 (con 64%); r11 battle -2 (con 63%); r12 boss -23 (con 44%); r14 battle -1 (con 44%); r15 elite -11 (con 35%); r15 battle -1 (con 34%); r17 battle -1 (con 33%); r18 boss -24 (con 14%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 22.59 +-1.48 | 34.09 +-1.93 | 31.12 +-1.77 | 20.08 +-1.67 | 5.17 +-0.36 | 0.51 +-0.09 | 14.3 +-6.1 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 33.33 | 1.43 | 1.22 | 5.12 | 85 | 357 | 0.56 | 0.00 | 0.20 | 0.08 | 0.60 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 15 | 5 | 18 | 22 | 40 | 5.44 | 1.30 | 18.75 | 4.25 | 4.43 | 10.01 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (536) | 0% (0) | 31.2 | 17.9 | 10.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 14.3% (18/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 16.7% (3/18) |
| expert | mixed_dmg | 16.7% (3/18) |
| expert | mixed_std | 5.6% (1/18) |
| expert | reptile_bug | 5.6% (1/18) |
| expert | tank_heavy | 16.7% (3/18) |
| expert | thorn_shield | 33.3% (6/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 4.8% (2/42) |
| expert | greedy_axis | 16.7% (7/42) |
| expert | random | 21.4% (9/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.9 luot (n=871)
- expert|boss: 5.1 luot (n=232)
- expert|elite: 4.1 luot (n=119)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r14: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r4: 3
- expert|battle r7: 1
- expert|battle r8: 5
- expert|battle r9: 2
- expert|boss r12: 23
- expert|boss r18: 24
- expert|boss r6: 9
- expert|elite r15: 11
- expert|elite r5: 12
- expert|elite r9: 12

Tran ket > 20 luot hoac khong ket thuc: 0 / 1222

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 37.3% | 7.9% | 21% | 7.9% | 100% | 20.0% (2/10) |  |
| c_dewdrop | stat | 0 | 34.9% | 12.7% | 36% | 12.7% | 100% | 25.0% (4/16) |  |
| c_elder_trunk | stat | 0 | 33.3% | 10.3% | 31% | 10.3% | 100% | 30.8% (4/13) |  |
| c_prime_chain | dice | 0 | 43.7% | 15.1% | 35% | 12.7% | 84% | 10.5% (2/19) |  |
| c_finisher | dice | 0 | 39.7% | 17.5% | 44% | 17.5% | 100% | 9.1% (2/22) |  |
| c_bastion | pos | 0 | 45.2% | 15.9% | 35% | 15.9% | 100% | 5.0% (1/20) |  |
| c_tidecaller | mana | 0 | 50.0% | 9.5% | 19% | 6.3% | 67% | 8.3% (1/12) |  |
| c_mana_pool | mana | 0 | 50.0% | 18.3% | 37% | 17.5% | 96% | 21.7% (5/23) |  |
| c_nest | rule | 0 | 50.8% | 14.3% | 28% | 14.3% | 100% | 27.8% (5/18) |  |
| c_spore_burst | rule | 0 | 48.4% | 16.7% | 34% | 16.7% | 100% | 42.9% (9/21) |  |
| c_fossil | rule | 0 | 18.3% | 8.7% | 48% | 7.9% | 91% | 27.3% (3/11) |  |
| c_meme_copycat | dice | 0 | 31.0% | 11.1% | 36% | 11.1% | 100% | 28.6% (4/14) |  |
| c_meme_nametag | rule | 0 | 40.5% | 10.3% | 25% | 10.3% | 100% | 30.8% (4/13) |  |
| c_meme_jumpy | dice | 0 | 30.2% | 7.1% | 24% | 7.1% | 100% | 33.3% (3/9) |  |
| c_bloodline_ward | pos | 0 | 30.2% | 4.8% | 16% | 2.4% | 50% | 16.7% (1/6) |  |
| c_smoldering | mana | 0 | 79.4% | 40.5% | 51% | 40.5% | 100% | 5.9% (3/51) |  |
| c_hunters_reward | dice | 0 | 43.7% | 9.5% | 22% | 5.6% | 58% | 25.0% (3/12) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 0.0% (0/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 40.0% (2/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 6.3% | 100% | 25.0% (2/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 28.6% (2/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 40.0% (2/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 20.0% (4/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 7.1% (1/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 0.0% (0/6) | LOW |
| c_prism | dice | 1 | 10.3% | 2.4% | 23% | 0.8% | 33% | 0.0% (0/3) |  |
| c_steady_hold | dice | 1 | 4.8% | 0.8% | 17% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 40.5% | 20.6% | 51% | 20.6% | 100% | 19.2% (5/26) |  |
| c_sonic_shield | dice | 1 | 10.3% | 5.6% | 54% | 4.8% | 86% | 28.6% (2/7) |  |
| c_fissure | dice | 1 | 5.6% | 1.6% | 29% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_field_medic | dice | 1 | 4.8% | 1.6% | 33% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_plague_spread | dice | 1 | 4.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 7.1% | 30% | 7.1% | 100% | 0.0% (0/9) |  |
| c_thorn_growth | pos | 1 | 15.1% | 3.2% | 21% | 2.4% | 75% | 50.0% (2/4) |  |
| c_thorn_shield | stat | 1 | 61.9% | 10.3% | 17% | 10.3% | 100% | 46.2% (6/13) |  |
| c_growing_shell | pos | 1 | 23.0% | 7.1% | 31% | 4.0% | 56% | 11.1% (1/9) |  |
| c_backline_glow | pos | 1 | 22.2% | 5.6% | 25% | 4.0% | 71% | 14.3% (1/7) |  |
| c_mana_ward | mana | 1 | 27.8% | 4.8% | 17% | 4.0% | 83% | 16.7% (1/6) |  |
| c_overflow | mana | 1 | 67.5% | 38.1% | 56% | 23.8% | 62% | 10.4% (5/48) |  |
| c_thorn_pact | mana | 1 | 24.6% | 11.1% | 45% | 11.1% | 100% | 0.0% (0/14) |  |
| c_dry_well | quest | 1 | 19.8% | 2.4% | 12% | 2.4% | 100% | 33.3% (1/3) |  |
| c_night_watch | quest | 1 | 36.5% | 4.8% | 13% | 4.8% | 100% | 16.7% (1/6) |  |
| c_key_strike | quest | 1 | 24.6% | 2.4% | 10% | 2.4% | 100% | 0.0% (0/3) |  |
| c_collector | quest | 1 | 29.4% | 9.5% | 32% | 9.5% | 100% | 8.3% (1/12) |  |
| c_chimera_hunt | quest | 1 | 30.2% | 9.5% | 32% | 7.1% | 75% | 8.3% (1/12) |  |
| c_golden_egg | rule | 1 | 8.7% | 4.8% | 55% | 4.8% | 100% | 33.3% (2/6) | LOW |
| c_dim_stone | rule | 1 | 7.9% | 2.4% | 30% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_cache_plate | dice | 1 | 41.3% | 14.3% | 35% | 11.9% | 83% | 16.7% (3/18) |  |
| c_golden_thread | mana | 1 | 24.6% | 9.5% | 39% | 6.3% | 67% | 25.0% (3/12) |  |
| c_melting_pot | pos | 1 | 11.1% | 4.0% | 36% | 4.0% | 100% | 20.0% (1/5) |  |
| c_support_hand | dice | 1 | 13.5% | 4.8% | 35% | 3.2% | 67% | 66.7% (4/6) |  |
| c_cracked_glass | dice | 1 | 10.3% | 1.6% | 15% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_mirror_face | dice | 2 | 7.1% | 2.4% | 33% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_sixth_die | dice | 2 | 14.3% | 7.9% | 56% | 7.9% | 100% | 50.0% (5/10) |  |
| c_whittle | dice | 2 | 9.5% | 3.2% | 33% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_three_dice | dice | 2 | 45.2% | 25.4% | 56% | 23.8% | 94% | 15.6% (5/32) |  |
| c_concord | dice | 2 | 7.9% | 1.6% | 20% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_living_wall | pos | 2 | 21.4% | 9.5% | 44% | 9.5% | 100% | 8.3% (1/12) |  |
| c_thorn_rebound | rule | 2 | 7.1% | 3.2% | 44% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_open_ranks | pos | 2 | 13.5% | 3.2% | 24% | 3.2% | 100% | 0.0% (0/4) |  |
| c_descend | pos | 2 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| c_hollow_core | mana | 2 | 30.2% | 7.9% | 26% | 7.1% | 90% | 10.0% (1/10) |  |
| c_deep_current | mana | 2 | 38.1% | 11.1% | 29% | 10.3% | 86% | 21.4% (3/14) |  |
| c_blood_sign | rule | 2 | 11.1% | 4.8% | 43% | 4.8% | 100% | 16.7% (1/6) |  |
| c_loop | rule | 2 | 11.9% | 4.8% | 40% | 3.2% | 67% | 50.0% (3/6) |  |
| c_cascade | rule | 2 | 10.3% | 4.8% | 46% | 4.8% | 100% | 50.0% (3/6) |  |
| c_sacrifice | rule | 2 | 11.1% | 3.2% | 29% | 3.2% | 100% | 25.0% (1/4) |  |
| c_last_testament | rule | 2 | 7.1% | 2.4% | 33% | 4.0% | 100% | 66.7% (2/3) | LOW |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 87.3% (110/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_sixth_die: 50.0% (5/10)
- c_thorn_shield: 46.2% (6/13)
- c_spore_burst: 42.9% (9/21)
- c_meme_jumpy: 33.3% (3/9)
- c_elder_trunk: 30.8% (4/13)
- c_meme_nametag: 30.8% (4/13)
- c_meme_copycat: 28.6% (4/14)
- c_nest: 27.8% (5/18)
- c_fossil: 27.3% (3/11)
- c_deep_current: 26.7% (4/15)

Bottom 10:
- c_thorn_pact: 0.0% (0/14)
- c_gatekeeper: 0.0% (0/9)
- c_bastion: 5.0% (1/20)
- c_smoldering: 5.9% (3/51)
- c_tidecaller: 8.3% (1/12)
- c_collector: 8.3% (1/12)
- c_chimera_hunt: 8.3% (1/12)
- c_living_wall: 8.3% (1/12)
- c_finisher: 9.1% (2/22)
- c_hollow_core: 10.0% (1/10)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_nest + c_spore_burst: 44.4% (4/9)
- c_meme_nametag + c_spore_burst: 37.5% (3/8)
- c_overflow + c_three_dice: 16.7% (2/12)
- c_meme_nametag + c_nest: 12.5% (1/8)
- c_dewdrop + c_smoldering: 12.5% (1/8)
- c_smoldering + c_three_dice: 0.0% (0/8)
- c_kindle + c_smoldering: 0.0% (0/9)
- c_overflow + c_smoldering: 0.0% (0/25)
- c_mana_pool + c_smoldering: 0.0% (0/8)
- c_overflow + c_thorn_pact: 0.0% (0/9)
