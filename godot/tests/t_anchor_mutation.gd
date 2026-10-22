extends Node
## Lane AU2 job 3: MUTATION strip under the PAIR banner (text from houses.json), in-combat banner once per fight,
## then at most one float per house per turn.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	UI3Gacha.instant_override = 1
	var m := AnchorAdapter.mutation_of("h_volley")
	_check(String(m["name"]) == "Spiked Shield" and String(m["rule"]) != "", "mutation text comes from houses.json: %s" % str(m))
	var host := Control.new()
	add_child(host)
	var ban := GachaFx.banner(host, "pair", "Shield Engine", ["c_sonic_shield", "c_thorn_shield"], {"house": "h_volley"})
	_check(ban.find_child("MutationStrip", true, false) != null, "strip present")
	_check((ban.find_child("MutationName", true, false) as Label).text == "Spiked Shield", "strip shows the mutation name")
	_check((ban.find_child("MutationTag", true, false) as Label).text == "MUTATION", "pair says MUTATION")
	var ban2 := GachaFx.banner(host, "full", "Shield Engine", ["c_sonic_shield", "c_thorn_shield", "c_living_wall"], {"house": "h_volley"})
	_check((ban2.find_child("MutationTag", true, false) as Label).text.contains("LEVEL 2"), "full says LEVEL 2 in words")
	var ban3 := GachaFx.banner(host, "pair", "X", ["c_sonic_shield", "c_thorn_shield"])
	_check(ban3.find_child("MutationStrip", true, false) == null, "no mutation: no strip")
	_check(UI3Gacha.timing().has("banner_pair_mutation_sec") and float(UI3Gacha.timing()["banner_pair_mutation_sec"]) == 2.0, "pair with strip lasts 2.0 s (knob)")
	# every combo belongs to a house with a mutation
	for c in CoreCombos.all():
		var h := AnchorAdapter.house_of_combo(String((c as Dictionary).get("id", "")))
		_check(h != "" and String(AnchorAdapter.mutation_of(h)["name"]) != "", "combo %s has a mutation" % str((c as Dictionary).get("id", "")))
	UI3Gacha.instant_override = -1
	# combat
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	var uid: int = v._combat.party[0].uid
	EventBus.core_fired.emit("h_volley", uid, 2, "mutation")
	_check(v.mutation_log.size() == 1 and v.mutation_log[0]["mode"] == "banner", "first mutation fire: banner")
	EventBus.core_fired.emit("h_volley", uid, 2, "mutation")
	_check(v.mutation_log.size() == 2 and v.mutation_log[1]["mode"] == "float", "second: float")
	EventBus.core_fired.emit("h_volley", uid, 2, "mutation")
	_check(v.mutation_log.size() == 2, "third in the same turn: nothing (one float per turn)")
	v._combat.turn += 1
	EventBus.core_fired.emit("h_volley", uid, 2, "mutation")
	_check(v.mutation_log.size() == 3 and v.mutation_log[2]["mode"] == "float", "next turn: one float again")
	EventBus.core_fired.emit("h_gambler", uid, 1, "mutation")
	_check(v.mutation_log.size() == 4 and v.mutation_log[3]["mode"] == "banner", "another house: its own first banner")
	v.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_anchor_mutation: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_anchor_mutation: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
