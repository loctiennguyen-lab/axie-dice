class_name LeaderboardScreen
extends Control
## M9 Leaderboard (key B). Spec: design/handoffs/ui-02-round3 README section 2 M9, frames M9a-M9g.
## One board per Ascension (A0-A10 chips; your best is preselected, boards above your unlock are
## readable but greyed with the reason) x filter (Pure / All / Nhiem vu) x period (Today / This week /
## Season). Data comes only through a LeaderboardSource (scripts/leaderboard); the default source
## has no endpoint yet, so the screen shows the "can't reach" banner until lane M's Worker source is
## plugged in via `source`. States: loading (skeleton), empty, offline/error banner (cached rows stay,
## greyed), guest ("Sign in to appear here"), newcomer (pinned row says ranked opens after 5 runs).
## Not built: house thumbnail in the header; score formula is deliberately not shown (R3).

const _Shell := preload("res://scenes/shared/R3Shell.gd")
const ASC_MAX := 10
const FILTER_LABEL := {"pure": "Pure", "all": "All", "mission": "Nhiệm vụ"}
const PERIOD_LABEL := {"today": "Today", "week": "This week", "season": "Season"}
const LAND_COLOR := {"Savannah": "F8B848", "Forest": "88C858", "Arctic": "98D8B8", "Mystic": "C2A6F4"}
const COLS := [80, 0, 140, 90, 130, 170, 130]       # 0 = expand

var source: LeaderboardSource = LeaderboardSource.new()
var no_scene_change := false
var use_account := true
var account_status_hook: Callable
## Test/QA overrides; "" or -1 = derive.
var guest := false
var offline := false
var newcomer := false

var asc := 0
var filter := "pure"
var period := "week"
## "loading" | "ok" | "empty" | "failed"
var status := "loading"
var rows: Array = []
var me: Dictionary = {}
var updated := ""
var fail_reason := ""
var detail_index := -1

var _req := 0
var _shell: Dictionary
var _chip_row: HBoxContainer
var _filter_box: HBoxContainer
var _period_box: HBoxContainer
var _title_lbl: Label
var _line_lbl: Label
var _updated_lbl: Label
var _table_host: Control


func _ready() -> void:
	if use_account:
		var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
		guest = st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED
		offline = st == AccountService.Status.OFFLINE
		newcomer = MetaState.is_newcomer()
	asc = clampi(MetaState.asc_max, 0, ASC_MAX)
	_build()
	reload()


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if detail_index >= 0:
			close_detail()
		else:
			_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ------------------------------------------------------------ public API

func is_locked(a: int = asc) -> bool:
	return a > MetaState.asc_max


func set_asc(a: int) -> void:
	asc = clampi(a, 0, ASC_MAX)
	reload()


func set_filter(f: String) -> void:
	if FILTER_LABEL.has(f):
		filter = f
		reload()


func set_period(p: String) -> void:
	if PERIOD_LABEL.has(p):
		period = p
		reload()


func query() -> Dictionary:
	return {"asc": asc, "filter": filter, "period": period}


## Asks the source for the current board. Cached rows stay on screen (greyed) if it fails.
func reload() -> void:
	_req += 1
	var my := _req
	detail_index = -1
	status = "loading"
	if offline:
		_finish({"ok": false, "reason": "offline", "rows": rows, "me": me, "updated": updated})
		return
	_redraw()
	source.fetch(query(), func(res: Dictionary) -> void:
		if my == _req:
			_finish(res))


func retry() -> void:
	reload()


func open_detail(i: int) -> void:
	if i >= 0 and i < rows.size():
		detail_index = i
		_redraw_table()


func close_detail() -> void:
	detail_index = -1
	_redraw_table()


func _finish(res: Dictionary) -> void:
	if bool(res.get("ok", false)):
		rows = (res.get("rows", []) as Array)
		me = res.get("me", {})
		updated = String(res.get("updated", ""))
		fail_reason = ""
		status = "ok" if not rows.is_empty() else "empty"
	else:
		fail_reason = String(res.get("reason", "error"))
		updated = String(res.get("updated", updated))
		status = "failed"
	_redraw()


# ------------------------------------------------------------ drawing

func _build() -> void:
	_shell = _Shell.build(self, "Leaderboard", "One board per Ascension · every created run counts", _on_back)
	var col: VBoxContainer = _shell["col"]
	var pad := MarginContainer.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 20)
	col.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pad.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	v.add_child(top)
	_chip_row = HBoxContainer.new()
	_chip_row.name = "AscChips"
	_chip_row.add_theme_constant_override("separation", 6)
	top.add_child(_chip_row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_filter_box = _segmented("Filters")
	top.add_child(_filter_box)
	_period_box = _segmented("Periods")
	top.add_child(_period_box)
	var cap := HBoxContainer.new()
	cap.add_theme_constant_override("separation", 10)
	v.add_child(cap)
	_title_lbl = _Shell.label("", 20, DangoTheme.INK, true)
	cap.add_child(_title_lbl)
	_line_lbl = _Shell.label("", 13, DangoTheme.INK_ON_CREAM_MUTED)
	_line_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line_lbl.clip_text = true
	cap.add_child(_line_lbl)
	_updated_lbl = _Shell.label("", 13, DangoTheme.INK_ON_CREAM_MUTED)
	cap.add_child(_updated_lbl)
	_table_host = Control.new()
	_table_host.name = "TableHost"
	_table_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table_host.custom_minimum_size = Vector2(0, 300)
	v.add_child(_table_host)


func _segmented(nm: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = nm
	h.add_theme_constant_override("separation", 4)
	return h


func _redraw() -> void:
	_Shell.clear(_shell["banner_host"])
	if status == "failed":
		var msg := "You are offline" if fail_reason == "offline" else \
			("The leaderboard isn't open yet" if fail_reason == "no_endpoint" else "Can't reach the leaderboard")
		var det := "Last updated %s" % updated if updated != "" else "No board has been loaded yet."
		if fail_reason == "no_endpoint":
			det = "This build has no ranking server connected. " + det
		_Shell.banner(_shell["banner_host"], msg, det, [
			{"text": "Try again", "primary": true, "cb": retry},
			{"text": "Back to Land", "cb": _on_back}])
	elif guest:
		_Shell.banner(_shell["banner_host"], "Sign in to appear here.",
			"Anyone can read the boards. Entries need an account.",
			[{"text": "Sign in", "primary": true, "cb": func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")}])
	_redraw_controls()
	_redraw_table()


func _chip_style(fill: Color, border: Color, shelf: int) -> StyleBoxFlat:
	var s := _Shell.box(fill, border, 10, 3, 0)
	s.shadow_size = 0
	s.shadow_color = DangoTheme.LINE
	s.shadow_offset = Vector2(0, shelf)
	return s


func _redraw_controls() -> void:
	_Shell.clear(_chip_row)
	for a in ASC_MAX + 1:
		var b := Button.new()
		b.name = "Asc%d" % a
		b.text = "A%d" % a
		b.custom_minimum_size = Vector2(44, 44)
		b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		b.add_theme_font_size_override("font_size", 16)
		var locked := is_locked(a)
		var on := a == asc
		var fill := DangoTheme.PRIMARY if on else (DangoTheme.CREAM_DISABLED if locked else DangoTheme.CREAM_RAISED)
		var bd := Color("9A7650") if locked else DangoTheme.OUTLINE
		var ink := DangoTheme.INK_ON_PRIMARY if on else (DangoTheme.INK_DISABLED if locked else DangoTheme.INK)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, _chip_style(fill, bd, 4 if on else 0))
		b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(10))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ink)
		b.tooltip_text = "Locked for you" if locked else ""
		b.pressed.connect(set_asc.bind(a))
		_chip_row.add_child(b)
	_seg_fill(_filter_box, FILTER_LABEL, filter, set_filter)
	_seg_fill(_period_box, PERIOD_LABEL, period, set_period)
	_title_lbl.text = "A%d · %s · %s" % [asc, FILTER_LABEL[filter] if filter != "all" else "All runs", PERIOD_LABEL[period]]
	if is_locked():
		_line_lbl.text = "Locked for you: win a run at A%d to unlock A%d. You can read it." % [asc - 1, asc]
	elif filter == "pure":
		_line_lbl.text = "Pure = runs with no Aid. Quit runs count as losses."
	elif filter == "all":
		_line_lbl.text = "Aid glyph marks runs that used Aid."
	else:
		_line_lbl.text = "Mission runs only."
	_updated_lbl.text = "Last updated %s" % updated if updated != "" else ""


func _seg_fill(box: HBoxContainer, labels: Dictionary, cur: String, cb: Callable) -> void:
	_Shell.clear(box)
	for k in labels:
		var b := _Shell.button(String(labels[k]), 0, 40, k == cur)
		b.name = "Seg_" + String(k)
		b.custom_minimum_size.x = 0
		b.pressed.connect(cb.bind(k))
		box.add_child(b)


func _cell(text: String, w: int, size := 14, display := false, color: Color = DangoTheme.INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := _Shell.label(text, size, color, display)
	if w > 0:
		l.custom_minimum_size = Vector2(w, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
	l.horizontal_alignment = align
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _redraw_table() -> void:
	if _table_host == null:
		return
	_Shell.clear(_table_host)
	var frame := PanelContainer.new()
	frame.name = "Table"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM_RAISED, DangoTheme.LINE, 18, 3, 0))
	_table_host.add_child(frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	frame.add_child(v)
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 40)
	var hsb := _Shell.box(DangoTheme.DUSK, DangoTheme.DUSK, 0, 0, 0)
	hsb.content_margin_left = 16
	hsb.content_margin_right = 16
	head.add_theme_stylebox_override("panel", hsb)
	var hr := _row_box(0)
	head.add_child(hr)
	var names := ["RANK", "PLAYER", "LAND", "AID", "SCORE", "MODE", "DATE"]
	for i in names.size():
		hr.add_child(_cell(("   " + names[i]) if i == 5 else names[i], COLS[i], 14, true, DangoTheme.DUSK_INK,
			HORIZONTAL_ALIGNMENT_RIGHT if i == 4 else HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(head)
	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var greyed := status == "failed" or is_locked()
	match status:
		"loading":
			var sk := VBoxContainer.new()
			sk.name = "Skeleton"
			sk.set_anchors_preset(Control.PRESET_FULL_RECT)
			sk.add_theme_constant_override("separation", 6)
			for i in 10:
				var w := Panel.new()
				w.custom_minimum_size = Vector2(0, 40)
				w.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM_TRACK, DangoTheme.CREAM_TRACK, 10, 0, 0))
				sk.add_child(w)
			var m := MarginContainer.new()
			m.set_anchors_preset(Control.PRESET_FULL_RECT)
			m.add_theme_constant_override("margin_left", 16)
			m.add_theme_constant_override("margin_right", 16)
			m.add_theme_constant_override("margin_top", 10)
			m.add_child(sk)
			body.add_child(m)
		"empty":
			var c := CenterContainer.new()
			c.name = "Empty"
			c.set_anchors_preset(Control.PRESET_FULL_RECT)
			var ev := VBoxContainer.new()
			ev.add_theme_constant_override("separation", 10)
			c.add_child(ev)
			var t := _Shell.label("No runs here yet", 28, DangoTheme.INK, true)
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ev.add_child(t)
			var d := _Shell.label("Nobody has finished a ranked run at this Ascension %s. Yours would be the first." % \
				{"today": "today", "week": "this week", "season": "this season"}[period], 15, DangoTheme.INK_ON_CREAM_MUTED)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(520, 0)
			d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ev.add_child(d)
			body.add_child(c)
		_:
			if status == "failed" and rows.is_empty():
				pass
			else:
				var sc := ScrollContainer.new()
				sc.name = "Scroll"
				sc.set_anchors_preset(Control.PRESET_FULL_RECT)
				sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
				DangoTheme.style_scrollbars(sc)
				var rv := VBoxContainer.new()
				rv.name = "Rows"
				rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rv.add_theme_constant_override("separation", 0)
				sc.add_child(rv)
				for i in rows.size():
					rv.add_child(_row(i))
				body.add_child(sc)
	body.modulate.a = 0.6 if greyed else 1.0
	v.add_child(_pinned())
	if detail_index >= 0 and detail_index < rows.size():
		_table_host.add_child(_detail_card(detail_index))


func _row_box(pad: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := pad
	h.offset_left = m
	h.offset_right = -m
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = m
	h.offset_right = -m
	return h


func _aid_cell(r: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(COLS[3], 0)
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aid := String(r.get("aid", ""))
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(20, 20)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if aid == "Aid":
		ic.texture = load("res://assets/icons/hl/aid.svg")
	else:
		ic.texture = MockupAssets.tex("assets/fx/shield.png")
	h.add_child(ic)
	h.add_child(_cell("Pure" if aid == "" else aid, 0, 13, false, DangoTheme.INK_ON_CREAM_MUTED))
	return h


func _land_chip(land: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(COLS[2], 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var fill := Color(String(LAND_COLOR.get(land, "E8D6B4")))
	var sb := _Shell.box(fill, DangoTheme.OUTLINE, 7, 2, 0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var l := _Shell.label(land, 13, DangoTheme.INK, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	c.add_child(p)
	return c


func _fill_cells(h: HBoxContainer, r: Dictionary, you: bool) -> void:
	h.add_child(_cell(str(r.get("rank", "—")), COLS[0], 19, true))
	var nm := HBoxContainer.new()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_constant_override("separation", 8)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := _cell(String(r.get("name", "")), 0, 17, true)
	if you:
		nl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nm.add_child(nl)
	if you:
		var y := PanelContainer.new()
		y.mouse_filter = Control.MOUSE_FILTER_IGNORE
		y.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		y.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.DUSK, DangoTheme.DUSK, 6, 0, 3))
		var yl := _Shell.label("YOU", 12, DangoTheme.CREAM_RAISED, true)
		yl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		y.add_child(yl)
		nm.add_child(y)
	h.add_child(nm)
	h.add_child(_land_chip(String(r.get("land", ""))) if String(r.get("land", "")) != "" else _cell("", COLS[2]))
	h.add_child(_aid_cell(r) if r.has("score") and r.has("rank") and int(r.get("rank", 0)) > 0 else _cell("", COLS[3]))
	var sc = r.get("score", "")
	h.add_child(_cell(_fmt(sc) if sc is int else String(sc), COLS[4], 19, true, DangoTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT))
	var mode := _cell(String(r.get("mode", "")), COLS[5], 14)
	mode.add_theme_constant_override("outline_size", 0)
	mode.text = "   " + mode.text if mode.text != "" else ""
	h.add_child(mode)
	h.add_child(_cell(String(r.get("date", "")), COLS[6], 14, false, DangoTheme.INK_ON_CREAM_MUTED))


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _row(i: int) -> Control:
	var r: Dictionary = rows[i]
	var b := Button.new()
	b.name = "Row%d" % i
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sel := i == detail_index
	var fill := DangoTheme.GOLD_SOFT if sel else (DangoTheme.CREAM if i % 2 else DangoTheme.CREAM_RAISED)
	for st in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.bg_color = fill if st != "hover" else fill.darkened(0.04)
		s.border_width_bottom = 1
		s.border_color = Color("EBD3A8")
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(4))
	var h := _row_box(16)
	b.add_child(h)
	_fill_cells(h, r, false)
	b.pressed.connect(open_detail.bind(i))
	return b


func _pinned() -> Control:
	var p := PanelContainer.new()
	p.name = "Pinned"
	p.custom_minimum_size = Vector2(0, 54)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.GOLD_SOFT
	sb.border_width_top = 3
	sb.border_color = DangoTheme.OUTLINE
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	p.add_theme_stylebox_override("panel", sb)
	var h := _row_box(0)
	p.add_child(h)
	var row: Dictionary
	if guest:
		row = {"rank": "—", "name": "Guest", "score": "Sign in to appear here"}
	elif newcomer:
		row = {"rank": "—", "name": _my_name(), "score": "—", "mode": "Ranked opens after %d runs" % int(preload("res://scripts/meta/economy_db.gd").get_table("missions").get("newcomer_runs", 5))}
	elif not me.is_empty():
		row = me
	else:
		row = {"rank": "—", "name": _my_name(), "score": "—"}
	_fill_cells(h, row, not guest)
	return p


func _my_name() -> String:
	var n := String(MetaState.get("display_name")) if MetaState.get("display_name") != null else ""
	return n if n != "" else "You"


func _detail_card(i: int) -> Control:
	var r: Dictionary = rows[i]
	var d: Dictionary = r.get("detail", {})
	var p := PanelContainer.new()
	p.name = "Detail"
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.offset_left = -460
	p.offset_right = -40
	p.offset_top = 96
	p.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM_RAISED, DangoTheme.LINE, 18, 4, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := _Shell.label("#%s · %s" % [str(r.get("rank", "")), String(r.get("name", ""))], 22, DangoTheme.INK, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := _Shell.button("Esc closes", 0, 36)
	close.name = "CloseDetail"
	close.pressed.connect(close_detail)
	head.add_child(close)
	var s := _Shell.label(String(d.get("summary", "")), 14)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var party := HBoxContainer.new()
	party.add_theme_constant_override("separation", 6)
	v.add_child(party)
	for k in d.get("party", []):
		var def: Dictionary = ContentDB.heroes.get(str(k), {})
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(44, 44)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
		party.add_child(pic)
	if String(d.get("aid_note", "")) != "":
		var a := PanelContainer.new()
		a.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.GEM_PANEL_TINT, DangoTheme.GEM_SHELF, 10, 2, 8))
		a.add_child(_Shell.label(String(d["aid_note"]), 14, DangoTheme.GEM_INK))
		v.add_child(a)
	return p
