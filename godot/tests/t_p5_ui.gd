extends Node
## p5-ui lane (4/11 polish leftovers): text floor measured on the real screens, event wording, ...
const Scan := preload("res://tests/p5_text_scan.gd")
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _scan(root: Node, tag: String) -> void:
	var sc := UI3Theme.layout_scale()
	var bad := Scan.small(root, sc)
	for b in bad:
		print("SMALL ", tag, " ", b)
	_ok(bad.is_empty(), "%s: all text >= 14 real px (%d small, first %s)" % [tag, bad.size(), str(bad.slice(0, 2))])


func _fake_cards(core: bool) -> Array:
	var out: Array = []
	for i in 3:
		var d := {"t": "relic", "key": "x%d" % i, "rar": 0, "title": "CORE" if core else "RELIC", "desc": "Name %d" % i, "sub": "Does thing %d." % i}
		if core:
			d.merge({"core": true, "axis": ["stat", "dice", "pos"][i], "tier": i, "slot": i})
		out.append(d)
	return out


func _ready() -> void:
	print("=== t_p5_ui: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	CombatView.disable_juice_for_tests = true
	UI3Theme.set_scale_override(2.0 / 3.0)
	# Event wording: no "Row 0", no "relic" for the player
	_ok(RunMapEvent.event_subtitle(0) == "Event" and RunMapEvent.event_subtitle(-1) == "Event", "event: row 0 / -1 reads 'Event'")
	_ok(RunMapEvent.event_subtitle(3) == "Event · Row 3", "event: row 3 keeps its row")
	_ok(RunMapEvent.core_words("Receive a Legendary relic. Lose a random relic.") == "Receive a Legendary Core. Lose a random Core.", "event: relic -> Core")
	_ok(RunMapEvent.core_words("Relics RELIC") == "Cores CORE" and RunMapEvent.core_words("relicary") == "relicary", "event: case kept, whole words only")
	# Login
	var lg: Node = load("res://scenes/login/LoginScreen.tscn").instantiate()
	add_child(lg)
	await _frames(8)
	_scan(lg, "login")
	lg.queue_free()
	await _frames(2)
	# Core offer (real) at 1280
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	rm._select_reward(1)
	rm._take_selected_reward()
	await _frames(8)
	rm._show_reward_overlay("x")
	await _frames(4)
	_scan(rm._overlay_root, "core offer")
	rm.queue_free()
	await _frames(2)
	# Combat
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": ["c_bastion"], "awakened": false}
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	RunState.pending_combat = {"node_id": "p5", "kind": "battle", "pw": 4, "ascension": 0, "roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [], "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	await _frames(10)
	_scan(view, "combat")
	for t in ["CorePanel", "AnchorTray", "AnchorChip"]:
		for n in view.find_children("*" + t + "*", "", true, false):
			print("NODE ", n.get_path())
	view.queue_free()
	AnchorAdapter.test_state = {}
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	print("=== t_p5_ui: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_p5_ui: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)
