class_name AccountUI
extends RefCounted
## The account surfaces from the approved mock (claude/ACCOUNT_SYSTEM_v1.md §7,
## account_ui_mock_v1.html): A welcome panel, B account chip, D save-choice dialog, E toasts.
## Settings → Account (C) lives in SettingsView and uses the same service calls.
##
## UI-03: welcome, desktop sign-in, save choice and toasts are on UI3 (round-2 screens 16 and 26).
## The account chip (B) is still Dango styled.

const WELCOME_W := 760.0
const CHOICE_W := 980.0
const MOVE_W := 760.0
const TOAST_W := 860.0
const TOAST_SECONDS := 10.0


# ============================================================================ A · welcome

## UI-03 (round 2, screen 16 / 26): plate dialog on a scrim, UI3 labels and buttons. One primary.
static func show_welcome(layer: CanvasLayer) -> Control:
	var service: Node = layer.get_parent()
	var overlay := _overlay(layer)
	overlay.name = "AccountWelcome"
	var box := _modal(overlay, WELCOME_W)

	var t := UI3.label("Save your progress", "LabelScreenTitle")
	t.name = "Title"
	box.add_child(t)
	box.add_child(_prose("Sign in with Google to keep your Axies, Shards and runs on any device. "
		+ "Your Sky Mavis work account works too. No new registration needed."))

	var perks := HBoxContainer.new()
	perks.add_theme_constant_override("separation", UI3Theme.space("16"))
	for p in [["Vault", "your imported Axies"], ["Shards & Pass", "every unlock you earned"],
			["Continue", "pick up a run on another device"]]:
		var well := UI3.plate(&"card")
		well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI3Theme.space("8"))
		var pt := UI3.label(p[0], "LabelTitle")
		pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(pt)
		var c := _prose(p[1], "LabelMuted")
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(c)
		well.add_child(col)
		perks.add_child(well)
	box.add_child(perks)

	var google := UI3.button("Continue with Google", &"primary", &"L")
	google.name = "ContinueWithGoogle"
	google.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	google.pressed.connect(func() -> void:
		overlay.queue_free()
		service.sign_in())
	box.add_child(google)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	var hint := _prose("No Google account? You can create one on the next screen.", "LabelMuted")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)
	var guest := UI3.button("Continue without signing in", &"secondary", &"M")
	guest.name = "PlayAsGuest"
	guest.pressed.connect(func() -> void:
		overlay.queue_free()
		service.play_as_guest())
	row.add_child(guest)
	box.add_child(row)
	google.call_deferred("grab_focus")
	return overlay


# ============================================================================ desktop browser flow

## Overlay for the desktop sign-in, shown over whatever screen started it. It only mirrors
## `service.desktop_phase` ("waiting" | "finishing" | "signed_in" | "error") and calls the service;
## it frees itself when the phase goes back to "idle". "signed_in" shows the name, then dismisses.
static func show_desktop_flow(layer: CanvasLayer, service: Node, auto_dismiss_s: float = 1.6) -> Control:
	var overlay := _overlay(layer)
	overlay.name = "DesktopSignInFlow"
	var box := _modal(overlay, 640.0)
	var dismissed := [false]
	var refresh := Callable()
	refresh = func() -> void:
		if not is_instance_valid(overlay):
			return
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
		var phase := String(service.get("desktop_phase"))
		match phase:
			"waiting":
				var t := UI3.label("Waiting for the browser…", "LabelScreenTitle")
				t.name = "Title"
				box.add_child(t)
				box.add_child(_prose("Finish signing in in your browser. Then come back here; the game picks it up by itself."))
				var again := UI3.button("Open browser again", &"primary", &"M")
				again.name = "OpenAgain"
				again.pressed.connect(func() -> void: service.reopen_desktop_browser())
				box.add_child(again)
				var cancel := UI3.button("Cancel", &"secondary", &"M")
				cancel.name = "Cancel"
				cancel.pressed.connect(func() -> void: service.cancel_desktop_sign_in())
				box.add_child(cancel)
			"finishing":
				var t := UI3.label("Signing you in…", "LabelScreenTitle")
				t.name = "Title"
				box.add_child(t)
				box.add_child(_prose("Google said yes. Checking your account."))
			"signed_in":
				var t := UI3.label("Signed in as %s" % String(service.display_name()), "LabelScreenTitle")
				t.name = "Title"
				box.add_child(t)
				var go := UI3.button("Continue", &"primary", &"M")
				go.name = "Continue"
				go.pressed.connect(func() -> void: service.dismiss_desktop_result())
				box.add_child(go)
				if auto_dismiss_s > 0.0 and not dismissed[0] and overlay.is_inside_tree():
					dismissed[0] = true
					overlay.get_tree().create_timer(auto_dismiss_s).timeout.connect(func() -> void:
						if is_instance_valid(service):
							service.dismiss_desktop_result())
			"error":
				var copy: Array = AccountScreen.error_copy(String(service.get("desktop_error")))
				var t := UI3.label(String(copy[0]), "LabelScreenTitle")
				t.name = "Title"
				t.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
				box.add_child(t)
				box.add_child(_prose(String(copy[1])))
				var retry := UI3.button(String(copy[2]), &"primary", &"M")
				retry.name = "Retry"
				retry.pressed.connect(func() -> void:
					service.clear_desktop_error()
					service.sign_in())
				box.add_child(retry)
				var close := UI3.button("Close", &"secondary", &"M")
				close.name = "Close"
				close.pressed.connect(func() -> void: service.clear_desktop_error())
				box.add_child(close)
			_:
				overlay.queue_free()
	service.changed.connect(refresh)
	overlay.tree_exiting.connect(func() -> void:
		if is_instance_valid(service) and service.changed.is_connected(refresh):
			service.changed.disconnect(refresh))
	refresh.call()
	return overlay


# ============================================================================ B · chip

## A button showing who is signed in and whether the save is in the cloud. It rebuilds itself
## whenever the service changes, and frees its connection when it leaves the tree.
static func build_chip(service: Node, on_open_settings: Callable) -> Button:
	var btn := Button.new()
	btn.name = "AccountChip"
	btn.custom_minimum_size = Vector2(0, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for key in ["normal", "hover", "pressed", "focus"]:
		var kind := DangoTheme.Surface.PANEL_RAISED if key == "hover" else DangoTheme.Surface.PANEL
		btn.add_theme_stylebox_override(key,
			DangoTheme.surface_style(kind, 30, 3, 5.0, Vector2(8, 6)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -16
	btn.add_child(row)

	var refresh := func() -> void:
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
		_fill_chip(row, service)
		btn.custom_minimum_size.x = 0
		btn.custom_minimum_size.x = row.get_combined_minimum_size().x + 24
	refresh.call()
	service.changed.connect(refresh)
	btn.tree_exiting.connect(func() -> void:
		if service.changed.is_connected(refresh):
			service.changed.disconnect(refresh))

	btn.pressed.connect(func() -> void:
		var st := int(service.status)
		if st == AccountServiceScript.Status.GUEST:
			service.mark_welcome_shown()
			show_welcome(service._ui_layer())
		elif st == AccountServiceScript.Status.EXPIRED:
			service.sign_in()
		else:
			on_open_settings.call())
	return btn


static func _fill_chip(row: HBoxContainer, service: Node) -> void:
	var signed_in: bool = service.is_signed_in()
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(40, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := DangoTheme.INFO if signed_in else DangoTheme.FUTURE
	avatar.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(fill, 20, 3))
	var initial := DangoTheme.display_label(
		String(service.display_name()).left(1).to_upper() if signed_in else "?", 20,
		DangoTheme.ink_on(fill))
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.add_child(initial)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(avatar)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nm := DangoTheme.display_label(service.display_name() if signed_in else "Guest", 18)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(nm)
	if signed_in and bool(service.account.get("sky_mavis", false)):
		name_row.add_child(sky_mavis_badge())
	col.add_child(name_row)

	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 6)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := status_line(service)
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.color = line[1]
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(dot)
	var lbl := _chip_prose(line[0], 13, DangoTheme.TEXT_DIM if signed_in else DangoTheme.PRIMARY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(lbl)
	col.add_child(st)
	row.add_child(col)


## [text, dot colour] for the service's current status.
static func status_line(service: Node) -> Array:
	var st := int(service.status)
	if st == AccountServiceScript.Status.SAVED:
		return ["Saved", UI3Theme.color("success_text")]
	if st == AccountServiceScript.Status.SAVING:
		return ["Saving…", UI3Theme.color("accent")]
	if st == AccountServiceScript.Status.CHECKING:
		return ["Checking…", UI3Theme.color("accent")]
	if st == AccountServiceScript.Status.OFFLINE:
		return ["Offline — will sync", UI3Theme.color("danger_text")]
	if st == AccountServiceScript.Status.EXPIRED:
		return ["Signed out — sign in to save", UI3Theme.color("danger_text")]
	return ["Sign in to save", UI3Theme.color("accent")]


static func sky_mavis_badge() -> PanelContainer:
	var b := UI3Meta.tag("SKY MAVIS")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


# ============================================================================ D · choice

## kind: "move" (account empty, guest save here), "choose" (both have a save, first sign-in on
## this device) or "conflict" (the account moved on elsewhere since this device last synced).
## done(choice) gets "move"/"fresh" or "local"/"cloud". The dialog cannot be dismissed without
## choosing — the whole point is that nothing is decided for the player.
## UI-03: "Choose a save" shows two cards; exactly one primary (the newer save), the other secondary.
static func show_choice(layer: CanvasLayer, kind: String, info: Dictionary, done: Callable) -> Control:
	var overlay := _overlay(layer)
	var box := _modal(overlay, MOVE_W if kind == "move" else CHOICE_W)

	if kind == "move":
		box.add_child(UI3.label("Move your guest progress?", "LabelScreenTitle"))
		box.add_child(_prose("This browser has progress from before you signed in, and your account "
			+ "is empty. Move it to your account to keep it on every device."))
		box.add_child(_save_card("This device (guest)", "", info.get("local", {})))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		var move := UI3.button("Move progress", &"primary", &"M")
		move.name = "MoveProgress"
		move.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		move.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("move"))
		var fresh := UI3.button("Start fresh", &"secondary", &"M")
		fresh.name = "StartFresh"
		fresh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fresh.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("fresh"))
		row.add_child(move)
		row.add_child(fresh)
		box.add_child(row)
		move.call_deferred("grab_focus")
		return overlay

	var title := "This device has guest progress" if kind == "choose" \
		else "This account was played somewhere else"
	var body := ("Your account already has a save. Pick the one to keep on your account. The "
		+ "other one stays on this device for %d days in case you change your mind.") if kind == "choose" \
		else ("This device and your account both changed since they last matched. Pick the one "
		+ "to keep. The other one stays on this device for %d days in case you change your mind.")
	var tl := UI3.label("Choose a save", "LabelScreenTitle")
	tl.name = "Title"
	box.add_child(tl)
	box.add_child(UI3.label(title, "LabelTitle"))
	box.add_child(_prose(body % AccountServiceScript.BACKUP_DAYS, "LabelMuted"))

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", UI3Theme.space("16"))
	var local_title := "This device (guest)" if kind == "choose" else "This device"
	var cloud: Dictionary = info.get("cloud", {})
	var cloud_when := ""
	if int(cloud.get("updated_at", 0)) > 0:
		cloud_when = "Saved " + ago(int(cloud["updated_at"]))
	# Primary goes to the save with more XP (the further-along one); a tie keeps the account's cloud save.
	var local_xp := int((info.get("local", {}) as Dictionary).get("xp", 0))
	var cloud_xp := int(cloud.get("xp", 0))
	var local_primary := local_xp > cloud_xp
	for side in [["local", local_title, "On this browser", "Keep this device", local_primary],
			["cloud", "Cloud (your account)", cloud_when, "Keep cloud", not local_primary]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI3Theme.space("16"))
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(_save_card(side[1], side[2], info.get(side[0], {})))
		var b := UI3.button(side[3], &"primary" if side[4] else &"secondary", &"M")
		b.name = "Keep" + String(side[0]).capitalize()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var choice: String = side[0]
		b.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call(choice))
		col.add_child(b)
		cards.add_child(col)
		# No auto-focus: either button overwrites the other save, so Enter must never pick one by itself.
	box.add_child(cards)
	return overlay


static func _save_card(title: String, when: String, s: Dictionary) -> PanelContainer:
	var card := UI3.plate(&"card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	card.add_child(col)
	col.add_child(UI3.label(title, "LabelTitle"))
	if not when.is_empty():
		col.add_child(UI3.label(when, "LabelMuted"))
	for r in [["Gene Shards", str(int(s.get("shards", 0)))],
			["XP", str(int(s.get("xp", 0)))],
			["Vault", "%d / 20" % int(s.get("vault", 0))],
			["Runs · wins", "%d · %d" % [int(s.get("runs", 0)), int(s.get("wins", 0))]],
			["Run in progress", String(s.get("run", "")) if not String(s.get("run", "")).is_empty() else "—"]]:
		var row := HBoxContainer.new()
		var k := UI3.label(r[0], "LabelMuted")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k)
		row.add_child(UI3.label(r[1]))
		col.add_child(row)
	return card


# ============================================================================ E · toast

static func show_toast(layer: CanvasLayer, code: String) -> Control:
	var service: Node = layer.get_parent()
	for c in layer.get_children():
		if c.name == "AccountToast":
			c.queue_free()
	var holder := Control.new()
	holder.name = "AccountToast"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)

	var warn := code in ["session_expired", "save_failed", "sign_out_failed"]
	var panel := UI3.plate(&"notice")
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.custom_minimum_size = Vector2(TOAST_W, 0)
	panel.offset_left = -TOAST_W / 2.0
	panel.offset_right = TOAST_W / 2.0
	panel.offset_bottom = -UI3Theme.space("24")
	holder.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	panel.add_child(row)
	# Status dot, then the message in words (red only for a real failure of sign-in).
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.color = UI3Theme.color("accent") if warn else UI3Theme.color("danger")
	row.add_child(dot)
	var msg := _prose(AccountServiceScript.error_message(code))
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(msg)

	var actions: Array = []
	match code:
		"access_denied", "network":
			actions = [["Try again" if code == "access_denied" else "Retry", true,
					func() -> void: service.sign_in()],
				["Continue without signing in", false, func() -> void: service.play_as_guest()]]
		"admin_policy_enforced", "org_internal":
			actions = [["Use another account", true, func() -> void: service.sign_in(true)]]
		"session_expired":
			actions = [["Sign in", true, func() -> void: service.sign_in()]]
		"save_failed":
			actions = [["Sync now", false, func() -> void: service.sync_now()]]
		"sign_out_failed":
			actions = []
		_:
			actions = [["Try again", true, func() -> void: service.sign_in()]]
	for a in actions:
		var b := UI3.button(a[0], &"primary" if a[1] else &"secondary", &"M")
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var act: Callable = a[2]
		b.pressed.connect(func() -> void:
			holder.queue_free()
			act.call())
		row.add_child(b)

	var timer := holder.get_tree().create_timer(TOAST_SECONDS)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(holder):
			holder.queue_free())
	return holder


# ============================================================================ helpers

static func ago(unix: int) -> String:
	var d := int(Time.get_unix_time_from_system()) - unix
	if d < 60:
		return "just now"
	if d < 3600:
		return "%d minute%s ago" % [d / 60, "" if d / 60 == 1 else "s"]
	if d < 86400:
		return "%d hour%s ago" % [d / 3600, "" if d / 3600 == 1 else "s"]
	return "%d day%s ago" % [d / 86400, "" if d / 86400 == 1 else "s"]


static func _overlay(layer: CanvasLayer) -> Control:
	var overlay := Control.new()
	overlay.name = "AccountOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI3Theme.get_theme()
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = UI3Theme.color("scrim")
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(scrim)
	layer.add_child(overlay)
	return overlay


static func _modal(overlay: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel := UI3.plate(&"dialog")
	panel.name = "Dialog"
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI3Theme.space("16"))
	panel.add_child(box)
	return box


## Wrapped body text. `variation` "" = body, "LabelMuted" = muted. (The chip below still uses _chip_prose.)
static func _prose(text: String, variation := "") -> Label:
	var l := UI3.label(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func _chip_prose(text: String, size: int, color: Color) -> Label:
	var l := DangoTheme.prose_label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func _button(text: String, primary: bool, height: float) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	DangoTheme.style_button(b, primary)
	return b


static func _gap(node: Control, top: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", top)
	m.add_child(node)
	return m
