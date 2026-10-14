extends Node
## M9 Leaderboard: source interface (default = no endpoint, stub = in-memory), screen states
## (loading skeleton, ok rows + pinned self row, empty, failed banner keeps greyed cache, guest,
## newcomer, locked Ascension), filters / periods / chips drive the query, row detail card.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _rows(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append({"rank": i + 1, "name": "P%d" % i, "land": "Savannah", "aid": "Aid" if i == 1 else "", "score": 2480 - i * 61,
			"mode": "Short · ranked", "date": "11 Oct 2026",
			"detail": {"summary": "Won · Full · A6", "party": ["plant1", "beast1"], "aid_note": "Aid used 2" if i == 1 else ""}})
	return out


func _make(src: LeaderboardSource, setup := {}) -> LeaderboardScreen:
	var s: LeaderboardScreen = load("res://scenes/leaderboard/Leaderboard.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.source = src
	for k in setup:
		s.set(k, setup[k])
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_leaderboard: start ===")
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9

	# ---- source interface
	var got := {"_": 1}
	LeaderboardSource.new().fetch({"asc": 1}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got.get("ok") == false and got.get("reason") == "no_endpoint", "base source: no_endpoint")
	_ok(LeaderboardSource.query_key({"asc": 6, "filter": "pure", "period": "week"}) == "6|pure|week", "query key")
	var stub := LeaderboardSourceStub.new()
	stub.boards["6|pure|week"] = {"rows": _rows(12), "me": {"rank": 48, "name": "Liam", "land": "Savannah", "aid": "", "score": 1612, "mode": "Short · ranked", "date": "10 Oct 2026"}}
	stub.fetch({"asc": 6, "filter": "pure", "period": "week"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got.get("ok") == true and (got["rows"] as Array).size() == 12 and int(got["me"]["rank"]) == 48, "stub returns board")
	stub.fetch({"asc": 2, "filter": "pure", "period": "week"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got.get("ok") == true and (got["rows"] as Array).is_empty(), "stub: missing board is empty")

	# ---- default source: failed banner with Try again + Back to Land
	var d := await _make(LeaderboardSource.new())
	_ok(d.status == "failed" and d.fail_reason == "no_endpoint", "default source -> failed state")
	_ok(d.find_child("Btn_Tryagain", true, false) != null and d.find_child("Btn_BacktoLand", true, false) != null, "banner has Try again + Back to Land")
	d.queue_free()

	# ---- normal board
	var s := await _make(stub)
	_ok(s.asc == 6, "best Ascension preselected")
	_ok(s.status == "ok" and s.rows.size() == 12, "rows loaded")
	_ok(s.find_child("Row11", true, false) != null, "12 rows drawn")
	_ok(s.find_child("Pinned", true, false) != null, "own row pinned")
	_ok(is_equal_approx(s.find_child("Pinned", true, false).custom_minimum_size.y, 54.0), "pinned row 54")
	_ok(is_equal_approx(s.find_child("Row0", true, false).custom_minimum_size.y, 46.0), "rows 46")
	_ok(s.find_child("Skeleton", true, false) == null, "no skeleton when loaded")
	_ok(s.find_child("Banner", true, false) == null, "no banner when loaded")
	_ok(s.find_child("Asc7", true, false) != null and (s.find_child("Asc7", true, false) as Button).tooltip_text == "Locked for you", "A7 chip locked above asc_max 6")
	_ok(not s.is_locked(6) and s.is_locked(7), "lock rule")
	# detail
	s.open_detail(1)
	await get_tree().process_frame
	_ok(s.find_child("Detail", true, false) != null, "detail card opens")
	s.close_detail()
	await get_tree().process_frame
	_ok(s.find_child("Detail", true, false) == null, "detail closes")
	# filters / periods / chips drive the query
	s.set_filter("all")
	s.set_period("season")
	s.set_asc(4)
	var last: Dictionary = stub.calls[stub.calls.size() - 1]
	_ok(last["asc"] == 4 and last["filter"] == "all" and last["period"] == "season", "controls drive the query")
	_ok(s.status == "empty" and s.find_child("Empty", true, false) != null, "empty board state")
	s.set_asc(9)
	_ok(s.is_locked() and String(s._line_lbl.text).begins_with("Locked for you: win a run at A8"), "locked board is readable with a reason")
	_ok(s.filter == "all", "filter unchanged by bad value")

	# ---- loading
	stub.pending = true
	s.set_asc(6)
	s.set_filter("pure")
	s.set_period("week")
	await get_tree().process_frame
	_ok(s.status == "loading" and s.find_child("Skeleton", true, false) != null, "loading skeleton")
	_ok(s.find_child("Back", true, false) != null and s.find_child("Asc3", true, false) != null, "header and chips stay live while loading")
	var r1 := s._req
	s.set_asc(5)       # supersede
	stub.release()
	await get_tree().process_frame
	_ok(r1 != s._req and s.status != "loading", "answers settle; stale one ignored")
	stub.pending = false

	# ---- failure keeps cache, greyed
	s.set_asc(6)
	_ok(s.rows.size() == 12, "cache present")
	stub.fail_reason = "error"
	s.retry()
	await get_tree().process_frame
	_ok(s.status == "failed" and s.rows.size() == 12, "failed keeps cached rows")
	_ok(s.find_child("Banner", true, false) != null, "failure banner")
	stub.fail_reason = ""
	s.retry()
	await get_tree().process_frame
	_ok(s.status == "ok" and s.find_child("Banner", true, false) == null, "Try again recovers")
	s.queue_free()

	# ---- offline from account
	var o := await _make(stub, {"offline": true})
	_ok(o.status == "failed" and o.fail_reason == "offline", "offline state without asking the source")
	o.queue_free()

	# ---- guest / newcomer pinned rows
	var g := await _make(stub, {"guest": true})
	_ok(g.find_child("Banner", true, false) != null, "guest banner")
	var gt := g.find_child("Pinned", true, false).find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
	_ok(gt.has("Sign in to appear here"), "guest pinned row text")
	g.queue_free()
	var n := await _make(stub, {"newcomer": true})
	var nt := n.find_child("Pinned", true, false).find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
	_ok(nt.any(func(t): return String(t).begins_with("   Ranked opens after")), "newcomer pinned row text")
	n.queue_free()

	# ---- Land: hub no longer says Coming soon for the board
	_ok(LandNav.is_available(&"leaderboard"), "leaderboard screen resolves")

	_guard.restore()
	for m in _fail:
		print("FAIL: ", m)
	if _fail.is_empty():
		print("PASS: t_leaderboard (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		get_tree().quit(1)
