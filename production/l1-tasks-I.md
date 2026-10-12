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
