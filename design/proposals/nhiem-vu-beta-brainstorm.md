Trạng thái: BRAINSTORM, chờ Liam duyệt hướng. Chưa plan, chưa code, chưa sim.

> **Liam duyệt 26/10 (trả lời từng câu):** (1) nâng nhà Nhiệm vụ: HOÃN, nhà giữ cấp 1, mở bậc bằng chuỗi thắng. (2) KHOÁ SỐ theo sim bot luôn, KHÔNG chờ Liam chơi ~30 run hiệu chuẩn. (3) BẬT cược Shard (cả các bậc, không chờ server kiểm hết; việc Worker kiểm rules/mở bậc vẫn làm nhưng không chặn bật). (4) GIỮ "heavy không lãi N1-N4"; N6 bậc danh hiệu. (5) Gói beta Land: CÓ. (6) Beta chạy CHỦ YẾU DESKTOP; SẼ XOÁ TIẾN ĐỘ sau beta (→ được hạ tier 2 xuống 20k; web nhẹ ưu tiên thấp hơn). (7) Reroll: PB (xúc xắc bay ngay, kết quả về lúc lăn) sau khi đo RTT thật từ VN; RTT quá cao thì PA (gửi trước cả lượt). (8) Số dư Shard/Stone/unlock: RESET (M1). (9) KHÔNG trần payout theo ngày (Liam chấp nhận rủi ro mint giữa B1-B3; chỉ còn kiểm tối thiểu ở run_close). (10) Khách: chỉ tutorial + run thường, không ranked/Nhiệm vụ, đăng ký chỉ mang lịch sử run.
**Đã sửa theo review 26/10** (`nhiem-vu-beta-brainstorm-review.md`, economy-designer, APPROVE WITH CHANGES): công thức m, việc Worker phải kiểm, giá trị Shard, N6/N5, bộ luật A/B, sim, hiệu chuẩn bot→người, các chỗ đảo quyết định 13/10.

# Nhiệm vụ (risk-to-earn) bản beta — brainstorm

Tác giả: game-designer · 26/10/2026. Đọc: `nhiem-vu-risk-to-earn.md` (doc cũ, 12-13/10), `missions.json`, `mission_rules.json`, `ascension.json`, `mission_board.gd`, `worker/src/missions.js`, `sim-v5.md`, `sim_balance.gd`, `economy-v2.md`.
Mọi số dưới đây là **giả thuyết để sim kiểm**. Chỗ cần sim ghi "SIM".

Liam chốt 26/10 (bắt buộc): bậc cao nhất người giỏi thắng < 5%; bậc thấp nhất ~15-25% (ngang run thường); giữ cược Shard, thua mất cược, không tiền thật; dùng lại luật/độ khó có sẵn.

## 1. Vấn đề hiện tại

1. **Bảng số doc cũ lỗi thời.** Nó dựng trên "regular thắng 47% ở A3" (`ascension-v2.md` §5.1, chưa đo). Sim v5 cho expert bot ở A0 **khoảng 16-21%** (không phải một số: 16,2 ở bảng anti-spam với cấu hình đã chọn; 20,6 ở vòng Anchor 3, CI ±4-5, n 246-287/ô). N1 cũ (A3 + 2 luật M + chuẩn) rất có thể dưới 10%, trái ý Liam.
2. **Chưa có số đo cho Nhiệm vụ.** `sim_balance.gd` hard-code `"mode":"short"` (dòng ~199), `_anchor_mode` mặc định `none`, không có header mission, không có luật M. Chưa ai đo A3..A9; Full chưa chạy lần nào (`full_exponent` 1,5 chỉ là đoán).
3. **N4-N6 và nâng nhà tắt** (`enabled:false`, `house_upgrade_enabled:false`; Worker 403 `tier_locked`). Nhà cấp 4 = 20.000 Shard + 30.000 Stone, và Stone cho nó cạnh tranh với tier Land (nguồn Stone: daily 500, Echo Box, Nhiệm vụ trần 150/ngày).
4. **Mở bậc ở client** (`mission_board.gd:88`, `asc_wins` trong save). Worker chỉ kiểm `enabled`, `stake`, `ascension` (`missions.js:28-38`); không kiểm luật M, không kiểm mở bậc.
5. **Thắng/thua là client tự báo** (chưa verifier; `missions.js` đầu file ghi rõ). Shard không có số dư server, chỉ ghi ledger; số dư thật ở save client.
6. **Màn chưa nói "kỳ vọng nhận về" và xác suất.** Với cược, mơ hồ là lỗi nặng (§5).

## 2. Ba hướng làm thang 6 bậc

Chung: payout = `cược × m` (trần 20.000), m tính **sau** khi đo p (§4), thua = mất cược, không bán gì trong run (MON-12/13).

### Hướng A — "Giữ khung cũ, đo lại, chỉnh d"
Giữ Ascension 3/4/6/7/9/9, bộ A/B xoay ngày, mở bậc bằng "thắng ở Ascension X", nhà nâng bằng Shard+Stone.
- Được: ít việc nhất.
- Mất: độ khó trộn hai nguồn nên khó chỉnh; cổng "thắng A3" nghẽn người mới; nhà cấp 4 bất khả.
- Rủi ro: phải kéo d của luật M về gần 0 để N1 không quá khó, bỏ luôn tính riêng của Nhiệm vụ.
- Không khuyến nghị.

### Hướng B — "Một thang: Ascension thấp + luật M, mở bậc theo chuỗi thắng" (khuyến nghị)
Một bộ luật cố định mỗi bậc (**bỏ xoay A/B cho beta**: hai bộ có d khác nhau mà m chỉ có một, người chờ ngày bộ dễ sẽ ăn m của bộ khó; sim cũng phải đo gấp đôi). Điểm xuất phát (SIM sẽ sửa):

| Bậc | Mode | Ascension | Luật thêm (đã có) | Ý |
|---|---|---|---|---|
| N1 | Short | A0 | chỉ "chuẩn" (dmg ×1,1, elite HP ×1,1) | gần run thường |
| N2 | Short | A1 | + M6 | quân dày hơn (A1 chỉ ×1,1 HP, giá shop; A2 chỉ thêm `elite_extra`, nên chọn A1) |
| N3 | Short | A3 | + M5 + M6 | boss dày |
| N4 | Short | A4 | + M1 + M7 | đồng hồ gắt, elite hung |
| N5 | Short | A6 | + M2 + M4 + M5 | đòn dồn, nặng (M2 đã có trong engine `combat_engine.gd:3442`, test `t_mission_rules`) |
| N6 | **Full** | A6 | + M1 + M5 + M6 + M7 | bậc danh hiệu |

- Mở bậc: thắng N(k) thì mở N(k+1); N6 cần thêm một run Full thắng. Tuỳ chọn chống may mắn: cần 2 thắng (SIM nói được N1-N4 có kéo dài quá không).
- Nâng nhà: hoãn (câu hỏi 1).
- **Chỗ đảo quyết định Liam 13/10, nêu rõ:** (1) N6 từ "Full ở **A9**" xuống "Full ở **A6**" (bỏ `unlock_full_a9`); (2) "nhà mở bậc" thay bằng chuỗi thắng, `house_level` không còn gate bậc trong beta; (3) bỏ `unlock_win_asc` theo Ascension. Cả ba là hệ quả của việc Ascension cao quá khó khi game đã khó hơn; cần Liam gật.
- Được: một thang đọc được, chỉnh bằng đổi/bỏ một luật M, người mới vào ngay, Land không phải làm gì.
- Mất: bỏ ý "nhà Nhiệm vụ là sink Shard+Stone lớn".
- Rủi ro: **Worker phải kiểm luật và mở bậc** (§6, bắt buộc trước khi bật N4-N6): độ khó nằm ở luật M, mà Worker chưa kiểm luật; client sửa có thể mua N5 (cược 1.800, trả ~16.200) với `rules: []`. Thêm: farm bậc thấp (§4.2); người lặp cùng bộ luật tăng p dần nên p thật > p sim theo thời gian; A6 + 3 luật có thể vẫn quá tay (SIM).

### Hướng C — "Bậc cao bằng độ dài"
N1-N3 như B. N4 trở lên **Full mode** (4 boss), ít luật M hơn.
- Được: ít luật chồng nên ít cảm giác bất công; dùng Full có sẵn.
- Mất: run dài, cược lớn, bỏ giữa chừng nhiều; `full_exponent` chưa đo; chuyển Full trong sim có thể không chỉ một cờ (4 boss, vòng map, `depth_stage`), cần ước lượng riêng.
- Rủi ro: dồn rủi ro vào chế độ chưa kiểm.
- Dự phòng cho N5 nếu Short không xuống nổi dưới 5%.

**Khuyến nghị: B**, N5 chuyển Full nếu Short không hạ nổi.

## 3. Mục tiêu tỉ lệ thắng và cách đo

Đại diện người giỏi: **expert bot**, random làm sàn. Người thật giỏi hơn bot (bot chưa chơi tốt Embers/Big Hand/Mana Mine, sim-v5), nên cần hệ số `r = p_người_giỏi / p_bot` (§3.3). **r chưa biết, giả thuyết ban đầu r = 1,5, khoảng 1,2-2; và r có thể tăng theo bậc.**

### 3.1 Bảng mục tiêu (cho bot; số người giỏi ước = bot × r)

| Bậc | Bot mục tiêu | Khoảng chấp nhận | Người giỏi ước (r 1,5) | Random |
|---|---|---|---|---|
| N1 | 18% | 15-22 | ~27% | 6-10% |
| N2 | 14% | 11-17 | ~21% | 3-6% |
| N3 | 10% | 8-12 | ~15% | 1-3% |
| N4 | 7% | 5-9 | ~10% | < 2% |
| N5 | 5% | 3-6 | ~7% | < 1% |
| N6 (Full) | 2,5% | 1-4 | ~4% (**r 2 → 5%**: chạm giới hạn Liam) | ~0% |

Giới hạn "người giỏi < 5%" ở N6 chỉ giữ nếu r ≤ 2; vì thế N6 mục tiêu cho bot có thể phải hạ xuống ~2% sau hiệu chuẩn (§3.3). N1 = 18%: chuẩn Nhiệm vụ hạ nhẹ từ mốc A0 16-21.

### 3.2 Việc thêm vào `sim_balance.gd` (lập trình, sau khi Liam duyệt)
1. `--mode=short|full` (ước lượng riêng cho Full).
2. `--mission=N1..N6`: dựng header như `MissionBoard.offers` (rules, m, stake) vào params `mission`.
3. `--rules=M1,M5,...` ép luật lẻ để đo d từng luật.
4. `--asc` đã có. **`--anchor=auto` bắt buộc** cho sim Nhiệm vụ (mặc định `none` không phải game thật: v5 có Anchor, Vỏ, stage 2).
5. Dùng **seed chung và so cặp** giữa các bậc (sim đã có common random numbers), CSV có cột mission/mode/rules, báo cáo ghi **CI 95%** (không phải SE).
6. **Đo run/giờ trước khi hứa tiến độ.** Khối lượng ước ~30-50k run (bước 0 ~7.200, bước 1 ~8.400, bước 2 ~5.400, chưa tính vòng chỉnh), nhiều cái là Full. Sim v5 mới làm được n ~250-290 mỗi ô.

### 3.3 Quy trình đo
- **Bước 0 (nền):** expert bot Short A0..A9, Full A0/A6, ≥ 600 run/điểm. Cho mốc A0 là khoảng, không phải một số.
- **Bước 1:** từng luật M đơn ở A0 và A3 → d thật.
- **Bước 2:** 6 bậc theo bảng §2. N1-N4 ≥ 600 run (SE ~1,6 điểm; **CI 95% ~±3,1** ở p=18%, nên khoảng chấp nhận hẹp như N3 8-12 chỉ kiểm được thô; nâng n lên ~1.500 cho N3-N4 nếu cần). N5-N6 ≥ 1.500. Tiêu chí "N(k) > N(k+1) ít nhất 2 điểm" chỉ kiểm bằng so cặp theo seed chung, không kiểm trên n=600 độc lập.
- **Bước 2b — hiệu chuẩn bot → người, TRƯỚC khi bật:** Liam/tester chơi ~30 run ở A0 và N1 (và vài run N4-N5 nếu có), tính r sơ bộ. Khoá p và m theo p_người ước, không theo p_bot. Câu hỏi 2 hỏi luôn "người giỏi" là top bao nhiêu %.
- **Bước 3 (xác nhận):** log thật 28 ngày; lệch quá ±5 điểm thì chỉnh. Chỉ là xác nhận, không đủ cho ràng buộc cứng < 5%.

### 3.4 Quy tắc chỉnh khi lệch (mỗi vòng đổi MỘT thứ)
1. Bậc quá khó: bỏ/hoán một luật M (~2-4 điểm mỗi luật, SIM đo).
2. Còn lệch: nhích Ascension ±1.
3. Lệch cả thang: đổi `standard` (dmg 1,1 / elite HP 1,1). **File kéo bump `RULES_VERSION`:** `mission_rules.json` và `ascension.json` (nằm trong fingerprint `t_rules_version`). `missions.json` ở `assets/data/economy/` **không** nằm trong fingerprint, nhưng Worker bundle nó và client đọc bản riêng nên đổi là phải deploy cả hai.
4. Không chỉnh m để sửa p. m tính sau từ p đã chốt.
5. Dừng khi mọi bậc trong khoảng chấp nhận và bậc cao nhất cận trên CI < 5%. Thang đơn điệu giảm.

## 4. Kinh tế

### 4.1 Công thức m — chốt theo p_người, không theo p_bot
Điều kiện Liam 13/10 còn hiệu lực: **"heavy không lãi ở N1-N4"** (`nhiem-vu-risk-to-earn.md:22`). Bản trước đặt RTP bot 0,85 chừa đệm chỉ đủ r ≤ 1,18, trong khi §3 giả định r 1,5-2: hai giả định mâu thuẫn. Công thức đúng:
`m = round05( RTP_mục_tiêu_cho_bot / p_bot )`, với `RTP_bot = 1 / r_giả_định` (đệm).
Lãi/run của người giỏi = cược × (RTP_bot × r − 1). Ba phương án:

| Phương án | RTP bot | N1 (300) r1,5 / r2 | N2 (500) | N3 (800) | N4 (1.200) | Hệ quả |
|---|---|---|---|---|---|---|
| P1 (khuyến nghị) | 0,65 | −7 / +90 | −12 / +150 | −20 / +240 | −30 / +360 | chỉ giữ "heavy không lãi" khi r ≤ 1,5; ở r=2 vẫn lãi +90..+360/run |
| P2 (bản cũ) | 0,85 | +82 / +210 | +137 / +350 | +220 / +560 | +330 / +840 | phá điều kiện 13/10; r2 ở N4 hơn cả R (450) mỗi run |
| P3 | 0,50 | −75 / 0 | −125 / 0 | −200 / 0 | −300 / 0 | không ai lãi tới r 2; người yếu mất ~85-90% cược |

(R = 450/run, `economy-v2.md:92`. P2 ở r 1,5 + 30 run/tuần cho N4 = ~+10k Shard/tuần; r 2 ≈ +25k, bằng cả thu nhập tuần heavy ~26k, mà Shard mua được vé Echo Box → Stone/cosmetic.)

**Khuyến nghị P1, r giả định 1,5, chốt r thật ở bước 2b.** Nếu đo r > 1,5 ở bậc nào thì hạ m bậc đó (RTP_bot = 1/r_bậc); nếu Liam chấp nhận người giỏi lãi, thì phải thêm trần (câu hỏi 3). Bảng m nếu sim ra đúng bảng §3.1 (cược giữ 300/500/800/1.200/1.800/2.500):

| Bậc | p bot | RTP bot | m | Trả khi thắng |
|---|---|---|---|---|
| N1 | 18% | 0,65 | 3,60 | 1.080 |
| N2 | 14% | 0,65 | 4,65 | 2.325 |
| N3 | 10% | 0,65 | 6,50 | 5.200 |
| N4 | 7% | 0,65 | 9,30 | 11.160 |
| N5 | 5% | 0,45 | 9,00 | 16.200 |
| N6 | 2,5% | 0,20 | 8,00 (kẹp trần) | 20.000 |

Payout tăng đơn điệu N1→N6; N6 là đỉnh 20.000. **Không ghi vào `missions.json` trước khi sim + bước 2b xong.**

### 4.2 Rủi ro kinh tế và cái chặn thật
- Lãi tuyến tính (cược cố định, một run mở một lúc), không vô hạn, nhưng người giỏi lãi sẽ đổi Shard → vé → Stone. Chặn thật (MON-5 cấm chỉnh theo người): (1) tốc độ (một run mở), (2) cược cố định + trần payout, (3) chọn RTP_bot đủ thấp (P1), (4) **theo dõi theo phân vị, không theo trung bình**: p90 lãi ròng 28 ngày, Shard/ngày của top 1% (có trong telemetry doc cũ). p toàn dân sẽ thấp vì đa số thua nên không bắt được farmer.
- **`m_scale` không chỉnh nóng được.** `missions.json` bundle vào Worker (`missions.js:9`) và client đọc bản riêng: đổi m = đổi json + deploy Worker + build client. Header run chốt m lúc mua nên run đang mở không lệch. Hạ m_scale cũng phạt cả người yếu. Cách thật: sửa theo từng bậc, theo lịch tuần, thông báo trước.
- **N6 là bậc danh hiệu (không kinh tế):** RTP bot 0,20, Stone 60 (trần 150/ngày), danh hiệu "Người Đứng Cuối"; payout 20.000 nhưng ít ai trúng. Nói thẳng trên thẻ. Phương án thay (câu hỏi 4) là bỏ N6 khỏi beta.
- Cổng mở bậc: để mở N5 phải thắng N1-N4 một lần: kỳ vọng bot ~37 run, ~30k Shard cược (RTP 0,65 → lỗ ~35%). Casual kiếm ~6k Shard/tuần nên sẽ khó với tới N5, đó là cổng hợp lý nhưng cần xác nhận casual vẫn có đường lên (SIM economy).

### 4.3 Nguồn / chỗ tiêu
- **Shard CÓ giá trị ngoài game:** Shard mua vé Echo Box (200 Shard/vé, `economy-v2.md` ~dòng 24-32, 111), vé ra Stone hoặc cosmetic. Nên Shard thắng từ cược là cosmetic và Stone Land thật; Nhiệm vụ phải coi là kinh tế thật, không phải "thử cảm giác".
- **Stone:** giữ 4/8/14/22/34/60, trần 150/ngày (ECO-12), tính ở client (`MetaState.gd:492`, sửa save được; mức thiệt nhỏ, ghi nhận).
- ECO-11 tính lại bằng p thật (economy-designer) sau sim.
- **Bất biến:** INV-1..5 không đụng (không chạm part/tier). INV-6: không có SKU tiền thật, Shard→vé không phải tiền thật nên không phá, nhưng ảnh hưởng cân Stone của economy-v2. INV-7: run thường không bị gate.
- Giữ từ doc cũ: bỏ cuộc = mất cược và mất R; khoản Shard khởi đầu không làm cược; một run mở; 5 run làm quen.

## 5. Trải nghiệm người chơi

Cảm giác muốn có: căng, biết trước mình dễ thua, thua đọc được lý do. Tránh: bị lừa, "lỗi khó hiểu", máy đánh bạc.

Thẻ offer, theo thứ tự đọc:
1. Tên bậc + mode + Ascension.
2. **Từng luật thêm bằng chữ**, chip cùng chữ đó trong run.
3. Cược → Trả khi thắng → Lãi ròng.
4. Xác suất và kỳ vọng nhận về, ghi nhãn **"ước tính"** (số từ bot/hiệu chuẩn thấp hơn hoặc lệch người thật; đổi sang số thật khi có log). Dòng cố định N3+ "Đa số người chơi thua bậc này"; N5-N6 "Bậc thử sức, trung bình nhận về dưới 100% cược"; N6 ghi "bậc danh hiệu".
5. Nút mua: "Trả 800 Shard. Thua hoặc bỏ giữa chừng: mất 800, không hoàn."

Disabled phải nói lý do: "Thắng N3 để mở N4", "Đang có một run mở", "Không đủ Shard (cần 800, có 450)".

**Lệch cược client/server khi lỗi mạng** (server giữ cược, Shard thật ở save client; hai nơi trừ): quy tắc đề xuất: **server escrow là gốc**; client chạy `reconcileEscrows` trước khi hiện số dư và trước khi cho mua; nếu không chắc đã trừ chưa, màn nói đúng "đang xác nhận cược, chưa chơi được" thay vì đoán. `infra_error` hoàn cược: phải chắc người chơi không tự kích được (đóng tab lúc đang thua không được tính infra_error). Test hiện có `t_mission_escrow_sync`.

Màn thua cụ thể ("Boss 2 hạ đội lượt 9, đồng hồ +60%. Mất 800 Shard."), hai nút "Về Nhiệm vụ", "Chơi run thường". Bỏ run: xác nhận nói "mất cược và không nhận Shard của run". Tên M6 "Quân dày", M7 "Elite hung" giữ như doc cũ (đề xuất lại ở `mission-rule-names-m6-m7.md`), Liam xem lúc duyệt.

## 6. Phụ thuộc

**Bắt buộc trước khi bật N4-N6 (hoặc bất kỳ bậc nào dựa vào luật M để tạo độ khó), Worker kiểm:**
1. `rules` của mission khớp bảng tier trong `missions.json` (hiện `validateMission` chỉ kiểm `enabled`, `stake`, `ascension`; client có thể gửi `rules: []`).
2. Điều kiện mở bậc **lưu ở D1** (chuỗi thắng), không tin `asc_wins` trong save client.
Câu "Worker: đổi luật mở bậc" ở bản trước sai chỗ: Worker hiện **không có** luật mở bậc; đây là việc thêm mới, không phải đổi. Nếu chưa làm, giữ N4-N6 tắt trên server (403 như nay) và chỉ bật N1-N3.
Khác:
- **Verifier / Server RNG** (hệ thống sau): thắng/thua vẫn là client khai; Shard có giá trị (vé → Stone/cosmetic), nên đây là rủi ro thật (câu hỏi 3). Chưa có thì Nhiệm vụ chưa lên leaderboard thật.
- **Land:** hướng B không cần gì (nhà Weaponsmith `fixed_lv: 1`, `Land.gd:45`, chưa mở file kiểm lại). Nâng nhà sau này cần UI nâng và tính Stone.
- **RULES_VERSION:** xem §3.4 mục 3; gom mọi thay đổi vào một lần bump sau khi sim chốt; Worker và client deploy cùng lúc.
- **`sim_balance.gd`** xong §3.2 trước mọi con số.

## 7. Câu hỏi cho Liam (4)

1. **Nâng nhà Nhiệm vụ (Shard+Stone) trong beta?** Khuyến nghị **hoãn**; mở bậc bằng chuỗi thắng. Đây là đảo quyết định 13/10 "nhà mở bậc" và bỏ sink Stone. Lý do (sửa theo review Land): không phải vì Stone "không ai với tới" (bản trước quên Stone từ Echo Box, `economy-v2.md` §6.3 có tính; Land tier 2 = 40k Stone mất ~1,1-3,2 tuần tuỳ nhóm). Lý do còn lại: Land chưa có UI nâng nhà, và nhà Nhiệm vụ sẽ tranh Stone với tier Land (không thêm hệ thống mới trong beta). **Câu này trùng với doc Land, Liam trả lời một lần cho cả hai.**
2. **Dải 15-25% ở N1 đo trên bot hay trên người giỏi? "Người giỏi" = top bao nhiêu %, hiệu chuẩn thế nào?** §3.1 đặt bot N1 = 18% thì người giỏi (r 1,5) ~27%, đã vượt 25%. Nếu Liam muốn người giỏi nằm trong 15-25% thì bot N1 phải hạ xuống ~13-16%. Khuyến nghị: Liam/tester chơi ~30 run ở A0 và N1 (thêm vài run N4-N5) **trước khi bật**, rút ra r rồi mới khoá p và m; bot chỉ để dựng thang. Nếu "người giỏi" nghĩa là top 5% thì bot N6 phải đặt thấp hơn.
3. **Cược Shard khi Worker chưa kiểm luật/mở bậc và chưa có verifier: chấp nhận cho beta nội bộ hay chặn bằng kiểm server trước?** Shard mua được vé Echo Box → Stone/cosmetic nên client gian lận là thiệt thật. Sự thật hiện tại: Worker chỉ kiểm `enabled`, cược và Ascension; **không kiểm luật ở N2-N3 và không kiểm mở bậc ở bậc nào**. Chỉ N1 sạch (không có luật M nào để khai gian, mở sẵn). Khuyến nghị: **thêm kiểm `rules` ở Worker trước khi bật N2-N3**, bật N1 trước; N4-N6 chờ thêm mở bậc ở D1; leaderboard Nhiệm vụ chờ verifier. Nếu Liam muốn bật cả 6 bậc ngay thì kiểm server là việc đầu tiên.
4. **Giữ "heavy không lãi ở N1-N4" (13/10) hay nới? Và N6 là bậc danh hiệu hay phải trả hơn N5?** Khuyến nghị: **giữ điều kiện** (P1, RTP bot 0,65, r 1,5), và **N6 là bậc danh hiệu** (không kinh tế, payout đỉnh 20.000, Stone 60, danh hiệu). Nếu Liam nới cho người giỏi lãi thì cần trần lãi cho Shard từ Nhiệm vụ (vé/ngày), nếu không thì ECO-11 vỡ.
