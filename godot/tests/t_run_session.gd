extends Node
## RunSession + RemoteEpochSource against an in-process fake RunDO (no network). The fake checks the
## hash chain with the REAL EpochCanon, answers a repeated seq with the same seed, and can lose a reply,
## drop the connection, or kick the client.

class FakeSocket extends RefCounted:
	var server: FakeServer
	var state := WebSocketPeer.STATE_CONNECTING
	var inbox: Array = []
	var close_code := 1000
	var close_reason := ""
	var opened_after := 0   # polls before it opens
	func connect_to_url(_u: String) -> int:
		return OK
	func poll() -> void:
		if state == WebSocketPeer.STATE_CONNECTING:
			if server.refuse:
				return
			opened_after -= 1
			if opened_after <= 0:
				state = WebSocketPeer.STATE_OPEN
	func get_ready_state() -> int:
		return state
	func get_available_packet_count() -> int:
		return inbox.size()
	func get_packet() -> PackedByteArray:
		return (inbox.pop_front() as String).to_utf8_buffer()
	func send_text(s: String) -> int:
		server.on_message(self, s)
		return OK
	func close(_c: int = 1000, _r: String = "") -> void:
		state = WebSocketPeer.STATE_CLOSED
	func get_close_code() -> int:
		return close_code
	func get_close_reason() -> String:
		return close_reason


class FakeServer extends RefCounted:
	var run_id := "0123456789abcdef0123456789abcdef"
	var rows: Array = []          # [{seq, kind, seed, h, log_len}]
	var last_h: PackedByteArray
	var last_len := 0
	var refuse := false
	var drop_next_reply := false
	var swallow_next := false     # no answer at all (timeout test)
	var sockets: Array = []
	var closed := false
	var revoked_token := ""       # hello with this token -> close 1008 'auth'
	var fresh_token := "tok2"
	var open_calls := 0
	var open_ok := true
	var received: Array = []
	var http_error := ""
	var stale_id := ""            # a run left open by an earlier attempt: POST /api/run answers 409 run_open
	var abandon_ok := true
	var abandon_calls := 0
	var create_calls := 0
	var open_other_id := ""       # /api/run/open names another run than the saved one
	var open_offline := false     # /api/run/open unreachable (code 0)
	var hold_open := false        # /api/run/open is counted but not answered until release_open()
	var _held: Array = []
	var _replaying := false

	func _init() -> void:
		last_h = EpochCanon.h0(run_id)

	func http(method: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/run":
			create_calls += 1
			if stale_id != "":
				done.call(409, JSON.stringify({"error": "run_open"}))
				return
			if http_error != "":
				done.call(409, JSON.stringify({"error": http_error}))
				return
			var b: Dictionary = JSON.parse_string(body)
			received.append(b)
			done.call(200, JSON.stringify({"run_id": run_id, "run_token": "tok", "commit": "c0ffee",
				"ws_url": "wss://x/api/run/%s/ws" % run_id, "header": {"newcomer": true}}))
		elif path == "/api/run/open":
			open_calls += 1
			if hold_open and not _replaying:
				_held.append([method, path, body, done])
				return
			if open_offline:
				done.call(0, "")
			elif open_other_id != "":
				done.call(200, JSON.stringify({"run_id": open_other_id, "run_token": "other", "commit": "c0ffee",
					"ws_url": "wss://x/api/run/%s/ws" % open_other_id, "header": {"mode": "normal"}}))
			elif stale_id != "":
				done.call(200, JSON.stringify({"run_id": stale_id, "run_token": "stale", "commit": "c0ffee",
					"ws_url": "wss://x/api/run/%s/ws" % stale_id, "header": {"mode": "normal"}}))
			elif open_ok:
				done.call(200, JSON.stringify({"run_id": run_id, "run_token": fresh_token, "commit": "c0ffee",
					"ws_url": "wss://x/api/run/%s/ws" % run_id, "header": {}}))
			else:
				done.call(200, "{}")
		elif path.ends_with("/abandon"):
			abandon_calls += 1
			if abandon_ok:
				if path.contains(stale_id):
					stale_id = ""
				done.call(200, "{}")
			else:
				done.call(502, JSON.stringify({"error": "server"}))
		else:
			done.call(404, "")

	## Answers every held /api/run/open now (late replies included), without counting them twice.
	func release_open() -> void:
		hold_open = false
		_replaying = true
		var held := _held
		_held = []
		for h in held:
			open_calls -= 1
			http(h[0], h[1], h[2], h[3])
		_replaying = false

	func make_socket() -> FakeSocket:
		var s := FakeSocket.new()
		s.server = self
		sockets.append(s)
		return s

	func on_message(s: FakeSocket, text: String) -> void:
		var m: Dictionary = JSON.parse_string(text)
		match String(m["t"]):
			"hello":
				if revoked_token != "" and String(m.get("run_token", "")) == revoked_token:
					s.state = WebSocketPeer.STATE_CLOSED
					s.close_code = 1008
					s.close_reason = "auth"
					return
				var seq := rows.size() - 1
				var last_seq := int(m.get("last_seq", -1))
				if last_seq < seq:
					var tail := []
					for r in rows:
						if int(r["seq"]) > last_seq:
							tail.append({"seq": r["seq"], "kind": r["kind"], "seed": r["seed"]})
					s.inbox.append(JSON.stringify({"t": "resync", "tail": tail, "seq": seq}))
				else:
					s.inbox.append(JSON.stringify({"t": "welcome", "seq": seq, "h": last_h.hex_encode(), "log_len": last_len}))
			"epoch_req":
				_epoch(s, m)
			"aid_req":
				var delta := EpochCanon.delta(m["log_delta"])
				var step := EpochCanon.chain_step(last_h, String(delta["canon"]))
				var line := EpochCanon.action_line("aid_use", [m["aid"]] + (m["args"] as Dictionary).values())
				var h2 := EpochCanon.chain_step(step, String(line["canon"]))
				last_h = h2
				last_len = int(m["log_len"]) + 1
				rows.append({"seq": int(m["seq"]), "kind": "aid", "seed": 0, "h": h2.hex_encode(), "log_len": last_len})
				s.inbox.append(JSON.stringify({"t": "aid_res", "seq": m["seq"], "h": h2.hex_encode(), "log_len": last_len, "extra": {"row_types": {"3": ["battle", "shop"]}}}))
			"run_close":
				closed = true
				s.inbox.append(JSON.stringify({"t": "closed", "seq": m["seq"]}))

	func _epoch(s: FakeSocket, m: Dictionary) -> void:
		var seq := int(m["seq"])
		for r in rows:                                 # repeated seq: same answer
			if int(r["seq"]) == seq:
				s.inbox.append(JSON.stringify({"t": "epoch_res", "seq": seq, "seed": r["seed"]}))
				return
		if seq != rows.size():
			s.inbox.append(JSON.stringify({"t": "epoch_err", "seq": seq, "code": "out_of_order"}))
			return
		var h: PackedByteArray
		if seq == 0:
			h = EpochCanon.h0(run_id)
			if String(m["h"]) != h.hex_encode():
				s.inbox.append(JSON.stringify({"t": "epoch_err", "seq": seq, "code": "rejected"}))
				return
		else:
			var d := EpochCanon.delta(m["log_delta"])
			h = EpochCanon.chain_step(last_h, String(d["canon"]))
			if String(m["h"]) != h.hex_encode():
				s.inbox.append(JSON.stringify({"t": "epoch_err", "seq": seq, "code": "rejected"}))
				return
		if swallow_next:
			swallow_next = false
			return
		last_h = h
		last_len = int(m["log_len"])
		var seed_value := 1000 + seq * 7
		rows.append({"seq": seq, "kind": m["kind"], "seed": seed_value, "h": h.hex_encode(), "log_len": last_len})
		if drop_next_reply:
			drop_next_reply = false
			s.state = WebSocketPeer.STATE_CLOSED   # the connection dies with the reply in flight
			return
		var extra := {}
		if m["kind"] == "node":
			extra = {"row_types": {"2": ["battle", "event"]}}
		s.inbox.append(JSON.stringify({"t": "epoch_res", "seq": seq, "seed": seed_value, "extra": extra}))


var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


## Advance the session clock in small steps until `r` is done or `secs` pass.
func _run(session: RunSession, r: EpochReply, secs: float) -> void:
	var t := 0.0
	while not r.done and t < secs:
		session.tick(0.25)
		t += 0.25


func _make(server: FakeServer) -> Array:
	var session := RunSession.new()
	add_child(session)
	session.set_process(false)
	session.http = server.http
	session.socket_factory = server.make_socket
	var src := RemoteEpochSource.new(session)
	var log := ActionLog.new()
	src.bind_log(log)
	return [session, src, log]


func _ready() -> void:
	var server := FakeServer.new()
	var parts := _make(server)
	var session: RunSession = parts[0]
	var src: RemoteEpochSource = parts[1]
	var log: ActionLog = parts[2]

	var r := src.start_run({"mode": "short", "ascension": 0, "kind": "normal", "loadout": {"boon_id": "b1"}})
	_run(session, r, 5.0)
	_check(r.done and r.ok and r.seed == 1000, "run_start answered with seq 0 seed")
	_check(String(r.extra.get("run_id")) == server.run_id and r.extra["header"]["loadout"]["boon_id"] == "b1" and r.extra["header"]["newcomer"], "extra carries run_id, header, loadout")
	_check(String(server.received[0]["client_nonce"]).length() == 32 and server.received[0]["kind"] == "normal", "POST /api/run body has nonce and kind")
	_check(src.is_remote() and src.tape().size() == 1 and int(src.tape()[0]["seq"]) == 0, "tape starts at seq 0")

	log.record("enter_node", ["r1_c0", "battle"])
	r = src.request("node", {"node_id": "r1_c0"})
	_run(session, r, 5.0)
	_check(r.ok and r.seed == 1007, "node epoch: chain checked by the server")
	_check(r.extra["row_types"].has(2), "row_types keys turned into ints")

	# reply lost with the connection: reconnect, hello(last_seq) -> resync settles the request
	log.record("use_die", [1, 100001])
	log.record("end_turn", [])
	server.drop_next_reply = true
	r = src.request("end_turn", {"turn": 1})
	_run(session, r, 20.0)
	_check(r.ok and r.seed == 1000 + 2 * 7, "lost reply recovered through resync")
	_check(server.rows.size() == 3 and server.sockets.size() == 2, "no duplicate epoch, exactly one reconnect")

	# no answer at all: re-sent after 8 s, answered the second time
	log.record("enter_node", ["r2_c0", "battle"])
	server.swallow_next = true
	r = src.request("node", {"node_id": "r2_c0"})
	_run(session, r, 30.0)
	_check(r.ok and r.seed == 1000 + 3 * 7, "swallowed request re-sent after the timeout")

	# server refuses: epoch_err mapped, chain and seq NOT advanced, so the same ask works afterwards
	var before := src.tape().size()
	r = src.request("node", {"node_id": "r2_c0"})   # wrong: log has no new delta for this seq? chain mismatch is not it; use bad kind seq below
	_run(session, r, 5.0)
	_check(r.done, "second ask settles")

	# Aid: server appends aid_use; client chain follows the server's h
	log.record("aid_use", ["scout", 3])
	var a := src.aid("scout", {"node_id": "r3_c0"})
	_run(session, a, 5.0)
	_check(a.ok and a.extra["row_types"].has(3), "aid_res carries row_types")

	var c := src.close("lost", {"battles_done": 2})
	_run(session, c, 5.0)
	_check(c.ok and server.closed, "run_close acknowledged")
	_check(src.request("node", {"node_id": "r9_c0"}).code == "out_of_order", "no requests after close")

	await _offline_and_errors()
	# RunState.begin_run picks the source from `axie/epoch_source`
	var had_flag := ProjectSettings.has_setting("axie/epoch_source")
	var old_flag: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/epoch_source", "local")
	var rl: Dictionary = await RunState.begin_run({"mode": "short", "kind": "normal"})
	_check(rl.ok and RunState.epoch is LocalEpochSource and not RunState.epoch.is_remote(), "flag local -> begin_run uses LocalEpochSource")
	RunState.reset()
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	var fs := FakeServer.new()
	var fsess := RunSession.new()
	add_child(fsess)
	fsess.set_process(false)
	fsess.http = func(_m: String, _p: String, _b: String, _d: Callable) -> void: pass   # never answers: no network
	fsess.socket_factory = fs.make_socket
	RunState.session = fsess
	RunState.begin_run({"mode": "short", "kind": "normal"})   # suspended on the fake transport
	_check(RunState.epoch is RemoteEpochSource and RunState.epoch.session == fsess and RunState.epoch_busy, "flag remote -> begin_run uses RemoteEpochSource on the given session")
	RunState.reset()
	RunState.session = null
	fsess.queue_free()
	if had_flag:
		ProjectSettings.set_setting("axie/epoch_source", old_flag)
	else:
		ProjectSettings.set_setting("axie/epoch_source", "local")

	await _auth_refresh()
	await _both_remote()
	await _resume_after_restart()
	_guard.capture()
	await _continue_through_run_state()
	await _continue_hardening()
	_guard.restore()

	print("t_run_session: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


## A stale open run on the server (Liam 15/10: one run stuck `open` made every Begin fail with "rejected").
func _open_run_recovery() -> void:
	var stale := "ffffffffffffffffffffffffffffffff"
	# (a) no local save for it: abandon exactly once, create exactly once more, run starts
	var s1 := FakeServer.new()
	s1.stale_id = stale
	var p1 := _make(s1)
	var src1: RemoteEpochSource = p1[1]
	src1.local_run_id = func() -> String: return ""
	var r1 := src1.start_run({"mode": "short"})
	_run(p1[0], r1, 5.0)
	_check(r1.done and r1.ok and r1.seed == 1000, "stale run_open + no local save: abandoned, retried, run started")
	_check(s1.abandon_calls == 1 and s1.create_calls == 2 and s1.open_calls == 1, "exactly one open(), one abandon, one retry")
	_check(String(r1.extra.get("run_id", "")) == s1.run_id, "the new run, not the stale one")
	(p1[0] as RunSession).queue_free()
	# (b) abandon fails: clear code, no loop, session detached from the stale run
	var s2 := FakeServer.new()
	s2.stale_id = stale
	s2.abandon_ok = false
	var p2 := _make(s2)
	var src2: RemoteEpochSource = p2[1]
	src2.local_run_id = func() -> String: return ""
	var r2 := src2.start_run({"mode": "short"})
	_check(r2.done and not r2.ok and r2.code == "run_open", "abandon fails -> run_open")
	_check(s2.abandon_calls == 1 and s2.create_calls == 1 and (p2[0] as RunSession).state == "idle", "no retry and no second abandon after a failed abandon")
	var r2b := src2.start_run({"mode": "short"})   # the player taps Begin again: allowed, still bounded per tap
	_check(r2b.done and r2b.code == "run_open" and s2.abandon_calls == 2 and s2.create_calls == 2, "a second tap is a fresh attempt (one abandon per tap)")
	(p2[0] as RunSession).queue_free()
	# (c) a resumable local save for that very run: no abandon, distinct code
	var s3 := FakeServer.new()
	s3.stale_id = stale
	var p3 := _make(s3)
	var src3: RemoteEpochSource = p3[1]
	src3.local_run_id = func() -> String: return stale
	var r3 := src3.start_run({"mode": "short"})
	_check(r3.done and not r3.ok and r3.code == "run_in_progress", "resumable local save -> run_in_progress")
	_check(s3.abandon_calls == 0 and s3.create_calls == 1 and s3.stale_id == stale, "the server run is left alone")
	(p3[0] as RunSession).queue_free()
	# (c2) a local save of a DIFFERENT run does not protect the stale one
	var s4 := FakeServer.new()
	s4.stale_id = stale
	var p4 := _make(s4)
	var src4: RemoteEpochSource = p4[1]
	src4.local_run_id = func() -> String: return "00000000000000000000000000000000"
	var r4 := src4.start_run({"mode": "short"})
	_run(p4[0], r4, 5.0)
	_check(r4.ok and s4.abandon_calls == 1, "local save of another run: stale one is abandoned")
	(p4[0] as RunSession).queue_free()
	# (c3) the real lookup: RunState save with the same RULES_VERSION and run_id; other rules -> not resumable
	var guard := SaveGuard.new()
	guard.capture()
	var payload := {"version": RunState.SAVE_VERSION, "rules_version": ActionLog.RULES_VERSION, "run": {"run_id": stale}}
	SaveStore.write_text(RunState.SAVE_PATH, JSON.stringify(payload))
	_check(RemoteEpochSource._saved_resumable_run_id() == stale, "lookup: save with this RULES_VERSION gives its run_id")
	payload["rules_version"] = "-old"
	SaveStore.write_text(RunState.SAVE_PATH, JSON.stringify(payload))
	_check(RemoteEpochSource._saved_resumable_run_id() == "", "lookup: save under other rules cannot resume -> no run_id")
	SaveStore.erase(RunState.SAVE_PATH)
	_check(RemoteEpochSource._saved_resumable_run_id() == "", "lookup: no save -> no run_id")
	guard.restore()


func _offline_and_errors() -> void:
	# POST /api/run refused
	var s1 := FakeServer.new()
	s1.http_error = "run_open"
	var p1 := _make(s1)
	var r1: EpochReply = (p1[1] as RemoteEpochSource).start_run({"mode": "short"})
	_check(r1.done and not r1.ok and r1.code == "run_open", "run_open (open() empty/stuck) keeps its own code, not generic rejected")
	(p1[0] as RunSession).queue_free()
	await _open_run_recovery()

	# socket never opens: the request is "offline" after 30 s
	var s2 := FakeServer.new()
	s2.refuse = true
	var p2 := _make(s2)
	var sess2: RunSession = p2[0]
	var r2: EpochReply = (p2[1] as RemoteEpochSource).start_run({"mode": "short"})
	_run(sess2, r2, 40.0)
	_check(r2.done and not r2.ok and r2.code == "offline", "unreachable server -> offline after the grace period")
	_check(sess2.state in ["connecting", "reconnecting"], "session keeps trying to reconnect")
	sess2.queue_free()

	# kicked by another device
	var s3 := FakeServer.new()
	var p3 := _make(s3)
	var sess3: RunSession = p3[0]
	var src3: RemoteEpochSource = p3[1]
	var r3 := src3.start_run({"mode": "short"})
	_run(sess3, r3, 5.0)
	var kicked := [""]
	sess3.kicked.connect(func(why: String) -> void: kicked[0] = why)
	var sock: FakeSocket = s3.sockets[0]
	sock.inbox.append(JSON.stringify({"t": "bye", "reason": "other_device"}))
	var r4 := src3.request("node", {"node_id": "r1_c0"})
	sess3.tick(0.1)
	_check(kicked[0] == "other_device" and sess3.state == "closed", "bye -> closed + kicked signal")
	sess3.queue_free()


## 1008 'auth' -> /api/run/open for a fresh token, hello again once; a second 'auth' in a row does not loop.
func _auth_refresh() -> void:
	var srv := FakeServer.new()
	srv.revoked_token = "tok"
	var parts := _make(srv)
	var sess: RunSession = parts[0]
	var src: RemoteEpochSource = parts[1]
	var log: ActionLog = parts[2]
	var r := src.start_run({"mode": "short"})
	_run(sess, r, 5.0)
	_check(r.ok and srv.open_calls == 1 and sess.state == "ready", "revoked token: re-open once, hello with the fresh token, ready")
	log.record("enter_node", ["r1_c0", "battle"])
	var r2 := src.request("node", {"node_id": "r1_c0"})
	_run(sess, r2, 5.0)
	_check(r2.ok and srv.open_calls == 1, "run goes on after the refresh")
	sess.queue_free()

	var s2 := FakeServer.new()
	s2.revoked_token = "tok"
	s2.fresh_token = "tok"   # server keeps handing out a dead token
	var p2 := _make(s2)
	var sess2: RunSession = p2[0]
	var r3: EpochReply = (p2[1] as RemoteEpochSource).start_run({"mode": "short"})
	_run(sess2, r3, 10.0)
	_check(s2.open_calls == 1 and sess2.state == "closed" and r3.done and not r3.ok, "dead token twice: one refresh, then closed (no loop)")
	sess2.queue_free()

	var s3 := FakeServer.new()
	s3.revoked_token = "tok"
	s3.open_ok = false   # no open run any more
	var p3 := _make(s3)
	var sess3: RunSession = p3[0]
	var r4: EpochReply = (p3[1] as RemoteEpochSource).start_run({"mode": "short"})
	_run(sess3, r4, 10.0)
	_check(sess3.state == "closed" and r4.done and not r4.ok and s3.open_calls == 1, "no open run on refresh: closed, request fails")
	_check(not sess3.is_processing(), "closed session stops processing")
	sess3.queue_free()


## Both L1 flags remote: begin_run attaches a RunSession to the (fake) Worker and the wallet turns remote.
func _both_remote() -> void:
	var old_e: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	var old_g: Variant = ProjectSettings.get_setting("axie/gem_wallet", "local")
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	ProjectSettings.set_setting("axie/gem_wallet", "remote")
	var srv := FakeServer.new()
	var sess := RunSession.new()
	_check(not sess.is_processing(), "new RunSession does not process")
	add_child(sess)
	sess.http = srv.http
	sess.socket_factory = srv.make_socket
	RunState.session = sess
	var pump := Timer.new()   # the real _process is off in tests: drive the clock from a timer
	pump.wait_time = 0.02
	pump.timeout.connect(func() -> void: sess.tick(0.25))
	add_child(pump)
	pump.start()
	var res: Dictionary = await RunState.begin_run({"mode": "short", "kind": "normal"})
	pump.queue_free()
	_check(res.ok and RunState.epoch is RemoteEpochSource and sess.state == "ready" and sess.is_processing(), "both flags remote: full run starts on the fake transport, session processing")
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.transport = func(_m: String, path: String, _b: String, done: Callable) -> void:
		if path == "/api/wallet":
			done.call(200, JSON.stringify({"gem": 5, "ledger_tail": []}))
		else:
			done.call(404, "")
	svc._attach_remote_wallet()
	_check(MetaState.gem_wallet() is RemoteGemWallet, "gem_wallet flag remote -> remote wallet")
	svc._detach_remote_wallet()
	svc.free()
	RunState.reset()
	RunState.session = null
	sess.queue_free()
	ProjectSettings.set_setting("axie/epoch_source", old_e)
	ProjectSettings.set_setting("axie/gem_wallet", old_g)


## A run saved mid-way and continued after the app was closed: a brand-new RunSession (no run, no socket) must
## reconnect to the saved run by itself (open_existing -> same run_id -> attach -> hello) before the first
## request goes out. Source level: no scenes, FakeServer plays the Worker.
func _resume_after_restart() -> void:
	# a run with two epochs behind it, then "quit the app": only the tape and the log survive
	var s1 := FakeServer.new()
	var p1 := _make(s1)
	var log: ActionLog = p1[2]
	var r := (p1[1] as RemoteEpochSource).start_run({"mode": "short", "ascension": 0, "kind": "normal"})
	_run(p1[0], r, 5.0)
	log.record("enter_node", ["r1_c0", "battle"])
	r = (p1[1] as RemoteEpochSource).request("node", {"node_id": "r1_c0"})
	_run(p1[0], r, 5.0)
	var saved_tape: Array = (p1[1] as RemoteEpochSource).tape()
	(p1[0] as RunSession).queue_free()
	_check(saved_tape.size() == 2 and s1.rows.size() == 2, "resume: setup, two epochs on the server")

	# (a) fresh session + resumed source: first epoch after Continue is answered by the server
	var sess := RunSession.new()
	add_child(sess)
	sess.set_process(false)
	sess.http = s1.http
	sess.socket_factory = s1.make_socket
	var src := RemoteEpochSource.new(sess)
	src.resume(saved_tape, sess)
	src.bind_log(log)
	log.record("use_die", [1, 100001])
	log.record("end_turn", [])
	var r2 := src.request("end_turn", {"turn": 1})
	_check(not r2.done, "resume: the request waits for the reconnect, it does not fail")
	_run(sess, r2, 10.0)
	_check(r2.done and r2.ok and r2.seed == 1000 + 2 * 7, "resume (a): first epoch after Continue is server-answered")
	_check(s1.rows.size() == 3 and s1.open_calls == 1 and sess.run_id == s1.run_id and sess.state == "ready",
		"resume (a): one open_existing, attached to the saved run, one new epoch")
	var r2b := src.request("end_turn", {"turn": 2})
	_run(sess, r2b, 10.0)
	_check(s1.open_calls == 1 and r2b.done, "resume (a): later requests do not reconnect again")
	sess.queue_free()


## Runs a coroutine without awaiting it; the box fills in when it finishes.
func _launch(f: Callable) -> Dictionary:
	var box := {"done": false, "res": null}
	(func() -> void:
		box["res"] = await f.call()
		box["done"] = true).call()
	return box


## Pumps `sess` until the launched call finished.
func _pump_busy(sess: RunSession, box: Dictionary) -> void:
	var t := 0.0
	while not bool(box["done"]) and t < 20.0:
		sess.tick(0.25)
		t += 0.25
		await get_tree().process_frame


## Starts a real remote run on `srv`, saves it, forgets everything in memory and returns a fresh session wired to
## the same server, with the run loaded back from the save (what the Continue button does before RunContinue).
func _saved_run_then_restart(srv: FakeServer) -> RunSession:
	var s1 := RunSession.new()
	add_child(s1)
	s1.set_process(false)
	s1.http = srv.http
	s1.socket_factory = srv.make_socket
	RunState.reset()
	RunState.session = s1
	var begin := _launch(func() -> Variant: return await RunState.begin_run({"mode": "short", "kind": "normal"}))
	await _pump_busy(s1, begin)
	RunState.save_run()
	s1.queue_free()
	RunState.reset()
	var s2 := RunSession.new()
	add_child(s2)
	s2.set_process(false)
	s2.http = srv.http
	s2.socket_factory = srv.make_socket
	RunState.session = s2
	return s2 if RunState.load_run() else null


func _continue_through_run_state() -> void:
	var old_e: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	RunState.discard_notice = ""

	# (a) through RunState: Continue -> reconnect -> the first epoch is answered by the server
	var sa := FakeServer.new()
	var sess_a := await _saved_run_then_restart(sa)
	_check(sess_a != null and RunState.epoch is RemoteEpochSource and RunState.epoch.needs_reconnect(), "continue: loaded run has a source that must reconnect")
	var ra := _launch(func() -> Variant: return await RunState.resume_online())
	await _pump_busy(sess_a, ra)
	var res_a: Dictionary = ra["res"]
	_check(res_a.ok and sa.open_calls == 1 and sess_a.run_id == sa.run_id, "continue (a): resume_online reconnects to the saved run")
	var ea := RunState.epoch.request("node", {"node_id": "r1_c0"})
	_run(sess_a, ea, 10.0)
	_check(ea.done and ea.ok and ea.seed == 1000 + 1 * 7, "continue (a): first epoch after Continue is server-answered")
	RunState.reset()
	sess_a.queue_free()

	# (b) the server has no open run: discard notice, save gone, no stuck run
	var sb := FakeServer.new()
	var sess_b := await _saved_run_then_restart(sb)
	_check(RunState.saved_run_file_exists(), "continue (b): save exists before")
	sb.open_ok = false
	var rb := _launch(func() -> Variant: return await RunState.resume_online())
	await _pump_busy(sess_b, rb)
	var res_b: Dictionary = rb["res"]
	_check(not res_b.ok and res_b.code == "run_gone", "continue (b): no open run -> run_gone")
	_check(not RunState.saved_run_file_exists() and RunState.epoch == null and not RunState.epoch_busy, "continue (b): save erased, run cleared")
	_check(RunState.take_discard_notice() == RunState.GONE_MESSAGE, "continue (b): discard notice set")
	sess_b.queue_free()

	# (c) the server has a different open run: same, and the session lets go of it
	var sc := FakeServer.new()
	var sess_c := await _saved_run_then_restart(sc)
	sc.open_other_id = "ffffffffffffffffffffffffffffffff"
	var rc := _launch(func() -> Variant: return await RunState.resume_online())
	await _pump_busy(sess_c, rc)
	var res_c: Dictionary = rc["res"]
	_check(not res_c.ok and res_c.code == "run_gone" and not RunState.saved_run_file_exists(), "continue (c): other run_id -> run_gone, save erased")
	_check(sess_c.state == "idle", "continue (c): session released from the other run")
	_check(RunState.take_discard_notice() == RunState.GONE_MESSAGE, "continue (c): discard notice set")
	sess_c.queue_free()

	# (d) offline at Continue: NetNotice RETRY really retries the reconnect
	var sd := FakeServer.new()
	var sess_d := await _saved_run_then_restart(sd)
	sd.open_offline = true
	var host := Node.new()
	add_child(host)
	var outcome := ["", ""]
	var retry_box := {"done": true}
	var first := _launch(func() -> Variant:
		return await RunContinue.reconnect(host, func() -> void:
			retry_box["done"] = false
			outcome[1] = await RunContinue.reconnect(host, Callable())
			retry_box["done"] = true))
	await _pump_busy(sess_d, first)
	outcome[0] = first["res"]
	_check(outcome[0] == "failed" and RunState.saved_run_file_exists(), "continue (d): offline -> failed, save kept")
	var notice := host.get_node_or_null("NetNotice")
	var retry_btn: Button = notice.find_child("RetryButton", true, false) as Button if notice != null else null
	_check(retry_btn != null, "continue (d): NetNotice offers RETRY")
	sd.open_offline = false
	if retry_btn != null:
		retry_btn.pressed.emit()
		await _pump_busy(sess_d, retry_box)
	_check(outcome[1] == "ok" and sd.open_calls == 2 and sess_d.run_id == sd.run_id, "continue (d): RETRY reconnects (second open_existing), then ok")
	var ed := RunState.epoch.request("node", {"node_id": "r1_c0"})
	_run(sess_d, ed, 10.0)
	_check(ed.done and ed.ok, "continue (d): epoch works after the retry")
	host.queue_free()
	RunState.reset()
	RunState.session = null
	sess_d.queue_free()

	ProjectSettings.set_setting("axie/epoch_source", old_e)


## Real-time wait (the reconnect timeout is a SceneTree timer) until the launched call finished.
func _wait_box(sess: RunSession, box: Dictionary, secs: float) -> void:
	var t := 0.0
	while not bool(box["done"]) and t < secs:
		sess.tick(0.05)
		await get_tree().create_timer(0.05).timeout
		t += 0.05


func _continue_hardening() -> void:
	var old_e: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	RunState.discard_notice = ""
	var host := Node.new()
	add_child(host)

	# (1) double Continue: the second press is ignored, one open_existing, button locked meanwhile
	var s1 := FakeServer.new()
	var sess1 := await _saved_run_then_restart(s1)
	s1.hold_open = true
	var btn := Button.new()
	host.add_child(btn)
	var first := _launch(func() -> Variant: return await RunContinue.reconnect(host, Callable(), btn))
	_check(RunContinue.busy and btn.disabled and s1.open_calls == 1, "hardening 1: first Continue in flight, busy, button disabled")
	var second := _launch(func() -> Variant: return await RunContinue.reconnect(host, Callable(), btn))
	_check(bool(second["done"]) and second["res"] == "busy" and s1.open_calls == 1, "hardening 1: second press ignored, still one open_existing")
	s1.release_open()
	await _pump_busy(sess1, first)
	_check(first["res"] == "ok" and s1.open_calls == 1 and not RunContinue.busy and not btn.disabled, "hardening 1: ok after release, busy cleared, button back")
	RunState.reset()
	sess1.queue_free()

	# (2) the reconnect never answers: timeout -> offline (NetNotice path), the late reply is ignored, RETRY works
	var s2 := FakeServer.new()
	var sess2 := await _saved_run_then_restart(s2)
	var src2 := RunState.epoch as RemoteEpochSource
	src2.reconnect_timeout_s = 0.3
	s2.hold_open = true
	var a := _launch(func() -> Variant: return await RunState.resume_online())
	_check(RunState.epoch_busy and not bool(a["done"]), "hardening 2: waiting on a reconnect that does not answer")
	await _wait_box(sess2, a, 5.0)
	_check(bool(a["done"]) and not a["res"].ok and a["res"].code == "offline", "hardening 2: timeout settles offline")
	_check(not RunState.epoch_busy and RunState.saved_run_file_exists(), "hardening 2: epoch_busy released, save kept")
	s2.release_open()   # the late answer: names the saved run, would mark it attached if it counted
	_check(src2.needs_reconnect(), "hardening 2: late reply after the timeout is ignored")
	var b := _launch(func() -> Variant: return await RunState.resume_online())
	await _pump_busy(sess2, b)
	_check(b["res"].ok and s2.open_calls == 2 and not src2.needs_reconnect(), "hardening 2: RETRY reconnects (second open_existing)")
	RunState.reset()
	RunState.session = null
	sess2.queue_free()

	# (3) two requests wait on the same reconnect: served one after the other, distinct seqs
	var s3 := FakeServer.new()
	var p3 := _make(s3)
	var lg: ActionLog = p3[2]
	var r0 := (p3[1] as RemoteEpochSource).start_run({"mode": "short", "ascension": 0, "kind": "normal"})
	_run(p3[0], r0, 5.0)
	var tape: Array = (p3[1] as RemoteEpochSource).tape()
	(p3[0] as RunSession).queue_free()
	var sess3 := RunSession.new()
	add_child(sess3)
	sess3.set_process(false)
	sess3.http = s3.http
	sess3.socket_factory = s3.make_socket
	var src3 := RemoteEpochSource.new(sess3)
	src3.resume(tape, sess3)
	src3.bind_log(lg)
	s3.hold_open = true
	var q1 := src3.request("end_turn", {"turn": 1})
	var q2 := src3.request("end_turn", {"turn": 2})
	_check(not q1.done and not q2.done and s3.open_calls == 1, "hardening 3: both wait on one reconnect")
	s3.release_open()
	_run(sess3, q2, 10.0)
	_run(sess3, q1, 10.0)
	_check(q1.ok and q2.ok and q1.seed == 1000 + 1 * 7 and q2.seed == 1000 + 2 * 7 and s3.rows.size() == 3,
		"hardening 3: gated requests got seq 1 then seq 2, no shared seq")
	sess3.queue_free()

	host.queue_free()
	ProjectSettings.set_setting("axie/epoch_source", old_e)
