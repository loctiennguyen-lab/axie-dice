class_name AccountUI
extends RefCounted
## The account surfaces from the approved mock (claude/ACCOUNT_SYSTEM_v1.md §7,
## account_ui_mock_v1.html): A welcome panel, B account chip, D save-choice dialog, E toasts.
## Settings → Account (C) lives in SettingsView and uses the same service calls.
##
## UI-03: welcome, desktop sign-in, save choice and toasts are on UI3 (round-2 screens 16 and 26).
## The account chip (B) is on UI3 tokens too (AccountChip, round-2 components.md).

const TOAST_SECONDS := 10.0
const Parts := preload("res://scenes/account/ui5/AccountParts.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


# ============================================================================ A · welcome

## UI-05 a14: WelcomePanel on the scrim over the Land. SkyMavisTag, three Points, GoogleButton (the one primary),
## GuestButton (quiet). Same service calls as before: sign_in() / play_as_guest(), overlay freed first.
static func show_welcome(layer: CanvasLayer) -> Control:
	var service: Node = layer.get_parent()
	var overlay := _overlay(layer)
	overlay.name = "AccountWelcome"
	var box: VBoxContainer = Parts.centered(overlay, "WelcomePanel", "welcome")["col"]

	var tag := UI3Meta.tag("SKY MAVIS")
	tag.name = "SkyMavisTag"
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(tag)
	var title := Ui5Text.label("Save your progress", "text_banner", "text", true)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	box.add_child(Parts.body("Sign in with Google to keep your Axies, Shards and runs on any device. "
		+ "Your Sky Mavis work account works too. No new registration needed.", false, "Body"))

	var perks := HBoxContainer.new()
	perks.name = "Points"
	perks.add_theme_constant_override("separation", UI3Theme.space("12"))
	for p in [["Vault", "your imported Axies"], ["Shards & Pass", "every unlock you earned"],
			["Continue", "pick up a run on another device"]]:
		perks.add_child(Parts.point(p[0], p[1]), true)
	box.add_child(perks)

	var google := Parts.btn("GoogleButton", "Continue with Google", &"primary", &"L", true)
	google.pressed.connect(func() -> void:
		overlay.queue_free()
		service.sign_in())
	box.add_child(google)

	var hint := Parts.body("No Google account? You can create one on the next screen.", true, "Hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var guest := UI3.button("Continue without signing in", &"quiet", &"S")
	guest.name = "GuestButton"
	guest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	guest.pressed.connect(func() -> void:
		overlay.queue_free()
		service.play_as_guest())
	box.add_child(guest)
	google.call_deferred("grab_focus")
	return overlay


## UI-05 a13: BootOfflineGate. The game cannot open without the server: one primary (TryAgainButton), no way around it.
static func show_offline_gate(layer: CanvasLayer, service: Node) -> Control:
	var overlay := _overlay(layer)
	overlay.name = "OnlineGate"
	var gate: Dictionary = Parts.box("BootOfflineGate")   # .acct: radius l, pad 32, gap 16, account_w
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.add_child(gate["panel"])
	var box := gate["col"] as VBoxContainer
	box.add_child(Parts.brand(Parts.version_text()))
	box.add_child(Parts.banner("Can't reach the game server", &"warn", "Title"))
	box.add_child(Parts.body("Axie Dice needs an internet connection for every mode. Check your connection and try again. "
		+ "Nothing is lost: your progress is kept on the server.", false, "Body"))
	var retry := Parts.btn("TryAgainButton", "Try again", &"primary", &"L", true)
	retry.pressed.connect(func() -> void: service.check())
	box.add_child(retry)
	retry.call_deferred("grab_focus")
	return overlay


# ============================================================================ desktop browser flow

## Overlay for the desktop sign-in, shown over whatever screen started it. It only mirrors
## `service.desktop_phase` ("waiting" | "finishing" | "signed_in" | "error") and calls the service;
## it frees itself when the phase goes back to "idle". "signed_in" shows the name, then dismisses.
static func show_desktop_flow(layer: CanvasLayer, service: Node, auto_dismiss_s: float = 1.6) -> Control:
	var overlay := _overlay(layer)
	overlay.name = "DesktopSignInFlow"
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var dlg: Dictionary = Parts.box("DesktopSignIn", true)   # .dialog.s: radius xl, pad 32, gap 20, modal_s_w
	center.add_child(dlg["panel"])
	var box := dlg["col"] as VBoxContainer
	var dismissed := [false]
	var refresh := Callable()
	refresh = func() -> void:
		if not is_instance_valid(overlay):
			return
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
		var phase := String(service.get("desktop_phase"))
		var focus: Button = null
		match phase:
			"waiting":
				box.add_child(Parts.banner("Waiting for the browser…", &"", "Title"))
				box.add_child(Parts.body("Finish signing in in your browser. Then come back here; the game picks it up by itself.", false, "Body"))
				var again := Parts.btn("OpenBrowserButton", "Open browser again", &"primary", &"L", true)
				again.pressed.connect(func() -> void: service.reopen_desktop_browser())
				box.add_child(again)
				var cancel := Parts.btn("CancelButton", "Cancel")
				cancel.pressed.connect(func() -> void: service.cancel_desktop_sign_in())
				box.add_child(cancel)
				focus = again
			"finishing":
				box.add_child(Parts.banner("Signing you in…", &"", "Title"))
				box.add_child(Parts.body("Google said yes. Checking your account.", false, "Body"))
				var sp := Ui5Spinner.new()
				sp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				box.add_child(sp)
			"signed_in":
				box.add_child(Parts.banner("Signed in as %s" % String(service.display_name()), &"ok", "Title"))
				var go := Parts.btn("ContinueButton", "Continue", &"primary", &"L", true)
				go.pressed.connect(func() -> void: service.dismiss_desktop_result())
				box.add_child(go)
				_space_cap(go)
				focus = go
				if auto_dismiss_s > 0.0 and not dismissed[0] and overlay.is_inside_tree():
					dismissed[0] = true
					overlay.get_tree().create_timer(auto_dismiss_s).timeout.connect(func() -> void:
						if is_instance_valid(service):
							service.dismiss_desktop_result())
			"error":
				var copy: Array = AccountScreen.error_copy(String(service.get("desktop_error")))
				box.add_child(Parts.banner(String(copy[0]), &"error", "Title"))
				box.add_child(Parts.body(String(copy[1]), false, "Body"))
				var retry := Parts.btn("TryAgainButton", String(copy[2]), &"primary", &"L", true)
				retry.pressed.connect(func() -> void:
					service.clear_desktop_error()
					service.sign_in())
				box.add_child(retry)
				var close := Parts.btn("CloseButton", "Close")
				close.pressed.connect(func() -> void: service.clear_desktop_error())
				box.add_child(close)
				focus = retry
			_:
				overlay.queue_free()
		if focus != null:
			focus.grab_focus.call_deferred()
	service.changed.connect(refresh)
	overlay.tree_exiting.connect(func() -> void:
		if is_instance_valid(service) and service.changed.is_connected(refresh):
			service.changed.disconnect(refresh))
	refresh.call()
	return overlay


## Space keycap trailing the label of the primary button (as RunPauseMenu): pins the variation's styles as overrides,
## then HudStyle.place_trailing once the button is in the tree and again on every resize.
static func _space_cap(b: Button) -> void:
	var cap := Ui5Keycap.make("Space", &"primary")
	b.add_child(cap)
	var pad := UI3Theme.space("32")
	var place := func() -> void:
		if not is_instance_valid(b) or not b.is_inside_tree():
			return
		if not b.has_meta("styles_pinned"):
			b.set_meta("styles_pinned", true)
			for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
				var src: StyleBox = UI3Theme.get_theme().get_stylebox(st, b.theme_type_variation)
				if src != null:
					b.add_theme_stylebox_override(st, src.duplicate())
		Ui5HudStyle.place_trailing(b, cap, pad)
	b.resized.connect(place)
	place.call_deferred()


# ============================================================================ B · chip

## A button showing who is signed in and whether the save is in the cloud. It rebuilds itself
## whenever the service changes, and frees its connection when it leaves the tree.
static func build_chip(service: Node, on_open_settings: Callable) -> Button:
	var btn := Button.new()
	btn.name = "AccountChip"
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for key in ["normal", "hover", "pressed"]:
		var bg := UI3Theme.color("panel_raised") if key == "hover" else UI3Theme.color("panel")
		btn.add_theme_stylebox_override(key, UI3Theme.flat(bg, UI3Theme.radius("m")))
	btn.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("m")))
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
		_fit_chip.call_deferred(btn, row)   # label sizes (theme fonts) exist only once in the tree
	refresh.call()
	btn.tree_entered.connect(func() -> void: _fit_chip.call_deferred(btn, row))
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


static func _fit_chip(btn: Button, row: HBoxContainer) -> void:
	if not is_instance_valid(btn) or not is_instance_valid(row):
		return
	btn.custom_minimum_size.x = 0
	btn.custom_minimum_size.x = row.get_combined_minimum_size().x + 24


static func _fill_chip(row: HBoxContainer, service: Node) -> void:
	var signed_in: bool = service.is_signed_in()
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := UI3Theme.color("panel_raised")
	# Amber 3 px ring only when the save is synced (signed in); a plain neutral ring for guests.
	var ring := UI3Theme.color("accent") if signed_in else UI3Theme.color("disabled_border")
	avatar.add_theme_stylebox_override("panel", UI3Theme.flat(fill, 24, 3, ring))
	var initial := UI3.label(String(service.display_name()).left(1).to_upper() if signed_in else "?", "LabelTitle")
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
	var nm := UI3.label(service.display_name() if signed_in else "Guest", "LabelTitle")
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
	var lbl := UI3.label(line[0], "LabelMuted" if signed_in else "")
	if not signed_in:
		lbl.add_theme_color_override("font_color", UI3Theme.color("accent"))
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
## choosing: the whole point is that nothing is decided for the player.
## UI-05 a15/a16: MoveGuestProgress (Start fresh, Move progress with Space and focus) and ChooseSave (two Ui5SaveCards,
## nothing picked, one Keep button under each; primary goes to the save with more XP, a tie keeps the cloud).
static func show_choice(layer: CanvasLayer, kind: String, info: Dictionary, done: Callable) -> Control:
	var overlay := _overlay(layer)

	if kind == "move":
		var mbox: VBoxContainer = Parts.centered(overlay, "MoveGuestProgress")["col"]
		mbox.add_child(Parts.dialog_head("Move your guest progress?", "This browser has progress from before you signed in, "
			+ "and your account is empty. Move it to your account to keep it on every device."))
		var fresh := Parts.btn("StartFreshButton", "Start fresh")
		fresh.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("fresh"))
		var move := Parts.btn("MoveButton", "Move progress", &"primary", &"M")
		move.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call("move"))
		mbox.add_child(Parts.save_card("This device (guest)", "On this browser", info.get("local", {}), move))
		mbox.add_child(Ui5ModalFooter.make(move, fresh))
		_space_cap(move)
		move.call_deferred("grab_focus")
		return overlay

	var box: VBoxContainer = Parts.centered(overlay, "ChooseSave")["col"]
	var heading := "This device has guest progress" if kind == "choose" \
		else "This account was played somewhere else"
	var body := ("Your account already has a save. Pick the one to keep on your account. The "
		+ "other one stays on this device for %d days in case you change your mind.") if kind == "choose" \
		else ("This device and your account both changed since they last matched. Pick the one "
		+ "to keep. The other one stays on this device for %d days in case you change your mind.")
	box.add_child(Parts.dialog_head("Choose a save", body % AccountServiceScript.BACKUP_DAYS, heading))

	var local_title := "This device (guest)" if kind == "choose" else "This device"
	var cloud: Dictionary = info.get("cloud", {})
	var cloud_when := ""
	if int(cloud.get("updated_at", 0)) > 0:
		cloud_when = "Saved " + ago(int(cloud["updated_at"]))
	var local_xp := int((info.get("local", {}) as Dictionary).get("xp", 0))
	var cloud_xp := int(cloud.get("xp", 0))
	var local_primary := local_xp > cloud_xp
	var cards := HBoxContainer.new()
	cards.name = "CardRow"
	cards.add_theme_constant_override("separation", UI3Theme.space("16"))
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	for side in [["local", local_title, "On this browser", "Keep this device", local_primary, "KeepLocalButton"],
			["cloud", "Cloud (your account)", cloud_when, "Keep cloud", not local_primary, "KeepCloudButton"]]:
		var b := Parts.btn(String(side[5]), String(side[3]), &"primary" if side[4] else &"secondary", &"M", true)
		var choice: String = side[0]
		b.pressed.connect(func() -> void:
			overlay.queue_free()
			done.call(choice))
		cards.add_child(Parts.save_card(side[1], side[2], info.get(side[0], {}), b), true)
		foot.add_child(b)
		# No auto-focus: either button overwrites the other save, so Enter must never pick one by itself.
	box.add_child(cards)
	box.add_child(foot)
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
	# Remote economy: Shards are the server's, the cloud save never carries them, so the row would always differ.
	var rows: Array = []
	if MetaState.econ_remote() == null:
		rows.append(["Gene Shards", str(int(s.get("shards", 0)))])
	rows.append_array([["XP", str(int(s.get("xp", 0)))],
			["Vault", "%d / 20" % int(s.get("vault", 0))],
			["Runs · wins", "%d · %d" % [int(s.get("runs", 0)), int(s.get("wins", 0))]],
			["Run in progress", String(s.get("run", "")) if not String(s.get("run", "")).is_empty() else "—"]])
	for r in rows:
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
		if c.name == "AccountToastHost":
			c.queue_free()
	var holder := Control.new()
	holder.name = "AccountToastHost"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)

	var warn := code in ["session_expired", "save_failed", "sign_out_failed"]
	var tw := float(UI3Theme.size_of("toast_max_w"))
	var st := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"),
		Vector4(UI3Theme.space("12"), UI3Theme.space("12"), UI3Theme.space("20"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink")))
	var panel := PanelParts.panel(st, "AccountToast")
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.custom_minimum_size = Vector2(tw, 0)
	panel.offset_left = -tw / 2.0
	panel.offset_right = tw / 2.0
	panel.offset_bottom = -float(UI3Theme.space("screen_margin") + UI3Theme.size_of("btn_l") + UI3Theme.space("24"))
	holder.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	panel.add_child(row)
	row.add_child(Ui5ToneDisc.make(&"warn" if warn else &"error"))
	var msg := Parts.body(AccountServiceScript.error_message(code), false, "Text")
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(msg)
	var acts := HBoxContainer.new()
	acts.name = "Acts"
	acts.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.add_child(acts)

	var actions: Array = []
	match code:
		"access_denied", "network":
			actions = [["Try again" if code == "access_denied" else "Retry", true,
					func() -> void: service.sign_in(), "TryAgainButton" if code == "access_denied" else "RetryButton"],
				["Continue without signing in", false, func() -> void: service.play_as_guest(), "ContinueWithoutSigningInButton"]]
		"admin_policy_enforced", "org_internal":
			actions = [["Use another account", true, func() -> void: service.sign_in(true), "UseAnotherButton"]]
		"session_expired":
			actions = [["Sign in", true, func() -> void: service.sign_in(), "SignInButton"]]
		"save_failed":
			actions = [["Sync now", false, func() -> void: service.sync_now(), "SyncNowButton"]]
		"sign_out_failed":
			actions = []
		_:
			actions = [["Try again", true, func() -> void: service.sign_in(), "TryAgainButton"]]
	for a in actions:
		var b := Parts.btn(String(a[3]), String(a[0]), &"secondary", &"S")   # a17/a18: every toast action is secondary
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var act: Callable = a[2]
		b.pressed.connect(func() -> void:
			holder.queue_free()
			act.call())
		acts.add_child(b)

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


## Wrapped body text. `variation` "" = body, "LabelMuted" = muted.
static func _prose(text: String, variation := "") -> Label:
	var l := UI3.label(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func _gap(node: Control, top: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", top)
	m.add_child(node)
	return m
