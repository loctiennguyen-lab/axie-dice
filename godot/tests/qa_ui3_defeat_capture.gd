extends Node
## UI-03 defeat panel capture (screen 30): paid, free, short of Gem, mission, boss with phase ticks, reviving.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_defeat_capture.tscn
## Writes production/qa/evidence/ui3-defeat-<state>-<w>x<h>.png. Real saves are restored by SaveGuard.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		await _state("paid", size, "battle", "r4_c0", 6, 20, 500, false, false)
		await _state("short", size, "battle", "r4_c0", 6, 20, 30, false, false)
		await _state("free", size, "boss", "r12_c0", 0, 0, 0, false, false)
		await _state("boss", size, "boss", "r12_c0", 6, 20, 500, false, false)
		await _state("mission", size, "battle", "r4_c0", 6, 20, 500, true, false)
		await _state("reviving", size, "boss", "r12_c0", 6, 20, 500, false, true)
	_guard.restore()
	get_tree().quit(0)


func _state(state: String, size: Vector2i, kind: String, node_id: String, asc: int, battles: int,
		gems: int, mission: bool, busy: bool) -> void:
	MetaState.runs_with_battle = battles
	MetaState.free_continue_used = false
	MetaState.gems_cache = gems
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", asc, false)
	await get_tree().process_frame
	RunState.power_level = 9 if kind == "boss" else 3
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	var combat: CombatEngine = scene._combat
	combat.lost = true
	combat.mission = mission
	for e in combat.enemies:
		if e.is_boss:
			e.hp = int(e.max_hp * 0.5)
	scene._show_defeat_panel()
	if busy:
		scene._defeat.set_busy(true)
	for _i in 10:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/ui3-defeat-%s-%dx%d.png" % [_out, state, size.x, size.y])
	print("QA: saved ui3-defeat-%s-%dx%d" % [state, size.x, size.y])
	scene.queue_free()
	await get_tree().process_frame
