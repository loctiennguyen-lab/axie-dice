extends Node
## One-off capture: the Codex as a player sees it. A rule book is text, and text is exactly the
## kind of thing a passing test can call "non-empty" while it renders as an unreadable wall or
## as `<NULL>`. Only a picture settles it.

const TABS_TO_SHOOT := ["basic", "dice", "st"]   # the basics, dice & faces, status effects


func _ready() -> void:
	var scene := load("res://scenes/codex/Codex.tscn") as PackedScene
	var codex: Node = scene.instantiate()
	# Deferred: `_ready()` runs while the root is still setting up children, and a plain
	# add_child() there fails with "Parent node is busy setting up children".
	get_tree().root.add_child.call_deferred(codex)
	await get_tree().process_frame
	await get_tree().process_frame

	for tab in TABS_TO_SHOOT:
		codex.call("_select_tab", tab)
		for _i in 20:
			await get_tree().process_frame
		var path := "/Users/loc.tien.nguyen/my-game/production/qa/evidence/%s_codex-%s.png" % [
			_today(), tab]
		get_tree().root.get_texture().get_image().save_png(path)
		print("QA: saved ", path)
	get_tree().quit(0)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
