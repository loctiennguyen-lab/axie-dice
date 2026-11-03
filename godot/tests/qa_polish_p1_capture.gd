extends Node
## Polish 3/11 P1 capture (NOT headless). Combat: tool-key reason; Core fire at 0.10 / 0.30 / 0.55 s; Anchor fire; egg die;
## boss enrage chip on the EnemyPlate.
## Run: AXIE_HANG_KILL=300 P1_OUT=/abs/dir UI6_PROBE_SCALE=1 godot/tools/shot.sh res://tests/qa_polish_p1_capture.tscn 1920x1080  (0.6667 / 1280x720)
var _guard := SaveGuard.new()
var _tag := "1280"


func _shot(name: String, pre := 0.0) -> void:
	if pre > 0.0:
		await get_tree().create_timer(pre).timeout
	var out := OS.get_environment("P1_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, _tag])


func _start(kind: String) -> Node:
	RunState.pending_combat = {"node_id": "p1_" + kind, "kind": kind, "pw": 4, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": RunState.owned_relic_ids.duplicate(), "combat_seed": 77}
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	await get_tree().create_timer(4.5).timeout   # boss intro / "Your turn" band are long over
	return v


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
	RunState._core_offer_active = false
	RunState._rule_offer_active = false
	RunState.set_phase(RunState.RunPhase.MAP)
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": ["c_bastion"], "awakened": false}
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	var v: Node = await _start("battle")
	var hud: CombatHud = v._hud_frame
	var oc := hud.find_child("OvercastKey", true, false) as Ui5ToolKey
	if oc != null and oc.button.disabled:
		hud._reason_show(oc, true)
	await _shot("reason", 0.3)
	hud._reason_key = null
	hud._reason_until_ms = 0
	hud.update_right_hint_refresh()
	# egg die: turn the 2nd party unit into a token look
	var eu = v._combat.party[1]
	eu.roster_index = -1
	v._rebuild_all()
	await _shot("egg-die", 0.4)
	var ally: int = v._combat.party[0].uid
	EventBus.core_fired.emit("c_bastion", ally, 3, "shield")
	await _shot("core-fire-010", 0.10)
	await _shot("core-fire-030", 0.20)
	await _shot("core-fire-045", 0.15)
	await _shot("core-fire-055", 0.10)
	print("P1_BURSTS ", v.core_bursts)
	await get_tree().create_timer(1.5).timeout
	var foe: int = v._combat.enemies[0].uid
	EventBus.core_fired.emit("a_volley", foe, 6, "dmg")
	await _shot("anchor-fire-010", 0.10)
	await _shot("anchor-fire-030", 0.20)
	await _shot("anchor-fire-045", 0.15)
	await _shot("anchor-fire-055", 0.10)
	print("P1_BURSTS ", v.core_bursts)
	v.queue_free()
	await get_tree().process_frame
	var b: Node = await _start("boss")
	await _shot("boss-plate", 0.2)
	_guard.restore()
	AnchorAdapter.test_state = {}
	get_tree().quit(0)
