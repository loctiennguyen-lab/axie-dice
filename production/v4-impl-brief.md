# V4 impl brief (làn BỘ + LIỀU + MẶT TẠM) — tóm gọn cho lập trình viên

Nguồn: `design/gdd/dice-depth-v4.md` (bản ở cây chính, số mục "§" bên dưới) + `production/qa/dice-depth-v4-qa-plan.md`.
Chốt thêm: N1 `reroll_paid_k` riêng; N5 trần thorn Khiên Gai `thorn.shield_transfer_cap` 6 mỗi lần chuyển mỗi Axie;
Lõi chủ + stage newcomer KHÔNG làm ở làn này (chỉ cờ `depth_stage`, mặc định 3). Viết TEST TRƯỚC, mỗi bước xanh thì commit.
Đã làm: `Unit.cracked`, `Unit.wild_slot` (+ to_data/from_data) trong `godot/scripts/data_models/unit.gd`. Chưa có gì khác.

## 1. BỘ, túi M, thứ tự tính (§3.2-3.4, 4.1, 3.10.5)
- Part của viên = `roll_face_index()` (fi, SLOT_ORDER mouth,horn,back,tail,eyes,ears), hoặc `wild_slot` nếu có.
- Viên đếm khi: side p, không `is_token`, không `custom_state.phantom` (knob `bo.phantom_counts`=0), hp>0, `has_rolled()`,
  mặt không `blank`, không `cracked`, không sidelined. Đã dùng / Hold / frozen / heavy VẪN đếm. Quái không bao giờ có BỘ.
- Concord (hook `roll_share_class` true): mỗi class chỉ viên đủ điều kiện đầu theo thứ tự `party` được đếm; lọc TRƯỚC khi áp `wild_slot`.
- Nhóm size>=3 là BỘ (3/4/5). Ảnh chụp `bo=[{part,size,uids,hi,m100}]` do `recompute_bo()` (hàm thuần), nằm trong `_state_dict` (undo+save),
  KHÔNG tính lại khi load. Chỉ chụp: cuối `roll_all`, cuối `reroll_dice`, sau `wild_face`, sau `_roll_edit` (tweak/loaded/hold_pick).
  Chết/dùng/Hold giữa hai lần chụp không đổi BỘ. Writer mặt khác của người chơi: chỉ `_roll_unit` (roll_all/reroll), `_share_class_rolls`,
  relic_hooks.gd:1498 (flip, qua `_roll_edit`). Token/Egg/enemy writer: chấp nhận không tính lại.
- Túi (số nguyên %): `M100 = clamp(100 + bo_add + oc_add + part_add (+core_add, chưa làm), 100, round(m_cap*100))`.
  `bo_add`= round(add_N*scale*100): knob `bo.add_3/4/5`=0.5/1.0/2.0, `bo.scale`=0.8 (ba 1.4, bốn 1.8, năm 2.6), `bo.m_cap`=3.0.
  `oc_add`=50 (`overcast.add`), `part_add`=25 nếu nhóm có viên mặt `rarity`>=`part.hi_r`(2) và stage>=3 (`part.hi_add`).
- Áp M CHỈ lên `value` mặt dmg/shield/heal/poison của phe p; không áp mana/debuff/summon/blank, không áp số trong keyword (thorns...).
- `v1 = (v0*M100 + 99)/100` chia nguyên (làm tròn lên).
- Thứ tự (§3.4): 1 giá trị gốc (value+growth, vital, blind/weaken/overdrive/hiveMind) → 2 Nứt `ceil(v/2)` (v>=1 còn >=1; v=0 giữ 0)
  → 3 R12 `side_face_bonus` + CONDUIT → 4 NHÂN M → 5 Resonance x1.15 → 6 hook `face_final` (Lõi, FLAT_CAP 10, mult_cap 8)
  → 7 first_dmg_face_bonus → 8 DamagePipeline. Lõi cộng phẳng KHÔNG bị M nhân.
- Nứt áp mặt dmg/shield/heal/poison/mana (đoán: "mặt có số"; debuff/summon không) — báo lệch nếu GDD muốn khác.
- Hook: `combat_engine.gd:1471 _face_value` (chèn nứt sau khối dmg ~1475-1490, M giữa CONDUIT và Resonance ~1491-1494, trước `face_final` dòng 1497).
  Tách `v0` (sau bước 3) để Overcast kiểm `v0>=1`. `preview_damage` (1510) gọi `_face_value` nên tự phản ánh.
- Knob mới trong `godot/assets/data/rules/combat_tune.json`: `bo`, `crack`(pct 30,value_div 2), `wild`(cost 2,per_turn 1), `part`, `hold.allow_cracked`=1,
  `reroll`(max_total 3, mana_cost_2 2, mana_cost_3 3, hard_cap 4), `thorn.shield_transfer_cap` 6, `poison.face_cap` 8/`stack_cap` 15 (§3.10.7). Đọc qua `tune_knob`.
- `depth_stage` (1..3, mặc định 3) vào `setup_new` + `_state_dict`: stage<2 từ chối Liều và wild_face; stage<3 từ chối Overcast, tắt part_add.

## 2. LIỀU, rmode, Nứt, pin (§3.5, 3.10.2, 3.10.3)
- `reroll_dice(uids, seed, from_aid, rmode)`; log args `[uids, from_aid, rmode]` (`combat_engine.gd:843`, verifier `run_verifier.gd:258`).
  Lần free an toàn (`rerolls>0`) và Aid: engine ĐỔI rmode thành 1 trước khi log. rmode 0=Liều (0 mana, Nứt), 1=An toàn.
- Lần chọn thứ nhất (tổng lần 2) giá `mana_cost_2`=2, lần hai `mana_cost_3`=3 (+ hook `before_reroll`, `reroll_mana_cost`, qua `maxi(0)`).
- `reroll_paid_k` (biến riêng, trong `_state_dict`) chỉ đếm Liều/An toàn, so với `reroll.max_total`=3; reroll tặng từ relic/Lõi KHÔNG đếm (N1).
  `reroll_total_turn` đếm MỌI nguồn (free, relic, Aid, Liều, An toàn) so `reroll.hard_cap`=4. Reset ở `roll_all`. Hiện `reroll_is_payable` (~923) dùng `reroll_nonaid` cần sửa.
- Nứt: sau `_resolve_cantrips` + `on_roll_settled`, với MỖI uid caller truyền (đúng thứ tự) rút `_rng.next_int(100) < crack.pct` từ stream seed của lần reroll;
  luôn rút đủ dù viên chết/không tung. Chỉ viên VỪA tung ở Liều. Nứt cũ xoá khi tung lại. Hết ở `roll_all`; viên Hold mang sang lượt sau sạch Nứt.
- Khoá `reroll_lock[k]={rmode,uids}` trong `_state_dict` (KHÔNG bị undo xoá; undo chỉ đưa `reroll_k` về): xin lại cùng k mà rmode/uids khác → false.
  Save/load giữ kết quả. Reset ở `roll_all`. `_rerollable` (~944) loại thêm viên có `wild_slot>=0` và `overcast`.
- Epoch: key MỚI `rmode` (enum 0/1, chỉ kind `reroll`) vào `worker/src/epoch_args.json` (kind reroll dòng "keys"), thêm vào `_reroll_args` (~770).
  KHÔNG dùng `mode` (enum short/full của run_start). Worker `worker/src/run_core.js` ~311-318 (pin_key, uids): khi pin đã có mà
  `rmode` hoặc `uids` khác → trả `pin_mismatch` (mã lỗi mới); cần cột lưu rmode (bảng epochs ~119). Sửa fake remote `t_remote_epoch_ui_run` (đọc cùng json).

## 3. MẶT TẠM (§3.6)
- `wild_face(uid, slot)` slot 0..5: trả `wild.cost`=2, `wild_used<wild.per_turn`(1/lượt, reset ở `roll_all`). Chỉ đổi part khi đếm BỘ; mặt thật giữ nguyên.
- Từ chối (false, mana không đổi): đã dùng, Hold, Nứt, cantrip, token/viên ảo, viên Concord loại, đã có wild_slot, slot==part thật, n<3 sau khi gắn, stage<2, mana<cost.
- Viên có Mặt Tạm: không tung lại, không Hold. Undo được (hoàn mana). Gọi `recompute_bo()` ngay sau. Hết ở `roll_all`, không hoàn mana.
- Viên mất tư cách đếm (Concord đổi viên đếm): `wild_slot` nằm im, không hoàn mana.

## 4. Overcast sửa (§3.7, 3.10.1) — code ở `combat_engine.gd:1301-1375`, nhân x1.5 ở `:1498-1501`
- Bỏ `overcast_mult()` và phép nhân sau `face_final`; thành `oc_add`=+0.50 trong M (knob `overcast.add`; xoá `overcast.mult`, giữ `mana_cost` 3, `per_turn` 1).
- Từ chối thêm: frozen (đã có), `v0==0`, viên ảo, mặt không thuộc dmg/shield/heal/poison, stage<3. Viên Overcast không tung lại (`_rerollable`), không Hold (`can_stash` ~1269 đã có).
- Sửa `t_overcast`, `t_overcast_ui` (đang assert ceil x1.5). Bốn + OC (scale 0.8) = M 2.30; scale 1.0 = 2.50.

## 5. Test bắt buộc (cố định knob scale=1.0/m_cap=3.5 VÀ một bản knob mặc định; M tính số nguyên)
t_bo_groups (nhóm theo fi, 3/4/5, loại trừ phantom/token/Nứt/blank/chết, Hold+đã dùng+frozen đếm) · t_bo_timing (chỉ đổi ở 4 thời điểm, mặt đổi bởi tweak) ·
t_bo_order (5x1.5=8, 4x2=8, 3x1.5=5, trần M, thorn/mana không nhân, v=0,1,2) · t_bo_overcast (không còn x1.5 sau face_final; OC+Mặt Tạm cùng viên) ·
t_bo_concord · t_crack (chỉ Liều, ceil(v/2), rút đủ 1 số/viên) · t_reroll_modes (max_total 3, hard_cap 4, N1 relic +1/+2) · t_wild_face ·
t_bo_undo (undo giữ bo/Nứt/wild/mana; đổi rmode cùng k bị từ chối) · t_bo_saveload (digest mỗi action) · t_bo_replay (RunVerifier) ·
t_reroll_epoch_pin + t_depth_epoch_args_contract (+ Worker `node --test`: rmode, pin_mismatch) · t_allowed_fns_sync (3 danh sách bằng nhau).
Không đụng `run_tests.sh`, `RULES_VERSION`, `t_rules_version.gd`, `project.godot`. Chạy `--import` sau khi thêm .gd mới.

## 6. Anti-cheat: ALLOWED_FNS 3 chỗ cùng commit
`godot/scripts/core/action_log.gd:76` (+ chú thích dòng ~63-70), `worker/src/run_core.js:21`, `godot/tests/t_replay.gd:340/548`; thêm `wild_face` (overcast, stash đã có);
`run_verifier.gd`: nhánh match ~255-275 và danh sách "cần engine" dòng 161; `reroll_dice` đọc `args[2]`=rmode.
Tamper T1-T10, mỗi cái RunVerifier báo lệch ĐÚNG tại action đó:
T1 đổi rmode của một reroll · T2 đổi slot của wild_face · T3 wild_face lần 2 trong lượt · T4 overcast lên mặt mana · T5 overcast/wild_face thiếu mana ·
T6 chèn wild_face vào run header stage 1 · T7 sửa header depth_stage lên 3 · T8 xoá một wild_face (digest lệch) · T9 đổi uids của reroll sau Liều (Nứt khác) ·
T10 Aid reroll giả (from_aid=1 mà không có ledger Aid). T6/T7 cần `depth_stage` trong `ActionLog.header` (cùng chỗ `newcomer`).

## 7. Sự kiện cho UI (bước 5)
`EventBus` thêm `bo_changed(groups)`, phát `core_fired`-kiểu kind "bo" khi BỘ đổi, `die_cracked(uid)`, `die_wild(uid, slot)`; `preview_damage`/`overcast_preview` đã đi qua `_face_value`.
