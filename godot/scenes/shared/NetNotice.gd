class_name NetNotice
extends RefCounted
## The one place that tells the player an epoch request (a real-run action that the server must seed) was
## refused, and offers RETRY when trying again can help (L1 B1). Views call `NetNotice.show(host, code, retry)`
## from RunState.epoch_failed / a failed request_* result. Never a silent no-op, never leaves input locked:
## the notice is a plain overlay, the buttons under it were never disabled for longer than the request.

const NODE_NAME := "NetNotice"


static func text_for(code: String) -> String:
	match code:
		"offline", "timeout":
			return "Connection lost. Check your network and try again."
		"expired", "version", "unauthenticated":
			return "Your session expired. Sign in again to continue this run."
		"run_gone":
			return RunState.GONE_MESSAGE
		"busy":
			return "Still waiting for the server. Try again in a moment."
		"rejected", "out_of_order", "bad_request":
			return "The server refused that move. Try again."
	return "Could not reach the server (%s)." % code


## True when RETRY is pointless: the session itself is gone (the player must sign in again).
static func is_fatal(code: String) -> bool:
	return code == "expired" or code == "version" or code == "unauthenticated"


## Shows (or replaces) the notice on `host`. `retry` is called by the RETRY button (non-fatal codes only).
## Fatal codes get SIGN IN and BACK TO MENU instead: never a dead screen.
static func show(host: Node, code: String, retry: Callable = Callable()) -> Node:
	if host == null or not host.is_inside_tree():
		return null
	var old := host.get_node_or_null(NODE_NAME)
	if old != null:
		host.remove_child(old)
		old.queue_free()
	# Own CanvasLayer: the fight and map HUDs live on layers of their own, a bare child would be drawn under them.
	var layer := CanvasLayer.new()
	layer.name = NODE_NAME
	layer.layer = 100
	# UI-03 18-system: wood-2 notice plate, top-centre 24 px down; buttons are UI3 secondary S.
	var top := CenterContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 24
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)
	var panel := UI3.plate(&"notice")
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(560, 0)
	top.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var l := UI3.label(text_for(code))
	l.name = "Message"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	if code == "run_gone":
		# Mid-run the server lost the run: drop the save and go to Land, never a stuck screen.
		var gone := UI3.button("BACK TO MENU", &"secondary", &"S")
		gone.name = "BackButton"
		gone.pressed.connect(func():
			RunState.discard_gone_run()
			host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
		row.add_child(gone)
		host.add_child(layer)
		return layer
	if is_fatal(code):
		var si := UI3.button("SIGN IN", &"secondary", &"S")
		si.name = "SignInButton"
		si.pressed.connect(func(): AccountService.sign_in())
		row.add_child(si)
		var back := UI3.button("BACK TO MENU", &"secondary", &"S")
		back.name = "BackButton"
		back.pressed.connect(func():
			host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
		row.add_child(back)
	elif retry.is_valid():
		var b := UI3.button("RETRY", &"secondary", &"S")
		b.name = "RetryButton"
		b.pressed.connect(func():
			layer.queue_free()
			retry.call())
		row.add_child(b)
	var close := UI3.button("OK", &"secondary", &"S")
	close.name = "OkButton"
	close.pressed.connect(func(): layer.queue_free())
	row.add_child(close)
	host.add_child(layer)
	return layer
