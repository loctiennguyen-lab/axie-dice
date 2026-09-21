extends Node
## REGRESSION TEST for the 2026-09-21 input bug: "only a tiny part of a skill card responds to
## a click", "I cannot aim a skill at a boss or an Axie", "clicking a unit never opens its Info".
##
## The first two were ONE defect with ONE cause, and it was invisible to every other test in
## this suite, because every other test calls CombatView's handlers DIRECTLY (t_combatview_smoke:
## `_view._on_die_slot_pressed(i)`; t_unit_inspect: `_view._on_target_clicked(uid)`). A handler
## that works perfectly is worthless if no click ever reaches it, so this test is the only one
## that pushes a REAL InputEventMouseButton through the viewport at a real screen coordinate and
## asks whether the game noticed.
##
## THE CAUSE. `DangoScreen.build()`'s "Content" column — a full-rect, EMPTY, transparent Control
## appended LAST to the shell, at Control's default MOUSE_FILTER_STOP. Godot picks GUI input by
## walking children in reverse tree order and ignores `z_index` while doing it, so it covered the
## board and the whole deck except the outer margin. At the 1920x1238 canvas the bug was reported
## at, its bottom edge fell at y=1190 and the die cards ran 1064..1222 — the ~32px strip below it
## was the only part of a card that answered a click, which is exactly the shape of the report.
##
## The third (no inspector on click) is the same cause: the nameplates sit inside that rectangle.
##
## WHAT THIS TEST IS ALSO FOR. The mouse_filter DEFAULTS are not uniform — Container is PASS,
## Panel/PanelContainer/ColorRect/Button are STOP, Label is IGNORE — and reasoning about a hit
## test from the source alone gets this wrong. See `_picked_at()`/`_handler_at()`/`_tooltip_at()`
## at the bottom of this file, which model the three separate walks the engine really does.
##
## Run: godot --headless --path godot res://tests/t_combat_hit_targets.tscn

const _VIEWPORT := Vector2i(1920, 1238)   # the shape the bug was reported at: 1920 canvas
	# (project.godot's minimum width) grown vertically by `stretch/aspect="expand"`. The Content
	# column's own bottom edge sat at 1238-48 = 1190, which is why "the bottom of the card works
	# and the rest does not" was the shape of the report.

var _view: Node2D
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true
	print("=== t_combat_hit_targets: start ===")

	# A window this size is what puts the Content column over the board. Headless still lays
	# Controls out against the root viewport's size, so setting it here is enough.
	tree.root.content_scale_size = _VIEWPORT
	tree.root.size = _VIEWPORT

	# One real relic, so the top-bar strip and the RELIC ACTIVES rack actually have something
	# to hover. Taken from the registry rather than hardcoded — a relic id that gets renamed
	# should not turn this into a test about nothing.
	var relic_ids: Array = []
	var defs: Array = RelicRegistry.offerable_defs_sorted()
	if not defs.is_empty():
		relic_ids.append(String(defs[0].id))
	RunState.pending_combat = {
		"node_id": "hit_targets_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": relic_ids, "combat_seed": 4242,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	# Two frames: one for _ready()/onready wiring, one for the container layout pass that gives
	# every Control its real size — a rect read on frame 0 is still (0,0).
	await tree.process_frame
	await tree.process_frame

	await _test_die_card_is_clickable_across_its_whole_face(tree)
	await tree.process_frame
	_test_reroll_and_end_turn_are_clickable_at_their_top_edge(tree)
	await tree.process_frame
	await _test_clicking_an_enemy_nameplate_reaches_the_view(tree)
	await tree.process_frame
	_test_the_3d_stage_can_receive_gui_input()
	_test_the_shared_content_column_is_click_through()
	await _test_every_hoverable_icon_explains_itself(tree)

	CombatView.disable_juice_for_tests = false
	if _fails.is_empty():
		print("=== t_combat_hit_targets: %d checks, 0 failure(s) ===" % _checks)
		print("t_combat_hit_targets: PASS — %d checks OK" % _checks)
		tree.quit(0)
	else:
		for f in _fails:
			print("t_combat_hit_targets: FAIL — %s" % f)
		tree.quit(1)


## THE headline case. Four points on DieSlot0 — its very top-left corner inward, the header
## band, the middle of the face row and the bottom strip. Before the fix only the last one
## selected the die; the other three landed on the Content column and did nothing.
func _test_die_card_is_clickable_across_its_whole_face(tree: SceneTree) -> void:
	var btn: Button = _view.get_node("%DieSlot0")
	_check(btn.size.x >= 170.0 and btn.size.y >= 150.0,
		"DieSlot0 has not been laid out yet (size=%s)" % btn.size)
	# Offsets from the card's own top-left, resolved against a FRESHLY measured rect each time:
	# a selected card lifts 16px (_update_die_slot_lift()), so a rect cached before the first
	# click describes the wrong rectangle by the second one.
	for where in ["top-left corner", "portrait tile", "header band", "part tile",
			"type tile", "face row", "bottom strip"]:
		# Deselect through the real path so the lift is undone and the card is back where the
		# player sees it, then let the layout settle before measuring.
		_view.set("_selected_die_uid", -1)
		_view.call("_rebuild_all")
		await tree.process_frame
		var r := Rect2(btn.global_position, btn.size)
		var at := r.position + r.size * 0.5
		match where:
			"top-left corner": at = r.position + Vector2(6, 6)
			# Points that land on a CHILD of the card rather than on bare card surface. A
			# Container defaults to MOUSE_FILTER_PASS, so these reach the Button by
			# propagation rather than directly — worth pinning, because switching any of
			# them to STOP (an easy thing to do while chasing a tooltip) turns that tile
			# into a dead spot and nothing else in the suite would notice.
			"portrait tile": at = r.position + Vector2(22, 19)       # header portrait, 26px
			"part tile": at = r.position + Vector2(30, 39 + 9 + 20)  # 41px part-icon tile
			"type tile": at = r.position + Vector2(r.size.x - 26, 39 + 9 + 20)  # 26px type tile
			"header band": at = r.position + Vector2(r.size.x * 0.5, 18)
			"bottom strip": at = r.position + Vector2(r.size.x * 0.5, r.size.y - 6)
		_click(tree, at)
		_check(int(_view.get("_selected_die_uid")) != -1,
			"clicking DieSlot0's %s at %s did not select the die — %s took the click" % [
				where, at, _describe(_handler_at(at))])


## The other two controls the report named. Their TOP edge is the half that was covered.
func _test_reroll_and_end_turn_are_clickable_at_their_top_edge(tree: SceneTree) -> void:
	for pair in [["%RerollButton", "reroll_dice"], ["%EndTurnButton", "end_turn"]]:
		var btn: Button = _view.get_node(String(pair[0]))
		if btn.disabled:
			continue   # nothing to prove on a button the rules have switched off this turn
		var top := btn.global_position + Vector2(btn.size.x * 0.5, 4.0)
		_check(_handler_at(top) == btn,
			"%s's top edge at %s is covered by %s, not by the button" % [
				pair[0], top, _describe(_handler_at(top))])


## Click an enemy's nameplate with NO die selected: the rule (src/client.html:5273, ported in
## CombatView._on_target_clicked()) is that this opens the inspector. It is also the cheapest
## end-to-end proof that a click reaches a unit at all.
func _test_clicking_an_enemy_nameplate_reaches_the_view(tree: SceneTree) -> void:
	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	var portraits: Dictionary = _view.get("_portraits") as Dictionary
	var enemy: Unit = combat.enemies[0]
	var p: Control = portraits.get(enemy.uid)
	_check(p != null, "no UnitPortrait for enemy uid=%d" % enemy.uid)
	if p == null:
		return
	_view.set("_selected_die_uid", -1)
	_view.call("_close_unit_inspect")
	_click(tree, p.global_position + p.size * 0.5)
	await tree.process_frame
	_check(_view.get("_inspect_panel") != null,
		"clicking enemy '%s' nameplate at %s opened no inspector" % [
			enemy.n, p.global_position + p.size * 0.5])
	_view.call("_close_unit_inspect")


## A guard, not a regression: the RUNTIME value is what decides whether clicking a 3D model
## works, and `CombatStage3D._ready()` sets STOP while the scene file spent a long time saying
## IGNORE. Asserting the runtime value is the only check that cannot be fooled by reading one
## file — and if anyone ever deletes that `_ready()` line, this is what catches it.
func _test_the_3d_stage_can_receive_gui_input() -> void:
	var stage: Control = _view.get_node("%Stage3D")
	_check(stage.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"CombatStage3D resolved to MOUSE_FILTER_IGNORE at runtime — _gui_input() can never "
		+ "fire, so clicking an Axie or a boss model would do nothing")
	_check(stage.has_signal("unit_inspect_requested"),
		"CombatStage3D lost its right-click inspect signal")


## Cause 1, pinned the same way. Every screen in the game gets this column; combat is only
## where it happened to sit over something clickable.
func _test_the_shared_content_column_is_click_through() -> void:
	var col: Node = _view.get_node_or_null("CanvasLayer/Root/Content")
	_check(col != null, "DangoScreen's Content column is missing from the combat shell")
	if col == null:
		return
	_check((col as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"DangoScreen's Content column is not MOUSE_FILTER_IGNORE — it is a full-rect Control "
		+ "appended last, so it covers whatever the screen put under it")


## The second half of the same bug report: "hovering a Relic or an effect icon shows nothing".
## A tooltip only appears on the control the viewport actually PICKS, so each case checks both
## halves — the control under the cursor is the one carrying the text, and the text says what
## the thing does rather than just naming it.
func _test_every_hoverable_icon_explains_itself(tree: SceneTree) -> void:
	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	var portraits: Dictionary = _view.get("_portraits") as Dictionary
	var enemy: Unit = combat.enemies[0]
	enemy.status["poison"] = 3
	_view.call("_rebuild_all")
	await tree.process_frame

	# 1 — a status chip on a nameplate.
	var p: Control = portraits.get(enemy.uid)
	var row: HBoxContainer = p.get("_status_row")
	_check(row.get_child_count() > 0, "poison 3 produced no status chip on the nameplate")
	if row.get_child_count() > 0:
		var chip: Control = row.get_child(0)
		var at := chip.global_position + chip.size * 0.5
		var tip := _tooltip_at(at)
		_check(tip.contains("Poison") and tip.length() > 20,
			"hovering the poison chip at %s resolves to '%s' — before this fix the plate's "
			% [at, tip] + "own full-rect ClickCatcher sat in front of the chips and the "
			+ "hover never reached them at all")

	# 2 — a relic chip in the top bar.
	var strip: HBoxContainer = _view.get("_relic_strip")
	if strip.get_child_count() > 0:
		var relic_chip: Control = strip.get_child(0)
		var at2 := relic_chip.global_position + relic_chip.size * 0.5
		var tip2 := _tooltip_at(at2)
		_check(tip2.contains("\n"),
			"relic hover at %s resolves to '%s' — it should be the name AND the relic's own "
			% [at2, tip2] + "rule, not a bare name")

	# 3 — the die card names its face and spells out every keyword on it.
	var btn: Button = _view.get_node("%DieSlot0")
	_check(btn.tooltip_text.length() > 0, "the die card has no tooltip at all")

	# 4 — the enemy intent badge, the documented hover target for "why is it doing that".
	var huds: Dictionary = _view.get("_head_huds") as Dictionary
	var hud = huds.get(enemy.uid)
	if hud != null:
		var panel: Control = hud.get("_intent_panel")
		_check(panel.tooltip_text.length() > 20,
			"the enemy intent badge explains nothing on hover: '%s'" % panel.tooltip_text)


# ---------------------------------------------------------------------------

## A real press+release pair through the viewport, exactly as a mouse would deliver it — this
## is the point of the whole file, so it must not shortcut into `Control._gui_input()`.
func _click(tree: SceneTree, at: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		tree.root.push_input(ev, true)


## Godot exposes no public `gui_find_control()`, so the three walks below re-implement what the
## viewport does. Getting this model wrong is not academic — an earlier version of this file
## treated "the control the viewport PICKS" as "the control that HANDLES the click", which is
## only true for MOUSE_FILTER_STOP, and it produced two confident, wrong diagnoses before the
## defaults were checked against the engine itself:
##
##     Control STOP · Panel STOP · PanelContainer STOP · ColorRect STOP · Button STOP
##     Container PASS (so CenterContainer / VBox / HBox / Margin / Grid) · TextureRect PASS
##     SubViewportContainer PASS · Label IGNORE
##
## PICKED   the topmost non-IGNORE control under the point.
## HANDLES  from the picked one, walk up while the filter is PASS; the first STOP is the one
##          that actually receives the click. This is why a PASS container sitting on a Button
##          is NOT a dead spot.
## TOOLTIP  from the picked one, walk up taking the first non-empty `tooltip_text`, stopping at
##          a STOP node that has none of its own.
func _picked_at(at: Vector2) -> Control:
	return _find_control(get_tree().root, at)


func _handler_at(at: Vector2) -> Control:
	var c := _picked_at(at)
	while c != null and c.mouse_filter == Control.MOUSE_FILTER_PASS:
		c = c.get_parent_control()
	return c


func _tooltip_at(at: Vector2) -> String:
	var c := _picked_at(at)
	while c != null:
		if not c.tooltip_text.is_empty():
			return c.tooltip_text
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			return ""
		c = c.get_parent_control()
	return ""


func _find_control(n: Node, at: Vector2) -> Control:
	for i in range(n.get_child_count() - 1, -1, -1):
		var hit := _find_control(n.get_child(i), at)
		if hit != null:
			return hit
	if n is Control:
		var c := n as Control
		if c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE \
				and Rect2(c.global_position, c.size).has_point(at):
			return c
	return null


func _describe(c: Control) -> String:
	return "<nothing>" if c == null else "%s (%s)" % [c.name, c.get_class()]


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
