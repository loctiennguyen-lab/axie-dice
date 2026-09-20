extends Control
## The Codex — the rule book (godot-port-gap-inventory.md §2.1). All ten tabs are built
## procedurally from CodexContent.gd so the same text can be reused by the in-combat InfoPanel
## (godot/scenes/combat/InfoPanelView.gd) without a second copy.
##
## v2 LAYOUT (docs/design-handoff-v2/mockups-v2/meta-screens-v2.html, CODEX screen — read from
## the mockup's own markup, 2026-09-20). This replaces the stock horizontal Button row over one
## full-width dark RichTextLabel. The mockup draws:
##   - eyebrow "THE RULE BOOK" + a 52px CODEX title at the top
##   - a 294px-wide vertical rail of ten 50px tabs down the left (top 164, left 64)
##   - a cream reading panel to its right (left 382, right 64), radius 18 / 5px outline /
##     7px shelf, with a CREAM_RAISED header strip carrying the current tab's title and the
##     rules text below it
##
## THREE THINGS FROM THAT MOCKUP ARE DELIBERATELY NOT BUILT. All three are authoring metadata
## rather than anything a player reads, and godot/CLAUDE.md forbids shipping a visible
## placeholder. They are named here and in the task report rather than skipped silently:
##
##   1. The per-tab DONE / TODO chip on each rail item. It reports whether the DESIGN team has
##      written that tab's copy yet. Every tab in this build has real, authored text, so the
##      chip would read "DONE" ten times and carry no information at all.
##   2. The "CONTENT IN" / "LAYOUT ONLY · CONTENT PENDING" state chip and the
##      `codex.statuses[] · {icon, name, body}` binding line in the panel header. Both are
##      notes from the designer to the implementer about where the data will come from.
##   3. The six body ARCHETYPES (steps / split / grid / status / cards / table) and their grey
##      skeleton bars, dashed "ICON"/"ART" boxes and striped table rows. Nine of the ten are
##      drawn as empty wireframes, and the mockup's own script says so in as many words:
##      "Codex: layout archetypes only. Copy is authored later against the Godot rules, not
##      lifted from the JS build". CodexContent.gd IS that later-authored copy — it was checked
##      line by line against `godot/scripts/core/` and `godot/autoload/`. Replacing it with the
##      mockup's placeholders would delete the finished work the mockup was asking for.
##
## What that leaves is the mockup's SHELL, built exactly, with the real rules text inside it.
## When the per-archetype Codex content is authored, it drops into `_body`'s place.
##
## Opened as its own scene. MainMenu.gd opens it with:
##   get_tree().change_scene_to_file("res://scenes/codex/Codex.tscn")
## BACK returns to the main menu through the shared footer.

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

## The mockup's own plate for this screen (it is the same temple backdrop the Lunacia Pass
## uses). Resolved through MockupAssets, never as a hand-written res:// string.
const BG_MOCKUP_PLATE := "assets/bg/temple.jpg"

## The mockup's left/right rail for this screen; `content` already supplies 84, so every
## offset below is expressed against that.
const RAIL := 64.0
const TAB_RAIL_W := 294.0
const PANEL_LEFT := 382.0
## Mockup `top:164` for both columns, measured against `content`'s own top edge — which is
## already the 48px safe line, so it is 116 here and not 164.
const COLUMNS_TOP := 164.0 - 48.0

var _tab_row: VBoxContainer
var _body: RichTextLabel
var _panel_title: Label
var _panel_lede: Label              ## X4
var _status_grid: GridContainer     ## X3 - the STATUS EFFECTS tab's body
var _body_scroll: ScrollContainer
var _panel: PanelContainer
var _panel_header: PanelContainer

var _current_tab: String = "basic"
var _tab_buttons: Dictionary = {}   # key -> Button


func _ready() -> void:
	var shell := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PLATE),
		DangoTheme.Scrim.DEFAULT, true)
	var content: Control = shell["content"]
	var footer: HBoxContainer = shell["footer"]

	_build_header(content)
	_build_tab_rail(content)
	_build_reading_panel(content)

	DangoScreen.add_back_button(footer, func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))

	_select_tab(_current_tab)
	get_viewport().size_changed.connect(_apply_body_height)
	_panel.resized.connect(_apply_body_height)
	call_deferred("_apply_body_height")


# ── Page heading ───────────────────────────────────────────────────────────────────────────
## Mockup `top:44`. RESTORED 2026-09-20: this used to be clamped to the old uniform 48px
## safe-area law, which is gone (the law now only checks that nothing is clipped by the
## 1920x1080 canvas edge). `content` starts at the shell's 48px line, so 44 is 4px above it.
func _build_header(content: Control) -> void:
	var col := VBoxContainer.new()
	col.name = "HeaderCol"
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	col.offset_left = RAIL - DangoScreen.RAIL_X
	col.offset_right = DangoScreen.RAIL_X - RAIL
	col.offset_top = 44.0 - 48.0
	col.add_theme_constant_override("separation", 9)
	content.add_child(col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 0)))
	var eyebrow := DangoTheme.display_label("THE RULE BOOK", 14,
		DangoTheme.INK_ON_PRIMARY, 800, 0.16)
	eyebrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eyebrow.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow)
	col.add_child(chip)

	col.add_child(DangoTheme.display_label("CODEX", 52, DangoTheme.CREAM_RAISED, 800, 0.02))


# ── The 294px tab rail ─────────────────────────────────────────────────────────────────────
func _build_tab_rail(content: Control) -> void:
	_tab_row = VBoxContainer.new()
	_tab_row.name = "TabRow"
	_tab_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tab_row.anchor_bottom = 1.0
	_tab_row.offset_left = RAIL - DangoScreen.RAIL_X
	_tab_row.offset_right = RAIL - DangoScreen.RAIL_X + TAB_RAIL_W
	_tab_row.offset_top = COLUMNS_TOP
	_tab_row.offset_bottom = 0.0
	_tab_row.add_theme_constant_override("separation", 7)
	content.add_child(_tab_row)

	_tab_buttons.clear()
	for pair in CodexContent.TABS:
		var key: String = pair[0]
		var label: String = pair[1]
		var b := Button.new()
		b.name = "CodexTab_%s" % key
		b.text = label
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 50)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		b.add_theme_font_size_override("font_size", 15)
		DangoTheme.apply_tracking(b, 0.06, 15)
		b.pressed.connect(_select_tab.bind(key))
		_tab_row.add_child(b)
		_tab_buttons[key] = b
		_add_tab_tag(b)


## X2 — the state tag on the right of a rail tab.
##
## A Button has no second slot, so the chip is a child laid out over the button's own right
## padding rather than a sibling: `justify-content:space-between` in the mockup, an anchored
## overlay here. `mouse_filter = IGNORE` so it never eats the tab's own click.
##
## FLAGGED, and worth a decision: every tab in this build has real authored copy, so all ten
## chips read IN and the column carries no information. The chip was left out of the previous
## pass for exactly that reason; it is built now because the owner asked for the mockup's
## layout. If it reads as noise on screen, this one function is what comes back out.
func _add_tab_tag(btn: Button) -> void:
	var tag := PanelContainer.new()
	tag.name = "Tag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_right = -15.0        # the tab's own 15px right padding
	tag.custom_minimum_size = Vector2(0, 18)
	tag.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.SUCCESS, 5, 2, Vector2(7, 0)))
	btn.add_child(tag)

	var lbl := DangoTheme.display_label("IN", 10, DangoTheme.ink_on(DangoTheme.SUCCESS), 800, 0.08)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_constant_override("line_spacing", 0)   # mockup: line-height 1
	tag.add_child(lbl)


## X3 — STATUS EFFECTS as the mockup's card grid instead of two BBCode tables.
##
## Three columns, one card per status, all eleven in one grid (the helpful/harmful split stays
## on the in-combat InfoPanel, which has no grid — see CodexContent._st()). Built from
## CodexContent.statuses(), so the copy is the build's and the layout is the mockup's.
func _build_status_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "StatusGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for st in CodexContent.statuses():
		var tone: Color = (DangoTheme.INFO if String(st["tone"]) == ""
			else DangoTheme.status_color(String(st["tone"])))

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = DangoTheme.CREAM_RAISED
		card_sb.border_color = Color.BLACK
		card_sb.set_border_width_all(3)
		card_sb.set_corner_radius_all(13)
		card_sb.content_margin_left = 15.0
		card_sb.content_margin_right = 15.0
		card_sb.content_margin_top = 13.0
		card_sb.content_margin_bottom = 13.0
		card.add_theme_stylebox_override("panel", card_sb)
		grid.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		card.add_child(row)

		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(46, 46)
		tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		tile.add_theme_stylebox_override("panel",
			DangoTheme.solid_chip_style(tone, 12, 3, Vector2.ZERO))
		row.add_child(tile)
		var tile_center := CenterContainer.new()
		tile.add_child(tile_center)
		var glyph := TextureRect.new()
		glyph.texture = MockupAssets.tex("assets/fx/%s.png" % String(st["icon"]))
		glyph.custom_minimum_size = Vector2(28, 28)
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile_center.add_child(glyph)

		var text_col := VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 4)   # mockup: rule `margin-top:4`
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_col)

		var name_lbl := DangoTheme.display_label(String(st["name"]), 16, DangoTheme.INK, 800, 0.06)
		name_lbl.add_theme_constant_override("line_spacing", 0)
		text_col.add_child(name_lbl)

		var rule := DangoTheme.prose_label(String(st["rule"]), 12,
			DangoTheme.INK_ON_CREAM_SOFT, 600)
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rule.add_theme_constant_override("line_spacing",
			DangoTheme.leading_for(DangoTheme.FONT_UI_SEMI, 12, 1.45))
		text_col.add_child(rule)

	return grid


## A rail tab: PRIMARY when it is the open one, PANEL when it is not. Radius 11, 3px outline,
## 15px side padding and no shelf, exactly as the mockup draws the pair.
func _style_tab(btn: Button, selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.PRIMARY if selected else DangoTheme.surface_color(
		DangoTheme.Surface.PANEL)
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(11)
	sb.content_margin_left = 15.0
	# X2: the mockup lays the tab out `space-between` — label left, tag chip right. The chip is
	# an overlay child (a Button has no second slot), so the label has to be kept off it by
	# reserving its width here instead: 15 of the mockup's own right padding, plus the chip and
	# a gap. Without this a long tab name ellipsises UNDER the chip rather than before it.
	sb.content_margin_right = 55.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	var hover := sb.duplicate() as StyleBoxFlat
	if not selected:
		hover.bg_color = DangoTheme.PANEL_RAISED
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)

	var ink: Color = DangoTheme.INK_ON_PRIMARY if selected else DangoTheme.INFO_TEXT_ON_WELL
	for color_key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_disabled_color"]:
		btn.add_theme_color_override(color_key, ink)


# ── The cream reading panel ────────────────────────────────────────────────────────────────
func _build_reading_panel(content: Control) -> void:
	_panel = PanelContainer.new()
	_panel.name = "ReadingPanel"
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = PANEL_LEFT - DangoScreen.RAIL_X
	_panel.offset_right = DangoScreen.RAIL_X - RAIL
	_panel.offset_top = COLUMNS_TOP
	_panel.offset_bottom = 0.0
	_panel.clip_contents = true
	_panel.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 18, 5, 7.0))
	DangoTheme.clip_to_frame(_panel)   # G3
	content.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_panel.add_child(col)

	# Header strip — CREAM_RAISED, one black rule along its bottom edge, 15px/24px padding.
	_panel_header = PanelContainer.new()
	_panel_header.name = "PanelHeader"
	var head_sb := StyleBoxFlat.new()
	head_sb.bg_color = DangoTheme.CREAM_RAISED
	head_sb.border_color = Color.BLACK
	head_sb.set_border_width(SIDE_BOTTOM, 4)
	# The card's own radius is 18 with a 5px outline, so its inner corner is 13.
	head_sb.corner_radius_top_left = 13
	head_sb.corner_radius_top_right = 13
	head_sb.content_margin_left = 24.0
	head_sb.content_margin_right = 24.0
	head_sb.content_margin_top = 15.0
	head_sb.content_margin_bottom = 15.0
	_panel_header.add_theme_stylebox_override("panel", head_sb)
	col.add_child(_panel_header)

	# X4 — the header is two columns, not a lone title on an empty band. Left: title over a
	# one-line lede capped at 900. Right: the content-state chip, bottom-aligned against them.
	var head_row := HBoxContainer.new()
	head_row.name = "HeaderRow"
	head_row.add_theme_constant_override("separation", 18)
	head_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_panel_header.add_child(head_row)

	var head_left := VBoxContainer.new()
	head_left.add_theme_constant_override("separation", 4)   # mockup: lede `margin-top:4`
	head_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(head_left)

	_panel_title = DangoTheme.display_label("", 32, DangoTheme.INK, 800, 0.02)
	_panel_title.name = "PanelTitle"
	_panel_title.clip_text = true
	_panel_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_panel_title.add_theme_constant_override("line_spacing", 0)
	head_left.add_child(_panel_title)

	_panel_lede = DangoTheme.prose_label("", 14, DangoTheme.INK_ON_CREAM_MUTED, 600)
	_panel_lede.name = "PanelLede"
	_panel_lede.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_lede.size_flags_horizontal = Control.SIZE_FILL
	# Mockup: `max-width:900` on this line. Not enforced, and deliberately so — a Godot Control
	# has no max-width, and the honest ways to get one (a resize clamp, or a spacer that fights
	# the HBox) would buy nothing here: the panel is ~1100 wide, so after its 24px padding, the
	# 18px gap and the state chip this column already lands within a few px of 900. If the
	# panel ever gets much wider, this is the line that needs the clamp.
	head_left.add_child(_panel_lede)

	var head_right := VBoxContainer.new()
	head_right.alignment = BoxContainer.ALIGNMENT_END
	head_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	head_right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head_right.add_theme_constant_override("separation", 6)
	head_row.add_child(head_right)

	# The mockup's state chip. Every tab in this build has authored copy, so it is CONTENT IN
	# on all ten — see the file header, and the same note on _add_tab_tag().
	#
	# NOT BUILT, deliberately, and reported rather than skipped silently: the 11px mono
	# `codex.statuses[] · {icon, name, body}` binding line the mockup draws under this chip.
	# It is a note from the designer to the implementer about where the data comes from, and
	# putting a code path on a screen a player reads is a different thing from putting a chip
	# there. Two reasons, either sufficient: the project ships no mono font, and the string
	# names an internal API. Say the word and it is four lines.
	var state_chip := PanelContainer.new()
	state_chip.name = "StateChip"
	state_chip.custom_minimum_size = Vector2(0, 24)
	state_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	state_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.SUCCESS, 7, 3, Vector2(10, 0)))
	head_right.add_child(state_chip)
	var state_lbl := DangoTheme.display_label("CONTENT IN", 12,
		DangoTheme.ink_on(DangoTheme.SUCCESS), 800, 0.06)
	state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_lbl.add_theme_constant_override("line_spacing", 0)
	state_chip.add_child(state_lbl)

	var body_margin := MarginContainer.new()
	body_margin.name = "BodyMargin"
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 22)
	body_margin.add_theme_constant_override("margin_right", 22)
	body_margin.add_theme_constant_override("margin_top", 18)
	body_margin.add_theme_constant_override("margin_bottom", 18)
	col.add_child(body_margin)

	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "BodyScroll"
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.clip_contents = true
	DangoTheme.style_scrollbars(_body_scroll)
	body_margin.add_child(_body_scroll)

	_body = RichTextLabel.new()
	_body.name = "Body"
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The rules text is prose — Work Sans, per rule 5 — inked for a CREAM surface rather than
	# for the dark panel this screen used to render on.
	_body.add_theme_font_override("normal_font", DangoTheme.FONT_UI)
	_body.add_theme_font_override("bold_font", DangoTheme.FONT_UI_BOLD)
	_body.add_theme_font_size_override("normal_font_size", 14)
	_body.add_theme_font_size_override("bold_font_size", 14)
	_body.add_theme_color_override("default_color", DangoTheme.INK_ON_CREAM_SOFT)
	_body.add_theme_constant_override("table_h_separation", 18)
	_body.add_theme_constant_override("table_v_separation", 6)

	# X3. The two bodies are siblings in the same scroll region and only one is ever visible;
	# _select_tab() swaps them. A VBox holds both so the ScrollContainer still has exactly one
	# child to size itself against.
	var body_stack := VBoxContainer.new()
	body_stack.name = "BodyStack"
	body_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_stack.add_theme_constant_override("separation", 0)
	_body_scroll.add_child(body_stack)
	body_stack.add_child(_body)
	_status_grid = _build_status_grid()
	_status_grid.visible = false
	body_stack.add_child(_status_grid)


## L3: the reading panel's height comes from its anchors (it runs to the bottom of the content
## column, as the mockup draws it), so the column inside it has to claim that height too —
## otherwise the panel measures as "hundreds of px of empty cream under its content". The
## scroll region takes whatever the header does not.
func _apply_body_height() -> void:
	if _panel == null or _panel_header == null or _body_scroll == null:
		return
	var inner := _panel.size.y - 10.0            # the card's own 5px outline, both edges
	var head := _panel_header.get_combined_minimum_size().y
	var body_h := maxf(0.0, inner - head - 36.0)   # the body margin's 18 top + 18 bottom
	# Only on a real change: this feeds a minimum size back into the layout that just produced
	# `_panel.size`, and re-assigning an identical value every pass would loop `resized`.
	if not is_equal_approx(_body_scroll.custom_minimum_size.y, body_h):
		_body_scroll.custom_minimum_size.y = body_h


## Public so `tests/qa_codex_capture.gd` and `tests/t_codex.gd` can drive the screen — both
## call this by name, so the signature does not change.
func _select_tab(key: String) -> void:
	_current_tab = key
	for k in _tab_buttons.keys():
		var btn: Button = _tab_buttons[k]
		btn.button_pressed = (k == key)
		_style_tab(btn, k == key)
	_panel_title.text = _tab_label(key)
	_panel_lede.text = String(CodexContent.TAB_LEDE.get(key, ""))   # X4
	# X3: STATUS EFFECTS is the one tab with a real layout of its own. Everything else is still
	# the authored BBCode until its archetype is built.
	var is_status := key == "st"
	_status_grid.visible = is_status
	_body.visible = not is_status
	if not is_status:
		_body.text = _ink_for_cream(CodexContent.tab_text(key))
	_body_scroll.scroll_vertical = 0
	call_deferred("_apply_body_height")


## CodexContent's section headings carry one hardcoded colour, picked when this text rendered on
## a dark panel. On the mockup's cream reading surface that colour fails contrast outright. The
## swap happens HERE rather than in CodexContent.gd because the in-combat InfoPanel shares that
## file and still renders on a dark surface — changing the source string would break the screen
## this file does not own.
func _ink_for_cream(bbcode: String) -> String:
	return bbcode.replace("#ffd76a", "#" + DangoTheme.INK.to_html(false))


func _tab_label(key: String) -> String:
	for pair in CodexContent.TABS:
		if String(pair[0]) == key:
			return String(pair[1])
	return key.to_upper()
