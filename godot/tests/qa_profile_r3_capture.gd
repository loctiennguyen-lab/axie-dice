extends Node
## Manual visual QA (non-headless): Profile M12 / M14 at the window size the runner gives.
## Run: godot/tools/shot.sh res://tests/qa_profile_r3_capture.tscn 1920x1080 (set QA_TAG=1080|1400)
var _guard := SaveGuard.new()

func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(QaPaths.evidence_dir())
	var tag := OS.get_environment("QA_TAG") if OS.get_environment("QA_TAG") != "" else "1080"
	var path := "%s/c6-m12-%s-%s.png" % [QaPaths.evidence_dir(), name, tag]
	get_tree().root.get_texture().get_image().save_png(path)
	print("saved ", path)

func _settle() -> void:
	for i in 12:
		await get_tree().process_frame

func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	MetaState.cosmetics_owned.assign(["die_c_clay", "die_c_reed", "frame_c_plant"])
	MetaState.equipped_die_skin = "die_c_clay"
	MetaState.runs = 14
	MetaState.wins = 9
	MetaState.asc_wins = {"4": 2}
	MetaState.run_log = []
	MetaState.profile_stats = {"pure_wins": 5, "ms_played": 2, "ms_won": 1}
	for i in 6:
		MetaState.record_run_outcome({"mode": "short", "ascension": i, "kind": ["normal", "ranked", "daily"][i % 3], "aid_used": i % 2 * 2, "mission_id": "ms" if i == 3 else ""}, i % 3 != 2)
	var pv: ProfileView = ProfileView.new()
	pv.no_scene_change = true
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pv)
	await _settle()
	print("DBG vp=", get_viewport().get_visible_rect().size, " content=", pv._shell["content"].size, " panel=", pv._shell["panel"].size, pv._shell["panel"].position)
	_shot("overview-guest")
	AccountService.account = {"id": "google:qa", "name": "Liam", "email": "q@skymavis.com", "sky_mavis": true}
	AccountService.status = AccountServiceScript.Status.SAVED
	AccountService.changed.emit()
	await _settle()
	_shot("overview-signed-in")
	pv.set_tab(1)
	await _settle()
	_shot("cosmetics")
	pv.set_tab(2)
	await _settle()
	_shot("titles")
	AccountService.account = {}
	AccountService.status = AccountServiceScript.Status.GUEST
	_guard.restore()
	get_tree().quit(0)
