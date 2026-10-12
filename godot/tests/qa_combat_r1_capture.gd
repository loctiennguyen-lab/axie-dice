extends Node
## Lane U QA capture: the R1 combat HUD in the states the design frames show, at 1920x1080 and
## 1920x1240 (the `expand` window). Run NOT headless (it needs a renderer), through with_lock:
##   with_lock.sh Godot --path godot res://tests/qa_combat_r1_capture.tscn
## Writes PNGs (viewport texture, not a screen grab) to $ADT_EVIDENCE_DIR or production/qa/evidence/l1-U.
## HudStateStub.override fakes attrition / clock / spike until lane A's hud_state() lands.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence/l1-U").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 6, false)
	await get_tree().process_frame

	for size in [Vector2i(1920, 1080), Vector2i(1920, 1240)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		await _normal_fight(size)
		await _boss_fight(size)
	_guard.restore()
	get_tree().quit(0)


func _shot(name: String, size: Vector2i) -> void:
	for _i in 8:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved %s_%dx%d" % [name, size.x, size.y])


func _open(kind: String, node_id: String, pw: int) -> Node:
	RunState.power_level = pw
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	return scene


func _normal_fight(size: Vector2i) -> void:
	HudStateStub.override = {}
	var scene: Node = await _open("battle", "r4_c0", 3)
	await _shot("a_player_turn", size)
	# Turn 7 look: attrition +10%, a spike tab on the first enemy, a die selected, a lethal preview.
	HudStateStub.override = {"attrition": {"active": true, "start_turn": 6, "stacks": 2, "pct": 10}}
	var c: CombatEngine = scene._combat
	var e0: Unit = c.enemies[0]
	var nxt := {}
	for e in c.enemies:
		nxt[e.uid] = {"dmg": 9, "spike": e == e0, "turns_to_spike": 2, "spike_dmg": 36}
	HudStateStub.override["enemy_next"] = nxt
	for u in scene._party_dice_units():
		if u.has_rolled():
			scene._selected_die_uid = u.uid
			break
	scene._rebuild_all()
	var p: UnitPortrait = scene._portraits.get(e0.uid)
	if p != null:
		p.set_preview_damage(maxi(e0.hp - 1, 1))
	await _shot("b_selected_lethal_hover", size)
	scene._aid.set_open(true)
	await _shot("c_aid_tray", size)
	scene._aid.set_open(false)
	scene._show_defeat_panel()
	await _shot("d_defeat", size)
	scene.queue_free()
	HudStateStub.override = {}
	await get_tree().process_frame


func _boss_fight(size: Vector2i) -> void:
	var scene: Node = await _open("boss", "r12_c0", 9)
	var c: CombatEngine = scene._combat
	HudStateStub.override = {
		"attrition": {"active": true, "start_turn": 6, "stacks": 5, "pct": 25},
		"clock": {"active": true, "start_turn": 10, "turns_left": 0, "stacks": 5, "pct": 100, "max_stacks": 5, "step_pct": 20}}
	var nxt := {}
	for e in c.enemies:
		nxt[e.uid] = {"dmg": 86, "spike": false, "turns_to_spike": 0}
	HudStateStub.override["enemy_next"] = nxt
	scene._rebuild_all()
	await _shot("e_boss_enraged_max", size)
	scene.queue_free()
	HudStateStub.override = {}
	await get_tree().process_frame
