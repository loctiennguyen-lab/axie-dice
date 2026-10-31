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
## UI-05 (S7a, round-3 frames lb--*): header plate with Back, title and the Season / Today Ui5TabBar; AscRow of 11 chips; an
## info Banner (offline / error with cache / guest); Caption plate; column head; Rows (Ui5ListRow leader, LbRow); PinnedRow;
## DetailPlate (lb_detail_w). Nothing is preselected in the rows: the plate opens on "Pick a run". The chip row IS a filter and
## keeps your best Ascension preselected. Rows, tabs and chips are built once where they can be, so keyboard focus survives a pick.
## UI-03 (screen 23, round 2): Season / Today tabs in the header, A0-A10 chips, table + pinned own row,
## 440 detail plate for the selected row with a Watch replay button (disabled until replays exist).
## The score formula is deliberately not shown (R3).

const ASC_MAX := 10
const PERIOD_LABEL := {"season": "Season", "today": "Today"}
## key, header, width ratio (columns share the row by ratio, never by text length), numeric.
## rank / name / score / won are the .lbr grid of the UI-05 frame (.5fr 4fr 1fr .8fr).
const COL_DEFS := [
	["rank", "RANK", 0.5, false], ["name", "PLAYER", 4.0, false], ["land", "LAND", 1.2, false],
	["aid", "AID", 0.8, false], ["score", "SCORE", 1.0, true], ["won", "RESULT", 0.8, false],
	["mode", "MODE", 1.6, false], ["date", "DATE", 1.2, false]]

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
var _chips: Array[Button] = []
var _bar: Ui5TabBar
var _banner_host: VBoxContainer
var _caption_host: VBoxContainer
var _line_text := ""   ## the caption's muted line (tests read it)
var _table_host: VBoxContainer
var _detail: Ui5DetailPlate
var _cols: Array = []
var _row_nodes: Array[LbRow] = []


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
	if detail_index >= 0 and ev is InputEventKey and ev.pressed and not ev.echo and ev.is_action_pressed(&"menu_back") \
			and _shell["modal_layer"].get_child_count() == 0:
		close_detail()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
	elif UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
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
		_sync_tabs()
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
		_update_rows()
		_draw_detail()


func close_detail() -> void:
	detail_index = -1
	_update_rows()
	_draw_detail()


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
	(_shell["back"] as Control).name = "BackButton"
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	(_shell["sub"] as Control).visible = false
	var cur := (_shell["col"] as Node).find_child("Currencies", true, false)
	if cur != null:   # the lb frames draw no wallet in the header
		cur.get_parent().remove_child(cur)
		cur.queue_free()
	# Season / Today live inside the header plate, after the title (frame: .meta-head > .tabs).
	var trow := (_shell["back"] as Control).get_parent()
	var tm := MarginContainer.new()
	tm.name = "Tabs"
	tm.add_theme_constant_override("margin_left", UI3Theme.space("16"))
	trow.add_child(tm)
	_bar = Ui5TabBar.new()
	_bar.setup(PERIOD_LABEL.values(), PERIOD_LABEL.keys().find(period), true)
	_bar.get_child(0).name = "SeasonTab"
	_bar.get_child(1).name = "TodayTab"
	_bar.tab_selected.connect(func(i: int) -> void:
		var k: String = PERIOD_LABEL.keys()[i]
		if k != period:
			set_period(k))
	tm.add_child(_bar)
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Theme.space("24"))
	(_shell["col"] as VBoxContainer).add_child(body)
	var v := VBoxContainer.new()
	v.name = "Content"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	body.add_child(v)
	_chip_row = HBoxContainer.new()
	_chip_row.name = "AscRow"
	_chip_row.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(_chip_row)
	for a in ASC_MAX + 1:
		var b := LbParts.asc_chip(a)
		b.pressed.connect(set_asc.bind(a))
		_chip_row.add_child(b)
		_chips.append(b)
	_banner_host = VBoxContainer.new()
	_banner_host.name = "BannerHost"
	v.add_child(_banner_host)
	_caption_host = VBoxContainer.new()
	_caption_host.name = "CaptionHost"
	v.add_child(_caption_host)
	_table_host = VBoxContainer.new()
	_table_host.name = "TableHost"
	_table_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table_host.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(_table_host)
	_detail = Ui5DetailPlate.new()
	_detail.setup("lb_detail_w", "Pick a run", "Select a row to see its party and result.", "", 12)
	body.add_child(_detail)
	_sync_tabs()
	_refresh_chips()
	_chips[clampi(asc, 0, ASC_MAX)].grab_focus()   # keyboard / gamepad start on the filter you are looking at


func _sync_tabs() -> void:
	if _bar == null:
		return
	var i := PERIOD_LABEL.keys().find(period)
	(_bar.get_child(i) as Button).button_pressed = true


func _refresh_chips() -> void:
	for a in _chips.size():
		LbParts.style_asc_chip(_chips[a], a == asc, is_locked(a))


func _redraw() -> void:
	UI3Meta.clear(_banner_host)
	if status == "failed" and not rows.is_empty():
		var det := "Last updated %s" % updated if updated != "" else "No board has been loaded yet."
		if fail_reason == "no_endpoint":
			det = "This build has no ranking server connected. " + det
		_banner_host.add_child(LbParts.banner(&"warn", _fail_title(), det, [
			{"name": "TryAgainButton", "text": "Try again", "cb": retry},
			{"name": "BackToLandButton", "text": "Back to Land", "cb": _on_back}]))
	elif guest and status != "failed":
		_banner_host.add_child(LbParts.banner(&"info", "Sign in to appear here.",
			"Anyone can read the boards. Entries need an account.",
			[{"name": "SignInButton", "text": "Sign in", "cb": func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")}]))
	_redraw_controls()
	_redraw_table()


func _fail_title() -> String:
	return "You are offline" if fail_reason == "offline" else \
		("The leaderboard isn't open yet" if fail_reason == "no_endpoint" else "Can't reach the leaderboard")


func _redraw_controls() -> void:
	_refresh_chips()
	_sync_tabs()
	if is_locked():
		_line_text = "Locked for you: win a run at A%d to unlock A%d. You can read it." % [asc - 1, asc]
	else:
		_line_text = "Quit runs count as losses."
	UI3Meta.clear(_caption_host)
	var shown_updated := updated if status != "loading" and not (status == "failed" and rows.is_empty()) else ""
	_caption_host.add_child(LbParts.caption("A%d · %s" % [asc, PERIOD_LABEL[period]], _line_text, shown_updated))


func _aid_text(r: Dictionary) -> String:
	var aid := String(r.get("aid", ""))
	return "Pure" if aid == "" else aid


static func _fmt(n: int) -> String:
	return UI3.fmt(n)


func _score_text(r: Dictionary) -> String:
	var sc = r.get("score", "")
	return _fmt(int(sc)) if (sc is int or sc is float) else String(sc)


## The Name cell: name (trimmed), then the "You" tag for the own row.
func _name_cell(r: Dictionary, you: bool, ratio: float) -> Control:
	var nm := HBoxContainer.new()
	nm.name = "NameCell"
	nm.set_meta("ratio", ratio)
	nm.add_theme_constant_override("separation", UI3Theme.space("8"))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := LbRow.text_cell(String(r.get("name", "")), 1.0)
	nl.name = "Name"
	if you:
		nl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		nl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	nm.add_child(nl)
	if you:
		nm.add_child(LbParts.tag("You", &"you", "YouTag"))
	return nm


func _cells_for(r: Dictionary, you: bool) -> Array:
	var out: Array = []
	for d in _cols:
		var k: String = d[0]
		var ratio := float(d[2])
		match k:
			"rank": out.append(LbRow.text_cell(str(r.get("rank", "—")), ratio))
			"name": out.append(_name_cell(r, you, ratio))
			"land": out.append(LbRow.text_cell(String(r.get("land", "")), ratio, "text_body", "text", false))
			"aid": out.append(LbRow.text_cell(_aid_text(r) if r.has("aid") else "", ratio, "text_body", "text_muted", false))
			"score": out.append(LbRow.text_cell(_score_text(r), ratio, "text_title", "text", true, true))
			"won": out.append(LbRow.text_cell(("Won" if bool(r["won"]) else "Lost") if r.has("won") else "", ratio, "text_body", "text", false))
			"mode": out.append(LbRow.text_cell(String(r.get("mode", "")), ratio, "text_body", "text", false))
			"date": out.append(LbRow.text_cell(String(r.get("date", "")), ratio, "text_body", "text_muted", false))
	return out


func _row(i: int) -> LbRow:
	var r := LbRow.new()
	r.setup_row("Row%d" % i, _cols, _cells_for(rows[i], false))
	r.pressed.connect(open_detail.bind(i))
	return r


func _grey() -> bool:
	return status == "failed" or is_locked()


func _update_rows() -> void:
	for i in _row_nodes.size():
		if is_instance_valid(_row_nodes[i]):
			_row_nodes[i].set_row_state(i == detail_index, _grey())


func _redraw_table() -> void:
	if _table_host == null:
		return
	UI3Meta.clear(_table_host)
	_row_nodes.clear()
	_cols = columns()
	var error_card := status == "failed" and rows.is_empty()
	match status:
		"loading":
			_table_host.add_child(LbParts.head_row(_cols))
			var sk := VBoxContainer.new()
			sk.name = "Rows"
			sk.add_theme_constant_override("separation", UI3Theme.space("8"))
			for i in 8:
				var s := UI3.skeleton_row(UI3Theme.size_of("lb_row_l_h"))
				s.name = "Skeleton" if i == 0 else "Skeleton%d" % i
				sk.add_child(s)
			_table_host.add_child(sk)
		"empty":
			# A locked board says why in the caption only; no "No runs here yet" on top of it.
			if not is_locked():
				_table_host.add_child(_fill(LbParts.center_block("EmptyState", "No runs here yet",
					"Nobody has finished a ranked run at this Ascension %s. Yours would be the first." % \
					("today" if period == "today" else "this season"))))
		_:
			if error_card:
				_table_host.add_child(_fill(LbParts.center_block("ErrorState", _fail_title(),
					"This build has no ranking server connected." if fail_reason == "no_endpoint" else "No board has been loaded yet.",
					&"error", [{"name": "TryAgainButton", "text": "Try again", "cb": retry},
						{"name": "BackToLandButton", "text": "Back to Land", "cb": _on_back}])))
			else:
				_table_host.add_child(LbParts.head_row(_cols))
				var rv := VBoxContainer.new()
				rv.name = "Rows"
				rv.add_theme_constant_override("separation", UI3Theme.space("8"))
				for i in rows.size():
					var rr := _row(i)
					rr.set_row_state(i == detail_index, _grey())
					_row_nodes.append(rr)
					rv.add_child(rr)
				var sc := UI3Meta.scroll(rv)
				sc.name = "Scroll"
				_table_host.add_child(sc)
	if status == "loading" or (status == "empty" and is_locked()):
		var fill := Control.new()   # keeps the pinned row at the foot
		fill.name = "Fill"
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_table_host.add_child(fill)
	if status != "loading" and not error_card:
		_table_host.add_child(_pinned())
	_draw_detail()


func _fill(c: Control) -> Control:
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## Own row, pinned under the table (.lbr.pin): plate_raised with the cream ring, no clicks.
func _pinned() -> Control:
	var p := LbRow.new()
	if guest or newcomer:
		var msg := "Sign in to appear here" if guest else "Ranked opens after %d runs" % int(preload("res://scripts/meta/economy_db.gd").get_table("missions").get("newcomer_runs", 5))
		var cells: Array = []
		var rest := 0.0
		for d in _cols:
			match String(d[0]):
				"rank": cells.append(LbRow.text_cell("—", float(d[2])))
				"name": cells.append(_name_cell({"name": "Guest" if guest else _my_name()}, not guest, float(d[2])))
				_: rest += float(d[2])
		var m := LbRow.text_cell(msg, maxf(rest, 1.0), "text_body", "text_muted", false)
		m.name = "PinnedNote"
		cells.append(m)
		p.setup_row("PinnedRow", _cols, cells)
	else:
		var row: Dictionary = me.duplicate()
		row["name"] = String(row.get("name", "")) if String(row.get("name", "")) != "" else _my_name()
		if not row.has("rank"):
			row["rank"] = "—"
		p.setup_row("PinnedRow", _cols, _cells_for(row, true))
	p.set_pinned()
	return p


func _my_name() -> String:
	var n: Variant = MetaState.get("display_name")
	return String(n) if n != null and String(n) != "" else "You"


## DetailPlate (always shown): the selected row's facts + Watch replay. No selection = "Pick a run".
func _draw_detail() -> void:
	if _detail == null:
		return
	if detail_index < 0 or detail_index >= rows.size():
		_detail.show_empty()
		return
	var r: Dictionary = rows[detail_index]
	var d: Dictionary = r.get("detail", {})
	_detail.show_item("#%s · %s" % [str(r.get("rank", "")), String(r.get("name", ""))])
	if r.has("won"):
		var t := LbParts.tag("Won" if bool(r["won"]) else "Lost", &"won" if bool(r["won"]) else &"lost", "ResultTag")
		t.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_detail.body.add_child(t)
	if String(d.get("summary", "")) != "":
		_detail.add_line(String(d["summary"]))
	var party := HBoxContainer.new()
	party.name = "Party"
	party.add_theme_constant_override("separation", UI3Theme.space("8"))
	for k in d.get("party", []):
		var def: Dictionary = ContentDB.heroes.get(str(k), {})
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("btn_m")
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
		party.add_child(pic)
	if party.get_child_count() > 0:
		_detail.body.add_child(party)
	else:
		party.free()
	if r.has("score"):
		_detail.body.add_child(LbParts.kv_row("Score", _score_text(r)))
	for k in ["land", "mode", "date"]:
		if r.has(k) and String(r[k]) != "":
			_detail.body.add_child(LbParts.kv_row(String(k).capitalize(), String(r[k])))
	if r.has("aid"):
		var aid_val := _aid_text(r)
		if String(d.get("aid_note", "")) != "":
			aid_val = String(d["aid_note"])
		_detail.body.add_child(LbParts.kv_row("Aid", aid_val))
	# Replays are not recorded for other players yet: the line says why, the button stays disabled.
	var why := Ui5Text.label("Replays are not available yet", "text_body", "text_muted")
	why.name = "WatchReplayReason"
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.footer.add_child(why)
	var wr := UI3.button("Watch replay", &"secondary", &"M")
	wr.name = "WatchReplayButton"
	wr.disabled = true
	_detail.footer.add_child(wr)
	var close := UI3.button("Close", &"secondary", &"M")
	close.name = "CloseButton"
	close.pressed.connect(close_detail)
	_detail.footer.add_child(close)
