extends Node
## Manual visual QA (non-headless): Echo Box 10-pulls showing the R5 Deep Reef Epic set (12 items over two pulls) + a single die.
var _guard := SaveGuard.new()


func _shot(tag: String, frames := 90) -> void:
	for i in frames:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	var d := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(d)
	get_viewport().get_texture().get_image().save_png("%s/cosm_r5_%s_%dx%d.png" % [d, tag, w.x, w.y])


func _cos(item: String) -> Dictionary:
	return {"ok": true, "kind": "cosmetic", "amount": 0, "rarity": "epic", "item": item, "duplicate": false, "fragments": 0}


func _ready() -> void:
	_guard.capture()
	MetaState.tickets = {"normal": 30, "season": 0}
	MetaState.echobox_pity = {"fragments": 4}
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	var a: Array = []
	var b: Array = []
	for n in range(1, 7):
		(a if n <= 3 else b).append(_cos("die_e_reef_0%d" % n))
		(a if n <= 3 else b).append(_cos("frame_e_reef_0%d" % n))
	for pair in [[a, "a"], [b, "b"]]:
		var arr: Array = pair[0]
		while arr.size() < 10:
			arr.append(_cos("die_e_reef_05" if arr.size() % 2 == 0 else "frame_e_reef_02"))
		s.pull_hook = func(_n: int) -> Array: return arr
		await s.pull(10)
		await _shot("ten_" + String(pair[1]), 200)
		s.close_modal()
	s.pull_hook = func(_n: int) -> Array: return [_cos("die_e_reef_04")]
	await s.pull(1)
	await _shot("single_jelly", 150)
	s.close_modal()
	_guard.restore()
	get_tree().quit(0)
