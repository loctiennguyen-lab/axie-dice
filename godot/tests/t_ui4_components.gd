extends Node
## UI-04 foundation gate: new/changed shared components build in every variant/state from components.md with the
## documented sizes and token colours, the UI-04 theme entries exist, and every motion row is in motion_ui3.json.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_ui4_components: start ===")
	_guard.capture()
	await get_tree().process_frame
	var host := Control.new()
	host.theme = UI3Theme.get_theme()
	add_child(host)
	_theme()
	_chips(host)
	_tags(host)
	_notices(host)
	_buttons(host)
	_motion()
	await get_tree().process_frame
	host.queue_free()
	_guard.restore()
	print("=== t_ui4_components: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_ui4_components: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_ui4_components: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _theme() -> void:
	UI3Theme.set_scale_override(1.0)
	var t := UI3Theme.get_theme()
	for v in ["PanelDock", "PanelKeycap", "PanelKeycapS", "PanelTagSquare"]:
		_ok(t.has_stylebox("panel", v), "theme lacks %s" % v)
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		_ok(t.has_stylebox(s, "ButtonPrimaryS"), "ButtonPrimaryS lacks %s" % s)
	var plate := t.get_stylebox("panel", "PanelPlate") as StyleBoxFlat
	_ok(plate.border_width_left == UI3Theme.stroke("rim") and plate.border_color == UI3Theme.color("plate_rim"), "plate bevel 2 px plate_rim (style A)")
	_ok(plate.shadow_offset == Vector2(0, float(UI3Theme.tokens()["shadow"]["lip"])) and plate.shadow_color == UI3Theme.color("plate_ink") and plate.get_corner_radius(CORNER_TOP_LEFT) == UI3Theme.radius("l"), "plate hard lip (0, lip) in plate_ink, radius l")
	var dlg := t.get_stylebox("panel", "PanelDialog") as StyleBoxFlat
	_ok(dlg.shadow_size <= 1 and dlg.shadow_offset == Vector2(0, 8), "dialog shadow hard y8, no blur")
	var prim := t.get_stylebox("normal", "ButtonPrimaryM") as StyleBoxFlat
	_ok(prim.shadow_color == UI3Theme.color("btn_primary_lip"), "primary lip is btn_primary_lip")
	var sec := t.get_stylebox("normal", "ButtonSecondary") as StyleBoxFlat
	_ok(sec.shadow_offset == Vector2(0, float(UI3Theme.tokens()["shadow"]["lip"])) and sec.shadow_color == UI3Theme.color("btn_secondary_lip"), "secondary hard lip (0, lip)")
	var sel := t.get_stylebox("panel", "PanelCardSelected") as StyleBoxFlat
	_ok(sel.expand_margin_left == 4 and sel.get_corner_radius(CORNER_TOP_LEFT) == UI3Theme.radius("xl"), "card selected outline outside 4 px, radius xl")
	var kc := t.get_stylebox("panel", "PanelKeycap") as StyleBoxFlat
	_ok(kc.bg_color == UI3Theme.color("keycap_bg") and kc.shadow_offset == Vector2(0, 3), "keycap fill kam-1, shadow 3")
	var ts := t.get_stylebox("panel", "PanelTagSquare") as StyleBoxFlat
	_ok(ts.get_corner_radius(CORNER_TOP_LEFT) == UI3Theme.radius("chip_square") and ts.border_width_left == 2, "tag_square radius 4, 2 px border")
	_ok(UI3Theme.size_of("dice_dock_w") == 808 and UI3Theme.size_of("action_dock_w") == 352, "dock widths")


func _chips(host: Control) -> void:
	for small in [false, true]:
		var k := UI3.keycap("Space", small)
		host.add_child(k)
		_ok(k.custom_minimum_size.y == (28.0 if small else 36.0), "keycap height small=%s" % small)
		UI3.set_keycap_state(k, &"dimmed")
		_ok(is_equal_approx(k.modulate.a, 0.4), "keycap dimmed 0.4")
		UI3.set_keycap_state(k, &"pressed")
		_ok((k.get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset == Vector2(0, 1), "keycap pressed shadow 1")
		UI3.set_keycap_state(k, &"normal")
		_ok((k.get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset == Vector2(0, 3) and k.modulate.a == 1.0, "keycap normal restored")
	for tier in UI3.TIERS:
		for current in [true, false]:
			for band in [false, true]:
				var c := UI3.tier_chip(tier, String(tier).capitalize(), current, band)
				host.add_child(c)
				var pips := c.find_child("Pips", true, false).get_child_count()
				_ok(pips == UI3.TIER_PIPS[tier], "%s has %d pips" % [tier, UI3.TIER_PIPS[tier]])
				_ok(c.custom_minimum_size.y == (56.0 if band else 40.0), "tier chip height band=%s" % band)
				var sb := c.get_theme_stylebox("panel") as StyleBoxFlat
				if current:
					_ok(sb.border_color == UI3Theme.color("tier_" + String(tier)) and sb.bg_color == UI3Theme.color("tier_%s_bg" % tier), "%s colours" % tier)
				else:
					_ok(is_equal_approx(c.modulate.a, 0.8) and sb.border_color == UI3Theme.color("disabled_border"), "%s legend-other" % tier)
	var cat := UI3.category_chip("rule change")
	host.add_child(cat)
	_ok((cat.find_children("*", "Label", true, false)[0] as Label).text == "RULE CHANGE" and cat.theme_type_variation == "PanelTagSquare", "category chip uppercase tag_square")
	for h in UI3.HOUSES:
		for st in [0, 1]:
			var hc := UI3.house_chip(h, "Kin", st, 2, st == 1)
			host.add_child(hc)
			_ok(hc.find_child("Pips", true, false).get_child_count() == 2, "house %s pips" % h)
			var hsb := hc.get_theme_stylebox("panel") as StyleBoxFlat
			_ok(hsb.border_width_left == (3 if st == 1 else 2), "house %s border awakened=%d" % [h, st])
	var rr := UI3.run_rule_chip("No rerolls", "Run rule")
	host.add_child(rr)
	_ok((rr.get_theme_stylebox("panel") as StyleBoxFlat).get_corner_radius(CORNER_TOP_LEFT) == 8, "run rule chip is not a pill")
	_ok((rr.find_child("RuleLabel", true, false) as Control) != null, "run rule label square")


func _tags(host: Control) -> void:
	for kind in UI3.ENEMY_TAGS:
		for inline in [false, true]:
			var tg := UI3.enemy_tag(kind, String(kind).to_upper(), inline)
			host.add_child(tg)
			_ok(tg.custom_minimum_size.y == (32.0 if inline else 36.0), "%s tag height" % kind)
			_ok(tg.find_child("Icon", true, false) != null and (tg.find_child("Word", true, false) as Label).text != "", "%s has glyph and word" % kind)
	var leader := UI3.enemy_tag(&"leader", "LEADER").get_theme_stylebox("panel") as StyleBoxFlat
	_ok(leader.bg_color == UI3Theme.color("leader") and leader.shadow_offset == Vector2(0, 3), "leader solid + shadow 3")
	var shell := UI3.enemy_tag(&"shell", "SHELL").get_theme_stylebox("panel") as StyleBoxFlat
	_ok(shell.get_corner_radius(CORNER_TOP_LEFT) == UI3Theme.radius("chip_square"), "shell is the square tag")
	var elite := UI3.enemy_tag(&"elite", "ELITE").get_theme_stylebox("panel") as StyleBoxFlat
	_ok(elite.get_corner_radius(CORNER_TOP_LEFT) >= 100 and elite.border_color == UI3Theme.color("tag_elite_border"), "elite outline pill")
	var ns := UI3.name_suffix("BC")
	host.add_child(ns)
	_ok(ns.custom_minimum_size == Vector2(28, 28) and (ns.find_children("*", "Label", true, false)[0] as Label).text == "B", "name suffix 28 square, one letter")
	var wp := UI3.waiting_pill("Waiting for server…")
	host.add_child(wp)
	_ok(wp.custom_minimum_size.y == 56.0, "waiting pill 56")
	var dk := UI3.dock(848)
	host.add_child(dk)
	_ok(dk.theme_type_variation == "PanelDock" and dk.custom_minimum_size.x == 848.0, "dock 848")
	for n in [0, 3, 6]:
		var rb := UI3.risk_bars(n)
		host.add_child(rb)
		_ok(rb.get_child_count() == 6, "risk bars: 6 bars")
		var filled := 0
		for b in rb.get_children():
			if ((b as Panel).get_theme_stylebox("panel") as StyleBoxFlat).bg_color != UI3Theme.color("hp_track"):
				filled += 1
		_ok(filled == n, "risk bars filled %d of %d" % [filled, n])
	_ok(is_equal_approx((UI3.risk_bars(6).get_child(5) as Control).custom_minimum_size.y, 20.4), "tallest risk bar 20.4")


func _notices(host: Control) -> void:
	var fired := []
	for st in [&"offline", &"timeout", &"retrying"]:
		var n := UI3.net_notice_v4("Could not save", "Your run is safe.", "RETRY", "OK",
			func() -> void: fired.append("retry"), Callable(), st)
		host.add_child(n)
		_ok(n.custom_minimum_size.y == 80.0 and (n.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top == 4, "net notice %s: 80 high, 4 px top edge" % st)
		var rb := n.find_child("Retry", true, false) as Button
		_ok(rb.theme_type_variation == "ButtonPrimaryS", "retry is primary small")
		_ok(rb.disabled == (st == &"retrying"), "retry disabled only while retrying (%s)" % st)
		if st == &"offline":
			rb.pressed.emit()
	_ok(fired.size() == 1, "retry callback fires")
	var ub := UI3.update_bar("Update ready", "Reload to keep playing.", "Reload the page", Callable())
	host.add_child(ub)
	_ok(ub.custom_minimum_size.y == 56.0 and (ub.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == UI3Theme.color("update_bar_bg"), "update bar 56 high, token fill")
	_ok((ub.find_child("Reload", true, false) as Button).custom_minimum_size.y >= 44.0, "reload hit area >= 44")


func _buttons(host: Control) -> void:
	for kind in [&"gem", &"shard", &"stone", &"free"]:
		var b := UI3.button_with_cost("Open", kind, 5)
		host.add_child(b)
		_ok(b.find_child("CostChip", true, false) != null, "button_with_cost %s has chip inside" % kind)
		var dis := UI3.button_with_cost("Need 2 more", kind, 5, true)
		host.add_child(dis)
		dis.disabled = true
		_ok(kind == &"free" or dis.find_child("CostChip", true, false).modulate.a < 1.0, "not-enough chip dimmed")
	var small := UI3.button("RETRY", &"primary", &"S")
	_ok(small.theme_type_variation == "ButtonPrimaryS" and small.custom_minimum_size.y == float(UI3Theme.size_of("btn_s")), "primary S is the small button, btn_s")
	small.free()
	var sec := UI3.button("Back", &"secondary", &"S")
	_ok(sec.theme_type_variation == "ButtonSecondaryS", "secondary S unchanged")
	sec.free()


func _motion() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/ui/motion_ui3.json"))
	var md := FileAccess.get_file_as_string("res://assets/data/ui/MOTION_IDS.md")
	var ids := 0
	for id in data.keys():
		if String(id).begins_with("_"):
			continue
		ids += 1
		var e: Dictionary = data[id]
		_ok(UI3Motion.validate_moment(String(id), e).is_empty(), "motion '%s' validates: %s" % [id, UI3Motion.validate_moment(String(id), e)])
		_ok(e.has("trigger") and e.has("skip") and e.has("reduce_flash") or id in ["turn_banner", "combo_banner"], "motion '%s' records trigger/skip/reduce_flash" % id)
		_ok(md.contains("`%s`" % id), "MOTION_IDS.md lists '%s'" % id)
	_ok(ids >= 41, "motion table has %d ids, expected the 2 old + every UI-04 row" % ids)
