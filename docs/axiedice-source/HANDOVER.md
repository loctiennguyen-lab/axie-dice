# HANDOVER — Việc còn lại, xếp theo thứ tự nên làm

> **⚠️ Sửa 2026-09-01 — file này đã lỗi thời ở nhiều điểm, đọc trước khi dùng làm nguồn sự thật:**
> - **§3 Economy/Bloodline không còn "BỊ CHẶN 3-4 tuần"** như mô tả dưới đây. Toàn bộ 16 quyết định D1-D16 đã được duyệt (`design/gdd/economy-progression.md` §1.2), pipeline part→dice-face đã thiết kế xong (không dùng Origins card text nữa — xem `design/gdd/part-tier-system.md`), 192 part thật đã gán vào 36 template. Việc kỹ thuật còn lại: viết lại `gen_parts.py` theo phương pháp mới.
> - Cơ chế "Gọi mặt"/Declare/BLOODCHAIN nhắc tới gián tiếp qua BLOODLINE §4 **đã bị gác lại chính thức**, không nằm trong scope build — đã gỡ khỏi `docs/axiedice-source/guide/PLAYER_GAME_GUIDE_v1.md`.
> - `design/gdd/game-concept.md` đã được viết lại hoàn toàn, khớp code thật — dùng nó làm nguồn sự thật cho core loop/mechanic thay vì suy luận lại từ đầu.
> - Balance quái/boss đã được đo bằng `tools/sim.js` và chỉnh (`TUNE.growth2`/`eliteMult`, xem `docs/balance-log.md`) — Full Run winrate 3.6%→8.0%.
> - Có 2 hệ thống MỚI chưa tồn tại khi file này được viết: **Leaderboard** (`design/gdd/leaderboard-system.md`, `docs/architecture/adr-0001-leaderboard-backend-infrastructure.md` — dự án lần đầu cần backend) và **Milestone Ledger** (`design/quick-specs/milestone-ledger.md`, mở rộng Lunacia Pass).
> - Quyết định mới về NFT: người sở hữu ≥5 NFT Axie được chọn trước toàn bộ 5/5 đội hình, không bù trừ độ khó (`docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` §G8).
>
> §1 (nợ UI/UX) và §2 (nợ accessibility) dưới đây **vẫn còn nguyên giá trị** — chưa có gì trong số đó được làm ở đợt cập nhật 2026-09-01.

Đọc `CLAUDE.md` trước. File này chỉ nói **cái gì chưa xong** và **cái gì
đang bị chặn**.

---

## 0. Ba mươi giây tóm tắt

Game **chơi được từ đầu tới cuối** và UI đã qua một vòng đại tu (verify
29/30). Cái còn thiếu chia làm ba nhóm rất khác nhau về độ khó:

| Nhóm | Tình trạng | Ai làm được |
|---|---|---|
| §1 Nợ UI/UX (T14–T26 + Phase E) | thuần code, spec đã viết sẵn từng task | Claude Code làm được ngay |
| §2 Nợ accessibility (phần còn lại của T08) | thuần code, có rủi ro hồi quy | Claude Code làm được, cần chạy verify sau mỗi bước |
| §3 Economy / Bloodline (M0–M7) | **BỊ CHẶN — cần designer người** | Claude Code **không** làm được |

Đừng bắt đầu §3 trước khi đọc hết nó.

---

## 1. Nợ UI/UX — làm được ngay

Spec đầy đủ cho từng task nằm ở `docs/uiux/UIUX_IMPLEMENTATION_BRIEF_v1.md`.
Sau **mỗi** task: `python3 build.py && python3 tools/serve.py & && node
tools/verify.mjs` — verify phải giữ nguyên 29/30 hoặc tốt hơn.

**Ưu tiên cao — ảnh hưởng trực tiếp tới việc hiểu game:**

- **T26 — Hint bar 3 lượt.** Tutorial auto-open đã bị gỡ (nó nuốt click đầu
  tiên của mỗi run mới). Hint bar là thứ thay thế nó. Không có cái này,
  người chơi mới không có gì dẫn dắt. **Làm đầu tiên.**
- **T15 — Combat log.** Game là deterministic; không có log thì người chơi
  không kiểm chứng được vì sao mình chết. Đây là cơ chế xây dựng lòng tin,
  không phải tính năng phụ.
- **T23 — Trạng thái unit chết.** Hiện unit chết biến mất không nghi lễ.
- **T14 — Mục tiêu `noop`.** Cho phản hồi khi thả mặt vào chỗ vô nghĩa,
  thay vì im lặng.

**Ưu tiên vừa — dọn dẹp và nhất quán:**

- **T25** bottom bar phân cấp lại · **T16** chip có nhãn ở header ·
  **T22** info panel 2 cột · **T24** map 1 node · **T19** card team-select
  220×300 · **T17** `ABANDON RUN` màu cảnh báo + bổ sung Settings

**Ưu tiên thấp — cần nội dung mới:**

- **T21 — Collection.** Màn này chỉ có nghĩa **sau khi** §3 xong. Bộ sưu
  tập hiển thị danh tính part, mà danh tính part chính là thứ đang bị chặn.
  Làm sớm sẽ phải làm lại.
- **Toàn bộ Phase E** — chưa động tới.

---

## 2. Nợ accessibility — phần còn lại của T08

`A8a` (focus được) và `A8b` (focus ring) đang **PASS**, nhưng pass vì
`.btn` vốn đã là `<button>` thật. `.die` và `.unit` vẫn là `div` + `onclick`.

Hệ quả thật: **screen reader không đọc được xúc xắc và Axie, và Tab không
tới được chúng** — tức là toàn bộ nội dung cốt lõi của game không tiếp cận
được bằng bàn phím.

Còn phải làm (mục 2, 3, 4 của T08):

1. Đổi `.die` và `.unit` sang `<button>` semantic + `role`/`aria-label` mô
   tả mặt và trạng thái Axie
2. Thứ tự tab hợp lý (xúc xắc trái→phải, rồi mục tiêu)
3. Phím **Q–T** chọn mục tiêu

⚠️ Đây là chỗ dễ gây hồi quy nhất trong toàn bộ danh sách: `fx.js` gắn
pointer handler trực tiếp lên các phần tử đó, và bug AoE trước đây đã cho
thấy thay đổi vòng đời của phần tử `.die` giữa chừng sẽ làm mất click.
Chạy **cả** `soak.mjs` và `soakm.mjs` sau khi đổi, không chỉ một cái.

---

## 3. Economy / Bloodline — BỊ CHẶN, đọc kỹ

`docs/economy/BUILD_SPEC_v1.md` mô tả 8 mốc M0–M7. **Không có mốc nào bắt
đầu được**, vì M0 chặn.

### Chuyện gì đang xảy ra

`docs/economy/parts_build_data.json` có đủ 192 part, nhưng với **mỗi**
part:

- `role` = `null`
- cả bốn entry bậc (common / rare / epic / legendary) = `null`

Tức là **768 định nghĩa mặt xúc xắc chưa được viết** (192 × 4 bậc).

### Vì sao Claude Code không được tự điền

Đây không phải là chỗ để suy đoán, vì ba lý do độc lập:

1. **`BUILD_SPEC_v1.md` §3.1 cấm đoán.** Rõ ràng, thành văn.
2. **§10 giao việc này cho designer**, ước tính **3–4 person-week**.
3. **Không suy ra được từ slot.** `BLOODLINE_SYSTEM_v1.md` §1.1 đã đo:
   **13/20 part không khớp vai trò mặc định của slot nó** (Aqua·Horn *Teal
   Shell* là shield, Beast·Back *Furball* là đánh 3 lần). Bảng part→role ở
   §B2 là **thiên hướng thống kê, không phải luật**. Đoán bừa sẽ tạo ra 192
   mặt sai bản sắc, và bản sắc class chính là toàn bộ giá trị của hệ này.

Thêm nữa **INV-6** (mọi part cùng bậc phải trong ±10% ngân sách sức mạnh)
là điều kiện sống còn. Dữ liệu đoán bừa sẽ vi phạm nó ngay lập tức và biến
bộ sưu tập thành pay-to-win — đúng thứ cả hệ được thiết kế để tránh.

### Việc cần làm để gỡ chặn

Theo thứ tự:

1. **Xin quyền IP dùng tên + art part.** Rủi ro 🔴 #5 ở
   `BLOODLINE_SYSTEM_v1.md` §9. Nội bộ Sky Mavis nên khả thi, nhưng **phải
   là yêu cầu chính thức**. Không có nó, cả chiến lược content đổ.
2. **Lấy card text cho 13 part còn thiếu** từ team Origins (Bird·Ears ×6,
   Bug·Ears ×6, Plant·Ears *Lotus*). Đừng đoán — hai trong sáu bản sắc
   class (Bird, Bug) đang được kết luận trên dữ liệu khuyết.
3. **Đối chiếu `parts.json` với bảng part chính thức.** Nguồn hiện tại là
   `agp-npm` — package **do cộng đồng làm**. Nội bộ Sky Mavis thì việc đối
   chiếu này rẻ và loại bỏ hẳn một giả định nền.
4. **Designer điền 192 `role` + 768 entry bậc.** Đây là đường tới hạn.
5. **Viết check CI cho INV-6 (±10%)** — `BUILD_SPEC` §9/§11 gọi đây là
   điều kiện sống còn. Viết nó **trước** khi dữ liệu về, để dữ liệu vào là
   được kiểm ngay.
6. Chỉ khi đó mới chạy M1–M7.

### Việc Claude Code **có thể** làm ngay, song song với chờ đợi

- Viết **check CI ngân sách sức mạnh** (mục 5 ở trên) — chỉ cần schema, không
  cần dữ liệu
- Viết **loader + validator** cho `parts_build_data.json`: fail rõ ràng khi
  gặp `null`, kiểm khoá là `partId` chứ không phải tên (**7 tên trùng giữa
  các slot**), và **slugify** (`partId` `eyes-kotaro?` có dấu `?`; 9 tên
  chứa `✨` — cả hai sẽ vỡ khi dùng làm tên file/URL)
- Đổi tên keyword **`chain:N` → `scatter:N`** ngay bây giờ. Trong Axie,
  *chain* nghĩa hoàn toàn khác; để lâu thì càng đắt. (§8 của BLOODLINE)
- Mở rộng `sim.js` để nhận hệ 4 bậc, chạy được với dữ liệu giả — để khi dữ
  liệu thật về là đo được luôn

---

## 4. Quyết định thiết kế còn treo

Không phải việc code, nhưng chặn việc code. Đầy đủ ở
`BLOODLINE_SYSTEM_v1.md` §9.

1. **Quyền IP tên + art part** — blocker số một (§3 ở trên)
2. **CHAIN/COMBO** — hiện **đã gác lại** (`COMBO_DECISION_MEMO.md`). Nếu
   mở lại, phải chốt **trước khi viết dòng code nào**: đây là thay đổi mô
   hình (một hero nhận nhiều mặt trong một lượt), không phải một hàm kiểm
   tra. Chi phí thật ~**4–6 tuần**, không phải 2–3 ngày.
3. **Mystic là tầng mạnh nhất hay giữ thuần cosmetic đúng canon?** Quyết
   định cấp thương hiệu, gắn với rủi ro IP bên thứ ba (*Hasagi*, *Namek
   Carrot*) và với kỳ vọng của người đã mua Mystic on-chain.
4. **Team art xác nhận sprite part tách lớp được không?** Quyết định giữa
   "render đầy đủ" và "icon crop".
5. **Ngân sách playtest legibility.** Rủi ro 🔴 #1: 192 part × 4 bậc ≈ 768
   cấu hình mặt + 27 keyword, cho một game **gán xúc xắc**. Đây là rủi ro
   có thể giết game **cao hơn** rủi ro IP — vì rủi ro IP chặn dự án trước
   khi tốn tiền, còn cái này để dự án ship ra rồi mới chết. Mitigation duy
   nhất là playtest người thật. Không có ngân sách cho nó thì **phải cắt
   số lượng mặt**.

---

## 5. Thứ tự đề xuất

```
Tuần 1     T26 hint bar, T15 combat log, T23 unit chết, T14 noop
           (song song) gửi yêu cầu IP + xin 13 card text còn thiếu
Tuần 2     T25, T16, T22, T24, T19, T17
           (song song) viết CI check INV-6 + validator + đổi chain→scatter
Tuần 3     T08 accessibility đầy đủ  (chạy soak.mjs VÀ soakm.mjs)
           mở rộng sim.js cho hệ 4 bậc
Tuần 4+    Phase E
Chờ        M0–M7 economy — mở khoá khi designer giao 768 entry bậc
Cuối       T21 Collection (phụ thuộc M0)
```
