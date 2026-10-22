extends Node
## Web path (Liam 22/10): RunSetup Begin -> RunState.begin_run -> RemoteEpochSource over a FAKE RunSession (no network).
## The fake server writes depth_stage 2 into the run header. Expect: Begin sends anchor:true, the AnchorPick screen shows,
## Gambler is picked, the action log holds pick_anchor, and the next epoch request carries pick_anchor in its log_delta.

class FakeSocket extends RefCounted:
	var server: FakeServer
	var state := WebSocketPeer.STATE_CONNECTING
	var inbox: Array = []
	func connect_to_url(_u: String) -> int:
		return OK
	func poll() -> void:
		if state == WebSocketPeer.STATE_CONNECTING:
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
		return 1000
	func get_close_reason() -> String:
		return ""


class FakeServer extends RefCounted:
	var run_id := "0123456789abcdef0123456789abcdef"
	var rows: Array = []
	var last_h: PackedByteArray
	var last_len := 0
	var create_bodies: Array = []
	var epoch_msgs: Array = []
	var stage := 2

	func _init() -> void:
		last_h = EpochCanon.h0(run_id)

	func http(_method: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/run":
			create_bodies.append(JSON.parse_string(body))
			done.call(200, JSON.stringify({"run_id": run_id, "run_token": "tok", "commit": "c0ffee",
				"ws_url": "wss://x/api/run/%s/ws" % run_id, "header": {"depth_stage": stage, "newcomer": false}}))
		else:
			done.call(404, "")

	func make_socket() -> FakeSocket:
		var s := FakeSocket.new()
		s.server = self
		return s

	func on_message(s: FakeSocket, text: String) -> void:
		var m: Dictionary = JSON.parse_string(text)
		match String(m["t"]):
			"hello":
				s.inbox.append(JSON.stringify({"t": "welcome", "seq": rows.size() - 1, "h": last_h.hex_encode(), "log_len": last_len}))
			"epoch_req":
				_epoch(s, m)

	func _epoch(s: FakeSocket, m: Dictionary) -> void:
		var seq := int(m["seq"])
		for r in rows:
			if int(r["seq"]) == seq:
				s.inbox.append(JSON.stringify({"t": "epoch_res", "seq": seq, "seed": r["seed"]}))
				return
		if seq != rows.size():
			s.inbox.append(JSON.stringify({"t": "epoch_err", "seq": seq, "code": "out_of_order"}))
			return
		var h: PackedByteArray
		if seq == 0:
			h = EpochCanon.h0(run_id)
		else:
			h = EpochCanon.chain_step(last_h, String(EpochCanon.delta(m["log_delta"])["canon"]))
		if String(m["h"]) != h.hex_encode():
			s.inbox.append(JSON.stringify({"t": "epoch_err", "seq": seq, "code": "rejected"}))
			return
		epoch_msgs.append(m)
		last_h = h
		last_len = int(m["log_len"])
		var seed_value := 1000 + seq * 7
		rows.append({"seq": seq, "kind": m["kind"], "seed": seed_value})
		var extra := {}
		if m["kind"] == "node":
			extra = {"row_types": {"2": ["battle", "event"]}}
		s.inbox.append(JSON.stringify({"t": "epoch_res", "seq": seq, "seed": seed_value, "extra": extra}))


var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()
var _tree: SceneTree


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _finish() -> void:
	UI3Gacha.instant_override = -1
	ProjectSettings.set_setting("axie/epoch_source", "local")
	_guard.restore()
	print("=== t_anchor_flow_online_session: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_anchor_flow_online_session: PASS")
	_tree.quit(0 if _fail == 0 else 1)


func _ready() -> void:
	print("=== t_anchor_flow_online_session: start ===")
	_tree = get_tree()
	_guard.capture()
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = null
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	var srv := FakeServer.new()
	var sess := RunState.run_session()
	sess.http = srv.http
	sess.socket_factory = srv.make_socket
	MetaState.runs = 0
	MetaState.runs_with_battle = 0
	MetaState.runs_completed = 0
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	add_child(s)
	await _frames(2)
	_ok(s.start_params().get("anchor", false) == true, "start_params carries anchor:true")
	s._begin_btn.pressed.emit()
	for _i in 120:
		await _frames(1)
		if RunState.epoch != null and not RunState.epoch_busy and RunState.epoch.is_remote() and not RunState.pending_rewards.is_empty() or RunState._anchor_waiting:
			break
	_ok(srv.create_bodies.size() == 1, "POST /api/run sent once")
	_ok(RunState.epoch != null and RunState.epoch.is_remote(), "run uses RemoteEpochSource")
	_ok(RunState.depth_stage == 2, "depth_stage 2 comes from the server header (got %d, local account stage %d)" % [RunState.depth_stage, MetaState.depth_stage()])
	_ok(RunState.anchor_wanted and RunState.anchor_gate_reason() == "", "Anchor gate open online at stage 2: " + RunState.anchor_gate_reason())
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	var pick := rm.find_child("AnchorPick", true, false) as AnchorPick
	_ok(pick != null and pick.cards.size() == 3, "AnchorPick shows 3 cards")
	if pick == null:
		s.queue_free()
		_finish()
		return
	var gi := -1
	for i in pick.cards.size():
		if String(pick.cards[i].get_meta("anchor_id")) == "a_gambler":
			gi = i
	_ok(gi >= 0, "Gambler offered")
	pick.select(gi)
	pick.take_button.pressed.emit()
	await _frames(10)
	_ok(RunState.anchor_id == "a_gambler", "Gambler chosen")
	var idx := RunState.anchor_offer.find("a_gambler")
	var found := false
	for e in RunState.action_log.entries:
		if String(e["fn"]) == "pick_anchor" and int((e["args"] as Array)[0]) == idx:
			found = true
	_ok(found and idx >= 0, "action_log has pick_anchor [%d]" % idx)
	# take Core 1 through the overlay, then enter a node: that epoch request must carry the pick in its log_delta
	_ok(not RunState.pending_rewards.is_empty(), "first Core offer open")
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(12)
	rm.free()   # the map would change scene to Combat on node_entered
	var before := srv.epoch_msgs.size()
	var r := await RunState.request_enter_node("r1_c0", "battle")
	_ok(bool(r["ok"]), "node epoch answered by the fake server: " + str(r))
	var carried := false
	if srv.epoch_msgs.size() > before:
		for d in (srv.epoch_msgs[srv.epoch_msgs.size() - 1]["log_delta"] as Array):
			if String((d as Dictionary).get("fn", "")) == "pick_anchor":
				carried = true
	_ok(carried, "next epoch request log_delta carries pick_anchor: " + str(srv.epoch_msgs.back().get("log_delta", []) if not srv.epoch_msgs.is_empty() else "<none>"))
	s.queue_free()
	_finish()
