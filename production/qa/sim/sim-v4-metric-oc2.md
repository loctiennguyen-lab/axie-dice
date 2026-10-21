# Sim v4 - vong 2 (cuoi): Overcast 2 mana +0.5, enemy_dmg_mult 1.55 (22/10/2026)

Nhanh v4/OC2. Knob: `overcast.mana_cost` 3->2, `overcast.add` 0.4->0.5, `difficulty.enemy_dmg_mult` 1.50->1.55 (commit dc3ee29). Dem mana da sua them (commit ff2e27a, xem duoi).
Bo do: 8 bot x 200 run, seed 1000-1199, Short A0, offline, teams=all, cores=random, lo 40. Rieng cap expert / expert_no_overcast them seed 1200-1399 (400 run/cap).
CSV goc: `sim-2026-10-21-oc2-all.csv` (8x200), `sim-2026-10-21-oc2-pair.csv` (cap 400). Sai so = 95% CI. Bao cao day du: `sim-2026-10-21-oc2-all.md`, `sim-2026-10-21-oc2-pair.md`.

## Dong gop co che (dmg/luot, expert - ban tat, cap seed)

| co che | 200 run (1000-1199) | 400 run (1000-1399) | vong 1 (200 run) | muc tieu |
|---|---|---|---|---|
| Overcast (CA BO) | +2.12 +-1.58 | **+1.19 +-1.05** | +0.41 +-1.28 | >= +1.5 (cat lo: >= +1.0) |
| Mat Tam (3->4, 1/tran) | +2.84 +-1.69 | - | +2.49 +-1.57 | >= +1.0 DAT |
| Lieu | +1.49 +-1.85 | - | +1.50 +-1.62 | - |

Doc: 200 run dau cho +2.12, 200 run moi (1200-1399) chi cho ~+0.3 -> chenh lech lon la nhieu mau, gop 400 run +1.19 +-1.05 la so tin hon.
Khoang tin cay 400 run (+0.14 .. +2.24) bao ca 0 va 1.5; diem uoc luong tren 1.0 nhung khong vuot muc tieu +1.5.

## Win-rate (200 run, seed 1000-1199; vong 1 trong ngoac)

| bot | win % | vong 1 | dmg/luot |
|---|---|---|---|
| random_legal | 11.0 +-4.3 | 16.0 | 18.97 |
| attack_spam | 10.5 +-4.3 | 9.0 | 18.60 |
| free_hold | 10.5 +-4.3 | 15.5 | 21.49 |
| expert | 25.0 +-6.0 | 24.0 | 29.20 |
| expert (400 run, 1000-1399) | 18.8 +-3.8 | - | 27.85 |
| expert_no_overcast | 18.0 +-5.3 (400 run: 17.5 +-3.7) | 21.5 | 27.08 |
| expert_no_wild | 19.5 +-5.5 | 16.0 | 26.36 |
| expert_no_lieu | 18.0 +-5.3 | 20.0 | 27.71 |
| expert_legacy | 17.5 +-5.3 | 19.5 | 23.02 |

expert 200 run = 25.0 nhung gop 400 run = 18.8: hai nua mau lech nhau 6 diem, nen dung 400 run (18.8 +-3.8, nam trong 20 +-3 + CI).
random/spam/free_hold 10.5-11.0 (<= 12 dat). Khoang cach: expert - free_hold +7.71 +-1.74 dmg/luot (vong 1: +6.28), expert - legacy +6.19 +-1.76 (vong 1: +4.61), expert - random +10.24.
Win-rate chenh nhau van trong CI (+-4..7 diem).

## Mana (dem da sua)

Sua: listener "+N MP" truoc day cong ca float cua nuoc di thu (use_die + undo_last) cua expert/free_hold; cap theo mana tang that chi chan tren. Nay listener tat trong `_choose_move` (chi suy nghi), bat lai trong reroll that, nen cot "mat mana" cua cac bot expert_*/free_hold dung nhu 3 bot vong 1. Ca 8 bot cung mot ban dem.
"thua/luot" la TON mana truoc end_turn (carry), khong phai ty le; dung "tieu/nhan".

| policy | nhan/luot | tieu/luot | tieu/nhan % | ton cuoi luot | nhan: mat | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|
| attack_spam | 0.70 | 0.42 | 60 | 7.23 | 0.44 | 0.16 | 0.09 | 0.00 |
| random_legal | 1.41 | 0.93 | 66 | 7.64 | 0.78 | 0.21 | 0.06 | 0.36 |
| free_hold | 1.24 | 0.50 | 41 | 7.47 | 0.51 | 0.17 | 0.06 | 0.49 |
| expert | 1.53 | 1.32 | 86 | 4.09 | 0.61 | 0.17 | 0.07 | 0.67 |
| expert_legacy | 1.28 | 0.71 | 56 | 6.73 | 0.53 | 0.16 | 0.05 | 0.54 |
| expert_no_lieu | 1.39 | 1.21 | 87 | 3.96 | 0.59 | 0.15 | 0.07 | 0.58 |
| expert_no_overcast | 1.41 | 0.98 | 70 | 5.30 | 0.56 | 0.13 | 0.07 | 0.64 |
| expert_no_wild | 1.59 | 1.17 | 73 | 6.87 | 0.62 | 0.14 | 0.06 | 0.77 |

expert tieu vao: An toan 20%, Mat Tam 20%, Overcast 23%, Lieu/khac 38%; mua/run: Overcast 5.25, Mat Tam 4.58 (100% o n=3->4). Co BO + >=3 mana dau luot 18.7% luot; sau quyet dinh con 9.9%.
Ghi chu: cot "khac" 0.5-0.8 van la phan du khong tach duoc (Core hook); mat mana (0.5-0.6/luot) van la nguon chinh.

## Ket luan theo quy tac cat lo (< +1.0 dmg/luot sau 2 vong thi bo)

- Overcast: vong 1 +0.41 (dua duoi +1.0), vong 2 (2 mana, +0.5) +1.19 +-1.05 tren 400 run. Diem uoc luong qua +1.0 nen THEO LUAT: GIU. Nhung chua dat +1.5 va CI cham duoi +1.0 (lower +0.14). Day la giu "sat nut", khong phai thang ro; neu Liam muon chac, can ~1000 run/cap de CI +-0.7.
- Mat Tam: +2.84 +-1.69 >= +1.0: GIU.
- Lieu +1.49 (khong thuoc luat nay).
- Do kho: expert 18.8% (400 run) trong muc 20 +-3 voi CI; random/spam/free_hold ~11%, khong con vot. enemy_dmg_mult 1.55 giu duoc.
