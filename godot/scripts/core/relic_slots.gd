class_name RelicSlots
extends RefCounted
## Relic slot model: 8 passive + 3 active slots, 1 G multiplier slot + 2 A multiplier slots.
## Implements design/proposals/relic-set-v2.md §3.1 and production/l1-interfaces.md §2.4.
##
## Static and pure: nothing here touches RunState. RunState.acquire_relic()/sell_relic() (lane A)
## call these to decide whether a relic may be taken, and what must be sold first.
## Numbers (8/7/3/4, 1 G, 2 A, sell %) come from resources/relics/relic_tuning.tres.
##
## Slot kinds: a relic with act_cost > 0 is ACTIVE (own 3 slots); everything else is PASSIVE
## (pacts and u_start relics included). A passive with mult_axis "G" / "A:*" also needs a free
## G / A slot, even when passive slots are free.

const TUNING_PATH := "res://resources/relics/relic_tuning.tres"
const STICKER_ETERNAL := "eternal"

static var _tuning: RelicTuning = null


static func tuning() -> RelicTuning:
	if _tuning == null:
		_tuning = load(TUNING_PATH) as RelicTuning
		if _tuning == null:
			_tuning = RelicTuning.new()
	return _tuning


## {passive: 8|7, active: 3|4, g: 1, a: 2}. `owned_ids` is read for hollowchalice (+1 active).
static func capacity(ascension: int, owned_ids: Array) -> Dictionary:
	var t := tuning()
	var passive := t.passive_slots_cramped if ascension >= t.cramped_from_ascension else t.passive_slots
	var active := t.active_slots + (t.active_slots_extra if owned_ids.has(t.chalice_id) else 0)
	return {"passive": passive, "active": active, "g": t.g_slots, "a": t.a_slots}


## Decide whether `new_id` may be taken now. See relic-set-v2 §3.1 "Bảng luật ô đầy".
## Returns {ok, needs_sell, sell_from: Array[String], reason, can_cancel}.
##   ok          the relic CAN be taken (possibly after selling one of `sell_from`).
##   needs_sell  the player must sell exactly one of `sell_from` to take it.
##   can_cancel  false only for a forced pact (A6 first boss / A10 every boss).
## reason when ok == false: "unknown_relic" | "already_owned" | "no_sellable" (every candidate to
## sell is Eternal, so the card is greyed out).
## `stickers`: relic id -> "eternal". Eternal relics are never sellable.
static func check_add(owned_ids: Array, stickers: Dictionary, new_id: String,
		ascension: int, forced: bool) -> Dictionary:
	var out := {"ok": true, "needs_sell": false, "sell_from": [] as Array[String],
		"reason": "", "can_cancel": not forced}
	var nd = RelicRegistry.get_def(new_id)
	if nd == null:
		out["ok"] = false
		out["reason"] = "unknown_relic"
		return out
	if owned_ids.has(new_id):
		out["ok"] = false
		out["reason"] = "already_owned"
		return out
	var cap := capacity(ascension, owned_ids)
	var is_active := _is_active(nd)
	var axis := String(nd.mult_axis)
	var same_kind: Array[String] = []        # owned relics of the same slot kind
	var same_axis: Array[String] = []        # owned relics holding the same multiplier slot kind
	for oid in owned_ids:
		var od = RelicRegistry.get_def(String(oid))
		if od == null or String(oid).begins_with("__"):
			continue
		if _is_active(od) == is_active:
			same_kind.append(String(oid))
		if axis != "" and _axis_class(String(od.mult_axis)) == _axis_class(axis):
			same_axis.append(String(oid))
	var kind_full: bool = same_kind.size() >= int(cap["active"] if is_active else cap["passive"])
	var axis_full := false
	if axis != "" and not is_active:
		axis_full = same_axis.size() >= int(cap["g"] if _axis_class(axis) == "G" else cap["a"])
	var candidates: Array[String] = []
	if axis_full:
		candidates = same_axis      # must sell the same multiplier kind, no dodging (§3.1)
	elif kind_full:
		candidates = same_kind
	else:
		return out
	for cid in candidates:
		if String(stickers.get(cid, "")) != STICKER_ETERNAL:
			(out["sell_from"] as Array[String]).append(cid)
	out["needs_sell"] = true
	if (out["sell_from"] as Array).is_empty():
		out["ok"] = false
		out["reason"] = "no_sellable"
	return out


## Sell price in Gene Shards: 50% of the rarity buy price, 40% from A1, rounded down.
## Buy prices are RewardGenerator.RELIC_SHOP_COST (45/75/120/180).
static func sell_price(relic_id: String, ascension: int) -> int:
	var def = RelicRegistry.get_def(relic_id)
	if def == null:
		return 0
	var t := tuning()
	var pct := t.sell_pct_ascended if ascension >= t.sell_pct_from_ascension else t.sell_pct
	var cost: int = int(RewardGenerator.RELIC_SHOP_COST[mini(maxi(int(def.rarity), 0), 4)])
	return (cost * pct) / 100


## True for pacts (boss-only relics with a drawback).
static func is_pact(relic_id: String) -> bool:
	var def = RelicRegistry.get_def(relic_id)
	return def != null and String(def.pact_group) != ""


static func _is_active(def) -> bool:
	return int(def.act_cost) > 0


## "" (no multiplier slot) | "G" | "A".
static func _axis_class(axis: String) -> String:
	if axis == "G":
		return "G"
	if axis.begins_with("A:"):
		return "A"
	return ""
