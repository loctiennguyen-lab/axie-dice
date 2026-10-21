extends Node
## Lane GM capture (NOT headless, tools/shot.sh): combo burst in combat. Saves gacha_meta_combat_WxH.png.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	TComboFired.ensure_signal()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 3, false)
	for id in ["c_bastion", "c_fissure", "c_plague_spread"]:
		RunState.owned_relic_ids.append(id)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 90:
		await get_tree().process_frame
	v._land_dice_now()
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	EventBus.core_fired.emit("c_bastion", ally, 6, "block")
	EventBus.core_fired.emit("c_fissure", foe, 5, "dmg")
	EventBus.emit_signal("combo_fired", "t_pair")
	await get_tree().create_timer(0.5).timeout
	await _shot(out, "gacha_meta_combat")
	ComboAdapter.test_combos = null
	_guard.restore()
	get_tree().quit(0)

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%dx%d.png" % [out, name, img.get_width(), img.get_height()])
	print("QA: saved ", name)
