extends Node
## Gate for the run's EVENT nodes.
##
## The invariant: every option the game OFFERS must actually DO something.
##
## This exists because of a specific near-miss. The content pass added `casino` and `mutant`
## to ContentDB.events, which immediately made them reachable at a real event node — but six
## of their fourteen `fx` values had no handler in RunState.apply_event_effect(). The result
## was not a crash and not an error: the player read "40%: a Mythic face", clicked it, and
## nothing whatsoever happened. Silent no-ops are worse than missing content, because they are
## indistinguishable from a bug at play time and invisible at review time.
##
## So this test asserts the CONTRACT between the two files rather than any single effect:
## whatever is offerable must be handled. It fails the moment someone adds event data without
## the matching effect, or removes an effect that data still points at.
##
## Run: godot --headless --path godot res://tests/t_event_effects.tscn

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_event_effects: start ===")
	test_every_offerable_option_has_an_effect()
	test_unported_options_are_filtered_out_of_the_offer()
	test_offered_events_are_a_real_choice()
	test_event_pool_order_is_deterministic()
	test_bet_small_both_outcomes_are_reachable_and_real()
	test_shards30_grants_shards()

	print("=== t_event_effects: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_event_effects: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_event_effects: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _fresh_run(seed_value: int = 4242) -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(seed_value, team, "short", 0, false)


# ---------------------------------------------------------------------------

func test_every_offerable_option_has_an_effect() -> void:
	# Arrange
	_fresh_run()

	# Act / Assert — an unhandled fx returns "" (and push_error's). A handled one always
	# returns the player-facing result line JS shows before eventDone().
	for key in ContentDB.playable_event_keys():
		for opt in ContentDB.playable_event_options(String(key)):
			var fx := String((opt as Dictionary).get("fx", ""))
			_assert(fx != "",
				"event '%s' offers an option with no fx at all: %s" % [key, opt])
			var msg := RunState.apply_event_effect(fx, Rng.new(7))
			_assert(msg != "",
				"event '%s' offers '%s' (fx '%s') but RunState.apply_event_effect() has no "
					% [key, (opt as Dictionary).get("text", "?"), fx]
				+ "handler for it — the player would pick this and nothing would happen")


func test_unported_options_are_filtered_out_of_the_offer() -> void:
	# Arrange — options whose JS effect needs the unported FACE_POOL are tagged
	# `needs_face_pool` in ContentDB and must never reach the player.
	var tagged_found := 0

	# Act / Assert
	for key in ContentDB.events.keys():
		for opt in ((ContentDB.events[key] as Dictionary).get("opts", []) as Array):
			if bool((opt as Dictionary).get("needs_face_pool", false)):
				tagged_found += 1
				var offered := false
				for playable in ContentDB.playable_event_options(String(key)):
					if playable == opt:
						offered = true
				_assert(not offered,
					"event '%s' option '%s' needs the unported FACE_POOL but is still being "
						% [key, (opt as Dictionary).get("text", "?")]
					+ "offered to the player")
	_assert(tagged_found > 0,
		"no option is tagged `needs_face_pool`, so this filter is unverified — if FACE_POOL "
		+ "has landed, delete the filter and this check rather than leaving both inert")


func test_offered_events_are_a_real_choice() -> void:
	# Arrange / Act / Assert — an event reduced to a single playable option is not a decision;
	# it should be dropped from the pool rather than shown as a one-button screen.
	var keys := ContentDB.playable_event_keys()
	_assert(not keys.is_empty(), "no event is offerable at all — event nodes would dead-end")
	for key in keys:
		var n := ContentDB.playable_event_options(String(key)).size()
		_assert(n >= 2, "event '%s' is offered with only %d playable option(s)" % [key, n])


func test_event_pool_order_is_deterministic() -> void:
	# Arrange — the pool is derived from a Dictionary's keys, whose iteration order must never
	# leak into a seeded run. Two calls must agree, and the order must be sorted.
	var a := ContentDB.playable_event_keys()
	var b := ContentDB.playable_event_keys()
	var sorted_copy := a.duplicate()
	sorted_copy.sort()

	# Assert
	_assert(a == b, "playable_event_keys() returned different orders on two calls: %s vs %s" % [a, b])
	_assert(a == sorted_copy, "playable_event_keys() is not sorted: %s" % [a])


func test_bet_small_both_outcomes_are_reachable_and_real() -> void:
	# Arrange — src/engine.js:1217-1218. A 50/50: an Epic+ relic, or the party pays 10% Max HP.
	var wins := 0
	var losses := 0

	# Act
	for i in 40:
		_fresh_run(1000 + i)
		var hp_before: int = int(RunState.roster[0].get("bonus_hp", 0))
		var relics_before: int = RunState.owned_relic_ids.size()
		var msg := RunState.apply_event_effect("bet_small", Rng.new(i * 31 + 5))
		_assert(msg != "", "bet_small returned no result message at iteration %d" % i)
		if msg.begins_with("YOU WIN"):
			wins += 1
			_assert(RunState.owned_relic_ids.size() > relics_before,
				"bet_small reported a WIN but granted no relic (iteration %d)" % i)
		else:
			losses += 1
			_assert(int(RunState.roster[0].get("bonus_hp", 0)) < hp_before,
				"bet_small reported a LOSS but the party's Max HP did not drop (iteration %d)" % i)

	# Assert — a coin flip that only ever lands one way is a broken coin flip.
	_assert(wins > 0 and losses > 0,
		"bet_small produced %d wins and %d losses over 40 draws — both outcomes must be "
			% [wins, losses]
		+ "reachable")


func test_shards30_grants_shards() -> void:
	# Arrange
	_fresh_run()
	var before := RunState.shards_this_run

	# Act
	var msg := RunState.apply_event_effect("shards30", Rng.new(1))

	# Assert
	_assert(RunState.shards_this_run == before + 30,
		"shards30 should grant exactly 30 Gene Shard, went %d -> %d" % [before, RunState.shards_this_run])
	_assert(msg != "", "shards30 returned no result message")
