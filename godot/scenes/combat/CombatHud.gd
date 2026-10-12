extends Control
class_name CombatHud
## Dice UI R1 combat HUD frame (design/handoffs/ui-02-round1b README §3): the top HUD, the
## attrition card, the right zone (Undo / Reroll / END TURN / speed control) and the left zone
## (Aid). Pure view: it is told what to show (`update_*`) and reports clicks (signals). It never
## reads or writes game state; CombatView owns that.
##
## Layout is relationships, not mockup y values (godot/CLAUDE.md rule 2): the top HUD hangs from
## y 0, everything in the bottom half hangs from y H, and extra window height opens up between
## the monsters and the party. `layout()` runs on every resize.

signal menu_pressed
signal ascension_pressed
signal active_pressed(relic_id: String)

const TOP := 12.0
const EDGE := 16.0
const BAR_H := 64.0
const TRAY_H := 176.0
const TRAY_BOTTOM := 16.0
const RIGHT_W := 200.0

var relic_strip: HBoxContainer      ## kept as a public name: tests hover relic chips here
var actives_row: HBoxContainer

var _left_bar: PanelContainer
var _mana_chip: PanelContainer
var _mana_label: Label
var _turn_plate: PanelContainer
var _turn_label: Label
var _turn_sub: Label
var _right_bar: PanelContainer
var _asc_badge: Button
var _shard_chip: PanelContainer
var _shard_label: Label
var _menu_button: Button
var _attr_card: PanelContainer
var _attr_style: StyleBoxFlat
var _attr_title: Label
var _attr_sub: Label
var _speed: PanelContainer
var _speed_buttons: Array[Button] = []
var _skip_button: Button

## Right-zone buttons are owned by the scene (%UndoButton etc. keep their names for the tests);
## CombatView hands them over via `adopt_right_zone()`.
var undo_button: Button
var reroll_button: Button
var end_turn_button: Button
var _undo_sub: Label
var _reroll_label: Label
var _reroll_sub: Label
var _end_sub: Label
var _end_label: Label
var _undo_label: Label

var _newcomer := false
var _tray_top := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_top()
	_build_attrition()
	_build_speed()
	resized.connect(layout)


# ── Top HUD ──────────────────────────────────────────────────────────────────────────────────

func _build_top() -> void:
	# Relic bar: 8 passive slots 44, divider, 3 active slots 48. Panel r16 border 3.
	_left_bar = PanelContainer.new()
	_left_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_bar.add_theme_stylebox_override("panel", HudKit.panel(16, 3, false, DangoTheme.PANEL, Vector2(8, 0)))
	add_child(_left_bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	_left_bar.add_child(row)
	relic_strip = HBoxContainer.new()
	relic_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_strip.add_theme_constant_override("separation", 4)
	row.add_child(relic_strip)
	var div := ColorRect.new()
	div.color = DangoTheme.LINE
	div.custom_minimum_size = Vector2(3, 44)
	div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var div_box := MarginContainer.new()
	div_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div_box.add_theme_constant_override("margin_left", 6)
	div_box.add_theme_constant_override("margin_right", 6)
	div_box.add_child(div)
	row.add_child(div_box)
	actives_row = HBoxContainer.new()
	actives_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actives_row.add_theme_constant_override("separation", 8)
	row.add_child(actives_row)
	# Mana is not in the R1 frames, but the active slots spend it and the player must see it.
	# Added as a small chip after the actives (flagged for design in the lane U report).
	_mana_chip = PanelContainer.new()
	_mana_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mana_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mana_chip.custom_minimum_size = Vector2(0, 36)
	_mana_chip.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 10, 3,
		DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(8, 0)))
	var mrow := HBoxContainer.new()
	mrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mrow.add_theme_constant_override("separation", 4)
	_mana_chip.add_child(mrow)
	mrow.add_child(HudKit.tex_rect(DangoTheme.face_type_icon("mana"), 22))
	_mana_label = HudKit.label("0", 17, DangoTheme.INK)
	mrow.add_child(_mana_label)
	_mana_chip.tooltip_text = "Mana: spent only on relic actives"
	_mana_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_mana_chip)

	# Turn plate: centred, 300 wide.
	_turn_plate = PanelContainer.new()
	_turn_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_plate.custom_minimum_size = Vector2(300, BAR_H)
	_turn_plate.add_theme_stylebox_override("panel", HudKit.panel(16, 3, false, DangoTheme.PANEL, Vector2(8, 0)))
	add_child(_turn_plate)
	var tcol := VBoxContainer.new()
	tcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	tcol.add_theme_constant_override("separation", 0)
	_turn_plate.add_child(tcol)
	_turn_label = HudKit.label("TURN 1", 26, DangoTheme.INK)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tcol.add_child(DangoTheme.line_box(_turn_label, 26, 1.0))
	_turn_sub = HudKit.label("", 12, DangoTheme.INK_2, 700)
	_turn_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tcol.add_child(_turn_sub)

	# Right cluster: Ascension badge · Gene Shard · Menu.
	_right_bar = PanelContainer.new()
	_right_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_bar.add_theme_stylebox_override("panel", HudKit.panel(16, 3, false, DangoTheme.PANEL, Vector2(8, 0)))
	add_child(_right_bar)
	var rrow := HBoxContainer.new()
	rrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rrow.add_theme_constant_override("separation", 6)
	_right_bar.add_child(rrow)

	_asc_badge = Button.new()
	_asc_badge.focus_mode = Control.FOCUS_ALL
	_asc_badge.custom_minimum_size = Vector2(0, 44)
	_asc_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled"]:
		_asc_badge.add_theme_stylebox_override(st, HudKit.box(DangoTheme.ASCENSION_RED, 11, 3,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(12, 0)))
	_asc_badge.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(11))
	DangoTheme.apply_tracking(_asc_badge, 0.0, 20, 800)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_asc_badge.add_theme_color_override(k, DangoTheme.CREAM_RAISED)
	_asc_badge.pressed.connect(func(): ascension_pressed.emit())
	_asc_badge.tooltip_text = "Ascension rules"
	rrow.add_child(_asc_badge)

	_shard_chip = PanelContainer.new()
	_shard_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shard_chip.custom_minimum_size = Vector2(0, 44)
	_shard_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_shard_chip.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 11, 3,
		DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(10, 0)))
	var srow := HBoxContainer.new()
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	srow.add_theme_constant_override("separation", 4)
	_shard_chip.add_child(srow)
	srow.add_child(HudKit.tex_rect(load("res://assets/icons/web/shard.png"), 28))
	_shard_label = HudKit.label("0", 18, DangoTheme.INK)
	srow.add_child(_shard_label)
	_shard_chip.tooltip_text = "Gene Shards earned this run"
	_shard_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	rrow.add_child(_shard_chip)

	_menu_button = Button.new()
	_menu_button.custom_minimum_size = Vector2(44, 44)
	_menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	DangoTheme.style_button(_menu_button, false)
	_menu_button.icon = MockupAssets.tex("assets/fx/settings.svg")
	_menu_button.expand_icon = true
	_menu_button.add_theme_constant_override("icon_max_width", 24)
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		_menu_button.add_theme_color_override(k, DangoTheme.INK)
	_menu_button.tooltip_text = "Menu"
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	rrow.add_child(_menu_button)


func _build_attrition() -> void:
	_attr_card = PanelContainer.new()
	_attr_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attr_card.custom_minimum_size = Vector2(310, 60)
	_attr_style = HudKit.box(DangoTheme.PANEL, 14, 3, DangoTheme.OUTLINE, Vector2(3, 5),
		DangoTheme.SHELF, Vector2(8, 0))
	_attr_card.add_theme_stylebox_override("panel", _attr_style)
	add_child(_attr_card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	_attr_card.add_child(row)
	row.add_child(HudKit.tex_rect(HudKit.icon("attrition"), 36))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	_attr_title = HudKit.label("", 18, DangoTheme.INK)
	col.add_child(_attr_title)
	_attr_sub = HudKit.label("", 12, DangoTheme.INK_2, 700)
	col.add_child(_attr_sub)


func _build_speed() -> void:
	# Speed control 1x / 2x / Skip (Space), shown only while a resolve is playing.
	_speed = PanelContainer.new()
	_speed.visible = false
	_speed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed.custom_minimum_size = Vector2(0, 52)
	_speed.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.DUSK, 14, 3, DangoTheme.OUTLINE,
		Vector2.ZERO, DangoTheme.SHELF, Vector2(4, 4)))
	add_child(_speed)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	_speed.add_child(row)
	for t in ["1x", "2x"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(52, 0)
		b.focus_mode = Control.FOCUS_ALL
		_style_speed_button(b, t == "1x")
		row.add_child(b)
		_speed_buttons.append(b)
	_skip_button = Button.new()
	_skip_button.text = "Skip %s Space" % HudKit.dot()
	_skip_button.icon = HudKit.icon("skip")
	_skip_button.expand_icon = true
	_skip_button.add_theme_constant_override("icon_max_width", 20)
	_style_speed_button(_skip_button, false)
	row.add_child(_skip_button)


func _style_speed_button(b: Button, on: bool) -> void:
	var fill := DangoTheme.CREAM_RAISED if on else Color("5A3A26")
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, HudKit.box(fill, 10, 0, DangoTheme.OUTLINE, Vector2.ZERO,
			DangoTheme.SHELF, Vector2(10, 0)))
	b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(10))
	DangoTheme.apply_tracking(b, 0.0, 17, 800)
	var ink := DangoTheme.INK if on else DangoTheme.CREAM_RAISED
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, ink)


# ── Right zone: adopt the scene's buttons and give them the R1 content ──────────────────────

func adopt_right_zone(undo: Button, reroll: Button, end_turn: Button) -> void:
	undo_button = undo
	reroll_button = reroll
	end_turn_button = end_turn
	for b in [undo, reroll, end_turn]:
		if b.get_parent() != null:
			b.get_parent().remove_child(b)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		add_child(b)
	# Undo: secondary, icon + "Undo · Z" + sub-line.
	undo.custom_minimum_size = Vector2(RIGHT_W, 52)
	DangoTheme.style_button(undo, false)
	_undo_label = _fill_button(undo, "Undo %s Z" % HudKit.dot(), 18, HudKit.icon("undo"), 28)
	_undo_sub = _sub_label(undo, "nothing to undo")
	# Reroll: secondary, icon + "Reroll · n left".
	reroll.custom_minimum_size = Vector2(RIGHT_W, 56)
	DangoTheme.style_button(reroll, false)
	_reroll_label = _fill_button(reroll, "Reroll", 19, HudKit.icon("reroll"), 30)
	# END TURN: primary 200 x 104, border 4.
	end_turn.custom_minimum_size = Vector2(RIGHT_W, 104)
	DangoTheme.style_button(end_turn, true)
	_end_label = _fill_button(end_turn, "END TURN", 28, null, 0)
	_end_sub = _sub_label(end_turn, "E %s 0 dice unused" % HudKit.dot())
	layout()


## A centred row/column of [icon] label inside a Button (Button has no layout of its own).
func _fill_button(b: Button, text: String, size: int, icon_tex: Texture2D, icon_px: int) -> Label:
	var row := HBoxContainer.new()
	row.name = "Content"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	b.add_child(row)
	if icon_tex != null:
		var ic := HudKit.tex_rect(icon_tex, icon_px)
		ic.name = "Icon"
		row.add_child(ic)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var l := HudKit.label(text, size, DangoTheme.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	return l


func _sub_label(b: Button, text: String) -> Label:
	var col: Node = b.get_node("Content/Col")
	var l := HudKit.prose(text, 12, DangoTheme.INK_2)
	l.add_theme_font_override("font", DangoTheme.FONT_UI_BOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	return l


# ── Update API (called from CombatView._rebuild_all) ─────────────────────────────────────────

func update_top(d: Dictionary) -> void:
	## d: relics:[{icon, tip, color}], actives:[{id, icon, charges, spent, armed, tip}], mana, turn,
	##    act_line, ascension, shards, newcomer, ender_phase (bool: enemy turn)
	_newcomer = bool(d.get("newcomer", false))
	for c in relic_strip.get_children():
		relic_strip.remove_child(c)
		c.queue_free()
	var relics: Array = d.get("relics", [])
	var shown := mini(relics.size(), 8 if relics.size() <= 8 else 7)
	for i in 8:
		if i < shown:
			var r: Dictionary = relics[i]
			relic_strip.add_child(_slot(44, 10, 2, DangoTheme.CREAM_RAISED, r.get("icon"), 36,
				String(r.get("tip", "")), 1.0))
		elif relics.size() > 8 and i == 7:
			relic_strip.add_child(_more_slot(relics.size() - 7))
		else:
			relic_strip.add_child(_slot(44, 10, 2, DangoTheme.CREAM_300, null, 0, "", 1.0))
	for c in actives_row.get_children():
		actives_row.remove_child(c)
		c.queue_free()
	for a in d.get("actives", []):
		actives_row.add_child(_active_slot(a))
	_mana_chip.visible = (d.get("actives", []) as Array).size() > 0
	_mana_label.text = str(int(d.get("mana", 0)))
	_turn_label.text = "TURN %d" % int(d.get("turn", 1))
	_turn_sub.text = String(d.get("act_line", ""))
	var asc := int(d.get("ascension", 0))
	_asc_badge.visible = asc > 0
	_asc_badge.text = "A%d %s" % [asc, HudKit.glyph(0x25BE, "v")]
	_shard_label.text = str(int(d.get("shards", 0)))
	layout()


func _slot(px: int, radius: int, border_w: int, fill: Color, icon_tex: Variant, icon_px: int,
		tip: String, icon_alpha: float) -> PanelContainer:
	var s := PanelContainer.new()
	s.custom_minimum_size = Vector2(px, px)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.add_theme_stylebox_override("panel", HudKit.box(fill, radius, border_w))
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(cc)
	if icon_tex != null and icon_px > 0:
		cc.add_child(HudKit.tex_rect(icon_tex, icon_px, Color(1, 1, 1, icon_alpha)))
	if tip != "":
		s.tooltip_text = tip
		s.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _more_slot(n: int) -> PanelContainer:
	var s := _slot(44, 10, 2, DangoTheme.DUSK, null, 0, "", 1.0)
	(s.get_child(0) as CenterContainer).add_child(HudKit.label("+%d" % n, 16, DangoTheme.CREAM_RAISED))
	return s


## Active slot: 48 x 48, r12, border 3, charge badge 20 at -6/-6. Spent: fill E8D6B4, icon .4.
## CLICKABLE (the engine's play_active); disabled when spent / unaffordable.
func _active_slot(a: Dictionary) -> Control:
	var spent := bool(a.get("spent", false))
	var armed := bool(a.get("armed", false))
	var b := Button.new()
	b.custom_minimum_size = Vector2(48, 48)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.disabled = spent
	b.tooltip_text = String(a.get("tip", ""))
	var fill := DangoTheme.CREAM_DISABLED if spent else (DangoTheme.GOLD if armed else DangoTheme.CREAM_RAISED)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, HudKit.box(fill, 12, 4 if armed else 3, DangoTheme.OUTLINE,
			Vector2(3, 4) if not spent else Vector2.ZERO))
	b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(12))
	var ic := HudKit.tex_rect(a.get("icon"), 36, Color(1, 1, 1, 0.4 if spent else 1.0))
	ic.set_anchors_preset(Control.PRESET_CENTER)
	ic.position = Vector2(6, 6)
	b.add_child(ic)
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(20, 20)
	badge.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.DUSK, 7, 2, DangoTheme.OUTLINE,
		Vector2.ZERO, DangoTheme.SHELF, Vector2(4, 0)))
	var bl := HudKit.label(str(a.get("charges", "")), 12, DangoTheme.CREAM_RAISED)
	badge.add_child(bl)
	badge.position = Vector2(48 - 14, 48 - 14)
	b.add_child(badge)
	var rid := String(a.get("id", ""))
	b.pressed.connect(func(): active_pressed.emit(rid))
	return b


## README 3 attrition card. state = hud_state().attrition; turn; hidden for newcomers.
func update_attrition(state: Dictionary, turn: int, newcomer: bool) -> void:
	_newcomer = newcomer
	_attr_card.visible = not newcomer
	if newcomer:
		return
	var pct := int(state.get("pct", 0))
	var start := int(state.get("start_turn", 6))
	var maxed := pct >= 25
	_attr_style.bg_color = DangoTheme.GOLD_SOFT if maxed else DangoTheme.PANEL
	if pct <= 0:
		_attr_title.text = "ATTRITION %s NOT YET" % HudKit.dot()
		_attr_sub.text = "starts turn %d %s +5%%/turn %s max +25%%" % [start, HudKit.dot(), HudKit.dot()]
	elif maxed:
		_attr_title.text = "ATTRITION +%d%% %s MAX" % [pct, HudKit.dot()]
		_attr_sub.text = "since turn %d" % (start + 4)
	else:
		_attr_title.text = "ATTRITION +%d%%" % pct
		_attr_sub.text = "+5%% each turn %s max +25%%" % HudKit.dot()


## Right zone texts + enabled states.
## undo: {enabled, sub}  reroll: {n, enabled}  end: {sub, warn, enabled}
func update_right(undo: Dictionary, reroll: Dictionary, end: Dictionary) -> void:
	if undo_button == null:
		return
	undo_button.disabled = not bool(undo.get("enabled", false))
	_undo_sub.text = String(undo.get("sub", ""))
	var n := int(reroll.get("n", 0))
	_reroll_label.text = "Reroll %s %d left" % [HudKit.dot(), n]
	reroll_button.disabled = not bool(reroll.get("enabled", false))
	_end_sub.text = String(end.get("sub", ""))
	DangoTheme.style_button(end_turn_button, true, bool(end.get("warn", false)))
	end_turn_button.disabled = not bool(end.get("enabled", true))
	# Disabled-but-informative ink stays readable (#6E4A30), icon at half strength.
	var ico: Node = undo_button.get_node_or_null("Content/Icon")
	if ico != null:
		(ico as Control).modulate.a = 0.5 if undo_button.disabled else 1.0
	var rico: Node = reroll_button.get_node_or_null("Content/Icon")
	if rico != null:
		(rico as Control).modulate.a = 0.5 if reroll_button.disabled else 1.0
	for l in [_undo_label, _undo_sub, _reroll_label, _end_label, _end_sub]:
		var dis: bool = (l == _undo_label or l == _undo_sub) and undo_button.disabled
		dis = dis or (l == _reroll_label and reroll_button.disabled)
		dis = dis or ((l == _end_label or l == _end_sub) and end_turn_button.disabled)
		var col: Color = DangoTheme.INK_DISABLED if dis else (
			DangoTheme.INK_ON_PRIMARY if (l == _end_label or l == _end_sub) else DangoTheme.INK)
		if l == _undo_sub or l == _end_sub:
			col = DangoTheme.INK_DISABLED if dis else (
				Color("4A2208") if l == _end_sub else DangoTheme.INK_2)
		l.add_theme_color_override("font_color", col)


## Show the 1x / 2x / Skip control while a resolve plays.
func set_resolving(v: bool) -> void:
	_speed.visible = v
	layout()


func speed_buttons() -> Array[Button]:
	return _speed_buttons


func skip_button() -> Button:
	return _skip_button


## Bottom of the screen the tray/right zone hang from.
func tray_top() -> float:
	return _tray_top


func layout() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0:
		var vs := get_viewport_rect().size
		w = vs.x
		h = vs.y
	_tray_top = h - TRAY_BOTTOM - TRAY_H
	_left_bar.size = Vector2.ZERO
	_left_bar.position = Vector2(EDGE, TOP)
	_left_bar.size = Vector2(_left_bar.get_combined_minimum_size().x, BAR_H)
	_turn_plate.position = Vector2((w - 300.0) * 0.5, TOP)
	_turn_plate.size = Vector2(300, BAR_H)
	_right_bar.size = Vector2.ZERO
	var rw := _right_bar.get_combined_minimum_size().x
	_right_bar.size = Vector2(rw, BAR_H)
	_right_bar.position = Vector2(w - EDGE - rw, TOP)
	_attr_card.position = Vector2(w - EDGE - 310.0, 88.0)
	_attr_card.size = Vector2(310, 60)
	if undo_button != null:
		var x := w - EDGE - RIGHT_W
		undo_button.position = Vector2(x, _tray_top - 60.0)
		undo_button.size = Vector2(RIGHT_W, 52)
		reroll_button.position = Vector2(x, _tray_top)
		reroll_button.size = Vector2(RIGHT_W, 56)
		end_turn_button.position = Vector2(x, h - TRAY_BOTTOM - 104.0)
		end_turn_button.size = Vector2(RIGHT_W, 104)
		# Undo is hidden while input is locked: the speed control takes the slot.
		undo_button.visible = not _speed.visible
	_speed.size = Vector2.ZERO
	var sw := _speed.get_combined_minimum_size().x
	_speed.size = Vector2(sw, 52)
	_speed.position = Vector2(w - EDGE - sw, _tray_top - 66.0)
