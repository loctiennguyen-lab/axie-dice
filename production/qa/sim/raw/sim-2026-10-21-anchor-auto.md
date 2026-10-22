# Sim balance anchor-auto

Runs: 800, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 7.0% -> CHUA DAT
- attack_spam <= 5%: 7.5% -> CHUA DAT
- expert 15-25%: 11.0% -> CHUA DAT
- expert - random >= 15 diem: 4.0 diem -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| attack_spam | a_gambler | 64 | 32.0 | 9.4 +-7.1 | 21.9 | 6.2 | 18.4 | 18.43 |
| attack_spam | a_mana_mine | 60 | 30.0 | 8.3 +-7.0 | 11.7 | 4.4 | 16.1 | 20.45 |
| attack_spam | a_volley | 76 | 38.0 | 5.3 +-5.0 | 6.6 | 9.4 | 28.0 | 19.46 |
| expert | a_gambler | 90 | 45.0 | 10.0 +-6.2 | 38.9 | 6.5 | 15.2 | 29.83 |
| expert | a_mana_mine | 30 | 15.0 | 16.7 +-13.3 | 23.3 | 6.1 | 11.0 | 27.03 |
| expert | a_volley | 80 | 40.0 | 10.0 +-6.6 | 12.5 | 6.8 | 19.2 | 25.26 |
| free_hold | a_gambler | 90 | 45.0 | 10.0 +-6.2 | 30.0 | 6.0 | 18.3 | 23.76 |
| free_hold | a_mana_mine | 30 | 15.0 | 3.3 +-6.4 | 10.0 | 6.7 | 18.0 | 12.97 |
| free_hold | a_volley | 80 | 40.0 | 5.0 +-4.8 | 12.5 | 7.5 | 25.6 | 18.82 |
| random_legal | a_gambler | 64 | 32.0 | 7.8 +-6.6 | 17.2 | 5.6 | 18.8 | 17.52 |
| random_legal | a_mana_mine | 60 | 30.0 | 6.7 +-6.3 | 18.3 | 7.8 | 22.2 | 18.69 |
| random_legal | a_volley | 76 | 38.0 | 6.6 +-5.6 | 3.9 | 7.3 | 29.0 | 18.96 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| attack_spam | h_volley | 0.5% | 0.0% |
| attack_spam | h_gambler | 9.5% | 0.0% |
| attack_spam | h_mana_mine | 5.5% | 0.5% |
| attack_spam | h_kin | 4.0% | 2.0% |
| attack_spam | h_embers | 1.0% | 0.5% |
| attack_spam | h_big_hand | 0.0% | 0.0% |
| attack_spam | combos formed avg | 0.21 | |
| expert | h_volley | 3.0% | 1.0% |
| expert | h_gambler | 15.5% | 1.0% |
| expert | h_mana_mine | 5.5% | 1.5% |
| expert | h_kin | 5.0% | 2.0% |
| expert | h_embers | 1.0% | 0.5% |
| expert | h_big_hand | 1.0% | 0.0% |
| expert | combos formed avg | 0.33 | |
| free_hold | h_volley | 1.0% | 0.5% |
| free_hold | h_gambler | 13.0% | 0.5% |
| free_hold | h_mana_mine | 3.0% | 0.5% |
| free_hold | h_kin | 3.5% | 1.0% |
| free_hold | h_embers | 0.5% | 0.0% |
| free_hold | h_big_hand | 0.0% | 0.0% |
| free_hold | combos formed avg | 0.21 | |
| random_legal | h_volley | 1.0% | 0.0% |
| random_legal | h_gambler | 7.0% | 1.0% |
| random_legal | h_mana_mine | 5.0% | 0.5% |
| random_legal | h_kin | 3.0% | 1.5% |
| random_legal | h_embers | 1.5% | 0.5% |
| random_legal | h_big_hand | 0.0% | 0.0% |
| random_legal | combos formed avg | 0.18 | |


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=200): r3 battle -3 (con 98%); r4 battle -5 (con 96%); r5 elite -42 (con 75%); r5 battle -4 (con 73%); r6 boss -49 (con 48%); r7 battle -1 (con 48%); r8 battle -1 (con 48%); r9 elite -25 (con 35%); r10 battle -2 (con 34%); r11 battle -4 (con 32%); r12 boss -17 (con 24%); r13 battle -3 (con 22%); r14 battle -1 (con 22%); r15 elite -11 (con 16%); r16 battle -1 (con 16%); r18 boss -16 (con 8%)
- **expert** (n=200): r3 battle -4 (con 98%); r4 battle -2 (con 97%); r5 elite -19 (con 88%); r5 battle -1 (con 87%); r6 boss -30 (con 72%); r7 battle -3 (con 70%); r8 battle -3 (con 69%); r9 battle -1 (con 68%); r9 elite -20 (con 58%); r10 battle -1 (con 58%); r11 battle -5 (con 56%); r12 boss -41 (con 35%); r15 elite -18 (con 26%); r15 battle -1 (con 26%); r17 battle -1 (con 25%); r18 boss -28 (con 11%)
- **free_hold** (n=200): r3 battle -3 (con 98%); r4 battle -11 (con 93%); r5 elite -30 (con 78%); r5 battle -1 (con 78%); r6 boss -65 (con 45%); r7 battle -2 (con 44%); r8 battle -2 (con 43%); r9 elite -17 (con 34%); r11 battle -2 (con 34%); r12 boss -26 (con 20%); r13 battle -1 (con 20%); r15 elite -8 (con 16%); r18 boss -18 (con 7%)
- **random_legal** (n=200): r2 battle -1 (con 100%); r3 battle -9 (con 95%); r4 battle -15 (con 88%); r5 elite -43 (con 66%); r5 battle -8 (con 62%); r6 boss -40 (con 42%); r7 battle -1 (con 42%); r8 battle -2 (con 40%); r9 elite -22 (con 30%); r9 battle -3 (con 28%); r10 battle -1 (con 28%); r11 battle -3 (con 26%); r12 boss -15 (con 18%); r15 elite -7 (con 15%); r16 battle -1 (con 14%); r18 boss -15 (con 7%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 17.22 +-1.17 | 17.56 +-0.72 | 17.56 +-0.72 | 12.07 +-1.08 | 6.67 +-0.41 | 0.48 +-0.07 | 7.5 +-3.7 | 
| expert | 200 | 25.46 +-1.43 | 20.07 +-0.81 | 26.20 +-1.16 | 18.81 +-1.26 | 5.48 +-0.32 | 0.50 +-0.07 | 11.0 +-4.3 | 
| free_hold | 200 | 17.97 +-1.24 | 17.58 +-0.73 | 19.25 +-0.80 | 13.24 +-1.13 | 7.19 +-0.47 | 0.38 +-0.08 | 7.0 +-3.5 | 
| random_legal | 200 | 16.48 +-1.29 | 17.11 +-0.85 | 17.11 +-0.85 | 11.91 +-1.19 | 7.18 +-0.59 | 0.44 +-0.08 | 7.0 +-3.5 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | -8.25 +-1.57 (n=200) | -2.52 +-0.97 (n=200) | -8.64 +-1.25 (n=200) | -6.74 +-1.52 (n=200) | +1.19 +-0.54 (n=132) | +0.02 +-0.14 (n=27) | -3.50 +-5.45 (n=200) | 
| free_hold | 200 | -7.50 +-1.56 (n=200) | -2.50 +-0.95 (n=200) | -6.94 +-1.18 (n=200) | -5.57 +-1.48 (n=200) | +1.84 +-0.58 (n=140) | -0.06 +-0.19 (n=21) | -4.00 +-5.17 (n=200) | 
| random_legal | 200 | -8.99 +-1.65 (n=200) | -2.97 +-1.02 (n=200) | -9.09 +-1.32 (n=200) | -6.90 +-1.54 (n=200) | +1.51 +-0.64 (n=113) | +0.04 +-0.17 (n=21) | -4.00 +-5.35 (n=200) | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 32.40 | 0.64 | 0.40 | 6.26 | 63 | 973 | 0.41 | 0.00 | 0.18 | 0.05 | 0.00 |
| expert | 200 | 31.28 | 1.50 | 1.29 | 4.81 | 86 | 321 | 0.58 | 0.00 | 0.15 | 0.04 | 0.73 |
| free_hold | 200 | 30.04 | 1.28 | 0.44 | 7.84 | 34 | 611 | 0.44 | 0.00 | 0.25 | 0.03 | 0.56 |
| random_legal | 200 | 28.96 | 1.13 | 0.86 | 6.64 | 76 | 586 | 0.63 | 0.00 | 0.16 | 0.03 | 0.31 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| expert | 14 | 5 | 22 | 23 | 37 | 5.04 | 1.11 | 18.35 | 3.85 | 4.89 | 10.00 |
| free_hold | 2 | 1 | 0 | 0 | 97 | 0.21 | 0.17 | 20.18 | 0.00 | 0.00 | 0.00 |
| random_legal | 8 | 1 | 6 | 5 | 81 | 1.77 | 0.10 | 4.66 | 0.61 | 0.73 | 8.22 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 16.1 | 11.6 | 11.6 |
| expert | 0% (0) | 100% (770) | 0% (0) | 33.2 | 19.0 | 10.9 |
| free_hold | 0% (0) | 0% (0) | 0% (0) | 33.0 | 20.2 | 21.1 |
| random_legal | 0% (0) | 100% (122) | 0% (0) | 14.1 | 8.0 | 8.0 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.01; expert 0.00; free_hold 0.00; random_legal 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 7.5% (15/200) |
| expert | 0 | 11.0% (22/200) |
| free_hold | 0 | 7.0% (14/200) |
| random_legal | 0 | 7.0% (14/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 0.0% (0/30) |
| attack_spam | beast_bird | 10.0% (3/30) |
| attack_spam | mixed_dmg | 10.0% (3/30) |
| attack_spam | mixed_std | 3.3% (1/30) |
| attack_spam | reptile_bug | 16.7% (5/30) |
| attack_spam | tank_heavy | 4.0% (1/25) |
| attack_spam | thorn_shield | 8.0% (2/25) |
| expert | aqua_plant | 16.7% (5/30) |
| expert | beast_bird | 6.7% (2/30) |
| expert | mixed_dmg | 10.0% (3/30) |
| expert | mixed_std | 13.3% (4/30) |
| expert | reptile_bug | 13.3% (4/30) |
| expert | tank_heavy | 12.0% (3/25) |
| expert | thorn_shield | 4.0% (1/25) |
| free_hold | aqua_plant | 3.3% (1/30) |
| free_hold | beast_bird | 13.3% (4/30) |
| free_hold | mixed_dmg | 13.3% (4/30) |
| free_hold | mixed_std | 3.3% (1/30) |
| free_hold | reptile_bug | 10.0% (3/30) |
| free_hold | tank_heavy | 4.0% (1/25) |
| free_hold | thorn_shield | 0.0% (0/25) |
| random_legal | aqua_plant | 0.0% (0/30) |
| random_legal | beast_bird | 16.7% (5/30) |
| random_legal | mixed_dmg | 6.7% (2/30) |
| random_legal | mixed_std | 6.7% (2/30) |
| random_legal | reptile_bug | 6.7% (2/30) |
| random_legal | tank_heavy | 4.0% (1/25) |
| random_legal | thorn_shield | 8.0% (2/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 11.7% (7/60) |
| attack_spam | greedy_axis | 5.7% (4/70) |
| attack_spam | random | 5.7% (4/70) |
| expert | combo | 5.0% (3/60) |
| expert | greedy_axis | 17.1% (12/70) |
| expert | random | 10.0% (7/70) |
| free_hold | combo | 5.0% (3/60) |
| free_hold | greedy_axis | 4.3% (3/70) |
| free_hold | random | 11.4% (8/70) |
| random_legal | combo | 6.7% (4/60) |
| random_legal | greedy_axis | 4.3% (3/70) |
| random_legal | random | 10.0% (7/70) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.8 luot (n=1085)
- attack_spam|boss: 6.4 luot (n=241)
- attack_spam|elite: 4.9 luot (n=163)
- expert|battle: 2.8 luot (n=1316)
- expert|boss: 5.3 luot (n=335)
- expert|elite: 4.2 luot (n=197)
- free_hold|battle: 3.4 luot (n=1052)
- free_hold|boss: 6.7 luot (n=254)
- free_hold|elite: 4.9 luot (n=155)
- random_legal|battle: 3.8 luot (n=992)
- random_legal|boss: 6.7 luot (n=205)
- random_legal|elite: 4.9 luot (n=141)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 2
- attack_spam|battle r11: 4
- attack_spam|battle r13: 3
- attack_spam|battle r14: 1
- attack_spam|battle r16: 1
- attack_spam|battle r3: 3
- attack_spam|battle r4: 5
- attack_spam|battle r5: 4
- attack_spam|battle r7: 1
- attack_spam|battle r8: 1
- attack_spam|boss r12: 17
- attack_spam|boss r18: 16
- attack_spam|boss r6: 49
- attack_spam|elite r15: 11
- attack_spam|elite r5: 42
- attack_spam|elite r9: 25
- expert|battle r10: 1
- expert|battle r11: 5
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r3: 4
- expert|battle r4: 2
- expert|battle r5: 1
- expert|battle r7: 3
- expert|battle r8: 3
- expert|battle r9: 1
- expert|boss r12: 41
- expert|boss r18: 28
- expert|boss r6: 30
- expert|elite r15: 18
- expert|elite r5: 19
- expert|elite r9: 20
- free_hold|battle r11: 2
- free_hold|battle r13: 1
- free_hold|battle r3: 3
- free_hold|battle r4: 11
- free_hold|battle r5: 1
- free_hold|battle r7: 2
- free_hold|battle r8: 2
- free_hold|boss r12: 26
- free_hold|boss r18: 18
- free_hold|boss r6: 65
- free_hold|elite r15: 8
- free_hold|elite r5: 30
- free_hold|elite r9: 17
- random_legal|battle r10: 1
- random_legal|battle r11: 3
- random_legal|battle r16: 1
- random_legal|battle r2: 1
- random_legal|battle r3: 9
- random_legal|battle r4: 15
- random_legal|battle r5: 8
- random_legal|battle r7: 1
- random_legal|battle r8: 2
- random_legal|battle r9: 3
- random_legal|boss r12: 15
- random_legal|boss r18: 15
- random_legal|boss r6: 40
- random_legal|elite r15: 7
- random_legal|elite r5: 43
- random_legal|elite r9: 22

Tran ket > 20 luot hoac khong ket thuc: 2 / 6136

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 36.9% | 9.1% | 25% | 9.1% | 100% | 16.4% (12/73) |  |
| c_dewdrop | stat | 0 | 39.5% | 16.2% | 41% | 16.2% | 100% | 15.4% (20/130) |  |
| c_elder_trunk | stat | 0 | 44.4% | 22.0% | 50% | 22.0% | 100% | 11.9% (21/176) |  |
| c_prime_chain | dice | 0 | 22.0% | 6.1% | 28% | 5.2% | 86% | 12.2% (6/49) |  |
| c_finisher | dice | 0 | 22.8% | 7.6% | 34% | 7.5% | 98% | 11.5% (7/61) |  |
| c_bastion | pos | 0 | 60.5% | 21.0% | 35% | 21.0% | 100% | 6.0% (10/168) |  |
| c_tidecaller | mana | 0 | 46.9% | 12.6% | 27% | 1.9% | 15% | 7.9% (8/101) |  |
| c_mana_pool | mana | 0 | 38.9% | 13.8% | 35% | 12.5% | 91% | 6.4% (7/110) |  |
| c_nest | rule | 0 | 30.2% | 10.6% | 35% | 10.6% | 100% | 22.4% (19/85) |  |
| c_spore_burst | rule | 0 | 30.2% | 9.1% | 30% | 9.1% | 100% | 43.8% (32/73) |  |
| c_fossil | rule | 0 | 21.1% | 5.8% | 27% | 4.5% | 78% | 21.7% (10/46) |  |
| c_meme_copycat | dice | 0 | 19.9% | 4.6% | 23% | 4.1% | 89% | 8.1% (3/37) |  |
| c_meme_nametag | rule | 0 | 25.1% | 6.4% | 25% | 5.9% | 92% | 17.6% (9/51) |  |
| c_meme_jumpy | dice | 0 | 18.6% | 3.6% | 19% | 3.6% | 100% | 3.4% (1/29) |  |
| rule_none | run_rule | 0 | 9.0% | 5.0% | 56% | 0.0% | 0% | 7.5% (3/40) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.5% | 6.0% | 48% | 2.8% | 46% | 8.3% (4/48) |  |
| rule_tundra | run_rule | 0 | 12.0% | 6.0% | 50% | 3.1% | 52% | 4.2% (2/48) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 6.0% | 48% | 4.4% | 73% | 0.0% (0/48) |  |
| rule_starfall | run_rule | 0 | 11.5% | 8.0% | 70% | 8.0% | 100% | 10.9% (7/64) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.5% | 59% | 6.5% | 100% | 7.7% (4/52) |  |
| rule_wasteland | run_rule | 0 | 11.5% | 7.0% | 61% | 7.0% | 100% | 7.1% (4/56) |  |
| rule_dry_steppe | run_rule | 0 | 16.5% | 8.0% | 48% | 8.0% | 100% | 4.7% (3/64) |  |
| rule_rising_tide | run_rule | 0 | 8.5% | 4.5% | 53% | 4.5% | 100% | 13.9% (5/36) | LOW |
| rule_upside_down | run_rule | 0 | 14.0% | 8.5% | 61% | 8.5% | 100% | 2.9% (2/68) |  |
| rule_old_forest | run_rule | 0 | 24.0% | 10.5% | 44% | 10.5% | 100% | 14.3% (12/84) |  |
| rule_crow | run_rule | 0 | 11.5% | 5.0% | 43% | 4.1% | 82% | 10.0% (4/40) |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 6.5% | 32% | 6.5% | 100% | 13.5% (7/52) |  |
| rule_balance | run_rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 8.0% (8/100) |  |
| c_prism | dice | 1 | 8.0% | 2.4% | 30% | 1.1% | 47% | 5.3% (1/19) | LOW |
| c_steady_hold | dice | 1 | 7.2% | 1.5% | 21% | 1.0% | 67% | 0.0% (0/12) | LOW |
| c_kindle | dice | 1 | 7.9% | 4.0% | 51% | 2.0% | 50% | 6.2% (2/32) | LOW |
| c_sonic_shield | dice | 1 | 10.4% | 3.2% | 31% | 3.1% | 96% | 3.8% (1/26) |  |
| c_fissure | dice | 1 | 4.9% | 1.4% | 28% | 1.2% | 91% | 18.2% (2/11) | LOW |
| c_field_medic | dice | 1 | 8.0% | 2.6% | 33% | 2.6% | 100% | 23.8% (5/21) | LOW |
| c_plague_spread | dice | 1 | 5.0% | 1.2% | 25% | 1.2% | 100% | 20.0% (2/10) | LOW |
| c_gatekeeper | pos | 1 | 15.1% | 5.9% | 39% | 5.9% | 100% | 12.8% (6/47) |  |
| c_thorn_growth | pos | 1 | 16.1% | 4.2% | 26% | 4.0% | 94% | 14.7% (5/34) |  |
| c_thorn_shield | stat | 1 | 57.8% | 19.9% | 34% | 19.0% | 96% | 12.6% (20/159) |  |
| c_growing_shell | pos | 1 | 16.5% | 5.1% | 31% | 4.2% | 83% | 9.8% (4/41) |  |
| c_backline_glow | pos | 1 | 21.4% | 9.4% | 44% | 8.6% | 92% | 13.3% (10/75) |  |
| c_mana_ward | mana | 1 | 21.5% | 8.0% | 37% | 4.4% | 55% | 7.8% (5/64) |  |
| c_overflow | mana | 1 | 17.4% | 8.0% | 46% | 4.4% | 55% | 12.5% (8/64) |  |
| c_thorn_pact | mana | 1 | 18.9% | 9.8% | 52% | 9.8% | 100% | 10.3% (8/78) |  |
| c_dry_well | quest | 1 | 15.5% | 1.9% | 12% | 1.9% | 100% | 13.3% (2/15) |  |
| c_night_watch | quest | 1 | 15.5% | 1.4% | 9% | 1.4% | 100% | 9.1% (1/11) |  |
| c_key_strike | quest | 1 | 14.2% | 2.6% | 18% | 0.2% | 10% | 19.0% (4/21) |  |
| c_collector | quest | 1 | 16.6% | 3.4% | 20% | 3.4% | 100% | 25.9% (7/27) |  |
| c_chimera_hunt | quest | 1 | 14.2% | 4.2% | 30% | 3.0% | 71% | 17.6% (6/34) |  |
| c_golden_egg | rule | 1 | 4.9% | 3.8% | 77% | 2.4% | 63% | 20.0% (6/30) | LOW |
| c_dim_stone | rule | 1 | 8.4% | 1.5% | 18% | 1.5% | 100% | 16.7% (2/12) | LOW |
| c_mirror_face | dice | 2 | 7.4% | 2.1% | 29% | 2.1% | 100% | 35.3% (6/17) | LOW |
| c_sixth_die | dice | 2 | 5.4% | 1.8% | 33% | 1.9% | 100% | 14.3% (2/14) | LOW |
| c_whittle | dice | 2 | 5.8% | 2.0% | 35% | 2.1% | 100% | 6.2% (1/16) | LOW |
| c_three_dice | dice | 2 | 5.6% | 2.5% | 44% | 2.5% | 100% | 5.0% (1/20) | LOW |
| c_concord | dice | 2 | 3.9% | 0.9% | 23% | 0.9% | 100% | 0.0% (0/7) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 0.9% | 22% | 0.9% | 100% | 0.0% (0/7) | LOW |
| c_living_wall | pos | 2 | 18.4% | 7.9% | 43% | 8.0% | 100% | 15.9% (10/63) |  |
| c_thorn_rebound | rule | 2 | 8.5% | 1.8% | 21% | 1.8% | 79% | 28.6% (4/14) | LOW |
| c_open_ranks | pos | 2 | 3.0% | 0.8% | 25% | 0.9% | 100% | 0.0% (0/6) | LOW |
| c_descend | pos | 2 | 10.9% | 4.0% | 37% | 3.9% | 97% | 31.2% (10/32) |  |
| c_hollow_core | mana | 2 | 15.8% | 6.4% | 40% | 4.4% | 69% | 13.7% (7/51) |  |
| c_deep_current | mana | 2 | 18.9% | 5.5% | 29% | 4.1% | 73% | 15.9% (7/44) |  |
| c_blood_sign | rule | 2 | 5.9% | 1.8% | 30% | 1.8% | 100% | 28.6% (4/14) | LOW |
| c_loop | rule | 2 | 6.8% | 1.4% | 20% | 1.1% | 64% | 18.2% (2/11) | LOW |
| c_cascade | rule | 2 | 5.4% | 2.6% | 49% | 2.8% | 100% | 38.1% (8/21) | LOW |
| c_sacrifice | rule | 2 | 8.9% | 2.5% | 28% | 2.5% | 100% | 0.0% (0/20) | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 48.4% (387/800)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 43.8% (32/73)
- c_cascade: 36.4% (8/22)
- c_mirror_face: 35.3% (6/17)
- c_descend: 31.2% (10/32)
- c_blood_sign: 28.6% (4/14)
- c_thorn_rebound: 27.8% (5/18)
- c_collector: 25.9% (7/27)
- c_field_medic: 23.8% (5/21)
- c_nest: 22.4% (19/85)
- c_fossil: 21.7% (10/46)

Bottom 10:
- c_steady_hold: 0.0% (0/12)
- c_sacrifice: 0.0% (0/20)
- c_meme_jumpy: 3.4% (1/29)
- c_sonic_shield: 3.8% (1/26)
- c_three_dice: 5.0% (1/20)
- c_prism: 5.3% (1/19)
- c_whittle: 5.9% (1/17)
- c_bastion: 6.0% (10/168)
- c_kindle: 6.2% (2/32)
- c_mana_pool: 6.4% (7/110)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_spore_burst + c_thorn_shield: 88.9% (8/9)
- c_cascade + c_spore_burst: 72.7% (8/11)
- c_elder_trunk + c_spore_burst: 62.5% (5/8)
- c_dewdrop + c_spore_burst: 62.5% (5/8)
- c_nest + c_spore_burst: 57.1% (16/28)
- c_mana_ward + c_overflow: 0.0% (0/18)
- c_deep_current + c_mana_ward: 0.0% (0/15)
- c_nest + c_sacrifice: 0.0% (0/8)
- c_bastion + c_growing_shell: 3.2% (1/31)
- c_thorn_pact + c_tidecaller: 4.0% (1/25)
