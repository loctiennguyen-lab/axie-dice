# Review SR0 phần 2 (PB pre-throw + [epoch_rtt]) — beta/sr0 c1ec336 + 741ee2e
Reviewer độc lập, chỉ đọc code, không chạy Godot. Verdict: APPROVE WITH CHANGES (không có lỗi chặn).

## (1) Không đổi luật — OK
- Pre-throw chỉ là hình: CombatView.gd `_begin_pre_throw` (~4070) không đụng engine, chỉ đọc die/uid. Seed vẫn đi qua `request_reroll_dice` như cũ nên thứ tự RNG, action log, log_len giữ nguyên.
- Đường local (không epoch): `_begin_pre_throw` return ngay khi `_combat._epoch == null`. Không đổi.
- `_cancel_pre_throw` sau `_rebuild_all` (CombatView ~2910) là no-op khi `_pre_throw_uids` đã bị clear trong `_start_dice_throw`.

## (2) Pending / timer — OK, có 3 điểm nhỏ
- Seed lỗi: `_cancel_pre_throw()` gọi ngay (~2893) rồi `_rebuild_all`. Đúng.
- Không kẹt vĩnh viễn: RunSession có timeout 8s x3, 30s "offline" (run_session.gd:11,17,259) nên reply luôn settle; tối đa xúc xắc nhảy ~30s rồi land.
- Không có timer/tween mới; nudge dùng bộ đếm trong `_step_air`. `DiceRoller3D._exit_tree` gọi `_clear()` nên đổi scene an toàn.
- (a) `_do_reroll` ~2890: `if not _still_running(): return` bỏ qua `_cancel_pre_throw`. Nếu trận kết thúc (`_result_shown`) trong lúc chờ seed mà view còn trong tree, xúc xắc pending nhảy đến khi đổi scene. Nên gọi `_cancel_pre_throw()` trước return (nếu is_inside_tree).
- (b) Âm: `dm_roll` phát tới 3 lần cho một lần reroll (đầu `_do_reroll`, `_begin_pre_throw`, rồi `_start_dice_throw` khi seed về). Nên bỏ ở 2 chỗ sau khi live_pre.
- (c) `resolve()` (DiceRoller3D ~405) trả false nếu roll đã kết thúc, nhưng `_start_dice_throw` không xét kết quả; được bảo vệ bởi `_pre_throw_matches` kiểm `is_rolling()` cùng frame, nên ổn.

## (3) Khoá input — OK
`epoch_pending` bật suốt lúc chờ (combat_engine.gd:881-885), tắt đồng bộ ngay trước `_rebuild_all`, không có await xen giữa. Dice đang bay không mở khoá sớm. Các chỗ kiểm `epoch_pending` (CombatView 1304..4817) không đổi.

## (4) [epoch_rtt] — OK
- remote_epoch_source.gd:54-68: chỉ in `ms` và `kind`, không seed/token/uid/log. Dữ liệu chỉ nằm trong bộ nhớ.
- `rtt_stats` nearest-rank: p50 = a[ceil(0.5n)-1], p95 = a[ceil(0.95n)-1]; đúng (n=1 -> cả hai là phần tử đó; n=20 -> p95 = phần tử thứ 19).
- Chưa có test riêng cho `rtt_stats` (không có trong t_pre_throw). Nên thêm 1 test nhỏ (vd [10..200]).

## (5) t_pre_throw — kiểm chưa đủ thật
- Tốt: giả trễ 0/800/2500ms bằng timer thật; so faces cuối + log_len với bản trễ 0; kiểm lock bật và engine chưa đổi giữa chừng.
- Yếu: `disable_juice_for_tests = true` (t_pre_throw.gd ~108) và headless nên `will_skip()` true. `_begin_pre_throw` return trước `roll_pending`; nhánh `live_pre`, `resolve` thật, `_pre_throw_matches`, `_cancel_pre_throw` với dice đang bay KHÔNG được chạy. Test chỉ chứng minh "đường logic không đổi", không chứng minh "xúc xắc bay trước".
- Phần roller API chỉ kiểm sổ sách (has_pending/resolve) ở nhánh skip, không có physics.
- Yêu cầu: (i) thêm test gọi `_cancel_pre_throw` + `_pre_throw_matches` bằng dữ liệu giả (không cần 3D); (ii) QA tay trên web có 3D: reroll với RTT chậm, seed lỗi (ngắt mạng), thoát trận khi đang chờ. Ghi rõ giới hạn này trong doc.

## Việc cần sửa trước khi merge
1. (2a) cancel khi `_still_running()` false.  2. (2b) bỏ âm trùng.  3. (5) thêm test cho `rtt_stats` và nhánh match/cancel; QA tay 3D.
Không pre-throw End turn / Aid reroll: theo quyết định lane I, không tính là lỗi.

## Vòng 2 (33d58bf, diff 741ee2e..33d58bf)
- (2a) Đóng: `_do_reroll` gọi `_cancel_pre_throw()` trước return khi `!_still_running()` (CombatView.gd ~2892). `_land_dice_now` đã có guard `is_instance_valid(_stage3d)` nên an toàn cả khi view rời tree.
- (2b) Đóng: `dm_roll` chỉ phát một lần. Bỏ ở `_do_reroll` (chỉ còn gamble_arm / reroll_safe), và `_start_dice_throw` chỉ phát khi `_pre_throw_uids.is_empty()`. Pre-throw không bay (headless / reduce motion) thì `_pre_throw_uids` rỗng nên vẫn có tiếng. Không có chỗ nào mất tiếng.
- (5) Đã thêm test match/mismatch/cancel/thoát trận + rtt_stats (t_pre_throw.gd +61 dòng). Tôi chỉ xem diffstat, không đọc kỹ từng check và không chạy; Coordinator cần xác nhận số check qua run_tests. QA tay 3D trên web vẫn cần.
- Không thấy lỗi mới. Code chỉ đổi 8 dòng ở CombatView, không đụng engine hay log. Verdict vòng 2: APPROVE (kèm QA tay 3D trước khi deploy).
