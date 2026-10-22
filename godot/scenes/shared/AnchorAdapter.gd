class_name AnchorAdapter
extends RefCounted
## Lane AU2: the ONE place the UI reads the Anchor API (Anchors data + RunState step 2a from lane AE).
## Every RunState / EventBus name goes through has_method / get() so the UI still loads before lane AE merges.
## No Anchor or awaken logic lives here: lookups and display text only.

## Test hook: non-null replaces the RunState reads. Keys: open(bool), offer(Array), reasons({id: String}), awakened(bool),
## anchor_id(String), picked(Array: pick_anchor ids are appended here).
static var test_state = null

const HOUSE_ICON := {"h_volley": "face_shield", "h_gambler": "node_event", "h_mana_mine": "face_mana",
	"h_kin": "face_heal", "h_embers": "face_dmg", "h_big_hand": "face_summon"}
const HOUSE_TOKEN := {"h_volley": "house_volley", "h_gambler": "house_gambler", "h_mana_mine": "house_mana_mine",
	"h_kin": "house_kin", "h_embers": "house_embers", "h_big_hand": "house_big_hand"}


static func _t() -> Dictionary:
	return test_state if test_state is Dictionary else {}


## True while the run waits for an Anchor pick (stage >= 3, before the first Core offer).
static func offer_open() -> bool:
	if test_state != null:
		return bool(_t().get("open", false))
	return RunState.has_method("anchor_offer_open") and bool(RunState.call("anchor_offer_open"))


## The 3 offered Anchor ids ([] when none).
static func offer() -> Array:
	var raw = _t().get("offer", []) if test_state != null else RunState.get("anchor_offer")
	var out: Array = []
	if raw is Array:
		for id in raw:
			if not Anchors.get_def(String(id)).is_empty():
				out.append(String(id))
	return out


## "" when `id` can be picked, else a short reason (G6).
static func disabled_reason(id: String) -> String:
	if test_state != null:
		return String((_t().get("reasons", {}) as Dictionary).get(id, ""))
	if RunState.has_method("anchor_disabled_reason"):
		return String(RunState.call("anchor_disabled_reason", id))
	return ""


static func reason_text(code: String) -> String:
	if code == "rule_too_few_house_cores":
		return TranslationServer.translate("Your Run Rule leaves too few House Cores for this Anchor.")
	if code == "stage_locked":
		return TranslationServer.translate("Unlocks at stage 3 (needs Overcast).")
	return TranslationServer.translate("Not available this run.")


## Locks the pick through the engine. False when refused or the API does not exist yet.
static func pick(id: String) -> bool:
	if test_state != null:
		(_t().get("picked", []) as Array).append(id)
		return true
	return RunState.has_method("pick_anchor") and bool(RunState.call("pick_anchor", id))


static func current_id() -> String:
	if test_state != null:
		return String(_t().get("anchor_id", ""))
	var v = RunState.get("anchor_id")
	return String(v) if v != null else ""


static func name_of(id: String) -> String:
	return String(Anchors.get_def(id).get("name_en", id))


static func house_id(id: String) -> String:
	return String(Anchors.get_def(id).get("house_id", ""))


static func house_name(house: String) -> String:
	return String(Anchors.get_house(house).get("name_en", house))


static func house_icon(house: String) -> String:
	return String(HOUSE_ICON.get(house, "ui_mooncard"))


static func house_color(house: String) -> Color:
	return UI3Theme.color(String(HOUSE_TOKEN.get(house, "text_muted")))


## Player-facing one-liners from data (never hand-written).
static func rule_text(id: String) -> String:
	return UI3.player_text(String(Anchors.get_def(id).get("rule_en", "")))


static func price_text(id: String) -> String:
	return UI3.player_text(String(Anchors.get_def(id).get("cost_en", "")))


static func awaken_name(id: String) -> String:
	return String((Anchors.get_def(id).get("awaken", {}) as Dictionary).get("name_en", ""))


static func awaken_rule(id: String) -> String:
	return UI3.player_text(String((Anchors.get_def(id).get("awaken", {}) as Dictionary).get("rule_en", "")))


static func house_cores(id: String) -> Array:
	return (Anchors.get_def(id).get("house_cores", []) as Array).duplicate()


## ---- HUD / moment reads (job 2-5). Test hook extra keys: owned(Array), mutation_tiers({house: int}).

static func has_anchor() -> bool:
	return current_id() != ""


## Core ids that count toward houses (finished quest Cores included).
static func owned() -> Array:
	if test_state != null:
		return (_t().get("owned", []) as Array)
	return UI3Gacha.owned_ids()


## Latched by the engine, never turns off in a run. Falls back to the live count only when the engine has no flag yet.
static func awakened() -> bool:
	if test_state != null:
		return bool(_t().get("awakened", false))
	var v = RunState.get("anchor_awakened")
	if v != null:
		return bool(v)
	return false


static func house_count() -> int:
	var id := current_id()
	return Anchors.house_count(owned(), id) if id != "" else 0


static func is_house_core(core_id: String) -> bool:
	var id := current_id()
	return id != "" and (Anchors.get_def(id).get("house_cores", []) as Array).has(core_id)


## True when taking `core_id` takes the Anchor from 1/2 to 2/2 (awaken). Never says anything about the next pick tier.
static func would_awaken(core_id: String) -> bool:
	if not has_anchor() or awakened() or not is_house_core(core_id):
		return false
	var own := owned()
	return not own.has(core_id) and Anchors.house_count(own, current_id()) == Anchors.AWAKEN_NEED - 1


## Mutation of a house: {name, rule, rule2}; from houses.json only.
static func mutation_of(house: String) -> Dictionary:
	var m: Dictionary = Anchors.get_house(house).get("mutation", {}) as Dictionary
	return {"name": String(m.get("name_en", "")),
		"rule": UI3.player_text(String((m.get("tier1", {}) as Dictionary).get("rule_en", ""))),
		"rule2": UI3.player_text(String((m.get("tier2", {}) as Dictionary).get("rule_en", "")))}


static func house_of_combo(combo_id: String) -> String:
	return Anchors.house_of_combo(combo_id)


## Connects an EventBus signal when the engine already has it; false (and nothing connected) otherwise.
static func listen(sig: String, cb: Callable) -> bool:
	if not EventBus.has_signal(sig):
		return false
	if not EventBus.is_connected(sig, cb):
		EventBus.connect(sig, cb)
	return true
