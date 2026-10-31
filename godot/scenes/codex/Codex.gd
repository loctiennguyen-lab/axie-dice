extends Control
## The Codex (UI-05 frames 29-codex*, round 3): header plate (Back, Title, SubLine, Codex / Guides / Unlocks tabs), Body =
## [SearchPlate + ReadingPlate] on the left, Topics (codex_topics_w) on the right. Text comes from CodexContent.gd (shared with
## the in-combat InfoPanel). Search: "Results for ..." + one SearchHit per matching topic (topic name + the matching line with the
## word marked); non-matching topics dim. Esc clears the search first, then goes back. Public for tests: `_select_tab(key)`,
## `_body`, `_search`, `_on_search_changed(q)`, `topic_node(key)`, `tile_for(id)`.

const AnchorCardScript := preload("res://scenes/run_map/ui5/AnchorCard.gd")
const BOOK_TABS: Array = [["cores", "CORES"], ["combos", "COMBOS"], ["anchors", "ANCHORS"]]
const BOOK_LEDE := {
	"cores": "Every Core you have been offered. The ones you have not met yet stay a question mark.",
	"combos": "Pairs and Fulls you have put together. Form one in a run to light its tile.",
	"anchors": "Every Anchor you have been offered, taken, and awakened.",
}
const TierWords := ["Moss", "Amber", "Crystal"]
const TierTokens := ["tier_moss", "tier_amber", "tier_crystal"]
const SNIP := 110

var _shell: Dictionary
var _search: LineEdit
var _count: Label
var _title: Label
var _lede: Label
var _body: RichTextLabel
var _status_grid: GridContainer
var _scroll: ScrollContainer
var _topic_col: VBoxContainer
var _stack: VBoxContainer
var _book_grid: GridContainer
var _hits: VBoxContainer
var _no_match: Control
var _current_tab := "basic"
var _topics: Dictionary = {}   # key -> Button
var _anchor_open := ""


func _ready() -> void:
	_shell = UI3Meta.build(self, "Codex", "The rule book", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	Ui5CodexParts.header(_shell, "codex", true)
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(body)
	_build_reading(body)
	_build_topics(body)
	_select_tab(_current_tab)
	call_deferred("_initial_focus")


func _initial_focus() -> void:
	if is_inside_tree() and _search != null:
		_search.grab_focus()


func _on_back() -> void:
	LandNav.back_to_land()


func _unhandled_key_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo and k.is_action_pressed(&"menu_back") and _search != null \
			and not _search.text.is_empty():
		_search.text = ""
		_on_search_changed("")
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _build_reading(host: HBoxContainer) -> void:
	var left := VBoxContainer.new()
	left.name = "Main"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	host.add_child(left)
	var sp := Ui5CodexParts.plate("SearchPlate", UI3Theme.space("8"), UI3Theme.space("12"))
	(sp.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = UI3Theme.space("16")
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", UI3Theme.space("12"))
	sp.add_child(hr)
	_search = LineEdit.new()
	_search.theme = UI3Theme.get_theme()
	_search.name = "SearchField"
	_search.placeholder_text = "Search the rule book"
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(0, UI3Theme.size_of("field_h"))
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_search_changed)
	hr.add_child(_search)
	_count = Ui5Text.label("", "text_body", "text_muted")
	_count.name = "ResultCount"
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(_count)
	left.add_child(sp)

	var panel := Ui5CodexParts.plate("ReadingPlate", UI3Theme.space("24"), UI3Theme.space("24"))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	panel.add_child(col)
	_title = Ui5Text.label("", "text_banner", "text", true)
	_title.name = "Title"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)
	_lede = Ui5Text.label("", "text_body", "text_muted")
	_lede.name = "Lede"
	_lede.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lede)
	_body = RichTextLabel.new()
	_body.name = "Body"
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_override("normal_font", UI3Theme.font_body())
	_body.add_theme_font_override("bold_font", UI3Theme.font_body())
	_body.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	_body.add_theme_font_size_override("bold_font_size", UI3Theme.size_of("text_body"))
	_body.add_theme_color_override("default_color", UI3Theme.color("text"))
	_body.add_theme_constant_override("table_h_separation", 0)
	_body.add_theme_constant_override("table_v_separation", 0)
	_stack = VBoxContainer.new()
	_stack.name = "BodyStack"
	_stack.add_theme_constant_override("separation", UI3Theme.space("12"))
	_stack.add_child(_body)
	_status_grid = _build_status_grid()
	_status_grid.visible = false
	_stack.add_child(_status_grid)
	_book_grid = GridContainer.new()
	_book_grid.columns = 6
	_book_grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	_book_grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	_book_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_grid.visible = false
	_stack.add_child(_book_grid)
	_hits = VBoxContainer.new()
	_hits.name = "Hits"
	_hits.add_theme_constant_override("separation", UI3Theme.space("12"))
	_hits.visible = false
	_stack.add_child(_hits)
	_no_match = CenterContainer.new()
	_no_match.name = "NoMatch"
	_no_match.visible = false
	_stack.add_child(_no_match)
	_scroll = UI3Meta.scroll(_stack)
	_scroll.name = "BodyScroll"
	col.add_child(_scroll)


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
	var panel := Ui5CodexParts.plate("Topics", UI3Theme.space("16"), UI3Theme.space("16"))
	panel.custom_minimum_size = Vector2(UI3Theme.size_of("codex_topics_w"), 0)
	host.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UI3Theme.space("4"))
	panel.add_child(outer)
	var h := Ui5Text.label("Topics", "text_title", "text", true)
	h.name = "TopicsTitle"
	outer.add_child(h)
	_topic_col = VBoxContainer.new()
	_topic_col.name = "TopicList"
	_topic_col.add_theme_constant_override("separation", UI3Theme.space("4"))
	outer.add_child(UI3Meta.scroll(_topic_col))
	for pair in CodexContent.TABS + BOOK_TABS:
		var key: String = pair[0]
		var b := Ui5SettingsParts.index_row(String(pair[1]))
		b.name = "Topic"
		b.set_meta("topic_key", key)
		b.pressed.connect(_on_topic.bind(key))
		_topic_col.add_child(b, true)
		_topics[key] = b


func topic_node(key: String) -> Button:
	return _topics.get(key) as Button


func _on_topic(key: String) -> void:
	if not _search.text.is_empty():
		_search.text = ""
		_on_search_changed("")
	_select_tab(key)


func _topic_hit(key: String, label: String, needle: String) -> bool:
	return label.to_lower().contains(needle) or (not BOOK_LEDE.has(key) and CodexContent.tab_text(key).to_lower().contains(needle))


## Matching topics get a SearchHit under "Results for ..."; the others dim. The count says how many match.
func _on_search_changed(q: String) -> void:
	var needle := q.strip_edges().to_lower()
	if needle.is_empty():
		for k in _topics.keys():
			(_topics[k] as Button).modulate = Color.WHITE
		_count.text = ""
		_select_tab(_current_tab)
		return
	UI3Meta.clear(_hits)
	var n := 0
	for pair in CodexContent.TABS + BOOK_TABS:
		var key: String = pair[0]
		var hit := _topic_hit(key, String(pair[1]), needle)
		(_topics[key] as Button).modulate = Color.WHITE if hit else Color(1, 1, 1, 0.4)
		if hit:
			n += 1
			var t := Ui5CodexParts.hit(String(pair[1]), _snippet(key, needle), needle)
			t.pressable = true
			t.set_meta("topic_key", key)
			t.activated.connect(_on_topic.bind(key))
			_hits.add_child(t, true)
	_count.text = "%d result%s" % [n, "" if n == 1 else "s"]
	_show_mode("results")
	_title.visible = n > 0
	_title.text = "Results for \"%s\"" % q.strip_edges()
	_lede.visible = false
	_hits.visible = n > 0
	_no_match.visible = n == 0
	UI3Meta.clear(_no_match)
	if n == 0:
		var l := Ui5Text.label("Nothing matches '%s'. Clear the search to see every topic." % q.strip_edges(), "text_body", "text")
		l.name = "NoMatchText"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 600
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_no_match.add_child(l)
	_scroll.scroll_vertical = 0


## The first line of the topic that holds the word (a window around it when long); the lede when only the name matched.
func _snippet(key: String, needle: String) -> String:
	if not BOOK_LEDE.has(key):
		for ln in CodexContent.plain_lines(key):
			var i := ln.to_lower().find(needle)
			if i >= 0:
				var a := maxi(0, i - SNIP)
				var b := mini(ln.length(), i + needle.length() + SNIP)
				return ("… " if a > 0 else "") + ln.substr(a, b - a) + (" …" if b < ln.length() else "")
	return String(CodexContent.TAB_LEDE.get(key, BOOK_LEDE.get(key, "")))


func _show_mode(mode: String) -> void:
	_status_grid.visible = mode == "st"
	_book_grid.visible = mode == "book"
	_body.visible = mode == "text"
	_hits.visible = mode == "results"
	_no_match.visible = false
	_title.visible = true
	_lede.visible = true


## Public so `tests/qa_codex_capture.gd` and `tests/t_codex.gd` can drive the screen.
func _select_tab(key: String) -> void:
	_current_tab = key
	for k in _topics.keys():
		Ui5SettingsParts.style_index_row(_topics[k] as Button, k == key)
	_title.text = _tab_label(key)
	_lede.text = String(CodexContent.TAB_LEDE.get(key, BOOK_LEDE.get(key, "")))
	var is_book := BOOK_LEDE.has(key)
	_show_mode("st" if key == "st" else ("book" if is_book else "text"))
	if is_book:
		_fill_book(key)
	elif key != "st":
		_body.text = CodexContent.tab_text(key)
	_scroll.scroll_vertical = 0


func tile_for(id: String) -> Control:
	for t in _book_grid.get_children():
		if String(t.get_meta("book_id", "")) == id:
			return t
	return null


func _fill_book(key: String) -> void:
	_close_anchor_detail()
	UI3Meta.clear(_book_grid)
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
			var r := clampi(int(def.rarity), 0, 2)
			var sub: String = TierWords[r] + (" · Picked" if bool(e.get("picked", false)) else "")
			_add_tile(Ui5CodexParts.tile("BookTile" if seen else "BookTileUnmet", seen, UI3.title_case(UI3.player_text(String(def.name))), sub, UI3Theme.color(TierTokens[r])), String(def.id))
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
			var house := AnchorAdapter.house_id(id)
			var hc := AnchorAdapter.house_color(house)
			var tile := Ui5CodexParts.tile("AnchorTile" if seen else "BookTileUnmet", seen, AnchorAdapter.name_of(id), " · ".join(chips), hc, UI3.icon(AnchorAdapter.house_icon(house)), hc)
			if seen:
				tile.pressable = true
				tile.activated.connect(_show_anchor_detail.bind(id))
			tile.selected = id == _anchor_open
			_add_tile(tile, id)
	else:
		for c in ComboAdapter.all():
			total += 1
			var id := String((c as Dictionary).get("id", ""))
			var e: Dictionary = MetaState.combo_codex.get(id, {})
			var pair := bool(e.get("pair", false))
			var full := bool(e.get("full", false))
			seen_n += 1 if (pair or full) else 0
			var tiers: Array[String] = []
			if pair:
				tiers.append("Pair")
			if full:
				tiers.append("Full")
			var t := Ui5CodexParts.tile("BookTile" if (pair or full) else "BookTileUnmet", pair or full, UI3.title_case(ComboAdapter.display_name(id)), " · ".join(tiers),
				UI3Theme.color("combo_full" if full else "combo_pair"))
			if full:
				t.inset_ring = UI3Theme.color("combo_full")
			_add_tile(t, id)
	if total == 0:
		var l := UI3.label("No combos in this build yet.", "LabelMuted")
		l.name = "BookEmpty"
		_book_grid.add_child(l)
	_lede.text = "%s  %d of %d met." % [BOOK_LEDE[key], seen_n, total]
	_book_grid.name = {"cores": "CoresBook", "combos": "CombosBook", "anchors": "AnchorsBook"}[key]


func _add_tile(t: Control, id: String) -> void:
	t.set_meta("book_id", id)
	_book_grid.add_child(t, true)


## Met Anchor: the shared AnchorCard above the grid; the same tile again closes it.
func _show_anchor_detail(id: String) -> void:
	var same := _anchor_open == id
	_close_anchor_detail()
	if same:
		for t in _book_grid.get_children():
			if t is Ui5CodexTile:
				(t as Ui5CodexTile).selected = false
		return
	_anchor_open = id
	var card: PanelContainer = AnchorCardScript.new()
	card.setup(id)
	card.focus_mode = Control.FOCUS_NONE
	var wrap := CenterContainer.new()
	wrap.name = "AnchorDetail"
	wrap.add_child(card)
	_stack.add_child(wrap)
	_stack.move_child(wrap, _book_grid.get_index())
	for t in _book_grid.get_children():
		if t is Ui5CodexTile:
			(t as Ui5CodexTile).selected = String(t.get_meta("book_id", "")) == id


func _close_anchor_detail() -> void:
	_anchor_open = ""
	if _stack == null:
		return
	var d := _stack.get_node_or_null("AnchorDetail")
	if d != null:
		_stack.remove_child(d)
		d.queue_free()


func _tab_label(key: String) -> String:
	for pair in CodexContent.TABS + BOOK_TABS:
		if String(pair[0]) == key:
			return String(pair[1])
	return key.to_upper()
