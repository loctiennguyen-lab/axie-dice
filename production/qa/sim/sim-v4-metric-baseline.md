# Sim v4 - metric nhay, baseline (21/10/2026)

Nhanh v4/SV4. Knob hien tai (khong chinh), Short A0, offline. 8 ban x 200 run, cung seed 1000-1199 (cap seed; team/Core xoay theo seed nen
moi ban choi cung bo ban dau). CSV goc gop: `sim-2026-10-21-metric-baseline-all.csv` (1600 dong, co cot m_*). Chay theo lo 40 run (5 lo/ban).
Chay lai/gop: `sim_balance.sh --from=<csv> --tag=...`. Bot moi: `free_hold` (reroll mien phi, giu nhom part lon nhat, khong tra mana,
khong Mat Tam/Overcast, di dice bang cung beam plan voi expert -> expert - free_hold = phan QUYET DINH TRA GIA). Hang cung expert da sua: xem commit a3493bb
(p roi dung part = 1/(6 - mat cantrip), lambda mana 0.5/0.35/0.25, --e2_samples/--e2_min_gain/--e1_*).

Dinh nghia: dmg/luot = damage gay ra (clamp, khong overkill) / luot nguoi choi; V dau luot = tong gia tri mat dmg/khien/hoi/doc sau tui M tren cac vien choi duoc, ngay sau khi tung;
V sau quyet dinh = cung so do sau reroll/Mat Tam/Overcast cua bot (luc bat dau di vien dau); sd dmg/luot = do lech chuan dmg giua cac luot trong run;
luot ha boss tinh tren run toi boss (thua boss thi tinh den luc chet); HP con = HP/maxHP ca doi sau boss, chi run thang boss (n nho, rong).
Sai so = 95% CI; bang chenh lech la CI cua hieu theo cap seed.

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


## Doc ket qua
- Nhay nhat la dmg/luot va V sau quyet dinh (CI ~ +-1.2-1.7, win-rate ~ +-7). Expert 29.9 dmg/luot, legacy 25.1 (-4.7 +-1.6), free_hold 22.8 (-7.0 +-1.6), random 22.3, spam 19.1.
- Expert vs legacy (tat 4 co che v4): +4.7 dmg/luot, V sau quyet dinh +5.7 (+-1.2) -> co tin hieu ro, win +6 +-7.6 (chua tach duoc). Tach rieng tung co che: no_wild -1.2 +-1.6 dmg, -1.8 +-1.2 V (chi tiem can); no_lieu -0.4 +-1.7 (khong thay Lieu co gia tri o knob nay); no_overcast ~0.
  Phan lon loi legacy->expert nam o thu "BO hunt bang An toan" + quyet dinh reroll lay mau (legacy tat luon no_bo_hunt), khong phai Lieu/Overcast.
- free_hold gan nhu bang random_legal ve dmg/luot (22.8 vs 22.3) nhung V sau quyet dinh cao hon (24.0 vs 22.6) -> reroll mien phi + giu nhom dua V len ~+1.9, nhung ket qua chua doi thanh dmg vi free_hold di dice tot hon random chi nho beam plan. Win free_hold 18.5% (n=200 +-5.4) nam giua spam/random (13-14.5) va expert (28).
- Tay nghe v4 (expert - free_hold) = +7.0 dmg/luot, +6.3 V, -1.3 luot ha boss, +9.5 win (+-7.4); do hoan toan tu quyet dinh tra gia + lay mau, nhung phan tach vao Lieu/Wild/Overcast thi sat 0.
- Luu y: HP con sau boss khong phan giai duoc (n 36-67/ban, CI +-0.12).

