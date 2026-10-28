extends PanelContainer
class_name EnemyPlate
## UI-05 b1 lane C: one enemy's plate in the EnemyColumn (design/handoffs/ui-05-figma/round-1, `.enemy-card`).
##
## EnemyPlate = HBox(EnemyMain VBox(NameRow, HPBar[, ShellRow]), IntentBlock): `enemy_card_w` wide, plate family
## (plate fill, 2 px plate_rim bevel, radius l, hard plate_ink lip), padding 0, clip on. EnemyMain: padding 12 16 16,
## gap 8, bottom-aligned. NameRow: EnemyName (text_body Rowdies, takes the free width, ellipsis), NameSuffix, EnemyTag(s),
## BigHitBadge, HPValue. The IntentBlock column decides the height.
## Big hit: 4 px intent_bighit_border edge (the content moves in with it, as in the HTML).
## BossPlate (BossPlate.gd) is the same plate with the boss body (boss_plate_w).
##
## View only: UnitPortrait owns the state (lit, lethal, big hit, nick, ...) and pushes it here.

var is_boss := false
var main_box: VBoxContainer        ## EnemyMain
var name_row: HBoxContainer        ## NameRow (boss: the first boss line)
var name_label: Label              ## EnemyName
var suffix: PanelContainer         ## NameSuffix ("A", "B")
var tag_box: HBoxContainer         ## EnemyTag(s) while they fit in the name row
var tags_row: HBoxContainer        ## second row the tags move to when the name row is full
var badge: PanelContainer          ## BigHitBadge "!"
var hp_label: Label                ## HPValue
var hp_bar: HPBar                  ## HPBar
var shell_row: HBoxContainer       ## ShellRow: SHELL tag + ShellBar + ShellValue
var shell_bar: HPBar
var shell_label: Label             ## ShellValue
var extra_box: VBoxContainer       ## boss: EnrageRow and the phase line hang here
var intent: IntentBlock
var _margin: MarginContainer
var _style: StyleBoxFlat
var _border_w := -1


func _init(boss := false) -> void:
	is_boss = boss
	name = "BossPlate" if boss else "EnemyPlate"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # UnitPortrait's click catcher sits behind the plate
	clip_contents = true
	_style = (UI3Theme.get_theme().get_stylebox("panel", "PanelPlate") as StyleBoxFlat).duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", _style)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	_margin = MarginContainer.new()
	_margin.name = "MainMargin"
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin.clip_contents = true
	row.add_child(_margin)
	main_box = VBoxContainer.new()
	main_box.name = "BossMain" if boss else "EnemyMain"
	main_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_box.alignment = BoxContainer.ALIGNMENT_BEGIN if boss else BoxContainer.ALIGNMENT_END
	_margin.add_child(main_box)
	intent = IntentBlock.new()
	row.add_child(intent)
	_build_main()
	apply_sizes()
	set_border(UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"))


## Enemy body: NameRow, HPBar, ShellRow (hidden until the engine reports a Shell), tags row (hidden).
func _build_main() -> void:
	name_row = _hbox("NameRow")
	main_box.add_child(name_row)
	name_label = _name()
	name_row.add_child(name_label)
	suffix = suffix_chip("A")
	suffix.visible = false
	name_row.add_child(suffix)
	tag_box = _hbox("Tags")
	name_row.add_child(tag_box)
	badge = bang()
	badge.visible = false
	name_row.add_child(badge)
	hp_label = _value("HPValue")
	# `.name-row .t-label{flex:1}` holds for both labels: name and HPValue split the free width, HPValue left-aligned
	# in its half (frames: "Ravenling" 108 | "19 / 19" 108). HPValue never clips: its text is its minimum.
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(hp_label)
	tags_row = _hbox("TagsRow")
	tags_row.visible = false
	main_box.add_child(tags_row)
	hp_bar = _bar("HPBar", HPBar.Kind.ENEMY)
	main_box.add_child(hp_bar)
	_build_shell_row()
	main_box.add_child(shell_row)
	extra_box = VBoxContainer.new()
	extra_box.name = "Extra"
	extra_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_box.add_child(extra_box)


func _build_shell_row() -> void:
	shell_row = _hbox("ShellRow")
	shell_row.mouse_filter = Control.MOUSE_FILTER_STOP   # tooltip; UnitPortrait forwards its clicks
	shell_row.visible = false
	shell_row.add_child(tag(&"shell", "SHELL"))
	shell_bar = _bar("ShellBar", HPBar.Kind.SHIELD)
	shell_bar.use_fixed_fill(UI3Theme.color("shell"))
	shell_row.add_child(shell_bar)
	shell_label = _value("ShellValue")
	shell_label.add_theme_color_override("font_color", UI3Theme.color("shell"))
	shell_row.add_child(shell_label)


# ── small builders ───────────────────────────────────────────────────────────────────────────

func _hbox(n: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = n
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	return h


func _name() -> Label:
	var l := UI3.label("", "LabelDisplay")
	l.name = "EnemyName"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true   # min width 0: a long name never widens the plate; the full name is in the tooltip
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _value(n: String) -> Label:
	var l := UI3.label("", "LabelDisplay")
	l.name = n
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _bar(n: String, kind: HPBar.Kind) -> HPBar:
	var b := HPBar.new()
	b.name = n
	b.ui3_look = true
	b.set_kind(kind, UI3Theme.size_of("hp_bar_h"), UI3Theme.size_of("hp_bar_h") / 2, UI3Theme.size_of("text_body"))
	b.custom_minimum_size.x = 0.0   # HPBar defaults to 96 wide
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


## EnemyTag (`.enemy-tag`): keycap_h high pill, padding 0 8, gap 4, glyph icon_s, text_key Rowdies.
## kind: elite | leader | shell (the one square tag) | boss. Children "Icon" and "Word" (tests read them).
static func tag(kind: StringName, word: String) -> PanelContainer:
	var fill: Color
	var border := Color.TRANSPARENT
	var ink := UI3Theme.color("text")
	var rad := UI3Theme.radius("pill")
	var tex: Texture2D
	match kind:
		&"elite":
			fill = UI3Theme.color("tag_elite_bg")
			border = UI3Theme.color("tag_elite_border")
			tex = HudKit.icon("elite")
		&"leader":
			fill = UI3Theme.color("leader")
			ink = UI3Theme.color("leader_text")
			tex = UI3.icon("node_elite")
		&"shell":
			fill = UI3Theme.color("tag_shell_bg")
			border = UI3Theme.color("shell")
			ink = UI3Theme.color("shell")
			rad = UI3Theme.radius("chip_square")
			tex = UI3.icon("face_shield")
		_:
			fill = UI3Theme.color("tag_boss_bg")
			tex = HudKit.icon("boss")
	var p := PanelContainer.new()
	p.name = "EnemyTag"
	p.set_meta("tag_kind", String(kind))
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(fill, rad, UI3Theme.stroke("hairline") if border.a > 0.0 else 0,
		border))
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = tex
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == &"shell":
		ic.modulate = ink   # greyscale glyph in the shell colour
	row.add_child(ic)
	var l := UI3.label(word, "LabelDisplay")
	l.name = "Word"
	l.add_theme_color_override("font_color", ink)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	size_tag(p)
	return p


## Token sizes of a tag (again at a scale change).
static func size_tag(p: PanelContainer) -> void:
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.content_margin_left = UI3Theme.space("8")
		sb.content_margin_right = UI3Theme.space("8")
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	var row := p.get_node("Row") as HBoxContainer
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	var s := UI3Theme.size_of("icon_s")
	(row.get_node("Icon") as TextureRect).custom_minimum_size = Vector2(s, s)
	set_text_size(row.get_node("Word") as Label, "text_key", true, 1.0)


## NameSuffix (`.suffix`): keycap_h circle, cream fill, ink letter text_key. One letter max.
static func suffix_chip(letter: String) -> PanelContainer:
	var p := _disc("NameSuffix", UI3Theme.color("text"))
	var l := p.get_node("Text") as Label
	l.text = letter.substr(0, 1)
	l.add_theme_color_override("font_color", UI3Theme.color("text_ink"))
	return p


## BigHitBadge (`.bang`): keycap_h circle in intent_bighit_border, cream "!" text_body.
static func bang() -> PanelContainer:
	var p := _disc("BigHitBadge", UI3Theme.color("intent_bighit_border"))
	(p.get_node("Text") as Label).text = "!"
	return p


static func _disc(n: String, fill: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = n
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(fill, UI3Theme.radius("pill")))
	var l := UI3.label("", "LabelDisplay")
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	_size_disc(p)
	return p


static func _size_disc(p: PanelContainer) -> void:
	var k := UI3Theme.size_of("keycap_h")
	p.custom_minimum_size = Vector2(k, k)
	set_text_size(p.get_node("Text") as Label, "text_key" if p.name == "NameSuffix" else "text_body", true, 1.0)


static var _tight := {}


## CSS line-height for a one-line Label: a FontVariation of `base` whose top/bottom spacing trims (or pads) the font's
## own height at `px` to `line_h` px, half on each side (CSS half-leading). Rowdies is much taller than its size, so
## without this every row is ~25 % taller than the frames. Cached per (font, px, line_h).
static func tight_font(base: Font, px: int, line_h: float) -> Font:
	if base == null:
		return null
	var key := "%d:%d:%.1f" % [base.get_instance_id(), px, line_h]
	if _tight.has(key):
		return _tight[key]
	var extra := line_h - base.get_height(px)
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_top = int(floor(extra * 0.5))
	fv.spacing_bottom = int(ceil(extra * 0.5))
	_tight[key] = fv
	return fv


## Label at token `size_key` in the display (Rowdies) or body (Work Sans) face, with CSS line-height `lh` (x size).
static func set_text_size(l: Label, size_key: String, display: bool, lh: float) -> void:
	var px := UI3Theme.size_of(size_key)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_font_override("font", tight_font(UI3Theme.font_display() if display else UI3Theme.font_body(), px,
		float(px) * lh))


## Plate width token: enemy_card_w (boss_plate_w for a boss).
static func card_width(boss: bool) -> int:
	return UI3Theme.size_of("boss_plate_w" if boss else "enemy_card_w")


# ── state ────────────────────────────────────────────────────────────────────────────────────

## Plate edge. The content margin follows the edge width (CSS border-box), so a 4 px edge moves the content in.
func set_border(width: int, col: Color) -> void:
	_style.border_color = col
	if width == _border_w:
		return
	_border_w = width
	_style.set_border_width_all(width)
	_style.set_content_margin_all(float(width))
	intent.set_outer_radius(UI3Theme.radius("l") - width)


## Every size from tokens (build, and again when the window scale changes).
func apply_sizes() -> void:
	custom_minimum_size = Vector2(card_width(is_boss), 0)
	_style.set_corner_radius_all(UI3Theme.radius("l"))
	_margin.add_theme_constant_override("margin_left", UI3Theme.space("16"))
	_margin.add_theme_constant_override("margin_right", UI3Theme.space("16"))
	_margin.add_theme_constant_override("margin_top", UI3Theme.space("12"))
	_margin.add_theme_constant_override("margin_bottom", UI3Theme.space("16"))
	main_box.add_theme_constant_override("separation", UI3Theme.space("8"))
	for h in [name_row, tag_box, tags_row, shell_row]:
		(h as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("8"))
	tag_box.add_theme_constant_override("separation", UI3Theme.space("4"))
	extra_box.add_theme_constant_override("separation", UI3Theme.space("8"))
	set_text_size(name_label, "text_title" if is_boss else "text_body", true, 1.2 if is_boss else 1.3)
	set_text_size(hp_label, "text_body", true, 1.3)
	set_text_size(shell_label, "text_body", true, 1.3)
	hp_bar.set_kind(HPBar.Kind.ENEMY, UI3Theme.size_of("hp_bar_l" if is_boss else "hp_bar_h"), 0, UI3Theme.size_of("text_body"))
	shell_bar.set_kind(HPBar.Kind.SHIELD, UI3Theme.size_of("hp_bar_h"), 0, UI3Theme.size_of("text_body"))
	_size_disc(suffix)
	_size_disc(badge)
	for box in [tag_box, tags_row, shell_row, name_row]:
		for c in (box as Node).get_children():
			if c is PanelContainer and (c as Node).has_meta("tag_kind"):
				size_tag(c as PanelContainer)
	intent.apply_sizes()
	if _border_w >= 0:
		intent.set_outer_radius(UI3Theme.radius("l") - _border_w)


## Inner width EnemyMain has for its rows (plate minus edges, intent column and padding).
func main_inner_width() -> float:
	var bw := maxi(_border_w, 0)
	return float(card_width(is_boss) - 2 * bw - UI3Theme.size_of("enemy_intent_w") - 2 * UI3Theme.space("16"))


## Tags go in the name row while the name keeps at least `min_name` px; else they move to their own row under it.
## Returns true when they are inline.
func place_tags(min_name: float) -> bool:
	var tags: Array = tag_box.get_children() + tags_row.get_children()
	var any := false
	for t in tags:
		if (t as Control).visible:
			any = true
	var fixed := 0.0
	var sep := float(UI3Theme.space("8"))
	for c in name_row.get_children():
		if c == name_label or c == tag_box or not (c as Control).visible:
			continue
		fixed += (c as Control).get_combined_minimum_size().x + sep
	var tags_w := 0.0
	for t in tags:
		if (t as Control).visible:
			tags_w += (t as Control).get_combined_minimum_size().x + float(UI3Theme.space("4"))
	var inline := not any or (main_inner_width() - fixed - (tags_w + sep - float(UI3Theme.space("4"))) >= min_name)
	var dst := tag_box if inline else tags_row
	for t in tags:
		if (t as Node).get_parent() != dst:
			(t as Node).reparent(dst, false)
	tag_box.visible = inline and any
	tags_row.visible = (not inline) and any
	return inline
