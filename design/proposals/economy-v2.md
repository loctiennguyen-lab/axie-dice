Trạng thái: ĐỀ XUẤT — chờ Liam review

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
> - **Thời gian tới LunaLanding (Liam chấp nhận 10/10):** regular ~1,5 năm, casual ~1,9 năm, heavy ~1 năm. Không thêm catch-up ở bản đầu (`final_stretch` để tắt).
> - Danh sách A (10/10): A2 giá unlock ×3 đồng ý; A3/A4 Pass có vòng lặp mốc sau lv30 trả Shard nhỏ (kiểu LoL),
>   XP dư không bỏ; A8 mua vé ngày không chơi; A9 Stone guest chờ 7 ngày; A10 Echo Market hoãn; A11 vé bundle
>   ra Stone, KHÔNG tính giới hạn 20 lượt/ngày. Chi tiết ở đầu `echobox-pass-v2.md`.
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


# Axie Dice — Economy v2 (bản hợp nhất: Shard, Land Stone, Vé Echo Box, Pass, Thưởng ngày)

Tác giả: economy-designer · 10/10/2026 · Chỉ sửa file này, không có code.
Cấu trúc cơ chế lấy từ `echobox-pass-v2.md` (game-designer). Số cuối là của tôi. Mọi số là first-pass, tính tay, **chưa qua sim**. Số nào lệch với file của game-designer thì tôi ghi rõ ở §0.3.

---

## 0. Đọc nhanh

### 0.1 Kết quả

1. **Với số đề xuất, thời gian tới LunaLanding (1.820.000 Stone):** heavy **51,6 tuần (~11,9 tháng)**, regular **77,9 tuần (~1,5 năm)**, casual **98,3 tuần (~1,9 năm)**. Heavy khớp mục tiêu 1 năm của Liam.
2. Echo Box là nguồn Stone chính: 66% (casual), 67% (regular), 79% (heavy) tổng Stone/tuần.
3. **Cửa sổ Stone 20 lượt/ngày chỉ khóa heavy.** Regular và casual không bao giờ chạm 20, nên đổi núm này chỉ đổi thời gian của heavy.
4. **Giá bậc thang theo ngày nén chênh lệch giữa các nhóm**: heavy kiếm gấp 3,5 lần Shard của casual nhưng chỉ nhanh hơn ~1,9 lần về Land. Đó là chủ ý (xem §2.4 và OQ-1).
5. Không có vòng lặp salvage: tối đa 0,265 vé hồi mỗi lượt quay, nên 1 vé mua được tối đa 1,36 lượt (§3.5).
6. Pass: heavy xong sau **14–14,7 ngày**. Phát hiện một lỗi nhỏ trong file game-designer (§0.3).
7. Mọi nhóm bình thường không bao giờ hết Shard (không có chi phí bắt buộc). Chỗ yếu duy nhất: heavy giỏi, nếu dừng ở đúng 20 lượt/ngày sẽ tồn ~235.000 Shard sau 6 tháng (§6, OQ-2).

### 0.2 Giả định

| # | Giả định | Nguồn |
|---|---|---|
| A1 | R = 450 Shard/run (short, đã trừ shop trong run, **không** gồm +60 daily). Độ nhạy 350 / 570 | Probe: ~568 thắng trọn, ~336 bot, ~854 full |
| A2 | Casual: mở game 4 ngày/tuần, 3 run/ngày (12 run/tuần), thắng ~45%. Regular: 7 ngày, 2 run/ngày (14). Heavy: 7 ngày, 8 run/ngày (56), thắng ~75%. Cả ba dùng R = 450 cho dễ so | Brief + A3 bản cũ |
| A3 | Người chơi tiêu hết Shard mỗi ngày vào vé, chia đều qua các ngày mở game (đây là cách rẻ nhất vì bậc giá reset hằng ngày) | Tối ưu của ladder lồi |
| A4 | Pool Echo 255 món: 61 / 55 / 47 / 39 / 31 / 22 (Common→Mythic), quay theo luật không-lặp | `echobox-pass-v2.md` §2.3, số ước |
| A5 | Pity "cứng" nâng đúng độ hiếm bảo đảm (lượt 15 → Rare, 60 → Epic, 200 → Legendary, 1.000 → Mythic) khi lượt đó tự nhiên thấp hơn | Quy ước của tôi |
| A6 | XP run: thắng ~506, thua ~190 → 332 XP/run (45% thắng), 427 (75%) | A4 bản cũ |
| A7 | Tuần = tuần UTC, reset thứ Hai 00:00. 1 tháng = 4,345 tuần | |
| A8 | Cả ba nhóm làm xong Pass mỗi mùa (8 tuần) nên Pass cộng bình quân 1/8 mỗi tuần | §4 |
| A9 | Tách mảnh xảy ra ngay lúc quay, tồn dư mảnh (<10) bỏ qua | |

### 0.3 Chỗ tôi lệch với `echobox-pass-v2.md`

| Mục | Game-designer | Tôi | Lý do |
|---|---|---|---|
| Tuần tới Luna (heavy / regular / casual) | 54 / 100 / 121 | **51,6 / 77,9 / 98,3** | Tôi cộng vé salvage (+20–30% lượt quay, vì đồ trùng chỉ có sau khi đủ độ hiếm) và tính số vé mua từ ngân sách Shard thật (regular 8,76 vé/ngày, không phải 8 hay 56 lượt/tuần cố định) |
| XP run heavy | 8 run = 3.416 XP thô "bị cắt còn 2.000" | **1.883** | Luật "1.500 đầu 100%, sau đó 20%": 1.500 + 0,2 × (3.416 − 1.500) = 1.883, chưa chạm trần 2.000. Heavy 8 run/ngày xong Pass ở 14,7 ngày. Chạm 2.000 phải ≥ 9,4 run/ngày |
| Tổng cộng dồn 5 vé đầu | 545 | 552,6 (công thức) / 550 (cộng giá làm tròn) | Lỗi cộng |
| E (Stone/lượt) | 180,1, nói pity thêm 8–12% | **E_eff ≈ 199** (+10,5%) | Tính cụ thể ở §3.2 |

Cấu trúc giữ nguyên: vé + mảnh, giá bậc thang theo ngày, cửa sổ Stone, không-lặp, pity theo lượt, Pass 30 level có trần XP/ngày.

---

## 1. Bản đồ currency

### 1.1 Gene Shard

| Faucet | Số cuối | Ghi chú |
|---|---|---|
| Run | R ≈ 450/run (thắng ~568, thua ~258) | A1 |
| Thưởng ngày | 60/ngày (hoàn thành 1 run) | |
| Thưởng tuần | 150 (≥ 4 ngày nhận trong tuần UTC) | |
| Pass | 4.800/mùa 8 tuần = 600/tuần | §4 |
| Nhiệm vụ | Tổng thể ≤ 100% stake (không phải faucet ròng) | Ngân sách §5 |
| Echo Box | **0**. Quay vé và salvage không bao giờ cộng Shard | ECO-3 |

| Sink | Số cuối |
|---|---|
| Mua vé Echo | giá vé thứ k trong ngày UTC = `round5(100 × 1,05^(k−1))`, tối đa 30 vé mua/ngày |
| Stake Nhiệm vụ | thiết kế sau |
| Shop trong run | giữ nguyên, đã nằm trong R |
| Unlock shop một lần | 10.350 (giá cũ ×3, `economy` bản trước; 5 unlock chỉ số nhận miễn phí ở Pass S1) |

### 1.2 Land Stone

| Faucet | Số cuối |
|---|---|
| Lượt quay Echo | Stone theo độ hiếm: 80 / 160 / 400 / 1.000 / 2.500 / 8.000, chỉ **20 lượt đầu mỗi ngày UTC** |
| Thưởng ngày | 500/ngày |
| Thưởng tuần | 2.000 (≥ 4 ngày) |
| Pass | 16.500/mùa = 2.062,5/tuần |
| Nhiệm vụ | ≤ 150/ngày hoạt động (§5) |

| Sink | Số |
|---|---|
| Nâng Land | 40.000 / 100.000 / 180.000 / 500.000 / 1.000.000 = **1.820.000** (cộng dồn 40k / 140k / 320k / 820k / 1.820k) |
| Sau LunaLanding | Ngoài phạm vi (Liam làm) |

Stone không đổi sang Shard, không mua trực tiếp bằng Shard. Đường duy nhất Shard → Stone là vé Echo.

### 1.3 Vé và mảnh

| | Faucet | Sink |
|---|---|---|
| Vé | Mua Shard (≤30/ngày), salvage (10 mảnh = 1 vé), Pass 12/mùa (1,5/tuần), quà khởi đầu 3, bundle sau này | 1 lượt quay |
| Mảnh | Đồ trùng: 1 / 2 / 5 / 15 / 40 / 100 mảnh (Common→Mythic) | Tự gộp 10 → 1 vé |

Vé/mảnh không đổi ngược ra Shard hay Stone. Vé từ salvage, Pass, bundle không làm tăng bậc giá nhưng **có** tính vào cửa sổ Stone 20.

---

## 2. Persona và timeline Land

### 2.1 Thu nhập Shard mỗi tuần và vé mua được

Thu nhập tuần = run + thưởng ngày + thưởng tuần + Pass.

| | Casual | Regular | Heavy |
|---|---|---|---|
| Run | 12 × 450 = 5.400 | 14 × 450 = 6.300 | 56 × 450 = 25.200 |
| Thưởng ngày | 4 × 60 = 240 | 7 × 60 = 420 | 420 |
| Thưởng tuần | 150 | 150 | 150 |
| Pass (4.800/8) | 600 | 600 | 600 |
| **Shard vào/tuần** | **6.390** | **7.470** | **26.370** |
| Shard/ngày mở game | 6.390 / 4 = 1.597 | 7.470 / 7 = 1.067 | 26.370 / 7 = 3.767 |

Tổng chi phí n vé trong một ngày: `C(n) = 100 × (1,05^n − 1) / 0,05 = 2.000 × (1,05^n − 1)`.

| n | 1,05^n | C(n) | Giá vé thứ n | C(n)/n |
|---|---|---|---|---|
| 8 | 1,4775 | 954,9 | 140 | 119,4 |
| 10 | 1,6289 | 1.257,8 | 155 | 125,8 |
| 12 | 1,7959 | 1.591,7 | 170 | 132,6 |
| 15 | 2,0789 | 2.157,9 | 200 | 143,9 |
| 20 | 2,6533 | 3.306,6 | 255 | 165,3 |
| 22 | 2,9253 | 3.850,5 | 280 | 175,0 |
| 25 | 3,3864 | 4.772,7 | 325 | 190,9 |
| 30 | 4,3219 | 6.643,9 | 410 | 221,5 |

(Bảng tính bằng công thức liên tục. Làm tròn từng vé về bội 5 lệch dưới 1% tổng.)

Giải `C(n) = Shard/ngày`:

| Persona | Phép tính | Vé/ngày | Vé mua/tuần | Shard tiêu/tuần |
|---|---|---|---|---|
| Casual | 1,05^n = 1 + 1.597/2.000 = 1,799 → n = 0,5873 / 0,04879 = **12,0** | 12 | 48 | 4 × 1.591,7 = 6.367 |
| Regular | 1,05^n = 1 + 1.067/2.000 = 1,533 → n = **8,76** (5,3 ngày mua 9, 1,7 ngày mua 8) | 8,76 | 61,3 | 7.470 |
| Heavy | 1,05^n = 1 + 3.767/2.000 = 2,884 → n = 1,0593 / 0,04879 = **21,7** | 21,7 | 152 | 26.370 |

Cộng vé Pass 12/8 = 1,5/tuần. Giá vé không chạm trần mua 30 (heavy cần 21,7; để chạm 30 phải có 6.644 Shard/ngày = 46.500/tuần).

Ghi chú: mở game vào ngày không chơi run vẫn mua được vé. Casual mở game 7 ngày thay vì 4 sẽ mua 6.390/7 = 913/ngày → 7,9 vé/ngày = 55 vé/tuần (+15%). Đó là thưởng cho thói quen mở game hằng ngày, tôi giữ.

### 2.2 Số lượt quay thật: salvage

Với luật không-lặp, đồ trùng chỉ xuất hiện sau khi đủ độ hiếm đó. Số lượt để đủ từng độ hiếm = số món / tỉ lệ hiệu dụng (§3.2):

| Độ hiếm | Món | Tỉ lệ hiệu dụng | Lượt quay tới khi đủ |
|---|---|---|---|
| Common | 61 | 0,602 | 101 |
| Uncommon | 55 | 0,243 | 226 |
| Rare | 47 | 0,113 | 416 |
| Epic | 39 | 0,0316 | 1.234 (làm tròn 1.230) |
| Legendary | 31 | 0,009 | 3.444 |
| Mythic | 22 | 0,00158 | ~13.900 |

Mỗi lượt sau khi đủ độ hiếm đó trả về `tỉ lệ × mảnh / 10` vé:

| Độ hiếm | Mảnh trùng | Vé hồi/lượt (hiệu dụng) |
|---|---|---|
| Common | 1 | 0,602 × 1 / 10 = 0,0602 |
| Uncommon | 2 | 0,243 × 2 / 10 = 0,0486 |
| Rare | 5 | 0,113 × 5 / 10 = 0,0565 |
| Epic | 15 | 0,0316 × 15 / 10 = 0,0474 |
| Legendary | 40 | 0,009 × 40 / 10 = 0,0360 |
| Mythic | 100 | 0,00158 × 100 / 10 = 0,0158 |
| **Tổng khi đủ hết** | | **0,265** |

Hệ số hồi ν theo tiến độ: 0 (dưới 101 lượt) → 0,060 → 0,109 → 0,165 (sau 416) → 0,213 (sau 1.230) → 0,249 (sau 3.444). Tổng số lượt = vé gốc / (1 − ν).

Tổng số lượt `N` mỗi persona (b = vé mua + Pass mỗi tuần; N' = b / (1 − ν)):

| | Casual (b = 49,5) | Regular (b = 62,8) | Heavy (b = 153,5) |
|---|---|---|---|
| Đủ Common (t, tuần) | 2,0 | 1,6 | 0,7 |
| Đủ Rare | 7,8 | 6,2 | 2,5 |
| Đủ Epic | 21,6 | 17,0 | 7,0 |
| Đủ Legendary | 56,8 | 44,8 | 18,3 |
| Lượt/tuần cuối cùng | 65,9 | 83,6 | 204 |
| **Lượt/tuần TB năm 1** | **60,5** | **77,9** | **~199** (chỉ 140 có Stone) |

Phép tính mẫu casual, đoạn Epic (N từ 416 tới 1.230): tốc độ = 49,5 / (1 − 0,165) = 59,3 lượt/tuần; 814 / 59,3 = 13,7 tuần.

### 2.3 Stone mỗi tuần

E_eff dùng làm tròn xuống 198 (giá trị tính được 199, chi tiết §3.2).

| Nguồn/tuần | Casual | Regular | Heavy |
|---|---|---|---|
| Echo (năm 1, TB) | 60,5 × 198 = 11.979 | 77,9 × 198 = 15.424 | **140** × 198 = 27.720 |
| Thưởng ngày | 4 × 500 = 2.000 | 3.500 | 3.500 |
| Thưởng tuần | 2.000 | 2.000 | 2.000 |
| Pass 16.500 / 8 | 2.062,5 | 2.062,5 | 2.062,5 |
| Nhiệm vụ | 0 (§5) | 0 | 0 |
| **Stone/tuần (năm 1)** | **18.041** | **22.987** | **35.282** |
| Tỉ lệ Echo | 66% | 67% | 79% |
| Tỉ lệ thưởng ngày + tuần | 22% | 24% | 16% |
| Tỉ lệ Pass | 11% | 9% | 6% |

Heavy bị cửa sổ cắt: 28 lượt/ngày thật nhưng chỉ 20 có Stone. Không có cửa sổ, heavy được 199 × 198 = 39.400 Stone Echo/tuần và tới Luna sau (39.400 + 7.562) → 1.820.000 / 46.962 = **38,8 tuần**, nghĩa là cửa sổ kéo heavy từ 38,8 lên 51,6 tuần.

Sau khi đủ Legendary, tốc độ ổn định: casual 65,9 × 198 + 6.062,5 = **19.110**, regular 83,6 × 198 + 7.562,5 = **24.117**.

### 2.4 Timeline Land

Heavy (hằng số 35.282/tuần): mỗi mốc = cộng dồn / 35.282. Ví dụ Luna: 1.820.000 / 35.282 = 51,6.
Casual/regular: cộng dồn theo từng đoạn salvage. Ví dụ casual: đoạn 1 (2,0 tuần) 15.863 × 2,04 = 32.361; đoạn 2: 16.491 × 2,37 = 39.084; đoạn 3: 17.059 × 3,42 = 58.342; đoạn 4: 17.803 × 13,73 = 244.436; đoạn 5: 18.514 × 35,20 = 651.693 → cộng dồn 1.025.916 tại tuần 56,76; còn lại 794.084 / 19.110 = 41,55 → **98,3 tuần**.

| Bước | Stone | Cộng dồn | Casual | Regular | Heavy |
|---|---|---|---|---|---|
| Savannah → Forest | 40.000 | 40.000 | 2,5 tuần | 2,0 | 1,1 |
| Forest → Arctic | 100.000 | 140.000 | 8,4 | 6,7 | 4,0 |
| Arctic → Mystic | 180.000 | 320.000 | 18,5 | 14,7 | 9,1 |
| Mystic → Genesis | 500.000 | 820.000 | 45,6 | 36,2 | 23,2 |
| Genesis → LunaLanding | 1.000.000 | 1.820.000 | **98,3 (22,6 tháng)** | **77,9 (17,9 tháng)** | **51,6 (11,9 tháng)** |

Bậc 4 (500.000) là bậc dài nhất đầu tiên, rồi bậc 5 dài hơn gấp đôi: heavy mất 28,4 tuần cho bậc cuối, casual 52,7 tuần.

Độ nhạy theo R (casual/regular giữ cách chia đều, tính lại vé; số lượt tỉ lệ b):

| R | Casual vé/ngày → Luna | Regular vé/ngày → Luna | Heavy vé/ngày → Luna |
|---|---|---|---|
| 350 | 10,3 → 108,6 tuần | 7,4 → 86,9 | 18,6 → ~52,5 |
| 450 | 12,0 → 98,3 | 8,76 → 77,9 | 21,7 → 51,6 |
| 570 | 14,0 → 88,8 | 10,3 → 69,8 | 24,9 → 51,6 |

(Ví dụ regular R = 350: Shard 6.070/tuần → 867/ngày → n = ln(1,4335)/0,04879 = 7,38; 51,7 + 1,5 = 53,2 lượt gốc; Echo TB 15.802 × 53,2/62,8 = 13.386; + 7.562 → 20.948 → 86,9 tuần.)

R đổi ±27% chỉ làm casual/regular đổi ±10%, heavy gần như không đổi (cửa sổ khóa). Đo R sai không làm hỏng ladder.

Dao động may rủi của heavy: σ Stone/lượt ≈ 358 (Mythic 8.000 chi phối). 7.280 lượt/năm → σ ≈ 358 × √7.280 = 30,5k, tức ±1,7% tổng 1.820.000. Hai σ ≈ ±1,8 tuần. Chấp nhận được.

**Có chấp nhận được không, có cần catch-up?** Khuyến nghị của tôi: **không đổi ladder, không thêm catch-up ở bản đầu.** Lý do:
1. Regular 1,5 năm và casual 1,9 năm tới đích cuối, nhưng bốn bậc đầu (đến Genesis, 820k) là 36 tuần (regular) và 46 tuần (casual): trong năm đầu họ vẫn có bậc mới. Luna là mốc cosmetic (không có sức mạnh).
2. Tỉ lệ heavy : regular : casual = 1 : 1,5 : 1,9 do hình dạng của bậc thang + cửa sổ. Mọi kéo casual nhanh lên đều đưa heavy xuống dưới 1 năm (ví dụ cộng +4.000 Stone/tuần cho mọi người: heavy 46,3 tuần, casual 80,9 tuần), vì thưởng ngày/tuần/Pass cộng như nhau cho mọi nhóm.
3. Nếu telemetry cho thấy median casual hoạt động dưới 14.000 Stone/tuần hoặc nghỉ giữa chừng ở bậc 4–5, bật "Final Stretch": thêm **+2.500 Stone/tuần khi đang leo bậc 5**. Tính thử: casual +13% tốc độ → bậc cuối từ 52,7 xuống ~46,6 tuần (−6); heavy +7% → 28,4 xuống ~26,6 (−1,8). Núm này nhắm vào nhóm ít chơi hơn mà gần như không động tới heavy. Chưa bật.

---

## 3. Echo Box: số cuối

### 3.1 Giá vé

`price(k) = round5(100 × 1,05^(k−1))`, k = thứ tự vé **mua bằng Shard** trong ngày UTC, tối đa 30/ngày.

| k | 1 | 2 | 3 | 5 | 8 | 10 | 12 | 15 | 20 | 22 | 25 | 30 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Giá | 100 | 105 | 110 | 120 | 140 | 155 | 170 | 200 | 255 | 280 | 325 | 410 |

Quà khởi đầu 3 vé. Nạp Shard tối thiểu để có vé đầu: 100 (một run đầu ~336–450 đủ cho 4 vé: C(4) = 2.000 × 0,2155 = 431).

Giữ 100 / 1,05 / 30. Đã thử: base 130 làm casual mua 9,8 vé/ngày (−18%); base 80 cho regular 10,5 (+20%). Heavy chỉ bị khóa bởi cửa sổ nên 100 tốt cho cả ba (regular 8,76 nằm trong dải 8–10, heavy 21,7 trong 18–22).

### 3.2 Drop table, E và pity

Tỉ lệ gốc, Stone mỗi lượt, tỉ lệ sau pity (tôi tính tay).

| Độ hiếm | Tỉ lệ gốc | Tỉ lệ hiệu dụng | Món | Stone/lượt | EV gốc | EV hiệu dụng |
|---|---|---|---|---|---|---|
| Common | 62,0% | 60,2% | 61 | 80 | 49,6 | 48,2 |
| Uncommon | 25,0% | 24,3% | 55 | 160 | 40,0 | 38,9 |
| Rare | 9,5% | 11,3% | 47 | 400 | 38,0 | 45,2 |
| Epic | 2,7% | 3,16% | 39 | 1.000 | 27,0 | 31,6 |
| Legendary | 0,7% | 0,90% | 31 | 2.500 | 17,5 | 22,5 |
| Mythic | 0,1% | 0,158% | 22 | 8.000 | 8,0 | 12,7 |
| **Tổng** | **100%** | **100%** | **255** | | **180,1** | **199,0** |

Cách tính pity. Với ngưỡng cứng T và xác suất tự nhiên p của "≥ độ hiếm đó", số lượt trung bình mỗi chu kỳ = `(1 − (1−p)^T) / p`. Tỉ lệ "nâng" mỗi lượt = `(1−p)^T / chu kỳ`. Nâng thay thế một lượt thấp hơn nên cộng thêm `(Stone bảo đảm − Stone TB lượt bị thay)`.

| Pity | p tự nhiên | (1−p)^T | Chu kỳ | Nâng/lượt | Stone thêm/nâng | Stone thêm/lượt |
|---|---|---|---|---|---|---|
| ≥ Rare @15 | 0,130 | 0,87^15 = 0,1237 | 6,74 | 0,01835 | 400 − 103 = 297 | **5,45** |
| ≥ Epic @60 | 0,035 | 0,965^60 = 0,1179 | 25,2 | 0,00468 | 1.000 − 132 = 868 | **4,06** |
| ≥ Legendary @200 | 0,008 | 0,992^200 = 0,2004 | 99,95 | 0,002005 | 2.500 − 156 = 2.344 | **4,70** |
| Mythic @1.000 | 0,001 | 0,999^1000 = 0,3677 | 632 | 0,000581 | 8.000 − 172 = 7.828 | **4,55** |
| | | | | | **Tổng** | **+18,76** |

E_eff = 180,1 + 18,8 = **198,9 (+10,4%)**. Hai điều cần nhớ:
- Xác suất chạm sàn: 14,2% (Rare), 12,2% (Epic), 20,2% (Legendary), 36,8% (Mythic). Rare/Epic/Legendary nâng nhau nên cộng gộp là gần đúng; sim sẽ cho số thật.
- Mythic pity (1.000) đóng góp 4,55 Stone/lượt, hơn một nửa EV gốc của Mythic (8,0). Nếu Liam muốn Mythic "thật sự hiếm" thì nới pity này (OQ-6).

Số lượt kỳ vọng tới độ hiếm đầu tiên (hiệu dụng): ≥ Rare 6,7; ≥ Epic 25,2; ≥ Legendary 100; Mythic 632. Regular (78 lượt/tuần): Epic+ mỗi ~2 ngày, Legendary+ mỗi 1,3 tuần, Mythic mỗi 8,1 tuần. Heavy (~199 lượt/tuần): Mythic mỗi 3,2 tuần, ~16/năm.

**Sàn/trần:** pity cứng 15 / 60 / 200 / 1.000 lượt, bộ đếm không reset theo ngày, tính cả vé salvage. Pity chạm hai ngưỡng cùng lượt → cấp độ cao nhất, reset các bộ đếm thấp hơn. Trần: 30 vé mua/ngày; Stone chỉ 20 lượt đầu/ngày; thêm trần bảo vệ server 24.000 Stone Echo/ngày (kỳ vọng 3.960; chỉ chặn bug, ECO-7).

### 3.3 Cost per pull và tỉ giá Shard → Stone

Chi phí Shard mỗi lượt (chỉ vé mua) = C(n)/n. Chi phí thật gồm vé Pass và vé salvage miễn phí:

| Persona | Shard tiêu/tuần | Lượt/tuần (TB năm 1) | Shard/lượt thật | Stone Echo/tuần | **Shard / 1.000 Stone** | Stone / 1.000 Shard |
|---|---|---|---|---|---|---|
| Casual | 6.367 | 60,5 | 105 | 11.979 | **531** | 1.881 |
| Regular | 7.470 | 77,9 | 96 | 15.424 | **484** | 2.065 |
| Heavy (tiêu hết) | 26.370 | ~199 (140 có Stone) | 133 (188 trên lượt có Stone) | 27.720 | **951** | 1.051 |
| Heavy (dừng ở 20 vé/ngày) | 23.149 | 140 | | 27.720 | **835** | 1.197 |

Phép tính mẫu casual: 6.367 / 11.979 = 0,5315 Shard/Stone → 531 Shard cho 1.000 Stone.
Tỉ giá biên: vé đầu ngày 100 / 199 = 0,50 Shard/Stone (503 mỗi 1.000); vé thứ 12 = 170 / 199 = 0,85 (854); vé thứ 20 (cuối cửa sổ, nếu không có salvage) = 255 / 199 = 1,28 (1.281). Vé từ 21 trở đi: vô hạn (0 Stone). Mỗi ngày Shard luôn có chỗ đi (lượt cosmetic vẫn tìm đồ mới), nhưng Stone thì không.

Tại sao dồn mua một ngày không có lợi: casual dồn 6.390 Shard vào 1 ngày → 1,05^n = 1 + 3,195 = 4,195 → n = 29,4 vé, chỉ 20 có Stone. Chia 4 ngày được 48 vé, cả 48 có Stone.

### 3.4 Đồ trùng và salvage

| Độ hiếm | Mảnh khi trùng | Giá trị (vé) |
|---|---|---|
| Common | 1 | 0,1 |
| Uncommon | 2 | 0,2 |
| Rare | 5 | 0,5 |
| Epic | 15 | 1,5 |
| Legendary | 40 | 4 |
| Mythic | 100 | 10 |

Giữ nguyên số của game-designer. Tách tự động, 10 mảnh = 1 vé. Quy tắc không-lặp: chỉ trùng khi đã đủ độ hiếm đó. Vé salvage tích về trung bình năm 1: casual 3.144 − 49,5 × 52 = **570 vé (11/tuần, 18% số lượt)**, regular 4.050 − 62,8 × 52 = **784 vé (15/tuần, 19%)**, heavy ~10.330 − 153,5 × 52 = **2.350 vé (45/tuần, 23%)**.

### 3.5 Chứng minh không có vòng lặp salvage vô hạn

1. **Vé và mảnh không bao giờ thành Shard** (ECO-3): sau mọi lượt, Shard không tăng. Vòng "quay → trùng → vé → quay" không có cạnh quay lại Shard.
2. **Hồi tối đa 0,265 vé/lượt** (bảng ở §2.2: 0,0602 + 0,0486 + 0,0565 + 0,0474 + 0,0360 + 0,0158 = 0,2645). Đây là trần với đủ 255 món, kể cả pity (nếu dùng tỉ lệ gốc là 0,238).
3. Chuỗi vé: 1 vé mua → tối đa 0,265 vé salvage → 0,265² … Tổng = 1 / (1 − 0,265) = **1,36 lượt**. Hội tụ vì 0,265 < 1.
4. Stone bị chặn độc lập: dù có vé vô hạn, Stone Echo/ngày ≤ 20 × E (kỳ vọng 3.960) và ≤ 24.000 (server). Nên ngay cả lỗi salvage cũng không mở Land vô hạn.
5. Bundle (sau này): tính vào cửa sổ 20, không bypass.

---

## 4. Battle Pass v2 và Thưởng ngày

### 4.1 Cấu trúc và thời gian xong

Level 30, `XP(lv) = 500 + 40(lv−1)`, cộng dồn `480L + 20L²`, lv 30 = 14.400 + 18.000 = **32.400**. Mùa 8 tuần, nối liền.

XP nguồn: run (1.500 đầu mỗi ngày 100%, phần sau 20%, tổng ≤ 2.000/ngày), thưởng ngày +100, việc tuần 3 × 500 = 1.500/tuần.

| Persona | XP/ngày | Xong |
|---|---|---|
| Casual (3 run/ngày × 4 ngày, 2/3 việc tuần) | (996 + 100) × 4 + 1.000 = 5.384/tuần | 32.400 / 5.384 = **6,0 tuần** |
| Regular (2 run/ngày) | 664 + 100 + 214 = 978 | 33,1 ngày = **4,7 tuần** |
| 1 run/ngày | 332 + 100 + 214 = 646 | 50,2 ngày = **7,2 tuần** (vẫn xong trong 8 tuần) |
| Heavy (8 run/ngày) | 1.883 + 100 + 214 = 2.197 | **14,7 ngày** |
| Cực đoan (≥ 9,4 run/ngày) | 2.000 + 100 + 214 = 2.314 | **14,0 ngày** (sàn) |

Sàn: `T_min = 32.400 / 2.314 = 14,0 ngày`. Kiểm theo tuần lịch: 14 ngày, 2 tuần việc tuần: 14 × 2.100 + 3.000 = 32.400. Nếu 14 ngày rơi vào 3 tuần lịch: 14 × 2.100 + 4.500 = 33.900 ≥ 32.400 (ngày 13 chỉ có 27.300 + 4.500 = 31.800 < 32.400) nên vẫn là ngày 14. ECO-9 giữ sàn này.

Người chơi dưới ~4.050 XP/tuần (ví dụ 3 ngày × 1 run) không xong mùa; họ giữ phần đã đạt. Giữ như vậy, không tăng hỗ trợ.

### 4.2 Bảng 30 level

Tổng Shard 4.800, Stone 16.500, vé 12, cosmetic 7 + 1 danh hiệu, 5 unlock chỉ số (lv 4/8/12/16/20; ai đã sở hữu thì nhận Shard theo giá shop). Giữ cấu trúc của game-designer, số đã kiểm lại.

| Lv | XP cộng dồn | Thưởng |
|---|---|---|
| 1 | 500 | 300 Shard |
| 2 | 1.040 | 1 vé |
| 3 | 1.620 | 1.000 Stone |
| 4 | 2.240 | **Unlock u_reroll** |
| 5 | 2.900 | fx_c_leaf + 300 Shard |
| 6 | 3.600 | 1 vé |
| 7 | 4.340 | 1.500 Stone |
| 8 | 5.120 | **Unlock u_hp** |
| 9 | 5.940 | frame_u_vine |
| 10 | 6.800 | 500 Shard + 1 vé |
| 11 | 7.700 | 1.500 Stone |
| 12 | 8.640 | **Unlock u_start** |
| 13 | 9.620 | 500 Shard |
| 14 | 10.640 | 1 vé |
| 15 | 11.700 | fx_r_bubble + 2.000 Stone |
| 16 | 12.800 | **Unlock u_reroll2** |
| 17 | 13.940 | 500 Shard |
| 18 | 15.120 | 1 vé |
| 19 | 16.340 | 2.000 Stone |
| 20 | 17.600 | **Unlock u_hp2** + 500 Shard |
| 21 | 18.900 | die_u_moss |
| 22 | 20.240 | 500 Shard |
| 23 | 21.620 | 2 vé |
| 24 | 23.040 | 2.500 Stone |
| 25 | 24.500 | die_e_s1_founder + 500 Shard |
| 26 | 26.000 | 600 Shard |
| 27 | 27.540 | frame_e_s1_founder |
| 28 | 29.120 | 1 vé + 3.000 Stone |
| 29 | 30.740 | 600 Shard |
| 30 | 32.400 | frame_l_sovereign + danh hiệu LUNACIA SOVEREIGN + 4 vé + 3.000 Stone |

Kiểm:
- Shard: 300 + 300 + 6 × 500 + 2 × 600 = 600 + 3.000 + 1.200 = **4.800**.
- Stone: 1.000 + 1.500 + 1.500 + 2.000 + 2.000 + 2.500 + 3.000 + 3.000 = **16.500**.
- Vé: lv 2, 6, 10, 14, 18 (5) + lv 23 (2) + lv 28 (1) + lv 30 (4) = **12**.

Giá trị Pass: 4.800 Shard + 12 vé (~12 × 140 = 1.680 Shard) + 16.500 Stone + 12 lượt × 198 = 2.376 Stone. Tỉ trọng Stone Pass: casual 11%, regular 9%, heavy 6% (§2.3). Pass là bù nhẹ cho người ít chơi, vì cố định theo thời gian.

### 4.3 Thưởng ngày

| | Điều kiện | Thưởng |
|---|---|---|
| Ngày | Hoàn thành 1 run trong ngày UTC (server xác nhận) | **60 Shard + 500 Stone + 100 XP** |
| Tuần | ≥ 4 ngày nhận trong tuần UTC | **+150 Shard + 2.000 Stone** |

Stone/tuần: casual 4 × 500 + 2.000 = 4.000, regular/heavy 7 × 500 + 2.000 = 5.500. Tỉ trọng 22% / 24% / 16% (§2.3). Không phạt đứt chuỗi. Guest: nhận Stone sau khi đăng nhập (queue 7 ngày). Đây là phần Stone cố định theo thời gian, không phụ thuộc kỹ năng hay lượng gacha.

---

## 5. Ngân sách cho Nhiệm vụ (thiết kế sau)

Nhiệm vụ trả Land Stone nhỏ và Shard theo stake. Ngân sách để hệ đó nhắm tới, tính trên timeline §2.4:

### 5.1 Stone

**Trần: ≤ 150 Stone mỗi ngày hoạt động** (≤ 1.050/tuần). Mỗi mission trung bình ~30 Stone nếu 5/ngày, tức 0,15 lượt quay. Ví dụ bậc I/II/III/IV = 10 / 20 / 40 / 80 (tổng 150); chỉ là minh họa.

| | Casual | Regular | Heavy |
|---|---|---|---|
| Tốc độ gốc (TB đến Luna) | 18.515 | 23.364 | 35.282 |
| + mission tối đa | 4 ngày × 150 = 600 → 19.115 | 1.050 → 24.414 | 1.050 → 36.332 |
| Luna | 1.820.000 / 19.115 = **95,2 tuần (−3,1)** | / 24.414 = **74,5 (−3,4)** | / 36.332 = **50,1 (−1,5)** |
| Rút ngắn | −3,2% | −4,4% | −2,9% |

Quy tắc: nếu mission được phép trả hơn trần này (ví dụ 300/ngày), regular rút −8% (24.2k → 25.5k/tuần, 71,5 tuần) và heavy xuống 48,7 tuần, sát ranh giới "~1 năm". Không đi quá mà không tính lại.

### 5.2 Shard

- Tổng thể (toàn dân) RTP ≤ 100%; mission không phải faucet ròng.
- Người giỏi có lãi tối đa **+5% thu nhập tuần**: casual +320, regular +375, heavy +1.300 Shard/tuần.
- Tác động lên Stone: casual +320 Shard/tuần mua thêm 320 / 180 = 1,8 vé × 198 × 1,2 = 430 Stone/tuần (+2,3%); regular tương tự +2%; heavy 0 (đã quá cửa sổ). Cộng với trần Stone mission, tổng rút ngắn nhiều nhất ~6–7% (casual).
- Người được phép lỗ cả 5 stake (quyết định 10/10): mất nhiều nhất cỡ vài ngày vé, không dẫn tới hết Shard, vì run thua vẫn cho ~258 Shard và không có chi phí bắt buộc nào (§6).

---

## 6. Shard 26 tuần mỗi persona

Giả định: tiêu hết mỗi ngày vào vé (A3), trừ 10.350 một lần cho unlock shop (cực đại; nếu 5 unlock chỉ số nhận từ Pass thì dư thêm 7.110).

| | Casual | Regular | Heavy |
|---|---|---|---|
| Shard vào (26 × tuần) | 6.390 × 26 = 166.140 | 7.470 × 26 = 194.220 | 26.370 × 26 = 685.620 |
| Unlock một lần | −10.350 | −10.350 | −10.350 |
| Còn cho vé | 155.790 | 183.870 | 675.270 |
| Số ngày mở game | 104 | 182 | 182 |
| Shard/ngày | 1.498 | 1.010 | 3.710 |
| Vé/ngày (giải C(n)) | 1,05^n = 1,749 → 11,5 | 1,505 → 8,4 | 2,855 → 21,5 |
| Tổng vé mua | ~1.190 | ~1.525 | ~3.910 |
| Số dư cuối kỳ | < 1 vé (< 170) | < 1 vé (< 150) | < 1 vé (< 280) |
| Tổng lượt quay (kèm Pass + salvage) | ~1.510 | ~1.950 | ~5.020 |
| Stone cộng dồn | ~456.000 | ~582.000 | ~917.000 |
| Bậc Land | Mystic (≥ 320k) | Mystic | **Genesis** (≥ 820k, đạt tuần 23,2) |

Phép tính mẫu: casual vé/ngày = ln(1,749) / 0,04879 = 0,5589 / 0,04879 = 11,5; 11,5 × 104 = 1.190.
Stone casual: 374.223 (tuần 21,56) + 4,44 × 18.514 = 82.202 → 456.425.

**Không bao giờ hết Shard:** không có chi phí bắt buộc, run không tốn Shard, mua vé là tự nguyện, run thua vẫn ~258. Người mới có đủ cho 4 vé sau 1 run.

**Không tích vô ích với casual/regular:** họ tiêu hết ngân sách mỗi ngày, tồn dưới 1 vé.

**Chỗ yếu: heavy dừng ở 20 vé/ngày.** Heavy "chỉ mua đủ để lấp cửa sổ" (vé cần = 20 × (1 − ν) − 0,2 Pass) tồn thêm:
- Tuần 0–8,8 (ν TB ≈ 0,10): mua 17,8 vé/ngày → C = 2.767; dư 3.767 − 2.767 ≈ 1.000/ngày × 61,6 ngày = 61.600.
- Tuần 8,8–24,6 (ν = 0,213): mua 15,5 → C = 2.261; dư 1.506/ngày × 110,6 = 166.600.
- Tuần 24,6–26 (ν = 0,249): mua 14,8 → C = 2.118; dư 1.649 × 9,8 = 16.200.
- Tổng 244.400 − 10.350 = **~234.000 Shard** (≈ 8,9 tuần thu nhập). Đây là "pile" thật của nhóm này.

Cách hấp thụ ngay: heavy mua vé vượt cửa sổ (không Stone nhưng vẫn ra cosmetic mới, mảnh, pity cho Mythic), tới 30 vé/ngày, đây là chế độ "tiêu hết" của bảng trên. Lâu dài cần sink riêng (OQ-2).

---

## 7. Núm chỉnh, bất biến, telemetry, câu hỏi mở

### 7.1 Núm và khoảng an toàn

Mọi số trong `assets/data/`, không hardcode.

| Núm | Mặc định | Khoảng an toàn | Độ nhạy (đã tính) |
|---|---|---|---|
| `ticket_price_base` | 100 | 80–130 | 130 → casual −18% vé, regular −20%; 80 → regular +20% |
| `ticket_price_growth` | 1,05 | 1,03–1,07 | Từ 1,08 heavy mua dưới 20/ngày (18,1) → heavy chậm hơn. 1,03: regular +7% vé |
| `ticket_buy_cap_day` | 30 | 25–50 | Không chạm ở R ≤ 570 |
| `stone_window_day` | 20 | 16–24 | Chỉ heavy: 16 → 61,2 tuần; 24 → 44,6 tuần. Regular/casual không đổi |
| `stone_by_rarity` | 80/160/400/1.000/2.500/8.000 | nhân 0,8–1,2 | ×1,2: heavy 44,4, regular 68,6, casual 86,7 tuần |
| `rarity_rates` | 62/25/9,5/2,7/0,7/0,1 | Mythic 0,05–0,2 | |
| `pity` | 15/60/200/1.000 | 10–20 / 40–80 / 120–300 / 600–1.500 | Mythic pity = 4,55 Stone/lượt |
| `fragments_per_ticket` | 10 | 6–15 | Dota dùng 6. Luôn giữ ν_max < 1 |
| `salvage_fragments` | 1/2/5/15/40/100 | — | ν_max = 0,265 |
| `daily_stone` | 500 | 300–1.000 | Mỗi +100/ngày: casual +400/tuần (+2,1%), regular/heavy +700 (+3% / +2%) |
| `weekly_bonus` | 150 Shard + 2.000 Stone, ≥ 4 ngày | 3–5 ngày | |
| `pass_xp` | 500 + 40(lv−1) | tổng 28.000–36.000 | T_min ≥ 14 ngày |
| `pass_run_xp_cap_day` | 2.000 (1.500 @100%, 20% sau đó) | 1.500–2.500 | |
| `pass_weekly_tasks_xp` | 3 × 500 | 1.000–2.000 | |
| `pass_totals` | 4.800 Shard / 16.500 Stone / 12 vé | Stone 12.000–22.000 | |
| `mission_stone_day_cap` | 150 | 100–200 | Tại 150 rút Luna −3% đến −4%; tại 300 thì −8% |
| `land_cost[5]` | 40k/100k/180k/500k/1M | Liam chốt | |
| `final_stretch` (tùy chọn) | tắt; +2.500 Stone/tuần ở bậc 5 | 0–4.000 | §2.4 |

### 7.2 Bất biến (test được)

Tiền tố ECO để không đụng `INV-1..7` của `build-spec.md` và `INV-V*` của game-designer.

| # | Bất biến |
|---|---|
| ECO-1 | Nâng Land chỉ trừ Stone. Không API nào trừ Shard cho Land |
| ECO-2 | Vé thứ k mua bằng Shard trong ngày UTC giá `round5(100 × 1,05^(k−1))`, k reset 00:00 UTC, tối đa 30/ngày. Vé salvage, Pass, bundle, starter không tăng k |
| ECO-3 | Quay vé và salvage không bao giờ cộng Shard. Sau mỗi lượt: Shard không đổi, vé −1. Không có đường Stone→Shard, vé→Shard |
| ECO-4 | Stone Echo chỉ cho 20 lượt đầu mỗi ngày UTC (mọi nguồn vé). Lượt 21+ = 0 Stone |
| ECO-5 | `Σ rate × mảnh / 10 < 1` với cả tỉ lệ gốc (0,238) và hiệu dụng (0,265). Test: 100.000 vé mua → tổng lượt ≤ 1,36 × 100.000 |
| ECO-6 | `Σ rarity_rates = 100% (±0,001)`. E gốc = 180,1 (±2). E_eff trong khoảng 190–208 (sim 100.000 lượt) |
| ECO-7 | Server chặn Echo Stone > 24.000/ngày/tài khoản và vé giữ ≤ 999 |
| ECO-8 | Pity: không quá 15 lượt liền không có ≥ Rare, 60 không có ≥ Epic, 200 không có ≥ Legendary, 1.000 không có Mythic (RNG ép xui) |
| ECO-9 | `T_min = 32.400 / (cap_run + 100 + 1.500/7) = 14,0 ngày ≥ 14`. XP cộng dồn lv 30 = 32.400. Pass: Shard 4.800, Stone 16.500, vé 12 |
| ECO-10 | Stone từ Pass, thưởng ngày/tuần, Echo: do server cấp và kiểm ngày UTC. Mọi ghi qua `SaveStore`; field mới (vé, mảnh, pity, bộ đếm ngày) có trong `MetaState.reload_from_store()` |
| ECO-11 | Timeline sim (R = 450): heavy 51,6 ±10%, regular 77,9 ±15%, casual 98,3 ±15% tuần. Heavy 49–54 tuần khi R ∈ [350, 570] |
| ECO-12 | Mission Stone ≤ 150/ngày hoạt động |
| ECO-13 | Unlock chỉ số = 0 khi Ranked; ai đã có unlock thì mốc Pass trả Shard bằng giá shop |

### 7.3 Telemetry

1. Sổ vé theo `origin` (shard/salvage/pass/starter/bundle): số vé, số lượt, tỉ lệ salvage trên lượt (đối chiếu 18–23%).
2. Vé mua/ngày p10/p50/p90 theo nhóm hoạt động; % ngày chạm cửa sổ 20; % người dùng > 20 lượt/ngày.
3. Stone/tuần theo nguồn (Echo, thưởng, Pass, mission) và **thời gian tới từng bậc Land** p10/p50/p90 so với bảng §2.4.
4. Tỉ lệ chạm pity theo bậc, số lượt thật tới Epic+/Legendary+/Mythic (đối chiếu 25 / 100 / 632).
5. Số dư Shard p90: cờ đỏ khi > 4 tuần thu nhập (pile của heavy) hoặc p10 mua < 4 vé/ngày ở ngày mở game.
6. Pass: số ngày hoàn thành (min ≥ 14), % xong mùa, % chạm trần XP ngày.
7. Thưởng ngày/tuần: tỉ lệ nhận, % đạt ≥ 4 ngày.
8. R thật theo mode và thắng/thua (cập nhật A1).
9. Mission Stone/ngày thật so với trần 150.
10. Echo Stone/ngày p99 so với trần server 24.000.

### 7.4 Câu hỏi mở (kèm đề xuất)

| # | Câu hỏi | Đề xuất |
|---|---|---|
| OQ-1 | Regular 1,5 năm, casual 1,9 năm tới Luna: chấp nhận không, hay cần catch-up? | Chấp nhận, không đổi ladder (§2.4). Chuẩn bị núm `final_stretch` +2.500 Stone/tuần ở bậc 5, bật khi telemetry cho thấy casual median < 14.000 Stone/tuần |
| OQ-2 | Heavy dừng ở cửa sổ tồn ~235.000 Shard/6 tháng. Cần sink Shard riêng? | Hoãn. Khi p90 số dư > 4 tuần thu nhập thì thêm "Echo Market": mua thẳng 1 món còn thiếu, giá cố định cao hơn nhiều so với quay (không ra Stone, không có Mythic) |
| OQ-3 | Cửa sổ 20 tính mọi vé (salvage, Pass, bundle)? | Có, như game-designer. Nếu bỏ salvage khỏi cửa sổ thì heavy nhanh hơn ~25% (vượt mục tiêu 1 năm) |
| OQ-4 | Có cần bậc "50% Stone cho lượt 21–30" không? | Không. Heavy chỉ vượt cửa sổ ~1,7 vé/ngày, thêm bậc chỉ tăng độ phức tạp |
| OQ-5 | Guest: Stone chờ trong queue 7 ngày, cấp khi đăng nhập? | Có. Nếu không thì đổi đồng hồ máy là lách |
| OQ-6 | Mythic pity 1.000 (cho 37% người chơi chạm sàn) có giữ? | Giữ ở bản đầu; nếu Liam muốn Mythic thực sự hiếm thì nới tới 1.500 (Stone/lượt −1,5) |
| OQ-7 | Mở game ngày không chơi vẫn mua vé được (thưởng +15% vé cho casual)? | Có, đây là thưởng cho thói quen mở game |
| OQ-8 | Ai đã mua unlock chỉ số từ shop: mốc Pass trả Shard bằng giá shop (ECO-13)? | Có, như game-designer; giá shop không đổi để làm đường dự phòng |
| OQ-9 | Mission Stone trần 150/ngày | Chốt ở đây, Nhiệm vụ thiết kế sau trong trần này |
| OQ-10 | Số món thật mỗi độ hiếm (61/55/47/39/31/22) là ước | Đổi số này chỉ làm dịch thời điểm salvage, không đổi kết luận. Cập nhật khi art request chốt |
