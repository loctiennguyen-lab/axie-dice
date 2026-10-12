Trạng thái: ĐỀ XUẤT (bản sửa 11/10) — chờ Liam review → economy-designer đặt giá → senior reviewer audit

> **QUYẾT ĐỊNH LIAM (12/10) — ưu tiên hơn thân file (B7 còn mở, xem `pending-decisions.md`):**
> B1 độ khó Ascension kiểu Angry Birds (răng cưa): bậc thường khó thêm 2–4 điểm %, bậc cổng A3/A6/A9 nhảy 6–8 điểm
> (bậc thêm cơ chế mới); trong run giữ đầu dễ, về sau khó · B6 bỏ nhảy cấp Pass ở v1; VIP = 1 Continue/run −25% +
> 1 Boon/ngày; A10 trần 4 Aid; **bỏ hẳn R10 Hồi khẩn** (Liam: không cần thiết) ·
> B2 có MON-13 (không luật chiến đấu nào đọc trạng thái Continue/Aid); nếu sim thấy Continue quá mạnh → Continue chỉ
> hồi 25% từ A6, viết thành luật Ascension · B3 unlock cày **được dùng trong ranked** (người cày không thua người nạp) ·
> B4 có giai đoạn làm quen theo tuổi tài khoản · B5 R6 Coupon shop đổi thành "làm mới hàng shop" · B8 kênh thanh toán
> **để sau khi ra mắt**, chưa làm bây giờ.

> **Liam (11/10, OQ-A..E):** A Continue **kiểu B** (địch giữ HP/phase, đội hồi 40%, clock về 0) · B **có** Boss Clock
> nhẹ ở A0 · C dùng bảng win rate làm mốc sim đầu, **nhưng game phải THẬT KHÓ** (nghiêng mục tiêu xuống thấp hơn) ·
> D chờ economy-designer · E **có**: spike từ A3, attrition nhẹ từ A0.

> **QUYẾT ĐỊNH LIAM (11/10) — ưu tiên hơn thân file:** monetization **KHÔNG nhắm vào Nhiệm vụ**. Ức chế để bán chỉ nằm
> **TRONG RUN**: quái/boss phải thật khó, gây ức chế, rồi bán giải pháp (tiện lợi + sức mạnh trong run, tiền thật, dùng
> được cả ranked). **Bỏ mọi sản phẩm Nhiệm vụ** (Thử lại, Bảo hiểm cược, cấp nhà bằng Gem). Nhà Nhiệm vụ nâng bằng
> **Gene Shard + Land Stone**, không tiền thật. Nhiệm vụ chỉ là bài test risk-to-earn của Liam: khó, ức chế, không bán gì.

# Axie Dice — Monetization v1 (tạo ức chế trong run, bán giải pháp)

Tác giả: game-designer · bản đầu 11/10/2026, **SỬA 11/10 — monetization chỉ trong run** · Chỉ viết file này, không code. Mọi con số là số đoán đầu, **chưa qua sim, chưa qua economy-designer**. Chỗ nào chưa kiểm trong code/docs thì ghi "chưa verify". Nguồn không chính thức đánh dấu **[không chính thức]**.

Đầu vào đã đọc: `core-loop-v2.md`, `economy-v2.md`, `echobox-pass-v2.md`, `relic-set-v2.md`, `ascension-v2.md` (đặc biệt Boss Clock A4/A9, luật "không trait khắc chế, không giấu thông tin"), `godot/autoload/ContentDB.gd` (`TUNE`, `budget(pw)`).

**Ranh giới Nhiệm vụ (một dòng duy nhất):** Nhiệm vụ chỉ khó và ức chế, không có SKU, Aid, Thử lại hay bảo hiểm nào gắn với nó; nâng nhà Nhiệm vụ trả bằng Gene Shard + Land Stone (không tiền thật), thiết kế nằm ở `nhiem-vu-risk-to-earn.md`.

---

## 0. Đọc nhanh (SỬA 11/10 — monetization chỉ trong run)

1. **Cách làm**: ức chế sinh ra ở **trong run**, do quái và boss. Mỗi sản phẩm đối ứng đúng một khoảnh khắc đau cụ thể (§1), chào đúng lúc đó (§2). Ức chế phải **công bằng và đọc được** (người chơi hiểu vì sao thua). Cấm: độ khó đổi theo ví, tỉ lệ ẩn, "suýt thắng giả".
2. **Hai loại sản phẩm trong run**: (a) **tiện lợi** (Scout, Run Kit, Boon đầu run, coupon shop, đổi pact), (b) **sức mạnh trong run** nhưng là **vật tiêu hao một run, có trần cứng**, nằm ngoài hệ relic (Continue, reroll thêm, hoãn đồng hồ boss, hồi khẩn).
3. **Sản phẩm chính (top 5)**: Continue sau trận thua · Pass trả phí · VIP "Moon Card" · Reroll thêm / Hoãn đồng hồ boss (bộ Aid) · Vé bundle + Starter pack.
4. **Store** giữ nguyên cấu trúc: một tiền cao cấp (**Lunar Gem**, tên tạm), 6 mốc USD, **Gem KHÔNG đổi thành Gene Shard, KHÔNG đổi thành Land Stone**. Lý do mạnh hơn bản trước: giờ không còn đường nào Gem → Shard (không có hoàn Shard), nên stake Nhiệm vụ hoàn toàn chỉ kiếm bằng chơi.
5. **Ranked**: một bảng, mọi Aid tính, thêm bộ lọc "Pure" tự tính từ ActionLog (§4).
6. **Rào bảo vệ niềm tin (không thương lượng)**: không bán relic; không độ khó theo ví; công khai trần và giá; **sàn win rate cho người không trả tiền** (§1.4); mọi Aid do server cấp và ghi ActionLog.
7. **Rủi ro lớn nhất**: nếu quái khó mà không có sàn win rate, thiết kế này thành "khó để ép nạp" và mất niềm tin (§6). Con số khó phải đi qua sim trước khi tin.

---

## 1. In-run friction design (SỬA 11/10 — monetization chỉ trong run)

Đây là phần cốt lõi. Mục tiêu: người chơi thua vì một lý do **họ đọc ra được**, thấy "suýt", rồi có (a) cách chơi tốt hơn miễn phí hoặc (b) cách trả tiền để vượt qua lần này.

### 1.1 Luật cho ức chế (khớp `ascension-v2`)

1. **Không giấu thông tin**: mọi thứ gây đau hiện số trước khi nó xảy ra (bộ đếm, ngưỡng phase, lịch spike). Người chơi không bao giờ bị đánh bởi thứ không thể tính trước.
2. **Không trait/hệ khắc chế**: khó đến từ **hình dạng của ngân sách chiến đấu** (khi nào địch ra đòn mạnh, đòn mạnh cỡ nào, trận kéo dài bao lâu), không từ "quái này miễn nhiễm build kia". Enemy-agnostic: không luật nào nhắc tên quái, nên Atia 3D thay Chimera vẫn chạy.
3. **Không đụng luật HP** (đội hồi đầy HP mỗi trận, đang là luật). Vì vậy **attrition không mang qua trận**, chỉ có attrition **trong một trận** (§1.2-D).
4. **Không rubber-band theo ví hoặc theo chuỗi thua** (MON-5). Mercy valve (§2.6) cho đồ, không đổi độ khó.
5. **Ức chế loại nào được khai thác**: thử thách (build/kỹ năng chưa đủ) → tự do; thời gian/tài nguyên trong trận (reroll, đồng hồ) → có trần; do game gian → cấm. Bằng chứng ngành: nhịp "dễ rồi khó" tạo tự tin trước rồi mới ức chế, theo phân tích Candy Crush ([Cornell CS5152](https://cs.cornell.edu/courses/cs5152/2025sp/lectures/lecture3/slides-3.pdf)). Ta cần nhịp, không cần bức tường phẳng.

### 1.2 Sáu công cụ gây ức chế (mỗi cái có chủ đích cảm xúc)

| Mã | Công cụ | Hoạt động (luật đọc được) | Cảm xúc đích | Cách người chơi miễn phí đối phó | Giải pháp trả phí (§2) |
|---|---|---|---|---|---|
| **A** | **Spike turn theo lịch** | Địch có lượt "đòn lớn" cố định mỗi N lượt (ví dụ N=4 với elite, N=3 với boss phase 2+), **bộ đếm hiện từ lượt 1**, mức đòn hiện số. Đòn lớn ≈ 1,6–2,0 × đòn thường | Căng, "phải chuẩn bị Shield trước lượt 4" | Dồn Shield/giết nhanh trước lượt spike; thua vì bỏ qua bộ đếm là lỗi của mình | R2 reroll thêm (tìm đúng mặt Shield), R10 hồi khẩn |
| **B** | **Phase boss theo ngưỡng HP** | Boss có 3 phase tại 66%/33% HP, vạch hiện trên thanh HP. Mỗi phase **đổi phân bố ngân sách** (nhiều đòn hơn, ít phòng thủ hơn), **không** thêm trait mới | "Gần xong rồi nhưng nó dồn dập hơn" | Hạ HP boss nhanh qua phase 1 để ít bị phase 3 | R1 Continue (vào lại ở phase đang chết), R4 |
| **C** | **Enrage clock** (đã có A4/A9) | Từ lượt `clock_start`, dmg boss +20%/lượt, tối đa 5 cộng dồn. **Đề xuất mới:** có bản nhẹ ở A0 (lượt 14, +10%/lượt, tối đa 3) để mọi người đều quen đồng hồ trước khi lên A4 (OQ-B) | "Kịp không?" | Build tốc độ, bỏ trận kéo dài | R4 Hoãn đồng hồ (+2 lượt, 1 lần/boss) |
| **D** | **Attrition trong trận** | Mỗi lượt kể từ lượt 6, mọi địch +5% dmg (cộng dồn, tối đa +25%). Hiện sẵn ở góc trận. Làm trận kéo dài đáng sợ mà không cần luật mới | Mỗi lượt lãng phí đều đau | Kết thúc trận nhanh hơn | R2, R10 |
| **E** | **Elite áp lực** | Elite = `elite_mult` cao hơn (đề xuất 1,25 → 1,35, sim chốt), 2 elite liền nhau ở nửa sau run từ A3. Elite luôn hiện trên map trước | "Phải chọn: né hay đánh" | Né elite bằng tuyến khác (mất thưởng) | R7 Scout (thấy elite sớm hơn), R6 coupon |
| **F** | **Trừng phạt sai lầm trung thực** | Không luật mới: hiển thị rõ "overkill lãng phí", "đòn lớn lượt kế" để người chơi nhận ra sai ở đâu. Màn thua có **recap**: lượt nào chết, đòn nào, boss còn bao nhiêu HP | "Mình sai ở lượt 5, lần sau khác" | Học | R1 (thử lại ngay với kinh nghiệm vừa có) |

**"Suýt thắng" trung thực:** không chỉnh để boss còn đúng 5% khi mình chết. Cách tạo "suýt" thật: phase 3 của boss có **đường cong dmg dốc** (không bỗng nhiên one-shot), nên thua thường xảy ra khi boss còn 10–25% HP. Đo bằng telemetry "boss HP còn lại khi thua" (§7.3), mục tiêu trung vị 15–30%. Nếu trung vị < 10% là quá dễ, > 50% là chưa đủ để ức chế có nghĩa, và quá cao là tường.

### 1.3 Bản đồ ức chế theo timeline run

Chưa verify số node mỗi run (Short/Full). Dùng vị trí tương đối theo % tiến độ run. Chỉnh theo thực tế số trận.

| Vị trí run | Cảm giác đích | Ức chế đang bật | Ghi chú |
|---|---|---|---|
| 0–25% (mở đầu) | Tự tin, học luật | Gần như không (D, A tắt). Boss clock nhẹ chưa tới | Tỉ lệ chết < 10% mọi người; đây là "đoạn dễ" của nhịp dễ-khó |
| 25–55% (giữa) | Căng dần, bắt đầu cân nhắc tài nguyên | D bật, A chỉ ở elite, E (elite đầu tiên) | Chỗ build thành hình; offer R6 coupon, R7 scout |
| ~55–75% (elite chuỗi) | **Đoạn khó thứ nhất**: đau cho build chưa đủ | A + D + E (2 elite liền từ A3) | Chết ở đây = "mình chọn tuyến sai/build lệch"; Continue ở elite rẻ |
| 75–100% (boss) | **Đoạn khó nhất**: cao trào, "suýt" | B + C + A (phase 2+) | Phân bố thua mục tiêu: 45–55% số lần thua nằm ở boss |
| Boss giữa run (nếu có) | Cột mốc nhỏ, giải tỏa rồi lại khó | B nhẹ (2 phase), C tắt | Chưa verify run có boss giữa hay không |

Mục tiêu phân bố **nơi người chơi thua** (trong các run thua, không-trả-tiền): trước 25% ≤ 10% · 25–55% ≈ 15% · elite chuỗi ≈ 25–30% · boss ≈ 45–55%.

### 1.4 Mục tiêu độ khó đầu tiên (cho economy-designer + sim cân bằng)

Win rate **người không trả tiền** (không Aid) theo Ascension và loại người chơi. Định nghĩa nhóm (sim dùng bot/hồ sơ): **casual** = chọn build trung bình, ít tối ưu reroll; **regular** = hiểu tag và build theo cặp; **heavy** = tối ưu tốt, biết tính đồng hồ. Số đoán đầu, chưa sim:

| Ascension | Casual | Regular | Heavy | Ghi chú |
|---|---|---|---|---|
| A0 | 40% | 65% | 85% | Casual thắng gần nửa số run: không tường ở bản thường |
| A3 | 25% | 50% | 75% | Reroll −1 bắt đầu đau; Continue bắt đầu có giá trị |
| A6 | 12% | 32% | 58% | Có pact bắt buộc; casual hầu như phải dùng Aid hoặc tự bỏ |
| A10 | 3% | 12% | 35% | "Heavy không có Aid vẫn thắng 1/3": đúng tinh thần đỉnh kỹ năng |

**Mức nâng của người dùng Aid** (cùng hồ sơ, dùng bộ Aid điển hình trong trần): mục tiêu **+8 đến +15 điểm %** ở A0–A3, **+12 đến +20 điểm %** ở A6–A10. **Ràng buộc kiểm:** regular-có-Aid ở A6 không được vượt heavy-không-Aid ở A6 (58%) → nếu vượt, Aid quá mạnh, nó biến thành P2W thật. Và casual-không-Aid ở A0 phải ≥ 35% (sàn công bằng; dưới đó là tường).

**Hiệu quả Continue (rất quan trọng):** trong các lần người chơi mua Continue ở boss, **≥ 50% phải kết thúc bằng thắng trận** (nếu thấp hơn, người chơi thấy "bán không đáng", gây hối tiếc → mất niềm tin).

### 1.5 Hand-off cho systems/combat (không thiết kế lại luật chiến đấu)

Mình chỉ nêu **cái cần có** để các công cụ A–F chạy được. Combat team chọn cách làm.

1. **`ContentDB.TUNE`** hiện: `base 10.5, growth 1.125, growth2 1.05, knee 12, elite_mult 1.25` (đọc từ `ContentDB.gd`). Cần thêm các knob (chưa verify cái nào đã tồn tại): `boss_mult`, `spike_period` (elite, boss), `spike_mult` (đòn lớn), `phase_thresholds` (66/33), `phase_budget_split` (3 phân bố ngân sách), `attrition_start` (6) + `attrition_step` (5%) + `attrition_cap` (25%), `base_clock_start` (14) cho A0. Đều là knob **gate/curve**, nằm trong `assets/data`, không hardcode.
2. **`budget(pw)`** hiện tăng theo `power_level` của đội, nghĩa là độ khó **tương đối** với power. Hệ quả: nếu ức chế chỉ đến từ tăng `base/growth` thì mọi người khó như nhau bất kể build, không tạo "build tốt thì dễ". Nên **giữ budget(pw) làm đáy**, và tạo ức chế chủ yếu bằng **hình dạng** (spike, phase, clock) để build tốt vẫn thấy hiệu quả. Sim cần thử `growth` 1.125 → 1.14–1.16 ở đoạn giữa knee chỉ khi các công cụ A–F không đủ chạm bảng §1.4.
3. **Boss design**: mỗi boss gồm 3 phase, mỗi phase một **phân bố ngân sách** (tỉ lệ dmg/phòng thủ/hỗ trợ), không trait. Đặt trên khung "budget chia theo phase", enemy-agnostic để Atia 3D gắn vào bằng model/animation, không đổi luật.
4. **Elite**: `elite_mult` (1,25 hiện tại) là ứng viên tăng; sim phải đo "tỉ lệ chết ở elite chuỗi" (§1.3).
5. **UI cần mockup trước khi code** (ux-designer): bộ đếm spike, vạch phase trên thanh HP, bộ đếm attrition, màn recap khi thua. Thiếu cái nào thì công cụ tương ứng không được bật (luật "nhìn thấy trước").
6. **Sim**: bổ sung vào `ascension-v2` mục kiểm "I. Enrage" các mục: spike, phase, attrition, và bảng §1.4. Nút xoay: đừng chỉnh `TUNE` mà không chạy lại bảng.
7. **Replay**: spike/phase/attrition là hàm xác định theo số lượt và HP, không thêm RNG, nên không làm hỏng replay.

---

## 2. Danh mục giải pháp trả phí (SỬA 11/10 — monetization chỉ trong run)

### 2.0 Nguyên tắc chung

- **P1. Vật tiêu hao một run, có trần cứng.** Không có sức mạnh vĩnh viễn mua được. (Khác Diablo Immortal: gem 5 sao nằm sau loot box tiền thật, bị review-bomb — [GameRevolution](https://www.gamerevolution.com/news/708086-diablo-immortal-pay-to-win-backlash), [VGC](https://videogameschronicle.com/news/diablo-immortals-director-comments-on-microtransaction-misinformation); ngưỡng "110.000 USD" là ước tính cộng đồng **[không chính thức]**.)
- **P2. Không đụng relic.** `relic-set-v2` khóa. Aid là hệ riêng: không chiếm ô relic, không vào pool relic, không kích hook relic, không đếm duo/tag, và có cờ `source=aid` để `twinfates` không coi Aid là nguồn reroll của relic (lead-programmer xác nhận).
- **P3. Server cấp và ghi log.** Mỗi Aid là một dòng ActionLog do server ký (§7.1). Server tung dice mọi mode, kể cả reroll thêm.
- **P4. Chỉ chào ngay khi điều kiện đau xảy ra** (không có reroll, vừa thua trận, sắp vào boss). Không chào trước vô nghĩa, trừ Run Kit/Boon ở màn chọn đội.
- **P5. Chỉ chào một lần mỗi khoảnh khắc, không nhấp nháy, không đếm ngược.** Bấm "Không, cảm ơn" thì không chào lại khoảnh khắc đó. Không popup chặn.
- **P6. Giá Aid cao hơn giá trị Shard kỳ vọng của nó** (MON-1), để không ai biến tiền thật thành Shard qua tỉ lệ thắng.

### 2.1 Bảng Aid (mỗi cái gắn công cụ ức chế §1.2)

| ID | Tên | Làm gì | Gắn với | Khi nào chào | Trần mỗi run |
|---|---|---|---|---|---|
| **R1** | **Continue (Second Wind)** | Sau khi **cả đội chết** trong một trận: chọn một trong hai dạng (OQ-A). **Dạng A (restart)**: vào lại trận từ đầu, đội đầy HP, địch reset, dice server mới. **Dạng B (resume, khuyến nghị)**: đội hồi sống ở 40% HP, **địch giữ nguyên HP và phase hiện tại**, enrage/attrition về 0, dice server mới | B, C, F (khoảnh khắc "suýt") | Màn thua trận, trước khi kết thúc run. Không đếm ngược. Nút nằm đó đến khi chọn | 1/run (VIP 2). Giá boss ×2 trận thường. **Lần Continue đầu của tài khoản miễn phí** nếu thua ở A0–A2 (sampling, §2.6) |
| **R2** | **Reroll thêm** | +1 reroll xúc xắc cho lượt hiện tại (không cộng dồn) | A, D (tìm đúng mặt Shield/đòn trước spike) | Khi reroll = 0 | 4/run, 2/trận. Lẻ hoặc gói 3 |
| **R3** | **Reroll thẻ thưởng** | +1 reroll thẻ thưởng (vô hiệu ở A10: Aid không phá luật Ascension) | F6 cũ: "không có thẻ cần" | Màn chọn thẻ | 2/run |
| **R4** | **Hoãn đồng hồ boss** | +2 lượt trước khi enrage (chốt sau sim) | C (và phase 3 của B) | Khi bộ đếm enrage còn ≤ 2 lượt, và màn intro boss | 1 lần/boss |
| **R5** | **Đổi pact** | Reroll 1 offer pact bắt buộc (A6/A10). Không bán "bỏ pact" | Pact bắt buộc | Màn pact | 1/pact |
| **R6** | **Coupon shop** | −20% giá lần ghé shop kế tiếp (không thấp hơn giá gốc trước A1) | Shop đắt A1/A8 | Cổng shop | 2/run |
| **R7** | **Scout** | Hiện loại node 3 hàng kế (thấy elite chuỗi) | E | Màn bản đồ | 3/run |
| **R8** | **Boon đầu run** | Chọn 1/3 Boon nhỏ (8 Boon cố định, không phải relic): ví dụ +1 reroll trận đầu, Shield lượt 1 trận đầu, coupon shop đầu | Mở đầu run | Màn chọn đội | 1/run (VIP 2) |
| **R9** | **Run Kit** | Bó R2×2 + R7×1 + R8×1, rẻ hơn mua lẻ ~25% | Mở đầu run | Màn chọn đội | 1/run |
| **R10** | **Hồi khẩn** *(mới)* | Hồi 40% HP tối đa cho **một** đơn vị đang sống, trong lượt của người chơi | A (trước spike), D | Khi có đơn vị ≤ 40% HP và có spike trong ≤ 2 lượt | 2/run, 1/trận *(economy 11/10: hạ từ 3, §9.2)* |

**Trần tổng mỗi run:** tối đa 8 lần `AID_USE` (không tính Run Kit/Boon đầu run, đã tính riêng). Ba lý do: dễ đọc, dễ audit, dễ kiểm sàn công bằng (§1.4). (OQ-D)

### 2.2 Chạm đúng khoảnh khắc: lịch chào

| Khoảnh khắc | Điều kiện | Chào gì | Ghi chú đọc được |
|---|---|---|---|
| Màn chọn đội, trước run | luôn | R9 Kit, R8 Boon | Thông tin trần/giá hiện rõ |
| Màn bản đồ | còn chỗ chưa thấy elite | R7 | Một dòng gợi ý, không popup |
| Màn pact (A6/A10) | có offer | R5 | |
| Màn chọn thẻ | có thẻ | R3 | Ẩn ở A10 |
| Cổng shop | có coupon | R6 | |
| Trong trận, lượt người chơi, reroll = 0 | | R2 | Nút phụ cạnh END TURN |
| Trong trận, có unit ≤ 40% HP và spike ≤ 2 lượt | | R10 | |
| Boss, enrage còn ≤ 2 lượt | | R4 | |
| Thua trận (cả đội chết) | luôn | **R1 Continue** | Kèm recap (§1.2-F) |

### 2.3 Hòa với relic, Ascension, ranked, replay

- **Ascension**: Aid không phá luật (R3 vô hiệu ở A10; R5 không bỏ pact; Continue không reset bộ đếm ladder). Danh hiệu cosmetic A5/A10 vẫn nhận, run detail hiện "Aid đã dùng".
- **Ranked**: mọi Aid được dùng, mỗi cái là một entry log; leaderboard có bộ lọc "Pure".
- **Replay verify (`RunVerifier`)**: vì server tung dice, replay không còn chạy nguyên văn theo seed. ActionLog chứa kết quả dice do server ký và các sự kiện `AID_USE`, `CONTINUE`. Verifier kiểm: (1) `entitlement_id` hợp lệ, chưa tiêu, đúng tài khoản; (2) số Aid ≤ trần; (3) hiệu ứng đúng luật (ví dụ reroll thêm ≤ 2/trận; Continue dạng B: địch đúng HP lúc chết). Bump `RULES_VERSION` (§7.1).

### 2.4 Nhóm tài khoản / meta (giữ, bỏ phần Nhiệm vụ)

| ID | Tên | Làm gì | Khi nào chào | Giới hạn |
|---|---|---|---|---|
| **T1** | **Vé bundle** | Gói vé (6/15/40/100). Quay hộp thường hoặc mùa, **không giới hạn 20 lượt/ngày** (Liam A11) | Cổng Echo Box khi đụng "tường giá" (~vé 12+ trong ngày) và store | Chỉ trần chi tiêu chung (§3.6) |
| **T2** | **Pass premium** | Track trả phí, thưởng cosmetic/Shard/vé/Gem hoàn, **không** có sức mạnh combat. 900 Gem ≈ 9,99 USD. **T2b**: mua nhảy cấp tối đa 10/mùa | Màn Pass; khi nhận thưởng free ở mốc có premium cạnh bên | Mua được tới tuần 6/8 với giá giảm |
| **T3** | **VIP "Moon Card"** | 30 ngày: 20 Gem/ngày (nhận chủ động, không cộng dồn), 1 vé/ngày, Continue 2/run, 1 Boon thêm/run. Không tăng Shard/Stone | Đầu ngày; sau thua run lần 2 | 4,99 USD (neo Welkin Moon, [Codashop **[không chính thức]**](https://news.codashop.com/us/?p=16685)). Cộng dồn tối đa 180 ngày. *(Bỏ "Thử lại miễn phí" và "Đổi bảng" của bản trước, vì thuộc Nhiệm vụ.)* |
| **T4** | **Starter Pack** | Ưu đãi lần đầu: 0,99 USD → 160 Gem + 3 vé + 1 Boon | Sau run thứ 3 hoàn thành | Một lần/tài khoản |
| **T5** | **Cosmetic bundle** | Skin Axie, dice, khung. Bán thẳng, không gacha | Store | Giá cố định |
| **T6** | **Bộ mùa mua thẳng** | Mua thẳng món/bộ hộp mùa bằng Gem, giá cố định | Hộp mùa, sau ≥ 10 lượt | Lá chắn pháp lý/niềm tin (§6) |
| **T7** | **Land Stone pack** | **Không bán trong v1** | | §3.5 |

**Thứ tự ưu tiên triển khai** (đau × an toàn): R1 Continue → T3 VIP → T2 Pass → R2/R10 → R4 → T1/T4 → R7/R8/R9.

### 2.5 Đã bỏ trong bản sửa 11/10

Bỏ hẳn: M1 Thử lại, M2 Bảo hiểm cược, M3 cấp nhà/slot bằng Gem, M4 Đổi bảng, biến thể "Iron" gắn Aid, RTP_aided, mercy valve cho Nhiệm vụ, số `mission_slots_*`. Hệ quả: Aid **không còn đường nào ra Shard** (trước đây M2 hoàn Shard), nên MON-2 trở thành tuyệt đối.

### 2.6 Mercy / sampling trong run

- **Continue đầu miễn phí** (một lần/tài khoản, nếu thua ở A0–A2): để người chơi biết Continue là gì trước khi bị mời trả tiền. Thông lệ "tặng mẫu trước khi bán" ([stepico **[không chính thức]**](https://stepico.com/?p=18445)).
- **Thua 3 run liên tiếp trong 24h UTC**: run kế tiếp được 1 Boon đầu run miễn phí. **Không đổi độ khó.** Đo churn trước/sau (§7.3).

---

## 3. Cấu trúc store (SỬA 11/10: bỏ Nhiệm vụ, giữ nguyên còn lại)

### 3.1 Tiền cao cấp: Lunar Gem

Một loại duy nhất (tên tạm, tránh trùng "Gene Shard/Land Stone/Moon Dust"). Vé bundle giao vé trực tiếp, người chơi không phải đổi hai lần.

| Mốc USD | Gem cơ sở | Starter (lần đầu) | Gem/USD |
|---|---|---|---|
| 0,99 | 80 | 160 | 81 |
| 4,99 | 420 | — | 84 |
| 9,99 | 880 | — | 88 |
| 19,99 | 1.800 | — | 90 |
| 49,99 | 4.650 | — | 93 |
| 99,99 | 9.600 | — | 96 |

*(Economy 11/10: hai mốc cuối hạ từ 4.700/9.800 để bonus ≤ 20%: cơ sở 80/0,99 = 80,8 Gem/USD, mốc 99,99 = 96,0 → +18,8%. Chi tiết §9.1.)*

Bonus giữa các mốc ≤ 20%, neo 19,99. Tham chiếu Genshin 60/300/980/1.980/3.280/6.480 ([Codashop **[không chính thức]**](https://news.codashop.com/us/?p=16685)).

### 3.2 Gem đổi được gì

| Đường | Cho phép? | Lý do |
|---|---|---|
| Gem → vé (bundle) | Có | Quyết định Liam. Vé ra Stone/cosmetic, không ra Shard |
| Gem → Pass, VIP, Aid, cosmetic | Có | SKU chính |
| Gem → **Gene Shard** | **Không** | Shard là stake Nhiệm vụ và vật liệu nâng nhà Nhiệm vụ. Bán Shard biến bài test risk-to-earn thành "ai nạp nhiều thì cược nhiều" và phá thang giá vé |
| Gem → **Land Stone** | **Không** (v1) | Land là thành tựu dài hơi; bán Stone phá pity và neo Land vào USD |
| Shard/Stone → Gem | Không | Một chiều |
| Gem tặng/giao dịch | Không | Tránh chợ đen, rửa tiền |

Lý do giữ "không Gem → Shard" **mạnh hơn** sau sửa đổi: nhà Nhiệm vụ nâng bằng Shard + Stone, nếu Gem đổi được Shard thì tiền thật lại chảy vào Nhiệm vụ qua cửa sau. Mình không đề xuất đổi quyết định này.

### 3.3 Premium Pass, 3.4 VIP

Như T2/T3. Premium không bao giờ là sức mạnh combat; hoàn khoảng 30–40% giá bằng Gem (mô hình Pass thay bán thẻ trực tiếp, [Marvel Snap Zone **[không chính thức]**](https://marvelsnapzone.com/marvel-snaps-endgame-economy-answering-the-biggest-questions/)). VIP: quà theo ngày phải nhận chủ động; lợi ích chỉ là tiện lợi + trần Aid cao hơn; hiện tổng giá trị/ngày trong store.

### 3.5 Vì sao chưa bán Land Stone

Land là một trong hai trục mục tiêu dài hạn của Liam. Bán trực tiếp thì mỗi Stone phải neo USD, pity hộp mùa mất ý nghĩa, Land thành "tài sản có giá" (nặng thêm pháp lý nếu liên quan AXS). Giữ, xem lại sau khi có dữ liệu.

### 3.6 Trần chi tiêu, tuổi

| Biện pháp | Đề xuất |
|---|---|
| Tuổi | 13+; dưới 18 (hoặc theo luật địa phương) trần 30 USD/tháng, tắt vé bundle trong hộp mùa; dưới 13 không bán. Pháp lý chốt |
| Trần mềm | Cảnh báo ở 100 USD/tháng; xác nhận lần nữa ở 250 |
| Trần cứng | 500 USD/tháng/tài khoản (OQ-9) |
| Tự đặt giới hạn | Có trong Settings |
| Hoàn tiền | Theo cửa hàng; chargeback trừ Gem về âm, không xóa tài khoản ngay |

---

## 4. Ranked và leaderboard (SỬA 11/10 — monetization chỉ trong run)

**Quyết định Liam**: mua được dùng trong ranked. **Khuyến nghị: một bảng, mọi Aid tính, kèm bộ lọc "Pure".**

| Lựa chọn | Ưu | Nhược |
|---|---|---|
| A. Một bảng, không tag | Đơn giản | Nhóm cạnh tranh thuần kỹ năng không có chỗ; nguy cơ "bảng ví tiền" |
| **B. Một bảng + ký hiệu Aid + lọc Pure (khuyến nghị)** | Không chia cộng đồng; lọc miễn phí từ ActionLog; minh bạch | Cần UI "Aid đã dùng" |
| C. Hai bảng | Rõ cho cạnh tranh thuần | Chia nhỏ cộng đồng; bảng Pure trống lúc đầu |

Vì ức chế nằm trong run và Aid mạnh hơn khi vào ranked, có thêm 2 điểm cần Liam biết:
- Độ khó A6–A10 (§1.4) vốn đã cao, nên trên ranked người dùng Aid sẽ chiếm tỉ lệ lớn. Đo "tỉ lệ run Pure trong top 100" (§7.3). Nếu < 20%, cân nhắc bảng Pure riêng (OQ-4).
- Mọi cuộc kiểm ranked chạy trên run có Aid phải verify `AID_USE` (§2.3), nếu không Aid trở thành đường gian lận.

*(Bỏ RTP_aided, RTP_pure, phiên bản "Iron" của bản trước.)*

---

## 5. Hook cho economy-designer (SỬA 11/10 — monetization chỉ trong run)

### 5.1 Số cần đặt

| # | Số | Gợi ý đầu | Ghi chú |
|---|---|---|---|
| E1 | Bảng USD → Gem (§3.1) | như bảng | **CHỐT (economy 11/10):** 80 / 420 / 880 / 1.800 / 4.650 / 9.600 Gem; hai mốc cuối hạ để bonus ≤ 20% (cao nhất +18,8%). Tham chiếu 90 Gem/USD. §9.1 |
| E2 | Giá vé bundle (6/15/40/100) | vé ≈ 20 Gem ≈ 0,25 USD; giảm 0–25% | **CHỐT:** 120 / 285 / 720 / 1.700 Gem = 20 / 19 / 18 / 17 Gem mỗi vé (giảm 0/5/10/15%). Đường mua thẳng Land ≈ 1.170 USD (§9.7) |
| E3 | Shadow price Gem ↔ Shard | 1 Gem ≈ 10 Shard | **CHỐT:** 1 Gem = 10 Shard, chỉ để kiểm giá (1 vé 200 Shard = 20 Gem). Là cận thận trọng: giá vé trung bình thực 220–278 Shard |
| **E4** | **Giá Aid** | R1: ~60 (thường) / ~120 (boss) · R2: ~15 · R3: ~10 · R4: ~40 · R5: ~10 · R6: ~8 · R7: ~10 · R8: ~25 · R9 (Kit): ~55 · R10: ~20 Gem | **CHỐT:** R1 60 / 120 · R2 10 · R3 8 · R4 40 · R5 10 · R6 6 · R7 8 · R8 25 · R9 Kit 40 · R10 12 Gem. Dải 8–24 Gem cho mỗi điểm % thắng mỗi run, MON-1 dư 1,9–28 lần (§9.2, §9.5) |
| **E5** | **Trần Aid/run** | R1: 1 (VIP 2) · R2: 4 · R3: 2 · R4: 1/boss · R5: 1/pact · R6: 2 · R7: 3 · R8: 1 (VIP 2) · R10: 3 · tổng `AID_USE` ≤ 8 | **CHỐT:** như gợi ý, ĐỔI: R10 3→**2**; VIP **không** thêm Continue (1/run, giá −25%); VIP Boon **1/ngày** (không 1/run); A10 tổng ≤ **4**. Trần 8 là bắt buộc cho MON-11 (§9.4, §9.9) |
| **E6** | **Mục tiêu độ khó (§1.4)** | bảng win rate A0/A3/A6/A10 × casual/regular/heavy; nâng Aid +8–20 điểm; sàn casual-A0 ≥ 35% | **CHỐT (theo Liam "thật khó"):** hạ bảng xuống, giữ sàn 35% và khoảng cách heavy − regular ở A6 ≥ 26 điểm. Bảng mới + mức nâng ở §9.4 |
| **E7** | **Mục tiêu phân bố nơi thua và hiệu quả Continue** | §1.3 (boss 45–55% thua); Continue boss thắng ≥ 50% | **CHỐT:** Continue boss người mua thắng ∈ [50%, 80%] **và** tỉ lệ cứu toàn bộ lần thua (nếu mua mọi lần) f₁ ≤ 0,17 ở regular A6, ≤ 0,10 ở A10. Hai số này mâu thuẫn nhau nếu boss chưa tinh chỉnh, xem BREAK-1 §9.9 |
| E8 | Pass premium: giá, thưởng, hoàn Gem | 900 Gem, hoàn 30–40% | **CHỐT:** 880 Gem (khớp gói 9,99, không dư lẻ); hoàn 300 Gem (34%) ở lv10/20/30; track premium KHÔNG Shard, KHÔNG Stone. §9.3 |
| E9 | VIP: giá, thưởng/ngày, trần | 4,99 USD, 20 Gem + 1 vé/ngày, 180 ngày | **CHỐT:** 4,99 USD (= 420 Gem); 20 Gem + 1 vé + 1 Boon (lần chơi đầu ngày); Continue giá −25%, vẫn 1/run; trần cộng dồn 180 ngày |
| E10 | Starter pack | như T4 | **CHỐT:** 0,99 USD → 160 Gem + 3 vé + 1 Boon (≈ 245 Gem-eq = 2,7× thường) |
| E11 | Giá bộ mùa mua thẳng (T6) | ~85% giá trần 80 lượt quy ra Gem | **CHỐT:** Epic 200 / Legendary 450 / Mythic 900 Gem mỗi món; cả bộ 3.700 Gem (≈ 41 USD). Không theo "85% trần" (= 6.800 Gem): vì mua thẳng không có Stone. §9.3 |
| E12 | Trần chi tiêu | 30/100/250/500 USD | **CHỐT:** giữ 30/100/250/500 USD. Whale mẫu (~250 USD/tháng) nằm đúng ngưỡng xác nhận |
| E13 | Ngưỡng sampling (§2.6) | Continue đầu miễn phí; 3 run thua/24h → 1 Boon | **CHỐT:** giữ; Boon miễn phí tối đa 1 lần/24h/tài khoản; Continue miễn phí chỉ A0–A2, 1 lần/tài khoản |
| E14 | Giá trị Shard của một run thắng so với thua | lấy từ `economy-v2` | **CHỐT:** short: thắng 569 − thua 258 = **311** Shard (probe `economy_probe`); full: thắng ~854, thua chưa đo, dùng cận trên **600**. Dùng cho §9.5 |

**Bỏ khỏi danh sách:** mọi số Nhiệm vụ (M1/M2 giá, `mission_slots_*`, giá cấp nhà, RTP). Giá nâng nhà Nhiệm vụ thuộc thiết kế Nhiệm vụ (Shard + Stone).

### 5.2 Ảnh hưởng tới nhịp Land

Chỉ qua vé (T1, T3, T4, Pass, T6). Theo `economy-v2`: +50 vé/tuần đưa "nửa bộ" xuống 36,8/58,0/65,0 tuần cho heavy/regular/casual; +100 vé/tuần xuống 28,4/39,5/42,6. Với E2, +100 vé/tuần ≈ 25 USD/tuần ≈ 108 USD/tháng. Economy-designer ước thêm vé từ VIP/Pass và kiểm trần "nạp lên Land nhanh gấp ~3,2 lần". Khuyến nghị: người nạp nhiều nhất tới LunaLanding sớm nhất ≥ 6 tháng. Aid **không** đổi nhịp Land.

### 5.3 Ảnh hưởng của Aid lên Shard (thay cho "RTP Nhiệm vụ")

Aid tăng tỉ lệ thắng run, mà thắng run cho Shard. Vì vậy có đường gián tiếp Gem → xác suất thắng → Shard (kể cả khi ranked/Shard từ run bị giới hạn). Phải bằng MON-1 mới (§5.4). Economy-designer cần số E14.

### 5.4 Bất biến kinh tế

- **MON-1 (không arbitrage Gem → Shard)**: với mọi Aid A, `giá_Gem(A) × E3 ≥ 1,5 × ΔP_thắng(A) × (Shard_thắng − Shard_thua)`, với ΔP_thắng đo từ sim trên người chơi trung bình ở độ khó đó. Ví dụ minh họa (số giả): ΔP = 15 điểm, chênh Shard thắng/thua = 400 → ΔEV = 60 Shard → giá ≥ 1,5 × 60 / 10 = **9 Gem**. Kết quả này cho thấy Aid trong run rẻ về Shard nên **MON-1 hiếm khi là ràng buộc chặt**; giá Aid thực sự quyết bởi mục tiêu doanh thu và niềm tin, không bởi arbitrage.
- **MON-2 (không đường Gem → Shard trực tiếp, và không hoàn Shard)**: không SKU "Shard", không Aid nào trả Shard.
- **MON-3 (trần Aid/run)**: server từ chối `AID_USE` vượt trần.
- **MON-4 (Aid không phải relic)**: không tag relic, không ô relic, không đếm duo/set.
- **MON-5 (không độ khó theo ví)**: độ khó và RNG không đọc số dư Gem/lịch sử mua. Test tĩnh: code sinh run không có input ví. Mọi A/B chia ngẫu nhiên, không theo ví.
- **MON-6 (dice stream)**: stream dice không đổi khi có Aid, trừ kết quả mà Aid định nghĩa (reroll thêm, Continue → stream mới).
- **MON-11 (sàn không trả tiền, mới)**: win rate casual-không-Aid ở A0 ≥ 35% và regular-có-Aid ở A6 ≤ heavy-không-Aid ở A6 (§1.4). Kiểm bằng sim mỗi khi đổi `TUNE`.

---

## 6. Rủi ro (nêu một lần, Liam quyết)

### 6.1 Niềm tin người chơi

- **Rủi ro mới, lớn nhất: "khó để ép nạp".** Hướng của Liam là cố tình làm quái/boss ức chế rồi bán lối thoát. Ranh giới giữa "game khó, có lối tắt tùy chọn" và "game bị bóp để bán" rất mỏng. Rào đã đưa vào: sàn win rate (MON-11), ức chế luôn đọc được trước (§1.1), không đổi độ khó theo ví/chuỗi thua, Continue phải thắng ≥ 50%, công khai giá và trần, đo churn sau chuỗi thua. Nếu một trong các số này vỡ, giảm ức chế trước khi nghĩ tới tăng giá.
- **Diablo Immortal (2022)**: backlash vì gem mạnh bị khóa sau loot box tiền thật, tuyên bố "không mua được trang bị" bị coi là gây hiểu lầm ([GameRevolution](https://www.gamerevolution.com/news/708086-diablo-immortal-pay-to-win-backlash), [VGC](https://videogameschronicle.com/news/diablo-immortals-director-comments-on-microtransaction-misinformation), [GamingBolt](https://gamingbolt.com/what-went-wrong-with-diablo-immortal)). Bài học: nói thẳng "bạn có thể mua sức mạnh trong run"; công khai trần Aid.
- **Hearthstone/Marvel Snap**: pity công khai và track thưởng thay bán thẻ ([Hearthstone wiki **[không chính thức]**](https://hearthstone.wiki.gg/wiki/Pity_Timer)). Axie Dice bán sức mạnh trong run nên cần minh bạch *nhiều hơn*.
- **Candy Crush/Clash of Clans**: thương mại hóa thời điểm thất bại hiệu quả, và có chi phí hối tiếc ([GameAnalytics **[không chính thức]**](https://gameanalytics.com/?p=2825)). Ta không bán tăng tốc thời gian thuần.
- **Archero/Survivor.io**: doanh thu lớn bằng IAP+quảng cáo (Survivor.io qua 75 triệu USD sau hai tháng, [Mobilegamer](https://mobilegamer.biz/two-months-in-survivor-io-passes-75m-from-37m-downloads/), số liệu AppMagic), retention dài hạn yếu ([Naavik **[không chính thức]**](https://naavik.co/digest/how-habby-mastered-tiktok-ua-for-survivor/)). Mô tả revive/continue của thể loại là mô hình thông dụng, **chưa verify** từng cơ chế. Slay the Spire mobile (mua một lần) không có đau nào để bán.
- **Genshin resin**: không bán thứ gì tương đương (energy/stamina không có trong Axie Dice; thêm sẽ mâu thuẫn bản chất run-based).

### 6.2 Pháp lý (sự thật, không phải tư vấn)

1. **Loot box có vé mua bằng tiền thật.** Apple yêu cầu công bố odds (Guideline 3.1.1, [Fenwick](https://fenwick.com/insights/publications/apple-now-requires-disclosure-of-loot-box-odds)); Trung Quốc có luật công bố xác suất; Valve chặn hộp tại Bỉ/Hà Lan ([hardwaresfera **[không chính thức]**](https://hardwaresfera.com/en/noticias/videojuegos/steam-impide-abrir-cajas-botin-en-belgica-y-holanda-tras-ser-consideradas-juegos-de-azar/)). Biện pháp: hiển thị odds + pity, T6 mua thẳng, cân nhắc tắt bán vé ở BE/NL.
2. **Nhiệm vụ stake và Aid tách riêng** (SỬA 11/10): vì Aid không dùng ở Nhiệm vụ, rủi ro "trả tiền để tăng cơ hội thắng một cược có giá trị" biến mất. Vẫn cần ý kiến pháp lý Sky Mavis trước khi stake sang AXS, nhưng đó là việc của thiết kế Nhiệm vụ, không còn là điều kiện của store.
3. **Aid trong ranked**: nếu ranked sau này có giải thưởng có giá trị tiền, "trả tiền để tăng cơ hội thắng" có thể bị xem xét. Cần pháp lý khi ranked có giải thật.
4. **Luật theo vùng** (Anh, EU, Hàn Quốc, Nhật, Úc): chưa verify. Cần danh sách vùng tắt vé.
5. **Xếp hạng tuổi**: nhãn "In-Game Purchases (Includes Random Items)" thường gặp cho loot box (chưa verify). Dự kiến 13+.
6. **Nền tảng**: Steam yêu cầu MicroTxn ([Steamworks](https://partner.steamgames.com/doc/features/microtransactions)); Mac App Store bắt buộc IAP cho hàng hóa số ([conductatlas **[không chính thức]**](https://conductatlas.com/platform/apple/apple-app-store-review-guidelines/mandatory-in-app-purchase-for-digital-goods)); hoa hồng ~30% (chưa verify). Web cần cổng riêng. Một server entitlement, ba kênh thanh toán (§7.1).
7. **Trẻ em**: COPPA/GDPR-K (chưa verify ngưỡng).

### 6.3 Rủi ro thiết kế

- **Ức chế quá liều → churn**: giảm bằng nhịp dễ-khó (§1.3: 25% đầu run dễ), sàn win rate, Continue đầu miễn phí, đo churn.
- **Bán sức mạnh làm yếu "relic là trọng tâm"**: Aid nhỏ, có trần, ngoài relic.
- **Continue dạng B quá mạnh ở boss**: nếu boss còn 5% HP, Continue gần như mua chiến thắng. Chỉnh bằng HP đội hồi (40%) và đo "Continue thắng" (§1.4). Nếu > 80%, chuyển sang dạng A.
- **Hiệu ứng ngược của spike/phase**: nếu bộ đếm không hiển thị đủ rõ thì thành "ức chế do game gian". Không bật công cụ khi UI chưa có.
- **Tương tác với Ascension ladder**: Continue ở A10 có thể làm ladder vô nghĩa. OQ-6.
- **Hai núm cùng lúc** (độ khó tăng và giá Aid giảm/tăng): đổi từng cái một khi chạy A/B.

---

## 7. Triển khai, bất biến, telemetry

### 7.1 Server-authoritative, entitlement, biên nhận

- **Nguồn sự thật là server** (Cloudflare Worker + D1, đã có tài khoản/cloud save). Client không giữ số dư Gem làm gốc.
- **Bảng đề xuất** (D1): `gem_ledger(account_id, delta, reason, ref, at)` (sổ cái bất biến), `purchases(receipt_id, channel, sku, account_id, status, at)` (idempotent theo `receipt_id`), `entitlements(entitlement_id, account_id, sku, qty_left, expires_at)`.
- **Luồng**: client bắt đầu thanh toán → kênh xác nhận → server xác minh biên nhận độc lập → ghi `purchases` + `gem_ledger` → client đọc lại số dư. Hoàn tiền: Gem về âm; entitlement chưa tiêu bị thu hồi; run đã xong không bị xóa (chỉ gắn cờ nếu nghi gian lận).
- **Dùng Aid**: client gửi `use_aid(type, run_id, battle_idx, nonce)` → server kiểm trần, trạng thái run/trận, điều kiện chào (MON-10) → trừ Gem/entitlement trong cùng giao dịch → trả kết quả → ghi `AID_USE` (có chữ ký server) vào ActionLog.
- **Continue**: `CONTINUE{battle_idx, form, enemy_hp_snapshot}`; server lưu snapshot HP/phase địch lúc chết (dạng B) để verifier kiểm.
- **Idempotency**: nonce mỗi lần gọi; cùng nonce chỉ trừ một lần; mạng rớt giữa chừng thì server quyết, client chỉ hiển thị. Online-only (đã là quyết định); mất mạng giữa run → resume theo luật resume server, Aid đã trừ không mất.
- **ActionLog/RULES_VERSION**: thêm sự kiện (`AID_USE`, `CONTINUE`), thêm spike/phase/attrition vào luật = đổi luật xác minh → bump `RULES_VERSION` và `t_rules_version` (nhóm 19 file rule). Làm cùng luồng "server tung dice".
- **Mọi ghi save qua `SaveStore`**: số dư Gem không nằm trong save client.

### 7.2 Bất biến (thêm vào `build-spec.md` INV-1..7 khi duyệt)

MON-1..MON-6 và MON-11 ở §5.4, và:
- **MON-7**: mọi SKU có giá/odds/giới hạn công khai trước khi mua.
- **MON-8**: số dư Gem không âm ngoài hoàn tiền/chargeback; không đường đảo chiều Gem → Shard/Stone.
- **MON-9**: không SKU nào đổi `relic_pool`, `rules`, hay xác suất rơi relic.
- **MON-10**: server từ chối `AID_USE` nếu run đã kết thúc hoặc chưa tới điều kiện chào (§2.2).
- **MON-12 (mới)**: không SKU/Aid nào chạm Nhiệm vụ (stake, slot, offer, cấp nhà). Test tĩnh: không có tham chiếu Aid trong code Nhiệm vụ.

### 7.3 Telemetry (SỬA 11/10)

| Chỉ số | Cách đo | Ngưỡng cảnh báo (số đầu) |
|---|---|---|
| Win rate người không trả tiền theo A-level × hồ sơ | ActionLog | lệch hơn ±8 điểm so với bảng §1.4: chỉnh `TUNE` |
| **Nơi thua** (trước 25%, giữa, elite chuỗi, boss) | ActionLog | boss < 35% hoặc > 65% thua: chỉnh phase/clock |
| **Boss HP còn lại khi thua** (trung vị) | ActionLog | mục tiêu 15–30%; < 10% quá dễ; > 50% tường |
| **Continue**: tỉ lệ mua, tỉ lệ thắng sau Continue | ActionLog | thắng < 50%: hạ giá hoặc đổi dạng |
| Offer view → mua theo từng khoảnh khắc (R1, R2, R4, R10…) | điểm chào | < 0,5% sau 1.000 lượt: bỏ/đổi |
| Aid/run trung bình theo A-level | ActionLog | quá cao = quá khó |
| **Churn sau ức chế** | % không quay lại D1/D7 sau ≥ 3 run thua liên tiếp, so với nhóm đối chứng | cao hơn > 25% tương đối: hạ ức chế, tăng sampling |
| Rage quit trong trận (thoát giữa spike/phase) | sự kiện thoát | tăng đột biến khi bật công cụ mới: tắt |
| Tỉ lệ run Pure trong top 100 ranked | ActionLog | < 20%: cân nhắc bảng Pure riêng |
| Payer %, ARPPU, ARPDAU | doanh thu/người mua, /DAU | < 1% sau 30 ngày xem lại; > 10% có thể quá ép. Bối cảnh Survivor.io ([Global Games Forum **[không chính thức]**](https://www.globalgamesforum.com/news/how-survivor.io-continues-to-pull-in-5-million-a-month-three-years-later)) |
| Phân bố chi tiêu (top 1%/10%, Gini) | | top 1% > 50% doanh thu: cảnh báo |
| Hoàn tiền/chargeback | kênh | trên ngưỡng cửa hàng |

A/B giá hoặc độ khó phải theo nhóm ngẫu nhiên, **không theo ví** (MON-5).

---

## 8. Câu hỏi mở cho Liam

| # | Câu hỏi | Khuyến nghị | Trạng thái |
|---|---|---|---|
| OQ-1 | Tên tiền cao cấp? | Tên không trùng Shard/Stone/Moon Dust | mở |
| OQ-2 | Gem → Shard? | Không | **chốt, lý do mạnh hơn** |
| OQ-3 | Bán Land Stone? | Không ở v1 | mở |
| OQ-4 | Ranked: một bảng + lọc Pure hay hai bảng? | Một bảng + lọc Pure; xem lại nếu Pure < 20% top 100 | mở |
| ~~OQ-5~~ | ~~Iron / Thử lại ở bậc cao nhất~~ | | **Obsolete** (bỏ Nhiệm vụ) |
| OQ-6 | Aid dùng được ở A10, tính danh hiệu A5/A10, bán Đổi pact? | Cho dùng; vẫn nhận danh hiệu; hiển thị "Aid đã dùng"; bán Đổi pact, không bán bỏ pact | mở |
| OQ-7 | Continue ở boss cuối? | Cho, giá ×2 | mở |
| ~~OQ-8~~ | ~~Aid khi stake AXS~~ | | **Obsolete** (Aid không chạm Nhiệm vụ) |
| OQ-9 | Trần chi tiêu 500/tháng, dưới 18 là 30? | Đồng ý, pháp lý chốt | mở |
| OQ-10 | Pass premium từ ngày 1 hay chờ mùa 2? | Chờ mùa 2 | mở |
| OQ-11 | Quảng cáo thưởng? | Không ở v1 | mở |
| OQ-12 | Hỏi pháp lý Sky Mavis trước khi code store? | Có (loot box + ranked có giải) | mở |
| OQ-13 | Giữ T6 mua thẳng bộ mùa? | Giữ | mở |
| OQ-14 | Kênh thanh toán v1? | Steam trước | mở |
| **OQ-A** | Continue dạng nào: A (restart trận) hay B (resume, địch giữ HP, đội hồi 40%)? | **B**, kèm theo dõi thắng ≥ 50% và ≤ 80% | mới |
| **OQ-B** | Có thêm Boss Clock nhẹ ở A0 (lượt 14, +10%/lượt, tối đa 3) để quen đồng hồ? | Có | mới |
| **OQ-C** | Chấp nhận bảng độ khó §1.4 làm mục tiêu sim (A0 casual 40%, A10 casual 3%)? | Chấp nhận làm mốc đầu, sim chỉnh | mới |
| **OQ-D** | Trần tổng 8 `AID_USE`/run và R10 Hồi khẩn có ổn? | Ổn; R10 có thể bỏ nếu quá giống hồi HP (HP vốn hồi đầy mỗi trận) | mới |
| **OQ-E** | Mức ức chế "attrition trong trận" (D) và spike (A) có bật cùng lúc ở A0 không? | Bật spike từ A3, attrition từ A0 nhẹ; chốt sau sim | mới |

## 9. Định giá (economy-designer, 11/10)

**Trạng thái:** đề xuất để Liam duyệt, rồi senior reviewer audit. **Chưa qua sim.** Mọi ΔP, f₁ và win rate bên dưới là mô hình số tay với giả định ghi rõ; sim phải xác nhận trước khi tin giá. Chỗ nào là giả định tôi ghi "giả định".

**Kết quả một đoạn.**
- Giá Aid nằm trong dải 8–24 Gem cho mỗi điểm % thắng mỗi run (khoảng 0,09–0,27 USD), Continue 60/120 Gem (0,67/1,33 USD).
- MON-1 không phải ràng buộc chặt (dư 1,9 đến 28 lần so với 1,5 cần), đúng như game-designer dự đoán. Giá quyết bởi doanh thu và niềm tin.
- **Chỗ vỡ thật là MON-11** (sàn công bằng), không phải MON-1. Liam chốt Continue kiểu B hồi 40%: với mô hình của tôi, Continue một mình cứu ≈ 37% số lần thua, đẩy regular-có-Aid ở A6 lên 58,1% so với trần heavy-không-Aid 50% (bảng đã hạ theo Liam, §9.4). Sửa không nằm ở giá mà ở độ dốc của boss sau Continue (BREAK-1, §9.9).
- Người nạp nhiều lên Land nhanh gấp 1,9 lần (heavy) tới 3,4 lần (casual) so với không nạp; mua đủ cả đường Land bằng vé ≈ 1.170 USD (§9.7).
- Doanh thu tham chiếu ≈ 3.170 USD/tháng mỗi 1k DAU (gộp), 2.220 sau phí 30% (§9.8). Số giả định, có độ nhạy.

**Đơn vị tham chiếu (chỉ để kiểm giá, không có quy đổi trong game):** 1 Gem = 10 Shard (E3) = 0,0111 USD (ở 90 Gem/USD). Suy ra 1 Shard = 0,00111 USD, một run R = 450 Shard ≈ 0,50 USD, một vé 200 Shard = 20 Gem = 0,22 USD. Gem không đổi ra Shard hay Stone; con số này chỉ cho phép so "Aid này đáng bao nhiêu Shard" với "giá Gem của nó".

### 9.1 Gem

| Mốc USD | Gem | Gem/USD | Bonus so với cơ sở 80,8 | Ghi chú |
|---|---|---|---|---|
| 0,99 | 80 | 80,8 | 0 | lần đầu: Starter 160 Gem + 3 vé + 1 Boon |
| 4,99 | 420 | 84,2 | +4,2% | đúng giá Moon Card |
| 9,99 | 880 | 88,1 | +9,0% | đúng giá Pass premium |
| 19,99 | 1.800 | 90,0 | +11,4% | mốc tham chiếu 90 Gem/USD |
| 49,99 | 4.650 | 93,0 | +15,1% | hạ từ 4.700 |
| 99,99 | 9.600 | 96,0 | +18,8% | hạ từ 9.800 (cũ +21,2% vượt 20%) |

Tính: cơ sở = 80 / 0,99 = 80,81. 9.600 / 99,99 = 96,01; 96,01 / 80,81 = 1,188. Mốc 9.800 cũ: 9.800 / 99,99 = 98,01; 98,01 / 80,81 = 1,213, vượt 20%.

- **Một lần mua đầu duy nhất** (Starter 0,99). Không nhân đôi lần đầu ở mọi mốc (kiểu Genshin) vì nhân đôi 99,99 lần đầu = 19.200 Gem, kéo Gem/USD của whale lần đầu lên 192 và làm méo mọi so sánh giá.
- **Phần dư (tail):** mọi sản phẩm đều chọn để còn dư vừa đủ một Aid: Pass 880 ở gói 9,99 dư 0; vé bundle 100 = 1.700 ở gói 19,99 dư 100; bundle 40 = 720 ở gói 9,99 dư 160; bundle 15 = 285 ở gói 4,99 dư 135. Dư 100–160 Gem = một Continue thường hoặc vài Aid nhỏ: đây là cách ngành giữ người chơi nạp lại, và nó khớp cách Aid được bán trong run.
- **Gem không hết hạn.** Số dư Gem là nợ của studio nên theo dõi (§9.8 telemetry: tồn kho Gem trung vị ≤ 2 tuần chi tiêu, cờ đỏ > 8 tuần).

### 9.2 Aid: giá, trần, gắn với ΔP

**Cách định giá.** Ba bước. (1) Đặt **ngân sách ΔP** cho từng Aid ở regular A6 (ΔP = mức tăng win rate, điểm %), sao cho cả bộ nằm trong E6 và dưới trần MON-11 (§9.4). Đây là **ngân sách đặt ra**, không phải đo: sim phải chứng minh mỗi Aid không vượt ngân sách của nó. (2) Giá = ΔP × một mức Gem/điểm trong dải 8–24, Continue tính theo "Gem mỗi lần thắng thêm". (3) Kiểm MON-1 (§9.5).

| ID | Aid | Giá Gem | USD (90/USD) | Trần | ΔP mỗi lần dùng (điểm %, regular A6) | Gem mỗi điểm % mỗi run | Ghi chú |
|---|---|---|---|---|---|---|---|
| R1 | Continue (B, hồi 40%) | 60 thường / 120 boss | 0,67 / 1,33 | 1/run | cứu ~0,5 lần thắng/lần mua (người mua chọn lúc) | 120 / 240 Gem mỗi lần thắng thêm | VIP −25% = 45 / 90. Miễn phí 1 lần/tài khoản A0–A2 |
| R2 | Reroll thêm | 10 (gói 3 = 25) | 0,11 | 4/run, 2/trận | 1,25 (5,0 cho 4 lần) | 8,0 | giảm từ 15; 4 lần = 40 Gem |
| R3 | Reroll thẻ | 8 | 0,09 | 2/run | 0,5 (1,0 cho 2 lần) | 16 | tắt ở A10 |
| R4 | Hoãn đồng hồ boss | 40 | 0,44 | 1/boss | 3,0 | 13,3 | Aid "cứu boss" mạnh nhất sau Continue |
| R5 | Đổi pact | 10 | 0,11 | 1/pact | 1,0 | 10 | chỉ A6+ |
| R6 | Coupon shop −20% | 6 | 0,07 | 2/run | 0,25 + tiết kiệm Shard (§9.5) | 24 | giá hạ từ 8; xem rủi ro rò Shard §9.9 |
| R7 | Scout | 8 | 0,09 | 3/run | 0,5 (1,5 cho 3 lần) | 16 | |
| R8 | Boon đầu run | 25 | 0,28 | 1/run | 1,5 | 16,7 | |
| R9 | Run Kit (R2×2 + R7 + R8) | **40** | 0,44 | 1/run | 4,5 (2,5 + 0,5 + 1,5) | 8,9 | tổng lẻ 2×10 + 8 + 25 = 53; 40/53 = 75,5% đúng quy tắc 75% (gợi ý 55 trên tổng lẻ cũ 65 chỉ giảm 15%). Kit không tính vào trần 8 |
| R10 | Hồi khẩn | 12 | 0,13 | **2/run**, 1/trận | 1,0 (2,0 cho 2 lần) | 12 | hạ từ 20 và từ 3 lần |

Ngân sách ΔP của Continue R1 ở regular A6: 7,6 điểm (f₁ chọn lọc ≈ 0,10 trên L = 76% thua → 0,10 × 76 = 7,6). Cộng cả bộ trần 8 cho ΔP cộng thẳng 7,6 + 5,0 + 3,0 + 2,0 = 17,6; ΔP thực nhân dần (phần thua nhỏ lại) = 16,3 (F = 0,215, §9.4).

**Vì sao đổi so với gợi ý đầu.** R2 15 → 10: ở 15, bốn lần = 60 Gem cho +5 điểm = 12 Gem/điểm nhưng ở A0 regular (L = 40%, ΔP chỉ bằng 0,53 lần ở A6) thành ~23 Gem/điểm: quá đắt đúng chỗ cần chào sampling. R10 20 → 12 vì 1 điểm/lần mà 20 Gem là 20 Gem/điểm, gấp đôi mặt bằng. Tất cả Aid trả đúng **một giá phẳng** theo mọi Ascension (không giá động); hệ quả tự nhiên: ở A0–A3 Aid ít đáng hơn, ở A6+ đáng hơn, doanh thu Aid dồn vào người đang thật sự bị ức chế.

**Quy tắc giá Continue theo trận (không theo ví):** boss ×2 vì nó cứu một run đã đi gần hết (lần thua ở boss ≈ 45–55% số lần thua, cứu thành công cao hơn). Không có giá phụ thuộc số dư Gem, lịch sử mua hay chuỗi thua (MON-5).

**Trần.** Giữ E5 (tổng 8), đổi R10 3 → 2. **Trần 8 là cái đang giữ MON-11**: dùng mọi trần (≈ 16 lần) cho regular A6 thắng 48,8% so với heavy-không-Aid 50% (§9.4), biên chỉ 1,2 điểm; trần 8 cho biên 5,1 điểm. Ở **A10 trần tổng 4** (R1, R2×2, R4) vì lý do cùng chỗ.

### 9.3 Sản phẩm meta

| Sản phẩm | Giá | Nhận | Giới hạn / lý do |
|---|---|---|---|
| **T1 Vé bundle** | 6 vé = 120 · 15 = 285 · 40 = 720 · 100 = 1.700 Gem | vé thường, không tăng bậc giá k, không trần 20 lượt/ngày (Liam A11) | 20/19/18/17 Gem mỗi vé; giá vé Shard 200 → 825, nên bundle luôn rẻ hơn vé Shard từ vé thứ 2 trở đi trong ngày. Vé không đổi ra Shard (ECO-3) |
| **T2 Pass premium** | 880 Gem (9,99 USD) | thưởng: 20 vé + 3 Run Kit + 6 cosmetic độc quyền + 300 Gem hoàn (lv10/20/30, 100 mỗi mốc) | hoàn 300/880 = 34% (trong 30–40%). **Không Shard, không Stone** ở track premium (MON-2). Giá trị vật chất: 20 vé (400 Gem-eq) + 3 Kit (120) + 300 Gem = 820 Gem-eq + cosmetic. Hoàn thành: casual 6,0 tuần, regular 4,7 tuần, heavy 14,7 ngày trên 8 tuần mùa (`economy-v2` §10), nên cả ba nhận đủ 300 Gem hoàn |
| **T2b Nhảy cấp** | **không bán ở v1** | | BREAK-2 §9.9: các cấp bị nhảy mang Shard + Stone của track free, Gem thành đường mua Shard/Stone. Nếu vẫn muốn bán, cấp nhảy chỉ nhận phần cosmetic/vé |
| **T3 Moon Card** | 4,99 USD / 420 Gem, 30 ngày | 20 Gem/ngày (nhận chủ động) + 1 vé/ngày + 1 Boon (lần chơi đầu ngày) + Continue giá −25% (1/run) | giá trị: 600 Gem + 30 vé (600 Gem-eq) + 30 Boon (750 Gem-eq) = 1.950 Gem-eq, gấp 4,6 lần giá thẻ (420). Đổi từ bản gốc: không còn Continue 2/run và Boon mỗi run (heavy chơi 56 run/tuần: Boon mỗi run = 25 × 242 = 6.050 Gem-eq/tháng, rút hết doanh thu R8) |
| **T4 Starter** | 0,99 USD | 160 Gem + 3 vé + 1 Boon = 160 + 60 + 25 = 245 Gem-eq | 2,7 lần giá trị thường (80 Gem); một lần/tài khoản, sau run thứ 3 |
| **T5 Cosmetic trực tiếp** | Rare 150 · Epic 400 · Legendary 900 · Mythic 1.800 Gem (dice, khung rẻ hơn một bậc) | cosmetic cố định | 1,7 / 4,4 / 10 / 20 USD. Bộ 3 món −15% |
| **T6 Bộ mùa mua thẳng** | Epic 200 · Legendary 450 · Mythic 900 Gem mỗi món; cả bộ S1 (6 Epic + 3 Legendary + 2 Mythic) = 1.200 + 1.350 + 1.800 = 4.350, giảm 15% = **3.700 Gem** (≈ 41 USD) | cosmetic, **không Stone** | so với chơi hộp: điển hình 55 lượt = 271,5 vé ròng × 20 = 5.430 Gem, nhưng đồng thời nhận ~55 × 1.006 = 55.300 Stone (~189 vé Land ≈ 3.200 Gem-eq ở giá bundle 17). Mua thẳng rẻ hơn chơi hộp về cosmetic, không cho Stone, nên không phá pity. Món mốc 40 lượt không bán (giữ ý nghĩa gacha). Gợi ý gốc "85% trần 80 lượt" = 0,85 × 400 vé × 20 = 6.800 Gem, đắt hơn điển hình 5.430 nên không ai mua thẳng và mất lá chắn pháp lý |
| **T7 Land Stone** | không bán | | giữ như gốc |

**Chặn đường Gem → Shard/Stone qua Pass và nhảy cấp:** xem BREAK-2. Free track của Pass vẫn trả Shard 4.800 + Stone 16.500/mùa, không đổi.

### 9.4 Độ khó mục tiêu (hạ theo Liam), mức nâng của Aid, MON-11

**Đầu vào mới của Liam:** Continue **kiểu B, hồi 40%, clock về 0** (khóa, không còn là biến để sửa); Boss Clock nhẹ ở A0; spike từ A3, attrition nhẹ từ A0; và "game phải THẬT KHÓ". Tôi áp dụng bằng cách hạ bảng mục tiêu, **giữ sàn MON-11** (casual A0 ≥ 35%) và giữ khoảng cách heavy − regular ở A6 (= 26 điểm), vì khoảng cách đó chính là ngân sách cho mức nâng của Aid.

**Bảng mục tiêu non-payer (không Aid), đề xuất hạ (E6):**

| Ascension | Casual | Regular | Heavy | Gốc §1.4 (casual/regular/heavy) |
|---|---|---|---|---|
| A0 | **37%** | 60% | 82% | 40 / 65 / 85 |
| A3 | 22% | 44% | 70% | 25 / 50 / 75 |
| A6 | 8% | 24% | 50% | 12 / 32 / 58 |
| A10 | 2% | 8% | 28% | 3 / 12 / 35 |

A0 casual chỉ hạ 3 điểm vì sàn 35% (biên 2 điểm). **Hệ quả cho telemetry:** ngưỡng cảnh báo ±8 của §7.3 sẽ cho phép casual A0 trôi xuống 29% mà không báo; đổi cảnh báo riêng cho ô này thành **< 36% là cờ đỏ**.

**Mô hình mức nâng.** Win rate có Aid = 1 − L × Π(1 − fᵢ), L = tỉ lệ thua. fᵢ = phần lần thua mà Aid i cứu được, ở regular A6 (L = 76%): R1 chọn lọc 0,10 (= 7,6/76), R2 ×4 0,066 (5,0/76), R4 0,039 (3,0/76), R10 ×2 0,026 (2,0/76), R3 0,013, R5 0,013, R6 0,007, R7 0,020, R8 0,020. **Bộ trần 8 điển hình** (R1 + R2×4 + R4 + R10×2): Π = 0,90 × 0,934 × 0,961 × 0,974 = 0,787 → F = 0,213. Hệ số kỹ năng dùng Aid u: casual 0,8, regular 1,0, heavy 1,1 (giả định). Mức nâng = L × F × u.

| Mức nâng điển hình (người mua chọn lúc, điểm %) | Casual | Regular | Heavy |
|---|---|---|---|
| A0 (L = 63 / 40 / 18) | +10,7 | +8,5 | +4,2 |
| A3 (L = 78 / 56 / 30) | +13,3 | +11,9 | +7,0 |
| A6 (L = 92 / 76 / 50) | +15,6 | +16,2 | +11,7 |
| A10, trần 4 (F = 0,164) | +12,8 | +15,1 | +13,0 |

Ví dụ: regular A6 = 0,76 × 0,213 = 0,162; casual A0 = 0,63 × 0,213 × 0,8 = 0,107. A10 cap-4: Π = 0,90 × 0,967 × 0,961 = 0,836, F = 0,164; regular 0,92 × 0,164 = 0,151.

**So E6 (+8–15 ở A0–A3, +12–20 ở A6–A10):** đạt hết, trừ heavy A0/A3 (+4,2 / +7,0): heavy đã ở 82% / 70%, trần vật lý, không cần chữa. Heavy A6 +11,7 sát 12, chấp nhận.

**MON-11 (trần worst case: người mua Continue ở MỌI lần thua, f₁ toàn bộ):**

| Kịch bản regular A6 (nền 24%, trần heavy-không-Aid 50%) | f₁ | Bộ Aid | Win | Biên so với 50% | Kết quả |
|---|---|---|---|---|---|
| Ước tính ngây thơ với B-40% (BREAK-1) | 0,37 | trần 8 | 58,1% | −8,1 | **VỠ** |
| Mục tiêu sau khi chỉnh boss | **0,17** | trần 8 | 44,9% | +5,1 | đạt (cần ≥ 3) |
| Ngưỡng f₁ để biên đúng 3 điểm | 0,20 | trần 8 | 47,0% | +3,0 | giới hạn |
| Không có trần 8 (~16 lần) | 0,17 | tất cả | 48,8% | +1,2 | **trần 8 là bắt buộc** |
| VIP Continue 2/run (gốc) | 0,17 + 0,08 | R1×2, R2×4, R4, R10 | 48,6% | +1,4 | **VỠ biên** → bỏ (E5) |

Tính: mục tiêu f₁ = 0,17: Π = 0,83 × 0,934 × 0,961 × 0,974 = 0,7256; F = 0,274; ΔP = 0,76 × 0,274 = 20,9; 24 + 20,9 = 44,9. Ngây thơ: f₁ = 0,37 từ phân bố HP boss còn lại lúc chết (25% lần thua còn ≤ 15% HP cứu 75%; 30% ở 15–30% cứu 55%; 25% ở 30–50% cứu 30%; 20% còn > 50% cứu 8% → trung bình 0,44; nhân 50% số lần thua ở boss ≈ 0,22; cộng elite/mid/early 0,15 → f₁ ≈ 0,37), Π = 0,63 × 0,874 = 0,551, F = 0,449, ΔP = 34,1, tổng 58,1. Người mua chọn lúc (chỉ mua khi boss còn ≤ 50% HP) thắng 53% mỗi lần mua, thỏa E7 ≥ 50%, nhưng tổng khối lượng cứu vẫn quá lớn: **hai mục tiêu E7 và MON-11 chỉ cùng thỏa khi sau Continue boss giết đội nhanh hơn mô hình ngây thơ**, tức là chỉnh đường dốc dmg phase 3 và spike sau khi hồi, không phải chỉnh số HP hồi (đã khóa 40%).

**A10 (MON-11 mở rộng, tôi thêm):** regular 8% + nâng tối đa. Cần trần tổng 4 và f₁ ≤ 0,10: Π = 0,90 × 0,967 × 0,961 = 0,836; F = 0,164; 0,92 × 0,164 = 15,1; 8 + 15,1 = 23,1% ≤ heavy 28% (biên 4,9). Với trần 8 và f₁ = 0,17 thì 8 + 0,92 × 0,274 × 100 = 33,2% > 28%: **vỡ**, nên trần A10 = 4 là cần.

**Phân bố nơi thua (E7):** giữ §1.3 (boss 45–55%). Boss HP còn lại trung vị lúc thua 15–30%. Telemetry như §7.3.

### 9.5 MON-1 bằng số (E14)

**Công thức (MON-1):** `giá_Gem × 10 ≥ 1,5 × ΔP × (Shard_thắng − Shard_thua)`. Shard_thắng − Shard_thua = **311** (short: 569 − 258) hoặc cận trên **600** (full: ~854 − 258 chưa đo, giả định; dùng 600 cho an toàn). ΔP = xác suất thắng thêm **mỗi lần dùng**. Tôi dùng cột 600 để kiểm; cột 311 để so.

| Aid | Giá × 10 (Shard-eq) | ΔP mỗi lần | ΔEV (ΔP × 600) | 1,5 × ΔEV cần | Giá×10 / ΔEV (≥ 1,5) | Cùng tỉ lệ với 311 |
|---|---|---|---|---|---|---|
| R1 thường | 600 | 0,50 | 300 | 450 | **2,0** | 3,9 |
| R1 boss | 1.200 | 0,50 | 300 | 450 | 4,0 | 7,7 |
| R2 | 100 | 0,0125 | 7,5 | 11 | 13,3 | 25,7 |
| R3 | 80 | 0,005 | 3,0 | 4,5 | 26,7 | 51 |
| R4 | 400 | 0,030 | 18 | 27 | 22,2 | 43 |
| R5 | 100 | 0,010 | 6,0 | 9 | 16,7 | 32 |
| R6 | 60 | 0,0025 + giảm giá ~30 Shard | 1,5 + 30 = 31,5 | 47 | **1,9** | 1,95 |
| R7 | 80 | 0,005 | 3,0 | 4,5 | 26,7 | 51 |
| R8 | 250 | 0,015 | 9,0 | 13,5 | 27,8 | 53 |
| R9 Kit | 400 | 0,045 | 27 | 40 | 14,8 | 29 |
| R10 | 120 | 0,010 | 6,0 | 9 | 20,0 | 39 |

Tính ví dụ: R2 = 10 Gem × 10 = 100 Shard-eq; ΔEV = 0,0125 × 600 = 7,5; 1,5 × 7,5 = 11,25 ≤ 100 nên đạt; tỉ lệ 100 / 7,5 = 13,3. R1 thường: 60 × 10 = 600; ΔEV = 0,5 × 600 = 300; 600/300 = 2,0 ≥ 1,5 đạt.

**Hai chỗ sát:** R1 thường (2,0) và R6 (1,9).
- R1 thường: đạt chừng nào người mua thắng sau Continue ở trận thường **≤ 0,66** (600 / (600 × 0,66) = 1,5). Nếu sim thấy cao hơn, nâng giá thường lên 80 (tỉ lệ 2,67 ở 0,5; 2,0 ở 0,66 trở lên).
- R6 là Aid **duy nhất có kênh Shard trực tiếp** (giảm giá shop trong run, mà `economy-v2` A1 cho biết R = 450 đã trừ shop). Giả định mỗi lần ghé shop tiêu ≤ 150 Shard nên −20% tiết kiệm 30 Shard (**chưa verify** giá shop). Nếu shop đắt hơn, nâng giá R6 hoặc đổi coupon thành "tiền trong run" không phải Shard.

**Toàn bộ bộ trần 8** (R1 boss + R2×4 + R4 + R10×2 = 120 + 40 + 40 + 24 = 224 Gem = 2.240 Shard-eq): ΔP regular A6 = 0,209; × 600 = 125 Shard. Tỉ lệ 2.240 / 125 = 17,9 lần.

**Rò Shard thực của người nạp (quy mô):** heavy A6 dùng tối đa bộ điển hình: +11,7 điểm × 311 = 36 Shard/run (8,1% của R = 450); 56 run/tuần = 2.040 Shard/tuần (7,7% của 26.653). Chi phí ≈ 105 Gem/run (kỳ vọng chi tiêu bộ trần 8 khi mua chọn lúc) × 56 = 5.880 Gem/tuần. Hiệu suất 2.040 / 5.880 = 0,35 Shard mỗi Gem = **3,5%** của tham chiếu 10 Shard/Gem. Nên rò chỉ ở mức vài %, không ai nạp để "cày Shard".

### 9.6 Persona chi tiêu × persona chơi

Số run/tháng (A2 của `economy-v2`, × 4,33 tuần): casual 12 × 4,33 = **52**, regular 14 × 4,33 = **61**, heavy 56 × 4,33 = **242**.

**Persona chi tiêu (Gem mỗi tháng):**

| | Minnow (~5,5 USD) | Dolphin (~30 USD) | Whale (~250 USD) |
|---|---|---|---|
| Mua | Moon Card 4,99 + ~0,5 | Card 4,99 + Gem 19,99 + Gem 4,99 + Pass 9,99 mỗi 2 tháng | Card + Gem 99,99 ×2 + 19,99 ×2 + Pass |
| Gem vào | 600 (Card) + 40 = 640 | 600 + 1.800 + 420 = 2.820 | 600 + 2 × 9.600 + 2 × 1.800 = 23.400 |
| Sink: Aid | 500 | 1.500 | 6.050 |
| Sink: vé bundle | 0 | 2 × 285 = 570 | 433 vé × 17 = 7.361 |
| Sink: Pass | 0 | 440 (880 / 2) | 440 |
| Sink: cosmetic | 140 | 310 | 9.549 |
| Vé thêm mỗi tuần | +6,9 (Card) | +6,9 + 2,5 (Pass 20 vé / 8 tuần) + 6,9 (30 vé bundle / 4,33) = +16,3 | +6,9 + 2,5 + 100 = +109,4 (bundle 100 vé mỗi tuần) |

**Aid dùng mỗi run và mức nâng ở A6** (mua Continue trước, 0,45 trận thắng thêm mỗi lần mua chọn lúc; Continue trung bình 90 Gem; phần dư vào R4/R2; xấp xỉ, sim xác nhận):

| Spender × chơi | Aid Gem/tháng | Số Continue mua | Trận thắng thêm | Nâng (điểm %) | Win A6 (nền → có Aid) | Aid/run |
|---|---|---|---|---|---|---|
| Non-payer (mọi loại) | 0 (trừ 1 Continue mẫu một lần + Boon sau 3 thua) | 0 | 0 | 0 | 8 / 24 / 50 | 0 |
| Minnow × casual (52) | 500 | 500/90 = 5,6 | 5,6 × 0,45 = 2,5 | +4,8 | 8 → 12,8 | 0,11 |
| Minnow × regular (61) | 500 | 5,6 | 2,5 | +4,1 | 24 → 28,1 | 0,09 |
| Dolphin × regular (61) | 1.500 | 14 (1.260 Gem) | 6,3 + 0,5 (R4/R2 từ 240 Gem) = 6,8 | +11,1 | 24 → 35,1 | 0,7 |
| Dolphin × heavy (242) | 1.500 | 14 | 6,8 | +2,8 | 50 → 52,8 | 0,2 |
| Whale × regular (61) | 6.050 | ~50 | chạm trần bộ ≈ 15,3 | +15,3 (trần điển hình 16,2) | 24 → 39,3 | ~1,0 |
| Whale × heavy (242) | 6.050 | 44 (4.000 Gem) + R4/R2/R10 | 44 × 0,45 = 19,8 + 2,2 = 22,0 | +9,1 (trần 11,7) | 50 → 59,1 | 0,8 |
| Whale × casual (52) | 6.050 (chỉ cần ~5.460) | ~50 | chạm trần | +15,6 | 8 → 23,6 | ~1,0 |

Ví dụ: dolphin × regular: 14 × 0,45 = 6,3 trận; 6,8 / 61 = 11,1 điểm. Win có Aid dolphin × heavy 50 + 2,8 = 52,8.

**Kiểm MON-11 theo persona:** regular có Aid tốt nhất (whale, 39,3%) < trần worst-case 44,9% < heavy-không-Aid 50%: **đạt, biên 10,7 điểm** với persona mua chọn lúc (biên 5,1 với mua mọi lần, §9.4). Casual A0 không Aid 37% ≥ 35%: đạt theo mục tiêu, sim phải xác nhận.

**Nhận xét:** whale chơi regular chỉ nhích +15 điểm dù chi 6.050 Gem/tháng cho Aid: Aid là gia vị, không mua được chiến thắng. Phần chi lớn của whale nằm ở cosmetic (41%) và vé (31%), không ở Aid (26%). Aid dùng mỗi run ≤ 1, xa trần 8.

**Echo Box, Pass, Land (R = 450, nửa bộ, `economy-v2`):**

| | Vé/tuần casual / regular / heavy | Pass xong (free track; premium cùng nhịp) | Tuần tới LunaLanding casual / regular / heavy |
|---|---|---|---|
| Non-payer | 29,2 / 35,7 / 97,5 | 6,0 tuần / 4,7 tuần / 14,7 ngày | 136,2 / 108,8 / 52,3 |
| Minnow (+6,9) | 36,1 / 42,6 / 104,4 | như trên | 118,3 / 97,1 / 49,4 |
| Dolphin (+16,3) | 45,5 / 52,0 / 113,8 | như trên | 100,3 / 84,6 / 46,0 |
| Whale (+109,4) | 138,6 / 145,1 / 206,9 | như trên | **40,1 / 37,3 / 27,2** |

Pull: hộp thường 1 vé/lượt, hộp mùa 5 vé/lượt. Ví dụ whale casual: 138,6 vé/tuần ≈ 138 lượt thường hoặc 28 lượt mùa mỗi tuần. Pass premium **không đổi tốc độ XP** nên không ai xong Pass nhanh hơn sàn 14 ngày (ECO-9). Tính Land ở §9.7.

### 9.7 Land và vé bundle

Vé bundle là **đường chi tiền → Land duy nhất** (Gem không mua Stone; vé thưởng từ Card/Pass/Starter đi cùng đường). Theo `economy-v2` A11/§9: Stone/tuần = S₀ + 293 × (vé bundle/tuần), với 293 = 242,5 × dP/dT ≈ 1,2. Kiểm: heavy S₀ = 1.820.000 / 52,3 = 34.800; +50 vé/tuần cho 36,8 tuần → 49.457; chênh 14.657 / 50 = 293 Stone/vé; +100 vé: 1.820.000 / 28,4 = 64.085; chênh 29.285 / 100 = 293. Cũng đúng với casual và regular. S₀: casual 13.363, regular 16.728, heavy 34.800.

**Giá mua thẳng từng bậc Land bằng vé (bundle 100 = 17 Gem/vé, 90 Gem/USD, bỏ qua Stone miễn phí):**

| Bậc | Stone cần | Vé (÷ 293) | Gem (× 17) | USD |
|---|---|---|---|---|
| Savannah → Forest | 40.000 | 136,5 | 2.321 | 25,8 |
| → Arctic | 100.000 | 341,3 | 5.802 | 64,5 |
| → Mystic | 180.000 | 614,3 | 10.443 | 116,0 |
| → Genesis | 500.000 | 1.706,5 | 29.010 | 322,3 |
| → LunaLanding | 1.000.000 | 3.412,9 | 58.019 | 644,7 |
| **Tổng** | 1.820.000 | 6.211,6 | 105.597 | **1.173** |

Bậc đầu thực tế đắt hơn ~10%, vì hai trăm vé đầu mới cho ~261 Stone/vé (dP/dT = 1,078). Con số 1.173 USD là trần của người **chỉ mua vé**; ai chơi và có Stone miễn phí (Pass, thưởng ngày, hộp từ Shard) cần ít hơn nhiều.

**Sàn "người nạp nhiều nhất tới LunaLanding ≥ 6 tháng" (§5.2 của game-designer, 26 tuần):**
- Heavy giữ 26 tuần khi 34.800 + 293 × x ≤ 1.820.000 / 26 = 70.000 → x ≤ **120 vé bundle/tuần** (= 2.040 Gem = 22,7 USD/tuần ≈ **98 USD/tháng** chi cho vé).
- Whale mẫu (+109,4 vé/tuần gồm Card, Pass, bundle 100): heavy **27,2 tuần**: sát nhưng ≥ 26. Casual-chơi whale 40,1 tuần, nhanh hơn heavy-không-nạp (52,3).
- Whale **dồn hết 250 USD vào vé**: Gem 23.400 / 17 = 1.376 vé/tháng = 318/tuần; heavy: 34.800 + 293 × 318 = 127.974 Stone/tuần → 1.820.000 / 127.974 = **14,2 tuần** (3,3 tháng, tổng chi ≈ 3,3 × 250 = 820 USD). **Vỡ sàn 26 tuần** (BREAK-3, §9.9).
- Liam đã chấp nhận (`economy-v2` quyết định 4) người nạp lên Land nhanh gấp ~2; thực tế 1,9–3,4 lần. Sàn 26 tuần là khuyến nghị của game-designer, không phải luật của Liam.

### 9.8 Doanh thu mỗi 1k DAU

**Giả định (tất cả là giả định, không có benchmark ngoài đã verify):** DAU/MAU = 25% → 1k DAU = 4.000 MAU. Tỉ lệ người trả tiền trong tháng = 3% MAU = **120 payer**. Chia: minnow 66% (79), dolphin 28% (34), whale 6% (7). Chi mỗi tháng: minnow 5,5 USD, dolphin 29,97 (Card 4,99 + gói Gem 19,99 + 4,99), whale 244,95 (Card + 2 × 99,99 + 2 × 19,99).

| Persona | Số người | USD/người | Doanh thu |
|---|---|---|---|
| Minnow | 79 | 5,50 | 79 × 5,5 = 434,5 |
| Dolphin | 34 | 29,97 | 34 × 29,97 = 1.019,0 |
| Whale | 7 | 244,95 | 7 × 244,95 = 1.714,7 |
| **Tổng / 1k DAU / tháng** | 120 | ARPPU 26,4 | **3.168** (ARPDAU 0,106) |

Sau phí nền tảng 30% (chưa verify): 3.168 × 0,7 = **2.218**. Một năm: 38.016 gộp, 26.611 ròng mỗi 1k DAU. Whale chiếm 1.714,7 / 3.168 = **54%** doanh thu (cờ cảnh báo §7.3 là top 1% > 50%: đang chạm; ở quy mô 1k DAU, 7 người ≈ 0,18% MAU).

**Doanh thu theo SKU (tiền thật):** Moon Card 120 × 4,99 = 599 (19%); gói Gem 2.569 (81%). Pass, vé, Aid và cosmetic **trả bằng Gem**, nên chia theo nơi Gem được tiêu (tổng 310.240 Gem/tháng):

| Sink Gem / 1k DAU / tháng | Gem | % |
|---|---|---|
| Aid | 39.500 + 51.000 + 42.350 = 132.850 | 42,8% |
| Cosmetic (T5/T6) | 11.060 + 10.540 + 66.843 = 88.443 | 28,5% |
| Vé bundle | 19.380 + 51.527 = 70.907 | 22,9% |
| Pass premium | 14.960 + 3.080 = 18.040 | 5,8% |

Continue chiếm giả định 55% Aid = 73.068 Gem ÷ 90 trung bình = **~812 lần mua/tháng** (6,8 mỗi payer). Cosmetic phụ thuộc whale (66.843 / 88.443 = 76%): nguồn cosmetic phải đủ sâu (OQ-16, §9.10).

**Độ nhạy (gộp/tháng/1k DAU, gốc 3.168):**

| Biến | Giá trị | Doanh thu | So gốc |
|---|---|---|---|
| Tỉ lệ payer | 1,5% / 5% | 1.584 / 5.280 | −50% / +67% |
| Whale ARPPU | 150 / 350 USD | 2.504 / 3.904 | −21% / +23% |
| Không có whale | 0 | 1.454 | −54% (rủi ro tập trung) |
| DAU/MAU | 40% / 15% | 1.980 / 5.280 | −38% / +67% (payer tính theo MAU) |
| Cầu Aid | −50% / +50% | ≈ 2.720 / 3.616 | ∓14% (dolphin/whale bớt/thêm nạp theo phần Aid trong chi Gem: 53% và 26%) |

Ví dụ Aid: dolphin 850 USD gói × 53% × 50% = 225; whale 1.715 × 26% × 50% = 223; tổng 448 = 14,1% của 3.168. Hướng "game thật khó" (Liam) nghiêng về cầu Aid cao hơn, nhưng đó cũng là rủi ro niềm tin (§6.1): không dùng làm cơ sở cho kế hoạch doanh thu.

**Telemetry thêm cho Gem:** tồn kho Gem trung vị ≤ 2 tuần chi tiêu, cờ đỏ p90 > 8 tuần (Gem không hết hạn là nợ); tỉ lệ Gem chi vào Aid / cosmetic / vé; số Continue mua trên 1k run thua; giá trị Shard thực của run (E14) so với 311 / 600.

### 9.9 Kiểm MON-1..MON-12, chỗ vỡ và cách sửa

| MON | Kiểm bằng số | Kết quả |
|---|---|---|
| MON-1 | Tỉ lệ giá×10 / ΔEV từ 1,9 (R6) đến 27,8; R1 thường 2,0; yêu cầu ≥ 1,5 (§9.5) | **Đạt**, sát ở R6 và R1 thường |
| MON-2 | Không Aid nào trả Shard; track Pass premium không Shard/Stone; T2b bị bỏ; R6 là giảm giá (~30 Shard/lần) | **Vỡ nếu giữ T2b** (BREAK-2); R6 rò nhỏ |
| MON-3 | Trần 8; thực tế người mua nhiều nhất ≈ 1 Aid/run (§9.6); A10 trần 4 | Đạt |
| MON-4 | Không số; Aid ngoài pool relic | Đạt (thiết kế) |
| MON-5 | Giá phẳng, theo loại trận (boss ×2) không theo ví; Boon miễn phí theo chuỗi thua, không đổi độ khó | Đạt |
| MON-6 | Không số | Đạt (thiết kế) |
| MON-7 | Bảng giá/trần §9.2–9.3 công khai | Đạt khi UI hiện |
| MON-8 | Gem không đổi Shard/Stone; chargeback âm Gem; vé bundle không ra Shard | Đạt; trừ BREAK-2 |
| MON-9 | T5/T6 chỉ cosmetic, không đụng `relic_pool` | Đạt |
| MON-10 | Chào đúng khoảnh khắc (§2.2) | Đạt (thiết kế) |
| MON-11 | casual A0 37% ≥ 35% (biên 2); regular+Aid A6 44,9% ≤ 50% (biên 5,1) **với f₁ ≤ 0,17**; ngây thơ 58,1% | **Vỡ ở mô hình ngây thơ** (BREAK-1); phụ thuộc sim |
| MON-12 | Không SKU/Aid nào chạm Nhiệm vụ; Shard từ Aid chỉ qua run thường, hiệu suất ≤ 3,5% (§9.5) | Đạt |

**BREAK-1: Continue B-40% vs MON-11 và E7.** Liam khóa B-40% nên không giảm HP hồi. Ước tính ngây thơ f₁ = 0,37 cho regular A6 58,1% > 50% (§9.4). Sửa (không đổi HP hồi): (a) chỉnh boss để sau Continue boss giết đội nhanh hơn: phase 3 có đường dốc dmg và spike không reset (clock về 0 đã khóa, nhưng bộ đếm spike và ngưỡng phase **không** reset); (b) sim phải đạt đồng thời f₁ toàn bộ ≤ 0,17 (A6) và ≤ 0,10 (A10) **và** người mua boss thắng ∈ [50%, 80%]. (c) Nếu sim không đạt (a)+(b), **cờ cho Liam**: hoặc Continue ở A6+ chỉ hồi 25% (trái OQ-A), hoặc nâng heavy A6 lên 58 (trái "thật khó"). Tôi không tự chọn.

**BREAK-2: T2b nhảy cấp và Pass premium là cửa sau Gem → Shard/Stone.** Cấp bị nhảy mang thưởng Shard 4.800 + Stone 16.500 của track free; ECO-9 (T_min ≥ 14 ngày) cũng gãy: nhảy 10 cấp (10.800 XP) còn (32.400 − 10.800) / 2.314 = 9,3 ngày. Sửa: không bán T2b ở v1; track premium không có Shard/Stone (đã đặt).

**BREAK-3: Land ≥ 26 tuần vs người dồn tiền vào vé.** 14,2 tuần ở 250 USD/tháng dồn vào vé; ngưỡng 26 tuần ứng với chi ≤ 98 USD/tháng cho vé (heavy). Không phải lỗi so với quyết định 4 của Liam; chỉ là khuyến nghị §5.2 bị phá. Lựa chọn ở §9.10 (OQ-15).

**BREAK-4: VIP 2 Continue/run và Boon mỗi run.** Continue ×2 cho biên MON-11 còn 1,4 điểm (< 3); Boon mỗi run cho heavy 6.050 Gem-eq/tháng (bằng cả chi Aid của whale). Sửa đã đặt trong E5/E9.

**BREAK-5: ba con số của gợi ý đầu không đúng.** Pass 900 Gem không mua được bằng một gói 9,99 (880), nên thành 880. T6 "85% trần" = 6.800 > điển hình 5.430 nên thành 3.700. Kit 55 trên tổng lẻ 65 chỉ giảm 15%; đổi thành 40.

**BREAK-6: A10.** Với trần 8 và f₁ = 0,17, regular A10 + Aid = 33,2% > heavy 28%. Sửa: trần 4 + f₁ ≤ 0,10 (23,1%, biên 4,9).

**BREAK-7: ngưỡng cảnh báo ±8 của §7.3 không bảo vệ sàn 35%.** Sửa: casual A0 < 36% là cờ đỏ.

**Chưa verify (sim/code phải kiểm):** giá shop trong run (R6); Shard thua ở chế độ full; phân bố HP boss còn lại khi thua (cơ sở của f₁); hệ số u của persona; mọi f.

### 9.10 Câu hỏi cho Liam, trả lời OQ-D

**Trả lời OQ-D (Aid cap 8/run, giữ R10?) từ phía economy:**
- **Cap 8: giữ, và nó là bắt buộc.** Không có trần, regular A6 dùng mọi Aid (~16 lần) đạt 48,8%, biên chỉ 1,2 điểm so với heavy-không-Aid 50%; trần 8 cho 44,9% (biên 5,1). A10 cần trần 4 (§9.4). Người mua thật dùng ≤ 1 Aid/run nên trần 8 gần như không cắt doanh thu.
- **R10: không phải bắt buộc, khuyến nghị để v1.1.** ΔP 1,0 điểm/lần, tối đa 2,0 trong 17,6 của bộ trần 8 (11%); doanh thu ước ≈ 1% doanh thu Aid; chồng với việc đội đã hồi đầy HP mỗi trận. Bỏ R10 không làm vỡ MON nào (F điển hình 0,213 → 0,192). Lý do giữ: spike từ A3 (OQ-E của Liam) và R10 là đáp án trực tiếp cho spike. Nếu giữ: trần 2/run, 1/trận, giá 12 Gem. Quyết định của Liam theo chi phí làm UI.

**Câu hỏi mở, mỗi câu kèm khuyến nghị (cần Liam trả lời):**

| # | Câu hỏi | Khuyến nghị |
|---|---|---|
| OQ-15 | Land: người dồn tiền vào vé tới LunaLanding sau 14,2 tuần (250 USD/tháng) và mua thẳng cả đường ≈ 1.173 USD. Chấp nhận? Hay hạ chiết khấu bundle 100 từ 15% xuống 10% (18 Gem/vé, Land ≈ 1.242 USD), hay thêm trần vé bundle/tuần (Liam đã không muốn "hàng rào")? | Chấp nhận như quyết định 4, giữ 15%, theo dõi "% người chơi đạt LunaLanding trong 6 tháng". Trần tuần chỉ khi có số thực |
| OQ-16 | Cosmetic whale chi 9.549 Gem/tháng ≈ 24 món Epic: kho 223 món đủ ~9 tháng. Cần lịch nội dung hay hạn chế bán? | Có lịch nội dung (cosmetic mới mỗi mùa) trước khi mở store; nếu không, whale tích Gem và doanh thu cosmetic tụt |
| OQ-17 | Có tặng một ít Gem miễn phí cho non-payer (vd 120 Gem/mùa ở Pass free = một Continue boss)? Hiện non-payer không thể dùng Aid sau mẫu miễn phí | Có, 120 Gem/mùa: cộng ≈ +0,5 điểm win (1 Continue / 96 run mỗi mùa casual), vô hại với MON-11, giữ họ trong phễu. Quyết định sáng tạo của Liam |
| OQ-18 | Chấp nhận bảng win rate hạ (§9.4) làm mốc sim? | Chấp nhận; giữ khoảng cách heavy − regular ở A6 ≥ 26 |
| OQ-19 | BREAK-1(c) nếu sim không đạt f₁: chọn giữa Continue 25% ở A6+ hoặc nâng heavy A6? | Chờ sim; ưu tiên chỉnh boss trước |
| OQ-20 | Bỏ T2b nhảy cấp ở v1? | Bỏ (BREAK-2) |
| OQ-21 | VIP: Continue 1/run −25% và Boon 1/ngày thay cho 2/run và mỗi run? | Đồng ý (BREAK-4) |
| OQ-22 | T6 3.700 Gem (≈ 41 USD) cho bộ S1, món mốc 40 lượt không bán | Đồng ý |
| OQ-23 | Free Continue mẫu: 1 lần/tài khoản ở A0–A2 | Giữ |

**Cần sim xác nhận trước khi chốt giá (cổng chấp nhận):** (1) bảng win rate §9.4 trong ±3 điểm; (2) f₁ toàn bộ ≤ 0,17 ở regular A6, ≤ 0,10 ở A10, và người mua Continue ở boss thắng 50–80%; (3) casual A0 ≥ 35% (cờ đỏ < 36%); (4) từng Aid không vượt ngân sách ΔP ở §9.2; (5) r của người mua Continue ở trận thường ≤ 0,66; (6) Shard thua ở chế độ full (thay giả định 600).

## 10. Bước kế tiếp

1. Liam duyệt §1 (in-run friction), §2 (Aid), §8 (câu hỏi mới OQ-A..E).
2. ~~economy-designer đặt số~~ xong 11/10 (§9); cần sim xác nhận các con số đánh dấu "sim".
3. Systems/combat: nhận hand-off §1.5 (TUNE, phase boss, spike, attrition) và chạy sim bảng §1.4.
4. ux-designer: mockup bộ đếm spike/phase/attrition và màn recap trước khi bật công cụ nào.
5. Kiến trúc server tung dice phải chứa `AID_USE`, `CONTINUE` và bump `RULES_VERSION`.
6. Senior reviewer audit.

Chưa làm gì ngoài file này. Chưa commit.
