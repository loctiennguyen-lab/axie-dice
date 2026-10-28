extends Node
## Reduce motion on the remaining sites: combat stage action/death/march, UI3.Spinner, GachaReveal flip.
## With the setting ON nothing may tween position/scale/rotation; the callbacks the game waits on still fire.
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	print("=== t_reduce_motion_rest: start ===")
	var was := MetaState.reduce_motion
	var was_juice := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	await _stage_slot_case()
	await _spinner_case()
	await _gacha_case()
	MetaState.reduce_motion = was
	CombatView.disable_juice_for_tests = was_juice
	if _fails.is_empty():
		print("t_reduce_motion_rest: PASS — %d checks OK" % _checks)
	else:
		for f in _fails:
			print("t_reduce_motion_rest: FAIL — %s" % f)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _stage_slot_case() -> void:
	var stage := (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate() as CombatStage3D
	add_child(stage)
	var slot := Node3D.new()
	stage.add_child(slot)
	slot.position = Vector3(1, 0, 2)
	var entry := {"slot": slot, "rest_pos": Vector3(1, 0, 2)}
	# Reduce ON: neither a lunge face nor a cast face leaves an action tween behind.
	MetaState.reduce_motion = true
	for face in ["dmg", "shield"]:
		stage._play_action_motion(1, entry, face, -1, "")
		_ok(entry.get("action_tween") == null, "reduced %s created an action tween" % face)
		await get_tree().create_timer(0.1).timeout
		_ok(slot.position.is_equal_approx(Vector3(1, 0, 2)) and slot.scale.is_equal_approx(Vector3.ONE), "reduced %s moved the slot" % face)
	# Reduce OFF: the lunge tween is still there.
	MetaState.reduce_motion = false
	stage._play_action_motion(1, entry, "dmg", -1, "")
	_ok(entry.get("action_tween") is Tween, "normal lunge lost its tween")
	stage._stop_action_motion(entry)
	# Death: reduced must still hide the slot, without scaling it.
	MetaState.reduce_motion = true
	slot.visible = true
	stage._start_death_fade(1, entry)
	await get_tree().create_timer(0.3).timeout
	_ok(not slot.visible, "reduced death did not hide the slot")
	_ok(slot.scale.is_equal_approx(Vector3.ONE), "reduced death scaled the slot")
	# Victory march: still resolves quickly, position untouched.
	slot.visible = true
	stage._units[7] = {"slot": slot, "rest_pos": slot.position, "character": null}
	var p0 := slot.position
	var t0 := Time.get_ticks_msec()
	await stage.play_victory_march([7], 3.0, 5.0)
	_ok(Time.get_ticks_msec() - t0 < 1500, "reduced victory march still waited its full duration")
	_ok(slot.position.is_equal_approx(p0), "reduced victory march slid the slot")
	stage.queue_free()


func _spinner_case() -> void:
	var sp := UI3.Spinner.new()
	add_child(sp)
	MetaState.reduce_motion = true
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(is_zero_approx(sp.rotation), "reduced spinner rotates")
	_ok(sp.modulate.a >= 0.3 and sp.modulate.a <= 1.0, "reduced spinner has no alpha indicator")
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(not is_zero_approx(sp.rotation), "normal spinner stopped rotating")
	sp.queue_free()


func _gacha_case() -> void:
	MetaState.reduce_motion = true
	var host := Control.new()
	add_child(host)
	var cards: Array = []
	for i in 2:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 100)
		var col := VBoxContainer.new()
		col.add_child(Label.new())
		card.add_child(col)
		host.add_child(card)
		cards.append(card)
	var r := GachaReveal.new()
	add_child(r)
	var max_dev := 0.0
	r.start(cards, 1, false, false, host)
	for _i in 240:
		await get_tree().process_frame
		for c in cards:
			max_dev = maxf(max_dev, absf((c as Control).scale.x - 1.0))
		if not r.running:
			break
	_ok(not r.running, "reduced gacha never finished")
	_ok(max_dev < 0.001, "reduced gacha flipped card scale (%f)" % max_dev)
	_ok(r.events.has("flip:0") and r.events.has("flip:1"), "reduced gacha skipped flip events")
	r.queue_free()
	host.queue_free()
