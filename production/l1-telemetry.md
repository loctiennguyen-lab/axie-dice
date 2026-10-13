# L1 telemetry — số liệu run + Nhiệm vụ (B4, 13/10)

Server ghi, không cần migration mới (không có 0006). Chạy báo cáo (chỉ đọc, KHÔNG ghi gì):

    cd worker && npx wrangler d1 execute axie-dice-db --remote --file=sql/l1_report.sql

Muốn xem một truy vấn thì copy câu đó vào `--command="..."`. Thêm `--json` nếu cần máy đọc.

## Cột nào lấy từ đâu
- `runs`: mode, ascension, rules_version, state (open/closed/abandoned/infra_error), created_at, closed_at (thời lượng = hiệu), outcome, battles_done.
- `runs.summary_json` (client gửi lúc đóng run, tối đa 2 KB): `v, battles_done, nodes_done, len (short/full), newcomer, client (version), aids[], boon_used, pacts, relics, shards, condition_ok, mission{tier, stake, payout, won}`. Đây là lời khai của client.
- `summary_json.srv.aids` = Aid/Continue server tự thấy trong epoch log (đáng tin hơn `aids`). R1 = Continue.
- `wallet_ledger` (reason `aid:Rx`, delta âm) = Gem thật đã trừ cho Aid/Continue.

## Client khai vs server thấy
- Client khai (có thể sai/gian): `battles_done` (kẹp 0..500), `summary_json.aids`, `newcomer`, `client`, `len`, `nodes_done`, toàn bộ `mission{tier, stake, payout, won}`, `outcome`.
- Server thấy: `summary_json.srv.aids` (epoch log), `wallet_ledger`, mode, ascension, rules_version, created_at/closed_at, state.
- Summary > 2 KB hoặc hỏng được lưu thành `{"truncated":1}` / `{}`.

## Chưa có / giới hạn
- Run bỏ giữa chừng (abandon) không có summary: chỉ biết state/mode/ascension/thời lượng; Aid vẫn thấy qua ledger. Mission bỏ = mất cược, chỉ đếm được số lần.
- Cược/payout Nhiệm vụ là Shard phía client (escrow trong save), server không thấy: số trong báo cáo là client khai. Nhiệm vụ trên Worker chỉ mở khi `ALLOW_GATED_MODES=1`.
- `newcomer` là cờ client; server không lưu riêng. Run cũ (trước bản này) có `battles_done = 0` và summary chỉ `{condition_ok}`, nên chỉ tính số liệu từ bản mới.
- Chưa có Act/floor riêng: dùng `nodes_done` (số node xong) và `battles_done`.
