# Deploy 6/11: 3 icon (pact, boss-clock, spike) (Liam: "Deploy ngay sau khi chọn được spike từ kho asset")

## Bản đưa lên
- `godot-port` @ **658afc3**.
- Pact: `HudKit.icon("pact")` → lá bài trăng `ui_mooncard`. Đã xoá `hl/pact*`. Bảng Aid UI-05 không vẽ icon ở từng dòng, nên trong game icon này hầu như không lộ ra.
- Boss-clock: HudKit ghép đồng hồ cũ lên đĩa `plate_ink` có viền `plate_rim`, tạo khi chạy và cache theo từng cỡ. Chỗ thấy được: dòng ENRAGE ở dải boss, Boss Rhythm. Kim vẫn mảnh.
- Spike: lấy `s17b` trong kho (cụm pha lê hồng), không đợi Claude Design. Cắt ra 128 / 64 / 32. Nằm trên chip cam "BIG HIT IN n", khác mũi tên lethal đỏ chỉ xuống. `PROMPT-batch5-spike.md` không dùng nữa.
- Luật không đổi (-w), Worker không đổi (bd77027e).

## Kiểm
- Suite trên nhánh (pact / boss-clock): 349 + `t_rules_version` bỏ qua. Lead-programmer review, góp ý đã sửa.
- Spike: chạy `t_art_batch34d`, `t_ui5_enemy_column`, `t_assets`, `t_rules_version`, đều xanh. Ảnh `production/qa/icons-0611/spike-tab-1920x1080.png`.
- Spike chọn bằng dải so sánh trên nền chip, chưa qua art-director (Liam cho dùng art gần giống).

## Live
- Web: pck **02fe988a21f24cbcb01c31ac588d3b02**. html / js / wasm khớp, Range 206. Smoke trên trình duyệt: tải chậm, chưa vào tới Land thì tôi dừng (quy tắc tiết kiệm token mới).
- Desktop: **b2484 (658afc3)**.
  - mac `d29fb9729f8088581e9fbc7874d168c73b96a03dd6b6572ed04db2a699efa1e3` (298113357 byte).
  - win `082cf733321ac997ae6f5a83619d27cf974eb647172914cd98ad9fa509f5e8a2` (274541106 byte). Sha tải về khớp.
  - b2477 ở `downloads/old/`.

## Rollback
- Web: `build/web-prev-192333d6/index.*` → `web/`, rồi chạy `deploy-r2.sh --pck-only`, sau đó `--rest`.
- Desktop: up `build/old/latest-b2477.json` lên `downloads/latest.json`, chép zip b2477 từ `downloads/old/` về gốc `downloads/`.
