# Sim balance a_volley

Runs: 126, wall 186.9s (1.48s/run).

## Muc tieu (Short A0)

- expert 15-25%: 17.5% -> DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_volley | 126 | 100.0 | 17.5 +-6.6 | 39.7 | 7.2 | 14.8 | 29.34 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 19.8% | 5.6% |
| expert | h_gambler | 13.5% | 0.8% |
| expert | h_mana_mine | 1.6% | 0.0% |
| expert | h_kin | 10.3% | 7.9% |
| expert | h_embers | 0.8% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.54 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -4 (con 97%); r5 elite -4 (con 94%); r6 boss -10 (con 86%); r8 battle -3 (con 83%); r9 elite -11 (con 75%); r10 battle -1 (con 74%); r11 battle -1 (con 73%); r12 boss -28 (con 51%); r15 elite -10 (con 43%); r15 battle -1 (con 42%); r16 battle -1 (con 41%); r18 boss -30 (con 17%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 28.79 +-2.14 | 22.42 +-1.20 | 28.88 +-1.63 | 22.36 +-1.83 | 5.09 +-0.34 | 0.50 +-0.10 | 17.5 +-6.7 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 31.27 | 1.65 | 1.26 | 4.95 | 77 | 300 | 0.63 | 0.00 | 0.26 | 0.03 | 0.73 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 15 | 6 | 20 | 23 | 36 | 5.22 | 1.06 | 17.43 | 4.00 | 4.63 | 10.87 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (504) | 0% (0) | 32.8 | 17.1 | 10.0 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 17.5% (22/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 33.3% (6/18) |
| expert | beast_bird | 16.7% (3/18) |
| expert | mixed_dmg | 11.1% (2/18) |
| expert | mixed_std | 16.7% (3/18) |
| expert | reptile_bug | 11.1% (2/18) |
| expert | tank_heavy | 16.7% (3/18) |
| expert | thorn_shield | 16.7% (3/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 19.0% (8/42) |
| expert | greedy_axis | 23.8% (10/42) |
| expert | random | 9.5% (4/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.4 luot (n=919)
- expert|boss: 5.0 luot (n=262)
- expert|elite: 3.4 luot (n=134)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 1
- expert|battle r15: 1
- expert|battle r16: 1
- expert|battle r4: 4
- expert|battle r8: 3
- expert|boss r12: 28
- expert|boss r18: 30
- expert|boss r6: 10
- expert|elite r15: 10
- expert|elite r5: 4
- expert|elite r9: 11

Tran ket > 20 luot hoac khong ket thuc: 0 / 1315

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 72.2% | 20.6% | 29% | 20.6% | 100% | 19.2% (5/26) |  |
| c_dewdrop | stat | 0 | 65.1% | 35.7% | 55% | 35.7% | 100% | 17.8% (8/45) |  |
| c_elder_trunk | stat | 0 | 60.3% | 25.4% | 42% | 25.4% | 100% | 12.5% (4/32) |  |
| c_prime_chain | dice | 0 | 38.9% | 15.9% | 41% | 13.5% | 85% | 30.0% (6/20) |  |
| c_finisher | dice | 0 | 41.3% | 16.7% | 40% | 15.9% | 95% | 9.5% (2/21) |  |
| c_bastion | pos | 0 | 75.4% | 29.4% | 39% | 28.6% | 97% | 21.6% (8/37) |  |
| c_tidecaller | mana | 0 | 27.0% | 4.8% | 18% | 3.2% | 67% | 16.7% (1/6) |  |
| c_mana_pool | mana | 0 | 30.2% | 7.9% | 26% | 7.9% | 100% | 20.0% (2/10) |  |
| c_nest | rule | 0 | 46.8% | 13.5% | 29% | 13.5% | 100% | 17.6% (3/17) |  |
| c_spore_burst | rule | 0 | 46.0% | 14.3% | 31% | 14.3% | 100% | 44.4% (8/18) |  |
| c_fossil | rule | 0 | 14.3% | 2.4% | 17% | 2.4% | 100% | 33.3% (1/3) |  |
| c_meme_copycat | dice | 0 | 26.2% | 4.0% | 15% | 4.0% | 100% | 20.0% (1/5) |  |
| c_meme_nametag | rule | 0 | 46.0% | 6.3% | 14% | 6.3% | 100% | 37.5% (3/8) |  |
| c_meme_jumpy | dice | 0 | 26.2% | 8.7% | 33% | 8.7% | 100% | 18.2% (2/11) |  |
| c_bloodline_ward | pos | 0 | 54.0% | 12.7% | 24% | 0.0% | 0% | 18.8% (3/16) | DEAD |
| c_smoldering | mana | 0 | 29.4% | 6.3% | 22% | 1.6% | 25% | 12.5% (1/8) |  |
| c_hunters_reward | dice | 0 | 34.9% | 8.7% | 25% | 1.6% | 18% | 18.2% (2/11) |  |
| rule_none | run_rule | 0 | 12.7% | 2.4% | 19% | 0.0% | 0% | 66.7% (2/3) | DEAD |
| rule_cheap_mana | run_rule | 0 | 8.7% | 4.8% | 55% | 4.8% | 100% | 0.0% (0/6) | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 4.0% | 50% | 4.0% | 100% | 0.0% (0/5) | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 6.3% | 67% | 6.3% | 100% | 0.0% (0/8) | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 7.1% | 64% | 7.1% | 100% | 11.1% (1/9) |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 5.6% | 64% | 5.6% | 100% | 14.3% (1/7) | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 4.0% | 31% | 4.0% | 100% | 40.0% (2/5) |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 1.6% | 33% | 1.6% | 100% | 50.0% (1/2) | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 7.1% | 47% | 7.1% | 100% | 22.2% (2/9) |  |
| rule_old_forest | run_rule | 0 | 19.8% | 10.3% | 52% | 10.3% | 100% | 15.4% (2/13) |  |
| rule_crow | run_rule | 0 | 8.7% | 1.6% | 18% | 1.6% | 100% | 50.0% (1/2) | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 10.3% | 57% | 10.3% | 100% | 23.1% (3/13) |  |
| rule_balance | run_rule | 0 | 22.2% | 15.9% | 71% | 15.9% | 100% | 20.0% (4/20) |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 11.1% | 52% | 11.1% | 100% | 7.1% (1/14) |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 4.8% | 50% | 4.0% | 83% | 33.3% (2/6) | LOW |
| c_prism | dice | 1 | 7.1% | 0.8% | 11% | 0.8% | 100% | 100.0% (1/1) | LOW |
| c_steady_hold | dice | 1 | 8.7% | 3.2% | 36% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_kindle | dice | 1 | 10.3% | 4.0% | 38% | 4.0% | 100% | 0.0% (0/5) |  |
| c_sonic_shield | dice | 1 | 57.9% | 23.0% | 40% | 22.2% | 97% | 31.0% (9/29) |  |
| c_fissure | dice | 1 | 7.9% | 1.6% | 20% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_field_medic | dice | 1 | 8.7% | 3.2% | 36% | 3.2% | 100% | 50.0% (2/4) | LOW |
| c_plague_spread | dice | 1 | 7.9% | 3.2% | 40% | 3.2% | 100% | 75.0% (3/4) | LOW |
| c_gatekeeper | pos | 1 | 39.7% | 23.0% | 58% | 23.0% | 100% | 24.1% (7/29) |  |
| c_thorn_growth | pos | 1 | 29.4% | 11.9% | 41% | 11.9% | 100% | 20.0% (3/15) |  |
| c_thorn_shield | stat | 1 | 86.5% | 29.4% | 34% | 29.4% | 100% | 24.3% (9/37) |  |
| c_growing_shell | pos | 1 | 43.7% | 18.3% | 42% | 15.1% | 83% | 30.4% (7/23) |  |
| c_backline_glow | pos | 1 | 72.2% | 36.5% | 51% | 34.9% | 96% | 26.1% (12/46) |  |
| c_mana_ward | mana | 1 | 20.6% | 7.1% | 35% | 4.8% | 67% | 11.1% (1/9) |  |
| c_overflow | mana | 1 | 29.4% | 9.5% | 32% | 4.8% | 50% | 16.7% (2/12) |  |
| c_thorn_pact | mana | 1 | 22.2% | 9.5% | 43% | 9.5% | 100% | 25.0% (3/12) |  |
| c_dry_well | quest | 1 | 29.4% | 5.6% | 19% | 5.6% | 100% | 14.3% (1/7) |  |
| c_night_watch | quest | 1 | 30.2% | 5.6% | 18% | 5.6% | 100% | 0.0% (0/7) |  |
| c_key_strike | quest | 1 | 26.2% | 4.0% | 15% | 4.0% | 100% | 20.0% (1/5) |  |
| c_collector | quest | 1 | 29.4% | 2.4% | 8% | 2.4% | 100% | 33.3% (1/3) |  |
| c_chimera_hunt | quest | 1 | 25.4% | 7.1% | 28% | 2.4% | 33% | 11.1% (1/9) |  |
| c_golden_egg | rule | 1 | 7.1% | 7.1% | 100% | 6.3% | 89% | 22.2% (2/9) | LOW |
| c_dim_stone | rule | 1 | 10.3% | 1.6% | 15% | 1.6% | 100% | 0.0% (0/2) |  |
| c_cache_plate | dice | 1 | 11.1% | 1.6% | 14% | 0.8% | 50% | 0.0% (0/2) |  |
| c_golden_thread | mana | 1 | 16.7% | 4.8% | 29% | 4.0% | 83% | 16.7% (1/6) |  |
| c_melting_pot | pos | 1 | 15.1% | 2.4% | 16% | 1.6% | 67% | 0.0% (0/3) |  |
| c_support_hand | dice | 1 | 14.3% | 4.8% | 33% | 4.0% | 83% | 16.7% (1/6) |  |
| c_cracked_glass | dice | 1 | 11.1% | 0.0% | 0% | 0.0% | - | - |  |
| c_mirror_face | dice | 2 | 7.9% | 4.8% | 60% | 4.8% | 100% | 50.0% (3/6) | LOW |
| c_sixth_die | dice | 2 | 15.9% | 6.3% | 40% | 6.3% | 100% | 50.0% (4/8) |  |
| c_whittle | dice | 2 | 11.9% | 2.4% | 20% | 2.4% | 100% | 0.0% (0/3) |  |
| c_three_dice | dice | 2 | 23.8% | 5.6% | 23% | 5.6% | 100% | 0.0% (0/7) |  |
| c_concord | dice | 2 | 10.3% | 4.0% | 38% | 4.8% | 100% | 40.0% (2/5) |  |
| c_toxic_still | dice | 2 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_living_wall | pos | 2 | 46.0% | 26.2% | 57% | 26.2% | 100% | 30.3% (10/33) |  |
| c_thorn_rebound | rule | 2 | 11.1% | 3.2% | 29% | 3.2% | 100% | 25.0% (1/4) |  |
| c_open_ranks | pos | 2 | 7.9% | 2.4% | 30% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_descend | pos | 2 | 23.0% | 10.3% | 45% | 10.3% | 100% | 38.5% (5/13) |  |
| c_hollow_core | mana | 2 | 24.6% | 4.0% | 16% | 4.0% | 100% | 20.0% (1/5) |  |
| c_deep_current | mana | 2 | 33.3% | 5.6% | 17% | 4.8% | 86% | 14.3% (1/7) |  |
| c_blood_sign | rule | 2 | 13.5% | 5.6% | 41% | 5.6% | 100% | 42.9% (3/7) |  |
| c_loop | rule | 2 | 4.8% | 2.4% | 50% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_cascade | rule | 2 | 13.5% | 3.2% | 24% | 3.2% | 100% | 50.0% (2/4) |  |
| c_sacrifice | rule | 2 | 11.9% | 3.2% | 27% | 4.0% | 100% | 0.0% (0/4) |  |
| c_last_testament | rule | 2 | 11.9% | 3.2% | 27% | 3.2% | 100% | 25.0% (1/4) |  |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 77.8% (98/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_sixth_die: 50.0% (4/8)
- c_spore_burst: 44.4% (8/18)
- c_descend: 38.5% (5/13)
- c_meme_nametag: 37.5% (3/8)
- c_sonic_shield: 31.0% (9/29)
- c_growing_shell: 30.4% (7/23)
- c_living_wall: 30.3% (10/33)
- c_prime_chain: 30.0% (6/20)
- c_backline_glow: 26.1% (12/46)
- c_thorn_pact: 25.0% (3/12)

Bottom 10:
- c_finisher: 9.5% (2/21)
- c_mana_ward: 11.1% (1/9)
- c_chimera_hunt: 11.1% (1/9)
- c_smoldering: 12.5% (1/8)
- c_elder_trunk: 12.5% (4/32)
- c_overflow: 16.7% (2/12)
- c_nest: 17.6% (3/17)
- c_dewdrop: 17.8% (8/45)
- c_hunters_reward: 18.2% (2/11)
- c_meme_jumpy: 18.2% (2/11)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_prime_chain + c_sonic_shield: 41.7% (5/12)
- c_growing_shell + c_living_wall: 41.7% (5/12)
- c_backline_glow + c_growing_shell: 38.5% (5/13)
- c_backline_glow + c_sonic_shield: 33.3% (4/12)
- c_bastion + c_living_wall: 33.3% (3/9)
- c_gatekeeper + c_thorn_growth: 10.0% (1/10)
- c_early_scales + c_elder_trunk: 10.0% (1/10)
- c_early_scales + c_thorn_shield: 14.3% (2/14)
- c_dewdrop + c_early_scales: 15.4% (2/13)
- c_elder_trunk + c_thorn_shield: 15.4% (2/13)
