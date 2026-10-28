extends PanelContainer
## UI-05 RewardCard (31-reward): fixed reward_card_w x reward_card_h plate, padding 20, gap 12, radius xl.
## Tree (data-names): RewardCard > Column > [CatRow(Category, RarityChip), RewardArt(icon), RewardName, ...].
## The caller adds the body under `column` (RewardBody, GainBox / GambleBox / CurseBox, Core chips...).
## Rarity is a filled chip and the colour of the art edge. Selected = 4 px cream ring outside the card and a
## 12 px lift (re-applied after every sort of the parent row); focus = the sky ring outside that.
## GachaReveal relies on child 0 being the content column: keep it first.

const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")

var column: VBoxContainer
var cat_row: HBoxContainer
var rarity_chip: PanelContainer
var art: Panel
var art_icon: TextureRect
var name_label: Label
var selected := false
var accent := Color.WHITE
var _prism := false


## category: muted word top-left ("Max HP", "Core"). rarity_word / rarity_col: the filled chip and the art edge.
## icon: art glyph. name: Rowdies 32 (wraps to 2 lines, never clipped).
func setup(category: String, rarity_word: String, rarity_col: Color, icon: Texture2D, title: String) -> void:
	theme = UI3Theme.get_theme()
	accent = rarity_col
	var pad := UI3Theme.space("20")
	add_theme_stylebox_override("panel", PanelParts.plate_box("xl", pad))
	custom_minimum_size = Vector2(UI3Theme.size_of("reward_card_w"), UI3Theme.size_of("reward_card_h"))
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", UI3Theme.space("12"))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	cat_row = HBoxContainer.new()
	cat_row.name = "CatRow"
	cat_row.add_theme_constant_override("separation", UI3Theme.space("8"))
	cat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cat_row)
	var cat := PanelParts.text(category, "text_body", "text_muted")
	cat.name = "Category"
	cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cat_row.add_child(cat)
	rarity_chip = rarity_chip_of(rarity_word, rarity_col)
	cat_row.add_child(rarity_chip)

	art = Panel.new()
	art.name = "RewardArt"
	art.custom_minimum_size = Vector2(0, UI3Theme.size_of("reward_art_h"))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected"), rarity_col))
	column.add_child(art)
	var px := UI3Theme.size_of("d_reward_icon")
	art_icon = PanelParts.icon_rect(icon, px)
	art_icon.set_anchors_preset(Control.PRESET_CENTER)
	art_icon.offset_left = -px / 2.0
	art_icon.offset_right = px / 2.0
	art_icon.offset_top = -px / 2.0
	art_icon.offset_bottom = px / 2.0
	art.add_child(art_icon)

	name_label = PanelParts.text(title, "text_screen_title", "text", true)
	name_label.name = "RewardName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.x = UI3Theme.size_of("reward_card_w") - 2 * pad
	column.add_child(name_label)

	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


## `.rarity-chip`: keycap-high pill filled with the rarity colour, Rowdies 16 in text_ink. Children: "Text".
static func rarity_chip_of(word: String, col: Color) -> PanelContainer:
	var pad := UI3Theme.space("12")
	var chip := PanelParts.panel(UI3Theme.flat(col, UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(pad, 0, pad, 0)), "RarityChip")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := PanelParts.text(word, "text_key", "text_ink", true)
	l.name = "Text"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(l)
	return chip


## `.trade` box: Gain = success_bg + success_text label; Gamble / Curse = danger_bg + danger_text label. Label is a
## word (Rowdies 18), body Work Sans 18 cream. Named GainBox / GambleBox / CurseBox; children "TradeLabel" / "TradeText".
static func trade_box(kind: StringName, body: String) -> PanelContainer:
	var gain := kind == &"gain"
	var words := {&"gain": "Gain", &"gamble": "Gamble", &"curse": "Curse"}
	var node_names := {&"gain": "GainBox", &"gamble": "GambleBox", &"curse": "CurseBox"}
	var pv := UI3Theme.space("12")
	var ph := UI3Theme.space("16")
	var box := PanelParts.panel(UI3Theme.flat(UI3Theme.color("success_bg" if gain else "danger_bg"), UI3Theme.radius("m"),
		0, Color.TRANSPARENT, Vector4(ph, pv, ph, pv)), String(node_names.get(kind, "CurseBox")))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	var l := PanelParts.text(TranslationServer.translate(String(words.get(kind, "Curse"))), "text_body",
		"success_text" if gain else "danger_text", true)
	l.name = "TradeLabel"
	v.add_child(l)
	var b := PanelParts.text(body)
	b.name = "TradeText"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	return box


## Crystal Core (gacha A3): the prism silhouette replaces the plate; its border turns cream when selected.
func use_prism(style_sel: Callable) -> void:
	_prism = true
	set_meta("prism_style", style_sel)
	add_theme_stylebox_override("panel", style_sel.call(false))


func set_selected(on: bool) -> void:
	selected = on
	if _prism:
		add_theme_stylebox_override("panel", (get_meta("prism_style") as Callable).call(on))
	queue_redraw()


## Lift applied by the row after it sorts its children (design: selected lifts 12).
func lift_px() -> float:
	return float(UI3Theme.space("12")) if selected else 0.0


func _draw() -> void:
	var rad := UI3Theme.radius("xl")
	var r := Rect2(Vector2.ZERO, size)
	var sel_w := UI3Theme.stroke("selected")
	if selected and not _prism:
		draw_style_box(PanelParts.ring_style(UI3Theme.color("selected"), sel_w, 0, rad), r)
	if has_focus():
		# Sky focus ring, gap 4 outside the card (outside the cream ring when selected).
		var gap := UI3Theme.stroke("focus_gap") + (sel_w if selected else 0)
		draw_style_box(PanelParts.ring_style(UI3Theme.color("focus_ring"), UI3Theme.stroke("focus"), gap, rad), r)
