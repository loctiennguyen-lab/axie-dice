# Review LD-B (beta/ldb, b40d54e + 2457c8b) — lead-programmer, 26/10

**Verdict: APPROVE WITH CHANGES** (không có lỗi chặn merge; 2 việc nhỏ khi merge)

Đã chạy riêng lẻ (không cờ gì ngoài SKIP_RULES_FINGERPRINT): t_decor_data, t_decor_rules, t_decor_score, t_decor_milestones, t_land_upgrade (29), t_decor_save, t_decor_edit: tất cả PASS.

## 1. Data khớp số chốt: ĐÚNG
- `land_tiers.json`: tier 2 = 20000, tổng 20k+100k+180k+500k+1M = 1,8M.
- `decor.json`: 27 def (26 craftable + Trophy), 8 common mới + 2 Rare (`decor_for_tree2`, `decor_sav_tree3a`) min_tier 2, max_own 4, R = 3 điểm. Mốc 5/12/20/30/42/60/80/100. Giá/footprint/scale đúng bảng LD-D.
- Mọi `scene` trong json đều có file .tscn thật (script kiểm 27/27).
- Test mới `t_decor_score` tính trần 14/32/54 từ data thật và assert trần T2 >= m4+2 (đúng yêu cầu review LD-D).

## 2. min_tier: KHÔNG làm mất đồ
- `land_decor.gd:113` `placement_block` chặn đặt khi tier < min_tier (trước đó không có chặn, đúng điều plan lo).
- `craft_block` (dòng 71) đã có chặn min_tier từ trước, nên T1 không craft được Rare.
- `sanitize` (dòng 158) bỏ khỏi `placed` món vượt tier; `owned` giữ nguyên nên món về kho (docstring dòng 146-147 đúng). `LandEdit.gd:69-79` chỉ gán `placed` trong bộ nhớ, load không ghi save. Không xoá âm thầm.
- Thực tế tier không giảm nên nhánh này chỉ chạy với save sửa tay / `tier_override`; an toàn.

## 3. Asset: OK
- Chỉ 2 scene mới (`F_Plant01`, `S_Shrub03_Allside`) + Plant01.fbx (25 KB) + T_Plant01_C.png (274 KB) + .tres + 2 .import. Tổng ~0,3 MB, không kéo file thừa. Các `ext_resource` res:// đều trỏ tới file có thật; .import có uid + dest_files hợp lệ.
- Chưa mở scene để xem hình (technical-artist đã đổi tên S_Tree03a thành "Bare Baobab" ở 2457c8b).

## 4. Test: kiểm thật, 2 điểm yếu nhỏ
- `t_decor_rules` kiểm placement_block và sanitize cho cả T1 lẫn T2 (cặp đúng/sai), không chỉ đếm.
- Yếu 1: không có test khẳng định món bị `sanitize` bỏ vẫn còn trong `land_decor_owned` sau `build_placed` (tính chất "không mất đồ" chỉ nằm trong docstring). Nên thêm 2-3 dòng vào `t_decor_save` hoặc `t_decor_edit`.
- Yếu 2: plan nhắc `t_land_milestones` nhưng file này không tồn tại; milestones nằm ở `t_decor_milestones` (đã sửa "m8 needs 100"). Test m8 chỉ kiểm nhận được ở 100 điểm, chưa kiểm 99 bị từ chối (cũ cũng vậy).
- Nhỏ: `t_decor_data.gd:8` message "26 craftable + trophy" khớp, ok.

## 5. economy_db.gd: "Run result: NO" ĐÚNG
- Diff `scripts/meta/economy_db.gd` chỉ đổi hằng validate 1820000 -> 1800000 (+ message). Không đụng `core/`, `autoload/`, `assets/data/rules/`. `land_tiers.json` và `decor.json` nằm ngoài WATCHED_DIRS.
- Chạy `t_rules_version` KHÔNG cờ skip: FAIL như dự kiến (fingerprint dời vì economy_db.gd). Cần ghim lại FINGERPRINT khi merge, không bump RULES_VERSION.

## Việc cần làm
1. Khi merge: ghim FINGERPRINT trong `t_rules_version.gd`, ghi "Run result: NO".
2. (nên) thêm test "sanitize không làm mất owned" như mục 4.
3. Còn lại ngoài phạm vi review code: Liam cần biết quà 3 món = 7 điểm qua m1 (đã ghi trong plan); chưa nhìn hình decor trong Land (QA luồng thật).
