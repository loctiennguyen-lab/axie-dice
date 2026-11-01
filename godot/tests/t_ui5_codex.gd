extends Node
## UI-05 b23 lane S13: Codex frames 29-codex*. data-names, 3 header tabs, books, search "poison" -> Results + matching lines,
## no match, 1920 + 1280, inside the frame, align pairs > 0, text >= 14 real px at 1280, initial focus.
## Run: godot --headless --path godot res://tests/t_ui5_codex.tscn
const Align := preload("res://tests/ui5_align_check.gd")
const HEAD := ["Header", "BackButton", "Title", "SubLine", "CodexTab", "GuidesTab", "UnlocksTab", "Body", "SearchPlate", "SearchField", "ReadingPlate", "Topics", "Topic"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_codex: start ===")
	_guard.capture()
	await get_tree().process_frame
	MetaState.core_codex = {"c_bastion": {"seen": true, "picked": true}}
	MetaState.anchor_codex = {"a_volley": {"seen": true, "picked": true, "awakened": true}}
	for sc in [1.0, 2.0 / 3.0]:
		await _run(sc)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	MetaState.reload_from_store()
	print("=== t_ui5_codex: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_codex: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_codex: FAIL - " + f)
	get_tree().quit(1)


func _open() -> Node:
	var v: Node = (load("res://scenes/codex/Codex.tscn") as PackedScene).instantiate()
	v.set("no_scene_change", true)
	add_child(v)
	for _i in 6:
		await get_tree().process_frame
	return v


func _frame(v: Control, sc: float, tag: String) -> void:
	var win := Rect2(0, 0, 1920.0, v.size.y).grow(1.0)
	var bad: Array[String] = []
	for n in v.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var p := c.get_parent()
		var in_scroll := false
		while p != null and p != v:
			if p is ScrollContainer:
				in_scroll = true
			p = p.get_parent()
		if not in_scroll and c.size.x > 0.0 and not win.encloses(c.get_global_rect()) and not (c is ScrollContainer):
			bad.append("%s %s" % [c.name, c.get_global_rect()])
		if sc < 1.0:
			if c is Label and (c as Label).text.strip_edges() != "":
				_check(float((c as Label).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 real px" % [tag, (c as Label).text.left(20)])
			elif c is Button:
				_check(float((c as Button).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 real px" % [tag, (c as Button).text])
	_check(bad.is_empty(), "[%s] inside the frame: %s" % [tag, ", ".join(bad.slice(0, 4))])
	var probs := Align.check(v)
	_check(probs.is_empty(), "[%s] align: %s" % [tag, "; ".join(probs)])


func _run(sc: float) -> void:
	UI3Theme.set_scale_override(sc)
	var tag := "%.2f" % sc
	var v := await _open()
	for n in HEAD:
		_check(v.find_child(n, true, false) != null, "[%s] node %s" % [tag, n])
	_check(v.find_children("Topic*", "Button", true, false).size() == 13, "[%s] 13 Topics" % tag)
	var topics := v.find_child("Topics", true, false) as Control
	_check(absf(topics.size.x - float(UI3Theme.size_of("codex_topics_w"))) < 1.0, "[%s] Topics wide codex_topics_w (%s)" % [tag, topics.size.x])
	_check((v.find_child("TabBar", true, false) as Ui5TabBar).get_child_count() == 3, "[%s] 3 tabs" % tag)
	var fo := get_viewport().gui_get_focus_owner()
	_check(fo != null and fo.name == "SearchField", "[%s] initial focus is the search field (%s)" % [tag, fo.name if fo != null else "none"])
	_frame(v, sc, tag + " basics")
	# keys come from KeyBindings
	v._select_tab("diff")
	_check((v._body as RichTextLabel).text.contains(KeyBindings.text_all(&"combat_end_turn")), "[%s] Controls table uses KeyBindings" % tag)
	for k in [["cores", "CoresBook", "BookTile"], ["combos", "CombosBook", "BookTileUnmet"], ["anchors", "AnchorsBook", "AnchorTile"]]:
		v._select_tab(k[0])
		await get_tree().process_frame
		_check(v.find_child(k[1], true, false) != null, "[%s] %s" % [tag, k[1]])
		_check(v.find_child(k[2], true, false) != null, "[%s] %s tile" % [tag, k[2]])
		_frame(v, sc, tag + " " + k[0])
	for tn in v.find_children("TileName", "Label", true, false):
		_check((tn as Label).get_line_count() <= 2, "[%s] tile name '%s' wraps in <= 2 lines (%d)" % [tag, (tn as Label).text, (tn as Label).get_line_count()])
	v.tile_for("a_volley").activated.emit()
	await get_tree().process_frame
	for n in ["AnchorCard", "HouseEmblem", "AnchorName", "HouseLine", "Tagline", "RuleBox", "AwakensBox", "HouseCores", "HouseCoreChip"]:   # UI-06 AnchorCard names
		_check(v.find_child(n, true, false) != null, "[%s] detail %s" % [tag, n])
	_check(Align.pairs(v) > 0, "[%s] align pairs > 0 (house glyph + name)" % tag)
	_frame(v, sc, tag + " detail")
	var card := v.find_child("AnchorCard", true, false)
	_check(card.find_children("*", "ScrollContainer", true, false).is_empty(), "[%s] AnchorCard has no scroll of its own" % tag)
	for pair in CodexContent.TABS:
		v._select_tab(pair[0])
		await get_tree().process_frame
		_frame(v, sc, tag + " tab " + pair[0])
		var rb := v._body as RichTextLabel
		_check(float(rb.get_theme_font_size("normal_font_size")) * sc >= 14.0 - 0.01, "[%s] body text >= 14 real px" % tag)
	# search
	v._search.text = "poison"
	v._on_search_changed("poison")
	await get_tree().process_frame
	_check(v.find_child("Title", true, false).get("text") != null and (v._title as Label).text == "Results for \"poison\"", "[%s] Results title (%s)" % [tag, v._title.text])
	var hits := v.find_children("SearchHit*", "PanelContainer", true, false)
	_check(hits.size() >= 3, "[%s] hits %d" % [tag, hits.size()])
	_check((v.find_child("ResultCount", true, false) as Label).text == "%d results" % hits.size(), "[%s] count = hits" % tag)
	for h in hits:
		var r := h.find_child("HitText", true, false) as RichTextLabel
		_check(String(r.get_meta("plain")).to_lower().contains("poison") and r.text.contains("[bgcolor"), "[%s] hit has the word, marked" % tag)
	_check((v.topic_node("mana") as Button).modulate.a < 1.0 and (v.topic_node("st") as Button).modulate.a == 1.0, "[%s] non-matching topics dim" % tag)
	_frame(v, sc, tag + " search")
	# hit click opens the topic and clears the search
	(hits[0] as Ui5CodexTile).activated.emit()
	_check(v._search.text == "" and v._current_tab == String(hits[0].get_meta("topic_key")), "[%s] SearchHit opens its topic and clears the search" % tag)
	for raw in ["cell", "color", "font_size", "bgcolor"]:
		v._search.text = raw
		v._on_search_changed(raw)
		_check((v.find_child("ResultCount", true, false) as Label).text == "0 results", "[%s] BBCode word '%s' finds nothing" % [tag, raw])
	# Esc: clears the search first, a second Esc goes back
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	var before: int = v.back_requests
	v._unhandled_key_input(ev)
	_check(v._search.text == "" and v.back_requests == before, "[%s] Esc with a search clears it, no back" % tag)
	v._unhandled_key_input(ev)
	_check(v.back_requests == before + 1, "[%s] second Esc goes back" % tag)
	v._search.text = "zzqx"
	v._on_search_changed("zzqx")
	await get_tree().process_frame
	_check(v.find_child("NoMatchText", true, false) != null and (v.find_child("ResultCount", true, false) as Label).text == "0 results", "[%s] none" % tag)
	_frame(v, sc, tag + " none")
	v._search.text = ""
	v._on_search_changed("")
	_check(v.find_child("NoMatchText", true, false) == null or not v.find_child("NoMatch", true, false).visible, "[%s] clear restores" % tag)
	var src := FileAccess.get_file_as_string("res://scenes/codex/Codex.gd") + FileAccess.get_file_as_string("res://scenes/codex/ui5/CodexParts.gd")
	_check(not src.contains("52 of 78"), "[%s] no illustrative value" % tag)
	v.queue_free()
	await get_tree().process_frame
