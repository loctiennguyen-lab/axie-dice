# Sim v4 - can bang (Short, A0, stage 3, offline), 21/10/2026

Nhanh v4/SV4 (engine v4 BO/Lieu/Mat Tam/Overcast + knob TD r2). Bot: random_legal (dung ca action moi), attack_spam, attack_only, expert (hoc v4), expert_no_* (ablation), expert_legacy (khong dung 4 co che v4).
So lieu goc: `sim-2026-10-21-v4_cheap/_exp1/_exp2/_abl.md|csv`. May cham (~4s/run expert) nen expert 325 run (khong 500), ablation 150 run/ban (seed 1000-1149, cung seed voi expert lo 1 de so cap).

## Win-rate
| bot | n | win | truoc v4 (TD r2) | ban cu |
|---|---|---|---|---|
| random_legal | 1000 | 14.4% | 13.3 | 20.6 |
| attack_spam | 1000 | 17.2% | 15.1 | 22.8 |
| attack_only | 1000 | 3.7% | 3.4 | - |
| expert (v4) | 325 (28.6%; seed 1000-1149: 25.3%) | 28.6% | 18.9 | 28.6 |
| gap expert - random | | 14.2 diem | 5.6 | 8.0 |

## Ablation (expert, 150 run cung seed, co so = expert v4 25.3% = 38/150)
| ban | win | delta vs expert v4 |
|---|---|---|
| expert_no_bo_hunt | 28.0% | +2.7 |
| expert_no_lieu | 30.7% | +5.4 |
| expert_no_wild | 32.7% | +7.4 |
| expert_no_overcast | 22.7% | -2.6 |
| expert_legacy (tat ca 4) | 26.7% | +1.4 |
Sai so mau n=150 ~ +-3.6 diem: chi Overcast (+2.6 dong gop) co dau hieu tich cuc, con lai nam trong nhieu. Tat Mat Tam / Lieu cho ket qua TOT HON => heuristic bot hien tai (Mat Tam 2 mana, Lieu vs An toan, san BO) chua khai thac duoc, hoac cac co che nay it gia tri o muc knob hien tai.

## Dat / chua dat muc tieu Liam
| muc tieu | ket qua | |
|---|---|---|
| Nguoi biet choi 15-25% | 28.6% (325) / 25.3% (150 dau) | CHUA DAT (hoi cao) |
| Choi bua / spam <= 5-12% | random 14.4, spam 17.2 (attack_only 3.7) | CHUA DAT (random > 12; spam > 12) |
| Khoang cach khon - bua >= 12-15 | 14.2 diem | DAT (so voi random_legal) |
| Kho hon ban cu (random 20.6, spam 22.8, expert 28.6) | random 14.4, spam 17.2, expert 28.6 | DAT voi bot bua, KHONG voi expert (bang ban cu) |

## Nhan xet
- v4 keo gian khoang cach tay nghe: 5.6 -> 14.2 diem, chu yeu vi expert tang (18.9 -> 28.6) trong khi random/spam gan nhu dung yen (13.3->14.4, 15.1->17.2). Nhung phan tang cua expert khong ro do co che nao (ablation nhieu, legacy 26.7 khong thua xa) - co the do khac biet seed/mau, can chay them.
- Game van de dang cho bot bua (14-17%) so voi muc <=12%.
- Viec tiep: tang mau ablation (>=500/ban) hoac giam nhieu bang so sanh theo cap seed; chinh heuristic Mat Tam (nguong gain) neu muon xem co che dung dung co lai loi khong.
