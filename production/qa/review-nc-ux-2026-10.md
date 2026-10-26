# Review UX làn N-C (UI Nhiệm vụ), 26/10/2026

Người review: ux-designer (độc lập). Chỉ xem ảnh trong `production/qa/evidence/nc_*` và đọc `MissionsScreen.gd`, không chạy Godot.
Verdict: **APPROVE WITH CHANGES**. Không có lỗi chặn merge. Có 1 việc chặn R1 (màn thua, xem cuối).

## Người mới nhìn thẻ có hiểu không
(a) Mất gì / được gì / khả năng thắng: hiểu tốt. Khung đỏ "Lose or abandon: You lose 800 Shards. No refund, no Stone", dòng "Net if you win", dòng "Estimate (bot)" và dòng cam "Most players lose this tier" đều nằm trong 1 panel (`nc_missions_n3_1920x1080.png`, panel phải). Đỏ chỉ dùng cho nguy hiểm, đúng luật. Cảnh báo N3/N5/N6 có đủ, câu chữ rõ.
(b) Vì sao khoá: hiểu. Mỗi hàng có "Locked: Win N3 to unlock", nút disabled ghi lý do, không chỉ dựa vào màu (`nc_missions_n5_locked`).
(c) Modal "có bản mới": rõ. Nói chuyện gì xảy ra, nói "Nothing was spent", nút primary duy nhất là "Download the new version", Close là phụ (`nc_update_modal_1920x1080.png`).

## NÊN SỬA (trước khi cho người chơi thật thấy)
1. Phụ đề header "Stake Shards on a hard Short run" và dòng "Win a hard Short run..." sai với N6 (Full). Ảnh `nc_missions_n6_locked` vẫn đọc "Short". Đổi thành "a hard run" hoặc lấy mode theo tier đang chọn. Vị trí: thanh tiêu đề trên cùng và banner dưới nó.
2. Nút khoá của N5/N6 nói "Win N4 to unlock" / "Win N5 to unlock", nhưng N4 cũng đang khoá. Người chơi hiểu mơ hồ. Gợi ý: "Clear N3, then N4 first" hoặc "Locked: clear N1 to N4 in order". Vị trí: nút dưới panel phải (`n5_locked`, `n6_locked`).
3. Thuật ngữ không giải thích: "A0..A6" (cột MODE và tiêu đề panel), "Stone" (cột STONE, không có icon, nằm trong tên cột chữ hoa), "Starter 0 (can't be staked)", "(bot)". Người mới không biết A3 là gì. Thêm tooltip hoặc 1 dòng chú thích ("A = độ khó"), và giải thích Starter 1 câu. Đang là chữ UI-vá, không phải lỗi luật.
4. Hàng khoá: chữ "Locked: ..." dùng LabelMuted trên nền nâu tối + cả hàng bị làm mờ. Nhìn bằng mắt thì độ tương phản thấp (khoảng 3:1, ước lượng, chưa đo). Cả STAKE/PAY của hàng khoá cũng mờ dù đó là thông tin người chơi cần để quyết định có đáng mở không. Giữ số rõ, chỉ mờ nền hoặc chỉ chữ "Locked".
5. Mission House (đáy trái, cả 4 ảnh): dòng giá "Lv 2: 3000 Shard + 4000 Stone ..." không có dấu phẩy, tự xuống dòng và "Lv 4:" bị rớt xuống dòng dưới; nút "Not in this build" là ngõ cụt. Nút này có reason nên không vi phạm "disabled phải nói lý do", nhưng nó hứa tính năng chưa có và chiếm 1 cụm sát nút primary. Khuyên: ẩn cả khối hoặc rút còn 1 dòng "Mission House: coming later", không giá, không nút. Không bắt buộc trước R1 nếu R1 chỉ là beta kín, nhưng nên làm trước khi mở rộng.
6. Nhất quán ký hiệu: bảng dùng "×3.6", panel dùng "x6.5". Chọn 1 (nên dùng "×"). Cột PAY IF YOU WIN trong bảng là tổng nhận về, không phải lãi; người mới dễ đọc thành lãi. Đổi tên cột thành "WIN BACK" cho khớp panel, hoặc thêm cột net.
7. 1280x720 (`nc_missions_n3_1280x720.png`): vẫn đọc được, không cắt, N6 (panel dài nhất) vẫn vừa (`nc_update_modal_1280x720.png` nền sau). Nhưng chữ thân panel và nhãn cột chỉ cỡ 11 đến 12px thực tế, và "Net if you win" dính sát số tiền bên phải. Cần kiểm lại cỡ chữ trong code có bám 16/18/24/32 (luật UI3) hay đang dùng cỡ lẻ; ảnh không cho xác nhận được. Nếu là scale cả canvas thì chấp nhận.

## Ổn, không cần đổi
- Chỉ 1 nút primary mỗi trạng thái; nút khoá chuyển sang kiểu xám phẳng, không còn trông bấm được.
- Nút nói số tiền: "Stake 800 and play". Tốt, không cần dialog xác nhận thêm nếu số này luôn hiện đúng. Tôi chưa thấy ảnh trường hợp Stake > Stakeable (chỉ có Starter): hãy chụp để chắc là nút disabled và nói "Need X more Shards".
- Modal: focus ở nút primary, có Close, nền tối đủ tách.

## Hai ghi chú Liam hỏi
- Màn thua (ResultView) chưa làm: **CHẶN R1.** Đây chính là chỗ người chơi mất tiền thật và dễ hiểu nhầm là bug. Tối thiểu phải có: "You lost 800 Shards (stake)", không có Stone, tier kế vẫn khoá hay mở, nút quay lại Missions. Không chặn merge N-C.
- "Mission House / Not in this build": **không chặn R1**, nhưng xem mục 5 ở trên.

Chưa kiểm: bàn phím/gamepad (ảnh tĩnh), trạng thái hover/focus, hàng khoá khi chọn bằng phím, modal ở 1280 khi Download không khả dụng (nền web).
