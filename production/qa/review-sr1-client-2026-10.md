# Review SR1 client (beta/sr1 f9038bb..dbc8065) — 26/10/2026

Reviewer: lead-programmer (độc lập). Chỉ đọc code, không chạy Godot. Không đọc hết 25 file; tập trung autoload + RemoteEcon + 4 test mới.

**Verdict: CẦN SỬA (1 CHẶN trước khi bật cờ, 4 NÊN SỬA).** Cấu trúc đúng hướng: cache + strip khỏi cloud save + wipe hoãn đều có, chỉ là cờ chưa bật và vài lỗ hổng nhỏ.

## CHẶN
1. `godot/project.godot:40-44` chỉ có `epoch_source="remote"` và `gem_wallet="remote"`, KHÔNG có `axie/econ`. Bản release vì vậy `econ_flag_on()` = false: không ai gắn RemoteEcon, `guest_no_wallet` luôn false, khách vẫn có ví local, mọi đường cộng/trừ local vẫn chạy. Toàn bộ SR1 client đang tắt trong build thật. Nếu là cố ý (chờ Worker deploy) thì ghi vào beta-plan và đặt `econ="remote"` cùng commit deploy. Test chạy xanh cũng không chứng minh được gì về build release vì đều bật cờ bằng tay.

## NÊN SỬA
2. `AccountService.gd:431-441` (`_apply_server`): chỉ giữ SERVER_FIELDS của máy, còn `econ_reset_seen` lấy từ cloud save. Cloud cũ (""/id cũ) về sau wipe sẽ (a) khôi phục lịch sử run/stat cũ ngay sau khi vừa wipe, (b) đặt lại `econ_reset_seen` cũ, nên lần /api/econ kế tiếp lại wipe một lần nữa, mất những gì chơi xen giữa. Không lặp vô hạn (wipe rồi save_to_disk ghi lại id, upload đè cloud) nhưng có thể wipe hai lần, và /api/me chạy song song /api/save nên race này có thật. Đề xuất: giữ `econ_reset_seen` của máy như SERVER_FIELDS (hoặc lấy giá trị lớn hơn), và chặn `_apply_server` trong lúc `_pending_reset` còn đó. Test `t_reset_m1_cloud` không có ca này.
3. `MetaState.gd:326-336` (`wipe_for_server_reset`): `reload_from_store` -> `_apply_starter_if_needed` cộng starter local (shard, ticket, `starter_shard_locked`, gems_cache) trước khi snap ghi đè. Shard/stone/ticket được ghi đè lại đúng, nhưng `starter_shard_locked` và `gems_cache` còn từ starter local. Đặt `starter_granted=true` trước khi reload, hoặc cho snap ghi đè `starter_shard_locked`.
4. `RunState.gd:1142-1151` + `MetaState.gd:341-351`: claim "run" là fire-and-forget. Offline lúc hết run thì mất Shard của run, không retry, không báo người chơi. Trong khi đó local `add_shards(...,"earn")` đã bị chặn. Nên gói vào hàng chờ lưu qua SaveStore (run_id + amount) và gửi lại khi refresh thành công, hoặc ít nhất báo "chưa nhận được thưởng".
5. Test cổng B4 yếu: `t_offline_removed.gd` bỏ nhánh `begin_run` refuse khi NO_NET, và `online_required()` luôn false khi NO_NET nên assert `gate_reason()=="offline"` bị bỏ qua dưới runner (runner đặt cờ này). Thực tế không test gì về cổng, Try again (`service.check()` gọi lại có hiệu lực không), hay mất mạng giữa chừng. Cần test dùng `online_required_override` + `NetGuard` giả, và test `MainMenu._on_account_changed` mở cổng khi `/api/me` trả 200. Cũng chưa có test khách vào được tutorial + run thường (t_guest_no_wallet chỉ test cờ ví).

## Ghi nhận (không chặn, làn khác đang làm)
- Còn cộng/trừ local khi cờ bật (chỉ `reason=="earn"` bị chặn trong `add_shards`; `add_stone` không có guard `_econ`): mission_win `MetaState.gd:629,647,672-675,692`, bet `:593`, battle pass `:1390`, `pass_v2.gd:134-179`, weekly daily `:1820`, `land_decor.gd:85`, `mission_board.gd:179`, `echo_box.gd` tab seasonal (EchoBoxScreen vẫn local khi `tab=="seasonal"`). Hiệu ứng: hiển thị sai đến lần refresh kế, chưa tới mức mint trên D1 vì push đã strip. Cần chuyển hoặc chặn hết khi `_econ != null`.
- Shop Gem và Aid trừ qua `spend("gem")` đi ví Gem remote, không đụng Shard.
- Cổng offline chỉ kiểm lúc mở menu; mất mạng giữa run/ở Land không có gì chặn ngoài lỗi từng request. `AXIE_TEST_NO_NET=1` đặt trên desktop thì bỏ qua cổng (begin_run vẫn dùng nguồn remote vì project.godot nên không rơi về LocalEpochSource).

## Đã đúng
- B4: `allow_local_epoch` là biến thường, không đọc từ cấu hình/URL nên release không bật được; `begin_run` trả `offline_removed` khi cờ remote tắt.
- Cloud save: PUT strip SERVER_FIELDS, GET không đè số dư (chỉ lệch ở mục 2). Mọi ghi qua SaveStore.
- `econ_reset_seen` có trong save_to_disk, `_economy_from_json`, `_reset_economy_fields`. Wipe hoãn đúng khi `RunState.phase != MENU`, chạy trong `RunState.reset()`.
