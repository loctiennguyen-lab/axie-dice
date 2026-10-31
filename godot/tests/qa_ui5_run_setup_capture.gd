extends Node
## QA (not headless): round-3 frames 06-run-setup--{stage1,stage3,a5,full-locked,newcomer,daily,ranked} at the window size.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s3a1 godot/tools/shot.sh res://tests/qa_ui5_run_setup_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
const Fx := preload("res://tests/ui5_run_setup_fixture.gd")
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var ids: Array = Fx.IDS.duplicate()
	if OS.get_environment("UI5_STATES") == "1":
		ids = Fx.STATE_IDS.duplicate()
	if OS.get_environment("UI5_IMPORT") == "1":
		ids = ["ranked-import"]
	for id in ids:
		if id == "ranked-import":   # Ranked toggle with an imported (Vault) Axie in the party: reason label must wrap, not "..."
			ContentDB.heroes["vault_dup1"] = (ContentDB.heroes["plant1"] as Dictionary).duplicate(true)
			var si := Fx.make("ranked")
			add_child(si)
			for i in 8:
				await get_tree().process_frame
			si.set_slot(0, "vault_dup1")
			for i in 8:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			Util.save(get_viewport(), "06-run-setup--ranked-import" + ("--1280" if small else ""))
			si.queue_free()
			ContentDB.heroes.erase("vault_dup1")
			continue
		var s := Fx.make_state(id) if id in Fx.STATE_IDS else Fx.make(id)
		add_child(s)
		for i in 8:
			await get_tree().process_frame
		if id in Fx.STATE_IDS:
			await Fx.apply_state(s, get_tree())
		else:
			Fx.apply_kind(s)
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		Util.save(get_viewport(), "06-run-setup--" + id + ("--1280" if small else ""))
		s.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)
