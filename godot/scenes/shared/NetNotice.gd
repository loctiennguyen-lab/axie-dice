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
		"expired", "version":
			return "Your session expired. Sign in again to continue this run."
		"rejected", "out_of_order", "bad_request":
			return "The server refused that move. Try again."
	return "Could not reach the server (%s)." % code


## True when RETRY is pointless: the session itself is gone (the player must sign in again).
static func is_fatal(code: String) -> bool:
	return code == "expired" or code == "version"


## Shows (or replaces) the notice on `host`. `retry` is called by the RETRY button; invalid = no button.
static func show(host: Node, code: String, retry: Callable = Callable()) -> Control:
	if host == null or not host.is_inside_tree() or code == "busy":
		return null
	var old := host.get_node_or_null(NODE_NAME)
	if old != null:
		old.queue_free()
	var layer := PanelContainer.new()
	layer.name = NODE_NAME
	layer.z_index = 90
	layer.set_anchors_preset(Control.PRESET_CENTER_TOP)
	layer.position = Vector2(0, 40)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	layer.add_child(row)
	var l := Label.new()
	l.text = text_for(code)
	row.add_child(l)
	if retry.is_valid() and not is_fatal(code):
		var b := Button.new()
		b.text = "RETRY"
		b.pressed.connect(func():
			layer.queue_free()
			retry.call())
		row.add_child(b)
	var close := Button.new()
	close.text = "OK"
	close.pressed.connect(func(): layer.queue_free())
	row.add_child(close)
	host.add_child(layer)
	return layer
