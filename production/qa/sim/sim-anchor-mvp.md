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
