# QA tổng beta — tiến độ 27/10 (bản R3, web md5 577eacb1, desktop b1752)

## Đã chạy
- **Server, không đăng nhập (khách):** 15 API tạo run / tiêu tiền / nhận thưởng / ghi save đều trả 401. Leaderboard GET mở. PASS.
- **Live smoke production (bot, phiên desktop của Liam):** 1 lần `--full` + 3 lần thường, đều PASS.
  - Đã kiểm: run thật, thắng trận, thưởng, offline RETRY, Continue sau khi thoát, Daily, abandon sạch, không sót run mở.
  - Công cụ phải sửa một chỗ: client R3 đẩy save ngay khi vào, công cụ chặn lệnh đó nên client tưởng offline. Sửa ở `godot/tools/live_smoke.gd`, đã review.
- **Web, tài khoản Liam (tay):**
  - FLOW-19: run thường, thắng trận 1, nhận thưởng Level Up. PASS.
  - FLOW-29: tải lại giữa run rồi Continue, giữ đúng tiến độ. PASS, nhưng gặp BUG-0006.
  - Bỏ run: lời xác nhận rõ. PASS.
  - FLOW-23 Echo Box, 3 vé: khung Common, 100 Stone, pity tăng. PASS, nhưng chip Stone trong màn không cập nhật.
  - FLOW-21 Daily: lỗi chữ và nút, xem bên dưới.
  - Pass: mùa chưa bắt đầu (3/11), hiện đúng.
- **Săn chỗ khó hiểu:**
  - 39 màn × 2 cỡ, chụp offline.
  - ux-designer review độc lập: 0 S1, 6 S2, 23 S3, 15 S4. Chi tiết ở `production/qa/ux-hunt-review-2026-10-27.md`.
- **RTT `[epoch_rtt]`:**
  - Desktop (live smoke, WebSocket): phần lớn 80–450 ms. Có 1465, 1292 và 3042 ms (node đầu run).
  - Web: 999–1204 ms, nhưng đo khi khung trình duyệt bị ẩn (timer bị hãm), nên chưa dùng được. Vẫn cần mẫu từ tester thật.

## Lỗi mới
| ID | Mức | Tóm tắt | Làn |
|---|---|---|---|
| BUG-0006 | S2 KHÓ HIỂU | Tải lại trang giữa run hiện "played somewhere else", máy này 500 Shard và cloud 0 Shard. Số 0 sai vì server cắt Shard khỏi cloud save; xung đột cũng không có thật. | qa/fix-account-ux |
| (reset) | S2 KHÓ HIỂU | Sau reset không có thông báo chung, số dư về 0 không giải thích. | qa/fix-account-ux |
| BUG-0007 | S2 | Màn Result và màn Pass lệch tên, thang XP và phần thưởng. | qa/fix-pass-result |
| BUG-0008 | S2 | Cổng 5 run, stage và Daily đếm từ save trên máy, không từ server. Server đã tính 5 run, web vẫn khoá Nhiệm vụ/Ranked và hiện "Daily 3 of 3". | qa/fix-server-gates |
| — | S2 | Màn thua Nhiệm vụ không nói mất cược. Nhãn khoá N6 thiếu điều kiện. "Pool now". | qa/fix-run-ux |
| — | S3 | "Relics" và "Cores". Callout "first run is guided" còn sau khi bỏ tutorial. "Preparing the run". Chờ seed trông như treo. "1 duplicates". | qa/fix-run-ux |
| — | S3 | Chip Stone/Gem ở đầu màn Echo Box và Daily không cập nhật sau khi nhận. | qa/ui-0001-0005 |
| — | S3 | Daily ghi "Any run counts" và nút Claim bấm được, server trả "Finish a run first". Chữ kết quả Gem hiện nhầm sang thẻ Daily. | qa/ui-0001-0005 |
| BUG-0001, 0005 | S3/S4 | Đã sửa (fd844a7). Review APPROVE WITH CHANGES, đang làm phần review yêu cầu. | qa/ui-0001-0005 |

## Chưa làm được
- FLOW-1/2/7 Nhiệm vụ trên production: bị chặn bởi BUG-0008. Server đã mở, client vẫn khoá. Làm lại sau khi sửa.
- Windows, tài khoản QA phụ, mẫu RTT web thật: vẫn chờ Liam.
- Soak R3 (`production/qa/soak/2026-10-27/`): đang chạy.
