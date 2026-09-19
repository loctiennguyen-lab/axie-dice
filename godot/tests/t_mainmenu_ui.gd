extends Node
## Regression gate for `production/qa/2026-09-19_visual-polish-backlog.md` P0-3, P0-5, P1-3,
## P1-5, P1-6 (Main Menu). Pins the four things the audit found by looking at screenshots,
## so they cannot silently regress:
##   - no dev-facing technical string reaches a player-visible Label (P0-3)
##   - every named section (SEED/MODE/ASCENSION/CHOOSE YOUR TEAM/LUNACIA PASS/UNLOCKS) is
##     wrapped in its own PanelContainer card, not bare on the flat background (P0-5)
##   - the seed field has a capped width instead of expanding without limit, and the content
##     column itself has a max-width wrapper so every section shares one alignment (P1-3)
##   - the locked FULL-mode button signals its lock state IN THE BUTTON, not only via a
##     separate caption label (P1-6)
##
## This file does not touch MetaState through any of the writer methods `t_vault.gd`'s static
## sweep watches for (`vault_import`/`buy_unlock`/`claim_bp_reward`/`save_to_disk`/etc.) — the
## two tests that need a specific pass/unlock state mutate `MetaState.xp` / `.bp_claimed` /
## `.unlocks` directly and restore them before returning, the same in-memory-only pattern
## `t_vault.gd`'s own ranked-run test already uses for `MetaState.unlocks` (no disk write
## happens, so no SaveGuard is needed — SaveGuard exists for `save_to_disk()` round trips).
##
## Run: godot --headless --path godot res://tests/t_mainmenu_ui.tscn

const _FORBIDDEN_SUBSTRINGS: Array[String] = [
	"not in this build", "TODO", "FIXME", "<NULL>", "NaN", "undefined",
]

## Every test in this file, by name — see t_vault.gd's own EXPECTED_TESTS for why this list
## exists: a GDScript runtime error aborts the running function silently, and without this
## check the gate would report PASS having skipped every assertion after the crash point.
const EXPECTED_TESTS: Array[String] = [
	"test_no_technical_strings_leak_on_default_screen",
	"test_locked_pass_reward_uses_player_facing_copy",
	"test_every_named_section_has_a_panel_container",
	"test_seed_field_width_is_capped",
	"test_content_root_has_a_max_width_wrapper",
	"test_locked_mode_button_signals_beyond_caption",
	"test_nothing_promises_waves_on_a_map_made_of_rows",
	"test_every_team_slot_shows_its_class_passive",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	print("=== t_mainmenu_ui: start ===")
	await get_tree().process_frame

	await test_no_technical_strings_leak_on_default_screen()
	await test_locked_pass_reward_uses_player_facing_copy()
	await test_every_named_section_has_a_panel_container()
	await test_seed_field_width_is_capped()
	await test_content_root_has_a_max_width_wrapper()
	await test_locked_mode_button_signals_beyond_caption()
	await test_nothing_promises_waves_on_a_map_made_of_rows()
	await test_every_team_slot_shows_its_class_passive()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	print("=== t_mainmenu_ui: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_mainmenu_ui: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_mainmenu_ui: FAIL — %s" % f)
	get_tree().quit(1)


## Called as the LAST line of every test. Reaching it is the proof the test finished.
func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _instantiate_menu() -> Node:
	var menu := (load("res://scenes/main_menu/MainMenu.tscn") as PackedScene).instantiate()
	add_child(menu)
	return menu


func _sweep_labels_for_forbidden_text(root: Node) -> Array[String]:
	var hits: Array[String] = []
	for node in root.find_children("*", "Label", true, false):
		var text := (node as Label).text
		for leak in _FORBIDDEN_SUBSTRINGS:
			if text.contains(leak):
				hits.append("Label '%s' contains forbidden substring '%s': \"%s\"" % [
					node.get_path(), leak, text])
	for node in root.find_children("*", "Button", true, false):
		var text := (node as Button).text
		for leak in _FORBIDDEN_SUBSTRINGS:
			if text.contains(leak):
				hits.append("Button '%s' contains forbidden substring '%s': \"%s\"" % [
					node.get_path(), leak, text])
	return hits


## P0-3 (default state) — the everyday screen a player sees must never carry a dev note.
func test_no_technical_strings_leak_on_default_screen() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var hits := _sweep_labels_for_forbidden_text(menu)
	_assert(hits.is_empty(), "default Main Menu leaks technical text to the player: %s"
		% ", ".join(hits))

	menu.queue_free()
	await get_tree().process_frame
	_done("test_no_technical_strings_leak_on_default_screen")


## P0-3 (the specific reward that used to say "(needs the mutation pool, not in this build)").
## Forces at least one Lunacia Pass "face" reward into the BLOCKED state so the row this bug
## lived in actually renders, instead of asserting on a section that might not appear.
func test_locked_pass_reward_uses_player_facing_copy() -> void:
	var xp_backup := MetaState.xp
	var claimed_backup: Array[int] = MetaState.bp_claimed.duplicate()

	# Lv 5's reward is `{"type": "face", ...}` (ContentDB.BP_TRACK) — never claimable in this
	# port (FACE_POOL is unported), so it is always eligible to show up in bp_blocked() once
	# its level is reached. bp_xp_for_level(1..5) sums to 445; 500 clears it with margin.
	MetaState.xp = 500
	MetaState.bp_claimed = []

	_assert(not MetaState.bp_blocked().is_empty(),
		"test setup did not produce a blocked Lunacia Pass reward — the row this regression "
		+ "lived in never rendered, so the sweep below would prove nothing")

	var menu := _instantiate_menu()
	await get_tree().process_frame

	var hits := _sweep_labels_for_forbidden_text(menu)
	_assert(hits.is_empty(),
		"a locked Lunacia Pass reward still leaks technical copy: %s" % ", ".join(hits))

	menu.queue_free()
	await get_tree().process_frame

	MetaState.xp = xp_backup
	MetaState.bp_claimed = claimed_backup
	_done("test_locked_pass_reward_uses_player_facing_copy")


## P0-5 — SEED / MODE / ASCENSION / CHOOSE YOUR TEAM / LUNACIA PASS / UNLOCKS must each sit in
## their own PanelContainer card. Counted as DIRECT children of %ContentRoot: the hero-slot
## cards inside CHOOSE YOUR TEAM are also PanelContainers, but they are nested two levels
## deeper (section panel -> row -> hero card), so counting only direct children of
## %ContentRoot distinguishes "a section card" from "a card inside a section".
func test_every_named_section_has_a_panel_container() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var content_root: VBoxContainer = menu.get_node("%ContentRoot")
	var section_panels := 0
	for child in content_root.get_children():
		if child is PanelContainer:
			section_panels += 1

	_assert(section_panels == 6,
		("%d direct-child PanelContainer section(s) under %%ContentRoot, expected 6 (SEED / "
		+ "MODE / ASCENSION / CHOOSE YOUR TEAM / LUNACIA PASS / UNLOCKS) — a section is back "
		+ "to being bare Labels/Buttons on the flat background") % section_panels)

	menu.queue_free()
	await get_tree().process_frame
	_done("test_every_named_section_has_a_panel_container")


## P1-3 — the SEED field must not be able to grow without limit.
func test_seed_field_width_is_capped() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var seed_edit: LineEdit = menu._seed_edit
	_assert(seed_edit != null, "menu has no _seed_edit to check")
	if seed_edit != null:
		_assert(seed_edit.custom_minimum_size.x > 0.0 and seed_edit.custom_minimum_size.x <= 500.0,
			"seed field custom_minimum_size.x is %.1f — expected a bounded width (~360px), not "
			% seed_edit.custom_minimum_size.x + "0 (unbounded) or an oversized value")
		_assert((seed_edit.size_flags_horizontal & Control.SIZE_EXPAND) == 0,
			("seed field size_flags_horizontal is %d, which still includes SIZE_EXPAND — it "
			+ "will keep stretching to fill the row with no ceiling, same as the original bug")
			% seed_edit.size_flags_horizontal)

	menu.queue_free()
	await get_tree().process_frame
	_done("test_seed_field_width_is_capped")


## P1-3 — every section shares one alignment column instead of each row picking its own
## expansion rule. Checked structurally: %ContentRoot must carry a bounded minimum width and
## sit inside a CenterContainer (MainMenu.tscn: Scroll -> ContentCenter -> ContentRoot).
func test_content_root_has_a_max_width_wrapper() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var content_root: VBoxContainer = menu.get_node("%ContentRoot")
	_assert(content_root.custom_minimum_size.x >= 900.0
			and content_root.custom_minimum_size.x <= 1200.0,
		"%%ContentRoot custom_minimum_size.x is %.1f, expected ~1000-1100px per the backlog fix"
		% content_root.custom_minimum_size.x)
	_assert(content_root.get_parent() is CenterContainer,
		"%%ContentRoot's parent is a %s, not a CenterContainer — the max-width column is no "
		% content_root.get_parent().get_class() + "longer centered/bounded inside Scroll")

	menu.queue_free()
	await get_tree().process_frame
	_done("test_content_root_has_a_max_width_wrapper")


## P1-6 — a locked FULL-mode button must carry a signal OUTSIDE the small caption label below
## it: either its own button text differs from the plain unlocked caption (a lock glyph/marker
## baked into `.text`), or it has a child icon node. Checking the caption Label's mere
## existence would not have caught the original bug (the caption already existed; the button
## itself carried nothing extra).
func test_locked_mode_button_signals_beyond_caption() -> void:
	var had_u_full := MetaState.unlocks.has("u_full")
	if had_u_full:
		MetaState.unlocks.erase("u_full")

	var menu := _instantiate_menu()
	await get_tree().process_frame

	var full_btn: Button = menu._mode_full_btn
	_assert(full_btn != null, "menu has no _mode_full_btn to check")
	if full_btn != null:
		_assert(full_btn.disabled, "test setup did not lock FULL mode — u_full still unlocked")
		var has_icon_child := full_btn.get_child_count() > 0
		var caption_text_only := full_btn.text.strip_edges() == "FULL — %d rows" % MainMenu._rows_for("full")
		_assert(has_icon_child or not caption_text_only,
			"locked FULL button text is exactly '%s' with no child icon — the only lock signal "
			% full_btn.text + "is the separate caption Label below it, same as the original bug")

	menu.queue_free()
	await get_tree().process_frame

	if had_u_full:
		MetaState.unlocks.append("u_full")
	_done("test_locked_mode_button_signals_beyond_caption")


## "12 waves" / "20 waves" has now been found wrong in FOUR player-facing places: the Codex,
## the end screen, these mode buttons and the Unlocks list. It is a word from the JS build's
## LINEAR run, and the counts were wrong on top of that — the real map branches and is 18 or
## 30 rows. Four independent fixes do not stop a fifth copy appearing; a gate does.
func test_nothing_promises_waves_on_a_map_made_of_rows() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var offenders: Array[String] = []
	for node in _descendants(menu):
		var texts: Array[String] = []
		var lbl := node as Label
		if lbl != null:
			texts.append(lbl.text)
		var btn := node as Button
		if btn != null:
			texts.append(btn.text)
		for t in texts:
			if t.to_lower().contains("wave"):
				offenders.append(t)
	_assert(offenders.is_empty(),
		"the menu still describes this map in waves: %s" % str(offenders))

	# And the counts it DOES show must be the generator's, not a second copy of them.
	var short_rows := MainMenu._rows_for("short")
	_assert(short_rows == 18,
		"RunMapGenerator says Short is %d rows; this gate was written against 18, so one of "
		% short_rows + "the two is out of date — check which before changing the number here")
	_assert((menu._mode_short_btn as Button).text.contains(str(short_rows)),
		"the SHORT button reads '%s' and the generator says %d rows"
		% [(menu._mode_short_btn as Button).text, short_rows])

	# The Unlocks list is content, not layout, so it is checked at the source.
	for unlock in ContentDB.UNLOCKS:
		var u: Dictionary = unlock
		for field in ["n", "d"]:
			_assert(not String(u.get(field, "")).to_lower().contains("wave"),
				"unlock '%s' still says waves: %s" % [String(u.get("id", "?")), u.get(field, "")])

	menu.queue_free()
	await get_tree().process_frame
	_done("test_nothing_promises_waves_on_a_map_made_of_rows")


## Picking a team is picking five always-on rules. This screen showed the six faces and hid
## the rule, so the most build-defining thing about a class was learnable only by playing a run
## with it. The text must come from ContentDB.CLASS_PASSIVE — a passive retyped into the menu
## is a menu that can promise something the engine does not do.
func test_every_team_slot_shows_its_class_passive() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var all_text := ""
	for node in _descendants(menu):
		var lbl := node as Label
		if lbl != null:
			all_text += lbl.text + "\n"

	var seen := 0
	for hero_key in menu._team_selection:
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
		# The DESCRIPTION, not just the name: a name alone tells a new player nothing.
		_assert(all_text.contains(String(passive.get("d", "")).substr(0, 24)),
			"the team slot for '%s' names %s but does not say what it does"
			% [hero_key, passive.get("n", "")])
	_assert(seen == 5, "checked %d team slots, expected 5" % seen)

	menu.queue_free()
	await get_tree().process_frame
	_done("test_every_team_slot_shows_its_class_passive")


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out
