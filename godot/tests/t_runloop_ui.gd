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
	"test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame",
	"test_the_row_band_keeps_its_height_and_slides_at_both_ends",
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

	await test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame()
	await test_the_row_band_keeps_its_height_and_slides_at_both_ends()
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

## UPDATED 2026-09-20 for the v2 UI redesign (docs/design-handoff-v2, RUN MAP screen). v1 laid
## the graph out in WORLD space and auto-framed a Camera2D around it — this test used to pin
## "the camera fit covers every rendered node, not just the reachable row" (the literal P0-1
## bug: a Camera2D that only fit current+reachable clipped every row beyond it).
##
## v2 deletes the camera entirely: the board is laid out directly in fixed 1920x1080 screen
## space (RunMapController._node_screen_pos()) and windowed to a band of rows around the
## player. There is nothing left to "clip" — a row either falls inside the band and is drawn
## on-screen, or falls outside it and is not rendered at all.
##
## UPDATED AGAIN 2026-09-21. The band used to be CLAMPED at the ends of the run, and this test
## pinned the consequence: standing on row 1 of a six-row fixture, it asserted that exactly
## five nodes rendered and that rows 5 and 6 were excluded. That was not a rule, it was a
## symptom — a seven-slot frame drawing four rows, which on the real 18-row map left the whole
## lower third of the screen blank (bug report: "The Path đang mất thẩm mỹ"). The band now
## SLIDES instead of shrinking, so on this fixture every row is in view and nothing is
## excluded at all. The two things worth pinning are pinned below instead: nothing rendered
## may fall off-screen (the original invariant, unchanged), and the band must keep its full
## height wherever the player stands (the new one).
func test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	var vp_size: Vector2 = runmap.get_viewport().get_visible_rect().size
	var viewport_rect := Rect2(Vector2.ZERO, vp_size)

	var node_visuals: Dictionary = runmap.get("_node_visuals")
	# Six fixture rows, eight nodes, a seven-slot band: standing on row 1 the band slides to
	# rows 1..7, the fixture runs out at 6, and every node is in view. Under the old clamped
	# band this was five nodes and two dead slots.
	_assert(node_visuals.size() == 8,
		"the band should now cover the whole six-row fixture (8 nodes), found %d — if this "
		% node_visuals.size() + "is 5, the band is clamping at the start of the run again")

	var all_onscreen := true
	var first_miss := ""
	for id in node_visuals.keys():
		var entry: Dictionary = node_visuals[id]
		var root: Control = entry["root"]
		var rect := Rect2(root.position, root.size)
		if not viewport_rect.encloses(rect):
			all_onscreen = false
			if first_miss == "":
				first_miss = "%s at %s (viewport %s)" % [id, rect, viewport_rect]
	_assert(all_onscreen, "a rendered node's token falls outside the viewport — first miss: %s" % first_miss)

	runmap.queue_free()
	_done("test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame")


## The band's own contract, on a map long enough to have an inside as well as two ends — the
## six-row fixture above cannot express exclusion any more, because a seven-slot band covers
## it whole.
##
## THREE THINGS, and the first is the one that was broken: the band is always exactly as tall
## as it is designed to be, wherever the player stands. Clamping it at the ends is what left
## the map hugging one edge of the frame with dead space against the other.
func test_the_row_band_keeps_its_height_and_slides_at_both_ends() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	# Swap in a long map and ask the controller directly. Cheaper and clearer than building a
	# second scene, and _row_window() reads nothing but `_graph.rows.size()`.
	var long_rows: Array = []
	for r in range(1, 21):
		long_rows.append([_node_data("L%d_c0" % r, r, 0, "battle",
			[] if r == 20 else ["L%d_c0" % (r + 1)])])
	runmap.set("_graph", RunMapGraph.from_data({
		"rows": long_rows, "boss_rows": [20], "elite_rows": [], "start_node_id": "L1_c0"}))

	# RunMapController.gd has no `class_name`, so its constants are read off the script
	# resource rather than hardcoded here — the point of this check is that the band matches
	# ITS OWN declared height, not a 7 typed into a test.
	var consts: Dictionary = (load("res://scenes/run_map/RunMapController.gd") as GDScript) \
		.get_script_constant_map()
	var span: int = int(consts["_ROWS_BEHIND"]) + int(consts["_ROWS_AHEAD"]) + 1
	for raw_row in [1, 2, 3, 10, 18, 19, 20]:
		var current_row := int(raw_row)
		var w: Vector2i = runmap.call("_row_window", current_row)
		var lo := current_row + w.x
		var hi := current_row + w.y
		_assert(hi - lo + 1 == span,
			"at row %d the band covers %d rows (%d..%d), not the full %d — it is clamping "
			% [current_row, hi - lo + 1, lo, hi, span] + "instead of sliding")
		_assert(lo >= 1 and hi <= 20,
			"at row %d the band runs off the map: rows %d..%d of 1..20" % [current_row, lo, hi])
		_assert(w.x <= 0 and w.y >= 0,
			"at row %d the band (%d..%d) no longer contains the player's own row"
			% [current_row, w.x, w.y])

	# And it still EXCLUDES: on a 20-row map a row seven beyond the player is out of the band
	# whichever way it has slid.
	var mid: Vector2i = runmap.call("_row_window", 10)
	_assert(mid.x == -3 and mid.y == 3,
		"in the middle of a long map the band should be the unslid -3..+3, got %d..%d"
		% [mid.x, mid.y])

	runmap.queue_free()
	_done("test_the_row_band_keeps_its_height_and_slides_at_both_ends")


## visual-polish-backlog P0-2. Every node's visible text — across every tier
## (current/reachable/dim/fog) — must never contain a technical "r<row>_c<col>" id.
##
## UPDATED 2026-09-20 for the v2 UI redesign: v1 put the caption directly on the node Button's
## own `.text`. v2's token button is deliberately chromeless/textless (DangoTheme's blank
## StyleBoxEmpty override plus `btn.flat = true` — see RunMapController._build_token()); the
## caption is now a separate Label inside a chip control below the token, stored in
## `_node_visuals[id]["caption"]`, and is only present at all for the "here"/"open" tiers. This
## still tests the exact same rule (no technical id ever reaches the player) against wherever
## that text now actually lives.
func test_node_label_never_contains_a_technical_graph_id() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	var re := RegEx.new()
	re.compile(_ID_PATTERN)

	var node_visuals: Dictionary = runmap.get("_node_visuals")
	_assert(node_visuals.size() > 0, "fixture rendered no nodes to check")
	for id in node_visuals.keys():
		var entry: Dictionary = node_visuals[id]
		var btn: Button = entry["root"]
		var leaked := re.search(btn.text) != null
		_assert(not leaked, "node '%s' button text leaks a technical id: '%s'" % [id, btn.text])
		var caption: Label = entry.get("caption")
		if caption != null:
			var caption_leaked := re.search(caption.text) != null
			_assert(not caption_leaked,
				"node '%s' caption leaks a technical id: '%s'" % [id, caption.text])

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

	var vbox: BoxContainer = runmap.get("_overlay_vbox")
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
	# UPDATED 2026-09-20 for the v2 surface system. v1's owned style was an 18%-alpha SUCCESS
	# wash with a SUCCESS border, so the border was where the colour lived and this asserted on
	# it. v2 forbids tints outright ("colour is a solid fill, never a tint") and every outline in
	# the system is pure black, so the colour moved to the FILL — which is a stronger version of
	# what this check has always been for: a bought item must read as a SUCCESS, not as a
	# disabled control.
	_assert(sbf_bought != null and sbf_bought.bg_color.is_equal_approx(DangoTheme.SUCCESS),
		"'bought' button does not use the solid-SUCCESS owned style")

	runmap.queue_free()
	_done("test_shop_bought_and_unaffordable_buttons_use_different_styleboxes")


## runloop-ux-backlog P0-2, RE-STATED FOR v2. The rule has not changed — a card that has a
## rarity must SHOW it — but where the colour lives has. v1 put it in a chip's font colour; v2
## forbids that outright (L4 "colour is a solid fill, never a wash", L5 "ink is chosen per fill")
## and gives each surface its own carrier: RWD-02 fills the reward card's 46px HEADER BAND with
## the rarity colour, and SHP-03 gives the shop row a solid `RarityChip`. Asserting on a font
## colour therefore failed on two screens that are both correct.
func test_reward_and_shop_cards_show_a_rarity_chip_matching_rar() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame

	RunState.pending_rewards = [
		{"t": "hp", "rar": 0, "title": "GENE VITALITY", "desc": "x", "sub": ""},
		{"t": "relic", "rar": 3, "title": "RELIC", "desc": "y", "sub": ""},
	]
	RunState.reward_reroll_charges = 0
	runmap.call("_show_reward_overlay", "CHOOSE A REWARD")

	var vbox: BoxContainer = runmap.get("_overlay_vbox")
	var cards := _only_card_panels(vbox)
	_assert(cards.size() == 2, "expected 2 reward cards, found %d" % cards.size())

	var expected_rars := [0, 3]
	for i in range(min(cards.size(), expected_rars.size())):
		var expected_color := DangoTheme.rarity_color(int(expected_rars[i]))
		_assert(_has_fill(cards[i], expected_color),
			"reward card %d draws nothing filled with rarity_color(%d) — RWD-02 puts the rarity "
			% [i, int(expected_rars[i])] + "in the header band's fill")

	# Shop cards go through the same call site with a different dict shape.
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
			var accent := DangoTheme.rarity_color(2)
			var chip_sb := shop_chip.get_theme_stylebox("panel") as StyleBoxFlat
			_assert(chip_sb != null and chip_sb.bg_color.is_equal_approx(accent),
				"shop card's RarityChip is not FILLED with rarity_color(2)")
			var shop_lbl: Label = shop_chip.get_child(0)
			_assert(shop_lbl.get_theme_color("font_color").is_equal_approx(
					DangoTheme.ink_on(accent)),
				"shop card's rarity label is not inked by ink_on() for its own fill")

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
## RWD-02: the reward screen lays its cards ACROSS, so this host is an HBoxContainer
## there and a VBoxContainer on the shop, event and treasure screens. `BoxContainer` is
## the type both share; pinning it to `VBoxContainer` made the reward case a hard error.
func _only_card_panels(vbox: BoxContainer) -> Array:
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


## True when any StyleBoxFlat under `node` is filled with `fill` — the v2 way a card carries a
## rarity, class or status: as a surface colour, not as coloured text.
func _has_fill(node: Node, fill: Color) -> bool:
	var ctrl := node as Control
	if ctrl != null:
		var sb := ctrl.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null and sb.bg_color.is_equal_approx(fill):
			return true
	for child in node.get_children():
		if _has_fill(child, fill):
			return true
	return false


func _find_rarity_chip(card: Node) -> PanelContainer:
	if card is PanelContainer and card.name == "RarityChip":
		return card
	for child in card.get_children():
		var found := _find_rarity_chip(child)
		if found != null:
			return found
	return null
