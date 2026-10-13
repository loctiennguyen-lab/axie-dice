Trạng thái: bản cực khó — Liam DUYỆT 13/10

> **QUYẾT ĐỊNH LIAM 13/10 (trả lời G1–G6, `pending-decisions.md` mục H 1–7):**
> - **RTP toàn dân ~0,70–0,75: chấp nhận** (game phải khó). Không hạ N1–N2.
> - **Trần payout 20.000 giữ.** N6 là bậc danh hiệu (m kẹp 8,00).
> - **Bỏ giới hạn "tối đa 2 luật thêm"** (N6 có 5 luật).
> - **M6 Quân dày + M7 Elite hung: duyệt** → sửa `mission_mods` + engine + bump `RULES_VERSION`.
> - **Giữ điều kiện phụ** (Một nhà, Đa sắc).
> - **Bỏ cuộc = mất cược và KHÔNG nhận R** (Shard của run).
> - **Danh hiệu:** A5 = "Người Giữ Ấn", A10 = "Người Đứng Cuối".
>
> **QUYẾT ĐỊNH LIAM còn hiệu lực (gom lại, ưu tiên hơn thân file).**
> - **12/10 (sau review cuối):** leaderboard Nhiệm vụ **tách theo từng Ascension** · **NFT (Axie/part thật) dùng được trong mọi run, kể cả Nhiệm vụ** · duyệt ngưỡng Bayes (R_hi 0,95, ε 0,10, bước ≤ 0,02/ngày) · trần ~20 run mới/ngày của kiến trúc **không áp cho Nhiệm vụ**.
> - Nhiệm vụ = cược (stake) + thưởng tăng theo độ khó. Cược bằng **Gene Shard**; thắng có thêm **Land Stone rất ít**. Thua thì **mất cược, không hoàn, không an ủi** (12/10). Lỗ bao nhiêu cũng được.
> - **Không giới hạn số lần mua mỗi ngày** (12/10). Chỉ một run mở tại một thời điểm.
> - Chạy ở mọi Ascension. Server giữ số dư Shard (escrow), **server tung xúc xắc ở mọi chế độ**. Thẻ offer và màn xác nhận hiện dòng "kỳ vọng nhận lại". Độ khó và thưởng đi cùng nhau.
> - **Nhiệm vụ không bán gì**: không Thử lại, không Bảo hiểm cược, không Gem, không Aid trả tiền, không Boon, không Continue (MON-12/13). Đây là bài test risk-to-earn của Liam. Mở sau 5 run làm quen. **MON-5: không định giá hay chỉnh độ khó theo từng người** (áp cả cho m tự chỉnh §11).
> - **Nhà Nhiệm vụ có cấp riêng**, nâng bằng **Gene Shard + Land Stone**, không tiền thật; nâng nhà **chỉ mở thêm bậc**. Chi phí giữ làm số khởi điểm.
> - **Bậc khó nhất dùng Full mode.** N6 chỉ mở cho người đã thắng một run Full ở A9.
> - **Unlock cày dùng được trong Nhiệm vụ** (từ chơi + Pass miễn phí; Pass trả tiền không cho sức mạnh). Run Nhiệm vụ **vào bảng xếp hạng** và tính là run đã tạo.
> - **Chưa sim vẫn được bật**; chỉnh live bằng m tự chỉnh (§11). Chưa dùng AXS, thử bằng Shard.
> - **N5/N6 là bậc "thử sức"**, kỳ vọng nhận lại < 100% với mọi hồ sơ. **RTP đo trên toàn dân, đích 0,75–0,95**, kèm điều kiện heavy không lãi ở N1–N4. **Payout tối đa 20.000/run: Liam đã chấp nhận** (bản cực khó chạm trần này ở N6, xem câu hỏi G2).
> - **Verifier lỗi (timeout/crash, canary qua, không tái lập) = huỷ Nhiệm vụ, chỉ hoàn cược, không trả R.** Lỗi tái lập được thì gắn cờ tài khoản (C10).
> - **Điều kiện phụ vào v1.0 nếu làm được** (kết quả: 2 loại, §3.8 bản 12/10, nay chạy trong `mission_rules.json`).
> - Kiến trúc (`docs/architecture/server-authoritative-rng.md`): cược trừ lúc tạo run (một batch D1); bỏ run = thua; không run nào bị huỷ vì để không; không giới hạn resume, không reseed khi vào lại; engine từ chối hành động sau khi đã xin seed = Nhiệm vụ thua; khoản khởi đầu không dùng làm cược; không cổng 18+ cho cược Shard; có trần payout theo run, không có trần Shard theo ngày.
> - **Bị bản này thay thế:** bảng d, bảng m và bảng thắng của bản 12/10 chiều (m 1,60/1,95/2,45/3,30/4,20/7,20), "tối đa 2 luật thêm", seed theo trận, "tối đa 5/ngày", "sim bắt buộc trước khi bật", "không lên bảng ranked".

# Nhiệm vụ (risk-to-earn) — bản CỰC KHÓ

Tác giả: game-designer · đêm 12/10/2026 · chỉ sửa doc này, không code. Nền: lane A đã merge (`godot/assets/data/rules/mission_rules.json`, `ContentDB.mission_mods`, `RunState.mission`).
**Mọi số là tính tay, chưa sim.** Tỉ lệ thắng casual/regular/heavy lấy từ **mục tiêu** `ascension-v2.md` §5.1 (cũng chưa sim). "d" (độ khó cộng thêm, đơn vị logit) là tôi ước. Chỗ cần sim ghi "SIM".

Khác bản chiều nay: bản chiều "cực khó" nhưng regular vẫn thắng ~40% ở N1. Bản này nặng hơn một bậc: **N1 regular ~25%, N3 regular ~13%, N6 heavy ~5%**. Hầu hết người chơi thua ở mọi bậc từ N3 trở lên.

---

## 0. Đọc nhanh

1. Một Nhiệm vụ = một run, luật khó hơn ranked. Trả cược lúc tạo run. Thắng nhận `cược × m` + ít Stone. Thua/bỏ mất cược. Thua do đội diệt vẫn trả Shard R như run thường; **bỏ cuộc thì mất cược và không có R**.
2. **6 bậc N1–N6**, cược 300 / 500 / 800 / 1.200 / 1.800 / 2.500. Số luật thêm tăng 2 → 5. **m: 2,15 / 2,40 / 3,60 / 4,40 / 7,85 (×0,90) / 8,00**.
3. Tỉ lệ thắng mục tiêu (§4.1): heavy 46 / 42 / 28 / 23 / 12 / 5%. Regular 26 / 22 / 13 / 10 / 5 / 1,4%. Casual 14 / 13 / 7 / 5 / 2 / 0,4%.
4. Kỳ vọng nhận lại: casual ~0,30, regular ~0,50, heavy N1–N4 ~1,00. **RTP toàn dân ~0,70–0,75, dưới đích 0,75: Liam chấp nhận (G1, 13/10).**
5. **N6 bị trần payout 20.000 kẹp m ở 8,00** nên heavy chỉ nhận lại 0,41. N6 là bậc "danh dự" (G2: Liam giữ trần, 13/10).
6. Hai luật mới M6, M7 và 2 khoá mới của `mission_mods` (§3.2, §7). Còn lại dùng được data/code có sẵn.
7. Nhà Nhiệm vụ giữ nguyên (cấp 1 miễn phí, cấp 2/3/4 = 3.000 / 8.000 / 20.000 Shard + 4.000 / 12.000 / 30.000 Stone).
8. Verify: sim 3 hồ sơ × 6 bậc × 2 bộ luật, sai số cho phép ±3 điểm (§4.5).

## 1. Overview

Nhiệm vụ là chế độ cược Shard lấy kỹ năng làm ngưỡng. Người chơi chọn một offer trên bảng ngày, trả cược, chơi một run với luật khó hơn hẳn run thường (3 đến 5 luật thêm ở bậc cao). Server giữ tiền, tung xúc xắc, verify log. Thắng được trả theo bậc; thua mất sạch, không có đường lui và không có gì để mua cho đỡ đau. Không có SKU tiền thật. Mục đích duy nhất: cho Liam đo xem người chơi có chấp nhận risk-to-earn khi game thật sự không nương tay. Run đủ điều kiện lên bảng xếp hạng (tách theo Ascension) và tính là run đã tạo.

Vòng lặp: meso (một run), chồng lên run thường. Thưởng ngày (60 Shard + 500 Stone) tách riêng.

## 2. Player Fantasy

**Aesthetic chính (MDA):** Challenge. Phụ: Expression (tự chọn bậc và mức rủi ro). Câu người chơi nói: "Tôi cược vào chính mình, game không nương tay, và tôi biết rõ mình sẽ thua nhiều." Cảm giác muốn có: căng, có thật để mất, thua thì biết vì sao, thắng thì đáng kể lại. **SDT:** Autonomy (tự chọn bậc, số lần), Competence (luật hiện sẵn, thua đọc được lý do).

Không phải: máy đánh bạc (không "gấp đôi hoặc mất hết", không hệ số liên thắng, không giảm giá mua lại, không "suýt thắng"); chỗ bán giải pháp; bẫy giấu (luật, xác suất, kỳ vọng, m hiện tại đều hiện trước khi mua).

Cái giá của bản cực khó: người chơi thường sẽ thua phần lớn số lần. Fantasy chỉ đứng được nếu thua đọc được. Nên màn thua phải nói đúng nguyên nhân (đồng hồ boss, spike, thiếu build), và thẻ offer nói thẳng "đa số người thua bậc này".

## 3. Detailed Rules

### 3.1 Mua = tạo run
Không đổi so với bản 12/10 chiều (đã khớp kiến trúc). Tóm lại: một batch D1 kiểm số dư *có thể cược* (số dư trừ khoản khởi đầu) ≥ cược, chưa có run mở, bậc đã mở; rồi trừ cược, ghi sổ, tạo run. Header run chốt cố định: `mission_id`, bậc, mode, Ascension, mã luật, điều kiện phụ, **cược, m gốc, `m_scale`, m hiệu dụng**. Chỉ một run mở/tài khoản. Không có kiểm số lần mua/ngày. Run Nhiệm vụ tính là run đã tạo kể cả thua (trừ run huỷ vì verifier lỗi hoặc run mồ côi).

### 3.2 Độ khó: Chuẩn + luật thêm
Chỉ chỉnh **ngân sách chiến đấu** bằng núm có sẵn. Không trait khắc chế, không giấu thông tin, không đụng luật HP (đội hồi đầy mỗi trận). Không luật nào nhắc tên quái.

**Chuẩn Nhiệm vụ** (mọi bậc, đã có trong json): địch dmg ×1,10, HP elite ×1,10. Không Aid/Continue/Boon. d = 0,30.

| Mã | Luật | Trạng thái code | d |
|---|---|---|---|
| M1 Đồng hồ gắt | Boss Clock từ lượt 6, +20%/lượt, tối đa +100% (ghi đè Ascension) | đã có | 0,35 |
| M2 Spike dồn | Chu kỳ đòn lớn elite/boss ngắn đi 1 lượt | đã có (key có; **cần kiểm engine đọc `spike_period_delta`**) | 0,30 |
| M3 Săn đuổi | +2 node elite, chỉ dùng ở A < 9 | đã có | 0,30 |
| M4 Đòn nặng | Địch dmg ×1,15 | đã có | 0,30 |
| M5 Boss dày | HP boss ×1,25 | đã có | 0,35 |
| **M6 Quân dày** (mới) | HP quái thường (không elite, không boss) ×1,20 | **mới**: key `enemy_hp` | 0,35 |
| **M7 Elite hung** (mới) | Dmg elite ×1,25 | **mới**: key `elite_dmg` | 0,35 |

Số d là ước, cộng theo logit. Chồng nhiều nhân tử dmg/HP thì d thật **khác cộng**, nên bắt buộc SIM (§4.5), nhất là N5/N6.

**Sáu bậc** (Ascension giữ như cũ để khóa mở bậc không đổi):

| Bậc | Mode | A | Số luật thêm | Bộ A / bộ B (xoay theo ngày) | d tổng |
|---|---|---|---|---|---|
| N1 | Short | A3 | 2 | M5+M6 / M1+M7 | 1,00 (0,30 + 0,70) |
| N2 | Short | A4 | 2 | M5+M6 / M1+M7 | 1,00 |
| N3 | Short | A6 | 3 | M2+M3+M4 / M1+M2+M4 | 1,20 / 1,25 |
| N4 | Short | A7 | 3 | M1+M5+M6 / M5+M6+M7 | 1,35 |
| N5 | Short | A9 | 4 | M1+M5+M6+M7 / M2+M4+M5+M6 | 1,70 / 1,60 |
| N6 | **Full** | A9 | 5 | M1+M4+M5+M6+M7 (một bộ duy nhất) | 2,00 |

Ghi chú: N1 và N2 cùng bộ luật, khác Ascension (A3 vs A4) và cược. M3 không dùng ở A9 (A9 đã có sẵn). d ở bảng dùng N1 = 0,95 khi tính (M5+M6 = 0,70 nhưng d tổng 1,00 chỉ là danh nghĩa; **số tính ở §4 là d = 0,95 cho N1 và 1,00 cho N2**; sim sẽ chỉnh lại).
**(sửa review 12/10)** Đoạn trên tự mâu thuẫn: 0,30 (chuẩn) + 0,35 (M5) + 0,35 (M6) = 1,00 theo đúng bảng d, nên d = 0,95 không có nguồn nào. Với d = 1,00, heavy N1 thắng 45,0%, RTP heavy = 0,968 (không phải 0,995), casual 13,6%, regular 24,6%. §4.1/§4.2 vẫn để d = 0,95 như tác giả viết, chờ Liam chọn (xem review cuối file): hoặc đổi cả bảng sang d = 1,00 (an toàn hơn vì heavy < 1), hoặc giữ 0,95 và sửa d của M5/M6 cho khớp.
**(Lane I, 13/10)** Chốt d = 1,00 cho N1 theo bảng (0,95 không có nguồn). Liam đã chấp nhận RTP thấp (H1), nên không chỉnh m để bù; sim sẽ đo lại.

Giờ **quy tắc "tối đa 2 luật thêm" bị bỏ** (G3: Liam đồng ý 13/10; Slay the Spire dừng ở 3 modifier vì "gần như không thể"). Đây là cố ý: N3–N6 là thử sức. Rủi ro: thua mà người chơi thấy "bất công". Giảm bằng chip luật trong run và thẻ offer liệt kê từng luật, và bằng việc N6 khoá sau điều kiện thắng Full A9.

**Mở khóa bậc:** phải đã thắng một run ở Ascension của bậc (N1 A3, N2 A4, N3 A6, N4 A7, N5 A9); N6 cần đã thắng một run **Full** ở A9. Ngoài ra bậc phải được nhà mở. Cần cả hai.

### 3.3 Nhà Nhiệm vụ (Shard + Stone)
Giữ nguyên bản chiều. Chỉ mở bậc, không đổi số lần mua.

| Cấp | Chi phí | Bậc trên bảng |
|---|---|---|
| 1 | miễn phí (sau 5 run làm quen) | N1–N3 |
| 2 | 3.000 Shard + 4.000 Stone | + N4 |
| 3 | 8.000 Shard + 12.000 Stone | + N5 |
| 4 | 20.000 Shard + 30.000 Stone | + N6 (và đã thắng Full A9) |

Tổng 31.000 Shard + 46.000 Stone (~2,5% Stone tới LunaLanding, ~1,2 tuần Shard của heavy, ~4,8 tuần của casual). Chú ý: bản cực khó làm Shard khó kiếm từ Nhiệm vụ, nên nhà cấp 3–4 chủ yếu là cổng thời gian. Giữ làm số khởi điểm, SIM sau cùng ECO-11.

### 3.4 Bảng ngày
Seed = `H(ngày UTC, "nv", rules_version)`; bảng giống nhau mọi người cùng cấp nhà. Mỗi bậc mở có **một offer**, seed chọn bộ A/B (N6 chỉ một bộ). Mua lặp lại trong ngày được, mỗi lần seed xúc xắc mới do server cấp. Không reroll bảng, không đếm ngược. Một run mở là giới hạn tốc độ duy nhất. Chơi lặp cùng bộ luật làm tỉ lệ thắng thật cao hơn d ước tính (luyện tay); §11 bắt qua dữ liệu.

### 3.5 Thắng, thua, trả tiền
- **Thắng** = hạ boss cuối (3 boss Short, 4 boss Full) theo replay đã verify, và thoả điều kiện phụ nếu có.
- **Thua** = đội diệt; hoặc bấm "Bỏ run" (xác nhận ghi "mất cược"); hoặc engine từ chối hành động sau khi xin seed; hoặc không thoả điều kiện phụ khi hạ boss cuối.
- Trả khi thắng: `payout = min(20.000, round5(cược × m_gốc × m_scale))` + Stone của bậc (cắt bởi `mission_stone_day_cap` 150), một transaction với việc đóng Nhiệm vụ.
- Không Stone, không an ủi khi thua. Thua do đội diệt: Shard R trả như run thường. **Bỏ cuộc: mất cược và không nhận R** (Liam 13/10; chặn kiểu mua N1 rồi bỏ ngay vẫn lãi nhờ R).
- Màn thua: chỉ hai nút ngang hàng "Về nhà Nhiệm vụ", "Chơi run thường". Không nút mua lại, không giảm giá.

### 3.6 Bảng cược / thưởng (R = 450)

| Bậc | Cược | Cược/R | m gốc | `m_scale` | m hiệu dụng | Trả khi thắng | Lãi khi thắng | Stone |
|---|---|---|---|---|---|---|---|---|
| N1 | 300 | 0,67 | 2,15 | 1,00 | 2,15 | 645 | +345 | 4 |
| N2 | 500 | 1,11 | 2,40 | 1,00 | 2,40 | 1.200 | +700 | 8 |
| N3 | 800 | 1,78 | 3,60 | 1,00 | 3,60 | 2.880 | +2.080 | 14 |
| N4 | 1.200 | 2,67 | 4,40 | 1,00 | 4,40 | 5.280 | +4.080 | 22 |
| N5 | 1.800 | 4,00 | 7,85 | 0,90 | 7,07 | 12.715 | +10.915 | 34 |
| N6 | 2.500 | 5,56 | 8,00 (kẹp trần) | 1,00 | 8,00 | 20.000 | +17.500 | 60 |

N6: m "đúng" theo công thức cũ (0,95/p_heavy) là ~18,7, payout ~42.000 vượt trần 20.000 mà Liam giữ (G2, 13/10), nên m bị kẹp ở 8,00. Stone tuần kỳ vọng vẫn dưới 0,3% Stone tuần (thắng quá hiếm).

### 3.7 UX tối thiểu (cần mockup mới trước khi làm UI)
- **Thẻ offer:** tên bậc, mode, Ascension, **từng luật thêm bằng chữ**, cược, trả khi thắng, Stone, m hiệu dụng kèm m gốc, hai dòng xác suất (toàn dân gần đây từ telemetry; ước tính cho bạn dạng khoảng làm tròn 5 khi đủ ≥ 10 run, chưa đủ ghi "chưa đủ dữ liệu"). **"Kỳ vọng nhận lại" luôn hiện trên thẻ.** Thêm dòng cố định ở N3+: "Đa số người chơi thua bậc này."
- **N5/N6:** "Bậc thử sức: trung bình mọi người nhận lại dưới 100% số cược."
- **Xác nhận mua:** "Bạn trả 800 Shard. Thắng: nhận 2.880 (+2.080) và 14 Stone. Thua hoặc bỏ giữa chừng: mất 800, không hoàn." Nút "Mua, mất cược nếu thất bại". Cảnh báo thông tin (không chặn) khi tổng cược trong ngày > 50% thu nhập tuần ước tính.
- **Trong run:** chip góc màn hình liệt kê bậc và các luật thêm; đồng hồ boss hiện từ lượt 1.
- **Màn thua:** trung tính, cụ thể ("Boss 2 hạ đội ở lượt 9, đồng hồ +60%. Mất 800 Shard.").

### 3.8 Điều kiện phụ
Giữ như bản chiều: 2 loại vào v1.0 (`one_house`, `multicolor` trong json), 16 loại để sau/khó, 1 gộp vào bậc. Trong bản cực khó có hai thay đổi: (1) điều kiện **thay** một luật thêm, d lệch ≤ 0,05 (N1 Đa sắc **thêm vào**, d 0,95 → ~1,11, heavy N1 còn ~42%, RTP ~0,91, an toàn vì dưới 1); (2) **N5/N6 không có điều kiện phụ**. Chỉ dùng điều kiện xong khi q_ref ≥ 0,70 (SIM). **G6: Liam giữ điều kiện phụ (13/10).**

---

## 4. Formulas

**Biến:** `p_asc,j(A)` = tỉ lệ thắng mục tiêu hồ sơ j ở Ascension A (`ascension-v2.md` §5.1: A3 30/47/69, A4 28/44/66, A6 20/34/56, A7 18/31/53, A9 10/21/43 cho casual/regular/heavy); `d` = tổng độ khó; `σ(x)=1/(1+e^-x)`; `s` = `m_scale`.

```
Short:  p_j = σ( logit(p_asc,j) − d )
Full:   p_short = p_asc,j ^ e        (e = full_exponent = 1,5, chưa verify)
        p_j = σ( logit(p_short) − d )
payout  = min(payout_cap, round5(cược × m_gốc × s))
RTP_j   = p_j × payout / cược
Lãi ròng kỳ vọng/lần mua = cược × (RTP_j − 1)
Bỏ cuộc: payout = 0 và R = 0 (mất cược, không nhận Shard của run). Thua do đội diệt: payout = 0, R như run thường.
```

**Dựng m:** N1–N4 `m = round05(1/p_heavy)` để heavy hòa vốn. N5: `0,95/p_heavy` rồi `m_scale` 0,90. N6: `0,95/p_heavy` bị kẹp bởi payout_cap/cược = 8,00.

Ví dụ N3 regular (bộ M2+M3+M4, d 1,20): A6 regular 34% → logit −0,663; trừ 1,20 → −1,863 → σ = 13,5%. m 3,60 → RTP 0,485, lãi ròng = 800 × (0,485−1) = **−412**.

### 4.1 Tỉ lệ thắng mục tiêu theo hồ sơ (cái SIM phải kiểm)

| Bậc | d dùng | Casual | Regular | Heavy |
|---|---|---|---|---|
| N1 (A3) | 0,95 | 14,2% | 25,5% | 46,3% |
| N2 (A4) | 1,00 | 12,5% | 22,4% | 41,7% |
| N3 (A6) | 1,20 | 7,0% | 13,5% | 27,7% |
| N4 (A7) | 1,35 | 5,4% | 10,4% | 22,6% |
| N5 (A9) | 1,70 | 2,0% | 4,6% | 12,1% |
| N6 (Full A9) | 2,00 | 0,4% | 1,4% | 5,1% |

So với ranked thường: N1 thấp hơn A3 thường 16 điểm (casual), 22 (regular), 23 (heavy). N6 là ngưỡng "gần như bất khả thi" của Slay the Spire cho casual (0,4%): chấp nhận vì khoá sau nhà 4 và thắng Full A9, nên casual gần như không tới đây.

### 4.2 RTP và lãi ròng kỳ vọng

| Bậc | m hiệu dụng | RTP casual | RTP regular | RTP heavy | Net casual | Net regular | Net heavy |
|---|---|---|---|---|---|---|---|
| N1 | 2,15 | 0,306 | 0,549 | 0,995 | −208 | −135 | −2 |
| N2 | 2,40 | 0,300 | 0,538 | 1,000 | −350 | −231 | 0 |
| N3 | 3,60 | 0,252 | 0,485 | 0,997 | −598 | −412 | −2 |
| N4 | 4,40 | 0,237 | 0,458 | 0,995 | −916 | −650 | −6 |
| N5 | 7,07 | 0,140 | 0,327 | 0,854 | −1.548 | −1.211 | −263 |
| N6 | 8,00 | 0,035 | 0,113 | 0,406 | −2.413 | −2.218 | −1.485 |

Heavy ở N1–N4 nằm 0,995–1,000: đúng điều kiện "heavy không lãi" nếu heavy đúng mục tiêu.

### 4.3 EV theo hồ sơ và toàn dân
Hành vi giả định (đoán, cần đo): casual mua 2 lần/tuần, regular 5, heavy 14; phân bố bậc như bản chiều.

| | Phân bố bậc | Cược TB | RTP gia quyền | Net/tuần | % thu nhập tuần |
|---|---|---|---|---|---|
| Casual | N1 60 / N2 30 / N3 10 | 410 | **0,293** | −578 | −9,0% (6.423) |
| Regular | N1 25 / N2 35 / N3 25 / N4 15 | 630 | **0,500** | −1.575 | −20,9% (7.540) |
| Heavy hợp lý | N2 20 / N3 35 / N4 45 | 920 | **0,996** | −52 | −0,2% |
| Heavy mua cả N5/N6 | N2 15 / N3 30 / N4 35 / N5 12 / N6 8 | 1.151 | **0,867** | −2.140 | −8,0% (26.653) |

**RTP toàn dân** (dân 45/40/15):
- Heavy hợp lý: **~0,75** (sát đáy đích, thật ra 0,748).
- Heavy bảng cũ có N5/N6: **~0,70**, **dưới đích 0,75**.

Casual lỗ ~70% mỗi đồng cược, regular ~50%. Đây là cái giá của "heavy hòa vốn" khi heavy chỉ hơn regular 20 điểm: kéo độ khó lên thì casual/regular rơi nhanh hơn heavy. **G1: Liam chấp nhận RTP thấp (13/10), không hạ d N1–N2.** (Review 12/10 cũng chỉ ra hạ d không cứu được: heavy chiếm ~54% khối lượng cược và nằm sát 1,00, nên RTP toàn dân bị chặn quanh 0,75.)

Ngày xấu (mua N1+N2+N3 một lần, cược 1.600): casual thua cả ba ~76%, regular ~54%.

### 4.4 Rủi ro faucet không trần mua
Người giỏi hơn heavy 0,5 logit chơi N4 liên tục: p = 32,5% × m 4,40 = RTP 1,43, **+517 Shard/lần mua**, 5 run/ngày ≈ +2.585, 10 run ≈ +5.170 (cao hơn bản chiều ~13%). Cái chặn: thời gian (một run mở), trần payout 20.000, ECO-2 (chặn đổi Shard thành Stone), §11 giám sát p99. Phải tính lại ECO-11 với kịch bản này (economy-designer). N6 ở m 8,00 không farm được (heavy +0,5 logit vẫn RTP ~0,65). **(sửa review 12/10)** Cùng điều kiện (+0,5 logit so với heavy) thì **N5 lại farm được**: p ≈ 18,5% × 7,07 = RTP ≈ 1,31, +560 Shard/lần mua. Câu "không farm được" chỉ đúng với N6.

### 4.5 Kế hoạch sim và cách verify
**Mục tiêu:** xác nhận mỗi bậc cho tỉ lệ thắng trong sai số, **trước khi tin bảng §4.1**, dù không chặn bật (Liam 12/10).
1. **Bot:** dùng sim F (bot A trên 11 archetype, `ascension-v2.md` §5.2) và ánh xạ ba hồ sơ (casual/regular/heavy). Ánh xạ hồ sơ do lần sim đầu quyết (chưa chốt).
2. **Chạy:** headless Godot qua `with_lock.sh`, mỗi (bậc × hồ sơ × bộ luật A/B) **2.000 run** (N5: 4.000; N6: 6.000 vì p ~1%). Server tung xúc xắc thế bằng seed cố định của sim.
3. **Kiểm cộng d:** thêm 1.000 run cho mỗi luật đơn lẻ (M1–M7) ở A3/A6/A9 để đo d thật; so với cộng logit của bảng. Dự kiến lệch ở tổ hợp 4–5 luật (nhân tử dmg/HP nhân nhau).
4. **Đạt:** |p_sim − bảng §4.1| ≤ 3 điểm (N1–N4), ≤ 2 điểm (N5), ≤ 1,5 điểm (N6) cho heavy và regular. Casual dưới 3% chỉ kiểm hướng (khoảng tin cậy rộng).
5. **Lệch thì:** chỉnh `d` (luật), **không chỉnh m** (§11 lo m). Rồi dựng lại m = 1/p_heavy.
6. **Kiểm RTP:** nhân p_sim với m, so §4.2 trong ±0,03. RTP heavy N1–N4 ≤ 1,03.
7. **Kiểm sau bật:** log thật 28 ngày so với bảng; vượt ±5 điểm thì chỉnh d.
8. **Kiểm full_exponent:** 6.000 run Full A9 không luật thêm để đo e thật (đang giả định 1,5).

Cần: M6, M7 và hai khoá mới hoạt động trước khi sim (§7).

---

## 5. Research ngắn
Giữ từ bản chiều: Hearthstone Arena (cố ý để người trung bình lỗ, ~7 thắng hòa vốn), Marvel Snap Conquest (thua một ván mất vé, có Medal an ủi, của ta không an ủi), Hades Heat (mỗi luật có điểm khó, thưởng gắn điểm đó), Slay the Spire Daily (3 modifier là mức "gần như không thể", ta vượt hẳn ở N5/N6 và biết rủi ro). Chưa verify số hiện tại của các game này; không dẫn thêm.

## 6. Edge Cases

| Tình huống | Kết quả |
|---|---|
| Mất mạng, đóng tab, crash | Run không huỷ, không hạn giờ, không đếm lần vào lại, không đổi seed. Run mở chặn run mới tới khi xong/bỏ |
| Vào lại từ thiết bị khác | Cho phép; máy cũ vô hiệu bằng `session_epoch` |
| Bỏ run (nút/endpoint) | Thua, **mất cược và không nhận R** (Liam 13/10). Rớt mạng rồi nối lại không tính bỏ |
| Client sửa hành động sau khi xin seed | Engine từ chối, Nhiệm vụ thua |
| Verifier timeout/crash, canary qua, không tái lập | Huỷ, **hoàn 100% cược**, không R, không Stone, không tính run đã tạo |
| Log làm verifier sập tái lập được | Huỷ + hoàn, **gắn cờ C10** |
| Verify fail do log bị sửa | Thua, mất cược, gắn cờ |
| Đổi `rules_version` khi run đang mở | Chạy tiếp theo bản cũ nếu còn trong `SUPPORTED_RULES`, không mất cược; bản cũ bỏ hẳn thì huỷ + hoàn. **Thêm M6/M7 và 2 khoá mới = bump `RULES_VERSION`** |
| Chỉnh `m_scale`/bảng/cron §11 khi run mở | Không ảnh hưởng run đó |
| Số dư thiếu, hoặc chỉ đủ nhờ khoản khởi đầu | Từ chối mua. Không vay, không cược một phần |
| Hai thiết bị mua cùng lúc | Batch D1 có điều kiện: chỉ một bên thành công |
| Run mồ côi (đã trừ cược, chưa có RunDO) | Cron hoàn cược, không tính run đã tạo |
| `AID_USE`/`CONTINUE`/Boon trong log Nhiệm vụ | Server từ chối; lọt vào replay thì verify fail + cờ |
| Payout vượt trần | Cắt ở 20.000, ghi cờ chỉ khi giá trị tính ra > 20.000. **(sửa review 12/10)** N6 m = 8,00 × 2.500 = đúng 20.000 nên bằng trần, không vượt: không được ghi cờ mỗi lần thắng N6 |
| Nhiều luật chồng: dmg/HP nhân nhau tràn số | Mọi nhân tử nhân trong float, không cộng; sàn/trần số nguyên của engine giữ. Test với bộ N6 (5 luật) ở A9 |
| M3 ở A ≥ 9 | Generator từ chối (đã có `max_ascension: 8`) |
| M1 khi Ascension đã có clock | Ghi đè, không cộng chồng (đã có) |
| Cược đổi sang AXS | Chưa làm; cần pháp lý duyệt lại, kể cả 18+ |

**Degenerate strategies:**
- *Farm bậc rẻ bằng người giỏi hơn heavy:* m định giá theo heavy, `m_scale` tự hạ chỉ bắt xu hướng toàn dân, trần payout, giám sát p99 (§4.4).
- *Mua rồi bỏ để xem trước boss:* mất cược và không có R; seed không lộ trước khi tạo run. (Bỏ ngay sau khi mua cũng không lãi nhờ R.)
- *Đuổi theo (mua liên tục sau thua):* không có trần mua, bản cực khó thua nhiều hơn nên nguy hiểm hơn. Chỉ có cảnh báo thông tin + chỉ số đuổi theo (§8). Đỏ thì rút lại.
- *Né bậc cao, chỉ farm N1–N2:* RTP regular ~0,54, vẫn lỗ; không có lợi ngoài người giỏi hơn heavy.
- *Bộ luật lặp trong ngày để luyện:* hiệu ứng thật, §11 bắt, không chặn.

## 7. Dependencies

| Hệ thống | Hướng | Hợp đồng / việc engine |
|---|---|---|
| `godot/assets/data/rules/mission_rules.json` + `ContentDB.mission_mods` | Cần sửa | Thêm M6 `{"enemy_hp": 1.20}`, M7 `{"elite_dmg": 1.25}`; `mission_mods` thêm hai khoá `enemy_hp`, `elite_dmg` (nhân) vào `out` (dòng ~739) |
| `combat_engine.gd` | Cần sửa | Áp `enemy_hp` lên quái thường và `elite_dmg` lên elite khi sinh trận (cạnh chỗ đang đọc `elite_hp`/`boss_hp`/`enemy_dmg`). **Kiểm engine thật sự đọc `spike_period_delta` (M2)**; nếu chưa thì M2 chết, thay bằng M4 và tính lại d |
| `RULES_VERSION` / `t_rules_version` | Cần sửa | Bump + cập nhật fingerprint; `t_mission_rules` thêm ca M6/M7/N6 5 luật |
| `RunState.mission` / `mission_rules()` | Không đổi | Header đã có; thêm mã M6/M7 vào dữ liệu offer |
| `mission_board.gd` (bảng ngày) | Cần sửa | Bảng 6 bậc mới (số luật 2–5, bộ A/B), N6 một bộ |
| Server (`worker`) | Cần sửa | m gốc/`m_scale` mới, payout cap 20.000 (đã có), `m_scale` cron §11. **Chưa verify** bảng `runs` chứa đủ field header |
| `ascension-v2.md` §5.1 | Nhiệm vụ cần | Nguồn p duy nhất, không tạo bảng thứ hai |
| `economy-v2.md` | Hai chiều | R = 450, Stone ≤ 150/ngày (giờ là giới hạn thật), ECO-2, ECO-11. Cần chạy lại với kịch bản §4.4 |
| `monetization-v1.md` | Cần | MON-5, 12, 13; Nhiệm vụ không có SKU |
| Leaderboard | Cần | Tách theo Ascension (Liam 12/10); hiện nhãn Nhiệm vụ + bậc. Chưa verify cách chấm điểm với luật khó |
| Unlock cày / Pass | Cần | Chỉ nguồn chơi + Pass miễn phí. Chưa verify đánh dấu nguồn |
| `build-spec.md` INV-1..7 | Cần đối chiếu | Chưa đọc lại khi viết bản này |
| Danh hiệu cosmetic A5/A10 | Độc lập | §10 |

## 8. Tuning Knobs và telemetry
Mọi số nằm trong `assets/data/` hoặc cấu hình server.

| Núm | Mặc định | Khoảng | Loại | Lý do |
|---|---|---|---|---|
| `tier_stake[6]` | 300/500/800/1.200/1.800/2.500 | ±30% | Curve | 0,67R tới 5,6R |
| `tier_m_base[6]` | 2,15/2,40/3,60/4,40/7,85/8,00 | N1–N4 `1/p_heavy` | Curve | Heavy ≈ 1,00 |
| `m_scale_init[6]` | 1/1/1/1/0,90/1,00 | §11 chỉ hạ, ≤ 1,00 | Curve | N6 đã bị trần kẹp |
| `d_base`, `d_M1..M7` | 0,30 / 0,35, 0,30, 0,30, 0,30, 0,35, 0,35, 0,35 | ±0,15 | Curve | Ước tính, SIM |
| `tier_rules[6][A/B]` | §3.2 | | Curve | Có thể đổi bộ luật không đổi code |
| `M6.enemy_hp`, `M7.elite_dmg` | 1,20 / 1,25 | 1,10–1,35 | Curve | Mới |
| `full_exponent` | 1,5 | 1,33–1,67 | Curve | SIM |
| `house_cost_shard/stone[3]` | 3.000/8.000/20.000; 4.000/12.000/30.000 | ±50% | Gate | Giữ |
| `tier_unlock_ascension` | A3/A4/A6/A7/A9; N6 = thắng Full A9 | | Gate | |
| `mission_payout_cap` | 20.000 | ≥ 20.000 | Gate | Liam giữ (G2, 13/10); N6 bị kẹp theo trần |
| `mission_stone_day_cap` | 150 | 100–200 | Gate | |
| `tier_stone[6]` | 4/8/14/22/34/60 | ×0,5–×2,5 | Curve | |
| `phat_min_runs` | 10 | 5–20 | Feel | |

**Telemetry** (soft launch ≥ 4 tuần, quyết khi mỗi nhánh ≥ 2.000 lượt xem bảng): tiếp nhận (% DAU mở bảng, % mua ≥ 1/tuần, số lần mua/người/ngày p50/p90/p99); khẩu vị rủi ro (phân phối bậc, chỉ số đuổi theo, mua lại trong 2 phút sau thua); hậu quả (retention D1/D7/D30, **tỉ lệ người mua đúng 1 lần rồi bỏ**, thời gian quay lại sau 3 thua liên tiếp); sức khỏe (RTP thật theo bậc/hồ sơ, p99 lãi ròng 28 ngày, Shard/ngày top 1%, sai lệch p dự đoán so với thực).

| Chỉ số | Xanh | Vàng | Đỏ |
|---|---|---|---|
| WAU mua ≥ 1 lần (tuần 2–4) | ≥ 12% | 5–12% | < 5% |
| Người mua đúng 1 lần rồi bỏ | ≤ 60% | 60–80% | > 80% |
| Retention D30 người mua − không mua | ≥ −3 điểm | −3 tới −6 | < −6 |
| Chỉ số đuổi theo | ≤ 20% | 20–35% | > 35% |
| RTP toàn dân 28 ngày | 0,70–0,95 | 0,60–0,70 hoặc 0,95–1,00 | < 0,60 hoặc > 1,00 |
| RTP heavy N1–N4 | ≤ 1,01 | 1,01–1,05 | > 1,05 |
| p99 lãi ròng 28 ngày | ≤ 25% thu nhập | 25–40% | > 40% |

Ngưỡng xanh nới hơn bản chiều (WAU 15% → 12%, bỏ sau 1 lần 50% → 60%, RTP đáy 0,75 → 0,70) vì bản cực khó dự kiến mất người sớm hơn. Liam duyệt ngưỡng nới (G5, 13/10). Đỏ về retention hoặc đuổi theo thì rút lại.

## 9. Acceptance Criteria

**Chức năng (test tự động):**
1. `mission_mods(["M6"])` trả `enemy_hp` 1,20; `["M7"]` trả `elite_dmg` 1,25; `["M5","M6","M7"]` nhân đúng; `["M3"]` ở A9 bị bỏ.
2. Bộ luật N6 (M1+M4+M5+M6+M7) ở A9: engine sinh trận có HP quái thường ×1,20, dmg elite ×1,25 × 1,10 × 1,15 theo thứ tự nhân; kiểm số cụ thể trên một quái mẫu.
3. Mua trừ đúng cược trong một batch; thiếu số dư (không tính khoản khởi đầu), bậc chưa mở, hoặc đang có run mở thì từ chối. Mua nhiều lần cùng offer trong ngày được phép.
4. Bảng cùng ngày, cùng cấp nhà là cùng danh sách trên hai tài khoản; đổi `rules_version` đổi bảng.
5. `aid_req`, `epoch_req(continue)`, Boon bị từ chối trong run Nhiệm vụ; log có `AID_USE`/`CONTINUE` thì verify fail.
6. Verifier timeout (canary qua) huỷ + hoàn đúng cược, không R/Stone; tái lập thêm cờ C10.
7. Payout dùng m gốc và `m_scale` ở header; đổi `m_scale` giữa chừng không đổi run mở; **N6 thắng trả đúng 20.000** và N5 12.715.
8. Mở N6 chỉ khi đã có run Full thắng ở A9, bất kể cấp nhà.
9. Stone/ngày từ Nhiệm vụ ≤ 150.
10. Run Nhiệm vụ đã verify hiện trên bảng của đúng Ascension với nhãn bậc; run huỷ vì verifier lỗi không hiện.
11. Unlock từ Pass trả tiền không áp dụng trong Nhiệm vụ.
12. Điều kiện phụ: hạ boss cuối mà không thoả thì thua, kiểm bằng replay.
13. Tính công thức: sim Monte Carlo 100.000 lần mua theo §4.2 cho RTP mỗi hồ sơ trong ±0,02 bảng.
14. **SIM game thật** (§4.5): p mỗi bậc trong dung sai đã nêu; heavy RTP N1–N4 ≤ 1,03.
15. AC của §11.

**Trải nghiệm (playtest):**
1. ≥ 7/8 người thử nói đúng "mất gì nếu thua, nhận gì nếu thắng, kỳ vọng nhận lại" chỉ từ thẻ + màn xác nhận.
2. Sau một run thua ở N3 trở lên, ≥ 6/8 người nêu được ít nhất một nguyên nhân cụ thể (đồng hồ, spike, thiếu build), không ai nói "bị giấu".
3. Ít nhất 1/8 người chơi giỏi thắng được N3 trong 5 lần thử (kiểm bậc không "bất khả thi" với người giỏi).
4. 4 tuần soft launch: §8 không hàng đỏ.

## 10. Danh hiệu A5 và A10 — ĐÃ CHỐT (Liam 13/10)

Cosmetic, không cho sức mạnh (quyết định 11/10 mục 7). A5 Eternal Gift (relic elite bị ấn Eternal, không đổi/bán được); A10 Last Stand (mọi boss ép pact, không reroll thẻ).

| | Việt | English | Ý |
|---|---|---|---|
| **A5** | **Người Giữ Ấn** | Sigilbearer | Mang ấn Eternal qua cả run |
| **A10** | **Người Đứng Cuối** | The Last Standing | Last Stand sát nghĩa, dễ đọc |

## 11. Tự chỉnh m theo bậc (Bayes) — giữ nguyên luật, cập nhật prior

Luật, núm, và ví dụ N4 của bản 12/10 chiều **giữ nguyên** (bản đầy đủ ở git trước commit này: `git show HEAD:design/proposals/nhiem-vu-risk-to-earn.md`, mục 11). Tóm tắt luật cứng: chỉ `m_scale` theo bậc, một số chung cho mọi người (MON-5), chỉ hạ hoặc nhả về bảng gốc (`s ∈ [s_min 0,75, 1,00]`), không đổi d hay luật, đổi chậm (≤ 0,02/ngày, ≤ 0,08/tuần), cron 00:00 UTC, `s* = R_hi / (m_gốc × θ_0,90)` với R_hi 0,95, ε 0,10, n0 60, n_min 100, cửa sổ 28 ngày, `account_cap` 30 run/bậc.

**Prior mới** (μ0 = Σ w × p, cùng tỉ lệ mua như bản chiều; ví dụ N4: 0,29×0,104 + 0,71×0,226 = 0,191):

| Bậc | μ0 | RTP prior (μ0 × m × s) |
|---|---|---|
| N1 | 0,197 | 0,42 |
| N2 | 0,252 | 0,61 |
| N3 | 0,204 | 0,73 |
| N4 | 0,191 | 0,84 |
| N5 | 0,121 | 0,85 |
| N6 | 0,051 | 0,41 |

Tất cả dưới R_hi 0,95: ở bản cực khó §11 hầu như không hạ `m_scale` trừ khi dân giỏi bất thường. Ví dụ để test: N4 prior α0 = 60 × 0,191 = 11,5; β0 = 48,5. Cửa sổ n = 400, w = 92 (23%) (sửa review 12/10: bản gốc ghi w = 100 nhưng (11,5+100)/460 = 0,2424, không phải 0,2243; w = 92 mới ra 0,2243): μ = 0,2243; sd ≈ 0,0194; θ_0,90 = 0,249; s* = 0,95/(4,40 × 0,249) = 0,867; s_target 0,87, đi xuống 0,02/ngày. Kẹp ở `s_min` quá 14 ngày thì báo động người xem lại bảng gốc. Giới hạn nói thật: chỉ bắt xu hướng toàn dân, không bắt vài người giỏi hơn hẳn (§4.4); N5/N6 ít người mua nên sống bằng prior lâu. **AC §11 (11.7) giữ**, thay số test: với dữ liệu ví dụ trên hàm trả `s*` = 0,867 ± 0,002.

---

## 12. Câu hỏi mở — ĐÃ TRẢ LỜI (Liam 13/10, `pending-decisions.md` mục H)
1. **G1** RTP toàn dân ~0,70–0,75: **chấp nhận**, không hạ d N1–N2.
2. **G2** Trần payout 20.000: **giữ**, N6 là bậc danh hiệu.
3. **G3** Bỏ "tối đa 2 luật thêm", N6 có 5 luật: **đồng ý**.
4. **G4** M6 Quân dày + M7 Elite hung, sửa `mission_mods`/engine (§7), bump `RULES_VERSION`: **đồng ý**.
5. **G5** Tên A5 "Người Giữ Ấn", A10 "Người Đứng Cuối" (§10); ngưỡng telemetry nới (§8) giữ như đề xuất.
6. **G6** Điều kiện phụ (Một nhà, Đa sắc): **giữ**.
Thêm: bỏ cuộc = mất cược, không nhận R (trả lời review mục 4).

---

## Review (economy-designer, 12/10 đêm)

**Verdict: APPROVE WITH CHANGES.** Số học §4 đúng gần hết (tôi tính lại logit cho cả 6 bậc × 3 hồ sơ; chỉ lệch ≤ 0,3 điểm, trừ N1). Chưa có chỗ nào cần viết lại cả bản. Các sửa nhỏ đã làm trực tiếp, đánh dấu "(sửa review 12/10)": d N1, N2 casual, RTP casual gia quyền, câu "hạ d lên 0,78" sai, N5 farm được, N6 chạm trần không phải lỗi, w trong ví dụ §11.

**Đã kiểm, đúng:** p/RTP N3, N4, N5, N6 mỗi hồ sơ; bảng cược/trả §3.6 (645/1.200/2.880/5.280/12.715/20.000); RTP gia quyền 0,500 / 0,996 / 0,867; RTP toàn dân 0,748 (heavy hợp lý) và 0,700 (heavy có N5/N6) với trọng số 45/40/15 theo khối lượng cược; +517 Shard/lần ở N4 khi giỏi hơn heavy 0,5 logit; N6 không clamp = 18,7/18,75; payout N6 chạm đúng 20.000 vì m đã kẹp 8,00. M2 `spike_period_delta` đã được engine đọc (`combat_engine.gd` ~1545), không còn là việc cần kiểm.

**Cần Liam quyết / tác giả sửa:**
1. **N1 d = 0,95 vs 1,00.** Bảng d tự cộng ra 1,00. Dùng 1,00 thì heavy N1 RTP = 0,968 (an toàn), m 2,15 vẫn dùng được (hoặc 2,20). Khuyến nghị: đổi cả §4 sang d = 1,00. Giữ 0,95 thì heavy N1 = 0,995, sát ngưỡng 1,01 của §8.
2. **RTP toàn dân bị chặn quanh 0,75.** Heavy ≈1,00 và chiếm ~54% khối lượng cược nên không chỉnh d nào đưa toàn dân lên 0,78 (sửa ở §4.3). Đích "0,75–0,95" của Liam và "heavy ≤ 1,00 ở N1–N4" chỉ cùng đứng được nếu heavy mua ít hơn giả định. Khuyến nghị: nói thẳng với Liam, hoặc m = 0,95/p_heavy cho N1–N4 (heavy ~0,95, toàn dân ~0,72) và chấp nhận dải xanh 0,70–0,95 ở §8 như đã nới.
3. **N5 farm được.** Giỏi hơn heavy 0,5 logit thì RTP 1,31 ở N5 (§4.4 chỉ nói N4 và N6). Cần: nâng `m_scale` init N5 xuống ~0,80, hoặc cho §11 một mốc tối đa theo p99 từng tài khoản, hoặc `account_cap` run/bậc/ngày riêng cho N4–N5 (đây là quyết định thiết kế, không tự sửa).
4. **Shard R khi thua/bỏ.** *(Liam 13/10: bỏ cuộc = không nhận R; đã sửa §0, §3.5, §4, §6. Phần dưới là lập luận gốc.)* §0 và §3.5 nói "R trả như run thường" kể cả thua. R = 450 là trung bình run đủ dài; cược N1 chỉ 300. Nếu R không phụ thuộc tiến độ thì mua N1 rồi bỏ ngay vẫn lãi ròng +150 (farm không rủi ro, phá cả bài test risk-to-earn). Cần ghi rõ: R theo tiến độ run, bỏ ngay sau khi mua R = 0 (hoặc tối thiểu), và bảng "Net" §4.2/§4.3 tính có/không R.
5. **Hoàn cược khi verifier timeout.** Không tái lập thì hoàn 100%: kẻ gian có thể gửi log nặng đúng lúc sắp thua. Cần trần hoàn/ngày/tài khoản và đếm tần suất theo tài khoản (không chỉ cờ C10 khi tái lập được).
6. **N1 và N2 gần như trùng:** cùng bộ luật, p chênh 4 điểm, m 2,15 vs 2,40, đều "heavy hòa vốn". Khác nhau thật chỉ là cược 300 vs 500 và A3/A4. Không vô nghĩa nhưng yếu về nấc thang: casual thua ~86% ở N1, nên với casual N1 đã là bậc "cực khó". Cân nhắc N1 d thấp hơn (hạ tới ~0,70) cho một bậc làm quen thật, với m dựng lại.
7. **Tên khoá `enemy_hp` trùng** `RunState.run_mods["enemy_hp"]` và `_run_mod("enemy_hp")` (curse/event, `combat_engine.gd` ~1740), mà khoá đó nhân vào *budget* (ảnh hưởng cả HP lẫn số quái/xúc xắc). M6 muốn "chỉ HP quái thường" thì phải nhân per-monster như `mods.hp`, không qua budget, và đặt tên khác (vd `normal_hp`). M7 `elite_dmg` cũng phải nhân per-monster, chỉ elite. Quy tắc làm tròn HP (ceil/round) chưa nêu.
8. **Stack dmg elite ở N6**: 1,10 × 1,15 × 1,25 = ×1,58, thêm clock +100%. Cộng logit d = 2,00 gần như chắc chắn thấp hơn thực tế; SIM §4.5 phải chạy N5/N6 trước khi tin bảng. `full_exponent` 1,5 chưa verify quyết định cả N6 (0,4/1,4/5,1%).
9. **`mission_rules.json` `_doc` và `ContentDB`** còn ghi "≤2 rule per offer"; cần sửa kèm bump `RULES_VERSION`. Kiểm xem có chỗ nào (bảng ngày, server) thực sự chặn >2 luật.
10. **Stone**: 4–60 Stone/lần thắng và trần 150/ngày không bao giờ chạm (heavy thắng vài lần/ngày); AC 9 gần như tầm thường. Nhà cấp 4 cần 30.000 Stone thì Nhiệm vụ gần như không đóng góp Stone nào: Stone phải đến từ nguồn khác, nên "nâng nhà bằng Shard + Stone" thực chất là cổng Stone.

Liam 13/10: chấp nhận RTP thấp; không hạ N1–N2.

**Exploit khác đã xét, ổn:** bỏ để né thua (cược trừ lúc tạo run, seed server cấp, không lộ trước → không né được); đa tài khoản (Shard không chuyển được và khoản khởi đầu không dùng làm cược → không thấy đường lợi, miễn là Shard không trade); cày N1–N2 (heavy hòa vốn, người giỏi hơn có lợi nhưng cần nhiều lần mua, một run mở/lần, §11 bắt xu hướng). Lỗ hổng đáng lo nhất là mục 4 và 3.

**Section & AC:** đủ 8 mục (Overview §1, Fantasy §2, Rules §3, Formulas §4, Edge §6, Deps §7, Knobs §8, AC §9). AC cần bổ sung: (a) AC 15 trỏ "AC của §11" ở bản HEAD, không tự đứng được, nên chép AC §11 vào đây; (b) AC 2 "kiểm số cụ thể" chưa có số, nên ghi ví dụ (quái thường HP gốc X → ×1,20 làm tròn Y; elite dmg A9 + N6 = ×1,58); (c) thiếu AC cho R khi bỏ run (mục 4) và trần hoàn cược verifier (mục 5); (d) AC "SIM" 14 chưa nêu số lần chạy, §4.5 có (2.000/4.000/6.000), nên dẫn số đó; (e) playtest 3 (≥1/8 thắng N3 trong 5 lần) cho heavy chỉ đạt ~80% xác suất, nên cỡ mẫu 8 người dễ cho kết quả ngẫu nhiên, nâng lên 12 hoặc đổi thành chỉ số telemetry.
