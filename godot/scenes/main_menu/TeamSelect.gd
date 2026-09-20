class_name TeamSelect
extends Control
## v2 UI REDESIGN — "Godot Meta Screens v2.dc.html" TEAM tab (design/design-handoff-v2).
## Own screen, split out of MainMenu.gd's old inline team picker (spec-data.js "Main Menu is a
## scrolling form" — the 5-slot hero picker + class passive + six faces used to live in one of
## MainMenu's stacked VBox sections; v2's Main Menu shows a read-only lineup instead and this
## screen owns editing it). The spec-data.js TEAM SELECT entry names its file as
## "MainMenu.tscn (own screen)" — read literally that would mean one shared .tscn switching
## between two layouts, but v2's own three rules ("one hero, one rail" — a screen this dense
## sharing a tree with the title screen would be two screens pretending to be one) and Godot's
## own scene-per-screen convention used by every other meta screen (Vault.tscn, Guides.tscn,
## Codex.tscn, Settings.tscn) both argue for a sibling scene instead. Kept in `scenes/main_menu/`
## because it is still conceptually part of the menu flow and is one of the two files this task
## owns.
##
## HAND-OFF PROTOCOL, reusing `MainMenu.pending_team` (already the channel Guides.tscn's
## "USE THIS TEAM" uses — see that scene's `hand_team_to_menu()`): MainMenu seeds
## `pending_team` with its current `_team_selection` before navigating here; this screen reads
## it once in `_ready()` (falling back to `MainMenu.DEFAULT_TEAM` if empty, e.g. a fresh boot
## that somehow lands here directly) and CLEARS it. CONFIRM TEAM sets `pending_team` to the
## edited roster and returns to MainMenu, which picks it up exactly the same way it already
## does for a Guides hand-off. No back/cancel affordance exists in the mockup's own top bar
## (only SAMPLE TEAMS and CONFIRM TEAM) — every path back through this screen commits the
## current picks, matching the mockup exactly.
##
## OMITTED FROM THIS PASS: the mockup's bottom "THIS COMP LEANS" archetype strip. Its own demo
## data (`archChips`: BULWARK/PLAGUE/AEGIS) is hardcoded and does not react to the five hero
## picks above it, and does not even match `ContentDB.GUIDES`' own archetype names
## (BULWARK/PLAGUE/APEX/CONDUIT) — it reads as unfinished demo copy, not a specified formula.
## Inventing a "which archetype does this comp lean toward" classifier is gameplay-analysis
## logic with no design spec behind it (out of scope for UI-programmer work — see this agent's
## "must NOT implement gameplay logic in UI code" rule). Flagged for design/ux to spec a real
## rule; left out rather than guessed at.

const _CLASS_ORDER: Array[String] = ["plant", "beast", "aqua", "reptile", "bug", "bird"]

var _team_selection: Array[String] = []

# One entry per slot: option (OptionButton), header_panel/header_name/header_cls,
# band_panel/portrait/tier_badge/hp_badge, passive_name/passive_text, faces_grid.
var _cards: Array[Dictionary] = []


func _ready() -> void:
	if not MainMenu.pending_team.is_empty():
		_team_selection = MainMenu.pending_team.duplicate()
		MainMenu.pending_team = []
	else:
		_team_selection = MainMenu.DEFAULT_TEAM.duplicate()
	_build_ui()


func _build_ui() -> void:
	var plate_host := Control.new()
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load("res://assets/backgrounds/origins/scene/5-crossroad.jpg"), DangoTheme.Scrim.DEFAULT)

	_build_header()

	var row := HBoxContainer.new()
	row.name = "TeamSlots"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 56
	row.offset_right = -56
	row.offset_top = 150
	row.add_theme_constant_override("separation", 14)
	add_child(row)

	_cards.clear()
	for i in MainMenu.TEAM_SIZE:
		row.add_child(_build_card(i))


func _build_header() -> void:
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wrap.offset_left = 56
	wrap.offset_right = -56
	wrap.offset_top = 42
	wrap.custom_minimum_size = Vector2(0, 54)
	add_child(wrap)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_col)

	var title := Label.new()
	title.text = "CHOOSE YOUR TEAM"
	title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	title_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "5 Tier-1 Axies · duplicates allowed · every run starts at Tier 1"
	subtitle.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	title_col.add_child(subtitle)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 11)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(buttons)

	var sample_btn := Button.new()
	sample_btn.name = "SampleTeamsButton"
	sample_btn.text = "SAMPLE TEAMS"
	sample_btn.custom_minimum_size = Vector2(0, 54)
	DangoTheme.style_button(sample_btn, false)
	sample_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	sample_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/guides/Guides.tscn"))
	buttons.add_child(sample_btn)

	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmTeamButton"
	confirm_btn.text = "CONFIRM TEAM"
	confirm_btn.custom_minimum_size = Vector2(0, 54)
	DangoTheme.style_button(confirm_btn, true)
	confirm_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_btn)


func _on_confirm_pressed() -> void:
	MainMenu.pending_team = _team_selection.duplicate()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# ===========================================================================
# One team card — mockup box: flex, header 40, hero band 186 (art 164),
# HP badge h 32, face cell pad 8/9, face value 24.
# ===========================================================================

func _build_card(index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 17, 5, 7.0))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 40)
	col.add_child(header)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var header_name := Label.new()
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_name.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	header_name.add_theme_font_size_override("font_size", 21)
	header_name.add_theme_color_override("font_color", DangoTheme.INK)
	header_row.add_child(header_name)
	var header_cls := Label.new()
	header_cls.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	header_cls.add_theme_font_size_override("font_size", 14)
	header_cls.add_theme_color_override("font_color", DangoTheme.INK)
	header_row.add_child(header_cls)

	var body_margin := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		body_margin.add_theme_constant_override("margin_%s" % side, 13)
	body_margin.add_theme_constant_override("margin_top", 12)
	col.add_child(body_margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body_margin.add_child(body)

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, 36)
	var pick_sb := StyleBoxFlat.new()
	pick_sb.bg_color = DangoTheme.CREAM_RAISED
	pick_sb.border_color = Color.BLACK
	pick_sb.set_border_width_all(3)
	pick_sb.set_corner_radius_all(10)
	pick_sb.content_margin_left = 11.0
	pick_sb.content_margin_right = 11.0
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		option.add_theme_stylebox_override(state_key, pick_sb)
	option.add_theme_color_override("font_color", DangoTheme.INK)
	option.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	option.add_theme_font_size_override("font_size", 14)
	for hero_key in MainMenu.T1_HERO_KEYS:
		var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
		option.add_item("%s (%s)" % [String(hero_def.get("n", hero_key)),
			String(hero_def.get("cls", "")).capitalize()])
	option.select(max(0, MainMenu.T1_HERO_KEYS.find(_team_selection[index])))
	option.item_selected.connect(func(idx: int) -> void:
		_team_selection[index] = MainMenu.T1_HERO_KEYS[idx]
		_refresh_card(index))
	body.add_child(option)

	var band := Control.new()
	band.custom_minimum_size = Vector2(0, 186)
	body.add_child(band)

	var band_panel := Panel.new()
	band_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var band_sb := StyleBoxFlat.new()
	band_sb.border_color = Color.BLACK
	band_sb.set_border_width_all(3)
	band_sb.set_corner_radius_all(14)
	band_panel.add_theme_stylebox_override("panel", band_sb)
	band.add_child(band_panel)

	var portrait_wrap := CenterContainer.new()
	portrait_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(portrait_wrap)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(164, 164)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_wrap.add_child(portrait)

	var tier_badge := _make_overlay_badge(band, Control.PRESET_BOTTOM_LEFT, Vector2(9, -9 - 26),
		Color(0, 0, 0, 0.36), DangoTheme.CREAM_RAISED, 12)
	var hp_badge := _make_overlay_badge(band, Control.PRESET_BOTTOM_RIGHT, Vector2(-9 - 70, -9 - 32),
		DangoTheme.CREAM_RAISED, DangoTheme.INK, 20)

	var passive_panel := PanelContainer.new()
	var passive_sb := StyleBoxFlat.new()
	passive_sb.bg_color = DangoTheme.PRIMARY
	passive_sb.border_color = Color.BLACK
	passive_sb.set_border_width_all(3)
	passive_sb.set_corner_radius_all(11)
	passive_sb.content_margin_left = 11.0
	passive_sb.content_margin_right = 11.0
	passive_sb.content_margin_top = 10.0
	passive_sb.content_margin_bottom = 10.0
	passive_panel.add_theme_stylebox_override("panel", passive_sb)
	body.add_child(passive_panel)

	var passive_col := VBoxContainer.new()
	passive_col.add_theme_constant_override("separation", 4)
	passive_panel.add_child(passive_col)
	var passive_name := Label.new()
	passive_name.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	passive_name.add_theme_font_size_override("font_size", 13)
	passive_name.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	passive_col.add_child(passive_name)
	var passive_text := Label.new()
	passive_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_text.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	passive_text.add_theme_font_size_override("font_size", 12)
	passive_text.add_theme_color_override("font_color", Color(0x3A / 255.0, 0x1E / 255.0, 0x07 / 255.0))
	passive_col.add_child(passive_text)

	var faces_caption := Label.new()
	faces_caption.text = "SIX FACES"
	faces_caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	faces_caption.add_theme_font_size_override("font_size", 12)
	faces_caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	body.add_child(faces_caption)

	var faces_grid := GridContainer.new()
	faces_grid.columns = 2
	faces_grid.add_theme_constant_override("h_separation", 8)
	faces_grid.add_theme_constant_override("v_separation", 8)
	body.add_child(faces_grid)

	_cards.append({
		"option": option, "header_panel": header, "header_name": header_name,
		"header_cls": header_cls, "band_panel": band_panel, "portrait": portrait,
		"tier_badge": tier_badge, "hp_badge": hp_badge, "passive_panel": passive_panel,
		"passive_name": passive_name, "passive_text": passive_text, "faces_grid": faces_grid,
	})
	_refresh_card(index)
	return card


func _make_overlay_badge(band: Control, corner: Control.LayoutPreset, offset: Vector2,
		bg: Color, ink: Color, font_size: int) -> Label:
	var badge := PanelContainer.new()
	badge.set_anchors_preset(corner)
	badge.position = offset
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color.BLACK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 9.0
	sb.content_margin_right = 9.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	badge.add_theme_stylebox_override("panel", sb)
	band.add_child(badge)

	var lbl := Label.new()
	lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", ink)
	badge.add_child(lbl)
	return lbl


func _refresh_card(index: int) -> void:
	var card: Dictionary = _cards[index]
	var hero_key := _team_selection[index]
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))
	var accent := DangoTheme.class_color(cls)

	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = accent
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 4)
	header_sb.content_margin_left = 13.0
	header_sb.content_margin_right = 13.0
	header_sb.content_margin_top = 8.0
	header_sb.content_margin_bottom = 8.0
	(card["header_panel"] as PanelContainer).add_theme_stylebox_override("panel", header_sb)
	(card["header_name"] as Label).text = String(hero_def.get("n", hero_key))
	(card["header_cls"] as Label).text = cls.to_upper()

	((card["band_panel"] as Panel).get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent

	var portrait: TextureRect = card["portrait"]
	var portrait_path := "res://assets/portraits/%s.png" % cls
	portrait.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null

	(card["tier_badge"] as Label).text = "TIER %d" % int(hero_def.get("tier", 1))
	(card["hp_badge"] as Label).text = "%d HP" % int(hero_def.get("max_hp", 0))

	# The passive text — straight from ContentDB.CLASS_PASSIVE, never retyped. This is the
	# figure the task brief calls out by name: "the game applies FERAL today and never tells
	# the player FERAL exists". v2's whole point for this screen is putting it on-screen, in a
	# block big enough to read, not hidden behind a hover or a wiki.
	var passive: Dictionary = ContentDB.CLASS_PASSIVE.get(cls, {})
	var passive_name: Label = card["passive_name"]
	var passive_text: Label = card["passive_text"]
	if passive.is_empty():
		passive_name.text = "PASSIVE · NOT DEFINED"
		passive_text.text = "This class has no passive defined yet."
	else:
		passive_name.text = "PASSIVE · %s" % String(passive.get("n", ""))
		passive_text.text = String(passive.get("d", ""))

	var grid: GridContainer = card["faces_grid"]
	for c in grid.get_children():
		c.queue_free()
	for face in (hero_def.get("die", []) as Array):
		grid.add_child(_build_face_cell(face as Dictionary, cls))


## Cream face cell — mockup box: pad 8/9, icon 22, value 24, swatch 18x18, caption 10px,
## keyword 10px. Icon path mirrors CombatView._face_icon_for()'s convention
## (`res://assets/icons/web/part/<slot>_<class>.svg`); falls back to no icon rather than
## crashing if a slot/class combination has no art yet.
func _build_face_cell(face: Dictionary, cls: String) -> PanelContainer:
	var face_type := String(face.get("type", ""))
	var part := String(face.get("part", ""))
	var accent := DangoTheme.die_type_color(face_type)

	var cell := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_RAISED
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 9.0
	sb.content_margin_right = 9.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	cell.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	cell.add_child(col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 7)
	col.add_child(top_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path := "res://assets/icons/web/part/%s_%s.svg" % [part, cls]
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	top_row.add_child(icon)

	var value_lbl := Label.new()
	var value := int(face.get("value", 0))
	value_lbl.text = "•" if (face_type == "buff" or face_type == "debuff") else str(value)
	value_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	value_lbl.add_theme_font_size_override("font_size", 24)
	value_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	top_row.add_child(value_lbl)

	var swatch := PanelContainer.new()
	swatch.custom_minimum_size = Vector2(18, 18)
	var swatch_sb := StyleBoxFlat.new()
	swatch_sb.bg_color = accent
	swatch_sb.border_color = Color.BLACK
	swatch_sb.set_border_width_all(2)
	swatch_sb.set_corner_radius_all(6)
	swatch.add_theme_stylebox_override("panel", swatch_sb)
	top_row.add_child(swatch)

	var caption := Label.new()
	caption.text = "%s · %s" % [part.to_upper(), face_type.to_upper()]
	caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	col.add_child(caption)

	var kw_lbl := Label.new()
	kw_lbl.text = _format_keywords(face.get("keywords", []))
	kw_lbl.custom_minimum_size = Vector2(0, 12)
	kw_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	kw_lbl.add_theme_font_size_override("font_size", 10)
	kw_lbl.add_theme_color_override("font_color", Color(0xB4 / 255.0, 0x60 / 255.0, 0x0C / 255.0))
	col.add_child(kw_lbl)

	return cell


func _format_keywords(keywords: Array) -> String:
	if keywords.is_empty():
		return ""
	var parts: Array[String] = []
	for k in keywords:
		parts.append(String(k).replace(":", " ").to_upper())
	return " · ".join(parts)
