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

## Làn D - bàn giao (UI + map)
Nhánh depth/D, worktree my-game-wt/DD. Spec ngắn ở `design/ux/depth-v3/` (gitignore, add -f).
Xong:
- Combat HUD (a5b9139): nút Hold (H, `combat_hold`) -> `stash`, chip HOLD trên thẻ tray, giá reroll mana ("Reroll N MP" / "Need N MP"), dải FRONT/BACK, FoeCard (nhịp boss 3 chip + tell, chip affix Elite + tooltip). Test `t_depthv3_combat_ui` (10). Ảnh `production/qa/evidence/depthv3_combat_*` (1920/1280).
- Màn chọn Lõi + Luật run (82c9f79): dùng overlay thưởng RunMap, thẻ `core:true` hiện bậc Moss/Amber/Crystal + trục, chip "Next: bậc", reroll "N left", Luật run 2 thẻ không reroll. Test `t_depthv3_core_offer` (10). Ảnh `depthv3_core_offer_*`, `depthv3_rule_offer_*`.
Còn: mục 3 (map: icon reward_kind + affix trên node, gán trong run_map_generator bằng Rng(seed ^ SALT)); mục 4 (Giáp: icon + "4 -> 1" preview + chữ "Vỡ Giáp" + coach run đầu); thẻ thứ 4 lần 1 khi có perk; ô Lõi 6 ô trên combat; chip Lõi nhiệm vụ.
Chờ làn khác (stub): `RunState.core_next_tier`, `RunState.core_reroll_left` (B, đọc bằng `RunState.get`, thiếu thì ẩn/fallback); B phải đẩy thẻ `CoreOffer.card_of` vào `pending_rewards`; A: hàm preview sát thương có Giáp, event Giáp. `combat_setup["affix"]` chưa ai điền từ map (mục 3 làm).
Chưa chạy full suite. Chưa thêm 3 test mới vào run_tests.sh (không được đụng): t_depthv3_combat_ui, t_depthv3_core_offer.
