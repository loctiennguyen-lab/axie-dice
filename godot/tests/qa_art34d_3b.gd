extends Node
## Manual visual QA (non-headless), art batch 3b: Echo Box 10-pull with the redrawn skins, l_kingdom right next to l_gold,
## plus a single pull of each. Writes echobox-*.png to $ADT_EVIDENCE_DIR.
var _guard := SaveGuard.new()


func _shot(tag: String, frames := 90) -> void:
	for i in frames:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	DirAccess.make_dir_recursive_absolute(OS.get_environment("ADT_EVIDENCE_DIR"))
	get_viewport().get_texture().get_image().save_png("%s/echobox-%s-%dx%d.png" % [OS.get_environment("ADT_EVIDENCE_DIR"), tag, w.x, w.y])


func _cos(item: String, rar: String) -> Dictionary:
	return {"ok": true, "kind": "cosmetic", "amount": 0, "rarity": rar, "item": item, "duplicate": false, "fragments": 0}


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
	for it in [["die_l_kingdom", "legendary"], ["die_l_gold", "legendary"]]:
		s.pull_hook = func(_n: int) -> Array: return [_cos(it[0], it[1])]
		await s.pull(1)
		await _shot("single-" + it[0], 150)
		s.close_modal()
	var mix: Array = [_cos("die_l_kingdom", "legendary"), _cos("die_l_gold", "legendary"), _cos("die_e_s1_founder", "epic"),
		_cos("die_e_reef_06", "epic"), _cos("die_r_aqua", "rare"), _cos("die_r_bird", "rare"), _cos("die_r_reptile", "rare"),
		_cos("die_m_moon", "mythic"), _cos("die_c_clay", "common"), _cos("die_u_moss", "uncommon")]
	s.pull_hook = func(_n: int) -> Array: return mix
	MetaState.tickets["normal"] = 12
	await s.pull(10)
	await _shot("ten", 200)
	s.close_modal()
	_guard.restore()
	get_tree().quit(0)
