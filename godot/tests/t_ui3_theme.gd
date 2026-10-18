extends Node
## UI-03 foundation gate: tokens load, every tokens.theme entry exists in the built Theme, every
## contrast pair in tokens.contrast really meets its minimum (recomputed from the hex values, not
## trusted), and the builders return controls with the documented sizes (hit area >= 44).
## No network, no screen, no save access (SaveGuard anyway, like every gate).

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()

const MIN_CONTRAST := 4.5   # every row in tokens.contrast says "AA body"


func _ready() -> void:
	print("=== t_ui3_theme: start ===")
	_guard.capture()
	await get_tree().process_frame
	_test_tokens_load()
	_test_theme_items()
	_test_contrast()
	_test_fonts()
	await _test_builders()
	_ok(_checks >= 400, "only %d checks ran, the gate did not exercise the foundation" % _checks)
	_guard.restore()
	print("=== t_ui3_theme: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_ui3_theme: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_ui3_theme: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _test_tokens_load() -> void:
	UI3Theme.reset_cache()
	var t := UI3Theme.tokens()
	for group in ["color", "contrast", "font", "size", "radius", "space", "stroke", "shadow", "motion", "z", "theme"]:
		_ok(t.has(group), "tokens missing group '%s'" % group)
	_ok(UI3Theme.color("accent") == Color.html("#ffb444"), "accent colour")
	_ok(UI3Theme.color("plate").a < 1.0 and absf(UI3Theme.color("plate").a - 0xE6 / 255.0) < 0.01, "plate alpha is 90%")
	_ok(UI3Theme.color("scrim").a > 0.79 and UI3Theme.color("scrim").a < 0.81, "scrim alpha is 80%")
	_ok(UI3Theme.size_of("btn_l") == 72 and UI3Theme.size_of("btn_m") == 56 and UI3Theme.size_of("btn_s") == 48, "button heights")
	_ok(UI3Theme.size_of("hit_min") == 44, "hit_min is 44")
	_ok(UI3Theme.size_dict("axie_combat") == Vector2(163, 214), "axie_combat size pair")
	_ok(UI3Theme.radius("l") == 12 and UI3Theme.radius("die") == 20, "radius tokens")
	_ok(UI3Theme.space("screen_margin") == 24, "screen margin")
	_ok(UI3Theme.stroke("selected") == 4 and UI3Theme.stroke("focus") == 2 and UI3Theme.stroke("focus_offset") == 4, "stroke tokens")
	_ok(is_equal_approx(UI3Theme.motion_sec("base"), 0.2), "motion base 200 ms")
	# All colour tokens parse (no magenta fallback from a bad value).
	for k in (t["color"] as Dictionary).keys():
		_ok(UI3Theme.color(String(k)) != Color.MAGENTA, "colour '%s' parses" % k)


func _test_theme_items() -> void:
	var theme := UI3Theme.build_theme()
	var items: Dictionary = UI3Theme.tokens()["theme"]
	for key in items.keys():
		var m := UI3Theme.theme_item_for(String(key))
		_ok(not m.is_empty(), "tokens.theme '%s' has no mapping in UI3Theme.theme_item_for" % key)
		if m.is_empty():
			continue
		match m["kind"]:
			"stylebox":
				_ok(theme.has_stylebox(m["name"], m["type"]), "theme lacks stylebox %s/%s (for %s)" % [m["type"], m["name"], key])
			"font_size":
				_ok(theme.has_font_size(m["name"], m["type"]), "theme lacks font size %s/%s" % [m["type"], m["name"]])
	# Every button variant has all five states.
	for v in ["ButtonPrimaryL", "ButtonPrimaryM", "ButtonSecondary", "ButtonSecondaryS", "ButtonDanger", "ButtonQuiet", "IconButton"]:
		_ok(theme.get_type_variation_base(v) == "Button", "%s is a Button variation" % v)
		for s in ["normal", "hover", "pressed", "disabled", "focus"]:
			_ok(theme.has_stylebox(s, v), "%s lacks %s" % [v, s])
	# Panels, tabs, inputs, bars, scrollbars, tooltip.
	for v in ["PanelPlate", "PanelCard", "PanelCardSelected", "PanelDialog", "PanelRow", "PanelNotice", "PanelChip", "PanelKeyHint", "PanelInfo", "PanelToast"]:
		_ok(theme.has_stylebox("panel", v), "%s lacks panel" % v)
	for s in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled", "tab_focus"]:
		_ok(theme.has_stylebox(s, "TabBar") and theme.has_stylebox(s, "TabContainer"), "Tab lacks %s" % s)
	for s in ["normal", "read_only", "focus"]:
		_ok(theme.has_stylebox(s, "LineEdit"), "LineEdit lacks %s" % s)
	for v in ["ProgressBarHP", "ProgressBarEnemy", "ProgressBarBoss"]:
		_ok(theme.has_stylebox("fill", v) and theme.has_stylebox("background", v), "%s lacks fill/background" % v)
	for ty in ["VScrollBar", "HScrollBar"]:
		for s in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			_ok(theme.has_stylebox(s, ty), "%s lacks %s" % [ty, s])
	_ok(theme.has_stylebox("panel", "TooltipPanel") and theme.has_font_size("font_size", "TooltipLabel"), "tooltip items")
	# Spot values straight from the tokens.
	var prim := theme.get_stylebox("normal", "ButtonPrimaryL") as StyleBoxFlat
	_ok(prim.bg_color == Color.html("#ffb444") and prim.get_corner_radius(CORNER_TOP_LEFT) == 8, "primary normal fill + radius")
	_ok(prim.shadow_offset == Vector2(0, 4), "primary raised shadow 0 4")
	var prs := theme.get_stylebox("pressed", "ButtonPrimaryL") as StyleBoxFlat
	_ok(prs.shadow_offset == Vector2(0, 2), "primary pressed shadow 0 2")
	var dis := theme.get_stylebox("disabled", "ButtonPrimaryL") as StyleBoxFlat
	_ok(dis.bg_color == Color.html("#3c424d") and dis.border_width_left == 2 and dis.border_color == Color.html("#5b6372"), "disabled: neutral-4 + 2 px neutral-5")
	var foc := theme.get_stylebox("focus", "ButtonPrimaryL") as StyleBoxFlat
	_ok(foc.border_width_left == 2 and foc.border_color == Color.html("#ffb444") and foc.expand_margin_left == 4 and not foc.draw_center, "focus ring 2 px amber, 4 px offset, no fill")
	var tab_sel := theme.get_stylebox("tab_selected", "TabBar") as StyleBoxFlat
	_ok(tab_sel.border_width_top == 3 and tab_sel.border_color == Color.html("#ffe5b4"), "selected tab 3 px cream")
	var card_sel := theme.get_stylebox("panel", "PanelCardSelected") as StyleBoxFlat
	_ok(card_sel.border_width_left == 4 and card_sel.border_color == Color.html("#ffe5b4"), "selected card 4 px cream")
	_ok(theme.get_font_size("title", "Label") == 24 and theme.get_font_size("screen_title", "Label") == 32, "label named sizes")


func _test_contrast() -> void:
	var under := UI3Theme.color("viewport")
	var rows: Array = UI3Theme.tokens()["contrast"]
	_ok(rows.size() >= 30, "contrast table present (%d rows)" % rows.size())
	for r in rows:
		var ratio := UI3Theme.contrast_ratio(UI3Theme.color(r["text"]), UI3Theme.color(r["background"]), under)
		var label := "%s on %s" % [r["text"], r["background"]]
		_ok(ratio >= MIN_CONTRAST, "contrast %s = %.2f < %.1f" % [label, ratio, MIN_CONTRAST])
		_ok(absf(ratio - float(r["ratio"])) <= 0.1, "contrast %s recomputed %.2f but tokens state %.2f" % [label, ratio, float(r["ratio"])])


func _test_fonts() -> void:
	_ok(UI3Theme.fonts_are_final(), "Rowdies Bold + Work Sans Regular are present (no fallback)")
	_ok(UI3Theme.font_display() != null and UI3Theme.font_body() != null, "fonts resolve (real or fallback)")
	_ok(UI3Theme.get_theme().default_font == UI3Theme.font_body(), "theme default font is the body face")


func _test_builders() -> void:
	var host := Control.new()
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var hit := float(UI3Theme.size_of("hit_min"))

	for spec in [[&"primary", &"L", 72], [&"primary", &"M", 56], [&"secondary", &"M", 56],
			[&"secondary", &"S", 48], [&"danger", &"M", 56], [&"quiet", &"M", 44]]:
		var b := UI3.button("Go", spec[0], spec[1])
		host.add_child(b)
		_ok(b.custom_minimum_size.y == float(spec[2]), "button %s %s min h %s, got %s" % [spec[0], spec[1], spec[2], b.custom_minimum_size.y])
		_ok(b.custom_minimum_size.x >= hit, "button %s min w >= 44" % spec[0])
	var dis := UI3.button("Go", &"primary", &"M")
	UI3.set_disabled_reason(dis, "Needs 20 Shards")
	_ok(dis.disabled and dis.text == "Needs 20 Shards", "set_disabled_reason")

	var ib := UI3.icon_button("ui_settings", "Settings")
	host.add_child(ib)
	_ok(ib.custom_minimum_size == Vector2(48, 48) and ib.icon != null, "icon button 48x48 with icon")

	var chip := UI3.chip("New best")
	host.add_child(chip)
	_ok(chip.custom_minimum_size.y == 32, "chip h 32")
	var kh := UI3.key_hint("Esc")
	host.add_child(kh)
	_ok(kh.get_child_count() == 1, "key hint has a label")
	var pill := UI3.currency_pill([{"icon": "cur_gem", "value": "10"}, {"icon": "cur_shard", "value": "2"}])
	host.add_child(pill)
	_ok(pill.find_child("value_cur_gem", true, false) != null and pill.find_child("value_cur_shard", true, false) != null, "currency pill values named")

	for kind in [[&"axie", 10], [&"enemy", 8], [&"boss", 16]]:
		var bar := UI3.hp_bar(30, 40, 6, 2, kind[0])
		host.add_child(bar)
		await get_tree().process_frame
		_ok(bar.bar_height() == kind[1] and bar._track.custom_minimum_size.y == float(kind[1]), "hp bar %s height %s" % [kind[0], kind[1]])
		_ok(bar._chips.visible and bar._chips.get_child_count() == 2, "hp bar %s shows shield + poison chips" % kind[0])
	var clean := UI3.hp_bar(40, 40)
	host.add_child(clean)
	_ok(not clean._chips.visible, "no chips without shield/poison")

	for face in UI3.FACE_TYPES:
		for st in UI3.DIE_STATES:
			var d := UI3.die_tile(face, 5, &"axie", st, 3.0)
			host.add_child(d)
			var tile: Panel = d.find_child("Tile", true, false)
			_ok(tile != null and tile.size == Vector2(88, 88), "die %s/%s tile 88" % [face, st])
			_ok(tile != null and tile.size.x >= hit, "die hit >= 44")
			_ok((d.find_child("SelectedOutline", true, false) != null) == (st == &"selected"), "die %s/%s outline only when selected" % [face, st])
			if st == &"used" or st == &"disabled":
				_ok(is_equal_approx(d.modulate.a, 0.4), "die %s/%s is 40%%" % [face, st])
			if st == &"used":
				_ok((d.find_child("Word", true, false) as Label).text.ends_with("used"), "used die says used")
	# DieTile: pressed signal, Enter/Space, set_state, dead states are inert.
	var dt := UI3.die_tile(&"attack", 4)
	host.add_child(dt)
	var hits := [0]
	dt.pressed.connect(func() -> void: hits[0] += 1)
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	dt._gui_input(accept)
	_ok(hits[0] == 1, "die tile: Enter/Space emits pressed")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(48, 40)
	dt._gui_input(click)
	_ok(hits[0] == 2, "die tile: click on the tile emits pressed")
	dt.set_state(&"selected")
	_ok(dt.find_child("SelectedOutline", true, false) != null and dt.tile.position.y == -18.0, "set_state selected adds outline + lift")
	dt.set_state(&"used")
	dt._gui_input(accept)
	_ok(hits[0] == 2 and dt.focus_mode == Control.FOCUS_NONE and is_equal_approx(dt.modulate.a, 0.4), "used die is inert, unfocusable, 40%")
	var word_w := (dt.word.get_theme_font("font") as Font).get_string_size(dt.word.text, HORIZONTAL_ALIGNMENT_LEFT, -1, dt.word.get_theme_font_size("font_size")).x
	_ok(word_w <= 96.0 and not dt.word.text.contains("\n"), "used word fits one line in the cell")
	dt.set_state(&"normal")
	_ok(dt.find_child("SelectedOutline", true, false) == null and dt.focus_mode == Control.FOCUS_ALL, "set_state normal restores")

	var egg := UI3.die_tile(&"summon", 2, &"egg")
	host.add_child(egg)
	_ok((egg.find_child("Tile", true, false) as Panel).size == Vector2(56, 56), "egg die 56")
	var sel := UI3.die_tile(&"attack", 6, &"axie", &"selected", 4.0)
	host.add_child(sel)
	var seltile: Panel = sel.find_child("Tile", true, false)
	_ok(seltile.position.y == -18 and seltile.rotation_degrees == 0.0, "selected die lifts 18 and is upright")

	var ok := UI3.button("OK", &"primary")
	var cancel := UI3.button("Cancel", &"secondary")
	var m := UI3.modal("Abandon run?", "You will lose progress.", [cancel, ok], 0)
	host.add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame
	var scrim: ColorRect = m.find_child("Scrim", true, false)
	_ok(scrim != null and absf(scrim.color.a - 0.8) < 0.01 and scrim.color.is_equal_approx(UI3Theme.color("scrim")), "modal scrim neutral-1 @ 80%")
	_ok(m.mouse_filter == Control.MOUSE_FILTER_STOP, "modal blocks input behind it")
	_ok((m.find_child("Dialog", true, false) as Control).custom_minimum_size.x == 560, "modal 560 w")
	_ok(cancel.has_focus(), "modal focuses the requested action")
	var cancelled := [false]
	m.cancelled.connect(func() -> void: cancelled[0] = true)
	var tab := InputEventAction.new()
	tab.action = "ui_focus_next"
	tab.pressed = true
	m._input(tab)
	_ok(ok.has_focus(), "modal Tab moves to the next action")
	m._input(tab)
	_ok(cancel.has_focus(), "modal Tab wraps inside the dialog (focus trap)")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	m._input(esc)
	_ok(cancelled[0], "modal Esc emits cancelled")

	var t := UI3.toast("Saved")
	host.add_child(t)
	_ok(t.custom_minimum_size.y == 56, "toast h 56")
	var pressed := [false]
	var nn := UI3.net_notice("Offline", "Retry", func() -> void: pressed[0] = true)
	host.add_child(nn)
	var retry: Button = nn.find_child("Retry", true, false)
	_ok(retry != null and retry.custom_minimum_size.y == 48 and retry.custom_minimum_size.x >= hit, "net notice has Retry (secondary S)")
	if retry != null:
		retry.pressed.emit()
	_ok(pressed[0], "Retry fires the callback")
	var rc := UI3.net_notice("Reconnecting", "Retry", Callable(), true)
	host.add_child(rc)
	_ok(rc.find_child("Retry", true, false) == null, "reconnecting shows a spinner, not Retry")
	var sk := UI3.skeleton_row()
	_ok(sk.custom_minimum_size.y == 72, "skeleton row 72")
	sk.free()
	var pl := UI3.plate(&"card")
	host.add_child(pl)
	_ok(pl.theme_type_variation == "PanelCard", "plate card variation")

	var fr := Button.new()
	host.add_child(fr)
	var ring := UI3.attach_focus_ring(fr)
	_ok(not ring.visible, "focus ring hidden until focus")
	fr.focus_entered.emit()
	_ok(ring.visible, "focus ring shows on focus")
	var ring_sb := ring.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(ring_sb.border_width_left == 2 and ring_sb.expand_margin_left == 4, "focus ring is 2 px with a 4 px offset")
	host.queue_free()
