extends Node
## Two reports, one file, because both are "the UI never let me at something the engine
## already supports".
##
## 1. RELIC ACTIVES COULD NOT BE CLICKED. CombatEngine.play_active() has always worked; the
##    tiles in the RELIC ACTIVES rack were built as PanelContainers with no `pressed` signal
##    and a comment saying "display only". Pinned here as: the tiles are Buttons, an
##    untargeted card resolves on the press, and a targeted one arms and waits.
##
## 2. A SUMMONED AXIE EGG HAD NO DIE SLOT. _party_dice_units() filtered on
##    `roster_index >= 0`; a token is not in RunState.roster so it carries the default -1,
##    and its die existed in the engine with no card on screen to spend it from.
##
## Run: godot --headless --path godot res://tests/t_actives_and_token_slot.tscn

## SAVE GUARD. Driving real combat writes: CombatView._ready() calls _save_run_progress().
var _guard := SaveGuard.new()

var _view: Node2D
var _combat: CombatEngine
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true
	print("=== t_actives_and_token_slot: start ===")
	_guard.capture()

	RunState.pending_combat = {
		"node_id": "t_act", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": 4242,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	await tree.process_frame
	await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine

	test_every_active_kind_declares_what_it_targets()
	await test_the_active_tiles_are_buttons_and_an_untargeted_card_fires(tree)
	await test_a_targeted_card_arms_and_waits_for_a_unit(tree)
	await test_a_summoned_token_gets_a_die_slot(tree)

	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("t_actives_and_token_slot: PASS — %d checks OK" % _checks)
		tree.quit(0)
	else:
		for f in _fails:
			print("  FAIL: %s" % f)
		print("t_actives_and_token_slot: FAIL — %d of %d" % [_fails.size(), _checks])
		tree.quit(1)


## RelicDef.act_target() has to agree with combat_engine's own `match`, or the UI offers a
## click the engine will refuse. Every `a_*` relic in the registry is checked, so a new
## active card cannot be added with a kind this table has never heard of.
func test_every_active_kind_declares_what_it_targets() -> void:
	var seen := {}
	var actives := 0
	for raw_def in RelicRegistry.all_defs_sorted():
		var def: RelicDef = raw_def
		var rid := String(def.id)
		if int(def.act_cost) <= 0:
			continue
		actives += 1
		var kind := String((def.act as Dictionary).get("kind", ""))
		seen[kind] = def.act_target()
		_check(def.act_target() in ["none", "ally", "enemy"],
			"%s: act_target() returned '%s'" % [rid, def.act_target()])
	_check(actives >= 10,
		"only %d active relics found; this check would pass vacuously" % actives)
	# The four the engine reads `tgt.side == "e"` for, and the one it reads "p" for.
	for k in ["dmg", "ult", "stun", "shatter"]:
		if seen.has(k):
			_check(seen[k] == "enemy", "kind '%s' should target an enemy, says '%s'"
				% [k, seen[k]])
	if seen.has("heal"):
		_check(seen["heal"] == "ally", "kind 'heal' should target an ally, says '%s'"
			% seen["heal"])


func test_the_active_tiles_are_buttons_and_an_untargeted_card_fires(tree: SceneTree) -> void:
	var rid := _find_active("none")
	if rid == "":
		_check(false, "no untargeted active relic in the registry to test with")
		return
	_combat.relic_ids = [rid]
	_combat.mana = 20
	_view.call("_rebuild_all")
	await tree.process_frame

	var tiles := _active_tiles()
	_check(tiles.size() >= 1, "the RELIC ACTIVES rack drew no tile for a held active")
	if tiles.is_empty():
		return
	_check(tiles[0] is Button,
		"the active tile is a %s, not a Button — it cannot be pressed"
		% tiles[0].get_class())

	var mana_before := _combat.mana
	_view.call("_on_active_pressed", rid)
	await tree.process_frame
	_check(_combat.mana < mana_before,
		"pressing an untargeted active spent no mana (%d -> %d): it did not fire"
		% [mana_before, _combat.mana])
	_check(String(_view.get("_selected_active_id")) == "",
		"an untargeted active should resolve on the press, not arm and wait")


func test_a_targeted_card_arms_and_waits_for_a_unit(tree: SceneTree) -> void:
	var rid := _find_active("enemy")
	if rid == "":
		_check(false, "no enemy-targeting active relic in the registry to test with")
		return
	_combat.relic_ids = [rid]
	_combat.mana = 20
	_view.call("_rebuild_all")
	await tree.process_frame

	var mana_before := _combat.mana
	_view.call("_on_active_pressed", rid)
	await tree.process_frame
	_check(String(_view.get("_selected_active_id")) == rid,
		"a targeted active did not arm; _selected_active_id is '%s'"
		% String(_view.get("_selected_active_id")))
	_check(_combat.mana == mana_before,
		"a targeted active spent mana before a target was picked")

	# Picking an ALLY for an enemy-only card must not spend anything.
	var ally: Unit = _combat.alive_party()[0]
	_view.call("_on_target_clicked", ally.uid)
	await tree.process_frame
	_check(_combat.mana == mana_before,
		"an enemy-only active fired at an ally and spent mana")

	# And the real target does.
	_combat.relic_ids = [rid]
	_view.call("_on_active_pressed", rid)
	await tree.process_frame
	var foe: Unit = _combat.alive_enemies()[0]
	_view.call("_on_target_clicked", foe.uid)
	await tree.process_frame
	_check(_combat.mana < mana_before,
		"a targeted active did not fire at a legal enemy (%d -> %d)"
		% [mana_before, _combat.mana])
	_check(String(_view.get("_selected_active_id")) == "",
		"the active stayed armed after firing")


## The egg. Counted by die SLOTS on screen, not by party size, because the party grew all
## along — what was missing was the card.
func test_a_summoned_token_gets_a_die_slot(tree: SceneTree) -> void:
	var before: int = int(_view.call("_party_dice_units").size())
	_check(before == 5, "expected the 5-hero roster in the tray, got %d" % before)
	var visible_before := _visible_slots()
	_check(visible_before == 5, "expected 5 visible die cards, got %d" % visible_before)

	var token: Unit = _combat._mk_ally()
	_combat._roll_unit(token)
	_combat.party.append(token)
	_check(token.roster_index < 0,
		"this test assumes a token carries no roster_index; it has %d" % token.roster_index)
	_view.call("_rebuild_all")
	await tree.process_frame

	var after: Array = _view.call("_party_dice_units")
	_check(after.size() == 6,
		"the summoned token is still missing from the tray list (%d entries)" % after.size())
	_check((after[after.size() - 1] as Unit).uid == token.uid,
		"the token should sit last so a summon never reorders the cards already on screen")
	_check(_visible_slots() == 6,
		"only %d die cards are visible; the token has no slot to roll into"
		% _visible_slots())


# ---------------------------------------------------------------------------

func _active_tiles() -> Array:
	var row: HBoxContainer = _view.get("_actives_row")
	var out: Array = []
	if row == null:
		return out
	for c in row.get_children():
		if c is Button:
			out.append(c)
	return out


func _visible_slots() -> int:
	var n := 0
	for b in (_view.get("_die_slot_buttons") as Array):
		if (b as Button).visible:
			n += 1
	return n


func _find_active(want_target: String) -> String:
	for raw_def in RelicRegistry.all_defs_sorted():
		var def: RelicDef = raw_def
		if int(def.act_cost) > 0 and int(def.act_cost) <= 8 \
				and def.act_target() == want_target:
			return String(def.id)
	return ""


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {},
			"bonus_hp": 0})
	return out


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
