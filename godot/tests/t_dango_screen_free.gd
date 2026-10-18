extends Node
## DangoScreen.build() listens to the viewport's size_changed; once the host screen is freed that listener
## must be gone (it used to fire with a freed capture: "get_viewport_rect on null"). A SCRIPT ERROR in this
## run fails the suite, so the test just frees the host and resizes.

func _ready() -> void:
	print("=== t_dango_screen_free: start ===")
	var host := Control.new()
	add_child(host)
	DangoScreen.build(host, null)
	var vp := get_viewport()
	var before := vp.size_changed.get_connections().size()
	host.free()
	var after := vp.size_changed.get_connections().size()
	vp.size_changed.emit()
	await get_tree().process_frame
	var ok := after < before
	print("t_dango_screen_free: %s — listeners %d -> %d" % ["PASS" if ok else "FAIL", before, after])
	get_tree().quit(0 if ok else 1)
