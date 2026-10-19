extends Node
## Lane U capture: WEAKEN die selected (tray + 3D die + info) and the battle log open with entries.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_combat_log_capture.tscn WxH

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	var size := Vector2i(get_window().size)
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	var u: Unit = scene._combat.alive_party()[0]
	var ri := u.roll_face_index()
	u.die[ri] = {"type": "debuff", "value": 0, "part": "eyes", "keywords": ["weaken:3"]}
	scene._rebuild_all()
	scene._selected_die_uid = u.uid
	scene._rebuild_all()
	for l in ["[input] Pomodoro weaken -> Slime", "[exec] Slime takes 4", "[exec] Pomodoro shield 3",
			"[enemy] Slime attacks Pomodoro for 3", "[turn] 2 begins", "[exec] Bug poison 2 -> Slime"]:
		scene._append_log(l)
	scene._debug_log_container.visible = true
	for _i in 15:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/lane-u-%s-%dx%d.png" % [_out, OS.get_environment("QA_TAG"), size.x, size.y])
	print("QA: saved lane-u %dx%d" % [size.x, size.y])
	_guard.restore()
	get_tree().quit(0)
