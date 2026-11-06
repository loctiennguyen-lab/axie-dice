# Deploy 6/11: Store và Daily đọc Gem mới, ví không bị câu trả lời cũ ghi đè (Liam: "Sửa luôn", "Deploy luôn")

## Bản đưa lên
- `godot-port` @ **3f5f080**, merge từ `fix/gem-stale` (10e4be4, 5244b06, 40e2306).
- Cùng gốc với lỗi Gem 0 trên Land (deploy 5/11): ví Gem trên server trả lời sau khi màn đã dựng.
  - Store và Daily giờ tải lại ví khi mở và vẽ lại khi ví trả lời.
  - Header các màn meta vốn đã có `UI3Meta.WalletSync` nên không phải sửa.
- `RemoteGemWallet` (`scripts/net`, không phải file luật):
  - `_local_epoch` tăng mỗi lần mua (trừ trước, chờ server) và mỗi lần nhận quà;
  - câu trả lời GET gửi đi trước một lần mua hay nhận quà bị bỏ qua, để số cũ không quay lại;
  - nhận quà mà server không trả số dư (lỗi mạng) thì ví tự tải lại.
- Luật không đổi: RULES_VERSION vẫn `godot-2026-11-03-w`, `t_rules_version` xanh. Worker không đổi, vẫn **bd77027e**.

## Kiểm
- Test mới `t_gem_screen_refresh`. `t_remote_gem_wallet` thêm 2 ca: mua trong lúc đang tải lại, và nhận quà thất bại.
- `t_daily_claim` sửa để chỉ đếm request nhận quà (màn giờ có thêm một GET ví lúc mở), thêm kiểm câu trả lời GET về trễ không xoá +300.
- Suite trên nhánh: 349 qua + `t_rules_version` bỏ qua (worktree). Ở cây chính chạy lại các test ví, Store, Daily, Land và `t_rules_version`: xanh. Sàn 350.
- Review: lead-programmer 2 lượt; góp ý chuyện câu trả lời cũ và lần nhận quà thất bại đã sửa.

## Live
- Web: pck **192333d6abb3ae6d68281945d0aa2c17**, lên ngay lần đầu.
  - html, js, wasm khớp `web/`. Range trả 206.
  - Smoke: vào Land bằng tài khoản Liam, Gem 900, console sạch.
  - Không mở Store và Daily trên site: bấm nhầm có thể nhận quà hoặc mở run trên tài khoản thật. Hai màn này có test tự động phủ.
- Desktop: **b2477 (3f5f080)**.
  - Log build: `check_export_no_override: sạch (1 pck)` cả hai bản, `codesign verify: ok (ad-hoc)`, `PE check: x86_64 ok`.
  - mac `51c8f9abdf4ae8918adc909cb44bcd78c3ed65296fd3dd911f54f256ac2058c0` (298129343 byte).
  - win `203cb467a563028062d0d89089b2c320892d07f906cba7e290b24cf3759da06d` (274551922 byte). Tải về, sha khớp.
  - `/download` hiện b2477 và cả hai sha. b2472 nằm ở `downloads/old/`.

## Rollback
- Web: chép `build/web-prev-d3a7cfbb/index.*` về `web/`, chạy `deploy-r2.sh --pck-only` rồi `--rest`. Worker không cần lùi.
- Desktop: up `build/old/latest-b2472.json` lên `downloads/latest.json` và chép zip b2472 từ `downloads/old/` về gốc `downloads/`.
