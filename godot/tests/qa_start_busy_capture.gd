extends Node
## Run Setup while Start run is waiting on the server -> production/qa/evidence/sfb-start-busy-<W>x<H>.png (not headless).
var _guard := SaveGuard.new()
func _slow(_p: Dictionary) -> Dictionary:
	while true:
		await get_tree().process_frame
	return {}
func _ready() -> void:
	_guard.capture()
	MetaState.asc_max = 3
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.no_scene_change = true
	s.use_account = false
	s.remote_on = true
	s.state = "normal"
	s.start_hook = _slow
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": 0, "max": 3})
	add_child(s)
	for i in 10:
		await get_tree().process_frame
	s.begin()
	s._on_start_phase("closing_old")
	for i in 20:
		await get_tree().process_frame
	var sz := get_viewport().get_visible_rect().size
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/sfb-start-busy-%dx%d.png" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]))
	_guard.restore()
	get_tree().quit(0)
