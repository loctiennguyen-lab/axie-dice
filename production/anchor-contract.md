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

## Hợp đồng sự kiện cho UI (điều phối chốt 23/10)
- Luật nền Anchor tác động: `EventBus.core_fired(core_id = anchor_id, unit_uid, amount, kind = "anchor")`.
- Đột biến Cặp tác động: `core_fired(core_id = house_id, unit_uid, amount, kind = "mutation")`; khi nấc đột biến của một nhà thay đổi: `EventBus.mutation_on(house_id: String, tier: int)`.
- Thức tỉnh: lần đầu đạt ≥2 Lõi ruột → `EventBus.anchor_awakened(anchor_id)` (một lần/run); luật thức tỉnh tác động: `core_fired(core_id = anchor_id, ..., kind = "awaken")`.
- Codex: UI được thêm `MetaState.anchor_codex` (qua SaveStore + `reload_from_store()`); lần merge này bump RULES_VERSION nên fingerprint cập nhật luôn.
