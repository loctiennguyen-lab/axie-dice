# Sim balance metric-mana-all

Runs: 1600, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 16.0% -> CHUA DAT
- attack_spam <= 5%: 9.0% -> CHUA DAT
- expert 15-25%: 24.0% -> DAT
- expert - random >= 15 diem: 8.0 diem -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **attack_spam** (n=200): r4 battle -8 (con 96%); r5 elite -27 (con 82%); r5 battle -1 (con 82%); r6 boss -30 (con 67%); r7 battle -1 (con 66%); r8 battle -4 (con 64%); r9 elite -19 (con 55%); r10 battle -1 (con 54%); r11 battle -3 (con 53%); r12 boss -22 (con 42%); r13 battle -1 (con 42%); r14 battle -1 (con 41%); r15 elite -15 (con 34%); r15 battle -2 (con 32%); r16 battle -1 (con 32%); r17 battle -1 (con 32%); r18 boss -45 (con 9%)
- **expert_legacy** (n=200): r4 battle -5 (con 98%); r5 elite -9 (con 93%); r5 battle -2 (con 92%); r6 boss -19 (con 82%); r7 battle -1 (con 82%); r8 battle -2 (con 81%); r9 elite -15 (con 74%); r9 battle -2 (con 72%); r11 battle -2 (con 72%); r12 boss -42 (con 50%); r13 battle -1 (con 50%); r14 battle -1 (con 50%); r15 elite -16 (con 42%); r18 boss -44 (con 20%)
- **expert_no_lieu** (n=200): r4 battle -4 (con 98%); r5 elite -7 (con 94%); r6 boss -12 (con 88%); r8 battle -3 (con 87%); r9 elite -20 (con 77%); r9 battle -1 (con 76%); r11 battle -3 (con 75%); r12 boss -40 (con 55%); r13 battle -1 (con 54%); r15 elite -16 (con 46%); r15 battle -1 (con 46%); r16 battle -1 (con 46%); r18 boss -51 (con 20%)
- **expert_no_overcast** (n=200): r4 battle -5 (con 98%); r5 elite -9 (con 93%); r6 boss -12 (con 87%); r7 battle -2 (con 86%); r8 battle -1 (con 86%); r9 elite -16 (con 78%); r11 battle -2 (con 76%); r12 boss -41 (con 56%); r15 elite -14 (con 49%); r16 battle -1 (con 48%); r18 boss -54 (con 22%)
- **expert_no_wild** (n=200): r4 battle -4 (con 98%); r5 elite -14 (con 91%); r6 boss -10 (con 86%); r7 battle -1 (con 86%); r8 battle -5 (con 83%); r9 elite -21 (con 72%); r10 battle -1 (con 72%); r11 battle -1 (con 72%); r12 boss -38 (con 52%); r13 battle -1 (con 52%); r14 battle -2 (con 51%); r15 elite -15 (con 44%); r15 battle -2 (con 42%); r17 battle -1 (con 42%); r18 boss -52 (con 16%)
- **free_hold** (n=200): r4 battle -6 (con 97%); r5 elite -16 (con 89%); r5 battle -1 (con 88%); r6 boss -17 (con 80%); r7 battle -3 (con 78%); r8 battle -5 (con 76%); r9 elite -18 (con 67%); r11 battle -1 (con 66%); r12 boss -46 (con 44%); r13 battle -1 (con 43%); r14 battle -1 (con 42%); r15 elite -15 (con 35%); r15 battle -1 (con 34%); r16 battle -1 (con 34%); r18 boss -37 (con 16%)
- **random_legal** (n=200): r4 battle -14 (con 93%); r5 elite -36 (con 75%); r5 battle -3 (con 74%); r6 boss -19 (con 64%); r8 battle -2 (con 63%); r9 battle -1 (con 62%); r9 elite -14 (con 56%); r10 battle -2 (con 54%); r11 battle -4 (con 52%); r12 boss -18 (con 44%); r13 battle -1 (con 43%); r14 battle -1 (con 42%); r15 elite -24 (con 30%); r18 boss -29 (con 16%)
- **expert** (n=200): r4 battle -6 (con 97%); r5 elite -10 (con 92%); r6 boss -6 (con 89%); r8 battle -1 (con 88%); r9 elite -19 (con 79%); r10 battle -1 (con 78%); r11 battle -2 (con 78%); r12 boss -38 (con 58%); r13 battle -1 (con 58%); r15 elite -10 (con 53%); r15 battle -2 (con 52%); r18 boss -56 (con 24%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 19.47 +-1.28 | 20.15 +-0.83 | 20.15 +-0.83 | 14.34 +-1.21 | 6.58 +-0.45 | 0.48 +-0.07 | 9.0 +-4.0 | 
| expert_legacy | 200 | 24.01 +-1.35 | 22.72 +-0.96 | 24.08 +-0.98 | 17.60 +-1.25 | 5.81 +-0.35 | 0.41 +-0.07 | 19.5 +-5.5 | 
| expert_no_lieu | 200 | 27.12 +-1.40 | 22.76 +-0.86 | 27.99 +-1.10 | 20.69 +-1.34 | 4.80 +-0.25 | 0.52 +-0.07 | 20.0 +-5.6 | 
| expert_no_overcast | 200 | 28.21 +-1.50 | 23.75 +-1.00 | 28.95 +-1.12 | 20.68 +-1.35 | 5.00 +-0.30 | 0.51 +-0.07 | 21.5 +-5.7 | 
| expert_no_wild | 200 | 26.13 +-1.40 | 22.82 +-0.99 | 27.08 +-1.12 | 19.14 +-1.25 | 4.97 +-0.31 | 0.58 +-0.07 | 16.0 +-5.1 | 
| free_hold | 200 | 22.34 +-1.36 | 22.20 +-0.98 | 24.15 +-1.02 | 17.09 +-1.17 | 6.23 +-0.39 | 0.53 +-0.07 | 15.5 +-5.0 | 
| random_legal | 200 | 20.15 +-1.38 | 20.40 +-0.86 | 20.40 +-0.86 | 15.23 +-1.28 | 6.14 +-0.46 | 0.51 +-0.07 | 16.0 +-5.1 | 
| expert | 200 | 28.62 +-1.45 | 23.80 +-0.97 | 29.74 +-1.18 | 21.27 +-1.33 | 4.77 +-0.26 | 0.52 +-0.07 | 24.0 +-5.9 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | -9.15 +-1.66 (n=200) | -3.65 +-1.14 (n=200) | -9.59 +-1.34 (n=200) | -6.93 +-1.68 (n=200) | +1.89 +-0.50 (n=150) | -0.13 +-0.13 (n=27) | -15.00 +-6.63 (n=200) | 
| expert_legacy | 200 | -4.61 +-1.77 (n=200) | -1.08 +-1.18 (n=200) | -5.66 +-1.33 (n=200) | -3.67 +-1.75 (n=200) | +1.05 +-0.43 (n=171) | -0.05 +-0.14 (n=34) | -4.50 +-7.77 (n=200) | 
| expert_no_lieu | 200 | -1.50 +-1.62 (n=200) | -1.04 +-1.03 (n=200) | -1.75 +-1.20 (n=200) | -0.58 +-1.60 (n=200) | +0.01 +-0.32 (n=178) | +0.04 +-0.13 (n=36) | -4.00 +-7.46 (n=200) | 
| expert_no_overcast | 200 | -0.41 +-1.28 (n=200) | -0.05 +-0.77 (n=200) | -0.79 +-0.89 (n=200) | -0.59 +-1.24 (n=200) | +0.24 +-0.30 (n=179) | -0.09 +-0.08 (n=48) | -2.50 +-5.97 (n=200) | 
| expert_no_wild | 200 | -2.49 +-1.57 (n=200) | -0.98 +-0.97 (n=200) | -2.66 +-1.11 (n=200) | -2.13 +-1.50 (n=200) | +0.25 +-0.32 (n=174) | +0.07 +-0.08 (n=47) | -8.00 +-6.57 (n=200) | 
| free_hold | 200 | -6.28 +-1.67 (n=200) | -1.60 +-1.19 (n=200) | -5.59 +-1.30 (n=200) | -4.18 +-1.62 (n=200) | +1.49 +-0.40 (n=164) | -0.03 +-0.12 (n=31) | -8.50 +-7.58 (n=200) | 
| random_legal | 200 | -8.47 +-1.79 (n=200) | -3.40 +-1.15 (n=200) | -9.34 +-1.32 (n=200) | -6.04 +-1.80 (n=200) | +1.43 +-0.51 (n=138) | -0.12 +-0.14 (n=40) | -8.00 +-6.86 (n=200) | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 37.24 | 0.77 | 0.43 | 7.56 | 55 | 980 | 0.43 | 0.00 | 0.26 | 0.08 | 0.00 |
| expert_legacy | 200 | 37.50 | 9.94 | 9.30 | 7.19 | 94 | 72 | 9.09 | 0.00 | 0.28 | 0.11 | 0.46 |
| expert_no_lieu | 200 | 35.45 | 10.07 | 10.03 | 3.83 | 100 | 38 | 9.27 | 0.00 | 0.27 | 0.05 | 0.48 |
| expert_no_overcast | 200 | 35.23 | 9.60 | 8.97 | 5.83 | 93 | 61 | 8.56 | 0.00 | 0.24 | 0.12 | 0.68 |
| expert_no_wild | 200 | 34.91 | 10.30 | 9.99 | 5.23 | 97 | 51 | 9.33 | 0.00 | 0.25 | 0.08 | 0.64 |
| free_hold | 200 | 37.64 | 12.59 | 11.72 | 7.69 | 93 | 61 | 11.73 | 0.00 | 0.31 | 0.08 | 0.47 |
| random_legal | 200 | 34.66 | 1.35 | 0.91 | 6.57 | 68 | 486 | 0.70 | 0.00 | 0.29 | 0.04 | 0.31 |
| expert | 200 | 35.38 | 1.53 | 1.33 | 4.61 | 87 | 302 | 0.61 | 0.00 | 0.24 | 0.05 | 0.62 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| expert_legacy | 2 | 1 | 0 | 0 | 97 | 5.27 | 1.59 | 17.16 | 0.00 | 0.00 | 0.00 |
| expert_no_lieu | 2 | 1 | 2 | 3 | 92 | 6.08 | 1.48 | 17.75 | 3.98 | 3.71 | 0.00 |
| expert_no_overcast | 2 | 1 | 3 | 0 | 95 | 5.50 | 1.27 | 19.21 | 4.18 | 0.00 | 10.25 |
| expert_no_wild | 2 | 1 | 0 | 4 | 93 | 6.17 | 1.39 | 19.57 | 0.00 | 5.11 | 10.14 |
| free_hold | 0 | 0 | 0 | 0 | 100 | 0.20 | 0.14 | 20.91 | 0.00 | 0.00 | 0.00 |
| random_legal | 6 | 0 | 5 | 6 | 82 | 1.64 | 0.08 | 5.04 | 0.80 | 0.67 | 8.46 |
| expert | 13 | 4 | 18 | 26 | 39 | 5.62 | 0.89 | 18.20 | 4.28 | 4.11 | 10.81 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 16.2 | 7.7 | 7.7 |
| expert_legacy | 0% (0) | 0% (0) | 0% (0) | 18.3 | 7.9 | 8.0 |
| expert_no_lieu | 0% (0) | 100% (795) | 0% (0) | 28.8 | 12.2 | 6.3 |
| expert_no_overcast | 0% (0) | 100% (836) | 0% (0) | 32.4 | 14.4 | 12.6 |
| expert_no_wild | 0% (0) | 0% (0) | 0% (0) | 31.5 | 14.1 | 9.9 |
| free_hold | 0% (0) | 0% (0) | 0% (0) | 30.8 | 14.7 | 16.0 |
| random_legal | 0% (0) | 100% (160) | 0% (0) | 15.9 | 6.1 | 6.1 |
| expert | 0% (0) | 100% (856) | 0% (0) | 31.9 | 13.7 | 7.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: attack_spam 0.00; expert_legacy 0.00; expert_no_lieu 0.00; expert_no_overcast 0.00; expert_no_wild 0.00; free_hold 0.00; random_legal 0.00; expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| attack_spam | 0 | 9.0% (18/200) |
| expert | 0 | 24.0% (48/200) |
| expert_legacy | 0 | 19.5% (39/200) |
| expert_no_lieu | 0 | 20.0% (40/200) |
| expert_no_overcast | 0 | 21.5% (43/200) |
| expert_no_wild | 0 | 16.0% (32/200) |
| free_hold | 0 | 15.5% (31/200) |
| random_legal | 0 | 16.0% (32/200) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| attack_spam | aqua_plant | 10.0% (3/30) |
| attack_spam | beast_bird | 13.3% (4/30) |
| attack_spam | mixed_dmg | 6.7% (2/30) |
| attack_spam | mixed_std | 3.3% (1/30) |
| attack_spam | reptile_bug | 16.7% (5/30) |
| attack_spam | tank_heavy | 4.0% (1/25) |
| attack_spam | thorn_shield | 8.0% (2/25) |
| expert | aqua_plant | 23.3% (7/30) |
| expert | beast_bird | 16.7% (5/30) |
| expert | mixed_dmg | 30.0% (9/30) |
| expert | mixed_std | 20.0% (6/30) |
| expert | reptile_bug | 30.0% (9/30) |
| expert | tank_heavy | 24.0% (6/25) |
| expert | thorn_shield | 24.0% (6/25) |
| expert_legacy | aqua_plant | 3.3% (1/30) |
| expert_legacy | beast_bird | 16.7% (5/30) |
| expert_legacy | mixed_dmg | 26.7% (8/30) |
| expert_legacy | mixed_std | 10.0% (3/30) |
| expert_legacy | reptile_bug | 43.3% (13/30) |
| expert_legacy | tank_heavy | 24.0% (6/25) |
| expert_legacy | thorn_shield | 12.0% (3/25) |
| expert_no_lieu | aqua_plant | 16.7% (5/30) |
| expert_no_lieu | beast_bird | 20.0% (6/30) |
| expert_no_lieu | mixed_dmg | 36.7% (11/30) |
| expert_no_lieu | mixed_std | 13.3% (4/30) |
| expert_no_lieu | reptile_bug | 20.0% (6/30) |
| expert_no_lieu | tank_heavy | 8.0% (2/25) |
| expert_no_lieu | thorn_shield | 24.0% (6/25) |
| expert_no_overcast | aqua_plant | 23.3% (7/30) |
| expert_no_overcast | beast_bird | 16.7% (5/30) |
| expert_no_overcast | mixed_dmg | 26.7% (8/30) |
| expert_no_overcast | mixed_std | 13.3% (4/30) |
| expert_no_overcast | reptile_bug | 30.0% (9/30) |
| expert_no_overcast | tank_heavy | 12.0% (3/25) |
| expert_no_overcast | thorn_shield | 28.0% (7/25) |
| expert_no_wild | aqua_plant | 16.7% (5/30) |
| expert_no_wild | beast_bird | 16.7% (5/30) |
| expert_no_wild | mixed_dmg | 10.0% (3/30) |
| expert_no_wild | mixed_std | 16.7% (5/30) |
| expert_no_wild | reptile_bug | 20.0% (6/30) |
| expert_no_wild | tank_heavy | 16.0% (4/25) |
| expert_no_wild | thorn_shield | 16.0% (4/25) |
| free_hold | aqua_plant | 16.7% (5/30) |
| free_hold | beast_bird | 13.3% (4/30) |
| free_hold | mixed_dmg | 20.0% (6/30) |
| free_hold | mixed_std | 10.0% (3/30) |
| free_hold | reptile_bug | 23.3% (7/30) |
| free_hold | tank_heavy | 12.0% (3/25) |
| free_hold | thorn_shield | 12.0% (3/25) |
| random_legal | aqua_plant | 10.0% (3/30) |
| random_legal | beast_bird | 13.3% (4/30) |
| random_legal | mixed_dmg | 20.0% (6/30) |
| random_legal | mixed_std | 6.7% (2/30) |
| random_legal | reptile_bug | 30.0% (9/30) |
| random_legal | tank_heavy | 12.0% (3/25) |
| random_legal | thorn_shield | 20.0% (5/25) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| attack_spam | random | 9.0% (18/200) |
| expert | random | 24.0% (48/200) |
| expert_legacy | random | 19.5% (39/200) |
| expert_no_lieu | random | 20.0% (40/200) |
| expert_no_overcast | random | 21.5% (43/200) |
| expert_no_wild | random | 16.0% (32/200) |
| free_hold | random | 15.5% (31/200) |
| random_legal | random | 16.0% (32/200) |


## So luot trung binh moi tran (chinh sach|loai)

- attack_spam|battle: 3.4 luot (n=1294)
- attack_spam|boss: 6.2 luot (n=333)
- attack_spam|elite: 4.9 luot (n=199)
- expert_legacy|battle: 2.9 luot (n=1472)
- expert_legacy|boss: 5.6 luot (n=410)
- expert_legacy|elite: 4.0 luot (n=217)
- expert_no_lieu|battle: 2.7 luot (n=1512)
- expert_no_lieu|boss: 4.8 luot (n=430)
- expert_no_lieu|elite: 3.8 luot (n=234)
- expert_no_overcast|battle: 2.6 luot (n=1553)
- expert_no_overcast|boss: 4.8 luot (n=436)
- expert_no_overcast|elite: 3.8 luot (n=222)
- expert_no_wild|battle: 2.8 luot (n=1478)
- expert_no_wild|boss: 5.0 luot (n=409)
- expert_no_wild|elite: 3.9 luot (n=224)
- expert|battle: 2.6 luot (n=1566)
- expert|boss: 4.7 luot (n=443)
- expert|elite: 3.8 luot (n=227)
- free_hold|battle: 3.1 luot (n=1398)
- free_hold|boss: 6.0 luot (n=378)
- free_hold|elite: 4.3 luot (n=211)
- random_legal|battle: 3.3 luot (n=1268)
- random_legal|boss: 5.8 luot (n=313)
- random_legal|elite: 4.6 luot (n=196)

## Chet theo node (chinh sach|loai row)

- attack_spam|battle r10: 1
- attack_spam|battle r11: 3
- attack_spam|battle r13: 1
- attack_spam|battle r14: 1
- attack_spam|battle r15: 2
- attack_spam|battle r16: 1
- attack_spam|battle r17: 1
- attack_spam|battle r4: 8
- attack_spam|battle r5: 1
- attack_spam|battle r7: 1
- attack_spam|battle r8: 4
- attack_spam|boss r12: 22
- attack_spam|boss r18: 45
- attack_spam|boss r6: 30
- attack_spam|elite r15: 15
- attack_spam|elite r5: 27
- attack_spam|elite r9: 19
- expert_legacy|battle r11: 2
- expert_legacy|battle r13: 1
- expert_legacy|battle r14: 1
- expert_legacy|battle r4: 5
- expert_legacy|battle r5: 2
- expert_legacy|battle r7: 1
- expert_legacy|battle r8: 2
- expert_legacy|battle r9: 2
- expert_legacy|boss r12: 42
- expert_legacy|boss r18: 44
- expert_legacy|boss r6: 19
- expert_legacy|elite r15: 16
- expert_legacy|elite r5: 9
- expert_legacy|elite r9: 15
- expert_no_lieu|battle r11: 3
- expert_no_lieu|battle r13: 1
- expert_no_lieu|battle r15: 1
- expert_no_lieu|battle r16: 1
- expert_no_lieu|battle r4: 4
- expert_no_lieu|battle r8: 3
- expert_no_lieu|battle r9: 1
- expert_no_lieu|boss r12: 40
- expert_no_lieu|boss r18: 51
- expert_no_lieu|boss r6: 12
- expert_no_lieu|elite r15: 16
- expert_no_lieu|elite r5: 7
- expert_no_lieu|elite r9: 20
- expert_no_overcast|battle r11: 2
- expert_no_overcast|battle r16: 1
- expert_no_overcast|battle r4: 5
- expert_no_overcast|battle r7: 2
- expert_no_overcast|battle r8: 1
- expert_no_overcast|boss r12: 41
- expert_no_overcast|boss r18: 54
- expert_no_overcast|boss r6: 12
- expert_no_overcast|elite r15: 14
- expert_no_overcast|elite r5: 9
- expert_no_overcast|elite r9: 16
- expert_no_wild|battle r10: 1
- expert_no_wild|battle r11: 1
- expert_no_wild|battle r13: 1
- expert_no_wild|battle r14: 2
- expert_no_wild|battle r15: 2
- expert_no_wild|battle r17: 1
- expert_no_wild|battle r4: 4
- expert_no_wild|battle r7: 1
- expert_no_wild|battle r8: 5
- expert_no_wild|boss r12: 38
- expert_no_wild|boss r18: 52
- expert_no_wild|boss r6: 10
- expert_no_wild|elite r15: 15
- expert_no_wild|elite r5: 14
- expert_no_wild|elite r9: 21
- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r13: 1
- expert|battle r15: 2
- expert|battle r4: 6
- expert|battle r8: 1
- expert|boss r12: 38
- expert|boss r18: 56
- expert|boss r6: 6
- expert|elite r15: 10
- expert|elite r5: 10
- expert|elite r9: 19
- free_hold|battle r11: 1
- free_hold|battle r13: 1
- free_hold|battle r14: 1
- free_hold|battle r15: 1
- free_hold|battle r16: 1
- free_hold|battle r4: 6
- free_hold|battle r5: 1
- free_hold|battle r7: 3
- free_hold|battle r8: 5
- free_hold|boss r12: 46
- free_hold|boss r18: 37
- free_hold|boss r6: 17
- free_hold|elite r15: 15
- free_hold|elite r5: 16
- free_hold|elite r9: 18
- random_legal|battle r10: 2
- random_legal|battle r11: 4
- random_legal|battle r13: 1
- random_legal|battle r14: 1
- random_legal|battle r4: 14
- random_legal|battle r5: 3
- random_legal|battle r8: 2
- random_legal|battle r9: 1
- random_legal|boss r12: 18
- random_legal|boss r18: 29
- random_legal|boss r6: 19
- random_legal|elite r15: 24
- random_legal|elite r5: 36
- random_legal|elite r9: 14

Tran ket > 20 luot hoac khong ket thuc: 6 / 16423

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | fired | fired/picked | co |
|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 47.5% | 13.2% | 13.2% | 100% |  |
| c_dewdrop | stat | 0 | 44.0% | 16.0% | 16.0% | 100% |  |
| c_elder_trunk | stat | 0 | 43.4% | 13.8% | 13.8% | 100% |  |
| c_prime_chain | dice | 0 | 50.9% | 16.5% | 15.6% | 95% |  |
| c_finisher | dice | 0 | 41.5% | 16.6% | 16.0% | 96% |  |
| c_bastion | pos | 0 | 71.5% | 25.0% | 24.9% | 100% |  |
| c_tidecaller | mana | 0 | 45.8% | 14.0% | 0.2% | 2% |  |
| c_mana_pool | mana | 0 | 43.3% | 13.1% | 12.5% | 96% |  |
| c_nest | rule | 0 | 52.8% | 17.3% | 17.3% | 100% |  |
| c_spore_burst | rule | 0 | 50.3% | 16.2% | 15.9% | 98% |  |
| c_fossil | rule | 0 | 33.2% | 10.3% | 0.0% | 0% | DEAD |
| rule_none | run_rule | 0 | 10.5% | 4.5% | 0.0% | 0% | DEAD |
| rule_cheap_mana | run_rule | 0 | 9.5% | 5.0% | 0.6% | 11% | LOW |
| rule_tundra | run_rule | 0 | 16.5% | 6.5% | 0.2% | 4% |  |
| rule_quick_beat | run_rule | 0 | 11.5% | 6.5% | 6.1% | 93% |  |
| rule_starfall | run_rule | 0 | 9.5% | 3.0% | 3.0% | 100% | LOW |
| rule_heavy_finish | run_rule | 0 | 14.5% | 8.5% | 8.5% | 100% |  |
| rule_wasteland | run_rule | 0 | 15.0% | 6.5% | 6.5% | 100% |  |
| rule_dry_steppe | run_rule | 0 | 8.0% | 3.0% | 3.0% | 100% | LOW |
| rule_rising_tide | run_rule | 0 | 11.5% | 6.5% | 6.5% | 100% |  |
| rule_upside_down | run_rule | 0 | 10.5% | 6.5% | 6.5% | 100% |  |
| rule_old_forest | run_rule | 0 | 24.0% | 11.5% | 11.5% | 100% |  |
| rule_crow | run_rule | 0 | 13.5% | 7.0% | 6.2% | 89% |  |
| rule_hard_shell | run_rule | 0 | 20.5% | 10.5% | 10.5% | 100% |  |
| rule_balance | run_rule | 0 | 25.0% | 14.5% | 14.5% | 100% |  |
| c_prism | dice | 1 | 11.3% | 3.6% | 1.4% | 40% |  |
| c_steady_hold | dice | 1 | 10.8% | 3.1% | 0.0% | 0% | DEAD |
| c_kindle | dice | 1 | 11.9% | 3.2% | 0.2% | 6% |  |
| c_sonic_shield | dice | 1 | 11.7% | 4.0% | 3.9% | 97% |  |
| c_fissure | dice | 1 | 8.0% | 2.9% | 2.9% | 100% | LOW |
| c_field_medic | dice | 1 | 11.6% | 4.4% | 4.4% | 100% |  |
| c_plague_spread | dice | 1 | 7.8% | 2.0% | 1.9% | 97% | LOW |
| c_gatekeeper | pos | 1 | 22.7% | 7.8% | 7.5% | 97% |  |
| c_thorn_growth | pos | 1 | 22.9% | 8.0% | 7.9% | 99% |  |
| c_thorn_shield | stat | 1 | 69.9% | 23.6% | 22.1% | 94% |  |
| c_backline_glow | pos | 1 | 27.1% | 9.0% | 8.2% | 92% |  |
| c_growing_shell | pos | 1 | 27.2% | 9.2% | 8.4% | 91% |  |
| c_mana_ward | mana | 1 | 26.9% | 9.0% | 6.7% | 74% |  |
| c_overflow | mana | 1 | 24.1% | 8.8% | 4.7% | 54% |  |
| c_thorn_pact | mana | 1 | 20.9% | 7.2% | 6.9% | 96% |  |
| c_dry_well | quest | 1 | 23.3% | 7.0% | 7.0% | 100% |  |
| c_night_watch | quest | 1 | 22.9% | 7.1% | 7.1% | 100% |  |
| c_key_strike | quest | 1 | 21.1% | 5.0% | 0.1% | 1% |  |
| c_collector | quest | 1 | 21.1% | 6.2% | 6.2% | 100% |  |
| c_chimera_hunt | quest | 1 | 22.9% | 7.6% | 5.8% | 77% |  |
| c_golden_egg | rule | 1 | 9.2% | 2.5% | 1.6% | 62% | LOW |
| c_dim_stone | rule | 1 | 13.6% | 3.6% | 0.0% | 0% | DEAD |
| c_mirror_face | dice | 2 | 11.6% | 3.3% | 3.6% | 100% |  |
| c_sixth_die | dice | 2 | 8.7% | 2.8% | 2.9% | 100% | LOW |
| c_whittle | dice | 2 | 11.1% | 4.3% | 4.5% | 100% |  |
| c_three_dice | dice | 2 | 11.9% | 3.5% | 3.7% | 100% |  |
| c_concord | dice | 2 | 7.3% | 2.1% | 2.1% | 100% | LOW |
| c_toxic_still | dice | 2 | 7.1% | 1.9% | 2.0% | 100% | LOW |
| c_living_wall | pos | 2 | 28.1% | 8.4% | 8.8% | 100% |  |
| c_thorn_rebound | rule | 2 | 17.2% | 5.6% | 4.6% | 74% |  |
| c_open_ranks | pos | 2 | 8.5% | 2.9% | 2.9% | 100% | LOW |
| c_descend | pos | 2 | 15.1% | 5.2% | 5.4% | 100% |  |
| c_hollow_core | mana | 2 | 23.5% | 7.4% | 6.1% | 83% |  |
| c_deep_current | mana | 2 | 29.1% | 9.6% | 7.2% | 74% |  |
| c_blood_sign | rule | 2 | 11.4% | 4.2% | 4.4% | 100% |  |
| c_loop | rule | 2 | 13.2% | 5.0% | 5.0% | 92% |  |
| c_cascade | rule | 2 | 12.4% | 4.4% | 4.9% | 100% |  |
| c_sacrifice | rule | 2 | 15.9% | 5.6% | 6.1% | 100% |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 57.7% (923/1600)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 52.6% (133/253)
- c_golden_egg: 42.5% (17/40)
- c_sixth_die: 39.1% (18/46)
- c_blood_sign: 35.2% (25/71)
- c_descend: 33.7% (29/86)
- c_concord: 32.4% (11/34)
- c_loop: 31.0% (27/87)
- c_nest: 30.8% (84/273)
- c_living_wall: 30.0% (42/140)
- c_sonic_shield: 29.7% (19/64)

Bottom 10:
- c_fossil: 0.0% (0/16)
- c_field_medic: 11.3% (8/71)
- c_bastion: 12.5% (48/385)
- c_plague_spread: 12.5% (4/32)
- c_steady_hold: 14.0% (7/50)
- c_prime_chain: 14.6% (38/261)
- c_three_dice: 15.3% (9/59)
- c_toxic_still: 15.6% (5/32)
- c_kindle: 15.7% (8/51)
- c_tidecaller: 15.7% (35/223)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_spore_burst + c_whittle: 84.6% (11/13)
- c_spore_burst + c_thorn_growth: 75.0% (12/16)
- c_early_scales + c_spore_burst: 75.0% (18/24)
- c_elder_trunk + c_spore_burst: 74.3% (26/35)
- c_spore_burst + c_thorn_shield: 69.1% (47/68)
- c_field_medic + c_thorn_shield: 0.0% (0/10)
- c_dewdrop + c_loop: 0.0% (0/8)
- c_collector + c_early_scales: 0.0% (0/11)
- c_field_medic + c_mana_pool: 0.0% (0/9)
- c_night_watch + c_sacrifice: 0.0% (0/9)
