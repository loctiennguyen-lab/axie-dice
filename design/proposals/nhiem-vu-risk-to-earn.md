Trạng thái: ĐỀ XUẤT — chờ Liam review

> **Liam (11/10, bổ sung):** (6) nhà Nhiệm vụ nâng cấp bằng **Gene Shard + Land Stone**, KHÔNG tiền thật · (7) **CÓ** —
> bậc khó nhất dùng Full mode · Nhiệm vụ **không gắn monetization**: không bán Thử lại / Bảo hiểm cược; chỉ khó và ức chế,
> là bài test risk-to-earn.

> **QUYẾT ĐỊNH LIAM (11/10) sau bản viết lại — ưu tiên hơn thân file:** (1) Nhiệm vụ chạy ở mọi Ascension · (2) server
> giữ số dư Shard làm chuẩn (escrow) · (3) hiện dòng "kỳ vọng nhận lại" ở màn xác nhận · (4) **bản này QUÁ DỄ — viết lại
> CỰC KHÓ, tạo ức chế; hướng sản phẩm mới: tạo ức chế rồi bán giải pháp (tiện lợi + sức mạnh trong run, tiền thật, dùng
> được cả ranked)** — xem `production/session-state/active.md` mục "HƯỚNG SẢN PHẨM MỚI" · (5) Stone 3–50 giữ · (6) **nhà
> Nhiệm vụ có cấp riêng, cấp cao mở thêm số Nhiệm vụ/ngày**; số này phải chỉnh được (sau có thể giới hạn chặt, vd nếu đổi
> sang AXS) · (7) chờ xác nhận: Full mode cho bậc khó nhất · (8) **server tung xúc xắc, ở mọi chế độ** (bỏ seed theo trận).

> **QUYẾT ĐỊNH CỦA LIAM SAU REVIEW (10/10) — ưu tiên hơn nội dung bên dưới:**
> - Thứ tự làm: **Economy → Relic → Nhiệm vụ** (Nhiệm vụ thiết kế lại SAU khi economy + relic chốt).
> - **Echo Box**: reset theo NGÀY (UTC), tăng số lượt quay được nhưng hạ tương đối tỉ lệ đồ hiếm.
>   KHÔNG quay trực tiếp bằng Shard: dùng Shard **mua vé**, quay bằng vé. Cosmetic trùng **phân tách
>   thành vé** để quay tiếp. Học cơ chế gacha mới của **Dota 2** (người chơi rất hài lòng) và kết
>   hợp với các ý trên. Vé được thiết kế để sau này có thể bán bundle vé riêng (chưa có store).
> - **Land chỉ trả bằng Land Stone.** Con số hiển thị phải TO: 40.000 / 100.000 / 180.000 /
>   500.000 (Liam xác nhận 10/10) / 1.000.000. Người chơi nhiều
>   tới LunaLanding mất ~**1 năm**. Muốn lên Land nhanh thì phải chơi gacha nhiều (Echo Box là
>   faucet Stone).
> - Land Stone sink sau LunaLanding / Land Wonders: Liam tự tính sau, chưa cần.
> - **Daily**: đồng ý đề xuất. Ngày tính theo **giờ UTC**, server xác nhận.
> - **Battle Pass**: đổi đường cong XP; học **Battle Pass của LoL** — chơi càng nhiều lên càng
>   nhanh, nhưng chơi nhiều nhất cũng mất ~2 tuần mới xong. Đưa một số cosmetic vào làm thưởng Pass.
>   **5 unlock cộng chỉ số vẫn đưa vào Battle Pass được** — tinh chỉnh khéo cho hợp (Ranked profile
>   vẫn tắt chúng).
> - **Nhiệm vụ**: CÓ trả Land Stone nhưng lượng rất nhỏ. **Bỏ** hai luật thêm (lỗ ngày ≤1R, stake
>   ≤40% số dư): người chơi được phép lỗ cả 5 nhiệm vụ. Đường cong độ khó và đường cong thưởng phải
>   đi cùng nhau: muốn kiếm nhiều thì phải chấp nhận khó và bỏ nhiều tiền. Mục đích: kiểm tra người
>   chơi có chấp nhận risk to earn không.
> - Ba điều trong thiết kế Nhiệm vụ: (1) chạy trên ranked profile — đồng ý; (2) đổi tên Daily
>   Mission +60 thành "Thưởng ngày" — đồng ý; (3) save-scum — Liam chưa thấy vấn đề, đang hỏi lại.


# Nhiệm vụ (risk-to-earn) — bản thiết kế lại sau khi economy và relic đã chốt

Tác giả: game-designer · 11/10/2026 · Thay toàn bộ thân bản 10/10 (nội dung cũ vẫn còn trong git). Chỉ sửa file này, không code.
Mọi con số tính tay, **chưa qua sim**. Chỗ nào chưa kiểm trong code thì ghi "chưa verify". Năng lực người chơi (tỉ lệ thắng run) là **giả định**, không phải số đo: phần 2.4 nói cách thay bằng số thật.

---

## 0. Đọc nhanh

1. Mỗi lần mua Nhiệm vụ = trả **stake** bằng Shard, chơi **đúng một run ranked-profile** có thêm một điều kiện. Đạt thì nhận `stake × m` (đã gồm stake) cộng một ít Land Stone. Không đạt thì mất stake, không hoàn, không có Stone.
2. Mỗi Nhiệm vụ có **một điểm khó D** (đơn vị logit). Từ D suy ra xác suất thành công của từng kiểu người chơi, và D quyết định **bậc** (T1 tới T7). Stake, hệ số m và Stone đều gắn vào bậc, nên **độ khó và thưởng đi cùng nhau** như Liam yêu cầu.
3. Thang 7 bậc: stake 100 → 1.800 Shard, m 1,20 → 3,40, Stone 3 → 50. Tính ở R = 450: casual lỗ nhẹ, regular lỗ vừa, người giỏi (~70% thắng run) lãi nhỏ ở bậc giữa. **RTP toàn dân kịch bản cơ sở ≈ 0,94** (≤ 1). Chỉ có hai cách kiếm Shard thật: chọn bậc hợp sức mình và chơi giỏi hơn mức giá đã tính.
4. Land Stone tối đa **130/ngày theo cấu trúc bảng** (dưới trần 150 của economy-v2); kỳ vọng thực tế 6–45/ngày tùy người, chưa tới 1% Stone tuần.
5. Bảng mỗi ngày **giống nhau cho mọi người** (seed theo ngày UTC), 5 offer (nhà Nhiệm vụ lên cấp Land thì hiện thêm tới 8 offer, vẫn chỉ mua tối đa 5). Mỗi ngày chỉ có **một** offer bậc cao nhất, không ai "cày bậc 7 năm lần" được.
6. Toàn bộ do **server** kiểm: server cấp seed, giữ stake (escrow), replay ActionLog, tính điều kiện từ replay rồi mới trả. Quy tắc resume mới (đổi RNG xúc xắc, server cấp seed) đóng lỗ save-scum: tối đa 3 lần resume mỗi Nhiệm vụ, mỗi lần đều ghi vào log.
7. Câu hỏi của Liam ("người chơi có chấp nhận risk-to-earn không?") trả lời bằng 4 nhóm số ở §8, kèm ngưỡng xanh/vàng/đỏ.

---

## 1. Mục tiêu, và thứ Nhiệm vụ không được trở thành

**Aesthetic chính (MDA)**: Challenge và Expression. Người chơi tự nói "run này tôi chơi theo luật khó hơn" và game trả công cho lời nói đó. **SDT**: Autonomy (tự chọn bậc và kiểu chơi), Competence (điều kiện đo được, thấy ngay vì sao thắng hay thua).

Vị trí trong vòng lặp: tầng MESO (một run). Run vẫn trả thưởng như run ranked bình thường; Nhiệm vụ là phần **chồng thêm**. Thua Nhiệm vụ không lấy lại Shard mà run đã kiếm. "Thưởng ngày" (60 Shard + 500 Stone) là thứ khác và không đổi.

Nó **không được** trở thành:
- **Máy đánh bạc.** Không "gấp đôi hoặc mất hết", không hệ số tăng khi thắng liên tiếp, không giảm giá mua lại sau khi thua, không hiệu ứng "suýt thắng".
- **Cày đều.** Stone nhỏ tới mức không ai cày vì Stone. Bậc cao nhất chỉ có một offer mỗi ngày.
- **Nguồn Shard cho người giỏi.** Population RTP ≤ 100%. Người giỏi được lãi, nhưng lãi bị chặn bởi giá đã tính theo năng lực cao.
- **Bẫy cho người yếu.** Người yếu thấy rõ xác suất của chính mình trước khi trả tiền (§7), và bảng luôn có offer bậc thấp.
- **Công việc phải làm.** Không phạt khi bỏ qua. Không đếm ngược gây áp lực ngoài giờ reset UTC (hiện thẳng, không nhấp nháy).

Chiều ngược lại cũng quan trọng với Liam: nếu thua mà không thấy đau thì không kiểm tra được gì. Vì vậy stake bậc cao đủ lớn để người chơi **cảm thấy** nó (1,1R tới 4R).

---

## 2. Mô hình độ khó

### 2.1 Định nghĩa

Mỗi Nhiệm vụ gồm: một **mục tiêu** (thắng, hoặc hạ boss k, hoặc tới boss k), một **mode** (Short ở bản đầu), một **Ascension** A (0 đến 10), và 0 đến 2 **điều kiện** phụ.

```
D = D_obj + D_asc + Σ D_cond + D_adj(loại)
D_asc  = 0,15 × A
D_cond = −ln(q)            q = P(đạt điều kiện | thắng), từ sim hoặc telemetry
```

D là độ lệch logit: tăng 1 điểm D là giảm khoảng 1 logit xác suất thành công. `D_adj` là chỉnh theo dữ liệu thật (§2.4), mặc định 0.

| Mục tiêu (Short, 12 node, boss ở node 4/8/12) | D_obj |
|---|---|
| Tới boss 1 (chưa cần hạ) | −1,9 |
| Hạ boss 1 | −1,3 |
| Hạ boss 2 | −0,5 |
| Thắng run (hạ boss 3) | 0 |
| Thắng run Full (20 node, 4 boss) | +0,8 (để dành, xem câu hỏi mở) |

Các số D_obj suy từ mô hình "xác suất sống sót đều mỗi node" (thắng Short 50% → sống 94,4% mỗi node → tới boss 1 ≈ 79%, Full ≈ 32%). Thô, sẽ thay bằng sim.

Vì sao `−ln(q)`: với điều kiện phụ độc lập, `p ≈ p_thắng × q`. Với p nhỏ đến vừa, nhân q tương đương dịch logit `−ln q`. Hai điều kiện thì cộng. Không phải đúng tuyệt đối, nhưng đủ gần để chia bậc, và bước 2.4 chỉnh lại theo dữ liệu.

**Luật kiểm hợp lệ** (generator từ chối): điều kiện xung đột (Không mua sắm cùng Két sắt), điều kiện bị Ascension làm cho miễn phí hoặc bất khả thi (ở A6+ "giữ 1 pact" là miễn phí, ở A10 bắt buộc nhiều pact nên "≥2 pact" gần như chắc), D tổng ngoài [−2,3; +2,3].

### 2.2 Từ D ra xác suất thành công

Mỗi kiểu người chơi j có **năng lực** θ_j = logit(tỉ lệ thắng run Short A0 ranked-profile). Xác suất thành công của Nhiệm vụ độ khó D:

```
p_j(D) = 1 / (1 + e^(D − θ_j))
```

**Giả định năng lực (thay bằng số đo, §2.4):**

| Persona | Thắng run Short A0 | θ |
|---|---|---|
| Casual | 30% | −0,85 |
| Regular | 50% | 0 |
| Heavy | 70% | +0,85 |

(Bản cũ giả định 20/45/75, nhưng đó là run có unlock cộng chỉ số. Ranked-profile tắt unlock nên khoảng cách có thể hẹp hơn; chưa có số đo.)

| D | −2 | −1 | 0 | +1 | +2 |
|---|---|---|---|---|---|
| Casual | 76,0% | 53,8% | 30,0% | 13,6% | 5,5% |
| Regular | 88,1% | 73,1% | 50,0% | 26,9% | 11,9% |
| Heavy | 94,5% | 86,4% | 70,0% | 46,2% | 24,0% |

Khoảng cách giữa người giỏi và người yếu **giãn ra khi D tăng** (tỉ lệ heavy/casual: 1,2 ở D = −2, 4,4 ở D = +2). Đây là bản chất của risk-to-earn dựa trên kỹ năng, và là lý do §3 định giá theo năng lực tăng dần theo bậc.

### 2.3 Chia bậc

Mỗi bậc có một **tâm D**. Generator chọn mục tiêu, Ascension, điều kiện sao cho D tổng nằm trong **±0,15** quanh tâm (núm `eps_D`); không đạt thì thử tổ hợp khác. Nhờ vậy cùng một bậc thì xác suất sai lệch tối đa khoảng ±3,5 điểm phần trăm, và bảng thưởng giữ nguyên bất kể điều kiện là gì.

### 2.4 Cách hiệu chỉnh p bằng sim và telemetry

**Trước khi ra (sim):**
1. Chạy sim A của `relic-set-v2.md` §6.1 (11 bot archetype, 300 seed mỗi bot) trên **ranked-profile** ở A0 và A5. Lấy tỉ lệ thắng trung bình `w̄` và của từng archetype `w_X`.
2. Với mỗi loại điều kiện, đo `q` bằng cách chạy bot có và không có ràng buộc, tính `q = P(đạt | thắng)`. Ghi `D_cond = −ln q` vào `assets/data/` (không hardcode).
3. Hiệu ứng từng luật Ascension: lấy từ sim G của `ascension-v2.md` (mục tiêu 2–5 điểm thắng mỗi luật) rồi đổi sang logit để thay `0,15 × A`.
4. θ_j của người thật chưa có; dùng giả định ở 2.2 rồi **soft launch** (§8) đo.

**Sau khi ra (hàng tuần):**
1. Với mỗi lần mua, ghi `(θ̂_i của người chơi, đặc trưng Nhiệm vụ, thành công hay không)`. θ̂_i = logit của tỉ lệ thắng ranked-profile của người đó, co về 45% với trọng số 10 run giả.
2. Hồi quy logistic `logit p = θ̂_i − D_loại` theo loại Nhiệm vụ. Co về D tiên nghiệm với **k = 200 lần thử giả**: `D_adj = (n·D_đo + k·D_tiên_nghiệm)/(n+k) − D_tiên_nghiệm`.
3. **Giá trị cập nhật là D, không phải m.** Loại nào dễ hơn dự đoán thì D tăng → bị đẩy lên bậc cao hơn → stake và m cao hơn, p giảm. Bảng thưởng theo bậc ổn định, người chơi không bị đổi giá giữa chừng, và không có loại nào ở mãi trong "tiền dễ".
4. Đạt chuẩn khi, với mỗi bậc, tỉ lệ thành công quan sát của nhóm tham chiếu nằm trong ±7 điểm của p_ref(bậc), với ≥ 1.000 lần thử mỗi bậc.

---

## 3. Thang stake và thưởng

### 3.1 Nguyên tắc định giá

`m = 0,95 / p_ref`, làm tròn 0,05. `p_ref` là xác suất của **người chơi tham chiếu của bậc**, và năng lực tham chiếu **tăng dần theo bậc**: θ_ref = −0,565 + 0,282 × (bậc − 1), tức bậc thấp định giá cho người yếu, bậc cao cho người giỏi, và người tham chiếu nằm khoảng **nửa bậc cao hơn** người dự kiến mua (để bù chọn lọc ngược: người giỏi dồn vào bậc nào lãi). Người tham chiếu đạt RTP ≈ 0,95; 5% còn lại là sink Shard nhỏ.

Hai lựa chọn tôi đã thử và bỏ: (a) định giá theo regular cho mọi bậc: heavy lãi tới 1,8× ở T7, in Shard 6.000/ngày, phá economy; (b) định giá theo heavy cho mọi bậc: casual mất 55–75% mỗi lần, cảm giác săn mồi.

### 3.2 Bảng thang (R = 450, Shard)

| Bậc | Tâm D | p_ref | Stake | Stake / R | m | Trả khi thắng | Lãi ròng khi thắng | Stone khi thắng |
|---|---|---|---|---|---|---|---|---|
| T1 | −1,95 | 80% | 100 | 0,22 | 1,20 | 120 | +20 | 3 |
| T2 | −1,15 | 70% | 200 | 0,44 | 1,35 | 270 | +70 | 6 |
| T3 | −0,40 | 60% | 350 | 0,78 | 1,60 | 560 | +210 | 10 |
| T4 | +0,30 | 50% | 500 | 1,11 | 1,90 | 950 | +450 | 16 |
| T5 | +0,90 | 42% | 800 | 1,78 | 2,25 | 1.800 | +1.000 | 24 |
| T6 | +1,45 | 35% | 1.200 | 2,67 | 2,70 | 3.240 | +2.040 | 34 |
| T7 | +2,05 | 28% | 1.800 | 4,00 | 3,40 | 6.120 | +4.320 | 50 |

Stake, m, Stone, D đều tăng nghiêm ngặt theo bậc (bất biến NV-2). Số bậc 7 là lựa chọn của tôi: 5 offer mỗi ngày cần phủ khoảng từ "dễ cho người mới" tới "khó cho người giỏi nhất" mà vẫn đủ khác biệt. Số 5–7 đều chạy được.

**Stone**: giá trị Stone vào bậc đều nhỏ: 1 vé hộp thường ≈ 242 Stone mà tốn 200 Shard, nên 100 Shard stake bỏ ra ≈ 120 Stone giá trị vé. Stone thưởng 3–50 chỉ là "mùi vị" của Nhiệm vụ, không phải lý do để chơi. Giữ `stone_scale` làm núm (§9).

### 3.3 Xác suất và RTP theo persona

p_j = 1/(1 + e^(D − θ_j)) tại tâm D; RTP = p × m.

| Bậc | p casual | p regular | p heavy | RTP casual | RTP regular | RTP heavy |
|---|---|---|---|---|---|---|
| T1 | 75,1% | 87,6% | 94,3% | 0,90 | 1,05 | 1,13 |
| T2 | 57,5% | 76,0% | 88,0% | 0,78 | 1,03 | 1,19 |
| T3 | 39,0% | 59,9% | 77,7% | 0,62 | 0,96 | 1,24 |
| T4 | 24,1% | 42,6% | 63,3% | 0,46 | 0,81 | 1,20 |
| T5 | 14,8% | 28,9% | 48,7% | 0,33 | 0,65 | 1,10 |
| T6 | 9,1% | 19,0% | 35,4% | 0,25 | 0,51 | 0,95 |
| T7 | 5,2% | 11,4% | 23,1% | 0,18 | 0,39 | 0,79 |

Đọc bảng: mỗi bậc là một "cổng kỹ năng". Casual ngon ở T1–T2 (RTP 0,78–0,90), regular ở T2–T4, heavy ở T3–T5. Mua cao hơn sức mình thì RTP rơi mạnh, và đó là **cái giá của risk** Liam muốn thấy. Muốn kiếm nhiều Shard hơn: lên bậc (stake và m lớn hơn) **và** giỏi hơn mức giá đã tính cho bậc đó.

**Lãi ròng kỳ vọng mỗi lần mua (Shard)** = stake × (RTP − 1):

| Bậc | Casual | Regular | Heavy |
|---|---|---|---|
| T1 | −10 | +5 | +13 |
| T2 | −45 | +5 | +38 |
| T3 | −132 | −15 | +85 |
| T4 | −271 | −96 | +102 |
| T5 | −533 | −280 | +77 |
| T6 | −904 | −584 | −55 |
| T7 | −1.480 | −1.102 | −387 |

### 3.4 Population RTP (kịch bản cơ sở)

Giả định hành vi (tôi đoán, đo ở §8): số Nhiệm vụ mua mỗi tuần: casual 4 (1 mỗi ngày chơi), regular 7, heavy 21 (3 mỗi ngày). Phân bố bậc đã mua:

| | T1 | T2 | T3 | T4 | T5 | T6 | T7 | Stake TB | RTP có trọng số | Stake/tuần | Lãi ròng/tuần | % thu nhập tuần (R = 450) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Casual | 35% | 40% | 20% | 5% | | | | 210 | 0,709 | 840 | −245 | −3,8% (6.423) |
| Regular | 10% | 25% | 30% | 25% | 10% | | | 370 | 0,853 | 2.590 | −381 | −5,1% (7.540) |
| Heavy | | 5% | 15% | 25% | 25% | 20% | 10% | 807,5 | 1,012 | 16.958 | +200 | +0,8% (26.653) |

Với dân số 45% casual, 40% regular, 15% heavy: khối lượng stake/tuần/người = 378 + 1.036 + 2.544 = 3.958; tổng trả lại = 268 + 884 + 2.575 = 3.726 → **RTP toàn dân = 0,941 ≤ 1**. Phần chênh 0,059 là sink Shard (≈ 5,9% khối lượng stake, tức ≈ 2,3% thu nhập Shard TB của người chơi, trong đó phần lớn từ casual/regular).

**Độ nhạy R** (stake cố định theo Shard; R chỉ đổi gánh nặng tương đối):

| Thu nhập tuần | R = 350 | R = 450 | R = 570 |
|---|---|---|---|
| Casual (−245/tuần) | 5.223 → −4,7% | 6.423 → −3,8% | 7.863 → −3,1% |
| Regular (−381) | 6.140 → −6,2% | 7.540 → −5,1% | 9.220 → −4,1% |
| Heavy (+200) | 21.053 → +0,9% | 26.653 → +0,8% | 33.373 → +0,6% |

Stake bậc cao tính theo R: T7 = 5,1R / 4,0R / 3,2R ở R = 350 / 450 / 570. Khuyến nghị: lưu stake dưới dạng **số Shard cố định**, dựng lại cả bảng khi R đo được lệch > 15% so với 450.

**Độ nhạy năng lực heavy** (rủi ro lớn nhất của mô hình này): nếu heavy thật chỉ thắng 60% (θ = 0,41) thì RTP T4 ≈ 1,00, farm hết lãi; nếu thắng 80% (θ = 1,39) thì RTP T4 ≈ 1,42 (+210 mỗi lần). Population RTP vì thế dao động 0,90 tới ~1,05 theo hành vi heavy. **Chỉ chạy m thật sau khi có số đo** (xem NV-8 và `m_scale`).

Hành vi xấu cho dân số: nếu heavy dồn hết vào T3–T5 (RTP ~1,16) thì population RTP = (268 + 884 + 2.544 × 1,16)/3.958 ≈ **1,04 > 1**. Đó là ngưỡng khiến `m_scale` giảm 5–10% ở T3–T5 theo NV-8.

### 3.5 Hai trường hợp Liam yêu cầu

**Thua cả 5 trong một ngày.** Bảng mặc định có offer T2, T3, T4, T5, T7 (§5.1). Xác suất thua cả 5 (nhân xác suất thất bại từng bậc):

| | Xác suất thua cả 5 | Mất | % thu nhập tuần |
|---|---|---|---|
| Casual | 15,9% | 3.650 | 57% (6.423) |
| Regular | 3,5% | 3.650 | 48% (7.540) |
| Heavy | 0,39% | 3.650 | 13,7% (26.653) |

Casual và regular không có 3.650 Shard dư mỗi ngày (thu nhập ngày 1.606 / 1.077, và economy-v2 giả định họ tiêu hết vào vé), nên muốn mua cả 5 phải dành dụm nhiều ngày, và đó là **chọn của họ**. Liam đã bỏ trần nên không chặn; tôi chỉ đề nghị một dòng cảnh báo thông tin (§7, câu hỏi mở 5).
Một ví dụ dễ xảy ra hơn: casual mua 5 × T1 (500 Shard, 31% thu nhập ngày), xác suất thua cả 5 = 0,249⁵ = 0,1%.

**Người giỏi cày bậc cao.** Bốn trường hợp:
- *Heavy 70%, bảng 5 offer, bỏ T7 (mua T2–T5)*: stake 1.850, lãi kỳ vọng **+301/ngày** (8% thu nhập ngày 3.808), Stone kỳ vọng ≈ 35.
- *Heavy 70%, bảng 8 offer (Land cao), mua tối ưu 2×T3 + 2×T4 + T5*: stake 2.500 (66% thu nhập ngày), lãi **+450/ngày** (+3.150/tuần ≈ 11,8% thu nhập tuần; kéo LunaLanding nhanh hơn chừng 4 tuần trên 52, tính nhanh), Stone ≈ 47.
- *Mua T7 mỗi ngày (chỉ 1 offer/ngày)*: heavy 70% có RTP 0,79 (−387/lần). Chỉ người thắng run ≥ ~76% mới có lãi ở T7 (p cần ≥ 29,4%). Người 80%: p = 34%, RTP 1,16, +283/ngày.
- *Người cực giỏi (80%), 5 mua ở T3–T5*: RTP T4 ≈ 1,42 → khoảng **+1.000/ngày** (26% thu nhập ngày). Nhóm này rất nhỏ (tôi đoán ≤ 2% người chơi) nhưng đây là rủi ro faucet thật. Không có trần thắng trong bản đề xuất này; giám sát p99 lãi ròng 28 ngày (§8) và có `m_scale` theo bậc để hạ giá nếu cần.

Stone: kể cả mua đúng bảng tốt nhất, Stone kỳ vọng ≤ 60/ngày, tối đa theo cấu trúc 130/ngày.

### 3.6 Kiểm ngân sách Stone (ECO-12)

Stone chỉ trả khi thắng, theo bậc: 3 / 6 / 10 / 16 / 24 / 34 / 50.

- Bảng 5 offer (mỗi ngày): slot 1 ∈ {T1, T2}, slot 2 ∈ {T2, T3}, slot 3 ∈ {T3, T4}, slot 4 = T5, slot 5 ∈ {T6, T7}. Stone tối đa nếu thắng hết = 6 + 10 + 16 + 24 + 50 = **106** (≤ 150).
- Bảng 8 offer (nhà Nhiệm vụ cao): chọn 5 tốt nhất trong {T2, T3, T4, T5, T7, T3, T4, T5} = 50 + 24 + 24 + 16 + 16 = **130** (≤ 150).
- Kỳ vọng thực: casual 3,14 Stone/lần → 12,6/tuần; regular 5,60/lần → 39/tuần; heavy 10,4/lần → 219/tuần. Đó là 0,1% / 0,2% / 0,6% Stone tuần (economy-v2 §6.3: 13.363 / 16.728 / 34.814). Land kéo gần hơn chưa tới 0,4 tuần.
- Trần cứng `mission_stone_day_cap` = 150 giữ làm hàng rào server (trường hợp bug hoặc bảng cấu hình sai), bình thường không bao giờ chạm tới.

Nếu Liam muốn Stone có cảm giác hơn: `stone_scale` tới 2,5 (cùng 106 → 265 sẽ bị cắt ở trần 150). Tôi đề nghị ra mắt ở 1,0 rồi tăng theo telemetry (§8).

---

## 4. Danh mục Nhiệm vụ

Mỗi Nhiệm vụ = mục tiêu + (A) + điều kiện. Bảng dưới là các **loại điều kiện**; `D_cond = −ln q`, với q là **tiên nghiệm tôi đoán**, thay bằng sim (§2.4). Mọi điều kiện đọc từ dữ liệu run đã có hoặc từ ActionLog, **không đòi đổi relic nào**.

| # | Tên | Điều kiện | Dữ liệu | D_cond | Khuyến khích |
|---|---|---|---|---|---|
| 1 | Chớp nhoáng | Thắng với `turns` ≤ P50 của run thắng (Tia chớp: ≤ P25) | `run_stats.turns` (có) | 0,69 (Tia chớp 1,39) | Burst, build crit/pierce/exec/aoe |
| 2 | Không ai gục | Tổng Axie KO ≤ 2 (không KO: q = 25%) | `axie_ko` (mới) | 0,69 (1,39) | Shield/thorns, chơi an toàn |
| 3 | Da dày | Thắng với `taken` ≤ P40 | `run_stats.taken` (có) | 0,92 | Bulwark, aegis, kiểm soát |
| 4 | Đòn tử huyệt | Có đòn `max_hit` ≥ P60 của run thắng (P80: q = 20%) | `run_stats.max_hit` (có; không tính poison/thorns) | 0,92 (1,61) | Crit, exec, nhân ô G |
| 5 | Build X (11 loại) | Thắng và cuối run giữ ≥ 4 relic có tag X (exec, shield, pierce, mana, thorns, summon, growth, poison, crit, aoe, burn) | Relic đang giữ + tag (có) | `−ln(0,5) + ln(w̄/w_X)` ≈ 0,4 đến 1,0 | Một Nhiệm vụ cho mỗi archetype |
| 6 | Hai kỳ ngộ | Thắng khi đang giữ ≥ 1 relic Duo (12 relic) | Relic đang giữ (có) | 0,80 | Dựng hai archetype cùng lúc |
| 7 | Giao kèo | Thắng khi đang giữ ≥ 2 pact (ở A6+ phải tính lại q) | Relic đang giữ, `pact_group` | 0,92 | Chấp nhận drawback có chủ đích |
| 8 | Trận đồ | Thắng khi giữ ≥ 2 relic positional (linkstone, bookend, keystone, relaybaton, symmetrycharm) và có ≥ 1 `reorder_party` | Relic + ActionLog | 1,20 | Xếp đội thành quyết định |
| 9 | Tay trắng | Thắng với ≤ 4 relic ở cuối run (8 ô passive, bán đi hoặc bỏ thẻ) | Số relic (có), `sell_relic` (mới trong bộ relic) | 1,05 | Build gọn, bán đổi |
| 10 | Không thần khí | Thắng không giữ Legendary nào ở cuối run | Rarity relic (có) | 0,51 | Chọn Epic/Rare an toàn |
| 11 | Không mua sắm | Thắng với 0 `shop_buy` | ActionLog (có) | 0,69 | Dựa vào thẻ thưởng/event |
| 12 | Két sắt | Kết run còn ≥ P75 Shard của run (q = 25%) | Shard run (có) | 1,39 | Tiết kiệm, bỏ shop |
| 13 | Một nhà | Cả 5 Axie cùng class (Plant, Beast, Aqua, Reptile, Bug, Bird, giá riêng theo class) | `team_keys` (có) | 0,16 đến 0,51 | Thử class hay bị bỏ |
| 14 | Đa sắc | Đội có ≥ 4 class khác nhau | `team_keys` (có) | 0,16 | Đội đa dạng |
| 15 | Leo thang | Thắng ở Ascension Ak | Header `ascension` (có) | 0,15 × k | Leo ladder |
| 16 | Săn boss | Hạ mọi boss trong ≤ 8 lượt mỗi boss | `boss_turns[]` (mới) | 1,05 | Tránh build chờ, đối chọi enrage A4+ |
| 17 | Lửa ngầm | ≥ 50% tổng `dmg` đến từ Poison/Burn/Thorns | `dmg_dot` (mới) | 1,39 | Poison, burn, thorns |
| 18 | Không reroll | Thắng với ≤ P30 số reroll của run thắng | Đếm action reroll (có trong ActionLog); `rerolls` (mới) | 1,20 | Build không cần reroll, shield/summon |
| 19 | Quét sạch | Có ≥ 1 lượt giết ≥ 3 địch | `max_kills_turn` (mới) | 0,51 | Aoe, summon, exec |

**Counter mới** (không có trong 6 key `run_stats` hiện nay): `axie_ko`, `dmg_dot`, `max_kills_turn`, `boss_turns[]`, `rerolls`. `RunState.gd` ~930 chỉ nạp lại 6 key cố định lúc resume (F2 trong bản cũ, chưa đọc lại lần này), nên **phải thêm cả 5 vào danh sách nạp**, nếu không sẽ mất âm thầm sau resume. Tuy nhiên điều kiện chính thức **không đọc counter client**: server tính lại tất cả từ replay ActionLog. Counter client chỉ phục vụ tracker (§7). Chưa verify `RunVerifier` hiện có trả được các số này hay chỉ trả kết quả thắng/thua; nếu không thì cần mở rộng.

**Cân bằng giữa archetype.** Không archetype nào được thành tiền dễ, bằng ba lớp:
1. **Giá theo thực tế**: loại 5 dùng `ln(w̄/w_X)`. Archetype mạnh (w_X cao) có D thấp, tức bậc thấp hơn và m thấp hơn; yếu thì ngược lại. Tỉ lệ thắng mục tiêu của relic-set là 35–60%, nên bù tối đa khoảng từ −0,24 đến +0,29.
2. **Xoay vòng**: mỗi bảng không có hai Nhiệm vụ cùng loại, tối đa 2 loại 5. Hàng đợi xoay 11 archetype cho mỗi archetype xuất hiện đều nhau.
3. **Tự điều chỉnh**: nếu một loại có tỉ lệ thành công thực − dự đoán > +8 điểm trong ≥ 2 tuần, `D_adj` tăng (§2.4). Loại 1 thuận cho burst; 3, 12 thuận cho shield/thorns; 17 thuận DoT; 18, 19 chia cho shield/summon/aoe; 7 thuận build pact. Mỗi archetype có ít nhất 3 loại thuận.

**Ví dụ một bảng (D tính tay, tâm bậc ± 0,15):**

| Slot | Bậc | Nhiệm vụ | D |
|---|---|---|---|
| 1 | T2 (−1,15) | Hạ boss 1 + Không mua sắm (q = 80%) | −1,3 + 0,22 = −1,08 |
| 2 | T3 (−0,40) | Hạ boss 2 + Một nhà: Reptile (q = 85%) | −0,5 + 0,16 = −0,34 |
| 3 | T4 (+0,30) | Thắng Short ở A2 | 0,30 |
| 4 | T5 (+0,90) | Thắng Short A1 + Build Poison ≥ 4 relic (−ln 0,5 + ln(0,47/0,45) = 0,73) | 0,15 + 0,73 = 0,88 |
| 5 | T7 (+2,05) | Thắng Short A5 + Không ai gục (0 KO, q = 25%) | 0,75 + 1,39 = 2,14 |

---

## 5. Bảng mỗi ngày, mua, thời gian, thất bại

### 5.1 Tạo bảng

- **Seed**: `H(ngày UTC, "nv", rules_version)`. **Bảng chung cho mọi người** (khuyến nghị). Lý do: (a) người chơi nói chuyện với nhau về "bảng hôm nay"; (b) không cần RNG theo từng người, nên server kiểm đơn giản và không ai bị "chọn offer" theo kỹ năng, điều dễ thành thao túng; (c) RTP tính được trên toàn bảng.
- **Slot → bậc** (5 offer): slot 1 ∈ {T1, T2}, slot 2 ∈ {T2, T3}, slot 3 ∈ {T3, T4}, slot 4 = T5, slot 5 ∈ {T6, T7} xen kẽ theo ngày chẵn lẻ của seed. Casual luôn thấy 2 offer bậc thấp mỗi ngày; **chỉ có một offer bậc ≥ T6**, nên không thể mua năm T7.
- **Offer bị khoá** (chưa mở Ascension hoặc chưa tới mức Full) vẫn hiện nhưng xám, kèm điều kiện mở khoá, và **không bao giờ** chiếm quá 1 slot bậc thấp (T1–T3). Generator ưu tiên Ascension ≤ 4 cho bậc ≤ T5; A5 trở lên chỉ ở T6–T7.
- **Đổi bảng (reroll): không**, ở bản đầu. Lý do: bảng đã có 5 offer phủ thang; reroll mời người chơi "đào" archetype dễ nhất thay vì chấp nhận giá, và buộc bảng theo người. Có thể thêm sau nếu telemetry thấy người chơi bỏ board vì không có offer hợp.
- **Slot theo Land** (chỉ thêm lựa chọn, không thêm cấp thưởng): nhà Nhiệm vụ mở 5 offer; Land cấp 2 thêm slot 6 (T3), cấp 4 thêm slot 7 (T4), cấp 5 thêm slot 8 (T5). Offer 6–8 lấy từ cùng một danh sách theo seed nên vẫn giống nhau cho mọi người cùng cấp. **Vẫn tối đa 5 lần mua/ngày.** Tôi đề nghị gắn vào "cấp nhà" chứ không vào "cấp Land" nếu Land không có cấp trung gian, câu hỏi cho Liam.

### 5.2 Mua và thời gian

1. **Mua**: người chơi chạm offer, xem màn xác nhận (§7), bấm "Mua". Server trừ stake **ngay** (escrow) trong một transaction, cấp `mission_id`. Cần chưa có Nhiệm vụ nào đang chạy.
2. **Bắt đầu**: một lần bấm "Bắt đầu" (hoặc "Mua và bắt đầu"). Server cấp `run_seed`, `rules_version`, và chuỗi seed xúc xắc. Client dựng run bằng ranked-profile (`run_bonuses(true)` = toàn số 0). **Một Nhiệm vụ = đúng một run.** Run chỉ có một ô lưu như hiện nay, nên cần xong hoặc bỏ run đang dở trước khi bắt đầu.
3. **Hủy trước khi bắt đầu**: hoàn 100% stake, không phí, và slot 5/ngày được trả lại (chưa có rủi ro). Tới 00:00 UTC mà chưa bắt đầu thì tự hủy hoàn tiền (huỷ hệ thống).
4. **Cửa sổ chơi**: sau khi bắt đầu, run phải kết thúc trong **72 giờ** kể từ checkpoint cuối. Quá hạn mà không resume thì tính là bỏ (thua, mất stake). Đủ rộng cho đi xa, vẫn đủ gọn để dọn trạng thái server.
5. **Kết quả**: điều kiện được đánh giá từ replay; **điều kiện hỏng sớm** thì hiện thất bại ngay trong run (§7), run vẫn chạy như run ranked bình thường để lấy Shard run. Trả tiền khi run kết thúc, hoặc khi server verify được tiền tố log nếu điều kiện đã đạt sớm (chưa verify `RunVerifier` có hỗ trợ replay tiền tố; nếu không thì trả khi run kết thúc).
6. **Qua nửa đêm UTC trong run**: Nhiệm vụ vẫn tính cho ngày đã mua.

### 5.3 Bảng định nghĩa thất bại

| Sự kiện | Kết quả | Hoàn stake? | Ghi chú |
|---|---|---|---|
| Đội bị tiêu diệt (thua run) | Thất bại | Không | Mất stake |
| Điều kiện hỏng giữa run | Thất bại ngay, run chạy tiếp như run thường | Không | Hiện lý do ngay |
| Bấm "Bỏ run" (có xác nhận) | Thất bại | Không | Nút ghi rõ "mất stake" |
| Đóng tab / crash / mất điện, quay lại trong 72 giờ | Resume từ checkpoint cuối, tính 1 lần resume | Không đổi | RNG xúc xắc đổi seed (server cấp, ghi log). Tối đa 3 resume mỗi Nhiệm vụ |
| Resume lần thứ 4 | Thất bại | Không | Chặn "thử tới khi may" |
| Quá 72 giờ không resume | Thất bại (bỏ) | Không | |
| Mất mạng giữa run | Chơi tiếp offline, log đồng bộ khi có mạng; xúc xắc đã có seed của trận | Không đổi | Cần mạng ở đầu trận (xem §6). Chờ nộp tới 7 ngày, quá thì thất bại |
| Đổi thiết bị | Resume được ở máy mới từ checkpoint đã đồng bộ, tính 1 resume; máy cũ bị vô hiệu | Không đổi | Chỉ máy có `session_epoch` mới nhất được nộp |
| Đăng xuất giữa run | Run tạm dừng, resume khi đăng nhập lại **cùng tài khoản** | Không đổi | |
| Đổi `rules_version` / `content_version` khi đang chạy | **Hủy hệ thống**, Nhiệm vụ vô hiệu | **Có, 100%** | Log không replay được (đúng như `run_verifier.gd`: không phải gian lận). Không có Stone. Chỉ hoàn nếu checkpoint cuối chưa ghi thất bại |
| Lỗi server / replay sập (không phải lỗi người chơi) | Hủy hệ thống | **Có**, qua công cụ hỗ trợ | Ghi vào log kiểm toán |
| Verify thất bại do log bị sửa | Thất bại + gắn cờ | Không | Xem §6 |

---

## 6. Tính toàn vẹn

### 6.1 Luồng

1. **Mua**: server kiểm bảng ngày (tính lại từ seed), số dư, hạn 5/ngày, chưa có Nhiệm vụ đang chạy. Trừ stake, ghi `mission_purchases` (D1), idempotency key.
2. **Bắt đầu**: server cấp `run_seed` (map, thẻ thưởng, shop, event vẫn tất định theo seed như quyết định Liam) và một **seed xúc xắc cho từng trận**, phát lúc bắt đầu trận (cần mạng ở đầu mỗi trận, khoảng 12 yêu cầu nhỏ cho một run Short).
3. **Checkpoint**: cuối mỗi trận, client đẩy đoạn ActionLog mới cùng hash chuỗi. Server lưu.
4. **Resume**: client gửi checkpoint cuối; server so hash, cấp **seed xúc xắc mới**, ghi action `resume {seed, index}` vào log. Lệch hash → từ chối.
5. **Kết thúc**: client nộp log đầy đủ. Server replay bằng `RunVerifier`, **tính lại mọi counter và điều kiện từ replay** (không đọc counter client), rồi mới trả (Shard và Stone, idempotent, một transaction với đóng Nhiệm vụ).

### 6.2 Cái gì được kiểm

- Seed trùng với seed đã cấp; mọi `resume` có seed đã cấp, đúng thứ tự, ≤ 3 lần.
- `rules_version`/`content_version` khớp.
- Mọi action hợp lệ (đã có trong `RunVerifier`, bộ relic thêm `reorder_party`, `sell_relic`, `tweak`...).
- Kết quả run và các counter của điều kiện, tính từ replay.
- Profile ranked: unlock cộng chỉ số = 0 (assert `run_bonuses(true)` toàn 0 ở đầu replay).
- Thời gian hợp lý: sàn thời gian tối thiểu một run (đo sau từ telemetry), gắn cờ run nhanh bất thường.

### 6.3 Lỗ save-scum và cách đóng

Quy tắc resume đã chốt (RNG xúc xắc đổi seed, trạng thái giữ nguyên) làm mất ý nghĩa của "load lại cho đến khi xúc xắc đẹp". Còn lại hai khe, và cách tôi xử lý:
- **Kill app trước checkpoint để thử lại lượt vừa rồi.** Checkpoint chỉ cập nhật cuối trận, nên hành động giữa trận chưa ghi lên server có thể bị "hoàn tác" bằng cách kill app và resume (xúc xắc mới). Giới hạn bằng **ngân sách 3 resume** và ghi mỗi lần vào log; mỗi lần chỉ hoàn tác tối đa một trận. Chấp nhận phần dư này, theo dõi tỉ lệ resume và tỉ lệ thành công sau resume (§8) để thấy có bị lạm dụng không.
- **Client sửa đổi tính trước xúc xắc.** Vì seed của trận biết được phía client, client độc hại có thể mô phỏng trước các lần reroll trong trận đó. Replay chỉ chứng minh **hợp lệ**, không chứng minh **người chơi thật** (cùng giới hạn với leaderboard hiện nay). Giảm bằng seed theo trận (không biết trận sau), và phát hiện thống kê: tỉ lệ reroll "hoàn hảo" bất thường, thời gian phản hồi không thể là người. Nếu lạm dụng thực sự xuất hiện thì đổi sang xúc xắc do server roll từng lượt. Tôi **không** làm sẵn vì tốn mạng; ghi vào câu hỏi mở.

### 6.4 Các trường hợp lạm dụng khác

| Trường hợp | Phản ứng |
|---|---|
| Nhiều tài khoản cày Stone bậc thấp | Stone ≤ 130/ngày/tài khoản và Shard RTP < 1, nên lỗ. Không cần chặn. Rate-limit mua theo IP/tài khoản |
| Mua rồi hủy liên tục | Rate-limit 20 lần/giờ; hoàn tiền không có phí nhưng không có lợi |
| Chờ cập nhật để lấy hoàn tiền | Chỉ hoàn nếu checkpoint cuối chưa ghi thất bại |
| Hai thiết bị cùng lúc | `session_epoch`: chỉ lần nộp có epoch mới nhất được nhận |
| Chỉnh đồng hồ | Server chỉ dùng giờ UTC của nó |
| Người chơi giỏi chơi hộ (boosting) | Không phát hiện được; giá trị thấp vì RTP ≤ 1 và Stone nhỏ. Bỏ qua |
| Tài khoản bị khóa hoặc đóng băng khi đang có Nhiệm vụ | Stake giữ nguyên trong escrow tới khi giải quyết |

**Phụ thuộc chưa verify**: (1) server có phải nơi giữ số dư Shard chính thức không (escrow cần), hay cloud save chỉ là ảnh chụp; (2) `RunVerifier` có xuất counter điều kiện hay chỉ kết quả; (3) tiền tố log; (4) run seed hiện sinh ở client hay đã có đường server cấp.

---

## 7. UX

*(Cần mockup mới trước khi làm UI, theo quy trình của Liam: Claude viết request cho Claude Design.)*

**Nhà Nhiệm vụ (bảng).** 5 thẻ (tới 8), sắp theo bậc. Mỗi thẻ hiện: tên + câu điều kiện ngắn ("Hạ boss 2 và không mua gì ở shop"), huy hiệu bậc (T1–T7), **stake**, **trả khi thắng** (gồm stake), **lãi khi thắng**, Stone, và hai dòng xác suất:
- **Tỉ lệ của người chơi gần đây**: "28% người chơi thành công trong 14 ngày qua" (số đo từ telemetry).
- **Ước tính cho bạn**: "30–40%" (từ `p̂ = σ(θ̂_i − D)` với θ̂ của chính người đó; hiện dạng khoảng, làm tròn 5). Cần ≥ 10 run ranked-profile; chưa đủ thì ghi "chưa đủ dữ liệu".
Đầu bảng: "Hôm nay còn 3/5 lần mua", đồng hồ tới reset UTC (số tĩnh, không nhấp nháy, không màu đỏ).

**Xác nhận mua.** Một sheet ba dòng: "Bạn trả **500** Shard. Thắng: nhận **950** (+450) và 16 Stone. Thua hoặc bỏ giữa chừng: **mất 500, không hoàn**." Dòng thứ tư nhỏ hơn: "Với tỉ lệ ước tính của bạn, kỳ vọng nhận lại khoảng 80% số bạn trả." Nút ghi **"Mua, mất stake nếu thất bại"**. Cảnh báo thông tin (không chặn) khi tổng stake mở của ngày > 50% thu nhập tuần ước tính của người đó.

**Trong run.** Một chip góc màn hình: "Nhiệm vụ: Hạ boss 2, không mua sắm" cùng trạng thái xanh (đang đạt), vàng (có nguy cơ), đỏ (đã hỏng). Số đếm liên quan (turns, KO, relic...) từ counter client. Điều kiện hỏng thì hiện **một lần**, bằng chữ, nói đúng lý do và nói "run vẫn tiếp tục như run thường". Không rung, không âm "thua".

**Kết quả.** Liệt kê từng điều kiện kèm đạt/không, số liệu cụ thể ("Lượt: 34 / giới hạn 36"), stake, tiền nhận, Stone. Số Shard của chính run (R) tách riêng để không lẫn. Thắng: gọn, không pháo hoa lớn hơn thắng run thường.

**Màn thua.** Giọng trung tính, cụ thể, không đổ lỗi, không an ủi giả: "Nhiệm vụ không đạt. Điều kiện hỏng ở trận 7: có 3 Axie bị KO. Mất 500 Shard." **Không** có dòng "suýt thắng", không nút "mua lại ngay", không giảm giá. Hai nút ngang hàng: "Về nhà Nhiệm vụ" và "Chơi run thường". Không popup nào hối thúc mua tiếp.

**Cách ly với cờ bạc**: không bao giờ hiện số tiền "đã thắng/thua" dạng tổng liên tục kiểu sòng bạc; có một trang lịch sử trong nhà Nhiệm vụ, người chơi tự mở.

---

## 8. Telemetry: người chơi có chấp nhận risk-to-earn không?

**Thời gian**: soft launch ≥ 4 tuần. Quyết định chỉ sau khi mỗi nhánh có ≥ 2.000 lượt xem bảng.

**Nhóm 1, tiếp nhận.** % DAU mở bảng; % người mua ≥ 1 mỗi tuần; số lần mua/ngày của người mua; stake/ngày so với thu nhập Shard ngày.

**Nhóm 2, khẩu vị rủi ro.** Phân phối bậc đã mua so với bậc có mặt trên bảng; **tỉ lệ nâng bậc** (mua bậc cao hơn trong 7 ngày sau khi thắng); **chỉ số đuổi theo** (mua bậc cao hơn hoặc stake lớn hơn trong cùng phiên sau khi thua); tỉ lệ người chỉ mua T1–T2 sau lần thua đầu.

**Nhóm 3, hậu quả.** Giữ chân D1/D7/D30 của người mua so với người không mua (ghép theo thu nhập Shard và số ngày chơi); thời gian quay lại sau chuỗi 3 thua liên tiếp; tỉ lệ bỏ run ngay sau khi điều kiện hỏng; tỉ lệ hủy trước khi bắt đầu; vé Echo Box/ngày của người mua so với người không (thay thế vé).

**Nhóm 4, sức khỏe hệ thống.** RTP thực theo bậc, persona, và 28 ngày; p99 lãi ròng 28 ngày; sai lệch dự đoán `|p quan sát − p dự đoán|` theo loại; Stone/ngày thực so với 150; tỉ lệ resume và tỉ lệ thành công sau resume; số lần gắn cờ verify.

**Dashboard**: (1) phễu mở bảng → mua → bắt đầu → xong; (2) thang bậc: mua/thắng/RTP; (3) hiệu chỉnh: p dự đoán so với thực mỗi loại; (4) lạm dụng: resume, thời gian run, cờ.

**Ngưỡng quyết định (đề xuất, chỉnh sau khi thấy số):**

| Chỉ số | Xanh (mở rộng: thêm Stone, thêm bậc) | Vàng (chỉnh) | Đỏ (rút lại) |
|---|---|---|---|
| WAU mua ≥ 1 lần (tuần 2–4) | ≥ 25% | 10–25% | < 10% |
| Người mua nâng bậc trong 14 ngày | ≥ 35% | 15–35% | < 15% |
| Retention D30 người mua − không mua | ≥ −2 điểm | −2 đến −5 | < −5 |
| Quay lại ≤ 3 ngày sau chuỗi 3 thua (so với nền) | ≥ 70% nền | 50–70% | < 50% |
| Chỉ số đuổi theo | ≤ 15% | 15–30% | > 30% |
| RTP toàn dân 28 ngày | 0,85–0,97 | 0,97–1,00 | > 1,00 (tự giảm `m_scale`) |
| p99 lãi ròng 28 ngày | ≤ 20% thu nhập | 20–35% | > 35% |

Cách đọc: **xanh** = người chơi chấp nhận risk-to-earn và không bị hại. **Vàng** thường nghĩa là cách trình bày chưa tốt (đọc kỹ nhóm 3 trước khi sửa giá). **Đỏ** về retention hoặc đuổi theo thì rút lại, bất kể doanh số. Thử nghiệm A/B chỉ trên `stone_scale` (1× so với 2,5×) và cách xếp bảng, **không** thử nghiệm "ẩn xác suất"; hiển thị xác suất là tiêu chuẩn.

---

## 9. Núm, bất biến, nghiệm thu, câu hỏi mở

### 9.1 Núm (mọi số trong `assets/data/` hoặc cấu hình server, không hardcode)

| Núm | Mặc định | Khoảng | Loại | Lý do |
|---|---|---|---|---|
| `tier_stake[7]` | 100/200/350/500/800/1.200/1.800 | ±30%/bậc | Curve | Stake/R 0,22–4,0 ở R = 450 |
| `tier_m[7]` | 1,20/1,35/1,60/1,90/2,25/2,70/3,40 | `0,95/p_ref` | Curve | RTP tham chiếu 0,95 |
| `tier_stone[7]` | 3/6/10/16/24/34/50 | ×0,5–×2,5 | Curve | Tổng kiểm ≤ 130/ngày |
| `tier_D_center[7]` | −1,95/−1,15/−0,40/0,30/0,90/1,45/2,05 | | Curve | Từ p_ref |
| `m_scale[7]` | 1,0 | 0,85–1,0 | Curve | Hạ giá nếu RTP > 1 (server) |
| `stone_scale` | 1,0 | 1–2,5 | Gate | A/B và tăng sau |
| `eps_D` | 0,15 | 0,10–0,25 | Feel | Độ khít bậc |
| `buy_cap_day` | 5 | Liam chốt | Gate | |
| `board_size_by_land` | 5/5/6/6/7/8 | 5–8 | Gate | Chỉ thêm lựa chọn |
| `top_tier_per_day` | 1 | 1–2 | Gate | Chặn cày bậc cao |
| `resume_budget` | 3 | 1–5 | Gate | Cân crash và save-scum |
| `play_window_hours` | 72 | 24–168 | Gate | |
| `submit_grace_days` | 7 | 3–14 | Gate | Mất mạng |
| `phat_min_runs` | 10 | 5–20 | Feel | Gợi ý cá nhân |
| `calib_shrink_k` | 200 | 100–500 | Curve | Hiệu chỉnh D |
| `d_asc_per_level` | 0,15 | 0,10–0,20 | Curve | Thay bằng sim G |
| `mission_stone_day_cap` | 150 | 100–200 | Gate | ECO-12 |

### 9.2 Bất biến (tiền tố NV)

| # | Bất biến |
|---|---|
| NV-1 | Stake trừ nguyên tử lúc mua; trả thưởng chỉ sau verify server; không bao giờ vừa hoàn vừa trả |
| NV-2 | `tier_stake`, `tier_m`, `tier_stone`, `tier_D_center` tăng nghiêm ngặt theo bậc; payout = `round5(stake × m × m_scale)` |
| NV-3 | Stone chỉ trả khi thắng; tối đa ≤ 150/ngày/tài khoản; Stone tối đa của bảng ≤ 150 theo cấu trúc (106 / 130) |
| NV-4 | ≤ `buy_cap_day` lần mua mỗi ngày UTC; mỗi offer mua một lần; hủy trước khi bắt đầu trả lại slot |
| NV-5 | Thất bại không hoàn, trừ ba trường hợp: hủy trước bắt đầu, hết hạn trước bắt đầu, hủy hệ thống (đổi `rules_version`, lỗi server) |
| NV-6 | Bảng = hàm của (ngày UTC, `rules_version`, cấp nhà); giống nhau cho mọi người cùng cấp |
| NV-7 | Mọi run Nhiệm vụ dùng ranked-profile, `run_bonuses(true)` toàn 0 |
| NV-8 | RTP toàn dân 28 ngày ≤ 0,97 cảnh báo; > 1,00 tự động giảm `m_scale` bậc có RTP cao nhất |
| NV-9 | Mỗi offer có `|D − tâm bậc| ≤ eps_D` |
| NV-10 | Không có Nhiệm vụ bất khả thi hoặc miễn phí (validator §2.1) |
| NV-11 | Kết quả và counter chỉ tính từ replay server |
| NV-12 | Không loại Nhiệm vụ nào đòi đổi relic, hook, hay luật; chỉ đọc dữ liệu đã có hoặc 5 counter mới |
| NV-13 | Không "gấp đôi hoặc mất hết", không giảm giá mua lại sau thua, không hiệu ứng suýt thắng |

### 9.3 Tiêu chí nghiệm thu

**Chức năng (test tự động):**
1. Mua → trừ đúng stake, hủy trước bắt đầu hoàn đúng, mua lần 6 trong ngày bị từ chối.
2. Bảng cùng ngày cùng cấp là cùng một danh sách trên hai tài khoản; đổi `rules_version` thì danh sách đổi.
3. 100.000 bảng sinh ngẫu nhiên: mọi offer `|D − tâm| ≤ eps_D`, không loại trùng, bậc ≥ T6 đúng 1 offer, Stone tối đa của bảng ≤ 130.
4. Replay run Nhiệm vụ: server tính đúng điều kiện của 19 loại trên run mẫu (đạt và không đạt); tamper (đổi counter, đổi seed, resume lần 4, log lệch hash) đều thất bại.
5. Đổi `rules_version` giữa run → hoàn 100%, không Stone.
6. Resume: seed xúc xắc mới có trong log, hai lần resume từ cùng checkpoint cho hai chuỗi xúc xắc khác nhau.
7. Counter mới sống sót qua resume (test trên `RunState`).
8. Sim 100.000 lần mua theo bảng §3.3: RTP mỗi persona nằm trong ±0,02 của bảng.

**Trải nghiệm (playtest):**
1. 8 người chơi thử, ≥ 7 giải thích đúng "mất gì nếu thua, nhận gì nếu thắng" chỉ từ màn xác nhận.
2. Không ai nói màn thua "đổ lỗi" hoặc "dụ mua tiếp".
3. Sau 4 tuần soft launch, telemetry §8 nằm ở xanh hoặc vàng ở mọi hàng, không có đỏ.

### 9.4 Câu hỏi mở cho Liam

| # | Câu hỏi | Đề xuất |
|---|---|---|
| 1 | Ascension có chạy trong run ranked/Nhiệm vụ không (câu 10 của ascension-v2 để tới bước ranked)? Loại 15 và nhiều ví dụ phụ thuộc | Có, header `ascension` đã có và replay kiểm được. Nếu không, tắt loại 15 bằng cờ; thang vẫn chạy bằng điều kiện |
| 2 | Số dư Shard có được server giữ làm chuẩn (cần cho escrow) không? | Có, ít nhất cho phần escrow Nhiệm vụ: server là nguồn đúng của số dư |
| 3 | Run Nhiệm vụ vẫn trả R như run ranked thường? Có tính bảng xếp hạng ranked không? | Trả R như thường. Bảng xếp hạng: có (nó đã là ranked-profile) |
| 4 | Dòng "kỳ vọng nhận lại ~80%" trong màn xác nhận: hiện hay không? | Hiện, vì nó là sự thật và Liam muốn kiểm tra chấp nhận rủi ro thật; ẩn thì kết quả telemetry bị méo |
| 5 | Cảnh báo thông tin khi tổng stake mở > 50% thu nhập tuần (không phải trần)? | Có. Liam đã bỏ trần; cảnh báo không chặn nên không đi ngược quyết định |
| 6 | Đổi bảng (reroll): có không? | Không ở bản đầu; thêm sau nếu thấy người chơi bỏ bảng vì không có offer hợp |
| 7 | Bảng chung hay riêng từng người? | Chung (§5.1) |
| 8 | Ngân sách resume 3 lần và seed xúc xắc theo trận, đổi sang xúc xắc roll bằng server khi có lạm dụng | 3 lần, seed theo trận. Xúc xắc roll bằng server chỉ khi có bằng chứng lạm dụng |
| 9 | Stone 3–50 (kỳ vọng < 1% Stone tuần) có "rất nhỏ" đủ ý Liam không, hay quá nhỏ? | Ra mắt ở 1,0 rồi nâng `stone_scale` theo telemetry; ngân sách 150/ngày cho phép tới ×2,5 |
| 10 | Người cực giỏi (80% thắng run) có thể kiếm ≈ +1.000 Shard/ngày; có chấp nhận không? | Chấp nhận bản đầu, giám sát p99, `m_scale` giảm nếu cần. Không đặt trần thắng vì trái tinh thần "muốn kiếm nhiều phải chịu khó" |
| 11 | Mode Full làm Nhiệm vụ không? | Bản đầu chỉ Short (run ngắn, hiệu chỉnh rẻ). Full thêm sau ở T6–T7, và cần mở khoá `u_full` |
| 12 | Nhà Nhiệm vụ gắn "cấp Land" hay "cấp nhà riêng"? Land chỉ có 5 lần nâng | Gắn cấp nhà riêng nếu Land không đủ cấp trung gian; Liam quyết |

Phụ thuộc vào công việc khác: bộ relic (hook `relic_state`, action `reorder_party`/`sell_relic`), resume rule (đang làm cùng combat), sim A và G (chưa chạy), ánh xạ run seed phía server (chưa verify).
