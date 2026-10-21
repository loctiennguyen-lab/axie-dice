# Sim v4 - bot expert v2 (quyet dinh bang ky vong lay mau), 21/10/2026

Nhanh v4/SV4. Short, A0, stage 3, offline, cung seed (1000+). CSV goc: `sim-2026-10-21-bot2_*.csv`.
Do so luong: may tai cao (load 25-40 do cac lane khac) nen mot lo 126 run x 2 policy bi treo/qua 600s va mat; chay lai theo lo 21 run.
Khong dat 500/300 run: expert 252, ablation 126 (cung seed 1000-1125; expert/no_lieu co them 1126-1251).

## 1. Loi heuristic cu (trace 15 run, 854 quyet dinh, `AXIE_SIM_TRACE=<file>`)
- Hunt BO bang Lieu tung lai MOI vien ngoai nhom part tot nhat, khong tinh gia tri hien tai cua cac vien do; 58/241 lan Lieu lam tut gia tri,
  vien bi Nut con nua gia tri (vd dm12 -> sh8 Nut, dTV -4). HUNT_LIEU TB +1.5 so voi HUNT_SAFE +3.6; WEAK_LIEU +5.3.
- Xac suat hoan thanh BO chi xap xi (p mat 1/6 x (1-nut)), khong lay mau, khong tinh vien outside co gia tri cao.
- Mana tinh co dinh 0.5/mana du dang co 0 hay 20 mana (trace: mana=13-20 van "tiet kiem"; mana=0-3 van tieu Safe 2-3). Mat Tam / Overcast
  chon theo uoc luong plan beam-1 co mana gia phang.
- Mat Tam o trace co dTV TB +13, Overcast +12: tren thang do cua bot thi co loi, nhung ablation khong cho thay do thanh thang (xem duoi).
## 2. Expert v2 (commit 91d98b7)
Mot vong tham lam moi luot (toi da 6 hanh dong) tren {khong lam gi, tung lai tap S Safe/Lieu, Mat Tam (vien,slot), Overcast vien}.
Gia tri = E[value sau] - value hien tai - mana x lambda(mana) (0.7 / 0.35 / 0.15 khi mana <6 / <10 / >=10). 16 mau tung lai bang rng RIENG cua bot
(khong dung rng game), cung mau cho moi lua chon (common random numbers). Mo hinh gia tri: _face_base + tui M (bo_add100/cap/hi_add), Nut chia doi,
trong so theo loai mat; Overcast dung `overcast_preview`; Mat Tam kiem `wild_block_reason`. Chuc nang goc `expert_old` van con. Toc do ~1.8-3 s/run
(truoc: ~3-4 s/run), khong cham hon.
## 3. Ket qua (95% CI; so sanh theo cap seed)
| ban | n | win | khac expert (cap seed) |
|---|---|---|---|
| expert v2 | 252 | 24.2% +-5.3 | - |
| no_lieu | 252 | 21.8% +-5.1 | -2.4 +-6.5 |
| no_wild | 126 | 28.6% +-7.9 | +4.0 +-9.7 |
| no_overcast | 126 | 26.2% +-7.7 | +1.6 +-7.6 |
| no_bo_hunt | 126 | 26.2% +-7.7 | +1.6 +-10.4 |
| legacy (tat 4) | 126 | 27.0% +-7.8 | +2.4 +-10.0 |
(expert tren 126 seed dau: 24.6%.) Cu: expert v1 28.6% (325) / 25.3% (150); v2 24.2% - khong khac (trong sai so).
## 4. Ket luan
Quyet dinh "dung" (v2) KHONG thang ro rang: moi ablation nam trong sai so (+-8 den +-10 diem); legacy 27.0 >= expert 24.2.
Khong chung minh duoc 4 co che thuong tay nghe o muc knob hien tai; khong chung minh duoc la khong co (can ~1500+ run/ban de phan giai 2-3 diem).
Goi y: tang mau (n>=1000/ban) hoac do bang metric nhay hon win-rate (HP con lai, so luot/boss); xem lai gia tri thiet ke cua Lieu/Mat Tam o muc knob nay
vi mo hinh bot hop ly cung khong khai thac duoc loi.
