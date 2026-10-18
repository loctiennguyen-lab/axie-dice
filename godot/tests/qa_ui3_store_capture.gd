extends Node
## QA: capture UI-03 Store. Not headless.
## godot --path godot --resolution 1920x1080 res://tests/qa_ui3_store_capture.tscn -- --screen=gem --out=/path/x.png
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var screen := "gem"
	var out := "user://store.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			screen = a.get_slice("=", 1)
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	MetaState.tutorial_seen = true
	MetaState.gems_cache = 400
	var s: StoreScreen = load("res://scenes/store/StoreScreen.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	match screen:
		"cos": s.set_tab("cosmetics")
		"tickets": s.set_tab("tickets")
		"moon": s.set_tab("moon")
		"guest":
			s.remote_on = true
			s.set_state("guest")
		"confirm":
			s.set_tab("tickets")
			s.open_confirm("6 tickets", "Adds 6 Echo Box tickets.", 120, func() -> void: pass)
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	_guard.restore()
	get_tree().quit(0)
