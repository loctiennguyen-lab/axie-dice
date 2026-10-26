# Review SR0 (Server RNG B0) - security-engineer, 26/10/2026

Nhánh `beta/sr0` (ce496a1 + commit client), so với `godot-port`. Không sửa gì, không deploy.
Chạy: Worker `node --test test/*.test.mjs` = 245/245; Godot `t_run_session_race` = PASS (11 checks).

## Verdict: APPROVE WITH CHANGES (không có mục CHẶN; 3 mục NÊN SỬA, 1 trong đó nên làm trước R0)

## 1. run_close chỉ-ghi: ĐẠT
- `run_core.js:515-519`: `closeSanity()` chạy SAU khi `UPDATE meta SET state='closed', outcome=...` và nằm trong `try/catch` rỗng. Reply `{t:'closed'}` không đổi. Lỗi sanity (JSON hỏng, SQL, `_anomaly` ném) không chặn được close.
- `run_do.js:158-159`: lần gọi thứ hai cũng trong `try/catch`; `srv.sanity` chỉ thêm vào `merged`. `outcome` ghi vào D1 lấy từ `meta.outcome`, không đụng. `settleEscrow` vẫn dùng outcome gốc. Thưởng/mở bậc không đọc `srv.sanity`. Đúng cam kết "không đổi won, không giữ thưởng".
- Dữ liệu ghi: cờ, đếm, giây, final_row, map_mode, boss. Không có token, email, seed, `s_run`. Log `close_sanity` có `run_id` + số (run_id không phải bí mật, cùng loại với các anomaly khác). Không lộ gì nhạy cảm. Chú ý: `srv.sanity` nằm trong `summary_json` mà client có thể đọc lại nếu có API trả summary; hiện tôi không thấy API nào trả, nên giữ nguyên, nhưng khi làm B3 đừng trả `srv` về client (lộ ngưỡng cho kẻ gian).
- Ngưỡng (short 18 hàng: >=9 node, log>=36, >=108 s; full 30 hàng): hợp lý cho "tạo run rồi đóng thắng ngay". Run thật đi đủ 18 enter_node, nên ngưỡng 50% dư an toàn, ít dương tính giả. `map_mode` lấy từ `run_start.args.mode` (client gửi `short|full`, khớp `RunState.gd:768`), đã kiểm.
- NÊN SỬA (nhẹ) `run_core.js:30-31 / 550`: bypass tầm thường là tạo run, đợi 108 s, gửi 18 `enter_node` + `end_turn` giả (chuỗi hash do client tự tính, rate limit 20 burst + 5/s cho phép). Kiểm này chỉ bắt kẻ lười. Ghi rõ vào doc/ plan là "soi lười", đừng gọi là chặn thắng giả; verifier (SR-V) mới là thứ chặn thật. Ngoài ra thêm cột/đếm để sau chọn ngưỡng: số run `won` có `fails` khác rỗng / tổng won.
- NICE: test chưa có ca "closeSanity ném lỗi nhưng close vẫn ok" (nhánh catch). Thêm 1 test stub `closeSanity` ném.

## 2. helloAllowed cần login sống: ĐẠT, có 2 rủi ro cần biết
- Truy vấn dùng đúng cột (`sessions.player_id/expires_at`, `device_sessions.player_id/revoked`); test chạy trên schema migration thật (0001/0002/0004/0005/0009), không phải mock. Tốt.
- Desktop: `helloAllowed` chỉ xét `device_sessions.revoked = 0`, không xét `device_tokens.expires_at` (access token ngắn hạn). Refresh token xoay vòng không làm `revoked`, trừ khi phát hiện dùng lại refresh cũ (`desktop_auth.js:116,127`) - lúc đó thu hồi là chủ ý. Run desktop hợp lệ không bị hỏng. Đạt.
- Khách/guest: `runs.js:2-3,207` chưa cho khách tạo run (401), nên không có run khách nào để hỏng. Đạt. Khi SR1/ADR C3 thêm khách phải xét lại (`is_guest` không có dòng sessions).
- Hết hạn giữa run: `SESSION_TTL_S` = 30 ngày cố định (`accounts.js:29`), run token 2 h. Chỉ run nằm đúng lúc cookie hết hạn bị đá. Khi đó hello 1008 'auth' -> client `_refresh_token()` gọi `/api/run/open` cũng 401 -> `_fail_all("expired")` + run đóng (`run_session.gd:227-246`). TRƯỚC SR0 run này vẫn chơi tiếp được tới 2 h. Hành vi mới chấp nhận được (thiệt hại: mất run đang chơi của người cookie vừa hết hạn; mission có escrow thì hoàn qua abandon/sweep). NÊN SỬA: ghi vào ghi chú R0 và QA thật bằng tài khoản Liam: (a) web, đăng xuất ở tab khác giữa run, (b) desktop, thu hồi thiết bị, (c) xoá bản ghi `sessions` thủ công để xem run mất gì và người chơi thấy thông báo gì ("expired" có chữ rõ không).
- NÊN SỬA (độ mạnh, không phải lỗi): điều kiện là "người chơi còn BẤT KỲ login nào" (`EXISTS ... player_id`), chưa ràng đúng session đã đúc token (code tự ghi chú, cần claim `sid` ở `runs.js`, file của N-W). Hệ quả: đăng xuất ở máy A khi máy B còn login thì token bị đánh cắp vẫn dùng được. Lợi ích bảo mật thực của thay đổi này là hẹp; vẫn tốt hơn trước, nhưng đừng viết "ràng token vào session" là xong. Giữ TODO `sid` cho lần sau (sau N-W).
- Chi phí: thêm 2 EXISTS vào mỗi hello (D1 đọc, có index `device_sessions_by_player`; `sessions` theo `player_id` cần kiểm có index). NICE: kiểm `sessions` có index theo `player_id`; nếu không, hello thành scan khi bảng lớn.

## 3. Khoá input CombatView: không kẹt vĩnh viễn
- Khoá = `_combat.epoch_pending` (`combat_engine.gd:853-885`), nhả khi `await r.resolved` xong. Mọi đường đều settle có hạn: `RunSession._age_requests` 8 s x3 lần -> "timeout"; queue >30 s -> "offline"; `reconnect()` 20 s -> "offline"; kick/bye/1008 -> `_fail_all`. Seed lỗi cũng trả `{ok:false}` và hạ cờ. Không thấy chỗ kẹt vĩnh viễn trong code SR0.
- Sáu guard mới (`CombatView.gd:1304,1318,2721,2808,3140,4729`) chỉ `return` sớm, không giữ trạng thái nên không thể tự kẹt. Chúng đứng TRƯỚC `_land_dice_now()` nên xúc xắc đang bay không bị gọi hạ sớm trong lúc chờ: chấp nhận được.
- NÊN SỬA: `t_run_session_race` chỉ test `CombatEngine.request_*` trả "busy" (hành vi đã có sẵn trước SR0), KHÔNG chạy `CombatView` nên 6 guard mới không có test nào. Cần ít nhất 1 test dựng CombatView với nguồn seed chậm, bấm die/target/undo/hold/overcast khi `epoch_pending`, xác nhận log không đổi, và sau settle (cả nhánh fail `offline`) nút nhận lại. Hoặc grep test đơn giản đảm bảo mọi `_on_*_pressed` đổi trạng thái đều có guard.
- NICE: nút END TURN/Reroll/Continue chỉ dựa vào `epoch_pending` + UI xám; khi "offline" hiện thông báo gì thì chưa kiểm ở đây (ngoài phạm vi, QA thật).

## 4. Test có kiểm thật?
- Worker `run_close_sanity.test.mjs`: chạy RunCore thật trên SQLite thật qua `epoch_req`/`run_close`, kiểm cả won-nhanh bị đánh dấu, thua không bị phạt, outcome không đổi; helloAllowed dùng SQL migration thật. Có giá trị.
- Godot: xem mục 3, kiểm engine chứ không kiểm view. `t_run_session_race` sẽ vẫn PASS dù xoá hết 6 guard: test không chứng minh thay đổi của commit client.
- RTT (`production/qa/rtt-vn-2026-10.md`): đo HTTP chứ không phải WS/DO, p95 780-1860 ms. Báo Liam đúng; không phải mục bảo mật.

## Tóm tắt việc cần làm trước R0
1. (NÊN) Thêm test CombatView cho 6 guard, hoặc ghi rõ chưa có và nhờ QA thật.
2. (NÊN) QA thật 3 tình huống mất login giữa run, ghi kết quả vào R0.
3. (NÊN) Sửa lời mô tả: kiểm close = "soi lười", token = "cần có một login sống", chưa ràng đúng session.
