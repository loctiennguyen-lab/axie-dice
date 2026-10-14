class_name LeaderboardScreen
extends Control
## M9 Leaderboard (key B). Spec: design/handoffs/ui-02-round3 README section 2 M9, frames M9a-M9g,
## cut to the L1 boards Liam chose: Season (default) and Today, one board per Ascension (A0-A10
## chips, your best preselected, boards above your unlock readable but greyed with the reason).
## No Week, no Pure / All / Mission filter. Data only through a LeaderboardSource
## (scripts/leaderboard): by default the Worker adapter when the account transport is up.
## Columns the source does not send (land / aid / result / mode / date) are not drawn.
## States: loading (skeleton), empty, offline/error banner (cached rows stay, greyed), guest
## ("Sign in to appear here"), newcomer (pinned row says ranked opens after 5 runs).
## Not built: house thumbnail in the header; the score formula is deliberately not shown (R3).

const _Shell := preload("res://scenes/shared/R3Shell.gd")
const ASC_MAX := 10
const HEAD_H := 40.0
const PERIOD_LABEL := {"season": "Season", "today": "Today"}
## key, header, width (0 = expand), numeric
const COL_DEFS := [
	["rank", "RANK", 80, false], ["name", "PLAYER", 0, false], ["land", "LAND", 140, false],
	["aid", "AID", 90, false], ["score", "SCORE", 130, true], ["won", "RESULT", 110, false],
	["mode", "MODE", 170, false], ["date", "DATE", 130, false]]

var source: LeaderboardSource = LeaderboardSource.make_default()
var no_scene_change := false
var use_account := true
var account_status_hook: Callable
## Test/QA overrides (derived from the account when use_account).
var guest := false
var offline := false
var newcomer := false

var asc := 0
var period := "season"
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
var _period_box: HBoxContainer
var _title_lbl: Label
var _line_lbl: Label
var _updated_lbl: Label
var _table_host: VBoxContainer
var _head: Control
var _cols: Array = []


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


func set_period(p: String) -> void:
	if PERIOD_LABEL.has(p):
		period = p
		reload()


func query() -> Dictionary:
	return {"asc": asc, "period": period}


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
	if i >= 0 and i < rows.size() and (rows[i] as Dictionary).has("detail"):
		detail_index = i
		_redraw_table()


func close_detail() -> void:
	detail_index = -1
	_redraw_table()


## Columns drawn for the current rows: always rank / name / score, others only if a row has them.
func columns() -> Array:
	var out: Array = []
	for d in COL_DEFS:
		var k: String = d[0]
		if k in ["rank", "name", "score"] or rows.any(func(r): return (r as Dictionary).has(k) and str(r[k]) != ""):
			out.append(d)
	return out


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
	_period_box = HBoxContainer.new()
	_period_box.name = "Periods"
	_period_box.add_theme_constant_override("separation", 4)
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
	_table_host = VBoxContainer.new()
	_table_host.name = "TableHost"
	v.add_child(_table_host)


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
	var s := _Shell.surface(DangoTheme.Surface.CREAM_RAISED, 10, 3, Vector2(0, 0), fill, border)
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
		b.add_theme_font_size_override("font_size", 16)
		var locked := is_locked(a)
		var on := a == asc
		var fill := DangoTheme.PRIMARY if on else (DangoTheme.CREAM_DISABLED if locked else DangoTheme.CREAM_RAISED)
		var bd := DangoTheme.INK_3 if locked else DangoTheme.OUTLINE
		var ink := DangoTheme.INK_ON_PRIMARY if on else (DangoTheme.INK_DISABLED if locked else DangoTheme.INK)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, _chip_style(fill, bd, 4 if on else 0))
		b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(10))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ink)
		b.tooltip_text = "Locked for you" if locked else ""
		b.pressed.connect(set_asc.bind(a))
		_chip_row.add_child(b)
	_Shell.clear(_period_box)
	for k in PERIOD_LABEL:
		var pb := _Shell.button(String(PERIOD_LABEL[k]), 0, 40, k == period)
		pb.name = "Seg_" + String(k)
		pb.pressed.connect(set_period.bind(k))
		_period_box.add_child(pb)
	_title_lbl.text = "A%d · %s" % [asc, PERIOD_LABEL[period]]
	if is_locked():
		_line_lbl.text = "Locked for you: win a run at A%d to unlock A%d. You can read it." % [asc - 1, asc]
	else:
		_line_lbl.text = "Quit runs count as losses."
	_updated_lbl.text = "Last updated %s" % updated if updated != "" else ""


func _cell(text: String, w: int, size := 14, display := false, color: Color = DangoTheme.INK, right := false) -> Label:
	var l := _Shell.label(text, size, color, display)
	if w > 0:
		l.custom_minimum_size = Vector2(w, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _row_box() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16
	h.offset_right = -16
	return h


func _redraw_table() -> void:
	if _table_host == null:
		return
	_Shell.clear(_table_host)
	_Shell.clear(_shell["modal_layer"])
	_cols = columns()
	var frame := PanelContainer.new()
	frame.name = "Table"
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.CREAM_RAISED, 18, 3, Vector2(-1, -1), null, DangoTheme.LINE))
	_table_host.add_child(frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	frame.add_child(v)
	var head := PanelContainer.new()
	head.name = "Head"
	head.custom_minimum_size = Vector2(0, HEAD_H)
	var hsb := _Shell.surface(DangoTheme.Surface.CREAM, 0, 0, Vector2(16, 0), DangoTheme.DUSK)
	head.add_theme_stylebox_override("panel", hsb)
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 0)
	head.add_child(hr)
	for d in _cols:
		hr.add_child(_cell(("   " if d[0] == "mode" else "") + String(d[1]), int(d[2]), 14, true, DangoTheme.DUSK_INK, bool(d[3])))
	v.add_child(head)
	_head = head
	var greyed := status == "failed" or is_locked()
	match status:
		"loading", "empty":
			var body := PanelContainer.new()
			body.custom_minimum_size = Vector2(0, 420)
			body.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			v.add_child(body)
			if status == "loading":
				var sk := VBoxContainer.new()
				sk.name = "Skeleton"
				sk.add_theme_constant_override("separation", 6)
				for i in 10:
					var w := Panel.new()
					w.custom_minimum_size = Vector2(0, 40)
					w.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.WELL, 10, 0, Vector2(0, 0)))
					sk.add_child(w)
				var m := MarginContainer.new()
				m.add_theme_constant_override("margin_left", 16)
				m.add_theme_constant_override("margin_right", 16)
				m.add_theme_constant_override("margin_top", 10)
				m.add_child(sk)
				body.add_child(m)
			else:
				body.add_child(_empty_view())
		_:
			if not (status == "failed" and rows.is_empty()):
				var rv := VBoxContainer.new()
				rv.name = "Rows"
				rv.add_theme_constant_override("separation", 0)
				for i in rows.size():
					rv.add_child(_row(i))
				var sc := _Shell.fit_in(rv, _shell["panel"], _rows_reserve())
				sc.name = "Scroll"
				sc.modulate.a = 0.6 if greyed else 1.0
				sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
				v.add_child(sc)
	v.add_child(_pinned())
	if detail_index >= 0 and detail_index < rows.size():
		var card := _detail_card(detail_index)
		_shell["modal_layer"].add_child(card)
		_place_detail.call_deferred(card)


## Chrome around the rows list inside the panel (for R3Shell.fit_in).
func _rows_reserve() -> float:
	return R3Shell.BAND_H + 44 + 24 + 14 + 12 + 12 + 20 + HEAD_H + 54 + 10 + (70.0 if (status == "failed" or guest) else 0.0)


func _empty_view() -> Control:
	var c := CenterContainer.new()
	c.name = "Empty"
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 10)
	c.add_child(ev)
	var t := _Shell.label("No runs here yet", 28, DangoTheme.INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(t)
	var d := _Shell.label("Nobody has finished a ranked run at this Ascension %s. Yours would be the first." % \
		("today" if period == "today" else "this season"), 15, DangoTheme.INK_ON_CREAM_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(520, 0)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(d)
	return c


func _aid_cell(r: Dictionary, w: int) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(w, 0)
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aid := String(r.get("aid", ""))
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(20, 20)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.texture = load("res://assets/icons/hl/aid.svg") if aid == "Aid" else MockupAssets.tex("assets/fx/shield.png")
	h.add_child(ic)
	h.add_child(_cell("Pure" if aid == "" else aid, 0, 13, false, DangoTheme.INK_ON_CREAM_MUTED))
	return h


func _land_chip(land: String, w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.CREAM_RAISED, 7, 2, Vector2(8, 1), DangoTheme.land_color(land), DangoTheme.OUTLINE))
	var l := _Shell.label(land, 13, DangoTheme.INK, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	c.add_child(p)
	return c


func _name_cell(r: Dictionary, you: bool) -> Control:
	var nm := HBoxContainer.new()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_constant_override("separation", 8)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := _cell(String(r.get("name", "")), 0, 17, true)
	if you:
		nl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		nl.clip_text = false
	nm.add_child(nl)
	if you:
		var y := PanelContainer.new()
		y.mouse_filter = Control.MOUSE_FILTER_IGNORE
		y.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		y.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.CREAM, 6, 0, Vector2(3, 3), DangoTheme.DUSK))
		var yl := _Shell.label("YOU", 12, DangoTheme.CREAM_RAISED, true)
		yl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		y.add_child(yl)
		nm.add_child(y)
	return nm


func _fill_cells(h: HBoxContainer, r: Dictionary, you: bool) -> void:
	for d in _cols:
		var k: String = d[0]
		var w := int(d[2])
		match k:
			"rank": h.add_child(_cell(str(r.get("rank", "—")), w, 19, true))
			"name": h.add_child(_name_cell(r, you))
			"land": h.add_child(_land_chip(String(r["land"]), w) if r.has("land") else _cell("", w))
			"aid": h.add_child(_aid_cell(r, w) if r.has("aid") else _cell("", w))
			"score":
				var sc = r.get("score", "—")
				h.add_child(_cell(_fmt(int(sc)) if (sc is int or sc is float) else String(sc), w, 19, true, DangoTheme.INK, true))
			"won": h.add_child(_cell(("Won" if bool(r["won"]) else "Lost") if r.has("won") else "", w, 14, true))
			"mode": h.add_child(_cell("   " + String(r.get("mode", "")) if r.has("mode") else "", w, 14))
			"date": h.add_child(_cell(String(r.get("date", "")), w, 14, false, DangoTheme.INK_ON_CREAM_MUTED))


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
	var fill := DangoTheme.GOLD_SOFT if i == detail_index else (DangoTheme.CREAM if i % 2 else DangoTheme.CREAM_RAISED)
	for st in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.bg_color = fill if st != "hover" else fill.darkened(0.04)
		s.border_width_bottom = 1
		s.border_color = DangoTheme.CREAM_200
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(4))
	var h := _row_box()
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
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	p.add_child(h)
	if guest or newcomer:
		var msg := "Sign in to appear here" if guest else "Ranked opens after %d runs" % int(preload("res://scripts/meta/economy_db.gd").get_table("missions").get("newcomer_runs", 5))
		h.add_child(_cell("—", 80, 19, true))
		h.add_child(_name_cell({"name": "Guest" if guest else _my_name()}, not guest))
		h.add_child(_cell(msg, 0, 16, true, DangoTheme.INK, true))
		return p
	var row: Dictionary = me.duplicate()
	if row.is_empty():
		row = {"rank": "—", "score": "—"}
	row["name"] = String(row.get("name", "")) if String(row.get("name", "")) != "" else _my_name()
	_fill_cells(h, row, true)
	return p


func _my_name() -> String:
	var n: Variant = MetaState.get("display_name")
	return String(n) if n != null and String(n) != "" else "You"


func _detail_card(i: int) -> Control:
	var r: Dictionary = rows[i]
	var d: Dictionary = r.get("detail", {})
	var p := PanelContainer.new()
	p.name = "Detail"
	p.custom_minimum_size = Vector2(420, 0)
	p.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.CREAM_RAISED, 18, 4, Vector2(16, 16)))
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
		a.add_theme_stylebox_override("panel", _Shell.surface(DangoTheme.Surface.CREAM, 10, 2, Vector2(8, 8), DangoTheme.GEM_PANEL_TINT, DangoTheme.GEM_SHELF))
		a.add_child(_Shell.label(String(d["aid_note"]), 14, DangoTheme.GEM_INK))
		v.add_child(a)
	return p


## Top-right of the table, just under its header row (relationship to the panel and the header).
func _place_detail(card: Control) -> void:
	if not is_instance_valid(card) or _head == null or not is_instance_valid(_head):
		return
	var panel: Control = _shell["panel"]
	var right := panel.global_position.x + panel.size.x - 40.0
	card.reset_size()
	card.global_position = Vector2(right - card.size.x, _head.global_position.y + HEAD_H + 8.0)
