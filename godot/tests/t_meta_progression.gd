extends Node
## Gate for the Lunacia Pass, the unlock ladder, and the meta bonuses they grant a run.
##
## THE ONE THAT MATTERS MOST
## -------------------------
## `test_a_ranked_run_gets_no_meta_bonus_at_all()`. Meta progression is local and never synced,
## so a ranked submission cannot be replayed by a server that does not know how many unlocks
## the player bought. If a single bonus leaks into a ranked run, every ranked score becomes a
## function of private local state — the board stops meaning anything, and nothing about it
## looks broken from the inside. JS zeroes all of them at `newRun()` (client.html:4669-4673)
## and so must this.
##
## THE OTHER SHAPE THIS GUARDS
## ---------------------------
## Content that is offered but inert. Five Lunacia Pass milestones award a `face`, and
## FACE_POOL is unported, so there is nothing to grant — those must be REFUSED and kept out of
## the claimable list, not marked claimed while granting nothing. The event system already made
## exactly that mistake once (an option the player picked that silently did nothing), and a
## burned pass milestone is worse: it cannot be re-earned.
##
## Run: godot --headless --path godot res://tests/t_meta_progression.tscn

var _failures: Array[String] = []
var _checks := 0

## Saved and restored around the whole file — these tests write to the real MetaState autoload.
var _backup: Dictionary = {}


## Borrows the player's real save file and puts it back byte for byte — this gate writes to the
## real `MetaState` autoload. See `save_guard.gd` for why a hand-written field list is not enough.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_meta_progression: start ===")
	_save_guard.capture()
	_backup = _snapshot_meta()

	test_the_xp_curve_matches_the_source()
	test_pass_levels_need_cumulative_xp()
	test_claiming_grants_exactly_once()
	test_face_rewards_are_refused_not_silently_burned()
	test_every_unlock_either_has_an_effect_or_is_declared_inert()
	test_every_pass_perk_actually_changes_a_run()
	test_buying_an_unlock_spends_shards_and_refuses_when_short()
	test_unlocks_and_perks_add_up_into_run_bonuses()
	test_a_ranked_run_gets_no_meta_bonus_at_all()
	test_run_xp_matches_the_source_formula()
	test_winning_at_your_ceiling_raises_ascension_by_one()

	# BOTH restores are needed, and neither replaces the other. `_restore_meta()` puts the
	# in-memory autoload back for anything later in this process; the guard puts the FILE back.
	# This gate was measured leaving the save file changed despite `_restore_meta()` — because the
	# tests call `save_to_disk()` (through `claim_bp_reward()`/`buy_unlock()`) long before the
	# in-memory restore runs.
	_restore_meta(_backup)
	_save_guard.restore()
	print("=== t_meta_progression: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_meta_progression: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_meta_progression: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _snapshot_meta() -> Dictionary:
	return {
		"shard_pool": MetaState.shard_pool, "xp": MetaState.xp,
		"unlocks": MetaState.unlocks.duplicate(), "bp_claimed": MetaState.bp_claimed.duplicate(),
		"perks": MetaState.perks.duplicate(true), "asc_max": MetaState.asc_max,
		"runs": MetaState.runs, "wins": MetaState.wins, "best": MetaState.best,
	}


func _restore_meta(d: Dictionary) -> void:
	MetaState.shard_pool = int(d["shard_pool"])
	MetaState.xp = int(d["xp"])
	MetaState.unlocks.assign(d["unlocks"])
	MetaState.bp_claimed.assign(d["bp_claimed"])
	MetaState.perks = (d["perks"] as Dictionary).duplicate(true)
	MetaState.asc_max = int(d["asc_max"])
	MetaState.runs = int(d["runs"])
	MetaState.wins = int(d["wins"])
	MetaState.best = int(d["best"])


## A blank slate for each test, so one test's purchases cannot make the next one pass.
func _wipe_meta() -> void:
	MetaState.shard_pool = 0
	MetaState.xp = 0
	MetaState.unlocks.clear()
	MetaState.bp_claimed.clear()
	MetaState.perks = {}
	MetaState.asc_max = 0
	MetaState.runs = 0
	MetaState.wins = 0
	MetaState.best = 0


# ---------------------------------------------------------------------------

## src/data.js: BP_XP = n => 45 + 22*(n-1)
func test_the_xp_curve_matches_the_source() -> void:
	for pair in [[1, 45], [2, 67], [10, 243], [30, 683]]:
		var n: int = pair[0]
		var want: int = pair[1]
		_assert(ContentDB.bp_xp_for_level(n) == want,
			"BP_XP(%d) is %d, src/data.js says %d" % [n, ContentDB.bp_xp_for_level(n), want])
	_assert(ContentDB.BP_TRACK.size() == 30,
		"the pass track has %d milestones, src/data.js has 30" % ContentDB.BP_TRACK.size())
	_assert(ContentDB.UNLOCKS.size() == 10,
		"the unlock ladder has %d entries, src/data.js has 10" % ContentDB.UNLOCKS.size())


## Levels are cumulative: reaching level 2 needs BP_XP(1)+BP_XP(2), not BP_XP(2).
func test_pass_levels_need_cumulative_xp() -> void:
	_wipe_meta()
	_assert(MetaState.bp_level() == 0, "0 XP should be level 0, got %d" % MetaState.bp_level())

	MetaState.xp = 45
	_assert(MetaState.bp_level() == 1, "45 XP should be exactly level 1")
	MetaState.xp = 44
	_assert(MetaState.bp_level() == 0, "44 XP is one short of level 1 and must still be level 0")
	MetaState.xp = 45 + 67
	_assert(MetaState.bp_level() == 2, "45+67 XP should be level 2, got %d" % MetaState.bp_level())
	MetaState.xp = 45 + 67 - 1
	_assert(MetaState.bp_level() == 1,
		"one XP short of level 2 must still be level 1, got %d" % MetaState.bp_level())

	# The progress readout must not divide by zero at the top of the track.
	var total := 0
	for i in range(1, ContentDB.BP_MAX_LEVEL + 1):
		total += ContentDB.bp_xp_for_level(i)
	MetaState.xp = total
	var prog: Dictionary = MetaState.bp_progress()
	_assert(int(prog["level"]) == ContentDB.BP_MAX_LEVEL,
		"full XP should be level %d, got %d" % [ContentDB.BP_MAX_LEVEL, int(prog["level"])])
	_assert(int(prog["needed"]) == 0, "max level should need 0 more XP")
	_assert(float(prog["percent"]) == 100.0, "max level should read 100%")


func test_claiming_grants_exactly_once() -> void:
	_wipe_meta()
	MetaState.xp = 45          # level 1: 120 shards
	_assert(MetaState.claim_bp_reward(1) == "", "level 1 should be claimable at 45 XP")
	_assert(MetaState.shard_pool == 120,
		"claiming level 1 should grant 120 shards, pool is %d" % MetaState.shard_pool)
	var again := MetaState.claim_bp_reward(1)
	_assert(again != "", "claiming level 1 twice was allowed")
	_assert(MetaState.shard_pool == 120,
		"the second claim granted shards anyway (pool %d)" % MetaState.shard_pool)
	_assert(MetaState.claim_bp_reward(2) != "", "level 2 was claimable without the XP for it")

	# An `unlock` milestone must actually put the id in unlocks, not just tick the level off.
	_wipe_meta()
	MetaState.xp = 999999
	_assert(MetaState.claim_bp_reward(3) == "", "level 3 (an unlock) should be claimable")
	_assert(MetaState.has_unlock("u_relic1"),
		"level 3 was claimed but u_relic1 was not granted")
	# And a `perk` milestone must stack.
	_assert(MetaState.claim_bp_reward(7) == "", "level 7 (a perk) should be claimable")
	_assert(int(MetaState.perks.get("reroll", 0)) == 1,
		"level 7 was claimed but the reroll perk did not stack")


## The heart of "offered but inert". A face milestone must be refused AND stay unclaimed, so it
## is still there when the mutation pool lands.
func test_face_rewards_are_refused_not_silently_burned() -> void:
	_wipe_meta()
	MetaState.xp = 999999
	var face_levels: Array = []
	for e in ContentDB.BP_TRACK:
		if String((e as Dictionary).get("type", "")) == "face":
			face_levels.append(int((e as Dictionary).get("lv", 0)))
	_assert(face_levels.size() == 5,
		"expected 5 face milestones on the track, found %d" % face_levels.size())

	for lv in face_levels:
		var err := MetaState.claim_bp_reward(int(lv))
		_assert(err != "", "face milestone %d was claimed, but there is no face to grant" % lv)
		_assert(not MetaState.bp_claimed.has(int(lv)),
			"face milestone %d was marked claimed despite granting nothing — it can never be "
				% lv + "collected again once the mutation pool lands")

	# They must also be kept out of the claimable list rather than shown with a dead button.
	for entry in MetaState.bp_unclaimed():
		_assert(String((entry as Dictionary).get("type", "")) != "face",
			"a face milestone is being offered as claimable")
	_assert(MetaState.bp_blocked().size() == 5,
		"all 5 face milestones should surface as blocked-with-a-reason, found %d"
			% MetaState.bp_blocked().size())


## Every unlock must change something, or be on the declared list of ones that cannot yet. The
## list is pinned so it can only grow deliberately — an unlock the player buys that does
## nothing is a shard sink that looks like a feature.
func test_every_unlock_either_has_an_effect_or_is_declared_inert() -> void:
	var with_effect := ["u_full", "u_reroll", "u_reroll2", "u_hp", "u_hp2", "u_start"]
	var declared_inert: Array = ContentDB.UNLOCKS_WITHOUT_EFFECT
	for u in ContentDB.UNLOCKS:
		var id := String((u as Dictionary).get("id", ""))
		_assert(with_effect.has(id) or declared_inert.has(id),
			"unlock '%s' is neither wired to an effect nor declared inert — it would be sold "
				% id + "and do nothing")
	_assert(declared_inert.size() == 4,
		"the inert-unlock list has %d entries; it was 4 when written, and growing it silently "
			% declared_inert.size() + "is how a shop fills with dead goods")


## The hole the unlock check above did not cover, and which shipped through it once: the pass
## also awards PERKS, and `rrw` (level 28, "reroll rewards twice per wave") was claimable while
## nothing anywhere read `perks.rrw`. An unlock that does nothing costs shards; a perk that does
## nothing costs a milestone that can never be re-earned.
##
## Checked by OUTCOME rather than by grepping for a call site: each perk is stacked on its own
## and `run_bonuses()` must come back different from a blank account. A perk whose plumbing is
## removed later fails here even if some unrelated code still mentions its name.
func test_every_pass_perk_actually_changes_a_run() -> void:
	var perk_keys: Dictionary = {}
	for e in ContentDB.BP_TRACK:
		if String((e as Dictionary).get("type", "")) == "perk":
			perk_keys[String((e as Dictionary).get("value", ""))] = true
	_assert(perk_keys.size() >= 4,
		"expected at least 4 distinct perks on the track, found %d" % perk_keys.size())

	_wipe_meta()
	var blank: Dictionary = MetaState.run_bonuses(false)
	for key in perk_keys.keys():
		_wipe_meta()
		MetaState.perks = {String(key): 1}
		var withp: Dictionary = MetaState.run_bonuses(false)
		var changed := false
		for field in blank.keys():
			if withp.get(field) != blank.get(field):
				changed = true
		_assert(changed,
			"pass perk '%s' changes nothing in run_bonuses() — claiming its milestone would "
				% key + "consume a reward that can never be earned again and grant nothing")

	# And ranked must still be untouched by every one of them.
	for key in perk_keys.keys():
		_wipe_meta()
		MetaState.perks = {String(key): 3}
		var ranked: Dictionary = MetaState.run_bonuses(true)
		_assert(ranked == MetaState.run_bonuses(true),
			"run_bonuses(true) is not stable for perk '%s'" % key)
		_assert(int(ranked.get("bonus_reroll", -1)) == 0
				and int(ranked.get("hp_bonus", -1)) == 0
				and int(ranked.get("start_relic_max_rarity", 0)) == -1
				and int(ranked.get("reward_reroll_max", -1)) == 1,
			"perk '%s' leaked into a ranked run: %s" % [key, str(ranked)])


func test_buying_an_unlock_spends_shards_and_refuses_when_short() -> void:
	_wipe_meta()
	MetaState.shard_pool = 100
	_assert(MetaState.buy_unlock("u_full") != "", "u_full was bought with 100 of 120 shards")
	_assert(MetaState.shard_pool == 100, "a refused purchase still took shards")
	_assert(not MetaState.has_unlock("u_full"), "a refused purchase still granted the unlock")

	MetaState.shard_pool = 120
	_assert(MetaState.buy_unlock("u_full") == "", "u_full was refused with exactly 120 shards")
	_assert(MetaState.shard_pool == 0, "u_full cost %d, expected 120" % (120 - MetaState.shard_pool))
	_assert(MetaState.has_unlock("u_full"), "u_full was paid for but not granted")
	_assert(MetaState.buy_unlock("u_full") != "", "u_full was bought twice")
	_assert(MetaState.buy_unlock("not_a_real_unlock") != "", "an unknown unlock id was accepted")


## src/client.html:4669-4673, term by term.
func test_unlocks_and_perks_add_up_into_run_bonuses() -> void:
	_wipe_meta()
	var none: Dictionary = MetaState.run_bonuses(false)
	_assert(int(none["bonus_reroll"]) == 0 and int(none["hp_bonus"]) == 0
			and int(none["start_relic_max_rarity"]) == -1,
		"a fresh account should get no run bonuses, got %s" % str(none))

	MetaState.unlocks.assign(["u_reroll", "u_reroll2", "u_hp", "u_hp2", "u_start"])
	MetaState.perks = {"reroll": 1, "hp4": 2}
	var full: Dictionary = MetaState.run_bonuses(false)
	_assert(int(full["bonus_reroll"]) == 3,
		"reroll: u_reroll(1) + u_reroll2(1) + perk(1) = 3, got %d" % int(full["bonus_reroll"]))
	_assert(int(full["hp_bonus"]) == 13,
		"hp: u_hp(3) + u_hp2(2) + 4*perk hp4(2) = 13, got %d" % int(full["hp_bonus"]))
	_assert(int(full["start_relic_max_rarity"]) == 0,
		"u_start alone grants a Common starting relic (rarity cap 0), got %d"
			% int(full["start_relic_max_rarity"]))

	MetaState.perks["relic1"] = 1
	_assert(int(MetaState.run_bonuses(false)["start_relic_max_rarity"]) == 1,
		"the relic1 perk should raise the starting relic's rarity cap to Rare")


## If this ever fails, stop and fix it before anything else — see the file header.
func test_a_ranked_run_gets_no_meta_bonus_at_all() -> void:
	_wipe_meta()
	MetaState.unlocks.assign(["u_reroll", "u_reroll2", "u_hp", "u_hp2", "u_start"])
	MetaState.perks = {"reroll": 3, "hp4": 5, "relic1": 1}

	var ranked: Dictionary = MetaState.run_bonuses(true)
	_assert(int(ranked["bonus_reroll"]) == 0,
		"a ranked run got %d bonus rerolls from local unlocks" % int(ranked["bonus_reroll"]))
	_assert(int(ranked["hp_bonus"]) == 0,
		"a ranked run got %d bonus Max HP from local unlocks" % int(ranked["hp_bonus"]))
	_assert(int(ranked["start_relic_max_rarity"]) == -1,
		"a ranked run was granted a starting relic from local unlocks")

	# And through the real entry point, not just the helper: a ranked run's roster and relics
	# must come out identical to a fresh account's.
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(4321, team, "short", 0, true)
	_assert(RunState.bonus_reroll == 0,
		"start_new_run(ranked) carried %d bonus reroll" % RunState.bonus_reroll)
	_assert(RunState.owned_relic_ids.is_empty(),
		"start_new_run(ranked) handed out a starting relic: %s" % str(RunState.owned_relic_ids))
	for entry in RunState.roster:
		_assert(int((entry as Dictionary).get("bonus_hp", 0)) == 0,
			"start_new_run(ranked) gave an Axie %d bonus Max HP"
				% int((entry as Dictionary).get("bonus_hp", 0)))

	# The same call unranked must show the bonuses, or this test would pass on a build where
	# run_bonuses() is simply never consulted.
	RunState.start_new_run(4321, team, "short", 0, false)
	_assert(RunState.bonus_reroll > 0,
		"an UNRANKED run with five unlocks got no bonus reroll — the ranked assertion above "
		+ "would then be passing for the wrong reason")


## src/data.js runXp(), term by term.
func test_run_xp_matches_the_source_formula() -> void:
	_wipe_meta()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(777, team, "short", 0, false)
	RunState.power_level = 10
	RunState.visited_node_ids.clear()

	# No elites or bosses visited: 30 + 10*10 + 0 + 0 + 150 + 0 + 0 = 280 on a win.
	_assert(RunState.compute_run_xp(true) == 280,
		"win at pw 10, no elites/bosses: expected 280 XP, got %d" % RunState.compute_run_xp(true))
	# A loss drops one step and the 150 win bonus: 30 + 10*9 = 120.
	_assert(RunState.compute_run_xp(false) == 120,
		"loss at pw 10: expected 120 XP, got %d" % RunState.compute_run_xp(false))

	# Ascension is +25 each.
	RunState.ascension = 4
	_assert(RunState.compute_run_xp(true) == 280 + 100,
		"A4 should add 100 XP, got %d" % RunState.compute_run_xp(true))
	RunState.ascension = 0

	# Full mode is +40.
	RunState.mode = "full"
	_assert(RunState.compute_run_xp(true) == 280 + 40,
		"full mode should add 40 XP, got %d" % RunState.compute_run_xp(true))
	RunState.mode = "short"

	# Elites are +30 and bosses +60, counted from the nodes actually visited.
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var elite_id := ""
	var boss_id := ""
	for row in graph.rows:
		for n in row:
			var node: RunMapNode = n
			if node.node_type == "elite" and elite_id == "":
				elite_id = node.id
			elif node.node_type == "boss" and boss_id == "":
				boss_id = node.id
	_assert(elite_id != "" and boss_id != "",
		"the generated map has no elite or boss node to count, so this check proved nothing")
	if elite_id != "" and boss_id != "":
		RunState.visited_node_ids.assign([elite_id, boss_id])
		_assert(RunState.compute_run_xp(true) == 280 + 30 + 60,
			"one elite (+30) and one boss (+60) should give 370, got %d"
				% RunState.compute_run_xp(true))


## src/client.html onRunEnd(): a win AT your ceiling raises it by one, capped at 10. A win
## below it changes nothing.
func test_winning_at_your_ceiling_raises_ascension_by_one() -> void:
	_wipe_meta()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

	RunState.start_new_run(11, team, "short", 0, false)
	RunState.end_run(true)
	_assert(MetaState.asc_max == 1,
		"winning at A0 with ceiling 0 should raise the ceiling to 1, got %d" % MetaState.asc_max)
	_assert(MetaState.wins == 1 and MetaState.runs == 1,
		"win/run counters did not both advance (wins %d, runs %d)" % [MetaState.wins, MetaState.runs])

	# A win BELOW the ceiling must not move it.
	MetaState.asc_max = 5
	RunState.start_new_run(12, team, "short", 2, false)
	RunState.end_run(true)
	_assert(MetaState.asc_max == 5,
		"winning at A2 with ceiling 5 moved the ceiling to %d" % MetaState.asc_max)

	# A loss never moves it.
	MetaState.asc_max = 5
	RunState.start_new_run(13, team, "short", 5, false)
	RunState.end_run(false)
	_assert(MetaState.asc_max == 5,
		"losing at A5 raised the ceiling to %d" % MetaState.asc_max)

	# The cap holds.
	MetaState.asc_max = 10
	RunState.start_new_run(14, team, "short", 10, false)
	RunState.end_run(true)
	_assert(MetaState.asc_max == 10,
		"winning at A10 pushed the ceiling past 10 (%d)" % MetaState.asc_max)
