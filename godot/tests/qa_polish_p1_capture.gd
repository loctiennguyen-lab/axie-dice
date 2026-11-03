extends Node
## Polish 3/11 P1 capture (NOT headless): combat tool-key reason, Core fire at 0.15 s / 0.4 s, boss enrage chip.
## Run: P1_OUT=/abs/dir UI6_PROBE_SCALE=1 godot/tools/shot.sh res://tests/qa_polish_p1_capture.tscn 1920x1080  (0.6667 / 1280x720)
var _guard := SaveGuard.new()


func _shot(name: String, tag: String, pre := 0.3) -> void:
	await get_tree().create_timer(pre).timeout
	var out := OS.get_environment("P1_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, tag])


func _start(kind: String) -> void:
	RunState.pending_combat = {"node_id": "p1_" + kind, "kind": kind, "pw": 4, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": RunState.owned_relic_ids.duplicate(), "combat_seed": 77}


func _ready() -> void:
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	if want != "":
		UI3Theme.set_scale_override(float(want))
	UI3Theme.sync_scale()
	var tag := "1920" if UI3Theme.layout_scale() >= 0.99 else "1280"
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.pending_rewards.clear()
	RunState._core_offer_active = false
	RunState._rule_offer_active = false
	RunState.set_phase(RunState.RunPhase.MAP)
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	_start("battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	for _i in 30:
		await get_tree().process_frame
	var hud: CombatHud = v._hud_frame
	var oc := hud.find_child("OvercastKey", true, false) as Ui5ToolKey
	if oc != null and oc.button.disabled:
		hud._reason_show(oc, true)
		print("P1_REASON overcast: ", oc.reason_text(), " hint_w=", hud._hint.size.x, " dock_w=", hud._dock.size.x, " hint_text=", hud._hint.text)
	await _shot("reason", tag)
	hud._reason_key = null
	hud._reason_until_ms = 0
	hud.update_right_hint_refresh()
	var ally: int = v._combat.party[0].uid
	EventBus.core_fired.emit("c_bastion", ally, 3, "shield")
	await _shot("core-fire-015", tag, 0.15)
	await _shot("core-fire-040", tag, 0.25)
	v.queue_free()
	await get_tree().process_frame
	_start("boss")
	var b: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(b)
	for _i in 30:
		await get_tree().process_frame
	await _shot("boss", tag)
	_guard.restore()
	get_tree().quit(0)
