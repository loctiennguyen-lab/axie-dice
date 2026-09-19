extends Node
## One-off capture: the main menu with its two teaching entry points, then the tutorial itself.
##
## The tutorial's gate proves its steps LOCK. Only a picture shows whether what a new player
## actually sees is a game teaching them something or a wall of instructions.

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame

	var menu: Node = (load("res://scenes/main_menu/MainMenu.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(menu)
	for _i in 30:
		await get_tree().process_frame
	_shoot("menu")
	menu.queue_free()
	await get_tree().process_frame

	var tut: Node = (load("res://scenes/tutorial/Tutorial.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(tut)
	for _i in 60:
		await get_tree().process_frame
	_shoot("tutorial-step1")

	# Walk past WELCOME into the rehearsal board — the first screen is a title card, and the
	# thing worth looking at is what the tutorial actually teaches on.
	tut.set("_manual_step", 1)
	tut.call("_render")
	for _i in 40:
		await get_tree().process_frame
	_shoot("tutorial-board")
	_guard.restore()
	get_tree().quit(0)


func _shoot(tag: String) -> void:
	var path := "/Users/loc.tien.nguyen/my-game/production/qa/evidence/%s_%s.png" % [_today(), tag]
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
