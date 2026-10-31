extends Node
## QA (not headless): frames lb--* of round-3 at the window size (1920x1080 or 1280x720, scale pinned). Stub data, no network.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s7a godot/tools/shot.sh res://tests/qa_ui5_lb_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _rows(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append({"rank": i + 1, "name": ["Alpha", "Bravo", "Charlie", "Delta", "Echo"][i % 5] + str(i), "score": 4200 - i * 137, "won": i % 4 != 3,
			"detail": {"summary": "Run summary %d" % i}})
	return out


func _frame(id: String, src: LeaderboardSource, setup := {}, asc := -1, after: Callable = Callable()) -> void:
	var s: LeaderboardScreen = load("res://scenes/leaderboard/Leaderboard.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.source = src
	for k in setup:
		s.set(k, setup[k])
	add_child(s)
	for i in 4:
		await get_tree().process_frame
	if asc >= 0:
		s.set_asc(asc)
	if after.is_valid():
		after.call(s)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)
	s.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 20
	MetaState.runs_with_battle = 20
	UI3Theme.set_scale_override(2.0 / 3.0 if get_window().size.x < 1600 else 1.0)
	var me := {"rank": 23, "name": "Me", "score": 1612, "won": true}
	var stub := LeaderboardSourceStub.new()
	stub.boards["6|season"] = {"rows": _rows(10), "me": me, "updated": "12:00"}
	stub.boards["6|today"] = {"rows": _rows(5), "me": me, "updated": "12:00"}
	stub.boards["9|season"] = {"rows": _rows(10), "me": {}, "updated": "12:00"}
	await _frame("lb--season", stub)
	await _frame("lb--detail", stub, {}, -1, func(s: LeaderboardScreen) -> void: s.open_detail(1))
	await _frame("lb--today", stub, {}, -1, func(s: LeaderboardScreen) -> void: s.set_period("today"))
	await _frame("lb--locked", stub, {}, 9)
	await _frame("lb--empty", stub, {}, 2)
	await _frame("lb--offline", stub, {}, -1, func(s: LeaderboardScreen) -> void:
		stub.fail_reason = "offline"
		s.retry())
	stub.fail_reason = ""
	await _frame("lb--error", LeaderboardSource.new())
	await _frame("lb--guest", stub, {"guest": true})
	await _frame("lb--newcomer", stub, {"newcomer": true})
	var slow := LeaderboardSourceStub.new()
	slow.pending = true
	await _frame("lb--loading", slow)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	get_tree().quit(0)
