# Combat HUD, depth v3 (lane D, mục 8.6.2)
- Hold: nút full-width trên hàng Undo/Reroll (CombatHud.hold_button), phím H (`combat_hold`). Chọn viên rồi bấm -> `CombatEngine.stash(uid)` (log `stash [uid]`). Disabled nói lý do: "Hold: pick a die" / "Holding 1/1" / "Hold: not allowed".
- Viên đang giữ: chip "HOLD" trên thẻ tray, thẻ không bấm được (TrayColumn `held`).
- Reroll: hết lượt miễn phí thì nút hiện "Reroll N MP" (giá = `reroll_mana_cost()`), thiếu mana: "Need N MP", hết trần: "No rerolls". Tooltip giải thích.
- Hàng trước/sau: dải "FRONT" / "BACK" có gạch ngang trên tray (CombatView._layout_row_strip, theo `row_of`), tooltip nói luật đánh đơn mục tiêu.
- Thẻ "FoeCard" cột trái dưới Attrition: boss = 3 chip Prep/Strike/Hollow (hiện tại = viền chọn, kế tiếp = dấu *) + dòng tell lượt kế (`boss_rhythm_state`); Elite = chip affix (icon node_elite + tên + "acts twice NOW/NEXT") với tooltip dựng từ key data (`CombatView.affix_tip`).
- Chữ 18/24 chỉ; token UI3; không màu đứng một mình (có chữ).
