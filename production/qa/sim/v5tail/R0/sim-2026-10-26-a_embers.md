# Sim balance a_embers

Runs: 126, wall 109.8s (0.87s/run).

## Muc tieu (Short A0)

- expert 15-25%: 10.3% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_embers | 126 | 100.0 | 10.3 +-5.3 | 42.9 | 6.0 | 13.4 | 21.82 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 1.6% | 0.0% |
| expert | h_gambler | 4.0% | 0.0% |
| expert | h_mana_mine | 12.7% | 0.8% |
| expert | h_kin | 7.9% | 3.2% |
| expert | h_embers | 17.5% | 2.4% |
| expert | h_big_hand | 1.6% | 0.0% |
| expert | combos formed avg | 0.48 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -4 (con 97%); r5 elite -10 (con 89%); r6 boss -11 (con 80%); r8 battle -9 (con 73%); r9 elite -13 (con 63%); r9 battle -1 (con 62%); r10 battle -1 (con 61%); r11 battle -2 (con 60%); r12 boss -29 (con 37%); r14 battle -2 (con 35%); r15 elite -13 (con 25%); r17 battle -1 (con 24%); r18 boss -17 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 20.99 +-1.33 | 31.24 +-1.55 | 28.85 +-1.44 | 17.89 +-1.34 | 5.78 +-0.50 | 0.47 +-0.09 | 10.3 +-5.3 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 34.06 | 1.28 | 1.12 | 4.45 | 87 | 346 | 0.47 | 0.00 | 0.21 | 0.10 | 0.50 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 19 | 24 | 38 | 4.73 | 0.95 | 18.41 | 4.18 | 4.50 | 8.95 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (527) | 0% (0) | 30.6 | 17.2 | 10.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 10.3% (13/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 11.1% (2/18) |
| expert | mixed_dmg | 11.1% (2/18) |
| expert | mixed_std | 11.1% (2/18) |
| expert | reptile_bug | 0.0% (0/18) |
| expert | tank_heavy | 22.2% (4/18) |
| expert | thorn_shield | 11.1% (2/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 7.1% (3/42) |
| expert | greedy_axis | 14.3% (6/42) |
| expert | random | 9.5% (4/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.0 luot (n=845)
- expert|boss: 5.8 luot (n=217)
- expert|elite: 4.3 luot (n=110)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r14: 2
- expert|battle r17: 1
- expert|battle r4: 4
- expert|battle r8: 9
- expert|battle r9: 1
- expert|boss r12: 29
- expert|boss r18: 17
- expert|boss r6: 11
- expert|elite r15: 13
- expert|elite r5: 10
- expert|elite r9: 13

Tran ket > 20 luot hoac khong ket thuc: 2 / 1172

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 34.9% | 6.3% | 18% | 6.3% | 100% | 12.5% (1/8) |  |
| c_dewdrop | stat | 0 | 37.3% | 13.5% | 36% | 13.5% | 100% | 5.9% (1/17) |  |
| c_elder_trunk | stat | 0 | 34.9% | 8.7% | 25% | 8.7% | 100% | 0.0% (0/11) |  |
| c_prime_chain | dice | 0 | 38.1% | 14.3% | 38% | 13.5% | 94% | 16.7% (3/18) |  |
| c_finisher | dice | 0 | 34.9% | 15.9% | 45% | 15.9% | 100% | 15.0% (3/20) |  |
| c_bastion | pos | 0 | 46.0% | 14.3% | 31% | 14.3% | 100% | 11.1% (2/18) |  |
| c_tidecaller | mana | 0 | 50.0% | 11.1% | 22% | 8.7% | 79% | 7.1% (1/14) |  |
| c_mana_pool | mana | 0 | 45.2% | 16.7% | 37% | 15.9% | 95% | 4.8% (1/21) |  |
| c_nest | rule | 0 | 42.9% | 13.5% | 31% | 13.5% | 100% | 23.5% (4/17) |  |
| c_spore_burst | rule | 0 | 49.2% | 14.3% | 29% | 14.3% | 100% | 33.3% (6/18) |  |
| c_fossil | rule | 0 | 18.3% | 8.7% | 48% | 7.9% | 91% | 18.2% (2/11) |  |
| c_meme_copycat | dice | 0 | 28.6% | 8.7% | 31% | 7.9% | 91% | 9.1% (1/11) |  |
| c_meme_nametag | rule | 0 | 36.5% | 9.5% | 26% | 8.7% | 92% | 33.3% (4/12) |  |
| c_meme_jumpy | dice | 0 | 33.3% | 8.7% | 26% | 8.7% | 100% | 0.0% (0/11) |  |
| c_bloodline_ward | pos | 0 | 27.0% | 4.8% | 18% | 3.2% | 67% | 16.7% (1/6) |  |
| c_smoldering | mana | 0 | 81.0% | 39.7% | 49% | 39.7% | 100% | 4.0% (2/50) |  |
| c_hunters_reward | dice | 0 | 45.2% | 11.9% | 26% | 7.9% | 67% | 20.0% (3/15) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 0.0% (0/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 20.0% (1/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 6.3% | 100% | 12.5% (1/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 14.3% (1/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 0.0% (0/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 10.0% (2/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 14.3% (2/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 16.7% (1/6) | LOW |
| c_prism | dice | 1 | 8.7% | 4.0% | 45% | 1.6% | 40% | 0.0% (0/5) | LOW |
| c_steady_hold | dice | 1 | 6.3% | 0.8% | 12% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 38.1% | 18.3% | 48% | 18.3% | 100% | 17.4% (4/23) |  |
| c_sonic_shield | dice | 1 | 12.7% | 4.8% | 38% | 4.8% | 100% | 0.0% (0/6) |  |
| c_fissure | dice | 1 | 4.0% | 1.6% | 40% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_field_medic | dice | 1 | 7.9% | 2.4% | 30% | 2.4% | 100% | 66.7% (2/3) | LOW |
| c_plague_spread | dice | 1 | 4.0% | 2.4% | 60% | 0.8% | 33% | 33.3% (1/3) | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 4.8% | 20% | 4.8% | 100% | 0.0% (0/6) |  |
| c_thorn_growth | pos | 1 | 15.9% | 3.2% | 20% | 3.2% | 100% | 25.0% (1/4) |  |
| c_thorn_shield | stat | 1 | 59.5% | 8.7% | 15% | 7.9% | 91% | 18.2% (2/11) |  |
| c_growing_shell | pos | 1 | 22.2% | 4.8% | 21% | 2.4% | 50% | 0.0% (0/6) |  |
| c_backline_glow | pos | 1 | 15.9% | 4.0% | 25% | 4.0% | 100% | 0.0% (0/5) |  |
| c_mana_ward | mana | 1 | 25.4% | 6.3% | 25% | 6.3% | 100% | 0.0% (0/8) |  |
| c_overflow | mana | 1 | 61.1% | 38.1% | 62% | 23.0% | 60% | 6.2% (3/48) |  |
| c_thorn_pact | mana | 1 | 23.0% | 9.5% | 41% | 9.5% | 100% | 16.7% (2/12) |  |
| c_dry_well | quest | 1 | 19.0% | 2.4% | 12% | 2.4% | 100% | 66.7% (2/3) |  |
| c_night_watch | quest | 1 | 28.6% | 4.0% | 14% | 4.0% | 100% | 0.0% (0/5) |  |
| c_key_strike | quest | 1 | 30.2% | 4.0% | 13% | 4.0% | 100% | 0.0% (0/5) |  |
| c_collector | quest | 1 | 27.0% | 7.9% | 29% | 7.9% | 100% | 10.0% (1/10) |  |
| c_chimera_hunt | quest | 1 | 22.2% | 5.6% | 25% | 4.8% | 86% | 14.3% (1/7) |  |
| c_golden_egg | rule | 1 | 5.6% | 4.0% | 71% | 4.0% | 100% | 40.0% (2/5) | LOW |
| c_dim_stone | rule | 1 | 7.1% | 3.2% | 44% | 3.2% | 100% | 75.0% (3/4) | LOW |
| c_cache_plate | dice | 1 | 34.1% | 13.5% | 40% | 11.9% | 88% | 5.9% (1/17) |  |
| c_golden_thread | mana | 1 | 25.4% | 7.1% | 28% | 4.8% | 67% | 0.0% (0/9) |  |
| c_melting_pot | pos | 1 | 15.1% | 7.9% | 53% | 6.3% | 80% | 30.0% (3/10) |  |
| c_support_hand | dice | 1 | 5.6% | 2.4% | 43% | 1.6% | 67% | 33.3% (1/3) | LOW |
| c_cracked_glass | dice | 1 | 5.6% | 0.8% | 14% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_mirror_face | dice | 2 | 7.9% | 3.2% | 40% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_sixth_die | dice | 2 | 12.7% | 6.3% | 50% | 6.3% | 100% | 37.5% (3/8) |  |
| c_whittle | dice | 2 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| c_three_dice | dice | 2 | 42.1% | 24.6% | 58% | 24.6% | 100% | 6.5% (2/31) |  |
| c_concord | dice | 2 | 6.3% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 5.6% | 1.6% | 29% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_living_wall | pos | 2 | 19.0% | 7.9% | 42% | 7.9% | 100% | 20.0% (2/10) |  |
| c_thorn_rebound | rule | 2 | 4.0% | 0.8% | 20% | 0.8% | 100% | 100.0% (1/1) | LOW |
| c_open_ranks | pos | 2 | 16.7% | 3.2% | 19% | 4.0% | 100% | 0.0% (0/4) |  |
| c_descend | pos | 2 | 12.7% | 3.2% | 25% | 4.0% | 100% | 0.0% (0/4) |  |
| c_hollow_core | mana | 2 | 27.8% | 9.5% | 34% | 10.3% | 100% | 8.3% (1/12) |  |
| c_deep_current | mana | 2 | 43.7% | 15.9% | 36% | 13.5% | 85% | 10.0% (2/20) |  |
| c_blood_sign | rule | 2 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| c_loop | rule | 2 | 11.9% | 3.2% | 27% | 2.4% | 75% | 50.0% (2/4) |  |
| c_cascade | rule | 2 | 7.9% | 4.0% | 50% | 3.2% | 80% | 0.0% (0/5) | LOW |
| c_sacrifice | rule | 2 | 10.3% | 2.4% | 23% | 2.4% | 100% | 33.3% (1/3) |  |
| c_last_testament | rule | 2 | 11.1% | 4.0% | 36% | 4.8% | 100% | 40.0% (2/5) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 88.9% (112/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_sixth_die: 37.5% (3/8)
- c_meme_nametag: 33.3% (4/12)
- c_spore_burst: 33.3% (6/18)
- c_melting_pot: 30.0% (3/10)
- c_nest: 23.5% (4/17)
- c_living_wall: 20.0% (2/10)
- c_hunters_reward: 20.0% (3/15)
- c_thorn_shield: 18.2% (2/11)
- c_fossil: 18.2% (2/11)
- c_kindle: 17.4% (4/23)

Bottom 10:
- c_elder_trunk: 0.0% (0/11)
- c_mana_ward: 0.0% (0/8)
- c_golden_thread: 0.0% (0/9)
- c_meme_jumpy: 0.0% (0/11)
- c_smoldering: 4.0% (2/50)
- c_mana_pool: 4.8% (1/21)
- c_cache_plate: 5.9% (1/17)
- c_dewdrop: 5.9% (1/17)
- c_overflow: 6.2% (3/48)
- c_three_dice: 6.5% (2/31)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_meme_nametag + c_spore_burst: 37.5% (3/8)
- c_nest + c_spore_burst: 33.3% (3/9)
- c_kindle + c_three_dice: 22.2% (2/9)
- c_kindle + c_smoldering: 12.5% (1/8)
- c_deep_current + c_mana_pool: 12.5% (1/8)
- c_finisher + c_three_dice: 0.0% (0/8)
- c_prime_chain + c_three_dice: 0.0% (0/11)
- c_mana_pool + c_overflow: 0.0% (0/8)
- c_mana_pool + c_smoldering: 0.0% (0/9)
- c_dewdrop + c_smoldering: 0.0% (0/8)
