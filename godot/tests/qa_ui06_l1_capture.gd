extends Node
## QA-only, UI-06 L1: shots of 47-core-offer states + 05-run-rule-offer, 1920 and 1280.
##   UI6_PROBE_SCALE=1 ADT_EVIDENCE_DIR=production/qa/ui06/l1 godot/tools/shot.sh res://tests/qa_ui06_l1_capture.tscn 1920x1080
##   UI6_PROBE_SCALE=0.6667 ... 1280x720   (Retina has DPR 2: the scale must be forced, as in qa_ui06_l0_probe)
## Frame ids: 47-core-offer--{facedown,facedown-crystal,moss,amber,crystal,selected,crystal-cap,combo-banner,make-room}, 05-run-rule-offer--offer.
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()
var _small := false
var _rm: Node


func _shot(frame: String) -> void:
	for _i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if _small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui06_l1_capture: saved ", path)


func _defs_of_tier(t: int) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at("res://resources/relics"):
		if not (f.begins_with("c_") and f.ends_with(".tres")):
			continue
		var d = RelicRegistry.get_def(f.get_basename())
		if d != null and int(d.rarity) == t and String(d.core_axis) not in ["", "run_rule"]:
			out.append(d)
	return out


func _offer(tiers: Array, cap_note := false) -> void:
	var cards: Array = []
	var used := {}
	for i in tiers.size():
		var pool := _defs_of_tier(int(tiers[i]))
		var d = pool[(i * 3) % pool.size()]
		cards.append(CoreOffer.card_of(d, i))
	RunState._core_offer_active = true
	RunState._rule_offer_active = false
	RunState.core_reroll_left = 2
	RunState.pending_rewards.assign(cards)
	_rm.call("_show_reward_overlay", "x")


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	DirAccess.make_dir_recursive_absolute(_dir)
	_small = (float(OS.get_environment("UI6_PROBE_SCALE")) < 0.9 and OS.get_environment("UI6_PROBE_SCALE") != "") or get_window().size.x < 1600
	var want := OS.get_environment("UI6_PROBE_SCALE")
	UI3Theme.set_scale_override(float(want) if want != "" else (2.0 / 3.0 if _small else 1.0))
	UI3Theme.sync_scale()
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	_rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(_rm)
	for _i in 8:
		await get_tree().process_frame
	await _shot("05-run-rule-offer--offer")
	UI3Gacha.instant_override = 0   # face-down: capture right after the deal, before any flip
	_offer([0, 1, 1])
	await get_tree().process_frame
	await _shot("47-core-offer--facedown")
	UI3Gacha.instant_override = 1
	for pair in [["moss", [0, 0, 0]], ["amber", [1, 1, 1]], ["crystal", [2, 1, 0]]]:
		_offer(pair[1])
		await _shot("47-core-offer--" + String(pair[0]))
	_offer([2, 1, 0])
	for _i in 4:
		await get_tree().process_frame
	_rm.call("_select_reward", 1)
	await _shot("47-core-offer--selected")
	# make-room: 6 owned Cores, take a 7th
	var ids: Array[String] = []
	for t in 3:
		for d in _defs_of_tier(t):
			ids.append(String(d.key if "key" in d else d.id))
	RunState._core_offer_active = false
	RunState.owned_relic_ids.assign(ids.slice(0, RelicSlots.tuning().core_slots))
	RunState.relic_stickers = {}
	RunState.pending_rewards = [{"t": "relic", "key": ids[RelicSlots.tuning().core_slots], "rar": 0, "title": "RELIC", "desc": "Core", "sub": ""}]
	_rm.call("_show_reward_overlay", "CHOOSE A REWARD")
	await get_tree().process_frame
	_rm.call("_select_reward", 0)
	_rm.call("_take_selected_reward")
	await _shot("47-core-offer--make-room")
	_rm.call("_close_overlay")
	var cid := ""
	for r in CoreCombos.all():
		cid = String(r.get("id", ""))
		if AnchorAdapter.house_of_combo(cid) != "":
			break
	UI3Gacha.instant_override = 0
	var house := AnchorAdapter.house_of_combo(cid)
	preload("res://scenes/run_map/ui5/ComboBand.gd").build(_rm.get("_overlay_layer"), "full", UI3Gacha.combo_name(cid), house,
		house != "", UI3Gacha.combo_members(cid, "full"))
	await get_tree().create_timer(1.0).timeout
	await _shot("47-core-offer--combo-banner")
	_guard.restore()
	get_tree().quit(0)
