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
## UI-03 (screen 23, round 2): Season / Today tabs in the header, A0-A10 chips, table + pinned own row,
## 440 detail plate for the selected row with a Watch replay button (disabled until replays exist).
## The score formula is deliberately not shown (R3).

const ASC_MAX := 10
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
var _detail: PanelContainer
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
	if detail_index >= 0 and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE \
			and _shell["modal_layer"].get_child_count() == 0:
		close_detail()
		get_viewport().set_input_as_handled()
	elif UI3Meta.esc_back(ev, _shell, _on_back):
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
	if i >= 0 and i < rows.size():
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
	_shell = UI3Meta.build(self, "Leaderboard", "", _on_back)
	_period_box = _shell["header_right"]
	_period_box.name = "Periods"
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(body)
	var v := VBoxContainer.new()
	v.name = "Content"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	body.add_child(v)
	_chip_row = HBoxContainer.new()
	_chip_row.name = "AscChips"
	_chip_row.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(_chip_row)
	var cap := UI3.plate(&"plate")
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", UI3Theme.space("16"))
	cap.add_child(ch)
	_title_lbl = UI3.label("", "LabelTitle")
	ch.add_child(_title_lbl)
	_line_lbl = UI3.label("One board per Ascension.", "LabelMuted")
	_line_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ch.add_child(_line_lbl)
	_updated_lbl = UI3.label("", "LabelMuted")
	ch.add_child(_updated_lbl)
	v.add_child(cap)
	_table_host = VBoxContainer.new()
	_table_host.name = "TableHost"
	_table_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table_host.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(_table_host)
	_detail = UI3.plate(&"plate")
	_detail.name = "Detail"
	_detail.custom_minimum_size = Vector2(440, 0)
	body.add_child(_detail)


func _redraw() -> void:
	UI3Meta.clear(_shell["banner_host"])
	if status == "failed":
		var msg := "You are offline" if fail_reason == "offline" else \
			("The leaderboard isn't open yet" if fail_reason == "no_endpoint" else "Can't reach the leaderboard")
		var det := "Last updated %s" % updated if updated != "" else "No board has been loaded yet."
		if fail_reason == "no_endpoint":
			det = "This build has no ranking server connected. " + det
		UI3Meta.banner(_shell["banner_host"], msg, det, [
			{"name": "TryAgain", "text": "Try again", "primary": true, "cb": retry},
			{"name": "BackToLand", "text": "Back to Land", "cb": _on_back}])
	elif guest:
		UI3Meta.banner(_shell["banner_host"], "Sign in to appear here.",
			"Anyone can read the boards. Entries need an account.",
			[{"name": "SignIn", "text": "Sign in", "primary": true, "cb": func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")}])
	_redraw_controls()
	_redraw_table()


func _redraw_controls() -> void:
	UI3Meta.clear(_chip_row)
	for a in ASC_MAX + 1:
		var locked := is_locked(a)
		var b := UI3.button("A%d" % a, &"secondary", &"S")
		b.name = "Asc%d" % a
		b.toggle_mode = true
		b.button_pressed = a == asc
		b.custom_minimum_size = Vector2(72, 48)
		if locked:
			b.modulate.a = 0.6
		b.tooltip_text = "Locked for you" if locked else ""
		b.pressed.connect(set_asc.bind(a))
		_chip_row.add_child(b)
	UI3Meta.clear(_period_box)
	for k in PERIOD_LABEL:
		var pb := UI3Meta.tab(String(PERIOD_LABEL[k]), k == period)
		pb.name = "Seg_" + String(k)
		pb.pressed.connect(set_period.bind(k))
		_period_box.add_child(pb)
	_title_lbl.text = "A%d · %s" % [asc, PERIOD_LABEL[period]]
	if is_locked():
		_line_lbl.text = "Locked for you: win a run at A%d to unlock A%d. You can read it." % [asc - 1, asc]
	else:
		_line_lbl.text = "Quit runs count as losses."
	_updated_lbl.text = "Last updated %s" % updated if updated != "" else ""


func _cell(text: String, w: int, variation := "", right := false) -> Label:
	var l := UI3.label(text, variation)
	if w > 0:
		l.custom_minimum_size = Vector2(w, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _redraw_table() -> void:
	if _table_host == null:
		return
	UI3Meta.clear(_table_host)
	_cols = columns()
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_child(head)
	for d in _cols:
		head.add_child(_cell(String(d[1]), int(d[2]), "LabelMuted", bool(d[3])))
	_table_host.add_child(pad)
	var greyed := status == "failed" or is_locked()
	match status:
		"loading":
			var sk := VBoxContainer.new()
			sk.name = "Skeleton"
			sk.add_theme_constant_override("separation", UI3Theme.space("8"))
			for i in 10:
				sk.add_child(UI3.skeleton_row(56))
			_table_host.add_child(sk)
			var fill := Control.new()
			fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_table_host.add_child(fill)
		"empty":
			var e := _empty_view()
			e.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_table_host.add_child(e)
		_:
			if not (status == "failed" and rows.is_empty()):
				var rv := VBoxContainer.new()
				rv.name = "Rows"
				rv.add_theme_constant_override("separation", UI3Theme.space("8"))
				for i in rows.size():
					rv.add_child(_row(i))
				var sc := UI3Meta.scroll(rv)
				sc.name = "Scroll"
				sc.modulate.a = 0.6 if greyed else 1.0
				_table_host.add_child(sc)
			else:
				var fill2 := Control.new()
				fill2.size_flags_vertical = Control.SIZE_EXPAND_FILL
				_table_host.add_child(fill2)
	_table_host.add_child(_pinned())
	_draw_detail()


func _empty_view() -> Control:
	var c := CenterContainer.new()
	c.name = "Empty"
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", UI3Theme.space("8"))
	c.add_child(ev)
	var t := UI3.label("No runs here yet", "LabelScreenTitle")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(t)
	var d := UI3.label("Nobody has finished a ranked run at this Ascension %s. Yours would be the first." % \
		("today" if period == "today" else "this season"), "LabelMuted")
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(520, 0)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(d)
	return c


func _aid_text(r: Dictionary) -> String:
	var aid := String(r.get("aid", ""))
	return "Pure" if aid == "" else aid


func _name_cell(r: Dictionary, you: bool) -> Control:
	var nm := HBoxContainer.new()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_constant_override("separation", UI3Theme.space("8"))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := _cell(String(r.get("name", "")), 0, "LabelTitle")
	if you:
		nl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		nl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	nm.add_child(nl)
	if you:
		var y := UI3Meta.tag("You")
		y.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nm.add_child(y)
	return nm


func _fill_cells(h: HBoxContainer, r: Dictionary, you: bool) -> void:
	for d in _cols:
		var k: String = d[0]
		var w := int(d[2])
		match k:
			"rank": h.add_child(_cell(str(r.get("rank", "—")), w, "LabelTitle"))
			"name": h.add_child(_name_cell(r, you))
			"land": h.add_child(_cell(String(r.get("land", "")), w))
			"aid": h.add_child(_cell(_aid_text(r) if r.has("aid") else "", w, "LabelMuted"))
			"score":
				var sc = r.get("score", "—")
				h.add_child(_cell(_fmt(int(sc)) if (sc is int or sc is float) else String(sc), w, "LabelTitle", true))
			"won": h.add_child(_cell(("Won" if bool(r["won"]) else "Lost") if r.has("won") else "", w))
			"mode": h.add_child(_cell(String(r.get("mode", "")), w))
			"date": h.add_child(_cell(String(r.get("date", "")), w, "LabelMuted"))


static func _fmt(n: int) -> String:
	return UI3.fmt(n)


func _row(i: int) -> Control:
	var r: Dictionary = rows[i]
	var b := UI3.button("", &"secondary", &"M")
	b.name = "Row%d" % i
	b.toggle_mode = true
	b.button_pressed = i == detail_index
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 24
	h.offset_right = -24
	b.add_child(h)
	_fill_cells(h, r, false)
	b.pressed.connect(open_detail.bind(i))
	return b


## Own row, pinned under the table with the cream outline (selected-card style).
func _pinned() -> Control:
	var p := UI3.plate(&"card_selected")
	p.name = "Pinned"
	p.custom_minimum_size = Vector2(0, 72)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	if guest or newcomer:
		var msg := "Sign in to appear here" if guest else "Ranked opens after %d runs" % int(preload("res://scripts/meta/economy_db.gd").get_table("missions").get("newcomer_runs", 5))
		h.add_child(_cell("—", 80, "LabelTitle"))
		h.add_child(_name_cell({"name": "Guest" if guest else _my_name()}, not guest))
		h.add_child(_cell(msg, 0, "LabelTitle", true))
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


func _kv(k: String, val: String) -> Control:
	var r := UI3.plate(&"row")
	r.custom_minimum_size = Vector2(0, 48)
	var h := HBoxContainer.new()
	r.add_child(h)
	var a := UI3.label(k, "LabelMuted")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(UI3.label(val, "LabelTitle"))
	return r


## Detail plate (always shown): the selected row's facts + Watch replay. No selection = a hint.
func _draw_detail() -> void:
	UI3Meta.clear(_detail)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(v)
	if detail_index < 0 or detail_index >= rows.size():
		var t := UI3.label("Pick a run", "LabelScreenTitle")
		t.name = "DetailTitle"
		v.add_child(t)
		var h := UI3.label("Select a row to see its party and result.", "LabelMuted")
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.custom_minimum_size.x = 392
		v.add_child(h)
		return
	var r: Dictionary = rows[detail_index]
	var d: Dictionary = r.get("detail", {})
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(head)
	var t2 := UI3.label("#%s · %s" % [str(r.get("rank", "")), String(r.get("name", ""))], "LabelScreenTitle")
	t2.name = "DetailTitle"
	t2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t2)
	if r.has("won"):
		head.add_child(UI3Meta.tag("Won" if bool(r["won"]) else "Lost"))
	if String(d.get("summary", "")) != "":
		var s := UI3.label(String(d["summary"]))
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 392
		v.add_child(s)
	var party := HBoxContainer.new()
	party.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(party)
	for k in d.get("party", []):
		var def: Dictionary = ContentDB.heroes.get(str(k), {})
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(56, 56)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
		party.add_child(pic)
	if r.has("score"):
		v.add_child(_kv("Score", _fmt(int(r["score"])) if (r["score"] is int or r["score"] is float) else String(r["score"])))
	for k in ["land", "mode", "date"]:
		if r.has(k) and String(r[k]) != "":
			v.add_child(_kv(String(k).capitalize(), String(r[k])))
	if r.has("aid"):
		v.add_child(_kv("Aid", _aid_text(r)))
	if String(d.get("aid_note", "")) != "":
		var a := UI3.label(String(d["aid_note"]), "LabelMuted")
		a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		a.custom_minimum_size.x = 392
		v.add_child(a)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	# Replays are not recorded for other players yet: the button says why (round-2 spec: Watch replay).
	var wr := UI3.button("Watch replay", &"primary", &"L")
	wr.name = "WatchReplay"
	UI3.set_disabled_reason(wr, "Replays are not available yet")
	v.add_child(wr)
	var close := UI3.button("Close", &"secondary", &"S")
	close.name = "CloseDetail"
	close.pressed.connect(close_detail)
	v.add_child(close)
