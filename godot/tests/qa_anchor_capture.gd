extends Node
## Manual visual QA, Anchor lane: tools/shot.sh res://tests/qa_anchor_capture.tscn 1280x720 (not headless).
var _guard := SaveGuard.new()
var rm: Node


func _snap(name: String) -> void:
	var sz := DisplayServer.window_get_size()
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/anchor_%s_%dx%d.png" % [dir, name, sz.x, sz.y])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.runs = 5
	MetaState.runs_completed = 5
	MetaState.runs_with_battle = 5
	UI3Gacha.instant_override = 1
	var r: Dictionary = await RunState.begin_run({"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short",
		"ascension": 0, "kind": "normal", "ranked": false, "depth_stage": 3, "anchor": true, "rules_on": false})
	RunState.anchor_offer = ["a_kin", "a_embers", "a_big_hand"]   # newer Anchors; remove this line for a random offer
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _wait(1.5)
	_snap("pick")
	var pk := rm.find_child("AnchorPick", true, false)
	pk.select(0)
	await _wait(0.6)
	_snap("picked")
	var id := String(pk.cards[0].get_meta("anchor_id"))
	pk.take_button.pressed.emit()
	await _wait(1.0)
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(1.5)
	var hc: Array = AnchorAdapter.house_cores(id)
	for c in RunState.owned_relic_ids.duplicate():
		pass
	if not RunState.owned_relic_ids.has(String(hc[0])):
		RunState.owned_relic_ids.append(String(hc[0]))
	for n in rm.find_children("*", "", true, false):
		if n is CorePanel:
			n.refresh()
	await _wait(0.5)
	_snap("hud_1of2")
	RunState.owned_relic_ids.append(String(hc[1]))
	UI3Gacha.instant_override = -1
	RunState.anchor_awakened = true
	for n in rm.find_children("*", "", true, false):
		if n is CorePanel:
			n.refresh()
	EventBus.anchor_awakened.emit(id)
	AnchorFx.arm(id)
	rm._maybe_show_pending_reward()
	await _wait(1.2)
	_snap("awaken_moment")
	await _wait(3.0)
	for n in rm.find_children("*", "", true, false):
		if n is CorePanel:
			n.refresh()
	await _wait(0.4)
	_snap("hud_awakened")
	rm.queue_free()
	MetaState.anchor_codex = {id: {"seen": true, "picked": true, "awakened": true}}
	var cx: Node = load("res://scenes/codex/Codex.tscn").instantiate()
	add_child(cx)
	await _wait(0.5)
	cx._select_tab("anchors")
	await _wait(0.5)
	_snap("codex")
	cx.queue_free()
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = load("res://scenes/result/Result.tscn").instantiate()
	add_child(v)
	await _wait(1.5)
	_snap("result")
	_guard.restore()
	get_tree().quit(0)
