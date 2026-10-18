extends Node
## Manual visual QA for UI-03 event (09) + treasure (13). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(name: String) -> void:
	for i in 12:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/ui3-%s-%dx%d.png" % [_EVIDENCE_DIR, name, w.x, w.y])


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	RunState.reset()
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	RunState.event_key = String(ContentDB.events.keys()[0])
	rm.call("_on_event_node", "x")
	rm.call("_select_event", 0)
	await _shot("event-choices")
	rm.call("_build_event_screen", 0, "You rest by the fire and feel stronger. +6 HP to the whole party.")
	await _shot("event-outcome")
	rm.call("_on_treasure_node", "tn")
	await _shot("treasure-closed")
	rm.call("_build_treasure", true)
	await _shot("treasure-opened")
	_guard.restore()
	get_tree().quit(0)
