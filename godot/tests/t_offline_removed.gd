extends Node
## B4: no offline play. begin_run refuses without the remote source unless a test opts in; the opening gate shows
## when the server is unreachable and lets go when it answers; tutorial routing still runs after the gate.
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	_check(RunState.local_epoch_allowed() == NetGuard.blocked(), "local epoch allowed exactly under AXIE_TEST_NO_NET (or opt-in)")
	RunState.allow_local_epoch = false
	RunState.force_online_gate = true   # behave like a release build even under AXIE_TEST_NO_NET
	var old_src: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/epoch_source", "local")   # a build whose remote flag is off
	var r := await RunState.begin_run({"team_keys": ["plant1"], "mode": "short", "ascension": 0, "ranked": false})
	_check(not r["ok"] and r["code"] == "offline_removed", "begin_run refuses without server source")
	RunState.force_online_gate = false
	ProjectSettings.set_setting("axie/epoch_source", old_src)
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.online_required_override = true
	_check(svc.gate_reason() == "", "gate open before any failure")
	svc.server_unreachable = true
	_check(svc.online_required(), "online_required with the override, also under NO_NET")
	_check(svc.gate_reason() == "offline", "unreachable server -> gate")
	svc.transport = func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(0, "")
	svc._on_me(0, "")
	_check(svc.server_unreachable and svc.gate_reason() == "offline", "/api/me gets no answer -> gate stays shut")
	svc.server_unreachable = false
	_check(svc.gate_reason() == "", "server answered -> gate open")
	var layer := CanvasLayer.new()
	add_child(layer)
	var g := AccountUI.show_offline_gate(layer, svc)
	_check(g.find_child("TryAgain", true, false) != null, "gate has the Try again button")
	_check(MainMenu.route_target() != "", "route_target still decides tutorial vs land after the gate")
	svc.free()
	_guard.restore()
	print("t_offline_removed: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
