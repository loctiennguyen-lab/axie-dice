# Plan beta (26/10/2026): Nhiệm vụ, Land, Atia, Server RNG, Cosmetics, việc nhỏ v5

Trạng thái: PLAN v2, LIAM DUYỆT 26/10: câu 1, 2, 4 theo khuyến nghị; **câu 3: RESET HẾT, KHÔNG ĐỂ LẠI GÌ (kể cả Gem và lịch sử run)**; Atia hướng B 12 con. Đang triển khai.
Nguồn: `design/proposals/nhiem-vu-beta-brainstorm.md`, `land-beta-brainstorm.md`, `docs/architecture/server-rng-beta-brainstorm.md` (+ review), review plan `production/beta-plan-review.md`, `design/proposals/cosmetics-frames-round6-brainstorm.md`. Brainstorm Atia đã có (`design/proposals/atia-roster-expansion-brainstorm.md`, khuyến nghị hướng B 13 con, đang sửa theo review). Khung cosmetics đã chốt 8 khung (C6 U3 R5 E6 L3 M2), prompt `design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`.
Mốc hiện tại: godot-port = axiedice/main `6ccb738`, RULES_VERSION `-t`. Sàn test: Godot 235/235, Worker 236/236. D1 đã áp tới `0009`.

**Đã sửa theo review 26/10** (producer, APPROVE WITH CHANGES):
- Theo 5 chỗ Liam trả lời khác khuyến nghị: số Nhiệm vụ khoá theo sim bot (bỏ hiệu chuẩn 30 run); bật cược cả 6 bậc, Worker kiểm không chặn bật; beta chủ yếu DESKTOP + xoá tiến độ sau beta nên tier 2 = 20k và web nhẹ ra khỏi đường găng; reset số dư M1, không nhập; không trần payout ngày.
- Thêm đường release desktop + màn "có bản mới" khi Worker trả 409 version; cửa sổ `-t` tính từ lúc có link tải desktop.
- Tách "đổi fingerprint" và "đổi kết quả run"; Atia có bump riêng.
- Hoàn cược run Nhiệm vụ dở khi bump; ngoại lệ có tên cho N-W ở `runs.js`; prelude thêm hàm + đổi tên field; reset M1 qua SaveStore + cloud save; sim ở worktree riêng; làn Atia + làn Cosmetics; lịch rút còn ~27/11.

## 1. Quy tắc chung

- Mỗi làn: worktree `/Users/loc.tien.nguyen/my-game-wt/<làn>`, nhánh `beta/<làn>` từ godot-port, `godot/override.cfg` riêng, mọi lần chạy Godot qua `with_lock.sh` của worktree đó, `AXIE_HANG_KILL` 120 (test lẻ) / 500 (suite). Theo `production/l1-lanes.md`, `production/agent-lane-rules.md`.
- Chỉ **làn I** (cây chính) sửa: `ActionLog.RULES_VERSION`, FINGERPRINT trong `t_rules_version.gd`, `project.godot`, `run_tests.sh`, sàn test, `SUPPORTED_RULE_VERSIONS` (`worker/src/run_do.js`), script export/deploy. Làn khác xin I.
- Test tự dựng save bằng SaveGuard, không mạng. Ghi save qua `SaveStore`; field mới thì sửa `MetaState.reload_from_store()`.
- Mỗi hệ thống: xong -> review độc lập (khác người làm) -> QA luồng thật (tài khoản Liam) -> I merge reviewed hash, grep CONFLICT, `--import`, suite -> commit/push `axiedice godot-port:main` -> deploy (Liam đã cho phép 26/10).
- **Hai loại thay đổi rule-file, đừng lẫn:** (1) "đổi fingerprint": file trong `autoload/`, `scripts/meta/`, `scripts/core/`, `assets/data/rules/` đổi nội dung -> I chỉ ghim lại FINGERPRINT, ghi "Run result: NO" (tiền lệ 14/10 Land upgrade), KHÔNG bump. (2) "đổi kết quả run": mới bump RULES_VERSION. Prelude, Land, N-C (phần client), SR1 thuộc loại 1.
- CPU là giới hạn thật. **Sim chạy ở worktree riêng** (`ns-sim1..n`, mỗi cái override.cfg riêng); `beta/ns` chỉ để viết tool. I không chạy suite merge khi sim đang đầy CPU (dễ hang-kill giả).

### Prelude (làn I, ngày 1, không cần đợi LD-D; ngưỡng Land chỉnh sau bằng commit nhỏ nếu số đổi)
Một commit trên godot-port trước khi tách worktree: field save mới + **hàm** (thân đơn giản, làn sửa thân qua yêu cầu cho I) + `t_meta_fields_beta`, kèm `reload_from_store()`.
- Field: `land_tier_banner_seen`, `land_gift_granted` (đổi tên từ `land_starter_granted`, tránh nhầm `starter_granted` ở `MetaState.gd:103`), `mission_unlock_cache` (cache đọc từ server, không phải nguồn thật). Ngưỡng Land tính theo tier 2 = 20k.
- Hàm: `grant_land_gift_once()`, `set_mission_unlocks()`.
- Fingerprint: ghim lại, "Run result: NO".

## 2. Sở hữu file chung

| File | Chủ | Ai đợi / ngoại lệ |
|---|---|---|
| `MetaState.gd`, `save_store.gd` | I (prelude), rồi SR1 | Land/Nhiệm vụ không sửa thân; SR1 bắt đầu sau khi R2 (Land) merge |
| `RunState.gd` | SR0 -> SR1/SR4 (cùng agent) | N-C chỉ đọc; N-C có ngoại lệ có tên: hàm xử lý hoàn cược/409 dưới đây nếu cần |
| `worker/src/run_core.js`, `run_do.js` (trừ SUPPORTED) | SR-W | N-W chỉ `missions.js` |
| `worker/src/runs.js` | **N-W** (ngoại lệ có tên: chỗ gọi `validateMission` dòng ~70, `settleEscrow`/`reconcileEscrows` dòng ~183, 409 version dòng ~57 chỉ để thêm mã lỗi rõ) | SR0, SR-W không đụng `runs.js` |
| `worker/src/index.js` | N-W chỉ hàm `loadPckManifest` | SR-W đợi |
| `worker/src/wallet.js`, `accounts.js` | SR-W | N-W không sửa |
| `scenes/land/*` | LD-A | LD-B chỉ đưa data |
| `missions.json`, `mission_board.gd`, `scenes/missions/*`, `mission_rules.json`, `ascension.json` | N-C | N-S chỉ đọc; N-W test dùng fixture bảng 6 bậc, không đọc `missions.json` hiện tại |
| `sim_balance.gd`, `sim_report.gd`, `production/qa/sim/` | N-S | V5, Atia chỉ chạy |
| anchor .tres, `gen_cores.py`, `combat_engine.gd`, `reward_generator.gd`, `relic_def.gd`, `unit.gd`, `record_sample_run.*`, `verify_run.*`, `t_desktop_signin` | V5 | |
| quái mới Atia (monster data, `monster_art.gd`, `assets/atia`, `atia_models.json`) | AT | CL xong trước AT mới bắt đầu (cùng thư mục) |
| `worker/wrangler.toml`, `verifier/` | SR-V | |

Migration cấp trước: `0010_mission_unlock` (N-W), `0011_economy` (SR1), `0012_verify` (SR-V). Chỉ ADD, không DROP/DELETE.

## 3. Các làn

Công sức: S ≤ 1 ngày, M 1-3, L 3-6 (ước, một agent).

### N-S — Sim Nhiệm vụ (`beta/ns` + `ns-sim*`) — M, nút thắt
economy-designer + godot-gdscript-specialist; review: lead-programmer, systems-designer.
1. `sim_balance.gd`: `--mode=short|full` (đang hard-code ~dòng 199), `--mission=N1..N6`, `--rules=`, `--anchor=auto` bắt buộc, seed chung, CSV, CI 95%. **Ngày 1 thêm cờ ép Luật run** (V5 cần cho 2 Luật đang tắt; V5 không sửa file này).
2. Đo run/giờ trước; thấp quá thì chia nhiều worktree sim.
3. Bước 0 (A0..A9 Short, Full A0/A6, >= 600/điểm), bước 1 (từng luật M ở A0, A3), bước 2 (6 bậc; N1-N4 >= 600-1.500, N5-N6 >= 1.500), sau khi Anchor đóng băng.
4. `production/qa/sim/mission-sim-v1.md`: p theo bậc, d từng luật, m theo P1 (RTP bot 0,65). Liam khoá theo sim bot nên **đây là nguồn số DUY NHẤT**: tiêu chí xong giữ chặt, không nới vì gấp: thang đơn điệu theo so cặp, mọi bậc trong khoảng chấp nhận, N6 cận trên CI 95% < 5% (nếu không đạt: đổi luật/Ascension theo §3.4 doc, rồi N5->Full hoặc báo Liam).
5. Mọi thay đổi `mission_rules.json`/`ascension.json` phải xong TRƯỚC R1.
Test mới: `t_sim_mission_args`. QA thật: không (tool); review kiểm seed chung + Anchor auto.

### N-W — Worker Nhiệm vụ (`beta/nw`) — M
network-programmer; review: security-engineer; QA: qa-tester gọi API thật.
1. `validateMission` (`missions.js`, gọi ở `runs.js:~70`): so `rules` với bảng tier; `rules: []` ở N2+ -> 400. Vì kiểm mở bậc phải đọc D1 theo người chơi mà `validateMission` đang đồng bộ, N-W sửa chỗ gọi ở `runs.js` (ngoại lệ có tên).
2. Mở bậc ở D1 (`mission_wins`, `0010_mission_unlock.sql`), `GET /missions/unlocks`. **Cược cả 6 bậc bật ngay** (bỏ `tier_locked` ở `missions.json`); kiểm rules/mở bậc vẫn làm nhưng không chặn việc bật. Bật bậc = sửa data + deploy Worker VÀ client cùng đợt (Worker import `missions.js:9`, client chặn ở `RunState.begin_run` qua `MissionBoard.tier_enabled`).
3. **Hoàn cược khi bump, sửa CẢ HAI đường:** `abandon()` (`runs.js:183`, nay chỉ hoàn khi `epochs === 0`) và `reconcileEscrows` (`missions.js:84-90`) đều hoàn khi `runs.rules_version` khác "bản hiện tại" (= phần tử cuối `SUPPORTED_RULE_VERSIONS`); N-W sửa luôn comment sai ở `runs.js:66` (client không chơi tiếp run khác luật, `RunState.gd:2041`). Worker chỉ có MỘT bảng mission (bản `-u`): trong cửa sổ giữ `-t`, run thường nhận cả hai bản, run Nhiệm vụ chỉ nhận `-u`; client cũ nhận mã lỗi rõ (`mission_needs_update`), không phải `rules_mismatch`.
4. Nợ bảo mật 23/10 (`loadPckManifest`: key bắt đầu `pck/`, md5 hợp lệ; Range `a>b`; If-Range).
Test mới (fixture bảng 6 bậc riêng): `missions_rules_check`, `missions_unlock`, `missions_refund_on_bump`, `pck_manifest_hardening` (`.test.mjs`).
Xong khi: gửi `rules` sai bị từ chối; sửa save không mua được N2 khi chưa thắng N1, **nhưng** `won` vẫn do client báo tới B3, nên run giả vẫn mở được bậc (Liam đã chấp nhận ở câu 9, ghi vào doc, không viết như đã chặn hết).

### N-C — Client Nhiệm vụ (`beta/nc`) — M-L
gameplay-programmer + ui-programmer; review: ux-designer (ảnh 1920x1080, 1280x720) + lead-programmer; QA: qa-tester.
1. `mission_board.gd:88` mở bậc theo chuỗi thắng từ server (bỏ `asc_wins`, `unlock_win_asc`, `unlock_full_a9`); bật cả 6 bậc.
2. Ghi bảng 6 bậc vào `missions.json`/`mission_rules.json`/`ascension.json` **từ số của N-S**, không số tạm trong bản deploy.
3. Thẻ offer theo §5 doc (luật bằng chữ, cược/trả/lãi ròng, "ước tính", cảnh báo N3+, disabled có lý do), màn thua đọc được, chip luật cùng chữ; "ước tính" ghi rõ là số từ bot.
4. Escrow: `reconcileEscrows` trước khi hiện số dư/mua; thấy run Nhiệm vụ dở khác `rules_version` thì báo "run cũ, đã hoàn cược".
5. **Màn "có bản mới":** khi Worker trả 409 `version` (`runs.js:57`) hoặc `mission_needs_update`, hiện "Bản này cũ, tải bản mới" + link tải cố định (UI3), không để lỗi thô. Làm TRƯỚC R1.
Test mới: `t_mission_unlock_chain`, `t_mission_offer_card`, `t_mission_escrow_reconcile`, `t_version_409_screen`.
QA thật (Liam, production + bản desktop): FLOW-1 mua N1 thắng -> Shard/Stone đúng; FLOW-2 thua/bỏ giữa chừng mất cược; FLOW-3 N2 khi chưa thắng N1 bị chặn; FLOW-4 mất mạng giữa run; FLOW-5 **bump giữa run Nhiệm vụ -> hoàn cược**; FLOW-6 bản desktop cũ thấy màn "có bản mới".

### V5 — Việc nhỏ v5 (`beta/v5`) — M
economy-designer + gameplay-programmer + qa-tester; review: lead-programmer.
1. Cân Anchor (Embers yếu nhất, chênh ~12): mục tiêu chênh ≤ 5; chỉ knob Anchor, tối đa 3 vòng, mỗi vòng đổi MỘT thứ, n >= 120/Anchor. **Đóng băng hết 28/10**; quá hạn thì giữ hiện trạng, ghi nợ, không chặn N-S.
2. Sim `rule_set_is_king`, `rule_pilot_light`, `c_magma_seed` (dùng cờ ép Luật của N-S); đạt thì bật theo `cores-rules-v5.md` mục 11 (`gen_cores.py`, giữ `hook_key`), không đạt thì để tắt ghi lý do.
3. Sửa comment: `combat_engine.gd:1071`, "Mythic" bậc 4 ở `reward_generator.gd`, `relic_def.gd`, `unit.gd` (đổi fingerprint, nằm trong bump `-u`).
4. SaveGuard cho `record_sample_run.tscn`, `verify_run.tscn` + `t_tool_scenes_saveguard`.
5. `t_desktop_signin` (đỏ cả bản cũ): tìm nguyên nhân gốc (cổng loopback?), chọn cổng trống hoặc skip có điều kiện + lý do, không nới assert.
Xong khi: suite xanh không cờ skip trên worktree sạch; báo cáo `production/qa/sim/v5-tail-2026-10.md`.

### CL — Dọn model boss cũ (`beta/cl`) — S
`godot/assets/atia/{frost_lord,mirror,plague_mother}` (~3,8 MB). `atia_models.json` trỏ sang `assets/bosses/chimera_*`; grep sơ bộ không thấy chỗ dùng đường dẫn cũ. Trước khi xoá: grep toàn repo (`.tscn`, `atia_model.gd` có quét thư mục không), `--import`, `t_assets` (457) + `t_boss_*`; sửa số trong `t_assets` nếu đếm file. Xong trước khi AT mở. gameplay-programmer; review: technical-artist. Vào R1.

### SR0 — Server RNG B0 (`beta/sr0`) — S, làm sớm có lý do
network-programmer + gameplay-programmer; review: security-engineer.
Lý do làm sớm dù Server RNG xếp thứ 4: nhỏ, và giờ bật cả 6 bậc không trần payout ngày, kiểm tối thiểu ở `run_close` là thứ DUY NHẤT soi "thắng giả" để mở bậc/nhận thưởng.
Việc: đo RTT thật từ VN (p50/p95) -> PB hay PA (p95 > ~1,2 s thì báo Liam, không tự đổi); luật khoá input + `t_run_session_race`; ràng run token vào session; kiểm `run_close` (đủ `enter_node` tới boss cuối, `log_len`, thời gian) ở chế độ chỉ-ghi, trượt ngưỡng chỉ đánh dấu. Không đụng `runs.js`. Test: Worker `run_close_sanity`. Bump: không.

### LD-D — Chốt số Land (không code) — S
economy-designer; review: systems-designer. **Tier 2 = 20k** (xoá tiến độ sau beta nên được). Tính lại m1-m8 với 20k + 2 Rare tier 2 + 8 common; viết lại phương án (a) dời mốc sớm / (b) nâng m6-m8 vì giả định "tier 40k" mất. Ghi số vào `land-beta-brainstorm.md`, rồi mới sửa `land_tiers.json`. 

### LD-A — Land scene (`beta/lda`) — M
gameplay-programmer + ui-programmer; review: godot-gdscript-specialist + ux-designer.
1. Nâng tier xong về Land, `_tier` mới, sửa `ADDS`, banner một lần (field prelude), chip HUD Stone bấm mở màn nâng.
2. Axie của mình (raid defense -> preset 0 -> ngẫu nhiên, bỏ trùng ghế).
3. Món khởi đầu 90 Shard một lần (`grant_land_gift_once()`), mục Land ở Profile (UI3).
4. **Ưu tiên thấp, ngoài đường găng:** cờ web nhẹ sau LD-M, làm khi rảnh, không chặn R2.
Test: `t_land_tier_up_flow`, `t_land_banner_once` (qua save/load + cloud), `t_land_my_axie`, `t_land_gift_once`, `t_land_light` (bước 4).
QA thật: save đủ Stone (20k) nâng tier 2, thấy banner/chip/Axie; đăng xuất/nhập lại không lặp banner; chạy trên bản desktop.

### LD-M — Đo web Land — S, ưu tiên thấp
performance-analyst. Chỉ đo M-series bằng agent, ghi `production/qa/land-web-perf-2026-10.md`; không máy iGPU, không chặn gì. Làm khi rảnh sau R2.

### LD-B — Data Land (`beta/ldb`) — S-M (đợi LD-D)
technical-artist + gameplay-programmer; review: lead-programmer. +8 decor common (chép từ `asset-library/godot-ready/`, chỉ món dùng), 2 Rare tier 2, số mốc theo LD-D. Test: `t_decor_data`, `t_land_milestones`. File data nếu nằm trong fingerprint thì chỉ ghim "Run result: NO", không bump. **Số chốt: mục "Số chốt LD-D (26/10)" trong `land-beta-brainstorm.md` + review `design/proposals/land-ldd-review.md` (APPROVE WITH CHANGES): giữ m4=30 + assert "trần T2 >= m4+2"; KIỂM `land_decor.gd` ~150-167 có chặn `min_tier` không (nếu không, Rare đặt được ở T1 → phải chặn); sửa `economy_db.gd:208` 1.82M→1.8M (ghim), test t_land_upgrade/t_decor_data/t_decor_milestones + grep số điểm cứng ở t_decor_score/t_land_milestones; technical-artist xem S_Tree03 vs S_Tree03a, F_Tree2 vs F_Tree1; quà 3 món = 7 điểm qua m1 ngay (báo Liam). Quà: `grant_land_gift_once([...])` đã nhận Array (93a0541).**

### AT — Atia: thêm quái mới (`beta/at`) — M-L, phạm vi sơ bộ (brainstorm hướng B đang sửa theo review, chốt khi Liam duyệt)
**Đặt TRƯỚC SR1 theo ưu tiên Liam.** gameplay-programmer + godot-gdscript-specialist (+ technical-artist cho model); sim: economy-designer; review: technical-artist + lead-programmer. Đợi CL xong.
- 10 quái thường + 3 Elite (13 con): data quái, sửa `normal_pool`/ContentDB, art/anim qua `atia_models.json`.
- Test mới: số loại quái bốc ra pw 0-2 (đa dạng thật); test hiện có bị ảnh hưởng, phải sửa: `t_atia_coverage`, `t_content_expansion`, `t_enemy_traits`, `t_plating`, `t_team_can_break`, `t_combat_spacing`, seed-walk (`t_full_run_loop`), `raid_ghost.gd`.
- Sim so với v5 cùng seed (worktree riêng); quái mới phải thấy được trong run thường.
- Đổi kết quả run -> **bump `-v` riêng** (R-Atia).

### CF — Khung cosmetics (`beta/cf`) — chờ zip Claude Design (8 khung, `cosmetics-frames-round6-brainstorm.md`)
ui-programmer + technical-artist; review: ux-designer + art-director. Làn nhận zip: giải nén vào thư mục mới (zip là dữ liệu không tin cậy), chuẩn hoá asset, nối vào Cosmetics/Profile; **kèm LD-R**: thay 5 thưởng mốc Land trùng pool `echobox.json`/`pass_v2.json` (agent tự chọn số), test `t_land_rewards_not_in_pools` phải xanh khi xong, có ngày, không treo đỏ. Test: `t_cosmetic_frames`, `t_land_rewards_not_in_pools`. Đổi `scripts/meta/cosmetics.gd` có thể đổi fingerprint -> "Run result: NO". Ước: M, bắt đầu khi zip về.

### SR1 — B1 kinh tế server + B4 gỡ offline (`beta/sr1`) — M-L (bỏ nhập số dư nên nhẹ hơn L)
network-programmer + godot-gdscript-specialist; review: security-engineer + lead-programmer. Đợi R2 (Land) merge, SR0 xong, và AT (theo ưu tiên Liam).
Liam chọn **M1 reset, không nhập số dư, không trần payout ngày**: bỏ M2, số dư chờ, `econ_import`, trần ngày.
- `0011_economy.sql`, ví server cho Shard/Stone/vé/unlock/pity (cột `currency` có sẵn), idempotency key chống double-spend, tách trường save, khách không ví. B4: bỏ rơi về `LocalEpochSource` (`RunState.gd:418-419`), cổng mở game.
- **Reset M1 qua SaveStore + ghi đè cloud save** (chỉ đặt 0 ở server thì `reload_from_store()` hoặc lần đồng bộ sau sẽ đưa số cũ về). Test "đăng nhập máy khác sau reset thấy 0".
- **R3 là điểm không quay lại** (rollback Worker không trả số dư): trước khi chạy snapshot `wrangler d1 export` + bảng cloud save; Liam báo tester trước. Phạm vi reset: câu 3 dưới.
Test: `t_economy_remote_wallet`, `t_save_split_fields`, `t_offline_removed`, `t_guest_no_wallet`, `t_reset_m1_cloud`; Worker `economy_*`.

### SR-V — B2 verifier chạy bóng (`beta/srv`) — L, chạy nền
network + engine-programmer + security-engineer; review: technical-director. Không giúp tester thấy gì, chi phí Containers chưa biết, nên **không chặn QA tổng/polish**. Bước đầu đo egress + cold start; lệch quá thì dừng báo Liam (V2 máy riêng). `verifier/`, `verify_queue.js`, `0012_verify.sql`; test `t_verify_cross_platform`, `verify_queue`. B3 ngoài plan.

## 4. Phụ thuộc và bump

```
Prelude -> mọi làn
V5 Anchor đóng băng 28/10 -> N-S bước 0-2 (sim ở worktree riêng)
N-S -> N-C ghi số -> R1 (cả 6 bậc, nếu trễ: N1-N3 trước, N4-N6 ngay khi có số)
N-W (+ màn 409 của N-C) -> R1;  CL -> AT;  LD-D -> LD-B;  R2 -> SR1;  AT -> SR1
SR0 -> SR1;  SR-V nền;  CF theo zip Claude Design, kèm LD-R
```
Bump RULES_VERSION: **`-u` ở R1** (V5 + `mission_rules.json`/`ascension.json`, xong trước R1) và **`-v` ở R-Atia** (quái mới, riêng). Prelude, Land, N-C client, SR1, CF: chỉ ghim fingerprint "Run result: NO". Không còn lý do `-v` cho Land hay hiệu chuẩn.

## 5. Release (có desktop)

**Trước mọi đợt có Nhiệm vụ (R1+): `grep -c '_tmp' godot/assets/data/economy/missions.json` = 0 và suite chạy với `AXIE_RELEASE=1` (test fail khi còn số tạm — review code N-C 26/10).** Web (như `deploy-2026-10-23.md`): suite KHÔNG cờ skip + Worker test -> push -> `wrangler d1 migrations list --remote`, đọc SQL, `apply` -> tắt editor -> `bash export-web.sh` -> `bash deploy-r2.sh --pck-only` -> `cd worker && npx wrangler deploy` -> `bash deploy-r2.sh --rest` -> kiểm md5 `/index.pck` đủ byte (không chỉ HTTP 200), html/js/wasm -> QA tài khoản Liam -> báo Liam 3-5 dòng. Dừng ở bước lỗi đầu tiên.
**Desktop (thêm, vì beta chủ yếu desktop):** sau khi web + Worker lên, `bash tools/build_desktop.sh` (mac + Windows, không để `override.cfg` vào gói), dời bản cũ vào `build/old/`, đặt bản tải ở **link cố định** (nơi đặt: chốt cùng Liam, câu 2), báo tester. Smoke bản desktop mới (đăng nhập desktop, vào run, Nhiệm vụ).
**Cửa sổ `-t`:** Worker giữ `-t` + `-u` trong **7 ngày kể từ lúc có link tải desktop mới**, không phải ngày deploy web. Hết hạn: bản cũ gặp 409 -> màn "có bản mới" (N-C). Đợt R-Atia (`-v`) lặp lại: giữ `-u` + `-v` 7 ngày từ link mới.
Trước mỗi đợt: giữ `web/` + md5 + version Worker cũ ở `build/web-prev/`. Đợt có bump: sửa tiến bằng hotfix; nếu buộc rollback Worker thì đổi link desktop về bản cũ CÙNG LÚC (tránh vòng lặp 409). Rollback: `wrangler rollback`; web chạy lại `deploy-r2.sh` từ `build/web-prev/` (cả bộ, không để pck cũ + js mới); desktop: link cũ để lại ở `build/old/`; D1 chỉ ADD nên không rollback.

| Đợt | Nội dung | Bump | Migration | Worker | Web | Desktop | Dự kiến |
|---|---|---|---|---|---|---|---|
| R0 | SR0 chỉ-ghi | Không | Không | Có | Chỉ nếu client đổi | Không | 29-30/10 |
| R1 | V5 + N-W + N-C (6 bậc) + màn 409 + CL | `-u` | `0010` | Có (-t và -u) | Có | **Có** (mở cửa sổ 7 ngày) | 4-5/11 |
| R2 | Land (tier 20k, banner, chip, Axie, decor) | Không (ghim) | Không | Không | Có | Có | 7-9/11 |
| R-Atia | quái mới | `-v` | Không | Có | Có | Có | ~16-18/11 |
| R3 | SR1 + B4 + reset M1 (lane I: `project.godot` `[axie] econ="remote"` + Worker env `ECON_SHARD_WALLET=1` CÙNG đợt; D1 0011 trước Worker; `tools/reset_m1.sh --remote --yes` sau snapshot, báo tester trước) | Không (ghim) | `0011` + snapshot | Có | Có | Có | ~18-21/11 |
| R-CF | khung cosmetics + LD-R | Không (ghim) | Không | Không | Có | Có | ~22-26/11 |
| R4 | SR-V bóng (nền) | Không | `0012` | Có + Container | Không | Không | sau, không chặn |

Sau R-CF: **QA tổng 2 ngày** (qa-lead lập kế hoạch luồng thật, tài khoản Liam, production + desktop) rồi giao Liam polish.

## 6. Lịch (ước, hôm nay 26/10; chưa chắc nhất: tốc độ sim, phạm vi Atia/CF)

| Ngày | Việc |
|---|---|
| 26-28/10 | Duyệt plan. Prelude (không đợi LD-D). Mở worktree. N-S tool, V5 vòng 1, N-W, SR0, LD-D, CL |
| 29-30/10 | R0. Anchor đóng băng (28/10). N-S sim bước 0. Liam gửi prompt khung cho Claude Design; AT đối chiếu tex 21 model |
| 31/10-3/11 | N-S bước 1-2 (worktree sim riêng), N-C ghép số, màn 409, review độc lập N-W/N-C/V5 |
| ~4-5/11 | R1 (6 bậc, desktop). Nếu sim chưa xong: N1-N3 trước |
| 6-9/11 | LD-A, LD-B, R2 |
| 10-17/11 | AT (theo brainstorm) ∥ SR1 bản M (viết, chưa deploy trước AT) |
| ~16-21/11 | R-Atia, rồi R3 (reset M1), hai đợt cách nhau >= 2 ngày |
| ~22-26/11 | CF + LD-R, R-CF, QA tổng 2 ngày |
| ~27/11 | Giao Liam polish. SR-V, LD-M, cờ web nhẹ chạy nền, không chặn |

## 7. Rủi ro

| Rủi ro | Chặn |
|---|---|
| Save thật bị test ghi đè | `override.cfg` riêng mỗi worktree; SaveGuard cho 2 tool scene + `t_tool_scenes_saveguard`; QA cây chính khi Liam không chơi |
| Godot treo vì parse error | `AXIE_HANG_KILL`, `--import` trước, không vòng chờ; lỗi lặp 2 lần thì dừng báo |
| Sim đầy CPU làm suite hang-kill giả | Sim ở worktree riêng; I không chạy suite merge cùng lúc |
| pck web ~360 MB (đã chia phần 250 MiB) | `--pck-only` trước, kiểm md5 đủ byte, `build/web-prev/`; CL bớt ~3,8 MB; Atia mới tăng pck: ghi kích thước mỗi đợt, > 5% xem lại |
| Bản desktop cũ bị 409 không hiểu | Màn "có bản mới" trước R1; cửa sổ 7 ngày từ link tải; link cố định |
| Run Nhiệm vụ dở lúc bump mất cược | Hoàn cược khi khác `rules_version` + FLOW-5 |
| Số Nhiệm vụ sai vì khoá theo bot, không hiệu chuẩn | Tiêu chí N-S chặt; thẻ ghi "ước tính"; sửa m theo bậc theo tuần; theo dõi phân vị p90 |
| Mint Shard giả (không trần ngày, `won` do client) tới B3 | Liam đã chấp nhận; SR0 soi `run_close`; Worker kiểm rules/mở bậc; xem p90 lãi |
| Reset M1 không quay lại; cloud save đưa số cũ về | Qua SaveStore + ghi đè cloud save, test máy khác; snapshot D1 + cloud save; báo tester trước |
| RTT PB cao, egress Containers, D1 batch | SR0 đo trước (báo Liam nếu p95 > 1,2 s); SR-V đo trước và chạy nền; reset là ghi lô nhỏ + idempotency key |
| Conflict file chung | Mục 2: một chủ mỗi file, ngoại lệ có tên |
| Atia (13 quái) hoặc zip khung cosmetics từ Claude Design về trễ | AT không chặn R1-R3, chỉ đứng trước SR1 theo ưu tiên Liam (trễ thì SR1 chạy trước, câu hỏi 4); CF chờ Liam gửi zip, không chặn gì khác |

## 8. Cần hỏi Liam (4 câu, có khuyến nghị)

1. **Cho sim nặng chạy đêm / lúc không dùng máy (CPU đầy nhiều giờ), và khi QA cây chính thì Liam không chơi bằng save thật?** Khuyến nghị: có; sim ở worktree riêng, save thật không bị đụng.
2. **Tester nhận bản desktop thế nào, và có chấp nhận "bản cũ không chơi được, phải tải bản mới" không?** Khuyến nghị: có; link tải cố định (chỗ đặt do Liam chọn: R2 `axiedice.fun/download` hoặc Drive/Dropbox của Liam) + màn báo khi gặp 409.
3. **Reset M1 gồm gì và làm lúc nào?** Shard, Stone, unlock, tier/decor Land, chuỗi thắng Nhiệm vụ? Khuyến nghị: reset tất cả trừ Gem và lịch sử run, làm ở R3 trước khi mời tester rộng, để khỏi xoá hai lần sát nhau; báo tester trước 2-3 ngày.
4. **Atia (làn AT) đứng trước SR1: nếu brainstorm Atia chưa duyệt kịp ~10/11, có cho SR1 chạy trước, Atia làm sau R3?** Khuyến nghị: có (không để Server RNG đứng chờ), đổi lại R-Atia dời tới sau R3 và bump `-v` đi sau reset.

Đã quyết, không hỏi lại: Hướng B Nhiệm vụ (một thang 6 bậc, hoãn nâng nhà, mở bậc bằng chuỗi thắng, bật cược cả 6 bậc, khoá số theo sim bot), P1 (RTP bot 0,65), N6 bậc danh hiệu, giữ "heavy không lãi N1-N4"; Land gói beta + tier 2 = 20k + web nhẹ ưu tiên thấp; Server RNG PB (đo RTT trước), reset M1, không trần ngày, khách không ví/ranked/Nhiệm vụ; beta chủ yếu desktop + xoá tiến độ sau beta; chạy song song và commit/push/deploy từng hệ thống sau review độc lập + QA thật.
