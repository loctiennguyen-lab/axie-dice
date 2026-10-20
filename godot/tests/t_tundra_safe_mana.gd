extends Node
## QA smoke v4 anomaly A1: Safe reroll under rule_tundra showed mana 4 -> 6. Proof: Tundra does not refund;
## the gain is a mana "cantrip" face (ears) resolving at roll time on the re-rolled die (_resolve_cantrips).

var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var fails := 0
	var saw_gain := 0
	for seed in range(1, 80):
		var with_t := _safe(seed, ["rule_tundra"])
		var plain := _safe(seed, [])
		# Tundra must not change the mana outcome of the same seeded Safe reroll (no refund of its own)
		if with_t != plain or with_t < 0:
			print("FAIL seed %d tundra=%d plain=%d" % [seed, with_t, plain])
			fails += 1
		# 4 - 2 = 2; anything above is mana-face cantrips resolving on the re-rolled dice
		if with_t > 2:
			saw_gain += 1
	print("t_tundra_safe_mana: cantrip-gain seeds=%d fails=%d" % [saw_gain, fails])
	if fails == 0 and saw_gain > 0:
		print("t_tundra_safe_mana: PASS")
	_guard.restore()
	get_tree().quit(0 if fails == 0 and saw_gain > 0 else 1)


## Mana left after a Safe (paid, 2 Mana) reroll of all dice from 4 Mana, free charges at 0.
func _safe(seed: int, relics: Array) -> int:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "tn", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": relics, "combat_seed": seed})
	e.rerolls = 0
	e.mana = 4
	var uids: Array = []
	for u in e.party:
		uids.append((u as Unit).uid)
	if e.reroll_mana_cost(false, 1) != 2 or not e.reroll_dice(uids, -1, false, 1):
		return -1
	return e.mana
