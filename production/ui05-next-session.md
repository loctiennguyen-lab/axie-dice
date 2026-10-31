# UI-05 — việc còn lại (bàn giao 1/11/2026)

## Trạng thái
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

### 2. S7a Leaderboard (màn duy nhất của đợt 3 chưa lên)
- Nhánh `ui5b23/s7a`, worktree `../my-game-wt/u5b-s7a`, đầu `c51f1f8` (WIP, CHƯA test; tách từ int cũ trước khi có
  S8a1/S9a… → phải `git merge godot-port` vào nhánh trước).
- Đã có: layout theo frame lb (Ui5TabBar, AscRow, LbRow, DetailPlate), states, `t_ui5_lb`, capture + ảnh. Review đã đòi
  sửa: tên PinnedRow lấy sai nguồn, PinnedRow hiện ở Today/empty, cột lệch khi cuộn — c51f1f8 sửa nhưng chưa chạy test.
- Test `t_ui5_lb` từng TREO 9 tiếng (đã kill). Chạy lại có kill timer; nếu treo → tìm vòng chờ trong test/màn
  (`await` không thoát khi không có mạng?).
- Một agent `ui-programmer`, làm xong → review → gộp `godot-port` → suite → deploy (hỏi Liam).

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
- Theo memory `beta-qa-phase`: sau QA kỹ là lượt polish của Liam. Chờ Liam chơi rồi quyết danh sách polish.

### 5. Việc lớn của dự án (sau UI-05)
Xem `production/session-state/active.md` mục "Việc lớn còn lại" (monetization/architecture review, Nhiệm vụ bản khó,
kế hoạch phase: combat batch + bump RULES_VERSION, quái Atia 3D, server RNG, store).

## Dọn máy / git còn treo
- Worktree còn: `../my-game-wt/u5b-0` (`int/ui5-b23`, đã gộp hết vào godot-port — xoá được), `../my-game-wt/u5b-s7a`
  (giữ cho việc 2), `../my-game-wt/u5b-s9a` (đã gộp; có thư mục rác `godot/production/` — Liam cho phép thì
  `git worktree remove --force`). Thêm `~/soak-sim1..3` (worktree cũ từ trước, detached).
- Nhánh `ui5b23/*` đã gộp: xoá được khi Liam đồng ý.
- Checkout chính có 3 file sửa chưa commit từ trước phiên (không phải của UI-05): `design/proposals/atia-roster-expansion-brainstorm.md`,
  `production/qa/review-sr1-client-2026-10.md`, `production/session-state/active.md` (mục đầu đã cập nhật 1/11).
- Không còn tiến trình Godot / vòng chờ nào của phiên 1/11.

## Luật chạy (nhắc nhanh)
- Godot luôn qua `godot/tools/with_lock.sh`, `--import` trước; test lẻ `AXIE_TEST_NO_NET=1 AXIE_HANG_KILL=500`; nền +
  kill timer (Mac không có `timeout`). Chi tiết: `production/ui05-b23-lane-run.md`.
- Deploy: tắt editor → `bash export-web.sh` → `bash deploy-r2.sh`; chỉ khi Liam bảo. Push `git push axiedice godot-port:main`.
