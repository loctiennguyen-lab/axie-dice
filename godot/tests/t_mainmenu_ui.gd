extends Node
## MainMenu.tscn is a pure router now (Liam dropped the Main Menu, 16/10): this gate checks the
## redirect (tutorial / Land) and that the scene draws nothing. The old menu-UI tests and the
## TeamSelect class-passive check were retired with those screens (RunSetup's picker shows no passive).
##
## Run: godot --headless --path godot res://tests/t_mainmenu_ui.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_routes_to_tutorial_until_seen",
	"test_routes_to_land_once_tutorial_seen",
	"test_main_menu_scene_draws_nothing",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
var _tutorial_seen_was := false
var _runs_was := 0
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_mainmenu_ui: start ===")
	_save_guard.capture()
	_tutorial_seen_was = MetaState.tutorial_seen
	_runs_was = MetaState.runs
	await get_tree().process_frame

	test_routes_to_tutorial_until_seen()
	test_routes_to_land_once_tutorial_seen()
	test_main_menu_scene_draws_nothing()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append("test '%s' did not run to completion" % name)

	MetaState.tutorial_seen = _tutorial_seen_was
	MetaState.runs = _runs_was
	_save_guard.restore()
	print("=== t_mainmenu_ui: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_mainmenu_ui: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_mainmenu_ui: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_routes_to_tutorial_until_seen() -> void:
	MetaState.tutorial_seen = false
	MetaState.runs = 0   # needs_tutorial() = not seen AND no runs yet
	_assert(MainMenu.route_target() == MainMenu.TUTORIAL_SCENE,
		"unseen tutorial must route to the tutorial, got " + MainMenu.route_target())
	_done("test_routes_to_tutorial_until_seen")


func test_routes_to_land_once_tutorial_seen() -> void:
	MetaState.tutorial_seen = true
	_assert(MainMenu.route_target() == LandNav.land_scene(),
		"seen tutorial must route to Land, got " + MainMenu.route_target())
	_assert(ResourceLoader.exists(MainMenu.route_target()), "route target does not exist")
	_done("test_routes_to_land_once_tutorial_seen")


func test_main_menu_scene_draws_nothing() -> void:
	var menu := (load("res://scenes/main_menu/MainMenu.tscn") as PackedScene).instantiate()
	_assert(menu.get_child_count() == 0, "MainMenu must build no UI, has %d children" % menu.get_child_count())
	menu.free()
	_done("test_main_menu_scene_draws_nothing")


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out
