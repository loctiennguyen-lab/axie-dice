# Review code N-C (beta/nc: 3a4dd59, 7d232e2, fa96e62) — lead-programmer, 26/10/2026

Verdict: **APPROVE WITH CHANGES** (1 CHẶN trước R1 là chốt số `_tmp`, 2 NÊN SỬA).
Đã chạy (worktree nc, không cờ ngoài skip fingerprint): t_mission_unlock_chain 47, t_mission_escrow_reconcile 13, t_version_409_screen 30, t_economy 1320 — đều PASS. Chưa chạy cả suite.

## 1. Hợp đồng client <-> Worker (beta/nw, chưa merge): KHỚP
- Body mua: client `mission:{tier:"N<k>", stake, rules:[...]}` (`remote_epoch_source.gd:70`), Worker đọc `m.rules` (`missions.js:84-86`). Tên field `rules` đúng ở cả `missions.json` (mỗi bậc) lẫn body.
- Thứ tự/trùng: Worker sort rồi so, trùng bị từ chối (`sameRules`); client gửi đúng mảng của bậc, không trùng. N1 `rules:[]`, Worker chấp nhận thiếu/rỗng. Khớp.
- `unlock_wins`: client `wins_needed` (`mission_board.gd`, max(1, unlock_wins), N1=0) = Worker `winsNeeded` (`missions.js:52`). Khớp.
- `GET /api/missions/unlocks` -> `{tiers:{N1:{unlocked,wins,needs}}}`: Worker `missions.js:~175` đúng hình dạng, client `apply_unlocks` đọc đúng 3 field. Khớp.
- Mã lỗi: `mission_rules_mismatch` (400), `tier_not_unlocked` (403), `tier_locked` (403), `mission_needs_update` (409), `version` (409) — client `_map_http_code` (`remote_epoch_source.gd:411-413`) cho qua đủ cả 5, `RunSetup.begin_error_text` + `MissionsScreen.begin_error_text` có chữ riêng, `UpdateRequired.is_update_code` gom `version` + `mission_needs_update`. Không thấy chỗ lệch.
- NÊN SỬA (nhỏ): `tier_locked` do Worker còn trả khi `MISSION_TIERS_OFF`; client có `tier_locked`/`tier_disabled` nên ổn, nhưng `apply_unlocks` vẫn coi bậc đó "unlocked" theo chuỗi thắng (Worker `isUnlocked` không xét kill switch) -> thẻ sáng, bấm mới báo "đóng". Chấp nhận được, ghi lại.

## 2. Một nguồn bảng: ĐÚNG
- Worker `import table from '../../godot/assets/data/economy/missions.json'` (`missions.js:9`), client đọc cùng file qua `economy_db`. Một file, wrangler bundle khi deploy.
- `_validate_missions` (`economy_db.gd:163-190`) kiểm stake cố định, `enabled`, `rules` là mảng, mã luật trong M1-M7, payout không giảm. Không kiểm `unlock_wins` hay `rules` trùng/không có trong `mission_rules.json` (hiện M1-M7 có đủ). NÊN SỬA: thêm kiểm trùng trong `rules` và `unlock_wins` >= 1 (Worker từ chối trùng, client sẽ thành "mismatch" khó hiểu).
- Lưu ý: `worker/test/missions.test.mjs:15` đọc `missions.json` thật, trái với plan ("N-W dùng fixture"). Số N-S đổi sẽ làm test Worker đổi theo; nhờ N-W xem lại khi merge.

## 3. Đường abandon khi khác bản luật: CÓ KẼ HỞ (NÊN SỬA, nặng vì mất cược)
- `mission_escrow_sync.gd:~88-100`: `stale_rules` chỉ dựa vào save run LOCAL có `rules_version` khác; rồi abandon `run_id` lấy từ `MetaState.mission_escrow` (mirror, có thể do thiết bị khác ghi qua cloud save). Không kiểm run_id của save local == run_id của escrow.
- Kịch bản: máy A bản cũ (-t) còn save run cũ; máy B bản mới mở run Nhiệm vụ hợp lệ trên -u, escrow đồng bộ về A; A thấy save "rules", abandon run của B. Worker (`runs.js:188`) chỉ hoàn khi `row.rules_version !== currentRules`, run của B đang đúng bản hiện tại -> `lost`, người chơi mất cược oan, run B chết.
- Sửa đề xuất: chỉ abandon khi run_id đọc từ file save (trường run_id/mission) == `mission_escrow.run_id`; và/hoặc đọc `reconcile_status` trước, chỉ abandon khi server báo `open` kèm `rules_version` != hiện hành (cần Worker trả thêm field, nếu không thì dùng điều kiện run_id). Thêm test "escrow của run khác thì không abandon". Test hiện có (`t_mission_escrow_reconcile.gd:75-106`) chỉ phủ 2 ca đúng.

## 4. Sửa ngoài phạm vi: AN TOÀN
- `remote_epoch_source.gd` (+1 field body, +3 mã), `economy_db.gd`, `NetNotice.gd`, `RunSetup.gd` (hiện modal 409, banner vẫn giữ). Không đụng khoá input `epoch_pending` của SR0.
- `comm` giữa `godot-port...beta/nc` và `beta/nc...godot-port`: không file nào trùng, merge sạch dự kiến. SR0 chỉ đổi test/tools/worker (`run_core.js`, `run_do.js`).
- NetNotice: `is_fatal` đổi sang `UpdateRequired.is_update_code`; `NetNotice.show` gọi modal rồi đổi scene về Land khi đóng — kiểm tay một lần FLOW-6 vì đổi scene từ callback.

## 5. Số tạm `_tmp`: CHẶN trước R1
- `missions.json:4` `"_tmp": true` + từng bậc `_tmp` (dòng 18,33,49,65,82,100). Test chỉ in WARN (`t_mission_unlock_chain.gd:34-36`), không fail; `export-web.sh`/`deploy-r2.sh` không kiểm. Worker cũng bundle thẳng file này -> số tạm sẽ vào Worker.
- Đề xuất: (a) test `t_mission_no_tmp_in_release` fail khi còn khoá `_tmp`/`_tmp_note` ở bất kỳ cấp nào, bật bằng cờ/biến `AXIE_RELEASE=1` (export-web.sh và deploy Worker đặt cờ, hoặc script kiểm grep `_tmp` trước `wrangler deploy`); (b) mặc định suite thường giữ WARN để N-C chưa ghép số vẫn xanh; (c) ghi vào checklist R1: grep `_tmp` = 0. Ngoài ra `rules_need_spike` trong missions.json là khoá lạ, hỏi N-S giữ hay xoá.

## 6. Test có kiểm thật?
- Tốt: unlock chain đi qua `apply_unlocks` bằng response giả đúng hình dạng; escrow reconcile dùng transport giả, kiểm đường POST abandon thật; 409 screen kiểm UI. t_economy cập nhật theo bảng 6 bậc.
- Yếu: `t_mission_unlock_chain` hardcode bảng tạm (ascension, rules, mode) — khi N-S đổi số, test đỏ đúng nhưng phải sửa tay; nên tách "hình dạng" (giữ) khỏi "giá trị N-S" (đọc từ file). Chưa có test hợp đồng chéo client<->Worker (ví dụ test Worker nạp `missions.json` rồi chạy `rules` do `MissionBoard.tier_rules` sinh ra); đề xuất 1 test chung, rẻ, bắt đúng loại lệch tên field.
- Không test: ca 3 ở trên; offline khi `fetch_unlocks` lỗi (cache giữ nguyên là hợp lý, chỉ thiếu test).

## Tóm tắt
CHẶN: chốt `_tmp` + test fail ở chế độ release. NÊN SỬA: kẽ hở abandon (mục 3), validate trùng/`unlock_wins` (mục 2), test chéo hợp đồng (mục 6).

## Vòng 2 (commit 42ca438, d6203bc; Worker f45709c)
Verdict: **APPROVE WITH CHANGES** (còn 1 NÊN SỬA nhỏ + số tạm vẫn là CHẶN R1).
- Abandon: ĐÃ SỬA đúng. `_stale_save_run_id()` (`mission_escrow_sync.gd:~109`) so run_id trong file save với escrow; ca máy B/mirror lạ không còn abandon. t_mission_escrow_reconcile PASS 15 (có thêm ca A/B).
- `_tmp`: chạy thường PASS + WARN (47); `AXIE_RELEASE=1` FAIL "still holds _tmp" như mong muốn. Việc còn lại: đặt cờ này trong export-web.sh / trước `wrangler deploy` (chưa thấy trong diff) và thay số N-S.
- `_validate_missions` kiểm trùng + `unlock_wins` >= 1: có trong diff, t_economy không đỏ.
- Worker f45709c: `/unlocks` trả `unlocked:false` + `locked_reason:"tier_locked"` khi kill switch. CLIENT CHƯA HIỂN THỊ: grep `locked_reason` trong godot/ = 0 chỗ. `apply_unlocks` chỉ đọc `unlocked`, `server_tiers` không lưu lý do, nên bậc bị tắt hiện lock "chain" (ví dụ "thắng N1 1/1" trong khi đã đủ) - gây hiểu nhầm. NÊN SỬA: lưu `locked_reason` vào `server_tiers`, `lock_reason()` trả "disabled" khi `locked_reason == "tier_locked"` (chữ "đóng lúc này" đã có ở `MissionsScreen.begin_error_text`), thêm 1 ca vào t_mission_unlock_chain.
