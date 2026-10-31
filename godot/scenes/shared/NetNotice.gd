class_name NetNotice
extends RefCounted
## The one place that tells the player an epoch request (a real-run action that the server must seed) was
## refused, and offers RETRY when trying again can help (L1 B1). Views call `NetNotice.show(host, code, retry)`
## from RunState.epoch_failed / a failed request_* result. Never a silent no-op, never leaves input locked:
## the notice is a plain overlay, the buttons under it were never disabled for longer than the request.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

const NODE_NAME := "NetNotice"


## Copy per error code: UI-03 round 2, screen 36 (toast table). Surfaces there: Notice (this overlay, Retry),
## Dialog (blocking: expired / run_gone / version), Toast (rejected / bad_request / server, shown here as the
## same plate with OK until a toast host exists), Card/Inline (sign-in card, Aid) live in their own screens.
## `action` names what failed when the caller knows ("Could not send your turn"); it leads the line.
## `about_run` false drops "Your run is saved" (a wallet or store call has no run to save).
static func text_for(code: String, action: String = "", about_run: bool = true) -> String:
	var lead := (action + ". ") if action != "" else ""
	match code:
		"offline":
			return lead + "Can't reach the server." + (" Your run is saved." if about_run else "")
		"timeout":
			return lead + "The server is slow to answer. Try again."
		"expired", "unauthenticated":
			return "Your session expired. Sign in again to continue this run."
		"version", "mission_needs_update":
			return "A new version is out. Update to keep playing."
		"run_gone":
			return RunState.GONE_MESSAGE
		"busy":
			return "Still waiting for the server. Try again in a moment."
		"rejected", "out_of_order", "pin_mismatch", "stage_mismatch":
			return "The server didn't accept that move. It was undone."
		"bad_request":
			return "Something went wrong. Try that again."
	return "Server error. Try again in a moment."


## True when RETRY is pointless: the session itself is gone (the player must sign in again).
static func is_fatal(code: String) -> bool:
	return code == "expired" or UpdateRequired.is_update_code(code) or code == "unauthenticated"


## Shows (or replaces) the notice on `host`. `retry` is called by the RETRY button (non-fatal codes only).
## Fatal codes get SIGN IN and BACK TO MENU instead: never a dead screen.
static func show(host: Node, code: String, retry: Callable = Callable(), action: String = "", about_run: bool = true) -> Node:
	if host == null or not host.is_inside_tree():
		return null
	if UpdateRequired.is_update_code(code):
		# "This build is too old": the one update modal, never the raw notice. Close = back to Land.
		return UpdateRequired.show(host, code, func() -> void:
			if host.is_inside_tree():
				host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
	var old := host.get_node_or_null(NODE_NAME)
	if old != null:
		host.remove_child(old)
		old.queue_free()
	# Own CanvasLayer: the fight and map HUDs live on layers of their own, a bare child would be drawn under them.
	var layer := CanvasLayer.new()
	layer.name = NODE_NAME
	layer.layer = 100
	# UI-05 18-netnotice: the screen under it is dimmed (the scrim never takes the mouse: input is never locked),
	# 560 plate top-centre 24 px: [ToneDisc + Message] over a right-aligned button row. Nothing takes focus: no keycap.
	layer.add_child(NetParts.scrim())
	var top := CenterContainer.new()
	top.name = "Top"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = UI3Theme.space("screen")
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)
	var panel := PanelParts.panel(NetParts.hud_box("l", UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("20")), NODE_NAME)
	panel.custom_minimum_size = Vector2(UI3Theme.size_of("netnotice_w"), 0)
	top.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	panel.add_child(col)
	var msg := HBoxContainer.new()
	msg.name = "Msg"
	msg.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(msg)
	var disc := Ui5ToneDisc.make(&"warn")
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # centred on the text block (Liam 29/10), also when it wraps
	msg.add_child(disc)
	var l := Ui5Text.label(text_for(code, action, about_run), "text_body", "text")
	l.name = "Message"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.add_child(l)
	var foot := HFlowContainer.new()
	foot.name = "Foot"
	foot.alignment = FlowContainer.ALIGNMENT_END
	foot.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	foot.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	col.add_child(foot)
	if code == "run_gone":
		# Mid-run the server lost the run: drop the save and go to Land, never a stuck screen.
		var gone := PanelParts.button("Back to menu", &"primary", &"M")
		gone.name = "BackToMenuButton"
		gone.pressed.connect(func():
			RunState.discard_gone_run()
			host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
		foot.add_child(gone)
		host.add_child(layer)
		return layer
	if is_fatal(code):
		# Sign in is the one live primary; Back to menu and OK stay secondary.
		var si := PanelParts.button("Sign in", &"primary", &"M")
		si.name = "SignInButton"
		si.pressed.connect(func(): AccountService.sign_in())
		foot.add_child(si)
		var back := PanelParts.button("Back to menu", &"secondary", &"M")
		back.name = "BackToMenuButton"
		back.pressed.connect(func():
			host.get_tree().change_scene_to_file(LandNav.LAND_SCENE))
		foot.add_child(back)
	elif retry.is_valid():
		var b := PanelParts.button("Retry", &"primary", &"M")   # the one primary: OK stays secondary
		b.name = "RetryButton"
		b.pressed.connect(func():
			layer.queue_free()
			retry.call())
		foot.add_child(b)
	var close := PanelParts.button("OK", &"secondary", &"M")
	close.name = "OkButton"
	close.pressed.connect(func(): layer.queue_free())
	foot.add_child(close)
	host.add_child(layer)
	return layer
