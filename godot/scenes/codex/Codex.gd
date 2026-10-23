extends Control
## The Codex (UI-03 round-2 screen 29, on UI3Meta): the rule book. Header tabs Codex / Guides / Unlocks,
## content = search plate + reading plate (title, lede, rules text or the status card grid), right 440 plate =
## the topic list. Text still comes from CodexContent.gd (shared with the in-combat InfoPanel), so there is one
## copy of the rules. Esc clears the search first, then goes back. Public for t_codex / qa_codex_capture:
## `_select_tab(key)`, `_body`.

const READ_W := 920   # max reading measure, px (spec 29: 880-960)
const DETAIL_W := 440

var _shell: Dictionary
var _search: LineEdit
var _count: Label
var _title: Label
var _lede: Label
var _body: RichTextLabel
var _status_grid: GridContainer
var _scroll: ScrollContainer
var _topic_col: VBoxContainer
var _no_match: Label
var _current_tab := "basic"
var _tab_buttons: Dictionary = {}   # key -> Button
## Lane GM (D1): the Core book and the Combo book. Tiles are built from MetaState.core_codex / combo_codex.
const BOOK_TABS: Array = [["cores", "CORES"], ["combos", "COMBOS"], ["anchors", "ANCHORS"]]
const BOOK_LEDE := {
	"cores": "Every Core you have been offered. The ones you have not met yet stay a question mark.",
	"combos": "Pairs and Fulls you have put together. Form one in a run to light its tile.",
	"anchors": "Every Anchor you have been offered, taken, and awakened.",
}
var _book_grid: GridContainer


func _ready() -> void:
	_shell = UI3Meta.build(self, "Codex", "The rule book", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	UI3Meta.doc_tabs(_shell, "codex")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(body)
	_build_reading(body)
	_build_topics(body)
	_select_tab(_current_tab)


func _on_back() -> void:
	LandNav.back_to_land()


func _unhandled_key_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo and k.is_action_pressed(&"menu_back") and _search != null \
			and not _search.text.is_empty():
		_search.text = ""
		_on_search_changed("")
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
		return
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _build_reading(host: HBoxContainer) -> void:
	var left := VBoxContainer.new()
	left.name = "Content"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	host.add_child(left)
	var head := UI3.plate(&"plate")
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", UI3Theme.space("16"))
	head.add_child(hr)
	_search = LineEdit.new()
	_search.theme = UI3Theme.get_theme()
	_search.name = "SearchField"
	_search.placeholder_text = "Search the rule book"
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(0, 56)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_search_changed)
	hr.add_child(_search)
	_count = UI3.label("", "LabelMuted")
	_count.name = "SearchCount"
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(_count)
	left.add_child(head)

	var panel := UI3.plate(&"plate")
	panel.name = "ReadingPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	panel.add_child(col)
	_title = UI3.label("", "LabelScreenTitle")
	_title.name = "PanelTitle"
	col.add_child(_title)
	_lede = UI3.label("", "LabelMuted")
	_lede.name = "PanelLede"
	_lede.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lede)
	_body = RichTextLabel.new()
	_body.name = "Body"
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	# Readable measure (spec 29): the reading column is capped, not stretched across the panel.
	_body.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_body.custom_minimum_size.x = READ_W
	_body.add_theme_font_override("normal_font", UI3Theme.font_body())
	_body.add_theme_font_override("bold_font", UI3Theme.font_body())
	_body.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	_body.add_theme_font_size_override("bold_font_size", UI3Theme.size_of("text_body"))
	_body.add_theme_color_override("default_color", UI3Theme.color("text"))
	_body.add_theme_constant_override("table_h_separation", 18)
	_body.add_theme_constant_override("table_v_separation", 6)
	var stack := VBoxContainer.new()
	stack.name = "BodyStack"
	stack.add_theme_constant_override("separation", 0)
	stack.add_child(_body)
	_status_grid = _build_status_grid()
	_status_grid.visible = false
	stack.add_child(_status_grid)
	_book_grid = GridContainer.new()
	_book_grid.name = "BookGrid"
	_book_grid.columns = 3
	_book_grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	_book_grid.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	_book_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_grid.visible = false
	stack.add_child(_book_grid)
	_scroll = UI3Meta.scroll(stack)
	_scroll.name = "BodyScroll"
	col.add_child(_scroll)
	_no_match = UI3.label("", "LabelMuted")
	_no_match.name = "NoMatch"
	_no_match.visible = false
	col.add_child(_no_match)


func _build_status_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "StatusGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for st in CodexContent.statuses():
		var card := UI3.plate(&"card")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		card.add_child(row)
		var glyph := TextureRect.new()
		glyph.texture = MockupAssets.tex("assets/fx/%s.png" % String(st["icon"]))
		glyph.custom_minimum_size = Vector2(48, 48)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(glyph)
		var tc := VBoxContainer.new()
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.add_theme_constant_override("separation", UI3Theme.space("8"))
		row.add_child(tc)
		tc.add_child(UI3.label(String(st["name"]), "LabelTitle"))
		var rule := UI3.label(String(st["rule"]), "LabelMuted")
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tc.add_child(rule)
		grid.add_child(card)
	return grid


func _build_topics(host: HBoxContainer) -> void:
	var panel := UI3.plate(&"plate")
	panel.name = "TopicPanel"
	panel.custom_minimum_size = Vector2(DETAIL_W, 0)
	host.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UI3Theme.space("16"))
	panel.add_child(outer)
	outer.add_child(UI3.label("Topics", "LabelScreenTitle"))
	_topic_col = VBoxContainer.new()
	_topic_col.name = "TabRow"
	_topic_col.add_theme_constant_override("separation", UI3Theme.space("8"))
	outer.add_child(UI3Meta.scroll(_topic_col))
	for pair in CodexContent.TABS + BOOK_TABS:
		var key: String = pair[0]
		var b := UI3Meta.tab(String(pair[1]), false)
		b.name = "CodexTab_%s" % key
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_select_tab.bind(key))
		_topic_col.add_child(b)
		_tab_buttons[key] = b


## Topics whose title or text contains the query stay; the others are hidden. The count says how many remain.
func _on_search_changed(q: String) -> void:
	var needle := q.strip_edges().to_lower()
	var n := 0
	var first := ""
	for pair in CodexContent.TABS + BOOK_TABS:
		var key: String = pair[0]
		var hit := needle.is_empty() or String(pair[1]).to_lower().contains(needle) \
			or (not BOOK_LEDE.has(key) and CodexContent.tab_text(key).to_lower().contains(needle))
		(_tab_buttons[key] as Button).visible = hit
		if hit:
			n += 1
			if first.is_empty():
				first = key
	_count.text = "" if needle.is_empty() else ("%d result%s" % [n, "" if n == 1 else "s"])
	_no_match.visible = n == 0
	_no_match.text = "" if n > 0 else "Nothing matches '%s'. Clear the search to see every topic." % q.strip_edges()
	if n > 0 and not (_tab_buttons[_current_tab] as Button).visible:
		_select_tab(first)


## Public so `tests/qa_codex_capture.gd` and `tests/t_codex.gd` can drive the screen.
func _select_tab(key: String) -> void:
	_current_tab = key
	for k in _tab_buttons.keys():
		(_tab_buttons[k] as Button).button_pressed = (k == key)
	_title.text = _tab_label(key)
	_lede.text = String(CodexContent.TAB_LEDE.get(key, BOOK_LEDE.get(key, "")))
	var is_status := key == "st"
	var is_book := BOOK_LEDE.has(key)
	_status_grid.visible = is_status
	_book_grid.visible = is_book
	_body.visible = not is_status and not is_book
	if is_book:
		_fill_book(key)
	elif not is_status:
		_body.text = CodexContent.tab_text(key)
	_scroll.scroll_vertical = 0


## One tile per Core / combo. Unmet = dimmed plate with "?" (the name is NOT in the tree, so it cannot leak).
func _fill_book(key: String) -> void:
	UI3Meta.clear(_book_grid)
	_close_anchor_detail()
	var seen_n := 0
	var total := 0
	if key == "cores":
		for def in RelicRegistry.all_defs_sorted():
			if not RelicSlots.is_core(def) or def.disabled or int(def.rarity) > 2:
				continue
			total += 1
			var e: Dictionary = MetaState.core_codex.get(String(def.id), {})
			var seen := bool(e.get("seen", false))
			seen_n += 1 if seen else 0
			var tier: String = TierWords[clampi(int(def.rarity), 0, 2)]
			var chips: Array[String] = []
			if bool(e.get("picked", false)):
				chips.append("Picked")
			_book_grid.add_child(_tile("CoreTile_%s" % def.id, seen, UI3.title_case(UI3.player_text(String(def.name))),
				tier + (" · " + ", ".join(chips) if not chips.is_empty() else "")))
	elif key == "anchors":
		for a in Anchors.enabled():
			total += 1
			var id := String((a as Dictionary).get("id", ""))
			var e: Dictionary = MetaState.anchor_codex.get(id, {})
			var seen := bool(e.get("seen", false))
			seen_n += 1 if seen else 0
			var chips: Array[String] = []
			if bool(e.get("picked", false)):
				chips.append("Picked")
			if bool(e.get("awakened", false)):
				chips.append("Awakened")
			var tile := _tile("AnchorTile_%s" % id, seen, AnchorAdapter.name_of(id),
				AnchorAdapter.house_name(AnchorAdapter.house_id(id)) + (" · " + ", ".join(chips) if not chips.is_empty() else ""))
			if seen:   # click a met Anchor: its Rule / Price / Awakens (same blocks as the pick screen)
				tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				tile.gui_input.connect(func(ev: InputEvent) -> void:
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						_show_anchor_detail(id))
			_book_grid.add_child(tile)
	else:
		for c in ComboAdapter.all():
			total += 1
			var id := String((c as Dictionary).get("id", ""))
			var e: Dictionary = MetaState.combo_codex.get(id, {})
			var seen := bool(e.get("pair", false)) or bool(e.get("full", false))
			seen_n += 1 if seen else 0
			var tiers: Array[String] = []
			if bool(e.get("pair", false)):
				tiers.append("Pair")
			if bool(e.get("full", false)):
				tiers.append("Full")
			_book_grid.add_child(_tile("ComboTile_%s" % id, seen, UI3.title_case(ComboAdapter.display_name(id)), " · ".join(tiers)))
	if total == 0:
		var l := UI3.label("No combos in this build yet.", "LabelMuted")
		l.name = "BookEmpty"
		_book_grid.add_child(l)
	_lede.text = "%s  %d of %d met." % [BOOK_LEDE[key], seen_n, total]


## Detail of one met Anchor above the grid; clicking the same tile (or the panel) again closes it.
func _show_anchor_detail(id: String) -> void:
	var was := _book_grid.get_parent().get_node_or_null("AnchorDetail")
	var same: bool = was != null and String(was.get_meta("anchor_id", "")) == id
	_close_anchor_detail()
	if same:
		return
	var house := AnchorAdapter.house_id(id)
	var panel := UI3.plate(&"card")
	panel.name = "AnchorDetail"
	panel.set_meta("anchor_id", id)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_anchor_detail())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var top := UI3.label("%s · %s" % [AnchorAdapter.name_of(id), AnchorAdapter.house_name(house)], "LabelTitle")
	top.name = "DetailTitle"
	top.add_theme_color_override("font_color", AnchorAdapter.house_color(house))
	col.add_child(top)
	AnchorPick.add_text_blocks(col, id)
	var par := _book_grid.get_parent()
	par.add_child(panel)
	par.move_child(panel, _book_grid.get_index())


func _close_anchor_detail() -> void:
	var d := _book_grid.get_parent().get_node_or_null("AnchorDetail") if _book_grid != null and _book_grid.get_parent() != null else null
	if d != null:
		d.get_parent().remove_child(d)
		d.queue_free()


const TierWords := ["Moss", "Amber", "Crystal"]


func _tile(node_name: String, seen: bool, title: String, sub: String) -> Control:
	var card := UI3.plate(&"card")
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 96
	card.set_meta("seen", seen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	card.add_child(v)
	var t := UI3.label(title if seen else "?", "LabelTitle")
	t.name = "TileName"
	v.add_child(t)
	var s := UI3.label((sub if sub != "" else TranslationServer.translate("Met")) if seen else TranslationServer.translate("Not met yet"), "LabelMuted")
	s.name = "TileSub"
	v.add_child(s)
	# Border only separates tiles: the normal (disabled_border) token, same for met and unmet. Inner padding so the
	# "?" / name never touches the edge. Met vs unmet reads from the text (name + tier vs "?" + "Not met yet").
	card.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"),
		UI3Theme.stroke("hairline"), UI3Theme.color("disabled_border"), Vector4(16, 12, 16, 12)))
	if not seen:
		t.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	return card


func _tab_label(key: String) -> String:
	for pair in CodexContent.TABS + BOOK_TABS:
		if String(pair[0]) == key:
			return String(pair[1])
	return key.to_upper()
