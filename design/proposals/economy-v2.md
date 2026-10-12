Trạng thái: ĐỀ XUẤT — chờ Liam review (ECO-13 sửa 12/10 theo B3)

> **QUYẾT ĐỊNH LIAM (12/10, B3) — ưu tiên hơn thân file:** unlock cày (5 unlock cộng chỉ số `u_reroll`, `u_hp`,
> `u_start`, `u_reroll2`, `u_hp2`, từ shop hay Pass) **được dùng trong ranked**; người cày không được thua người nạp
> (Aid mua bằng tiền thật đã dùng được trong ranked). **ECO-13 bỏ vế "Unlock chỉ số = 0 khi Ranked"**; giữ vế
> "ai đã có unlock thì mốc Pass trả Shard bằng giá shop". Mọi chỗ trong file này nói "Ranked profile tắt unlock/bonus = 0"
> đã bị thay bằng quyết định này. Hệ quả: bảng win rate ranked phải đo **có unlock**, và verifier nhận loadout unlock
> tiêm vào (`docs/architecture/server-authoritative-rng.md` F9). File khác còn câu cũ (`echobox-pass-v2.md` INV-V10 và
> các dòng "Không áp dụng ở Ranked", `core-loop-v2.md` mục Ranked profile) cần sửa theo, chưa sửa ở đây.

> **SỬA 10/10: jackpot thật nhỏ.** Liam: jackpot 10.000 / 25.000 Stone được giữ, nhưng tỉ lệ phải thật nhỏ.
> - Hộp thường: jackpot 10.000 từ 0,2% (1/500) xuống **0,02% = 1 trong 5.000 lượt**.
> - Hộp mùa: jackpot 25.000 từ 0,2% trong lượt Stone (0,16% mỗi lượt mùa, 1/625) xuống **0,03% trong lượt Stone = 0,0234% mỗi lượt mùa = 1 trong ~4.274 lượt mùa** (~21.400 vé).
> - Phần xác suất và EV bỏ ra chuyển sang các stack 500–5.000, đã chỉnh để **EV hộp thường vẫn đúng 242,5, EV hộp mùa vẫn 1.290/lượt Stone (1.006/lượt mùa)**. Nên bảng tuần tới LunaLanding (§6.4) **không đổi một con số nào**. Chỉ độ dao động do may mắn nhỏ lại (§6.4). Bảng mới: §3.1, §4.2. Trần server ECO-7 giữ 80.000. Thêm ECO-20.

> **LIAM ĐÍNH CHÍNH (10/10):** Land Stone là MỘT LOẠI PHẦN THƯỞNG trong bảng rơi của Echo Box (tỉ lệ ra cao),
> KHÔNG đi kèm mọi lượt quay. Mỗi lượt ra đúng một phần thưởng. Thân file hiện tính sai mô hình (Stone kèm mọi
> lượt + cửa sổ 20 lượt) → phải tính lại. Casual/regular vượt mục tiêu: Liam chấp nhận, để nguyên.
> **Liam xác nhận mô hình (10/10):** mỗi lượt = 1 phần thưởng (Land Stone HOẶC cosmetic). **Hộp mùa CÓ ra Stone,
> với lượng CAO HƠN hộp thường** vì giá lượt cao hơn (5 vé).
> **Liam chốt 3 câu cuối (10/10):** (1) casual/regular chậm hơn mục tiêu ~37–39%: ĐỂ NGUYÊN · (2) trần đủ bộ mùa
> 80 lượt: GIỮ NGUYÊN · (3) jackpot 10.000 / 25.000 Stone: ĐƯỢC, nhưng **tỉ lệ ra phải THẬT NHỎ** · cho phép thêm
> thực thể economy vào `design/registry/entities.yaml`.
> **QUYẾT ĐỊNH LIAM (10/10, 5 câu sau bản 2 hộp):** (1) **giá vé cơ sở = 200 Shard** (không hỏi lại) ·
> (2) CHẤP NHẬN casual/regular mua đủ bộ mùa thì tốn nhiều Shard và lên Land chậm hơn · (3) hộp thường **1 vé**/
> lượt, hộp mùa **5 vé**/lượt · (4) vé bundle: KHÔNG hàng rào, chấp nhận người nạp nhiều lên Land nhanh gấp đôi ·
> (5) vé đổi từ đồ thừa **KHÔNG tính** vào cửa sổ Stone 20 lượt/ngày.

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
>   **5 unlock cộng chỉ số vẫn đưa vào Battle Pass được** — tinh chỉnh khéo cho hợp (~~Ranked profile
>   vẫn tắt chúng~~ — **đảo lại 12/10, B3: unlock cày được dùng trong ranked**, xem khối đầu file).
> - **Nhiệm vụ**: CÓ trả Land Stone nhưng lượng rất nhỏ. **Bỏ** hai luật thêm (lỗ ngày ≤1R, stake
>   ≤40% số dư): người chơi được phép lỗ cả 5 nhiệm vụ. Đường cong độ khó và đường cong thưởng phải
>   đi cùng nhau: muốn kiếm nhiều thì phải chấp nhận khó và bỏ nhiều tiền. Mục đích: kiểm tra người
>   chơi có chấp nhận risk to earn không.
> - Ba điều trong thiết kế Nhiệm vụ: (1) chạy trên ranked profile — đồng ý (nay ranked profile **có** unlock cày, B3 12/10); (2) đổi tên Daily
>   Mission +60 thành "Thưởng ngày" — đồng ý; (3) save-scum — Liam chưa thấy vấn đề, đang hỏi lại.

> **BỔ SUNG (trích nguyên ý từ `echobox-pass-v2.md` và lệnh của Liam, 10/10) — Echo Box tách 2 hộp:**
> - **E1** giá hộp mùa = **gấp 5** hộp thường (không phải 3) · **E2** chấp nhận người đủ bộ mỗi mùa lên Land chậm hơn (economy-designer tính lại) · **E3** nhịp hộp mùa **12 tuần** · **E4** hộp thường giữ Mythic (decor/thú), die/frame/FX Mythic chỉ ở hộp mùa · **E5** dành ~15 món Epic+ của thư viện cho các mùa sau.
> - **E6** một tòa nhà Echo Box, hai tab (Thường / Mùa). 
> - **E7** 19 món art mới bậc thấp vào hộp thường. **MỘT loại vé cho cả hai hộp** (không có `season_ticket`). **Đồ trùng đổi thành vé**, ví dụ của Liam: "10 đồ trùng bậc thấp → 3 vé", bậc cao đáng giá hơn, cho cả hai hộp.

# Axie Dice — Economy v2 (mô hình: mỗi lượt đúng 1 phần thưởng)

Tác giả: economy-designer · 10/10/2026 (bản viết lại theo đính chính) · Chỉ sửa file này, không code. Mọi số tính tay, **chưa qua sim**.

---

## 0. Đọc nhanh

### 0.1 Mô hình mới và kết quả

1. **Mỗi lượt quay = một phần thưởng từ một bảng rơi.** Land Stone là một loại phần thưởng (nhiều cỡ), phần còn lại là cosmetic theo độ hiếm. **Không còn cửa sổ 20 lượt, không còn knob E/A/B**, vì Stone không kèm mọi lượt nên không cần khóa. Quyết định (5) và A11 hết đối tượng (không còn cửa sổ nào để "tính" hay "không tính"). Tốc độ lên Land giờ do hai thứ điều khiển: **xác suất ra Stone** và **cỡ stack** của từng hộp.
2. **Hộp thường (1 vé):** 60% lượt ra Stone (100 / 250 / 500 / 1.000 / 2.500 / 10.000; jackpot 10.000 chỉ 0,02% = 1/5.000 lượt), 40% ra cosmetic (tỉ lệ độ hiếm giữ như cũ, pity tính trên lượt cosmetic). Stone trung bình **242,5/lượt** (§3).
3. **Hộp mùa (5 vé):** ra cosmetic theo odds leo dần có trần cứng như cũ, **lượt nào không trúng tầng nào thì ra Stone** (500 / 1.000 / 2.500 / 5.000 / 25.000, trung bình 1.290 mỗi lần ra Stone; jackpot 25.000 chỉ 0,0234% mỗi lượt mùa = 1/4.274). Cả bộ S1 vẫn **chắc chắn đủ trong ≤ 80 lượt** (chứng minh §4.3). Stone ~**78% lượt**, trung bình **1.006/lượt** (201/vé, bằng 83% hộp thường tính theo vé). Epic không còn là "ô mặc định"; nó thành tầng có odds leo dần riêng (N = 10).
4. **Đồ trùng:** vì cosmetic chỉ còn 40% lượt (hộp thường) và ~22% (hộp mùa), hồi vé thấp hơn nhiều: hộp thường tối đa **0,211 vé/lượt** (cũ 0,527), hộp mùa **0,35 vé/lượt = 0,07 mỗi vé bỏ ra**. Không có vòng lặp vô hạn (§5).
5. **Tuần tới LunaLanding (R = 450, tuần)**, bảng Stone đã chỉnh để **heavy ở "nửa bộ" = 52,3 tuần (1,00 năm)**:

| | Không mua mùa | Nửa bộ | Đủ bộ |
|---|---|---|---|
| Casual | 125,9 (2,41 năm) | 136,2 (2,61) | 146,8 (2,82) |
| Regular | 102,1 (1,96) | 108,8 (2,09) | 115,7 (2,22) |
| Heavy | 50,6 (0,97) | **52,3 (1,00)** | 53,9 (1,03) |

6. **Casual/regular vượt mục tiêu 37–39%** ở "nửa bộ" (casual 2,61 năm so với ~1,9; regular 2,09 so với ~1,5). Liam đã chấp nhận, không thêm catch-up. Lý do vẫn nên biết con số: heavy bị ghim ở 52 tuần nên nguồn Stone theo vé đã chỉnh vừa heavy; casual/regular có thu nhập vé thấp hơn 3–4 lần nhưng Stone cố định (thưởng ngày, Pass) chỉ thấp hơn ~0–20%, nên khoảng cách không thu hẹp được nếu không đổi nguồn cố định (§11, OQ-1).
7. **Bộ mùa S1:** điển hình 55 lượt = 275 vé, hoàn ~3,5 vé, **ròng ~271,5 vé** (cũ 188, vì Epic hết là ô trùng 85% nên hoàn nhiều). Tốn **81,7% / 66,0% / 23,6%** Shard 12 tuần của casual / regular / heavy. Trần cứng 80 lượt = 400 vé: **120% / 97% / 35%** (§7). Casual không đủ Shard cho trần cứng trong một mùa (OQ-2).
8. **Bundle** (không hàng rào): +50 vé/tuần đưa "nửa bộ" xuống heavy 36,8 / regular 58,0 / casual 65,0 tuần; +100 vé/tuần xuống 28,4 / 39,5 / 42,6 (§9). Người nạp đạt Land nhanh gấp ~1,4–3,2 lần.
9. **Shard 6 tháng:** mọi persona về ~0 (hết vào vé mỗi ngày, §8). Pass sau lv30 giữ 2.000 XP = 50 Shard.

### 0.2 Giả định

| # | Giả định |
|---|---|
| A1 | R = 450 Shard/run (đã trừ shop trong run, không gồm +60 thưởng ngày). Độ nhạy R = 350 / 570 |
| A2 | Casual 4 ngày × 3 run (12 run/tuần). Regular 7 × 2 (14). Heavy 7 × 8 (56) |
| A3 | Hết Shard mỗi ngày mở game đều vào vé (thang giá lồi, chia đều là rẻ nhất) |
| A4 | Hộp thường 223 món: 61 / 55 / 47 / 28 / 20 / 12 theo độ hiếm (`echobox-pass-v2.md` §2.7) |
| A5 | Hộp mùa S1: 6 Epic, 3 Legendary, 2 Mythic + 1 độc quyền mốc 40 |
| A6 | Mô hình dòng chảy §6.1: vé không-tái-chế → số lượt, qua hồi vé theo tiến độ bộ sưu tập. Missions chưa tính vào mốc thời gian (§9) |
| A7 | 1 năm = 52,14 tuần; tuần UTC |

---

## 1. Bản đồ currency

| Faucet Shard | Số |
|---|---|
| Run | 450/run |
| Thưởng ngày / tuần | 60/ngày; +150 nếu ≥ 4 ngày |
| Pass | 4.800/mùa 8 tuần + vòng lặp sau lv30 (+33 / +70 / +283 mỗi tuần: casual/regular/heavy) |
| Echo Box (cả hai), đổi trùng | **0** |

Sink Shard: mua vé `round5(200 × 1,05^(k−1))`, k = thứ tự vé mua trong ngày UTC, tối đa 30/ngày, một thang chung; unlock shop một lần 10.350.

| Faucet Stone | Số |
|---|---|
| Hộp thường | 242,5/lượt trung bình, theo bảng §3 |
| Hộp mùa | 1.006/lượt trung bình, theo bảng §4 |
| Thưởng ngày / tuần | 500/ngày; +2.000/tuần (≥ 4 ngày) |
| Pass | 16.500/mùa 8 tuần = 2.062,5/tuần |
| Nhiệm vụ (sau này) | ≤ 150/ngày hoạt động (§9) |
| Bundle | Vé bundle quay như vé thường, ra đúng bảng trên |

Sink Stone: Land 40k / 100k / 180k / 500k / 1M, cộng dồn 40k / 140k / 320k / 820k / 1.820k. Vé và mảnh không đổi ngược ra Shard hay Stone.

---

## 2. Giá vé, thu nhập, persona

Tổng chi n vé trong ngày: `C(n) = 4.000 × (1,05^n − 1)`. Ví dụ C(10) = 4.000 × 0,6289 = 2.516; C(20) = 6.613; C(30) = 13.288. Vé thứ k: 1→200, 5→245, 10→310, 15→395, 20→505, 30→825.

Thu nhập tuần và vé/tuần (vé mua từ `n = ln(1 + Shard_ngày/4.000) / 0,04879`, cộng 1,5 vé Pass/tuần):

| R | | Casual | Regular | Heavy |
|---|---|---|---|---|
| 450 | Shard/tuần (run + ngày + tuần + Pass) | 5.400+240+150+633 = **6.423** | 6.300+420+150+670 = **7.540** | 25.200+420+150+883 = **26.653** |
| | Shard/ngày mở game | 1.606 | 1.077 | 3.808 |
| | Vé/ngày | ln(1,4015)/0,04879 = **6,92** | **4,89** | **13,71** |
| | **Vé/tuần (b₀)** | 6,92×4+1,5 = **29,2** | 4,89×7+1,5 = **35,7** | 13,71×7+1,5 = **97,5** |
| | Giá TB/vé | 232 | 220 | 278 |
| 350 | Shard/tuần | 5.223 | 6.140 | 21.053 |
| | Vé/ngày · vé/tuần | 5,79 · **24,7** | 4,06 · **29,9** | 11,49 · **81,9** |
| 570 | Shard/tuần | 7.863 | 9.220 | 33.373 |
| | Vé/ngày · vé/tuần | 8,19 · **34,3** | 5,83 · **42,3** | 16,08 · **114,1** |

Shard 12 tuần (R = 450): 77.076 / 90.480 / 319.836. Hai cap giữ nguyên: 30 vé mua/ngày (hầu như không ai chạm; heavy 13,7) và 8 lượt mùa/ngày (= 40 vé/ngày; xong bộ điển hình không sớm hơn ~7 ngày, trần cứng 80 lượt không sớm hơn 10 ngày).

Ba hành vi mùa (mỗi 12 tuần), dùng xuyên suốt:
- **Không mua mùa:** 0 lượt mùa.
- **Nửa bộ:** 27,5 lượt = 137,5 vé = **11,46 vé/tuần** (2,29 lượt/tuần), hoàn ~0 (chưa có tầng nào đủ).
- **Đủ bộ:** 55 lượt = 275 vé = 22,92 vé/tuần, hoàn 3,5 vé/12 tuần = 0,29/tuần, ròng **22,63 vé/tuần** (4,58 lượt/tuần).

Vé còn cho hộp thường: `b_std = b₀ − vé mùa ròng`.

---

## 3. Hộp thường — bảng rơi (1 vé/lượt)

### 3.1 Bảng rơi

| Phần thưởng | Tỉ lệ mỗi lượt | Điều kiện | Ghi chú |
|---|---|---|---|
| Stone 100 | 15,30% | | SỬA 10/10 (cũ 20,0%) |
| Stone 250 | 24,08% | | SỬA 10/10 (cũ 20,0%) |
| Stone 500 | 13,00% | | không đổi |
| Stone 1.000 | 6,00% | | SỬA 10/10 (cũ 5,5%) |
| Stone 2.500 | 1,60% | | SỬA 10/10 (cũ 1,3%) |
| **Stone 10.000 (jackpot)** | **0,02%** | **1/5.000 lượt** | SỬA 10/10: jackpot thật nhỏ (cũ 0,2% = 1/500) |
| **Tổng Stone** | **60,00%** | | EV = 15,3+60,2+65+60+40+2 = **242,5**/lượt |

Kiểm tổng xác suất: 15,30+24,08+13,00+6,00+1,60+0,02 = 60,00. Kiểm EV từng dòng: 100×0,1530 = 15,3 · 250×0,2408 = 60,2 · 500×0,13 = 65 · 1.000×0,06 = 60 · 2.500×0,016 = 40 · 10.000×0,0002 = 2. Cộng 242,5, bằng bản cũ. Cách chỉnh: jackpot mất 0,18% xác suất và 18 EV; phần 0,18% dồn sang 2.500, 1.000, 250 (kéo từ stack 100) để bù đủ 18 EV. Bảng sạch ở mức 2 số lẻ; không có phương án sạch hơn mà giữ EV chính xác 242,5.
| **— Cosmetic (40%) —** | | | |
| Common | 24,0728% | cosmetic, 61 món | SỬA 10/10: 24,08 → 24,0728 để tổng cosmetic đúng 40,0000% (trước cộng 40,0072%) |
| Uncommon | 9,72% | 55 món | |
| Rare | 4,52% | 47 món | |
| Epic | 1,264% | 28 món | |
| Legendary | 0,360% | 20 món | |
| Mythic (decor/thú/phụ kiện/danh hiệu) | 0,0632% | 12 món | E4: không phải die/frame/FX |
| **Tổng cosmetic** | **40,0000%** | | 24,0728+9,72+4,52+1,264+0,360+0,0632 = 40,0000; = 0,4 × (60,2 / 24,3 / 11,3 / 3,16 / 0,90 / 0,158) |

Tỉ lệ cosmetic là tỉ lệ hiệu dụng cũ (đã gồm pity) nhân 0,4; tỉ lệ cơ bản trước pity là 62 / 25 / 9,5 / 2,7 / 0,7 / 0,1% của phần cosmetic. Không-lặp theo tầng: còn món chưa có thì chỉ ra món chưa có; hết món thì ra đồ trùng.

Phân bổ EV Stone theo stack (chia 242,5): 100 → 6,3%; 250 → 24,8%; 500 → 26,8%; 1.000 → 24,7%; 2.500 → 16,5%; jackpot → 0,8% (cũ 8,2%). Lý do (variable ratio): nhiều chiến thắng nhỏ đều đặn (60% lượt "có gì đó"); cú lớn nhất giờ là chuyện hiếm hẳn (1/5.000), còn cú "khá to" là stack 2.500 (1,6% = 1/62,5 lượt) để người chơi vẫn có chuyện để nhớ. Stone không đổi ra Shard nên stack 100 không phải "thua tiền".

### 3.2 Sàn / trần và kỳ vọng

- **Pity cứng, đếm theo lượt cosmetic** (lượt ra Stone không làm bộ đếm tăng): 15 lượt cosmetic không có ≥ Rare thì lượt kế chắc ≥ Rare; 60 / 200 / 1.000 cho Epic / Legendary / Mythic. Giữ nguyên số cũ nên tỉ lệ hiệu dụng ở trên đúng. Chạm hai ngưỡng thì cấp cao nhất, reset các bộ đếm thấp. Không có pity cho Stone (xác suất 10 lượt liền không Stone = 0,4¹⁰ = 0,01%).
- Số lượt trung bình tới món đầu tiên của tầng (≥ tầng đó): Rare+ `1/(0,4 × 0,15518)` = **16,1**; Epic+ `1/(0,4 × 0,04218)` = **59,3**; Legendary+ `1/(0,4 × 0,01058)` = **236**; Mythic `1/(0,4 × 0,00158)` = **1.582**. Stone: cỡ 1.000+ cứ ~13 lượt (7,62% → 1/0,0762 = 13,1), 2.500+ ~62 lượt (1,62% → 61,7), jackpot **5.000 lượt** (SỬA 10/10, cũ 500).
- Số lượt tới khi **đủ cả tầng** (bộ sưu tập chậm gấp 2,5 so với cũ): Common 252,5 · Uncommon 565 · Rare 1.040 · Epic 2.215 · Legendary 5.555 · Mythic 18.988 lượt (= lượt cosmetic cũ 101 / 226 / 416 / 886 / 2.222 / 7.595 chia 0,4).

---

## 4. Hộp mùa — bảng rơi (5 vé/lượt)

### 4.1 Cơ chế mỗi lượt (thay thứ tự của `echobox-pass-v2.md` §2.8)

Mỗi tầng chưa đủ có bộ đếm `c_t` (lượt kể từ lần tầng đó trúng, không reset theo ngày) và trần `N_t`. Công thức odds leo dần giữ nguyên: `p_t(c) = (2c − 1) / (N_t² − (c−1)²)` (k = 2), `p_t(N_t) = 1`.

1. `c_t += 1` cho mọi tầng chưa đủ.
2. **Đến hạn thắng ngẫu nhiên:** nếu có tầng chưa đủ với `c_t ≥ N_t`, lấy tầng cao nhất. Xong lượt (ra cosmetic).
3. Không tầng nào đến hạn: thử lần lượt Mythic → Legendary → Epic. Tầng chưa đủ trúng với `p_t(c_t)`; tầng đã đủ trúng với `b_t` (ra đồ trùng). Tầng đầu tiên trúng là kết quả.
4. **Không tầng nào trúng → ra Stone**, bốc từ bảng 4.2.
5. Reset `c_t = 0` cho tầng vừa trúng (nếu nó chưa đủ trước lượt này).

| Tầng | Món | Trần N | `p(1)` | Lượt TB / món | `b_t` khi đủ | Trùng → vé |
|---|---|---|---|---|---|---|
| Mythic | 2 | 40 | 0,0625% | 27,16 | 1% | 8 |
| Legendary | 3 | 20 | 0,25% | 13,83 | 3% | 4 |
| **Epic (mới)** | 6 | **10** | 1,0% | 7,15 | 8% | 2 |

Lượt TB = `N − (N−1)(2N−1)/(6N)`: Epic `10 − 9×19/60` = 7,15; Legendary `20 − 19×39/120` = 13,83; Mythic `40 − 39×79/240` = 27,16. Mẫu Epic: p(5) = 9/84 = 10,7%; p(8) = 15/51 = 29,4%; p(9) = 17/36 = 47,2%; p(10) = 100%. Mythic và Legendary giữ bảng mẫu cũ. Độc quyền `die_m_moon` ở mốc 40 lượt mở là phần thưởng thêm ngoài lượt, không chiếm lượt, không kèm Stone.

### 4.2 Bảng rơi

**Khi không tầng nào trúng (≈ 78% lượt), ra Stone:**

| Stone | Xác suất (trong lượt Stone) | Mỗi lượt mùa trung bình (× 0,78) | EV |
|---|---|---|---|
| 500 | 32,74% | 25,54% | 163,7 |
| 1.000 | 45,13% | 35,20% | 451,3 |
| 2.500 | 17,50% | 13,65% | 437,5 |
| 5.000 | 4,60% | 3,59% | 230,0 |
| **25.000 (jackpot)** | **0,03%** | **0,0234%** (1/4.274 lượt mùa) | 7,5 |
| Tổng | 100% | 78,0% | **1.290 / lượt Stone; 1.006 / lượt mùa** |

SỬA 10/10: jackpot thật nhỏ (cũ 0,2% trong lượt Stone = 0,16% mỗi lượt mùa = 1/625). Kiểm xác suất: 32,74+45,13+17,50+4,60+0,03 = 100,00. Kiểm EV: 500×0,3274 = 163,7 · 1.000×0,4513 = 451,3 · 2.500×0,175 = 437,5 · 5.000×0,046 = 230 · 25.000×0,0003 = 7,5; cộng 1.290,0, bằng bản cũ. Mỗi lượt mùa: nhân 0,78 (32,74 → 25,54; 45,13 → 35,20; 17,5 → 13,65; 4,6 → 3,59; 0,03 → 0,0234; cộng 78,0). 1.290 × 0,78 = 1.006,2. Jackpot mùa: 1/0,000234 = 4.274 lượt = 21.370 vé. Một người đủ bộ mỗi mùa (~4,58 lượt/tuần ≈ 238 lượt/năm) gặp trung bình 0,056 jackpot/năm, tức gần như không bao giờ trong một năm; đây là chủ ý "thật nhỏ", nhưng nghĩa là với hộp mùa jackpot là truyền thuyết hơn là phần thưởng người chơi trông đợi. Nếu Liam muốn nó còn dễ thấy hơn thì tăng lên 0,05%, nhưng đó vẫn là ≤ 0,05% mỗi lượt.

**Cosmetic (≈ 22% lượt, theo bộ đếm):** trong 55 lượt điển hình có 11 lượt ra món mới (6 Epic, 3 Legendary, 2 Mythic) và ~1,3 lượt trùng (E 0,92 + L 0,40), tức 12,3/55 = 22,4% cosmetic, **77,6% ≈ 78% Stone**. Nửa bộ (27,5 lượt đầu): ~5,8 món mới/27,5 = 21%, Stone 79%. Dùng 78% cho cả hai.

Lý do cỡ stack: stack thấp nhất 500 = 5 × stack 100 của hộp thường; EV mỗi vé 1.006/5 = **201** so với 242,5 của hộp thường khi chưa hồi vé (83%). Không bằng 100% vì mỗi lượt mùa còn có ~22% là cosmetic cực hiếm; Stone của hộp mùa vẫn *lớn hơn từng lượt* nhưng người chỉ muốn lên Land nên quay hộp thường. Vault (series cũ, N nhân đôi): chưa tính riêng, Stone ~88% lượt nên ~1.140/lượt, giữ cùng bảng.

### 4.3 Chứng minh bound ≤ 80 lượt khi Stone là ô "không trúng"

Stone chỉ được bốc ở bước 4, **sau** bước 2 (đến hạn). Nên Stone không bao giờ chiếm lượt của một tầng đã đến hạn. Với tầng t, gọi `h_t` = số tầng cao hơn nó (Mythic 0, Legendary 1, Epic 2). Sau khi tầng t trúng, bộ đếm về 0 và tới hạn sau đúng `N_t` lượt; lượt đó chỉ bị chặn bởi tầng cao hơn cũng đến hạn, mỗi tầng cao hơn chặn tối đa một lần (vì nó vừa trúng thì bộ đếm về 0 và `N_t > h_t`). Vậy món kế của tầng t trúng không muộn hơn `N_t + h_t` lượt sau món trước:

```
B(Epic)      = 6 × (10 + 2) = 72
B(Legendary) = 3 × (20 + 1) = 63
B(Mythic)    = 2 × (40 + 0) = 80
B = max = 80 lượt. Mythic đầu tiên ≤ 40.
```

Điều kiện: mọi `N_t > h_t` (10 > 2, 20 > 1, 40 > 0 đều đúng), bước 2 đi trước. Đồ trùng của tầng đã đủ nằm ở bước 3 nên không chặn được tầng đến hạn. Điển hình **~55 lượt**: chuỗi Mythic 2 × 27,16 = 54,3 là chuỗi dài nhất (Epic 6 × 7,15 = 42,9; Legendary 3 × 13,83 = 41,5), cộng ~1 lượt do chặn lẫn nhau. Số điển hình là ước tay, cần sim 100.000 series (ECO-15).

---

## 5. Đồ trùng và chứng minh không vòng lặp

Bảng đổi: Common 3 · Uncommon 5 · Rare 10 · Epic 20 · Legendary 40 · Mythic 80 mảnh, 10 mảnh = 1 vé (10 trùng Common = 30 mảnh = 3 vé, đúng ví dụ Liam). Một loại vé, hai hộp dùng chung.

**Hộp thường (hồi vé theo tiến độ).** `ν` = hồi vé mỗi lượt cosmetic khi đủ các tầng tới đó (không đổi so với bản cũ: 0,1806 / 0,3021 / 0,4151 / 0,4783 / 0,5143 / 0,5269). Mỗi lượt chỉ 40% là cosmetic nên `ν_p = 0,4 × ν`:

| Đủ tầng | Sau lượt thứ | `ν_p` (vé/lượt) | Hồi / giá | Stone mỗi vé không-tái-chế = 242,5 / (1 − ν_p) |
|---|---|---|---|---|
| (chưa) | 0 | 0 | 0 | 242,5 |
| Common | 252,5 | 0,07224 | 7,2% | 261,4 |
| Uncommon | 565 | 0,12084 | 12,1% | 275,8 |
| Rare | 1.040 | 0,16604 | 16,6% | 290,8 |
| Epic | 2.215 | 0,19132 | 19,1% | 299,9 |
| Legendary | 5.555 | 0,20572 | 20,6% | 305,3 |
| Mythic | 18.988 | 0,21076 | **21,1%** | 307,3 |

Cũ: hồi tối đa 0,527 vé/lượt. Mới 0,211: bộ sưu tập chậm hơn, ít trùng hơn, vòng tái chế yếu hơn hai lần rưỡi.

**Hộp mùa.** Khi cả ba tầng đã đủ: xác suất ra M / L / E trùng = 1% / 0,99×3% = 2,97% / 0,99×0,97×8% = 7,68%. Hồi = 0,01×8 + 0,0297×4 + 0,0768×2 = 0,08 + 0,1188 + 0,1536 = **0,352 vé/lượt**, chia giá 5 vé = **0,0705**.

**Không vòng lặp vô hạn.** Một vé bỏ ra (ở hộp nào cũng vậy) sinh ra kỳ vọng ≤ max(0,211; 0,0705) = **0,211** vé mới; không cạnh nào về Shard hay Stone (ECO-3). Quá trình vé→lượt→mảnh→vé là chuỗi hình học tỉ số < 1: từ n vé, tổng vé bỏ ra ≤ n / (1 − 0,211) = **1,267 n**. Hồi thực tế còn thấp hơn vì chỉ tính trùng sau khi đủ tầng và mảnh lẻ < 10 bị giữ lại.

---

## 6. Persona: lượt, Stone, thời gian tới LunaLanding

### 6.1 Mô hình

Với T = số vé không-tái-chế đã dùng ở hộp thường, số lượt P(T) tính từ bảng §5. Mốc (T, P): (252,5; 252,5) · (542,4; 565) · (960,0; 1.040) · (1.939,9; 2.215) · (4.640,9; 5.555). Độ dốc `dP/dT = 1/(1 − ν_p)`: 1,078 · 1,137 · 1,199 · 1,237 · 1,259. Stone hộp thường = 242,5 × P.

Tổng Stone sau t tuần = `242,5 × P(b_std × t)` + `(Stone cố định + Stone hộp mùa) × t`, giải bằng 1.820.000.
- Stone cố định: casual 2.000 (ngày) + 2.000 (tuần) + 2.062,5 (Pass) = **6.062,5**; regular/heavy 3.500 + 2.000 + 2.062,5 = **7.562,5**.
- Stone hộp mùa: nửa bộ 2,2917 lượt × 1.006,2 = **2.306**; đủ bộ 4,5833 × 1.006,2 = **4.612**.

Ví dụ heavy nửa bộ: `b_std` = 97,5 − 11,46 = 86,04. t = 52,28: T = 4.498,2 → P = 2.215 + (4.498,2 − 1.939,9)/0,80868 = 2.215 + 3.163,4 = 5.378,4 → hộp thường 5.378,4 × 242,5 = 1.304.262; cố định+mùa 9.868,4 × 52,28 = 515.918; tổng **1.820.180** ✓.

### 6.2 Vé/lượt mỗi tuần (R = 450)

| | | Không mua mùa | Nửa bộ | Đủ bộ |
|---|---|---|---|---|
| Casual | Vé đầu cho hộp thường `b_std` (→ lượt TB cả hành trình) | 29,2 (→ 34,6) | 17,7 (→ 20,6) | 6,6 (→ 7,1) |
| | Lượt hộp mùa/tuần | 0 | 2,29 | 4,58 |
| Regular | `b_std` (→ lượt TB) | 35,7 (→ 42,3) | 24,2 (→ 28,3) | 13,1 (→ 14,7) |
| | Lượt mùa/tuần | 0 | 2,29 | 4,58 |
| Heavy | `b_std` (→ lượt TB) | 97,5 (→ 117,1) | 86,0 (→ 102,9) | 74,9 (→ 89,2) |
| | Lượt mùa/tuần | 0 | 2,29 | 4,58 |

(Lượt TB = Stone hộp thường trung bình/tuần ÷ 242,5; cao hơn `b_std` nhờ tái chế.)

### 6.3 Stone/tuần theo nguồn (trung bình cả hành trình tới LunaLanding, R = 450)

| Persona · hành vi | Hộp thường | Hộp mùa | Thưởng ngày+tuần | Pass | Nhiệm vụ (chưa tính) | **Tổng/tuần** |
|---|---|---|---|---|---|---|
| Casual · không | 8.399 | 0 | 4.000 | 2.063 | 0 | 14.462 |
| Casual · nửa | 4.994 | 2.306 | 4.000 | 2.063 | 0 | 13.363 |
| Casual · đủ | 1.723 | 4.612 | 4.000 | 2.063 | 0 | 12.398 |
| Regular · không | 10.263 | 0 | 5.500 | 2.063 | 0 | 17.826 |
| Regular · nửa | 6.859 | 2.306 | 5.500 | 2.063 | 0 | 16.728 |
| Regular · đủ | 3.562 | 4.612 | 5.500 | 2.063 | 0 | 15.737 |
| Heavy · không | 28.405 | 0 | 5.500 | 2.063 | 0 | 35.968 |
| Heavy · nửa | 24.945 | 2.306 | 5.500 | 2.063 | 0 | 34.814 |
| Heavy · đủ | 21.623 | 4.612 | 5.500 | 2.063 | 0 | 33.798 |

Kiểm: 1.820.000 / tuần tới Land (ví dụ heavy nửa 1.820.000/52,28 = 34.813). Hộp thường của heavy ở năm cuối lớn hơn năm đầu vì tái chế tăng dần.

### 6.4 Tuần tới LunaLanding

| R = 450 | Không mua mùa | Nửa bộ | Đủ bộ |
|---|---|---|---|
| Casual | 125,9 | 136,2 | 146,8 |
| Regular | 102,1 | 108,8 | 115,7 |
| Heavy | 50,6 | **52,3** | 53,9 |

Độ nhạy R, hành vi nửa bộ (tuần): 

| R | Casual | Regular | Heavy |
|---|---|---|---|
| 350 | 151,1 (2,90 năm) | 121,1 (2,32) | 60,1 (1,15) |
| 450 | 136,2 (2,61) | 108,8 (2,09) | 52,3 (1,00) |
| 570 | 122,6 (2,35) | 97,6 (1,87) | 45,9 (0,88) |

Mục tiêu Liam: heavy ~52, regular ~78, casual ~99 tuần. Heavy khớp (R = 450). Regular/casual chậm hơn 39% / 37% ở nửa bộ (OQ-1). Tỉ lệ heavy : regular : casual = 1 : 2,08 : 2,60.

**Biến thiên do may mắn (±1σ, chỉ phần hộp thường), SỬA 10/10 sau khi hạ jackpot:** Stone mỗi lượt hộp thường có E[x²] = 0,153×10⁴ + 0,2408×62.500 + 0,13×250.000 + 0,06×10⁶ + 0,016×6,25×10⁶ + 0,0002×10⁸ = 1.530 + 15.050 + 32.500 + 60.000 + 100.000 + 20.000 = 229.080 → var = 229.080 − 242,5² (58.806) = 170.274, SD ≈ **413/lượt** (cũ 594). Heavy ~5.380 lượt: SD = 413 × √5.380 = 30.300 Stone ≈ **±0,9 tuần** (cũ ±1,3); casual nửa bộ ~2.800 lượt: SD = 413 × 52,9 = 21.800 ≈ **±1,6 tuần** (cũ ±2,4). Chưa tính hộp mùa. Heavy gặp jackpot thường ~5.380/5.000 ≈ **1,1 cái/năm** (cũ ~11), tức chừng 11.000 Stone ≈ 0,6% đường Land (cũ 6%).

**Stone sau 26 tuần (nửa bộ):** casual ~323k (vừa qua mốc Mystic 320k), regular ~410k (Mystic), heavy ~897k (Genesis, mốc 820k).

Mốc hoàn tất tầng hộp thường theo tuần (nửa bộ, vé đầu b_std / 86,0, 24,2, 17,7): Common xong ở tuần 2,9 / 10,4 / 14,2 (heavy / regular / casual); Uncommon 6,3 / 22,4 / 30,6; Rare 11,2 / 39,6 / 54,1; Epic 22,5 / 80 / 109; Legendary 53,9 / 191 / 261. Heavy cũng chỉ vừa kịp Legendary vào năm thứ hai; Mythic của hộp thường gần như không ai đủ bộ.

---

## 7. Chi phí bộ mùa so với Shard 12 tuần

Ròng điển hình = 275 − 3,5 = **271,5 vé**; nửa bộ 137,5; trần cứng 80 lượt = 400 vé (hoàn ≥ 0, tính cận trên). Giá = vé × giá TB (232 / 220 / 278).

| | Shard 12 tuần | Nửa bộ 137,5 vé | % | Điển hình 271,5 vé | % | Trần cứng 400 vé | % |
|---|---|---|---|---|---|---|---|
| Casual | 77.076 | 31.900 | **41,4%** | 62.988 | **81,7%** | 92.800 | **120,4%** |
| Regular | 90.480 | 30.250 | **33,4%** | 59.730 | **66,0%** | 88.000 | **97,3%** |
| Heavy | 319.836 | 38.225 | **12,0%** | 75.477 | **23,6%** | 111.200 | **34,8%** |

Ở R = 350, tỉ lệ của casual/regular tăng ~+20–23% (thu nhập thấp hơn tỉ lệ nghịch). Cũ (hộp mùa cho Stone, Epic là ô trùng 85%): 188 vé ròng, 56,6 / 45,7 / 16,3%. Giờ đắt hơn ~44% vì hoàn vé gần như mất; đổi lại Stone của hộp mùa tự bù lại (201 Stone/vé). Vault: series cũ N nhân đôi (bound 160 lượt = 800 vé), mở bằng cùng vé, không hạn.

---

## 8. Shard 6 tháng (26 tuần, R = 450)

Mua 10.350 unlock ngay từ đầu (cực đại); Pass bình quân; hết Shard vào vé mỗi ngày (A3).

| | Casual | Regular | Heavy |
|---|---|---|---|
| Shard vào | 166.998 | 196.040 | 692.978 |
| Unlock | −10.350 | −10.350 | −10.350 |
| Vé mua (sau unlock) + Pass 39 | 681 + 39 = 720 | 847 + 39 = 886 | 2.468 + 39 = 2.507 |
| Cho hộp mùa: đủ bộ (26/12 × 275 = 596) / nửa (298) | 596 / 298 | 596 / 298 | 596 / 298 |
| Còn cho hộp thường: đủ / nửa | 124 / 422 | 290 / 588 | 1.911 / 2.209 |
| **Số dư Shard cuối kỳ** | < 1 vé (~200–300) | < 1 vé | < 1 vé |

Không ai dư Shard vì Shard chỉ có một đường tiêu (vé) và không có chi bắt buộc. Casual đủ bộ để lại chỉ 124 vé cho hộp thường trong 6 tháng, tức Stone hộp thường gần như không tăng (xem 1.723/tuần ở §6.3). Echo Market tiếp tục hoãn (A10); chỉ bật khi telemetry thấy p90 số dư > 8 tuần thu nhập.

---

## 9. Nhiệm vụ và bundle

**Ngân sách Nhiệm vụ (hệ thống tương lai).** Stone ≤ **150/ngày hoạt động** (≤ 600/tuần casual, ≤ 1.050/tuần regular/heavy). Phần lớn lượng Stone này vẫn "rất nhỏ": 4,5% / 6,3% / 3,0% Stone tuần của casual / regular / heavy (nửa bộ). Nếu kiếm đủ cả trần, Land nhanh hơn ≈ casual −5,9 tuần (136,2 → ~130), regular −6,4 (108,8 → ~102), heavy −1,5 (52,3 → ~50,8). Mốc thời gian ở §6 **chưa tính** nhiệm vụ. Shard: không có Shard cho không; thưởng Shard chỉ từ stake của người chơi với RTP ≤ 100%, người chơi được phép lỗ cả 5 nhiệm vụ. Nếu sau này muốn tặng Shard thật, ngân sách ≤ 40 Shard/ngày hoạt động (~0,6–3% thu nhập) để vẫn dưới sai số.

**Bundle vé (quyết định 4, không hàng rào).** Vé bundle ra Stone như vé thường (hộp thường ~242–307 Stone/vé tùy tiến độ). Hành vi nửa bộ, tuần tới Land:

| | Không bundle | +50 vé/tuần | +100 vé/tuần |
|---|---|---|---|
| Heavy | 52,3 | 36,8 (1,4×) | 28,4 (1,8×) |
| Regular | 108,8 | 58,0 (1,9×) | 39,5 (2,8×) |
| Casual | 136,2 | 65,0 (2,1×) | 42,6 (3,2×) |

Người nạp lên Land nhanh gấp ~1,4–3,2 lần tùy mức nạp. Casual/regular hưởng nhiều hơn heavy vì phần vé thêm so với vé họ có lớn hơn. Chỉ nêu hệ quả, không guardrail. Trần server (ECO-7) chỉ để chặn bug.

---

## 10. Battle Pass và Thưởng ngày (giữ nguyên)

Theo `echobox-pass-v2.md` §3–§4 và A1–A11: Pass 30 level, mùa 8 tuần, 32.400 XP; thưởng Shard 4.800 + Stone 16.500 + vé 12 + cosmetic; vòng lặp sau lv30 **2.000 XP = 50 Shard** (trần ~405 Shard/tuần ở XP tối đa, ≤ 1,5% thu nhập heavy; XP lẻ đổi cùng tỉ lệ, không mang sang). Thưởng ngày 60 Shard + 500 Stone + 100 XP; ≥ 4 ngày/tuần +150 Shard + 2.000 Stone; Stone guest chờ 7 ngày. Vé Pass không tăng bậc k. Casual 6,0 tuần / regular 4,7 tuần / heavy 14,7 ngày xong Pass; sàn 14,0 ngày.

---

## 11. Núm, bất biến, telemetry, câu hỏi mở

### 11.1 Núm (mọi số trong `assets/data/`, không hardcode)

| Núm | Mặc định | Khoảng an toàn | Độ nhạy (đã tính) |
|---|---|---|---|
| `ticket_price_base` | **200** (Liam chốt) | | |
| `ticket_price_growth` / `ticket_buy_cap_day` | 1,05 / 30 | 1,03–1,07 / 20–50 | |
| `season_pull_cost_tickets` | 5 | 4–6 | |
| `season_pull_cap_day` | 8 | 6–10 | |
| `std_stone_share` | 60% | 50–70% | mean 242,5 cố định: đổi share là đổi ν (cosmetic nhiều/ít), phải sim lại |
| `std_stone_table` | 100/250/500/1.000/2.500/10.000 ở 15,30/24,08/13/6/1,6/**0,02**% (SỬA 10/10) | EV 225–260; jackpot ≤ 0,05% | ±10 Stone/lượt ≈ ∓1,5 tuần heavy, ∓1,8 regular |
| `std_jackpot_rate` | **0,02%** (1/5.000) | 0,01–0,05% | đổi jackpot phải dồn/rút EV ở 1.000–2.500 để giữ 242,5 |
| `season_stone_table` | 500/1.000/2.500/5.000/25.000 ở 32,74/45,13/17,5/4,6/**0,03**% trong lượt Stone (SỬA 10/10) | EV/lượt Stone 1.100–1.600; jackpot ≤ 0,06% (= 0,05% mỗi lượt mùa) | EV/vé 201 = 83% hộp thường |
| `season_jackpot_rate` | **0,03%** trong lượt Stone = 0,0234% mỗi lượt mùa (1/4.274) | 0,01–0,06% | như trên, giữ 1.290 |
| `season_N_E / N_L / N_M`, `k` | 10 / 20 / 40, 2 | N_t > h_t; N_M ≥ 30 | N_M = 50 → bound 100 |
| `season_dupe_rate b_E/b_L/b_M` | 8% / 3% / 1% | 0–15% | b_E 0 → hoàn ~1,6 vé, chi phí +0,6% |
| `dupe_fragments` | 3/5/10/20/40/80 | Common 2–4, Mythic 60–100 | |
| `fragments_per_ticket` | 10 | 8–12 | |
| `pity_std` (lượt cosmetic) | 15/60/200/1.000 | | |
| `series_weeks` | 12 | 8–16 | |
| `daily_stone` | 500 | 300–1.100 | 700 → heavy 50,3 · regular 100,6 · casual 128,7 (nửa bộ) |
| `weekly_bonus` | 150 Shard + 2.000 Stone, ≥ 4 ngày | 3–5 ngày | |
| `pass_*`, `pass_loop` | như §10 | T_min ≥ 14 ngày | |
| `mission_stone_day_cap` | 150 | 100–200 | |
| `land_cost[5]` | 40k/100k/180k/500k/1M | Liam chốt | |
| `final_stretch` | tắt | | |

Bỏ khỏi bản cũ: `stone_window_day`, `recycle_stone_window_day`, `recycled_pull_stone_scale`, `stone_by_rarity`, `season_first_hit_stone`, `vault_first_hit_scale`, `rho_max`.

### 11.2 Bất biến (tiền tố ECO)

| # | Bất biến |
|---|---|
| ECO-1 | Nâng Land chỉ trừ Stone |
| ECO-2 | Vé thứ k mua Shard trong ngày UTC giá `round5(200 × 1,05^(k−1))`, ≤ 30/ngày, một thang chung; vé Pass/tái chế/starter/bundle không tăng k |
| ECO-3 | Mở hộp và đổi trùng không bao giờ cộng Shard; không có đường vé/mảnh/Stone → Shard |
| ECO-4 | **Mỗi lượt ra đúng một phần thưởng** (Stone XOR cosmetic). Hộp thường: Σ = 100% (±0,001), Stone 60% (±0,5 sim 100.000 lượt), EV Stone 242,5 (±3%) |
| ECO-5 | Không có cửa sổ Stone theo ngày ở bất kỳ hộp nào. Chặn duy nhất: ECO-7 |
| ECO-6 | Hồi vé/lượt: hộp thường ≤ 0,25 (hiện 0,211), hộp mùa ≤ 0,10 mỗi vé bỏ ra (hiện 0,0705). Test: 100.000 vé mua → tổng vé bỏ ra ≤ 1,30 × 100.000 |
| ECO-7 | Server chặn Stone Echo > 80.000/ngày/tài khoản (cao hơn 3 × stack lớn nhất, chỉ chặn bug) và vé giữ ≤ 999. (Số 24.000 cũ sẽ cắt jackpot nên bỏ). SỬA 10/10: vẫn giữ 80.000. Trần này chưa bao giờ được tính theo tần suất jackpot, chỉ theo độ lớn stack (3 × 25.000 = 75.000, làm tròn 80.000); jackpot hiếm hơn không làm trần sai, và hạ trần xuống dưới 25.000 sẽ cắt jackpot nên không hạ |
| ECO-8 | Pity hộp thường theo lượt cosmetic: không quá 15/60/200/1.000 lượt cosmetic liền không có ≥ Rare/Epic/Legendary/Mythic |
| ECO-9 | `T_min = 32.400 / (2.000 + 100 + 1.500/7) = 14,0 ngày ≥ 14`; Pass: Shard 4.800, Stone 16.500, vé 12 |
| ECO-10 | Stone và vé do server cấp, kiểm ngày UTC. Ghi qua `SaveStore`; field mới (vé theo nguồn, mảnh, pity, bộ đếm series) vào `MetaState.reload_from_store()` |
| ECO-11 | Timeline sim (R = 450, nửa bộ): heavy 52 ±10%, regular 109 ±15%, casual 136 ±15%; không mua mùa / đủ bộ theo §6.4 |
| ECO-12 | Stone nhiệm vụ ≤ 150/ngày hoạt động |
| ECO-13 | **SỬA 12/10 (B3):** unlock chỉ số **tính trong Ranked** (không còn = 0); ai đã có unlock thì mốc Pass trả Shard bằng giá shop. Test: run ranked nhận đúng bonus của loadout tài khoản, và verifier tái tạo cùng bonus từ loadout |
| ECO-14 | Một lượt mùa trừ đúng 5 vé; bảng Stone mùa chỉ bốc khi không tầng nào trúng và không tầng nào đến hạn; ≤ 8 lượt mùa/ngày |
| ECO-15 | S1 đủ trong ≤ 80 lượt, Mythic đầu ≤ 40; sim 100.000 series: max ≤ 80, mean 55 ±3, Stone mùa 78% ±2 |
| ECO-16 | Bảng đổi trùng đơn điệu tăng theo độ hiếm; 10 trùng Common → 3 vé |
| ECO-17 | Vòng lặp Pass: 2.000 XP = 50 Shard, ≤ 405 Shard/tuần, XP lẻ đổi cùng tỉ lệ, không mang sang |
| ECO-18 | Bundle: lượt dùng vé bundle ra đúng bảng thường, không trần/tuần riêng |
| ECO-19 | **Hộp mùa không có Stone một lần theo món mới** (khoản 9.300 cũ bị xóa; trúng cosmetic = hết phần thưởng lượt đó) |
| ECO-20 | **Jackpot thật nhỏ (SỬA 10/10):** hộp thường jackpot 10.000 = 0,02% mỗi lượt (±0,01 điểm %, sim 100.000 lượt chỉ kỳ vọng ~20 cái nên kiểm bằng đếm trọng số trong bảng, không bằng sim); hộp mùa jackpot 25.000 = 0,03% trong lượt Stone. Không jackpot nào > 0,05% mỗi lượt của hộp nó. Đổi tỉ lệ jackpot thì EV 242,5 / 1.290 phải giữ trong ±3% |

### 11.3 Telemetry

1. Sổ vé theo `origin` (shard / recycle / pass / starter / bundle); tỉ lệ lượt dùng vé tái chế (kỳ vọng thấp hơn bản cũ: heavy ~16% lượt năm đầu = (5.378 − 4.498)/5.378, casual/regular thấp hơn).
2. Vé mua/ngày p10/p50/p90 (đối chiếu 6,9 / 4,9 / 13,7); % ngày chạm cap 30.
3. Tỉ lệ ra Stone mỗi hộp (60% / 78%), phân phối stack, EV thực mỗi lượt (242,5 / 1.006), tần suất jackpot (1/5.000 lượt thường / 1/4.274 lượt mùa; SỬA 10/10, cũ 1/500 và 1/625). Vì quá hiếm nên đếm trên toàn bộ người chơi, không theo từng người.
4. Stone/tuần theo nguồn; thời gian tới từng bậc Land p10/p50/p90 theo hành vi mùa.
5. Hộp mùa: % người mở, lượt/series (đối chiếu 55, max 80), vé ròng/series (271,5), % Shard 12 tuần cho mùa (82 / 66 / 24).
6. Hồi vé thực tế mỗi hộp (≤ 0,211 / 0,0705), % chạm pity.
7. Số dư Shard p90 (cờ đỏ > 8 tuần thu nhập).
8. Pass: ngày xong (min ≥ 14), Shard từ vòng lặp (≤ 405/tuần).
9. R thật theo mode; Echo Stone/ngày p99 so với trần 80.000; Stone/ngày từ bundle.
10. Mission Stone/ngày thật so với 150.

### 11.4 Câu hỏi mở (chỉ những gì Liam còn phải trả lời)

| # | Câu hỏi | Đề xuất |
|---|---|---|
| OQ-1 | Với heavy ghim ở ~1 năm, regular ra **2,09 năm** (mục tiêu 1,5) và casual **2,61 năm** (mục tiêu 1,9), chậm hơn ~38%. Số này lớn hơn con số Liam đã thấy. Chấp nhận như đã duyệt, hay nâng nguồn Stone cố định? | Để nguyên (đúng quyết định "không catch-up"). Nếu muốn nới: `daily_stone` 500 → 700 kéo regular về 100,6, casual 128,7 (heavy 50,3); chỉ tính khi telemetry cho thấy người chơi bỏ cuộc |
| OQ-2 | Trần cứng 80 lượt = 400 vé = **120% Shard 12 tuần của casual** (97% regular). Casual không thể chắc đủ bộ trong một mùa. Giữ ≤ 80, hay hạ trần (cần đổi N_E/N_L/N_M và tính lại điển hình ~55)? | Giữ 80: điển hình mới là mức người chơi thực trả (82% casual), phần còn lại là bộ vào Vault không hạn. Chỉ hạ nếu playtest cho thấy casual nản |
| OQ-3 | ĐÃ CHỐT 10/10 (Liam: giữ 10.000 / 25.000, tỉ lệ thật nhỏ). Đã hạ xuống 0,02% (1/5.000) và 0,03% (1/4.274 lượt mùa), xem §3.1 / §4.2. Heavy gặp ~1,1 jackpot thường/năm | Không còn câu hỏi. Nếu muốn jackpot mùa dễ thấy hơn, tăng tới 0,05% (xem §4.2) |

Đăng ký registry (`design/registry/entities.yaml`): vé, mảnh, bảng đổi trùng, 5 vé/lượt mùa, giá cơ sở 200, các stack Stone. Liam đã cho phép (10/10); đã đăng ký ngày 10/10/2026 với `status: active` kèm comment "đề xuất Liam đã duyệt, chưa vào GDD" (registry chỉ có active | deprecated). Số ước, chưa sim: số lượt điển hình 55, hồi 3,5 vé, 78% Stone mùa; cần sim 100.000 series và 100.000 lượt hộp thường trước khi chốt.

---

## 12. Game-designer phải sửa trong `echobox-pass-v2.md` §2–§4 cho khớp

**§2 (Echo Box)**
1. **Một loại vé, bỏ `season_ticket`**: §2.0 đọc nhanh, §2.2 (bảng 2 hộp), §2.3 (vé), §2.4 (hai thang giá, tỉ lệ 3×, OQ-27) viết lại: một thang `round5(200 × 1,05^(k−1))`, hộp thường 1 vé, hộp mùa 5 vé/lượt; bỏ bộ đếm `season_dupe_count`; quà khởi đầu 3 vé chung.
2. **Mô hình bảng rơi, mỗi lượt đúng một phần thưởng**: thêm Stone vào bảng rơi cả hai hộp; bỏ cửa sổ 20 lượt/ngày (§2.4 dòng "Cửa sổ Stone", §2.6) và bỏ "Stone mỗi lượt theo độ hiếm 80/160/400/1.000/2.500/8.000" (§2.7).
3. **§2.7 hộp thường**: thay bảng "Tỉ lệ cơ bản và Stone" bằng bảng §3.1 của file này (Stone 60% gồm 6 stack, cosmetic 40%); pity đếm theo lượt cosmetic; thời gian tới đủ tầng nhân 2,5 (252 / 565 / 1.040 / 2.215 / 5.555 / 18.988 lượt).
4. **§2.8 hộp mùa**: Epic thành tầng có odds leo dần (N_E = 10, b_E = 8%), không còn là ô mặc định; ô không trúng = Stone theo bảng 4.2; thứ tự xử lý 5 bước như §4.1; bound `B = max(72, 63, 80) = 80`; xóa bảng bound cũ và dòng "Epic ~1".
5. **§2.5 đồ trùng**: một bảng 3/5/10/20/40/80 mảnh (cũ 1/2/5/15/40/100 và "6 trùng = 1 vé Mùa"), 10 mảnh = 1 vé; hồi hộp thường tối đa 0,211/lượt, hộp mùa 0,0705 mỗi vé; sửa chứng minh (một vòng chung, tỉ số 0,211).
6. **§2.6 Land Stone**: thay bảng "Stone một lần 9.300" bằng Stone là phần thưởng bảng rơi hộp mùa; xóa `season_first_hit_stone`; bảng tuần tới Land thay bằng §6.4 file này.
7. **§2.9 mốc 12/40**: giữ danh hiệu và `die_m_moon`, **bỏ Stone 2.000 ở mốc 40**.
8. **§2.10 Vault**: bỏ `vault_first_hit_scale`; N nhân đôi giữ; Stone mùa giữ cùng bảng.
9. §0 mục 1, 4, 5, 8: sửa "hai loại vé", "đồ trùng không nuôi hộp kia", "hộp mùa gần như trung tính", "Pass trả 8 vé Echo + 4 vé Mùa".

**§3 (Battle Pass)**: Pass trả **12 vé chung** (bỏ "8 Echo + 4 Mùa"); mọi dòng nhắc `season_ticket` đổi thành "vé".

**§4 (Thưởng ngày)**: không đổi số; chỉ sửa các dòng nhắc cửa sổ Stone 20 lượt và vé Echo/Mùa thành "vé".
