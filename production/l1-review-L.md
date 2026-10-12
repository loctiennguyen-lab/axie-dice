# Review làn L (ui-programmer, 12/10 tối) — FIX FIRST, chưa merge

1. `t_guides_daily` treo (godot/tests/t_guides_daily.gd:311 instantiate MainMenu.tscn, MainMenu giờ chuyển sang Land):
   thêm `LandNav.legacy_setup_open = true` trước dòng 311 (như t_mainmenu_ui). Chạy lại riêng `t_ui_laws` (SCENES có MainMenu.tscn).
2. `godot/scenes/land/Land.gd:54` "ends 30 Nov 2026" → "29 Dec 2026"; thêm check trong t_land_hub.
3. Luồng menu cũ đứt (`LandNav.gd:65,72`): `open()` xoá cờ `legacy_setup_open` khi mở Vault/Pass/Guides… từ menu cũ → Back
   đá về Land; bắt đầu run từ menu cũ thì cờ còn true → hết run (CombatView.gd:874, ResultView.gd:865, RunMapController.gd:1166)
   về menu cũ thay vì Land. Sửa: thoát về MainMenu thì gọi `LandNav.back_to_land()`, hoặc LandNav tự quản cờ ở điểm vào/ra run;
   tối thiểu reset cờ khi bắt đầu run.
4. Shortcut khoá còn `modulate.a = 0.8` (Land.gd:~728) — R1 A8: bỏ opacity, chữ `#6E4A30`. Chữ 11 px (profile sub-line ~690,
   key hint) → 12 px.
Nhỏ: `_continue_line()` thêm act · floor · đội còn đứng khi làn A có dữ liệu; xoá `S_Plot_Module_3x3.tscn` + fbx không dùng;
thêm check dy ở 1920×1240 và Esc ở MainMenu fallback.
Liam yêu cầu thêm: xoay Portal 90°; làm đẹp hub (ánh sáng ấm + bóng mềm, nền đất/địa hình biome thật, decor dày hơn).
