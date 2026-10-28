# Việc để làm SAU polish (Liam 28/10)

Liam: "những việc còn đang dở, note lại để làm sau, sau khi xong polish. Việc nào làm luôn không ảnh hưởng gì thì làm song song."

## A. Đang làm song song, không ảnh hưởng polish (28/10)
- [ ] Báo cáo QA cuối `production/qa/beta-qa-report.md` (qa-lead đang viết).
- [ ] Kiểm Pass mùa 1 bắt đầu đúng 3/11 bằng test giả giờ (qa-tester, không deploy).
- [ ] Sửa `live_smoke` để không bao giờ làm app desktop phải đăng nhập lại (tools, không deploy).
- [x] Soak 28/10 trên bản mới nhất: 27.069 run, 0 crash, 0 lệch replay, 3 run kẹt bỏ qua replay (`production/qa/soak/2026-10-28/SUMMARY.md`).

## B. Để sau polish

### QA còn thiếu trên production
- Mua Nhiệm vụ thật: N1 thắng/thua, trừ cược, trả tiền, N2 mở. Bị chặn vì tài khoản web của Liam còn 0/5 run hợp lệ theo server. Cần tài khoản QA phụ, hoặc chơi 5 run có thắng trận và kết thúc.
- Windows: cài bản desktop và chơi thử. Chưa ai làm.
- Đăng nhập máy thứ hai giữa run, rút mạng giữa lượt (làm tay).
- Hoàn cược Nhiệm vụ khi bump RULES_VERSION: chỉ thử được ở lần bump tới.
- RTT `[epoch_rtt]`: ≥ 100 mẫu mỗi nền tảng từ tester thật → Liam chốt giữ PB hay chuyển PA.

### SR-V (verifier chạy bóng)
- Theo dõi `bash verifier/stats.sh`. Thoát chạy bóng khi đủ: 0 lệch, ≥ 500 run mỗi nền tảng, ≥ 7 ngày. Chi phí do Liam duyệt.
- Chuyển runner khỏi Mac của Liam (VPS hoặc Cloudflare Containers).
- Sau đó mới cho verifier được từ chối hay trả thưởng. Khi đó đóng luôn các lỗ hổng đã chấp nhận:
  - Thưởng run và Pass tuần dựa vào số liệu do client báo.
  - Kết quả thắng Nhiệm vụ do client báo.
  - Điểm Land do client tính.

### Nội dung / thiết kế
- UI-04 round 2 (gửi Claude Design: `design/handoffs/ui-04-polish/round-1/PROMPT-ROUND-1-FIXES.md` mục 3):
  - Daily, Profile, Codex, Settings.
  - Chọn thưởng, Event/Treasure.
  - Màn thua thường và màn thua Nhiệm vụ.
  - Hộp xác nhận mua Nhiệm vụ, hộp "Open 10".
  - Tutorial, giới thiệu boss.
- Khung cosmetics round 6: chờ zip Claude Design (`design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`).
- S4-7: icon riêng cho từng nhóm Lõi (cần art).
- Liam quyết: N6 có cần thêm "thắng một run Full" như kế hoạch beta không (phải đổi luật + Worker).

### Phát hành / vận hành
- Notarize bản Mac (cần tài khoản Apple Developer của Liam), ký bản Windows.
- Tài khoản QA phụ (Liam đồng ý).
- App desktop và web của Liam đang là hai tài khoản Google khác nhau. Chọn một để test.

### Nợ kỹ thuật
- Khoảng 126 màu ghi cứng (phần lớn là màu cảnh 3D, cần token mới) và 73 tween chưa qua `UI3Motion` (danh sách ở `design/handoffs/ui-04-polish/token-audit.md`).
- Reduce motion: còn vài hiệu ứng chưa tắt theo cài đặt:
  - Nhân vật lao lên và trượt trong trận.
  - Spinner.
  - Lật thẻ gacha.
  - Phóng to khi rê chuột trên Land.
- Store / tiền thật: tạm bỏ theo quyết định của Liam.
- Đo thời gian khung hình trên máy yếu cho lớp chỉnh màu web (sửa chói Savannah).
