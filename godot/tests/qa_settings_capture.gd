extends Node
## One-off capture: the settings screen with a run saved, so the ABANDON section is visible.

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	RunState.start_new_run(4242, ["plant1", "beast1", "aqua1", "reptile1", "bird1"],
		"short", 0, false)
	RunState.save_run({})
	await get_tree().process_frame

	var view: Node = (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(view)
	for _i in 30:
		await get_tree().process_frame
	var path := QaPaths.evidence_dir() + "/%s_settings.png" % _today()
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
	RunState.clear_saved_run()
	_guard.restore()
	get_tree().quit(0)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
