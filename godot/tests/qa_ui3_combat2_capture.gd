extends Node
## UI-03 combat fixes capture (lane C): inspector placement, Aid tray open / disabled rows / Coming soon, offer at 1920x1080 and 1280x720.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_combat2_capture.tscn
## Writes production/qa/evidence/ui3-combat2-<state>-<w>x<h>.png.

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
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		await _normal(size)
		await _boss(size)
	_guard.restore()
	get_tree().quit(0)


func _shot(state: String, size: Vector2i) -> void:
	for _i in 10:
		await get_tree().process_frame
	for n in get_tree().root.get_children():
		if n.has_method("_land_dice_now"):
			n.call("_land_dice_now")
	await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/ui3-combat2-%s-%dx%d.png" % [_out, state, size.x, size.y])
	print("QA: saved ui3-combat2-%s-%dx%d" % [state, size.x, size.y])


func _open(kind: String, node_id: String, pw: int) -> Node:
	RunState.power_level = pw
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	return scene


func _normal(size: Vector2i) -> void:
	MetaState.runs_with_battle = 99
	MetaState.gems_cache = 500
	var scene: Node = await _open("battle", "r4_c0", 3)
	scene._land_dice_now()
	scene._combat.rerolls = 0
	scene._rebuild_all()
	await _shot("offer", size)
	for who in ["party", "enemy"]:
		var u: Unit = scene._combat.alive_party()[0] if who == "party" else scene._combat.alive_enemies()[0]
		scene._open_unit_inspect(u.uid)
		await _shot("inspect-%s" % who, size)
		scene._close_unit_inspect()
	var last: Unit = scene._combat.alive_party().back()
	scene._open_unit_inspect(last.uid)
	await _shot("inspect-party-last", size)
	scene._close_unit_inspect()
	scene._aid.set_open(true)
	await _shot("aid-tray-open", size)
	scene._aid.set_open(false)
	MetaState.gems_cache = 0
	scene._rebuild_all()
	scene._aid.set_open(true)
	await _shot("aid-disabled-rows", size)
	scene._aid.set_open(false)
	scene.queue_free()
	await get_tree().process_frame


func _boss(size: Vector2i) -> void:
	MetaState.gems_cache = 500
	var scene: Node = await _open("boss", "r12_c0", 9)
	scene._aid.set_open(true)
	await _shot("aid-coming-soon", size)
	scene._aid.set_open(false)
	scene.queue_free()
	await get_tree().process_frame
