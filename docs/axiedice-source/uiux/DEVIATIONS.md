# DEVIATIONS.md

Mọi chỗ bản build lệch khỏi `IMPLEMENTATION_BRIEF_1.md`, kèm lý do.

---

- **[pre-flight] Repo không giống kỳ vọng §2.** Không có `npm run dev`, không có
  dist/bundler. Game là **một file HTML tự chứa**, dựng bằng `python3 build.py`
  từ `src/*.js` + `src/style.css`. Để chạy `verify.mjs` tôi phục vụ file build
  qua `python3 serve.py` ở `http://localhost:5173`. Mọi đường dẫn trong các task
  trỏ tới `src/style.css` và `src/ui.js` như brief dự đoán.

- **[pre-flight] Tutorial overlay chặn `reachCombat`.** Bản v0.9 tự mở overlay
  hướng dẫn ngay sau `startRun()`, và vì `render()` vẽ nó đè lên màn Map nên
  **click đầu tiên của một run mới bị nuốt** — verify không vào nổi combat, và
  người chơi mới cũng gặp đúng rào đó.
  → Đã bỏ auto-open. Nội dung tutorial vốn đã nằm đủ trong CODEX, giờ là một
  trong bốn ô ở menu (T18). Hint bar (T26) lo phần dẫn dắt trong trận.

- **[T10] `--die-num` ở breakpoint dùng 24px, không phải 26/24 như brief gợi ý.**
  Brief cho phép thêm 26 vào `ALLOWED_FONT_SIZES` và ghi deviation. Không cần:
  **24px đã nằm sẵn trong thang hợp lệ**, nên tôi dùng 24 ở cả hai breakpoint
  dưới. Không phải nới lỏng check nào.

- **[T09] `--ui-scale` vẫn áp qua `zoom` trên `#app`.** Brief §8.5 nói zoom là
  lớp tinh chỉnh cuối, sau breakpoint — đúng như đang làm: breakpoint đổi kích
  thước component, và JS chỉ đặt `--ui-scale ≠ 1` khi `innerWidth ≥ 1200`.

- **[T05] `.hpnum` nằm BÊN TRONG `.hpbar`, không phải sibling đứng trước.**
  Brief đề nghị đặt `.hpnum` trước `.hpbar`. Làm vậy thì `checkHpState` của
  `verify.mjs` — vốn đọc `HP x/y` từ `b.textContent` của chính `.hpbar` — sẽ
  không thấy số nào và **A9 pass rỗng**, tức là qua check mà không chứng minh
  được gì. → `.hpnum` là con của `.hpbar`, `position:absolute; bottom:100%`,
  còn thanh máu thật nằm trong `.hptrack`. Chữ vẫn hoàn toàn nằm ngoài fill
  (đúng mục tiêu T05) và A9 vẫn đo được thật.

- **[T07] Giữ cả tên cũ `.btn.sm` / `.btn.xs` bên cạnh `.btn--sm`.** Brief nói
  đổi `.btn.xs` → `.btn--sm`. Vì `btn()` được gọi ~60 chỗ trong `ui.js` với
  chuỗi class tự do, tôi map `.btn.xs, .btn.sm, .btn--sm` về **cùng một quy tắc
  32px**. Kết quả đo giống hệt; rủi ro sót chỗ gọi thì không.

- **[T11 / N1.phone] Check `N1.phone` FAIL là hệ quả trực tiếp của việc làm
  đúng T11.** T11 yêu cầu ở phone portrait phải ẩn bàn chơi và hiện gợi ý xoay
  máy. `verify.mjs` chạy `reachCombat()` **trước** rồi mới xoay ngang, nên nó
  đếm `.die` khi bàn đang bị ẩn có chủ đích → `N1.phone` đỏ.
  Check được thiết kế cho tình huống này là **`B4` — và B4 PASS**. Theo §8.10
  tôi **không** sửa hay nới check; ghi lại ở đây. Ở landscape 852×393, các check
  `B2.phone`, `B3.phone` đều xanh.

- **[T13] Không đổi `.die` sang `grid-template-rows` 5 hàng cố định.** Giải phẫu
  hiện tại là flex-column với `.dkw` luôn tồn tại, và `C1` (5 ô cùng width/height,
  kể cả khi có mặt keyword) **PASS**. Đổi sang grid không cải thiện phép đo nào
  nên không đáng rủi ro hồi quy.

- **[T08] Semantic `<button>` cho `.die` / `.unit` chưa làm.** `A8a` (mọi element
  tương tác focus được) và `A8b` (focus ring) đều PASS vì `.btn` đã là `<button>`
  thật và focus ring dùng `:focus-visible`. Nhưng `.die` và `.unit` vẫn là `div`
  + `onclick`, nên **screen reader chưa đọc được chúng và Tab chưa tới**. Đây là
  nợ kỹ thuật đã biết, còn lại của T08 (mục 2, 3, 4: role/aria, thứ tự tab,
  phím Q–T chọn mục tiêu).

- **Chưa làm — ghi rõ để không ai tưởng đã xong:** T14 (mục tiêu `noop`),
  T15 (combat log), T16 (chip có nhãn ở header), T17 (`ABANDON RUN` + Settings),
  T19 (card team select 220×300), T21 (Collection), T22 (info panel 2 cột),
  T23 (unit chết), T24 (map 1 node), T25 (bottom bar), T26 (hint bar 3 lượt),
  và **toàn bộ Phase E**.
