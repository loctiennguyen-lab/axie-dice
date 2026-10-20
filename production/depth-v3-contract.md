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

## Làn B - bàn giao (nhánh depth/B)

Commit: bb77554 (schema + ẩn relic cũ + CoreOffer + slots), ddeb88a (flow RunState + verifier + 7 test). Test lẻ xanh: t_core_offer, t_core_tierchain, t_core_reroll_card, t_core_seen, t_core_filter, t_core_quest, t_run_rule_offer, t_relic_* (đã sửa), t_replay, t_full_run_loop, t_boss_pact. Cả suite CHƯA chạy.

**Xong:** bước 1 (schema), 2 (offer), 3 (reroll TỪNG THẺ, không đổi schema Worker: action `reroll_rewards [slot]`, args tự do; ALLOWED_FNS không đổi), 4 (6 ô Core + 1 ô Luật, đầy thì bán: `take_reward [idx, sell_id]`), 5 (quest nhiều nấc), 6 (offer Luật run), 8 một phần (verifier gọi after_node sau mỗi take_reward, mở offer của event/shop khi tới pick).
**Còn:** bước 7 (shop/event cho relic -> lần chọn Lõi; `RunState.apply_event_fx`, `generate_shop_items` còn gọi pick_relic, pool rỗng nên không crash nhưng chưa đổi thành Core pick), bước 9 (chữ INV-6 trong build-spec.md), test replay riêng cho Core (chưa có test dùng Core thật qua RunVerifier, cần tape; t_replay hiện chỉ chạy pool rỗng), Worker test (không đổi gì phía Worker), tests để RulesVersion (không đụng), Luật run R6 (bỏ lần chọn) chưa có knob.

**File/hàm chính:** `scripts/core/core_offer.gd` (CoreOffer: draw_tier_chain, effective_tier, token_ok, valid_pool, build_offer, reroll_card, can_reroll_card, build_rule_offer); `autoload/RunState.gd` cuối file (`_open_opening_offers`, `_open_core_offer`, `_core_trigger_hit`, `_reroll_core_card`, `_apply_core_pick`, `note_quest_event`, `_open_bonus_offer`, `rule_knob`, `add_core_tier_bump`, `core_can_reroll`); `relic_slots.gd` (_check_add_core, owned_cores); `relic_def.gd` (core_axis, requires, excludes, disabled, first_run_hidden, run_rule, quest, rule_knobs); `relic_tuning.gd` (core_* knob, tier_chains, core_triggers_short/full).

**Quyết định/đoán:**
- Core offer = `pending_rewards` (card có core=true, phase REWARD). Pick 1 (và offer Luật run) mở ngay trong `_start_core`; pick 2.. mở trong `after_node()` theo `core_triggers_*` (row 5, boss1, boss2; Full thêm row 18, boss3). UI/D: sau take_reward vẫn gọi after_node() như cũ (bước chain tự bỏ qua).
- Loadout cờ mới: `rules_on` (mặc định `MetaState.runs > 0`, lưu vào header loadout) và `core_off` (test/tool). Không thêm field meta nên không đụng reload_from_store.
- Perk relic0/relic1/u_start: không còn tặng relic, chỉ `core_first_extra` (4 thẻ ở pick 1).
- Seed: pick 1 = seed bắt đầu run ^ CORE_SALT; pick sau = `_node_seed` của node vừa đóng ^ CORE_SALT ^ (index * 0x9E3779B1); reroll = seed epoch `reward_reroll` (k = số reroll Core đã dùng + 1) ^ CORE_SALT.
- Run đầu (rules_on=false): không Luật, không Lõi quest/first_run_hidden.
- Token `requires/excludes`: class_pair, face:x, back_face:x|y, faces_distinct:n, front_hero, egg_source, owned:id, owned_axis:a, owned_tag:t, rule:id. Token lạ = false.
- Quest: `quest={kind(wins|elite|boss), steps:[{target,reward_tier}]}`; mỗi nấc xong xếp 1 offer vào `core_bonus_queue`, mở ở after_node kế; nấc cuối gỡ Lõi khỏi ô.
- Tier bump Elite affix(+) / Quạ: gọi `RunState.add_core_tier_bump(n)` trước khi offer kế mở (làn D/C nối).
- Nội dung mẫu `c_test_*` / `rule_test_*` để `disabled = true` (người chơi không thấy); test gọi `CoreTestUtil.enable()`. `rule_none` bật thật. Hiện game thật không có Lõi nào hiển thị tới khi làn C thêm.
- Relic cũ: tất cả non-pact đã `hidden_from_pool = true`; test cũ gọi `RelicRegistry.legacy_unhide_for_tests()`.


### Làn B - cập nhật cuối (agent 2)
Xong bước 7 (event chest/bet_small/gamble_legend xếp 1 lần chọn Lõi vào `core_bonus_queue`: chest = Hổ Phách, bet_small thắng và gamble_legend = Tinh Thể; shop có món "Core Pick" bậc Rêu giá `core_shop_cost`=60 shard trong run, đặt cuối danh sách, shop không còn bán relic cũ ở chế độ Lõi; không bán reroll Lõi), knob R6 `core_skip_picks` (mảng chỉ số lần chọn bị bỏ, 0-based; R6 = [1]; chưa có file R6, "+4 Max HP" chưa làm), test `t_core_replay` (RunBot có `core_script`, `drain_core_offers`), INV-6 trong build-spec. Pick Lõi từ event/shop mở ở `after_node` kế (không mở giữa shop). `pick_relic` và `pick_offer_relic` bỏ qua Lõi. Shop refresh (Aid R6) giờ ra hàng giống hệt (không còn relic ngẫu nhiên): cần hỏi Liam/economy có cần đổi. Giá 60 và bậc event là đoán.
