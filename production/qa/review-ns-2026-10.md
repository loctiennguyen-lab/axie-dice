# Review làn N-S (tool sim Nhiệm vụ), 26/10/2026

Reviewer độc lập: lead-programmer. Nhánh `beta/ns` (de7f21e, 10e5d4c). Chạy lẻ `t_sim_mission_args`: PASS (phải chờ khoá, run_tests của làn đang chạy). Không chạy sim lớn.

**Verdict: APPROVE WITH CHANGES.** Cơ chế sim đúng, nhưng bảng bậc cứng là rủi ro số 1 vì Liam khoá số theo tool này.

## Đúng
- Header run: `_play_run` truyền `kind=mission`, `mission{rules,tier}`, `ascension` giống `MissionsScreen.mission_params` (thiếu stake/m_* nhưng không ảnh hưởng chiến đấu). `ContentDB.mission_mods(rules, asc)` đọc header nên `standard` + M áp đúng. Test kiểm `RunState.ascension/mission_rules()/mode/run_kind`.
- Anchor: sim mission không Anchor là ĐÚNG (`RunState.gd:2537` kind != normal -> "kind"). `--anchor=auto` mặc định trong mission mode chỉ bật `anchor_wanted`, gate vẫn chặn, kết quả không đổi (test kiểm `anchor==""`).
- Seed: seed+i, team/core theo i, giống nhau mọi cấu hình; test kiểm x[0].seed==x[2].seed và lặp lại cho record y hệt.
- Wilson (`sim_report.gd` wilson) đúng công thức; test 0/4 và 50/100 khớp. SE cặp = sqrt((E[d²]-d̄²)/(n-1)) đúng.
- Lệnh cũ: không có --mission/--rules thì `configs=[]`, đi nhánh cũ (asc list, `_anchor_mode`/`_stage` giữ như `_ready`, `cfg` rỗng, header không thêm kind/mission). `--force_run_rule` rỗng thì nhánh cũ nguyên vẹn. CSV đọc lại được file cũ (`c.size() >= ai+8`).

## Phải sửa
1. **LADDER lệch game thật** (`sim_balance.gd:64`). Bảng cứng theo brainstorm: N1=A0, N2=A1, N3=A3... Còn `missions.json` hiện tại (L1): N1=A3, N2=A4, N3=A6, và `rule_sets` có biến thể A/B theo ngày (`MissionBoard.rule_set_key`). Tên "N3" trong sim hiện KHÔNG phải N3 của game; khi N-C ghi bảng mới sẽ lệch âm thầm. Đề xuất: (a) sim đọc `tiers[N].{mode,ascension}` + `rule_sets[N][A|B]` từ `ContentDB`/`_Econ.get_table("missions")` khi tier có đủ `rules`/`rule_sets`; thêm `--variant=A|B`. (b) LADDER chỉ là dự phòng, nhãn đổi thành `N3(bs)` và báo cáo ghi dòng "nguồn bảng: missions.json | brainstorm". (c) test so cấu hình sim với `MissionBoard.offers()` cho các tier enabled, đỏ khi lệch.
2. **Báo cáo không ghi nguồn bảng và việc Anchor bị chặn.** Thêm vào header .md: nguồn bảng, `kind`, "Anchor: không (RunState gate kind)". `--anchor=<id>` ép trong mission kind bị bỏ qua không báo: nên cảnh báo/lỗi (`sim_balance.gd:187`).
3. **CI cặp khi n nhỏ / ít cặp lệch** (`sim_report.gd:627-628`): a_only+b_only=0 cho SE=0, CI rộng 0 (sai trực quan). Dùng Wilson/Newcombe cho hiệu cặp hoặc in "n lệch < 10: chỉ tham khảo". Ghi chú: RNG hai cấu hình tách nhau sau trận đầu nên "cặp theo seed" chủ yếu khớp team/core; vẫn hợp lệ nhưng mạnh hơn không nhiều so với so độc lập.
4. Khoá ô `cell[cfg|policy][seed]` (`sim_report.gd:579`) chỉ theo seed: gộp `--from` của hai lô trùng seed (khác team/core) sẽ đè nhau mất run. Thêm team+core vào khoá hoặc báo trùng.

## Nhỏ
- `--mode=full` không kèm --mission/--rules bị bỏ qua âm thầm (không đổi so với trước, nhưng nên báo).
- `--force_run_rule` không tiêu rng bot nên dòng rng của run khác run thường (chấp nhận được, ghi vào doc).
- Test: kiểm thật header, seed, determinism, force rule (có lỗi push_error mong đợi trong stdout, gây nhiễu log). Chưa kiểm mod thật vào trận (vd boss_hp x1.25 trong combat setup) và chưa kiểm LADDER vs missions.json (mục 1c).

## Throughput (`production/qa/sim/mission-sim-throughput.md`)
10 run/cấu hình, bot `expert` chết sớm nên giây/run phụ thuộc cấu hình (A6 0,8s vs A0 1,3s), máy có Godot khác chạy chung. Không đủ để hứa 30-50k run. Đo lại: máy rảnh, 1 lệnh chạy cả N1..N6 (dùng bảng thật), >=50 run/bậc (Full >=30), 3 lần lặp lấy trung vị, tách thời gian khởi động, ghi chính sách + tỉ lệ thắng (thời gian run theo độ sâu bot đạt). Full A0 hiện chỉ đoán.

## Vòng 2 (44651cc): APPROVE
Chạy lẻ `t_sim_mission_args`: PASS.
- Mục 1: sim đọc `tiers[N].{mode,ascension,rules}` từ missions.json khi tier có mảng `rules`, không thì dùng LADDER với nhãn `N3(bs)` + cột `src`; báo cáo ghi nguồn bảng, kind, Anchor bị chặn. Test dùng bảng giả (`_table`) cho cả hai dạng.
- Mục 2: cảnh báo `--anchor=<id>` trong mission kind (in + push_warning). Khoá gộp seed|team|core(+#n) không còn đè. CI cặp có sàn +1 cặp lệch và ghi chú "it lech < 10".
- Test mới kiểm mod vào trận (HP boss x1.25 / normal x1.2 trong combat setup, mission_rules trong setup).
Còn lại (không chặn): missions.json hiện tại chưa có `rules` nên mọi bậc vẫn ra `(bs)` cho tới khi N-C ghi bảng; trước khi Liam khoá số phải thấy `src=missions.json` trong báo cáo. Dạng `rule_sets` A/B chưa có `--variant`: nếu N-C giữ dạng đó, thêm cờ hoặc ghi rõ cách chọn.
