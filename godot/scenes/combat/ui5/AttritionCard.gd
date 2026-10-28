extends PanelContainer
class_name AttritionCard
## UI-05 b1 lane C: AttritionCard, the last item of the EnemyColumn (`.attrition`).
##
## enemy_card_w x attrition_h pill (the frame: `.enemy-column .attrition{width: enemy-card-w}`, Liam/review 29/10) on the plate family: plate fill, 2 px plate_rim edge, hard lip, padding 0 16, gap 12.
## Attrition glyph icon_m · AttritionLabel (text_body Rowdies, one line, takes the free width) · 3 pips before start.
##   upcoming : "ATTRITION · TURN N", dashed edge, 14 px pips (2 px attrition ring, filled = turns gone)
##   active   : "ATTRITION +N%", solid edge
##   max      : "ATTRITION +N% · MAX", attrition_max edge and text
## Same strings and visibility rule as the UI-04 card (CombatLabels.attrition_visible). The tooltip is bound here.

const MAX_PCT := 25   ## the engine's cap (hud_state().attrition.pct); the tooltip says "up to +25%"

var label: Label        ## AttritionLabel
var pips: HBoxContainer
var _icon: TextureRect
var _style: StyleBoxFlat
var _dashed := false
var _edge := Color.TRANSPARENT
var state := &"upcoming"   ## upcoming | active | max (tests, QA)


func _init() -> void:
	name = "AttritionCard"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP   # hover = attrition tooltip
	add_to_group("ui3_tip_avoid")
	_style = (UI3Theme.get_theme().get_stylebox("panel", "PanelPlate") as StyleBoxFlat).duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", _style)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = HudKit.tex_rect(HudKit.icon("attrition"), UI3Theme.size_of("icon_m"))
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	label = UI3.label("", "LabelDisplay")
	label.name = "AttritionLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	pips = HBoxContainer.new()
	pips.name = "Pips"
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pips)
	apply_sizes()
	draw.connect(_draw_dashes)


func apply_sizes() -> void:
	custom_minimum_size = Vector2(UI3Theme.size_of("enemy_card_w"), UI3Theme.size_of("attrition_h"))
	_style.set_corner_radius_all(UI3Theme.radius("pill"))
	_style.content_margin_left = UI3Theme.space("16")
	_style.content_margin_right = UI3Theme.space("16")
	_style.content_margin_top = 0
	_style.content_margin_bottom = 0
	(get_node("Row") as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("12"))
	pips.add_theme_constant_override("separation", UI3Theme.space("4"))
	var ic := UI3Theme.size_of("icon_m")
	_icon.custom_minimum_size = Vector2(ic, ic)
	label.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))


## state = hud_state().attrition ({start_turn, pct}); hidden for newcomers and until a few turns before it starts.
func apply(st: Dictionary, turn: int, newcomer: bool) -> void:
	visible = (not newcomer) and CombatLabels.attrition_visible(st, turn)
	var start := int(st.get("start_turn", 6))
	UI3Tooltip.bind(self, "Attrition: from turn %d every enemy hits 5%% harder each turn, up to +%d%%. Long fights get dangerous, so finish them. It resets every fight." % [start, MAX_PCT])
	if newcomer:
		return
	var pct := int(st.get("pct", 0))
	var running := pct > 0
	var maxed := pct >= MAX_PCT
	state = &"max" if maxed else (&"active" if running else &"upcoming")
	var ink := UI3Theme.color("attrition_max" if maxed else "attrition")
	if not running:
		label.text = "ATTRITION %s TURN %d" % [HudKit.dot(), start]
	elif maxed:
		label.text = "ATTRITION +%d%% %s MAX" % [pct, HudKit.dot()]
	else:
		label.text = "ATTRITION +%d%%" % pct
	label.add_theme_color_override("font_color", ink)
	_dashed = not running
	_edge = UI3Theme.color("attrition_max" if maxed else "plate_rim")
	var w := UI3Theme.stroke("rim")
	_style.set_border_width_all(0 if _dashed else w)
	_style.border_color = _edge
	for c in pips.get_children():
		pips.remove_child(c)
		c.queue_free()
	if not running:   # 3 pips only before start: 4 - N turns to go filled
		var filled := clampi(4 - (start - turn), 0, 3)
		var col := UI3Theme.color("attrition")
		for i in 3:
			var d := Panel.new()
			d.custom_minimum_size = Vector2(14, 14)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			d.add_theme_stylebox_override("panel", UI3Theme.flat(col if i < filled else Color.TRANSPARENT, 7,
				UI3Theme.stroke("hairline"), col))
			pips.add_child(d)
	queue_redraw()


## Dashed 2 px edge before the attrition starts (a StyleBox cannot dash): straight runs between the pill's round ends,
## and the two round ends as dashed arcs.
func _draw_dashes() -> void:
	if not _dashed:
		return
	var w := float(UI3Theme.stroke("rim"))
	var r := Rect2(Vector2.ZERO, size).grow(-w * 0.5)
	var rad := r.size.y * 0.5
	var col := UI3Theme.color("plate_rim")
	var a := Vector2(r.position.x + rad, r.position.y)
	var b := Vector2(r.end.x - rad, r.position.y)
	draw_dashed_line(a, b, col, w, 8.0)
	draw_dashed_line(Vector2(a.x, r.end.y), Vector2(b.x, r.end.y), col, w, 8.0)
	for side in [-1.0, 1.0]:
		var c := Vector2(a.x if side < 0.0 else b.x, r.position.y + rad)
		var from := PI * 0.5 if side < 0.0 else -PI * 0.5
		var steps := 8
		for i in steps:
			if i % 2 == 1:
				continue
			var t0 := from + PI * float(i) / float(steps)
			var t1 := from + PI * float(i + 1) / float(steps)
			draw_arc(c, rad, t0, t1, 4, col, w, true)
