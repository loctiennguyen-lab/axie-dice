# Review code LD-A (beta/lda cb23e02, diff 51c263c..beta/lda) — 26/10/2026
Chỉ đọc, không chạy Godot. Verdict: **APPROVE WITH CHANGES** (không có lỗi chặn, vài chỗ nên sửa/ghi rõ).

## Kiểm theo yêu cầu
1. Nâng tier: ổn. `confirm_upgrade` chặn `target == land_tier+1`, `upgrade_land` trừ Stone qua `spend` một lần rồi `save_to_disk`. Về Land bằng `LandNav.back_to_land()`, Land đọc tier mới ở `_ready`. Không thấy đường trừ hai lần.
   - Nhẹ: `LandUpgradeScreen.gd:~331` `change_scene_to_file` chạy trễ một frame; bấm đúp trong frame đó thì lần hai ra toast "Could not upgrade" (không trừ tiền). Nên khoá nút sau khi thành công.
2. Banner: ổn. `Land.gd _notices_on_enter` ghi `land_tier_banner_seen` rồi `MetaState.save_to_disk()` (không ghi file trực tiếp); load đã clamp `<= land_tier` (MetaState:902). Esc đóng modal (`_handle_key_event` MENU_BACK) + `cancelled` + nút "Look around". Phím E bị chặn khi `_modal != null`.
   - Chưa kiểm được (không chạy): modal có tự lấy focus bàn phím/gamepad không. Nên QA tay: mở Land tier mới, bấm Enter/A không cần chuột.
   - Banner bị bỏ qua nếu lúc vào có NetNotice/Moon card/AccountWelcome (`has_modal`), seen chưa ghi nên lần sau sẽ hiện. Chấp nhận được.
3. `LandAxies.pick_keys`: không crash với preset rỗng (`is_empty` → `[]`), key lạ bị lọc bằng `ContentDB.heroes.has`, bỏ trùng, tôn trọng limit; `descriptor_for` trả null thì Land rơi về ngẫu nhiên. 
   - `LandAxies.gd:14-17` `presets[0] as Dictionary` và `.get("party", [])` trả về kiểu Array: nếu save cũ/cloud có preset không phải Dictionary hoặc party không phải Array thì lỗi. Nên guard `typeof`.
   - `for src in [preset0_keys()]` là vòng một phần tử (còn sót từ chuỗi nguồn cũ). Dọn cho gọn.
   - **Lệch plan:** plan ghi "raid defense -> preset 0 -> ngẫu nhiên", code đã bỏ raid defense (ghi trong comment "dropped for beta, Lane I"). Cần Liam/producer biết.
4. Quà: `grant_land_gift_once(GIFT_DECOR)` gọi một lần trong `_ready` (flag `land_gift_granted`, tự save). 3 id đều có trong `assets/data/land/decor.json` (đã grep). Test kiểm ==1 sau hai lần vào Land. Ổn. (Plan cũ ghi "90 Shard", code là 3 decor, khớp ghi chú LD-B.)
5. Profile mục Land (`ProfileView.gd _land_section`): chỉ dùng `UI3.label`, `UI3Theme.space`, `_info_row`, không màu/cỡ chữ cứng trong diff. Cỡ chữ cụ thể do `LabelTitle`/`_info_row` (có sẵn) quyết định; chưa đối chiếu từng cỡ 16/18/24/32 vì không chạy được. Nên mở Profile nhìn một lần.
6. `LandQuality.is_light()` một chỗ duy nhất (`OS.has_feature("web")` chỉ ở đây); Land chỉ gọi `wanderers()`. Ổn. Chưa có `t_land_light` (plan bước 4, ưu tiên thấp); light mode mới chỉ giảm số Axie, chưa đụng bóng.
7. Test:
   - `t_land_tier_up_flow`: KHÔNG kiểm Stone bị trừ đúng một lần (đặt 20000 nhưng không assert sau nâng) và dùng `no_scene_change`, nên nhánh `back_to_land()` mới thêm không được chạy; banner chỉ kiểm khi tự dựng Land lại. Thêm assert `MetaState.stone == 20000 - cost` và gọi `confirm_upgrade` lần hai (phải false, Stone không đổi).
   - `t_land_gift_once.gd:~37-38` đặt `land_gift_granted = true` rồi `= false` liền nhau (dòng thừa).
   - `t_land_banner_once`: kiểm thật (hiện, ghi seen, qua save/load, không lặp, tier 1 không hiện). "cloud" chỉ là `reload_from_store` nội bộ, chưa phải đường apply cloud thật.
   - `t_land_my_axie`: kiểm preset 0, trùng, giới hạn, key lạ, preset rỗng, 5 vs 2 Axie. Tốt. Thiếu ca party chứa key không tồn tại ở bên trong Land (mới test ở hàm).
   - Tất cả test có SaveGuard. Chưa chạy nên số 235 chưa kiểm; cần chạy suite khi máy rảnh.

## Cần làm trước khi merge
- Bổ sung assert Stone/nâng lần hai ở `t_land_tier_up_flow`.
- Guard kiểu dữ liệu preset ở `LandAxies.preset0_keys`.
- Báo Liam việc bỏ raid defense; QA tay banner bằng bàn phím/gamepad.
