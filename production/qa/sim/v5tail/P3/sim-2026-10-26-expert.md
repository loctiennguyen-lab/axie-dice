# Sim balance expert

Runs: 126, wall 180.2s (1.43s/run).

## Muc tieu (Short A0)

- expert 15-25%: 13.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_big_hand | 18 | 14.3 | 11.1 +-14.5 | 22.2 | 6.2 | 14.2 | 22.94 |
| expert | a_embers | 4 | 3.2 | 0.0 +-0.0 | 50.0 | 6.0 | 8.0 | 20.64 |
| expert | a_gambler | 22 | 17.5 | 4.5 +-8.7 | 54.5 | 4.4 | 8.7 | 21.82 |
| expert | a_kin | 42 | 33.3 | 19.0 +-11.9 | 50.0 | 4.9 | 9.2 | 28.92 |
| expert | a_mana_mine | 14 | 11.1 | 14.3 +-18.3 | 57.1 | 2.9 | 3.1 | 22.53 |
| expert | a_volley | 26 | 20.6 | 15.4 +-13.9 | 38.5 | 5.6 | 11.9 | 28.45 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 7.1% | 0.8% |
| expert | h_gambler | 11.9% | 0.8% |
| expert | h_mana_mine | 4.8% | 0.8% |
| expert | h_kin | 20.6% | 9.5% |
| expert | h_embers | 3.2% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.58 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -5 (con 96%); r5 elite -8 (con 90%); r6 boss -15 (con 78%); r8 battle -2 (con 76%); r9 elite -14 (con 65%); r9 battle -1 (con 64%); r12 boss -26 (con 44%); r15 elite -11 (con 35%); r16 battle -1 (con 34%); r18 boss -26 (con 13%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 24.55 +-1.70 | 22.74 +-1.31 | 28.48 +-1.52 | 19.27 +-1.59 | 5.46 +-0.36 | 0.58 +-0.10 | 13.5 +-6.0 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 31.48 | 1.41 | 1.22 | 4.34 | 86 | 308 | 0.52 | 0.00 | 0.27 | 0.05 | 0.57 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 6 | 20 | 24 | 37 | 4.93 | 1.06 | 16.79 | 3.90 | 4.76 | 9.19 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (492) | 0% (0) | 34.5 | 18.8 | 11.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 13.5% (17/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 11.1% (2/18) |
| expert | beast_bird | 27.8% (5/18) |
| expert | mixed_dmg | 0.0% (0/18) |
| expert | mixed_std | 11.1% (2/18) |
| expert | reptile_bug | 16.7% (3/18) |
| expert | tank_heavy | 22.2% (4/18) |
| expert | thorn_shield | 5.6% (1/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 23.8% (10/42) |
| expert | greedy_axis | 9.5% (4/42) |
| expert | random | 7.1% (3/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=849)
- expert|boss: 5.4 luot (n=237)
- expert|elite: 4.1 luot (n=122)

## Chet theo node (chinh sach|loai row)

- expert|battle r16: 1
- expert|battle r4: 5
- expert|battle r8: 2
- expert|battle r9: 1
- expert|boss r12: 26
- expert|boss r18: 26
- expert|boss r6: 15
- expert|elite r15: 11
- expert|elite r5: 8
- expert|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 0 / 1208

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 69.8% | 23.8% | 34% | 23.8% | 100% | 13.3% (4/30) |  |
| c_dewdrop | stat | 0 | 60.3% | 29.4% | 49% | 29.4% | 100% | 13.5% (5/37) |  |
| c_elder_trunk | stat | 0 | 58.7% | 24.6% | 42% | 24.6% | 100% | 6.5% (2/31) |  |
| c_prime_chain | dice | 0 | 21.4% | 8.7% | 41% | 6.3% | 73% | 9.1% (1/11) |  |
| c_finisher | dice | 0 | 36.5% | 13.5% | 37% | 12.7% | 94% | 11.8% (2/17) |  |
| c_bastion | pos | 0 | 57.9% | 24.6% | 42% | 24.6% | 100% | 12.9% (4/31) |  |
| c_tidecaller | mana | 0 | 44.4% | 11.9% | 27% | 7.1% | 60% | 6.7% (1/15) |  |
| c_mana_pool | mana | 0 | 39.7% | 9.5% | 24% | 8.7% | 92% | 0.0% (0/12) |  |
| c_nest | rule | 0 | 60.3% | 23.0% | 38% | 23.0% | 100% | 31.0% (9/29) |  |
| c_spore_burst | rule | 0 | 47.6% | 19.0% | 40% | 19.0% | 100% | 45.8% (11/24) |  |
| c_fossil | rule | 0 | 22.2% | 5.6% | 25% | 5.6% | 100% | 0.0% (0/7) |  |
| c_meme_copycat | dice | 0 | 23.0% | 4.0% | 17% | 4.0% | 100% | 0.0% (0/5) |  |
| c_meme_nametag | rule | 0 | 47.6% | 7.9% | 17% | 7.9% | 100% | 40.0% (4/10) |  |
| c_meme_jumpy | dice | 0 | 15.9% | 3.2% | 20% | 3.2% | 100% | 0.0% (0/4) |  |
| c_bloodline_ward | pos | 0 | 48.4% | 12.7% | 26% | 0.0% | 0% | 25.0% (4/16) | DEAD |
| c_smoldering | mana | 0 | 42.1% | 7.9% | 19% | 3.2% | 40% | 0.0% (0/10) |  |
| c_hunters_reward | dice | 0 | 33.3% | 7.1% | 21% | 2.4% | 33% | 33.3% (3/9) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 33.3% (1/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 33.3% (2/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 5.6% | 88% | 12.5% (1/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 14.3% (1/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 0.0% (0/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 0.0% (0/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 10.0% (2/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 28.6% (4/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 16.7% (1/6) | LOW |
| c_prism | dice | 1 | 10.3% | 4.8% | 46% | 2.4% | 50% | 33.3% (2/6) |  |
| c_steady_hold | dice | 1 | 10.3% | 4.8% | 46% | 4.8% | 100% | 0.0% (0/6) |  |
| c_kindle | dice | 1 | 12.7% | 4.8% | 38% | 4.8% | 100% | 16.7% (1/6) |  |
| c_sonic_shield | dice | 1 | 19.8% | 8.7% | 44% | 8.7% | 100% | 18.2% (2/11) |  |
| c_fissure | dice | 1 | 10.3% | 3.2% | 31% | 3.2% | 100% | 0.0% (0/4) |  |
| c_field_medic | dice | 1 | 4.0% | 0.8% | 20% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 13.5% | 57% | 13.5% | 100% | 23.5% (4/17) |  |
| c_thorn_growth | pos | 1 | 21.4% | 7.9% | 37% | 7.9% | 100% | 20.0% (2/10) |  |
| c_thorn_shield | stat | 1 | 77.8% | 22.2% | 29% | 21.4% | 96% | 10.7% (3/28) |  |
| c_growing_shell | pos | 1 | 33.3% | 7.1% | 21% | 6.3% | 89% | 11.1% (1/9) |  |
| c_backline_glow | pos | 1 | 36.5% | 19.0% | 52% | 18.3% | 96% | 16.7% (4/24) |  |
| c_mana_ward | mana | 1 | 24.6% | 8.7% | 35% | 5.6% | 64% | 0.0% (0/11) |  |
| c_overflow | mana | 1 | 33.3% | 14.3% | 43% | 9.5% | 67% | 11.1% (2/18) |  |
| c_thorn_pact | mana | 1 | 27.0% | 11.9% | 44% | 11.9% | 100% | 13.3% (2/15) |  |
| c_dry_well | quest | 1 | 23.0% | 2.4% | 10% | 2.4% | 100% | 0.0% (0/3) |  |
| c_night_watch | quest | 1 | 31.0% | 1.6% | 5% | 1.6% | 100% | 0.0% (0/2) |  |
| c_key_strike | quest | 1 | 30.2% | 7.1% | 24% | 5.6% | 78% | 0.0% (0/9) |  |
| c_collector | quest | 1 | 27.8% | 4.8% | 17% | 4.8% | 100% | 33.3% (2/6) |  |
| c_chimera_hunt | quest | 1 | 25.4% | 6.3% | 25% | 4.8% | 75% | 12.5% (1/8) |  |
| c_golden_egg | rule | 1 | 17.5% | 15.9% | 91% | 15.1% | 95% | 30.0% (6/20) |  |
| c_dim_stone | rule | 1 | 10.3% | 2.4% | 23% | 2.4% | 100% | 33.3% (1/3) |  |
| c_cache_plate | dice | 1 | 12.7% | 1.6% | 12% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_golden_thread | mana | 1 | 23.0% | 3.2% | 14% | 3.2% | 100% | 0.0% (0/4) |  |
| c_melting_pot | pos | 1 | 6.3% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_support_hand | dice | 1 | 7.9% | 2.4% | 30% | 1.6% | 67% | 0.0% (0/3) | LOW |
| c_cracked_glass | dice | 1 | 10.3% | 1.6% | 15% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_mirror_face | dice | 2 | 6.3% | 1.6% | 25% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_sixth_die | dice | 2 | 11.9% | 4.0% | 33% | 4.0% | 100% | 40.0% (2/5) |  |
| c_whittle | dice | 2 | 10.3% | 1.6% | 15% | 1.6% | 100% | 0.0% (0/2) |  |
| c_three_dice | dice | 2 | 19.0% | 7.1% | 38% | 7.1% | 100% | 11.1% (1/9) |  |
| c_concord | dice | 2 | 3.2% | 0.8% | 25% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 6.3% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 31.7% | 17.5% | 55% | 18.3% | 100% | 22.7% (5/22) |  |
| c_thorn_rebound | rule | 2 | 11.9% | 5.6% | 47% | 2.4% | 43% | 28.6% (2/7) |  |
| c_open_ranks | pos | 2 | 15.9% | 4.0% | 25% | 4.0% | 100% | 20.0% (1/5) |  |
| c_descend | pos | 2 | 17.5% | 5.6% | 32% | 5.6% | 100% | 14.3% (1/7) |  |
| c_hollow_core | mana | 2 | 25.4% | 7.9% | 31% | 7.9% | 100% | 20.0% (2/10) |  |
| c_deep_current | mana | 2 | 33.3% | 6.3% | 19% | 5.6% | 88% | 12.5% (1/8) |  |
| c_blood_sign | rule | 2 | 11.1% | 3.2% | 29% | 3.2% | 100% | 50.0% (2/4) |  |
| c_loop | rule | 2 | 11.9% | 6.3% | 53% | 5.6% | 88% | 25.0% (2/8) |  |
| c_cascade | rule | 2 | 14.3% | 7.9% | 56% | 7.9% | 100% | 50.0% (5/10) |  |
| c_sacrifice | rule | 2 | 9.5% | 6.3% | 67% | 6.3% | 100% | 12.5% (1/8) | LOW |
| c_last_testament | rule | 2 | 23.8% | 12.7% | 53% | 13.5% | 100% | 37.5% (6/16) |  |
| c_high_roller | rule | 2 | 2.4% | 0.8% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 72.2% (91/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_cascade: 50.0% (5/10)
- c_spore_burst: 45.8% (11/24)
- c_meme_nametag: 40.0% (4/10)
- c_last_testament: 35.3% (6/17)
- c_hunters_reward: 33.3% (3/9)
- c_nest: 31.0% (9/29)
- c_golden_egg: 30.0% (6/20)
- c_living_wall: 26.1% (6/23)
- c_loop: 25.0% (2/8)
- c_bloodline_ward: 25.0% (4/16)

Bottom 10:
- c_mana_ward: 0.0% (0/11)
- c_smoldering: 0.0% (0/10)
- c_key_strike: 0.0% (0/9)
- c_mana_pool: 0.0% (0/12)
- c_elder_trunk: 6.5% (2/31)
- c_tidecaller: 6.7% (1/15)
- c_prime_chain: 9.1% (1/11)
- c_thorn_shield: 10.7% (3/28)
- c_overflow: 11.1% (2/18)
- c_three_dice: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_last_testament + c_spore_burst: 62.5% (5/8)
- c_backline_glow + c_gatekeeper: 50.0% (4/8)
- c_golden_egg + c_last_testament: 33.3% (3/9)
- c_bastion + c_living_wall: 30.0% (3/10)
- c_golden_egg + c_nest: 28.6% (4/14)
- c_early_scales + c_thorn_shield: 0.0% (0/11)
- c_dewdrop + c_early_scales: 0.0% (0/13)
- c_early_scales + c_elder_trunk: 0.0% (0/11)
- c_dewdrop + c_thorn_shield: 6.2% (1/16)
- c_dewdrop + c_elder_trunk: 6.2% (1/16)
