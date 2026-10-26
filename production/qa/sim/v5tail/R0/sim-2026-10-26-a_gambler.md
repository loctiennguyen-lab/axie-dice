# Sim balance a_gambler

Runs: 126, wall 214.9s (1.71s/run).

## Muc tieu (Short A0)

- expert 15-25%: 13.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 126 | 100.0 | 13.5 +-6.0 | 57.9 | 5.4 | 12.2 | 24.97 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 11.1% | 0.8% |
| expert | h_gambler | 32.5% | 9.5% |
| expert | h_mana_mine | 7.1% | 0.8% |
| expert | h_kin | 11.1% | 5.6% |
| expert | h_embers | 1.6% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.73 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -4 (con 97%); r5 elite -9 (con 90%); r5 battle -1 (con 89%); r6 boss -9 (con 82%); r7 battle -1 (con 81%); r8 battle -1 (con 80%); r9 elite -13 (con 70%); r9 battle -2 (con 68%); r10 battle -2 (con 67%); r12 boss -24 (con 48%); r15 elite -14 (con 37%); r16 battle -2 (con 35%); r18 boss -27 (con 13%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 24.17 +-1.79 | 21.37 +-1.18 | 28.64 +-1.78 | 19.09 +-1.70 | 5.77 +-0.37 | 0.48 +-0.09 | 13.5 +-6.0 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 34.13 | 1.74 | 1.33 | 5.77 | 76 | 331 | 0.60 | 0.00 | 0.35 | 0.08 | 0.72 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 4 | 20 | 26 | 39 | 4.51 | 0.90 | 22.79 | 4.60 | 5.83 | 8.66 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (580) | 0% (0) | 35.4 | 20.1 | 13.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 13.5% (17/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 22.2% (4/18) |
| expert | beast_bird | 11.1% (2/18) |
| expert | mixed_dmg | 11.1% (2/18) |
| expert | mixed_std | 16.7% (3/18) |
| expert | reptile_bug | 5.6% (1/18) |
| expert | tank_heavy | 16.7% (3/18) |
| expert | thorn_shield | 11.1% (2/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (7/42) |
| expert | greedy_axis | 16.7% (7/42) |
| expert | random | 7.1% (3/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=882)
- expert|boss: 5.6 luot (n=240)
- expert|elite: 4.5 luot (n=126)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 2
- expert|battle r16: 2
- expert|battle r4: 4
- expert|battle r5: 1
- expert|battle r7: 1
- expert|battle r8: 1
- expert|battle r9: 2
- expert|boss r12: 24
- expert|boss r18: 27
- expert|boss r6: 9
- expert|elite r15: 14
- expert|elite r5: 9
- expert|elite r9: 13

Tran ket > 20 luot hoac khong ket thuc: 0 / 1248

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 63.5% | 23.0% | 36% | 23.0% | 100% | 24.1% (7/29) |  |
| c_dewdrop | stat | 0 | 59.5% | 29.4% | 49% | 29.4% | 100% | 21.6% (8/37) |  |
| c_elder_trunk | stat | 0 | 92.1% | 50.0% | 54% | 50.0% | 100% | 17.5% (11/63) |  |
| c_prime_chain | dice | 0 | 23.8% | 7.1% | 30% | 6.3% | 89% | 11.1% (1/9) |  |
| c_finisher | dice | 0 | 33.3% | 9.5% | 29% | 9.5% | 100% | 25.0% (3/12) |  |
| c_bastion | pos | 0 | 50.8% | 16.7% | 33% | 16.7% | 100% | 4.8% (1/21) |  |
| c_tidecaller | mana | 0 | 56.3% | 12.7% | 23% | 6.3% | 50% | 6.2% (1/16) |  |
| c_mana_pool | mana | 0 | 60.3% | 23.0% | 38% | 20.6% | 90% | 3.4% (1/29) |  |
| c_nest | rule | 0 | 49.2% | 14.3% | 29% | 14.3% | 100% | 11.1% (2/18) |  |
| c_spore_burst | rule | 0 | 51.6% | 13.5% | 26% | 13.5% | 100% | 29.4% (5/17) |  |
| c_fossil | rule | 0 | 15.1% | 3.2% | 21% | 2.4% | 75% | 25.0% (1/4) |  |
| c_meme_copycat | dice | 0 | 16.7% | 3.2% | 19% | 2.4% | 75% | 0.0% (0/4) |  |
| c_meme_nametag | rule | 0 | 52.4% | 7.9% | 15% | 7.9% | 100% | 20.0% (2/10) |  |
| c_meme_jumpy | dice | 0 | 19.0% | 4.0% | 21% | 4.0% | 100% | 0.0% (0/5) |  |
| c_bloodline_ward | pos | 0 | 34.1% | 4.8% | 14% | 0.0% | 0% | 16.7% (1/6) | DEAD |
| c_smoldering | mana | 0 | 54.0% | 14.3% | 26% | 2.4% | 17% | 5.6% (1/18) |  |
| c_hunters_reward | dice | 0 | 23.0% | 1.6% | 7% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 33.3% (1/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 33.3% (2/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 20.0% (1/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 5.6% | 88% | 12.5% (1/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 0.0% (0/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 20.0% (1/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 23.1% (3/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 0.0% (0/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 0.0% (0/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 5.0% (1/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 14.3% (2/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.8% | 100% | 33.3% (2/6) | LOW |
| c_prism | dice | 1 | 10.3% | 1.6% | 15% | 0.8% | 50% | 0.0% (0/2) |  |
| c_steady_hold | dice | 1 | 9.5% | 3.2% | 33% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_kindle | dice | 1 | 12.7% | 2.4% | 19% | 1.6% | 67% | 0.0% (0/3) |  |
| c_sonic_shield | dice | 1 | 18.3% | 4.8% | 26% | 4.0% | 83% | 33.3% (2/6) |  |
| c_fissure | dice | 1 | 8.7% | 0.8% | 9% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 7.9% | 1.6% | 20% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_gatekeeper | pos | 1 | 23.8% | 6.3% | 27% | 6.3% | 100% | 25.0% (2/8) |  |
| c_thorn_growth | pos | 1 | 17.5% | 6.3% | 36% | 6.3% | 100% | 37.5% (3/8) |  |
| c_thorn_shield | stat | 1 | 84.1% | 38.1% | 45% | 35.7% | 94% | 22.9% (11/48) |  |
| c_growing_shell | pos | 1 | 27.8% | 10.3% | 37% | 8.7% | 85% | 30.8% (4/13) |  |
| c_backline_glow | pos | 1 | 24.6% | 11.1% | 45% | 10.3% | 93% | 28.6% (4/14) |  |
| c_mana_ward | mana | 1 | 58.7% | 27.8% | 47% | 24.6% | 89% | 20.0% (7/35) |  |
| c_overflow | mana | 1 | 27.8% | 15.1% | 54% | 5.6% | 37% | 26.3% (5/19) |  |
| c_thorn_pact | mana | 1 | 48.4% | 28.6% | 59% | 28.6% | 100% | 16.7% (6/36) |  |
| c_dry_well | quest | 1 | 26.2% | 5.6% | 21% | 5.6% | 100% | 14.3% (1/7) |  |
| c_night_watch | quest | 1 | 31.0% | 6.3% | 21% | 6.3% | 100% | 0.0% (0/8) |  |
| c_key_strike | quest | 1 | 27.0% | 3.2% | 12% | 2.4% | 75% | 50.0% (2/4) |  |
| c_collector | quest | 1 | 23.8% | 5.6% | 23% | 5.6% | 100% | 14.3% (1/7) |  |
| c_chimera_hunt | quest | 1 | 32.5% | 8.7% | 27% | 4.8% | 55% | 9.1% (1/11) |  |
| c_golden_egg | rule | 1 | 9.5% | 6.3% | 67% | 6.3% | 100% | 25.0% (2/8) | LOW |
| c_dim_stone | rule | 1 | 7.1% | 2.4% | 33% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_cache_plate | dice | 1 | 11.9% | 2.4% | 20% | 1.6% | 67% | 0.0% (0/3) |  |
| c_golden_thread | mana | 1 | 27.8% | 9.5% | 34% | 5.6% | 58% | 16.7% (2/12) |  |
| c_melting_pot | pos | 1 | 11.1% | 0.0% | 0% | 0.0% | - | - |  |
| c_support_hand | dice | 1 | 6.3% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_cracked_glass | dice | 1 | 8.7% | 2.4% | 27% | 0.0% | 0% | 33.3% (1/3) | LOW DEAD |
| c_mirror_face | dice | 2 | 6.3% | 0.8% | 12% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_sixth_die | dice | 2 | 10.3% | 3.2% | 31% | 3.2% | 100% | 75.0% (3/4) |  |
| c_whittle | dice | 2 | 14.3% | 3.2% | 22% | 4.0% | 100% | 0.0% (0/4) |  |
| c_three_dice | dice | 2 | 11.1% | 2.4% | 21% | 2.4% | 100% | 0.0% (0/3) |  |
| c_concord | dice | 2 | 6.3% | 1.6% | 25% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 7.1% | 0.8% | 11% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 28.6% | 13.5% | 47% | 13.5% | 100% | 29.4% (5/17) |  |
| c_thorn_rebound | rule | 2 | 7.1% | 1.6% | 22% | 1.6% | 50% | 0.0% (0/2) | LOW |
| c_open_ranks | pos | 2 | 14.3% | 1.6% | 11% | 1.6% | 100% | 0.0% (0/2) |  |
| c_descend | pos | 2 | 19.8% | 8.7% | 44% | 8.7% | 100% | 18.2% (2/11) |  |
| c_hollow_core | mana | 2 | 40.5% | 21.4% | 53% | 16.7% | 78% | 3.7% (1/27) |  |
| c_deep_current | mana | 2 | 39.7% | 14.3% | 36% | 9.5% | 67% | 11.1% (2/18) |  |
| c_blood_sign | rule | 2 | 7.1% | 2.4% | 33% | 3.2% | 100% | 33.3% (1/3) | LOW |
| c_loop | rule | 2 | 11.1% | 4.8% | 43% | 2.4% | 50% | 16.7% (1/6) |  |
| c_cascade | rule | 2 | 11.9% | 4.0% | 33% | 4.0% | 100% | 40.0% (2/5) |  |
| c_sacrifice | rule | 2 | 11.9% | 3.2% | 27% | 3.2% | 100% | 0.0% (0/4) |  |
| c_last_testament | rule | 2 | 8.7% | 2.4% | 27% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_high_roller | rule | 2 | 12.7% | 2.4% | 19% | 0.0% | 0% | 33.3% (1/3) | DEAD |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 69.8% (88/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_thorn_growth: 37.5% (3/8)
- c_growing_shell: 30.8% (4/13)
- c_spore_burst: 29.4% (5/17)
- c_living_wall: 29.4% (5/17)
- c_backline_glow: 28.6% (4/14)
- c_overflow: 26.3% (5/19)
- c_golden_egg: 25.0% (2/8)
- c_gatekeeper: 25.0% (2/8)
- c_finisher: 25.0% (3/12)
- c_early_scales: 24.1% (7/29)

Bottom 10:
- c_night_watch: 0.0% (0/8)
- c_mana_pool: 3.4% (1/29)
- c_hollow_core: 3.7% (1/27)
- c_bastion: 4.8% (1/21)
- c_smoldering: 5.6% (1/18)
- c_tidecaller: 6.2% (1/16)
- c_chimera_hunt: 9.1% (1/11)
- c_deep_current: 11.1% (2/18)
- c_nest: 11.1% (2/18)
- c_prime_chain: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_dewdrop + c_early_scales: 30.8% (4/13)
- c_mana_ward + c_thorn_pact: 30.8% (4/13)
- c_early_scales + c_thorn_shield: 25.0% (3/12)
- c_dewdrop + c_mana_ward: 25.0% (2/8)
- c_dewdrop + c_thorn_pact: 22.2% (2/9)
- c_mana_ward + c_smoldering: 0.0% (0/9)
- c_hollow_core + c_mana_pool: 0.0% (0/9)
- c_hollow_core + c_mana_ward: 0.0% (0/13)
- c_thorn_pact + c_thorn_shield: 0.0% (0/11)
- c_mana_pool + c_mana_ward: 0.0% (0/9)
