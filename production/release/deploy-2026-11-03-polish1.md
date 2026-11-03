# Deploy polish 3/11 đợt 1 (Liam: "Deploy ngay")

## Bản đưa lên
- `godot-port` @ **4290521**, merge `int/polish0311` @ 9c05276. Cây `godot/` và `worker/` trùng hệt bản đã chạy gate.
- **RULES_VERSION `godot-2026-11-03-w`:**
  - ô relic cũ / pact không đếm Lõi nữa (`relic_slots.check_add`);
  - sửa lỗi kẹt run khi bán Lõi trong bảng Make room. Lỗi này có trên bản cũ: Lõi được cấp 2 lần và màn chọn Lõi không đóng.
  - Run đang dở của người chơi bị huỷ một lần khi lên bản này.
- **23 mục polish** (`production/polish-0311-list.md`, `production/polish-0311-plan.md`):
  - P1 combat:
    - nút công cụ tắt nói lý do;
    - chip enrage, "Egg die", Boss Rhythm gọn;
    - nhãn trạng thái không bị đẩy lên trên mép màn, ngọc bậc to hơn;
    - **Lõi / Anchor kích hoạt = ô sáng + nổ VFX kỹ năng trên đích + chữ trên đầu, không hạt bay** (Liam chọn).
  - P2 map / thưởng / shop:
    - shop: cột Sell, giá, emblem;
    - Make room / Slot swap / Pact dùng chung một câu "Cores / Relics: N of M";
    - thẻ thưởng gọn hơn, nút "Take <tên>", tên boss xuống dòng;
    - ô Cores trên map, nút Take căn giữa, Take tắt kèm lý do khi thẻ không lấy được.
  - P3:
    - chọn Anchor thu gọn;
    - thẻ Luật run co theo nội dung;
    - event: nút đặt dưới các lựa chọn, tiêu đề;
    - bỏ dòng gợi ý phím trên map.

## Kiểm
- Review độc lập cho từng nhánh: P1+P3, P2, sửa luật, sửa kẹt run. Art-director soát hình. Mọi điểm "nên sửa" đã sửa khi gộp.
- `release_gate --suite` (AXIE_RELEASE=1) cho 342/344.
  - 2 test đỏ chỉ do seed / golden đổi theo -w: `t_run_tamper_v4`, `t_runmap_split_log_golden`.
  - Đã làm mới cả hai (9c05276, giữ nguyên assert). Chạy lẻ ở worktree sạch: xanh, cùng `t_replay` và `t_rules_version`. Mức sàn mới 344.
- Worker 397/397.
- QA luồng thật trên nhánh tích hợp:
  - run ranked seed 59: 7 trận gồm boss, `patched_matches_ui: true`, RunVerifier ok, không anomaly;
  - 2 run có Anchor thua ở trận 3 vì seed đổi, nên chưa đi tới shop / Make room / boss. Các phần đó chỉ có test tự động phủ.
  - `patched_matches_ui:false` của run Anchor là bình thường (run không ranked thì không verify).

## Live
- Worker: **ae8f917a-c774-4952-bd91-b9ee59377c4f**. Bản trước ed4c90bb (ghi ở `build/web-prev/WORKER_VERSION.txt`).
- Web: pck **a7ef2613882fdeaaa6779728a2794e02** (373014144 byte). html 81f60b0a, js e923d4fb, wasm 8b163661, icon, favicon đều khớp local. Range trả 206. Bước `--rest` lên ngay lần đầu.
- Desktop: **b2435 (4290521)**, mac sha `b1c804de…`, win sha `e19d484b…`. `/download` hiện b2435, sha zip Windows khớp. Manifest b2385 lưu ở `build/old/latest-b2385.json`.
- Smoke trên site:
  - vào Land, API me / wallet / econ / save / daily đều 200, console không lỗi;
  - nút đổi từ "Continue run" thành "Start run": run dở bị huỷ, đúng như dự kiến khi đổi luật.

## Rollback
- Worker: `cd worker && npx wrangler@4.151.3 rollback ed4c90bb-8c01-4c51-92c4-5202e4e5f3b6`.
- Web: chép `build/web-prev/index.*` (pck 7ec48c9a) về `web/`, rồi chạy `deploy-r2.sh --pck-only` và `--rest`.
  - Phải lùi cả Worker và web cùng lúc, vì web cũ gửi log -v. Worker mới vẫn nhận -v, nên lùi web không cần lùi Worker.
- Desktop: up `build/old/latest-b2385.json` lên `downloads/latest.json`; zip b2385 nằm ở `downloads/old/`.
