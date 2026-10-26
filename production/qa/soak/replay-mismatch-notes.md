# Replay lệch seed 5004 (expert, Gambler) — ghi chú điều tra (chưa kết luận)

Tái hiện: `godot/tools/sim_balance.sh --runs=1 --seed=5004 --asc=0 --policies=expert --teams=mixed_dmg --verify=1 --anchor=auto` -> `rejected:action_rejected@53`.

Cách đo: code debug TẠM trong `CombatEngine._log` (đánh dấu `TEMP debug`, bật bằng env `AXIE_TRACE=<file>`): mỗi action ghi một dòng
`L|R fn args ||| _state_dict ||| RunState.to_data ||| _cond_given` (L = live, R = replay). Live lọc bỏ cặp thử+undo_last rồi so từng action với replay.

Kết quả:
- Điểm phân kỳ ĐẦU TIÊN không phải @53 mà sớm hơn: combat action thứ 26 (log index 37, trận r4_c0, lượt 1): `use_die [3,100000]`.
  Trước action: state engine + RunState + _cond_given GIỐNG HỆT (live vs replay). Sau action: live gây 3 dmg (enemy0 11->8, stat.dmg 10), replay gây 4 (11->7, stat.dmg 11). Cùng mặt xúc xắc, cùng target (bomblet).
  Các action trước đó khớp tuyệt đối -> lệch 1 dmg phát sinh trong tính damage, từ thứ NGOÀI `_state_dict`/RunState.to_data. Lệch dồn lên, tới @53 thì action bất hợp pháp.
- Gambler/Crack: chưa phải thủ phạm ở điểm này (anchor_turn gb100=0, chưa Gamble lượt đó).
- Nghi vấn tiếp theo: trạng thái ẩn dùng khi tính damage — static (CoreHooks.mute, core_hooks), field Unit không vào to_data, `_impact_at`, `core_emit`/`_chain_mute`; hoặc live bị ảnh hưởng bởi cặp thử+undo của bot (undo không phục hồi 1 thứ gì đó; KEEP_TRIALS=1 vẫn lệch nên khả năng là replay vs live khác nhau ở thứ không snapshot, kể cả khi trial replay cũng được chạy).
- Việc kế: ghi thêm vào trace các field ngoài dict (Unit transient, CoreHooks.mute, _chain_mute, core_emit) và dmg breakdown của _exec_face tại action này.

## KẾT LUẬN: (A) lỗi thật trong game — ĐÃ SỬA
Nguyên nhân: `Unit.to_data()/from_data()` (godot/scripts/data_models/unit.gd) không lưu `g_oc_bonus` (bonus G của ascend/forge). `CombatEngine.undo_last` và save/load dựng lại unit từ dict nên mất bonus -> sau bất kỳ undo nào, damage live thấp hơn (3 thay vì 4), còn replay (không undo) giữ bonus. Người chơi thật có Axie ascend/forge + dùng Undo sẽ bị verifier từ chối (và mất +G sau load save giữa trận).
Sửa: thêm "g_oc_bonus" vào to_data/from_data (save cũ thiếu key -> 0). File luật đổi: godot/scripts/data_models/unit.gd (KHÔNG bump RULES_VERSION (review lead-programmer 26/10: replay không đi qua undo/to_data nên log cũ replay y nguyên; unit.gd ngoài WATCHED_DIRS). Test: tests/t_unit_g_oc_roundtrip (tests +1).
Chạy lại: 5003/5004/5005 ok; 20 run expert (seed 5000, teams all, verify=1) 20/20 ok. Code trace TEMP đã gỡ.
