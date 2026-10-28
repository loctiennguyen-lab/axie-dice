extends Node
## Manual visual QA, UI-04 run screens (not headless): tools/shot.sh res://tests/qa_ui4_run_capture.tscn 1920x1080
## Writes ui4run_<stage>_<W>x<H>.png: anchor pick, core offer, run map (Anchor 1/2 + run rule), awaken moment.
var _guard := SaveGuard.new()
var rm: Node


func _snap(tag: String) -> void:
	var sz := DisplayServer.window_get_size()
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/ui4run_%s_%dx%d.png" % [dir, tag, sz.x, sz.y])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.runs = 5
	MetaState.runs_completed = 5
	MetaState.runs_with_battle = 5
	UI3Gacha.instant_override = 1
	await RunState.begin_run({"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short",
		"ascension": 0, "kind": "normal", "ranked": false, "depth_stage": 3, "anchor": true, "rules_on": false})
	RunState.anchor_offer = ["a_kin", "a_volley", "a_gambler"]
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _wait(1.2)
	var pk := rm.find_child("AnchorPick", true, false)
	_snap("anchorpick_none")
	pk.select(0)
	await _wait(0.4)
	_snap("anchorpick_picked")
	var id := String(pk.cards[0].get_meta("anchor_id"))
	pk.take_button.pressed.emit()
	await _wait(0.8)
	# Core offer: Moss + Amber + Crystal, the Anchor's house Cores.
	var hc: Array = AnchorAdapter.house_cores(id)
	var cards: Array = []
	var axes := ["stat", "rule", "mana"]
	for i in 3:
		var d = RelicRegistry.get_def(String(hc[i]))
		cards.append({"t": "relic", "key": String(hc[i]), "rar": i, "title": "CORE", "desc": String(d.name),
			"sub": String(d.description), "core": true, "axis": axes[i], "tier": i, "slot": i})
	RunState.pending_rewards.assign(cards)
	rm.call("_show_reward_overlay", "x")
	await _wait(0.8)
	_snap("coreoffer")
	rm._close_overlay()
	RunState.pending_rewards.clear()
	rm._board.visible = true
	RunState.run_rule = "rule_upside_down"
	if not RunState.owned_relic_ids.has("rule_upside_down") and RelicRegistry.get_def("rule_upside_down") != null:
		RunState.owned_relic_ids.append("rule_upside_down")
	RunState.owned_relic_ids.append(String(hc[0]))
	rm.call("_refresh", false)
	await _wait(0.8)
	var tb := rm.find_child("TravelButton", true, false) as Button
	if tb != null:
		print("TRAVEL disabled=", tb.disabled, " normal=", (tb.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, " text=", tb.text)
	_snap("runmap")
	# Awaken moment
	UI3Gacha.instant_override = -1
	RunState.owned_relic_ids.append(String(hc[1]))
	RunState.anchor_awakened = true
	EventBus.anchor_awakened.emit(id)
	AnchorFx.arm(id)
	rm._maybe_show_pending_reward()
	await _wait(1.3)
	_snap("awaken")
	rm.queue_free()
	_guard.restore()
	get_tree().quit(0)
