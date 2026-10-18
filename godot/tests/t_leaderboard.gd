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
	_ok(LeaderboardSource.query_key({"asc": 6, "period": "season"}) == "6|season", "query key")
	var stub := LeaderboardSourceStub.new()
	stub.boards["6|season"] = {"rows": _rows(12), "me": {"rank": 48, "name": "Liam", "land": "Savannah", "aid": "", "score": 1612, "mode": "Short · ranked", "date": "10 Oct 2026"}}
	stub.fetch({"asc": 6, "period": "season"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got.get("ok") == true and (got["rows"] as Array).size() == 12 and int(got["me"]["rank"]) == 48, "stub returns board")
	stub.fetch({"asc": 2, "period": "season"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got.get("ok") == true and (got["rows"] as Array).is_empty(), "stub: missing board is empty")

	# ---- adapter: Worker JSON -> rows, season/today -> board, optional columns hidden
	var seen := {}
	var ad := RemoteLeaderboardAdapter.new()
	ad.remote.http = func(_m: String, path: String, _b: String, cb: Callable) -> void:
		seen["path"] = path
		cb.call(200, JSON.stringify({"season": "s1", "board": "daily", "mode": "short", "ascension": 3, "entries": [{"rank": 1, "name": "Kito", "score": 2480, "won": true}, {"rank": 2, "name": "Mara", "score": 2400, "won": false}], "self": {"rank": 9, "score": 1500}, "total": 40}))
	ad.fetch({"asc": 3, "period": "today"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(String(seen["path"]).contains("board=daily") and String(seen["path"]).contains("asc=3") and String(seen["path"]).contains("mode=short"), "today -> board=daily")
	_ok(got["ok"] == true and got["rows"].size() == 2 and got["rows"][0]["won"] == true and int(got["me"]["rank"]) == 9, "adapter maps entries + self")
	ad.fetch({"asc": 3, "period": "season"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(String(seen["path"]).contains("board=season"), "season -> board=season")
	ad.remote.http = func(_m: String, _p: String, _b: String, cb: Callable) -> void: cb.call(0, "")
	ad.fetch({"asc": 3, "period": "season"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got["ok"] == false and got["reason"] == "offline", "code 0 -> offline")
	ad.remote.http = func(_m: String, _p: String, _b: String, cb: Callable) -> void: cb.call(500, "{}")
	ad.fetch({"asc": 3, "period": "season"}, func(r: Dictionary) -> void: got.clear(); got.merge(r))
	_ok(got["ok"] == false and got["reason"] == "error", "server error -> error")
	var worker_stub := LeaderboardSourceStub.new()
	worker_stub.boards["6|season"] = {"rows": [{"rank": 1, "name": "Kito", "score": 2480, "won": true}, {"rank": 2, "name": "Mara", "score": 2400, "won": false}], "me": {"rank": 9, "score": 1500}}
	var w := await _make(worker_stub)
	var keys: Array = w.columns().map(func(c): return c[0])
	_ok(keys == ["rank", "name", "score", "won"], "only the columns the Worker sends: %s" % str(keys))
	_ok(w.find_child("Pinned", true, false).find_children("*", "Label", true, false).any(func(l): return (l as Label).text == "1,500"), "pinned self row from {rank, score}")
	w.queue_free()

	# ---- default source: failed banner with Try again + Back to Land
	var d := await _make(LeaderboardSource.new())
	_ok(d.status == "failed" and d.fail_reason == "no_endpoint", "default source -> failed state")
	_ok(d.find_child("TryAgain", true, false) != null and d.find_child("BackToLand", true, false) != null, "banner has Try again + Back to Land")
	d.queue_free()

	# ---- normal board
	var s := await _make(stub)
	_ok(s.asc == 6 and s.period == "season", "best Ascension + Season preselected")
	_ok(s.status == "ok" and s.rows.size() == 12, "rows loaded")
	_ok(s.find_child("Row11", true, false) != null, "12 rows drawn")
	_ok(s.find_child("Pinned", true, false) != null, "own row pinned")
	_ok(is_equal_approx(s.find_child("Pinned", true, false).custom_minimum_size.y, 72.0), "pinned row 72")
	_ok(is_equal_approx(s.find_child("Row0", true, false).custom_minimum_size.y, 56.0), "rows 56")
	_ok(s.find_child("Skeleton", true, false) == null, "no skeleton when loaded")
	_ok(s.find_children("*", "Label", true, false).all(func(l): return not ("[" in (l as Label).text)), "no label shows a [tag]")
	_ok(s.find_child("Banner", true, false) == null, "no banner when loaded")
	_ok(s.find_child("Asc7", true, false) != null and (s.find_child("Asc7", true, false) as Button).tooltip_text == "Locked for you", "A7 chip locked above asc_max 6")
	_ok(not s.is_locked(6) and s.is_locked(7), "lock rule")
	# detail
	s.open_detail(1)
	await get_tree().process_frame
	_ok(s.find_child("CloseDetail", true, false) != null and s.detail_index == 1, "detail opens for the selected row")
	var wr := s.find_child("WatchReplay", true, false) as Button
	_ok(wr != null and wr.disabled and wr.text != "Watch replay", "Watch replay disabled with a reason")
	s.close_detail()
	await get_tree().process_frame
	_ok(s.find_child("CloseDetail", true, false) == null and s.detail_index == -1, "detail closes")
	_ok(s.find_child("Detail", true, false) != null, "detail plate stays (hint)")
	# filters / periods / chips drive the query
	s.set_period("today")
	s.set_asc(4)
	var last: Dictionary = stub.calls[stub.calls.size() - 1]
	_ok(last["asc"] == 4 and last["period"] == "today" and not last.has("filter"), "controls drive the query (Season/Today only)")
	_ok(s.find_child("Seg_week", true, false) == null and s.find_child("Seg_pure", true, false) == null, "no Week, no Pure/All/Mission controls")
	_ok(s.find_child("Seg_season", true, false) != null and s.find_child("Seg_today", true, false) != null, "Season + Today present")
	_ok(s.status == "empty" and s.find_child("Empty", true, false) != null, "empty board state")
	s.set_asc(9)
	_ok(s.is_locked() and String(s._line_lbl.text).begins_with("Locked for you: win a run at A8"), "locked board is readable with a reason")

	# ---- loading
	stub.pending = true
	s.set_asc(6)
	s.set_period("season")
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
	_ok(nt.any(func(t): return String(t).begins_with("Ranked opens after")), "newcomer pinned row text")
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
