extends Node
## Lane AU2 job 4: the awakening moment plays exactly once per run, queues with the PAIR line (no second banner),
## can be skipped (click / Space / Esc), honours Reduce flashing, and never leaves a node behind.
var _guard := SaveGuard.new()
var _checks := 0
var _tree: SceneTree = null
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await _tree.process_frame


func _ready() -> void:
	_tree = get_tree()
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": []}
	AnchorFx.pending = ""
	AnchorFx.played_run = ""
	AnchorFx.log.clear()
	# 1 once per run
	AnchorFx.arm("a_volley")
	_check(AnchorFx.take_pending(), "first arm plays")
	AnchorFx.arm("a_volley")
	_check(not AnchorFx.take_pending(), "second arm in the same run does not play")
	AnchorFx.played_run = ""
	# 2 instant: content built, no node left, no input block
	UI3Gacha.instant_override = 1
	var host := Control.new()
	add_child(host)
	var fx := AnchorFx.play(host, "a_volley", "PAIR: Shield Engine . MUTATION: Spiked Shield")
	_check((fx.find_child("AwakenName", true, false) as Label).text == AnchorAdapter.awaken_name("a_volley"), "shows the awaken name")
	_check((fx.find_child("AwakenStrip", true, false) as Label).text.contains("Shield Engine"), "PAIR line merged in")
	await _frames(2)
	_check(not is_instance_valid(fx), "instant: node freed")
	# 2b the three newer awakenings show their own name + rule, and each has its own combat float line
	for aid in ["a_kin", "a_embers", "a_big_hand"]:
		var fx2 := AnchorFx.play(host, aid)
		_check((fx2.find_child("AwakenName", true, false) as Label).text == AnchorAdapter.awaken_name(aid) and AnchorAdapter.awaken_name(aid) != "", "%s awaken name" % aid)
		_check((fx2.find_child("AwakenRule", true, false) as Label).text == AnchorAdapter.awaken_rule(aid), "%s awaken rule" % aid)
		_check(fx2.find_child("HouseGlyph", true, false) != null, "%s house glyph" % aid)
	_check(AnchorFx.awaken_line("a_kin", 3).contains("Unison") and AnchorFx.awaken_line("a_kin", 3).contains("3"), "Unison line carries the count")
	_check(AnchorFx.awaken_line("a_embers", 2).contains("Passed Flame") and AnchorFx.awaken_line("a_embers", 2).contains("free"), "Passed Flame line says free")
	_check(AnchorFx.awaken_line("a_big_hand", 1).contains("Sixth Hand") and AnchorFx.awaken_line("a_big_hand", 1).contains("bonus"), "Sixth Hand line says bonus die")
	await _frames(2)
	# 3 animated: skip by click / Space / Esc
	UI3Gacha.instant_override = 0
	CombatView.disable_juice_for_tests = false
	for k in [-1, KEY_SPACE, KEY_ESCAPE]:
		var f := AnchorFx.play(host, "a_volley")
		await _frames(2)
		_check(f.running, "running before skip (%d)" % k)
		var ev: InputEvent
		if k == -1:
			var mb := InputEventMouseButton.new()
			mb.pressed = true
			mb.button_index = MOUSE_BUTTON_LEFT
			ev = mb
		else:
			var kk := InputEventKey.new()
			kk.pressed = true
			kk.keycode = k
			ev = kk
		f._input(ev)
		_check(not f.running and f.skipped, "input %d jumps to the end" % k)
		await _frames(2)
		_check(not is_instance_valid(f), "skipped moment freed (%d)" % k)
	# 4 timing: normal vs Reduce flashing
	var t_full := AnchorFx.duration()
	MetaState.reduce_flash = true
	var t_red := AnchorFx.duration()
	_check(t_full <= 2.5 and t_red <= 1.6 and t_red < t_full, "2.5 s / 1.6 s with Reduce flashing (%f, %f)" % [t_full, t_red])
	var fr := AnchorFx.play(host, "a_volley")
	await _frames(2)
	_check(fr._card.get_node("AwakenName").modulate.a < 1.0 and fr._rays.get_parent() == fr and fr._rays_static, "reduced: runs (fades only, rays static)")
	fr.skip()
	MetaState.reduce_flash = false
	await _frames(2)
	_check(host.get_child_count() == 0, "no node stuck in the host (%d)" % host.get_child_count())
	# 5 map queue: awaken + pick on the same beat = one moment, no banner
	CombatView.disable_juice_for_tests = true
	UI3Gacha.instant_override = -1
	AnchorFx.played_run = ""
	AnchorAdapter.test_state = null
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	rm._select_reward(1)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(8)
	var line: String = rm._awaken_extra_line([{"id": String(CoreCombos.all()[0]["id"]), "tier": "pair"}])
	_check(line.begins_with("PAIR: ") and line.contains("MUTATION"), "extra line = PAIR + MUTATION: %s" % line)
	AnchorFx.arm("a_volley")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true}
	var logn := AnchorFx.log.size()
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(12)
	var plays := 0
	for e in AnchorFx.log.slice(logn):
		if e == "play":
			plays += 1
	_check(plays == 1, "pick with a pending awakening plays one moment (%d)" % plays)
	_check(not rm.gacha_log.has("banner:pair"), "no PAIR banner on top of the moment")
	_check(RunState.pending_rewards.is_empty(), "map goes on after the moment")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true}
	AnchorFx.arm("a_volley")
	_check(not AnchorFx.take_pending(), "same run: never plays twice")
	rm.free()   # the map listens to node_entered and would change scene away from this test
	# 6 in combat: signal -> one moment; kind awaken -> gold mark on the Anchor tile
	CombatView.disable_juice_for_tests = true
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": false}
	AnchorFx.played_run = ""
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(60)
	AnchorAdapter.test_state["awakened"] = true
	v._on_anchor_awakened("a_volley")
	v._on_anchor_awakened("a_volley")
	_check(v.awaken_log.size() == 1, "combat: one moment even if the signal repeats (%d)" % v.awaken_log.size())
	var cp = v._hud_frame.core_panel if v._hud_frame != null else null
	if cp != null and cp.anchor_slot != null:
		EventBus.core_fired.emit("a_volley", v._combat.party[0].uid, 1, "awaken")
		_check(cp.awaken_marks == 1, "awaken fire marks the Anchor tile")
		_check(String((cp.anchor_slot.find_child("AnchorBadge", true, false) as Label).text).begins_with("x"), "badge shows the x count once Awakened")
	# 7 tray marks: Embers carried die (EMBER / FREE) and a phantom bonus die (BONUS)
	var cb = v._combat
	var u0: Unit = cb.party[0]
	cb.anchor_id = "a_embers"
	u0.stash_carry = true
	cb.anchor_awakened = false
	v._update_dice_tray()
	var ch = v._die_slot_content[0].get("anchor_chip", null)
	_check(ch != null and ch.visible and ch.get_meta("chip_text").begins_with("EMBER +%s" % String.num(float(cb.anchor_embers_real100(u0)) / 100.0, 2).rstrip("0").rstrip(".")), "carried Embers die shows EMBER")
	cb.anchor_awakened = true
	v._update_dice_tray()
	_check(v._die_slot_content[0]["anchor_chip"].get_meta("chip_text").begins_with("FREE"), "Passed Flame ready: FREE")
	u0.stash_carry = false
	v._update_dice_tray()
	_check(not v._die_slot_content[0]["anchor_chip"].visible, "no carry: mark hidden")
	u0.custom_state["phantom"] = true
	v._update_dice_tray()
	_check(v._die_slot_content[0]["anchor_chip"].get_meta("chip_text") == "BONUS", "phantom die shows BONUS")
	u0.custom_state.erase("phantom")
	AnchorAdapter.test_state = null
	v.queue_free()
	_guard.restore()
	CombatView.disable_juice_for_tests = false
	print("=== t_anchor_awaken_ui: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("t_anchor_awaken_ui: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_anchor_awaken_ui: PASS")
	_tree.quit(0 if _fails.is_empty() else 1)
