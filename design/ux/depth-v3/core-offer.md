# Màn chọn Lõi + Luật run, depth v3 (lane D, mục 8.6.1)
- Dùng lại overlay thưởng của RunMap (`_show_reward_overlay`); thẻ nào có `core: true` (format `CoreOffer.card_of` / `rule_card_of`) thì đổi hiển thị, không thêm màn mới.
- Thẻ Lõi: nhãn "Core", tên, dòng "Moss/Amber/Crystal · <trục>" (từ trục: Stat, Dice faces, Position, Mana, Quest, Rule change) màu theo bậc (rarity_rare / legendary / epic) + từ bậc, mô tả qua `UI3.describe`. Viền art theo màu bậc.
- Tiêu đề "CHOOSE A CORE"; chip "Next: <bậc>" cạnh tiêu đề nếu `RunState.core_next_tier` có (lane B cấp, 0..2; thiếu thì ẩn).
- Nút Reroll "Reroll · N left": N lấy `RunState.core_reroll_left` nếu có (lane B), không thì `reward_reroll_charges`. Bấm -> `_on_reward_reroll` như cũ (B nối vào offer Lõi). 0 lần = disabled có chữ lý do.
- Luật run: cùng overlay, tiêu đề "CHOOSE A RUN RULE", 2 thẻ nhãn "Run rule", thẻ "No Rule" là thẻ thường (key `rule_none`), KHÔNG có nút Reroll.
- 3 thẻ hoặc 4 thẻ (chế độ wide có sẵn khi >=4). Chọn: viền cream, Take là primary duy nhất.
- Chờ lane B: RunState.core_next_tier, core_reroll_left, và luồng đẩy `pending_rewards` bằng thẻ Lõi (hiện chỉ test bằng thẻ giả).
