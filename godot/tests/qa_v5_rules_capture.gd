extends Node
## Capture (run NOT headless, tools/shot.sh): elite fight with Pack Alpha + Shell on. Saves v5_rules_WxH.png.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	var b: Dictionary = (ContentDB.combat_tune.get("shell", {}) as Dictionary).duplicate(true)
	b["enabled"] = true
	ContentDB.combat_tune["shell"] = b
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var ros: Array = []
	for i in keys.size():
		ros.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	RunState.pending_combat = {"node_id": "cap", "kind": "elite", "pw": 4, "ascension": 0,
		"roster_snapshot": ros, "relic_ids": ["rule_pack_alpha"], "combat_seed": 77}
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	for _i in 90:
		await get_tree().process_frame
	v._land_dice_now()
	var other = null
	for e in v._combat.enemies:
		v._update_portrait(e)
		if not bool(e.custom_state.get("alpha", false)):
			other = e
	if other != null:
		EventBus.core_fired.emit("rule_pack_alpha", other.uid, 3, "block")
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/v5_rules_%dx%d.png" % [out, img.get_width(), img.get_height()])
	print("QA: saved v5_rules")
	_guard.restore()
	get_tree().quit(0)
