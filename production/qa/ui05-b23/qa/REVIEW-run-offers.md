# REVIEW run offers (UI-05 đợt 2): core_offer, rule_offer, anchor, room, shop, event_treasure

Gốc ảnh: `/Users/loc.tien.nguyen/my-game-wt/u5b-qa/production/qa/ui05-b23/qa/` (viết tắt `QA/`).
Đã xem: 21 ảnh bản 1280 (20 ảnh trong 6 thư mục + `QA/anchor/anchorfx_1280x720.png`). Chưa xem bản 1920 và `QA/anchor/anchorfx_1920x1080.png`. Tổng trong nhóm: 20 (1280) + 2 anchor, ưu tiên 1280 theo yêu cầu. Không có thư mục `QA/1280/anchor/`. Chỉ so với luật UI, chưa mở được HTML frame để đối chiếu từng điểm.

## Lỗi (mỗi lỗi một dòng)

Chặn deploy: không thấy lỗi nào.

Nên sửa
1. [nên sửa] room, `QA/1280/room/47-core-offer--make-room--1280.png`: ảnh tên "make-room" nhưng chỉ là một thẻ reward đơn ("Relic / Seedling", Reroll · 2 left, "Pick a card"). Không có lời nhắc "hết chỗ", không có danh sách Core để thay. Hoặc capture chụp sai trạng thái, hoặc UI make-room chưa render. Phải xác nhận trước khi coi là đã kiểm. File nghi: scene core offer/make-room trong `godot/scenes/run/` và tool chụp QA.
2. [nên sửa] room, `QA/1280/room/47-core-offer--combo-banner--1280.png`: ảnh tên "combo-banner" nhưng là banner "Lunacia Rain / MUTATION · LEVEL 2" trên map, không phải combo của Core. Capture có thể sai, hoặc combo banner chưa có ảnh. Trong banner có icon bàn tay cạnh chữ MUTATION trông như emoji lạc chỗ. File nghi: tool chụp QA, scene map banner.
3. [nên sửa] anchor, `QA/anchor/anchorfx_1280x720.png`: tiêu đề "ANCHOR AWAKENED" bị hạt confetti đè lên, huy hiệu mũi tên vàng chạm sát dưới chữ (đè cả viền chữ). Thanh "House Cores 2/2" không có phần fill, chỉ một chấm tròn ở mép phải, nhìn như thanh rỗng nên không rõ 2/2 nghĩa là đầy. Nền xám phẳng (có thể do harness). File nghi: scene hiệu ứng Anchor (anchor fx) trong `godot/scenes/`.

Nhỏ
4. [nhỏ] core_offer, tất cả `QA/1280/core_offer/*.png`: dòng "Core tier: Moss → Amber → Crystal (strongest)" và phần mô tả thẻ trông cỡ 13-14 px, sát ngưỡng 14 px. Cần đo font thật bằng test, không kết luận được bằng mắt.
5. [nhỏ] core_offer, `47-core-offer--facedown-1280x720.png`: ba thẻ úp đều ghi "Moss" cho mọi thẻ. Nếu thẻ thật là Amber/Crystal thì úp mà vẫn lộ hạng, hoặc nhãn là placeholder. Hỏi design.
6. [nhỏ] core_offer, `47-core-offer--crystal-1280x720.png`: thẻ Crystal có viền cắt góc, nội dung lệch xuống 3-4 px so với thẻ Moss/Amber (tiêu đề y 232 so với 228). Lệch nhẹ khi đổi hạng.
7. [nhỏ] rule_offer, `05-run-rule-offer--offer-1280x720.png`: nhãn "Run rule" (trên) và "Rule" (dưới tiêu đề) trùng nghĩa, nhãn "Run rule" màu nhạt trên nền nâu, tương phản thấp. Dòng giá "- Enemies have +30% HP too" trông chỉ khoảng 13 px, cần đo.
8. [nhỏ] event_treasure, `event--choices-1280x720.png` và `event--outcome-1280x720.png`: art sự kiện là icon pixel phóng lớn khoảng 250 px, bị mờ/vỡ hạt, nằm trong khung trống lớn. Có thể là placeholder. Khi chuyển sang outcome, tiêu đề nhảy lên 12 px (layout shift nhẹ).
9. [nhỏ] event_treasure, `event--outcome-1280x720.png`: hai lựa chọn không chọn bị làm mờ rất nhiều, chữ mô tả gần như không đọc được (tương phản thấp). Chấp nhận được nếu là trạng thái disabled có chủ ý, nhưng nên nâng nhẹ.
10. [nhỏ] shop, `shop--stock--1280.png`, `shop--sold-out--1280.png`, `shop--cant-afford--1280.png`: icon shard trong các nút Sell chỉ khoảng 10 px, nhỏ hơn hẳn chữ. Cột Cores để trống chỗ thẻ thứ 3 và khung Sell nổi bên phải, bố cục lệch. Trong sold-out và cant-afford thẻ Core Pick ghi "Sold out" trong khi stock thì "Buy · 60 Shards" (khác dữ liệu fixture, bỏ qua nếu vậy).
11. [nhỏ] anchor/room, `47-core-offer--combo-banner--1280.png`: dòng gợi ý góc dưới "Arrows pick · Enter or double-click travels · Esc menu" dùng chữ Enter/Esc, không phải keycap nên không vi phạm luật keycap, nhưng nhỏ và mờ, khó đọc.

## Đã kiểm, không thấy lỗi
- Keycap Space chỉ có trên nút an toàn đã sẵn sàng: Take, Open chest, Continue, Leave shop, và "Click or Space to skip". Không có keycap trên nút tắt (Pick a Core, Pick a rule, Pick a card, Pick a choice, Pick a reward, Reveal the cards first, Need N Shards, Sold out, No rerolls left, Rerolled).
- Không chọn sẵn: khi chưa chọn, mọi màn đều chỉ có focus ring xanh nhạt trên thẻ đầu, nút xác nhận xám. Chỉ khi chọn mới có viền kem + nâng thẻ + nút Take vàng.
- Nút tắt nói lý do/việc cần làm: có ("Need 110 Shards", "No rerolls left", "Reveal the cards first", banner "You can't afford anything here. Sell a Core or leave.").
- Không thấy chuỗi minh hoạ trong game ngoài dữ liệu fixture ("A sample rule…", "Reward one", "A stand-in reward" thuộc fixture, bỏ qua). Không thấy hiệu ứng PROPOSAL.
- Tiêu đề thẻ Core/Shop căn trái đúng luật. Nhãn dưới icon (Kin trong anchor, tên trên thẻ úp) căn giữa. Chữ không bị cắt ở 1280 trong các màn đã xem.

## Số ảnh
Đã xem 21 / 24 (22 ảnh 1280+anchor1280 trong nhóm tính cả anchor 1920 và 1920 chưa xem). Bản 1920 của 6 thư mục chưa xem theo ưu tiên 1280.
