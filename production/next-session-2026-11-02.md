# Bàn giao cho session mới (2/11/2026)

## Prompt dán vào session mới
> Đọc `production/next-session-2026-11-02.md` và làm tiếp theo thứ tự ở mục "Việc tiếp theo". Luật làm việc ở `CLAUDE.md`. Hỏi tôi trước khi deploy.

## Trạng thái
- **Live (axiedice.fun):** `godot-port` @ 773691a. Web pck `f56ef53c`, desktop b2359. Đã có UI-06 (thẻ Lõi/Anchor/Luật run, dải Lõi, hiệu ứng kích hoạt, art Drop B), UI-07 (màn đăng nhập), 25 câu trả lời UI của Liam, thẻ Core ở màn thưởng có emblem họ và chip bậc. Ghi chép: `production/release/deploy-2026-11-02-ui06-ui07.md`.
- **`godot-port` @ 5bf4007, CHƯA deploy:** hotfix màn đăng nhập.
  - Lỗi trên live: người CHƯA đăng nhập chỉ thấy một cột nâu trống, không có nút Google hay Play as guest. Nguyên nhân: panel phình ~8000 px lúc dựng rồi không co lại.
  - Đã sửa trong `LoginScreen._fit_panel` và có test chặn hồi quy trong `t_ui7_login`.
  - **Phải deploy sớm** (web + desktop).
- **Nhánh `ui06/finish` @ add3bf6 (worktree `../my-game-wt/u6-fin`), chưa gộp, chưa review:**
  - moment map-reward (`scenes/shared/ui6/MapRewardFx.gd`);
  - `49-anchor-awaken--after` (chip "Volley Awakened" kèm dấu awaken);
  - mỗi lần Lõi kích hoạt chỉ một con số: giữ float note, `CoreFireFX.SHOW_NUMBER = false` (Liam: gộp);
  - nền chân dung Run setup = màu panel trộn 30% màu class (Liam: giảm);
  - test mới `t_ui6_map_reward` 21 check. Đã sửa `t_ui5_event_treasure`, giờ chờ rương lắc xong.
  - Ảnh ở `production/qa/ui06/finish/`, CHƯA `git add`: boss-next, node-icons, treasure-opened, 49-after, run setup 1280.
  - Chưa chạy suite đủ. `t_ui5_run_setup` chưa chạy lại sau khi đổi tint.
  - Lỗi thấy khi chụp, chưa sửa: ở `03-run-map--boss-next` 1920, tên boss bị cắt ("NIGHTMARE AGO…") ở tiêu đề NodeDetail và caption dưới node boss.
  - Chưa chụp: 47 facedown-crystal / combo-tags / house-core / reroll-used; 49 --after trong combat; combat một số.
  - Cần review độc lập rồi mới gộp.
- **Nhánh `ui06/qa2` (worktree `../my-game-wt/u6-qa`) @ 16e0083:** driver QA `qa_ui5_flow_capture.gd` có thêm `QA_ENTRY` (đi qua màn đăng nhập), `QA_ANCHOR`, `QA_SHOP`, script `production/qa/ui06/qa2/run.sh`. Chỉ đổi driver, gộp được.
- Suite: 338 (AXIE_RELEASE=1, cần `AXIE_HANG_KILL` ≥ 4500, chạy > 40 phút). Worker 397, không đổi.

## Việc tiếp theo (theo thứ tự)
1. Gộp vào `godot-port`:
   - `ui06/qa2`;
   - `ui06/finish`, sau khi review độc lập.
2. Chạy `tools/release_gate.sh --suite` ở worktree `../my-game-wt/u5b-0` (detach về godot-port, `--import` trước, `AXIE_HANG_KILL=4500`). Sửa test nếu đỏ vì đổi tên node.
3. Hỏi Liam rồi deploy web + desktop. Quy trình theo các file `production/release/deploy-*.md` mới nhất:
   - **trước khi export:** chép `web/index.*` sang `build/web-prev/` để có bản lùi (đợt trước quên bước này);
   - export, `deploy-r2.sh --pck-only` rồi `--rest`, kiểm md5 / Range;
   - `build_desktop.sh all`, rồi `publish_desktop.sh --prev` với manifest lấy từ R2;
   - smoke trên site.
   - Màn đăng nhập phải kiểm khi CHƯA đăng nhập (cửa sổ ẩn danh, hoặc chạy driver `QA_ENTRY=1`).
4. Chạy lại QA2 với vài seed để gặp shop: `QA_SEED=7 bash production/qa/ui06/qa2/run.sh`. Xem ảnh màn đăng nhập sau hotfix.
5. Lỗi QA2 còn mở:
   - Make room ghi "Passive slots are full (7 of 8)". Có thể Lone Wolf Contract tốn 2 slot; kiểm và viết lại câu cho rõ.
   - Thẻ "Brittle Dice" ở màn Make room / slot-swap còn chip "Rare" kiểu cũ.
   - Nút "Reveal the cards first" hơi lệch.
6. **3/11 07:00 (giờ VN):** Liam nhắc thì kiểm Pass mùa 1 trên site, chỉ đọc.

## Câu hỏi / việc chờ Liam
- Verifier chạy bóng đang tính run thường (không ranked) là "lệch" (`not_ranked`), nên điều kiện "0 lệch" không bao giờ đạt. Đề xuất: verifier bỏ qua run không ranked thay vì đếm là lệch. Cần Liam đồng ý, có thể phải đổi Worker.
- Run có Anchor không verify được, vì RunVerifier chỉ nhận run ranked. Hỏi Liam có cần verify cả run thường không.

## Danh sách Liam tự làm (điều kiện mở cho tester ngoài, `production/qa/beta-qa-report.md`)
1. Mua Nhiệm vụ N1 trên production: thắng 1, thua 1, bỏ 1. Đối chiếu số dư trước và sau.
2. Kiểm bằng tay khi rớt mạng: rút mạng lúc xúc xắc bay, lúc chờ seed, lúc END TURN, ở màn thưởng, giữa run Nhiệm vụ.
3. Hai thiết bị cùng một tài khoản.
4. Một tài khoản mới đi hết: tutorial, Daily, Echo Box.
5. Chạy thử bản Windows trên máy Windows, hoặc ghi "chưa hỗ trợ Windows" trong lời mời.
6. Notarize bản mac. Cần Apple Developer ID; xem `production/release/signing-setup.md`.
7. Kiểm Pass khi mùa mở 3/11 (Claude làm cùng).
8. Gom ≥ 100 mẫu RTT thật mỗi nền tảng, rồi chốt PB hay PA.
9. Thay `godot/assets/ui7/google_g.svg` bằng logo "G" chính thức trong bộ thương hiệu Google Sign-In.
10. Sau vài ngày closed beta: verifier phải đạt 0 lệch, ≥ 500 run mỗi nền tảng, ≥ 7 ngày.

## Việc lớn sau đó
- **Viết lại kế hoạch phase.**
  - `production/phase-plan-v1.md` viết ngày 12/10, nhắm mốc L1 = 3/11. Phần lớn các giai đoạn trong đó đã xong.
  - Việc cần làm là viết bản kế hoạch SAU L1:
    - liệt kê cái gì đã xong;
    - việc lớn còn lại: đợt đổi luật combat (gom một lần tăng RULES_VERSION), server RNG P3/P5, quái Atia 3D còn thiếu, store/tiền thật, Land, telemetry;
    - sắp thứ tự, ước lượng, mốc.
  - Liam duyệt rồi mới làm.
- Kế hoạch dùng máy Mac này làm server 24/24. Liam cần nói muốn chạy gì trên máy.
- `production/session-state/pending-decisions.md` không còn câu nào chờ trả lời. Mục D trong đó là việc cũ, đã lỗi thời.

## Dọn máy (2/11)
- Đã xoá 22 worktree đã gộp. File chưa commit của chúng nén ở `~/my-game-archive/worktrees-2026-11-02/`.
- Còn 5 worktree:
  - `u5b-0`: dùng chạy cổng phát hành;
  - `u6-fin`, `u6-qa`: chờ gộp, gộp xong thì xoá;
  - `verifier`: đang chạy;
  - `agent-ab462…`: bị khoá bởi một phiên Claude khác.
- Bản web lùi còn ở `build/web-prev-a8fa9a4f/`. Hai bản cũ hơn đã chuyển vào Thùng rác.
