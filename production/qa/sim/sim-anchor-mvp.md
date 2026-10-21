# Sim Anchor MVP (SA, nhanh sim/anchor = anchor/eng 60d55a6)

Cau hinh: Short A0, stage 3, `anchor:true`, seed 1000-1199, 200 run/bot (5 lo x 40). Raw CSV + bao cao day du: `raw/`.
Bot chon Anchor: random_legal/attack_spam/free_hold = ngau nhien; expert = heuristic doi (plant/reptile -> Volley, aqua -> Mana Mine, con lai -> Gambler); expert nghieng +3 diem cho Loi ruột khi chon Loi (policy combo).

## Nhom 1: Anchor tu chon
Baseline truoc Anchor (v4 OC2): expert 18.8, random 11, spam 10.5, free_hold 10.5.

| bot | win (200 run) | baseline |
|---|---|---|
| expert | 11.0% | 18.8 |
| random_legal | 7.0% (xem bang duoi) | 11 |
| attack_spam | 7.5% | 10.5 |
| free_hold | 7.0% | 10.5 |

Chi tiet theo Anchor (pick%, win%, % run thuc tinh, node/luot thuc tinh): xem `raw/sim-*-anchor-auto.md` muc "## Anchor". Tom tat expert: Gambler 45% pick / 10.0% win / 38.9% thuc tinh; Volley 40% / 10.0% / 12.5%; Mana Mine 15% / 16.7% (n=30) / 23.3%.
Dot bien Cap (expert, % run co >=1): h_gambler 15.5%, h_mana_mine 5.5%, h_kin 5%, h_volley 3%, h_embers 1%, h_big_hand 1%; nac 2 <=2%. Combo formed trung binh 0.33/run.

## Nhom 2: expert none va ep tung Anchor (200 run moi, seed 1000-1199)

| expert | win +-CI95 | thuc tinh % | node thuc tinh (TB) | luot combat thuc tinh (TB) | dmg/luot | combo formed |
|---|---|---|---|---|---|---|
| none (khong Anchor) | 17.5% (+-5.3) | - | - | - | - | - |
| ep a_volley | 11.0% +-4.3 | 14.0 | 7.6 | 17.8 | 28.5 | 0.29 |
| ep a_gambler | 9.0% +-4.0 | 33.0 | 6.2 | 15.4 | 25.9 | 0.36 |
| ep a_mana_mine | 10.0% +-4.2 | 28.0 | 5.6 | 12.2 | 26.9 | 0.35 |
| tu chon (heuristic) | 11.0% | 29.0 (gop) | | | | 0.33 |

Do chenh giua 3 Anchor: 2.0 diem (dat <=5, nhung nam trong nhieu CI). Pick rate la do heuristic doi, khong phai "Anchor manh": Gambler 45%, Volley 40%, Mana Mine 15%.
Dot bien Cap: h_gambler 11-16% run co nac 1, h_mana_mine 17% khi ep Mana Mine, nha khac <=7.5%; nac 2 <=4% moi nha. Combo formed ~0.3/run (it) la goc re cua ca thuc tinh lan dot bien.

## So voi muc tieu
- expert 20+-3: CHUA DAT. 17.5% khi khong Anchor (dat), nhung co Anchor 9-11%. Random 7.0 (<=12 dat), spam 7.5 (dat), free_hold 7.0 (dat).
- Anchor thuc su KHONG lam game de di: no lam khoang 7 diem kho hon cho expert (17.5 -> ~10.3). Ca random/spam cung tut 3-4 diem.
- Chenh giua Anchor <=5: DAT (2 diem). Pick rate 10-60%: DAT (15/40/45) nhung do heuristic.
- Thuc tinh >=33% run: CHUA DAT tru Gambler (33%); Mana Mine 28%, Volley 14%. Cua random/spam chi 4-22%.
- Dot bien Cap: nac 1 hiem (Volley 3-5%, Embers/Big Hand ~1%), nac 2 gan nhu khong: CHUA DAT "du thuong".

## De xuat knob
1. Nguyen nhan chinh: phi cua Anchor (Volley -0.15 BỘ, Gambler Nut 40%, Mana Mine Mat Tam 3) nang hon loi vi luat nen yeu va thuc tinh den muon. Giam phi hoac tang luat nen (vd Volley cost -0.15 -> -0.05, Gambler Nut Lieu 40% -> 25%) cho win-rate ve ~17-20.
2. Thuc tinh/dot bien hiem vi chi ~0.3 combo/run: tang `anchor_house_bias` 1.5 -> 2.5 va `anchor_axis_bias` 1.5 -> 2.0 (ti le Loi ruot hien chi x1.2-1.37), hoac ha nguong thuc tinh xuong con 2 Loi ruot trong 1 offer dau; Volley can chu y nhat (14%).
3. Mana Mine chi 15% khi expert tu chon (heuristic chi chon khi doi nhieu aqua); can heuristic/nhan xet tot hon truoc khi ket luan ve pick rate.
Lenh tai tao: `godot/tools/sim_balance.sh --runs=40 --seed=<s> --policies=expert --anchor=auto|none|a_volley|a_gambler|a_mana_mine`.

## Chan doan (~0.3 combo/run)
1. `sim_combo_draw.gd` (1000 run, policy random): 4 moc chon Loi/run x 3 the = 12 the thay; 26.9% run co >=1 Cap, 0.31 combo/run (quest/shop/event Loi khong tinh).
2. Moi combo chi 0.9-4.7% run; Loi ruot cua Anchor la 5 trong ~50 Loi, bias house 1.5/axis 1.5 chi nhan ~x1.2-1.4.
3. Bot expert co Anchor chi 0.34-0.42 combo/run => bias cu gan nhu khong doi gi; thuc tinh can 2 Loi ruot nen thuong den muon (19-44% run).
4. Khong co bias nao day Loi ban-doi-tac: Loi con lai cua combo da co 1 Loi chi duoc xuat hien theo xac suat thuong => them knob `anchor_partner_bias` (chi khi co Anchor).
5. Anchor khong Anchor 17.5 vs co Anchor ~11: gia Anchor (nhat Volley) nang hon loi, khong phai chi do it combo.

## Vong chinh
### Vong 1 (Volley set_add 0.15->0.05, Gambler Nut 40->25, Mana Mine Mat Tam 3->2, house_bias 2.5, axis_bias 2.0)
Do: expert auto 120 / random 120 / spam 80 / ep Anchor 80 moi cai.
| chi so | truoc | vong 1 |
|---|---|---|
| expert auto | 11.0 | 11.7 |
| ep Volley / Gambler / Mana Mine | 11 / 9 / 10 | 8.8 / 17.5 / 16.2 |
| random / spam | 7 / 7.5 | 5.8 / 2.5 |
| thuc tinh (auto) Volley/Gambler/Mine | 14/33/28% | 19/44/39% |
| dot bien Cap nac1 (nha Anchor) | <=17% | Volley 6 / Gambler 15-26 / Mine 14% |
| combo/run | 0.3 | 0.34-0.40 |
Ket luan: Gambler/Mine len ~17, Volley van yeu (8.8), bias hau nhu khong tang combo.
### Vong 2 (dang chay): Volley pct 40/65/90 cap 20, house_bias 3.5, axis_bias 2.5, them `anchor_partner_bias` 2.0 (core_offer.gd, relic_tuning.gd).
