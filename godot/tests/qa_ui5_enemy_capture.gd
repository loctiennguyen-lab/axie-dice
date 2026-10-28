extends Node
## UI-05 b1 lane C capture: the enemy column states of design/handoffs/ui-05-figma/round-1/ui05-combat-screens.html
## (02-combat--boss, --bighit, --attrition-upcoming / -active / -max, --ab-names), at 1920x1080 and 1280x720.
## Not headless: godot/tools/shot.sh res://tests/qa_ui5_enemy_capture.tscn
## Writes production/qa/ui05-b1/c/<frame id>[--1280].png (the HTML frame ids). A real fight is opened; the states the
## seed does not give (big hit, attrition, repeated names) are pushed onto the plates / HUD right before the shot.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/c").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		# Pin the design scale: on a Retina Mac current_scale() divides by the screen DPR (2), so a 1920 px window
		# reads as 0.5 and every text token jumps to the 14 px floor. The frames are 1.0 / 0.667.
		UI3Theme.set_scale_override(1.0 if size.x == 1920 else 2.0 / 3.0)
		for _i in 8:
			await get_tree().process_frame
		await _normal(size)
		await _boss(size)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _shot(frame_id: String, size: Vector2i) -> void:
	for _i in 12:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	var f := "%s/%s%s.png" % [_out, frame_id, "--1280" if size.x == 1280 else ""]
	img.save_png(f)
	print("QA: saved ", f)


func _open(kind: String, node_id: String, pw: int) -> Node:
	RunState.power_level = pw
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	return scene


func _plates(scene: Node) -> Array:
	var out: Array = []
	for e in scene._combat.enemies:
		var p: UnitPortrait = scene._portraits.get(e.uid)
		if p != null and p.visible:
			out.append(p)
	return out


func _normal(size: Vector2i) -> void:
	var scene: Node = await _open("battle", "r4_c0", 3)
	var ps := _plates(scene)
	# bighit: the last enemy's intent can knock out an Axie.
	if ps.size() > 0:
		(ps.back() as UnitPortrait).set_intent({"show": true, "type": "dmg", "num": 18, "label": "ATTACK",
			"target": "Olek", "big_hit": true})
	await _shot("02-combat--bighit", size)
	scene._rebuild_all()
	# attrition, 3 states (the HUD card the column places last).
	var states := [["upcoming", {"start_turn": 6, "pct": 0}, 4], ["active", {"start_turn": 6, "pct": 10}, 7],
		["max", {"start_turn": 6, "pct": 25}, 12]]
	for st in states:
		scene._hud_frame.update_attrition(st[1], st[2], false)
		await _shot("02-combat--attrition-%s" % st[0], size)
	scene._hud_frame.update_attrition({"start_turn": 6, "pct": 0}, 1, false)
	# ab-names: two plates with the same name.
	var i := 0
	for p in ps:
		(p as UnitPortrait).set_nick("", "Ravenling %s" % char(65 + i))
		i += 1
	await _shot("02-combat--ab-names", size)
	scene.queue_free()
	await get_tree().process_frame


func _boss(size: Vector2i) -> void:
	var scene: Node = await _open("boss", "r12_c0", 9)
	await _shot("02-combat--boss", size)
	scene.queue_free()
	await get_tree().process_frame
