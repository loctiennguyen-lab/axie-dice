# Sim balance metric-aplus-all

Runs: 1600, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 12.5% -> CHUA DAT
- attack_spam <= 5%: 11.5% -> CHUA DAT
- expert 15-25%: 22.0% -> DAT
- expert - random >= 15 diem: 9.5 diem -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=200): r4 battle -12 (con 94%); r5 elite -24 (con 82%); r5 battle -2 (con 81%); r6 boss -35 (con 64%); r7 battle -1 (con 63%); r8 battle -1 (con 62%); r9 elite -15 (con 55%); r10 battle -3 (con 54%); r11 battle -2 (con 52%); r12 boss -29 (con 38%); r13 battle -2 (con 37%); r14 battle -1 (con 36%); r15 elite -17 (con 28%); r15 battle -1 (con 28%); r18 boss -32 (con 12%)
- **expert** (n=200): r4 battle -4 (con 98%); r5 elite -12 (con 92%); r6 boss -6 (con 89%); r7 battle -1 (con 88%); r8 battle -4 (con 86%); r9 elite -16 (con 78%); r11 battle -2 (con 78%); r12 boss -37 (con 59%); r15 elite -14 (con 52%); r16 battle -1 (con 52%); r18 boss -59 (con 22%)
- **expert_legacy** (n=200): r4 battle -2 (con 99%); r5 elite -23 (con 88%); r6 boss -16 (con 80%); r7 battle -1 (con 79%); r8 battle -1 (con 78%); r9 elite -23 (con 67%); r9 battle -1 (con 66%); r10 battle -2 (con 66%); r11 battle -1 (con 65%); r12 boss -42 (con 44%); r13 battle -1 (con 44%); r15 elite -13 (con 37%); r15 battle -1 (con 36%); r18 boss -43 (con 15%)
- **expert_no_lieu** (n=200): r4 battle -3 (con 98%); r5 elite -14 (con 92%); r6 boss -7 (con 88%); r7 battle -1 (con 88%); r8 battle -6 (con 84%); r9 battle -1 (con 84%); r9 elite -23 (con 72%); r11 battle -6 (con 70%); r12 boss -39 (con 50%); r15 elite -8 (con 46%); r15 battle -1 (con 46%); r17 battle -1 (con 45%); r18 boss -48 (con 21%)
- **expert_no_overcast** (n=200): r4 battle -6 (con 97%); r5 elite -14 (con 90%); r6 boss -6 (con 87%); r7 battle -1 (con 86%); r8 battle -3 (con 85%); r9 battle -3 (con 84%); r9 elite -21 (con 73%); r10 battle -1 (con 72%); r12 boss -40 (con 52%); r15 elite -16 (con 44%); r16 battle -1 (con 44%); r18 boss -37 (con 26%)
- **expert_no_wild** (n=200): r4 battle -1 (con 100%); r5 elite -12 (con 94%); r6 boss -11 (con 88%); r7 battle -1 (con 88%); r8 battle -7 (con 84%); r9 elite -12 (con 78%); r12 boss -36 (con 60%); r14 battle -2 (con 59%); r15 elite -14 (con 52%); r15 battle -2 (con 51%); r18 boss -51 (con 26%)
- **free_hold** (n=200): r4 battle -6 (con 97%); r5 elite -29 (con 82%); r5 battle -2 (con 82%); r6 boss -20 (con 72%); r8 battle -2 (con 70%); r9 elite -18 (con 62%); r9 battle -1 (con 61%); r12 boss -37 (con 42%); r15 elite -15 (con 35%); r17 battle -1 (con 34%); r18 boss -36 (con 16%)
- **random_legal** (n=200): r4 battle -12 (con 94%); r5 battle -4 (con 92%); r5 elite -24 (con 80%); r6 boss -12 (con 74%); r7 battle -1 (con 74%); r8 battle -4 (con 72%); r9 elite -29 (con 57%); r9 battle -3 (con 56%); r10 battle -4 (con 54%); r11 battle -1 (con 53%); r12 boss -30 (con 38%); r13 battle -2 (con 37%); r14 battle -4 (con 35%); r15 elite -15 (con 28%); r17 battle -1 (con 27%); r18 boss -29 (con 12%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 18.65 +-1.22 | 19.73 +-0.92 | 19.73 +-0.92 | 13.47 +-1.15 | 6.73 +-0.41 | 0.48 +-0.08 | 11.5 +-4.4 | 
| expert | 200 | 27.93 +-1.42 | 23.16 +-0.95 | 29.33 +-1.15 | 20.32 +-1.22 | 4.82 +-0.25 | 0.52 +-0.06 | 22.0 +-5.8 | 
| expert_legacy | 200 | 22.88 +-1.25 | 21.56 +-0.88 | 23.10 +-0.91 | 16.53 +-1.14 | 5.97 +-0.37 | 0.42 +-0.06 | 15.0 +-5.0 | 
| expert_no_lieu | 200 | 26.57 +-1.36 | 22.80 +-0.94 | 28.30 +-1.16 | 19.27 +-1.27 | 4.98 +-0.25 | 0.46 +-0.07 | 21.0 +-5.7 | 
| expert_no_overcast | 200 | 27.97 +-1.53 | 22.90 +-0.98 | 28.96 +-1.15 | 20.37 +-1.36 | 4.80 +-0.30 | 0.50 +-0.06 | 25.5 +-6.1 | 
| expert_no_wild | 200 | 28.49 +-1.48 | 23.47 +-0.95 | 28.40 +-1.13 | 20.83 +-1.30 | 4.98 +-0.28 | 0.47 +-0.06 | 25.5 +-6.1 | 
| free_hold | 200 | 22.40 +-1.46 | 21.59 +-1.03 | 23.59 +-1.05 | 16.92 +-1.36 | 5.90 +-0.38 | 0.48 +-0.06 | 16.5 +-5.2 | 
| random_legal | 200 | 20.19 +-1.25 | 20.61 +-0.83 | 20.61 +-0.83 | 15.31 +-1.25 | 5.99 +-0.39 | 0.53 +-0.06 | 12.5 +-4.6 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | -9.28 +-1.68 (n=200) | -3.43 +-1.24 (n=200) | -9.60 +-1.38 (n=200) | -6.85 +-1.63 (n=200) | +1.88 +-0.43 (n=151) | -0.01 +-0.16 (n=30) | -10.50 +-7.14 (n=200) | 
| expert_legacy | 200 | -5.05 +-1.61 (n=200) | -1.60 +-1.08 (n=200) | -6.23 +-1.24 (n=200) | -3.79 +-1.50 (n=200) | +1.23 +-0.42 (n=164) | -0.15 +-0.14 (n=36) | -7.00 +-7.29 (n=200) | 
| expert_no_lieu | 200 | -1.36 +-1.54 (n=200) | -0.36 +-0.98 (n=200) | -1.03 +-1.15 (n=200) | -1.05 +-1.52 (n=200) | +0.16 +-0.30 (n=173) | -0.17 +-0.12 (n=38) | -1.00 +-7.22 (n=200) | 
| expert_no_overcast | 200 | +0.04 +-1.36 (n=200) | -0.26 +-0.87 (n=200) | -0.37 +-1.01 (n=200) | +0.05 +-1.24 (n=200) | -0.02 +-0.32 (n=177) | -0.02 +-0.07 (n=59) | +3.50 +-6.86 (n=200) | 
| expert_no_wild | 200 | +0.56 +-1.55 (n=200) | +0.31 +-1.05 (n=200) | -0.93 +-1.21 (n=200) | +0.51 +-1.45 (n=200) | +0.16 +-0.28 (n=176) | -0.03 +-0.09 (n=45) | +3.50 +-7.66 (n=200) | 
| free_hold | 200 | -5.53 +-1.66 (n=200) | -1.57 +-1.22 (n=200) | -5.74 +-1.38 (n=200) | -3.40 +-1.63 (n=200) | +1.06 +-0.42 (n=150) | -0.16 +-0.13 (n=28) | -5.50 +-7.25 (n=200) | 
| random_legal | 200 | -7.74 +-1.60 (n=200) | -2.55 +-1.12 (n=200) | -8.72 +-1.27 (n=200) | -5.01 +-1.55 (n=200) | +1.21 +-0.44 (n=149) | -0.02 +-0.15 (n=37) | -9.50 +-7.03 (n=200) | 


## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 11.5% (23/200) |
| expert | 0 | 22.0% (44/200) |
| expert_legacy | 0 | 15.0% (30/200) |
| expert_no_lieu | 0 | 21.0% (42/200) |
| expert_no_overcast | 0 | 25.5% (51/200) |
| expert_no_wild | 0 | 25.5% (51/200) |
| free_hold | 0 | 16.5% (33/200) |
| random_legal | 0 | 12.5% (25/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 6.7% (2/30) |
| attack_spam | beast_bird | 10.0% (3/30) |
| attack_spam | mixed_dmg | 10.0% (3/30) |
| attack_spam | mixed_std | 6.7% (2/30) |
| attack_spam | reptile_bug | 20.0% (6/30) |
| attack_spam | tank_heavy | 8.0% (2/25) |
| attack_spam | thorn_shield | 20.0% (5/25) |
| expert | aqua_plant | 23.3% (7/30) |
| expert | beast_bird | 20.0% (6/30) |
| expert | mixed_dmg | 10.0% (3/30) |
| expert | mixed_std | 16.7% (5/30) |
| expert | reptile_bug | 30.0% (9/30) |
| expert | tank_heavy | 36.0% (9/25) |
| expert | thorn_shield | 20.0% (5/25) |
| expert_legacy | aqua_plant | 3.3% (1/30) |
| expert_legacy | beast_bird | 13.3% (4/30) |
| expert_legacy | mixed_dmg | 20.0% (6/30) |
| expert_legacy | mixed_std | 6.7% (2/30) |
| expert_legacy | reptile_bug | 10.0% (3/30) |
| expert_legacy | tank_heavy | 36.0% (9/25) |
| expert_legacy | thorn_shield | 20.0% (5/25) |
| expert_no_lieu | aqua_plant | 13.3% (4/30) |
| expert_no_lieu | beast_bird | 23.3% (7/30) |
| expert_no_lieu | mixed_dmg | 10.0% (3/30) |
| expert_no_lieu | mixed_std | 20.0% (6/30) |
| expert_no_lieu | reptile_bug | 23.3% (7/30) |
| expert_no_lieu | tank_heavy | 28.0% (7/25) |
| expert_no_lieu | thorn_shield | 32.0% (8/25) |
| expert_no_overcast | aqua_plant | 23.3% (7/30) |
| expert_no_overcast | beast_bird | 23.3% (7/30) |
| expert_no_overcast | mixed_dmg | 16.7% (5/30) |
| expert_no_overcast | mixed_std | 23.3% (7/30) |
| expert_no_overcast | reptile_bug | 36.7% (11/30) |
| expert_no_overcast | tank_heavy | 20.0% (5/25) |
| expert_no_overcast | thorn_shield | 36.0% (9/25) |
| expert_no_wild | aqua_plant | 16.7% (5/30) |
| expert_no_wild | beast_bird | 16.7% (5/30) |
| expert_no_wild | mixed_dmg | 36.7% (11/30) |
| expert_no_wild | mixed_std | 16.7% (5/30) |
| expert_no_wild | reptile_bug | 40.0% (12/30) |
| expert_no_wild | tank_heavy | 28.0% (7/25) |
| expert_no_wild | thorn_shield | 24.0% (6/25) |
| free_hold | aqua_plant | 10.0% (3/30) |
| free_hold | beast_bird | 16.7% (5/30) |
| free_hold | mixed_dmg | 16.7% (5/30) |
| free_hold | mixed_std | 13.3% (4/30) |
| free_hold | reptile_bug | 10.0% (3/30) |
| free_hold | tank_heavy | 24.0% (6/25) |
| free_hold | thorn_shield | 28.0% (7/25) |
| random_legal | aqua_plant | 10.0% (3/30) |
| random_legal | beast_bird | 6.7% (2/30) |
| random_legal | mixed_dmg | 6.7% (2/30) |
| random_legal | mixed_std | 10.0% (3/30) |
| random_legal | reptile_bug | 26.7% (8/30) |
| random_legal | tank_heavy | 12.0% (3/25) |
| random_legal | thorn_shield | 16.0% (4/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | combo | 13.3% (8/60) |
| attack_spam | greedy_axis | 11.4% (8/70) |
| attack_spam | random | 10.0% (7/70) |
| expert | combo | 21.7% (13/60) |
| expert | greedy_axis | 22.9% (16/70) |
| expert | random | 21.4% (15/70) |
| expert_legacy | combo | 18.3% (11/60) |
| expert_legacy | greedy_axis | 12.9% (9/70) |
| expert_legacy | random | 14.3% (10/70) |
| expert_no_lieu | combo | 21.7% (13/60) |
| expert_no_lieu | greedy_axis | 22.9% (16/70) |
| expert_no_lieu | random | 18.6% (13/70) |
| expert_no_overcast | combo | 31.7% (19/60) |
| expert_no_overcast | greedy_axis | 22.9% (16/70) |
| expert_no_overcast | random | 22.9% (16/70) |
| expert_no_wild | combo | 31.7% (19/60) |
| expert_no_wild | greedy_axis | 28.6% (20/70) |
| expert_no_wild | random | 17.1% (12/70) |
| free_hold | combo | 11.7% (7/60) |
| free_hold | greedy_axis | 20.0% (14/70) |
| free_hold | random | 17.1% (12/70) |
| random_legal | combo | 10.0% (6/60) |
| random_legal | greedy_axis | 11.4% (8/70) |
| random_legal | random | 15.7% (11/70) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.5 luot (n=1269)
- attack_spam|boss: 6.3 luot (n=322)
- attack_spam|elite: 4.9 luot (n=182)
- expert_legacy|battle: 3.0 luot (n=1390)
- expert_legacy|boss: 5.7 luot (n=378)
- expert_legacy|elite: 4.5 luot (n=219)
- expert_no_lieu|battle: 2.7 luot (n=1484)
- expert_no_lieu|boss: 5.0 luot (n=412)
- expert_no_lieu|elite: 4.3 luot (n=219)
- expert_no_overcast|battle: 2.6 luot (n=1505)
- expert_no_overcast|boss: 4.7 luot (n=413)
- expert_no_overcast|elite: 3.8 luot (n=220)
- expert_no_wild|battle: 2.7 luot (n=1561)
- expert_no_wild|boss: 4.9 luot (n=445)
- expert_no_wild|elite: 3.7 luot (n=226)
- expert|battle: 2.7 luot (n=1568)
- expert|boss: 4.8 luot (n=442)
- expert|elite: 4.1 luot (n=226)
- free_hold|battle: 3.0 luot (n=1349)
- free_hold|boss: 5.7 luot (n=354)
- free_hold|elite: 4.6 luot (n=198)
- random_legal|battle: 3.5 luot (n=1337)
- random_legal|boss: 5.7 luot (n=320)
- random_legal|elite: 4.4 luot (n=185)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 3
- attack_spam|battle r11: 2
- attack_spam|battle r13: 2
- attack_spam|battle r14: 1
- attack_spam|battle r15: 1
- attack_spam|battle r4: 12
- attack_spam|battle r5: 2
- attack_spam|battle r7: 1
- attack_spam|battle r8: 1
- attack_spam|boss r12: 29
- attack_spam|boss r18: 32
- attack_spam|boss r6: 35
- attack_spam|elite r15: 17
- attack_spam|elite r5: 24
- attack_spam|elite r9: 15
- expert_legacy|battle r10: 2
- expert_legacy|battle r11: 1
- expert_legacy|battle r13: 1
- expert_legacy|battle r15: 1
- expert_legacy|battle r4: 2
- expert_legacy|battle r7: 1
- expert_legacy|battle r8: 1
- expert_legacy|battle r9: 1
- expert_legacy|boss r12: 42
- expert_legacy|boss r18: 43
- expert_legacy|boss r6: 16
- expert_legacy|elite r15: 13
- expert_legacy|elite r5: 23
- expert_legacy|elite r9: 23
- expert_no_lieu|battle r11: 6
- expert_no_lieu|battle r15: 1
- expert_no_lieu|battle r17: 1
- expert_no_lieu|battle r4: 3
- expert_no_lieu|battle r7: 1
- expert_no_lieu|battle r8: 6
- expert_no_lieu|battle r9: 1
- expert_no_lieu|boss r12: 39
- expert_no_lieu|boss r18: 48
- expert_no_lieu|boss r6: 7
- expert_no_lieu|elite r15: 8
- expert_no_lieu|elite r5: 14
- expert_no_lieu|elite r9: 23
- expert_no_overcast|battle r10: 1
- expert_no_overcast|battle r16: 1
- expert_no_overcast|battle r4: 6
- expert_no_overcast|battle r7: 1
- expert_no_overcast|battle r8: 3
- expert_no_overcast|battle r9: 3
- expert_no_overcast|boss r12: 40
- expert_no_overcast|boss r18: 37
- expert_no_overcast|boss r6: 6
- expert_no_overcast|elite r15: 16
- expert_no_overcast|elite r5: 14
- expert_no_overcast|elite r9: 21
- expert_no_wild|battle r14: 2
- expert_no_wild|battle r15: 2
- expert_no_wild|battle r4: 1
- expert_no_wild|battle r7: 1
- expert_no_wild|battle r8: 7
- expert_no_wild|boss r12: 36
- expert_no_wild|boss r18: 51
- expert_no_wild|boss r6: 11
- expert_no_wild|elite r15: 14
- expert_no_wild|elite r5: 12
- expert_no_wild|elite r9: 12
- expert|battle r11: 2
- expert|battle r16: 1
- expert|battle r4: 4
- expert|battle r7: 1
- expert|battle r8: 4
- expert|boss r12: 37
- expert|boss r18: 59
- expert|boss r6: 6
- expert|elite r15: 14
- expert|elite r5: 12
- expert|elite r9: 16
- free_hold|battle r17: 1
- free_hold|battle r4: 6
- free_hold|battle r5: 2
- free_hold|battle r8: 2
- free_hold|battle r9: 1
- free_hold|boss r12: 37
- free_hold|boss r18: 36
- free_hold|boss r6: 20
- free_hold|elite r15: 15
- free_hold|elite r5: 29
- free_hold|elite r9: 18
- random_legal|battle r10: 4
- random_legal|battle r11: 1
- random_legal|battle r13: 2
- random_legal|battle r14: 4
- random_legal|battle r17: 1
- random_legal|battle r4: 12
- random_legal|battle r5: 4
- random_legal|battle r7: 1
- random_legal|battle r8: 4
- random_legal|battle r9: 3
- random_legal|boss r12: 30
- random_legal|boss r18: 29
- random_legal|boss r6: 12
- random_legal|elite r15: 15
- random_legal|elite r5: 24
- random_legal|elite r9: 29

Tran ket > 20 luot hoac khong ket thuc: 10 / 16224

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 46.1% | 13.7% | 13.7% | 100% |  |
| c_dewdrop | stat | 0 | 47.4% | 17.5% | 17.5% | 100% |  |
| c_elder_trunk | stat | 0 | 45.3% | 19.6% | 19.6% | 100% |  |
| c_prime_chain | dice | 0 | 48.8% | 14.1% | 13.4% | 95% |  |
| c_finisher | dice | 0 | 45.9% | 15.2% | 15.1% | 99% |  |
| c_bastion | pos | 0 | 63.4% | 21.6% | 21.4% | 99% |  |
| c_tidecaller | mana | 0 | 50.3% | 9.2% | 0.1% | 1% |  |
| c_mana_pool | mana | 0 | 41.7% | 14.9% | 12.9% | 87% |  |
| c_nest | rule | 0 | 50.2% | 16.6% | 16.6% | 100% |  |
| c_spore_burst | rule | 0 | 46.6% | 15.9% | 15.8% | 99% |  |
| c_fossil | rule | 0 | 30.4% | 8.4% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.0% | 2.5% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 9.5% | 4.5% | 0.6% | 12% | LOW |
| rule_tundra | run_rule | 0 | 9.5% | 5.5% | 0.8% | 15% | LOW |
| rule_quick_beat | run_rule | 0 | 11.0% | 5.5% | 4.6% | 83% |  |
| rule_starfall | run_rule | 0 | 13.5% | 6.5% | 6.5% | 100% |  |
| rule_heavy_finish | run_rule | 0 | 15.0% | 9.5% | 9.5% | 100% |  |
| rule_wasteland | run_rule | 0 | 10.0% | 4.5% | 4.5% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 12.5% | 8.5% | 8.5% | 100% |  |
| rule_rising_tide | run_rule | 0 | 13.5% | 5.5% | 5.5% | 100% |  |
| rule_upside_down | run_rule | 0 | 14.0% | 7.5% | 7.5% | 100% |  |
| rule_old_forest | run_rule | 0 | 23.5% | 13.0% | 13.0% | 100% |  |
| rule_crow | run_rule | 0 | 13.5% | 6.5% | 5.9% | 91% |  |
| rule_hard_shell | run_rule | 0 | 19.5% | 7.5% | 7.5% | 100% |  |
| rule_balance | run_rule | 0 | 25.0% | 13.0% | 13.0% | 100% |  |
| c_prism | dice | 1 | 11.7% | 6.1% | 2.7% | 44% |  |
| c_steady_hold | dice | 1 | 11.4% | 4.0% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 11.4% | 4.6% | 0.5% | 11% |  |
| c_sonic_shield | dice | 1 | 10.9% | 4.9% | 4.7% | 96% |  |
| c_fissure | dice | 1 | 6.5% | 1.8% | 1.8% | 97% | LOW |
| c_field_medic | dice | 1 | 11.4% | 2.7% | 2.7% | 100% |  |
| c_plague_spread | dice | 1 | 7.9% | 3.4% | 3.4% | 98% | LOW |
| c_gatekeeper | pos | 1 | 19.6% | 10.1% | 9.8% | 98% |  |
| c_thorn_growth | pos | 1 | 21.8% | 6.2% | 6.1% | 99% |  |
| c_thorn_shield | stat | 1 | 70.1% | 17.0% | 16.7% | 98% |  |
| c_backline_glow | pos | 1 | 26.6% | 12.1% | 10.6% | 88% |  |
| c_growing_shell | pos | 1 | 21.2% | 8.8% | 7.5% | 85% |  |
| c_mana_ward | mana | 1 | 25.2% | 6.4% | 4.3% | 67% |  |
| c_overflow | mana | 1 | 23.2% | 10.0% | 5.2% | 52% |  |
| c_thorn_pact | mana | 1 | 21.9% | 9.6% | 9.5% | 99% |  |
| c_dry_well | quest | 1 | 23.4% | 2.4% | 2.4% | 100% |  |
| c_night_watch | quest | 1 | 20.9% | 3.1% | 3.1% | 100% |  |
| c_key_strike | quest | 1 | 21.6% | 1.8% | 0.0% | 0% | DEAD |
| c_collector | quest | 1 | 25.8% | 6.1% | 6.1% | 100% |  |
| c_chimera_hunt | quest | 1 | 24.7% | 6.1% | 5.0% | 82% |  |
| c_golden_egg | rule | 1 | 8.6% | 6.9% | 4.4% | 63% | LOW |
| c_dim_stone | rule | 1 | 15.5% | 4.4% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.2% | 4.6% | 4.8% | 100% |  |
| c_sixth_die | dice | 2 | 10.2% | 4.6% | 4.6% | 100% |  |
| c_whittle | dice | 2 | 10.2% | 2.7% | 2.8% | 100% |  |
| c_three_dice | dice | 2 | 12.1% | 4.6% | 4.6% | 100% |  |
| c_concord | dice | 2 | 7.6% | 1.6% | 1.8% | 96% | LOW |
| c_toxic_still | dice | 2 | 7.1% | 1.7% | 1.7% | 100% | LOW |
| c_living_wall | pos | 2 | 29.6% | 13.1% | 13.4% | 100% |  |
| c_thorn_rebound | rule | 2 | 14.3% | 4.2% | 4.3% | 87% |  |
| c_open_ranks | pos | 2 | 4.1% | 1.6% | 1.6% | 100% | LOW |
| c_descend | pos | 2 | 16.0% | 6.0% | 5.6% | 92% |  |
| c_hollow_core | mana | 2 | 22.9% | 7.8% | 5.9% | 75% |  |
| c_deep_current | mana | 2 | 27.6% | 7.3% | 4.8% | 59% |  |
| c_blood_sign | rule | 2 | 9.9% | 5.4% | 5.7% | 100% | LOW |
| c_loop | rule | 2 | 12.2% | 6.1% | 5.6% | 85% |  |
| c_cascade | rule | 2 | 12.2% | 5.6% | 6.3% | 100% |  |
| c_sacrifice | rule | 2 | 16.7% | 6.0% | 6.4% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 65.6% (1049/1600)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 56.3% (139/247)
- c_cascade: 47.5% (48/101)
- c_golden_egg: 45.0% (50/111)
- c_sacrifice: 41.2% (42/102)
- c_nest: 40.5% (105/259)
- c_blood_sign: 38.5% (35/91)
- c_sixth_die: 33.8% (25/74)
- c_collector: 33.7% (33/98)
- c_living_wall: 31.8% (68/214)
- c_plague_spread: 30.9% (17/55)

Bottom 10:
- c_fossil: 0.0% (0/23)
- c_three_dice: 6.8% (5/74)
- c_fissure: 10.3% (3/29)
- c_mana_pool: 12.6% (29/230)
- c_bastion: 12.9% (43/334)
- c_kindle: 14.1% (10/71)
- c_open_ranks: 15.4% (4/26)
- c_deep_current: 15.5% (20/129)
- c_finisher: 16.5% (39/237)
- c_prime_chain: 17.0% (38/224)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_spore_burst + c_tidecaller: 87.5% (7/8)
- c_collector + c_spore_burst: 87.5% (14/16)
- c_sixth_die + c_spore_burst: 85.7% (12/14)
- c_cascade + c_spore_burst: 82.7% (43/52)
- c_spore_burst + c_steady_hold: 80.0% (8/10)
- c_bastion + c_three_dice: 0.0% (0/10)
- c_thorn_pact + c_three_dice: 0.0% (0/8)
- c_elder_trunk + c_three_dice: 0.0% (0/9)
- c_growing_shell + c_mana_pool: 0.0% (0/11)
- c_finisher + c_fissure: 0.0% (0/10)
