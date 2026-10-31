# REVIEW combat + moment + menu + tutorial + result (UI-05)

Gốc ảnh: `QA/` = `/Users/loc.tien.nguyen/my-game-wt/u5b-qa/production/qa/ui05-b23/qa/`. Chỉ xem bản 1280.
Đã xem: 57 / 57 ảnh 1280 của các nhóm hud, dice, enemy, moments, moments_b2, run_menu, tutorial, result (+1 ảnh 1920 để kiểm kích thước). Bản 1920 chưa xem.
Lưu ý: trong `QA/1280/hud/` các file KHÔNG hậu tố (`02-combat--idle.png`, ...) thực ra là 1920x1080. Chỉ file `--1280` mới đúng cỡ. Không so được với frame HTML, chỉ so với luật UI. Cỡ chữ ước lượng bằng mắt (ảnh là 1280 thật), cần đo bằng code để chắc.

## Lỗi (mỗi lỗi một dòng)

Chặn deploy
1. [chặn] moments, `QA/1280/moments/moment-victory-t600-1280x720.png`, `moment-victory-end-1280x720.png`: Victory có sunburst, các tia sáng lớn xoè từ giữa màn hình. Đây là hiệu ứng PROPOSAL (rays). File nghi: scene/script moment Victory trong `godot/scenes/combat/` (CombatView / victory banner).
2. [chặn, cần xác nhận] moments_b2, `QA/1280/moments_b2/treasure-open-rest.png`: ảnh "rest" (trạng thái cuối) có đúng 1 thẻ "Level Up" dính góc trên-trái, tiêu đề "Choose one" cắt sát mép trái, không căn giữa, Pick a reward ở giữa. Bố cục sai hoặc chụp trước khi layout xong. `treasure-open-mid.png` chỉ có nền tối. File nghi: màn treasure trong `godot/scenes/run/` (treasure open).
3. [chặn, cần xác nhận] result, `QA/1280/result/10-result--combos-full-1280.png`, `10-result--loss-1280.png`, `10-result--mission-lost-1280.png`: cả ba chỉ thấy nền Land, không có panel kết quả nào. Không kiểm được loss, mission lost, combos đầy đủ. Có thể chụp quá sớm (fade), nhưng chưa có bằng chứng panel hiện. File nghi: `godot/scenes/result/` + script chụp trong `godot/tools/`.

Nên sửa
4. [nên sửa] hud, `QA/1280/hud/02-combat--enemy-turn--1280.png`: nút "Enemy turn" đang tắt mà vẫn có keycap Space. Luật: keycap không trên nút tắt. File nghi: End turn button trong `godot/scenes/combat/` (HUD action column).
5. [nên sửa] hud, `QA/1280/hud/02-combat--waiting--1280.png`: nút "Waiting..." đang tắt có keycap Space, cùng lỗi mục 4. Nút Reroll bên trên ghi "need 1 MP" lúc đang chờ server, hơi lệch ngữ cảnh.
6. [nên sửa] moments, `QA/1280/moments/moment-bighit-1280x720.png`: BIG HIT có một dải sáng chéo (light shaft) cắt qua màn hình. Giống tia sáng PROPOSAL. File nghi: moment BigHit trong `godot/scenes/combat/`.
7. [nên sửa] moments, `moment-crit-1280x720.png`, `moment-bighit-1280x720.png`: cụm icon kiếm/khiên (particle) phủ lên số damage, số "12" và số BIG HIT gần như không đọc được. Số damage phải rõ nhất. File nghi: FX damage popup / particle emitter của hit.
8. [nên sửa] moments, `moment-shield-1280x720.png`: vòng tròn cyan quanh Axie (vòng sáng) và số "+6" mờ gần như không thấy. Vòng sáng nằm trong danh sách hiệu ứng cấm; "+6" cần rõ hơn.
9. [nên sửa] tutorial, `QA/1280/tutorial/ui5-tutorial-04-reroll`, `05-pick-die`, `06-pick-target` (1280x720): bước 4 nói "the highlighted one is the only card you can press", nhưng thẻ Machito và Momo cũng có viền vàng (SET) nên trông cũng "highlight". Gây hiểu nhầm. File nghi: tutorial coach (`godot/scenes/tutorial/`) + DieCard SET outline.
10. [nên sửa] tutorial, `ui5-tutorial-07-end-turn-1280x720.png`: card hướng dẫn che mất thẻ Momo và nút Reroll, đúng lúc đang dạy thao tác ở đó. Ngoài ra bước 4 che SET banner và Olek. File nghi: vị trí card coach.
11. [nên sửa] tutorial, `ui5-tutorial-09-reward-1280x720.png`: dải banner cam "Your turn" còn sót nằm sau màn reward. Thẻ đầu có khung focus cyan (trông như chọn sẵn) trong khi "Pick a reward" đang tắt. Luật: không chọn sẵn khi chọn để lấy. Thẻ reward cũng trống nửa dưới.
12. [nên sửa] moments_b2, `core-reveal-b.png`, `core-reveal-rest.png`: thẻ Mana Pool có viền focus cyan ngay khi mở, nhìn như chọn sẵn. Cùng vấn đề mục 11. File nghi: màn Choose a Core trong `godot/scenes/run/`.
13. [nên sửa] enemy, `QA/1280/enemy/02-combat--ab-names--1280.png`: hai quái cùng tên bị cắt thành "Ravenl..." với badge A/B, không phân biệt được loại gì. Tên cắt còn ở `dice/set-3` ("Gooey S...") và tutorial ("Mire Sli..."). File nghi: EnemyCard name label trong `godot/scenes/combat/`.
14. [nên sửa] run_menu, `menu--save-quit-confirm--1280.png`: nút an toàn "Cancel" có focus nhưng không có keycap Space, trong khi "Keep playing" (abandon) và "Resume" có. Không nhất quán. Tương tự "End run" ở `moments/moment-defeat-1280x720.png` (nút mặc định không keycap).
15. [nên sửa] hud/dice, mọi ảnh combat 1280: chữ nhỏ có vẻ dưới 14 px: nhãn Undo/Hold/Wild/Overcast, "5 dice unused", "Not now", "Armor 2", dòng "then +20%/turn", nội dung tooltip, "Enemies are acting". Cần đo bằng code, nếu <14 thì sai luật. File nghi: theme font size trong `godot/` (text_small).

Nhỏ
16. [nhỏ] moments, `moment-victory-end-1280x720.png`: dòng "Click or Space to continue" đè lên chữ "5 dice unused" ở góc dưới phải.
17. [nhỏ] moments, `moment-turn-banner-player/enemy-1280x720.png`: banner che mất thẻ quái thứ hai (chỉ lộ nửa), và nút End turn vẫn sáng "End turn Space" lúc banner Enemy turn.
18. [nhỏ] run_menu, `menu--map-cores`, `menu--settings`, `menu--combat-run` (1280): hai hàng cùng nổi bật (Resume có focus cyan, hàng khác có viền kem). Giống hai mục cùng chọn. Cores owned còn dùng cùng một icon mặt trắng cho Backline Glow và Bastion.
19. [nhỏ] run_menu, `menu--map-cores--1280.png`: mô tả Iron Vow có dấu cách thừa trước dấu phẩy ("+50% , and").
20. [nhỏ] tutorial, `ui5-tutorial-03-intent-1280x720.png`: text "That badge above its head" nhưng badge intent nằm ở thẻ quái bên phải, không phải trên đầu quái. File nghi: chuỗi coach step 2.
21. [nhỏ] tutorial, `ui5-tutorial-07-end-turn-1280x720.png`: BIG HIT cho hit 3 damage và đám particle kiếm rải rộng cả màn, lấn át. Cần xem BIG HIT có đúng ngưỡng không.
22. [nhỏ] result, `10-result--new-title-1280.png`: tiêu đề "Run won" bị mờ và icon Shard đè lên chữ, vùng giữa panel trống lớn (không có combo/thống kê), hàng party chỉ có tên và "T1". `10-result--win-1280.png` chụp giữa fade. Có thể do fixture hoặc timing.
23. [nhỏ] dice, `02-combat--set-3--1280.png`, `set-4--1280.png`: vệt sáng vàng trên Olek (set-3) và vệt trắng đứng trên Axie đỏ (set-4). Nếu đây là hiệu ứng SET thì ổn, nếu là glow/spark thì thuộc nhóm cấm.
24. [nhỏ] hud, `02-combat--idle--1280.png` và các ảnh combat: nhãn "FRONT" bị đường kẻ ngang chạm vào cuối chữ.

## Đã kiểm, không thấy lỗi
- Keycap Space chỉ trên nút an toàn/mặc định ở: End turn đang bật, Resume, Keep playing, Got it, Start, Go to the Land, Back to Land. Không có keycap trên Hold/Undo/Wild/Overcast hay các nút Reroll/Pick tắt (ngoại lệ mục 4, 5).
- Nút tắt Pick a reward, Pick a Core, "Reroll · need 1 MP" đều ghi lý do.
- Không thấy chuỗi minh hoạ kiểu lorem/placeholder trong nhóm này.
- Nhãn dưới icon (Undo/Hold/Wild/Overcast) căn giữa đúng.
- Attrition, boss rhythm, boss HUD, die states, SET banner đều đọc được và đúng nội dung ở 1280.
