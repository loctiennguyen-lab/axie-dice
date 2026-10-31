# REVIEW run + Land (UI-05 đợt 2+3) - CHƯA ĐẦY ĐỦ

Gốc ảnh: `/Users/loc.tien.nguyen/my-game-wt/u5b-qa/production/qa/ui05-b23/qa/` (viết tắt `QA/`).
Tình trạng: người review hết lượt giữa chừng. Mới xem 68 ảnh. Không so được với frame HTML, chỉ so với luật UI. Những gì ghi dưới đây chỉ là phần đã xem.

## Lỗi (mỗi lỗi một dòng)

Chặn deploy: chưa thấy lỗi nào trong 68 ảnh đã xem.

Nên sửa
1. [nên sửa] land_edit (Land upgrade), ảnh `QA/1920/land_edit/u01..u05-*.png`, `QA/1280/land_edit/u01..u05-*.png`: khung preview bên phải là một khối màu phẳng (xanh / tím / lavender), không có art. Ba swatch nhỏ trong danh sách cũng là ô màu. Chưa so với frame nên chưa biết đây là filler của frame hay thiếu art. File nghi: `godot/scenes/land/` (màn Land upgrade).
2. [nên sửa] run_setup, ảnh `QA/1920/run_setup/06-run-setup--*.png`, `QA/1280/run_setup/*.png`: thẻ party có nền portrait xanh lá giống hệt nhau cho cả 5 class (Plant, Beast, Aqua, Reptile, Bug). Brief nói màu class dùng token `class_*`. Có thể frame cũng vậy, cần đối chiếu. File nghi: `godot/scenes/run_setup/RunSetup.gd`.

Nhỏ
3. [nhỏ] land_overlays offline, ảnh `QA/1280/land_overlays/01-land--offline-1280x720.png` và `--offline-retry-1280x720.png`: toast Offline xuống 3 dòng, đè lên đảo và cổng. Toast "Still offline" nằm chồng lên cổng. Ở 1920 toast chỉ 2 dòng và nằm gọn.
4. [nhỏ] run_picker, ảnh `QA/1920/run_picker/06-run-setup--picker.png` và `QA/1280/run_picker/06-run-setup--picker--1280.png`: tooltip "In slot 2 · picking it swaps" che gần hết art và một phần chữ thẻ Vault Bird.
5. [nhỏ] land_edit placing, ảnh `QA/1280/land_edit/e02-edit-land--placing-1280x720.png`: nhãn "Placing: Savannah Shrub" chạm mép panel Edit Land, sát cắt chữ "Shrub".
6. [nhỏ] land_edit Rewards, ảnh `QA/1920/land_edit/e04-edit-land--rewards-1920x1080.png` và bản 1280: mọi dòng đều có câu "No Stone, no power." lặp lại. Nhìn như filler, nên hỏi design xem có để không.
7. [nhỏ] run_picker leaderboard, ảnh `QA/1920/run_picker/06-run-setup--lb-rows.png` và bản 1280: hàng "Player One / Two / Three / Me" và "Last updated 14:02" trông như chuỗi minh hoạ. Nếu chỉ là fixture của test thì bỏ qua, nếu hardcode trong game thì sai luật.
8. [nhỏ] run_setup daily/ranked, ảnh `QA/1920/run_setup/06-run-setup--daily-1920x1080.png` và `--ranked-`, bản 1280 tương ứng: vòng focus xanh vẫn nằm ở "Normal" trong khi Daily/Ranked đang được chọn (viền kem), nhìn như hai nút cùng được chọn. Có thể là artifact fixture.
9. [nhỏ] land_edit, ảnh `QA/1920/land_edit/e01..e05` và bản 1280: toast "Welcome gift… Open Edit Land to place them." vẫn hiện khi đang ở Edit Land (fixture, chỉ để ý).

Đã kiểm, không thấy lỗi: keycap Space chỉ có trên nút mặc định có focus (Start run, Keep playing, Cancel, Close, Try again, OK), không có trên nút tắt (Start run - needs connection, Reconnecting..., Need N more). Nút tắt đều ghi lý do. Picker không chọn sẵn. Chữ ở 1280 không bị cắt trong land_overlays, land_edit (trừ mục 5), run_setup, run_picker.

## Đã xem (68 ảnh)
- `land_overlays` 1920 + 1280: 16 ảnh
- `land_edit` 1920 + 1280: 20 ảnh
- `run_setup` 1920 + 1280: 14 ảnh
- `run_picker` 1920 + 1280: 16 ảnh
- `enemy` (chỉ `02-combat--ab-names--1280.png` và `02-combat--boss--1280.png`, nằm trong thư mục 1920/enemy): 2 ảnh
  - ab-names 1280: ổn.
  - boss 1280: ổn, không thấy lỗi.

## CHƯA xem (khoảng 200 ảnh), cần review tiếp
- `hud` (1920 + 1280): lần Read đầu bị lỗi "media removed", coi như chưa xem. Lưu ý: thư mục `QA/1280/hud/` có cả file không hậu tố và `--1280`, thư mục `QA/1920/hud/` cũng có file `--1280`. Cần kiểm xem file nào đúng cỡ.
- `dice` (1920 + 1280): chưa xem (cùng lỗi Read).
- `enemy`: 10 ảnh còn lại (bighit, attrition-upcoming/active/max, ab-names 1920, boss 1920, và các bản 1280 còn lại ngoài hai ảnh trên) chưa xem.
- `anchor`, `core_offer`, `moments`, `moments_b2`, `room`, `rule_offer`, `run_menu`, `shop`, `event_treasure`, `tutorial`, `result`: chưa xem ảnh nào (cả 1920 và 1280).
