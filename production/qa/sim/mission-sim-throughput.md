# Mission sim: run/giờ (N-S, 26/10/2026)

Đo: 1 process, policy `expert`, `--anchor=auto`, 10 run mỗi cấu hình, máy của Liam (có Godot editor/tool khác chạy chung nên số có thể lệch). Lệnh: `godot/tools/sim_balance.sh --runs=10 --policies=expert --anchor=auto --asc=N [--mode=full]`.

| Cấu hình | giây/run (trong sim) | run/giờ | ghi chú |
|---|---|---|---|
| Short A0 | 1,26 | ~2.850 | có run thắng nên dài hơn |
| Short A6 | 0,81 | ~4.400 | bot chết sớm |
| Full A6 | 0,82 | ~4.400 | bot cũng chết sớm; **không đại diện** cho Full A0 / N6 khi sống lâu |

Chưa tính ~5 s khởi động + import mỗi lệnh (chia lô >= 300 run thì không đáng kể).

Cảnh báo: n = 10 là quá nhỏ, chỉ cho bậc độ lớn. Full chưa đo ở A0 (run dài hơn nhiều; đoán 2-3 lần Short, tức ~1.000-1.500 run/giờ). Cần đo lại với 30-50 run Full A0 trước khi hứa tiến độ cho bước 0.

## Ước tính cho bước 0-2 (khối lượng của beta-plan: ~30-50k run)
Giả sử trung bình ~3.000 run/giờ (hỗn hợp Short, Full chiếm ít): **10-17 giờ chạy một process**. Nếu Full A0/A6 chiếm 5k run ở ~1.200/giờ thì cộng thêm ~4 giờ.
Đề xuất: **4 worktree sim** (`ns-sim1..4`, mỗi cái có override.cfg và khóa riêng, chạy song song) => ~4-6 giờ tường cho bước 0-2 lần đầu, chưa tính vòng chỉnh. Số lõi CPU máy: xem dòng dưới; nếu < 6 lõi thì dừng ở 3 worktree để không làm chậm lẫn nhau. Chia lô mỗi lệnh <= 600 s (HANG_KILL 900), tức ~300 run Short A0 hoặc ~150 run Full mỗi lệnh; gộp bằng `--from=a.csv,b.csv`.
Mọi cấu hình dùng chung `--seed` + danh sách seed để so cặp; khi chia lô, lô k dùng `--seed=1000+k*N` rồi gộp, và giữ cùng bảng seed giữa các bậc.
Số lõi: 12
