Trạng thái: CHỐT THIẾT KẾ (12/10) — chờ review nhanh

> **QUYẾT ĐỊNH LIAM còn hiệu lực (gom lại, ưu tiên hơn thân file). Chỗ nào ghi THAY là đã ghi đè quyết định cũ.**
> - Nhiệm vụ = cược (stake) + thưởng tăng theo độ khó. Cược bằng **Gene Shard**; thắng có thêm **Land Stone rất ít**. Thua thì **mất cược, không hoàn, không an ủi gì** (12/10 chốt lại). Người chơi được phép lỗ bao nhiêu cũng được.
> - **THAY (12/10): bỏ giới hạn "tối đa 5 Nhiệm vụ/người/ngày". Hiện tại KHÔNG có giới hạn số lần mua mỗi ngày** (chỉnh sau, xem §3.4 và §4.4). Chỉ còn một run mở tại một thời điểm.
> - Chạy ở mọi Ascension. Server giữ số dư Shard (escrow). Màn xác nhận và thẻ offer hiện rõ dòng "kỳ vọng nhận lại". Độ khó và thưởng đi cùng nhau.
> - **11/10: Nhiệm vụ cực khó.** Nhiệm vụ **không bán gì**: không Thử lại, không Bảo hiểm cược, không Gem. Đây là bài test risk-to-earn của Liam. (Hướng "tạo ức chế rồi bán giải pháp" chỉ nằm trong run thường, xem `monetization-v1.md`.)
> - **Nhà Nhiệm vụ có cấp riêng**, nâng bằng **Gene Shard + Land Stone**, không tiền thật. **THAY (12/10): nâng nhà chỉ mở thêm bậc**, không còn cơ cấu 2/3/4/5 lần mỗi ngày. N4/N5/N6 vẫn mở theo cấp nhà. Chi phí nâng nhà giữ làm số khởi điểm, kiểm bằng sim sau.
> - **Bậc khó nhất dùng Full mode.** Server tung xúc xắc ở mọi chế độ. **N6 chỉ mở cho người đã thắng một run Full ở A9** (12/10).
> - `monetization-v1.md` MON-12/13: không Aid mua bằng tiền thật, **không Boon nào**, không Continue trong run Nhiệm vụ. Nhiệm vụ mở sau 5 run làm quen. **MON-5: không định giá hay chỉnh độ khó theo từng người** (áp cho cả cơ chế tự chỉnh m ở §11).
> - **12/10: unlock cày dùng được trong Nhiệm vụ**, nhưng chỉ unlock có từ chơi và từ track miễn phí của Pass. Pass trả tiền không bao giờ cho sức mạnh.
> - **12/10: run Nhiệm vụ đủ điều kiện VÀO bảng xếp hạng** (đảo khuyến nghị cũ "không lên bảng"), và tính là run đã tạo.
> - **12/10: chưa có sim vẫn được bật**; chỉnh live bằng luật m tự chỉnh (§11). Chưa dùng AXS, chạy thử bằng Shard trước.
> - **12/10: bảng giá N1–N4 đã dựng lại** (m = 1,60 / 1,95 / 2,45 / 3,30) để người chơi giỏi không lãi ở N1–N4. N5/N6 giữ m, có `m_scale` riêng.
> - **12/10: N5/N6 là bậc "thử sức"**, kỳ vọng nhận lại < 100% với mọi hồ sơ, chấp nhận. Thẻ ghi rõ "kỳ vọng nhận lại".
> - **12/10: RTP đo trên toàn dân, đích 0,75–0,95**, kèm điều kiện heavy không lãi ở N1–N4.
> - **12/10: payout tối đa 20.000 mỗi run**: chấp nhận.
> - **12/10: verifier lỗi (timeout/crash, canary qua, không tái lập) = huỷ Nhiệm vụ, chỉ hoàn cược, không trả R.** Lỗi tái lập được thì gắn cờ tài khoản (bậc C10).
> - **12/10: điều kiện phụ (19 loại bản 11/10) đưa vào v1.0 nếu làm được**, xem §3.8.
> - Kiến trúc (`docs/architecture/server-authoritative-rng.md`, khối đầu): cược trừ lúc **tạo run**, một batch D1; bỏ run = thua; **không run nào bị huỷ vì để không**; **không giới hạn resume, không reseed khi vào lại, không đếm resume**; engine từ chối hành động sau khi đã xin seed = Nhiệm vụ thua; khoản khởi đầu không dùng làm cược; không áp cổng 18+ cho cược Shard; có trần payout theo từng run, không có trần Shard theo ngày.
> - **Bị bản này thay thế (đừng đọc lại bản cũ cho các điểm này):** seed xúc xắc theo trận, `resume{seed}`, "tối đa 3 resume", hạn chơi 72 giờ, hủy-trước-khi-bắt-đầu có hoàn, "Short là mode duy nhất", NV-7 "unlock = 0", **"tối đa 5/ngày"**, **"mỗi offer mua tối đa 1 lần/ngày"**, **"sim bắt buộc trước khi bật"**, **"không lên bảng ranked"**, **"để điều kiện phụ ngoài v1"**, **m cũ 1,85/2,30/2,80/3,65 và `m_scale` 0,90 chung cho mọi bậc**.

# Nhiệm vụ (risk-to-earn) — bản CỰC KHÓ, v1.0

Tác giả: game-designer · 12/10/2026 · Đã áp review của economy-designer (APPROVE WITH CHANGES) và quyết định Liam 12/10. Chỉ sửa file này, không code.
**Mọi con số là tính tay, chưa qua sim.** Tỉ lệ thắng của casual/regular/heavy lấy từ **mục tiêu** của `ascension-v2.md` §5.1 (cũng chưa sim), không phải số đo người thật. Mọi "d" của luật Nhiệm vụ (độ khó cộng thêm, đơn vị logit) là **tôi ước**. Chỗ nào chưa kiểm trong code thì ghi "chưa verify". Vì Liam cho bật khi chưa sim, các số này sẽ được chỉnh live bằng §11, không chờ sim.

---

## 0. Đọc nhanh

1. **Một Nhiệm vụ = một run**, chơi với luật khó hơn bản ranked thường. Trả cược lúc tạo run. Thắng thì nhận `cược × m` (đã gồm cược) cộng ít Stone. Thua hoặc bỏ giữa chừng thì mất cược, không Stone, không an ủi. Run vẫn trả Shard của run (R) như thường.
2. **Sáu bậc (N1–N6)**, cược 300 → 2.500 Shard. m mới: **1,60 / 1,95 / 2,45 / 3,30 / 4,20 / 7,20**. Trả khi thắng (m_scale N5/N6 = 0,90 lúc ra mắt): **480 / 975 / 1.960 / 3.960 / 6.805 / 16.200**. N6 là Full mode.
3. **Cực khó thật**: ngay N1, regular thắng ~40%, casual ~24%. N6 chỉ ~13% cho heavy, ~4% cho regular, ~1% cho casual. Không Aid, không Continue, không Boon, một mạng.
4. **Kỳ vọng mới**: casual lấy lại **~35%** số cược (lỗ ~65%), regular **~55% (lỗ ~45% mỗi lần cược)**, heavy hợp lý (chỉ N1–N4) **~1,00** (hòa vốn, không lãi), heavy mua cả N5/N6 ~0,95. **RTP toàn dân ≈ 0,77**, nằm trong đích 0,75–0,95 nhưng sát đáy. N5/N6 là bậc thử sức, lỗ với mọi hồ sơ.
5. **Không giới hạn số lần mua mỗi ngày.** Mỗi bậc có một offer trên bảng ngày, mua lặp lại được, nhưng chỉ một run mở. Người giỏi hơn heavy 0,5 logit chơi N4 liên tục có thể lãi ~+2.300 (5 run) tới ~+4.600 Shard/ngày (10 run), xem §4.4.
6. **Nhà Nhiệm vụ 4 cấp** chỉ mở bậc: cấp 1 miễn phí (N1–N3), cấp 2/3/4 tốn **3.000 / 8.000 / 20.000 Shard + 4.000 / 12.000 / 30.000 Stone**, mở N4 / N5 / N6 (N6 còn cần đã thắng một run Full ở A9).
7. **m tự chỉnh theo bậc bằng Bayes (Beta-Binomial)**, một số chung cho mọi người, hiện công khai trên thẻ, chỉ được hạ (không vượt bảng gốc), đổi chậm. §11.
8. **Điều kiện phụ: 2 trong 19 loại vào v1.0** (Một nhà, Đa sắc), 1 loại gộp vào bậc (Leo thang), 16 loại để sau hoặc khó (§3.8).

---

## 1. Overview

Nhiệm vụ là chế độ cược Shard lấy kỹ năng làm ngưỡng. Người chơi chọn một offer trên bảng ngày, trả cược, rồi chơi **một run** có luật khó hơn. Server giữ tiền, tung xúc xắc, verify log. Thắng thì được trả theo bậc; thua là mất, không có đường lui, không có thứ gì để mua nhằm đỡ đau. Nhiệm vụ **không có SKU tiền thật**. Mục đích: cho Liam đo xem người chơi có chấp nhận risk-to-earn không (§8). Run đủ điều kiện lên bảng xếp hạng và tính là run đã tạo.

Vị trí trong vòng lặp: tầng meso (một run). Nhiệm vụ chồng lên run thường, không thay nó. Thưởng ngày (60 Shard + 500 Stone) là thứ khác, không đổi.

## 2. Player Fantasy

**Aesthetic chính (MDA):** Challenge, rồi Expression. "Tôi cược vào chính mình và game không nương tay." Cảm giác muốn có: căng, có thật để mất, và khi thua thì biết rõ vì sao (đồng hồ boss, spike, thiếu build), không thấy bị lừa. **SDT:** Autonomy (tự chọn bậc, tự quyết cược và số lần), Competence (luật hiện sẵn, thua đọc được lý do).

Nhiệm vụ **không phải**:
- Máy đánh bạc: không "gấp đôi hoặc mất hết", không hệ số tăng khi thắng liên tiếp, không giảm giá mua lại sau khi thua, không hiệu ứng "suýt thắng".
- Chỗ để bán giải pháp: không có thứ gì trả tiền thật chạm vào Nhiệm vụ (MON-12).
- Bẫy giấu: mọi luật khó hiện trước khi mua, tỉ lệ thắng và "kỳ vọng nhận lại" hiện trước khi mua, m hiện tại hiện công khai.

Thua mà không đau thì không đo được gì, nên cược từ 0,7R (N1) tới 5,6R (N6) và không có an ủi.

---

## 3. Detailed Rules

### 3.1 Mua = tạo run

1. Người chơi chạm offer trên bảng, xem màn xác nhận (§3.7), bấm "Mua và chơi".
2. Server làm **một batch D1**: kiểm số dư *có thể cược* ≥ cược, kiểm chưa có run mở, kiểm bậc đã mở (nhà + điều kiện thắng §3.2), rồi trừ cược, ghi sổ, tạo bản ghi run. Sau đó mới tạo RunDO. Hết đường "mua rồi hủy lấy lại tiền": mua và tạo run là **một việc**. **Không có kiểm số lần mua trong ngày.**
3. Header của run ghi cố định lúc tạo: `mission_id`, bậc, mode, Ascension, mã các luật Nhiệm vụ, điều kiện phụ (nếu có), **cược, m gốc, `m_scale` và m hiệu dụng đã chốt**. Sau đó đổi `m_scale`, bảng giá hay chạy lại §11 không ảnh hưởng run đang mở.
4. Chỉ **một run mở/tài khoản**. Đang có run dở (thường hay Nhiệm vụ) thì phải xong hoặc bỏ nó trước. Đây là giới hạn tự nhiên duy nhất của tốc độ mua (thời gian chơi).
5. **Số dư có thể cược** = số dư Shard − phần khoản khởi đầu còn lại. Khoản khởi đầu tiêu trước vào các khoản chi không phải cược (vé). Cần tài khoản đã đăng ký.
6. Run Nhiệm vụ **tính là run đã tạo** (thống kê, mốc, bảng xếp hạng), kể cả khi thua hoặc bỏ. Run bị huỷ vì verifier lỗi hoặc run mồ côi được hoàn thì **không** tính.

### 3.2 Độ khó: bậc, Ascension, luật Nhiệm vụ

Không thêm trait khắc chế địch, không giấu thông tin, không đụng luật HP (đội hồi đầy mỗi trận), đúng khóa ở `core-loop-v2.md` và `ascension-v2.md`. Mọi luật chỉ chỉnh **ngân sách chiến đấu** bằng các núm đã có (HP, dmg, số elite, đồng hồ boss). Không luật nào nhắc tên quái nên Atia 3D thay Chimera vẫn chạy.

**Chuẩn Nhiệm vụ** (bật ở mọi bậc): địch dmg +10%, HP elite +10%. Không Aid, không Continue, không Boon, và không luật nào đọc "trạng thái Aid" (MON-13). d ≈ 0,30.

**Năm luật thêm** (hiện trên thẻ offer, d là ước tính):

| Mã | Luật | d |
|---|---|---|
| M1 Đồng hồ gắt | Boss Clock bắt đầu từ lượt 6 (ghi đè `clock_start` của Ascension, không cộng chồng), +20%/lượt, tối đa +100% | 0,35 |
| M2 Spike dồn | Chu kỳ lượt đòn lớn của elite/boss ngắn đi 1 lượt | 0,30 |
| M3 Săn đuổi | +2 node elite (chỉ dùng ở A < 9, vì A9 đã có sẵn) | 0,30 |
| M4 Đòn nặng | Địch dmg thêm +15% (nhân với Ascension) | 0,30 |
| M5 Boss dày | HP boss +25% | 0,35 |

*(M2 giả định bộ "spike theo lịch" của `monetization-v1.md` §1.2-A được làm. Chưa verify. Nếu không làm thì thay M2 bằng M4 ở các bậc dùng nó và tính lại d.)*

**Sáu bậc:**

| Bậc | Mode | Ascension | Luật thêm (bộ A / bộ B xoay theo ngày) | d tổng |
|---|---|---|---|---|
| N1 | Short | A3 | — (chỉ Chuẩn) | 0,30 |
| N2 | Short | A4 | M3 / M2 | 0,60 |
| N3 | Short | A6 | M2 / M3 | 0,60 |
| N4 | Short | A7 | M1+M4 / M5+M2 | 0,95 |
| N5 | Short | A9 | M1+M4 / M5+M2 | 0,95 |
| N6 | **Full** | A9 | M1+M4 / M5+M2 | 0,95 |

Hai bộ A/B của cùng một bậc có cùng d (±0,05). **Bộ nào cũng không có quá 2 luật thêm** (xem §5, Slay the Spire). Điều kiện phụ (§3.8) chiếm một trong hai chỗ đó, không cộng thêm. Generator từ chối luật đã nằm sẵn trong Ascension của bậc đó.

**Mở khóa bậc** (đã chốt 12/10): người chơi phải đã **thắng ít nhất một run ở Ascension của bậc đó** (N1 A3, N2 A4, N3 A6, N4 A7, N5 A9). **N6 cần đã thắng một run Full ở A9** (điều kiện này đủ, vì thắng Full đã kéo theo Full đã mở). Bậc còn khóa vẫn hiện, xám, ghi điều kiện. Ngoài ra bậc phải được nhà mở (§3.3). Cần cả hai.

### 3.3 Nhà Nhiệm vụ (nâng bằng Shard + Stone)

Nâng nhà **chỉ mở thêm bậc**, không đổi số lần mua.

| Cấp | Chi phí lên cấp | Bậc trên bảng |
|---|---|---|
| 1 | miễn phí (sau 5 run làm quen) | N1–N3 |
| 2 | 3.000 Shard + 4.000 Stone | + N4 |
| 3 | 8.000 Shard + 12.000 Stone | + N5 |
| 4 | 20.000 Shard + 30.000 Stone | + N6 (Full, và cần đã thắng Full A9) |

Tổng 31.000 Shard + 46.000 Stone. So sánh (`economy-v2.md`, R = 450): 46.000 Stone ~2,5% tổng 1.820k Stone tới LunaLanding, ~1,3 tuần Stone của heavy (34.814/tuần), ~3,4 tuần của casual (13.363/tuần). 31.000 Shard ~1,2 tuần thu nhập heavy (26.653/tuần), ~4,8 tuần của casual (6.423). **Giữ làm số khởi điểm (Liam 12/10), kiểm bằng sim sau** cùng `economy-v2.md` ECO-11. Giờ nhà chỉ là cổng bậc, không còn hạn chế tốc độ mua, nên người giỏi trả hết nhà rất nhanh; số tiền này là phần nhỏ của faucet ở §4.4. Bảng cấp nằm trong data.

### 3.4 Bảng ngày (không có giới hạn mua)

- Seed = `H(ngày UTC, "nv", rules_version)`. **Bảng giống nhau cho mọi người cùng cấp nhà.** Người chơi nói chuyện được về "bảng hôm nay", không ai chọn offer theo kỹ năng.
- Mỗi bậc đang mở có đúng **một offer**; seed chọn bộ A hay bộ B. **Offer mua được nhiều lần trong ngày**, mỗi lần là một run mới với seed xúc xắc mới do server cấp (luật giữ nguyên trong ngày). Không có số lần mua tối đa, không có "đã mua hôm nay".
- Giới hạn tốc độ duy nhất là chỉ một run mở tại một lúc, nên tốc độ mua bị chặn bởi thời gian chơi (Short ~25 phút/run là giả định của economy, chưa verify cho Nhiệm vụ).
- Không đổi bảng (không reroll). Không đếm ngược, không nhấp nháy; chỉ một dòng "bảng đổi lúc 00:00 UTC".
- Chơi lặp cùng bộ luật trong ngày cho người chơi luyện tay; hiệu ứng này làm tỉ lệ thắng thật cao hơn d ước tính. Không chặn, §11 tự bắt qua dữ liệu.
- Núm `buy_cap_by_house` và `offer_per_day` **không còn ở v1.0**. Nếu sau này cần siết (ví dụ khi đổi sang AXS) thì thêm lại một núm giới hạn số mua/ngày, không cần đổi cấu trúc nhà.

### 3.5 Thắng, thua, trả tiền

- **Thắng** = hạ boss cuối của run (3 boss Short, 4 boss Full) theo replay đã verify, **và** thoả điều kiện phụ nếu offer có (§3.8).
- **Thua** = đội bị tiêu diệt; hoặc bấm "Bỏ run" (có xác nhận ghi rõ "mất cược"); hoặc engine từ chối hành động sau khi đã xin seed (§6); hoặc không thoả điều kiện phụ khi hạ boss cuối.
- Trả khi thắng: `payout = round5(cược × m_gốc × m_scale)` và Stone của bậc, **một transaction với việc đóng Nhiệm vụ**, khóa idempotency do server dựng. Stone bị cắt bởi trần ngày `mission_stone_day_cap`. Qua trần payout theo run (**20.000, Liam chấp nhận**) thì cắt ở trần và ghi cờ.
- **Không có Stone khi thua. Không có an ủi nào khi thua** (Liam 12/10). Shard của run (R) trả như run thường trong mọi trường hợp đã verify.
- Không có Thử lại, Bảo hiểm cược, hay bất cứ thứ gì giảm đau sau khi thua. Màn thua chỉ có hai nút ngang hàng: "Về nhà Nhiệm vụ", "Chơi run thường". (Không có nút "mua lại ngay": người chơi vẫn mua lại được từ nhà Nhiệm vụ, nhưng game không đẩy.)

### 3.6 Bảng thưởng (R = 450 Shard)

`m_scale` lúc ra mắt: N1–N4 = 1,00 (m đã dựng sát hòa vốn cho heavy), N5/N6 = 0,90. Cột "m hiệu dụng" là cái hiện trên thẻ; §11 chỉ có thể kéo `m_scale` xuống, không bao giờ lên quá 1,00.

| Bậc | Cược | Cược/R | m gốc | `m_scale` | m hiệu dụng | Trả khi thắng | Lãi khi thắng | Stone khi thắng |
|---|---|---|---|---|---|---|---|---|
| N1 | 300 | 0,67 | 1,60 | 1,00 | 1,60 | 480 | +180 | 4 |
| N2 | 500 | 1,11 | 1,95 | 1,00 | 1,95 | 975 | +475 | 8 |
| N3 | 800 | 1,78 | 2,45 | 1,00 | 2,45 | 1.960 | +1.160 | 14 |
| N4 | 1.200 | 2,67 | 3,30 | 1,00 | 3,30 | 3.960 | +2.760 | 22 |
| N5 | 1.800 | 4,00 | 4,20 | 0,90 | 3,78 | 6.805 | +5.005 | 34 |
| N6 | 2.500 | 5,56 | 7,20 | 0,90 | 6,48 | 16.200 | +13.700 | 60 |

Không có trần số lần mua nên **trần Stone ngày 150 (`mission_stone_day_cap`, economy-v2 §9) giờ là giới hạn thật**, không còn tự nhiên ≤ 138 như bản cũ. Người chơi bình thường chạm rất xa trần (Stone kỳ vọng mỗi tuần: casual ~2, regular ~12, heavy ~90, dưới 0,3% Stone tuần). Người farm 10 run N4/ngày thắng ~4 lần × 22 = ~92 Stone/ngày, vẫn dưới trần.

### 3.7 UX tối thiểu (cần mockup mới trước khi làm UI)

- **Thẻ offer:** tên bậc, mode, Ascension, các luật thêm và điều kiện phụ bằng chữ, cược, trả khi thắng, Stone, **m hiệu dụng hiện tại kèm m gốc** (ví dụ "×3,23, bảng gốc ×3,30", cập nhật lần cuối), và hai dòng xác suất: tỉ lệ thắng gần đây của toàn bộ người chơi ở bậc đó (từ telemetry), và **ước tính cho bạn** dạng khoảng làm tròn 5 (cần ≥ 10 run, chưa đủ thì ghi "chưa đủ dữ liệu"). **Dòng "kỳ vọng nhận lại" luôn hiện trên thẻ**, không chỉ ở màn xác nhận: dùng số cá nhân khi có ước tính, chưa có thì dùng số toàn dân của bậc.
- **N5/N6:** thẻ ghi "Bậc thử sức: trung bình mọi người nhận lại dưới 100% số cược."
- **Xác nhận mua:** "Bạn trả **500** Shard. Thắng: nhận **975** (+475) và 8 Stone. Thua hoặc bỏ giữa chừng: **mất 500, không hoàn.** Với tỉ lệ ước tính của bạn, kỳ vọng nhận lại khoảng 59% số trả." Nút ghi "Mua, mất cược nếu thất bại". Cảnh báo thông tin (không chặn) khi tổng cược trong ngày > 50% thu nhập tuần ước tính; vì không có trần số lần mua nên cảnh báo này là lưới an toàn duy nhất.
- **Trong run:** chip góc màn hình ghi bậc và các luật thêm. Đồng hồ boss hiện từ lượt 1 (luật chung).
- **Màn thua:** trung tính, cụ thể ("Boss 2 hạ đội ở lượt 9, đồng hồ đang +60%. Mất 500 Shard."). Không "suýt thắng", không nút mua lại, không giảm giá.

### 3.8 Điều kiện phụ (v1.0)

**Nguồn:** danh mục 19 loại của bản 11/10 (§4 bản cũ, trong git). Cột `d` dưới đây là `D_cond = −ln q` của bản cũ, q là tiên nghiệm tôi đoán, **chưa sim**. Bản cũ chưa tính việc Nhiệm vụ không có Aid/Continue/Boon nên q thật có thể thấp hơn, tức d thật cao hơn; vì vậy lọc theo d cũ là lọc lỏng, không chặt hơn.

**Cách hoạt động.** Điều kiện phụ là một mệnh đề thêm vào điều kiện thắng ("hạ boss cuối **và** điều kiện"). Nó được tính như một "luật thêm" (§3.2): có `d_cond ≈ −ln(q_ref)`, trong đó `q_ref` = xác suất thoả điều kiện, biết đã hạ được boss cuối, của người chơi tham chiếu. Chiếm một trong hai chỗ luật thêm của offer. Hiện trên thẻ trước khi mua. Không đổi cược; m không đổi tay mà để §11 điều chỉnh theo dữ liệu.

**Tiêu chí vào v1.0 (phải đạt cả sáu):**
1. Kiểm được từ action log / replay mà `RunVerifier` đã verify, không thêm đường tin client.
2. Dùng key đã có. Nếu cần counter mới (bản cũ có 5: `axie_ko`, `dmg_dot`, `max_kills_turn`, `boss_turns[]`, `rerolls`) thì phải thêm ở **verifier**: `RunVerifier` phải tính lại từ replay ActionLog và trả số đó (chưa verify hiện chỉ trả thắng/thua hay cả counter), nạp lại trong `RunState.gd` ~930 khi resume (chỉ 6 key cố định), và đưa vào fingerprint `RULES_VERSION` kèm test replay. Điều kiện chính thức không đọc counter client. Counter mới = bump rules version, nên mặc định **không vào v1.0**.
3. `q_ref ≥ 0,70` (tức `d_cond ≤ 0,36`) **và** `|d_cond − d của luật bị thay| ≤ 0,05`, để tổng d của bậc không lệch (lệch thì heavy RTP rời 1,00 vào ngày có điều kiện). Số q là **ước**, sim sau.
4. Không đọc Aid/Continue/Boon (đã cấm), không dựa vào thông tin bị giấu.
5. Không chồng lên luật thêm cùng cơ chế (ví dụ điều kiện "không mua sắm" không đi cùng luật đụng vào shop).
6. Không nhắc tên quái hay node cụ thể.

**Quy tắc v1.0:** mỗi bậc N1–N4 mỗi ngày có tối đa **một** điều kiện phụ, **thay cho** một trong hai luật thêm (tổng không quá 2). Ngoại lệ N1 (chỉ có Chuẩn, không có luật thêm để thay): điều kiện được **thêm vào**, d tổng N1 từ 0,30 lên ~0,46; tính tay heavy N1 còn ~58% thắng, RTP ~0,94 (dưới 1, an toàn). **N5/N6 không có điều kiện phụ** (p đã 1–23%; thêm điều kiện là chạm "gần như bất khả thi" của Slay the Spire). Điều kiện chọn theo seed ngày như bộ A/B.

**Phân loại 19 loại cho v1.0.** Lọc: q_ref ≥ 0,70 (d ≤ 0,36), không cần counter mới, kiểm được từ log.

| # | Loại | d (bản cũ) | Dữ liệu | Kết luận |
|---|---|---|---|---|
| 1 | Chớp nhoáng | 0,69 (Tia chớp 1,39) | `run_stats.turns` (có) | **Để sau.** q 0,50; ngưỡng P50 cần phân phối thật chưa có |
| 2 | Không ai gục | 0,69 (1,39) | `axie_ko` (mới) | **KHÓ.** q 0,50 và cần counter mới ở verifier; Nhiệm vụ không Aid nên q còn thấp hơn |
| 3 | Da dày | 0,92 | `run_stats.taken` (có) | **Để sau.** q 0,40; ngưỡng P40 cần phân phối thật |
| 4 | Đòn tử huyệt | 0,92 (1,61) | `run_stats.max_hit` (có) | **Để sau.** q 0,40 |
| 5 | Build X (11 loại) | ~0,4–1,0 | relic + tag (có) | **Để sau.** d thấp nhất ~0,45 > 0,36; cần `w_X` thật từ sim relic. Có thể vào v1.1 cho archetype mạnh nhất khi có số |
| 6 | Hai kỳ ngộ | 0,80 | relic Duo (có) | **Để sau.** q 0,45 |
| 7 | Giao kèo | 0,92 | relic, `pact_group` (có) | **Để sau.** q 0,40; ở A6+ pact bắt buộc nên q phải tính lại |
| 8 | Trận đồ | 1,20 | relic + ActionLog | **KHÓ.** q 0,30; đòi hai điều kiện cùng lúc (relic positional + `reorder_party`) |
| 9 | Tay trắng | 1,05 | `sell_relic` (mới) | **KHÓ.** q 0,35 và cần counter mới |
| 10 | Không thần khí | 0,51 | rarity relic (có) | **Để sau (gần đạt).** q 0,60, thiếu ~0,15 logit; thử lại khi sim cho q thật |
| 11 | Không mua sắm | 0,69 | ActionLog `shop_buy` (có) | **Để sau (gần đạt).** q 0,50, kiểm dễ nhất. Tôi từng ước 0,75 ở bản trước của §3.8; số cũ của bản 11/10 là 0,69 nên lấy số này |
| 12 | Két sắt | 1,39 | Shard run (có) | **Để sau.** q 0,25 |
| 13 | Một nhà | 0,16–0,51 theo class | `team_keys` (có) | **VÀO v1.0** ở N2–N4, **chỉ class có d trong 0,25–0,40** (khớp một luật M); class còn lại để sau. Danh sách class đạt chờ sim. |
| 14 | Đa sắc (≥ 4 class) | 0,16 | `team_keys` (có) | **VÀO v1.0** ở **N1** (thêm vào, không thay). Ở N2–N4 d 0,16 quá dễ so với luật M 0,30–0,35 nên không dùng, trừ khi có biến thể chặt hơn (≥ 5 class, d chưa tính) |
| 15 | Leo thang | 0,15 × k | header `ascension` (có) | **Gộp vào bậc, không dùng như điều kiện.** Mỗi bậc Nhiệm vụ đã gắn cứng một Ascension (A3…A9) và p lấy từ bảng Ascension; thêm "thắng ở Ak" chỉ lặp lại bậc hoặc làm bậc nhảy qua A khác, phá bảng §4.1. Phần "leo ladder" do chính bậc N1→N5 và điều kiện mở khóa bậc (§3.2) đảm nhiệm |
| 16 | Săn boss | 1,05 | `boss_turns[]` (mới) | **KHÓ.** q 0,35, cần counter mới, và đụng M1/M5 (đồng hồ gắt, boss dày) cho cùng bậc |
| 17 | Lửa ngầm | 1,39 | `dmg_dot` (mới) | **KHÓ.** q 0,25, counter mới, và ép riêng poison/burn/thorns |
| 18 | Không reroll | 1,20 | đếm reroll (ActionLog) + `rerolls` (mới) | **KHÓ.** q 0,30; counter mới (đếm được từ ActionLog nhưng ngưỡng P30 cần phân phối) |
| 19 | Quét sạch | 0,51 | `max_kills_turn` (mới) | **Để sau (gần đạt).** q 0,60 và cần counter mới ở verifier |

**Kết quả: 2 loại vào v1.0 (13 Một nhà, 14 Đa sắc), 1 loại gộp vào bậc (15), 16 loại không vào.** Trong 16 loại đó, 6 loại cần counter mới ở verifier (2, 9, 16, 17, 18, 19); phần còn lại rớt vì q thấp (d > 0,36). Ba loại gần đạt (10, 11, 19, thiếu ≤ 0,2 logit) là ứng viên đầu tiên của v1.1 khi có sim.

**Vì sao ít:** bản cũ đặt q bằng "ngưỡng khó đủ để có ý nghĩa" (thường q 0,25–0,50) nên d thường 0,5–1,4, nặng hơn cả một luật M (0,30–0,35). Với quy tắc "thay một luật, d lệch ≤ 0,05" thì chỉ điều kiện nhẹ mới vừa. Đây là điểm đánh đổi: muốn nhiều điều kiện nặng hơn thì phải bỏ luật M ở bậc đó và đổi bảng d (việc của sim, không làm ở v1.0).

---

## 4. Formulas

**Biến:** `p_asc,j(A, mode)` = tỉ lệ thắng mục tiêu của hồ sơ j (casual/regular/heavy) ở Ascension A, bảng `ascension-v2.md` §5.1; `d` = tổng độ khó luật Nhiệm vụ (§3.2, gồm điều kiện phụ nếu có); `σ(x) = 1/(1+e^-x)`; `s` = `m_scale` của bậc.

```
Short:  p_j(bậc) = σ( logit(p_asc,j(A, Short)) − d )
Full:   p_short = p_asc,j(A)^e          (e = full_exponent, mặc định 1,5)
        p_j(bậc) = σ( logit(p_short) − d )
Payout   = round5( cược × m_gốc × s )
RTP_j    = p_j × m_gốc × s
Lãi ròng kỳ vọng mỗi lần mua = cược × (RTP_j − 1)
```

**Cách dựng m gốc (đã đổi 12/10).** Không còn "người tham chiếu p_ref". Mỗi bậc neo vào **heavy**:
- N1–N4: `m = round05( 1 / p_heavy )` để RTP heavy ≈ 1,00 (hòa vốn). N1: 1/0,623 = 1,605 → 1,60. N2: 1/0,516 = 1,938 → 1,95. N3: 1/0,411 = 2,433 → 2,45. N4: 1/0,304 = 3,289 → 3,30.
- N5/N6: giữ m cũ (`0,95 / p_heavy`: 4,20 và 7,20) và hạ bằng `m_scale` 0,85–0,90 (lúc ra mắt 0,90). Hai bậc này là bậc thử sức, RTP heavy dưới 1.
- Lý do: định theo heavy thì heavy hợp lý (chỉ mua N1–N4) không lãi, nhưng casual/regular lỗ nặng (regular lỗ ~45%, Liam chấp nhận 12/10). Đây là cái giá của "không cho heavy lãi" khi heavy đến 62% ở N1.

**Về `e = 1,5` (giả định, chưa verify):** `ascension-v2.md` §5.1 chỉ có bảng Short. Full có 30 hàng thay vì 18 (`core-loop-v2.md` F1) nhưng chỉ thêm 1 boss. Mô hình "sống sót đều mỗi hàng" cho e = 1,67; "chỉ boss quyết định" cho e = 1,33. Tôi lấy giữa. Cần sim Full (hoặc để §11 tự bắt).

**Ví dụ tính tay (N4, regular, bộ M1+M4):** A7 regular = 31% → logit −0,800; trừ d 0,95 → −1,750 → σ = 14,8%. m = 3,30. RTP = 0,148 × 3,30 = 0,488. Lãi ròng = 1.200 × (0,488 − 1) = **−614** Shard mỗi lần mua.

### 4.1 Tỉ lệ thắng theo hồ sơ (không đổi so với bản trước, vì d không đổi)

| Bậc | Casual | Regular | Heavy |
|---|---|---|---|
| N1 (A3) | 24,1% | 39,7% | 62,3% |
| N2 (A4) | 17,6% | 30,1% | 51,6% |
| N3 (A6) | 12,1% | 22,1% | 41,1% |
| N4 (A7) | 7,8% | 14,8% | 30,4% |
| N5 (A9) | 4,1% | 9,3% | 22,6% |
| N6 (Full A9) | 1,3% | 4,0% | 13,2% |

Đối chiếu: run ranked thường A0 là 40/60/82, A9 là 10/21/43. N1 khó hơn A3 thường ~6–7 điểm cho mỗi hồ sơ, N5 khó hơn A9 thường 6–20 điểm.

### 4.2 RTP và lãi ròng kỳ vọng (Shard mỗi lần mua)

`m_scale` = 1,00 ở N1–N4. N5/N6 hiện cả hai mức: 1,00 (tham khảo) và 0,90 (ra mắt).

| Bậc | m | RTP casual | RTP regular | RTP heavy | Net casual | Net regular | Net heavy |
|---|---|---|---|---|---|---|---|
| N1 | 1,60 | 0,386 | 0,635 | 0,997 | −184 | −109 | −1 |
| N2 | 1,95 | 0,343 | 0,587 | 1,006 | −328 | −207 | +3 |
| N3 | 2,45 | 0,296 | 0,542 | 1,007 | −563 | −367 | +6 |
| N4 | 3,30 | 0,257 | 0,488 | 1,003 | −891 | −614 | +4 |
| N5 (s=1,00) | 4,20 | 0,172 | 0,391 | 0,949 | −1.490 | −1.097 | −91 |
| N5 (s=0,90) | 3,78 | 0,155 | 0,352 | 0,854 | −1.521 | −1.166 | −263 |
| N6 (s=1,00) | 7,20 | 0,094 | 0,288 | 0,950 | −2.266 | −1.780 | −124 |
| N6 (s=0,90) | 6,48 | 0,084 | 0,259 | 0,855 | −2.290 | −1.852 | −361 |

Heavy ở N1–N4 trong khoảng 0,997–1,007: đúng điều kiện "heavy không lãi đáng kể ở N1–N4" của Liam (câu 13). Mức lãi +3…+6 Shard mỗi lần mua là rơi vào sai số làm tròn của m, không phải lợi thế thật. Nhưng đây chỉ đúng nếu tỉ lệ heavy đúng mục tiêu; sai số kỹ năng thì xem §4.4.

### 4.3 EV theo hồ sơ (kịch bản cơ sở, R = 450, `m_scale` N5/N6 = 0,90)

Hành vi giả định (tôi đoán, cần đo): casual mua 2 lần/tuần, regular 5, heavy 14. Đây là số lần **kỳ vọng**, không phải trần (bỏ trần 5/ngày không đổi giả định này vì những người này chưa chơi hơn thế). Phân bố bậc đã mua:

| | N1 | N2 | N3 | N4 | N5 | N6 | Cược TB | RTP gia quyền | Net/lần mua | Net/tuần | % thu nhập tuần |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Casual | 60% | 30% | 10% | | | | 410 | **0,353** | −265 | −531 | −8,3% (6.423) |
| Regular | 25% | 35% | 25% | 15% | | | 630 | **0,550** | −284 | −1.417 | −18,8% (7.540) |
| Heavy (bảng cũ, mua cả N5/N6) | | 15% | 30% | 35% | 12% | 8% | 1.151 | **0,950** | −57 | −798 | −3,0% (26.653) |
| **Heavy hợp lý (chỉ N1–N4)** | | 20% | 35% | 45% | | | 920 | **1,005** | +4 | +60 | +0,2% |

**Regular giờ lỗ ~45% mỗi đồng cược** (RTP 0,55; bản trước là 0,63). Casual lỗ ~65%. Đây là hệ quả trực tiếp của việc định giá theo heavy ở N1–N4; Liam đã chấp nhận.

**Toàn dân 45% casual / 40% regular / 15% heavy** (tổng cược/người/tuần, và nhận lại):

| Kịch bản heavy | Cược | Nhận lại | **RTP toàn dân** | Sink Shard/người/tuần | % thu nhập TB (9.904) |
|---|---|---|---|---|---|
| Heavy bảng cũ (có N5/N6) | 4.046 | 3.119 | **0,771** | 927 | 9,4% |
| Heavy hợp lý (chỉ N1–N4) | 3.561 | 2.764 | **0,776** | 797 | 8,0% |

Cả hai nằm trong đích 0,75–0,95 của Liam nhưng **sát đáy** (biên 0,02). Nếu casual/regular chơi nhiều hơn dự kiến thì RTP toàn dân còn thấp hơn, vì họ là nhóm lỗ nặng. §11 không nâng m vượt bảng, nên nếu RTP toàn dân xuống dưới 0,75 thì phải người chỉnh bảng gốc (§11.6).

**Ngày xấu (mua N1+N2+N3 một lần, cược 1.600):** casual thua cả ba 55%, regular 33%. **Ngày xấu nhất:** không còn trần, ví dụ mua một lượt N2–N6 (cược 6.800 như bản cũ), regular thua cả năm 40% (mất ~6,3 ngày thu nhập), casual 63%. Vì không có trần mua, người chơi có thể mua nhiều hơn nữa; chỉ có cảnh báo thông tin chặn nhẹ.

### 4.4 Rủi ro faucet khi không có giới hạn mua

**Rủi ro (ghi một lần, ở đây):** bỏ trần mua/ngày nghĩa là người chơi giỏi hơn mục tiêu "heavy" có thể mua lặp bậc có RTP > 1 theo thời gian chơi. Cái chặn duy nhất là thời gian (một run mở), trần payout 20.000/run, và §11 (chỉ bắt được xu hướng toàn dân, **không bắt được vài tài khoản giỏi hơn xa mức trung bình**) cùng theo dõi p99 lãi ròng.

Giả định giỏi hơn heavy **0,5 logit** (heavy thắng ~89% ở A0 thay vì 82%), tính tay:

| Bậc | p heavy +0,5 logit | RTP (s như ra mắt) | Lãi ròng mỗi lần mua |
|---|---|---|---|
| N1 | 73,2% | 1,170 | +51 |
| N2 | 63,7% | 1,243 | +121 |
| N3 | 53,5% | 1,310 | +248 |
| N4 | 41,9% | 1,382 | **+458** |
| N5 (s=0,90) | 32,5% | 1,228 | +411 |
| N6 (s=0,90) | 20,0% | 1,299 | +747 |

(N5/N6 ở s=0,85: 1,160 và 1,227, tức +288 và +567.)

**Faucet không có trần, người giỏi chơi N4 lặp lại** (N4 là bậc lãi tốt nhất mỗi giờ: Short, không rủi ro Full, m_scale = 1):
- 5 run/ngày (~2 giờ): **+2.290 Shard/ngày** (60% thu nhập ngày của heavy, 3.808).
- 10 run/ngày (~4 giờ): **+4.580 Shard/ngày** (120%).
- Bản cũ có trần (mua N2–N6 mỗi bậc một lần): ~+1.985/ngày. Bỏ trần nâng mức tối đa theo giờ chơi, không theo số offer.
- R của các run này không tính thêm: những run đó thay cho run thường vốn cũng trả R.

**Cái chặn thật là thang vé ECO-2, nhưng chỉ ở đầu ra.** ECO-2 (vé thứ k giá `200 × 1,05^(k-1)`, tối đa 30 vé/ngày, tối đa tiêu 13.288 Shard/ngày) không chặn Shard vào, nó chặn tốc độ đổi Shard thành Stone qua vé. Tính tay (economy-v2: ~242 Stone/vé hộp thường): heavy hiện tiêu ~13,7 vé/ngày; cộng thêm +4.580 Shard thì ~23 vé/ngày, Stone/ngày từ ~4.970 lên ~7.300 (+9,5 vé × ~242 Stone), **Land ~36 tuần thay vì 52 tuần**. Trần cứng 30 vé/ngày cho Land khoảng **29 tuần**. Nghĩa là người giỏi chơi Nhiệm vụ nhiều đẩy Land nhanh hơn heavy ~30%, tới sàn ~29 tuần, không hơn. Còn Shard dư ngoài 13.288/ngày thì tồn lại không có chỗ tiêu (đúng ý sink của economy). Cần economy-designer chạy lại ECO-11 với kịch bản này.

**Chấp nhận (Liam 12/10):** không sim trước, chỉnh live bằng §11, nên rủi ro này nằm trong tuần đầu. Theo dõi p99 lãi ròng 28 ngày và Shard tích lũy/ngày của top 1%.

**Độ nhạy R:** cược lưu theo số Shard cố định, m không phụ thuộc R. Bảng giả định **R = 450 không đổi**. Nếu R đo được lệch > 15% so với 450 thì dựng lại tỉ lệ cược/R ở §3.6 (không đụng m). §11 theo dõi RTP thật nên không phụ thuộc R.

---

## 5. Research: game khác làm cược khó thế nào

Chỉ ghi điều tôi tìm được và điều chưa kiểm được.

- **Hearthstone Arena** ([Game Developer: The Math of Hearthstone Part II](https://www.gamedeveloper.com/design/the-math-of-hearthstone-part-ii-arena-the-american-dream-), [wiki](https://hearthstone.wiki.gg/wiki/Arena)): vào cửa 150 vàng, kết thúc khi thua 3 ván hoặc thắng 12. Số trận thắng kỳ vọng ≈ 3p/(1−p). Bảng thưởng lồi theo số thắng; một hướng dẫn cho rằng cần ~7 thắng mới hòa vốn 150 vàng, tôi suy ra ≈ p 70% mỗi ván. Bài học: game này **cố ý** để người trung bình lỗ, chỉ người giỏi hòa vốn hoặc lãi; đó là mô hình của ta. Khác biệt: Arena cho 3 "mạng", Nhiệm vụ chỉ 1, phương sai cao hơn (lý do N6 ở nhà cấp 4). **Chưa verify** bảng thưởng hiện tại.
- **Marvel Snap Conquest** ([Untapped](https://blog.snap.untapped.gg/marvel-snap-wiki-conquest-mode-shop), [Prima](https://primagames.com/tips/everything-you-need-to-know-about-conquest-mode-in-marvel-snap)): vé Silver 80 / Gold 200 / Infinity 500 vàng; thua một ván là hết run và mất vé; Infinity chỉ mở tuần cuối mùa. **Vào cửa đã nhận Medal an ủi** (Gold 40, Infinity 100) đổi được đồ. Nhiệm vụ của Liam **không có an ủi** (Liam chốt 12/10), đây là điểm cần đo bằng chỉ số "đúng 1 lần rồi bỏ" ở §8. Số liệu 2023, **chưa verify** hiện tại.
- **Hades, Pact of Punishment / Heat** ([RPG Site](https://www.rpgsite.net/feature/10287-hades-pact-of-punishment-heat-modifiers-and-how-to-maximize-your-rewards), [TheGamer](https://www.thegamer.com/hades-heat-pact-punishment-trivia/)): không cược, nhưng thưởng tăng theo điểm Heat; bậc cao nhất gây tranh cãi. Bài học: mỗi luật thêm đi kèm điểm khó và thưởng gắn vào điểm đó; đúng cách `d` hoạt động. Số Heat tối đa các nguồn nói khác nhau.
- **Slay the Spire Daily Climb** ([Spine](https://intothespine.com/2018/03/05/slay-the-spire-daily-climb/), [wiki Custom Mode](https://slaythespire.wiki.gg/wiki/Custom_Mode)): cùng seed cho mọi người, 3 modifier mỗi ngày. Bản đầu 4 modifier và "gần như không thể" nên giảm còn 3. Bài học: tối đa 2 luật thêm + Chuẩn (đã áp, gồm cả điều kiện phụ), bảng chung (đã áp). N6 của ta (casual 1,3%) chạm ngưỡng đó, nên khóa sau nhà cấp 4 và đã thắng Full A9, và không có điều kiện phụ.
- **Chưa kiểm được:** Balatro challenge deck, buy-in/rake của poker (từ trí nhớ). Không dẫn nguồn.

---

## 6. Edge Cases

| Tình huống | Kết quả |
|---|---|
| Mất mạng, đóng tab, crash, mất điện | Run **không bị huỷ**, không có hạn giờ, không đếm lần vào lại. Vào lại ở đúng epoch cuối, **không đổi seed**. Cược nằm trong escrow. Run mở chặn tạo run mới cho tới khi xong hoặc bỏ |
| Vào lại từ thiết bị khác | Cho phép; máy cũ bị vô hiệu bằng `session_epoch` |
| Bỏ run (nút hoặc endpoint bỏ) | Thua, mất cược. Rớt mạng rồi nối lại **không** tính là bỏ |
| Xin seed rồi hành động khác với hành động đã khai (client sửa) | Engine từ chối; **Nhiệm vụ thua**. Client thật không bao giờ gặp vì có hàm kiểm thuần trước khi xin |
| Verifier timeout/crash, canary qua, không tái lập | **Huỷ Nhiệm vụ, chỉ hoàn 100% cược** (Liam 12/10). **Không trả R**, không Stone, không tính là run đã tạo. Không còn "trả lại lần mua trong ngày" vì không có trần mua |
| Log làm verifier sập **tái lập được** | Vẫn huỷ + hoàn cược, nhưng **gắn cờ tài khoản theo bậc C10** |
| Verify fail do log bị sửa | Thua, mất cược, gắn cờ |
| Đổi `rules_version` khi run đang mở | Run tiếp tục theo bản cũ nếu server còn trong `SUPPORTED_RULES`; chỉ chờ (`pending_version`), **không bao giờ mất cược**. Nếu bản cũ bị bỏ hẳn thì huỷ + hoàn cược. Bảng ngày dùng `rules_version` nên đổi bản sẽ đổi bảng; run đã tạo giữ cược/m/luật đã ghi ở header |
| Chỉnh `m_scale`, bảng giá, hoặc cron §11 chạy khi run đang mở | Không ảnh hưởng run đó (payout chốt ở header) |
| Hai tài khoản bấm mua cùng lúc cùng bậc | Cùng m hiệu dụng (§11 không nhận danh tính tài khoản) |
| Số dư không đủ, hoặc chỉ đủ nhờ khoản khởi đầu | Từ chối mua. Không vay, không "cược một phần" |
| Hai thiết bị bấm mua cùng lúc (một tài khoản) | Batch D1 có điều kiện (đã có run mở?): chỉ một bên thành công |
| Mua qua 00:00 UTC | Run tính cho ngày tạo; run qua nửa đêm vẫn chạy bình thường |
| Run mồ côi (đã trừ cược, chưa tạo được RunDO) | Cron dọn: **hoàn cược**. Không tính là thua, không tính là run đã tạo |
| Log chứa `AID_USE`, `CONTINUE`, hoặc Boon trong run Nhiệm vụ | Server từ chối ngay ở `aid_req`/`epoch_req(continue)`; nếu lọt vào replay thì verify fail + cờ |
| Payout vượt trần payout theo run | Cắt ở trần 20.000, ghi cờ xem xét. Trần ≥ payout lớn nhất của bảng (N6 = 16.200 ở s=0,90; 18.000 ở s=1,00) |
| Tài khoản bị khóa/đóng băng khi có Nhiệm vụ mở | Cược giữ trong escrow tới khi giải quyết |
| Hai tài khoản cày bậc thấp lấy Stone | Stone ≤ 150/ngày/tài khoản và RTP toàn dân < 1, nên lỗ; không cần chặn |
| Người giỏi chơi hộ | Không phát hiện được; giá trị thấp vì Stone nhỏ. Bỏ qua |
| Người giỏi mua lặp để farm Shard | Cho phép (không có trần); xem §4.4 và §11 giới hạn của nó |
| Điều kiện phụ cần counter chưa có trong code | Điều kiện đó không vào v1.0 (§3.8), không dùng trong bảng ngày |
| Run Nhiệm vụ lên bảng xếp hạng | Chỉ run đã verify xong (thắng hoặc thua theo luật bảng hiện hành); run huỷ vì verifier lỗi thì không. **Chưa quyết** hiện chung hay tách theo nhãn Nhiệm vụ (§10, mục B) |
| Axie NFT import / part NFT trong run Nhiệm vụ | **Chưa quyết** (dễ phát sinh lợi thế mua được ở một chế độ có cược). Hỏi Liam (§10, mục C) |
| Cược đổi sang AXS sau này | Chưa làm (Liam 12/10). Nếu đổi thì cần pháp lý duyệt lại, kể cả cổng 18+; bản này không giả định gì về AXS |

**Degenerate strategies:**
- *Farm bậc rẻ bằng người giỏi hơn bảng:* không còn giới hạn mua; chặn bằng m định giá theo heavy, `m_scale` tự hạ (§11, chỉ bắt xu hướng toàn dân), trần payout, giám sát p99 (§4.4).
- *Mua rồi bỏ để "xem trước" boss:* mất cược, nên không có lợi. Seed không lộ trước khi tạo run.
- *Thắng sớm rồi nghỉ:* không rút tiền giữa run; thắng = hạ boss cuối.
- *Đuổi theo (mua liên tục sau thua):* dễ hơn khi không có trần. Chỉ có cảnh báo thông tin và chỉ số đuổi theo ở §8; đỏ thì rút lại.

---

## 7. Dependencies

| Hệ thống | Hướng | Hợp đồng |
|---|---|---|
| `docs/architecture/server-authoritative-rng.md` | Nhiệm vụ cần | Cược trừ lúc tạo run (batch D1), một run mở, bỏ = thua, không huỷ vì để không, không reseed khi vào lại, verifier canary, C10, trần payout theo run, `SUPPORTED_RULES`. **Chưa verify** bảng `runs`/ledger có chỗ chứa `mission_id`, m gốc, `m_scale`, luật đã chốt. Cần thêm bảng cron cho §11 (một dòng `m_scale` mỗi bậc) |
| `ascension-v2.md` §5.1 | Nhiệm vụ cần | Nguồn duy nhất của tỉ lệ thắng; Nhiệm vụ không tạo bảng độ khó thứ hai, chỉ cộng `d` |
| `economy-v2.md` | Hai chiều | Nhiệm vụ cần R = 450, Stone ≤ 150/ngày (giờ là giới hạn thật), ECO-2. Economy cần biết: sink Shard ~800–930/người/tuần, sink Stone nhà 46.000, **faucet không trần của người giỏi §4.4 (~+2.300 tới +4.600 Shard/ngày) và Land ~36 tuần cho họ** |
| `monetization-v1.md` | Nhiệm vụ cần | MON-5 (không giá theo người), MON-12, MON-13, không Boon, mở sau 5 run làm quen. Nhiệm vụ không có SKU |
| `player-accounts.md` / `AccountService`, `SaveStore` | Nhiệm vụ cần | Ví chỉ ở tài khoản đăng ký; số dư thuộc server; **chưa verify** ledger tách "khoản khởi đầu còn lại" |
| Unlock cày / Pass | Nhiệm vụ cần | Chỉ unlock từ chơi và Pass miễn phí dùng trong Nhiệm vụ; Pass trả tiền không cho sức mạnh. **Chưa verify** nguồn unlock có đánh dấu được nguồn gốc |
| Leaderboard | Nhiệm vụ cần | Nhận run Nhiệm vụ đã verify; cách hiện (§10, mục B). Chưa verify cách chấm điểm với luật khó hơn |
| `RunState` / `RULES_VERSION` | Điều kiện phụ cần | Counter mới nếu có (§3.8, tiêu chí 2) |
| `relic-set-v2.md` | Không phụ thuộc | Nhiệm vụ không đổi relic; sim A hiệu chỉnh `d` khi có |
| `design/gdd/build-spec.md` (INV-1..7) | Cần đối chiếu | Chưa đọc lại INV khi viết bản này; phải kiểm Nhiệm vụ không vi phạm bất biến Shard nào |
| Daily board / Thưởng ngày | Tách | Không đụng nhau |

Spike theo lịch (M2) là phụ thuộc mềm vào `monetization-v1.md` §1.2-A.

---

## 8. Tuning Knobs và telemetry

Mọi số nằm trong `assets/data/` hoặc cấu hình server, không hardcode. Núm của §11 ở bảng riêng trong §11.5.

| Núm | Mặc định | Khoảng | Loại | Lý do |
|---|---|---|---|---|
| `tier_stake[6]` | 300/500/800/1.200/1.800/2.500 | ±30% | Curve | 0,67R tới 5,6R |
| `tier_m_base[6]` | **1,60/1,95/2,45/3,30**/4,20/7,20 | N1–N4 `1/p_heavy`; N5/N6 `0,95/p_heavy` | Curve | Heavy ≈ 1,00 ở N1–N4 |
| `m_scale_init[6]` | 1,00/1,00/1,00/1,00/**0,90/0,90** | N1–N4 cố định 1,00; N5/N6 0,85–0,90; §11 chỉ hạ, tối đa 1,00 | Curve | Đệm cho sai số năng lực heavy |
| `tier_stone[6]` | 4/8/14/22/34/60 | ×0,5–×2,5 | Curve | |
| `d_base`, `d_M1..M5` | 0,30 / 0,35, 0,30, 0,30, 0,30, 0,35 | ±0,15 | Curve | Ước tính; §11 bù khi lệch |
| `d_cond` (điều kiện phụ) | `−ln(q_ref)` | ≤ 0,36 | Curve | §3.8 |
| `full_exponent` | 1,5 | 1,33–1,67 | Curve | §4 |
| `house_cost_shard[3]` | 3.000/8.000/20.000 | ±50% | Gate | Số khởi điểm, sim sau |
| `house_cost_stone[3]` | 4.000/12.000/30.000 | ±50% | Gate | Số khởi điểm, sim sau |
| `house_tier_unlock[4]` | N1–N3 / +N4 / +N5 / +N6 | | Gate | Chỉ còn mở bậc |
| `tier_unlock_ascension` | A3/A4/A6/A7/A9; N6 = thắng Full A9 | | Gate | Chỉ cho người đã thắng |
| `mission_payout_cap` | 20.000 | ≥ payout bậc cao nhất | Gate | Chặn bug và verifier bị chiếm |
| `mission_stone_day_cap` | 150 | 100–200 | Gate | ECO-12; giờ là giới hạn thật |
| `phat_min_runs` | 10 | 5–20 | Feel | Gợi ý "ước tính cho bạn" |
| ~~`buy_cap_by_house`, `offer_per_day`~~ | **đã bỏ** | | | Liam 12/10: không giới hạn mua |

**Telemetry** (soft launch ≥ 4 tuần, quyết định khi mỗi nhánh ≥ 2.000 lượt xem bảng). Câu hỏi cần trả lời: người chơi có chấp nhận risk-to-earn không?
1. *Tiếp nhận:* % DAU mở bảng; % mua ≥ 1 lần/tuần; **số lần mua/người/ngày (p50/p90/p99, giờ không có trần)**; cược/ngày so với thu nhập Shard ngày.
2. *Khẩu vị rủi ro:* phân phối bậc đã mua so với bậc mở; tỉ lệ nâng bậc sau thắng; **chỉ số đuổi theo** (mua bậc cao hơn hoặc cược lớn hơn trong cùng phiên sau khi thua; thêm: mua lại ngay trong 2 phút sau thua).
3. *Hậu quả:* retention D1/D7/D30 của người mua so với không mua (ghép theo thu nhập và số ngày chơi); thời gian quay lại sau 3 thua liên tiếp; tỉ lệ bỏ run ngay sau thua ở boss; **tỉ lệ người mua đúng 1 lần rồi không mua lại** (đo "khó quá", và đo luôn tác động của việc không an ủi).
4. *Sức khỏe hệ thống:* RTP thật theo bậc, theo hồ sơ và toàn dân; p99 lãi ròng 28 ngày; **Shard tích lũy/ngày của top 1% từ Nhiệm vụ**; sai lệch p dự đoán so với thực theo bậc; Stone/ngày thực; nhật ký §11 (`m_scale` từng bậc theo ngày).

| Chỉ số | Xanh | Vàng | Đỏ |
|---|---|---|---|
| WAU mua ≥ 1 lần (tuần 2–4) | ≥ 15% | 6–15% | < 6% |
| Người mua đúng 1 lần rồi bỏ | ≤ 50% | 50–70% | > 70% |
| Retention D30 người mua − không mua | ≥ −3 điểm | −3 tới −6 | < −6 |
| Chỉ số đuổi theo | ≤ 20% | 20–35% | > 35% |
| RTP toàn dân 28 ngày | 0,75–0,95 | 0,95–1,00 hoặc 0,60–0,75 | > 1,00 hoặc < 0,60 |
| RTP heavy ở N1–N4 (28 ngày) | ≤ 1,01 | 1,01–1,05 | > 1,05 |
| p99 lãi ròng 28 ngày | ≤ 25% thu nhập | 25–40% | > 40% |

Số đề xuất, chỉnh sau khi thấy số thật. Đỏ về retention hoặc đuổi theo thì rút lại, kể cả khi sink Shard tốt. Không A/B "ẩn xác suất". RTP toàn dân hiện ước tính 0,77: nằm ở rìa dưới của xanh nên chú ý sớm.

---

## 9. Acceptance Criteria

**Chức năng (test tự động, server):**
1. Mua → trừ đúng cược trong một batch; mua khi số dư (không tính khoản khởi đầu) < cược bị từ chối; mua bậc chưa mở (nhà hoặc điều kiện thắng) bị từ chối; mua khi đang có run mở bị từ chối. **Mua nhiều lần cùng offer trong ngày được phép** (không có test "từ chối vượt cap").
2. Batch lỗi giữa chừng không để lại trạng thái "trừ tiền chưa có run"; run mồ côi bị cron hoàn cược.
3. Bảng cùng ngày, cùng cấp nhà là cùng danh sách trên hai tài khoản; đổi `rules_version` thì danh sách đổi.
4. Run Nhiệm vụ: `aid_req`, `epoch_req(continue)`, Boon bị từ chối; log có `AID_USE`/`CONTINUE` thì verify fail.
5. Hành động sau khi xin seed khác khai báo → Nhiệm vụ thua. Vào lại nhiều lần từ cùng epoch: không đổi seed, không có bộ đếm nào.
6. Verifier timeout (canary qua) → huỷ + hoàn đúng cược, **không R**, không Stone, không tính run đã tạo; tái lập → huỷ + hoàn + cờ C10.
7. Payout dùng m gốc và `m_scale` đã chốt ở header; đổi `m_scale` giữa chừng không đổi payout của run mở; payout > 20.000 bị cắt và có cờ.
8. Nâng nhà: trừ đúng Shard + Stone, không nâng được nếu thiếu một trong hai; bậc mở đúng theo cấp; **không có tác dụng nào lên số lần mua**.
9. Mở N6 chỉ khi tài khoản đã có một run Full thắng ở A9, bất kể cấp nhà.
10. Stone ngày: tổng Stone từ Nhiệm vụ trong một ngày UTC ≤ 150, kể cả khi mua nhiều lần.
11. Run Nhiệm vụ đã verify hiện trên bảng xếp hạng với nhãn bậc; run huỷ vì verifier lỗi không hiện; run tính vào "run đã tạo" đúng quy tắc §3.1.6.
12. Unlock có nguồn Pass trả tiền hoặc tiền thật không áp dụng trong run Nhiệm vụ; unlock từ chơi và Pass miễn phí áp dụng.
13. Điều kiện phụ (nếu có trong offer): thắng boss cuối mà không thoả điều kiện → thua; kiểm bằng replay đã verify.
14. Sim 100.000 lần mua theo §4.2: RTP mỗi hồ sơ nằm trong ±0,02 của bảng (kiểm công thức, không kiểm game).
15. **Sau khi bật** (không chặn bật, Liam 12/10): sim game thật so tỉ lệ thắng mỗi bậc với §4.1 trong ±5 điểm; lệch hơn thì chỉnh `d`, không chỉnh m.
16. Các AC của §11 (11.7).

**Trải nghiệm (playtest):**
1. ≥ 7/8 người thử giải thích đúng "mất gì nếu thua, nhận gì nếu thắng, kỳ vọng nhận lại khoảng bao nhiêu" chỉ từ thẻ offer và màn xác nhận.
2. Không ai nói luật khó là "bất công" hoặc "giấu" (mọi luật hiện trước; thua đọc được lý do).
3. Sau 4 tuần soft launch, §8 không có hàng đỏ.

---

## 10. Quyết định Liam 12/10 và việc còn mở

12 câu hỏi cũ đã trả lời, cộng ba câu mới (13–15) và các điểm review (H1, M1–M3, L1).

| # | Câu hỏi | Quyết định (12/10) | Đã áp ở |
|---|---|---|---|
| 1 | An ủi khi thua? | **Không** | §3.5, §5 |
| 2 | Nhiệm vụ dùng unlock cày? | **Có**, chỉ từ chơi và Pass miễn phí | §3.2, §7, M2 |
| 3 | Khóa bậc theo thắng ở Ascension đó | **Có.** N6 cần thắng một run Full ở A9 | §3.2 (M3) |
| 4 | Giá và `m_scale` ra mắt | N1–N4 m = 1,60/1,95/2,45/3,30; N5/N6 giữ m, `m_scale` 0,85–0,90 (ra mắt 0,90) | §3.6, §4 (H1) |
| 5 | Sim trước khi bật | **Không bắt buộc**, chỉnh live theo §11 | §4.4, §9 |
| 6 | Lên bảng xếp hạng | **Có**, đủ điều kiện, tính run đã tạo | §3.1, §7 (M1) |
| 7 | Số lần mua/ngày | **Không giới hạn** (thay "tối đa 5"); nhà chỉ mở bậc | §3.3, §3.4, §4.4 |
| 8 | Chi phí nâng nhà | Giữ số khởi điểm, sim sau | §3.3 |
| 9 | Verifier lỗi | Hoàn cược, **không R** | §6 |
| 10 | Trần payout 20.000 | **Chấp nhận** | §3.5, §6 |
| 11 | 19 điều kiện phụ | **Vào v1.0 nếu làm được.** Kết quả: 2 loại vào (13, 14), 1 gộp vào bậc (15), 16 để sau/khó | §3.8 |
| 12 | AXS | Chưa; thử bằng Shard | §6 |
| 13 | Cách đo RTP | Toàn dân 0,75–0,95, thêm điều kiện heavy không lãi ở N1–N4 | §4.3, §8 |
| 14 | N5/N6 | Bậc thử sức, −EV mọi hồ sơ, thẻ hiện "kỳ vọng nhận lại" | §3.7, §4.2 |
| 15 | Tự chỉnh m theo bậc | **Có**, theo Bayes (Beta-Binomial), ngưỡng duyệt một lần; không bao giờ theo người (MON-5) | §11 |

**Còn mở, cần Liam hoặc người khác trả lời:**
- **B. Bảng xếp hạng:** hiện chung với ranked thường (cùng bảng, thêm nhãn Nhiệm vụ + bậc) hay tách bảng "Nhiệm vụ" riêng? Luật khó hơn nên so điểm chung có thể không công bằng. Khuyến nghị: cùng bảng theo Ascension nhưng có bộ lọc Nhiệm vụ.
- **C. Axie NFT / part NFT trong Nhiệm vụ:** cho dùng hay không? Khuyến nghị: không dùng trong Nhiệm vụ ở v1.0 vì lợi thế mua được trong chế độ có cược.
- **D. Xác nhận ngưỡng §11** (`R_hi` = 0,95, `ε` = 0,10, bước tối đa 0,02/ngày), duyệt một lần.

Phụ thuộc chưa verify: ledger server tách khoản khởi đầu; spike theo lịch (M2) có làm không; `RunVerifier` hiện chỉ trả thắng/thua hay cả counter; INV-1..7 của `build-spec.md`; counter mới cho điều kiện phụ.

---

## 11. Tự chỉnh m theo bậc (Beta-Binomial)

### 11.1 Mục đích và ranh giới

Giữ RTP của từng bậc (theo cả người chơi) không vượt `R_hi` = 0,95, dựa vào dữ liệu thật thay cho sim. Mô hình d-logit (§4) là **niềm tin ban đầu**; dữ liệu cập nhật niềm tin đó.

Quy tắc cứng:
1. **Chỉ `m_scale` của từng bậc thay đổi.** Đó là một số chung cho mọi người, hiện công khai trên thẻ (m hiệu dụng + m gốc). **Không có đầu vào nào là danh tính hay thành tích của một tài khoản**, không có kết quả nào theo từng người. Cùng lúc, cùng bậc, mọi tài khoản trả cùng m (MON-5).
2. **Chỉ được hạ hoặc nhả về bảng gốc**: `m_scale ∈ [s_min, 1,00]`. Không bao giờ nâng m vượt bảng gốc, vì bảng gốc đã được dựng để heavy ≈ 1,00 ở N1–N4; nâng sẽ tạo lãi cho heavy.
3. **Không chỉnh độ khó.** Dữ liệu thắng chỉ dùng để chỉnh m, không bao giờ đổi `d` hay luật.
4. Mọi thay đổi có rate limit, và run đang mở không bị ảnh hưởng (header chốt).

### 11.2 Mô hình

Với bậc t, đặt θ_t = tỉ lệ thắng trung bình của các lần mua trong bậc đó trên toàn dân. Cược mọi người cùng bậc bằng nhau, nên **RTP của bậc = θ_t × m_gốc,t × s_t** (s = `m_scale`) chính xác, không cần phân theo hồ sơ.

**Prior:** `θ_t ~ Beta(α0, β0)` với
```
μ0_t = Σ_j  w_j,t × p_j(t)       (p_j(t) là bảng §4.1; w_j,t = tỉ lệ lượt mua bậc t do hồ sơ j, từ giả định §4.3)
α0 = n0 × μ0_t        β0 = n0 × (1 − μ0_t)       (n0 = sức nặng prior = số run "tương đương")
```
Với giả định §4.3 (dân 45/40/15, 2/5/14 lần mua/tuần, heavy bảng cũ), tính tay:

| Bậc | Tỉ lệ lượt mua casual / regular / heavy | μ0 |
|---|---|---|
| N1 | 0,52 / 0,48 / 0 | 0,316 |
| N2 | 0,21 / 0,54 / 0,25 | 0,327 |
| N3 | 0,07 / 0,41 / 0,52 | 0,312 |
| N4 | 0 / 0,29 / 0,71 | 0,259 |
| N5 | 0 / 0 / 1 | 0,226 |
| N6 | 0 / 0 / 1 | 0,132 |

RTP prior của bậc (μ0 × m_gốc × s): N1 0,51 · N2 0,64 · N3 0,76 · N4 0,85 · N5 0,85 · N6 0,86. Bậc thấp nằm dưới 0,95 vì có nhiều casual/regular mua; không sao, §11.1(2) không cho nâng.

**Dữ liệu:** trong cửa sổ cuốn, mỗi run Nhiệm vụ của bậc t đã đóng cho một quan sát: thắng (w) hoặc thua (l). Bỏ run bị huỷ vì verifier lỗi và run mồ côi. Bỏ run (bỏ giữa chừng) tính là thua (cược đã mất, nên RTP thật cũng thế).

**Posterior (Beta-Binomial, liên hợp):** `θ_t | dữ liệu ~ Beta(α0 + w, β0 + l)`. Với n = w + l:
```
μ_t = (α0 + w) / (n0 + n)
var  = μ_t (1 − μ_t) / (n0 + n + 1)           (xấp xỉ chuẩn khi n0 + n ≥ 30)
θ_q  = quantile q của posterior   ≈ μ_t + z_q × sqrt(var)      (z_0,90 = 1,2816)
RTP_t posterior = θ × m_gốc,t × s_t
```
Giữ giới hạn một người: mỗi tài khoản đóng góp tối đa `account_cap` = 30 run mỗi bậc trong cửa sổ (quan sát thừa bỏ), để vài tài khoản farm không kéo cả bảng.

### 11.3 Luật cập nhật (cron 00:00 UTC mỗi ngày, mỗi bậc một dòng)

1. Lấy cửa sổ: run đóng trong `window_days` ngày gần nhất, tối đa `window_max_runs` run mới nhất. Nếu n < `n_min` thì **không đổi** (giữ `s_t` hiện tại).
2. Tính posterior và `θ_0,90`.
3. Mục tiêu: chọn `s*` sao cho phân vị 90% của RTP posterior không vượt `R_hi`:
   ```
   s* = R_hi / ( m_gốc,t × θ_0,90 )
   s_target = clamp( s*, s_min, 1,00 )
   ```
   (Tương đương: P(RTP_t > R_hi) ≤ ε = 0,10.)
4. **Rate limit và dead band:** nếu |s_target − s_t| < `deadband` (0,01) thì không đổi. Ngược lại `s_t,mới = s_t + clamp(s_target − s_t, −step_day, +step_day)`, làm tròn 0,01. Giới hạn thêm theo tuần: tổng thay đổi trong 7 ngày ≤ `step_week` (0,08).
5. Ghi nhật ký một dòng/bậc/ngày: n, w, μ, θ_0,90, s* , s mới. Hiện trong dashboard nội bộ.
6. Nếu `s_t` nằm ở `s_min` quá 14 ngày liên tục thì báo động: bảng gốc hoặc `d` sai, cần người xem lại (không tự đổi bảng gốc).
7. Công tắc đóng băng: đặt `bayes_enabled=0` để giữ nguyên `s_t`.

Giá trị hiện trên thẻ là `m_hiệu_dụng = m_gốc × s_t`, kèm m gốc và thời điểm cập nhật cuối. Payout của run chốt theo giá trị lúc tạo run.

### 11.4 Ví dụ có số (N4, m gốc 3,30, `s` = 1,00)

Prior: μ0 = 0,2588, n0 = 60 → α0 = 15,53; β0 = 44,47. Sau một cửa sổ có n = 400 run đóng, w = 118 thắng (29,5%, cao hơn dự đoán 25,9% vì nhiều người giỏi mua N4), l = 282.

- Posterior: α = 133,53; β = 326,47; tổng 460. μ = 0,2903. var = 0,2903 × 0,7097 / 461 = 0,000447 → sd = 0,02114.
- RTP posterior trung bình = 0,2903 × 3,30 = **0,958**; P(RTP > 0,95) = P(θ > 0,2879) = P(z > −0,114) ≈ 55%. Lớn hơn ε = 10%, nên cần hạ.
- θ_0,90 = 0,2903 + 1,2816 × 0,02114 = 0,3174. RTP ở phân vị 90% = 0,3174 × 3,30 = 1,047.
- `s* = 0,95 / (3,30 × 0,3174) = 0,907`. Đích 0,907.
- Rate limit 0,02/ngày: s đi 1,00 → 0,98 → 0,96 → 0,94 → 0,92 (bốn ngày, chạm step tuần 0,08 nên đứng ở 0,92), sau 7 ngày mới nhích tiếp về 0,91. Thẻ hiện: ngày 1 "×3,23 (gốc ×3,30)", payout N4 = round5(1.200 × 3,234) = 3.880.
- Cùng ví dụ, nếu dữ liệu quay về 25% thắng, `s*` ra > 1 nên bị kẹp 1,00 và `s` nhích ngược lên 0,02/ngày về bảng gốc.
- Ví dụ không đủ dữ liệu: n = 60 < `n_min` = 100 thì không đổi dù tỉ lệ thắng rất cao.

Ghi chú: ví dụ này tính tay, dùng xấp xỉ chuẩn; triển khai dùng CDF Beta thật (regularized incomplete beta) khi n0 + n < 30.

### 11.5 Núm (đều chỉnh live, không hardcode)

| Núm | Mặc định | Khoảng | Loại | Lý do |
|---|---|---|---|---|
| `bayes_enabled` | 1 | 0/1 | Gate | Công tắc đóng băng |
| `R_hi` | 0,95 | 0,90–1,00 | Curve | Trần RTP bậc; Liam duyệt một lần |
| `eps` (xác suất vượt R_hi cho phép) | 0,10 | 0,05–0,20 | Curve | Càng nhỏ càng thận trọng |
| `n0` (sức nặng prior) | 60 | 20–200 | Curve | ~11% trọng số khi n = 500 |
| `n_min` | 100 | 50–300 | Gate | Dưới ngưỡng không đổi |
| `window_days` / `window_max_runs` | 28 / 3.000 | 7–56 / 500–10.000 | Gate | Cuốn theo mùa kỹ năng |
| `account_cap` | 30 run/bậc/cửa sổ | 10–100 | Gate | Chặn vài tài khoản kéo cả bảng |
| `s_min` | 0,75 | 0,70–0,90 | Gate | Sàn hạ |
| `step_day` / `step_week` | 0,02 / 0,08 | 0,01–0,05 / 0,03–0,15 | Feel | Đổi chậm, người chơi kịp thấy |
| `deadband` | 0,01 | 0–0,02 | Feel | Tránh nhích vặt |
| `prior_mix[tier][profile]` | Bảng §11.2 | | Curve | Cập nhật khi có dữ liệu mua thật |
| `alarm_days_at_min` | 14 | 7–30 | Gate | §11.3 mục 6 |

### 11.6 Giới hạn (nói thật)

- **Chỉ bắt xu hướng toàn dân.** Vài tài khoản giỏi hơn hẳn mức trung bình có thể lãi lớn trong khi RTP toàn bậc vẫn dưới `R_hi` (§4.4). `account_cap` còn che bớt nhóm này khỏi dữ liệu. Phần đó do p99 lãi ròng bắt.
- **Chỉ hạ, không nâng.** Nếu RTP toàn dân xuống dưới 0,75 (ước tính hiện 0,77) thì cần người chỉnh bảng gốc hoặc `d`; §11 không làm thay.
- **Người chơi mới vào bậc cao thay đổi thành phần mua** nên θ_t trôi; cửa sổ cuốn bắt được nhưng chậm.
- **Không phải sim.** n nhỏ ở N5/N6 (ít người mua) nên chủ yếu sống bằng prior tới khi đủ `n_min`.
- Posterior nói về RTP, không nói về cảm nhận công bằng. Telemetry §8 vẫn bắt buộc.

### 11.7 Acceptance Criteria riêng cho §11

1. Cho dữ liệu cố định (n0 = 60, μ0 = 0,2588, w = 118, l = 282, m = 3,30), hàm tính ra `s*` = 0,907 ± 0,002 và `s_target` = 0,91.
2. n < `n_min` → `s_t` không đổi.
3. Mọi lần chạy: `s_min ≤ s_t ≤ 1,00`; |Δ| mỗi ngày ≤ `step_day`, mỗi 7 ngày ≤ `step_week`; không nhảy khi |s_target − s_t| < `deadband`.
4. Hàm cập nhật chỉ nhận tổng hợp theo bậc (đếm thắng/thua đã bỏ danh tính, sau `account_cap`) và hằng số; **không có tham số `account_id`** (kiểm bằng chữ ký hàm và test: đổi mọi `account_id` cho cùng dữ liệu tổng hợp thì kết quả giống hệt).
5. Hai tài khoản bất kỳ mua cùng bậc cùng giây có cùng m hiệu dụng và cùng payout.
6. Run mở không đổi payout khi cron chạy; run tạo sau cron dùng `s_t` mới.
7. Thẻ offer hiển thị đúng m hiệu dụng, m gốc, giờ cập nhật; khớp với giá trị server.
8. `bayes_enabled=0` giữ `s_t`; mọi lần đổi có dòng nhật ký.
9. Playtest: ≥ 7/8 người thử hiểu "m hiện tại" trên thẻ là số chung cho mọi người, không phải giá riêng.
