# Sim balance metric-baseline-all

Runs: 1600, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 13.0% -> CHUA DAT
- attack_spam <= 5%: 14.5% -> CHUA DAT
- expert 15-25%: 28.0% -> CHUA DAT
- expert - random >= 15 diem: 15.0 diem -> DAT


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=200): r4 battle -11 (con 94%); r5 elite -23 (con 83%); r5 battle -2 (con 82%); r6 boss -39 (con 62%); r8 battle -1 (con 62%); r9 elite -14 (con 55%); r10 battle -2 (con 54%); r12 boss -26 (con 41%); r13 battle -4 (con 39%); r14 battle -1 (con 38%); r15 elite -13 (con 32%); r18 boss -35 (con 14%)
- **expert** (n=200): r4 battle -2 (con 99%); r5 elite -3 (con 98%); r6 boss -9 (con 93%); r7 battle -2 (con 92%); r8 battle -2 (con 91%); r9 elite -13 (con 84%); r9 battle -1 (con 84%); r11 battle -1 (con 84%); r12 boss -37 (con 65%); r15 elite -18 (con 56%); r18 boss -56 (con 28%)
- **expert_legacy** (n=200): r4 battle -7 (con 96%); r5 elite -15 (con 89%); r5 battle -1 (con 88%); r6 boss -11 (con 83%); r8 battle -3 (con 82%); r9 elite -21 (con 71%); r11 battle -1 (con 70%); r12 boss -29 (con 56%); r15 elite -11 (con 50%); r16 battle -1 (con 50%); r17 battle -1 (con 50%); r18 boss -55 (con 22%)
- **expert_no_lieu** (n=200): r4 battle -3 (con 98%); r5 elite -7 (con 95%); r6 boss -9 (con 90%); r8 battle -1 (con 90%); r9 elite -11 (con 84%); r11 battle -2 (con 84%); r12 boss -31 (con 68%); r13 battle -1 (con 68%); r14 battle -1 (con 67%); r15 elite -13 (con 60%); r18 boss -66 (con 28%)
- **expert_no_overcast** (n=200): r4 battle -2 (con 99%); r5 elite -8 (con 95%); r6 boss -6 (con 92%); r8 battle -2 (con 91%); r9 elite -13 (con 84%); r9 battle -1 (con 84%); r11 battle -2 (con 83%); r12 boss -44 (con 61%); r15 elite -16 (con 53%); r18 boss -42 (con 32%)
- **expert_no_wild** (n=200): r5 elite -11 (con 94%); r6 boss -6 (con 92%); r8 battle -3 (con 90%); r9 elite -13 (con 84%); r9 battle -1 (con 83%); r11 battle -1 (con 82%); r12 boss -36 (con 64%); r15 elite -19 (con 55%); r15 battle -2 (con 54%); r18 boss -47 (con 30%)
- **free_hold** (n=200): r4 battle -5 (con 98%); r5 elite -22 (con 86%); r5 battle -2 (con 86%); r6 boss -24 (con 74%); r9 elite -10 (con 68%); r12 boss -46 (con 46%); r15 elite -18 (con 36%); r17 battle -1 (con 36%); r18 boss -35 (con 18%)
- **random_legal** (n=200): r4 battle -15 (con 92%); r5 battle -2 (con 92%); r5 elite -19 (con 82%); r6 boss -13 (con 76%); r8 battle -2 (con 74%); r9 elite -21 (con 64%); r9 battle -2 (con 63%); r10 battle -3 (con 62%); r11 battle -3 (con 60%); r12 boss -23 (con 48%); r13 battle -1 (con 48%); r14 battle -1 (con 48%); r15 battle -1 (con 47%); r15 elite -14 (con 40%); r16 battle -2 (con 39%); r17 battle -2 (con 38%); r18 boss -50 (con 13%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 19.12 +-1.28 | 20.20 +-0.93 | 20.20 +-0.93 | 13.75 +-1.13 | 6.73 +-0.42 | 0.52 +-0.07 | 14.5 +-4.9 | 
| expert | 200 | 29.86 +-1.46 | 23.68 +-0.90 | 30.33 +-1.10 | 22.24 +-1.33 | 4.96 +-0.28 | 0.44 +-0.07 | 28.0 +-6.2 | 
| expert_legacy | 200 | 25.14 +-1.47 | 23.22 +-0.99 | 24.67 +-1.00 | 18.91 +-1.39 | 5.60 +-0.33 | 0.44 +-0.06 | 22.0 +-5.8 | 
| expert_no_lieu | 200 | 29.46 +-1.44 | 24.47 +-0.97 | 30.48 +-1.21 | 22.34 +-1.30 | 5.07 +-0.25 | 0.42 +-0.06 | 27.5 +-6.2 | 
| expert_no_overcast | 200 | 29.63 +-1.55 | 23.94 +-0.92 | 30.22 +-1.18 | 21.54 +-1.34 | 4.82 +-0.25 | 0.44 +-0.06 | 32.0 +-6.5 | 
| expert_no_wild | 200 | 28.67 +-1.43 | 24.42 +-1.01 | 28.54 +-1.11 | 21.54 +-1.34 | 5.01 +-0.29 | 0.48 +-0.06 | 30.5 +-6.4 | 
| free_hold | 200 | 22.84 +-1.45 | 22.18 +-0.96 | 24.04 +-0.97 | 17.40 +-1.32 | 6.15 +-0.43 | 0.40 +-0.06 | 18.5 +-5.4 | 
| random_legal | 200 | 22.26 +-1.42 | 22.55 +-1.00 | 22.55 +-1.00 | 17.26 +-1.35 | 5.82 +-0.43 | 0.50 +-0.07 | 13.0 +-4.7 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | -10.74 +-1.64 (n=200) | -3.48 +-1.10 (n=200) | -10.13 +-1.29 (n=200) | -8.49 +-1.58 (n=200) | +1.89 +-0.44 (n=160) | +0.06 +-0.12 (n=36) | -13.50 +-7.18 (n=200) | 
| expert_legacy | 200 | -4.71 +-1.62 (n=200) | -0.46 +-1.06 (n=200) | -5.66 +-1.21 (n=200) | -3.32 +-1.63 (n=200) | +0.65 +-0.39 (n=174) | +0.03 +-0.12 (n=47) | -6.00 +-7.56 (n=200) | 
| expert_no_lieu | 200 | -0.39 +-1.65 (n=200) | +0.79 +-1.03 (n=200) | +0.15 +-1.20 (n=200) | +0.11 +-1.61 (n=200) | +0.13 +-0.36 (n=187) | -0.02 +-0.12 (n=44) | -0.50 +-7.92 (n=200) | 
| expert_no_overcast | 200 | -0.23 +-1.35 (n=200) | +0.26 +-0.74 (n=200) | -0.11 +-0.92 (n=200) | -0.69 +-1.34 (n=200) | -0.15 +-0.28 (n=189) | +0.03 +-0.09 (n=67) | +4.00 +-6.78 (n=200) | 
| expert_no_wild | 200 | -1.18 +-1.64 (n=200) | +0.74 +-1.07 (n=200) | -1.79 +-1.18 (n=200) | -0.70 +-1.60 (n=200) | +0.05 +-0.36 (n=187) | -0.01 +-0.11 (n=56) | +2.50 +-8.15 (n=200) | 
| free_hold | 200 | -7.01 +-1.62 (n=200) | -1.50 +-1.08 (n=200) | -6.29 +-1.20 (n=200) | -4.83 +-1.63 (n=200) | +1.31 +-0.46 (n=168) | -0.04 +-0.11 (n=38) | -9.50 +-7.43 (n=200) | 
| random_legal | 200 | -7.60 +-1.66 (n=200) | -1.12 +-1.09 (n=200) | -7.78 +-1.20 (n=200) | -4.97 +-1.66 (n=200) | +0.93 +-0.47 (n=159) | +0.04 +-0.12 (n=41) | -15.00 +-7.58 (n=200) | 


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 14.5% (29/200) |
| expert | 0 | 28.0% (56/200) |
| expert_legacy | 0 | 22.0% (44/200) |
| expert_no_lieu | 0 | 27.5% (55/200) |
| expert_no_overcast | 0 | 32.0% (64/200) |
| expert_no_wild | 0 | 30.5% (61/200) |
| free_hold | 0 | 18.5% (37/200) |
| random_legal | 0 | 13.0% (26/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 10.0% (3/30) |
| attack_spam | beast_bird | 23.3% (7/30) |
| attack_spam | mixed_dmg | 13.3% (4/30) |
| attack_spam | mixed_std | 6.7% (2/30) |
| attack_spam | reptile_bug | 16.7% (5/30) |
| attack_spam | tank_heavy | 4.0% (1/25) |
| attack_spam | thorn_shield | 28.0% (7/25) |
| expert | aqua_plant | 13.3% (4/30) |
| expert | beast_bird | 26.7% (8/30) |
| expert | mixed_dmg | 26.7% (8/30) |
| expert | mixed_std | 33.3% (10/30) |
| expert | reptile_bug | 33.3% (10/30) |
| expert | tank_heavy | 36.0% (9/25) |
| expert | thorn_shield | 28.0% (7/25) |
| expert_legacy | aqua_plant | 16.7% (5/30) |
| expert_legacy | beast_bird | 20.0% (6/30) |
| expert_legacy | mixed_dmg | 30.0% (9/30) |
| expert_legacy | mixed_std | 13.3% (4/30) |
| expert_legacy | reptile_bug | 23.3% (7/30) |
| expert_legacy | tank_heavy | 28.0% (7/25) |
| expert_legacy | thorn_shield | 24.0% (6/25) |
| expert_no_lieu | aqua_plant | 30.0% (9/30) |
| expert_no_lieu | beast_bird | 30.0% (9/30) |
| expert_no_lieu | mixed_dmg | 33.3% (10/30) |
| expert_no_lieu | mixed_std | 16.7% (5/30) |
| expert_no_lieu | reptile_bug | 23.3% (7/30) |
| expert_no_lieu | tank_heavy | 40.0% (10/25) |
| expert_no_lieu | thorn_shield | 20.0% (5/25) |
| expert_no_overcast | aqua_plant | 23.3% (7/30) |
| expert_no_overcast | beast_bird | 30.0% (9/30) |
| expert_no_overcast | mixed_dmg | 30.0% (9/30) |
| expert_no_overcast | mixed_std | 33.3% (10/30) |
| expert_no_overcast | reptile_bug | 33.3% (10/30) |
| expert_no_overcast | tank_heavy | 44.0% (11/25) |
| expert_no_overcast | thorn_shield | 32.0% (8/25) |
| expert_no_wild | aqua_plant | 20.0% (6/30) |
| expert_no_wild | beast_bird | 16.7% (5/30) |
| expert_no_wild | mixed_dmg | 36.7% (11/30) |
| expert_no_wild | mixed_std | 36.7% (11/30) |
| expert_no_wild | reptile_bug | 33.3% (10/30) |
| expert_no_wild | tank_heavy | 40.0% (10/25) |
| expert_no_wild | thorn_shield | 32.0% (8/25) |
| free_hold | aqua_plant | 3.3% (1/30) |
| free_hold | beast_bird | 33.3% (10/30) |
| free_hold | mixed_dmg | 23.3% (7/30) |
| free_hold | mixed_std | 10.0% (3/30) |
| free_hold | reptile_bug | 20.0% (6/30) |
| free_hold | tank_heavy | 16.0% (4/25) |
| free_hold | thorn_shield | 24.0% (6/25) |
| random_legal | aqua_plant | 3.3% (1/30) |
| random_legal | beast_bird | 16.7% (5/30) |
| random_legal | mixed_dmg | 10.0% (3/30) |
| random_legal | mixed_std | 13.3% (4/30) |
| random_legal | reptile_bug | 20.0% (6/30) |
| random_legal | tank_heavy | 24.0% (6/25) |
| random_legal | thorn_shield | 4.0% (1/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 16.7% (10/60) |
| attack_spam | greedy_axis | 14.3% (10/70) |
| attack_spam | random | 12.9% (9/70) |
| expert | combo | 40.0% (24/60) |
| expert | greedy_axis | 28.6% (20/70) |
| expert | random | 17.1% (12/70) |
| expert_legacy | combo | 31.7% (19/60) |
| expert_legacy | greedy_axis | 17.1% (12/70) |
| expert_legacy | random | 18.6% (13/70) |
| expert_no_lieu | combo | 30.0% (18/60) |
| expert_no_lieu | greedy_axis | 18.6% (13/70) |
| expert_no_lieu | random | 34.3% (24/70) |
| expert_no_overcast | combo | 35.0% (21/60) |
| expert_no_overcast | greedy_axis | 38.6% (27/70) |
| expert_no_overcast | random | 22.9% (16/70) |
| expert_no_wild | combo | 31.7% (19/60) |
| expert_no_wild | greedy_axis | 28.6% (20/70) |
| expert_no_wild | random | 31.4% (22/70) |
| free_hold | combo | 23.3% (14/60) |
| free_hold | greedy_axis | 17.1% (12/70) |
| free_hold | random | 15.7% (11/70) |
| random_legal | combo | 18.3% (11/60) |
| random_legal | greedy_axis | 10.0% (7/70) |
| random_legal | random | 11.4% (8/70) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=1312)
- attack_spam|boss: 6.2 luot (n=336)
- attack_spam|elite: 4.9 luot (n=170)
- expert_legacy|battle: 2.9 luot (n=1499)
- expert_legacy|boss: 5.4 luot (n=417)
- expert_legacy|elite: 4.2 luot (n=217)
- expert_no_lieu|battle: 2.7 luot (n=1633)
- expert_no_lieu|boss: 4.9 luot (n=478)
- expert_no_lieu|elite: 3.9 luot (n=238)
- expert_no_overcast|battle: 2.6 luot (n=1604)
- expert_no_overcast|boss: 4.7 luot (n=462)
- expert_no_overcast|elite: 3.7 luot (n=236)
- expert_no_wild|battle: 2.7 luot (n=1602)
- expert_no_wild|boss: 4.9 luot (n=462)
- expert_no_wild|elite: 4.1 luot (n=234)
- expert|battle: 2.6 luot (n=1614)
- expert|boss: 4.8 luot (n=474)
- expert|elite: 3.7 luot (n=243)
- free_hold|battle: 3.0 luot (n=1384)
- free_hold|boss: 5.8 luot (n=380)
- free_hold|elite: 4.4 luot (n=207)
- random_legal|battle: 3.3 luot (n=1406)
- random_legal|boss: 5.6 luot (n=360)
- random_legal|elite: 4.3 luot (n=190)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 2
- attack_spam|battle r13: 4
- attack_spam|battle r14: 1
- attack_spam|battle r4: 11
- attack_spam|battle r5: 2
- attack_spam|battle r8: 1
- attack_spam|boss r12: 26
- attack_spam|boss r18: 35
- attack_spam|boss r6: 39
- attack_spam|elite r15: 13
- attack_spam|elite r5: 23
- attack_spam|elite r9: 14
- expert_legacy|battle r11: 1
- expert_legacy|battle r16: 1
- expert_legacy|battle r17: 1
- expert_legacy|battle r4: 7
- expert_legacy|battle r5: 1
- expert_legacy|battle r8: 3
- expert_legacy|boss r12: 29
- expert_legacy|boss r18: 55
- expert_legacy|boss r6: 11
- expert_legacy|elite r15: 11
- expert_legacy|elite r5: 15
- expert_legacy|elite r9: 21
- expert_no_lieu|battle r11: 2
- expert_no_lieu|battle r13: 1
- expert_no_lieu|battle r14: 1
- expert_no_lieu|battle r4: 3
- expert_no_lieu|battle r8: 1
- expert_no_lieu|boss r12: 31
- expert_no_lieu|boss r18: 66
- expert_no_lieu|boss r6: 9
- expert_no_lieu|elite r15: 13
- expert_no_lieu|elite r5: 7
- expert_no_lieu|elite r9: 11
- expert_no_overcast|battle r11: 2
- expert_no_overcast|battle r4: 2
- expert_no_overcast|battle r8: 2
- expert_no_overcast|battle r9: 1
- expert_no_overcast|boss r12: 44
- expert_no_overcast|boss r18: 42
- expert_no_overcast|boss r6: 6
- expert_no_overcast|elite r15: 16
- expert_no_overcast|elite r5: 8
- expert_no_overcast|elite r9: 13
- expert_no_wild|battle r11: 1
- expert_no_wild|battle r15: 2
- expert_no_wild|battle r8: 3
- expert_no_wild|battle r9: 1
- expert_no_wild|boss r12: 36
- expert_no_wild|boss r18: 47
- expert_no_wild|boss r6: 6
- expert_no_wild|elite r15: 19
- expert_no_wild|elite r5: 11
- expert_no_wild|elite r9: 13
- expert|battle r11: 1
- expert|battle r4: 2
- expert|battle r7: 2
- expert|battle r8: 2
- expert|battle r9: 1
- expert|boss r12: 37
- expert|boss r18: 56
- expert|boss r6: 9
- expert|elite r15: 18
- expert|elite r5: 3
- expert|elite r9: 13
- free_hold|battle r17: 1
- free_hold|battle r4: 5
- free_hold|battle r5: 2
- free_hold|boss r12: 46
- free_hold|boss r18: 35
- free_hold|boss r6: 24
- free_hold|elite r15: 18
- free_hold|elite r5: 22
- free_hold|elite r9: 10
- random_legal|battle r10: 3
- random_legal|battle r11: 3
- random_legal|battle r13: 1
- random_legal|battle r14: 1
- random_legal|battle r15: 1
- random_legal|battle r16: 2
- random_legal|battle r17: 2
- random_legal|battle r4: 15
- random_legal|battle r5: 2
- random_legal|battle r8: 2
- random_legal|battle r9: 2
- random_legal|boss r12: 23
- random_legal|boss r18: 50
- random_legal|boss r6: 13
- random_legal|elite r15: 14
- random_legal|elite r5: 19
- random_legal|elite r9: 21

Tran ket > 20 luot hoac khong ket thuc: 8 / 17158

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 47.6% | 13.7% | 13.7% | 100% |  |
| c_dewdrop | stat | 0 | 49.9% | 19.6% | 19.6% | 100% |  |
| c_elder_trunk | stat | 0 | 46.6% | 20.4% | 20.4% | 100% |  |
| c_prime_chain | dice | 0 | 50.7% | 14.6% | 14.1% | 97% |  |
| c_finisher | dice | 0 | 46.8% | 16.1% | 15.4% | 96% |  |
| c_bastion | pos | 0 | 63.8% | 21.1% | 21.0% | 100% |  |
| c_tidecaller | mana | 0 | 53.5% | 9.0% | 0.3% | 3% |  |
| c_mana_pool | mana | 0 | 40.8% | 14.8% | 13.1% | 88% |  |
| c_nest | rule | 0 | 50.9% | 16.9% | 16.9% | 100% |  |
| c_spore_burst | rule | 0 | 49.9% | 18.1% | 17.7% | 98% |  |
| c_fossil | rule | 0 | 31.6% | 8.4% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.0% | 2.5% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 9.5% | 4.5% | 0.6% | 12% | LOW |
| rule_tundra | run_rule | 0 | 9.5% | 5.5% | 0.9% | 17% | LOW |
| rule_quick_beat | run_rule | 0 | 11.0% | 5.5% | 4.8% | 88% |  |
| rule_starfall | run_rule | 0 | 13.5% | 6.5% | 6.5% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 15.0% | 9.5% | 9.5% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.0% | 4.5% | 4.5% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 12.5% | 8.5% | 8.5% | 100% |  |
| rule_rising_tide | run_rule | 0 | 13.5% | 5.5% | 5.5% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.0% | 7.5% | 7.5% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.5% | 13.0% | 13.0% | 100% |  |
| rule_crow | run_rule | 0 | 13.5% | 6.5% | 5.8% | 89% |  |
| rule_hard_shell | run_rule | 0 | 19.5% | 7.5% | 7.5% | 100% |  |
| rule_balance | run_rule | 0 | 25.0% | 13.0% | 13.0% | 100% |  |
| c_prism | dice | 1 | 11.2% | 5.4% | 2.1% | 40% |  |
| c_steady_hold | dice | 1 | 12.4% | 4.4% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 11.8% | 4.4% | 0.8% | 18% |  |
| c_sonic_shield | dice | 1 | 10.6% | 4.2% | 4.1% | 97% |  |
| c_fissure | dice | 1 | 7.2% | 3.2% | 3.1% | 98% | LOW |
| c_field_medic | dice | 1 | 13.2% | 3.0% | 3.0% | 100% |  |
| c_plague_spread | dice | 1 | 7.6% | 3.2% | 3.1% | 98% | LOW |
| c_gatekeeper | pos | 1 | 21.9% | 10.1% | 9.9% | 98% |  |
| c_thorn_growth | pos | 1 | 24.0% | 7.0% | 6.9% | 99% |  |
| c_thorn_shield | stat | 1 | 72.2% | 17.1% | 16.2% | 95% |  |
| c_backline_glow | pos | 1 | 28.0% | 12.7% | 11.1% | 88% |  |
| c_growing_shell | pos | 1 | 23.6% | 9.8% | 8.6% | 88% |  |
| c_mana_ward | mana | 1 | 29.4% | 8.8% | 5.1% | 59% |  |
| c_overflow | mana | 1 | 25.3% | 9.8% | 4.9% | 51% |  |
| c_thorn_pact | mana | 1 | 23.9% | 11.1% | 10.8% | 97% |  |
| c_dry_well | quest | 1 | 25.7% | 2.5% | 2.5% | 100% |  |
| c_night_watch | quest | 1 | 23.8% | 3.4% | 3.4% | 100% |  |
| c_key_strike | quest | 1 | 23.2% | 2.4% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 24.8% | 6.6% | 6.6% | 100% |  |
| c_chimera_hunt | quest | 1 | 25.8% | 5.8% | 4.8% | 84% |  |
| c_golden_egg | rule | 1 | 10.4% | 8.7% | 4.9% | 57% |  |
| c_dim_stone | rule | 1 | 17.1% | 4.9% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 12.2% | 4.1% | 4.3% | 100% |  |
| c_sixth_die | dice | 2 | 11.8% | 5.7% | 6.0% | 100% |  |
| c_whittle | dice | 2 | 10.6% | 2.9% | 2.9% | 100% |  |
| c_three_dice | dice | 2 | 12.1% | 5.2% | 5.3% | 100% |  |
| c_concord | dice | 2 | 8.3% | 2.1% | 2.1% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.2% | 1.7% | 1.7% | 100% | LOW |
| c_living_wall | pos | 2 | 28.6% | 12.3% | 12.8% | 100% |  |
| c_thorn_rebound | rule | 2 | 16.4% | 5.2% | 4.9% | 78% |  |
| c_open_ranks | pos | 2 | 4.8% | 1.6% | 1.6% | 100% | LOW |
| c_descend | pos | 2 | 18.1% | 6.7% | 6.4% | 95% |  |
| c_hollow_core | mana | 2 | 23.4% | 8.0% | 6.2% | 77% |  |
| c_deep_current | mana | 2 | 30.9% | 8.8% | 6.2% | 66% |  |
| c_blood_sign | rule | 2 | 11.4% | 5.8% | 6.2% | 100% |  |
| c_loop | rule | 2 | 12.8% | 5.3% | 5.0% | 85% |  |
| c_cascade | rule | 2 | 13.1% | 6.2% | 6.8% | 98% |  |
| c_sacrifice | rule | 2 | 15.8% | 5.6% | 6.1% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 68.4% (1094/1600)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 62.2% (178/286)
- c_golden_egg: 53.2% (74/139)
- c_cascade: 50.5% (56/111)
- c_loop: 47.3% (44/93)
- c_blood_sign: 46.0% (46/100)
- c_nest: 44.4% (120/270)
- c_thorn_rebound: 43.9% (43/98)
- c_sixth_die: 36.5% (35/96)
- c_key_strike: 35.9% (14/39)
- c_living_wall: 35.8% (73/204)

Bottom 10:
- c_fossil: 0.0% (0/11)
- c_dry_well: 7.5% (3/40)
- c_three_dice: 11.8% (10/85)
- c_tidecaller: 13.7% (19/139)
- c_bastion: 15.7% (50/319)
- c_prism: 16.3% (14/86)
- c_open_ranks: 16.7% (4/24)
- c_prime_chain: 17.3% (40/231)
- c_steady_hold: 17.4% (12/69)
- c_finisher: 18.0% (44/245)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_spore_burst + c_three_dice: 100.0% (9/9)
- c_sixth_die + c_spore_burst: 91.7% (11/12)
- c_cascade + c_spore_burst: 83.7% (41/49)
- c_backline_glow + c_spore_burst: 78.9% (30/38)
- c_loop + c_spore_burst: 77.8% (35/45)
- c_steady_hold + c_three_dice: 0.0% (0/8)
- c_elder_trunk + c_prism: 0.0% (0/9)
- c_field_medic + c_steady_hold: 0.0% (0/9)
- c_finisher + c_mana_ward: 0.0% (0/8)
- c_bastion + c_three_dice: 0.0% (0/10)
