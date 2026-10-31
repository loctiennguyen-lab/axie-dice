extends Node
## UI-05 b23 lane S12: Profile frames at 1920x1080 and 1280x720 (scale pinned). Not headless:
## godot/tools/shot.sh res://tests/qa_ui5_profile_capture.tscn
## Writes production/qa/ui05-b23/s12/24-profile--<state>[--1280].png (or $UI5_SHOT_DIR). Own state; SaveGuard restores.

class StubService extends Node:
	signal changed
	var status: int = AccountService.Status.SAVED
	var account: Dictionary = {}
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))

var _guard := SaveGuard.new()
var _out := ""
var _svc: StubService


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("UI5_SHOT_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s12").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	MetaState.reload_from_store()
	_svc = StubService.new()
	add_child(_svc)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		_svc.account = {"name": "Test Player", "sky_mavis": true}
		MetaState.run_log = []
		MetaState.runs = 0
		MetaState.wins = 0
		MetaState.asc_wins = {}
		MetaState.profile_stats = {"pure_wins": 0, "ms_played": 0, "ms_won": 0}
		MetaState.cosmetics_owned.clear()
		MetaState.equipped_die_skin = ""
		MetaState.equipped_frame = ""
		MetaState.equipped_title = ""
		await _shot("overview-empty", sfx, 0)
		for i in 8:
			MetaState.record_run_outcome({"mode": "short" if i % 3 else "full", "ascension": i % 6, "kind": "normal" if i % 4 else "ranked", "aid_used": i % 2, "mission_id": ""}, i % 3 != 0)
		await _shot("overview", sfx, 0)
		_svc.account = {}
		await _shot("guest", sfx, 0)
		_svc.account = {"name": "Test Player", "sky_mavis": true}
		var dice := ProfileView.catalog("die")
		var frames := ProfileView.catalog("frame")
		MetaState.cosmetics_owned.append(dice[0])
		MetaState.cosmetics_owned.append(frames[0])
		MetaState.cosmetics_owned.append("title:Gardener")
		MetaState.cosmetics_owned.append(TitleNames.ascension_titles()[0]["id"])
		MetaState.equipped_title = TitleNames.ascension_titles()[0]["id"]
		await _shot("cosmetics-dice", sfx, 1)
		await _shot("cosmetics-owned", sfx, 1, dice[0])
		await _shot("cosmetics-locked", sfx, 1, dice[2])
		await _shot("cosmetics-frames", sfx, 1, "", true)
		await _shot("titles", sfx, 2)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _shot(state: String, sfx: String, tab: int, pick := "", frames := false) -> void:
	var v: ProfileView = (load("res://scenes/profile/Profile.tscn") as PackedScene).instantiate()
	v.service = _svc
	v.no_scene_change = true
	add_child(v)
	for _i in 4:
		await get_tree().process_frame
	v.set_tab(tab)
	if frames:
		v.cat = Cosmetics.SLOT_FRAME
		v.refresh()
	if pick != "":
		v.selected = pick
		v.refresh()
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/24-profile--%s%s.png" % [_out, state, sfx])
	v.queue_free()
	await get_tree().process_frame
