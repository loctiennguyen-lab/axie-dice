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

## Làn C - bàn giao (Lõi + Luật run), dừng sau lô 1 (WIP)
Công cụ: `godot/tools/gen_cores.py <relics_dir> [ids...]` sinh `.tres` từ catalog (đủ 50 Lõi + 14 luật); chạy với id của lô cần bật, rồi thêm entry TABLE + hàm trong core_hooks.gd. Game text là tiếng Anh; tên Việt trong doc ↔ id dưới đây. Logic hook ở `godot/scripts/core/core_hooks.gd` (class `CoreHooks`), `RelicHooks.TABLE` chỉ có entry mỏng gọi sang đó (khối giữa `CORE_TABLE_BEGIN/END`). Thêm `RelicDef.weight` (trọng số Luật run, mặc định 1). Đã sửa `t_relic_set_v2` (bỏ Lõi khỏi đếm 133). Thêm `t_core_behaviour` (35 check, +1 file test: sàn tăng 1).

**Đã viết và bật (10), có hook + proof:** c_early_scales (Vảy Sớm), c_dewdrop (Giọt Sương), c_elder_trunk (Thân Cổ Thụ), c_steady_hold (Giữ Vững), c_kindle (Cất Lửa), c_prime_chain (Chuỗi Mồi), c_finisher (Kết Cục), c_prism (Đa Sắc), c_mana_pool (Hồ Mana), c_tidecaller (Ngọn Triều). Chỉ 5 có proof trong t_core_behaviour (early_scales, dewdrop, mana_pool, elder_trunk, steady_hold, finisher); kindle/prime/prism/tidecaller chưa có proof.
**File disabled đã ghi (14, `disabled`+`hidden_from_pool`, `needs_hook` ghi lý do):** c_spearhead, c_squad_up, c_wicked_tally, c_verdict (cắt 2.10); c_fissure, c_bastion, c_sixth_die, c_concord, c_growing_shell, c_descend, c_deep_current, c_nest, c_loop, c_sacrifice (chờ hook, xem dưới). Cũng có `rule_none` (weight 0, TABLE entry rỗng).
**Còn phải viết (catalog đã nằm đầy đủ trong gen_cores.py, nay chưa có file):** dice: c_sonic_shield, c_field_medic, c_plague_spread, c_mirror_face, c_whittle, c_three_dice, c_toxic_still. pos: c_gatekeeper, c_backline_glow, c_living_wall, c_open_ranks. mana: c_mana_ward, c_overflow, c_hollow_core, c_thorn_pact. quest (data + hiệu ứng "khi chưa xong"): c_collector, c_dry_well, c_night_watch, c_key_strike, c_chimera_hunt. rule: c_golden_egg, c_blood_sign, c_cascade, c_spore_burst, c_fossil, c_dim_stone. 13 Luật run (rule_*: cheap_mana, tundra, quick_beat, starfall, heavy_finish, wasteland, dry_steppe, rising_tide, upside_down, old_forest, crow, hard_shell, balance; weight 2 cho old_forest, hard_shell, balance) + `t_core_catalog`, `t_run_rule_catalog` (tổng trọng số 16), proof còn thiếu.
**Cách làm đã chốt cho phần còn lại (không cần sửa engine):** `face_final` (value hook, KHÔNG đổi state, UI dùng để preview) cho số cộng; `on_face_used` (ctx: unit, face, side, depth) để đếm; `on_turn_end/start`; `reroll_mana_cost`, `rerollUp` (âm = bỏ reroll miễn phí); trần reroll tổng tăng bằng cách giảm `combat.reroll_nonaid` trong `on_reroll_paid` (Lõi Rỗng 4→8, Mana Rẻ 4→5); Mặt Gương bằng `Unit.clear_used_for_second_action()` trong `on_face_used`; Ba Viên bằng cách set `u.held = true` cho viên còn lại sau lần dùng thứ 3 và ở `on_turn_end`; Mạch Ngầm / Mai Lớn Dần có thể dùng `relic_run_out` nếu RunState lưu nó (cần kiểm); Kẻ Gác Cổng dùng `on_dmg_taken` (ctx src,tgt,attack) + intent không aoe.

**Cần hook / việc của làn khác (danh sách cho làn A, B):**
- A: (1) hook phía mục tiêu cho sát thương đơn mục tiêu nhận vào (`incoming_dmg`, ctx src/tgt/single:bool) → Thành Trì, Thuỷ Triều Lên. (2) Giáp + dấu trạng thái quái (6.7 M1) → Vết Nứt, Vỏ Cứng (`plating_global`, `side_face_bonus`). (3) viên phụ thứ 6 tạm thời → Con Xúc Xắc Thứ Sáu. (4) roll chung theo class + theo dõi part → Đồng Tâm. (5) Axie "ngủ" (không viên, không bị chọn) → Hiến Tế. (6) Egg ở hàng trước → Tổ Ấm. (7) lượt cantrip thêm → Vòng Lặp. (8) knob `boss_rhythm.period` đọc qua hook → Nhịp Gấp. (9) ưu tiên hàng mục tiêu quái → Thế Giới Lộn Ngược. (10) đổi hàng vĩnh viễn Axie (cả roster, RunState) → Xuống Trận.
- B: token cho `requires/excludes` (CoreOffer chỉ có token cũ, token lạ = false): `team_can_break` (R12 requires), `face_any:poison|debuff` (Vết Nứt), `nondmg_faces:<n>` (Sóng Khiên, Y Sĩ; tạm dùng `face:shield` / `faces_distinct:3`). Rule ids ở `excludes` dùng dạng `rule:rule_<slug>`. Hoá Thạch/Hòn Đá Mờ: `rule_knobs` có `bet`/`pick_max` (chỉ lần 1-2 / không lần 2 và cuối) do B xử lý. R1 chỉ rút khi Ascension<3 (`rule_knobs.asc_lt`). Quest: dict `quest` có `kind` mới (distinct_faces_turn, mana_spent, boss_no_loss, held_big_hit, finisher_kills) — B làm tracker. Mai Lớn Dần/Mạch Ngầm cần field run nếu `relic_run_out` không được lưu.
- Ghi chú: trần +10/mặt (3.4) chưa được áp chung cho các Lõi của làn C; cần một hàm cap chung ở face_final sau khi mọi Lõi xong (đề nghị làm cuối).
