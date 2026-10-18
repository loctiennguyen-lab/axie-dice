extends Node
## Repeated starter Axies in a party: a run starts, saves/loads through JSON, and combat gives each
## copy its own uid. Vault Axies still swap places in the Run Setup picker.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "plant1", "beast1", "beast1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	RunState.reset()
	RunState.start_new_run(777, TEAM, "short", 0, false)
	var keys: Array[String] = []
	var pids := {}
	for e in RunState.roster:
		keys.append(String(e["hero_key"]))
		pids[int(e["persistent_id"])] = true
	_check(keys == TEAM and pids.size() == 5, "run keeps the repeated party with distinct persistent ids")
	var data := JSON.parse_string(JSON.stringify(RunState.to_data())) as Dictionary
	RunState.reset()
	RunState.from_data(data)
	var back: Array[String] = []
	var pids2 := {}
	for e in RunState.roster:
		back.append(String(e["hero_key"]))
		pids2[int(e["persistent_id"])] = true
	_check(back == TEAM and pids2.size() == 5, "save/load round trip keeps the repeats and ids")

	var eng := CombatEngine.new()
	eng.setup_new({"node_id": "n", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [], "combat_seed": 5})
	var uids := {}
	for u in eng.party:
		uids[u.uid] = true
	_check(eng.party.size() == 5 and uids.size() == 5, "combat units have distinct uids")

	# Run Setup: Vault Axie still swaps places, starter copies.
	ContentDB.heroes["vault_rep1"] = (ContentDB.heroes["plant1"] as Dictionary).duplicate(true)
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.no_scene_change = true
	s.use_account = false
	add_child(s)
	await get_tree().process_frame
	s.party = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	_check(s.set_slot(0, "vault_rep1"), "vault Axie seated")
	_check(s.swap_into_slot(3, "vault_rep1") and s.party[3] == "vault_rep1" and s.party[0] == "reptile1",
		"a Vault Axie still swaps places")
	_check(s.party.count("vault_rep1") == 1, "vault Axie stays once")
	ContentDB.heroes.erase("vault_rep1")
	s.queue_free()

	_guard.restore()
	if _fails.is_empty():
		print("t_party_repeat: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_party_repeat: FAIL - " + f)
		get_tree().quit(1)
