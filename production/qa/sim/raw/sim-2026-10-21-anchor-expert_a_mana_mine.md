# Sim balance anchor-expert_a_mana_mine

Runs: 200, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 10.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 200 | 100.0 | 10.0 +-4.2 | 28.0 | 5.6 | 12.2 | 26.91 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.5% | 0.5% |
| expert | h_gambler | 11.5% | 0.0% |
| expert | h_mana_mine | 17.0% | 4.0% |
| expert | h_kin | 3.5% | 1.0% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.35 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=200): r3 battle -2 (con 99%); r4 battle -4 (con 97%); r5 battle -1 (con 96%); r5 elite -23 (con 85%); r6 boss -24 (con 73%); r7 battle -3 (con 72%); r8 battle -3 (con 70%); r9 elite -15 (con 62%); r10 battle -1 (con 62%); r11 battle -7 (con 58%); r12 boss -47 (con 35%); r13 battle -1 (con 34%); r14 battle -1 (con 34%); r15 elite -18 (con 25%); r15 battle -1 (con 24%); r17 battle -1 (con 24%); r18 boss -28 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 200 | 25.40 +-1.42 | 19.89 +-0.78 | 26.73 +-1.17 | 19.10 +-1.32 | 5.36 +-0.31 | 0.50 +-0.08 | 10.0 +-4.2 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 200 | 31.21 | 1.78 | 1.48 | 5.30 | 83 | 298 | 0.61 | 0.00 | 0.19 | 0.21 | 0.76 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 4 | 22 | 23 | 36 | 5.77 | 1.03 | 19.71 | 3.44 | 7.54 | 9.43 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (688) | 0% (0) | 33.7 | 25.5 | 14.9 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 10.0% (20/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (5/30) |
| expert | beast_bird | 3.3% (1/30) |
| expert | mixed_dmg | 16.7% (5/30) |
| expert | mixed_std | 16.7% (5/30) |
| expert | reptile_bug | 3.3% (1/30) |
| expert | tank_heavy | 4.0% (1/25) |
| expert | thorn_shield | 8.0% (2/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 5.0% (3/60) |
| expert | greedy_axis | 10.0% (7/70) |
| expert | random | 14.3% (10/70) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=1317)
- expert|boss: 5.2 luot (n=335)
- expert|elite: 4.1 luot (n=198)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 7
- expert|battle r13: 1
- expert|battle r14: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r3: 2
- expert|battle r4: 4
- expert|battle r5: 1
- expert|battle r7: 3
- expert|battle r8: 3
- expert|boss r12: 47
- expert|boss r18: 28
- expert|boss r6: 24
- expert|elite r15: 18
- expert|elite r5: 23
- expert|elite r9: 15

Tran ket > 20 luot hoac khong ket thuc: 0 / 1850

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 38.5% | 9.5% | 25% | 9.5% | 100% | 15.8% (3/19) |  |
| c_dewdrop | stat | 0 | 46.5% | 23.5% | 51% | 23.5% | 100% | 10.6% (5/47) |  |
| c_elder_trunk | stat | 0 | 45.0% | 18.0% | 40% | 18.0% | 100% | 13.9% (5/36) |  |
| c_prime_chain | dice | 0 | 20.0% | 3.0% | 15% | 3.0% | 100% | 0.0% (0/6) |  |
| c_finisher | dice | 0 | 23.0% | 6.5% | 28% | 6.0% | 92% | 23.1% (3/13) |  |
| c_bastion | pos | 0 | 57.0% | 15.0% | 26% | 15.0% | 100% | 13.3% (4/30) |  |
| c_tidecaller | mana | 0 | 54.5% | 27.5% | 50% | 12.0% | 44% | 7.3% (4/55) |  |
| c_mana_pool | mana | 0 | 45.5% | 23.0% | 51% | 20.5% | 89% | 6.5% (3/46) |  |
| c_nest | rule | 0 | 33.5% | 10.5% | 31% | 10.5% | 100% | 28.6% (6/21) |  |
| c_spore_burst | rule | 0 | 36.5% | 11.0% | 30% | 11.0% | 100% | 45.5% (10/22) |  |
| c_fossil | rule | 0 | 23.0% | 7.0% | 30% | 6.0% | 86% | 14.3% (2/14) |  |
| c_meme_copycat | dice | 0 | 19.5% | 2.5% | 13% | 2.0% | 80% | 0.0% (0/5) |  |
| c_meme_nametag | rule | 0 | 33.5% | 9.5% | 28% | 9.0% | 95% | 31.6% (6/19) |  |
| c_meme_jumpy | dice | 0 | 19.0% | 3.0% | 16% | 3.0% | 100% | 0.0% (0/6) |  |
| rule_none | run_rule | 0 | 9.0% | 5.0% | 56% | 0.0% | 0% | 10.0% (1/10) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.5% | 6.0% | 48% | 6.0% | 100% | 8.3% (1/12) |  |
| rule_tundra | run_rule | 0 | 12.0% | 6.0% | 50% | 6.0% | 100% | 8.3% (1/12) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.0% | 48% | 5.5% | 92% | 0.0% (0/12) |  |
| rule_starfall | run_rule | 0 | 11.5% | 8.0% | 70% | 8.0% | 100% | 18.8% (3/16) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.5% | 59% | 6.5% | 100% | 7.7% (1/13) |  |
| rule_wasteland | run_rule | 0 | 11.5% | 7.0% | 61% | 7.0% | 100% | 7.1% (1/14) |  |
| rule_dry_steppe | run_rule | 0 | 16.5% | 8.0% | 48% | 8.0% | 100% | 12.5% (2/16) |  |
| rule_rising_tide | run_rule | 0 | 8.5% | 4.5% | 53% | 4.5% | 100% | 0.0% (0/9) | LOW |
| rule_upside_down | run_rule | 0 | 14.0% | 8.5% | 61% | 8.5% | 100% | 5.9% (1/17) |  |
| rule_old_forest | run_rule | 0 | 24.0% | 10.5% | 44% | 10.5% | 100% | 19.0% (4/21) |  |
| rule_crow | run_rule | 0 | 11.5% | 5.0% | 43% | 4.5% | 90% | 20.0% (2/10) |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 6.5% | 32% | 6.5% | 100% | 7.7% (1/13) |  |
| rule_balance | run_rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 8.0% (2/25) |  |
| c_prism | dice | 1 | 7.0% | 1.5% | 21% | 0.0% | 0% | 33.3% (1/3) | LOW DEAD |
| c_steady_hold | dice | 1 | 6.5% | 0.5% | 8% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 8.5% | 4.0% | 47% | 3.5% | 88% | 0.0% (0/8) | LOW |
| c_sonic_shield | dice | 1 | 8.0% | 1.5% | 19% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_fissure | dice | 1 | 6.0% | 1.0% | 17% | 1.0% | 100% | 50.0% (1/2) | LOW |
| c_field_medic | dice | 1 | 11.0% | 4.5% | 41% | 4.5% | 100% | 11.1% (1/9) |  |
| c_plague_spread | dice | 1 | 6.5% | 1.5% | 23% | 1.5% | 100% | 33.3% (1/3) | LOW |
| c_gatekeeper | pos | 1 | 16.5% | 6.5% | 39% | 6.0% | 92% | 30.8% (4/13) |  |
| c_thorn_growth | pos | 1 | 16.5% | 4.0% | 24% | 4.0% | 100% | 25.0% (2/8) |  |
| c_thorn_shield | stat | 1 | 68.5% | 15.0% | 22% | 15.0% | 100% | 13.3% (4/30) |  |
| c_growing_shell | pos | 1 | 16.5% | 6.0% | 36% | 5.0% | 83% | 8.3% (1/12) |  |
| c_backline_glow | pos | 1 | 26.0% | 8.5% | 33% | 7.5% | 88% | 11.8% (2/17) |  |
| c_mana_ward | mana | 1 | 32.5% | 12.5% | 38% | 8.0% | 64% | 8.0% (2/25) |  |
| c_overflow | mana | 1 | 33.5% | 18.5% | 55% | 10.0% | 54% | 10.8% (4/37) |  |
| c_thorn_pact | mana | 1 | 26.0% | 14.0% | 54% | 14.0% | 100% | 7.1% (2/28) |  |
| c_dry_well | quest | 1 | 20.0% | 2.0% | 10% | 2.0% | 100% | 0.0% (0/4) |  |
| c_night_watch | quest | 1 | 23.5% | 2.5% | 11% | 2.5% | 100% | 20.0% (1/5) |  |
| c_key_strike | quest | 1 | 19.5% | 2.0% | 10% | 1.5% | 75% | 0.0% (0/4) |  |
| c_collector | quest | 1 | 22.5% | 2.0% | 9% | 2.0% | 100% | 25.0% (1/4) |  |
| c_chimera_hunt | quest | 1 | 19.0% | 4.5% | 24% | 2.5% | 56% | 11.1% (1/9) |  |
| c_golden_egg | rule | 1 | 5.5% | 3.0% | 55% | 2.0% | 67% | 16.7% (1/6) | LOW |
| c_dim_stone | rule | 1 | 12.5% | 3.0% | 24% | 3.0% | 100% | 50.0% (3/6) |  |
| c_mirror_face | dice | 2 | 6.5% | 1.0% | 15% | 1.0% | 100% | 0.0% (0/2) | LOW |
| c_sixth_die | dice | 2 | 4.0% | 0.5% | 12% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_whittle | dice | 2 | 10.5% | 2.0% | 19% | 2.0% | 100% | 0.0% (0/4) |  |
| c_three_dice | dice | 2 | 7.0% | 2.5% | 36% | 3.0% | 100% | 0.0% (0/5) | LOW |
| c_concord | dice | 2 | 4.5% | 1.0% | 22% | 1.0% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 18.0% | 7.5% | 42% | 7.5% | 100% | 13.3% (2/15) |  |
| c_thorn_rebound | rule | 2 | 9.0% | 2.5% | 28% | 2.0% | 60% | 40.0% (2/5) | LOW |
| c_open_ranks | pos | 2 | 3.5% | 1.5% | 43% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_descend | pos | 2 | 12.0% | 4.5% | 38% | 4.0% | 89% | 44.4% (4/9) |  |
| c_hollow_core | mana | 2 | 21.0% | 8.5% | 40% | 8.0% | 88% | 17.6% (3/17) |  |
| c_deep_current | mana | 2 | 36.0% | 18.0% | 50% | 12.5% | 67% | 11.1% (4/36) |  |
| c_blood_sign | rule | 2 | 7.5% | 3.5% | 47% | 3.5% | 100% | 0.0% (0/7) | LOW |
| c_loop | rule | 2 | 11.0% | 4.5% | 41% | 4.0% | 78% | 22.2% (2/9) |  |
| c_cascade | rule | 2 | 8.0% | 2.0% | 25% | 2.0% | 100% | 25.0% (1/4) | LOW |
| c_sacrifice | rule | 2 | 9.0% | 3.5% | 39% | 4.0% | 100% | 14.3% (1/7) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 63.5% (127/200)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 45.5% (10/22)
- c_descend: 44.4% (4/9)
- c_meme_nametag: 31.6% (6/19)
- c_gatekeeper: 30.8% (4/13)
- c_nest: 28.6% (6/21)
- c_thorn_growth: 25.0% (2/8)
- c_finisher: 23.1% (3/13)
- c_hollow_core: 22.2% (4/18)
- c_loop: 20.0% (2/10)
- c_early_scales: 15.8% (3/19)

Bottom 10:
- c_kindle: 0.0% (0/8)
- c_mana_pool: 6.5% (3/46)
- c_thorn_pact: 7.1% (2/28)
- c_tidecaller: 7.3% (4/55)
- c_mana_ward: 8.0% (2/25)
- c_growing_shell: 8.3% (1/12)
- c_dewdrop: 10.6% (5/47)
- c_overflow: 10.8% (4/37)
- c_chimera_hunt: 11.1% (1/9)
- c_field_medic: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_meme_nametag + c_spore_burst: 55.6% (5/9)
- c_hollow_core + c_tidecaller: 23.1% (3/13)
- c_dewdrop + c_elder_trunk: 18.2% (4/22)
- c_elder_trunk + c_thorn_shield: 15.8% (3/19)
- c_dewdrop + c_early_scales: 15.4% (2/13)
- c_deep_current + c_thorn_pact: 0.0% (0/9)
- c_overflow + c_thorn_pact: 0.0% (0/9)
- c_overflow + c_tidecaller: 0.0% (0/19)
- c_thorn_pact + c_tidecaller: 0.0% (0/12)
- c_hollow_core + c_mana_pool: 0.0% (0/8)
