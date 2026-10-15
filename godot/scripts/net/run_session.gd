class_name RunSession
extends Node
## One WebSocket to the RunDO (L1 contract 6.3, ADR-RNG 4.6) plus the run-creation HTTP call.
## Registered as autoload `RunSession` by lane I; it lives in scripts/net so a change here never moves
## the fingerprint of res://autoload.
##
## What it guarantees to RemoteEpochSource:
##   * every message has a `seq` (starts at 0) and is answered at most once per seq;
##   * a request stays queued while the socket is down and is re-sent after `hello{last_seq}`; the server
##     answers a repeated seq with the SAME seed, so a lost reply is harmless;
##   * the 16 KB message cap, an 8 s answer timeout (re-sent up to 3 times) and a 30 s "offline" verdict.
## It never decides anything about the rules: it moves bytes.

signal state_changed(state: String)
signal kicked(reason: String)

const REPLY_TIMEOUT_S := 8.0
const MAX_TRIES := 3
const OFFLINE_AFTER_S := 30.0
const RECONNECT_BACKOFF: Array[float] = [1.0, 2.0, 4.0, 8.0]

var run_id := ""
var commit := ""
var header: Dictionary = {}
var state := "idle"   # idle | connecting | ready | reconnecting | closed

## http.call(method, path, body_text, done(code:int, text:String)); defaults to AccountService.transport.
var http: Callable
## socket_factory.call() -> object with WebSocketPeer's methods. Tests inject a fake.
var socket_factory: Callable = func() -> Object:
	return null if NetGuard.blocked() else WebSocketPeer.new()

var _sock: Object = null
var _token := ""
var _ws_url := ""
var _last_ack := -1
var _inflight: Dictionary = {}    # seq -> {msg, reply, sent, age, tries, queued_age}
var _backoff := 0
var _retry_in := 0.0
var _sent_hello := false
var _refreshed := false    # one token refresh per connection loss; reset by welcome/resync (no infinite loop)
var _refreshing := false   # /api/run/open in flight


# ============================================================================ run creation

## POST /api/run. done(ok:bool, data:Dictionary): data = {run_id, commit, header} or {code}.
func create_run(params: Dictionary, done: Callable) -> void:
	var body := JSON.stringify(params)
	_http().call("POST", "/api/run", body, func(code: int, text: String) -> void:
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("run_token"):
			var d: Dictionary = j
			attach(String(d["run_id"]), String(d["run_token"]), String(d["ws_url"]))
			commit = String(d.get("commit", ""))
			header = d.get("header", {})
			done.call(true, {"run_id": run_id, "commit": commit, "header": header})
		else:
			done.call(false, {"code": _http_code(code, j)}))


## GET /api/run/open: resume an unfinished run. done(ok, data) with data {} when there is none.
func open_existing(done: Callable) -> void:
	_http().call("GET", "/api/run/open", "", func(code: int, text: String) -> void:
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code == 200 and typeof(j) == TYPE_DICTIONARY:
			var d: Dictionary = j
			if d.has("run_token"):
				attach(String(d["run_id"]), String(d["run_token"]), String(d["ws_url"]))
				commit = String(d.get("commit", ""))
				header = d.get("header", {})
			done.call(true, d)
		else:
			done.call(false, {"code": _http_code(code, j)}))


## GET /api/run/daily: Daily tries today. done(ok, {used, max, resets_at}) or (false, {code}).
func daily_info(done: Callable) -> void:
	if not _http().is_valid():
		done.call(false, {"code": "offline"})
		return
	_http().call("GET", "/api/run/daily", "", func(code: int, text: String) -> void:
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("used"):
			done.call(true, j)
		else:
			done.call(false, {"code": _http_code(code, j)}))


func abandon(done: Callable) -> void:
	_http().call("POST", "/api/run/%s/abandon" % run_id, "", func(code: int, _t: String) -> void:
		if code == 200:
			_teardown("closed")
		done.call(code == 200))


## Drops the socket and forgets the attached run without telling the server (used when open_existing()
## attached us to a run we decided not to play; the run itself stays as it is on the server).
func release() -> void:
	_teardown("idle")


## Server error mapped to an EpochReply code: run_open / daily_cap / not_available / version / server.
static func _http_code(code: int, j: Variant) -> String:
	if code == 0:
		return "offline"
	if typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("error"):
		return String((j as Dictionary)["error"])
	return "server"


func _http() -> Callable:
	if http.is_valid():
		return http
	return AccountService.transport


## Point the session at a run (new or resumed) and open the socket.
func attach(p_run_id: String, p_token: String, p_ws_url: String) -> void:
	_teardown("idle")
	run_id = p_run_id
	_token = p_token
	_ws_url = p_ws_url
	_last_ack = -1
	_refreshed = false
	_refreshing = false
	set_process(true)
	_connect()


# ============================================================================ messaging

## Queues `msg` (must carry `seq`). `reply` settles when the server answers.
func submit(msg: Dictionary, reply: EpochReply) -> void:
	var seq := int(msg["seq"])
	if JSON.stringify(msg).length() > 16 * 1024:
		reply.settle(false, 0, "bad_request")
		return
	_inflight[seq] = {"msg": msg, "reply": reply, "sent": false, "age": 0.0, "tries": 0, "queued": 0.0}
	if state == "ready":
		_send_inflight(seq)
	elif state == "idle" or state == "closed":
		_inflight.erase(seq)
		reply.settle(false, 0, "offline")


func last_ack() -> int:
	return _last_ack


func _connect() -> void:
	_sock = socket_factory.call()
	_sent_hello = false
	_set_state("connecting" if _backoff == 0 and state != "reconnecting" else "reconnecting")
	if _sock == null:   # NetGuard: no real socket in tests
		_schedule_retry()
		return
	var err: int = _sock.connect_to_url(_ws_url)
	if err != OK:
		_schedule_retry()


func _set_state(s: String) -> void:
	if state != s:
		state = s
		state_changed.emit(s)


func _schedule_retry() -> void:
	_sock = null
	_set_state("reconnecting")
	_retry_in = RECONNECT_BACKOFF[mini(_backoff, RECONNECT_BACKOFF.size() - 1)]
	_backoff += 1


func _init() -> void:
	set_process(false)   # nothing to poll until a run attaches (attach() turns it on, teardown to idle/closed off)


func _process(delta: float) -> void:
	tick(delta)


## Separate from _process so tests can drive time. delta in seconds.
func tick(delta: float) -> void:
	if state == "idle" or state == "closed" or _refreshing:
		return
	if _sock == null:
		_retry_in -= delta
		if _retry_in <= 0.0:
			_connect()
	else:
		_sock.poll()
		var rs: int = _sock.get_ready_state()
		if rs == WebSocketPeer.STATE_OPEN:
			if not _sent_hello:
				_sent_hello = true
				_send({"t": "hello", "run_token": _token, "last_seq": _last_ack})
			while _sock != null and _sock.get_available_packet_count() > 0:
				_on_packet((_sock.get_packet() as PackedByteArray).get_string_from_utf8())
		elif rs == WebSocketPeer.STATE_CLOSED:
			var code: int = _sock.get_close_code()
			var why: String = _sock.get_close_reason() if _sock.has_method("get_close_reason") else ""
			_sock = null
			if code == 1008 and why == "auth" and not _refreshed:
				_refresh_token()
				return
			if code == 1008 or code == 4001:
				_fail_all("expired" if code == 1008 else "version")
				_teardown("closed")
				return
			_schedule_retry()
	_age_requests(delta)


## 1008 'auth' = the token was revoked or replaced: ask /api/run/open for a fresh one and say hello again, once.
func _refresh_token() -> void:
	_refreshed = true
	_refreshing = true
	_set_state("reconnecting")
	var rid := run_id
	_http().call("GET", "/api/run/open", "", func(code: int, text: String) -> void:
		if not _refreshing or run_id != rid:
			return   # torn down or re-attached while the request was out
		_refreshing = false
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("run_token") \
				and String((j as Dictionary).get("run_id", "")) == rid:
			var d: Dictionary = j
			_token = String(d["run_token"])
			_ws_url = String(d.get("ws_url", _ws_url))
			_backoff = 0
			_connect()
		else:
			_fail_all("expired")
			_teardown("closed"))


func _age_requests(delta: float) -> void:
	for seq in _inflight.keys():
		var e: Dictionary = _inflight[seq]
		if state != "ready" or not bool(e["sent"]):
			e["queued"] = float(e["queued"]) + delta
			if float(e["queued"]) > OFFLINE_AFTER_S:
				_inflight.erase(seq)
				(e["reply"] as EpochReply).settle(false, 0, "offline")
			continue
		e["age"] = float(e["age"]) + delta
		if float(e["age"]) > REPLY_TIMEOUT_S:
			if int(e["tries"]) >= MAX_TRIES:
				_inflight.erase(seq)
				(e["reply"] as EpochReply).settle(false, 0, "timeout")
			else:
				_send_inflight(seq)


func _send_inflight(seq: int) -> void:
	var e: Dictionary = _inflight[seq]
	e["sent"] = true
	e["age"] = 0.0
	e["queued"] = 0.0
	e["tries"] = int(e["tries"]) + 1
	_send(e["msg"])


func _send(msg: Dictionary) -> void:
	if _sock != null:
		_sock.send_text(JSON.stringify(msg))


func _on_packet(text: String) -> void:
	var j: Variant = JSON.parse_string(text)
	if typeof(j) != TYPE_DICTIONARY:
		return
	var m: Dictionary = j
	match String(m.get("t", "")):
		"welcome":
			_backoff = 0
			_refreshed = false
			_set_state("ready")
			for seq in _inflight.keys():   # unanswered requests go out again; the server replays old answers
				_send_inflight(int(seq))
		"resync":
			_backoff = 0
			_refreshed = false
			for row in m.get("tail", []):
				var r: Dictionary = row
				_answer(int(r["seq"]), true, int(r["seed"]), "", {})
			_set_state("ready")
			for seq in _inflight.keys():
				_send_inflight(int(seq))
		"epoch_res":
			_answer(int(m["seq"]), true, int(m["seed"]), "", m.get("extra", {}))
		"aid_res":
			_answer(int(m["seq"]), true, 0, "", {"h": String(m.get("h", "")), "log_len": int(m.get("log_len", 0)), "row_types": (m.get("extra", {}) as Dictionary).get("row_types", {})})
		"closed":
			_answer(int(m["seq"]), true, 0, "", {})
		"epoch_err":
			_answer(int(m["seq"]), false, 0, String(m.get("code", "rejected")), {})
		"bye":
			var reason := String(m.get("reason", ""))
			_fail_all("version" if reason == "version" else "expired")
			_teardown("closed")
			kicked.emit(reason)


func _answer(seq: int, ok: bool, seed_value: int, code: String, extra: Dictionary) -> void:
	if not _inflight.has(seq):
		return
	var e: Dictionary = _inflight[seq]
	_inflight.erase(seq)
	if ok:
		_last_ack = maxi(_last_ack, seq)
	(e["reply"] as EpochReply).settle(ok, seed_value, code, extra)


func _fail_all(code: String) -> void:
	for seq in _inflight.keys():
		var e: Dictionary = _inflight[seq]
		(e["reply"] as EpochReply).settle(false, 0, code)
	_inflight.clear()


func _teardown(new_state: String) -> void:
	_refreshing = false
	if _sock != null:
		_sock.close()
		_sock = null
	_set_state(new_state)
	if new_state == "idle" or new_state == "closed":
		_fail_all("offline")
		set_process(false)
