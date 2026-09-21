extends Node
## Every number the player reads off a face must be the number the engine will actually
## produce. Reported 2026-09-21: an Axie's die card said 3, its own inspector said 4, and the
## attack landed for 4.
##
## THE SPLIT THAT CAUSED IT. `u.die[fi].value` is a face's PRINTED value. What happens is
## `CombatEngine._face_value()`, which folds growth, vital-at-full-HP, blind, weaken, boss
## overdrive, the Aqua CONDUIT passive and the hiveMind relic on top of it. The unit inspector
## called that function. The die card, the two damage previews, the enemy intent badge, the
## in-combat Info panel and the tutorial's own labels all read the printed number instead — so
## the moment anything modified a face, the screen disagreed with itself and with the fight.
##
## This test does not check that the six call sites call one function; it checks the property
## that matters and would survive a rewrite: WHAT IS SHOWN IS WHAT IS DEALT.
##
## Run: godot --headless --path godot res://tests/t_face_value_display.tscn

## SAVE GUARD. Real combat writes: CombatView._ready() ends with _save_run_progress(). See
## save_guard.gd's header for the measurement that made borrowing the file a rule here.
var _guard := SaveGuard.new()

var _view: Node2D
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	var tree := get_tree()
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	print("=== t_face_value_display: start ===")

	RunState.pending_combat = {
		"node_id": "facevalue_node", "kind": "battle", "pw": 3, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": 777001,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	await tree.process_frame
	await tree.process_frame

	test_a_grown_die_card_shows_what_the_attack_actually_deals()
	test_a_weakened_enemys_intent_badge_shows_what_it_will_really_hit_for()

	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("=== t_face_value_display: %d checks, 0 failure(s) ===" % _checks)
		print("t_face_value_display: PASS — %d checks OK" % _checks)
		tree.quit(0)
	else:
		for f in _fails:
			print("t_face_value_display: FAIL — %s" % f)
		tree.quit(1)


## THE reported case, end to end. Grow a party member's rolled attack face, then read the
## number off the CARD — the thing the player actually looks at — and spend the die at an
## enemy. The HP that leaves the enemy must be the number the card showed.
func test_a_grown_die_card_shows_what_the_attack_actually_deals() -> void:
	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	var units: Array = _view.call("_party_dice_units")
	var slot := -1
	var attacker: Unit = null
	for i in units.size():
		var u: Unit = units[i]
		if u.hp <= 0 or not u.has_rolled() or u.roll_used():
			continue
		if String((u.die[u.roll_face_index()] as Dictionary).get("type", "")) == "dmg":
			slot = i
			attacker = u
			break
	_check(attacker != null, "no party member rolled an attack face — pick another seed")
	if attacker == null:
		return

	var fi := attacker.roll_face_index()
	var printed := int((attacker.die[fi] as Dictionary).get("value", 0))
	attacker.add_growth(fi, 3)          # what GROWTH, BLOOMSCALE and the evolve archetype do
	attacker.set_crit_now(false)        # crit is an RNG roll and deliberately not in the number
	var live: int = combat._face_value(attacker, fi)
	_check(live == printed + 3,
		"the fixture did not actually modify the face: printed %d, live %d" % [printed, live])

	_view.call("_rebuild_all")

	var content: Dictionary = (_view.get("_die_slot_content") as Array)[slot]
	var shown := int(String((content["value_label"] as Label).text))
	_check(shown == live,
		"the die card reads %d but this face is worth %d — the card is showing the PRINTED "
		% [shown, live] + "value again (printed is %d)" % printed)

	# And now spend it. A clean target: no shield, no vulnerable, nothing to explain a gap.
	var target: Unit = combat.alive_enemies()[0]
	target.shield = 0
	target.status.clear()
	target.max_hp = maxi(target.max_hp, live + 20)
	target.hp = target.max_hp
	var before := target.hp
	var ok: bool = combat.use_die(attacker.uid, target.uid)
	_check(ok, "use_die() refused a legal attack")
	var dealt := before - target.hp
	_check(dealt == shown,
		"the card showed %d and the attack dealt %d — this is the bug the file is named for"
		% [shown, dealt])
	_done("test_a_grown_die_card_shows_what_the_attack_actually_deals")


## The enemy telegraph. Rule spec §2 is "minh bạch triệt để" — the badge is a promise — and
## _incoming_damage_for() next to it already computed the at-risk slice the honest way, so a
## modified enemy put two different numbers about the same blow on the same screen.
func test_a_weakened_enemys_intent_badge_shows_what_it_will_really_hit_for() -> void:
	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	var enemy: Unit = null
	for e in combat.alive_enemies():
		if e.intent.is_empty():
			continue
		var fi := int(e.intent.get("face_index", -1))
		if fi >= 0 and fi < e.die.size() \
				and String((e.die[fi] as Dictionary).get("type", "")) == "dmg":
			enemy = e
			break
	if enemy == null:
		_check(true, "no enemy telegraphed an attack this seed — nothing to check")
		return

	var fi := int(enemy.intent.get("face_index", -1))
	enemy.status["weaken"] = 1          # a status the enemy side really can get
	var live: int = combat._face_value(enemy, fi)
	_view.call("_rebuild_all")

	var huds: Dictionary = _view.get("_head_huds") as Dictionary
	var hud = huds.get(enemy.uid)
	_check(hud != null, "enemy uid=%d has no intent HUD" % enemy.uid)
	if hud == null:
		return
	var badge: Label = hud.get("_intent_number")
	var shown := int(String(badge.text)) if badge.text != "" else 0
	_check(shown == live,
		"the intent badge promises %d but weaken makes this blow %d — the badge is reading "
		% [shown, live] + "the printed value while the target's own at-risk slice is not")
	_done("test_a_weakened_enemys_intent_badge_shows_what_it_will_really_hit_for")


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


func _done(name: String) -> void:
	if _fails.is_empty():
		print("  ok — %s" % name)
