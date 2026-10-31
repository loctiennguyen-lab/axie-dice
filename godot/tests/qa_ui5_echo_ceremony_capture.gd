extends Node
## QA (not headless): 20-echo--opening / reveal-new / reveal-duplicate / reveal-stone / reveal-rare-plus / reveal-mythic / open10
## at the window size (scale pinned like qa_ui5_pin). Files: <UI5_SHOT_DIR>/<frame id>[--1280]-WxH.png
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s9b godot/tools/shot.sh res://tests/qa_ui5_echo_ceremony_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _cos(rarity: String, dup := false) -> Dictionary:
	var box: Dictionary = ((EchoBox._cfg().get("boxes", {}) as Dictionary).get("normal", {})) as Dictionary
	var best := ""
	for id in EchoBox.pool_ids(box, rarity):
		var a := Cosmetics.art_id(String(id))
		if a != "" and Cosmetics.slot_of(a) == Cosmetics.SLOT_DIE and CosmeticTile.any_name(String(id)) != "":
			best = String(id)
			break
	return {"ok": true, "kind": "cosmetic", "item": best, "rarity": rarity, "duplicate": dup, "fragments": 10 if dup else 0}


func _shot(id: String, res: Array, instant := true, opening := false) -> void:
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = instant
	add_child(s)
	for i in 6:
		await get_tree().process_frame
	s.pull_hook = func(_n: int) -> Array: return res
	if opening:
		s.pull(res.size())
	else:
		await s.pull(res.size())
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)
	s.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	MetaState.tickets = {"normal": 30, "season": 0}
	MetaState.echobox_pity = {}
	var stone := {"ok": true, "kind": "stone", "amount": 500, "rarity": "", "item": "", "duplicate": false, "fragments": 0}
	await _shot("20-echo--opening", [_cos("rare")], false, true)
	await _shot("20-echo--reveal-new", [_cos("rare")])
	await _shot("20-echo--reveal-duplicate", [_cos("epic", true)])
	await _shot("20-echo--reveal-stone", [stone])
	await _shot("20-echo--reveal-rare-plus", [_cos("legendary")])
	await _shot("20-echo--reveal-mythic", [_cos("mythic")])
	var ten: Array = []
	for r in ["", "common", "", "common", "", "", "uncommon", "", "common", "epic"]:
		ten.append(stone if r == "" else _cos(r))
	await _shot("20-echo--open10", ten)
	_guard.restore()
	get_tree().quit(0)
