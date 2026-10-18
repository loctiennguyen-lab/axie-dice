extends Node
## UI-03 17/37/38: the coach on UI3. Starter plate shows the entries and Esc = Go to the Land; Skip asks first.

var _fails := 0
var _cta := 0
var _skips := 0


func _ok(c: bool, what: String) -> void:
	if not c:
		_fails += 1
		print("  FAIL: ", what)


func _ready() -> void:
	await get_tree().process_frame
	var coach := TutorialCoach.new()
	add_child(coach)
	coach.cta_pressed.connect(func() -> void: _cta += 1)
	coach.skip_pressed.connect(func() -> void: _skips += 1)
	await get_tree().process_frame
	coach.show_curtain("Welcome", "One sentence.", "Start")
	await get_tree().process_frame
	var skip := coach.find_child("SkipConfirm", true, false)
	_ok(skip == null, "no confirm before Skip is pressed")
	coach.call("_ask_skip")
	await get_tree().process_frame
	_ok(coach.find_child("SkipConfirm", true, false) != null, "Skip opens the confirm modal")
	_ok(_skips == 0, "Skip does not emit before the confirm")
	coach.find_child("SkipConfirm", true, false).queue_free()
	await get_tree().process_frame
	coach.show_starter("Ready", "Waiting in the Land.", [
		{"value": "500", "label": "Shards", "sub": "Not stakeable"},
		{"value": "3", "label": "Tickets", "sub": ""}], "Go to the Land")
	await get_tree().process_frame
	var plate := coach.find_child("StarterPlate", true, false) as Control
	_ok(plate != null and plate.visible and plate.custom_minimum_size.x == 560.0, "starter plate 560 wide")
	_ok((plate.find_children("*", "GridContainer", true, false)[0] as GridContainer).get_child_count() == 2, "two starter cells")
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_cta == 1, "Esc on the starter plate = Go to the Land")
	print("t_tutorial_coach_ui: %s" % ("PASS" if _fails == 0 else "FAIL"))
	get_tree().quit(0 if _fails == 0 else 1)
