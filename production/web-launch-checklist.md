# Đưa bản Godot lên web — còn những gì

> Phạm vi: **đưa bản Godot lên mạng cho người chơi vào chơi**, không phải thay thế bản JS đang
> live (việc đó là `production/cutover-gate.md`, rộng hơn). Đo ngày 2026-09-20. Mọi con số dưới
> đây là đo thật; chỗ nào chưa đo thì ghi rõ "CHƯA KIỂM" kèm cách kiểm.

## 🚨 A. Chặn cứng — không lên web được khi chưa xong

### A1. Asset Axie không vào được gói build — **ĐÂY KHÔNG PHẢI LỖI VAULT**
Ticket J. `.gdignore` khiến 249MB asset Axie không bao giờ vào pck, nên **mọi bản export không
dựng nổi một con Axie nào** — đội hình, quái sinh từ gene, preview Vault, tất cả. Vault chỉ là
một trong các chỗ hỏng, không phải nguyên nhân.

Đo rồi: gỡ `.gdignore` **KHÔNG** sửa được (addon parse glTF lúc chạy, cần file gốc; Godot export
bản `.scn` đã import và bỏ file gốc). Ba hướng còn lại chưa đo — xem ticket J.

Phần vẫn đúng trong bản export: `AxieToDie.build()` ra `faces=6 hp=12 purity=3`. Tức Axie nhập
vào **đúng số liệu, không có hình**.

### A2. Nơi host phải đặt được HTTP header
Bản export bật thread nên trình duyệt đòi `Cross-Origin-Opener-Policy: same-origin` +
`Cross-Origin-Embedder-Policy: require-corp`. Thiếu là game **không khởi động nổi**, và lỗi hiện
ra trông như lỗi game chứ không phải lỗi server (`tools/serve_web_build.py` tồn tại vì lý do đó).

- **GitHub Pages: KHÔNG đặt được header** → không dùng được nếu giữ thread.
- Netlify (`_headers`), Vercel (`headers` trong config), Cloudflare Pages: đặt được.
- itch.io: có tuỳ chọn bật SharedArrayBuffer.
- Hoặc tắt `variant/thread_support` rồi export lại — **chưa đo** ảnh hưởng hiệu năng.

### A3. Giấy phép asset — phải xác nhận trước khi mở công khai
`third_party/axie-3d-assets/.../RIGHTS.md` và LICENSE của Origins Kit: asset chỉ được dùng cho
**Axie Vibeathon hoặc chương trình Axie khác được Sky Mavis duyệt**. Dự án được duyệt thì **được
phép đóng gói asset cần thiết để chạy**. Cấm: bán/phát tán asset dạng gói rời, sublicense, nhận
sở hữu.

→ Cần xác nhận dự án này nằm trong diện được duyệt. (Cũng là lý do nên cân nhắc kỹ trước khi đẩy
repo lên nơi công khai: đẩy nguyên thư mục asset lên repo public trông rất giống "phát tán asset
dạng gói rời".)

## ⚠️ B. Chưa kiểm — phải thử trước khi cho người chơi vào

### B1. Bản web có LƯU được tiến trình không — **rủi ro lớn nhất trong nhóm này**
Đo được: IndexedDB `/userfs` **có** được tạo, nhưng store `FILE_DATA` **RỖNG** sau khi boot và
vào tutorial — tức chưa có gì được ghi. Chưa chứng minh được một lần lưu/đọc lại trọn vẹn.

Nếu hỏng âm thầm thì người chơi mất sạch tiến trình mỗi lần đóng tab, và không ai báo lỗi.

**Cách kiểm**: chạy `tools/serve_web_build.py`, chơi tới chỗ game lưu (xong tutorial, đổi một
tuỳ chọn trong Settings, hoặc bắt đầu một run), **reload trang**, xem trạng thái còn không. Rồi
soi `indexedDB.open('/userfs')` xem `FILE_DATA` đã có key chưa.

### B2. Âm thanh trong trình duyệt
Trình duyệt chặn phát tiếng cho tới khi người dùng tương tác. Chưa kiểm bản web có tiếng không.

### B3. Điện thoại / màn dọc
Bản JS có màn "xoay ngang máy". Bản Godot **chưa biết** xử lý ra sao. Chưa kiểm trên máy thật.

### B4. Một lỗi runtime còn sót
Console bản web in ngay lúc boot:
`Parent node is busy adding/removing children, remove_child() can't be called at this time`.
Chưa truy nguồn. Không thấy hậu quả rõ ràng, nhưng chưa ai xem nó đến từ đâu.

## 📦 C. Kích thước tải về
Hiện tại **41MB pck + 39MB wasm ≈ 80MB**; sau khi sửa A1 sẽ lên **~150MB**. Với game chạy
trình duyệt thì nặng. Cần: bật nén Brotli phía host (giảm mạnh phần wasm), và cân nhắc cắt bớt
asset không dùng. Chưa đo kích thước sau nén.

## 🏆 D. Chỉ cần nếu muốn có bảng xếp hạng — KHÔNG chặn việc lên web
- Deploy `godot/server/axie-proxy.js` (đã viết, chưa deploy) — Vault nhập Axie bằng ID trên web
  cần nó, vì trình duyệt bị CORS chặn.
- Endpoint nộp điểm luôn bật (ADR-0004). Đường CI hiện tại chỉ đủ cho beta kín.

## ✅ E. Những thứ KHÔNG chặn — đừng để nó giữ chân bản phát hành
Collection chưa có · tutorial còn là sân tập rút gọn · lịch sử run · Account/đồng bộ đám mây ·
telemetry · FACE_POOL 55 mặt. Tất cả đã được chủ dự án xếp vào polish/phase 3.

---

## Thứ tự đề xuất
1. **B1** trước tiên — rẻ nhất mà rủi ro cao nhất. Không ai muốn phát hiện game không lưu được
   sau khi đã có người chơi.
2. **A1** — việc nặng nhất, và mọi thứ nhìn thấy trên màn hình phụ thuộc vào nó.
3. **A3** — một câu xác nhận nội bộ, nhưng phải có trước khi mở công khai.
4. **A2 + C** — chọn nơi host và đo kích thước sau nén cùng lúc, vì cùng một quyết định.
5. B2, B3, B4 — kiểm trên máy thật trước khi mời người chơi.
