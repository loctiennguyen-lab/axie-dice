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
