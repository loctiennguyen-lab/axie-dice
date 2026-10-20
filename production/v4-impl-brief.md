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

## Bước 1 - xong (BỘ + túi M + Overcast sửa)
API (combat_engine.gd): `bo` (Array `[{part,size,uids,hi,m100}]`, trong `_state_dict`, KHÔNG tính lại khi load), `recompute_bo()` thuần, `_snap_bo()` (chỉ ghi `bo`),
`m100_for(u)` (túi M % của một viên, gồm Overcast), `bo_cap100()`, `bo_add100(size)`, `overcast_add()`, `_face_base(u,fi)` (= v0, bước 1-3, -1.0 nếu blind),
`depth_stage` (setup_new key `depth_stage`, mặc định 3, trong `_state_dict`). `overcast_mult()` còn là shim (1+add) cho tooltip CombatView:1249; UI bước 5 đổi sang preview rồi xoá.
Chụp `bo`: cuối `roll_all` (sau on_roll_settled; `bo=[]` đầu roll_all nên cantrip đọc M=1), cuối `reroll_dice`, `_roll_edit` (tweak/loaded/hold_pick). wild_face (bước 3) phải gọi `_snap_bo()`.
Event cho UI: `EventBus.bo_changed(groups)` khi snapshot ĐỔI (so JSON). KHÔNG phát `core_fired` "bo": `RunState.note_core_fired` sẽ ghi "bo" vào `core_impact` (save + thống kê Lõi) và CorePanel đếm nhầm. Nếu UI cần thì lọc ở đó.
Nứt: `_face_base` đã halve khi `u.cracked` (mặt dmg/shield/heal/poison/mana, v>=1); chưa có ai set `cracked` (bước 2). Knob thêm: `bo.*`, `crack.*`, `part.*`, `overcast.add` (xoá `overcast.mult`). CHƯA thêm `reroll.*` mới/`wild`/`hold` (bước 2-3, để khỏi đổi hành vi reroll cũ).
`_rerollable` loại thêm viên `overcast` và `wild_slot>=0`. Overcast từ chối: viên ảo, mặt không thuộc dmg/shield/heal/poison, v0<1, stage<3.
Test: t_bo_groups, t_bo_order, t_bo_timing, t_bo_overcast, t_bo_concord, t_bo_saveload (undo+save), t_bo_replay (engine; run-level phủ bởi t_replay). Mỗi test chạy knob nominal (1.0/3.5) + default (0.8/3.0). Floor +7 file.

## Bước 2 - xong (LIỀU + rmode + khoá + pin)
combat_engine.gd: `reroll_dice(uids, seed, from_aid, rmode=1)`, `can_reroll(uids, from_aid, rmode)`, `reroll_refusal(...)` (mã: over, hard_cap, stage, mission, none, pin_mismatch, mana, veto, bad_rmode),
`effective_rmode(from_aid, rmode)` (free/Aid -> 1), `reroll_paid_k` (thay `reroll_nonaid`, max_total 3 = paid_k + reroll.free), `reroll_total_turn` (hard_cap 4, mọi nguồn), `reroll_lock[k]={rmode,rsrc,uids,list}` (trong save, KHÔNG bị undo xoá, reset ở roll_all).
Log `reroll_dice` args `[uids, from_aid, rmode]`; verifier đọc args[2] (thiếu = 1). Nứt: 1 lần `_rng.next_int(100)` mỗi uid caller truyền (đúng thứ tự), sau cantrip + on_roll_settled; `cracked` xoá khi tung lại, ở roll_all (kể cả viên Hold).
Giá An toàn: `reroll.mana_cost_2`=2 (paid_k 0), `mana_cost_3`=3 (paid_k>=1), qua hook `reroll_mana_cost` như cũ. Knob `reroll.mana_cost` bỏ. Cores hollow_core/cheap_mana giờ sửa `reroll_paid_k` (đổi tên); hard_cap 4 cắt trên cùng.
Epoch: key `rmode` (enum 0/1, chỉ kind reroll, không bắt buộc) trong epoch_args.json; `_reroll_args` gửi rmode đã chuẩn hoá. Worker `run_core.js`: `pin_mismatch` khi rmode/uids lệch dòng pin (đọc rmode từ cột args, không thêm cột). LocalEpochSource: cùng luật (`_pin_sigs`). ALLOWED_FNS không đổi (không thêm action).
Test mới: t_reroll_modes, t_reroll_pin; sửa t_reroll_mana, t_core_behaviour (đổi tên), t_epoch_source (+3), t_remote_epoch_ui_run (enum số), worker run_core.test (pin_mismatch). Floor +2.
Chưa làm / ghi chú: sổ Aid hoàn theo undo (nằm ngoài engine, chưa có); T10 Aid giả (from_aid=1 trong log mà epoch source='base') server chưa đối chiếu, chỉ bị hard_cap 4 chặn; UI chọn Liều/An toàn (bước 5) — CombatView vẫn gọi rmode mặc định 1.

## Bước 3 - xong (MẶT TẠM + T10 + Lõi hollow/cheap)
API (combat_engine.gd): `wild_face(uid, slot) -> bool` (log `wild_face [uid, slot]`, undo, gọi `_snap_bo()`), `can_wild_face`, `wild_block_reason(uid, slot)` (mã: phase, slot, stage, no_die, limit, used, held, cracked, cantrip, wild, same, not_counted (Concord/blank/không đếm), mana, size (n<3 sau khi gắn); "" = được), `wild_cost()`, `wild_per_turn()`, `wild_used` (trong `_state_dict`, reset ở `roll_all`; `wild_slot` cũng xoá ở roll_all cho mọi viên, kể cả Hold, không hoàn mana).
`preview_wild(uid, slot) -> {ok, reason, bo_label ("" | "BỘ BA" | "BỘ BỐN" | "BỘ NĂM"), mult (float, M của nhóm có viên đó, 1.0 = không BỘ), groups (bo giả định)}`: thuần, không đổi state/event/rng; vẫn trả groups khi bị từ chối vì mana/limit (UI xám nút bằng `ok`/`reason`).
Event: `EventBus.die_wild(uid, slot)` (+ float_text "WILD"); `bo_changed` phát khi BỘ đổi. Viên wild: `_rerollable` loại, `can_stash` false. Overcast cùng viên vẫn được.
Refactor: `_bo_dice()` (viên đếm BỘ sau Concord, trước wild_slot) dùng chung với `recompute_bo`. Knob mới: `wild.cost`=2, `wild.per_turn`=1, `reroll.core_hard_cap_add`=1.
ALLOWED_FNS (action_log.gd, run_core.js, t_replay.gd) + `run_verifier.gd` đã có `wild_face`. Test `t_wild_face` (94). Floor +1 = 178 (suite đo 178/178, t_rules_version skip).
T10: Worker `_consumeProblem` (cả submit và close): epoch kind `reroll` phải được tiêu bởi `reroll_dice` có `args[1]` (from_aid) khớp `source==='aid'` của epoch, lệch -> `rejected` (anomaly `delta_rejected`, why `aid_mismatch`). Sửa fixture `wallet.test.mjs` (reroll Aid giờ log from_aid=1). Worker 196/196 (thêm 2 assert). Chưa làm: đối chiếu rmode trong log với args.rmode của epoch (T1 vẫn bắt qua digest).
Lõi: `hollow_core`/`cheap_mana` có hook `reroll_hard_cap` (+`reroll.core_hard_cap_add`, 4->5) và `reroll_mana_cost` = giá knob (mana_cost_2/_3) - 1, min 0 (không còn hằng 1). `reroll_hard_cap()` giờ đi qua hook. Proof trong `t_core_behaviour`.
Chưa có: tamper T2/T3/T5/T6/T7 ở mức RunVerifier-run (chỉ engine từ chối wild_face sai trong t_wild_face; verifier trả ERR_REJECTED khi engine false); T6/T7 cần `depth_stage` trong ActionLog.header (chưa làm).

## Bước 4 - bàn giao (làn V4, chưa xong hẳn)
Xong (đã commit, test lẻ xanh):
- Tamper T2/T3/T5 qua RunVerifier full run: `godot/tests/t_run_tamper_v4.gd` (hook `RunBot.wild_script`). T6/T7 cũng ở đó (14 check).
- (A) trần thorn Khiên Gai `thorn.shield_transfer_cap` 6, `poison.face_cap` 8 (cuối `_face_value`, chỉ mặt poison phe p), `poison.stack_cap` 15 (`StatusEngine.capped_poison`: không cắt stack đã vượt, chỉ không cho cộng quá). (C) `hollow_paid`/`cheap_paid` chỉ chạy khi `rmode==1` (ctx `rmode` mới trong `on_reroll_paid`). (D) `reroll_refusal` trả `max_total` (lần chọn hết) tách khỏi `hard_cap`. Test: `t_v4_caps` (22), sửa `t_reroll_modes`, `t_core_behaviour` (toxic_still giờ cắt ở 15).
- `depth_stage`: `ActionLog.set_epoch_header(..., depth_stage=3)`, `RunState.depth_stage` (header server/params, mặc định 3; vào save + `pending_combat`), `LocalEpochSource` header, `RunVerifier` lấy stage từ `tape[0].extra.header.depth_stage`, header log lệch -> `stage_mismatch` (ERR_STAGE_MISMATCH), engine replay chạy dưới stage của tape (T6 bị từ chối đúng index). `RemoteEpochSource` gắn `depth_stage` vào mọi epoch_req/aid_req/run_close; NetNotice map `pin_mismatch`/`stage_mismatch`.
- Worker: migration `0009_depth_stage.sql` (ADD COLUMN `runs.depth_stage`), `runs.js depthStage()` (closed + won/lost: >=1 -> 2, >=3 -> 3, chưa newcomer-qua -> 1, qua newcomer -> 3), trả `header.depth_stage` ở create và /api/run/open (hàng cũ NULL -> 3), DO meta cột `depth_stage` (ALTER có bọc try cho DO cũ), `stage_mismatch` ở epoch_req + run_close (thiếu stage cũng lệch khi server đã ghi). Việc 3 + (B): `_consumeProblem` so rmode log (args[2], thiếu = 1) với `args.rmode` của epoch -> `rejected` (anomaly `rmode_mismatch`); pin reroll so thêm `source`. Worker `node --test`: 205/205.
Còn lại / chưa làm:
- CHƯA chạy cả suite Godot (làm một lần cuối). Test Godot lẻ đã xanh: t_run_tamper_v4, t_remote_epoch_ui_run, t_run_session, t_epoch_source, t_replay, t_wild_face, t_reroll_pin, t_v4_caps. Floor +2 file mới (t_v4_caps, t_run_tamper_v4) so với 178.
- `fake remote` của `t_remote_epoch_ui_run` chưa kiểm `stage_mismatch`/`pin_mismatch` (chỉ NetNotice đã map); chưa có test `t_depth_epoch_args_contract` cho hai mã lỗi.
- Relic cộng poison +1 trực tiếp (relic_hooks.gd ~1256, 1315, 1329, 1340) chưa qua `stack_cap`.
- Offline stage vẫn mặc định 3 (chưa có `runs_completed` trong MetaState; thuộc bước khác). UI online chưa đọc stage từ server (N8, bước 5).
- Cần Liam/lane I: bump `RULES_VERSION` (đổi luật poison/thorn/Lieu) + `t_rules_version`.
Lệnh deploy (CHỜ Liam bảo, theo thứ tự): 1) `cd worker && npx wrangler d1 migrations apply axie-dice-db --remote` (chỉ ADD COLUMN, 0009) TRƯỚC; 2) `npx wrangler deploy` Worker; 3) build + upload client (`bash export-web.sh` rồi `bash deploy-r2.sh`). Không đảo: Worker mới cần cột trước; client cũ (không gửi depth_stage) sẽ bị `stage_mismatch` ở run mới nên client phải lên cùng lúc.
