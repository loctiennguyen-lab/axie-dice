extends Control
class_name DefeatPanel
## Defeat screen — Dice UI R1 README 4 (03a-03c). Pure view: CombatView fills `show_defeat(d)` and
## listens to `end_run_pressed` / `continue_pressed`. The Continue effect (heal %, boss kept at its
## HP/phase, clock and attrition reset) is lane A's `continue_after_wipe`; this panel only states
## it and reports the click.
##
## d = {
##   title_line: "Act 1 boss · A6 · your party fell on turn 14",
##   boss: {name, hp, max_hp, phase, phases, spike_in}  or {}        # {} for a normal fight
##   recap: [{turn, what, result, final: bool}]                       # newest last, <= 6 rows
##   aid_used, aid_cap, continue_left (0|1),
##   heal_pct: 25|40, party: [{name, max_hp}],
##   enrage_reset_line, attrition_reset_line,
##   price: int, price_was: int (0 = none), usd: String,
##   variant: "paid"|"gift"|"moon",
##   foot: String }

signal end_run_pressed
signal continue_pressed

var _panel: PanelContainer
var _end_button: Button
var _continue_button: Button


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func show_defeat(d: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = DangoTheme.SCRIM_DEFEAT
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1320, 0)
	var psb := HudKit.box(DangoTheme.CREAM_100, 28, 4, DangoTheme.LINE, Vector2(5, 8))
	psb.content_margin_left = 0.0
	psb.content_margin_right = 0.0
	psb.content_margin_top = 0.0
	psb.content_margin_bottom = 0.0
	_panel.add_theme_stylebox_override("panel", psb)
	center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_panel.add_child(col)

	# Header 72, dusk-brown.
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 72)
	var hsb := HudKit.box(Color("5A3A26"), 24, 0, DangoTheme.LINE, Vector2.ZERO, DangoTheme.SHELF,
		Vector2(28, 0))
	hsb.border_width_bottom = 4
	head.add_theme_stylebox_override("panel", hsb)
	col.add_child(head)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 14)
	head.add_child(hrow)
	var ht := HudKit.label("Defeat", 36, DangoTheme.CREAM_RAISED)
	hrow.add_child(ht)
	var hs := HudKit.prose(String(d.get("title_line", "")), 16, DangoTheme.CREAM_200)
	hs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hrow.add_child(hs)

	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 28)
	body.add_theme_constant_override("margin_right", 28)
	body.add_theme_constant_override("margin_top", 24)
	body.add_theme_constant_override("margin_bottom", 28)
	col.add_child(body)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	body.add_child(cols)
	cols.add_child(_recap_column(d))
	cols.add_child(_wind_column(d))
	_end_button.grab_focus()   # focus starts on End run (README 4)


func _recap_column(d: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size = Vector2(600, 0)
	col.add_theme_constant_override("separation", 12)
	col.add_child(HudKit.label("RECAP", 15, DangoTheme.LINE, 800, 0.08))
	var boss: Dictionary = d.get("boss", {})
	if not boss.is_empty():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 16, 3,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(14, 14)))
		col.add_child(card)
		var cc := VBoxContainer.new()
		cc.add_theme_constant_override("separation", 8)
		card.add_child(cc)
		var top := HBoxContainer.new()
		cc.add_child(top)
		var nm := HudKit.label("%s had" % String(boss.get("name", "")), 20, DangoTheme.INK)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nm)
		top.add_child(HudKit.label("%d / %d HP" % [int(boss.get("hp", 0)), int(boss.get("max_hp", 1))],
			26, DangoTheme.INK))
		var bar := HPBar.new()
		bar.set_kind(HPBar.Kind.ENEMY, 30, 9, 16)
		bar.set_marks([0.66, 0.33])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.set_stats(int(boss.get("hp", 0)), int(boss.get("max_hp", 1)))
		cc.add_child(bar)
		var pct := int(round(100.0 * float(boss.get("hp", 0)) / maxf(float(boss.get("max_hp", 1)), 1.0)))
		var line := "%d%% left %s phase %d of %d" % [pct, HudKit.dot(), int(boss.get("phase", 1)),
			int(boss.get("phases", 3))]
		if int(boss.get("spike_in", 0)) > 0:
			line += " %s big hit was due in %d turn%s" % [HudKit.dot(), int(boss.get("spike_in", 0)),
				"" if int(boss.get("spike_in", 0)) == 1 else "s"]
		cc.add_child(HudKit.prose(line, 13, DangoTheme.INK_2))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	col.add_child(rows)
	for r in d.get("recap", []):
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(0, 44)
		p.add_theme_stylebox_override("panel", HudKit.box(
			DangoTheme.GOLD_SOFT if bool(r.get("final", false)) else DangoTheme.CREAM_RAISED, 12, 2,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(12, 4)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		p.add_child(row)
		var t := HudKit.label("Turn %d" % int(r.get("turn", 0)), 15, DangoTheme.INK_2)
		t.custom_minimum_size = Vector2(64, 0)
		row.add_child(t)
		var w := HudKit.prose(String(r.get("what", "")), 14, DangoTheme.INK)
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(w)
		row.add_child(HudKit.label(String(r.get("result", "")), 16, DangoTheme.INK))
		rows.add_child(p)
	return col


func _wind_column(d: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size = Vector2(600, 0)
	col.add_theme_constant_override("separation", 12)
	var top := HBoxContainer.new()
	col.add_child(top)
	var k := HudKit.label("SECOND WIND", 15, DangoTheme.LINE, 800, 0.08)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(k)
	top.add_child(HudKit.label("Aid used %d of %d %s Continue %d of 1" % [int(d.get("aid_used", 0)),
		int(d.get("aid_cap", 6)), HudKit.dot(), 1 - int(d.get("continue_left", 1))], 14, DangoTheme.GEM_SHELF))

	var variant := String(d.get("variant", "paid"))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 16, 3,
		DangoTheme.OWNED_BOTTOM if variant == "gift" else (DangoTheme.GEM_SHELF if variant == "moon" else DangoTheme.OUTLINE),
		Vector2.ZERO, DangoTheme.SHELF, Vector2(16, 16)))
	col.add_child(card)
	var cc := VBoxContainer.new()
	cc.add_theme_constant_override("separation", 12)
	card.add_child(cc)
	if variant != "paid":
		var tag := PanelContainer.new()
		tag.custom_minimum_size = Vector2(0, 32)
		tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var gift := variant == "gift"
		tag.add_theme_stylebox_override("panel", HudKit.box(Color("8CC85A") if gift else DangoTheme.GEM, 999, 3,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(8, 0)))
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 6)
		tag.add_child(trow)
		trow.add_child(HudKit.tex_rect(HudKit.icon("gift" if gift else "mooncard"), 22))
		trow.add_child(HudKit.label("A GIFT %s ONCE PER ACCOUNT" % HudKit.dot() if gift else "MOON CARD %s -25%%" % HudKit.dot(),
			15, DangoTheme.INK_ON_OWNED if gift else DangoTheme.GEM_INK))
		cc.add_child(tag)
	var title := HudKit.label("Revive the party at %d%% HP and keep fighting" % int(d.get("heal_pct", 25)),
		26, DangoTheme.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(540, 0)
	cc.add_child(title)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	cc.add_child(grid)
	for m in d.get("party", []):
		var heal := int(ceil(float(m.get("max_hp", 0)) * float(d.get("heal_pct", 25)) / 100.0))
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.FACE_TINT["heal"], 10, 2,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(4, 6)))
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 0)
		cell.add_child(cv)
		var n := HudKit.label(String(m.get("name", "")), 14, DangoTheme.INK)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(n)
		var v := HudKit.label("+%d" % heal, 18, DangoTheme.OUTLINE)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(v)
		grid.add_child(cell)
	for line in [d.get("keep_line", ""), d.get("enrage_reset_line", ""), d.get("attrition_reset_line", "")]:
		if String(line) == "":
			continue
		var l := HudKit.prose(String(line), 14, DangoTheme.INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(540, 0)
		cc.add_child(l)

	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 14)
	col.add_child(brow)
	# End run / Continue: BOTH 302 x 72.
	_end_button = _big_button("End run", "Keep rewards earned so far", false, "")
	_end_button.pressed.connect(func(): end_run_pressed.emit())
	brow.add_child(_end_button)
	var price := int(d.get("price", 90))
	var was := int(d.get("price_was", 0))
	var label := "Continue %s Free" % HudKit.dot() if variant == "gift" else "Continue %s %d" % [HudKit.dot(), price]
	_continue_button = _big_button(label, String(d.get("usd", "")), true, variant)
	if was > 0:
		_continue_button.tooltip_text = "was %d" % was
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	# B2: hidden for a newcomer / the tutorial; disabled with the reason (no Gem, cap) otherwise.
	_continue_button.visible = bool(d.get("continue_show", true))
	if not bool(d.get("continue_enabled", true)):
		_continue_button.disabled = true
		_continue_button.tooltip_text = String(d.get("continue_reason", ""))
	brow.add_child(_continue_button)
	var foot := HudKit.prose(String(d.get("foot", "")), 12, DangoTheme.INK_2)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(600, 0)
	col.add_child(foot)
	return col


func _big_button(text: String, sub: String, paid: bool, variant: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(302, 72)
	b.focus_mode = Control.FOCUS_ALL
	if paid and variant == "gift":
		DangoTheme.style_button(b, false, false, DangoTheme.INK_ON_OWNED, true)
	elif paid:
		DangoTheme.style_button(b, false, false, DangoTheme.GEM_INK, false, true)
	else:
		DangoTheme.style_button(b, false)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	b.add_child(col)
	var ink := DangoTheme.INK_ON_OWNED if variant == "gift" else (DangoTheme.GEM_INK if paid else DangoTheme.INK)
	var l := HudKit.label(text, 22, ink)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var s := HudKit.prose(sub, 12, ink if paid else DangoTheme.INK_2)
	s.add_theme_font_override("font", DangoTheme.FONT_UI_BOLD)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(s)
	return b
