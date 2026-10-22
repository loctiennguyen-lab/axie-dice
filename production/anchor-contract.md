# Anchor contract (lane AE step 1)

Design: `design/proposals/mutation-and-keystones-v1.md` (2.1, 2.2, "Liam chốt 23/10"). Effects are NOT coded yet; this is data + read API.

## Data (`godot/assets/data/rules/`)
- `anchors.json`: array of 6. `{id a_*, enabled, name_en, name_vi, rule_en, cost_en, house_id, house_cores[5], awaken{name_en, rule_en}}`.
  enabled=true only: `a_volley` (Tam Tấu), `a_gambler` (Con Bạc), `a_mana_mine` (Mỏ Mana). Others: a_kin, a_embers, a_big_hand.
- `houses.json`: array of 6. `{id h_*, name_en, combo_ids[], mutation{name_en, tier1{rule_en, name_en, ...knob}, tier2{rule_en, ...knob}}}`.
  All 14 combos from core_combos.json sit in exactly one house. Knobs: shield_to_thorn_frac/max, mana/per_turn, min_mana/cost/dmg,
  shield_per_die, mult, free_safe/second_safe_cost.

## `Anchors` (`scripts/core/anchors.gd`, static, pure)
- `all()`, `enabled()` -> Array[Dictionary]; `get_def(anchor_id)`, `get_house(house_id)` -> Dictionary ({} if unknown); `houses()`.
- `offer_three(rng: Rng, enabled_ids: Array) -> Array`: 3 distinct ids, sorted pool then rng.next_int, so same set + same rng state = same result.
- `house_count(owned, anchor_id) -> int`, `is_awakened(owned, anchor_id) -> bool` (>= 2 house Cores, any 2).
- `house_of_combo(combo_id) -> String`.
- `mutation_tier(owned, house_id, combo_state) -> int`: 0 none, 1 a Pair, 2 a Full / jackpot / Pairs of 2 combos in the house.
- Callers pass `owned = RunState.combo_owned_ids()` (finished quest Cores count) and `combo_state = CoreCombos.state(owned)`
  (combos hidden by the Run Rule are absent, so they give no mutation but their Cores still count for awakening).

## Planned for step 2 (not built; UI lane can code against these names)
- `RunState.anchor_id: String` ("" = none), saved + replayed; chosen from `Anchors.offer_three(rng, ids)` with the run's own rng.
  Helpers: `anchor_awakened() -> bool`, `house_tier(house_id) -> int`.
- `EventBus.anchor_chosen(anchor_id: String)`, `EventBus.anchor_awakened(anchor_id: String)`,
  `EventBus.mutation_on(house_id: String, tier: int)` (fires on 0->1 and 1->2, like `combo_formed`).
- Relic name stays `r_keystone`. One RULES_VERSION bump for the whole MVP, done in step 2, not before.
- Four show-points (UI lane): offer card, HUD chip (with awakened state), mutation banner on fire, tier-2 upgrade toast.

## AU2 - bàn giao (lane anchor/ui, 21/10)
Xong và commit (xanh): việc 1 (AnchorAdapter + AnchorPick), việc 2 (HUD: ô Anchor 56px trong CorePanel, chip/badge x/2, vòng nhà + glyph trên Lõi ruột, chip "1/2 -> AWAKEN" trên thẻ Lõi; t_anchor_hud), việc 3 (dải MUTATION dưới banner PAIR, banner đột biến trong trận + 1 float/lượt/nhà; knob `banner_pair_mutation_sec`; t_anchor_mutation).
Việc 4 DANG DỞ (code đã viết, CHƯA có test, CHƯA nối vào luồng):
- `godot/scenes/shared/ui3/AnchorFx.gd` (moment 2.5s / 1.6s reduce flashing, scrim, khung đôi, sóng, rung, bấm/Space/Enter/A/Esc nhảy cuối, `AnchorFx.play(parent, id, extra_line, fly_to_rect)`, `arm/take_pending`, cờ một-lần-mỗi-run `played_run`). Import sạch, chưa chạy.
- Âm: đã chép `city_hall_upgrade_complete.ogg` vào sfx/ui, event `dm_awaken` (DiceMomentAudio), `sfx.awaken` trong gacha_timing.json, knob `awaken_sec`/`awaken_reduced_sec`. t_assets + t_v4ui_audio xanh.
- CÒN: (a) nối: RunMapController `_apply_and_finish` — nếu `AnchorAdapter.awakened()` vừa chuyển false->true khi nhận thẻ thì bỏ banner Cặp, gọi `AnchorFx.play` với extra_line "PAIR: <combo> . MUTATION: <tên>"; nguồn khác: `AnchorAdapter.listen("anchor_awakened", ...)` -> `AnchorFx.arm`, phát ở nhịp bản đồ kế (CombatView cũng listen + `dm_awaken` khi `core_fired` kind "awaken"); (b) test t_anchor_awaken (skip bằng Esc/click, reduce flashing 1.6s, một lần/run, instant_override); (c) `AnchorFx.run_key` đang dùng RunState.get("_core_base_seed"), kiểm lại với RunState của engine; (d) hit-stop 0.1s chưa làm; banner "AWAKENED" lần đầu trong trận (4.4) chưa làm; glyph nhà trong float đột biến chưa có; material_credit.ogg chưa chép (dm_mutation tạm dùng star_activate).
Việc 5 (Result: hàng Anchor + Mutations trong thẻ Combos, Codex tab Anchors, MetaState.anchor_codex qua SaveStore + reload_from_store + test lưu/đọc) và việc 6 (t_ui_laws, t_ui3_theme, t_gacha_*, cả suite một lần, ảnh 1280/1920) CHƯA làm.
Ghi chú lệch spec: glyph nhà trên Lõi ruột đặt góc dưới-TRÁI (góc dưới-phải đã là xN); chip ngoài trận khi thức tỉnh đổi thành "Awakened" (không bỏ hẳn); luật tier1 dùng cho cả Pair và Full ở dải đột biến.
## Hợp đồng sự kiện cho UI (điều phối chốt 23/10)
- Luật nền Anchor tác động: `EventBus.core_fired(core_id = anchor_id, unit_uid, amount, kind = "anchor")`.
- Đột biến Cặp tác động: `core_fired(core_id = house_id, unit_uid, amount, kind = "mutation")`; khi nấc đột biến của một nhà thay đổi: `EventBus.mutation_on(house_id: String, tier: int)`.
- Thức tỉnh: lần đầu đạt ≥2 Lõi ruột → `EventBus.anchor_awakened(anchor_id)` (một lần/run); luật thức tỉnh tác động: `core_fired(core_id = anchor_id, ..., kind = "awaken")`.
- Codex: UI được thêm `MetaState.anchor_codex` (qua SaveStore + `reload_from_store()`); lần merge này bump RULES_VERSION nên fingerprint cập nhật luôn.

## AE bước 2a - xong (API thật cho UI)
Chưa có hiệu ứng đột biến/thức tỉnh (bước 2b): `mutation_on` và `core_fired kind=anchor|mutation|awaken` chưa phát.

**RunState** (`autoload/RunState.gd`)
- Field: `anchor_id: String` ("" = không có), `anchor_awakened: bool` (cờ khoá, không bao giờ tắt), `anchor_offer: Array` (3 id, giữ sau khi chọn), `anchor_wanted: bool`. Tất cả lưu trong `to_data()["anchor"]`, `reset()` xoá, `from_data()` đọc.
- Opt-in: UI truyền `params["anchor"] = true` vào `begin_run` / `start_run_with_epoch`. Không truyền = luồng cũ, không đổi gì. Không ghi header, không ghi action log.
- `anchor_gate_reason() -> String`: "" = mở; "off" (không opt-in) | "online" (không phải LocalEpochSource) | "ranked" | "kind" (daily/mission) | "stage" (`depth_stage` < 3) | "core_off".
- `anchor_offer_open() -> bool`: true khi đang chờ chọn (cổng mở, chưa có Anchor, còn ít nhất 1 Anchor chọn được). Lần đầu gọi thì tạo `anchor_offer` từ `Rng(base_seed ^ CoreOffer.ANCHOR_SALT)`.
- `anchor_disabled_reason(id) -> String` (G6): "" = chọn được; "rule_too_few_house_cores" = Luật run hiện tại để lại < 2 Lõi ruột hợp lệ; "unknown". UI vẽ thẻ xám + lý do. (Hiện chưa Luật nào làm vậy với 3 Anchor bật, test đã liệt kê.)
- `pick_anchor(id) -> bool`: khoá, `save_run()` ngay, phát `anchor_chosen`, rồi mới mở offer Lõi 1. `decline_anchor() -> bool`: bỏ qua, mở offer Lõi 1.
- Luồng: sau Luật run (nếu có), thay vì offer Lõi 1, run vào `phase == REWARD` với `pending_rewards` RỖNG và `_anchor_waiting == true` (cũng được lưu). UI thấy `anchor_offer_open()` thì hiện màn chọn Anchor.
- Thức tỉnh: trong `_grant_relic` sau `_note_combo_grant()`, đạt >= 2 Lõi ruột (Lõi quest đã xong tính) thì bật `anchor_awakened` và phát `anchor_awakened` đúng 1 lần/run.

**EventBus**: `anchor_chosen(anchor_id)`, `anchor_awakened(anchor_id)`.

**Verifier**: header hoặc `header.loadout` có `anchor_id != ""` -> `bad_header`.

**R1 + bias** (`core_offer.gd`, knob trong `relic_tuning.gd`): `axis_weight_cap` 4, `anchor_house_bias` 1.5. Bias chỉ áp trong ô khi `build_offer` (ctx `anchor_house`); `reroll_card` không áp. Test: `t_anchor_runstate`, `t_core_offer_weights`.
