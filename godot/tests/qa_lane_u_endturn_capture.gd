extends Node
## Manual capture: combat bottom-right block in the player turn and during the enemy turn
## (End turn -> "Enemy turn", speed controls). Not headless:
##   godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_lane_u_endturn_capture.tscn 1920x1080

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	var size := Vector2i(get_window().size)
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	await _shot("turn", size)
	var hud: CombatHud = scene._hud_frame
	hud.update_right({"enabled": false, "sub": ""}, {"n": 0, "max": 2, "enabled": false},
		{"sub": "E · 0 dice unused", "enabled": false, "resolving": true})
	hud.set_resolving(true)
	await _shot("enemy", size)
	_guard.restore()
	get_tree().quit(0)


func _shot(state: String, size: Vector2i) -> void:
	for _i in 10:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/lane-u-%s-%dx%d.png" % [_out, state, size.x, size.y])
