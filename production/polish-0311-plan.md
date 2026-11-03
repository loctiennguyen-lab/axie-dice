# Kế hoạch polish 3/11: 23 mục + làm lại art AI

Nguồn:
- danh sách mục: `production/polish-0311-list.md`;
- art: `production/qa/art-provenance-0311.md` (mục "Liam quyết") và `production/qa/ui06-asset-audit.md`.

Luật chung:
- quy tắc UI ở `godot/CLAUDE.md`;
- dùng kho asset trước;
- art kho không có thì Claude Design vẽ lại bám kho, và Liam duyệt từng món;
- mỗi làn có review độc lập và QA luồng thật;
- hỏi Liam trước khi deploy.

## Quyết định cần Liam trước khi làm
1. **Mục 2, slot.** Game có hai loại ô khác nhau:
   - **Lõi**: 6 ô Lõi + 1 ô Luật run;
   - **relic cũ / pact**: 8 ô passive + 3 ô active, Ascension có thể giảm số ô (`scripts/core/relic_slots.gd`).

   Câu "Passive slots are full (9 of 8)" là UI đếm sai, không phải luật sai. Đề xuất: sửa cách đếm; giữ hai từ riêng, "Core" cho Lõi và "Relic" cho relic cũ / pact; câu chung dạng "Relics: 8 of 8. Sell one to take Lone Wolf Contract". Không đổi luật.
2. **Mục 9, màn chọn Anchor dày chữ ở 1280.** Đề xuất: luôn hiện Rule và Price; khối "Awakens" và "House Cores" hiện đủ ở thẻ đang chọn, các thẻ khác thu gọn; dòng chú thích SET / M / Cracked chuyển thành tooltip.
3. **Mục 20, dòng gợi ý phím trên map** ("Arrows pick · Enter or double-click travels · Esc menu"). Đề xuất: bỏ dòng này. Phím vẫn hoạt động, chỉ ghi trong tooltip, đúng luật "chỉ hiện Space".

## Đợt 1: code, không chờ art (3 làn song song)
- **P1 Combat:**
  - #5 bốn nút Undo / Hold / Wild / Overcast phải nói lý do khi tắt;
  - #15 tên dài trên thẻ xúc xắc, nhãn "Name Tag" giữa sân;
  - #16 cột boss, chip Enrage, ô trứng Axie;
  - #17 nhãn trạng thái quái bị đẩy lên trên mép màn;
  - #18 ngọc bậc trên strip to hơn.
- **P2 Run map, thưởng, shop:**
  - #2 đếm slot + chữ;
  - #6 tên boss bị cắt;
  - #7 shop: cột Sell, giá, icon, khoảng trống;
  - #8 thẻ thưởng trống nửa dưới; Reroll lệch hàng;
  - #12 chip "Rare" cũ, icon trong Make room;
  - #14 ô Cores trên map;
  - #19 nút "Reveal the cards first";
  - #22 thống nhất chữ trên nút;
  - #23 driver đứng yên ở màn chọn Lõi.
- **P3 Màn khác:**
  - #3 màn kết quả, chụp lại và sửa nếu lỗi thật;
  - #9 màn chọn Anchor;
  - #10 bố cục thẻ Luật run và trạng thái focus;
  - #13 sự kiện và rương: nút và cỡ chữ;
  - #20 dòng gợi ý phím;
  - #21 bố cục Land sau khi đăng nhập.

Mỗi làn chạy test liên quan, chụp ảnh 1920 + 1280 và có review. Gộp xong thì chạy suite đủ.

## Đợt 2: làm lại art AI (theo bảng nguồn gốc, Liam đã chốt)
- **Bước 1, bảng tồn kho cuối cùng.** Mỗi món ghi "kho có, dùng luôn" hoặc "vẽ bám kho" kèm món kho cụ thể để bám. Liam xem bảng TRƯỚC khi gửi brief.
- **Bước 2, brief Claude Design**, theo từng gói, mỗi gói có ảnh đồ kho đính kèm:
  - **Gói A, thẻ Lõi** (khoảng 26 món): khung thẻ theo bậc, crest, art window, mặt sau, socket, family dice / stat / quest / run_rule, badge, ui_awaken, fx. Cộng hướng mới cho #4 (hiệu ứng Lõi kích hoạt, thay đường chấm và mũi tên), icon riêng cho từng pact (#11), minh hoạ Luật run nếu cần (#10).
  - **Gói B, icon do agent tự vẽ** (khoảng 22 món): 6 house emblem và các icon SVG khác.
  - **Gói C, cosmetics**: 26 skin xúc xắc và 49 khung.
- **Bước 3**: nhận bản giao, Liam duyệt từng món, rồi đưa vào game qua `UI6Assets` và các chỗ tương ứng.
- Xoá 95 file ui6 không còn ai dùng. Pck nhẹ đi.
- Giữ nguyên: tranh `cards/*` (Origins Kit), `icons/web`, chân dung class, logo, nền màn đăng nhập.

## Thứ tự
1. Liam chốt 3 quyết định ở trên.
2. Đợt 1 chạy ngay. Song song: em lập bảng tồn kho gói A/B/C để Liam xem.
3. Liam duyệt bảng, em gửi brief gói A trước (ảnh hưởng nhiều màn nhất), rồi B, rồi C.
4. Bản giao về: code, review, QA, Liam duyệt, deploy.
