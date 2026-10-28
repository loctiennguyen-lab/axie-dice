# Bàn giao cho Liam polish (28/10/2026)

## Bản đang chạy
- Web: https://axiedice.fun. Desktop: https://axiedice.fun/download (bản mới nhất ghi ở `downloads/latest.json`).
- RULES_VERSION `godot-2026-10-26-v`. Worker có ví server (R3), Nhiệm vụ 6 bậc, Land, 6 quái Atia, 6 Anchor, SR-V chạy bóng.
- App desktop và web của Liam đang đăng nhập **hai tài khoản Google khác nhau** ("Lộc Nguyễn" và "Lộc Tiến Nguyễn"). Tiến độ không chung giữa hai bên.

## QA đã xong (27–28/10)
- Soak bản R3: 27.069 run bot, 0 crash. 1 run lệch replay và 3 run kẹt đều là trận kéo dài khi chỉ còn 1 Axie. Liam quyết: không thêm luật. Chi tiết: `production/qa/soak/2026-10-27/ANALYSIS.md`.
- FLOW trên production: run thường, Continue sau khi tải lại, bỏ run, Echo Box, Daily, Pass, live smoke (mất mạng → RETRY, Continue, Daily). Khách không gọi được API tiền/run.
- Săn chỗ khó hiểu: 39 màn × 2 cỡ, review UX 44 dòng (`production/qa/ux-hunt-review-2026-10-27.md`). Đã sửa hết S2, gần hết S3/S4.
- Lỗi đã sửa và đang chạy: BUG-0001, 0005, 0006, 0007, 0008 (`production/qa/bugs/INDEX.md`).

## Còn mở (biết trước, không chặn polish)
- S4-7: icon riêng cho từng nhóm Lõi. Cần art.
- Màn Pass có hai thanh cuộn ở 1280x720.
- Nhiệm vụ chưa được mua thử trên production: tài khoản web còn 0/5 run hợp lệ theo server. Cần 5 run có thắng trận.
- Đo độ trễ `[epoch_rtt]` trên web chưa có mẫu thật (tester cần mở DevTools → Console).
- Khung cosmetics round 6: chờ zip Claude Design (`design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`).
- Windows chưa kiểm.

## SR-V (server tự replay run, chạy bóng)
- Chỉ GHI NHẬN, không đổi thưởng, kết quả hay leaderboard.
- Runner chạy trên Mac này (`../my-game-wt/verifier`, log `~/.axie-verifier/runner.log`). Mac tắt thì job chờ, không mất. Job chờ quá 14 ngày thì bỏ.
- Xem kết quả: `bash verifier/stats.sh`. Dừng runner: `pkill -f "verifier/runner.sh"` (chỉ tiến trình này). Chạy lại: `cd ../my-game-wt/verifier && nohup bash verifier/runner.sh >> ~/.axie-verifier/runner.log 2>&1 &`.
- Chỉ run kết thúc (thắng/thua) trên client mới mới được chấm. Run của bản cũ hiện là "error/bad_header".
- Điều kiện thôi chạy bóng (README): 0 lệch, ≥ 500 run mỗi nền tảng, ≥ 7 ngày, Liam duyệt chi phí.

## Khi polish
- Mỗi chỗ khựng lại, ghi một dòng vào `production/qa/bugs/liam-notes.md` (màn, thấy gì). Mình biến thành bug.
- Đừng chạy `godot/tools/live_smoke.sh` trên phiên desktop của Liam (lần trước làm phải đăng nhập lại).
