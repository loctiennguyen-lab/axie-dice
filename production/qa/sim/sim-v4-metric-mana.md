# Sim v4 - metric nhay, phuong an mana MD (22/10/2026)

Nhanh v4/SM @ 6751c99 (Overcast chi khi co BO, +0.4 cho CA BO, 3 mana, 1 lan/luot; Mat Tam chi 3->4, 2 mana, 1 lan/tran) + tooling do mana tu 5eed4b4. Cung bo do voi A+:
8 ban x 200 run, seed 1000-1199, Short A0, offline, teams=all, cores=random, lo 40. CSV goc: `sim-2026-10-21-metric-mana-all.csv`. Sai so = 95% CI.
Bot expert da sua cho luat moi (commit edfbd52): Overcast cham gia tri CA BO (`overcast_group_preview`; engine tu chan khi khong co BO); Mat Tam chi xet khi
`wild_block_reason` == "" (tuc chi n=3->4). Phan "de danh theo EV" KHONG them luat rieng (khong tu dat luat): Mat Tam bam khi loi hon gia mana theo mo hinh, nhu cu.
random_legal chon ngau nhien trong hanh dong ma engine bao hop le.

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

## So voi A+ (cung bot, cung seed; A+ = `sim-v4-metric-aplus.md`)

| bot | dmg/luot A+ | dmg/luot MD | d dmg (cap seed) | win A+ % | win MD % | d win |
|---|---|---|---|---|---|---|
| random_legal | 20.19 | 20.15 | -0.03 +-1.53 | 12.5 | 16.0 | +3.5 +-6.1 |
| attack_spam | 18.65 | 19.47 | +0.82 +-1.60 | 11.5 | 9.0 | -2.5 +-6.1 |
| free_hold | 22.40 | 22.34 | -0.05 +-1.70 | 16.5 | 15.5 | -1.0 +-7.4 |
| expert | 27.93 | 28.62 | +0.69 +-1.86 | 22.0 | 24.0 | +2.0 +-8.2 |
| expert_no_lieu | 26.57 | 27.12 | +0.56 +-1.86 | 21.0 | 20.0 | -1.0 +-8.1 |
| expert_no_wild | 28.49 | 26.13 | -2.36 +-1.81 | 25.5 | 16.0 | -9.5 +-7.7 |
| expert_no_overcast | 27.97 | 28.21 | +0.24 +-1.90 | 25.5 | 21.5 | -4.0 +-7.6 |
| expert_legacy | 22.88 | 24.01 | +1.13 +-1.57 | 15.0 | 19.5 | +4.5 +-7.1 |

## Dong gop co che (dmg/luot, expert - ban tat, cap seed) so muc tieu

| co che | expert - ban tat | muc tieu | ket qua |
|---|---|---|---|
| Overcast (CA BO) | +0.41 +-1.28 | >= +1.5 | KHONG DAT (A+: -0.04) |
| Mat Tam (3->4, 1/tran) | +2.49 +-1.57 | >= +1.0 | DAT (A+: -0.56) |
| Lieu | +1.50 +-1.62 | - | (A+: +1.36) |
| expert - free_hold | +6.28 +-1.67 | rong hon A+ (+5.53) | rong hon 0.75 (trong nhieu) |
| expert - legacy | +4.61 +-1.77 | rong hon A+ (+5.05) | hep hon 0.44 (legacy tu no cung tang +1.13, trong nhieu) |

Win: random 16.0, spam 9.0, free_hold 15.5, expert 24.0 (muc tieu 20 +-3; CI cua expert +-5.9). Cac chenh win deu trong nhieu (CI +-6..8 diem).

## Mana (da sua cach dem)

**Da sua loi DEM**: cot "nhan tu mat mana" ra 0 vi moi mat mana la Tai cantrip, tu chay trong `roll_all/reroll -> _resolve_cantrips()` truoc khi bot hanh dong,
nen mana do roi vao "dau luot"/"khac". Nay `sim_balance.gd` nghe `EventBus.float_text` ("+N MP", css "man") de dem luong mat mana (commit 59b2caf).
Mat mana luc tung dau luot la so chinh xac; mat mana tu reroll giua luot bi chan tren boi muc tang mana khong giai thich duoc (expert co tung thu roi undo, cung phat float).
Chi giu 4 bot (attack_spam, random_legal, free_hold, expert): cac bot expert_* kia chay voi ban dem cu, phan mx cua chung khong tin duoc (dmg/win khong anh huong).
Cot "thua" la TON mana truoc end_turn (carry giua luot), khong phai ty le; dung "tieu/nhan". Cot "Mat mana lan ra" cuoi bang goc luon 0 (mat mana la cantrip da dung), bo qua.

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 200 | 37.24 | 0.77 | 0.43 | 7.56 | 55 | 980 | 0.43 | 0.00 | 0.26 | 0.08 | 0.00 |
| free_hold | 200 | 37.64 | 12.59 | 11.72 | 7.69 | 93 | 61 | 11.73 | 0.00 | 0.31 | 0.08 | 0.47 |
| random_legal | 200 | 34.66 | 1.35 | 0.91 | 6.57 | 68 | 486 | 0.70 | 0.00 | 0.29 | 0.04 | 0.31 |
| expert | 200 | 35.38 | 1.53 | 1.33 | 4.61 | 87 | 302 | 0.61 | 0.00 | 0.24 | 0.05 | 0.62 |

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| attack_spam | 0 | 0 | 0 | 0 | 100 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| free_hold | 0 | 0 | 0 | 0 | 100 | 0.20 | 0.14 | 20.91 | 0.00 | 0.00 | 0.00 |
| random_legal | 6 | 0 | 5 | 6 | 82 | 1.64 | 0.08 | 5.04 | 0.80 | 0.67 | 8.46 |
| expert | 13 | 4 | 18 | 26 | 39 | 5.62 | 0.89 | 18.20 | 4.28 | 4.11 | 10.81 |

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| attack_spam | 0% (0) | 0% (0) | 0% (0) | 16.2 | 7.7 | 7.7 |
| free_hold | 0% (0) | 0% (0) | 0% (0) | 30.8 | 14.7 | 16.0 |
| random_legal | 0% (0) | 100% (160) | 0% (0) | 15.9 | 6.1 | 6.1 |
| expert | 0% (0) | 100% (856) | 0% (0) | 31.9 | 13.7 | 7.4 |

"Lieu/khac" = khoan tru mana khong thuoc An toan / Mat Tam / Overcast (Lieu 0 mana; hook/Loi). Bang day du (kem 4 bot mana cu): `sim-2026-10-21-metric-mana-all.md`.
