# Luật làn polish 3/11 (P1, P2, P3)

Đọc trước:
- `production/polish-0311-plan.md`: phần việc của làn mình và quyết định của Liam;
- `production/polish-0311-list.md`: chi tiết từng mục, ảnh bằng chứng ở cột cuối, `P/` = `production/qa/polish-0311/`;
- `godot/CLAUDE.md`: luật UI.

## Chỗ làm
- Worktree `/Users/loc.tien.nguyen/my-game-wt/pl-<p1|p2|p3>`, nhánh `polish/0311-<p1|p2|p3>`. Đã có `godot/override.cfg`.
- Chỉ sửa file của màn trong làn mình. Cần sửa file dùng chung (`scenes/shared/*`, `UI6Assets`, `PanelParts`, `UI3.gd`) thì ghi rõ trong report, và sửa càng nhỏ càng tốt.

## Cấm
- Không sửa file luật: `autoload/`, `scripts/core/`, `scripts/meta/`, `resources/relics/`, `assets/data/rules/`, `part_faces.json`. Sửa vào đây phải tăng RULES_VERSION. Cần thì DỪNG và báo.
- Không sửa `tokens_ui3.json`. Cần token mới thì ghi report.
- Không đổi art / icon trong đợt này: đợt 2 sẽ làm lại art. Chỉ làm bố cục, chữ, logic UI.
- Không `git stash` (repo dùng chung stash). Không `pkill`. Không kill tiến trình không phải của mình. Không `rm -rf`.

## Chạy Godot
- Mọi lần chạy đều qua `bash godot/tools/with_lock.sh`, luôn `cd` vào worktree của mình ngay trong lệnh.
- Test: `AXIE_TEST_NO_NET=1`. Chạy nền, kèm kill timer cho đúng PID của mình: `( cmd ) & p=$!; ( sleep 300; kill $p ) & wait $p`. Không viết vòng until / while chờ file.
- Chạy `--import` trước khi chạy test, nhất là khi vừa thêm file hoặc `class_name` mới. Parse error làm Godot treo chứ không báo lỗi.
- Ảnh chụp: chạy KHÔNG headless qua `godot/tools/shot.sh`, cả 1920 và 1280.
  - Đường dẫn thư mục ảnh phải TUYỆT ĐỐI, đặt trong `/Users/loc.tien.nguyen/my-game-wt/pl-<làn>/production/qa/polish-0311/<làn>/`. Đường tương đối sẽ rơi vào `godot/production/` và lọt vào pck; lỗi này đã xảy ra.
  - Các scene QA ui06 cần ép scale: `UI6_PROBE_SCALE=1` (1920) hoặc `0.6667` (1280), cùng `UI6_SHOT_TAG`.
  - Driver chạy cả một run: `tests/qa_ui5_flow_capture.gd` (QA_ENTRY / QA_ANCHOR / QA_SHOP, QA_SEED).
  - Xem ảnh ở scale 0.5. Nếu scene ghi đè ảnh đang được git theo dõi thì `git checkout --` lại ảnh đó.

## Mỗi mục
1. Sửa.
2. Thêm hoặc cập nhật test có chặn hồi quy.
3. Chạy test liên quan.
4. Chụp ảnh trước / sau.
5. Commit, message ghi "(polish 3/11 <làn>, #<số mục>)". Dòng `Co-Authored-By: <model thật> <noreply@anthropic.com>` để riêng ở cuối message.

Bạn có khoảng 20 lượt mỗi lần chạy, người điều phối sẽ cho chạy tiếp. Sắp hết lượt thì commit WIP rồi gửi report.

## Report (tiếng Việt, ngắn)
- hash commit;
- mục nào xong, mục nào chưa;
- test đã chạy kèm số check;
- đường dẫn ảnh;
- file dùng chung đã đụng;
- việc còn lại.
