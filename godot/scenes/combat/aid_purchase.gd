class_name AidPurchase
extends RefCounted
## Buying Aid R1 (Continue) and R2 (extra reroll) in a fight. Checklist L1 B2, monetization-v1 2.2,
## l1-interfaces.md 3 (Aid) and 1.5 (the server charges inside the epoch request).
##
## Prices, caps and "is it offered" come ONLY from AidCatalog (assets/data/economy/aid_prices.json, kept
## equal to worker/src/aid_prices.js by worker/test/aid_prices_match.test.mjs).
##
## Who charges:
##  - local epoch source: this class spends the Gem through MetaState.spend("gem") (the wallet), once,
##    BEFORE the effect, and gives it back if the engine refuses.
##  - remote epoch source: the RunDO charges inside the epoch request the engine sends (continue / reroll
##    source=aid). The client must NOT spend here; it only refreshes the wallet display afterwards.
## The effect always goes through the existing engine API (continue_after_wipe / reroll_dice from_aid).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const CATALOG_ID := {"extra_reroll": "R2", "continue": "R1"}


static func is_remote() -> bool:
	return RunState.epoch != null and RunState.epoch.is_remote()


## ctx for AidCatalog.offer(), built from the live run. `tutorial` hides every paid Aid.
static func context(combat: CombatEngine, tutorial: bool = false) -> Dictionary:
	var kind := combat.kind
	return {
		"mission": combat.mission, "newcomer": MetaState.is_newcomer() or tutorial,
		"ascension": combat.ascension, "node_kind": "combat" if kind == "battle" else kind,
		"node_id": combat.node_id, "party_wiped": combat.can_continue(), "rerolls_left": combat.rerolls,
		"uses": RunState.aid_uses_view(), "boon_used": RunState.boon_used, "vip": false,
		"free_continue_left": MetaState.free_continue_left() and not tutorial, "gems": MetaState.gem_wallet().balance(),
	}


## AidCatalog.offer() for a UI id ("extra_reroll" | "continue"), plus the used / cap numbers for the panel.
static func offer(ui_id: String, combat: CombatEngine, tutorial: bool = false) -> Dictionary:
	var ctx := context(combat, tutorial)
	var o := AidCatalog.offer(String(CATALOG_ID[ui_id]), ctx)
	o["used"] = (ctx["uses"] as Array).size() + (1 if bool(ctx["boon_used"]) else 0)
	o["cap"] = total_cap(combat.ascension)
	return o


## Catalog price of `aid_id` even when it is not on offer right now (the tray shows it greyed out).
static func list_price(aid_id: String, boss: bool = false) -> int:
	var a: Dictionary = (_Econ.get_table("aid_prices").get("aids", {}) as Dictionary).get(aid_id, {})
	return int(a.get("boss_price" if boss and a.has("boss_price") else "price", 0))


static func cap_run(aid_id: String) -> int:
	return int(((_Econ.get_table("aid_prices").get("aids", {}) as Dictionary).get(aid_id, {}) as Dictionary).get("cap_run", 0))


static func total_cap(asc: int) -> int:
	var cfg: Dictionary = _Econ.get_table("aid_prices")
	var tc: Dictionary = cfg.get("total_cap", {})
	return int(tc.get("a9_a10", 4)) if asc >= int(cfg.get("total_cap_split_asc", 9)) else int(tc.get("a0_a8", 6))


## Human text for a catalog `reason` (the tray shows it instead of the cap line when disabled).
static func reason_text(reason: String) -> String:
	match reason:
		"no_gems": return "Not enough Gem"
		"cap_total": return "Aid cap for this run reached"
		"cap_type": return "Limit reached"
		"newcomer", "mission_run": return "Not available now"
		"not_now": return "Not available now"
	return reason


## Buys and applies one Aid. `uids` = dice to reroll (R2 only). Returns {ok:bool, code:String, charged:int}.
static func buy(ui_id: String, combat: CombatEngine, uids: Array = [], tutorial: bool = false) -> Dictionary:
	if not CATALOG_ID.has(ui_id):
		return {"ok": false, "code": "unknown_aid", "charged": 0}
	var aid_id := String(CATALOG_ID[ui_id])
	var o := AidCatalog.offer(aid_id, context(combat, tutorial))
	if not bool(o["show"]) or not bool(o["enabled"]):
		return {"ok": false, "code": String(o["reason"]), "charged": 0}
	if aid_id == "R2" and not combat.can_reroll(uids, true):
		return {"ok": false, "code": "illegal", "charged": 0}
	if aid_id == "R1" and not combat.can_continue():
		return {"ok": false, "code": "illegal", "charged": 0}
	var price := int(o["price"])
	var remote := is_remote()
	var spent := 0
	if not remote and price > 0:
		if not MetaState.spend("gem", price, "aid:" + aid_id):
			return {"ok": false, "code": "no_gems", "charged": 0}
		spent = price
	var done := false
	if aid_id == "R2":
		done = combat.reroll_dice(uids, -1, true)
	else:
		done = combat.continue_after_wipe(-1, -1)
	if not done:
		if spent > 0:
			MetaState.gem_wallet().grant(spent, "aid_refund")
		return {"ok": false, "code": "refused", "charged": 0}
	RunState.record_aid_use(aid_id)
	if aid_id == "R1" and price == 0:
		MetaState.use_free_continue()   # the account's one sample Continue is gone (remote: the server claimed it)
	if remote:
		var w := MetaState.gem_wallet()
		if w.has_method("refresh"):
			w.call("refresh")   # server charged inside the epoch request; update the display
	return {"ok": true, "code": "", "charged": spent}


## ---- R5: swap one boss Pact card (PactView) ----

## AidCatalog.offer("R5") for the open Pact screen, plus used/cap for the panel. Price and caps from aid_prices.json.
static func pact_swap_offer() -> Dictionary:
	var ctx := {
		"mission": not RunState.mission.is_empty(), "newcomer": MetaState.is_newcomer(),
		"ascension": RunState.ascension, "node_kind": "pact", "at_pact": RunState.phase == RunState.RunPhase.PACT,
		"node_id": RunState.current_node_id, "uses": RunState.aid_uses_view(), "boon_used": RunState.boon_used,
		"vip": false, "gems": MetaState.gem_wallet().balance(),
	}
	var o := AidCatalog.offer("R5", ctx)
	o["used"] = (ctx["uses"] as Array).size() + (1 if bool(ctx["boon_used"]) else 0)
	o["cap"] = total_cap(RunState.ascension)
	return o


## Buys and applies R5 on card `slot`. Same charging rule as buy(): local spends here (refund if refused),
## remote is charged by the RunDO inside the pact_reroll epoch request. Returns {ok, code, charged}.
static func buy_pact_swap(slot: int) -> Dictionary:
	var o := pact_swap_offer()
	if not bool(o["show"]) or not bool(o["enabled"]):
		return {"ok": false, "code": String(o["reason"]), "charged": 0}
	var price := int(o["price"])
	var remote := is_remote()
	var spent := 0
	if not remote and price > 0:
		if not MetaState.spend("gem", price, "aid:R5"):
			return {"ok": false, "code": "no_gems", "charged": 0}
		spent = price
	var r: Dictionary = await RunState.request_pact_reroll(slot)
	if not bool(r["ok"]):
		if spent > 0:
			MetaState.gem_wallet().grant(spent, "aid_refund")
		return {"ok": false, "code": String(r["code"]), "charged": 0}
	RunState.record_aid_use("R5")
	if remote:
		var w := MetaState.gem_wallet()
		if w.has_method("refresh"):
			w.call("refresh")
	return {"ok": true, "code": "", "charged": spent}
