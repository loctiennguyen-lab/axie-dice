# Review AT (6 quái Atia), beta/at 6ec5298, 26/10/2026
Reviewer độc lập: lead-programmer. Verdict: **APPROVE WITH CHANGES** (2 việc bắt buộc, 1 câu hỏi cho Liam).

## 1. Data
- 6 khối chỉ số đúng bản sao 1:1 của gốc, tôi so từng face: anemone=bugling (HP 8), shiitake=jellyfin (13, ward), slimes_04=slime (9), pangolord=thornback (19, plating), e_golem=e_ravager (30), e_seahorse=e_archon (26). Không cơ chế mới. ContentDB.gd:455-494.
- Chỉ khác name/cost: 3 con min-1 cost 4 (trên slime/bugling cost 3) nên vào pool đầu run; pangolord cost 6 min 3. Dán cuối pool (ContentDB.gd:509) để tie không cắt nhầm, ý đúng.
- t_pool_diversity kiểm thật: dùng _available_normal_keys thật + bốc 180 trận thường + 79 elite, chạy PASS 23 check. Chưa có mốc "trước" trong test, chỉ FLOOR 5/5/7/15.
- monster_art.gd: NORMAL_KEYS 21, ELITE_KEYS 6, sprite fallback có đủ. OK.

## 2. Asset
- 6 thư mục mới ~4.7 MB (e_golem 1.5M lớn nhất), đạt ~5 MB. Chỉ model/tex/anims/library/tscn + .import.
- atia_models.json: clip map đúng tên có sẵn; thiếu clip hit/die ở shiitake, slimes_04, e_golem... đã bỏ khỏi map thay vì bịa, hợp lý. Tôi chưa mở từng .tscn kiểm tên clip trong library.tres, ngoài t_atia_coverage.

## 3. Test đổi
- Không nới assert nào. t_enemy_traits (dòng 172-173): chỉ thêm die 6 mặt trước end_turn, đúng (end_turn re-roll). Chạy PASS 86.
- t_anchor_awaken/t_anchor_rules (seed 7→29), t_enemy_phase_pacing (246813→2794), t_overcast (424242→211): chỉ đổi seed cho đội quái cũ, assert nguyên. Tôi KHÔNG chạy lại 4 cái này; lane nên ghi trong báo cáo rằng seed mới vẫn dựng đúng đội/kịch bản test cần.
- t_atia_coverage: 17→21, 4→6, đúng.

## 4. t_anti_stall (quan trọng)
- Không phải lỗi data. e_golem/e_seahorse y hệt e_ravager/e_archon (HP, khiên, mặt). Elite mới không khó hơn gốc; 18-23 lượt ở seed 1/7/8 là do pool elite đổi 4→6 và đội quái đi kèm đổi theo seed. Tôi suy luận từ data giống hệt, KHÔNG chạy trực tiếp ravager vs golem cùng seed (script riêng của tôi không biên dịch được với autoload).
- Tuy vậy: thay seed 1 bằng 11 là chọn seed cho dễ qua. Seed 7, 8 (18 và 23 lượt) không nằm trong test nên không bị lộ. Giới hạn 14 là bất biến thiết kế 6.7 (dmg-only bot). Nếu đội đi kèm làm elite sống 23 lượt thì anti-stall thật sự yếu hơn trên pool mới, không phải chuyện test. Test này không còn chứng minh được điều đó.
- Cần Liam quyết: (a) chấp nhận 14 chỉ áp cho seed đã chọn, hoặc (b) lane luật xem knob anti-stall/mend cap. Đề nghị thêm 1 lần chạy forced-key (ravager vs golem, seed 1) để chốt "chỉ là RNG".

## 5. RULES_VERSION (bắt buộc, chưa làm)
- Nhánh vẫn `godot-2026-10-26-t` (action_log.gd:52), FINGERPRINT t_rules_version.gd:244 chưa đổi. ContentDB.gd đổi kết quả run (pool, elite_pool) nên phải bump `-v` + tính lại FINGERPRINT, ghi cùng commit. Hiện test pass chỉ nhờ AXIE_SKIP_RULES_FINGERPRINT=1.
- Cập nhật số test floor trong technical-preferences.md (thêm t_pool_diversity) cùng commit.

## Việc phải sửa trước merge
1. Bump RULES_VERSION -v + FINGERPRINT (+ test floor).
2. Chốt hướng t_anti_stall với Liam; ghi rõ seed 7/8 trong note nếu giữ.
