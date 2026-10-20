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

## Lan A dot 2 - ban giao

Nhanh `depth/A`. Test lan nay xanh (chay le, AXIE_SKIP_RULES_FINGERPRINT=1): t_plating 52, t_enemy_traits 47, t_elite_affix 31 (bang affix 9 -> 14, luat doi), t_boss_rhythm 17, t_boss_encounters 71, t_replay 65. Chua chay ca suite.

### Xong (danh sach "Viec engine moi cho lan A")
- Muc 1 Plating (M1, M6): `086358b`. Muc 2-3 trait quai + ward/mend (M2, M4), muc 4 Spite (M3), muc 7 schema affix (mot phan): `9faec8f`.

### Con lai
- Muc 5 Don Nap / charge (M5): affix `charge` da co trong json nhung CHUA co logic (intent kind `charge`, chu ky 4: Nap khi `turn%4==3`, danh khi `%4==0`, x2.5, boss chi muon tell, stun/freeze ngat, chon lai muc tieu). Event `charge_start/charge_hit/charge_break` da khai bao trong EventBus, chua phat.
- Muc 6 boss dung `charge` (tell o luot Chuan bi truoc luot Don).
- Muc 7 con thieu: ham chon affix `choose_affixes` (nhom A/B, loc `no_break_ok` theo team_can_break, cap cam charge+rush, charge+frenzy, salt rieng); `guarantee_tank` (A.13).
- Muc 8: `team_can_break(team) -> bool` (static, thuan) + `t_team_can_break`; knob R12/R13: `run_rules` (da luu trong state) nhung CHUA cai: R12 side_face_bonus +2 (shield/poison/debuff cua Axie), R13 (dmg_use_soft_cap, dmg_overuse_penalty, nondmg_mana; dem `dmg_used_turn` da co trong state, chua dung). R12 plating_global da chay (`CombatTraits.plating_of`).
- Muc 10-A.14-A.15: ham preview sat thuong ("4 -> 1": dung `CombatTraits.reduce(combat, tgt, v)` la pure san, chua co ham boc cho UI); tests `t_charge`, `t_boss_plating_rhythm`, `t_plating_stack`, `t_anti_stall`, `t_affix_pairs`, `t_team_can_break`, `t_damage_cap` (Giap x Loi), ca `t_replay` charge + plating; mo rong `t_elite_affix` (nhom A/B, run dau).
- Chua lam: mo ta affix_state() cho `affix2`/`charge`; Agony khong co Giap nhip (khong co luot Ho).

### Event moi (EventBus)
`plating(uid, before, after, p)`, `plating_off(uid, turns)`, `plating_decay(uid, p_now)`, `ward(src, tgt, amount)`, `mend(src, tgt, amount)`, `spite(src, tgt, dmg, hits)`; khai bao chua phat: `charge_start(uid, target_uid)`, `charge_hit(uid, target_uid, value)`, `charge_break(uid)`.

### Knob moi (combat_tune.json)
`plating.{div 12, min 2, max 4, off_turns 2, decay_turn 7, iron_bonus 1}`, `ward.{base 3, pw_div 4, max 7, stack_cap_mult 2, elite_mult 1.5}`, `mend.{pct 0.2, cap 6, fight_cap_pct 0.5}`, `spite.{after 3, dmg 2, pw_step 8, dmg_hi 3}`, `charge.{mult 2.5, period 4, charge_at 3}`, `traits.{cap_default 2, cap_early 1}`, `run_rules.{plating_global 2, side_face_bonus 2, dmg_use_soft_cap 2, dmg_overuse_penalty 2, nondmg_mana 1}`.
`elite_affixes.json`: moi affix co `group` (A/B), `no_break_ok`; them iron, ward, spite, mend, charge; `thorns` danh dau `retired`; `forbidden_pairs`, `first_run` (ContentDB.elite_affix_meta).

### Ham / field public
- `CombatTraits` (scripts/core/combat_traits.gd): `plating_of(combat, unit)`, `plating_for_pw(pw)`, `reduce(combat, tgt, v)`, `on_debuff`, `turn_start`, `assign_traits`, `ward_amount(pw)`, `spite_damage(pw)`, `enemy_phase_start`, `on_single_hit`.
- `Unit.plating`, `Unit.plating_off`; `custom_state`: `m_trait` (plating/ward/mend), `mend_done`, `spite`.
- CombatEngine: `affix2`, `run_rules`, `spite_hits`, `dmg_used_turn` (trong snapshot). DamagePipeline.resolve nhan ctx `single: bool` (chi `_do_face` dat; Plating chi cat khi attack + single + khong pierce).
- combat_setup moi: `affix2`, `run_rules` (["R12","R13"]), `first_run_elite` (+ `team_can_break` bool: iron, hoac ward neu false), `before_first_elite` (tran thuong toi da 1 quai trait).

### Doan / luu y
- Ngan sach Giap: P = clamp(round(ContentDB.budget(pw)/12), 2, 4); voi growth 1.14 pw 11 ra 4 (doc ghi 3).
- Chain duoc tinh la dmg don (bi Giap, tinh vao Spite); cleave/aoe khong.
- Ward nham ca chinh nguon (khien thap nhat, hoa -> o nho nhat). Mend hoi 20% Max HP cua MUC TIEU.
- Quai thuong co thorns (Spikelet, Thornback, Warden) giu thorns cu; Spite chi qua affix va thay thorns cua con Elite do.
- ContentDB.enemies them field `trait` (spikelet/thornback/e_bulwark plating, jellyfin/totem ward, warden mend). Fingerprint: doi file trong autoload/, assets/data/rules/ -> gop vao bump 1.


## Lan A dot 3 - ban giao

Commit (nhanh `depth/A`): `6d0588d` Don Nap, `9a8253f` team_can_break + choose_affixes + guarantee_tank, `80eca68` preview_damage, `4f0fdb4` t_anti_stall, `3f48327` R12, `c326083` t_replay ca elite. Test moi: t_charge 25, t_team_can_break 16, t_affix_pairs 4804, t_preview_damage 45, t_anti_stall 14, t_run_rule_r12 24; t_replay 65 -> 72. Them 6 file test vao suite (floor +6, lan I cap nhat).

### Ham / field cho cac lan
- `CombatTraits.team_can_break(team: Array) -> bool` (static, thuan). Phan tu: Unit, mang mat (die), Dictionary co "die", hoac roster entry (hero_key + muts). Lan B goi luc `begin_run`, luu vao state, truyen `team_can_break` vao combat_setup. LUU Y: tier-1 beast1 khong co keyword nao -> "back Beast" trong doc KHONG tu dong true; bird1/bug1/reptile1 moi true.
- `CombatTraits.choose_affixes(seed, can_break, after_boss1, first_run=false) -> {"affix","affix2"}`: Rng rieng `seed ^ AFFIX_SALT`, khong dung rng chung; nhom A (loc `no_break_ok` neu khong pha duoc), sau boss 1 them 1 nhom B, bo cap cam (charge+rush, charge+frenzy). `affix_forbidden(a,b)`. Lan map/B goi ham nay roi dua `affix`/`affix2` vao combat_setup.
- `CombatTraits.guarantee_tank(keys, avail)` + combat_setup `guarantee_tank: true` (tran thuong truoc Elite dau, A.13): rng khong doi, quai tank dat o o 0.
- `CombatEngine.preview_damage(src, target, fi) -> {raw, after, plating, single, shield}`: thuan, khong event/rng. Khong tinh crit, exec/feral, hook Loi `mod_dmg`.
- `affix_state()` them `id2`, va neu co charge: `charge_now`, `charge_next`, `strike_now`, `charge_target`.
- Don Nap: intent co key `charge` = "start" | "hit" (elite) | "tell" (boss, luot Chuan bi). Boss khong x2.5; stun/freeze luc Chuan bi -> `charge_broken`, Don ve mat thuong. Event `charge_start/charge_hit/charge_break` da phat.
- R12: `side_face_bonus` +2 cho mat shield/poison cua Axie (gia tri) va do manh keyword debuff (weaken:2 -> weaken:4); stun/freeze giu nguyen. `plating_global` da co.
- R13: KHONG cai trong engine (lan C lam bang hook, tranh tru hai lan). `dmg_used_turn` van con trong state, chua dung.

### Doan / de Liam quyet
- t_anti_stall: doc muon <= 14 luot, do thuc te 27-33 luot (Elite pw 8 ~57 HP vs ~3 mat dmg yeu cua doi Aqua/Plant, ngay ca khong Mend). Giap het o luot 9 va Mend tran 28 HP deu chay dung; van chua dat 14. Test ghim tran 40. Can game-designer xem so HP elite / dmg doi.
- Don Nap: muc tieu = HP+khien thap nhat trong hang truoc (front_row_targets), khong phu thuoc mat. Mat danh = mat dmg manh nhat. Chu ky theo `turn` cua tran.
- R12 debuff +2 chi ap keyword co so (weaken, vulnerable, blind, burn, poison).
- guarantee_tank chuyen tank len o 0 de tran tinh `traits.cap_early` khong cat mat.
- Con thieu: `t_boss_plating_rhythm`, `t_plating_stack`, `t_damage_cap` (Giap x Loi), mo ta affix_state cho UI ngoai cac key tren.
## Làn C - bàn giao (Lõi + Luật run), xong lô 1-4
Công cụ: `godot/tools/gen_cores.py <relics_dir> [ids...]` (catalog đủ 50 Lõi + 14 luật, chạy không id = sinh lại tất cả). Logic ở `godot/scripts/core/core_hooks.gd`, entry mỏng trong `RelicHooks.TABLE` (giữa `CORE_TABLE_BEGIN/END`).
- **36 Lõi bật** (Rêu 10 / Hổ Phách 17 / Tinh Thể 9), **10 disabled chờ hook** (`needs_hook`): Vết Nứt, Con Xúc Xắc Thứ Sáu, Đồng Tâm, Thành Trì, Mai Lớn Dần, Xuống Trận, Mạch Ngầm, Tổ Ấm, Vòng Lặp, Hiến Tế; **4 cắt theo 2.10**: Mũi Giáo, Hợp Đội, Tích Ác, Phán Quyết. Hook cần của làn A/B: như danh sách cũ (Giáp, incoming_dmg, viên thứ 6, roll chung class, Axie ngủ, Egg hàng trước, cantrip thêm, đổi hàng, mana mang qua trận).
- **13 Luật run** (`rule_*`, weight 1/2, tổng 16). 9 bật có hook; 4 disabled: quick_beat (cần `boss_rhythm.period`), rising_tide, upside_down, hard_shell (Giáp, `plating_global`/`side_face_bonus`). Knob khai báo trong `rule_knobs`. rule_crow, wasteland (core_picks/core_cards), starfall(first_tier), Hoá Thạch / Hòn Đá Mờ (`next_pick_tier_up`, `grant_crystal_other_axis`, `not_pick`) là dữ liệu cho làn B đọc. Thế Cân Bằng (R13) làm hẳn bằng hook `face_final`+`on_face_used` (không cần engine A); đừng cài trùng ở làn A.
- **Trần +10/mặt**: `CoreHooks.flat()`/`FLAT_IDS`: mọi Lõi cộng phẳng đi qua đó, chỉ dùng phần còn lại sau các Lõi đứng trước. Lõi thêm cộng phẳng mới phải vào `bonus()` + `FLAT_IDS`.
- **Quest**: tiến độ do combat ghi vào `relic_run_out["c_<slug>"] = {n, boss, steps_done, done}` (`CoreHooks.quest()`); làn B chỉ cần phát thưởng theo `steps_done`. Hiệu ứng "khi chưa xong" đã có.
- Ghi chú lệch nhỏ: Gọt Xúc Xắc tính mặt yếu nhất theo từng Axie (không theo cả đội); Y Sĩ: mặt debuff chưa +3 (debuff không có số). Mặt Gương bỏ qua cantrip khi tính "viên đầu tiên".
- Test: `t_core_catalog` (in số ngưỡng 2.10: không-attack 44 / biến mặt phụ thành dmg 9 / đánh đổi 7), `t_run_rule_catalog`, `t_core_behaviour` (123 check). +2 file test so với trước.
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

## Làn E - bàn giao (nhánh depth/E, dừng giữa chừng)

Commit (mới nhất trước): bf4486e feat(core): enable Fissure, Bastion, Growing Shell, Deep Current, Nest + rules Quick Beat, Rising Tide, Upside Down, Hard Shell (engine hooks incoming_dmg, boss_period, enemy_row_pref, eggs_front); behaviour proofs still TODO;eae7934 feat(core): enable Take The Field (auto-picks the back-row Axie with most heal faces; row_of override);5e30614 feat(core): enable Concord (roll_share_class engine hook, part-chain +2) + proof;53f0ef7 feat(core): enable Sixth Die (phantom extra die) + proof;c3829ea feat(core): enable Sacrifice (sleeping unit support in engine) + proof;531845c feat(core): enable Loop (cantrip_extra engine hook) + proof;cc3b0a0 fix: post-merge catalog/rule-offer tests ignore lane B c_test_/rule_test_ fixtures;52dbeca merge: depth/B (Core flow, shop/events, INV-6) into depth/E;
- Bước 0: sửa test catalog/offer bỏ qua fixture c_test_/rule_test_ của làn B (cc3b0a0). Luồng rule_none (weight 0) vẫn xanh (t_run_rule_offer).
- Đã bật 10/10 Lõi: Vòng Lặp (hook `cantrip_extra`), Hiến Tế (Axie ngủ: `custom_state.asleep`, loại khỏi alive_party/lose-check), Xúc Xắc Thứ Sáu (đơn vị `phantom`, hook `extra_dice`, rút rng chung chỉ khi có Lõi), Đồng Tâm (`roll_share_class`, +2 chuỗi cùng part), Xuống Trận (TỰ CHỌN Axie hàng sau nhiều mặt heal nhất, không có UI chọn; `row_of` override), Vết Nứt, Thành Trì (hook `incoming_dmg` trong DamagePipeline), Mai Lớn Dần, Mạch Ngầm (qua relic_state), Tổ Ấm (`eggs_front`).
- Đã bật 4 Luật: Nhịp Gấp (`boss_period`, `boss_strike_mult`), Thuỷ Triều Lên, Thế Giới Lộn Ngược (`enemy_row_pref`), Vỏ Cứng (nối R12 qua relic_ids trong setup_new).
- Có proof trong t_core_behaviour (147 check) cho: Loop, Sacrifice, Sixth Die, Concord, Descend. CHƯA có proof: Fissure, Bastion, Growing Shell, Deep Current, Nest, 4 luật.
- Chưa làm: việc 2 anti-stall (t_anti_stall vẫn ghim trần 40); review A: (a) assert t_replay Giáp/Đòn Nạp + tamper digest, (b) t_preview_damage đối chiếu _do_face + không event, (c) charge_roll thoát sớm khi intent rỗng, (d) dmg_used_turn có dùng không (R13 làm bằng hook nên có lẽ gỡ được); cả suite + Worker test chưa chạy.
- Đoán: Mai Lớn Dần giảm stack = ceil(n/3); Thuỷ Triều: fight chẵn trước nước, đếm bằng relic_state; Nest trần Egg theo tokenCap.
