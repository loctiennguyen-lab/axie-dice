extends Node
## Manual visual QA (non-headless): Echo Box reveal cards (20): single die (live drop), single frame, 10-pull 5 x 2.
var _guard := SaveGuard.new()


func _shot(tag: String, frames := 90) -> void:
	for i in frames:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	var d := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(d)
	get_viewport().get_texture().get_image().save_png("%s/cos3d-echobox-%s-%dx%d.png" % [d, tag, w.x, w.y])


func _cos(item: String, rar: String, dup := false) -> Dictionary:
	return {"ok": true, "kind": "cosmetic", "amount": 0, "rarity": rar, "item": item, "duplicate": dup, "fragments": 20 if dup else 0}


func _ready() -> void:
	_guard.capture()
	MetaState.tickets = {"normal": 12, "season": 0}
	MetaState.echobox_pity = {"fragments": 4}
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	s.pull_hook = func(_n: int) -> Array: return [_cos("die_e_rune", "epic")]
	await s.pull(1)
	await _shot("single-die", 150)
	s.close_modal()
	s.pull_hook = func(_n: int) -> Array: return [_cos("die_m_moon", "mythic")]
	await s.pull(1)
	await _shot("single-mythic", 40)
	s.close_modal()
	s.pull_hook = func(_n: int) -> Array: return [_cos("frame_m_eclipse", "mythic")]
	await s.pull(1)
	await _shot("single-frame", 60)
	s.close_modal()
	var stone := {"ok": true, "kind": "stone", "amount": 250, "rarity": "", "item": "", "duplicate": false, "fragments": 0}
	var mix: Array = [stone, _cos("die_c_reed", "common"), _cos("die_u_moss", "uncommon", true), _cos("die_r_aqua", "rare"),
		_cos("frame_c_plant", "common"), _cos("die_e_rune", "epic"), _cos("frame_e_firefly", "epic", true), _cos("die_l_gold", "legendary"),
		_cos("die_m_redcrystal", "mythic"), _cos("frame_m_eclipse", "mythic")]
	s.pull_hook = func(_n: int) -> Array: return mix
	MetaState.tickets["normal"] = 12
	await s.pull(10)
	await _shot("ten", 200)
	s.close_modal()
	_guard.restore()
	get_tree().quit(0)
