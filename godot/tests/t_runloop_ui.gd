extends Node
## Gate for the 2026-09-19 run-loop UI/UX fixes to RunMapController.gd/reward_generator.gd
## (production/qa/2026-09-19_visual-polish-backlog.md P0-1/P0-2, and
## production/qa/2026-09-19_runloop-ux-backlog.md P0-1/P0-2/P0-3). Pins exactly the things a
## screenshot alone does not reliably catch:
##   - the RunMap camera fit covers EVERY rendered node, not just current+reachable
##   - no node label leaks a technical graph id ("r1_c0") to the player
##   - a shop's "already bought" button and its "can't afford" button use DIFFERENT styleboxes
##   - every reward/shop card shows a rarity chip whose colour matches its `rar` field
##   - a "LEVEL UP" description never reads as "X -> X" with an identical hero name on both
##     sides (reward_generator.gd's tier-up phrasing fix)
##
## Anti-abort pattern (per t_vault.gd): every test function ends by calling _done(name), and
## EXPECTED_TESTS is cross-checked in _ready() so a runtime error that aborts a test partway
## cannot silently read as PASS.
##
## No test here touches MetaState (the player's real profile save) — RunMapController's
## save-on-progress calls (`_save_map_progress()`) only ever write RunState.SAVE_PATH
## ("user://run_save.json", the resumable-run slot), which the project's own t_run_save.gd
## already treats as fair game for a test to overwrite (no SaveGuard used there either) — see
## that file's test_a_wrong_version_save_is_refused_not_half_loaded(). SaveGuard is reserved
## for MetaState.SAVE_PATH specifically (save_guard.gd's own header), so it is not needed here.
##
## Run: godot --headless --path godot res://tests/t_runloop_ui.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_camera_fit_covers_every_rendered_node_not_just_reachable",
	"test_node_label_never_contains_a_technical_graph_id",
	"test_shop_bought_and_unaffordable_buttons_use_different_styleboxes",
	"test_reward_and_shop_cards_show_a_rarity_chip_matching_rar",
	"test_level_up_description_never_reads_as_x_arrow_x",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []

const _ID_PATTERN := "r\\d+_c\\d+"


func _ready() -> void:
	print("=== t_runloop_ui: start ===")
	await get_tree().process_frame

	await test_camera_fit_covers_every_rendered_node_not_just_reachable()
	await test_node_label_never_contains_a_technical_graph_id()
	await test_shop_bought_and_unaffordable_buttons_use_different_styleboxes()
	await test_reward_and_shop_cards_show_a_rarity_chip_matching_rar()
	test_level_up_description_never_reads_as_x_arrow_x()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	print("=== t_runloop_ui: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_runloop_ui: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_runloop_ui: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------------------
# Shared fixture — same construction style as t_run_map_fog.gd (hand-authored graph, real
# RunMap.tscn instance, white-box .call()/.get()/.set()).
# ---------------------------------------------------------------------------------------

## A multi-row graph shaped specifically to exercise the camera-fit bug: a start row (r1),
## the currently-reachable row (r2, 2 nodes), AND several rows further out (r3..r6) that are
## only ever "fog"/"dim" tier — exactly the rows the old current+reachable-only fit box
## excluded. r6 also carries a non-zero column so the fix's width coverage is exercised too,
## not only its height coverage.
func _build_synthetic_graph() -> RunMapGraph:
	var rows_data: Array = [
		[_node_data("r1_c0", 1, 0, "battle", ["r2_c0", "r2_c1"])],
		[
			_node_data("r2_c0", 2, 0, "event", ["r3_c0"]),
			_node_data("r2_c1", 2, 1, "shop", ["r3_c0"]),
		],
		[_node_data("r3_c0", 3, 0, "battle", ["r4_c0"])],
		[_node_data("r4_c0", 4, 0, "treasure", ["r5_c0"])],
		[_node_data("r5_c0", 5, 0, "battle", ["r6_c1"])],
		[
			_node_data("r6_c0", 6, 0, "elite", []),
			_node_data("r6_c1", 6, 1, "boss", []),
		],
	]
	return RunMapGraph.from_data({
		"rows": rows_data, "boss_rows": [6], "elite_rows": [6], "start_node_id": "r1_c0",
	})


func _node_data(id: String, row: int, col: int, node_type: String, next_ids: Array) -> Dictionary:
	return {
		"id": id, "row": row, "col": col, "node_type": node_type,
		"next_ids": next_ids, "visited": false, "locked": false,
	}


## Instantiates a real RunMap.tscn against a fresh RunState + the synthetic graph above,
## current_node_id = "r1_c0" (so r2's row is "reachable now" and r3+ are the fog/dim rows the
## camera-fit bug used to clip). Caller must queue_free() the returned node when done.
func _new_runmap() -> Node:
	RunState.reset()
	RunState.map_graph = _build_synthetic_graph().to_data()
	RunState.current_node_id = "r1_c0"
	RunState.visited_node_ids = ["r1_c0"]
	RunState.pending_rewards = []
	var runmap: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(runmap)
	return runmap


# ---------------------------------------------------------------------------------------

## visual-polish-backlog P0-1. Builds the fixture above (6 rows, up to 2 columns), lets
## RunMapController run its normal _ready()/_refresh(false) pass, then reads back the
## camera's own position/zoom and checks EVERY node's world position — including the
## far/fogged rows the bug used to exclude — falls inside the framed viewport rect.
func test_camera_fit_covers_every_rendered_node_not_just_reachable() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	var camera: Camera2D = runmap.get_node("%MapCamera")
	var vp_size: Vector2 = runmap.get_viewport().get_visible_rect().size
	var half_visible: Vector2 = vp_size * 0.5 * camera.zoom
	var cam_min: Vector2 = camera.position - half_visible
	var cam_max: Vector2 = camera.position + half_visible

	var node_visuals: Dictionary = runmap.get("_node_visuals")
	_assert(node_visuals.size() == 8, "fixture expected 8 rendered nodes, found %d" % node_visuals.size())

	var all_covered := true
	var first_miss := ""
	for id in node_visuals.keys():
		var entry: Dictionary = node_visuals[id]
		var n: RunMapNode = entry["node"]
		var world_pos: Vector2 = runmap.call("_node_world_pos", n)
		var inside := world_pos.x >= cam_min.x and world_pos.x <= cam_max.x \
			and world_pos.y >= cam_min.y and world_pos.y <= cam_max.y
		if not inside:
			all_covered = false
			if first_miss == "":
				first_miss = "%s at %s (camera frame %s..%s)" % [id, world_pos, cam_min, cam_max]
	_assert(all_covered, "camera fit does not cover every rendered node — first miss: %s" % first_miss)

	# Regression guard for the literal reported symptom: the row furthest from current/reachable
	# (r6, the boss/elite row) must be inside the frame, not just the reachable r2 row.
	var far_entry: Dictionary = node_visuals.get("r6_c1", {})
	if not far_entry.is_empty():
		var far_pos: Vector2 = runmap.call("_node_world_pos", far_entry["node"])
		_assert(far_pos.y >= cam_min.y, "far row r6 is still clipped above the camera's top edge")

	runmap.queue_free()
	_done("test_camera_fit_covers_every_rendered_node_not_just_reachable")


## visual-polish-backlog P0-2. Every node button's visible text, across every tier
## (current/reachable/dim/fog), must never contain a technical "r<row>_c<col>" id.
func test_node_label_never_contains_a_technical_graph_id() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	var re := RegEx.new()
	re.compile(_ID_PATTERN)

	var node_visuals: Dictionary = runmap.get("_node_visuals")
	_assert(node_visuals.size() > 0, "fixture rendered no nodes to check")
	for id in node_visuals.keys():
		var entry: Dictionary = node_visuals[id]
		var btn: Button = entry["button"]
		var leaked := re.search(btn.text) != null
		_assert(not leaked, "node '%s' button text leaks a technical id: '%s'" % [id, btn.text])

	runmap.queue_free()
	_done("test_node_label_never_contains_a_technical_graph_id")


## runloop-ux-backlog P0-1. Crafts a shop with one bought item and one item the player cannot
## afford, renders it, and checks the two buttons' "disabled" stylebox (the one Godot actually
## paints for both, since both end up with `disabled=true`) are NOT the same StyleBox — the
## exact bug: `bought or not afford` collapsing both into one visual state.
func test_shop_bought_and_unaffordable_buttons_use_different_styleboxes() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	RunState.shards_this_run = 10
	# The offer lives on RunState now, not on the screen — the screen only draws it.
	RunState.shop_items.assign([
		{"kind": "relic", "key": "bought_one", "title": "Bought Relic", "desc": "", "rar": 1,
			"cost": 5, "bought": true},
		{"kind": "relic", "key": "too_pricey", "title": "Pricey Relic", "desc": "", "rar": 1,
			"cost": 999, "bought": false},
	])
	runmap.call("_render_shop")

	var vbox: VBoxContainer = runmap.get("_overlay_vbox")
	var cards := _only_card_panels(vbox)
	_assert(cards.size() == 2, "expected 2 shop item cards, found %d" % cards.size())
	var bought_btn := _card_button(cards[0]) if cards.size() > 0 else null
	var unafford_btn := _card_button(cards[1]) if cards.size() > 1 else null
	_assert(bought_btn != null and unafford_btn != null,
		"could not find the action button inside one or both shop cards")
	if bought_btn == null or unafford_btn == null:
		runmap.queue_free()
		_done("test_shop_bought_and_unaffordable_buttons_use_different_styleboxes")
		return

	_assert(bought_btn.disabled and unafford_btn.disabled,
		"fixture expectation broken: both buttons should be disabled (nothing to press)")

	var sb_bought: StyleBox = bought_btn.get_theme_stylebox("disabled")
	var sb_unafford: StyleBox = unafford_btn.get_theme_stylebox("disabled")
	_assert(sb_bought != sb_unafford,
		"'bought' and 'can't afford' shop buttons still share the identical disabled stylebox")

	var sbf_bought := sb_bought as StyleBoxFlat
	_assert(sbf_bought != null and sbf_bought.border_color.is_equal_approx(DangoTheme.SUCCESS),
		"'bought' button does not use the SUCCESS-tinted owned style")

	runmap.queue_free()
	_done("test_shop_bought_and_unaffordable_buttons_use_different_styleboxes")


## runloop-ux-backlog P0-2. Every card built by _add_card() with a `rar` should carry a
## "RarityChip" whose label colour matches DangoTheme.rarity_color(rar). Exercised directly
## through reward cards (post-combat/treasure path) AND shop cards, the two real dictionaries
## that already carry a `rar` field end to end.
func test_reward_and_shop_cards_show_a_rarity_chip_matching_rar() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	RunState.pending_rewards = [
		{"t": "hp", "rar": 0, "title": "GENE VITALITY", "desc": "x", "sub": ""},
		{"t": "relic", "rar": 3, "title": "RELIC", "desc": "y", "sub": ""},
	]
	RunState.reward_reroll_charges = 0
	runmap.call("_show_reward_overlay", "CHOOSE A REWARD")

	var vbox: VBoxContainer = runmap.get("_overlay_vbox")
	var cards := _only_card_panels(vbox)
	_assert(cards.size() == 2, "expected 2 reward cards, found %d" % cards.size())

	var expected_rars := [0, 3]
	for i in range(min(cards.size(), expected_rars.size())):
		var chip := _find_rarity_chip(cards[i])
		_assert(chip != null, "reward card %d has no RarityChip" % i)
		if chip == null:
			continue
		var lbl: Label = chip.get_child(0)
		var expected_color := DangoTheme.rarity_color(int(expected_rars[i]))
		_assert(lbl.get_theme_color("font_color").is_equal_approx(expected_color),
			"reward card %d rarity chip colour does not match rar=%d" % [i, expected_rars[i]])

	# Shop cards go through the same _add_card() call site with a different dict shape.
	# _close_overlay()'s _clear_overlay_content() only queue_free()s the old reward cards —
	# they are still in the tree until the next frame, so a frame must pass before the
	# freshly-rendered shop card is safely the only PanelContainer left in _overlay_vbox.
	runmap.call("_close_overlay")
	await get_tree().process_frame
	RunState.shards_this_run = 500
	# The offer lives on RunState now, not on the screen — the screen only draws it.
	RunState.shop_items.assign([
		{"kind": "relic", "key": "k1", "title": "Shop Relic", "desc": "", "rar": 2, "cost": 5, "bought": false},
	])
	runmap.call("_render_shop")
	var shop_cards: Array = _only_card_panels(runmap.get("_overlay_vbox"))
	_assert(shop_cards.size() >= 1, "shop rendered no cards")
	if shop_cards.size() >= 1:
		var shop_chip := _find_rarity_chip(shop_cards[0])
		_assert(shop_chip != null, "shop card has no RarityChip")
		if shop_chip != null:
			var shop_lbl: Label = shop_chip.get_child(0)
			_assert(shop_lbl.get_theme_color("font_color").is_equal_approx(DangoTheme.rarity_color(2)),
				"shop card rarity chip colour does not match rar=2")

	runmap.queue_free()
	_done("test_reward_and_shop_cards_show_a_rarity_chip_matching_rar")


## runloop-ux-backlog P0-3. Direct RewardGenerator-level regression test: a roster member
## whose tier_up target has the IDENTICAL name (the real "Pomodoro" case, ContentDB.gd
## bug1/bug2/bug3) must never produce a "%s -> %s"-shaped description with equal sides.
func test_level_up_description_never_reads_as_x_arrow_x() -> void:
	var roster: Array = [
		{"persistent_id": 1, "hero_key": "bug1", "tier": 1, "max_hp": 14, "muts": [],
			"growth": {}, "bonus_hp": 0},
	]
	var rng := Rng.new(4242)
	var reward := RewardGenerator._make_level_reward(rng, roster, [])
	_assert(not reward.is_empty(), "fixture roster (bug1, has a tier_up entry) produced no level reward")
	if not reward.is_empty():
		var desc := String(reward.get("desc", ""))
		var arrow_split := desc.split(" -> ")
		var bad_old_form := arrow_split.size() == 2 and arrow_split[0] == arrow_split[1]
		_assert(not bad_old_form, "level-up desc still reads as 'X -> X': '%s'" % desc)
		_assert(desc.find(" -> ") == -1, "level-up desc still uses the bare ASCII arrow: '%s'" % desc)
		_assert(desc.find("Tier") != -1, "level-up desc dropped tier information entirely: '%s'" % desc)

	_done("test_level_up_description_never_reads_as_x_arrow_x")


# ---------------------------------------------------------------------------------------
# Small structural helpers — mirror _add_card()'s own tree shape (PanelContainer > HBox >
# [text_col, Button]) rather than duplicating it via a second implementation.
# ---------------------------------------------------------------------------------------

## `_overlay_vbox`'s children are NOT only cards — `_add_overlay_title()`/`_add_overlay_body()`
## add plain Labels and `_add_continue_button()` adds a bare Button directly into the same
## VBox, alongside the PanelContainer cards `_add_card()` builds. Filtering to PanelContainer
## isolates the actual cards regardless of how many labels/buttons a given screen also adds.
func _only_card_panels(vbox: VBoxContainer) -> Array:
	var out: Array = []
	for child in vbox.get_children():
		if child is PanelContainer:
			out.append(child)
	return out


func _card_button(card: Node) -> Button:
	if not (card is PanelContainer):
		return null
	var row := card.get_child(0) if card.get_child_count() > 0 else null
	if row == null:
		return null
	for child in row.get_children():
		if child is Button:
			return child
	return null


func _find_rarity_chip(card: Node) -> PanelContainer:
	if card is PanelContainer and card.name == "RarityChip":
		return card
	for child in card.get_children():
		var found := _find_rarity_chip(child)
		if found != null:
			return found
	return null
