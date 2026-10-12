# Câu hỏi và việc chờ Liam — bản gom (cập nhật 12/10/2026, tối)

Liam trả lời theo số, ví dụ "đồng ý hết, trừ 4: …". Mỗi câu có khuyến nghị. Các câu cũ đã trả lời đều đã ghi vào file
nguồn, không nằm ở đây nữa.

## A. Gấp — đang chặn làn code

| # | Câu hỏi | Khuyến nghị | Trả lời |
|---|---|---|---|
| 1 | **Đăng nhập cho bản desktop.** Hiện desktop luôn là khách (chỉ web đăng nhập được). Không có đăng nhập thì không có ví, Gem tặng, cọc Nhiệm vụ. Làm đăng nhập Google qua Worker (mở trình duyệt rồi quay lại game)? | Có. Làn S thêm ~2–3 ngày, làn U thêm màn đăng nhập | |
| 2 | **Gem lưu ở đâu?** | Trên server (thêm ~1 ngày), để server kiểm trần 900 và trừ Gem khi Continue/Aid. Shard, Stone vẫn trong save | |

## B. Sprint L1 (3/11)

| # | Câu hỏi | Khuyến nghị | Trả lời |
|---|---|---|---|
| 3 | Duyệt trước **danh sách cắt** (`production/l1-sprint-plan.md`, 12 mục + 3b "Land chỉ tier 1") để tới mốc 24/10 làn nào trễ thì tự cắt theo thứ tự? | Duyệt | |
| 4 | Ở L1: Shard/Stone trong save, server chỉ ghi sổ; **cọc Nhiệm vụ do server giữ** để đối soát | Đồng ý | |
| 5 | Chưa có verifier: thưởng Nhiệm vụ dựa vào client tự báo, đánh dấu "chưa kiểm" | Chấp nhận cho nhóm nội bộ | |
| 6 | Game **bắt buộc online** (không có chế độ offline) | Đồng ý | |
| 7 | Mỗi ngày anh duyệt được khoảng bao nhiêu giờ? | Nếu < 1 giờ/ngày, gộp làn meta vào làn UI và làn Land vào làn combat 3D | |

## C. Bản phát hành

| # | Câu hỏi | Khuyến nghị | Trả lời |
|---|---|---|---|
| 8 | **Tên app** (đổi tên làm đổi thư mục save, phải chốt trước RC1 29/10) | "Axie Dice" | |
| 9 | Bundle id | `fun.axiedice.game` (đang dùng) | |
| 10 | Số phiên bản hiển thị | `0.1.0` cho L1 | |
| 11 | **Kênh báo lỗi** cho người test và người nhận | Một kênh Slack riêng + form ngắn; người nhận: Liam | |

## D. Việc anh cần tự làm (agent không làm được)

| Hạn | Việc |
|---|---|
| Ngay | Gửi Claude Design: **prompt menu/meta (Round 3)** — em đang viết, sẽ đưa link; và ghi chú cosmetics lượt 2 `design/handoffs/cosmetics-01/NOTE-TO-CLAUDE-DESIGN-02.md` nếu chưa gửi |
| 13–14/10 | **Nâng Cloudflare Workers lên gói Paid** (Durable Object cần). Đừng `wrangler deploy` trước khi nâng |
| 14/10 | Chạy đo độ trễ WebSocket (lệnh trong tin nhắn trước, em gửi lại khi anh sẵn sàng) và dựng staging một lần (em đưa từng bước) |
| 20/10 | Hạn Claude Design giao Round 2 (run flow + Ascension) |
| 22/10 | **Asset boss Atia** còn thiếu — làn C sẽ báo danh sách cụ thể |
| 24/10 | Hạn Claude Design giao Round 3 (menu/meta) · **danh sách ~50 người mời + máy của họ (mac/win)** |
| Khi rảnh | Chạy thử bản Windows trên một máy Windows (bản build đầu ở `~/my-game-wt/R/build/`) |

## E. Đã chốt hôm nay (để tham chiếu, không cần trả lời)
Kiến trúc server RNG · monetization (cách B, PA-1, quà 180 Gem) · Ascension răng cưa · Nhiệm vụ bản cực khó (Bayes, không giới
hạn/ngày, NFT dùng được) · UI request 02 + Round 1 · L1 = 3/11 nội bộ, phạm vi đầy đủ, Gem tặng 300/ngày · commit/push tự do, duyệt theo tuần.
