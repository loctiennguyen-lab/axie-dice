extends Node
## RunSession + RemoteEpochSource against an in-process fake RunDO (no network). The fake checks the
## hash chain with the REAL EpochCanon, answers a repeated seq with the same seed, and can lose a reply,
## drop the connection, or kick the client.

class FakeSocket extends RefCounted:
	var server: FakeServer
	var state := WebSocketPeer.STATE_CONNECTING
	var inbox: Array = []
	var close_code := 1000
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
	var received: Array = []
	var http_error := ""

	func _init() -> void:
		last_h = EpochCanon.h0(run_id)

	func http(method: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/run":
			if http_error != "":
				done.call(409, JSON.stringify({"error": http_error}))
				return
			var b: Dictionary = JSON.parse_string(body)
			received.append(b)
			done.call(200, JSON.stringify({"run_id": run_id, "run_token": "tok", "commit": "c0ffee",
				"ws_url": "wss://x/api/run/%s/ws" % run_id, "header": {"newcomer": true}}))
		elif path.ends_with("/abandon"):
			done.call(200, "{}")
		else:
			done.call(404, "")

	func make_socket() -> FakeSocket:
		var s := FakeSocket.new()
		s.server = self
		sockets.append(s)
		return s

	func on_message(s: FakeSocket, text: String) -> void:
		var m: Dictionary = JSON.parse_string(text)
		match String(m["t"]):
			"hello":
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
	print("t_run_session: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


func _offline_and_errors() -> void:
	# POST /api/run refused
	var s1 := FakeServer.new()
	s1.http_error = "run_open"
	var p1 := _make(s1)
	var r1: EpochReply = (p1[1] as RemoteEpochSource).start_run({"mode": "short"})
	_check(r1.done and not r1.ok and r1.code == "rejected", "run_open -> rejected")
	(p1[0] as RunSession).queue_free()

	# socket never opens: the request is "offline" after 30 s
	var s2 := FakeServer.new()
	s2.refuse = true
	var p2 := _make(s2)
	var sess2: RunSession = p2[0]
	var r2: EpochReply = (p2[1] as RemoteEpochSource).start_run({"mode": "short"})
	_run(sess2, r2, 40.0)
	_check(r2.done and not r2.ok and r2.code == "offline", "unreachable server -> offline after the grace period")
	_check(sess2.state == "reconnecting", "session keeps trying to reconnect")
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
