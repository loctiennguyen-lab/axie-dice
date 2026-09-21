extends Node
## Manual VISUAL QA for the two reports: a relic active the player can actually press, and a
## summoned Axie Egg with a die card of its own.
## Run: xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot \
##        --rendering-driver opengl3 --resolution 1920x1080 res://tests/qa_actives_token_capture.tscn
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()
var _view: Node2D
var _combat: CombatEngine


func _ready() -> void:
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	_guard.capture()
	RunState.pending_combat = {
		"node_id": "qa_act", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 4242,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	for _i in 4:
		await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine

	# Two affordable actives in the rack, one of each targeting shape.
	var ids: Array = []
	for raw in RelicRegistry.all_defs_sorted():
		var d: RelicDef = raw
		if int(d.act_cost) > 0 and int(d.act_cost) <= 6 and ids.size() < 3:
			ids.append(String(d.id))
	_combat.relic_ids = ids
	_combat.mana = 20
	_view.call("_rebuild_all")
	await tree.create_timer(0.5).timeout
	_shot("actives_idle")

	# Arm a targeted one: the tile turns PRIMARY and only its legal side lights up.
	for rid in ids:
		var d2: RelicDef = RelicRegistry.get_def(rid)
		if d2 != null and d2.act_target() == "enemy":
			_view.call("_on_active_pressed", rid)
			break
	await tree.create_timer(0.5).timeout
	_shot("actives_armed")

	# And the egg.
	var token: Unit = _combat._mk_ally()
	_combat._roll_unit(token)
	_combat.party.append(token)
	_view.call("_rebuild_all")
	await tree.create_timer(0.6).timeout
	_shot("token_slot")

	_guard.restore()
	print("qa_actives_token_capture: done")
	tree.quit(0)


func _shot(tag: String) -> void:
	var path := "%s/%s_actives-%s.png" % [_EVIDENCE_DIR, _today(), tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_actives_token_capture: saved %s" % path)


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {},
			"bonus_hp": 0})
	return out


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
