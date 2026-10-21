# Sim v4 - metric nhay, A+ (21/10/2026)

Nhanh v4/SV4 @ e618162 (A+: bo add 0.3/1.2/1.6 scale 1.0 -> x1.3/x2.2/x2.6; An toan lan dau 1 mana; Mat Tam 3 mana, khong tao Bo nam; enemy_dmg_mult 1.50).
Cung bo do voi baseline (`sim-v4-metric-baseline.md`): 8 ban x 200 run, seed 1000-1199, lo 40, Short A0 offline, bot/param mac dinh. CSV goc: `sim-2026-10-21-metric-aplus-all.csv`.
Dinh nghia metric va cach doc: xem bao cao baseline. Sai so = 95% CI.

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


## SO VOI BASELINE (cung bot, cung seed; delta theo cap seed)

| bot | n cap | dmg/luot (base -> A+) | delta dmg/luot | win % (base -> A+) | delta win |
|---|---|---|---|---|---|
| attack_spam | 200 | 19.12 -> 18.65 | -0.47 +-0.57 | 14.5 -> 11.5 | -3.0 +-4.8 |
| expert | 200 | 29.86 -> 27.93 | -1.93 +-1.76 | 28.0 -> 22.0 | -6.0 +-8.3 |
| expert_legacy | 200 | 25.14 -> 22.88 | -2.27 +-1.33 | 22.0 -> 15.0 | -7.0 +-6.9 |
| expert_no_lieu | 200 | 29.46 -> 26.57 | -2.90 +-1.62 | 27.5 -> 21.0 | -6.5 +-7.4 |
| expert_no_overcast | 200 | 29.63 -> 27.97 | -1.66 +-1.73 | 32.0 -> 25.5 | -6.5 +-7.9 |
| expert_no_wild | 200 | 28.67 -> 28.49 | -0.19 +-1.65 | 30.5 -> 25.5 | -5.0 +-8.2 |
| free_hold | 200 | 22.84 -> 22.40 | -0.44 +-1.20 | 18.5 -> 16.5 | -2.0 +-6.7 |
| random_legal | 200 | 22.26 -> 20.19 | -2.07 +-1.22 | 13.0 -> 12.5 | -0.5 +-5.6 |

## Doc ket qua
- (a) Chenh expert - legacy: dmg/luot +5.05 +-1.61 (baseline +4.71 +-1.62), V sau quyet dinh +6.2 +-1.2 (baseline +5.7) -> khong rong ra ro (trong sai so). expert - free_hold: +5.5 +-1.7 (baseline +7.0 +-1.6), thu hep chut. A+ khong tang khoang cach tay nghe do duoc.
- (b) Dong gop tung co che (expert - ban tat): Lieu +1.4 +-1.5 dmg (baseline +0.4), V +1.0 +-1.2; Mat Tam -0.6 +-1.6 dmg, V +0.9 +-1.2; Overcast 0.0 +-1.4 dmg. Tat ca trong sai so; chi Lieu nhich len, Mat Tam/Overcast ~0 (win cua no_wild/no_overcast thanh cao hon expert +3.5 +-7).
  Phan lon khoang expert - legacy van den tu quyet dinh reroll lay mau + san Bo (legacy tat no_bo_hunt).
- (c) Win-rate (n=200, +-4.4 den 5.8): random 12.5, attack_spam 11.5, free_hold 16.5, expert 22.0 (muc tieu expert 20+-3 dat; random/spam <= 10-12: spam 11.5 sat bien, random 12.5 hoi tren). Khoang expert - random 9.5 +-7.0, expert - free_hold 5.5 +-7.3.
- A+ ha moi bot ve dmg/luot (random -2.1, expert -1.9, legacy -2.3: do enemy_dmg_mult 1.50 va bag keo; spam/free_hold ~0) va ha win ~2-7 diem; CI cua win van lon (+-7), nen dung dmg/luot va V de so.
