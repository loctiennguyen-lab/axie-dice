extends Node
## Regression gate for `production/qa/2026-09-19_visual-polish-backlog.md` P0-3, P0-5, P1-3,
## P1-5, P1-6 (Main Menu), UPDATED 2026-09-20 for the v2 UI redesign
## (docs/design-handoff-v2, "Godot Meta Screens v2.dc.html" MENU/TEAM tabs). MainMenu.gd's
## `_build_ui()` changed from a scrolling VBox of six stacked sections to a fixed, non-scrolling
## title screen, and the 5-slot team picker (hero dropdown + class passive + six faces) moved
## off this screen entirely onto its own `TeamSelect.tscn`. Every test below either still checks
## the SAME rule it always did against the new structure, or — where noted per-test — has been
## replaced by a stronger/more literal check of the same underlying rule. None were deleted or
## skipped; see MainMenu.gd's own header comment for the full v2 rationale.
##
## This file does not touch MetaState through any of the writer methods `t_vault.gd`'s static
## sweep watches for (`vault_import`/`buy_unlock`/`claim_bp_reward`/`save_to_disk`/etc.) — the
## tests that need a specific state mutate MetaState fields directly and restore them before
## returning, matching `t_vault.gd`'s own in-memory-only pattern (no disk write happens, so no
## SaveGuard is needed).
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
	"test_disabled_nav_tiles_use_player_facing_tooltips",
	"test_nothing_on_this_screen_scrolls",
	"test_seed_field_is_bounded_by_its_panel_not_by_its_own_expansion",
	"test_run_setup_panel_and_nav_tiles_and_team_row_all_exist",
	"test_locked_mode_button_signals_beyond_the_lock_glyph",
	"test_nothing_promises_waves_on_a_map_made_of_rows",
	"test_team_select_shows_every_slots_class_passive",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
var _tutorial_seen_was := false


func _ready() -> void:
	print("=== t_mainmenu_ui: start ===")
	# MainMenu._ready() is the onboarding choke point: on a save that has never seen the tutorial
	# it calls `change_scene_to_file()` and returns, which frees THIS node — every `get_tree()`
	# after that is null and all eight tests abort with "Parameter data.tree is null".
	#
	# That is not a menu bug and not a tutorial bug. It is this file assuming the machine it runs
	# on already has a played save, which is true on the author's Mac and false on a fresh
	# checkout, in a container and in CI — so the gate reported eight failures that had nothing
	# to do with what it tests. The flag is set in memory only and put back below, which is the
	# same no-disk-write pattern the header describes.
	_tutorial_seen_was = MetaState.tutorial_seen
	MetaState.tutorial_seen = true
	await get_tree().process_frame

	await test_no_technical_strings_leak_on_default_screen()
	await test_disabled_nav_tiles_use_player_facing_tooltips()
	await test_nothing_on_this_screen_scrolls()
	await test_seed_field_is_bounded_by_its_panel_not_by_its_own_expansion()
	await test_run_setup_panel_and_nav_tiles_and_team_row_all_exist()
	await test_locked_mode_button_signals_beyond_the_lock_glyph()
	await test_nothing_promises_waves_on_a_map_made_of_rows()
	await test_team_select_shows_every_slots_class_passive()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	MetaState.tutorial_seen = _tutorial_seen_was
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


func _instantiate_team_select() -> Node:
	var screen := (load("res://scenes/main_menu/TeamSelect.tscn") as PackedScene).instantiate()
	add_child(screen)
	return screen


func _sweep_labels_for_forbidden_text(root: Node) -> Array[String]:
	var hits: Array[String] = []
	for node in root.find_children("*", "Label", true, false):
		var text := (node as Label).text
		for leak in _FORBIDDEN_SUBSTRINGS:
			if text.contains(leak):
				hits.append("Label '%s' contains forbidden substring '%s': \"%s\"" % [
					node.get_path(), leak, text])
	for node in root.find_children("*", "Button", true, false):
		var btn := node as Button
		for leak in _FORBIDDEN_SUBSTRINGS:
			if btn.text.contains(leak):
				hits.append("Button '%s' contains forbidden substring '%s': \"%s\"" % [
					node.get_path(), leak, btn.text])
			if btn.tooltip_text.contains(leak):
				hits.append("Button '%s' tooltip contains forbidden substring '%s': \"%s\"" % [
					node.get_path(), leak, btn.tooltip_text])
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


## UPDATED 2026-09-20, replaces `test_locked_pass_reward_uses_player_facing_copy`. v1 forced a
## blocked Lunacia Pass reward into `MetaState.bp_blocked()` and swept the menu for the leaked
## dev-note copy that reward used to render inline (the P0-3 bug this file exists to pin). v2
## deletes the inline Pass/Unlocks lists entirely — see MainMenu.gd's GAP FLAGGED note — so that
## specific render path no longer exists on this screen at all, and the old test's setup would
## now be exercising dead code. The rule it protected ("no dev-facing string reaches the
## player") still applies to whatever nav tile IS intentionally disabled today.
##
## UPDATED AGAIN 2026-09-20 (same day, ui-programmer pass building Pass/Unlocks/Vault/Guides):
## `pass` and `unlocks` moved from `disabled_ids` to `enabled_ids`. Both now have real screens
## (`scenes/pass/Pass.tscn`, `scenes/unlocks/Unlocks.tscn`) and route to them — see MainMenu.gd's
## `_build_nav_tiles()`, "GAP FLAGGED, RESOLVED 2026-09-20". This asserts the fix directly: the
## same tiles that used to be pinned disabled with a tooltip must now be enabled and routed,
## which is the whole reason those two screens exist.
##
## UPDATED 2026-09-20 (FIX-PASS-01 M2 — "Remove any tile with no value: an empty tile is worse
## than a missing one"): `collection` used to be this test's one still-expected-disabled tile.
## It is not disabled-with-a-tooltip anymore, it is GONE — MainMenu.gd no longer builds it at
## all, since there is still no Collection system anywhere in the project for it to point at.
## `disabled_ids` is empty today on purpose (kept as a list, not deleted, so a future
## intentionally-disabled tile has an obvious place to land).
func test_disabled_nav_tiles_use_player_facing_tooltips() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var disabled_ids: Array[String] = []
	for id in disabled_ids:
		var tile: Button = menu._nav_tiles.get(id)
		_assert(tile != null, "no nav tile registered for '%s'" % id)
		if tile == null:
			continue
		_assert(tile.disabled, "nav tile '%s' should be disabled (no screen exists for it yet)"
			% id)
		_assert(not tile.tooltip_text.is_empty(),
			"disabled nav tile '%s' has no tooltip explaining why" % id)

	_assert(not menu._nav_tiles.has("collection"),
		"FIX-PASS-01 M2: 'collection' should be REMOVED, not merely disabled — an empty tile "
		+ "is worse than a missing one")

	var enabled_ids := ["pass", "unlocks", "vault", "guides", "codex"]
	for id in enabled_ids:
		var tile: Button = menu._nav_tiles.get(id)
		_assert(tile != null, "no nav tile registered for '%s'" % id)
		if tile != null:
			_assert(not tile.disabled, "nav tile '%s' has a real destination and should be "
				% id + "enabled")

	var hits := _sweep_labels_for_forbidden_text(menu)
	_assert(hits.is_empty(), "a disabled nav tile's tooltip leaks technical copy: %s"
		% ", ".join(hits))

	menu.queue_free()
	await get_tree().process_frame
	_done("test_disabled_nav_tiles_use_player_facing_tooltips")


## UPDATED 2026-09-20, replaces `test_every_named_section_has_a_panel_container` AND
## `test_content_root_has_a_max_width_wrapper`. Both v1 tests existed to catch symptoms of the
## same root problem: a screen that scrolls, with content that sprawls because nothing bounds
## it. v2's own rule is "nothing scrolls" (spec-data.js "Main Menu is a scrolling form" +
## MainMenu.gd's header) — checking for the literal absence of a ScrollContainer anywhere in the
## tree is a strictly stronger and more direct test of that same intent than counting
## PanelContainers or checking one wrapper's width, so it replaces both.
func test_nothing_on_this_screen_scrolls() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var scrollers := menu.find_children("*", "ScrollContainer", true, false)
	_assert(scrollers.is_empty(),
		"Main Menu still contains %d ScrollContainer(s) — v2 is a title screen where nothing "
		% scrollers.size() + "scrolls")

	menu.queue_free()
	await get_tree().process_frame
	_done("test_nothing_on_this_screen_scrolls")


## UPDATED 2026-09-20, replaces `test_seed_field_width_is_capped`. v1's seed field carried a
## hardcoded `custom_minimum_size.x` cap and explicitly excluded `SIZE_EXPAND` because it sat
## alone in an unbounded-width VBox column. v2's seed field DOES carry `SIZE_EXPAND_FILL` on
## purpose — the mockup's own redline is `flex:1 1 auto` next to a fixed-width RANDOM button —
## but the row it lives in is inside RUN SETUP, a panel with a fixed `custom_minimum_size.x`
## (566, per the box measurement in MainMenu.gd). The field can only ever render as wide as
## "panel width minus the fixed RANDOM button minus padding/gaps", which is the same rule
## ("bounded, not unbounded") enforced through a different, v2-correct mechanism. This checks
## the mechanism that now provides the bound, since checking `_seed_edit`'s own size flags would
## fail on a legitimate v2 layout.
func test_seed_field_is_bounded_by_its_panel_not_by_its_own_expansion() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	var seed_edit: LineEdit = menu._seed_edit
	_assert(seed_edit != null, "menu has no _seed_edit to check")
	if seed_edit != null:
		# ROUTING TASK (FIX-PASS-02 §1 item 4): RunSetupPanel is now a child of the shell's
		# `Content` (DangoScreen.build()), not a direct child of the menu root — read through
		# MainMenu's own stored reference rather than a name-based node lookup, which would
		# silently break the next time this node is renamed or re-parented again.
		var panel: Node = menu._run_setup_panel
		_assert(panel != null, "no RunSetupPanel to bound the seed field's width")
		if panel != null:
			var min_w: float = (panel as Control).custom_minimum_size.x
			_assert(min_w > 0.0 and min_w <= 700.0,
				"RunSetupPanel custom_minimum_size.x is %.1f — expected a bounded width "
				% min_w + "(~566px), not 0 (unbounded) or an oversized value")

	menu.queue_free()
	await get_tree().process_frame
	_done("test_seed_field_is_bounded_by_its_panel_not_by_its_own_expansion")


## New structural sanity check for the v2 layout's three major regions.
func test_run_setup_panel_and_nav_tiles_and_team_row_all_exist() -> void:
	var menu := _instantiate_menu()
	await get_tree().process_frame

	# ROUTING TASK (FIX-PASS-02 §1 item 4): both now live under the shell's `Content`, not
	# directly under the menu root — see the identical note above.
	_assert(menu._run_setup_panel != null, "no RunSetupPanel")
	var nav_tiles: Node = menu._nav_tiles_grid
	_assert(nav_tiles != null, "no NavTiles grid")
	if nav_tiles != null:
		# UPDATED 2026-09-20 (FIX-PASS-01 M2): 6 -> 5. COLLECTION was removed outright (see
		# test_disabled_nav_tiles_use_player_facing_tooltips's own note on this same date) —
		# "an empty tile is worse than a missing one" — so the grid legitimately has 5 tiles now,
		# not a bug leaving one unbuilt.
		_assert(nav_tiles.get_child_count() == 5,
			"NavTiles has %d tile(s), expected 5 (Pass/Unlocks/Vault/Sample Teams/Codex — "
			% nav_tiles.get_child_count() + "Collection removed, FIX-PASS-01 M2)")
	var team_row: Node = menu._team_row
	_assert(team_row != null, "no team row built")
	if team_row != null:
		_assert(team_row.get_child_count() == MainMenu.TEAM_SIZE,
			"team row has %d card(s), expected %d" % [
				team_row.get_child_count(), MainMenu.TEAM_SIZE])

	menu.queue_free()
	await get_tree().process_frame
	_done("test_run_setup_panel_and_nav_tiles_and_team_row_all_exist")


## UPDATED 2026-09-20, replaces `test_locked_mode_button_signals_beyond_caption`. v1's FULL-mode
## button had a separate dim caption Label below it, and the bug was that button carried no
## signal of its own beyond that caption. v2's mode buttons are two-line cards
## ("FULL\nN rows · N bosses") with no separate caption Label at all — the lock glyph baked into
## the button's own `.text` is now the ONLY lock signal, which trivially satisfies the original
## rule (a locked button must signal beyond a caption that, in v2, does not exist to hide behind
## in the first place) but is still checked explicitly so a future pass cannot silently drop the
## glyph and leave a plain, indistinguishable button.
func test_locked_mode_button_signals_beyond_the_lock_glyph() -> void:
	var had_u_full := MetaState.unlocks.has("u_full")
	if had_u_full:
		MetaState.unlocks.erase("u_full")

	var menu := _instantiate_menu()
	await get_tree().process_frame

	var full_btn: Button = menu._mode_full_btn
	_assert(full_btn != null, "menu has no _mode_full_btn to check")
	if full_btn != null:
		_assert(full_btn.disabled, "test setup did not lock FULL mode — u_full still unlocked")
		_assert(full_btn.text.contains("🔒"),
			"locked FULL button text '%s' carries no lock glyph" % full_btn.text)

	menu.queue_free()
	await get_tree().process_frame

	if had_u_full:
		MetaState.unlocks.append("u_full")
	_done("test_locked_mode_button_signals_beyond_the_lock_glyph")


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
			texts.append(btn.tooltip_text)
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
	# Read the whole TILE, not just `Button.text`. MNU-05 splits the run-length card into a
	# Baloo 19 name and a Work Sans 12 detail line under it, and the row count lives in the
	# detail line — so asserting on `Button.text` alone measured a label the count was never in
	# again and reported a copy bug that did not exist. What matters to the rule is that the
	# number a player reads on that card is the generator's.
	var short_btn := menu._mode_short_btn as Button
	var short_sub := short_btn.get_node_or_null("Subtitle") as Label
	var short_tile_text: String = short_btn.text + " " + (short_sub.text if short_sub != null else "")
	_assert(short_tile_text.contains(str(short_rows)),
		"the SHORT card reads '%s' and the generator says %d rows"
		% [short_tile_text.strip_edges(), short_rows])

	# The Unlocks list is content, not layout, so it is checked at the source (still true even
	# though v2 no longer renders this list on Main Menu itself — see the GAP FLAGGED note).
	for unlock in ContentDB.UNLOCKS:
		var u: Dictionary = unlock
		for field in ["n", "d"]:
			_assert(not String(u.get(field, "")).to_lower().contains("wave"),
				"unlock '%s' still says waves: %s" % [String(u.get("id", "?")), u.get(field, "")])

	menu.queue_free()
	await get_tree().process_frame
	_done("test_nothing_promises_waves_on_a_map_made_of_rows")


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
