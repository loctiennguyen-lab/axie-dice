extends Node
## Capture (NOT headless): Core offer + Run rule overlays. `-- <out dir>`
const T := preload("res://tests/t_depthv3_core_offer.gd")
var _guard := SaveGuard.new()
func _ready() -> void:
	_guard.capture()
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for _i in 10:
		await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		CoreTestUtil.enable()
		var cs: Array = []
		var seen_ax: Array = []
		for d in RelicRegistry.all_defs_sorted():
			if String(d.id).begins_with("c_test_") and not seen_ax.has(String(d.core_axis)) and cs.size() < 3:
				seen_ax.append(String(d.core_axis))
				cs.append(CoreOffer.card_of(d, cs.size()))
		RunState.core_rerolled_slots = [1] as Array[int]
		for pair in [["core", cs], ["rule", T.rules()]]:
			RunState.pending_rewards.assign(pair[1])
			RunState.reward_reroll_charges = 2
			RunState.core_reroll_left = 2
			RunState._core_offer_active = pair[0] == "core"
			rm.call("_show_reward_overlay", "x")
			for _i in 12:
				await get_tree().process_frame
			get_tree().root.get_texture().get_image().save_png("%s/depthv3_%s_offer_%dx%d.png" % [out, pair[0], size.x, size.y])
	_guard.restore()
	get_tree().quit(0)
