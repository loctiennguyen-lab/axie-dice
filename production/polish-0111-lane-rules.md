# Luật chạy chung cho 2 làn sửa nhỏ UI (1/11/2026)

Áp cho làn `pol-a` và `pol-b`. Đọc trước khi làm.

## Chỗ làm
- Worktree riêng: `/Users/loc.tien.nguyen/my-game-wt/pol-<a|b>`, nhánh `polish/ui-small-<a|b>`. Đã có `godot/override.cfg` riêng.
- Mọi lệnh phải tự `cd` vào worktree của mình ngay trong lệnh. Không dùng script chung trong scratchpad.
- Đọc trước khi sửa UI: `godot/CLAUDE.md`, đặc biệt mục UI-05 và luật toàn cục.
- Chi tiết lỗi lấy từ QA:
  - báo cáo: `production/qa/ui05-b23/qa/REVIEW-*.md`, `REPORT.md`;
  - sổ tích hợp: `production/ui05-b23-integration.md`.
- Frame thiết kế ở cây chính, chỉ đọc: `/Users/loc.tien.nguyen/my-game/design/handoffs/ui-05-figma/round-{1,2,3}/`.
  - Chỉ in đúng frame cần xem: `python3 -I godot/tools/ui5_names.py <html> <id frame>`.
  - KHÔNG đọc cả file HTML.

## Chạy Godot
- `GODOT=/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot`.
- Mọi lần chạy đều qua `bash godot/tools/with_lock.sh` của chính worktree mình.
- Chạy `--import` trước, lần đầu mất vài phút: `bash godot/tools/with_lock.sh "$GODOT" --headless --path godot --import`.
- Lỗi parse làm headless TREO, và Mac không có `timeout`. Luôn chạy nền và tự kill đúng PID của mình:
  `( cmd > log 2>&1 ) & p=$!; ( sleep 300; kill $p 2>/dev/null ) & wait $p`.
  - Sau đó grep log tìm `Parse Error` / `SCRIPT ERROR`.
  - Không `pkill` chung chung.
- Test lẻ: `AXIE_TEST_NO_NET=1 bash godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tests/t_x.tscn`.
  - Chỉ chạy test liên quan tới chỗ mình sửa.
  - Một test treo 2 lần thì DỪNG và ghi vào report, không chạy lại lần thứ ba.
- Ảnh chụp KHÔNG được chạy headless: `godot/tools/shot.sh <scene> 1920x1080` và `1280x720`.
  - Thư mục ra đặt bằng biến môi trường mà scene chụp đó đọc (`UI5_SHOT_DIR` hoặc `ADT_EVIDENCE_DIR`, xem đầu file capture).
  - Lưu vào `production/qa/polish-0111/<làn>/`.
  - Xem ảnh ở scale 0.5. Chỉ xem ảnh chứng minh chỗ đã sửa.
- KHÔNG viết vòng chờ `until`/`while` không có hạn. Không chờ một dấu hiệu mà tiến trình mình chạy có thể không bao giờ ghi ra.
- Full suite: KHÔNG chạy. Người tích hợp chạy.

## Luật
- Chỉ sửa file thuộc việc của làn mình.
  - Cấm đụng file luật: `autoload/`, `scripts/core/`, `scripts/meta/`, `resources/relics/`, `assets/data/rules/`, `assets/data/part_faces.json`. Đụng vào là phải bump RULES_VERSION.
  - Cũng không sửa `tokens_ui3.json` hay `UI3*.gd`.
  - Cần đụng mấy file đó thì DỪNG và ghi vào report.
- KHÔNG sửa các màn sẽ được thiết kế lại ở UI-06: thẻ/màn Core offer, Anchor pick/awaken, Run rule offer, dải Lõi. Riêng việc dọn code chết có ghi trong việc của làn thì được.
- Luật Liam đã chốt:
  - Chỉ hiện phím Space.
  - Không chọn sẵn khi chọn món để lấy/mua.
  - Nút primary tắt phải nói lý do.
  - Chữ dưới/cạnh icon căn giữa theo icon.
  - Ở 1280, chữ không dưới 14 px thật.
  - Không đưa số minh hoạ trong HTML vào code.
- Sửa test cũ khi đổi giao diện: giữ ý nghĩa của test, chỉ đổi cách tìm node.
- Test mới phải không treo:
  - `find_child` có thể trả null thì kiểm null và ghi fail, không gọi thẳng thuộc tính trên kết quả.
  - Mọi đường đều phải tới được `quit()`.
- Commit sau MỖI việc xong, theo Conventional Commits, ghi "(polish 1/11 lane <a|b>)".
  - Dòng cuối: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - `git add` đúng file, không `-A`. File `.gd` mới thì commit kèm `.gd.uid`.
  - KHÔNG `git stash`, KHÔNG push, KHÔNG merge.
- Bạn có khoảng 20 lượt: gom nhiều lệnh/file vào mỗi lượt. Sắp hết lượt thì commit WIP và viết report ngay.

## Report (tiếng Việt, ngắn, dưới 30 dòng)
- Hash cuối.
- Từng việc: đã sửa gì, file nào, test nào chạy (số check / đỏ), ảnh ở đâu.
- Việc nào chưa làm hoặc phải dừng, kèm lý do.
