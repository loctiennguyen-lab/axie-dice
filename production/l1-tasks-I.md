# Làn I — nợ và việc còn mở (L1)

Cập nhật 12/10, sau merge A PR1 (3220402) + B (6ae29ef) và bump `RULES_VERSION = godot-2026-10-12-a`.

## Nợ phải trả trước khi bật remote

1. **Combat resume mất epoch.** Lưu và tải lại giữa trận không mang theo epoch. Làn A thêm `CombatEngine.set_epoch(...)`; làn U gọi nó sau `CombatEngine.from_data(...)`. BẮT BUỘC xong trước khi bật nguồn epoch remote. Chưa có thì trận được tiếp tục sẽ rút seed sai nguồn.
2. **`t_full_run_loop` giảm từ 209 xuống 177 check.** Chưa rõ vì sao. Làn A phải xác nhận là cố ý (bỏ check lặp do đổi sang epoch) và không mất phủ luật. Chưa xác nhận thì coi là nợ.
3. **Verifier Local không dùng để chấm leaderboard thật.** `LocalEpochSource` rút seed từ `randi()` của máy người chơi, nên replay Local chỉ chứng minh log nhất quán, không chứng minh người chơi không chọn seed. Chấm điểm thật chỉ qua verifier theo tape do server cấp seed.

## Nợ nhỏ

4. **`randi()` tự do trong `RunState.begin_run`** (chọn `local_secret` của `LocalEpochSource`). Hiện không có test `t_no_free_rng` nào để cho phép riêng dòng này; nếu thêm test đó, phải ghi ngoại lệ đúng dòng này và không cho nơi khác.
5. **Fingerprint** giờ phủ `scripts/core`, `autoload`, `resources/relics` (`*.tres`, gồm `relic_tuning.tres`), `assets/data/rules` (`*.json`, thư mục chưa có), đệ quy. Làn thêm file luật ở chỗ khác thì báo làn I thêm vào `WATCHED_DIRS`.
6. **Khoá Godot:** mỗi worktree có user dir + khoá riêng (override.cfg); chỉ cây chính dùng khoá chung. Suite ở cây chính vẫn phải xếp hàng sau các lần chạy lẻ trong cây chính, và có lúc chờ rất lâu.

## Sau merge E (12/10, RULES_VERSION -> godot-2026-10-12-b)

7. ~~Verifier chưa đọc loadout từ header~~ — ĐÃ XONG (A PR2): verifier đọc `header.loadout`, có `t_replay_loadout`. Bump `-b` vẫn đúng vì cùng actions + seed cho run khác.
8. Fingerprint giờ phủ thêm `scripts/meta/` (Aid catalog ảnh hưởng combat). `assets/data/economy/*.json` chưa phủ (ví/Pass, không đổi kết quả run); nếu Aid hoặc luật đọc dữ liệu từ đó thì phải thêm.

## Sau merge A PR2 (12/10, RULES_VERSION -> godot-2026-10-12-c)

9. `t_mon13` là quét văn bản (cấm `aid_*`, `continue_used`, `boon_used` trong `scripts/core`; `boon_id` chỉ trong `_reward_count`). Hiện `_reward_count` chưa có trong `scripts/core` nên `boon_id` bị cấm hẳn; khi làn B/A thêm hàm đó thì ngoại lệ có hiệu lực. Chưa chạy thử đột biến (thêm dòng vi phạm để xem test đỏ).
10. Hook H1-H8 đang rỗng; khi B nối thân relic vào hook thì cần bump lại (nếu đổi kết quả run) hoặc cập nhật fingerprint.

## Sau merge S (12/10, RULES_VERSION vẫn -c, chỉ cập nhật FINGERPRINT)

11. **Trước deploy Worker (Liam/devops làm, tôi không deploy):**
    - Áp migration D1 `0002_runs.sql`, `0003_wallet.sql`, `0004_desktop_auth.sql` lên `axie-dice-db` (`wrangler d1 migrations apply`).
    - `cd worker && npx wrangler secret put RUN_TOKEN_KEY` (chỉ đặt bằng wrangler secret, không ghi vào code).
    - Thêm redirect URI cho login desktop vào Google OAuth console, nếu luồng desktop dùng Google (kiểm với làn S).
    - Worker test phải 121/121 trước khi deploy.
12. **`RemoteGemWallet` và `RemoteEpochSource` chưa được nối.** Cờ remote đang tắt; client vẫn chạy `LocalGemWallet` + `LocalEpochSource`. Bật remote cần: nợ #1 (combat resume `set_epoch`, đã có từ PR2 nhưng U phải gọi) và quyết định cờ cho Gem server.
