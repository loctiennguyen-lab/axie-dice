extends Node
## Gate for the unit inspector (src/client.html scUnitInfo(), :6945).
##
## WHAT IT IS FOR
## --------------
## Until 2026-09-19 a player could read their own dice off the tray cards and had **no way at
## all** to see an enemy's. Twenty-one monsters and six bosses, six faces each, and the only
## way to learn any of it was to be hit by it. The rule spec calls for total transparency; that
## was the largest hole in it.
##
## THE RISK THIS GUARDS
## --------------------
## The inspector opens on a click that previously did nothing, and that click arrives through
## the SAME handler as targeting, by two separate routes (the 3D model and the nameplate). The
## failure that would matter is not a missing panel — it is a panel that eats a click meant to
## attack. `test_selecting_a_die_then_clicking_an_enemy_still_attacks()` is the important one
## in this file; the rest describe the panel.
##
## Run: godot --headless --path godot res://tests/t_unit_inspect.tscn

var _failures: Array[String] = []
var _checks := 0
var _view: Node2D


func _ready() -> void:
	print("=== t_unit_inspect: start ===")
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true

	RunState.pending_combat = {
		"node_id": "inspect_node", "kind": "battle", "pw": 4, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 5150,
	}
	var scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(scene)
	_view = scene
	await tree.process_frame

	test_every_class_has_passive_text()
	test_every_body_part_the_data_uses_has_a_label()
	test_clicking_an_enemy_with_no_die_selected_opens_the_inspector()
	test_the_panel_lists_all_six_faces_with_live_values()
	test_selecting_a_die_then_clicking_an_enemy_still_attacks()
	test_the_inspector_closes_and_leaves_nothing_behind()

	print("=== t_unit_inspect: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_unit_inspect: PASS — %d checks OK" % _checks)
		tree.quit(0)
		return
	for f in _failures:
		print("t_unit_inspect: FAIL — %s" % f)
	tree.quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _roster() -> Array:
	var out: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


## Every Label anywhere under the open panel, flattened — the panel is built from plain
## Controls, so its text IS its contract.
func _panel_text() -> String:
	if _view._inspect_panel == null or not is_instance_valid(_view._inspect_panel):
		return ""
	var out: Array = []
	var stack: Array = [_view._inspect_panel]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label:
			out.append((n as Label).text)
		elif n is Button:
			out.append((n as Button).text)
		for c in n.get_children():
			stack.append(c)
	return "\n".join(PackedStringArray(out))


# ---------------------------------------------------------------------------

## The engine has applied all six class passives since Phase 1 and never told the player any of
## them existed. The text is ported data, so its absence is checkable.
func test_every_class_has_passive_text() -> void:
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		_assert(ContentDB.CLASS_PASSIVE.has(cls),
			"class '%s' has no passive text — the engine applies its passive regardless, so the "
				% cls + "player sees an effect with no explanation")
		if not ContentDB.CLASS_PASSIVE.has(cls):
			continue
		var pas: Dictionary = ContentDB.CLASS_PASSIVE[cls]
		_assert(String(pas.get("n", "")).strip_edges() != "",
			"class '%s' passive has no name" % cls)
		_assert(String(pas.get("d", "")).strip_edges().length() > 20,
			"class '%s' passive description is too short to say anything: '%s'"
				% [cls, pas.get("d", "")])


## `_PART_LABEL` shipped with keys "ear"/"eye" while every hero die in `ContentDB` says
## "ears"/"eyes". Nothing complained: the die card's lookup falls back to `part.to_upper()` and
## produced the right word by accident, so the table's two dead entries went unnoticed until the
## inspector — which used an empty fallback — silently dropped the label off every mana face.
##
## Checked against the DATA rather than against a hand-written list, so adding a body part to a
## hero die without labelling it fails here.
func test_every_body_part_the_data_uses_has_a_label() -> void:
	var seen: Dictionary = {}
	for key in ContentDB.heroes.keys():
		for f in (ContentDB.heroes[key] as Dictionary).get("die", []):
			var part := String((f as Dictionary).get("part", ""))
			if part != "" and part != "blank":
				seen[part] = true
	_assert(seen.size() >= 6,
		"expected at least 6 distinct body parts across the hero dice, found %d" % seen.size())
	for part in seen.keys():
		_assert(CombatView._PART_LABEL.has(String(part)),
			"hero dice use the body part '%s' but _PART_LABEL has no entry for it — the "
				% part + "inspector shows no part name, and the die card only looks right "
			+ "because its fallback upper-cases the raw key")


func test_clicking_an_enemy_with_no_die_selected_opens_the_inspector() -> void:
	_view._selected_die_uid = -1
	var enemy: Unit = _view._combat.alive_enemies()[0]
	_view._on_target_clicked(enemy.uid)

	_assert(_view._inspect_panel != null and is_instance_valid(_view._inspect_panel),
		"clicking an enemy with no die selected did not open the inspector — that click used "
		+ "to do nothing at all, which is the gap this closes")
	var text := _panel_text()
	_assert(text.find(enemy.n.to_upper()) != -1,
		"the panel does not name the unit it was opened for ('%s'); it shows:\\n%s"
			% [enemy.n, text])
	_assert(text.find("ALL SIX FACES") != -1,
		"the panel has no face section — the whole point is reading the enemy's die")
	_view._close_unit_inspect()


## The values shown must be what the face is worth NOW. A face with growth on it, or on a
## weakened or blinded unit, is not worth its printed number, and a panel consulted mid-fight
## that showed the base value would mislead at exactly the moment it is trusted.
func test_the_panel_lists_all_six_faces_with_live_values() -> void:
	var enemy: Unit = _view._combat.alive_enemies()[0]
	_assert(enemy.die.size() == 6, "enemy die has %d faces, expected 6" % enemy.die.size())

	# Arrange — put growth on one face so the live value and the printed value differ.
	var target_face := -1
	for i in enemy.die.size():
		if int((enemy.die[i] as Dictionary).get("value", 0)) > 0:
			target_face = i
			break
	_assert(target_face >= 0, "no enemy face carries a value, so this test proved nothing")
	if target_face < 0:
		return
	enemy.growth[target_face] = 5
	var base_value := int((enemy.die[target_face] as Dictionary).get("value", 0))
	var live_value: int = _view._combat._face_value(enemy, target_face)
	_assert(live_value == base_value + 5,
		"growth is not reaching _face_value(): base %d + 5 growth should be %d, engine says %d"
			% [base_value, base_value + 5, live_value])

	_view._selected_die_uid = -1
	_view._on_target_clicked(enemy.uid)
	var text := _panel_text()
	_assert(text.find(str(live_value)) != -1,
		"the panel does not show the live value %d for the grown face; it shows:\\n%s"
			% [live_value, text])
	_assert(_count_face_rows() == 6,
		"the panel rendered %d face rows, expected 6" % _count_face_rows())
	_view._close_unit_inspect()
	enemy.growth.erase(target_face)


## Face rows are the HBoxContainers under the panel that carry a type icon.
func _count_face_rows() -> int:
	if _view._inspect_panel == null:
		return 0
	# CB-30 sizes the inspector's face row as "a 32px part tile" holding a 22px icon. This used
	# to look for a 20x20 TextureRect, which was the pre-v2 size — the rows were all there and
	# the gate reported zero of them.
	var rows := 0
	var stack: Array = [_view._inspect_panel]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is HBoxContainer:
			for c in n.get_children():
				if _is_face_part_tile(c):
					rows += 1
					break
		for c in n.get_children():
			stack.append(c)
	return rows


## The 32px part tile of a CB-30 face row: a PanelContainer that size, carrying a 22px icon.
func _is_face_part_tile(n: Node) -> bool:
	var panel := n as PanelContainer
	if panel == null or panel.custom_minimum_size != Vector2(32, 32):
		return false
	for c in panel.find_children("*", "TextureRect", true, false):
		if (c as TextureRect).custom_minimum_size == Vector2(22, 22):
			return true
	return false


## THE ONE THAT MATTERS. The inspector rides the same handler as targeting, reached from both
## the 3D model and the nameplate. If it swallowed a click meant to attack, the game would feel
## broken in the middle of a fight and the panel would look like the culprit only afterwards.
func test_selecting_a_die_then_clicking_an_enemy_still_attacks() -> void:
	_view._close_unit_inspect()
	# Arrange — a party member that has rolled and not yet acted.
	var attacker: Unit = null
	for u in _view._combat.alive_party():
		if u.has_rolled() and not u.roll_used():
			attacker = u
			break
	_assert(attacker != null, "no party member is holding an unused roll, so this proved nothing")
	if attacker == null:
		return
	var enemy: Unit = _view._combat.alive_enemies()[0]
	var hp_before := enemy.hp
	var shield_before := enemy.shield

	# Act — exactly what a player does: pick the die, then click the enemy.
	_view._selected_die_uid = attacker.uid
	_view._on_target_clicked(enemy.uid)

	# Assert
	_assert(_view._inspect_panel == null,
		"clicking an enemy WITH a die selected opened the inspector instead of attacking — "
		+ "the inspector is eating targeting clicks")
	_assert(attacker.roll_used() or enemy.hp != hp_before or enemy.shield != shield_before,
		"the attack did not resolve: attacker still unused and the enemy is untouched "
		+ "(hp %d->%d, shield %d->%d)" % [hp_before, enemy.hp, shield_before, enemy.shield])


func test_the_inspector_closes_and_leaves_nothing_behind() -> void:
	_view._selected_die_uid = -1
	var enemy: Unit = _view._combat.alive_enemies()[0]
	_view._on_target_clicked(enemy.uid)
	_assert(_view._inspect_panel != null, "the inspector did not open for the close test")
	var layers_open := _count_inspect_layers()

	_view._close_unit_inspect()
	_assert(_view._inspect_panel == null, "_close_unit_inspect() left the reference set")

	# Re-opening must not stack a second copy: the panel is rebuilt every time, and a leaked
	# CanvasLayer would keep swallowing clicks behind the visible one.
	_view._on_target_clicked(enemy.uid)
	_view._on_target_clicked(enemy.uid)
	_assert(_count_inspect_layers() <= layers_open,
		"opening the inspector repeatedly leaked layers (%d now, %d after the first open) — "
			% [_count_inspect_layers(), layers_open]
		+ "each one keeps a full-screen click blocker alive")
	_view._close_unit_inspect()


func _count_inspect_layers() -> int:
	var n := 0
	for c in _view.get_children():
		if c is CanvasLayer and (c as CanvasLayer).layer == 28:
			n += 1
	return n
