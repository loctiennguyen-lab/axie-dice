# 25 câu hỏi UI cho Liam (1/11/2026)

Gom từ QA và review UI-05 đợt 2+3 (`production/ui05-b23-integration.md`). Không câu nào chặn việc khác.
Trả lời ngắn theo số, ví dụ "1 khoá, 2 giữ, 3 có…". Câu nào anh để trống thì em làm theo đề xuất.

## Mua bán, tài khoản
1. **Unlocks:** mục ghi "NO EFFECT YET" (Relic Pool II/III, Gene Pool II/III) vẫn mua được bằng Shards. Đề xuất: **khoá nút**, ghi "Coming soon".
2. **Choose a save:** nút "Keep this device" đang tô cam như nút chính. Bấm nút này là không đổi lại được (ghi đè save kia). Đề xuất: **để hai nút ngang nhau**, cùng kiểu.
3. **Choose a save:** màn không đặt focus sẵn. Code cũ cũng vậy, để tránh bấm Enter nhầm vào nút ghi đè. Có muốn focus sẵn vào thẻ đầu không? (Focus chỉ chuyển ô, không chọn.) Đề xuất: **có**.
4. **Raid khi chơi guest hoặc offline:** chỉ có nút xám "Sign in to raid", không có nút Sign in thật. Daily và Store có nút này. Đề xuất: **thêm nút Sign in**.
5. **Nút "Play as guest"** kiểu chữ gạch chân. Ở 1280 nhìn như dòng chữ thường, đúng như HTML thiết kế. Đề xuất: **giữ**.

## Land
6. **Land upgrade:** khung xem trước bậc đất bên phải là khối màu phẳng, vì chưa có art (thiết kế ghi tạm). Đề xuất: **giữ tạm**, đưa vào đợt art.
7. **Land 1280 offline:** nhãn "Daily run · needs connection" và "Start run · needs connection" quá dài, nên hàng nút run bị đẩy lên một hàng riêng. Đề xuất: **rút ngắn nhãn** thành "Offline" để về một hàng.
8. **Tooltip toà nhà trên Land** ghi cả phím, ví dụ "Echo Box · 4", theo luật "phím khác chỉ ghi trong tooltip". Frame chỉ có tên. Đề xuất: **giữ**.
9. **Land tier up:** khi bật Reduce flashing, em tắt luôn hit-stop, rung và flash. Bảng spec ghi "—", em chọn cách an toàn. Đề xuất: **giữ**.

## Run, combat
10. **Run setup:** thẻ party 5 class đều nền xanh lá (art portrait mặc định). Đúng ý không? Đề xuất: **đổi nền theo màu class**.
11. **Panel "Cores owned":** frame không vẽ Pact. Em đang hiện Pact theo kiểu hàng Luật: tên bên trái, chữ "Pact" bên phải, điều khoản phạt ở dưới. Đề xuất: **giữ** (UI-06 sẽ làm lại phần này).
12. **Card Anchor ở 1280:** khoảng cách trong thẻ giảm từ 12 xuống 8, để thẻ không cao quá khi chữ được nâng lên tối thiểu 14 px. Đề xuất: **giữ** (UI-06 làm lại thẻ).

## Pass, Echo, Profile
13. **Pass level-up:** hiệu ứng chỉ chạy khi màn Pass thấy level tăng trong cùng phiên. Mở Pass lần đầu trong phiên thì không chạy. Đề xuất: **giữ**.
14. **Pass ở 1280:** ô hẹp nên "Reach Level N" bị cắt thành "Reach Lev…", mất số (tooltip vẫn có đủ). Đề xuất: **đổi thành "Lv N"**.
15. **Pass sau khi mùa kết thúc hoặc offline:** frame vẽ nút Claim all tắt, nhưng game vẫn cho nhận các level đã đạt. Đề xuất: **giữ cho nhận** (người chơi đã đạt thì được nhận).
16. **Profile, tab Titles:** câu phụ "Titles from Ascension goals. One title at a time." Giờ có cả title từ Land. Đề xuất: **đổi** thành "Titles from Ascension goals and Land milestones. One title at a time."
17. **Profile, tab cosmetic:** số đếm có tính ô Default không? Code ghi "2 of 27", HTML ghi "2 of 26". Đề xuất: **không tính** ("2 of 26").
18. **Profile:** HTML vẽ chip Pure cho dòng Mission Won, nhưng chỉ số Pure wins không tính Mission. Em đang làm theo dữ liệu (không có Pure cho Mission). Đề xuất: **giữ**.

## Hệ thống, khác
19. **Raid:** khi chờ server (lưu đội thủ, bấm Fight), nút không tắt (để giữ focus) và chưa có dấu hiệu đang chờ. Đề xuất: **thêm dòng "Working…"**.
20. **Codex, bảng Controls:** liệt kê đủ phím, ví dụ "Enter, Num Enter". Có muốn chỉ ghi phím chính không? Đề xuất: **chỉ phím chính**.
21. **NetNotice** (báo mất mạng): làm mờ màn bên dưới nhưng không chặn chuột, giữ như cũ. Đề xuất: **giữ, không chặn**.
22. **NetNotice:** frame đặt icon ToneDisc căn trên, code căn giữa theo luật "chữ cạnh icon căn giữa". Đề xuất: **giữ căn giữa**, báo Claude Design sửa HTML.
23. **Settings, thanh trượt:** theo HTML không có núm kéo (vùng bấm vô hình vẫn đủ lớn). Đề xuất: **thêm núm** cho dễ thấy.
24. **Leaderboard, tab Today:** khi chơi guest hoặc là người mới, vẫn thấy hàng ghim "Sign in to appear here" ở cuối, dù frame Today không vẽ. Đề xuất: **giữ**.
25. **Leaderboard, bảng bị khoá:** dòng giải thích ghi "win a run at A{n−1}". Ví dụ anh mới mở tới A6 mà xem A9 thì nó ghi "win a run at A8", trong khi A7 còn chưa mở. Đề xuất: **đổi** thành "win a run at A{bậc cao nhất anh đã mở} to unlock the next one".

## Liam trả lời (1/11 tối)
1 khoá nút, ghi "Coming soon" · 2 để hai nút ngang nhau · 3 có · 4 thêm · 5 giữ · **6 làm một bản xem trước cho Liam** ·
7 rút thành "Offline" · **8 chỉ để tên, KHÔNG ghi phím** (khác đề xuất) · 9 giữ · 10 đổi nền theo màu class · 11 giữ (UI-06) ·
12 giữ (UI-06) · 13 giữ · 14 đổi thành "Lv N" · 15 giữ cho nhận · 16 đổi · 17 không tính · 18 giữ · 19 thêm "Working…" ·
**20 giữ (liệt kê đủ phím)** (khác đề xuất) · 21 giữ · 22 giữ căn giữa · 23 thêm núm · 24 giữ · 25 ghi theo bậc cao nhất đã mở.
Thêm: Liam muốn có **màn hình đăng nhập**.
