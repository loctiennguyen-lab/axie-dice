# UI-05 — việc còn lại (bàn giao 1/11/2026)

## Trạng thái
- **Mới (1/11 chiều), CHƯA push/deploy:** `godot-port` @ `1a04951` = S7a Leaderboard (`12eceba`) + sửa polish của Liam
  (`fix/daily-remote` → merge `1a04951`): Daily online lấy trạng thái từ server (nút Claim tắt sau khi nhận, thẻ tuần đếm
  đúng, server tự trả thưởng tuần ở lần nhận thứ 4, nút Claim có cờ chờ), nút Land chỉ ghi "Upgrade Land" (chi tiết vào
  tooltip). **Deploy lần này phải `cd worker && npx wrangler deploy`** (Worker đổi `economy.js`), rồi export + R2.
  Worker 397/397; suite đủ trên bản gộp (worktree u5b-0 detached @ 1a04951, không cờ skip) **331/331**. RULES_VERSION không
  đổi (`t_rules_version` xanh).
- **Đã deploy** lên axiedice.fun: `godot-port` @ `68fd93a` (push `axiedice/main`). Gồm UI-05 đợt 1 + 2 + 3, chuyển động
  M2/M3, sửa lỗi QA F1/F2. Kiểm trước deploy: release_gate --suite 329/329 + Worker 395/395; QA luồng thật; flow UI cả run
  qua RunVerifier; soak 2856 run 0 xấu. Worker KHÔNG đổi (không cần `wrangler deploy`).
- Sổ đợt 2+3: `production/ui05-b23-integration.md` (bảng gộp, bẫy, backlog, câu hỏi). Báo cáo QA:
  `production/qa/ui05-b23/qa/` (REPORT.md + REVIEW-*.md).
- **Trước khi chạy agent: đọc memory `ui-lane-token-savers`** (ảnh 0.5, chỉ đưa đoạn frame, sửa nhỏ tự kiểm, làn to hơn,
  không vòng chờ, chép quyết định của Liam vào brief).

## Việc còn lại (thứ tự đề xuất)

### 1. Liam chơi thử bản live và trả lời câu hỏi
- Liam chơi trên axiedice.fun, báo lỗi gặp phải.
- Trả lời các câu trong mục "Câu hỏi gom cho Liam" của `production/ui05-b23-integration.md` (~25 câu, không câu nào chặn).
  Đáng hỏi trước: Unlocks "NO EFFECT YET" vẫn mua được; nút Sign in ở Raid khi guest; nút "Keep this device" tô cam ở
  Choose save; RunRow bị nâng lên ở Land 1280 offline; Pass "Reach Level N" bị cắt ở 1280.

### 2. ~~S7a Leaderboard~~ — XONG 1/11, đã gộp `godot-port` (`12eceba`), chưa deploy
- Merge godot-port vào nhánh, `t_ui5_lb` chạy vài giây (lần treo 9 tiếng trước là do test dừng giữa chừng khi `find_child`
  trả null → không `quit`; đã thêm guard). Review 2 (lead-programmer): sửa lộ email ở PinnedRow (`display_name()` rơi về
  email), tên chỉ lấy từ tài khoản, focus sau Close/Try again, hàng cache chỉ hiện cho đúng bảng của nó.
- Còn nhỏ (chưa sửa): tên "You" dài không cắt (`OVERRUN_NO_TRIMMING`, PinnedRow); viền banner guest luôn màu warn
  (`LbParts.gd:84`, chưa đối chiếu frame `lb--guest`); comment cũ `LbRow.setup_row`; `_fmt` thừa; `LbParts.banner/kv_row`
  trùng ý với MissionParts/RaidParts/DailyParts → gom lúc dọn.
- Ảnh: `production/qa/ui05-b23/s7a/`.

### 3. Backlog sửa nhỏ (gom 1 làn, không chặn)
Từ QA (`production/qa/ui05-b23/qa/REVIEW-*.md`) và sổ tích hợp:
- Tên quái bị cắt ở cột quái 1280 ("Ravenl…").
- Tutorial: coach che nút Reroll bước 7; thẻ SET viền vàng ở bước 4 dù chỉ thẻ highlight bấm được.
- Toast offline ở Land 1280 xuống 3 dòng đè đảo.
- Chữ update bar / netnotice / dòng đội hình Raid nghi < 14 px → đo bằng test, sửa nếu đúng.
- Echo seasonal 1920: kiểm lại Series items sau F1; Pass nút task "Claim · season not running" gập 3 dòng.
- Combat: dưới curtain tutorial Welcome nút End turn vẫn hiện keycap (README round-3 nói ẩn khi curtain giữ focus).
- Codex: bảng BBCode chưa kéo full bề ngang.
- Daily remote claim không có cờ pending (bấm đúp 2 request) — có từ trước.
- Dọn: `GachaFx.banner()` không dùng; `LandPlates.attach_space_cap` → `shared/ui5`; `_take`/`_refresh_take` chết trong
  `TutorialCoach.gd`; 2 test kiểm đáy lẫn đơn vị (`t_ui5_anchor_pick`, `t_ui5_core_offer`).
- Capture QA cần sửa: `room` dựng sai state (make-room, combo banner); 3 ảnh Result trống (chụp sớm);
  `qa_ui5_anchor_capture`/`qa_ui5_codex_capture` ghi đường dẫn cứng.

### 4. Polish của Liam
- 1/11: Liam chơi bản live, "mọi thứ đã làm rất tốt", chỉ báo 2 điểm: nút Claim Daily còn sáng sau khi nhận (thật ra
  lỗi sâu hơn: online không có trạng thái daily, thưởng tuần online chưa bao giờ trả) và nút "Upgrade Land …" quá dài.
  Cả hai đã sửa (`1a04951`, Liam chọn "sửa đủ" cho Daily). Ảnh: `production/qa/polish-0111/`.
- Còn nhỏ từ review Daily (chưa sửa, đều có từ trước): client so ngày bằng đồng hồ máy → máy lệch quanh 00:00 UTC thì
  Claim sáng sai (server vẫn chặn trả 2 lần); `state()` của Worker thêm 3 truy vấn mỗi request econ (để ý khi ledger to).

### 5. Việc lớn của dự án (sau UI-05)
Xem `production/session-state/active.md` mục "Việc lớn còn lại" (monetization/architecture review, Nhiệm vụ bản khó,
kế hoạch phase: combat batch + bump RULES_VERSION, quái Atia 3D, server RNG, store).

## Dọn máy / git còn treo
- **1/11 tối, Liam duyệt "xoá rác":** đã xoá 55 worktree đã gộp và sạch (nhánh giữ nguyên), ổ trống 32 → 97 GB.
  Còn giữ: `verifier` (đang chạy `verifier/runner.sh`), `.claude/worktrees/agent-ab462b22488911dcf` (khoá bởi phiên Claude
  khác còn sống, pid 2948), và các worktree có file chưa commit mà cây chính không có: `b2-epoch`, `ns-sim1`, `soak`
  (59 file sim), `u5-0`, `u5-c` (18 ảnh), `u5-e`, `u5-stage`, `u5b-0`, `ui4`, `agent-a39fd…`, `agent-aa6f…` (test qa_ux
  staged), `~/soak-sim1..3` (sửa `sim_balance.gd`). `build/` đã dọn (30 GB → 871 MB, giữ `web/`, bản desktop b1841, mọi json/txt/sha256): luật `deny rm -rf` của dự án chặn xoá thẳng nên 26 GB được chuyển vào `~/.Trash/build-cleanup-2026-11-01/`; Liam đổ Thùng rác thì mới trống ổ.
  Mục worktree cũ ngay dưới đây đã lỗi thời.
- Worktree còn: `../my-game-wt/u5b-0` (detached ở `1a04951`, dùng chạy suite bản gộp 1/11 — xoá được),
  `../my-game-wt/u5b-s7a` (S7a đã gộp — xoá được), `../my-game-wt/daily` (`fix/daily-remote`, đã gộp — xoá được), `../my-game-wt/u5b-s9a` (đã gộp; có thư mục rác `godot/production/` — Liam cho phép thì
  `git worktree remove --force`). Thêm `~/soak-sim1..3` (worktree cũ từ trước, detached).
- Nhánh `ui5b23/*` đã gộp: xoá được khi Liam đồng ý.
- Checkout chính có 3 file sửa chưa commit từ trước phiên (không phải của UI-05): `design/proposals/atia-roster-expansion-brainstorm.md`,
  `production/qa/review-sr1-client-2026-10.md`, `production/session-state/active.md` (mục đầu đã cập nhật 1/11).
- Không còn tiến trình Godot / vòng chờ nào của phiên 1/11.

## Luật chạy (nhắc nhanh)
- Godot luôn qua `godot/tools/with_lock.sh`, `--import` trước; test lẻ `AXIE_TEST_NO_NET=1 AXIE_HANG_KILL=500`; nền +
  kill timer (Mac không có `timeout`). Chi tiết: `production/ui05-b23-lane-run.md`.
- Deploy: tắt editor → `bash export-web.sh` → `bash deploy-r2.sh`; chỉ khi Liam bảo. Push `git push axiedice godot-port:main`.
