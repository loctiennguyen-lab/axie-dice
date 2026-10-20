extends Node
## Raid R1 client transport (lane RV): the four calls hit the right path/method/body, answers map to
## (ok, data) / {code}, offline = code "offline", and no real network is used (injected stub only).

var _fails: Array[String] = []
var _checks := 0
var _sent: Array = []


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fails.append(msg)


func _client(code: int, text: String) -> RaidClient:
	var c := RaidClient.new()
	c.http = func(method: String, path: String, body: String, cb: Callable) -> void:
		_sent.append({"m": method, "p": path, "b": body})
		cb.call(code, text)
	return c


func _ready() -> void:
	print("=== t_raid_client: start ===")
	var got := {}
	var done := func(ok: bool, d: Dictionary) -> void:
		got["ok"] = ok
		got["d"] = d

	_client(200, '{"ok":true,"ghost_id":"abcd"}').save_defense([{"key": "plant1"}], {"frame": "f1"}, 50000, done)
	var s: Dictionary = _sent[0]
	var body: Dictionary = JSON.parse_string(s["b"])
	_ok(s["m"] == "POST" and s["p"] == "/api/raid/defense", "defense path")
	_ok(int(body["power_hint"]) == 9999 and body["skin"]["frame"] == "f1" and body["team"].size() == 1, "defense body (power clamped)")
	_ok(got["ok"] == true and got["d"]["ghost_id"] == "abcd", "defense ok")

	_sent.clear()
	_client(200, '{"opponents":[],"points":4}').opponents(done)
	_ok(_sent[0]["m"] == "GET" and _sent[0]["p"] == "/api/raid/opponents" and _sent[0]["b"] == "", "opponents request")
	_ok(got["ok"] and int(got["d"]["points"]) == 4, "opponents ok")

	_sent.clear()
	_client(200, '{"challenge_id":"c","seed":5,"team":[],"skin":{},"name":"N"}').start("0123456789abcdef", done)
	_ok(_sent[0]["p"] == "/api/raid/start" and JSON.parse_string(_sent[0]["b"])["ghost_id"] == "0123456789abcdef", "start request")
	_ok(got["ok"] and int(got["d"]["seed"]) == 5, "start ok")

	_sent.clear()
	_client(200, '{"ok":true,"points":3,"counted":true,"total":3}').finish("c", true, 999, "ab", done)
	var fb: Dictionary = JSON.parse_string(_sent[0]["b"])
	_ok(_sent[0]["p"] == "/api/raid/finish" and fb["won"] == true and int(fb["turns"]) == 60 and fb["challenge_id"] == "c", "finish request (turns clamped)")
	_ok(got["ok"] and int(got["d"]["points"]) == 3, "finish ok")

	# errors
	_client(401, '{"error":"unauthenticated"}').opponents(done)
	_ok(got["ok"] == false and got["d"]["code"] == "unauthenticated", "401 -> unauthenticated")
	_client(409, '{"error":"already_done"}').finish("c", false, 3, "ab", done)
	_ok(got["d"]["code"] == "already_done", "409 code kept")
	_client(0, "").opponents(done)
	_ok(got["d"]["code"] == "offline", "code 0 -> offline")
	_client(500, "<html>").start("0123456789abcdef", done)
	_ok(got["d"]["code"] == "server", "garbage body -> server")
	_client(200, "[1]").opponents(done)
	_ok(got["ok"] == false, "non-dict 200 refused")

	# offline guard: no injected transport and the test switch on -> no socket, code offline
	if NetGuard.blocked():
		RaidClient.new().opponents(done)
		_ok(got["ok"] == false and got["d"]["code"] == "offline", "NetGuard: real transport never reached in tests")

	# hash shape (the Worker wants 16..64 hex)
	var h := RaidClient.result_hash("c", 5, true, 7)
	_ok(h.length() == 64 and RegEx.create_from_string("^[a-f0-9]{64}$").search(h) != null, "hash is 64 hex")
	_ok(h != RaidClient.result_hash("c", 5, false, 7), "hash depends on the result")

	if _fails.is_empty():
		print("t_raid_client: PASS (%d checks)" % _checks)
	else:
		print("t_raid_client: FAIL")
		for f in _fails:
			print("  FAIL: ", f)
	get_tree().quit(0 if _fails.is_empty() else 1)
