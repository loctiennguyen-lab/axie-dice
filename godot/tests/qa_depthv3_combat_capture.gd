extends Node
## Depth v3 lane D capture (run NOT headless): Hold button + held chip, reroll price, FRONT/BACK strip,
## boss rhythm card, Elite affix chip. `-- <out dir>` (default production/qa/evidence).
var _guard := SaveGuard.new()
var _out := ""

func _ready() -> void:
	_guard.capture()
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		var s: Node = await _open("elite", "r5_c0", 4, "shell")
		s._land_dice_now()
		var c: CombatEngine = s._combat
		for u in s._party_dice_units():
			if u.has_rolled():
				s._selected_die_uid = u.uid
				break
		s._rebuild_all()
		await _shot("depthv3_combat_elite_affix_select", size)
		s._on_hold_pressed()
		c.rerolls = 0
		c.mana = 3
		s._rebuild_all()
		await _shot("depthv3_combat_held_paid_reroll", size)
		s.queue_free()
		await get_tree().process_frame
		s = await _open("boss", "r6_c0", 6, "")
		await _shot("depthv3_combat_boss_rhythm", size)
		s.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)

func _open(kind: String, node_id: String, pw: int, affix: String) -> Node:
	RunState.power_level = pw
	RunState.enter_node(node_id, kind)
	if affix != "":
		RunState.pending_combat["affix"] = affix
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	return scene

func _shot(name: String, size: Vector2i) -> void:
	for _i in 90:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ", name)
