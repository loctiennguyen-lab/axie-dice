# QA luồng thật UI-05 đợt 2+3 (u5b-qa @ dedd7a6) — BẢN DỞ, cập nhật dần

Trạng thái: phần 1 (chụp) xong, phần xem ảnh CHƯA làm, nên chưa có lỗi nào được xác nhận bằng mắt. Không có "OK" nào dưới đây là OK về mặt hình ảnh.

## Đã chạy
- Import sạch (0 Parse Error / SCRIPT ERROR).
- 33 scene capture `qa_ui5_*_capture` chạy ở cửa sổ thật (không headless) 1920x1080 và 1280x720: tất cả rc=0, 0 SCRIPT ERROR, 0 dòng QA_CLIP/QA_ANOMALY. Ảnh: `production/qa/ui05-b23/qa/{1920,1280}/<scene>/` (330 ảnh mỗi cỡ, `_run.log` cạnh ảnh). Capture ghi thêm bản `--1280` ngay trong thư mục 1920 (tự ghim scale).
- `t_soak_verify`: PASS 24 checks (`qa/t_soak_verify.log`).
- Luồng cả run qua UI (`qa_ui5_flow_capture`: win/free/paid/boost/reduce motion): chạy nền, kết quả ở `qa/flows/_summary.txt` (chưa đọc).
- `soak_matrix.sh run` bản giảm (N_FAST=3, N_EXPERT=2, ngày 2026-10-31-ui5b23): chạy nền, chưa report.

## Chưa kiểm được / lỗi của chính capture
- `qa_ui5_anchor_capture` và `qa_ui5_codex_capture` KHÔNG ghi vào thư mục đã truyền (ghi cứng vào `r3/` và `s13/`); đã chép ảnh sang `qa/anchor/`, `qa/codex/`. Ghi lại để làn sửa.
- Không có capture riêng cho Land HUD chính (chỉ overlay first-visit/offline), Settings reduce-motion đi moment, đăng nhập thật (cần Liam), `live_smoke` (cấm).
- `qa_real_flow_capture` chỉ là chụp 1 trận combat, không phải luồng nhiều màn.

## Lỗi
Chưa có (chưa xem ảnh).
