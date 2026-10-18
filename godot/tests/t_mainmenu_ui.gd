extends Node
## MainMenu.tscn is a pure router now (Liam dropped the Main Menu, 16/10): this gate checks the
## redirect (tutorial / Land), that the scene draws nothing, and the TeamSelect class-passive
## rule that used to live here. The old menu-UI tests were retired with the menu itself.
##
## Run: godot --headless --path godot res://tests/t_mainmenu_ui.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_routes_to_tutorial_until_seen",
	"test_routes_to_land_once_tutorial_seen",
	"test_main_menu_scene_draws_nothing",
	"test_team_select_shows_every_slots_class_passive",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
var _tutorial_seen_was := false
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_mainmenu_ui: start ===")
	_save_guard.capture()
	_tutorial_seen_was = MetaState.tutorial_seen
	await get_tree().process_frame

	test_routes_to_tutorial_until_seen()
	test_routes_to_land_once_tutorial_seen()
	test_main_menu_scene_draws_nothing()
	await test_team_select_shows_every_slots_class_passive()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append("test '%s' did not run to completion" % name)

	MetaState.tutorial_seen = _tutorial_seen_was
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


func _instantiate_team_select() -> Node:
	var screen := (load("res://scenes/main_menu/TeamSelect.tscn") as PackedScene).instantiate()
	add_child(screen)
	return screen


## UPDATED 2026-09-20, replaces `test_every_team_slot_shows_its_class_passive`. The 5-slot
## picker this test used to check on MainMenu.tscn now lives entirely on TeamSelect.tscn (see
## that file's header for why) — MainMenu's own team row is read-only and shows no passive text
## at all, so re-running the old assertion against MainMenu would either false-fail or, worse,
## silently pass on an empty sweep. The rule is unchanged (picking a team is picking five
## always-on rules, so the passive must be on screen, straight from ContentDB.CLASS_PASSIVE,
## never retyped) — only the screen under test moved.
func test_team_select_shows_every_slots_class_passive() -> void:
	MainMenu.pending_team = MainMenu.DEFAULT_TEAM.duplicate()
	var screen := _instantiate_team_select()
	await get_tree().process_frame

	var all_text := ""
	for node in _descendants(screen):
		var lbl := node as Label
		if lbl != null:
			all_text += lbl.text + "\n"

	var seen := 0
	for hero_key in MainMenu.DEFAULT_TEAM:
		var hero_def: Dictionary = ContentDB.heroes.get(String(hero_key), {})
		var passive: Dictionary = ContentDB.CLASS_PASSIVE.get(String(hero_def.get("cls", "")), {})
		_assert(not passive.is_empty(),
			"hero '%s' has a class with no passive defined" % hero_key)
		if passive.is_empty():
			continue
		seen += 1
		_assert(all_text.contains(String(passive.get("n", ""))),
			"the team slot for '%s' does not name its passive (%s)"
			% [hero_key, passive.get("n", "")])
		_assert(all_text.contains(String(passive.get("d", "")).substr(0, 24)),
			"the team slot for '%s' names %s but does not say what it does"
			% [hero_key, passive.get("n", "")])
	_assert(seen == 5, "checked %d team slots, expected 5" % seen)

	screen.queue_free()
	await get_tree().process_frame
	MainMenu.pending_team = []
	_done("test_team_select_shows_every_slots_class_passive")


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out
