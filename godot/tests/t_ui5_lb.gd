extends Node
## UI-05 b23 lane S7a: Leaderboard (round-3 frames lb--*), 1920 and 1280 (scale 0.667).
## Data-names exist, nothing preselected in the rows ("Pick a run"), states (rows, detail, locked, empty, offline, error, guest,
## newcomer, loading), text >= 14 real px, everything inside the 1920 logical frame at 1280, icon / label centring measured on
## > 0 pairs, initial focus kept, no illustration value of the HTML frames in the scene or script.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_lb.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["Header", "BackButton", "Title", "SeasonTab", "TodayTab", "Body", "AscRow", "AscChipA0", "AscChipA6", "AscChipA10",
	"Caption", "Rows", "Row0", "PinnedRow", "DetailPlate"]
const ILLUSTRATION := ["Kito", "Mara", "Tuan Anh", "4,210", "4,073", "14:02", "1,612"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


## Text of a named Label under `n`, or "" when either is missing (a null here would stop the coroutine: headless hang).
func _txt(n: Node, child: String) -> String:
	var l := n.find_child(child, true, false) as Label if n != null else null
	return l.text if l != null else ""


func _rows(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append({"rank": i + 1, "name": "P%d" % i, "score": 2480 - i * 61, "won": i % 3 != 0,
			"detail": {"summary": "Run %d" % i}})
	return out


func _ready() -> void:
	print("=== t_ui5_lb: start ===")
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_source_check()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_lb: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_lb: FAIL - ", f)
		get_tree().quit(1)


func _make(sc: float, src: LeaderboardSource, setup := {}) -> LeaderboardScreen:
	var host := Control.new()
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: LeaderboardScreen = load("res://scenes/leaderboard/Leaderboard.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.source = src
	for k in setup:
		s.set(k, setup[k])
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		await get_tree().process_frame
	return s


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame


func _text(n: Node, sc: float, tag: String) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label or n is Button:
		var txt := (n as Label).text if n is Label else (n as Button).text
		if txt.strip_edges() != "":
			var fs := (n as Control).get_theme_font_size("font_size")
			_check(float(fs) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, txt.left(20), fs * sc])
	for ch in n.get_children():
		_text(ch, sc, tag)


func _inside(n: Node, frame: Rect2, tag: String) -> void:
	if n is ScrollContainer:   # rows scrolled out of view are meant to be outside: check the box only
		if (n as Control).is_visible_in_tree():
			_check(frame.grow(1.5).encloses((n as Control).get_global_rect()), "%s: scroll box %s outside the frame" % [tag, n.name])
		return
	if n is Control and (n as Control).is_visible_in_tree():
		var r := (n as Control).get_global_rect()
		if r.size.x > 0 and r.size.y > 0 and not (n is ColorRect) and n.name != "Modals":
			_check(frame.grow(1.5).encloses(r), "%s: %s %s outside the frame %s" % [tag, n.name, str(r), str(frame)])
	for ch in n.get_children():
		_inside(ch, frame, tag)


func _audit(s: Node, sc: float, tag: String) -> void:
	_text(s, sc, tag)
	_inside(s, Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc), tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)


func _pass(sc: float, tag: String) -> void:
	var stub := LeaderboardSourceStub.new()
	stub.boards["6|season"] = {"rows": _rows(12), "me": {"rank": 48, "name": "Me", "score": 1500, "won": true}}
	stub.boards["6|today"] = {"rows": _rows(5), "me": {}}
	stub.boards["9|season"] = {"rows": _rows(10), "me": {}}
	var s := await _make(sc, stub)
	for n in NAMES:
		_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	var dp := s.find_child("DetailPlate", true, false) as Ui5DetailPlate
	_check(dp.is_empty() and dp.title.text == "Pick a run", "%s: opens on 'Pick a run'" % tag)
	_check(s.detail_index == -1, "%s: no row selected" % tag)
	for i in 12:
		_check((s.find_child("Row%d" % i, true, false) as Ui5ListRow).state != &"selected", "%s: Row%d not selected" % [tag, i])
	_check((s.find_child("Row0", true, false) as Control).size.y >= UI3Theme.size_of("lb_row_l_h") - 1.0, "%s: row height >= lb_row_l_h" % tag)
	var fo := s.get_viewport().gui_get_focus_owner()
	_check(fo != null and fo.name == "AscChipA6", "%s: initial focus on your best Ascension chip (%s)" % [tag, str(fo)])
	_check((s.find_child("AscChipA7", true, false) as Button).tooltip_text == "Locked for you", "%s: A7 locked" % tag)
	_check(s.find_child("PinnedRow", true, false) != null, "%s: season: PinnedRow" % tag)
	var lock := (s.find_child("AscChipA7", true, false) as Button).get_node("Content/Lock") as Control
	_check(lock.visible and lock.custom_minimum_size.x * sc >= 13.99, "%s: lock icon >= 14 real px (%.1f)" % [tag, lock.custom_minimum_size.x * sc])
	var chip := s.find_child("AscChipA3", true, false) as Button
	_check(chip.has_theme_stylebox_override("hover") and chip.get_theme_stylebox("hover") != chip.get_theme_stylebox("normal") and chip.find_child("FocusRing", false, false) != null, "%s: chip has its own hover style and a focus ring" % tag)
	_audit(s, sc, tag + " season")
	# pick a row: ring on it, plate fills, footer has the disabled Watch replay
	s.open_detail(1)
	await _settle()
	_check((s.find_child("Row1", true, false) as Ui5ListRow).state == &"selected", "%s: picked row has the ring" % tag)
	var wr := s.find_child("WatchReplayButton", true, false) as Button
	_check(wr != null and wr.disabled and s.find_child("CloseButton", true, false) != null and s.find_child("WatchReplayReason", true, false) != null, "%s: detail has disabled WatchReplayButton, reason, CloseButton" % tag)
	_check(Ui5Keycap.all_under(wr).is_empty(), "%s: no keycap on the disabled button" % tag)
	_check(is_instance_valid(s.get_viewport().gui_get_focus_owner()), "%s: focus survives a pick" % tag)
	var cb := s.find_child("CloseButton", true, false) as Button
	if cb != null:
		cb.grab_focus()
	_check(Align.pairs(s) > 0, "%s: centring check measured an icon / label pair" % tag)
	_audit(s, sc, tag + " detail")
	s.close_detail()
	await _settle()
	var fo1 := s.get_viewport().gui_get_focus_owner()
	_check(fo1 != null and fo1.name == "Row1", "%s: Close hands focus back to the row (%s)" % [tag, str(fo1)])
	# today, locked, empty
	s.set_period("today")
	await _settle()
	_check((s.find_child("TodayTab", true, false) as Button).button_pressed, "%s: Today tab on" % tag)
	_check(s.find_child("PinnedRow", true, false) == null, "%s: today: no PinnedRow" % tag)
	_audit(s, sc, tag + " today")
	s.set_period("season")
	s.set_asc(9)
	await _settle()
	_check(s.is_locked() and s.find_child("EmptyState", true, false) == null and s.find_child("PinnedRow", true, false) != null, "%s: locked board readable, PinnedRow" % tag)
	_audit(s, sc, tag + " locked")
	s.set_asc(2)
	await _settle()
	_check(s.find_child("EmptyState", true, false) != null and s.find_child("PinnedRow", true, false) == null, "%s: EmptyState, no PinnedRow" % tag)
	_audit(s, sc, tag + " empty")
	# loading
	stub.pending = true
	s.set_asc(6)
	await _settle()
	var heads: Array = s.find_child("Head", true, false).find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
	_check(heads == ["RANK", "PLAYER", "SCORE", "RESULT"], "%s: Head has the 4 default columns while loading %s" % [tag, str(heads)])
	_check(s.find_child("Skeleton", true, false) != null and s.find_child("PinnedRow", true, false) == null, "%s: loading skeleton, no pinned row" % tag)
	_audit(s, sc, tag + " loading")
	stub.release()
	stub.pending = false
	await _settle()
	# failure with cache = banner + grey rows + pinned
	stub.fail_reason = "offline"
	s.retry()
	await _settle()
	_check(s.find_child("Banner", true, false) != null and s.find_child("TryAgainButton", true, false) != null and s.find_child("BackToLandButton", true, false) != null and s.find_child("PinnedRow", true, false) != null, "%s: offline banner buttons, PinnedRow" % tag)
	_check(s.find_child("Banner", true, false).find_child("ToneDisc", true, false) != null, "%s: banner ToneDisc" % tag)
	_check(is_equal_approx((s.find_child("Row0", true, false) as Control).modulate.a, 0.55), "%s: cached rows grey" % tag)
	var fo2 := s.get_viewport().gui_get_focus_owner()
	_check(fo2 != null and fo2.name == "AscChipA6", "%s: focus back on the chip after Try again (%s)" % [tag, str(fo2)])
	_audit(s, sc, tag + " offline")
	# still offline, another board: no rows of the A6 season board under the "A6 · Today" caption
	s.set_period("today")
	await _settle()
	_check(s.find_child("ErrorState", true, false) != null and s.find_child("Row0", true, false) == null and s.find_child("PinnedRow", true, false) == null, "%s: offline on another board: error card, not the old rows" % tag)
	s.set_period("season")
	await _settle()
	stub.fail_reason = ""
	s.retry()
	await _settle()
	_check(s.find_child("Banner", true, false) == null, "%s: Try again recovers" % tag)
	s.get_parent().queue_free()
	# error with nothing cached
	var e := await _make(sc, LeaderboardSource.new())
	_check(e.find_child("ErrorState", true, false) != null and e.find_child("TryAgainButton", true, false) != null and e.find_child("PinnedRow", true, false) == null, "%s: ErrorState, no pinned row" % tag)
	var eh := LeaderboardScreen.new()
	_check(eh.columns().map(func(c): return c[0]) == ["rank", "name", "score", "won"], "%s: default columns with no rows" % tag)
	eh.free()
	_check(e.find_child("ErrorState", true, false).find_child("ToneDisc", true, false) != null, "%s: ErrorState ToneDisc" % tag)
	_audit(e, sc, tag + " error")
	e.get_parent().queue_free()
	# guest / newcomer
	var g := await _make(sc, stub, {"guest": true})
	_check(g.find_child("SignInButton", true, false) != null and g.find_child("PinnedNote", true, false) != null, "%s: guest banner + pinned note" % tag)
	_audit(g, sc, tag + " guest")
	g.get_parent().queue_free()
	var n := await _make(sc, stub, {"newcomer": true})
	_check(n.find_child("PinnedNote", true, false) != null and (n.find_child("PinnedNote", true, false) as Label).text.begins_with("Ranked opens after"), "%s: newcomer pinned note" % tag)
	_audit(n, sc, tag + " newcomer")
	n.get_parent().queue_free()
	# own name: signed-in account name + You tag; no account name -> just "You"
	var saved_acc: Dictionary = AccountService.account
	var ns := LeaderboardSourceStub.new()
	ns.boards["6|season"] = {"rows": _rows(3), "me": {"rank": 9, "score": 100}}
	AccountService.account = {"name": "Zed", "email": "z@example.test"}
	var a1 := await _make(sc, ns)
	var pr1 := a1.find_child("PinnedRow", true, false)
	_check(_txt(pr1, "Name") == "Zed" and pr1 != null and pr1.find_child("YouTag", true, false) != null, "%s: pinned row shows the account name + You tag" % tag)
	a1.get_parent().queue_free()
	AccountService.account = {}
	var a2 := await _make(sc, ns)
	var pr2 := a2.find_child("PinnedRow", true, false)
	_check(_txt(pr2, "Name") == "You" and pr2 != null and pr2.find_child("YouTag", true, false) == null, "%s: no account name: 'You' and no tag" % tag)
	a2.get_parent().queue_free()
	# signed in with an email but no name: never the email on a public board
	AccountService.account = {"email": "nobody@example.test"}
	var a3 := await _make(sc, ns)
	var pr3 := a3.find_child("PinnedRow", true, false)
	var shown: Array = a3.find_children("*", "Label", true, false).filter(func(l): return "@" in (l as Label).text)
	_check(_txt(pr3, "Name") == "You" and pr3 != null and pr3.find_child("YouTag", true, false) == null and shown.is_empty(), "%s: email-only account: 'You', no tag, no email on screen" % tag)
	a3.get_parent().queue_free()
	AccountService.account = saved_acc
	# a scrolling list keeps Head / Row / Pinned columns in line
	var big := LeaderboardSourceStub.new()
	big.boards["6|season"] = {"rows": _rows(30), "me": {"rank": 31, "score": 5}}
	var b := await _make(sc, big)
	await _settle()
	var sx: Array = []
	for nd in [b.find_child("Head", true, false), b.find_child("Row0", true, false), b.find_child("PinnedRow", true, false)]:
		var lbls: Array = nd.find_children("*", "Label", true, false).filter(func(l): return (l as Label).visible and (l as Label).horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT) if nd != null else []
		if not lbls.is_empty():
			sx.append((lbls[0] as Label).global_position.x + (lbls[0] as Label).size.x)
	_check(sx.size() == 3 and abs(sx[0] - sx[1]) <= 1.0 and abs(sx[1] - sx[2]) <= 1.0, "%s: Score column right edge in line Head/Row0/Pinned %s" % [tag, str(sx)])
	_audit(b, sc, tag + " scrolling")
	b.get_parent().queue_free()
	# long names do not move the columns
	var long_stub := LeaderboardSourceStub.new()
	var lr := _rows(3)
	lr[1]["name"] = "A very very long player name that must not push the score column anywhere at all"
	long_stub.boards["6|season"] = {"rows": lr, "me": {}}
	var l := await _make(sc, long_stub)
	var x0 := (l.find_child("Row0", true, false).find_child("Cells", true, false).get_child(2) as Control).global_position.x
	var x1 := (l.find_child("Row1", true, false).find_child("Cells", true, false).get_child(2) as Control).global_position.x
	_check(is_equal_approx(x0, x1), "%s: score column does not depend on name length (%.1f vs %.1f)" % [tag, x0, x1])
	_audit(l, sc, tag + " long")
	l.get_parent().queue_free()
	await get_tree().process_frame


func _source_check() -> void:
	for p in ["res://scenes/leaderboard/LeaderboardScreen.gd", "res://scenes/leaderboard/ui5/LbParts.gd", "res://scenes/leaderboard/ui5/LbRow.gd"]:
		var t := FileAccess.get_file_as_string(p)
		for w in ILLUSTRATION:
			_check(not t.contains('"%s"' % w) and not t.contains(w + " "), "%s has no illustration value '%s'" % [p.get_file(), w])
