class_name LandHud
extends RefCounted
## Land hub HUD pieces moved out of Land.gd (UI-05 b23 lane 0c): Run plate + "Start here" coach, offline banner,
## toast stack and the confirm dialog. Code only moved: every piece of state still lives on the LandHub (`_l`),
## and LandHub keeps same-name forwarders for everything tests and tools call.

const Plates := preload("res://scenes/land/ui5/LandPlates.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Over := preload("res://scenes/land/ui5/LandOverlays.gd")

var _l: Node3D   # the LandHub
var _tip: PanelContainer
var _tip_owner: Control
var _tip_gen := 0


func _init(land: Node3D) -> void:
	_l = land


## Primary "Start run" (guest on the server build: "Sign in to play"). Name stays RunPlate.
func build_run_button() -> Button:
	var title := "Start run"
	var tip := "Your first run" if _l._first else "Run Setup"
	if _l._has_run:
		if _l._mission_run:
			title = "Continue mission"
			tip = mission_line()
		else:
			title = "Continue run"
			tip = continue_line()
	elif _l._guest_blocked():
		title = "Sign in to play"
		tip = "Dice are rolled on the server, so runs need an account"
	var state := "start"
	if _l._has_run:
		state = "continue_mission" if _l._mission_run else "continue_run"
	elif _l._guest_blocked():
		state = "sign_in"
	var plate := UI3.button(title, &"primary", &"L")
	plate.name = "RunPlate"
	plate.custom_minimum_size.x = 320   # frame: RunPlate min-width 320 (213 at 1280 is the canvas scale)
	plate.tooltip_text = tip
	plate.pressed.connect(_l._on_run_pressed)
	Plates.attach_space_cap(plate, UI3Theme.space("32"))
	if _l._loading:
		state = "loading"
		Ui5DisabledReason.apply(plate, "Loading…")
	elif _l._offline and not _l._has_run and not _l._guest_blocked():   # round 2: a new run needs a connection
		state = "offline"
		Ui5DisabledReason.apply(plate, "Start run · needs connection")
	plate.set_meta("state", state)
	if _l._first and not _l._has_run:
		plate.grab_focus.call_deferred()
	# "Start here" coach card (640 wide, 32x20 arrow toward the Start run spotlight).
	var hint := Over.coach("Start here", "Pick a mode and play your first run", func() -> float:
		return float(UI3Theme.size_of("coach_w")) - plate.size.x * 0.5)
	_l._start_hint = hint
	Over.spotlight(plate, UI3Theme.radius("m"))
	hint.visible = _l._first and not _l._has_run and not _l._guest
	_l._ui.add_child(hint)
	return plate


## Whole HUD (frame 01-land): TopLeft{ProfilePlate, LandPlate}, CurrencyPlate(+SettingsButton), LinksPlate, RunRow.
## State stays on the LandHub (`_l._hud_tl`, `_wallet`, `_hud_bl`, `_hud_br`, `_daily_btn`, ...).
func build_hud() -> void:
	var gap12 := UI3Theme.space("12")
	var tl := VBoxContainer.new()
	tl.name = "TopLeft"
	tl.theme = UI3Theme.get_theme()
	tl.add_theme_constant_override("separation", gap12)
	_l._hud_tl = tl
	_l._ui.add_child(tl)
	var guest: bool = _l._guest
	var pname := "Guest"
	var sub := "Sign in to save online"
	if not guest:
		pname = AccountService.display_name() if AccountService.is_signed_in() else "Player"
		sub = _l._best_line()
		if MetaState.equipped_title != "":
			sub = TitleNames.display(MetaState.equipped_title)
	tl.add_child(Plates.profile_plate(guest, pname, sub, MetaState.equipped_frame, _l._open_profile))
	tl.add_child(land_plate())

	# CurrencyPlate: three amounts (hidden when signed out) + SettingsButton.
	var st := UI3.icon_button("ui_settings", "Settings")
	st.name = "SettingsButton"
	st.pressed.connect(_l._open_screen.bind(&"settings"))
	var vals := {}
	if not _l._loading:
		vals = {"shard": MetaState.shard_pool, "stone": MetaState.stone, "gem": MetaState.gem_wallet().balance()}
	var cp := Ui5CurrencyPlate.make(vals, st)
	_l._wallet = cp
	_l._currencies = null
	# frame 01-land names the cells ShardValue / StoneValue / GemValue (the components sheet says Currency*).
	for pair in [["CurrencyShard", "ShardValue"], ["CurrencyStone", "StoneValue"], ["CurrencyGem", "GemValue"]]:
		var cell := cp.find_child(pair[0], true, false) as Control
		cell.name = pair[1]
		cell.visible = not guest
	_l._ui.add_child(cp)

	# LinksPlate: Codex / Edit Land / Raid cells + Moon Card (no key hints: only Space is printed).
	var lp := PanelParts.panel(Plates.box("l", Vector4.ONE * UI3Theme.space("8")), "LinksPlate")
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	lp.add_child(row)
	var cx := Plates.cell_button("CodexButton", "Codex", _l._on_rail_pressed.bind(&"codex"))
	cx.tooltip_text = "Codex · %s" % KeyBindings.text(&"land_codex")
	row.add_child(cx)
	row.add_child(Plates.cell_button("EditLandButton", "Edit Land", _l._on_edit_pressed))
	# Raid R1: fight another player's defence team (online only; the screen explains why when it can't).
	row.add_child(Plates.cell_button("RaidButton", "Raid", _l._on_rail_pressed.bind(&"raid")))
	var moon := UI3.button("Moon Card · Coming soon", &"secondary", &"S")
	moon.name = "MoonCardButton"
	moon.disabled = true
	moon.visible = not guest
	_l._moon_btn = moon
	row.add_child(moon)
	_l._hud_bl = lp
	_l._ui.add_child(lp)

	# RunRow: New run, Daily, RunPlate (right aligned).
	var rr := HBoxContainer.new()
	rr.name = "RunRow"
	rr.theme = UI3Theme.get_theme()
	rr.add_theme_constant_override("separation", UI3Theme.space("16"))
	rr.alignment = BoxContainer.ALIGNMENT_END
	_l._hud_br = rr
	_l._ui.add_child(rr)
	var nb := UI3.button("New run", &"secondary", &"M")
	nb.name = "NewRunButton"
	nb.tooltip_text = "New run · %s" % KeyBindings.text(&"land_new_run")
	nb.pressed.connect(_l._on_new_run_pressed)
	nb.visible = _l._has_run
	_l._new_run_btn = nb
	rr.add_child(nb)
	var db := UI3.button("Daily run", &"secondary", &"M")
	db.name = "DailyButton"
	db.pressed.connect(_l._on_rail_pressed.bind(&"daily"))
	if _l._block_reason_screen(&"daily") != "":
		UI3.set_disabled_reason(db, "Daily run · needs connection")
	elif _l._tag("daily") == "CLAIM":
		db.text = "Daily run · claim"
	db.visible = not (_l._first and not _l._has_run) and not guest   # first visit / signed out: Daily hidden
	_l._daily_btn = db
	rr.add_child(db)
	_l._load_daily_tries()
	_l._run_plate = _l._build_run_button()
	rr.add_child(_l._run_plate)
	_l._run_plate.minimum_size_changed.connect(_l._layout, CONNECT_DEFERRED)   # the keycap widens the plate: re-place the row


## LandPlate: "Upgrade Land · Forest 2/6 · Stone a/b · n to Next" (secondary S button), or the max-tier plate.
func land_plate() -> Control:
	var tn: String = _l.TIER_NAMES[_l._tier - 1]
	if _l._tier >= 6:
		return Plates.max_plate("%s Land · max tier" % tn)
	var need: int = _l._upgrade_cost()
	var have: int = _l._meta_int("stone")
	var txt := "Upgrade Land · %s %d/6 · Stone ···" % [tn, _l._tier]
	var tip := ""
	if not _l._loading:
		var can_up := preload("res://scripts/meta/economy_db.gd").land_upgrade_enabled() and have >= need
		txt = "Upgrade Land · %s %d/6 · Stone %s/%s" % [tn, _l._tier, UI3.fmt(mini(have, need)), UI3.fmt(need)]
		txt += " · ready" if can_up else " · %s to %s" % [UI3.fmt(maxi(need - have, 0)), _l.TIER_NAMES[_l._tier]]
		tip = "%s / %s Land Stone · L" % [UI3.fmt(have), UI3.fmt(need)]
	else:
		txt = "Upgrade Land · ···"
	var btn := UI3.button(txt, &"secondary", &"S")
	btn.name = "LandPlate"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.tooltip_text = tip
	btn.pressed.connect(_l._on_land_pressed)
	return btn


## Tier-up banner (frame 01-land--tier-up): UI3.modal with Title, Body, NewList (one NewRow per unlock) and a
## LookAroundButton carrying the Space keycap. Once per tier (the caller checks).
func show_tier_banner() -> void:
	var tier: int = _l._tier
	var ok := UI3.button("Look around", &"primary")
	ok.name = "LookAroundButton"
	ok.pressed.connect(_l._close_modal)
	var body := "%s is open." % _l.TIER_NAMES[tier - 1]
	var used: int = maxi(preload("res://scripts/meta/economy_db.gd").land_tier_cost(tier - 1), 0)
	if used > 0:
		body += " Used %s Stone." % UI3.fmt(used)
	var m := UI3.modal("Your Land is now %s" % _l.TIER_NAMES[tier - 1], body, [ok], 0)
	m.name = "TierUpBanner"
	m.cancelled.connect(_l._close_modal)
	var dlg := m.find_child("Dialog", true, false) as Control
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	var col := dlg.get_child(0) as VBoxContainer
	col.get_child(0).name = "Title"
	col.get_child(1).name = "Body"
	var where := String(LandUpgradeScreen.ADDS_WHERE.get(tier, ""))
	if where != "":
		var list := VBoxContainer.new()
		list.name = "NewList"
		list.add_theme_constant_override("separation", UI3Theme.space("8"))
		for item in where.split(" · "):
			var r := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("s"), 0, Color.TRANSPARENT,
				Vector4(UI3Theme.space("16"), UI3Theme.space("8"), UI3Theme.space("16"), UI3Theme.space("8"))), "NewRow")
			r.add_child(PanelParts.text(item, "text_body", "text"))
			list.add_child(r)
		col.add_child(list)
		col.move_child(list, 2)
	var foot := col.get_child(col.get_child_count() - 1)
	foot.name = "Footer"
	Plates.attach_space_cap(ok, UI3Theme.space("32"))
	_l._modal = m
	_l._ui.add_child(m)


# ---- BuildingTooltip (frame 01-land--tooltip-building / -lock): plate to the right of the building, Title + Status
# (bold lead word + rest) or LockReason. Replaces the generic UI3Tooltip on the Land hit boxes.

## Stores each hit's tip text (meta "ui3_tip", read back by UI3Tooltip.text_of) and wires hover/focus once.
func bind_tips() -> void:
	for id in _l._hits:
		_bind_tip(_l._hits[id] as Control, String(id))
	for id in _l._plot_marks:
		_bind_tip(_l._plot_marks[id] as Control, String(id))
	_l._layout()


func _bind_tip(c: Control, id: String) -> void:
	c.tooltip_text = ""
	c.set_meta("ui3_tip", _l._tip_text(id))
	c.set_meta("land_tip_id", id)
	if c.has_meta("land_tip_bound"):
		return
	c.set_meta("land_tip_bound", true)
	c.mouse_entered.connect(_arm_tip.bind(c))
	c.mouse_exited.connect(tip_hide.bind(c))
	c.focus_entered.connect(tip_show_now.bind(c))
	c.focus_exited.connect(tip_hide.bind(c))
	c.tree_exiting.connect(tip_hide.bind(c))


func _arm_tip(c: Control) -> void:
	if not c.is_inside_tree():
		return
	_tip_gen += 1
	var mine := _tip_gen
	await c.get_tree().create_timer(UI3Theme.motion_sec("tooltip_delay_ms")).timeout
	if mine == _tip_gen and is_instance_valid(c) and c.is_inside_tree() and c.get_global_rect().has_point(c.get_global_mouse_position()):
		tip_show_now(c)


func tip_hide(c: Control = null) -> void:
	_tip_gen += 1
	if c != null and _tip_owner != c:
		return
	if _tip != null and is_instance_valid(_tip):
		_tip.queue_free()
	_tip = null
	_tip_owner = null


func tip_show_now(c: Control) -> void:
	if c == null or not c.is_inside_tree() or not c.has_meta("land_tip_id") or not c.is_visible_in_tree():
		return
	if _l._modal != null or UI3Tooltip.modal_open(c.get_tree()):
		return
	tip_hide()
	var id := String(c.get_meta("land_tip_id"))
	var text := String(c.get_meta("ui3_tip", ""))
	var nl := text.find("\n")
	var head := text.substr(0, nl) if nl > 0 else text
	var rest := text.substr(nl + 1) if nl > 0 else ""
	var s4 := UI3Theme.space("4")
	var plate := PanelParts.panel(Plates.box("m", Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12"))), "BuildingTooltip")
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", s4)
	plate.add_child(v)
	# 400 design px at 18 px text; the 1280 text floor makes the text bigger, so the budget grows with it
	var maxw := float(UI3Theme.size_of("tooltip_w")) * maxf(1.0, float(UI3Theme.size_of("text_body")) / 18.0) - 2.0 * UI3Theme.space("16")
	var tl := PanelParts.text(head, "text_body", "text", true)
	tl.name = "Title"
	v.add_child(tl)
	var why: String = _l._block_reason(id)
	if why != "":
		v.add_child(Ui5DisabledReason.lock_line(why))
	elif rest != "":
		var lead: String = _l._tag_words(id)
		var st := HBoxContainer.new()
		st.name = "Status"
		st.add_theme_constant_override("separation", 0)
		var tail := rest
		if lead != "" and rest.begins_with(lead):
			var l1 := PanelParts.text(lead, "text_body", "text", true)
			l1.name = "Lead"
			st.add_child(l1)
			tail = rest.substr(lead.length())
		if tail != "":
			var l2 := PanelParts.text(tail, "text_body", "text")
			l2.name = "Rest"
			var f := l2.get_theme_font("font")
			var w := f.get_string_size(tail, HORIZONTAL_ALIGNMENT_LEFT, -1, l2.get_theme_font_size("font_size")).x + 2.0
			var lead_w := f.get_string_size(lead, HORIZONTAL_ALIGNMENT_LEFT, -1, l2.get_theme_font_size("font_size")).x if lead != "" else 0.0
			var avail := maxw - lead_w * 1.15
			if w > avail:   # only a long status wraps; a short one stays on the Title's line width
				l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l2.custom_minimum_size.x = avail
			st.add_child(l2)
		v.add_child(st)
	plate.set_meta("tip_owner_id", id)
	_tip = plate
	_tip_owner = c
	plate.modulate.a = 0.0
	_l._ui.add_child(plate)
	await _l.get_tree().process_frame
	if not is_instance_valid(plate) or _tip != plate or not is_instance_valid(c):
		return
	plate.reset_size()
	var f2: float = _l._ui_floor()
	plate.scale = Vector2(f2, f2)
	var sz := plate.get_combined_minimum_size() * f2
	var r := Rect2(c.global_position - _l._ui.global_position, c.size)
	var pos := Vector2(r.end.x + 10.0, r.position.y + 15.0)
	var m := float(UI3Theme.space("24"))
	if pos.x + sz.x > _l._ui.size.x - m:
		pos.x = r.position.x - 10.0 - sz.x
	pos.x = clampf(pos.x, m, maxf(_l._ui.size.x - sz.x - m, m))
	pos.y = clampf(pos.y, m, maxf(_l._ui.size.y - sz.y - m, m))
	plate.position = pos
	plate.modulate.a = 1.0


func continue_line() -> String:
	if not _l._has_run:
		return ""
	return "%s · Ascension %d" % [String(RunState.mode).capitalize(), int(RunState.ascension)]


func mission_line() -> String:
	var e: Dictionary = MetaState.mission_escrow
	return "Mission %s · stake %s" % [String(e.get("mission_id", "N?")).to_upper(), UI3.fmt(int(e.get("stake", 0)))]


func build_banners() -> void:
	var b: Control = Over.banner("Offline · Runs, Store, Pass, Echo Box, Daily and Leaderboard need a connection.",
		"Retry", _l._on_retry)
	_l._offline_banner = b
	b.visible = _l._offline
	_l._ui.add_child(b)


func on_retry() -> void:
	if _l._detect_offline():
		show_toast("Still offline", 1.6, &"error")
		return
	LandHub.qa.erase("offline")
	_l.get_tree().reload_current_scene()


func build_toast() -> void:
	# UI-03 18-system: the toast is rebuilt per message by show_toast (UI3.toast, top-centre 24 px down).
	_l._toast = null


func show_toast(text: String, hold: float = 1.6, tone: StringName = &"ok") -> void:
	# Stack of at most 3, top-centre, 24 px from the top, 8 px gap (UI-03 18-system).
	_l._toasts = _l._toasts.filter(func(t: Variant) -> bool: return is_instance_valid(t))
	# S4-14: one toast at a time (they stacked over the Upgrade Land chip); the rest wait their turn.
	if not _l._toasts.is_empty() and not _l._draining:
		_l._toast_queue.append([text, hold, tone])
		return
	var tw_node := Ui5Toast.make(text, tone)
	tw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_l._ui.add_child(tw_node)
	_l._toasts.append(tw_node)
	_l._toast = tw_node
	layout_toasts()
	var tw := _l.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(tw_node, "modulate:a", 0.0, UI3Motion.REDUCED_MAX_SEC if UI3Motion.reduced() else 0.4)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tw_node):
			tw_node.queue_free()
		_l._toasts.erase(tw_node)
		layout_toasts()
		if not _l._toast_queue.is_empty() and _l._toasts.is_empty() and _l.is_inside_tree():
			var nx: Array = _l._toast_queue.pop_front()
			_l._draining = true
			show_toast(String(nx[0]), float(nx[1]), nx[2])
			_l._draining = false)


func layout_toasts() -> void:
	var ban: Control = _l._offline_banner
	var up: bool = ban != null and is_instance_valid(ban) and ban.visible
	var y := float(Ui5Toast.top_y(up))
	if up:
		y = maxf(y, ban.position.y + ban.size.y * ban.scale.y + 8.0)
	for t in _l._toasts:
		if not is_instance_valid(t) or t.is_queued_for_deletion():
			continue
		var c := t as Control
		c.reset_size()
		c.position = Vector2((_l._ui.size.x - c.size.x) * 0.5, y)
		y += c.size.y + 8.0


func open_confirm(title: String, body: String, ok_text: String, on_ok: Callable, _warning: bool = false,
		cancel_text: String = "Cancel", loss: Array = [], _head: Color = Color(0, 0, 0, 0)) -> void:
	if _l._modal != null:
		return
	# Destructive (`loss` given): safe button first, carries Space and the focus; the danger button is the action.
	var destructive := loss.size() >= 2
	var abandon := title.begins_with("Abandon")
	var m := Over.dialog("Confirm", "AbandonMissionConfirm" if abandon else "NewRunConfirm", title, body, abandon and destructive)
	var col := m.get_meta("col") as VBoxContainer
	var cancel := UI3.button(cancel_text, &"secondary", &"M")
	cancel.name = "KeepPlayingButton"
	cancel.pressed.connect(_l._close_modal)
	var ok := UI3.button(ok_text, &"danger" if destructive else &"primary", &"M")
	ok.name = "AbandonButton" if abandon else "EndRunButton"
	ok.pressed.connect(on_ok)
	if destructive:
		col.add_child(Over.loss_rows(String(loss[0]), String(loss[1]), abandon))
		col.add_child(Over.confirm_footer(cancel, ok))
	else:
		col.add_child(Ui5ModalFooter.make(ok, cancel))
	m.actions = [cancel, ok]
	m.focus_index = 0 if destructive else 1
	m.cancelled.connect(_l._close_modal)
	_l._modal = m
	_l._ui.add_child(m)
	if destructive:
		Over.safe_cap(cancel)


## Beta reset notice (frame 01-land--beta-reset): one OK button with the Space cap, focused.
func reset_notice(body: String, ok: Button) -> UI3.ModalRoot:
	var m := Over.dialog("ResetNotice", "BetaResetModal", "Beta reset", body)
	ok.name = "OkButton"
	(m.get_meta("col") as VBoxContainer).add_child(Ui5ModalFooter.make(ok))
	m.actions = [ok]
	m.focus_index = 0
	Plates.attach_space_cap(ok, UI3Theme.space("32"))
	return m


func close_modal() -> void:
	if _l._modal != null:
		_l._modal.queue_free()
		_l._modal = null
