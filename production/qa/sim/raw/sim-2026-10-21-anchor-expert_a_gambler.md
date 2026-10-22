# Sim balance anchor-expert_a_gambler

Runs: 200, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 9.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 200 | 100.0 | 9.0 +-4.0 | 33.0 | 6.2 | 15.4 | 25.90 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 5.0% | 1.0% |
| expert | h_gambler | 16.0% | 1.0% |
| expert | h_mana_mine | 7.0% | 1.5% |
| expert | h_kin | 5.0% | 2.0% |
| expert | h_embers | 0.5% | 0.0% |
| expert | h_big_hand | 1.0% | 0.0% |
| expert | combos formed avg | 0.36 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=200): r3 battle -3 (con 98%); r4 battle -2 (con 98%); r5 elite -18 (con 88%); r5 battle -2 (con 88%); r6 boss -28 (con 74%); r7 battle -3 (con 72%); r8 battle -2 (con 71%); r9 battle -3 (con 70%); r9 elite -22 (con 58%); r10 battle -1 (con 58%); r11 battle -4 (con 56%); r12 boss -50 (con 31%); r15 elite -14 (con 24%); r15 battle -1 (con 24%); r16 battle -1 (con 23%); r18 boss -28 (con 9%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 200 | 24.48 +-1.41 | 19.72 +-0.86 | 25.88 +-1.15 | 17.81 +-1.19 | 5.53 +-0.33 | 0.50 +-0.07 | 9.0 +-4.0 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 200 | 32.18 | 1.46 | 1.28 | 4.96 | 88 | 339 | 0.56 | 0.00 | 0.17 | 0.05 | 0.69 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 19 | 24 | 39 | 5.14 | 1.08 | 19.23 | 3.98 | 4.87 | 10.01 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (796) | 0% (0) | 32.9 | 18.7 | 10.7 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 9.0% (18/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 10.0% (3/30) |
| expert | beast_bird | 6.7% (2/30) |
| expert | mixed_dmg | 10.0% (3/30) |
| expert | mixed_std | 13.3% (4/30) |
| expert | reptile_bug | 13.3% (4/30) |
| expert | tank_heavy | 8.0% (2/25) |
| expert | thorn_shield | 0.0% (0/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 5.0% (3/60) |
| expert | greedy_axis | 17.1% (12/70) |
| expert | random | 4.3% (3/70) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.9 luot (n=1299)
- expert|boss: 5.3 luot (n=333)
- expert|elite: 4.5 luot (n=193)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 4
- expert|battle r15: 1
- expert|battle r16: 1
- expert|battle r3: 3
- expert|battle r4: 2
- expert|battle r5: 2
- expert|battle r7: 3
- expert|battle r8: 2
- expert|battle r9: 3
- expert|boss r12: 50
- expert|boss r18: 28
- expert|boss r6: 28
- expert|elite r15: 14
- expert|elite r5: 18
- expert|elite r9: 22

Tran ket > 20 luot hoac khong ket thuc: 1 / 1825

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 43.0% | 9.5% | 22% | 9.5% | 100% | 21.1% (4/19) |  |
| c_dewdrop | stat | 0 | 43.0% | 18.0% | 42% | 18.0% | 100% | 13.9% (5/36) |  |
| c_elder_trunk | stat | 0 | 57.5% | 30.5% | 53% | 30.5% | 100% | 9.8% (6/61) |  |
| c_prime_chain | dice | 0 | 21.5% | 5.5% | 26% | 5.0% | 91% | 0.0% (0/11) |  |
| c_finisher | dice | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 0.0% (0/15) |  |
| c_bastion | pos | 0 | 57.0% | 17.5% | 31% | 17.5% | 100% | 11.4% (4/35) |  |
| c_tidecaller | mana | 0 | 51.5% | 10.5% | 20% | 4.5% | 43% | 4.8% (1/21) |  |
| c_mana_pool | mana | 0 | 46.5% | 15.5% | 33% | 13.5% | 87% | 6.5% (2/31) |  |
| c_nest | rule | 0 | 30.5% | 14.5% | 48% | 14.5% | 100% | 24.1% (7/29) |  |
| c_spore_burst | rule | 0 | 30.5% | 10.0% | 33% | 10.0% | 100% | 40.0% (8/20) |  |
| c_fossil | rule | 0 | 22.5% | 5.5% | 24% | 5.5% | 100% | 27.3% (3/11) |  |
| c_meme_copycat | dice | 0 | 19.5% | 2.5% | 13% | 2.0% | 80% | 0.0% (0/5) |  |
| c_meme_nametag | rule | 0 | 35.5% | 9.0% | 25% | 8.5% | 94% | 22.2% (4/18) |  |
| c_meme_jumpy | dice | 0 | 14.5% | 1.5% | 10% | 1.5% | 100% | 0.0% (0/3) |  |
| rule_none | run_rule | 0 | 9.0% | 5.0% | 56% | 0.0% | 0% | 0.0% (0/10) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.5% | 6.0% | 48% | 5.5% | 92% | 33.3% (4/12) |  |
| rule_tundra | run_rule | 0 | 12.0% | 6.0% | 50% | 6.0% | 100% | 0.0% (0/12) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.0% | 48% | 6.0% | 100% | 0.0% (0/12) |  |
| rule_starfall | run_rule | 0 | 11.5% | 8.0% | 70% | 8.0% | 100% | 6.2% (1/16) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.5% | 59% | 6.5% | 100% | 7.7% (1/13) |  |
| rule_wasteland | run_rule | 0 | 11.5% | 7.0% | 61% | 7.0% | 100% | 7.1% (1/14) |  |
| rule_dry_steppe | run_rule | 0 | 16.5% | 8.0% | 48% | 8.0% | 100% | 0.0% (0/16) |  |
| rule_rising_tide | run_rule | 0 | 8.5% | 4.5% | 53% | 4.5% | 100% | 11.1% (1/9) | LOW |
| rule_upside_down | run_rule | 0 | 14.0% | 8.5% | 61% | 8.5% | 100% | 0.0% (0/17) |  |
| rule_old_forest | run_rule | 0 | 24.0% | 10.5% | 44% | 10.5% | 100% | 9.5% (2/21) |  |
| rule_crow | run_rule | 0 | 11.5% | 5.0% | 43% | 3.5% | 70% | 10.0% (1/10) |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 6.5% | 32% | 6.5% | 100% | 15.4% (2/13) |  |
| rule_balance | run_rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 20.0% (5/25) |  |
| c_prism | dice | 1 | 8.0% | 1.5% | 19% | 0.5% | 33% | 0.0% (0/3) | LOW |
| c_steady_hold | dice | 1 | 10.5% | 1.0% | 10% | 1.0% | 100% | 0.0% (0/2) |  |
| c_kindle | dice | 1 | 9.0% | 5.0% | 56% | 5.0% | 100% | 0.0% (0/10) | LOW |
| c_sonic_shield | dice | 1 | 10.0% | 3.0% | 30% | 2.5% | 83% | 0.0% (0/6) |  |
| c_fissure | dice | 1 | 7.0% | 2.0% | 29% | 2.0% | 100% | 0.0% (0/4) | LOW |
| c_field_medic | dice | 1 | 6.5% | 2.5% | 38% | 2.5% | 100% | 0.0% (0/5) | LOW |
| c_plague_spread | dice | 1 | 5.0% | 1.0% | 20% | 1.0% | 100% | 50.0% (1/2) | LOW |
| c_gatekeeper | pos | 1 | 18.5% | 6.0% | 32% | 6.0% | 100% | 25.0% (3/12) |  |
| c_thorn_growth | pos | 1 | 16.5% | 3.5% | 21% | 3.5% | 100% | 42.9% (3/7) |  |
| c_thorn_shield | stat | 1 | 71.0% | 28.0% | 39% | 26.0% | 93% | 7.1% (4/56) |  |
| c_growing_shell | pos | 1 | 19.5% | 4.5% | 23% | 3.5% | 78% | 33.3% (3/9) |  |
| c_backline_glow | pos | 1 | 18.5% | 9.0% | 49% | 9.0% | 100% | 16.7% (3/18) |  |
| c_mana_ward | mana | 1 | 30.5% | 15.0% | 49% | 9.0% | 60% | 13.3% (4/30) |  |
| c_overflow | mana | 1 | 17.5% | 10.0% | 57% | 4.5% | 45% | 10.0% (2/20) |  |
| c_thorn_pact | mana | 1 | 28.5% | 17.5% | 61% | 17.5% | 100% | 5.7% (2/35) |  |
| c_dry_well | quest | 1 | 18.0% | 2.0% | 11% | 2.0% | 100% | 0.0% (0/4) |  |
| c_night_watch | quest | 1 | 24.5% | 2.5% | 10% | 2.5% | 100% | 40.0% (2/5) |  |
| c_key_strike | quest | 1 | 21.0% | 1.5% | 7% | 0.5% | 33% | 0.0% (0/3) |  |
| c_collector | quest | 1 | 20.5% | 4.5% | 22% | 4.5% | 100% | 33.3% (3/9) |  |
| c_chimera_hunt | quest | 1 | 22.0% | 5.0% | 23% | 4.0% | 80% | 0.0% (0/10) |  |
| c_golden_egg | rule | 1 | 6.5% | 5.0% | 77% | 3.5% | 70% | 0.0% (0/10) | LOW |
| c_dim_stone | rule | 1 | 11.0% | 2.0% | 18% | 2.0% | 100% | 25.0% (1/4) |  |
| c_mirror_face | dice | 2 | 9.0% | 1.0% | 11% | 1.0% | 100% | 0.0% (0/2) | LOW |
| c_sixth_die | dice | 2 | 6.5% | 2.5% | 38% | 2.5% | 100% | 20.0% (1/5) | LOW |
| c_whittle | dice | 2 | 12.0% | 2.5% | 21% | 3.0% | 100% | 0.0% (0/5) |  |
| c_three_dice | dice | 2 | 6.5% | 2.5% | 38% | 2.5% | 100% | 0.0% (0/5) | LOW |
| c_concord | dice | 2 | 2.0% | 0.5% | 25% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 0.5% | 12% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 25.0% | 11.5% | 46% | 11.5% | 100% | 13.0% (3/23) |  |
| c_thorn_rebound | rule | 2 | 9.5% | 2.5% | 26% | 2.0% | 80% | 40.0% (2/5) | LOW |
| c_open_ranks | pos | 2 | 1.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.0% | 5.0% | 42% | 5.0% | 100% | 20.0% (2/10) |  |
| c_hollow_core | mana | 2 | 23.0% | 9.0% | 39% | 7.5% | 83% | 16.7% (3/18) |  |
| c_deep_current | mana | 2 | 27.5% | 8.0% | 29% | 6.0% | 69% | 18.8% (3/16) |  |
| c_blood_sign | rule | 2 | 9.5% | 3.5% | 37% | 4.0% | 100% | 14.3% (1/7) | LOW |
| c_loop | rule | 2 | 7.5% | 1.5% | 20% | 1.5% | 100% | 66.7% (2/3) | LOW |
| c_cascade | rule | 2 | 7.5% | 4.5% | 60% | 4.5% | 100% | 11.1% (1/9) | LOW |
| c_sacrifice | rule | 2 | 10.5% | 4.5% | 43% | 4.5% | 100% | 11.1% (1/9) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 56.0% (112/200)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 40.0% (8/20)
- c_collector: 33.3% (3/9)
- c_growing_shell: 33.3% (3/9)
- c_fossil: 27.3% (3/11)
- c_gatekeeper: 25.0% (3/12)
- c_nest: 24.1% (7/29)
- c_deep_current: 23.5% (4/17)
- c_meme_nametag: 22.2% (4/18)
- c_early_scales: 21.1% (4/19)
- c_descend: 20.0% (2/10)

Bottom 10:
- c_kindle: 0.0% (0/10)
- c_prime_chain: 0.0% (0/11)
- c_golden_egg: 0.0% (0/10)
- c_finisher: 0.0% (0/15)
- c_chimera_hunt: 0.0% (0/10)
- c_tidecaller: 4.8% (1/21)
- c_thorn_pact: 5.7% (2/35)
- c_mana_pool: 6.5% (2/31)
- c_thorn_shield: 7.1% (4/56)
- c_elder_trunk: 9.8% (6/61)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_nest + c_spore_burst: 54.5% (6/11)
- c_meme_nametag + c_nest: 50.0% (4/8)
- c_meme_nametag + c_spore_burst: 44.4% (4/9)
- c_dewdrop + c_early_scales: 33.3% (4/12)
- c_early_scales + c_thorn_shield: 30.8% (4/13)
- c_overflow + c_tidecaller: 0.0% (0/8)
- c_golden_egg + c_nest: 0.0% (0/10)
- c_thorn_pact + c_tidecaller: 0.0% (0/8)
- c_mana_pool + c_thorn_pact: 0.0% (0/8)
- c_mana_ward + c_thorn_pact: 7.7% (1/13)
