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
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE and _search != null \
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
	for pair in CodexContent.TABS:
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
	for pair in CodexContent.TABS:
		var key: String = pair[0]
		var hit := needle.is_empty() or String(pair[1]).to_lower().contains(needle) \
			or CodexContent.tab_text(key).to_lower().contains(needle)
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
	_lede.text = String(CodexContent.TAB_LEDE.get(key, ""))
	var is_status := key == "st"
	_status_grid.visible = is_status
	_body.visible = not is_status
	if not is_status:
		_body.text = CodexContent.tab_text(key)
	_scroll.scroll_vertical = 0


func _tab_label(key: String) -> String:
	for pair in CodexContent.TABS:
		if String(pair[0]) == key:
			return String(pair[1])
	return key.to_upper()
