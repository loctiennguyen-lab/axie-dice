extends Node
## One-off capture: the main menu with its two teaching entry points, then every coached step
## of the tutorial, on the real combat screen it now runs on.
##
## t_tutorial_flow.gd proves the steps LOCK. Only a picture shows whether what a new player
## actually sees is a game teaching them something or a wall of instructions — and with the
## coach now cutting a hole in a dimmed production screen, "is the right thing lit, and is the
## card next to it rather than on top of it" is a question only a render can answer.
##
## Run: xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot \
##        --rendering-driver opengl3 --resolution 1920x1080 res://tests/qa_tutorial_capture.tscn

var _guard := SaveGuard.new()
var _tut: Node = null


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame

	var menu: Node = (load("res://scenes/main_menu/MainMenu.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(menu)
	await _settle(30)
	_shoot("menu")
	menu.queue_free()
	await _settle(2)

	_tut = (load("res://scenes/tutorial/Tutorial.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(_tut)
	await _settle(60)
	_shoot("01-welcome")

	# Drive the flow the way a player would: press the coach's own button, click the die the
	# coach lit, click the enemy it lit. Going through the real handlers (rather than poking
	# _manual_step) is what makes the capture evidence of the flow and not just of the art.
	await _advance("02-party")            # WELCOME -> PARTY
	await _advance("03-intent")           # PARTY   -> INTENT
	await _advance("04-reroll")           # INTENT  -> REROLL

	_view().call("_on_reroll_pressed")
	await _settle(45)
	_shoot("05-pick-die")

	var slot := int(_tut.call("_slot_of", _tut.call("_teaching_actor")))
	_view().call("_on_die_slot_pressed", slot)
	await _settle(20)
	_shoot("06-pick-target")

	var target: Unit = _tut.call("_teaching_target", _tut.call("_teaching_actor"))
	if target != null:
		_view().call("_on_target_clicked", target.uid)
	await _settle(75)
	_shoot("07-end-turn")

	_view().call("_on_end_turn_pressed")
	await _settle(150)
	_shoot("08-free-play")

	# The two end screens, reached by hand: winning the fight for real from here would take a
	# variable number of turns and this capture is about the chrome, not about the rules.
	_tut.set("_outcome", 1)
	_tut.call("_render", false)
	await _settle(20)
	_shoot("09-reward")

	_tut.call("_on_reward_pressed", 0)
	await _settle(20)
	_shoot("10-done")

	_guard.restore()
	print("qa_tutorial_capture: done")
	get_tree().quit(0)


## Presses the coach's card button and shoots whatever step that lands on.
func _advance(tag: String) -> void:
	_tut.call("_on_cta_pressed")
	await _settle(25)
	_shoot(tag)


func _view() -> Node:
	return _tut.get("_view") as Node


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame


func _shoot(tag: String) -> void:
	var path := QaPaths.evidence_dir() + "/%s_tutorial-%s.png" % [_today(), tag]
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
