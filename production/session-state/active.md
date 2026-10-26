# Axie Dice — trạng thái hiện tại

## ⇢ BẮT ĐẦU TỪ ĐÂY (26/10) — CHIỀU SÂU ĐỦ CHO BETA; LÀM HỆ THỐNG LỚN → VIỆC NHỎ V5 → QA KỸ → LIAM POLISH
Liam chơi v5 (24/10): "game đã có chiều sâu hơn, nhiều cái phải tính toán và phải làm hơn" → đủ cho beta, ngừng thêm chiều sâu.
Không nhớ đã chọn Anchor nào (dấu hiệu Anchor chưa đủ nổi); gặp "lỗi khó hiểu" nhưng quên → QA phải săn chỗ khó hiểu như bug.
Thứ tự Liam chốt 26/10 (mỗi hệ thống đi brainstorm → plan → Liam duyệt → làm):
1. Nhiệm vụ bản cực khó · 2. Land (tier + Land 3D sống) · 3. Quái Atia 3D · 4. Server tung xúc xắc (P0–P5) · 6. Khung cosmetics.
5 (Store tiền thật / monetization) TẠM BỎ QUA.
Sau đó: việc nhỏ v5 (cân Anchor/Embers, sim 2 Luật run + Magma Seed đang tắt, comment file luật, SaveGuard tool, t_desktop_signin)
→ QA thật kỹ (qa-lead viết plan trước) → Liam polish.
QA luồng thật trên production: Liam CHO PHÉP dùng tài khoản của Liam (26/10).
Liam trả lời 14 câu (26/10):
- Brainstorm 5 hệ thống song song, duyệt một lượt; chi tiết nhỏ agent tự quyết có số liệu + ghi lý do. Xong hệ thống nào (review + QA)
  thì commit + push axiedice + DEPLOY hệ thống đó (đã cho phép). Được xoá worktree cũ, phải kiểm kỹ chỉ xoá rác.
- Nhiệm vụ: bậc cao nhất người giỏi thắng <5%, bậc thấp nhất ~15–25%; giữ risk-to-earn (cọc Shard, không tiền thật); tên M6/M7 + chữ: agent đặt.
- Land: không sức mạnh combat; web bản nhẹ (ít Axie, ít decor), desktop đầy đủ.
- Atia 3D: đổi HẾT quái (5 boss Chimera đã có model 3D + màn giới thiệu boss từ trước, giữ). Budget web +60 MB tối đa, texture quái web thu nhỏ.
- Server RNG: bắt buộc online mọi chế độ kể cả desktop; không chờ mỗi lần tung: server gửi trước kết quả cả lượt (khoá mã băm), client hiện
  ngay, cuối run server kiểm.
- Khung cosmetics: mình viết prompt → Liam dán Claude Design → gửi zip về.
Kiểm hiện trạng 26/10 (sửa ghi chú cũ): Nhiệm vụ bản cực khó ĐÃ viết 12/10 (Liam duyệt 13/10), N1-N3 live, N4-N6 + nâng nhà tắt, chưa sim,
cần chỉnh lại theo mục tiêu 26/10. Land: 6 tier 3D + decor + raid có; thiếu web nhẹ, Stone/tier chỉ client, nâng không đổi cảnh, Gallery.
Atia: 27/27 quái ĐÃ 3D (21 Atia + 5 Chimera boss); 3 thư mục boss cũ `assets/atia/{frost_lord,mirror,plague_mother}` là rác trong pck → hỏi Liam
"đổi hết quái" nghĩa là gì. Server RNG: P0-P2 xong, P4 một phần, P3 (verifier server) + P5 chưa; RemoteEpochSource chờ từng request.
Khung cosmetics: 27 khung trong game (21 + 6 Reef), round 4 đã sửa cắt mép; "19 khung vẽ lại" là ghi chú cũ. Còn: Legendary không có khung
trong pool Echo Box, khung mốc Land mượn, pool 223 id placeholder.
Brainstorm XONG + review 2 vòng APPROVE (26/10), CHỜ LIAM DUYỆT: `design/proposals/nhiem-vu-beta-brainstorm.md` (+ `-review.md`,
economy-designer), `design/proposals/land-beta-brainstorm.md` (+ `-review.md`, creative-director),
`docs/architecture/server-rng-beta-brainstorm.md` (+ `-review.md`, security-engineer). LIAM DUYỆT 26/10 từng câu (dòng đầu mỗi doc): hoãn nhà; khoá số theo sim, không hiệu chuẩn; bật cược; giữ heavy không lãi; Land gói beta; DESKTOP chính + XOÁ tiến độ sau beta; PB→PA nếu RTT cao; RESET số dư; KHÔNG trần payout; khách như khuyến nghị. Atia = THÊM quái mới (brainstorm `design/proposals/atia-roster-expansion-brainstorm.md`, 12 con, review APPROVE); khung cosmetics = 8 khung (`design/proposals/cosmetics-frames-round6-brainstorm.md`, prompt `design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`, APPROVE). PLAN `production/beta-plan.md` (+ `-review.md`, producer APPROVE vòng 2) LIAM DUYỆT 26/10 (sim đêm OK; desktop link cố định + màn có bản mới; RESET HẾT KHÔNG ĐỂ LẠI GÌ kể cả Gem + lịch sử run; Atia trễ thì SR1 trước; Atia hướng B). **int/r1 (worktree ../my-game-wt/ir1) = godot-port + N-W f45709c + N-C f526bd2 + V5 a23b641 (đều review APPROVE), Worker 290/290. Sim v1 (`mission-sim-v1.md`): KHÔNG Anchor thì bot A0 chỉ 8,3% → Liam 26/10: CHO ANCHOR VÀO RUN NHIỆM VỤ (int/r1 5ecc08f, đổi kết quả run, vào bump -u). Sim v2 có Anchor đang chạy → `mission-sim-v2.md`; xong thì lane I ghi số thật vào missions.json (xoá `_tmp`), bump `-u` + SUPPORTED + fingerprint, suite AXIE_RELEASE=1, review, QA FLOW-1..6, R1 deploy (web + Worker + D1 0010 + desktop). SR0 phần 2 (PB bay ngay + `[epoch_rtt]`) review APPROVE, ĐÃ vào int/r1 (75bdca6). AT xong (beta/at, review APPROVE WITH CHANGES; anti-stall dài do đội đi kèm, Elite mới = Elite gốc; cần lane I bump `-v` + floor 240 lúc R-Atia). LD-A xong code (beta/lda 24c697d, review code đã sửa), còn chụp ảnh 2 cỡ + review UX khi máy rảnh.** **Liam 26/10: GIỮ PB (RTT thật 12 mẫu p50 ~0,8 s, 2/12 > 1,4 s), theo dõi log `[epoch_rtt]` từ tester; QA tổng gom ≥100 mẫu/nền tảng.** **HOTFIX BUG-0003 ĐÃ DEPLOY (Undo mất bonus G; desktop b1705, web 742c9d4c) — tìm bằng soak --verify. Soak lớn (381 ô, ~24k nhanh + ~3,3k expert, replay mọi run) đang chạy đêm → `production/qa/soak/<ngày>/`; xong chạy `bash godot/tools/soak_matrix.sh report <ngày>`. R3 int/r3 1ca3a8e: suite 264/264, Worker 334/334, CHỜ LIAM xác nhận reset.** **R-ATIA ĐÃ DEPLOY 26/10 tối (godot-port 93b15a7, RULES -v, Worker baeeebf0, desktop b1696): `deploy-2026-10-26-ratia.md`. R3 (int/r3 = live + SR1 + econ remote + ECON_SHARD_WALLET; review tích hợp GO WITH CHANGES đã sửa 4412130) đang chạy suite; RESET cần Liam xác nhận lần cuối (xoá cả ví Gem).** **R2 ĐÃ DEPLOY 26/10 tối (godot-port 37be7c9, web md5 e92b8e2c, desktop b1678): `production/release/deploy-2026-10-26-r2.md`. Tiếp: R-Atia (int/ra 6c61f70, -v).** **R1 ĐÃ DEPLOY 26/10 tối (godot-port 5fe5150, Worker b0ed877a, D1 0010, web md5 ec72b6c2, desktop b1657 trên /download): `production/release/deploy-2026-10-26-r1.md`. Tiếp: merge int/r1 mới vào int/r2 + int/ra, chạy lại suite, deploy R2 (Land) rồi R-Atia (-v).** **Nhánh release dựng sẵn (26/10 tối): `int/r1` (ir1, tip 6742c83: N-W + N-C + V5 + SR0 p2 + DL + Anchor trong Nhiệm vụ + bump -u; suite 245/245, Worker 310/310; CÒN THIẾU số sim v2 trong missions.json) → `int/r2` (ir2 = r1 + Land, fingerprint ghim NO; suite đang chạy) → `int/ra` (ira = r2 + 6 quái Atia, bump -v f4798c8). SR1 (beta/sr1 + beta/sr1b): Worker kinh tế/Pass XP/claim/reset xong + review APPROVE vòng 3; client ví/offline/reset xong, đang chuyển Pass/Land/Stone Nhiệm vụ sang claim + sửa review client. SR-V local xong bước 2 (beta/srv). QA plan: `production/qa/beta-qa-plan.md`. Chờ Liam: tài khoản QA phụ, máy Windows, khung giờ, zip khung cosmetics; sau này: Containers hay máy riêng cho verifier, notarize mac.** **R0 ĐÃ DEPLOY 26/10 (Worker af75a7d1, rollback 31ad483d; `production/release/deploy-2026-10-26-r0.md`).** Đã merge vào godot-port: prelude, CL, N-S (tool sim), SR0. Xong + review, chờ release: N-W (beta/nw f7a2157, R1), LD-B (beta/ldb 76f0aab, R2). Đang: V5, N-C. Liam 26/10: Atia CHỈ 6 con tốt (bỏ thú làng); reroll GIỮ PB, đo lại RTT bằng run thật (log epoch RTT trong client, đo ở QA R1), p95 > ~1,4 s thì chuyển PA. ĐANG TRIỂN KHAI: prelude (MetaState 3 field + t_meta_fields_beta; suite 236, 235 xanh, chỉ t_desktop_signin) → đợt 1: N-S, N-W, SR0, V5, CL, LD-D. Tiếp: plan beta `production/beta-plan.md`. Đã xoá 42 worktree cũ (đều đã merge, nhánh giữ nguyên); file chưa commit duy nhất
không có ở cây chính (sim thô SA/LF + sweep B) đã sao lưu `../my-game-wt/_archive-2026-10-26/`.

## ⇢ BẮT ĐẦU TỪ ĐÂY (23/10 tối) — V5 ĐÃ VÀO GODOT-PORT (78346be), RULES -t, DEPLOY (xem cuối mục)
Liam giao 5 việc (23/10): (1) thêm Lõi + Luật run mới, (2) spam < 10%, (3) sửa Lõi ít kích hoạt, (4) thêm Anchor cho đa dạng, (5) polish để cuối.
Đã làm (mỗi phần review độc lập + QA luồng thật):
- 11 Lõi mới + 9 combo (design/proposals/cores-rules-v5.md mục 10 = bản Liam duyệt; c_magma_seed tắt chờ sim); 4 Luật run: Pack Alpha, High Stakes
  (stage ≥2) bật; Set Is King, Pilot Light tắt chờ sim (mục 11: bật bằng gen_cores.py rồi sinh lại .tres).
- Lõi ít kích hoạt: Fissure, Open Ranks, Tidecaller (2 mana), Steady Hold (+1/lượt giữ, max +3), Golden Egg (nở, 1/lượt); 52/52 Lõi ≥10% run (sim 6 lượt).
- 6 Anchor: thêm Kin, Embers, Big Hand (luật + thức tỉnh Unison/Passed Flame/Sixth Hand + UI chip EMBER/FREE/BONUS, sigil nhà mới).
  Lõi nhà đổi theo duyệt. Kin + Concord: Concord không chào dưới Kin.
- Chống spam: Vỏ Cộng Hưởng (Elite/boss có Vỏ = 25% max HP, viên ngoài BỘ chỉ 50% lên Vỏ), từ stage 2; UI: nhãn SHELL, coach C8 lần đầu,
  float "Outside a SET". Mana Quá Tải và Chuỗi Xen có code nhưng tắt (design/proposals/anti-spam-v5.md).
- Lỗi thật tìm được: fell_now dùng chung một cờ (combo Hoả Táng không cộng), 9 combo mới chưa vào nhà, Tidecaller trừ 3 thay vì 2,
  plate Thủ Lĩnh làm cắt cột intent ở 1280.
Sim (production/qa/sim/sim-v5.md): expert tự chọn 20.6, stage 2 ~21, random 12.5, spam 7.0, thức tỉnh 36-54% mỗi Anchor.
CHƯA ĐẠT: chênh giữa Anchor ~12 điểm (Kin 19, Volley 17, Gambler 13, Mana Mine 12, Big Hand 12, Embers 7) sau 3 vòng; Liam chốt deploy cả 6 rồi chơi.
Theo dõi: Embers yếu nhất; bot sim chưa chơi tốt Embers/Big Hand; comment cũ combat_engine.gd:1071 (file luật, sửa ở lần bump sau).
Deploy 23/10: godot-port 78346be, Worker 31ad483d (RULES -t), pck md5 919d6f31 khớp. Kiểm trên tài khoản Liam (Liam cho phép): run mới →
Luật run (offer ra Quick Beat / Crow Herald, chọn Crow Herald) → màn Anchor chào Kin / Gambler / Big Hand đúng chữ vòng 3. Dừng ở đó cho Liam chọn.
Worktree hôm nay (dọn sau): IV (int/v5), IVs, IVa1, IVa2, IVb1, IVb2, LF2, NC, NR, AN2, SP, SA.

## ⇢ BẮT ĐẦU TỪ ĐÂY (22/10 chiều) — ANCHOR MVP ĐÃ DEPLOY (godot-port 83d73bc, RULES -s, Worker 7aaffe19, pck md5 917649e0)
Liam chốt thêm hôm nay: (1) Anchor mở cho run ONLINE thường (web chạy online: epoch_source=remote) — `pick_anchor [index]` vào action log +
ALLOWED_FNS 3 chỗ, Worker chặn ranked/daily/mission và stage 1; (2) Anchor mở từ STAGE 2 (tài khoản Liam trên D1: runs_completed=1 = stage 2);
Mana Mine `min_stage: 3` (Overcast mở ở stage 3) — hiện thẻ khoá + lý do; (3) Gai tạm Spiked Shield tối đa 4 MỖI AXIE mỗi lượt;
(4) làm song song tối đa + việc gì cũng có QA (memory parallel-and-qa-always).
Lỗi lớn tìm ra bằng sim: `RunState.after_node()` không chặn khi màn chọn Anchor đang chờ → đếm node ảo (power_level +1 cả run). Đã sửa (c746fc0)
+ test. Đây là lý do mọi số "có Anchor" trước đó thấp ~10 điểm.
Số chốt (knob gốc, n 240-320): ép Gambler/Mana Mine/Volley 19.6/20.0/20.8 (chênh 1.2), expert tự chọn 24.1, random 10.0, spam 15.5 (chưa đạt ≤12),
thức tỉnh 60/49/42%, đột biến nhà bất kỳ 43-55%, expert stage 2 25.6, expert không Anchor 23.5. Báo cáo: `production/qa/sim/sim-anchor-mvp.md`.
Chữ: cả 3 Anchor không có giá thật ở knob này → bỏ dòng PRICE; Gambler ghi "Crack 15% (normally 30%)"; Mana Mine "first roll of a turn".
Review: lead-programmer x5 (engine, online, sửa, UI code, tích hợp), ux-designer (UI → đã sửa 6 điểm). QA luồng thật: t_anchor_flow_online_stage2,
_gut_progress, _pair_mutation, _awaken_in_combat (3 Anchor), _online_session (RunSetup→RemoteEpochSource giả) + t_replay từ chối Mana Mine stage 2.
Suite 224 (223 xanh; t_desktop_signin đỏ cả trên godot-port gốc ở máy này — kiểm lại khi máy rảnh). Worker 236/236.
Theo dõi sau playtest: spam 15.5, expert tự chọn 24.1 (Volley theo heuristic đội 32.8%). Run online dở của Liam trên -r sẽ không tiếp tục được (-s).
Deploy + QA trên web (22/10): md5 html/js/wasm/pck khớp. Phát hiện lỗi CŨ trên web: `RelicRegistry` liệt kê `res://resources/relics/`
mà bản export trả `x.tres.remap` → web KHÔNG nạp Lõi/Luật run nào (run mở thẳng ra map). Sửa 120f4a9 (`def_file_name`), test t_relic_registry_export,
giữ -s (luật không đổi), export + deploy lại. Server tính stage theo run online đã đóng (D1), không theo save client: tài khoản Liam có 1 run
đóng → stage 2. Đã kiểm trên tài khoản Liam (Liam cho phép): run mới → Luật run (chọn Hard Shell, bỏ Mystic Wasteland vì cắt còn 3 lượt Lõi)
→ màn chọn Anchor hiện, Mana Mine khoá đúng lý do. Dừng ở màn chọn, Liam tự chọn.
Worktree dùng hôm nay (dọn sau): IA (int/anchor), IA2, AF (anchor/ui-fix), PM (fix/pck-manifest), SA2-4 (sim detached).

## ⇢ BẮT ĐẦU TỪ ĐÂY (25/10) — ANCHOR MVP: ĐỦ CODE, CHƯA ĐẠT SỐ; CÒN SIM 6 MỐC → TÍCH HỢP → REVIEW → QA → DEPLOY
Liam chốt thêm (24-25/10): (1) TĂNG mốc chọn Lõi 4 → 6 mỗi run (vì 3 vòng chỉnh knob không đủ: combo/run chỉ 0.3-0.5); (2) cho hoàn tất merge
engine vào nhánh UI (đã làm). Mọi worktree SẠCH (không file sửa dở), không còn tiến trình Godot chạy.
Ba nhánh làn (chưa merge vào godot-port; RULES_VERSION vẫn -r, CHƯA bump):
- `../my-game-wt/AE` `anchor/eng` @ **60d55a6**: engine Anchor đủ (3 Anchor + giá, 6 nhà đột biến nấc 1/2, 3 thức tỉnh, cổng offline+stage≥3,
  R1 rút trục, bias nhà/trục, replay). Tóm tắt luật: `production/anchor-2b-brief.md` (worktree AE).
- `../my-game-wt/AU2` `anchor/ui` @ **8dce003** (đã merge AE 2a+2b): màn chọn Anchor, HUD ô Anchor + chip x/2→Awakened, chip AWAKEN trên thẻ Lõi,
  dải MUTATION, moment thức tỉnh AnchorFx + âm dm_awaken + hit-stop, Result + Codex tab Anchors (`MetaState.anchor_codex`), RunSetup bật
  `anchor: true`, sửa lỗi Luật run bỏ qua màn Anchor; test t_anchor_flow_start/codex/hud/mutation/awaken_ui/pick_ui; ảnh
  `production/qa/evidence/anchor_*` (AU2). Bàn giao: mục "AU2 - bàn giao" trong `production/anchor-contract.md` (AU2). Chưa: ảnh MUTATION
  trong trận, glyph nhà trong float, material_credit.ogg. CHƯA chạy cả suite trên AU2 sau 8dce003.
- `../my-game-wt/SA` `sim/anchor` @ **d533bd2** (= AE + godot-port tooling): bot sim Anchor (`--anchor=auto|none|a_*`), 3 vòng chỉnh knob
  (Volley 40/65/90 cap 20 set_add 0; Gambler Nứt 15% +0.35; Mỏ Mana Mặt Tạm 2; house_bias 5.0, axis_bias 3.0, partner_bias 3.0 mới) và
  **d533bd2 = 6 mốc chọn Lõi** (thêm sau Elite thắng đầu tiên không phải milestone + sau nút N; t_core_pick_points). Báo cáo
  `production/qa/sim/sim-anchor-mvp.md` (SA). SIM VỚI 6 MỐC CHƯA CHẠY.
Số trước 6 mốc (vòng 3): expert có Anchor 14.2 (mục tiêu 20±3, không quá ~21), random 6.7, spam 2.5, thức tỉnh Volley 17%/Gambler 52%/
Mỏ Mana 33% (mục tiêu ≥33% mỗi Anchor), đột biến Cặp nấc 1 ≤24% (mục tiêu ≥40%), 3 Anchor chênh 6.2 (mục tiêu ≤5).
Việc tiếp theo (thứ tự):
1. SA: sim 6 mốc (expert auto 160, random 120, spam 120, mỗi Anchor ép 80, expert none 120; Short A0 stage 3, lô 40); nếu expert > 23 thì
   tăng `difficulty.enemy_dmg_mult` 0.05/bước hoặc hạ knob Anchor (≤3 vòng). Ghi mục "Vòng 6 mốc" vào báo cáo SA. Nếu vẫn chưa đạt → hỏi Liam.
2. Tạo nhánh tích hợp `int/anchor` từ godot-port: merge AE 60d55a6 → SA (tip sau bước 1) → AU2 8dce003; grep marker, `--import`.
3. Bump RULES_VERSION → `-s` + `SUPPORTED_RULE_VERSIONS` (worker/src/run_do.js) + fingerprint t_rules_version; suite KHÔNG cờ skip + Worker test;
   cập nhật sàn test trong `.claude/docs/technical-preferences.md` (hiện 206/206, Worker 229/229).
4. Review độc lập: lead-programmer (engine + replay + save) và ux-designer (UI, ảnh 2 cỡ).
5. QA luồng thật (qa-tester, 4 test FLOW trong `production/qa/anchor-mvp-qa-plan.md` mục 3) ở stage của tài khoản Liam.
6. Merge vào godot-port, push `axiedice godot-port:main`, deploy: `bash export-web.sh` → `bash deploy-r2.sh --pck-only` → `cd worker && npx
   wrangler deploy` → `bash deploy-r2.sh --rest` → kiểm md5 `/index.pck` + html/js/wasm + mở axiedice.fun. Kèm nợ Worker trong
   `production/release/deploy-2026-10-23.md` (manifest key prefix `pck/`, md5 bắt buộc). Liam đã cho phép deploy gói này.
7. Báo Liam 3-5 dòng "để ý gì" (memory finish-then-deploy-for-playtest).

## ⇢ BẮT ĐẦU TỪ ĐÂY (24/10, cập nhật) — CÒN LẠI CỦA ANCHOR MVP (theo thứ tự)
Làn đang mở (mỗi làn có bàn giao trong `production/anchor-contract.md` của worktree đó):
- `../my-game-wt/AE` nhánh `anchor/eng`: bước 1 xong (b07c0df..435e6a9, cfbbe3d hợp đồng sự kiện). Bước 2a (RunState anchor_id/anchor_awakened/
  anchor_offer, cổng offline+normal+stage≥3, pick_anchor khoá trước offer đầu, R1 rút trục, bias nhà, reroll không bias, verifier bad_header) đang
  sửa 5 file CHƯA commit. Bước 2b (hiệu ứng 3 Anchor + đột biến 6 nhà + thức tỉnh, theo `production/qa/anchor-mvp-qa-plan.md` mục 5) CHƯA làm.
- `../my-game-wt/AU2` nhánh `anchor/ui`: màn chọn Anchor xong (7f519f2); HUD/chip x/2/AWAKEN đang sửa CHƯA commit; MUTATION, thức tỉnh AnchorFx +
  dm_awaken, Result, Codex `MetaState.anchor_codex` (được duyệt sửa MetaState) CHƯA làm.
- `../my-game-wt/LF` nhánh `fix/lowfire`: Key Strike = lỗi bot (đã sửa 9827d2f); còn prism/overflow/golden_egg/tidecaller/chimera_hunt/mana_ward/
  deep_current/thorn_rebound → ghi vào `design/proposals/core-visibility-fix.md` mục "Lõi ít kích hoạt".
Sau đó: merge AE + AU2 + LF vào một nhánh tích hợp → bump RULES_VERSION (-s) + fingerprint + Worker SUPPORTED → suite không skip → sim đo
(expert 20±3, mỗi Anchor chọn 10-25%, chênh ≤5 điểm; thức tỉnh ≥1 lần/2-3 run) → review độc lập (lead-programmer + ux) → QA luồng thật (4 test FLOW
trong QA plan) → kiểm khác biệt hiện ngay trong run thường (stage của tài khoản Liam!) → deploy (`deploy-r2.sh --pck-only` → `wrangler deploy` →
`deploy-r2.sh --rest`, kiểm md5) → báo Liam 3-5 dòng. Nợ nhỏ Worker (deploy log) gom vào lần deploy này.

## ⇢ BẮT ĐẦU TỪ ĐÂY (24/10) — ANCHOR MVP ĐANG CODE; LIAM: XONG HẲN RỒI MỚI DEPLOY + ĐƯA TEST
Liam chơi local "chưa thấy khác biệt" → luật mới (memory finish-then-deploy-for-playtest): không đưa bản dở; xong hẳn (engine + UI + sim + review +
QA luồng thật) → deploy web → kiểm khác biệt hiện ngay trong run thường → báo Liam kèm 3-5 dòng "để ý gì".
Liam chốt Anchor (23/10): Cặp có sức mạnh thật; thức tỉnh khi ≥2 Lõi ruột (khoá tới hết run); tên "Anchor". QA plan
`production/qa/anchor-mvp-qa-plan.md` (23 lỗ hổng + mục 5 cách bịt đã chốt). UX `design/ux/anchor-mvp.md` (+ token house_* đã ở godot-port bf0a618).
Làn: `../my-game-wt/AE` (anchor/eng: bước 1 data+API xong; 2a RunState/cổng/R1/cờ thức tỉnh đang làm; 2b hiệu ứng chưa), `../my-game-wt/AU2`
(anchor/ui: màn chọn Anchor xong 7f519f2; HUD/mutation/thức tỉnh/Result/Codex đang làm), `../my-game-wt/LF` (tra Lõi ít kích hoạt).
Hợp đồng sự kiện: `../my-game-wt/AE/production/anchor-contract.md`.

## ⇢ BẮT ĐẦU TỪ ĐÂY (23/10 đêm) — ĐÃ DEPLOY PRODUCTION, CHỜ LIAM DUYỆT ĐỘT BIẾN + LÕI CHỦ
**Production live** (Liam cho phép 23/10): D1 0008+0009; Worker `ea88583d` (RULES -r, phục vụ index.pck từ các phần R2 + manifest vì pck
359 MB > 300 MiB CLI; review bảo mật ĐẠT, nợ nhỏ ghi ở `production/release/deploy-2026-10-23.md`); web = build 805b6dc, md5 khớp, game boot
được. Có sự cố giữa chừng (web lên nửa → rollback Worker 4055be9c; lần ghép đầu cắt body) — đã xử lý. `deploy-r2.sh` (gitignore) có
`--pck-only` / `--rest`. godot-port = **43e1d9d** + docs: thêm âm 18/18 dm_* + gacha từ MyGame SFX (`asset-library/audio/mygame-sfx/`), suite
**206/206** không skip. Âm CHƯA lên production (lần deploy sau).
Chờ Liam 3 câu ở `design/proposals/mutation-and-keystones-v1.md` (Cặp có sức mạnh thật? Thức tỉnh khi 2 Lõi ruột bất kỳ? tên "Anchor"?)
rồi code MVP (3 Lõi chủ Tam Tấu/Con Bạc/Mỏ Mana + đột biến Cặp 6 nhà + thức tỉnh) gộp với sửa rút trục Lõi (`core-visibility-fix.md` R1)
trong MỘT lần bump. Sim đếm Lõi (`../my-game-wt/SVIS`) đang đo baseline.

## ⇢ BẮT ĐẦU TỪ ĐÂY (23/10 tối) — PHẢN HỒI PLAYTEST: RỜI RẠC, THIẾU ĐỘT BIẾN
Liam chơi b1393: "chưa đủ hay, còn rời rạc, thiếu đột biến khi chọn được combo Lõi đặc biệt" (ghi vào memory game-design-depth-priority).
Đang: (1) game-designer brainstorm `design/proposals/combo-mutation-brainstorm.md` (combo phải đổi luật/cách chơi, kiểu Duo/Legendary Hades,
Prismatic LoL Arena); (2) game-designer `design/proposals/keystones-v1.md` Lõi chủ làm mỏ neo nối Lõi thường + đột biến (Liam đồng ý làm);
(3) systems-designer `design/proposals/core-visibility-fix.md` (Lõi <10% run / không fire; Liam đồng ý làm); (4) âm: Liam chọn (a) MyGame
→ đã chép 44 SFX vào `asset-library/audio/mygame-sfx/`, sound-designer gắn ở `../my-game-wt/AU`; (5) **Liam CHO PHÉP DEPLOY** 23/10 →
devops-engineer đang deploy (D1 0008+0009 → wrangler deploy → export-web + deploy-r2), nhật ký `production/release/deploy-2026-10-23.md`.

## ⇢ BẮT ĐẦU TỪ ĐÂY (23/10 chiều) — BUILD b1393, ĐỘ KHÓ + MANA ĐẠT MỤC TIÊU
godot-port = axiedice/main = **805b6dc** (RULES_VERSION **-r**: Overcast 2 mana +0.5 cả BỘ, enemy_dmg_mult 1.55). Suite 205/205 không skip,
Worker 212/212. Build `build/AxieDice-0.1.0-L1-b1393-805b6dc-*` (b1377 → old). Sim vòng 2 (`design/proposals/v4-mana-decisions.md` cuối):
random 11.0, spam 10.5, free_hold 10.5, expert 18.8 (đạt cả 3 mục tiêu); Overcast +1.19 (giữ, sát nút), Mặt Tạm +2.84, Liều +1.49.
Tiếp theo (đề xuất, chờ Liam OK để code): Lõi chủ (GDD dice-depth-v4 mục 10, 5 Lõi chủ) + xử lý 8 Lõi <10% run và Hoá Thạch/Hòn Đá Mờ báo không
kích hoạt; QA lại cả build mới. Chờ Liam: playtest, nguồn 8 âm (MyGame hay Kenney CC0), deploy.

## ⇢ BẮT ĐẦU TỪ ĐÂY (23/10) — GÓI GACHA L + MANA ĐÃ VÀO GODOT-PORT, BUILD b1377
godot-port = axiedice/main = **04a83bc** (merge int/v4b): mana v4 (Overcast cả BỘ +0.4 3 mana; Mặt Tạm chỉ 3→4, 2 mana, 1 lần/trận) +
gói gacha L (14 combo 2 tầng `core_combos.json`, +1 reroll Lõi khi ráp Cặp cap 2, 3 Lõi meme, màn chọn Lõi lật/jackpot/cược quay/near-miss/
PAIR-FULL, banner combo, Result Combos, Sổ Lõi, daily combo) + RULES_VERSION **-q**. Suite **205/205 không skip**, Worker 212/212. Review: logic
APPROVED, UX 2 vòng (đã sửa). Smoke luồng thật `production/qa/smoke-v4b-2026-10-23.md` (không lỗi game; Mặt Tạm chưa kiểm được trong luồng thật).
Build `build/AxieDice-0.1.0-L1-b1377-04a83bc-*`. Đang: vòng 2 Overcast (`../my-game-wt/OC2`: 2 mana, +0.5, enemy_dmg 1.55; quy tắc cắt lỗ).
Sim mana vòng 1: Mặt Tạm +2.49 ĐẠT, Overcast +0.41 chưa đạt; expert 24, spam 9, random 16. Deploy vẫn CHƯA (0008+0009 + Worker -q + web cùng lúc).

## ⇢ BẮT ĐẦU TỪ ĐÂY (22/10 tối) — GÓI GACHA LỚN (2 NGÀY) + MANA
Liam chốt gacha: B không lộ bậc, 2 tầng, chỉ hiện thưởng, được chậm (agent chọn nhịp), có Lõi meme, **gói Lớn ≤2 ngày**. Hợp đồng
`production/gacha-contract.md`. Làn: **GD** (`../my-game-wt/GD` data 14 combo + CoreCombos API + thưởng +1 reroll + sim rút thẻ + 3 Lõi meme),
**GP** (`../my-game-wt/GP` UI chọn Lõi A1-A3, A5-A8, B2-B3), **GM** (`../my-game-wt/GM` B5 combo nổ, Result, Sổ Lõi, daily, copy run card);
game-designer viết `design/proposals/meme-cores.md`. Mana: làn **MD** (`../my-game-wt/MD` 6751c99) xong + review (cần: bump -q lúc merge,
thêm 1 tamper Overcast ngoài BỘ, chặn Mặt Tạm lên viên đã Overcast); sim **SM** (`../my-game-wt/SM`) đang đo 8×200. Âm: axie-asset-sources
chỉ có SFX Origins (đã có) — hỏi Liam: (a) tìm trong ~/Downloads/MyGame hay (b) tải Kenney CC0 (khuyến nghị). Merge cuối: MD + GD + GP + GM
→ bump RULES_VERSION -q → suite không skip → build.

## Liam 22/10 (ghi nhớ thứ tự)
- **Polish để SAU CÙNG**, khi game design xong: Sảnh, Đổi mặt xúc xắc, Cược, Ascension thêm luật mới (thay vì +HP). Làm với **Claude Design**.
- Âm thanh: Liam bảo "lấy trong asset có rất nhiều". Repo chỉ có 118 .ogg (sfx/class 78, sfx/status 35, music 5); asset-library không có âm.
  Đang hỏi Liam có cho chép âm từ `~/Downloads/axie-asset-sources/` (cấm mở nếu chưa được phép). Trong lúc chờ: sound-designer map 18 event dm_* vào âm có sẵn.
- Mana: Liam giao mình quyết câu 1-2 (đã quyết từ số liệu bước 0, `design/proposals/v4-mana-decisions.md` mục cuối), đồng ý câu 3 (cắt lỗ).
  Làn MD (`../my-game-wt/MD`) đang code Overcast cả BỘ + Mặt Tạm 3→4 2 mana 1 lần/trận.

## ⇢ BẮT ĐẦU TỪ ĐÂY (22/10/2026) — V4 + A+ ĐÃ VÀO GODOT-PORT, BUILD b1304
godot-port = axiedice/main = **0aef367** (merge depth/V4 c22162f + RULES_VERSION **-p** + sửa trần uid Worker 9999999 vì token uid từ
100000; review security OK). Suite **192/192 KHÔNG cờ skip**, Worker **212/212**. Build `build/AxieDice-0.1.0-L1-b1304-0aef367-*` (b1196 → old).
A+ (Liam duyệt): bộ ba ×1.3 / bốn ×2.2 / năm ×2.6, An toàn lần đầu 1 mana, Mặt Tạm 3 mana không tạo Bộ năm, enemy_dmg 1.50, Lõi giảm giá
reroll sàn 1. Sim A+ (`production/qa/sim/sim-v4-metric-aplus.md`, 200 run cặp seed): expert 22.0 (mục tiêu 20±3 ĐẠT), spam 11.5,
random 12.5, free_hold 16.5; nhưng Liều/Mặt Tạm/Overcast đóng góp ~0 → đề xuất `design/proposals/v4-mana-decisions.md` (P1 Overcast cả
BỘ, P2 Mặt Tạm 2 mana 1 lần/trận) CHỜ LIAM 3 câu; bước 0 đo mana đang chạy (`../my-game-wt/SV4`). Deploy (CHƯA, hỏi Liam): D1 0008 + 0009
→ wrangler deploy → export-web + deploy-r2 CÙNG LÚC (client cũ bị stage_mismatch).

## ⇢ BẮT ĐẦU TỪ ĐÂY (đêm 22/10/2026) — V4 ĐỦ, ĐANG ĐO TAY NGHỀ
`../my-game-wt/V4` `depth/V4` = **7a3f76f**: engine v4 (review OK) + UI v4 (UX review 2 vòng, 5.1b, glyph, nhãn SET giữa nhóm) + knob TD r2
+ smoke luồng thật v4 6/7 ĐẠT (`production/qa/smoke-v4-2026-10-22.md`; A1 mana Tundra = cantrip, không lỗi; A2 sửa: một SlotSwapSheet)
+ bot sim v4. Suite 190/190 (skip t_rules_version). Sim v4 (`production/qa/sim/sim-v4-report.md`): random 14.4, spam 17.2, attack_only 3.7,
expert 28.6 (n=325), gap 14.2 (trước v4 5.6). CHƯA: expert ngang bản cũ (cần 18-23); ablation 150 run nhiễu, tắt cả 4 cơ chế vẫn 26.7%
→ chưa chứng minh quyết định đúng tạo khác biệt. Đang: `../my-game-wt/SV4` sửa heuristic expert (Liều/Mặt Tạm dùng sai) + ablation 300-500.
Sau đó: làn TD2 (`../my-game-wt/TD2` tạo sẵn) tăng độ khó trên v4; rồi bump RULES_VERSION + merge godot-port + build. Nếu quyết định đúng
vẫn không tạo khác biệt → báo Liam để chỉnh thiết kế (thưởng bộ 4/5), không chỉ chỉnh số. Deploy vẫn chờ Liam.

## ⇢ BẮT ĐẦU TỪ ĐÂY (tối 22/10/2026) — V4 ĐÃ GHÉP, ĐANG ĐO + SỬA UI
`../my-game-wt/V4` `depth/V4` = engine v4 (review OK bước 1-5, security Worker PASS) + UI V4U (0d40b84) + knob TD r2 (263534f,
plating.off_turns trả về 2, anti-stall 14); agent tích hợp đang thêm best_bo + chạy suite. TD xác nhận (trước v4): random 13.3,
spam 15.1, attack_only 3.4, expert 18.9 (gap 5.6) — đã khó hơn bản cũ 7-10 điểm, gap vẫn nhỏ. Đang: `../my-game-wt/SV4` dạy bot sim
v4 + ablation; `../my-game-wt/UF` sửa UI theo UX review (nghi lỗi đồng bộ banner BỘ 4 vs nhãn SET OF 3; chữ % Nứt nhỏ; bố cục
cụm nút 2 hàng). Ranked chỉ stage 3 (mặc định, báo Liam). Deploy: 0008+0009 → Worker → web CÙNG LÚC (hỏi Liam).

## ⇢ BẮT ĐẦU TỪ ĐÂY (chiều 22/10/2026) — V4 ENGINE GẦN XONG, UI ĐANG LÀM
`../my-game-wt/V4` `depth/V4` (đọc `production/v4-impl-brief.md` các mục "Bước N - xong/bàn giao"): bước 1 BỘ/túi M/Overcast +0.5;
bước 2 Liều/An toàn/rmode/pin/Nứt; bước 3 Mặt Tạm + T10; bước 4 trần thorn/poison, stage server (migration 0009), pin rmode+source
(339903c). Review bước 1-3 lead-programmer: chỉ còn thorn/poison (đã làm ở bước 4). Đang: bước 5 (poison relic qua stack_cap,
fake remote mã lỗi, MetaState.runs_completed, cả suite), security review Worker. `../my-game-wt/V4U` `depth/V4U` (UI theo
`design/ux/depth-v4/combat-v4.md`): mục 1 BỘ trên tray commit WIP be8a8e3, còn 2-6. TD: chốt knob r2 (enemy_dmg 1.45,
hollow 50, plating off 1) đang chạy xác nhận. Audio spec `design/audio/v4-dice-moments.md` (12 âm mới cần nguồn — hỏi Liam).
Deploy (CHƯA, hỏi Liam): D1 0008 + 0009 → wrangler deploy → export-web + deploy-r2 cùng lúc.

## ⇢ BẮT ĐẦU TỪ ĐÂY (trưa 22/10/2026) — V4 ĐANG CODE
QA vòng 2 (mục 6 QA plan): 12 lỗ hổng mới N1-N12 → systems-designer đang sửa GDD (chốt: N1 `reroll_paid_k` riêng; N5 trần thorn mỗi lần chuyển
mỗi Axie; N7 stage theo số run hoàn thành server đếm được; N10 Lõi chủ TÁCH sang bump sau, keystone pin theo tài khoản+số run).
Làn V4 (`../my-game-wt/V4`, `depth/V4` = godot-port + depth/OC): gameplay-programmer code BỘ + LIỀU (rmode, pin, Nứt từ epoch) + MẶT TẠM + sửa
Overcast thành +0.5 trong túi M, test trước theo ma trận QA, tamper T1-T10, Worker `pin_mismatch`. Sau đó: làn UI v4, TD chỉnh độ khó trên v4,
QA flow. Smoke b1196 ĐẠT (`production/qa/smoke-b1196-2026-10-21.md` ở worktree QA): Liam chơi được b1196; lỗi hiển thị: Pact hiện "never fired"
trong Result (pact thụ động) → sửa ở làn UI.

## ⇢ BẮT ĐẦU TỪ ĐÂY (sáng 22/10/2026) — V4 BỘ + LIỀU + MẶT TẠM: GDD → QA → SỬA GDD
GDD `design/gdd/dice-depth-v4.md` (đã design review systems-designer: bộ số khởi điểm bo.scale 0.8, crack 30%, max_total 3, quái hp/dmg ×1.30,
cộng MỘT túi M). QA lead: `production/qa/dice-depth-v4-qa-plan.md` (26 lỗ hổng: 2 chặn [Overcast nhân chồng; key `mode` đụng epoch enum],
12 nặng; G1-G21; tamper T1-T10; 10 test FLOW). game-designer đang sửa GDD đóng G1-G21 → QA lead kiểm lại → code. Làn OC (Overcast) review
PASS nhưng PHẢI sửa: +0.5 vào túi M thay vì ×1.5 sau trần; chưa merge, sẽ ghép cùng v4 + TD. Chờ Liam 4 câu (max_total 3 + giá 2/3 mana +
Nứt 30%; tài khoản cũ vào stage 3; tách Lõi chủ sang bump sau; bộ số khó hơn) + G4 (Aid reroll có Nứt/cap?).

## ⇢ BẮT ĐẦU TỪ ĐÂY (rạng sáng 22/10/2026) — LIAM: GAME PHẢI KHÓ HƠN
Liam chốt (cuối `design/proposals/turn-decisions-brainstorm.md`): bản mới phải THẤP HƠN bản cũ 5-10 điểm tỉ lệ thắng (cũ: random 20.6,
expert 28.6; hiện: 23.9 / 30.9 — đang dễ hơn, sai); bỏ "3 Đòn + Tự Nạp"; có Lõi chủ; có Overcast (độc lập); hướng (a) thưởng người giỏi +
khó chung, không phạt bằng quái. Đang chạy: làn TD (`../my-game-wt/TD`, sim loop chỉnh knob → mục tiêu random ≤12, spam ≤13, expert 18-22,
log `production/qa/sim/td-tuning-log.md`); làn OC (`../my-game-wt/OC`, action Overcast + UI + replay/Worker); game-designer brainstorm
`design/proposals/dice-depth-v4-brainstorm.md` → ĐÃ review, LIAM DUYỆT hướng BỘ + LIỀU + MẶT TẠM (dễ hiểu, QA kỹ); đang viết GDD
`design/gdd/dice-depth-v4.md` → QA lead soi lỗ hổng → code. Smoke b1196 (QA).

## ⇢ BẮT ĐẦU TỪ ĐÂY (gần nửa đêm 21/10/2026) — BUILD b1196
godot-port = axiedice/main = **6a83513** (thêm fix/core-overlay: overlay chọn Lõi tự hiện sau Luật run — lỗi chặn do smoke luồng thật
bắt; nhãn Cores; thẻ đã free; tween DiceRoller3D; tab Edit Land). Suite **167/167** ở cây chính. Build `build/AxieDice-0.1.0-L1-b1196-6a83513-*`
(b1188 → old). Đang chạy: smoke lại b1196 tới Result (`production/qa/smoke-b1196-2026-10-21.md`), sim trên bản mới (`../my-game-wt/SB2`).
Chờ Liam: 5 câu `design/proposals/turn-decisions-brainstorm.md` (quan trọng nhất: 3 Đòn + Nạp, Lõi chủ), 4 câu depth-tuning-v1,
6 câu gacha, deploy.

## ⇢ BẮT ĐẦU TỪ ĐÂY (khuya 21/10/2026) — ĐÃ MERGE + BUILD b1188
godot-port = axiedice/main = **759cabc** (merge int/v3: depth v3 + Land v1 + raid; RULES_VERSION godot-2026-10-20-o), suite **166/166**
không skip, Worker 196/196. Build Liam: `build/AxieDice-0.1.0-L1-b1188-759cabc-macos.dmg` + `-windows.zip` (b1049 → build/old). CHƯA deploy
(Worker/D1 0008/web — hỏi Liam). Đang chạy: qa-tester smoke luồng thật + ảnh (`../my-game-wt/QA`, báo cáo `production/qa/smoke-b1188-2026-10-21.md`);
sim nâng bot expert (`../my-game-wt/SB`; phát hiện: bật Hold làm expert −4 điểm → Hold chưa đáng giá hoặc bot dùng dở).
**PHÁT HIỆN LỚN (sim 2000 run/bot, bản depth/E):** random 20.6, spam 22.8, attack_only 5.0, expert 28.6 (+8 điểm); beam sâu không thắng
thêm (trần ~29%), Hold làm expert tệ đi, reroll mana không giúp, chọn Lõi theo combo không khác biệt → "dùng hết mọi viên" gần tối ưu =
THIẾU QUYẾT ĐỊNH THẬT. Chỉnh số (depth-tuning-v1) không đủ; game-designer đang brainstorm `design/proposals/turn-decisions-brainstorm.md`
(chi phí cơ hội trong lượt). Sim đang chạy lại trên godot-port 759cabc.
**SMOKE luồng thật:** nghi lần chọn Lõi 1 KHÔNG mở sau khi chọn Luật run (map rail chỉ có luật, còn ghi "Relics") — qa-tester đang xác minh.
Liam được dặn tạm khoan chơi b1188.
Nợ: core_impact lệch live 98 vs replay 83 cho rule_balance (chỉ hiển thị, có thể preview làm hook chạy thừa) — cần kiểm.

## ⇢ BẮT ĐẦU TỪ ĐÂY (đêm 21/10/2026) — TÍCH HỢP VÒNG 2 + SIM + CHỈNH ĐỘ SÂU
int/v3 vòng 1 XANH: 163/163 không skip, Worker 196 (5d35dfe; RULES_VERSION -o, Worker nhận -o + -n). Vòng 2 đang chạy (INT):
merge depth/FX cfca4ba (thorn không trần 2 phe, 3 Lõi thorn, sửa review Lõi, core_fired mọi Lõi + t_core_fires 62/63, Lõi cược bậc
Hoá Thạch/Hòn Đá Mờ/Quạ chạy thật, Kết Nặng) + depth/VZ 8d480d1 (Lõi hiện rõ: CorePanel nháy, chữ nổi, Result card Cores) → chỉ cập
nhật fingerprint, không bump mới. Review: FX tới ad1e931 OK, VZ OK; FX phần sau (b6c296a..cfca4ba) đang review.
Sim (`../my-game-wt/SB`, `tools/sim-balance`, `godot/tools/sim_balance.sh`): random 20.5 / spam 20.8 / attack_only 5.3 / expert 26.8 →
chưa đạt mục tiêu Liam (bừa ≤5, giỏi 15-25, gap ≥15). Bot expert đang được nâng (S0). Kế hoạch chỉnh: `design/proposals/depth-tuning-v1.md`
(đã review) — chờ Liam 4 câu (Q0 enemy_dmg ≤1.30, Q1 luật viên dư → mana có 3 ràng buộc, Q2 Aqua/Plant chờ sim, Q3 sửa bot trước).
Memory mới: game-design-depth-priority, new-content-must-be-visible.

## ⇢ BẮT ĐẦU TỪ ĐÂY (tối 21/10/2026, sau mất mạng) — VIỆC ĐANG CHẠY + CÒN THIẾU
godot-port = axiedice/main = c3d919c (đã push: K5 Deep Reef, docs). Không còn việc dở chưa commit ở worktree nào.
Đang chạy: (1) TÍCH HỢP `../my-game-wt/INT` `int/v3`: đã merge L, RV, depth/E (581bac4); còn depth/D 2b8477d → ui/result-bg e8306cc
→ đổi "Relics carried" → bump RULES_VERSION + Worker SUPPORTED_RULE_VERSIONS → full suite KHÔNG skip + Worker; (2) review nội dung
Lõi C+E (systems-designer, worktree DE); (3) công cụ sim `../my-game-wt/SB` `tools/sim-balance` (attack_spam vs greedy).
Liam 21/10: BỎ TRẦN THORN cả hai phe (lối thorn + shield) → làm trên int/v3 ngay sau bump, cùng đợt bump.
Còn thiếu sau tích hợp: chụp ảnh màn raid + Land (kéo thả chuột thật), UX xem lại ảnh UI làn D sau sửa, build desktop cho Liam,
cập nhật mốc test sàn, sửa theo review C+E + kết quả sim. Chờ Liam: deploy (D1 0008 → Worker → web), 6 câu brainstorm gacha,
Nhà Sưu Tầm (đề xuất lên Hổ Phách), Aid Refresh shop (đề xuất ẩn), khung mốc Land, 12 tên Deep Reef, quest trả thưởng node sau,
Xuống Trận auto-pick.

## ⇢ BẮT ĐẦU TỪ ĐÂY (khuya 20/10/2026) — ĐỢT DEPTH V3 + LAND V1, HẠN 2 NGÀY (Liam: tự quyết cách làm)
Worktree/nhánh (chưa merge gì vào godot-port; RULES_VERSION bump + deploy Worker gom lúc tích hợp, HỎI Liam trước deploy):
- DA `depth/A`: engine đợt 1 xong + review (f155bf0); đợt 2 đang làm (Giáp/Khiên Hồi/Phản Đòn/Hồi Ngắt/Đòn Nạp/affix, 6.7/6.7b).
- DB `depth/B`: hệ Lõi (bb77554 schema), đang làm offer/reroll/quest/Luật run.
- DC `depth/C` (từ B): nội dung 46 Lõi + 13 Luật run. DD `depth/D` (từ B): UI combat/màn Lõi/Luật run/map.
- K5 Deep Reef Epic: ĐÃ MERGE vào godot-port = 5e352d0 (chưa push), review art-director OK. Chờ Liam: 12 tên, uv1_scale 2.0 (họa tiết to hơn Epic cũ ~1.5x) hay 3.0, dấu màu trên viền Epic.
- Land v1: spec `design/proposals/land-v1-spec.md` (decor craft Shard 16 món, Sửa Land thả tự do, điểm thẩm mỹ + 8 mốc, raid ghost). Làn L (`../my-game-wt/L`, `land/L`, làm MetaState trước) + RV (`../my-game-wt/RV`, `land/RV`, Worker raid.js + 0008_raid.sql; rebase lên L khi L commit MetaState). Deploy Worker/D1 migration: HỎI Liam.
Thiết kế: `design/proposals/depth-v3-design.md` (mục 6.7/6.7b chống spam attack, 2/2b Lõi + Luật run, mục cuối = câu trả lời Liam).
Bàn giao từng làn (agent mới đọc đây): `production/depth-v3-contract.md` (mục "Làn X - bàn giao"). Cập nhật rạng sáng 21/10:
A: xong stash/reroll/hàng/knob/nhịp/affix9/A3/Giáp/Ward/Mend/Spite/affix A-B/Đòn Nạp (6d0588d); đang: team_can_break,
choose_affixes, chống kẹt, R12/R13, preview_damage. Sau đó: hook engine cho ~10 Lõi đang disabled (needs_hook, xem bàn giao C).
B: xong (4c44e39 + đang INV-6 + suite). C: 10 Lõi bật (9cc4567), agent mới đang sinh 27 Lõi + 13 luật bằng `godot/tools/gen_cores.py`.
D: combat HUD + màn Lõi/Luật (82c9f79); agent mới: merge depth/B, map icon + affix node, panel 6 ô, Giáp UI.
L + RV: XONG + review (lead-programmer, security-engineer), đã merge vào nhánh tích hợp `int/v3` (worktree `../my-game-wt/INT`,
dd531ce): suite 133/133 (+skip t_rules_version), Worker 196/196. Chờ Liam: deploy (D1 migration 0008 → Worker → web), khung mốc
Land đang mượn cosmetic Echo Box/Pass, cây Savannah to.
A: xong hết đợt 3 (5bc3cc8), đang review. C: xong (36 Lõi bật, 10 + 4 luật chờ hook). Làn E (`../my-game-wt/DE`, `depth/E` =
A + C + B đã merge 52dbeca): hook cho 10 Lõi + 4 luật disabled, chỉnh anti-stall (40 lượt → ~14). D: còn Giáp UI.
Kế hoạch ghép: int/v3 ← depth/E (đã gồm A+B+C) ← depth/D, rồi bump RULES_VERSION + SUPPORTED_RULE_VERSIONS + full suite.
B: xong + review 2 vòng (685440d). D: xong + sửa theo UX review (2b8477d). E: đang anti-stall + review a-d + suite.
Việc mới từ Liam (chiều 21/10): (1) nền màn Result xấu → làn RB (`../my-game-wt/RB`, `ui/result-bg`) dựng 3 phương án A arena/B run map/
C Land, chọn 1; (2) hướng "gacha vui, phấn khích khi ra combo Lõi kiểu LoL" → game-designer brainstorm
`design/proposals/core-pick-excitement-brainstorm.md` (đã review creative-director, chờ Liam 6 câu mục 4). Đề xuất tiếp: công cụ
sim cân bằng `sim_balance.gd`. Nền Result: XONG làn RB (dca163f, 3a097c5; phương án A = ảnh arena theo biome,
`godot/assets/ui3/result_bg/`), test lẻ xanh, chưa merge. Lưu ý: Result vẫn ghi "Relics carried" — đổi thành Lõi lúc ghép.
E: anti-stall xong (de0488f: Giáp mòn từ lượt 3, Mend 25%) — Liam để ý spam attack sau lượt 3.

## ⇢ BẮT ĐẦU TỪ ĐÂY (chốt trưa 20/10/2026) — SESSION MỚI = GAME DESIGN

**Cập nhật chiều 20/10:** bước brainstorm XONG, đã qua review creative-director: `design/proposals/depth-brainstorm-2026-10-20.md`
(chưa commit). Chờ Liam trả lời 10 câu ở mục 5 (gói 1/2/3, sim baseline, một hay hai lần bump...) rồi mới lên plan.
BLANK ở Vault = lỗi hiển thị, ĐÃ SỬA commit 46a508e (chưa push), t_vault 462 PASS.
**Liam trả lời (20/10 chiều):** game hiện RẤT DỄ, không cần sim baseline · Gói 3 nhưng gói gọn, triển khai trong 3 ngày ·
giữ full-heal · chấp nhận affix Elite/nhịp boss · mở lại UI-03 cho combat/map · chấp nhận bump lần 2 có kế hoạch · Focus quyết
cùng Hold · sửa INV-6 · mục tiêu: nghiện, run sau khác run trước, kết hợp sâu dice + vị trí Axie + relic + mana; relic làm lại
theo hệ "Lõi" (augments) của LoL ARAM Hỗn Loạn / Võ Đài. game-designer đang viết `design/proposals/depth-v3-design.md`
(thiết kế + plan 3 ngày) → ĐÃ review (lead-programmer mục 9b, creative-director mục 9c) → chờ Liam duyệt + 5 câu mục 10
→ mới triển khai 4 làn (A engine, B Lõi+Worker+INV-6, C nội dung Lõi, D UI+map). Chưa commit file thiết kế.
**Tối 20/10: Liam đã trả lời 5 câu (ghi cuối file thiết kế) và bảo làm.** Đang chạy: làn A (gameplay-programmer, worktree
`../my-game-wt/DA`, nhánh `depth/A`: stash, reroll mana, hàng trước/sau, knob độ khó, nhịp boss, affix Elite, hợp đồng
`production/depth-v3-contract.md`) + 2 agent nghiên cứu Lõi LoL (`design/research/lol-aram-mayhem-augments.md`,
`lol-arena-tft-augments.md`). Sau nghiên cứu: game-designer viết lại mục 2 (Lõi) + Luật run → mới mở làn B/C/D.
Session khác đã merge làn R (Brine fit 6.1) = 2b8582b.
**Làn A XONG + đã review (lead-programmer):** `depth/A` 65d4883..a254785 (8 commit), test mới t_stash/t_reroll_mana/t_front_row/
t_boss_rhythm/t_elite_affix, Worker 184/184. CHƯA merge, CHƯA bump RULES_VERSION (gom lúc tích hợp). Nợ: affix phải suy ra từ
seed/node để replay khớp (làn map); Gooey/Plague chưa tell riêng, Agony chưa có nhịp. Chờ Liam: Ascension A3 vô tác dụng
(khuyến nghị A3 mất reroll miễn phí) + lối "một chiều" là lối nào.
Mục 2 (46 Lõi, bỏ bộ) + 2b (12 Luật run) đã viết lại theo nghiên cứu + review vòng 2 (mục 9d). Chờ Liam duyệt mục 2/2b + câu
6-9 mục 10 + A3 → rồi mở làn B (Lõi+Luật run+Worker), C (46 Lõi + 12 luật), D (UI+map, gắn affix theo seed/node).
**Khuya 20/10: Liam trả lời hết (cuối file thiết kế):** lối một chiều = spam mặt attack; Luật run hiện SAU chọn đội; đồng ý lùi
reroll cả bộ ba; run đầu không luật; A3 mất reroll miễn phí. Đang chạy 4 agent: làn A (A3), game-designer (phá spam attack, thay
R12, việc mới cho A/C), làn B (`../my-game-wt/DB`, nhánh `depth/B` từ depth/A), làn K5 cosmetics R5 Deep Reef Epic
(`../my-game-wt/K5`, nhánh `cosm/r5`; gói ở `design/handoffs/cosmetics-3d/round-5/`; 12 tên đề xuất chờ Liam duyệt).
Sau: làn C (46 Lõi + 12 luật) khi B có schema; làn D (UI+map).
**Liam gửi sơ đồ ý tưởng vòng meta Land** (`design/proposals/assets/land-meta-idea-liam-2026-10-20.png`: gameplay → gold/
nguyên liệu/đồ công-thủ/thẻ sưu tầm → xây/nâng Land → trang trí → điểm thẩm mỹ → mốc → Pass; raid phá công trình + cướp gold).
Bỏ/thay Stamina và Inns. Brainstorm XONG + review (game-designer): `design/proposals/land-meta-loop-brainstorm.md`, chờ Liam
trả lời 7 câu mục 6 (câu 1 = Land có cho sức mạnh nhỏ không / C6). Phần chống spam attack (mục 6.7, 2.10, R12/R13) đang review
vòng 3; xong thì làn A làm 11 việc engine mới (cuối mục 9).

**Git:** godot-port = axiedice/main = **a6b7ba3**, suite **125/125**. Bản test Liam: `build/AxieDice-0.1.0-L1-b1049-a6b7ba3-macos.dmg`
+ `-windows.zip` (b945 → `build/old/`). Không có agent/Godot nào đang chạy.

**Đã xong 20/10 (không làm lại):** merge U/E/M/C/V/K/L/S/A — màn giới thiệu boss; hộp mùa + 3 danh hiệu; test/with_lock luôn
dùng user dir cô lập (cây chính an toàn khi Liam chơi) + chặn override.cfg lọt vào build; bỏ Dango; preload map; **6 boss Chimera**
(agony Venom, mecha Tempest, mirror Feral, plague_mother Parasite = mesh team Art, gooey_king Brine, frost_lord Brine xanh-tím);
boss nhìn về party hé ~12° (t_boss_facing); quái gọi ra 0.7 (t_boss_resume_summons); chữ đe doạ boss mới; số phase thật.
Blender đang mở scene `Chimera_Review` (6 Chimera + script `chimera_clip.py` đổi clip).

**TẠM DỪNG theo Liam (20/10 trưa).** Đã làm thêm sau mốc trên: Blight BỎ khỏi dự án (Liam; code không còn tham chiếu; còn 2 ảnh
nền + thư mục rỗng trong asset-library chờ Liam tự xoá vì lệnh rm bị chặn quyền); prompt Claude Design art Epic hộp thường =
`design/handoffs/cosmetics-3d/PROMPT-EPIC-ECHOBOX.md` (Liam duyệt Deep Reef, 12 món) → khi có art: thêm id vào `art_map` epic
trong `godot/assets/data/economy/echobox.json`, bỏ 2 hình Founder khỏi đó. **Brine to hơn: XONG** (merge 2b8582b, suite 125/125,
đã push): fit 6.1; trận có boss rộng (> 5.3 m, gồm Brine + Plague Mother) thì boss giữ mép phải, party lùi trái ~100 px; trận
thường/elite không đổi; t_combat_spacing không đổi. Chưa kiểm màn 4:3. Dọn: còn worktree B (suite) + R. Nhánh còn: l1/B-hooks, sim/quick-1012, claude/happy-herschel; nhánh script/* đã xoá (brine cbbac48,
feral 20e6a15, parasite 069dcc0). Thư mục save test cũ AxieDice-wt-* ngoài B/R chờ Liam tự xoá.

**Việc nhỏ còn treo (không chặn game design):**
1. Liam chơi b1049, duyệt Chimera trong game → rồi **deploy web** theo `production/release/web-deploy-2026-10-19.md`
   (HỎI Liam trước khi upload R2; Worker không cần deploy).
2. Brine đã to (fit 6.1, 2b8582b); Tempest nhìn party nên thấy cánh từ cạnh; vỏ kiếm Parasite: UV FBX không khớp
   texture team Art gửi → đang chiếu lại vùng texture (nhờ team Art sửa UV nếu muốn đúng gốc). Blight Chimera chờ team Art.
3. Art Epic thật cho hộp thường (đang mượn hình Founder); phím B/S ở Run setup chưa vào tab Controls.
4. Dọn worktree cũ (A,C,E,K,L,M,S,U,V,SIM; nhánh script/* giữ tham khảo bản Chimera dựng tay).

**PHASE TIẾP: làm lại game design cho sâu hơn** (Liam: mechanics hay nhưng chưa đủ sâu). Quy trình: brainstorm → plan → Liam
duyệt → làm (CLAUDE.md). Đầu vào: `production/backlog-after-b931.md` mục B + C (Vault trống ô = mặt dice BLANK → thiết kế lại
cách part sinh mặt; chiều sâu xây đội part/bloodline/synergy; lựa chọn trong trận; cơ chế quái/boss; quyết định trên map;
tiến triển dài hạn Land/Ascension/Nhiệm vụ; Nhiệm vụ cực khó; kế hoạch phase toàn dự án; sim cân bằng). Mọi thay đổi luật gom
MỘT lần bump `RULES_VERSION` (+ comment "Mythic" bậc 4 cũ, Result Ranked/mất cọc) và deploy Worker (hỏi Liam).
Doc: `design/gdd/systems-index.md`, `build-spec.md` (INV-1..7), `economy-progression.md`, `godot-port-rule-spec.md`.
Agent gợi ý: `game-designer` + `creative-director` (/brainstorm), rồi `systems-designer`, `economy-designer`.

## ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật sáng 20/10/2026 ~10:20, session "Session state active file")

**Cập nhật 11:30:** Parasite giờ dùng MESH TEAM ART Liam gửi (FBX + texture ở `asset-library/chimera-src/Parasite (Bug)/3D/Bug_01/`),
đúng nguyên bản (HAIR_SCALE 1.0); chỉ vỏ kiếm được chiếu lại vùng texture vì UV FBX không khớp texture gửi.
axiedice/main = **a6b7ba3** (suite 125/125). Team Art có mesh con nào khác → thay theo cùng cách (build_venom/build_parasite).

**5 Chimera boss đã vào game (merge d298ac4, đã push; mốc mới 125):**
agony = Venom (art team mesh, VenomPool `cover`), mecha = Tempest, mirror = Feral, plague_mother = Parasite,
gooey_king = Brine (màu tranh), frost_lord = Brine bản màu chính thức xanh dương-tím. 4 con sau = mesh AI Liam tạo bằng
Meshy/Tripo (`asset-library/chimera-src/<tên>/3D/*_ai.glb`), dọn + rig + 6 clip bằng Blender CLI
(`tools/art/chimera/build_<tên>.py`). Dựng tay bằng Blender script = Liam chê xấu, đã bỏ (nhánh script/* giữ tham khảo).
**Luật Liam:** boss LUÔN nhìn về phía party, hé ~12° về camera (facing_deg 7; test `t_boss_facing` ≤15° + phía camera);
intro có `intro_facing_deg` riêng. Quái do boss gọi ra vẽ SUMMON_SCALE 0.7 (cả khi resume), boss rộng có cột quái gọi ra
bên phía party (`WIDE_*` trong CombatStage3D, chỉnh khít theo `t_combat_spacing`, lề ~1 px). `fit_width_m`, `hover_m`
(Tempest bay), chip trạng thái theo đỉnh model. Mỏ Parasite: thẳng về TRƯỚC (tranh nghiêng `Bug_1.png` cột 3), tay tách áo.
**Còn lại:** Liam duyệt ảnh 5 Chimera trong game → push → export web + HỎI Liam trước khi upload R2 → build desktop.
Brine fit 5.3 (to hơn cần dời cổng/party — Liam quyết). Tempest nhìn party thì thấy cánh từ cạnh (hệ quả luật).
Meshy MCP đã cài (user scope, key trong Keychain `meshy-api-key`, cần gói Pro).

## (cũ hơn) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật đêm 20/10/2026, session "Session state active file")

**Git:** godot-port = axiedice/main **a9486d4** đã push (suite 123/123 ở worktree B). Sau đó merge chưa push: 0ed00cc (E: xác nhận hộp mùa
mỗi phiên) + 2acedd5 (U: dòng đe doạ boss + số phase thật) — suite 2acedd5 **123/123**. Mốc test: **123**.
**Đã merge hôm nay:** U (màn giới thiệu boss, nền lossy), E (hộp mùa + fingerprint 4871eef, giữ -n), M (user dir cô lập cho test,
không lọt override.cfg vào build: exclude + guard + quét pck sau export; shot.sh qua with_lock; bỏ Dango; sửa watcher import để lại
`sleep 240` mồ côi). `export-web.sh` (cây chính, gitignored) có guard override tạm.
**Cây chính giờ an toàn khi Liam chơi**: test/with_lock dùng user dir AxieDice-test-my-game (sau merge M).
**Liam trả lời 7 câu** (đầu `pending-decisions.md`). Chữ intro: giữ tiêu đề cũ, dùng dòng đe doạ mới.

**Đang chạy lúc ghi (kiểm git từng worktree nếu session chết):**
- Làn V `l1/V` 8b249aa: VenomPool che chỗ cắt hông Venom (intro + trận). Đang review → merge.
- Làn U `l1/U` 7470131: HUD boss "Phase X of Y" chỉ hiện khi > 1 phase. Đang review → merge.
- 4 Chimera dựng tay bằng Blender CLI (Liam: không có AI 3D; Brine dùng cho CẢ gooey_king + frost_lord, mỗi con 1 bộ màu):
  A = Brine (gooey_king, frost_lord), K = Tempest (mecha), L = Feral (mirror), S = Parasite (plague_mother). Brief chung:
  scratchpad `chimera-brief.md` (nội dung: build_<name>.py headless, 6 clip Idle/Attack/Hit/Dead/Cast/Roar, ≤3 MB, ≤25k tris,
  gắn qua `godot/assets/atia/atia_models.json`, ảnh intro + trận 1920/1280, suite).
**CẬP NHẬT (Liam, đêm 20/10): DỪNG làm Chimera bằng Blender script ("xấu quá").** 4 agent đã dừng, KHÔNG merge. Commit dở còn
trên l1/A 3b5857e (Brine), l1/S 8c81f1e (Parasite), l1/K, l1/L — chỉ để tham khảo rig/anim. Liam không muốn trả phí AI 3D.
Hướng tiếp (chờ Liam): xin mesh từ team Art như Venom, hoặc thử TRELLIS.2 (Microsoft, MIT, free trên HF Spaces) → GLB bỏ vào
`asset-library/chimera-src/<tên>/3D/`, rồi rig/anim theo pipeline Venom. Hunyuan 3D free nhưng giấy phép loại EU/UK/KR.
Làn V (VenomPool, field `cover` trong atia_models.json) + U (HUD phase) đã merge: d98bdd9. Deploy web với bản này.
**(cũ) Sau đó:** review từng con → merge (atia_models.json mỗi làn sửa 1 key, có thể conflict nhẹ) → suite ở B → push →
export web theo `production/release/web-deploy-2026-10-19.md` → **hỏi Liam trước khi upload R2** → build desktop mới.
Liam: "làm hết rồi deploy 1 thể".

## ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao 20/10/2026, session "Build b831 review và fixes")

**Trạng thái git:** cây chính `godot-port` = **ca8bed3**; `axiedice/main` = **ca26343** (merge Venom, suite 122/122 ở worktree B). Chưa push: chỉ merge làn C (preload map, ca8bed3) — chạy suite cho ca8bed3 ở worktree B rồi push:
`git -C ../my-game-wt/B checkout --detach godot-port && cd ../my-game-wt/B && AXIE_HANG_KILL=900 godot/tools/with_lock.sh $GODOT --headless --path godot --import && AXIE_HANG_KILL=500 bash godot/tools/run_tests.sh` → xanh thì `git push axiedice godot-port:main`.
**Bản build Liam đang chơi:** b945 (40e33c7). **Mốc test:** 122/122 ở 40e33c7 (+ t_arena_preload sau merge C).

**LUẬT MỚI (Liam 19–20/10):**
- KHÔNG chạy suite/Godot ở cây chính khi Liam chơi (chung user dir "Axie Dice"); merge ở cây chính, chạy suite ở worktree B/R detached. (Làn M đã làm cách cô lập hẳn, đang chờ review → khi merge xong thì cây chính cũng an toàn.)
- Không giới hạn số agent, tự chọn đúng chuyên gia; mỗi làn một vùng file; review + suite trước merge.
- CHỐNG TREO tuyệt đối: AXIE_HANG_KILL (120 test lẻ / 500 suite / 900 import-export), không vòng until/while; bật bộ canh treo (Monitor, `ps -axww`) khi có agent chạy, bật lại mỗi 30 phút. Luật chung cho agent: `production/agent-lane-rules.md` (trỏ agent tới file này).
- Art/UI coi như XONG (Liam). Phase sau: làm lại game design (session sau, brainstorm trước).

**Làn đang dở lúc bàn giao (agent chết theo session cũ — kiểm git rồi giao agent mới làm tiếp):**
1. **Làn M** `l1/M` fe75f6a (worktree M): 1c56816 test luôn dùng user dir riêng (temp override.cfg khi giữ lock) + fe75f6a xoá Dango (bỏ `[gui] theme/custom` khỏi project.godot). **Review = FIX FIRST, KHÔNG merge trước khi sửa:** (a) RỦI RO LỌT override.cfg VÀO BẢN EXPORT (build_desktop.sh chạy export qua with_lock → temp override.cfg có mặt lúc export; export-web.sh không khoá) → thêm `override.cfg` vào cả 3 `exclude_filter` trong `godot/export_presets.cfg` + guard trong `tools/build_desktop.sh` và `export-web.sh` dừng nếu `godot/override.cfg` có dấu `axie-temp-override`; kiểm lại bằng cách export rồi tìm override.cfg trong pck. (b) `with_lock_test.sh` dòng ~137/149: thay `sleep 1.5` bằng poll có giới hạn ~10 s. (c) Chụp 1280 Combat, Tutorial, Store, Leaderboard xem có mất theme không (InfoLabel/InfoPanel/log trong Combat.tscn, TutorialView, TutorialCoach dựa project theme). Sau đó merge + cập nhật FINGERPRINT nếu cần. (Bản b945 build TRƯỚC thay đổi này nên không bị ảnh hưởng.)
2. **Làn E** `l1/E` **6f5803c** (worktree E, XONG, suite 122/122 có skip fingerprint): 4488ffd tên M6 "Sturdy foes"/M7 "Fierce elites"; e487236 balance `production/qa/season-box-balance-2026-10-19.md` (không vỡ INV-1..7; full set trung bình 57,7 lượt ≈ 289 vé, tối đa 400; vé free cả mùa chỉ ~55–60 → hoàn thành set cần Gem/Nhiệm vụ — CÂU HỎI DESIGN cho Liam); 2302828 bật hộp mùa + tách pool (die_m_moon cũng bỏ khỏi hộp thường) + 3 danh hiệu ECHO WALKER / MOONBOUND / LUNAR ECHO MASTER (`title:<NAME>`); 6f5803c tab Seasonal + t_season_box. **Cần Liam:** bậc Epic hộp thường giờ chỉ còn Founder Seal/Laurel làm hình tạm (vốn là đồ Pass) → cần art Epic thật; tên 3 danh hiệu. Worker chưa có endpoint roll hộp (hộp thường cũng roll client). Việc tiếp: review → merge → tính lại FINGERPRINT (echo_box.gd, echobox.json; kết quả run KHÔNG đổi).
3. **Làn U** `l1/U` **5734b87** (worktree U, sạch; 9842203 hình nền + BossIntroData, 22dc39d màn BossIntro + phím boss_intro_skip + nối từ node boss, 5734b87 t_boss_intro; CHƯA chụp ảnh, CHƯA chạy suite đủ, CHƯA review — agent bị dừng khi bàn giao): **màn giới thiệu boss** — spec `design/ux/screens/52-boss-intro/spec.md` NHƯNG theo quyết định Liam: luôn bản đầy đủ; model 3D boss đứng trước hình nền TRƠN `asset-library/chimera-src/Backgrounds/Chimera_BG_<Name>.png`, animation mạnh (đẩy camera, Roar, chớp sáng tôn trọng Reduce flashing, bảng tên); 5 Chimera (Blight để sau); boss chưa có model Chimera thì dùng model hiện tại + nền cùng hệ; phím skip là action KeyBindings mới; resume bỏ intro.
4. **Boss Chimera:** Venom xong (godot/assets/bosses/chimera_venom/, pipeline `tools/art/chimera/build_venom.py`, gắn boss `agony`). **Chờ Liam duyệt Venom** (ảnh `production/qa/evidence/chimera/`) → dựng Brine (Aqua) bằng Blender theo tranh `asset-library/chimera-src/Brine (Aqua)/` → duyệt → Feral, Parasite, Tempest. Liam: Chimera THAY CẢ 3 boss trong run (chia slot sau khi đủ model). Venom hơi mảnh trong trận (cỡ do `_fit_atia_model`); Cast/Roar chưa dùng trong trận (Roar hợp đổi phase). 4 biến thể Venom 02–05 ở scratchpad cũ, chưa commit.
5. **Deploy web** (Liam duyệt, chấp nhận ~253 MB): sau khi M/E/U merge → làm theo `production/release/web-deploy-2026-10-19.md` (dọn `web/_pckparts`, `.DS_Store` trước khi `deploy-r2.sh`). Worker KHÔNG cần deploy (code không đổi từ 16/10, 184/184). Xoá `../my-game-wt/R/build/web-stage` (~250 MB, agent bị chặn quyền xoá — hỏi Liam).
6. Sau cùng: build bản Mac/Win mới (`bash tools/build_desktop.sh`), dời bản cũ vào `build/old/`.

**Còn trong backlog (đã duyệt):** `production/backlog-after-b931.md` — B gom bump RULES_VERSION với game design; C game design (session sau; Vault "trống ô" = mặt dice BLANK → thiết kế lại cách part sinh mặt); token Worker để sau L1. Phím B/S ở Run setup chưa vào tab Controls.


Cập nhật: 2026-10-12. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).

## ⇢ BẮT ĐẦU TỪ ĐÂY (tối 18/10/2026, Liam review b831)

Liam chơi b831, gửi 11 mục. Đã điều tra (chưa sửa code), đang chờ Liam trả lời câu hỏi rồi mới làm:
1. Reroll vẫn là khay 2D cũ (`reroll_fx.gd`), chỉ lượt tung đầu dùng `DiceRoller3D` → chuyển reroll sang 3D (M).
2. Bố cục trận: spec round 2 đặt Axie trái, quái phải; game vẫn dọc (`CombatStage3D.gd` :325, `CombatArena3D.gd` theo trục z) → xoay sang ngang, cổng sau quái, chạy ngang qua cổng (L).
3. Bấm phím tắt văng game: SIGSEGV thật (`~/Library/Logs/DiagnosticReports/Axie Dice-2026-10-18-*.ips`), chưa tái hiện, đang hỏi Liam màn nào/phím nào. Lỗi phụ: `UnitPortrait.gd` connect `gui_input` 2 lần (:411/:443).
4. Land: bỏ biển tên + badge, kéo nhà vào giữa (`BUILDINGS` Land.gd:48), cây không lòi ra ngoài (`_build_props` :585).
5. Prompt cosmetics 3D: `design/handoffs/ui-03-redesign/PROMPT-COSMETICS-3D.md` (art-director đã review) → Liam gửi Claude Design.
6. Cho trùng Axie free trong party, Vault mỗi con 1 lần (RunSetup.gd:208/225/792/1394, `team_presets.gd` là file luật → bump).
7. Echo Box thẻ Stone dùng ảnh `UI3.icon("cur_stone")` (EchoBoxScreen.gd:623).
8. Khung avatar lệch: `AvatarFrame.wrap` (Land.gd:1118), chưa rõ gốc, cần chụp.
9. Continue run không phản hồi: nghi `RunContinue.busy` chờ reconnect, không báo gì (Land.gd:1461).
10. Hiệu ứng (SHD/POI/THN) thành icon trên đầu unit, bỏ chữ trong bảng quái; chip "THN 2" đang trôi lơ lửng.
11. Run map: ô đã qua hiện ổ khoá (RunMapController.gd:410 `passed` → locked); nhấn 2 lần vào ô = đi luôn.

**Cập nhật 19/10 23:10:** godot-port = axiedice/main **40e33c7**. Suite **122/122** (worktree R). Bản test: `build/AxieDice-0.1.0-L1-b945-40e33c7-macos.dmg` + `-windows.zip`.
Từ b931: run map nền tím (reptile class art), "Enemy turn" không tràn, tab Settings > Controls đổi phím (KeyBindings, MetaState.key_bindings — fingerprint đã cập nhật, giữ -n), bỏ chữ P/L/C, Claim Gem (Daily + Store) chờ server, Vault thẻ gọn + ô Import, decor nửa sau Land (NFT_Item, +8 MB), cosmetics round 4 (viền mặt dice bo tròn, khung hết cắt mép). Art/UI XONG (Liam).
**Việc tiếp theo:** Liam duyệt `production/backlog-after-b931.md`, xác nhận Vault "trống nhiều ô" = mặt dice BLANK, rồi phase làm lại game design (brainstorm trước).

**Cập nhật 19/10 18:15:** godot-port = axiedice/main **4593e6b**. Suite **119/119** (chạy ở worktree R vì Liam chơi trên save thật — KHÔNG chạy suite ở cây chính khi Liam đang chơi). Bản test: `build/AxieDice-0.1.0-L1-b931-4593e6b-macos.dmg` + `-windows.zip` (b896 vào `build/old/`).
Từ b896: số N trên mặt dice (WEAKEN 3), battle log sang trái, cosmetics round 3, đội hình quái giữa trục cổng (2–3 con gần nhau, add 5+ hàng sau), Arctic bớt chói, 6 map trận mới làm bằng Blender (arena v2, `godot/assets/atia/arena_v2/`, pipeline `tools/art/arena_v2/`), xúc xắc rơi lưới gọn giữa 2 bên + không đè nhau + to thêm 15%, Land bớt cây (vài cụm, không chìm).
Còn: frame_m_eclipse vẫn bị cắt mép trên (cần Claude Design sửa); arena v2 tải đồng bộ lần đầu mỗi biome (web có thể giật, nên preload); kiểm dung lượng bản web (+15 MB map); Land tier 1 khá thưa (Liam xem).

**Cập nhật 19/10 14:00:** godot-port = axiedice/main **377135e**. Suite cây chính **116/116**. Bản cho Liam test: `build/AxieDice-0.1.0-L1-b896-377135e-macos.dmg` + `-windows.zip` (b831 đã vào `build/old/`).
Đã merge 19/10: làn U (icon enrage, hiệu ứng skill đầu trận nhỏ trên caster), làn K (cosmetics 3D round 2: skin xúc xắc 3D, trims, khung ×1.5, Profile, Echo Box, Store, icon Stone/Ticket/Fragment, 41 tên Liam duyệt), làn C (giãn khoảng cách trận, quái theo chiều cao Axie, boss 2.6×, cổng trên đường tiến sau quái + ngoài cột bảng quái, xúc xắc rơi giữa màn hình).
Còn: prompt cosmetics round 3 (`design/handoffs/cosmetics-3d/PROMPT-ROUND-3.md`, 6 mục) chờ Liam gửi; ô thưởng Pass chưa theo tile 48; web size_limit 256 cho skin khi build web; theo dõi 11 xúc xắc có đè nhau lúc dừng không; cổng hơi nhỏ so với boss, Thornback hơi bé.

**Cập nhật cuối tối 18/10:** đã merge vào godot-port (CHƯA push, chưa build): làn M (e90646a: trùng Axie free, Stone Echo Box, run map),
fingerprint f7ec3ca (kết quả run KHÔNG đổi, giữ -n, không cần deploy Worker), làn U (5a7585f: reroll 3D, icon hiệu ứng trên đầu),
làn L (crash phím tắt Land + 23 màn, Continue, bỏ biển tên, nhà vào giữa, cây trong land, khung avatar), làn C (bố cục trận ngang 3/4).
Suite cây chính **113/113**. Việc sau của làn C (review gợi ý, không chặn): quái sát nhau khi 3 con (ENEMY_CENTER_X), xúc xắc rơi
chạm quái, cache pad texture quái; chưa chụp 4–5 quái / boss+summon / 4 Egg. Thiếu art icon enrage. Hiệu ứng skill đầu trận (đốm sáng to) cần xem.
Cosmetics: Claude Design trả round 1 → `design/handoffs/cosmetics-3d/round-1/_zip/`. Prompt round 2 (chờ Liam chốt 3 câu ở đầu file rồi gửi):
`design/handoffs/cosmetics-3d/PROMPT-ROUND-2.md`. Việc tiếp: Liam test bản build mới (cần build lại từ godot-port), push khi Liam bảo.

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 18/10/2026)

**Đang làm: port UI-03 (Claude Design, A4 Blend trên Terrariums) vào game.** Kế hoạch làn: `production/ui3-port-plan.md`.
Bản giao round 1: `design/handoffs/ui-03-redesign/round-1/handoff/`. Màn chưa có mockup: `round-1/GAP-LIST.md`. Prompt round 2 đã
gửi Liam: `design/handoffs/ui-03-redesign/PROMPT-ROUND-2.md`. Quyết định Liam 18/10 ở cuối `pending-decisions.md`
(cả 25 màn, xúc xắc 3D vật lý làm luôn, giữ bắt đăng nhập, font Rowdies + Work Sans).

**Đã merge 18/10:** xúc xắc 3D (`DiceRoller3D.gd`, mô hình Blender `godot/assets/dice/axie_die.glb`, nguồn `tools/art/dice/axie_die.blend`)
và nền UI-03 (`godot/scenes/shared/ui3/UI3Theme.gd`, `UI3.gd`, `tokens_ui3.json`, font). Suite cây chính **104/104**.

**UI-03 đã port HẾT các màn trong bản giao round 1 + 2 (axiedice/main 3f014fe, suite 110/110 không SKIP).** Thêm 19 Store,
25 Vault (Use in team → Run setup), 29 codex/guides/unlocks, AccountUI, 43 tooltips, 45 victory march, 30/39/42 combat, MainMenu
chỉ còn chuyển hướng, TeamSelect + R3Shell đã xoá, `godot/CLAUDE.md` viết lại cho UI3. Live smoke `--full` PASS trên production (18/10).
**Bản cho Liam test:** `build/AxieDice-0.1.0-L1-b831-3f014fe-macos.dmg` + `-windows.zip` (cũ ở `build/old/`). Sau b831 đã merge thêm (4842dfe, chưa build): Vault preview 260, Scan, chip tài khoản UI3, Codex cột 920 + nhãn token, menu in-run thẳng hàng.
**Còn sau:** xoá hẳn DangoTheme/DangoScreen/dango.tres (còn `gen_theme.gd`, test `t_button_states`/`t_ui_laws`/`t_mockup_assets`, vài
dòng lẻ); trạng thái gửi điểm Ranked trên Result + câu "mất cọc" đúng theo hoàn cọc → gom vào lần bump RULES_VERSION.
**Chờ Liam:** tên M6/M7, duyệt chữ Claude Design tự viết (nhãn tóm tắt Defeat, câu lỗi…), test bản build mới.
Mỗi màn: review code + art-director xem ảnh 2 cỡ → merge đúng commit → --import → suite cây chính → push.

## (cũ 16/10) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao 16/10/2026 03:10)

**Đọc `production/l1-plan-16-10.md`** (định nghĩa "xong", thứ tự việc, quy tắc chống treo + tiết kiệm token).
godot-port = axiedice/main. Suite cây chính **102/102**. Worker **184/184**, deploy **4055be9c** (16/10, migration 0007 đã áp),
RULES_VERSION `-n`. Live smoke PASS trên production với code mới nhất.
Bản Mac cho Liam test sáng 17/10 (L2): `build/AxieDice-0.1.0-L1-b615-bbfc8fb-macos.dmg` (ổ "Axie Dice L1" đang gắn).

**Xong sáng 16/10 (session sau bàn giao):**
1. Build Windows: `build/AxieDice-0.1.0-L1-b616-9574922-windows.zip` (9574922 chỉ thêm doc so với bbfc8fb). Bản Win cũ b556 đã ở `build/old/`.
2. Polish plan v2 (`production/polish/polish-plan-draft.md`, 4fe15e4): ux-designer review → art-director sửa (vạch freeze sau Batch 2,
   Reward/Shop/Event vào Batch 2, mỗi mục có cách kiểm, còn 3 câu hỏi). Chờ Liam duyệt.
3. Làn U 3 việc (a95d2dc, 6a631e6, c8d8d18) → lead-programmer review MERGE → merge c88c997, suite cây chính 102/102 không SKIP,
   push. Live smoke `--full` PASS trên production (R ở c88c997). Còn nhỏ: test _atia_play chưa kiểm die/RESET/không connect 2 lần.
   b615 KHÔNG có 3 sửa này (build sau sẽ có).
4. Web gọn đã export: `web/index.pck` 205 MB (từ a100cf6 = code bbfc8fb). CHƯA deploy R2.

**Chờ Liam:** L2 test b615 (chơi run thường + Nhiệm vụ N1 + tắt wifi giữa trận + thoát rồi Continue); L3 đăng nhập trên Windows;
duyệt kế hoạch Polish. Quyết định Liam 16/10 ở cuối `pending-decisions.md` (L1 A đã làm, L4 bỏ, L5 vào Polish, L6 đã làm, L7 web-only đã làm).

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 14/10/2026)

**godot-port = axiedice/main (4ed21e7).** Suite cây chính **96/96 không SKIP**, Worker **163/163**. RULES_VERSION **`godot-2026-10-13-m`**.
Checklist: `production/l1-checklist.md`. Quyết định Liam 14/10: cuối `pending-decisions.md`.

**Xong 14/10 (đều review + suite cây chính):** C (bỏ FrontLine), C7 danh hiệu, C8 thưởng tuần Daily, C4 test, C5 polish Land v5,
C2 Daily + Ranked + leaderboard (Worker migration 0006), B11 R5 đổi thẻ pact (-m; R4 chờ ví chung LIAM-2), C6 Team presets + Leaderboard + Land upgrade (mở L1, giá gốc), C9 polish (cả 5 việc + MultiMesh lối đi).

**CHỜ LIAM DEPLOY Worker** (C2 + B11): `git pull axiedice main` → `cd worker && node --test test/*.test.mjs` →
`npx wrangler d1 migrations apply axie-dice-db --remote` (chỉ 0006) → `npx wrangler deploy`. Build game mới cũng cần (client gửi -m).

**Việc kế tiếp:** C6 còn Profile/Account, Cosmetics; đo FPS web (lối đi sân + Land) ở B8; B1 cuối + B3 (cần Liam), B7/B8 build.

**Bẫy hôm nay:** lỗi parse / thiếu `--import` sau rebase / dấu CONFLICT còn trong file → Godot TREO (luôn kill timer); test xanh ở
worktree nhưng đỏ ở cây chính vì save thật của Liam (không còn newcomer) → test phải tự đặt trạng thái; agent con hay chạm giới hạn
20 lượt → bảo commit từng bước nhỏ; vòng `until ! pgrep run_tests` không bao giờ thoát.

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao chiều 13/10/2026 — session mới đọc mục này trước)

**Việc đầu tiên: mở `production/l1-checklist.md`** (checklist L1, ô `[ ]` = còn làm). Quyết định của Liam: `production/session-state/pending-decisions.md` mục F–K + các dòng cuối file (đã chốt, không hỏi lại).

**godot-port = axiedice/main.** Suite cây chính **92/92 không SKIP**, Worker **152/152**. RULES_VERSION **`godot-2026-10-13-l`**
(Worker `SUPPORTED_RULE_VERSIONS` có tới -l). **Worker đã deploy 13/10 16:13** (gồm -l, pact_pick, telemetry, Continue miễn phí).

**Đã xong chiều 13/10 (đều qua review + suite):** B1 (điều kiện bật online), B2 (Aid/Continue trừ Gem), B3 code (màn đăng nhập),
B4 (số liệu + `worker/sql/l1_report.sql`), B5 (Nhiệm vụ N1–N3 + số bản cực khó -k), B6 (boss/elite đủ model), B9 (save cũ), B10
(Continue miễn phí người mới), B12 (cosmetics trong game), C1 (màn pact, -l), C3 (menu trong run), C5 (Land hub v5), C11 (cosmetics v8).

**Đang dở khi chuyển session (agent đã dừng cùng session cũ — kiểm tra rồi review + merge):**
- l1/L có commit chưa merge: cd2475b (Land v5: "5 runs" từ data, nút + Gem 44 px, chạm-để-xem, UI scale 0.85) — review FIX FIRST:
  `_is_touch()` chỉ dựa `is_touchscreen_available()` → laptop cảm ứng click chuột cũng 2 bước; cần chốt touch khi có
  InputEventScreenTouch thật + test HUD không đè dock ở scale 1.275. Đã có commit sửa 1cd678d (touch chỉ bật khi chạm thật + test HUD ở 1.275) — CHƯA review: cho agent khác review cd2475b..1cd678d rồi merge.
- l1/C: bỏ hẳn FrontLine (Liam chọn C) — đã có commit 20d73ee (xoá node + code, `_update_front_line` để no-op vì TutorialView còn đọc; suite worktree 91/91), CHƯA review: cho agent khác review rồi merge.
- Worktree R: file nháp `godot/tests/qa_b12_capture.*` untracked — xoá.

**Việc kế tiếp theo checklist:** B1 phần cuối (bật cờ remote trong `project.godot` [axie] + chạy trọn 1 run thật trên Worker),
B3 (Liam thử đăng nhập Google trên bản Mac/Win), B7 (build lại Mac Apple Silicon + Win), B8 (web), B11 (Aid R4/R5), C2 (Daily/Ranked),
C6 (màn R3 còn lại: Team presets, Leaderboard, Profile R3, Land upgrade), C7, C8, C9, rồi D1–D7 theo lịch.

**Bẫy quan trọng (đã cắn hôm nay):** merge commit đã review chứ không merge đầu nhánh; không `| tail -1` output merge (giấu CONFLICT);
test ở worktree xanh vẫn có thể đỏ ở cây chính vì save thật của Liam (có run_save + meta cũ) → test phải SaveGuard + tự đặt trạng thái
(newcomer, saved_run_probe); vòng chờ `until … pgrep run_tests` không bao giờ thoát nếu worktree khác đang chạy suite. Xem memory
`lane-merge-pitfalls`.

## (cũ) bàn giao sáng 13/10/2026 — sau đêm chạy liên tục)

**godot-port = axiedice/main** (đã push). Suite cây chính **85/85 không SKIP**, Worker **141/141**. RULES_VERSION
`godot-2026-10-13-i`. Mức sàn trong `.claude/docs/technical-preferences.md` đã cập nhật (file đó nằm trong .gitignore, chỉ trên máy).

**Đã merge trong đêm (mỗi lần merge đều có agent khác review + suite xanh ở cây chính):**
- A: luật Nhiệm vụ, end_run → record_run_outcome (+reached_boss), RemoteEpochSource sau cờ (mặc định local).
- B: offer v2, EN, boss miễn instant kill, 22 relic H1–H8 + 7 rework, pact live, trục G/A (trần G ×2,5), trần reroll,
  Eternal, pact_forced, **mở hết 14 relic ẩn** (không còn relic ẩn).
- C: Atia 3D, 6 sân biome (chọn theo hàng bản đồ, boss có biến thể), ánh sáng khớp Land, sửa khung/cổng.
- E: ví Gem remote, Pass v2 + việc tuần, ký quỹ cược Nhiệm vụ (nonce, an toàn khi tắt app), daily +500 Stone, hộp mùa (đang tắt).
- L: Land hub 6 tier, cổng xoay 90°, ánh sáng ấm, đất, decor dày, phím 1/3/4/daily mở màn R3, sửa lỗi khởi động.
- U: UI combat v3, AidPanel/DefeatPanel, "Elite row ahead" ở A9, số build 0.1.0-l1, chọn sân 3D.
- M (Round 3): Run Setup, Echo Box, Nhiệm vụ (cược thật qua ký quỹ), Store + Daily, Pass, Vault, Settings, Codex.
- S: RunSession, ví Gem khi đăng nhập (sau cờ), Continue boss 180, quà mùa 2×90 (bảng mùa server + điều kiện số run),
  token kid/jti + thu hồi, khoá trần quà nguyên tử, alarm hello.
- `.gitignore`: `src/` neo về gốc (trước đó giấu mesh sân và Land).

**Còn lại theo làn:**
- A: (xong, -i) header.newcomer lấy từ params. Nối màn pact gọi `RelicSlots.pact_forced`. Client gọi lại `/api/run/open` sau 1008 auth.
- B: xong bộ relic L1. Còn: sim cân bằng thật (sim F), sporegale có thể dùng `poisonSpread`.
- C: mystic/genesis chưa ai xem ảnh; chân trời boss vẫn phẳng (camera thấy ít trời).
- E: thưởng tuần Daily (4 ngày → 150 Shard + 2000 Stone) có data chưa có logic; ghép số vào bảng Aid catalog (giá Aid đang viết cứng trong CombatView).
- L: mảnh địa hình biome thật (mới có đất texture), tier 6 trời tím/đất hồng chưa chỉnh.
- M: M2 Team presets, M9 Leaderboard, M12–M14 Profile/Account/Cosmetics, M15 Land upgrade chưa làm; Vault giữ thẻ cũ (chưa lưới 5×4); hộp mùa UI (bật `enabled`).
- R: bản build Mac/Win ở `build/l1-2026-10-13/` (từ b2bd505, TRƯỚC Pass/ký quỹ/màn M sau) — build lại sau khi anh duyệt.
- S: ràng token với session (chờ anh quyết); M7 nhảy hàng chưa có spec server.

**Câu cần Liam quyết:** `production/session-state/pending-decisions.md` mục F (đã trả lời) + **G** (agent chọn tạm). Quan trọng:
G1–G6 Nhiệm vụ cực khó (doc `design/proposals/nhiem-vu-risk-to-earn.md` + review), Eternal (2 relic đầu, có tính relic khởi đầu?),
breakersward, A9 "Elite row ahead", việc tuần (XP ngoài trần ngày, mất nếu qua tuần), quà mùa 3/8 run, token không ràng session,
thu nhỏ 72 MB texture nguồn, hộp mùa (dup trả vé).
Review UI R3 để gửi Claude Design: `design/handoffs/ui-02-round3/REVIEW-art-director.md`. Sim nhanh: `production/qa/sim-quick-2026-10-12.md`.
Smoke: `production/qa/smoke-2026-10-13.md`.

**Deploy Worker: XONG (Liam, sáng 13/10)** — đã kiểm: D1 không còn migration chờ (0001–0005 đã áp), secret RUN_TOKEN_KEY có (RUN_TOKEN_KID không đặt → mặc định "k1", đúng code), `/api/gem/season_gift` trả 401 khi chưa đăng nhập (code mới đang chạy). Web R2 + build desktop: chưa làm lại.

**Các bước deploy (để tham chiếu lần sau):**
1. `cd worker && node --test test/*.test.mjs` (141/141).
2. `npx wrangler d1 migrations apply axie-dice-db --remote` — áp 0002, 0003, 0004, **0005_token_revocation** (0005 phải trước code).
3. `npx wrangler secret put RUN_TOKEN_KEY` (và `RUN_TOKEN_KID`; khi xoay khoá thêm `RUN_TOKEN_KEY_PREV`/`RUN_TOKEN_KID_PREV`).
4. Google OAuth: thêm redirect URI desktop (loopback) nếu dùng login desktop.
5. `npx wrangler deploy`. Cờ client `axie/epoch_source`, `axie/gem_wallet` vẫn "local" → người chơi chưa thấy thay đổi.
6. Web: `bash export-web.sh` (tắt editor) → `bash deploy-r2.sh`. Desktop: build lại từ godot-port mới nhất.

## (cũ, tối 12/10) bàn giao trước đêm

**Đang làm: sprint L1 — playtest nội bộ tải về, ra mắt 3/11/2026.** Kế hoạch: `production/l1-sprint-plan.md` (khối quyết định
đầu file), giao diện giữa các làn: `production/l1-interfaces.md`, bảng làn/worktree/quy tắc merge: `production/l1-lanes.md`,
nợ của làn I: `production/l1-tasks-I.md`, làn S: `production/l1-tasks-S.md`.

**Quy tắc làm việc đêm nay / sprint (Liam):** commit + push tự do (`git push axiedice godot-port:main`), duyệt theo tuần,
chạy liên tục; KHÔNG deploy (Worker/R2) khi chưa hỏi; mọi việc xong phải có agent khác review rồi mới merge.
**Dùng token cẩn thận:** đọc `production/agent-token-rules.md`, tối đa 4 agent cùng lúc, prompt gọn, agent mới cho việc mới.

**Worktree** `/Users/loc.tien.nguyen/my-game-wt/<A|B|C|E|L|M|R|S|U>` (nhánh `l1/<làn>`), mỗi cái có `godot/override.cfg`
(user dir riêng, khoá Godot riêng). Mọi lần chạy Godot qua `godot/tools/with_lock.sh`; worktree làn dùng
`AXIE_SKIP_RULES_FINGERPRINT=1`; cây chính thì không (phải xanh không SKIP). Sau rebase cần `--import` (class_name mới).
Nếu rebase bị chặn bởi `.import` untracked của echobox: xoá chúng (godot-port đã track).

**godot-port (= axiedice/main) hiện có:** ngày 0 (khoá, worktree), S (RunDO, canon, ví Gem server, login desktop),
R (build mac/win), A PR1 epoch + PR2 (hook H1–H8, Ascension v2, đồng hồ, attrition, spike, Continue, Aid R4/R6, Boon),
B relic v2 (133 relic, slots), C sổ Atia, E kinh tế + Store fixes. RULES_VERSION `godot-2026-10-12-c`. Suite 68/68 trước merge S.
**Cây chính còn sửa chưa commit:** `godot/tests/t_rules_version.gd` (FINGERPRINT sau merge S d9fbe77, không bump) +
`production/l1-tasks-I.md` — chạy suite ở cây chính, xanh thì commit + push.

**Lưu ý worktree bẩn lúc bàn giao** (agent bị ngắt do hết hạn mức): C 3 file, E 4, L 3, S 7 chưa commit — session mới
xem `git status` từng worktree, giữ/commit nếu xanh, không xoá bừa. Agent cũ của session trước có thể vẫn đang chạy nền một lúc.

**Chưa merge (theo làn, việc kế tiếp):**
| Làn | Commit chưa merge | Trạng thái / việc tiếp |
|---|---|---|
| A | 24b8d76 luật Nhiệm vụ, b7f270d end_run gọi record_run_outcome/pass_add_run_xp | 24b8d76 đang chờ review (lead-programmer). Tiếp: nối offer_ctx của B vào RunState (reward/shop/event/treasure/pact boss, shop_relic_count), R5 pact_reroll/pact_pick + ALLOWED_FNS + replay |
| B | 7ffcbb7 mô tả EN+boss immune (đã duyệt), ee2b582 offer v2 (đã duyệt), 83aefe9 thân 22 relic H1–H8 + 7 rework, 24dd998 pact live | 2 commit đầu đã duyệt MERGE (bump `-d`). 2 commit sau cần review. Còn: trục G/A, trần reroll a_chaos 6/4, relaybaton, Eternal sticker, pact bắt buộc A6/A10, mở nốt relic ẩn |
| C | 3f389e4, 8353d24, 011971f (Atia 3D + sửa review), 2935916 sân 6 biome, ef4bf9f ảnh lineup/arena | Review lần 2 báo commit cũ thiếu file arena — nay đã commit arena; cần review lại cả chuỗi + kiểm checkout sạch. Ảnh ở production/qa/evidence/ |
| E | 7f68d62 ví Gem remote (đã duyệt MERGE), 7ce7560 Pass v2 | 7ce7560 cần review. Tiếp: Việc tuần (3/tuần, 500 XP), MissionBoard theo `params.mission`/`mission_outcome` khi A merge |
| L | 50b016b LandNav, 888ec56 hub Savannah, a6ebd95 đủ 6 tier + nâng Land | Review xong: FIX FIRST, danh sách ở `production/l1-review-L.md`. Tiếp: **xoay cổng Portal 90° (Liam)**, **làm đẹp hub (Liam duyệt ưu tiên)**: ánh sáng ấm + bóng mềm, nền đất/mảnh địa hình biome thật, decor dày hơn, Pass ghi 29 Dec 2026 |
| U | 3 commit WIP (theme v3, khay 5 cột, AidPanel, DefeatPanel, banner) | CHƯA xanh. Tiếp: cho xanh, gọi `_combat.set_epoch(RunState.epoch)` sau `from_data`, màn đăng nhập desktop (AccountService.begin_desktop_sign_in), newcomer ẩn nút Aid, dòng "2 elite ẩn" ở A9, số build |
| S | e0fc845 (h_0 run_start) | Tiếp: nối RemoteGemWallet khi đăng nhập / set_gem_wallet(null) khi đăng xuất, RunSession + RemoteEpochSource (seq từ 0), giá Continue boss 180, kiểm nhảy hàng M7, endpoint quà mùa 2×90 Gem, tài khoản khách tối thiểu |
| M | chưa mở | Mở làn M: các màn meta theo Round 3 (`design/handoffs/ui-02-round3/_zip/`, README normative, 135 khung): ưu tiên Run Setup, Echo Box, Nhiệm vụ, Store+Daily, Pass |

**Claude Design Round 3 + phụ lục Round 2 đã về** (`design/handoffs/ui-02-round3/`), chưa review. Việc: art-director review
→ ghi chú sửa cho Liam gửi; làn M + U làm theo.

**Liam trả lời tối 12/10:** Pass: hết mùa vẫn nhận được thưởng đã đạt, chỉ dừng cộng XP · ưu tiên làm đẹp Land hub: CÓ.
**Liam trả lời thêm tối 12/10 (đã chốt, không hỏi lại):** (3) chấp nhận các chỗ [INF] của Round 3, code theo, gom danh sách
sửa cho Liam gửi Claude Design · (4) bỏ phần gamepad trong R3 · (5) KHÔNG deploy Worker trong đêm — sáng 13/10 Liam làm cùng ·
(6) thứ tự ưu tiên trong đêm: merge các commit đang chờ → U xanh → màn meta R3 (Run Setup, Echo Box, Nhiệm vụ, Store, Pass
trước) → đẹp Land hub → relic ẩn → sân biome → RunSession. Tối đa 4 agent cùng lúc. Chạy liên tục, không chờ Liam duyệt.

**Trước deploy Worker (hỏi Liam):** áp migration 0002–0004 lên D1 `axie-dice-db`, `wrangler secret put RUN_TOKEN_KEY`, có
thể thêm redirect URI desktop cho Google OAuth; Cloudflare gói Free.

Bản đầy đủ trước khi rút gọn: `archive/active-2026-10-12-before-rewrite.md`. Backlog trước 20/9: `archive/2026-09-pre-cowork/` (đã bỏ).

## (cũ, sáng 12/10) BẮT ĐẦU TỪ ĐÂY

**Cập nhật cuối 12/10:** đã chốt + review xong: kiến trúc server RNG (local `docs/architecture/`), monetization-v1
(cách B, PA-1, quà 180 Gem, status CHỐT — chờ sim), ascension-v2 bảng răng cưa, prompt UI
`design/requests/ui-redesign-request-02.md` (Liam gửi Claude Design). Tiếp theo: (1) Liam gửi prompt UI + ghi chú cosmetics
02 cho Claude Design; (2) technical-director thêm kind epoch cho R5 đổi pact; (3) sim F/G cho monetization + Ascension;
(4) viết lại Nhiệm vụ bản cực khó; (5) kế hoạch phase toàn dự án. Mục 1–3 bên dưới là bản sáng 12/10, đã xong.

1. **Mở `production/session-state/pending-decisions.md`** — 23 câu (A art, B monetization, C kiến trúc) + câu commit (D),
   mỗi câu có đề xuất. Liam nói sẽ trả lời ở session này. Đưa danh sách cho Liam, ghi quyết định vào đầu file nguồn,
   rồi làm "Việc sau khi Liam trả lời" ở cuối file đó.
2. Không có agent nào đang chạy. Không có server preview nào đang mở.
3. Có việc CHƯA COMMIT (xem `pending-decisions.md` mục D) — chỉ commit/push khi Liam cho phép.

## Quy tắc làm việc (Liam)
- Brainstorm → plan → làm → polish, đợi Liam duyệt giữa các bước. Có chỗ chưa rõ → hỏi.
- **Mọi việc xong phải cho một agent cao cấp KHÁC người làm audit/review** trước khi báo Liam.
- Thiết kế do agent làm chính (`game-designer`, `economy-designer`, `systems-designer`), Liam review.
- Không chạy nhiều agent song song nếu Liam chưa cho; thực tế đang giữ tối đa 2 cùng lúc.
- **Không mở/sửa `~/Downloads/MyGame` (Axie Infinity: A New Empire) và `~/Downloads/axie-asset-sources/`.**
- Gọi là "Nhiệm vụ", không gọi "hợp đồng".

## Tầm nhìn & hướng sản phẩm (đã chốt)
- Axie Dice thành game thật (không còn prototype Vibeathon). Nền tảng **Windows + macOS trước**, web giữ song song, mobile sau.
- Màn chính là **Land 3D** sống (Axie đi lại), các nhà là lối vào. Land là tài sản free, 6 tier Savannah < Forest <
  Arctic < Mystic < Genesis < LunaLanding, nâng bằng **Land Stone** (40k/100k/180k/500k/1M). Land KHÔNG cho sức mạnh combat.
- Combat giữ nguyên chiều sâu, chỉ bổ sung; không trait khắc chế; hồi đầy HP mỗi trận. Quái chuyển sang **Atia 3D**.
- **Hướng mới 11/10:** tạo ức chế TRONG RUN (quái/boss thật khó) rồi bán giải pháp (tiện lợi + sức mạnh trong run)
  bằng **tiền thật**, dùng được cả ranked. **Server tung xúc xắc ở mọi chế độ** (online-only). Nhiệm vụ KHÔNG gắn
  monetization — chỉ khó, là bài test risk-to-earn của Liam. Đã nêu rủi ro pháp lý (cược tiền có giá trị) → hỏi pháp lý Sky Mavis.

## Thiết kế — trạng thái từng file (`design/proposals/`, mỗi file mở đầu bằng khối quyết định của Liam)
| File | Trạng thái |
|---|---|
| `core-loop-v2.md` | Đã review; quyết định ở đầu file ghi đè thân file |
| `economy-v2.md` | **Chốt**: 2 tiền (Gene Shard, Land Stone), vé 200 Shard ×1,05/ngày cap 30, mỗi lượt Echo Box 1 phần thưởng, jackpot 0,02%/0,03%, heavy ~1 năm tới Luna (regular/casual chậm hơn — Liam chấp nhận). R ≈ 450 Shard/run (đo: `godot/prototypes/economy_probe/`) |
| `echobox-pass-v2.md` | **Chốt**, đồng bộ với economy: hộp thường (pool lớn, pity) + hộp mùa (kiểu Dota "Trove of Terror", 5 vé/lượt, đủ bộ ≤80 lượt, 12 tuần); Pass kiểu LoL ≥14 ngày, có 5 unlock chỉ số |
| `relic-audit-research.md`, `relic-set-v2.md`, `relic-set-v2-review.md` | **Bộ relic KHOÁ về thiết kế** (133 relic, 8+3 ô, trần nhân G ×2,5/Axie mặt dmg, 9 pact, 8 hook mới); số chốt sau sim |
| `ascension-v2.md` | Liam trả lời đủ; A1–A10 luật cố định; mốc enrage chốt sau sim |
| `nhiem-vu-risk-to-earn.md` | Bản 7 bậc đã viết; Liam yêu cầu **viết lại CỰC KHÓ** (chưa làm), nhà Nhiệm vụ nâng bằng Shard + Stone, bậc khó nhất dùng Full mode, server tung xúc xắc |
| `monetization-v1.md` (+ `-review.md`) | Đã định giá (Lunar Gem, 10 Aid, trần 8/run); creative-director: APPROVE WITH CHANGES, 3 BLOCKER → chờ Liam (pending B) |
| `design/registry/entities.yaml` | Đã đăng ký 18 mục economy |

Kiến trúc: `docs/architecture/server-authoritative-rng.md` (B2) + `-review.md` (lead-programmer) + `-security-review.md`
— **3 file chỉ có trên máy (docs/ bị gitignore)**. Chờ Liam (pending C).

Request cho Claude Design: `design/requests/cosmetics-art-request-01.md` (55 món), `design/requests/ascension-ui-request-01.md`.

## Art Cosmetics 01 (Claude Design, nhận 11/10)
- Nguồn + REVIEW: `design/handoffs/cosmetics-01/`. Đã xuất 20 die plate PNG 512 (mipmap bật) → `godot/assets/cosmetics/dice/`,
  5/21 khung → `godot/assets/cosmetics/frames/`, manifest `godot/assets/cosmetics/cosmetics_manifest.json` (spec 14 FX).
- SVG plate dùng filter → phải rasterize bằng Chrome headless (cách làm trong README của handoff).
- art-director: skin ACCEPT WITH FIXES, khung REJECT (cần vẽ 19), FX ACCEPT WITH FIXES. Chờ Liam (pending A).

## Đã làm (code) — đều đã commit + push trừ khi ghi khác
- Test không còn làm bẩn save thật; `run_tests.sh` FAIL test nào đổi save. Suite **56/56**. Worker **27/27**.
- Worker: rate limit sign-in/save, sửa typo /terms /privacy — đã deploy (version b73672cd).
- Prototypes: `godot/prototypes/land_spike/` (Land 3D khả thi; M3 Pro: 20 Axie ~200 FPS, 50 ~76; Compatibility chậm ~10×),
  `godot/prototypes/economy_probe/`. Công cụ `godot/tools/import_homeland.py`.
- Asset 3D: `asset-library/godot-ready/` (bản chép Godot-ready, 951 scene) + `asset-library/design-library/` — local, gitignore.

## Việc lớn còn lại (thứ tự)
1. Liam trả lời `pending-decisions.md` → sửa kiến trúc + monetization theo review, gửi Claude Design sửa cosmetics.
2. Viết lại Nhiệm vụ bản cực khó (+ review).
3. Viết lại kế hoạch phase toàn dự án (Land, combat batch gom một lần bump `RULES_VERSION`: relic hooks + Ascension +
   Aid + epoch seed, quái Atia 3D, server RNG P0–P5, store).
4. Bắt đầu triển khai theo phase.

## Bẫy
- Comment cũ gọi bậc 4 là "Mythic" (`reward_generator.gd:56`, `relic_def.gd:32`, `unit.gd:40`) giờ sai vì Mythic = 5 (chỉ cosmetic).
  Đây là file luật: sửa comment cũng làm đỏ `t_rules_version`, nên để gom vào lần bump `RULES_VERSION` chung.
- Lỗi parse GDScript làm Godot treo; Mac không có `timeout` → background + `( sleep N; kill $p )`.
- `godot/tools/record_sample_run.tscn` và `verify_run.tscn` CHƯA có SaveGuard — ghi đè save thật. Sao lưu
  `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` trước khi chạy bất cứ thứ gì.
- Chụp màn hình phải chạy KHÔNG `--headless`. Mọi ghi save qua `SaveStore`; field meta mới → sửa `MetaState.reload_from_store()`.
- Worker test: `cd worker && node --test test/*.test.mjs` (Node 24 không nhận `test/`).
- zsh không tách biến chứa tham số: dùng `${=var}`.
- Server tĩnh xem bản giao Claude Design: cấu hình `cosmetics-01` trong `.claude/launch.json` (cổng 8766).

---
**Session mới: đọc mục "⇢ BẮT ĐẦU TỪ ĐÂY" ở đầu file này, `production/session-state/pending-decisions.md` KHÔNG còn câu chờ (23 câu trả lời 12/10, 7 câu 20/10); chỉ còn mục D cũ.**
