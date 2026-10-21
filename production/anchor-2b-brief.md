# Anchor bước 2b — bản tóm tắt để code (đọc file này, KHÔNG cần đọc đề xuất / QA plan)

Số và chữ đã nằm trong `godot/assets/data/rules/anchors.json` + `houses.json` — đọc knob từ đó, không hard-code.
Engine có sẵn (bước 2a): `RunState.anchor_id`, `RunState.anchor_awakened` (cờ khoá cả run), `Anchors.*`, `Anchors.mutation_tier(...)`.
Chỗ cắm (grep tên hàm): `combat_engine.gd` `m100_for` (túi M, clamp `bo_cap100()`), `_bo_dice` / snapshot BỘ, `reroll_dice` (rmode 0 Liều, Nứt từ seed epoch),
`overcast` / `overcast_block_reason`, `wild_face`, `roll_all`, cuối lượt người chơi, `_apply_state_dict` + `to_data/from_data` (undo/save);
`core_hooks.gd` `is_finisher`, cách phát `CoreHooks.fire` / `EventBus.core_fired`.

## Luật nền 3 Anchor (kind "anchor", core_id = anchor_id)
- a_volley (Tam Tấu): mỗi lượt BỘ ≥3 nổ 1 lần: mọi quái nhận 30/55/80% tổng giá trị GỐC của BỘ (ba/bốn/năm), tối đa 16/quái. Base CHỈ mặt sát thương. Sát thương `from_burst` (thorn quái không phản). Giá: thưởng BỘ −0.15 (đi qua `m100_for`, sàn 100).
- a_gambler (Con Bạc): Liều sạch (≥2 viên, không viên nào Nứt) → mọi BỘ lượt này +0.30 (tối đa +0.60/lượt). Giá: Nứt khi Liều 40%.
- a_mana_mine (Mỏ Mana): lượt có BỘ tự nhiên ngay lần tung đầu: +1 mana, và Overcast lượt đó giá 1. Giá: Mặt Tạm 3 mana.
## Thức tỉnh (kind "awaken"; chỉ khi `anchor_awakened`)
- Thorn Storm (a_volley): BỘ nổ lần 2 khi dùng viên cuối của BỘ (`is_finisher`), lần 2 xuyên Khiên quái (Plating boss vẫn chặn). Lần 2 chỉ khi mọi viên BỘ dùng trong cùng lượt.
- Second Wind (a_gambler): 1 lần/lượt, khi Liều có Nứt → các viên Nứt được tung lại ngay miễn phí. Seed = dẫn xuất từ seed epoch của lần Liều đó (`seed ^ (k+1)`), `reroll_k` tăng, khoá (rmode, uids, k) giữ kết quả → undo/Liều lại ra đúng kết quả cũ.
- Double Beat (a_mana_mine): Overcast 2 lần/lượt (lần 2 giá 2).
## Đột biến Cặp 6 nhà (kind "mutation", core_id = house_id; `EventBus.mutation_on(house_id, tier)` khi nấc đổi)
Nấc từ `Anchors.mutation_tier`: 1 = có Cặp của combo trong nhà; 2 = có Đủ HOẶC 2 Cặp cùng nhà KHÔNG chung Lõi nào.
- h_volley: T1 1/3 khiên từ mặt khiên trong BỘ → Gai tạm (làm tròn xuống, tối đa 4) tới hết lượt quái; T2 Gai đủ số, khiên không bị trừ. Gai tạm = `custom_state.tmp_thorns`, xoá đầu lượt người chơi kế, có trong snapshot/save; KHÔNG đụng `thorns.cap`.
- h_gambler: T1 lần Nứt đầu mỗi lượt +1 mana; T2 hai lần Nứt đầu mỗi lượt +1 mana mỗi lần.
- h_mana_mine: cuối lượt còn ≥3 mana: tốn 1 mana, mọi quái nhận 2 (T2: 4); 1 lần/lượt; sau Mana Pool và Mana Ward; KHÔNG chạy ở lượt thắng trận.
- h_kin: lượt đầu có BỘ: Axie hàng trước ít máu nhất (kể cả Trứng) nhận Khiên = 2 × số viên BỘ (T2: 3×), không nhân BỘ.
- h_embers: viên dùng cuối lượt nếu thuộc BỘ +0.30 hệ số (T2 +0.60), qua `m100_for` (dưới m_cap).
- h_big_hand: lượt có đúng bộ ba: lần An toàn đầu miễn phí (1/lượt, vẫn tính vào 3 lần); T2 lần An toàn thứ hai giá 1.
## Luật chung bắt buộc (QA)
- MỌI hệ số mới vào `m100_for` trước clamp — không nguồn M nào khác.
- Mọi tally theo lượt/trận mới (cờ 1/lượt, Liều sạch, Gai tạm, Overcast lần 2, mana từ Nứt…) có trong snapshot undo (`_apply_state_dict`) VÀ save (`to_data/from_data`); tally Liều sạch rewind cùng `reroll_k`.
- Không ngẫu nhiên mới ngoài seed epoch/engine; run không có Anchor: số lần rút rng y như cũ (replay cũ không đổi).
- Bias trục: trục chứa Lõi ruột của Anchor đang chọn × `anchor.axis_bias` (knob, khởi điểm 1.5) ngoài bias trong ô; reroll Lõi KHÔNG bias; mục tiêu Lõi ruột hiện ~1.5x so với không Anchor (đo trong t_core_offer_weights, in tỉ lệ).
## Test cần có
t_anchor_rules (3 luật nền + giá), t_anchor_awaken (3 thức tỉnh; Second Wind + undo), t_mutation_houses (6 nhà × nấc 1/2 + undo + save/load giữa trận), cập nhật t_core_offer_weights (axis bias), t_replay thêm 1 run có Anchor offline qua RunVerifier.

## 2b phần 1 - xong
- Code: combat_engine.gd (anchor_id/anchor_awakened/anchor_turn trong snapshot+save, m100_for, Volley/Thorn Storm, Gambler/Second Wind, Mana Mine/Double Beat), RunState truyền anchor vào pending_combat, knob ở combat_tune.json mục "anchor".
- Quyết định chờ duyệt: Volley nổ lần 1 khi dùng viên đầu của BỘ; Thorn Storm nổ lần 2 khi viên cuối của BỘ được dùng (không dùng is_finisher của cả lượt); Double Beat lần 2 chồng thêm +0.5 lên chính BỘ đó (vì chỉ có 1 BỘ nên không thể Overcast BỘ khác).
- Gambler Liều sạch tính trước Second Wind; Second Wind không rút Nứt lại, không tốn mana/reroll cap.
- Test: t_anchor_rules 190, t_anchor_awaken 37; t_replay, t_bo_order, t_overcast, t_reroll_modes, t_reroll_pin xanh.
- Còn: đổi combat_tune.json đổi luật nên RULES_VERSION/t_rules_version cần bump khi merge (chưa đụng); phần 2 (6 nhà, bias trục, t_replay run Anchor).
