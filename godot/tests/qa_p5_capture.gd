extends Node
## p5-ui capture (NOT headless). P5_MODE=combat: Undo / Hold / Wild reasons on the StatusLine + egg die.
## Run: P5_OUT=/abs/dir UI6_PROBE_SCALE=1 godot/tools/shot.sh res://tests/qa_p5_capture.tscn 1920x1080  (0.6667 / 1280x720)
var _guard := SaveGuard.new()
var _tag := "1280"


func _shot(name: String, pre := 0.0) -> void:
	if pre > 0.0:
		await get_tree().create_timer(pre).timeout
	var out := OS.get_environment("P5_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, _tag])


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	if want != "":
		UI3Theme.set_scale_override(float(want))
	UI3Theme.sync_scale()
	_tag = "1920" if UI3Theme.layout_scale() >= 0.99 else "1280"
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.pending_rewards.clear()
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.pending_combat = {"node_id": "p5", "kind": "battle", "pw": 4, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [], "combat_seed": 77}
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	await get_tree().create_timer(4.5).timeout
	v._combat.depth_stage = 2
	v._combat.mana = 0
	v._rebuild_all()
	var hud: CombatHud = v._hud_frame
	await get_tree().process_frame
	for k in ["Undo", "Hold", "Wild"]:
		var key := hud.find_child(k + "Key", true, false) as Ui5ToolKey
		if key != null and key.button.disabled:
			hud._reason_show(key, true)
		await _shot("reason-" + k.to_lower(), 0.3)
		hud._reason_key = null
		hud._reason_until_ms = 0
		hud.update_right_hint_refresh()
	var eu = v._combat.party[1]
	eu.roster_index = -1
	v._rebuild_all()
	await _shot("egg-die", 0.4)
	_guard.restore()
	get_tree().quit(0)
