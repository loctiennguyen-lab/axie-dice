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
## RunMapController's save-on-progress calls (`_save_map_progress()`) write RunState.SAVE_PATH,
## which on a dev machine is the player's real run in progress. This file used to call that fair
## game; measured 2026-10-10 it was deleting a real run, so it now uses SaveGuard, which covers
## the run save as well as meta (save_guard.gd).
##
## Run: godot --headless --path godot res://tests/t_runloop_ui.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame",
	"test_the_row_band_keeps_its_height_and_slides_at_both_ends",
	"test_no_edge_travels_more_than_one_lane",
	"test_node_label_never_contains_a_technical_graph_id",
	"test_shop_bought_and_unaffordable_buttons_use_different_styleboxes",
	"test_reward_and_shop_cards_show_a_rarity_chip_matching_rar",
	"test_event_and_treasure_ui3",
	"test_player_text_strips_internal_tags",
	"test_level_up_description_never_reads_as_x_arrow_x",
]

## Puts the player's real meta and run saves back before quitting (see save_guard.gd).
var _guard := SaveGuard.new()

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []

const _ID_PATTERN := "r\\d+_c\\d+"


func _ready() -> void:
	_guard.capture()
	print("=== t_runloop_ui: start ===")
	await get_tree().process_frame

	await test_map_window_renders_nearby_rows_onscreen_and_fills_the_frame()
	await test_the_row_band_keeps_its_height_and_slides_at_both_ends()
	test_no_edge_travels_more_than_one_lane()
	await test_node_label_never_contains_a_technical_graph_id()
	await test_shop_bought_and_unaffordable_buttons_use_different_styleboxes()
	await test_reward_and_shop_cards_show_a_rarity_chip_matching_rar()
	await test_event_and_treasure_ui3()
	await test_player_text_strips_internal_tags()
	test_level_up_description_never_reads_as_x_arrow_x()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	print("=== t_runloop_ui: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_runloop_ui: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_runloop_ui: FAIL — %s" % f)
	_guard.restore()
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
## No drawn edge may travel more than ONE lane sideways.
##
## This is the "The Path vẫn cực kì xấu" report, pinned as a number. The generator is not at
## fault — it keeps |dcol| <= 1 within a path — but a boss row holds a single node that is
## always col 0, and invariant #9 funnels the whole row below onto it and fans the row above
## out of it. Drawn at col 0 those funnels ran lane 2 -> lane 0: 740px sideways across a
## 124px row, five times in an 18-row map, which is the near-horizontal sweep in the report's
## screenshot. RunMapController.lane_index() centres single-node rows so the funnel becomes a
## symmetric V.
##
## Checked against REAL generated graphs over many seeds rather than a fixture, because the
## offending shape only appears at segment boundaries and a hand-written map would not have
## them. Asserting on lane distance rather than on pixels keeps it true if the lane x values
## or the canvas ever move.
func test_no_edge_travels_more_than_one_lane() -> void:
	var script := load("res://scenes/run_map/RunMapController.gd") as GDScript
	var worst := 0
	var worst_desc := ""
	var checked := 0
	for seed_value in [13371337, 555001, 1, 42, 99999, 246810]:
		var rng := Rng.new(seed_value)
		var graph: RunMapGraph = RunMapGenerator.generate(rng, "normal", 0)
		var size_of_row := {}
		for i in graph.rows.size():
			size_of_row[i + 1] = (graph.rows[i] as Array).size()
		for row in graph.rows:
			for raw_from in row:
				var from_node: RunMapNode = raw_from
				var from_lane: int = script.call("lane_index", from_node.col,
					int(size_of_row.get(from_node.row, 0)))
				for next_id in from_node.next_ids:
					var to_node := graph.find_node(next_id)
					if to_node == null:
						continue
					var to_lane: int = script.call("lane_index", to_node.col,
						int(size_of_row.get(to_node.row, 0)))
					checked += 1
					var travel: int = absi(to_lane - from_lane)
					if travel > worst:
						worst = travel
						worst_desc = "seed %d: r%dc%d(lane %d) -> r%dc%d(lane %d)" % [
							seed_value, from_node.row, from_node.col, from_lane,
							to_node.row, to_node.col, to_lane]
	_assert(checked > 100,
		"only %d edges were examined — the generator returned almost nothing and this check "
		% checked + "would pass vacuously")
	_assert(worst <= 1,
		"an edge travels %d lanes sideways (%s); at 370px a lane and 124px a row that draws "
		% [worst, worst_desc] + "as a near-horizontal sweep across the board")
	_done("test_no_edge_travels_more_than_one_lane")


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

	# UI-03 shop: rows are selectable cards; the Buy button lives in the detail plate and says why it is off.
	var cards: Array = runmap.get("_shop_cards")
	_assert(cards.size() == 2, "expected 2 shop item cards, found %d" % cards.size())
	_assert(absf((cards[0] as Control).modulate.a - 0.4) < 0.01 and absf((cards[1] as Control).modulate.a - 1.0) < 0.01,
		"a bought row must be drawn at 40%, an unbought one at full")
	runmap.call("_select_shop", 0)
	var buy0: Button = runmap.find_child("BuyButton", true, false)
	_assert(buy0 != null and buy0.disabled and buy0.text == "Sold out", "bought item: Buy must be disabled and say 'Sold out'")
	runmap.call("_select_shop", 1)
	var buy1: Button = runmap.find_child("BuyButton", true, false)
	_assert(buy1 != null and buy1.disabled and buy1.text == "Need 999 Shards",
		"unaffordable item: Buy must be disabled and say 'Need 999 Shards', got '%s'" % (buy1.text if buy1 else ""))
	_assert(runmap.find_child("BlockReason", true, false) == null, "the reason is on the button only, not repeated above it")
	_assert(runmap.find_child("NothingAffordable", true, false) != null, "nothing affordable: notice missing")
	runmap.call("_select_shop", 0)
	RunState.shards_this_run = 100
	RunState.shop_items[0]["bought"] = false
	RunState.shop_items[0]["cost"] = 5
	runmap.call("_render_shop")
	var buy2: Button = runmap.find_child("BuyButton", true, false)
	_assert(buy2 != null and not buy2.disabled, "affordable, unbought item must have an enabled Buy")
	_assert(runmap.find_child("NothingAffordable", true, false) == null, "notice shown though an item is affordable")

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
		var expected_color: Color = runmap.call("_rarity_color", int(expected_rars[i]))
		_assert(_has_border(cards[i], expected_color),
			"reward card %d shows no art frame in rarity colour %d — UI-03 carries the rarity "
			% [i, int(expected_rars[i])] + "in the art frame border and the rarity label")
	# Five rarities must read as five different colours (Uncommon and Rare used to collide).
	var seen: Array[Color] = []
	for r in 5:
		var c: Color = runmap.call("_rarity_color", r)
		for s in seen:
			_assert(not s.is_equal_approx(c), "rarity %d shares its colour with a lower rarity" % r)
		seen.append(c)
	await get_tree().process_frame
	await get_tree().process_frame
	# The same relic id shows the same rarity name and colour on the reward card and the relic plate.
	for rid in ["r_bastionplate", "r_ember"]:
		var def = RelicRegistry.get_def(rid)
		if def == null:
			continue
		var want_name: String = runmap.call("_rarity_name", int(def.rarity))
		var want_col: Color = runmap.call("_rarity_color", int(def.rarity))
		var wrong_rar := (int(def.rarity) + 1) % 4   # a stale/incorrect `rar` in the offer must not win
		var got: int = runmap.call("_reward_rarity", {"t": "relic", "key": rid, "rar": wrong_rar})
		_assert(got == int(def.rarity), "%s: reward card rarity %d differs from its definition %d" % [rid, got, int(def.rarity)])
		var row: Control = runmap.call("_build_relic_row", rid)
		var lbl: Label = row.get_child(0).get_child(1)
		_assert(lbl.text == want_name and lbl.get_theme_color("font_color").is_equal_approx(want_col),
			"%s: relic plate rarity label/colour differs from the reward card's" % rid)
		row.free()
	var cards_h: Array = []
	for c in cards:
		cards_h.append(int((c as Control).size.y))
	_assert(cards_h.size() < 2 or cards_h.min() == cards_h.max(), "reward cards differ in height: %s" % [cards_h])
	# UI-03: pick a card, then Take. Selecting alone must not finish the node.
	_assert(runmap.find_child("TakeButton", true, false) != null, "reward screen has no Take button")
	_assert(runmap.find_child("RerollButton", true, false) != null, "reward screen has no Reroll button")
	_assert(runmap.find_child("RerollButton", true, false).disabled, "Reroll with 0 charges should be disabled")
	runmap.call("_select_reward", 1)
	_assert(int(runmap.get("_reward_sel")) == 1, "selecting card 1 did not stick")

	# UI-03 31: Chaos / Curse draw Gain + Gamble/Curse boxes and ask "This lasts the whole run" before applying.
	var none: Array[Dictionary] = []
	var chaos := RewardGenerator._make_chaos_reward(Rng.new(5), RunState.owned_relic_ids, none)
	var curse := RewardGenerator._make_curse_reward(none)
	_assert(not chaos.is_empty() and not curse.is_empty(), "generator gave a chaos and a curse card")
	RunState.pending_rewards = [chaos, curse]
	runmap.call("_show_reward_overlay", "CHOOSE A REWARD")
	await get_tree().process_frame
	_assert(runmap.find_child("TradeBox_gain", true, false) != null and runmap.find_child("TradeBox_gamble", true, false) != null
		and runmap.find_child("TradeBox_curse", true, false) != null, "chaos/curse cards show TradeBoxes")
	var reroll_before := RunState.bonus_reroll
	runmap.call("_select_reward", 1)
	runmap.call("_take_selected_reward")
	await get_tree().process_frame
	_assert(runmap.find_child("LastingConfirm", true, false) != null, "curse Take asks for confirmation")
	_assert(RunState.bonus_reroll == reroll_before and RunState.pending_rewards.size() == 2, "curse not applied before confirm")
	runmap.call("_close_overlay")
	await get_tree().process_frame

	# UI-03 32: passive slots full -> swap sheet; Leave it changes nothing; picking a cell then confirming sells + takes.
	var full := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook", "r_barbedhide", "r_heart"]
	RunState.owned_relic_ids.assign(full)
	RunState.relic_stickers = {"r_heart": "eternal"}
	RunState.pending_rewards = [{"t": "relic", "key": "r_seedling", "rar": 0, "title": "RELIC", "desc": "Seedling", "sub": ""}]
	runmap.call("_show_reward_overlay", "CHOOSE A REWARD")
	await get_tree().process_frame
	runmap.call("_take_selected_reward")
	await get_tree().process_frame
	var sheet := runmap.find_child("SlotSwapSheet", true, false)
	_assert(sheet != null, "full passive slots open the swap sheet")
	if sheet != null:
		var conf: Button = sheet.find_child("SwapConfirm", true, false)
		_assert(conf.disabled, "swap confirm disabled until a cell is picked")
		_assert((sheet.find_child("SlotCell_r_heart", true, false) as Button).disabled, "Eternal cell can't be picked")
		var shards0 := RunState.shards_this_run
		(sheet.find_child("SwapLeave", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_assert(runmap.find_child("SlotSwapSheet", true, false) == null and not RunState.owned_relic_ids.has("r_seedling"), "Leave it takes nothing")
		runmap.call("_take_selected_reward")
		await get_tree().process_frame
		sheet = runmap.find_child("SlotSwapSheet", true, false)
		(sheet.find_child("SlotCell_r_claw", true, false) as Button).pressed.emit()
		_assert(not (sheet.find_child("SwapConfirm", true, false) as Button).disabled, "pick enables confirm")
		(sheet.find_child("SwapConfirm", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		_assert(RunState.owned_relic_ids.has("r_seedling") and not RunState.owned_relic_ids.has("r_claw"), "swap sold r_claw, took r_seedling")
		_assert(RunState.shards_this_run == shards0 + RelicSlots.sell_price("r_claw", RunState.ascension), "sale paid shards")
	RunState.relic_stickers = {}
	runmap.call("_close_overlay")
	await get_tree().process_frame

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
	var shop_cards: Array = runmap.get("_shop_cards")
	_assert(shop_cards.size() >= 1, "shop rendered no cards")
	if shop_cards.size() >= 1:
		var rl: Label = (shop_cards[0] as Node).find_child("RarityLabel", true, false)
		_assert(rl != null and rl.get_theme_color("font_color").is_equal_approx(runmap.call("_rarity_color", 2)),
			"shop card's rarity label is not coloured with its own rarity")
		_assert(rl.text == runmap.call("_rarity_name", 2), "shop card rarity name mismatch")

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


func _has_border(node: Node, col: Color) -> bool:
	var ctrl := node as Control
	if ctrl != null:
		var sb := ctrl.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null and sb.border_color.is_equal_approx(col) and sb.border_width_left > 0:
			return true
	for child in node.get_children():
		if _has_border(child, col):
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


## UI-03 09/13: the event's Pick button is off until a choice is selected, then names it; the outcome
## dims the other choices. Treasure starts closed ("Open chest") and then offers the rewards.
func test_event_and_treasure_ui3() -> void:
	var runmap := _new_runmap()
	await get_tree().process_frame
	RunState.event_key = String(ContentDB.events.keys()[0])
	runmap.call("_on_event_node", "x")
	await get_tree().process_frame
	var go: Button = runmap.find_child("EventAction", true, false)
	_assert(go != null and go.disabled and go.text == "Pick a choice", "event: action must start disabled as 'Pick a choice'")
	var opts: Array = runmap.get("_event_opts")
	_assert(opts.size() >= 1 and runmap.find_child("EventOption0", true, false) != null, "event: no choice rows")
	runmap.call("_select_event", 0)
	_assert(not go.disabled and go.text == "Choose", "event: action must read 'Choose' once a choice is picked")
	runmap.call("_build_event_screen", 0, "Result text")
	await get_tree().process_frame
	go = runmap.find_child("EventAction", true, false)
	_assert(go.text == "Continue" and not go.disabled, "event outcome: button must be Continue")
	if opts.size() > 1:
		_assert(absf((runmap.find_child("EventOption1", true, false) as Control).modulate.a - 0.4) < 0.01, "event outcome: other choices at 40%")
	_assert((runmap.find_child("EventBody", true, false) as Label).text == "Result text", "event outcome: body must be the result")
	runmap.call("_on_treasure_node", "tn")
	await get_tree().process_frame
	_assert(runmap.find_child("OpenChest", true, false) != null, "treasure: closed state needs 'Open chest'")
	runmap.call("_build_treasure", true)
	await get_tree().process_frame
	_assert(runmap.find_child("TakeButton", true, false) != null, "treasure: opened state needs 'Take and continue'")
	runmap.queue_free()
	_done("test_event_and_treasure_ui3")


## UI3.describe(): no internal tag may reach a label.
func test_player_text_strips_internal_tags() -> void:
	for raw in ["RULE: Burn loses only 1 stack.", "PACT. +3 max Rerolls.", "[Global] [Axis: Burn] Deal 4.", "[INF] Say \\\"hi\\\"", "[MP 7] Apply Burn 6."]:
		var t := UI3.player_text(raw)
		_assert(not t.contains("RULE:") and not t.contains("[") and not t.contains("PACT.") and not t.contains("\\"), "tag leaked: '%s' -> '%s'" % [raw, t])
	_assert(int(UI3.describe("[MP 7] Apply Burn 6.")["mp"]) == 7 and UI3.player_text("[MP 7] Apply Burn 6.") == "Apply Burn 6.", "MP not lifted out")
	# every real relic description renders clean
	for def in RelicRegistry.all_defs_sorted():
		var rid := String(def.id)
		var t2 := UI3.player_text(String(def.description))
		_assert(not t2.contains("RULE:") and not t2.contains("["), "relic %s leaks a tag: %s" % [rid, t2])
	_done("test_player_text_strips_internal_tags")
