class_name AccountUI
extends RefCounted
## The account surfaces from the approved mock (claude/ACCOUNT_SYSTEM_v1.md §7,
## account_ui_mock_v1.html): A welcome panel, B account chip, D save-choice dialog, E toasts.
## Settings → Account (C) lives in SettingsView and uses the same service calls.
##
## Interim styling (Liam, 10 Oct 2026: "dùng tạm", full UI polish comes last). Everything goes
## through DangoTheme surfaces, buttons and labels so the polish pass only has numbers to change.

const WELCOME_W := 760.0
const CHOICE_W := 980.0
const MOVE_W := 760.0
const TOAST_W := 860.0
const TOAST_SECONDS := 10.0


# ============================================================================ A · welcome

static func show_welcome(layer: CanvasLayer) -> Control:
	var service: Node = layer.get_parent()
	var overlay := _overlay(layer)
	overlay.name = "AccountWelcome"
	var box := _modal(overlay, WELCOME_W)

	box.add_child(_eyebrow("ACCOUNT"))
	box.add_child(DangoTheme.display_label("Save your progress", 40))
	box.add_child(_prose("Sign in with Google to keep your Axies, shards and runs on any device. "
		+ "Your Sky Mavis work account works too. No new registration needed.", 18,
		DangoTheme.TEXT_DIM))

	var perks := HBoxContainer.new()
	perks.add_theme_constant_override("separation", 12)
	for p in [["Vault", "your imported Axies"], ["Shards & Pass", "every unlock you earned"],
			["Continue", "pick up a run on another device"]]:
		var well := PanelContainer.new()
		well.add_theme_stylebox_override("panel",
			DangoTheme.surface_style(DangoTheme.Surface.WELL, 12, 3, 0.0, Vector2(12, 12)))
		well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var t := DangoTheme.display_label(p[0], 22, DangoTheme.CREAM)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t)
		var c := _prose(p[1], 14, DangoTheme.TEXT_DIM)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(c)
		well.add_child(col)
		perks.add_child(well)
	box.add_child(_gap(perks, 8))

	var google := _button("CONTINUE WITH GOOGLE", true, 64)
	google.name = "ContinueWithGoogle"
	google.pressed.connect(func() -> void:
		overlay.queue_free()
		service.sign_in())
	box.add_child(_gap(google, 8))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var hint := _prose("No Google account? You can create one on the next screen.", 14,
		DangoTheme.TEXT_DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)
	var guest := _button("PLAY AS GUEST", false, 44)
	guest.name = "PlayAsGuest"
	guest.pressed.connect(func() -> void:
		overlay.queue_free()
		service.play_as_guest())
	row.add_child(guest)
	box.add_child(row)
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
	var lbl := _prose(line[0], 13, DangoTheme.TEXT_DIM if signed_in else DangoTheme.PRIMARY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(lbl)
	col.add_child(st)
	row.add_child(col)


## [text, dot colour] for the service's current status.
static func status_line(service: Node) -> Array:
	var st := int(service.status)
	if st == AccountServiceScript.Status.SAVED:
		return ["Saved", DangoTheme.SUCCESS]
	if st == AccountServiceScript.Status.SAVING:
		return ["Saving…", DangoTheme.PRIMARY]
	if st == AccountServiceScript.Status.CHECKING:
		return ["Checking…", DangoTheme.PRIMARY]
	if st == AccountServiceScript.Status.OFFLINE:
		return ["Offline — will sync", DangoTheme.DANGER]
	if st == AccountServiceScript.Status.EXPIRED:
		return ["Signed out — sign in to save", DangoTheme.DANGER]
	return ["Sign in to save", DangoTheme.PRIMARY]


static func sky_mavis_badge() -> PanelContainer:
	var b := PanelContainer.new()
	b.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(DangoTheme.SHIELD_BLUE, 6, 2))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := DangoTheme.display_label("SKY MAVIS", 11, DangoTheme.INK_ON_SHIELD)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	return b


# ============================================================================ D · choice

## kind: "move" (account empty, guest save here), "choose" (both have a save, first sign-in on
## this device) or "conflict" (the account moved on elsewhere since this device last synced).
## done(choice) gets "move"/"fresh" or "local"/"cloud". The dialog cannot be dismissed without
## choosing — the whole point is that nothing is decided for the player.
static func show_choice(layer: CanvasLayer, kind: String, info: Dictionary, done: Callable) -> Control:
	var overlay := _overlay(layer)
	var box := _modal(overlay, MOVE_W if kind == "move" else CHOICE_W)
	box.add_child(_eyebrow("CHOOSE A SAVE"))

	if kind == "move":
		box.add_child(DangoTheme.display_label("Move your guest progress?", 40))
		box.add_child(_prose("This browser has progress from playing as a guest, and your account "
			+ "is empty. Move it to your account to keep it on every device.", 18,
			DangoTheme.TEXT_DIM))
		box.add_child(_gap(_save_card("This device (guest)", "", info.get("local", {})), 8))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var move := _button("MOVE PROGRESS", true, 56)
		move.name = "MoveProgress"
		move.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		move.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("move"))
		var fresh := _button("START FRESH", false, 56)
		fresh.name = "StartFresh"
		fresh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fresh.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("fresh"))
		row.add_child(move)
		row.add_child(fresh)
		box.add_child(_gap(row, 8))
		return overlay

	var title := "This device has guest progress" if kind == "choose" \
		else "This account was played somewhere else"
	var body := ("Your account already has a save. Pick the one to keep on your account. The "
		+ "other one stays on this device for %d days in case you change your mind.") if kind == "choose" \
		else ("This device and your account both changed since they last matched. Pick the one "
		+ "to keep. The other one stays on this device for %d days in case you change your mind.")
	box.add_child(DangoTheme.display_label(title, 40))
	box.add_child(_prose(body % AccountServiceScript.BACKUP_DAYS, 18, DangoTheme.TEXT_DIM))

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	var local_title := "This device (guest)" if kind == "choose" else "This device"
	var cloud: Dictionary = info.get("cloud", {})
	var cloud_when := ""
	if int(cloud.get("updated_at", 0)) > 0:
		cloud_when = "Saved " + ago(int(cloud["updated_at"]))
	# Both cards carry a "when" line so they are the same height and the two buttons line up.
	for side in [["local", local_title, "On this browser", "KEEP THIS DEVICE", true],
			["cloud", "Cloud (your account)", cloud_when, "KEEP CLOUD", false]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(_save_card(side[1], side[2], info.get(side[0], {})))
		var b := _button(side[3], side[4], 52)
		b.name = "Keep" + String(side[0]).capitalize()
		var choice: String = side[0]
		b.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call(choice))
		col.add_child(b)
		cards.add_child(col)
	box.add_child(_gap(cards, 8))
	return overlay


static func _save_card(title: String, when: String, s: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM, 14, 3, 4.0, Vector2(18, 14)))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	col.add_child(DangoTheme.display_label(title, 22, DangoTheme.INK))
	if not when.is_empty():
		col.add_child(_prose(when, 13, DangoTheme.INK_ON_CREAM_MUTED))
	for r in [["Gene shards", str(int(s.get("shards", 0)))],
			["XP", str(int(s.get("xp", 0)))],
			["Vault", "%d / 20" % int(s.get("vault", 0))],
			["Runs · wins", "%d · %d" % [int(s.get("runs", 0)), int(s.get("wins", 0))]],
			["Run in progress", String(s.get("run", "")) if not String(s.get("run", "")).is_empty() else "—"]]:
		var row := HBoxContainer.new()
		var k := _prose(r[0], 15, DangoTheme.INK_ON_CREAM_MUTED)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k)
		row.add_child(DangoTheme.display_label(r[1], 20, DangoTheme.INK))
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

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 12, 3, 6.0, Vector2(3, 3)))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.custom_minimum_size = Vector2(TOAST_W, 0)
	panel.offset_left = -TOAST_W / 2.0
	panel.offset_right = TOAST_W / 2.0
	panel.offset_bottom = -(DangoScreen.SAFE + DangoScreen.FOOTER_H + 24.0)
	holder.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var warn := code in ["session_expired", "save_failed", "sign_out_failed"]
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(8, 0)
	bar.color = DangoTheme.PRIMARY if warn else DangoTheme.DANGER
	row.add_child(bar)
	var msg := _prose(AccountServiceScript.error_message(code), 16, DangoTheme.TEXT)
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var msg_box := MarginContainer.new()
	msg_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_box.add_theme_constant_override("margin_top", 14)
	msg_box.add_theme_constant_override("margin_bottom", 14)
	msg_box.add_child(msg)
	row.add_child(msg_box)

	var actions: Array = []
	match code:
		"access_denied", "network":
			actions = [["TRY AGAIN" if code == "access_denied" else "RETRY", true,
					func() -> void: service.sign_in()],
				["PLAY AS GUEST", false, func() -> void: service.play_as_guest()]]
		"admin_policy_enforced", "org_internal":
			actions = [["USE ANOTHER ACCOUNT", true, func() -> void: service.sign_in(true)]]
		"session_expired":
			actions = [["SIGN IN", true, func() -> void: service.sign_in()]]
		"save_failed":
			actions = [["SYNC NOW", false, func() -> void: service.sync_now()]]
		"sign_out_failed":
			actions = []
		_:
			actions = [["TRY AGAIN", true, func() -> void: service.sign_in()]]
	for a in actions:
		var b := _button(a[0], a[1], 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var act: Callable = a[2]
		b.pressed.connect(func() -> void:
			holder.queue_free()
			act.call())
		row.add_child(b)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(4, 0)
	row.add_child(pad)

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
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(DangoTheme.SCRIM_INK, 0.82)
	overlay.add_child(scrim)
	layer.add_child(overlay)
	return overlay


static func _modal(overlay: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 18, 3, 8.0, Vector2(32, 28)))
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


static func _eyebrow(text: String) -> Label:
	return DangoTheme.display_label(text, 13, DangoTheme.PRIMARY, 800, 0.18)


static func _prose(text: String, size: int, color: Color) -> Label:
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
