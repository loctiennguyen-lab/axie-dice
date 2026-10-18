extends Node
## QA capture: status icons above heads, reroll mid-air, reroll result with MAX tag + chips. NOT headless.
## godot/tools/shot.sh res://tests/qa_combat_status_capture.tscn 1920x1080 -> $ADT_EVIDENCE_DIR/ui3-combat-*.png
var _guard := SaveGuard.new()
var _tag := "1920"


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	img.save_png("%s/ui3-combat-%s-%s.png" % [out, name, _tag])
	print("QA: saved ui3-combat-%s-%s" % [name, _tag])


func _wait(sec: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(sec * 1000.0):
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	_tag = str(get_window().size.x)
	CombatView.disable_juice_for_tests = false
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 6, false)
	await get_tree().process_frame
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(view)
	await _wait(5.5)
	var combat: CombatEngine = view._combat
	var units: Array = view._party_dice_units()
	units[0].shield = 6
	units[0].status["thorns"] = 2
	units[1].status["poison"] = 3
	units[1].status["regen"] = 2
	units[2].status["weaken"] = 1
	units[3].shield = 4
	units[3].status["undying"] = 1
	units[3].status["burn"] = 2
	units[3].status["stun"] = 1
	units[3].status["blind"] = 1
	for i in combat.enemies.size():
		var e: Unit = combat.enemies[i]
		e.shield = 5 if i == 0 else 0
		e.status["poison"] = 4
		e.status["vulnerable"] = 2
		e.status["thorns"] = 1
	view._rebuild_all()
	await _wait(0.6)
	await _shot("statuses")
	# a die whose every face is its max: the reroll always shows the MAX tag
	var u: Unit = units[2]
	for k in u.die.size():
		u.die[k] = {"type": "dmg", "value": 6, "keywords": []}
	combat.rerolls = 3
	view._on_reroll_pressed()
	await _wait(0.7)
	await _shot("reroll-air")
	var t0 := Time.get_ticks_msec()
	while (not is_instance_valid(view._reroll_tags) or view._reroll_tags.get_child_count() < 2) \
			and Time.get_ticks_msec() - t0 < 6000:
		await get_tree().process_frame
	await _wait(0.45)
	await _shot("reroll-after")
	_guard.restore()
	get_tree().quit(0)
