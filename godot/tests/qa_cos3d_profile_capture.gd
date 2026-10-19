extends Node
## Manual visual QA (non-headless): Profile > Cosmetics (24) dice + frames. QA_TAG names the size (1920|1280).
## Run: godot/tools/shot.sh res://tests/qa_cos3d_profile_capture.tscn 1920x1080
var _guard := SaveGuard.new()


func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(QaPaths.evidence_dir())
	var tag := OS.get_environment("QA_TAG") if OS.get_environment("QA_TAG") != "" else "1920"
	var path := "%s/cos3d-%s-%s.png" % [QaPaths.evidence_dir(), name, tag]
	get_tree().root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	MetaState.cosmetics_owned.assign(["die_c_clay", "die_c_reed", "die_u_moss", "die_r_aqua", "die_e_rune", "die_l_gold",
		"die_m_moon", "frame_c_aqua", "frame_c_bird", "frame_c_plant", "frame_u_vine", "frame_e_firefly", "frame_m_eclipse"])
	MetaState.equipped_die_skin = "die_l_gold"
	MetaState.equipped_frame = "frame_e_firefly"
	AccountService.account = {"id": "google:qa", "name": "Liam", "email": "q@skymavis.com", "sky_mavis": true}
	AccountService.status = AccountServiceScript.Status.SAVED
	var pv: ProfileView = ProfileView.new()
	pv.no_scene_change = true
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pv)
	pv.cat = "die"
	pv.selected = "die_e_rune"
	pv.set_tab(1)
	await _wait(240)
	_shot("profile-dice")
	pv.selected = "die_m_moon"
	pv.refresh()
	await _wait(240)
	_shot("profile-dice-mythic")
	pv.cat = "frame"
	pv.selected = "frame_m_eclipse"
	pv.refresh()
	await _wait(120)
	_shot("profile-frames")
	for fid in ["frame_c_aqua", "frame_c_bird"]:
		pv.selected = fid
		pv.refresh()
		await _wait(60)
		_shot("profile-" + fid)
	AccountService.account = {}
	AccountService.status = AccountServiceScript.Status.GUEST
	_guard.restore()
	get_tree().quit(0)
