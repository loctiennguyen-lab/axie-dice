# Depth v3 - hợp đồng làn A (engine chiến đấu) cho các làn sau

Nguồn: `design/proposals/depth-v3-design.md`. Nhánh `depth/A`. Mọi knob đọc qua `CombatEngine.tune_knob(section, key, default)`.

## Action mới
- `stash` `[uid]`: Hold một viên chưa dùng. Có trong ALLOWED_FNS ở `action_log.gd`, `worker/src/run_core.js`, `tests/t_replay.gd`; `run_verifier.gd` tái hiện. Engine: `can_stash(uid)`, `stash(uid)`, `stash_count()`, `stash_cap()`. Field `Unit.held` / `Unit.stash_carry`. Không đè `hold_pick` (relic Amber).
- Reroll KHÔNG có action mới: vẫn `reroll_dice [uids, from_aid]`, epoch source vẫn `base`/`aid`. Engine trừ mana, verifier tái hiện (reroll trả mana mà thiếu mana bị từ chối).

## Knob mới trong `godot/assets/data/rules/combat_tune.json`
- `stash.cap` = 1
- `reroll.free` = 1, `reroll.mana_cost` = 2, `reroll.max_total` = 4 (tổng lượt, tính phần trả mana), `reroll.conduit_step` = 3 (Aqua: mana đổi 1 reroll)
- `rows.front_size` = 2
- `difficulty.enemy_dmg_mult` = 1.2 (quái thường/elite), `difficulty.boss_hp_mult` = 1.1 (boss, áp trong `ContentDB.boss_stats`; boss dmg cũng nhân enemy_dmg_mult ở đó)
- `TUNE.growth` 1.14, `TUNE.elite_mult` 1.5
- `boss_rhythm.enabled` 1, `.period` 3, `.hollow_taken_pct` 30, `.hollow_dealt_pct` -30
- File mới `elite_affixes.json`: 9 affix (echo, shell, frenzy, swarm, thorns, rush, fang, ambush, chill), nạp vào `ContentDB.elite_affixes`. Combat nhận qua `combat_setup["affix"]` (chỉ kind elite, gắn lên enemies[0]). Làn map chọn affix và truyền xuống; `plus=true` = affix (+) (swarm, rush, ambush) để làn reward ép bậc Hổ Phách.

## Hook / event để Lõi (làn B/C) móc vào
Qua `RelicHooks.fire` (event không có handler thì bỏ qua, không cần sửa `relic_hooks.gd` để engine chạy):
- `on_stash` ctx `{combat, unit, face, fi}`: sau khi Hold thành công.
- `on_reroll_paid` ctx `{combat, cost, k}`: reroll trả mana (không bắn cho reroll miễn phí / Aid).
- `on_boss_rhythm` ctx `{combat, boss, phase, next}`: đầu lượt boss, phase = prep/strike/hollow.
Qua `RelicHooks.run_value_hook` (value đầu vào = knob):
- `stash_cap` (nâng trần Giữ), `stash_repeat` (cho giữ liên tiếp, Giữ Vững; ctx có `unit`, mặc định false)
- `reroll_mana_cost` (giảm giá reroll), `front_row_size` (hàng trước rộng hơn)
EventBus: `die_stashed(uid)` cho UI. Đổi hàng giữa trận: không có (hàng theo `roster_index`, chỉ đổi qua `reorder_party` ngoài trận) nên chưa có event "đổi hàng". Hàm đọc cho UI: `row_of(unit)`, `boss_rhythm_state(boss)`, `affix_state()`, `reroll_mana_cost()`, `reroll_is_payable()`.

## Luật hàng trước/sau (5 dòng)
1. Hàng trước = roster_index 0..`rows.front_size`-1 (mặc định 0-1); còn lại là hàng sau.
2. Egg/token (`roster_index = -1`) đứng hàng sau.
3. Quái đánh đơn mục tiêu (dmg/poison/debuff) chỉ chọn hàng trước còn sống; hết hàng trước mới đánh hàng sau.
4. Mặt có `aoe` hoặc `pierce` bỏ qua hàng. Role assassin giữ hành vi cũ: nhắm Axie yếu nhất cả đội.
5. Intent vẫn công khai đúng mục tiêu; affix `ambush` nhắm yếu nhất HÀNG SAU (đơn mục tiêu).

## Ghi chú khác
- Hold: viên giữ không roll lại ở đầu lượt kế (không bốc rng), dùng được ngay, không giữ lại được liên tiếp; viên cantrip / Frozen / token / đã dùng không giữ được.
- Nhịp boss: strike = `turn_count % 3 == 0` (OVERDRIVE Mecha, brood Plague Mother đã ở đó), hollow = lượt kế (boss nhận +30% dmg từ mặt dmg, đánh -30%), prep = còn lại. Agony không có nhịp (hai pha riêng). Tell riêng đã làm: Mecha (hollow mở gai), Frost (strike đóng băng 2, hollow 0), Mirror (hollow không chép). Gooey/Plague chỉ có nhịp chung.

## Làn C - bàn giao (Lõi + Luật run), xong lô 1-4
Công cụ: `godot/tools/gen_cores.py <relics_dir> [ids...]` (catalog đủ 50 Lõi + 14 luật, chạy không id = sinh lại tất cả). Logic ở `godot/scripts/core/core_hooks.gd`, entry mỏng trong `RelicHooks.TABLE` (giữa `CORE_TABLE_BEGIN/END`).
- **36 Lõi bật** (Rêu 10 / Hổ Phách 17 / Tinh Thể 9), **10 disabled chờ hook** (`needs_hook`): Vết Nứt, Con Xúc Xắc Thứ Sáu, Đồng Tâm, Thành Trì, Mai Lớn Dần, Xuống Trận, Mạch Ngầm, Tổ Ấm, Vòng Lặp, Hiến Tế; **4 cắt theo 2.10**: Mũi Giáo, Hợp Đội, Tích Ác, Phán Quyết. Hook cần của làn A/B: như danh sách cũ (Giáp, incoming_dmg, viên thứ 6, roll chung class, Axie ngủ, Egg hàng trước, cantrip thêm, đổi hàng, mana mang qua trận).
- **13 Luật run** (`rule_*`, weight 1/2, tổng 16). 9 bật có hook; 4 disabled: quick_beat (cần `boss_rhythm.period`), rising_tide, upside_down, hard_shell (Giáp, `plating_global`/`side_face_bonus`). Knob khai báo trong `rule_knobs`. rule_crow, wasteland (core_picks/core_cards), starfall(first_tier), Hoá Thạch / Hòn Đá Mờ (`next_pick_tier_up`, `grant_crystal_other_axis`, `not_pick`) là dữ liệu cho làn B đọc. Thế Cân Bằng (R13) làm hẳn bằng hook `face_final`+`on_face_used` (không cần engine A); đừng cài trùng ở làn A.
- **Trần +10/mặt**: `CoreHooks.flat()`/`FLAT_IDS`: mọi Lõi cộng phẳng đi qua đó, chỉ dùng phần còn lại sau các Lõi đứng trước. Lõi thêm cộng phẳng mới phải vào `bonus()` + `FLAT_IDS`.
- **Quest**: tiến độ do combat ghi vào `relic_run_out["c_<slug>"] = {n, boss, steps_done, done}` (`CoreHooks.quest()`); làn B chỉ cần phát thưởng theo `steps_done`. Hiệu ứng "khi chưa xong" đã có.
- Ghi chú lệch nhỏ: Gọt Xúc Xắc tính mặt yếu nhất theo từng Axie (không theo cả đội); Y Sĩ: mặt debuff chưa +3 (debuff không có số). Mặt Gương bỏ qua cantrip khi tính "viên đầu tiên".
- Test: `t_core_catalog` (in số ngưỡng 2.10: không-attack 44 / biến mặt phụ thành dmg 9 / đánh đổi 7), `t_run_rule_catalog`, `t_core_behaviour` (123 check). +2 file test so với trước.
