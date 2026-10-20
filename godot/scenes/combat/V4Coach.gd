class_name V4Coach
extends RefCounted
## Depth v4 coach lines C1-C7 (combat-v4.md 5.3): one sentence, once per account, one bubble per turn.
## "Seen" flags live in user://v4_coach_seen.json through SaveStore (never a raw file write).

const PATH := "user://v4_coach_seen.json"
const ORDER := ["C1", "C2", "C3", "C4", "C5", "C6", "C7"]
const TEXT := {
	"C1": "Every die has a part. 3 dice of the same part make a SET, and a SET is stronger.",
	"C2": "You have a pair. Reroll the other dice to find a third of the same part.",
	"C3": "The numbers on dice in a SET are multiplied.",
	"C4": "Rerolling more costs mana.",
	"C5": "Gamble: free, but each die has a chance to Crack.",
	"C6": "Wild face: 2 mana, one die counts as the part you pick.",
	"C7": "Overcast: 3 mana, +0.5 on the multiplier.",
}
const MIN_STAGE := {"C5": 2, "C6": 2, "C7": 3}

static var enabled := true         # tests switch it on explicitly (juice-off mode keeps it quiet)
static var persist := true
static var enabled_in_tests := false
static var _seen: Dictionary = {}
static var _loaded := false


static func text_for(id: String) -> String:
	return TranslationServer.translate(String(TEXT.get(id, "")))


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not persist:
		return
	var raw := SaveStore.read_text(PATH)
	if raw != "":
		var d: Variant = JSON.parse_string(raw)
		if d is Dictionary:
			_seen = d


static func seen(id: String) -> bool:
	_load()
	return bool(_seen.get(id, false))


static func mark(id: String) -> void:
	_load()
	_seen[id] = true
	if persist:
		SaveStore.write_text(PATH, JSON.stringify(_seen))


static func reset_for_tests() -> void:
	_seen = {}
	_loaded = true
	persist = false


## First unseen coach id whose condition holds. `s`: {stage, rolled, pair, bo, free_left, payable, mana, reroll_cost, wild_cost, oc_cost}.
static func next_id(s: Dictionary) -> String:
	for id in ORDER:
		if seen(id) or int(s.get("stage", 3)) < int(MIN_STAGE.get(id, 1)):
			continue
		match id:
			"C1":
				if bool(s.get("rolled", false)):
					return id
			"C2":
				if bool(s.get("pair", false)) and not bool(s.get("bo", false)):
					return id
			"C3":
				if bool(s.get("bo", false)):
					return id
			"C4", "C5":
				if int(s.get("free_left", 1)) <= 0 and bool(s.get("payable", false)) and int(s.get("mana", 0)) >= int(s.get("reroll_cost", 2)):
					return id
			"C6":
				if bool(s.get("pair", false)) and int(s.get("mana", 0)) >= int(s.get("wild_cost", 2)):
					return id
			"C7":
				if int(s.get("mana", 0)) >= int(s.get("oc_cost", 3)):
					return id
	return ""
