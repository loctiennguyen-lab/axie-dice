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
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(0, 40)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var l := Label.new()
	l.name = "Message"
	l.text = text_for(code)
	row.add_child(l)
	if is_fatal(code):
		var si := Button.new()
		si.name = "SignInButton"
		si.text = "SIGN IN"
		si.pressed.connect(func(): AccountService.sign_in())
		row.add_child(si)
		var back := Button.new()
		back.name = "BackButton"
		back.text = "BACK TO MENU"
		back.pressed.connect(func():
			host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
		row.add_child(back)
	elif retry.is_valid():
		var b := Button.new()
		b.name = "RetryButton"
		b.text = "RETRY"
		b.pressed.connect(func():
			layer.queue_free()
			retry.call())
		row.add_child(b)
	var close := Button.new()
	close.name = "OkButton"
	close.text = "OK"
	close.pressed.connect(func(): layer.queue_free())
	row.add_child(close)
	host.add_child(layer)
	return layer
