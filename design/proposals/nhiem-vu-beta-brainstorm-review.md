Trạng thái: REVIEW độc lập (economy-designer, 26/10/2026) cho `nhiem-vu-beta-brainstorm.md`. Chỉ đọc doc + json + code, không chạy Godot, không sửa file nào khác.

# Review: Nhiệm vụ beta (brainstorm 26/10)

**Verdict: APPROVE WITH CHANGES.** Hướng B (một thang, luật M mang độ khó, mở bậc theo chuỗi thắng) hợp lý và đúng ý Liam. Số liệu trích từ code/doc gần như đều đúng. Nhưng có 3 chỗ phải sửa trước khi đưa Liam duyệt: (1) công thức m với RTP 0,85 mâu thuẫn điều kiện "heavy không lãi ở N1-N4" Liam đã chốt; (2) Hướng B đẩy độ khó sang luật M, mà Worker không kiểm luật; (3) câu hỏi 3 đứng trên một tiền đề sai (Shard có giá trị ngoài game).

## 1. Số liệu: đúng / sai

Đúng (đã đối chiếu): cọc 300/500/800/1.200/1.800/2.500, m cũ 2,15/2,4/3,6/4,4/7,85×0,9/8,0, Stone 4/8/14/22/34/60, trần Stone 150/ngày, `payout_cap` 20.000, nhà cấp 4 = 20.000 Shard + 30.000 Stone (tổng 46.000 Stone), N4-N6 `enabled:false`, `house_upgrade_enabled:false`, Worker 403 `tier_locked` (`missions.js:34`), luật M1..M7 trong `mission_rules.json` (M1 đồng hồ từ lượt 6 +20%/lượt, M2 spike -1 lượt, M4 dmg ×1,15, M5 boss HP ×1,25, M6 quái thường HP ×1,2, M7 elite dmg ×1,25), chuẩn dmg ×1,1 và elite HP ×1,1, sim v5 expert 20,6 / random 12,5 / spam 7,0.

Sai hoặc thiếu:
- §6 "Worker: đổi luật mở bậc theo chuỗi thắng": Worker **không có** luật mở bậc. `validateMission` (`missions.js:28-38`) chỉ kiểm `enabled`, `stake`, `ascension`. Mở bậc chỉ nằm ở client (`mission_board.gd:88`, `asc_wins` trong save).
- §3 / §1.1 dùng 20,6% làm mốc A0. Trong `sim-v5.md` chỉ là một dòng "vòng 3", CI ±4-5, n 246-287 mỗi Anchor; bảng anti-spam cùng file cho expert 16,2 (config đã chọn, trước vòng Anchor 3). Mốc thật nằm khoảng 16-21, không phải một số.
- §4.3 và câu 3 nói "Shard beta chưa có giá trị ngoài game". Sai: `economy-v2.md:111` Shard mua vé Echo Box (200 Shard, +5%/vé, tối đa 30 vé/ngày), vé ra Stone 242,5/lượt hoặc cosmetic. Shard từ cược = cosmetic và Land Stone thật.
- Hướng B bỏ `unlock_full_a9` và đổi N6 từ Full A9 sang Full A6. Quyết định Liam 13/10 (`nhiem-vu-risk-to-earn.md:19`) ghi "N6 chỉ mở cho người đã thắng Full ở A9". Brainstorm đổi mà không nêu là đang đổi quyết định cũ.
- Không nhắc M2 ("cần kiểm engine đọc `spike_period_delta`"); đã có ở `combat_engine.gd:3442` và test `t_mission_rules.gd:54`, nên ổn, chỉ cần ghi.
- Chưa kiểm được: "Weaponsmith `fixed_lv:1`" (không mở file Land).

## 2. Toán

- Phép tính bảng §4.1 đúng (0,18×4,75=0,855; 0,14×6=0,84; 0,10×8,5=0,85; 0,07×12=0,84; 0,05×11=0,55; 0,025×8=0,20). N5 ghi đích 0,60 nhưng m=12 vượt trần (1.800×12=21.600) nên thực ra 0,55; đã giải thích, ok.
- Farm không "vô hạn": cọc cố định theo bậc, một run mở một lúc, nên lãi chạy tuyến tính (cọc × (RTP-1) mỗi run), không cộng dồn. Vấn đề không phải vô hạn mà là **lãi người giỏi so với R = 450/run** (`economy-v2.md:92`) và chuyển được sang vé/Stone.
- Số mẫu (r = p người giỏi / p bot): RTP người giỏi = 0,85 × r. r=1,5 → N1 +84, N2 +140, N3 +224, N4 +336 Shard/run. r=2 ở N4 (bot 7% → người 14%) → RTP 1,7, +840/run, hơn R. 30 run/tuần = +25k Shard, bằng cả thu nhập tuần của heavy (~26k, `economy-v2.md:134`), đi thẳng sang vé → Stone.
- Mâu thuẫn trong chính brainstorm: §3 giả định người giỏi hơn bot rất nhiều (bot N6 2-3% để người ~4-5%, tức r ≈ 1,7-2) nhưng §4.1 chọn RTP 0,85 "chừa khoảng" chỉ đủ cho r ≤ 1,18. Hai giả định không cùng đúng. Thêm: r thường **tăng** theo bậc (sim-v5: bot chưa chơi nổi Embers/Big Hand/Mana Mine, chênh Anchor ~12 điểm), nên N3-N5 là chỗ rò nhiều nhất.
- Điều kiện Liam đã chốt 13/10 (`nhiem-vu-risk-to-earn.md:22`): "heavy không lãi ở N1-N4". Với RTP bot 0,85 và r>1,18 điều kiện này bị phá.
- `m_scale` "live" không đủ chặn, và không live: (a) `missions.json` được bundle vào Worker (`missions.js:9`) và client đọc bản riêng, đổi là phải deploy cả hai; header run chốt m lúc mua nên run đang mở không lệch, nhưng không "chỉnh nóng"; (b) trigger "p thật > 1,5 × mục tiêu" đo trên **toàn dân**, mà phần lớn thua nên p toàn dân thấp hơn nhiều so với p người giỏi. Farmer ẩn trong số trung bình; hạ m_scale thì phạt cả người yếu. MON-5 cấm chỉnh theo người, nên chặn thật chỉ có: tốc độ (một run mở), cọc cố định, và chọn RTP bot đủ thấp.
- INV-1..5 không đụng (không chạm part/tier). INV-6 ổn vì không có SKU, nhưng xem lỗ Shard→vé ở trên: không phải tiền thật nên không phá INV-6, chỉ phá cân Stone của economy-v2. INV-7 ổn (run thường không bị gate).
- N6 không trả hơn N5: N5 19.800, N6 20.000, RTP bot 0,55 vs 0,20, Stone 34 vs 60. Về Shard N6 thua N5 ở mọi mặt, chỉ còn danh hiệu + Stone 60 (mà Stone nhiệm vụ trần 150/ngày, tức 2 lần thắng/ngày). Không vô nghĩa nếu coi là bậc danh hiệu, nhưng nên nói thẳng là bậc không-kinh-tế, hoặc làm N5 trả ít hơn để thang đơn điệu.

## 3. Kế hoạch sim

Khả thi và thứ tự đúng (nền A0..A9 → từng luật → ghép bậc → log thật). Chỗ thiếu:
- Số run: bước 0 ≈ 7.200, bước 1 ≈ 8.400, bước 2 ≈ 5.400, chưa tính vòng chỉnh "mỗi vòng đổi một thứ". Cỡ 30-50k run, nhiều cái là Full (chưa chạy bao giờ). Cần đo run/giờ trước khi hứa tiến độ. `sim-v5` chỉ làm được n ~250-290 mỗi ô.
- "Sai số 1,6 điểm" là sai số chuẩn, không phải CI 95% (CI 95% ở p=18%, n=600 là ±3,1). Khoảng chấp nhận N3 8-12 hẹp hơn CI ±2,4. Tiêu chí "N(k) > N(k+1) ít nhất 2 điểm" không kiểm được ở n=600 giữa N4 (7) và N5 (5). Dùng seed chung giữa các bậc (sim đã có common random numbers) và so cặp, hoặc nâng n.
- `sim_balance.gd` mặc định `_anchor_mode = "none"` (dòng 46, 200). Sim nhiệm vụ phải chạy `--anchor=auto`, nếu không không đo đúng game thật (v5 có Anchor, Vỏ, stage 2). Ghi rõ trong cờ.
- `mode: "short"` hard-code ở dòng 199, Full còn dùng `depth_stage`: chuyển Full có thể không chỉ là một cờ (4 boss, vòng map). Ước lượng riêng.
- Thiếu bước hiệu chuẩn bot → người **trước** khi bật (xem lỗ hổng 4). Bước 3 (28 ngày) quá muộn cho ràng buộc cứng "<5%" của Liam.
- `--ruleset=A|B|both` trong khi bảng §2 chỉ có một bộ luật mỗi bậc (xem lỗ hổng 2).
- Bump `RULES_VERSION` thuộc fingerprint: `missions.json` nằm ở `assets/data/economy/` nên **không** nằm trong fingerprint, nhưng `mission_rules.json` và `ascension.json` thì có. Brainstorm gộp hai loại; chỉ cần nói rõ file nào kéo bump.

## 4. Lỗ hổng

1. Luật tự khai: Hướng B chuyển độ khó từ Ascension (Worker kiểm `ascension === t.ascension`) sang luật M (Worker không kiểm). Client sửa đổi có thể mua N5 (cọc 1.800, trả 19.800) với `rules: []`. Brainstorm nói nhẹ ở §6. Hướng B làm lỗ này đắt hơn vì N3..N5 chỉ chênh nhau vài nấc Ascension.
2. Chọn bậc/bộ theo seed: json còn `rule_sets` A/B xoay theo ngày, d hai bộ khác nhau (N3 1,20 vs 1,25 trong doc cũ), nhưng m chỉ có một. Người chờ ngày bộ dễ hơn thì ăn m của bộ khó. Brainstorm không nói bỏ hay giữ.
3. Mở bậc: chuỗi thắng lưu ở save client, sửa save là mở hết. Tốn kém cho người thật: để mở N5 phải thắng N1..N4 mỗi bậc một lần, kỳ vọng ~37 run và ~30k Shard cọc (bot, RTP 0,85 nên lỗ ~15%). Là cổng hợp lý, chỉ cần cho đo cả người mới có thể đủ Shard (casual ~6k/tuần) không.
4. Bỏ giữa run: logic cũ đủ (mất cọc + mất R, seed không lộ, `missions.js:64-65` không hoàn trừ `refunded`). Không thấy lách. Lưu ý `infra_error` hoàn cọc: phải chắc người chơi không kích được (đóng tab lúc đang thua).
5. Lỗi mạng khi trừ cọc: `missions.js:6-7` Shard không có số dư server, ledger chỉ ghi; số dư thật ở save client. Hai bên trừ cọc ở hai nơi, có cửa sổ lệch (server đã giữ cọc, client chưa trừ hoặc ngược lại). Có `reconcileEscrows` và test `t_mission_escrow_sync`, nhưng brainstorm chỉ lo lời nhắn UI. Cần quy tắc: server escrow là gốc, client reconcile trước khi hiện số dư.
6. Stone trần 150/ngày chạy ở client (`MetaState.gd:492`, "stays client-side"): sửa save được. Nhỏ.
7. Người chơi lặp cùng bộ luật tăng p dần (doc cũ §3.4 đã ghi). Với Hướng B bậc thấp lặp được nhiều, nên p thật > p sim theo thời gian.

## 5. Ba câu hỏi và khuyến nghị

- Câu 1 (nâng nhà, khuyến nghị hoãn): đúng câu và hợp lý, khớp "không thêm hệ thống mới". Nói thêm rằng nó đảo quyết định 13/10 "nhà mở bậc" và bỏ sink Stone.
- Câu 2 (bot hay người thật): đúng câu cần hỏi, nhưng khuyến nghị "bot làm số bật beta" yếu: chưa biết r. Nên đổi thành: Liam/tester chơi ~30 run ở A0 và N1 trước, có r sơ bộ rồi mới khoá p. Và hỏi luôn "người giỏi" = top bao nhiêu %.
- Câu 3 (bật cược khi chưa verifier): tiền đề sai (Shard mua được vé, xem mục 1). Câu đúng hơn: "cược Shard bật khi Worker chưa kiểm luật/mở bậc thì client sửa được; chấp nhận cho beta nội bộ, hay chặn bằng kiểm server trước?"
- Thiếu câu: N6 là bậc danh hiệu (không kinh tế) hay phải có thưởng Shard hơn N5? Và RTP đích: Liam muốn "heavy không lãi ở N1-N4" (13/10) giữ nguyên hay nới?

## 6. Vấn đề theo mức

**CHẶN**
1. Công thức m (RTP 0,85 trên p bot) phá điều kiện "heavy không lãi N1-N4", và mâu thuẫn với giả định r ở §3. Sửa: chốt một r sơ bộ (hoặc đo trước), rồi đặt RTP bot = 1 / r_max_tier trừ đệm, ví dụ r=1,5 → RTP bot ≤ 0,65 ở N1-N4; hoặc ghi rõ Liam chấp nhận người giỏi lãi và đặt trần lãi (số vé/Shard/ngày) cho Shard từ nhiệm vụ.
2. Server không kiểm luật và không kiểm mở bậc, mà Hướng B dồn độ khó vào luật. Sửa: thêm vào §6 việc kiểm server (`rules` khớp bảng tier trong `missions.json`, mở bậc lưu D1) như điều kiện bật cược, không phải "việc lập trình sau".
3. Câu 3 sai tiền đề (Shard → vé → Stone/cosmetic). Sửa lại §4.3, §6 và câu 3.

**NÊN SỬA**
4. N6 ≈ N5 về tiền: nói thẳng "bậc danh hiệu" hoặc hạ N5 (ví dụ m về ~9,5 → 17.100, RTP 0,475) để N6 20.000 là đỉnh. Một trong hai, Liam chọn.
5. Bỏ hoặc tách A/B xoay ngày; nếu giữ, m theo từng bộ và sim đo cả hai.
6. Bổ sung hiệu chuẩn bot→người trước bật (Liam hoặc tester, ≥30 run N1/A0); bước 3 28 ngày chỉ là xác nhận.
7. Sim: dùng `--anchor=auto`, so cặp theo seed chung, đo run/giờ, gọi đúng "SE" vs "CI 95%", ghi mốc A0 là khoảng 16-21 chứ không phải 20,6.
8. `m_scale`: ghi là cần deploy Worker + client, không phải chỉnh nóng; trigger theo p toàn dân sẽ không bắt farmer; thêm chỉ số theo phân vị (p90 lãi ròng 28 ngày, Shard/ngày top 1%, đã có trong telemetry doc cũ).
9. Nêu rõ đang đổi quyết định 13/10 (N6 Full A9, nhà mở bậc). Chọn "N2 A1-A2" thành một số (A1 và A2 chỉ khác `elite_extra`, `ascension.json:75`).
10. Quy tắc lệch cọc client/server (lỗ hổng 5) vào §5/§6.

**GỢI Ý**
11. Mở bậc "thắng N(k) một lần": cân nhắc cần ≥2 thắng hoặc thắng trong 3 ngày để lọc may mắn và chống rò Shard từ một lần thắng bậc cao may mắn (chi phí thấp, chưa phá gì).
12. Ghi tách file nào kéo bump `RULES_VERSION` (mục 3 cuối).
13. Màn offer: nếu hiện "người giỏi thắng X%" thì X lấy từ bot sẽ hiện số thấp hơn người thật; ghi nhãn "ước tính" cho tới khi có log.

## Vòng 2 (26/10): kiểm bản đã sửa

**Verdict: APPROVE** (không còn mục CHẶN; còn 2 chỗ NÊN SỬA nhỏ, có thể sửa lúc Liam duyệt).

3 mục CHẶN đã đóng:
1. Công thức m: tính lại bảng P1/P2/P3 lãi/run theo cược × (RTP × r − 1), r 1,5 và 2, 4 bậc N1-N4: đúng hết (P1 −7/+90, −12/+150, −20/+240, −30/+360; P2 +82/+210 ... +330/+840; P3 −75/0 ... −300/0). Bảng m mới: 3,60 / 4,65 / 6,50 / 9,30 / 9,00 / 8,00 khớp RTP/p (0,648 / 0,651 / 0,65 / 0,651 / 0,45 / 0,20), payout 1.080 / 2.325 / 5.200 / 11.160 / 16.200 / 20.000 đúng và tăng đơn điệu, N6 là đỉnh. Cổng mở N5 (~37 run, ~30k cược, lỗ ~35% ở RTP 0,65) tính lại đúng.
2. Worker kiểm luật + mở bậc ở D1: đã thành điều kiện bắt buộc §6, sửa lại câu "đổi luật mở bậc" thành "thêm mới".
3. Tiền đề Shard: sửa ở §4.3, §6, câu 3. Đã kiểm hai chỗ người viết chưa tự kiểm: `economy-v2.md:111` đúng (vé `round5(200 × 1,05^(k−1))`, tối đa 30/ngày) và `Land.gd:45` đúng (`missions` → Weaponsmith, `"fixed_lv": 1`).

NÊN SỬA còn lại (xử lý đủ, trừ hai cái dưới): bỏ A/B, N6 danh hiệu, sim (`--anchor=auto`, so cặp, CI 95%, run/giờ), hiệu chuẩn bước 2b, `m_scale` không nóng, nêu đảo quyết định 13/10, N2 = A1, lệch cọc client/server: đều đã vào bản sửa.

Lỗi mới / còn sót:
- **(NÊN SỬA) Câu 3 nói "N1-N3 Worker đã kiểm đủ Ascension và cược" là quá tay.** Worker không kiểm luật ở N2 (M6) và N3 (M5+M6) và không kiểm mở bậc ở bậc nào. Chỉ N1 (không luật thêm) là sạch. Rò ở N2-N3 nhỏ (luật thiếu chỉ làm run dễ hơn vài điểm, cược ≤ 800) nên chấp nhận được cho beta nội bộ, nhưng phải viết đúng như vậy, hoặc thêm kiểm `rules` trước cho cả N2-N3 (rẻ: so với `missions.json`).
- **(NÊN SỬA) §3.1 N1: người giỏi ước ~27% (r 1,5) vượt khoảng 15-25% Liam đặt cho bậc thấp.** Nếu "15-25%" áp cho người giỏi chứ không cho bot, N1 bot phải hạ xuống ~14-16%. Cần hỏi Liam trong câu 2 ("người giỏi" và dải 15-25% đo trên ai).
- (GỢI Ý) P1 ở r = 2 vẫn lãi +90..+360/run; bản sửa có ghi, nhưng nên nói ngay trong bảng rằng P1 chỉ giữ điều kiện "heavy không lãi" nếu r ≤ 1,5, và r đo ở bước 2b quyết định có hạ RTP_bot xuống 0,50 (P3) hay không.
