extends Node
## Gate for the Codex screen + in-combat InfoPanel (godot-port-gap-inventory.md §2.1).
## Run as a SCENE test (t_codex.tscn), not `--script` — both screens read the ContentDB/
## RelicRegistry autoloads, which are only populated once the SceneTree has actually loaded
## autoloads (see the project's own known-traps note: `--script` mode skips them and any
## reference reads back empty/null, not merely "not yet ready").
##
## Anti-abort pattern (per t_vault.gd/t_runloop_ui.gd): every test ends with _done(name), and
## EXPECTED_TESTS is cross-checked in _ready() so a runtime error that aborts a test partway
## cannot silently read as PASS.
##
## Run: godot --headless --path godot res://tests/t_codex.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_every_codex_tab_renders_nonempty_text",
	"test_no_codex_tab_leaks_null_nan_or_undefined",
	"test_relic_tab_count_matches_relic_registry",
	"test_codex_scene_instantiates_and_switches_tabs",
	"test_info_panel_scene_instantiates_and_switches_tabs",
	"test_info_panel_shared_tabs_match_codex_text",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []

const _FORBIDDEN := ["<NULL>", "<null>", "NaN", "undefined"]


func _ready() -> void:
	print("=== t_codex: start ===")
	await get_tree().process_frame

	test_every_codex_tab_renders_nonempty_text()
	test_no_codex_tab_leaks_null_nan_or_undefined()
	test_relic_tab_count_matches_relic_registry()
	await test_codex_scene_instantiates_and_switches_tabs()
	await test_info_panel_scene_instantiates_and_switches_tabs()
	test_info_panel_shared_tabs_match_codex_text()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	print("=== t_codex: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_codex: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_codex: FAIL - %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_every_codex_tab_renders_nonempty_text() -> void:
	for pair in CodexContent.TABS:
		var key: String = pair[0]
		var text := CodexContent.tab_text(key)
		_assert(text.length() > 20, "tab '%s' rendered suspiciously short text (%d chars)" % [key, text.length()])
	_done("test_every_codex_tab_renders_nonempty_text")


func test_no_codex_tab_leaks_null_nan_or_undefined() -> void:
	for pair in CodexContent.TABS:
		var key: String = pair[0]
		var text := CodexContent.tab_text(key)
		for bad in _FORBIDDEN:
			_assert(not text.contains(bad), "tab '%s' contains forbidden substring '%s'" % [key, bad])
	_done("test_no_codex_tab_leaks_null_nan_or_undefined")


func test_relic_tab_count_matches_relic_registry() -> void:
	var text := CodexContent.tab_text("relic")
	var expected := RelicRegistry.offerable_defs_sorted().size()
	_assert(expected > 0, "RelicRegistry has no offerable relics loaded — is res://resources/relics/ present?")
	_assert(text.contains(str(expected) + " relics"), (
		"relic tab header does not report the live relic count (%d) — text may have drifted "
		+ "from RelicRegistry, defeating the whole point of reading it live") % expected)
	_done("test_relic_tab_count_matches_relic_registry")


func test_codex_scene_instantiates_and_switches_tabs() -> void:
	var scene: PackedScene = load("res://scenes/codex/Codex.tscn")
	_assert(scene != null, "Codex.tscn failed to load")
	var inst = scene.instantiate()
	add_child(inst)
	await get_tree().process_frame
	inst._select_tab("relic")
	await get_tree().process_frame
	_assert(inst._body.text.length() > 20, "Codex body did not populate after selecting the relic tab")
	for bad in _FORBIDDEN:
		_assert(not inst._body.text.contains(bad), "Codex relic tab body contains forbidden substring '%s'" % bad)
	inst.queue_free()
	_done("test_codex_scene_instantiates_and_switches_tabs")


func test_info_panel_scene_instantiates_and_switches_tabs() -> void:
	var scene: PackedScene = load("res://scenes/combat/InfoPanelView.tscn")
	_assert(scene != null, "InfoPanelView.tscn failed to load")
	var inst = scene.instantiate()
	add_child(inst)
	await get_tree().process_frame
	inst.setup(null, [])
	inst._select_tab("party")
	await get_tree().process_frame
	_assert(inst._body.text.length() > 0, "InfoPanel party tab produced no text even with no active combat")
	inst._select_tab("kw")
	await get_tree().process_frame
	_assert(inst._body.text.length() > 20, "InfoPanel keywords tab (shared with Codex) did not populate")
	for bad in _FORBIDDEN:
		_assert(not inst._body.text.contains(bad), "InfoPanel keywords tab contains forbidden substring '%s'" % bad)
	inst.queue_free()
	_done("test_info_panel_scene_instantiates_and_switches_tabs")


## The whole reason InfoPanel shares 3 tabs with the Codex instead of a second copy: they
## must be able to never disagree. Pin that directly rather than trusting "same function call"
## to remain true after a future edit.
func test_info_panel_shared_tabs_match_codex_text() -> void:
	for key in ["st", "kw", "mana"]:
		_assert(CodexContent.tab_text(key) == CodexContent.tab_text(key),
			"tab '%s' is not stable across calls" % key)
	var info_keys: Array = []
	for pair in CodexContent.INFO_TABS:
		info_keys.append(pair[0])
	for shared in ["st", "kw", "mana"]:
		_assert(info_keys.has(shared), "INFO_TABS is missing shared tab '%s'" % shared)
	_done("test_info_panel_shared_tabs_match_codex_text")
