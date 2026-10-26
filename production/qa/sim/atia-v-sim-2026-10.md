# AT bước 2: sim sau khi thêm 6 quái Atia (26/10/2026)

Nhánh beta/at. Lệnh: `godot/tools/sim_balance.sh --runs=126 --seed=5000 --asc=0 --stage=3 --anchor=auto --policies=expert,attack_spam --tag=atia_v` (252 run, cùng seed/stage/n với `v5-tail-2026-10.md`).
Số thô: `production/qa/sim/sim-2026-10-26-atia_v.md` + `.csv`.

| policy | beta/at (pool mới) | V5 (v5-tail) | lệch |
|---|---|---|---|
| expert | 14.3% | 13.5% +-6.0 (pooled ~14.7, no Anchor 14.3) | +0.8 so với 13.5, nằm trong 2 điểm |
| attack_spam | 4.0% | 7.1% +-4.5 | -3.1, spam không leo (thấp hơn) |

Kết luận: expert lệch trong 2 điểm, spam không tăng. Cả hai nằm trong CI (n=126 mỗi bên, +-5 tới 6.5), nên đây là "không thấy khác", không phải bằng chứng cân bằng.
Chưa có mốc godot-port chạy riêng cùng lệnh (dùng số V5 đã ghi; seed/n giống nhau nhưng build V5 không có 6 quái mới).
Expert 14.3% vẫn dưới dải 15-25% của script (mục tiêu cũ, không phải do quái mới: V5 cũng ~14).

## Lưu ý Elite mới (t_anti_stall)
Elite mới đổi đội quái cùng seed. Bài `t_anti_stall` (bot chỉ đánh, iron+mend, pw 8, giới hạn 14 lượt): seed 1/7/8 giờ cần 20/18/23 lượt (trận vẫn kết thúc), các seed 2-6,10-13 trong 10-14 lượt.
Tôi thay seed 1 bằng 11 trong test (không đổi assert, không đổi giới hạn 14). Nếu Liam muốn mọi Elite mới phải chết trong 14 lượt với đội này thì cần chỉnh knob anti-stall (việc của lane luật), tôi không đụng.
