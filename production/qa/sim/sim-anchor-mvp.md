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
### Vong 2: Volley pct 40/65/90 cap 20, house_bias 3.5, axis_bias 2.5, them `anchor_partner_bias` 2.0 (core_offer.gd, relic_tuning.gd).
Do vong 2: expert auto 13.3 (n=120); ep Volley 11.2 / Gambler 13.8 / Mana Mine 17.5 (n=80); random 7.5; spam 2.5; thuc tinh auto Volley 25 / Gambler 44 / Mine 28% (ep: 27.5/40/38.8%); dot bien nac1 nha Anchor: Volley 16 / Gambler 22 / Mine 16%; combo/run 0.39-0.46.
Ket luan: bias them (house 3.5, axis 2.5, partner x2) gan nhu khong nang combo/run (0.34 -> 0.4): nut that la so moc chon Loi (4/run), khong phai ti le xuat hien. CI +-7 diem nen chenh giua Anchor chua phan biet duoc.
### Vong 3: Volley set_add 0.05->0.0, Gambler Nut 25->15 va set_add 0.30->0.35, house_bias 5.0, axis 3.0, partner 3.0.
Do vong 3: expert auto 14.2 (n=120); ep Volley 10.0 / Gambler 16.2 / Mana Mine 15.0 (n=80); random 6.7; spam 2.5; thuc tinh auto Volley 17 / Gambler 52 / Mine 33% (ep: 21/49/40%); dot bien nac1 nha Anchor ep: Volley 10 / Gambler 24 / Mine 24%; combo/run 0.33-0.53.
### Bang tong ket (trung binh 3 Anchor ep: R1 12.8 / R2 14.2 / R3 13.7; auto 11.7 / 13.3 / 14.2)
| chi so | muc tieu | truoc | V1 | V2 | V3 |
|---|---|---|---|---|---|
| expert auto | 20+-3 | 11 | 11.7 | 13.3 | 14.2 |
| random / spam | <=12 | 7 / 7.5 | 5.8 / 2.5 | 7.5 / 2.5 | 6.7 / 2.5 |
| chenh 3 Anchor (ep) | <=5 | 2 | 8.7 | 6.3 | 6.2 |
| thuc tinh min Anchor | >=33% | 14% | 19% | 25% | 17% (auto, Volley) / 21% (ep) |
| dot bien nac1 nha | >=40% | <=17% | <=26% | <=22% | <=24% |
**Ket luan: CHUA DAT sau 3 vong.** Knob cuoi: volley 40/65/90 cap 20 set_add 0.0; gambler Nut 15% set_add 0.35; mine wild 2; house_bias 5.0, axis_bias 3.0, partner_bias 3.0 (moi). Ly do: giam gia + buff nhe dua expert tu 11 len ~14; bias nang Loi ruot (x1.7-2.3) nhung combo/run chi 0.3->0.4 vi chi co 4 moc chon Loi/run. Van xa 20: de dat can doi co che (them moc chon Loi, ha nguong Cap, hoac Anchor cho +dame truc tiep), khong chi so knob. Volley van yeu nhat (10), nhieu khi Volley khong thuc tinh (can 2 Loi ruot, Loi nha Volley nam o tier H). CI +-7 nen chenh giua Anchor chua tin duoc ngay ca voi 80 run.
Test sua expect: t_anchor_rules, t_anchor_awaken, t_core_offer_weights (ratio 1.15..2.6). Xanh: t_anchor_rules 190, t_anchor_awaken 37, t_mutation_houses 86, t_core_offer_weights 57, t_core_combos 143, t_anchor_runstate 84, t_anchors 172.

## Vòng 6 mốc (22/10, sau d533bd2)
Cách đo: Short A0 stage 3, lô 40, chạy song song ở 4 worktree (SA, SA2-4 detached). Gộp bằng script đọc CSV `sim-*-<vòng>_*.csv`.
"Đột biến nhà bất kỳ" = % run có ≥1 nhà nấc ≥1; "nhà Anchor" = riêng nhà của Anchor đang cầm.

| vòng | knob | expert auto | ép G / M / V | random / spam | thức tỉnh G/M/V (ép) | đột biến bất kỳ (auto) |
|---|---|---|---|---|---|---|
| v6 (n=160, ép n=80) | gốc (V3 cũ) | 18.1 | 17.5 / 21.2 / 23.8 | 11.7 / 6.7 | 58/59/40 | 49% |
| w1 (n=160) | V 35/55/80 cap18, G +0.40 Nứt 12 | 16.2 | 13.8 / 15.0 / 20.0 | 11.7 / 5.8 | 52/49/42 | 48% |
| w2 (n=160) | + G +0.45 cap .80 Nứt 10, M Mặt Tạm 1 | 12.5 | 11.2 / 9.4 / - | 12.5 / 5.8 | 52/48/- | 47% |
| w3 (n=400) | gốc + sửa engine (review) + pick_anchor trong log | 12.0 | 11.5 / 13.0 / 16.5 | 6.5 / 6.0 | 54/54/39 | 44% |
| w5 (n=240) | buff mạnh: V 50/75/100 cap24, G +0.45 cap .90 Nứt 8, M +2 mana, Mặt Tạm 1 | 13.8 | 11.2 / 14.6 / 16.7 | 5.5 / 4.5 | 55/50/36 | 42% |
Expert không Anchor: 23.5% (n=400). Expert có Anchor ở stage 2: 14.4% (n=160).

Lưu ý nhiễu: từ khi `pick_anchor` vào action log, seed epoch local băm cả log nên dãy RNG sau lượt chọn Anchor khác hẳn bản cũ; "cùng seed" trước/sau không còn so cặp được. v6 18.1 là mẫu may (cùng knob, w3 ra 12.0 với n=400).

Chẩn đoán (expert ép Volley, n=160 mỗi biến thể): tắt đột biến 16.9; bias offer = 1.0 16.9; bot bỏ ưu tiên Lõi ruột 13.8; giữ luồng Anchor nhưng tắt mọi hiệu ứng Anchor trong trận 13.8; mở màn Anchor rồi TỪ CHỐI (không Anchor nào) 14.4 so với không có màn 23.5-25.
=> Hiệu ứng Anchor trong trận có lợi (+2-3), đột biến trung tính, buff luật nền gần như không đổi số. Phần tụt ~10 điểm nằm ở LUỒNG mở run khi có màn Anchor (kể cả khi từ chối): mana đầu lượt trung bình 2.79 -> 1.04, m_v0 886 -> 712. Đang truy gốc (agent riêng).
Knob giữ: gốc (V 40/65/90 cap 20, G +0.35 cap .60 Nứt 15, M +1 mana, Overcast 1, Mặt Tạm 2) — buff không đổi số nên giữ bản đã duyệt. Chữ luật sửa: cả 3 Anchor không có giá thật ở knob này (Nứt gốc 30%, Mặt Tạm gốc 2), nên bỏ dòng PRICE.
