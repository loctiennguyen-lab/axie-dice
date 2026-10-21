# Sim balance anchor-expert_a_volley

Runs: 200, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 11.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_volley | 200 | 100.0 | 11.0 +-4.3 | 14.0 | 7.6 | 17.8 | 28.47 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 4.5% | 0.5% |
| expert | h_gambler | 12.5% | 1.0% |
| expert | h_mana_mine | 3.0% | 0.0% |
| expert | h_kin | 7.5% | 2.5% |
| expert | h_embers | 1.0% | 0.5% |
| expert | h_big_hand | 1.0% | 0.5% |
| expert | combos formed avg | 0.29 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=200): r3 battle -4 (con 98%); r4 battle -1 (con 98%); r5 battle -1 (con 97%); r5 elite -24 (con 85%); r6 boss -24 (con 73%); r7 battle -2 (con 72%); r8 battle -3 (con 70%); r9 elite -23 (con 59%); r9 battle -1 (con 58%); r10 battle -4 (con 56%); r11 battle -3 (con 55%); r12 boss -42 (con 34%); r13 battle -1 (con 34%); r15 elite -15 (con 26%); r15 battle -1 (con 26%); r17 battle -1 (con 25%); r18 boss -28 (con 11%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 200 | 26.78 +-1.53 | 20.16 +-0.81 | 25.67 +-1.06 | 19.81 +-1.29 | 5.20 +-0.33 | 0.51 +-0.08 | 11.0 +-4.3 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 200 | 30.02 | 1.34 | 1.15 | 3.78 | 85 | 281 | 0.56 | 0.00 | 0.14 | 0.02 | 0.62 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 4 | 21 | 23 | 38 | 4.43 | 0.66 | 16.14 | 3.56 | 4.04 | 10.02 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (713) | 0% (0) | 31.7 | 16.7 | 9.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 11.0% (22/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 10.0% (3/30) |
| expert | beast_bird | 16.7% (5/30) |
| expert | mixed_dmg | 6.7% (2/30) |
| expert | mixed_std | 13.3% (4/30) |
| expert | reptile_bug | 13.3% (4/30) |
| expert | tank_heavy | 12.0% (3/25) |
| expert | thorn_shield | 4.0% (1/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 11.7% (7/60) |
| expert | greedy_axis | 8.6% (6/70) |
| expert | random | 12.9% (9/70) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=1306)
- expert|boss: 5.1 luot (n=330)
- expert|elite: 3.8 luot (n=206)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 4
- expert|battle r11: 3
- expert|battle r13: 1
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r3: 4
- expert|battle r4: 1
- expert|battle r5: 1
- expert|battle r7: 2
- expert|battle r8: 3
- expert|battle r9: 1
- expert|boss r12: 42
- expert|boss r18: 28
- expert|boss r6: 24
- expert|elite r15: 15
- expert|elite r5: 24
- expert|elite r9: 23

Tran ket > 20 luot hoac khong ket thuc: 0 / 1842

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 41.5% | 11.5% | 28% | 11.5% | 100% | 26.1% (6/23) |  |
| c_dewdrop | stat | 0 | 42.5% | 18.0% | 42% | 18.0% | 100% | 13.9% (5/36) |  |
| c_elder_trunk | stat | 0 | 46.0% | 21.5% | 47% | 21.5% | 100% | 18.6% (8/43) |  |
| c_prime_chain | dice | 0 | 27.5% | 7.0% | 25% | 6.5% | 93% | 0.0% (0/14) |  |
| c_finisher | dice | 0 | 28.5% | 11.0% | 39% | 11.0% | 100% | 13.6% (3/22) |  |
| c_bastion | pos | 0 | 68.0% | 26.5% | 39% | 25.0% | 94% | 9.4% (5/53) |  |
| c_tidecaller | mana | 0 | 41.0% | 7.5% | 18% | 4.0% | 53% | 6.7% (1/15) |  |
| c_mana_pool | mana | 0 | 31.0% | 10.0% | 32% | 9.0% | 90% | 0.0% (0/20) |  |
| c_nest | rule | 0 | 35.0% | 14.5% | 41% | 14.5% | 100% | 27.6% (8/29) |  |
| c_spore_burst | rule | 0 | 32.0% | 10.5% | 33% | 10.5% | 100% | 52.4% (11/21) |  |
| c_fossil | rule | 0 | 20.0% | 5.5% | 28% | 5.5% | 100% | 36.4% (4/11) |  |
| c_meme_copycat | dice | 0 | 25.0% | 4.5% | 18% | 3.5% | 78% | 11.1% (1/9) |  |
| c_meme_nametag | rule | 0 | 28.0% | 7.0% | 25% | 7.0% | 100% | 14.3% (2/14) |  |
| c_meme_jumpy | dice | 0 | 24.0% | 4.0% | 17% | 4.0% | 100% | 12.5% (1/8) |  |
| rule_none | run_rule | 0 | 9.0% | 5.0% | 56% | 0.0% | 0% | 10.0% (1/10) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.5% | 6.0% | 48% | 5.0% | 83% | 0.0% (0/12) |  |
| rule_tundra | run_rule | 0 | 12.0% | 6.0% | 50% | 6.0% | 100% | 8.3% (1/12) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.0% | 48% | 5.5% | 92% | 8.3% (1/12) |  |
| rule_starfall | run_rule | 0 | 11.5% | 8.0% | 70% | 8.0% | 100% | 6.2% (1/16) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.5% | 59% | 6.5% | 100% | 15.4% (2/13) |  |
| rule_wasteland | run_rule | 0 | 11.5% | 7.0% | 61% | 7.0% | 100% | 28.6% (4/14) |  |
| rule_dry_steppe | run_rule | 0 | 16.5% | 8.0% | 48% | 8.0% | 100% | 0.0% (0/16) |  |
| rule_rising_tide | run_rule | 0 | 8.5% | 4.5% | 53% | 4.5% | 100% | 22.2% (2/9) | LOW |
| rule_upside_down | run_rule | 0 | 14.0% | 8.5% | 61% | 8.5% | 100% | 5.9% (1/17) |  |
| rule_old_forest | run_rule | 0 | 24.0% | 10.5% | 44% | 10.5% | 100% | 23.8% (5/21) |  |
| rule_crow | run_rule | 0 | 11.5% | 5.0% | 43% | 4.0% | 80% | 0.0% (0/10) |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 6.5% | 32% | 6.5% | 100% | 30.8% (4/13) |  |
| rule_balance | run_rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 0.0% (0/25) |  |
| c_prism | dice | 1 | 12.5% | 5.0% | 40% | 1.5% | 30% | 20.0% (2/10) |  |
| c_steady_hold | dice | 1 | 7.5% | 2.0% | 27% | 2.0% | 100% | 0.0% (0/4) | LOW |
| c_kindle | dice | 1 | 12.5% | 5.5% | 44% | 5.5% | 100% | 9.1% (1/11) |  |
| c_sonic_shield | dice | 1 | 13.0% | 4.5% | 35% | 4.5% | 100% | 44.4% (4/9) |  |
| c_fissure | dice | 1 | 7.0% | 1.0% | 14% | 0.5% | 50% | 0.0% (0/2) | LOW |
| c_field_medic | dice | 1 | 8.5% | 3.5% | 41% | 3.5% | 100% | 28.6% (2/7) | LOW |
| c_plague_spread | dice | 1 | 6.0% | 1.5% | 25% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_gatekeeper | pos | 1 | 20.5% | 7.0% | 34% | 7.0% | 100% | 7.1% (1/14) |  |
| c_thorn_growth | pos | 1 | 20.0% | 5.5% | 28% | 5.5% | 100% | 0.0% (0/11) |  |
| c_thorn_shield | stat | 1 | 68.5% | 25.0% | 36% | 24.0% | 96% | 14.0% (7/50) |  |
| c_growing_shell | pos | 1 | 24.0% | 10.5% | 44% | 9.5% | 90% | 9.5% (2/21) |  |
| c_backline_glow | pos | 1 | 31.0% | 14.0% | 45% | 13.0% | 93% | 10.7% (3/28) |  |
| c_mana_ward | mana | 1 | 21.0% | 4.5% | 21% | 2.5% | 56% | 0.0% (0/9) |  |
| c_overflow | mana | 1 | 17.5% | 8.0% | 46% | 5.5% | 69% | 0.0% (0/16) |  |
| c_thorn_pact | mana | 1 | 16.0% | 7.5% | 47% | 7.0% | 93% | 20.0% (3/15) |  |
| c_dry_well | quest | 1 | 19.5% | 2.5% | 13% | 2.5% | 100% | 0.0% (0/5) |  |
| c_night_watch | quest | 1 | 18.0% | 1.5% | 8% | 1.5% | 100% | 33.3% (1/3) |  |
| c_key_strike | quest | 1 | 15.5% | 3.0% | 19% | 1.0% | 33% | 33.3% (2/6) |  |
| c_collector | quest | 1 | 15.5% | 2.0% | 13% | 2.0% | 100% | 50.0% (2/4) |  |
| c_chimera_hunt | quest | 1 | 16.5% | 3.5% | 21% | 1.5% | 43% | 42.9% (3/7) |  |
| c_golden_egg | rule | 1 | 8.5% | 6.5% | 76% | 4.0% | 62% | 23.1% (3/13) | LOW |
| c_dim_stone | rule | 1 | 10.5% | 2.0% | 19% | 2.0% | 100% | 25.0% (1/4) |  |
| c_mirror_face | dice | 2 | 8.5% | 1.5% | 18% | 1.5% | 100% | 0.0% (0/3) | LOW |
| c_sixth_die | dice | 2 | 12.5% | 5.0% | 40% | 5.0% | 100% | 40.0% (4/10) |  |
| c_whittle | dice | 2 | 10.5% | 3.5% | 33% | 3.5% | 100% | 14.3% (1/7) |  |
| c_three_dice | dice | 2 | 8.0% | 2.0% | 25% | 2.0% | 100% | 0.0% (0/4) | LOW |
| c_concord | dice | 2 | 2.5% | 0.5% | 20% | 0.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 8.5% | 2.0% | 24% | 2.0% | 100% | 0.0% (0/4) | LOW |
| c_living_wall | pos | 2 | 25.5% | 12.5% | 49% | 12.5% | 100% | 16.0% (4/25) |  |
| c_thorn_rebound | rule | 2 | 11.5% | 1.5% | 13% | 2.0% | 100% | 33.3% (1/3) |  |
| c_open_ranks | pos | 2 | 2.5% | 1.5% | 60% | 2.0% | 100% | 0.0% (0/3) | LOW |
| c_descend | pos | 2 | 17.5% | 6.5% | 37% | 6.5% | 100% | 15.4% (2/13) |  |
| c_hollow_core | mana | 2 | 22.0% | 8.5% | 39% | 6.5% | 76% | 11.8% (2/17) |  |
| c_deep_current | mana | 2 | 20.0% | 5.5% | 28% | 4.0% | 73% | 18.2% (2/11) |  |
| c_blood_sign | rule | 2 | 11.5% | 4.5% | 39% | 5.0% | 100% | 22.2% (2/9) |  |
| c_loop | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 80% | 0.0% (0/5) |  |
| c_cascade | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 20.0% (1/5) | LOW |
| c_sacrifice | rule | 2 | 7.5% | 2.0% | 27% | 2.0% | 100% | 25.0% (1/4) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 62.5% (125/200)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 52.4% (11/21)
- c_sonic_shield: 44.4% (4/9)
- c_sixth_die: 40.0% (4/10)
- c_fossil: 36.4% (4/11)
- c_blood_sign: 30.0% (3/10)
- c_nest: 27.6% (8/29)
- c_early_scales: 26.1% (6/23)
- c_golden_egg: 23.1% (3/13)
- c_prism: 20.0% (2/10)
- c_thorn_pact: 20.0% (3/15)

Bottom 10:
- c_mana_pool: 0.0% (0/20)
- c_prime_chain: 0.0% (0/14)
- c_thorn_growth: 0.0% (0/11)
- c_mana_ward: 0.0% (0/9)
- c_overflow: 0.0% (0/16)
- c_tidecaller: 6.7% (1/15)
- c_gatekeeper: 7.1% (1/14)
- c_kindle: 9.1% (1/11)
- c_bastion: 9.4% (5/53)
- c_growing_shell: 9.5% (2/21)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_nest + c_spore_burst: 63.6% (7/11)
- c_dewdrop + c_early_scales: 44.4% (4/9)
- c_early_scales + c_thorn_shield: 35.7% (5/14)
- c_golden_egg + c_nest: 23.1% (3/13)
- c_early_scales + c_elder_trunk: 22.2% (2/9)
- c_bastion + c_thorn_growth: 0.0% (0/8)
- c_hollow_core + c_mana_pool: 0.0% (0/8)
- c_bastion + c_growing_shell: 0.0% (0/14)
- c_bastion + c_living_wall: 8.3% (1/12)
- c_backline_glow + c_living_wall: 10.0% (1/10)
