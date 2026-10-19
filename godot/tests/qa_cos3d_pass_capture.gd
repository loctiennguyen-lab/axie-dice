extends Node
## Manual visual QA (non-headless): Pass reward tiles for dice skins / frames (48): claimed, claimable, locked.
var _guard := SaveGuard.new()


func _shot(name: String) -> void:
	for i in 20:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	var d := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(d)
	get_viewport().get_texture().get_image().save_png("%s/cos3d-pass-%s-%dx%d.png" % [d, name, w.x, w.y])


func _ready() -> void:
	_guard.capture()
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = 9000
	MetaState.pass_season["level"] = 22
	var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.today_override = "2026-11-10"
	add_child(s)
	await get_tree().process_frame
	s.claim_level(9)
	s.refresh()
	var sc := s.find_child("TrackScroll", true, false) as ScrollContainer
	if sc != null:
		sc.scroll_vertical = 205
	await _shot("lv9")
	if sc != null:
		sc.scroll_vertical = 640
	await _shot("lv21")
	_guard.restore()
	get_tree().quit(0)
