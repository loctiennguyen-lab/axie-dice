extends BoTestBase
## Gacha guards (QA TF): the four rules that keep the "gacha vui" pack honest.
##  1. combo reroll: sell + rebuild gives nothing; Pair -> Full gives nothing; cap 2 per run.
##  2. whole-run replay (RunVerifier) reproduces combo_done / core_rerolls; a log edited to grant a reroll is refused or differs.
##  3. Copycat: a copied die is outside the Set (_bo_dice), preview (recompute_bo) and Overcast agree.
##  4. first-run offers carry no meme Core and equal the offer built from the pool without memes; <= 1 meme per offer from run 2.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const SEEDS_COMBO := 60


func run() -> void:
	_name = "t_gacha_guards"
	_g1_sell_rebuild_cap()
	_g2_replay()
	_g3_copycat()
	_g4_first_run_offer()


func _start(seed_v: int) -> void:
	RunState.reset()
	RunState.start_new_run_seeded(seed_v, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {},
		"loadout": {"rules_on": false}})
	RunState.owned_relic_ids = []


func _g1_sell_rebuild_cap() -> void:
	_start(5)
	var r0 := RunState.core_reroll_left
	RunState._grant_relic("c_living_wall", "core")
	RunState._grant_relic("c_thorn_shield", "core")
	eq(RunState.core_reroll_left, r0 + 1, "G1: first Pair gives +1 reroll")
	ok(RunState.sell_relic("c_thorn_shield"), "G1: sold a Pair member")
	RunState._grant_relic("c_thorn_shield", "core")
	eq(RunState.core_reroll_left, r0 + 1, "G1: selling then rebuilding the same Pair gives no 2nd reroll")
	eq(RunState.combo_rerolls_gained, 1, "G1: counter stays 1 after rebuild")
	RunState._grant_relic("c_gatekeeper", "core")
	eq(String(RunState.combo_done.get("combo_turtle_fort", "")), "full", "G1: upgraded to Full")
	eq(RunState.core_reroll_left, r0 + 1, "G1: Pair -> Full gives no reroll")
	ok(RunState.sell_relic("c_gatekeeper"), "G1: sold the Full card")
	RunState._grant_relic("c_gatekeeper", "core")
	eq(RunState.core_reroll_left, r0 + 1, "G1: rebuilding Full gives no reroll")
	# cap 2: a 2nd and 3rd distinct combo
	RunState._grant_relic("c_nest", "core")
	RunState._grant_relic("c_golden_egg", "core")
	eq(RunState.combo_rerolls_gained, 2, "G1: 2nd combo gives the 2nd reroll")
	RunState.sell_relic("c_nest")
	RunState._grant_relic("c_overflow", "core")
	RunState._grant_relic("c_tidecaller", "core")
	ok(RunState.combo_done.has("combo_rising_tide"), "G1: 3rd combo recorded")
	eq(RunState.core_reroll_left, r0 + 2, "G1: cap 2 per run, 3rd combo gives nothing")
	RunState.reset()


func _clone(source: ActionLog) -> ActionLog:
	return ActionLog.from_data(JSON.parse_string(JSON.stringify(source.to_data())))


func _g2_replay() -> void:
	RunBot.combo_script = true
	var found := {}
	for s in SEEDS_COMBO:
		var r := RunBot.play_run(7000 + s, TEAM)
		if not (r["state"] as Dictionary).is_empty() and not RunState.combo_done.is_empty() and RunState.combo_rerolls_gained >= 1:
			found = {"log": _clone(r["log"]), "tape": (r["tape"] as Array).duplicate(true), "score": r["score"], "state": JSON.parse_string(JSON.stringify(r["state"])),
				"done": RunState.combo_done.duplicate(), "gained": RunState.combo_rerolls_gained, "left": RunState.core_reroll_left}
			break
	RunBot.combo_script = false
	ok(not found.is_empty(), "G2: found a bot run that formed a combo through real take_reward")
	if found.is_empty():
		return
	var log: ActionLog = found["log"]
	var tape: Array = found["tape"]
	var v := RunVerifier.verify(log, tape)
	ok(bool(v["ok"]), "G2: honest combo run verifies (%s %s)" % [str(v["error"]), str(v["message"])])
	eq(int(v["score"]), int(found["score"]), "G2: referee score = played score")
	var st: Dictionary = v["state"]
	var cr: Dictionary = (st.get("core", {}) as Dictionary)
	var pc: Dictionary = ((found["state"] as Dictionary).get("core", {}) as Dictionary)
	eq(JSON.stringify(cr.get("combo_done")), JSON.stringify(pc.get("combo_done")), "G2: replayed combo_done identical")
	eq(int(cr.get("combo_rerolls", -1)), int(pc.get("combo_rerolls", -2)), "G2: replayed combo_rerolls identical")
	eq(int(cr.get("reroll_left", -1)), int(pc.get("reroll_left", -2)), "G2: replayed core_rerolls (reroll_left) identical")
	ok(not (cr.get("combo_done", {}) as Dictionary).is_empty(), "G2: replayed state holds a combo")
	eq(int(cr.get("combo_rerolls", -1)), mini(RelicSlots.tuning().combo_reroll_cap, (cr.get("combo_done", {}) as Dictionary).size()), "G2: replayed combo_rerolls = formations capped (no hand-added reroll)")
	# tamper A: an extra reroll granted by hand: log gets a reroll_pending_rewards that was never earned (before the first take_reward)
	var extra := 0
	var caught := 0
	for i in log.entries.size():
		if String((log.entries[i] as Dictionary)["fn"]) == "take_reward":
			extra += 1
			var t := _clone(log)
			t.entries.insert(i, {"fn": "reroll_pending_rewards", "args": [-1, 0]})
			var r2 := RunVerifier.verify(t, tape)
			if not bool(r2["ok"]) or JSON.stringify((r2["state"] as Dictionary).get("core")) != JSON.stringify(cr):
				caught += 1
			if extra >= 12:
				break
	ok(extra > 0 and caught == extra, "G2: a self-granted reroll is refused or changes the run (%d of %d)" % [caught, extra])
	# tamper B: the sold/kept Core order edited so a combo is skipped: dropping every take_reward after the first changes the state
	var u := _clone(log)
	var dropped := false
	for i in range(u.entries.size() - 1, -1, -1):
		if String((u.entries[i] as Dictionary)["fn"]) == "take_reward":
			u.entries.remove_at(i)
			dropped = true
			break
	var r3 := RunVerifier.verify(u, tape)
	ok(dropped and (not bool(r3["ok"]) or JSON.stringify((r3["state"] as Dictionary).get("core")) != JSON.stringify(cr)), "G2: removing a take_reward is detected")


## Copycat: copied die is outside _bo_dice / Set groups; the preview and an Overcast on it agree (refused: not counted).
func _g3_copycat() -> void:
	var c := BoTestBase.engine(["c_meme_copycat"], 9)
	BoTestBase.force(c, [0, 0, 0, 1, 2])
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": []})
	var copied: Unit = null
	for u in c.party:
		if int(u.custom_state.get("copycat_turn", -1)) == c.turn:
			copied = u
	ok(copied != null, "G3: Copycat copied a die")
	if copied == null:
		return
	ok(not c._bo_dice().has(copied), "G3: copied die is not in _bo_dice")
	var groups := c.recompute_bo()
	ok(groups.size() == 1 and int(groups[0]["size"]) == 3 and not (groups[0]["uids"] as Array).has(copied.uid), "G3: preview Set stays 3 without the copied die")
	eq(c.wild_block_reason(copied.uid, 1), "not_counted", "G3: a Wild Face on the copied die is refused as not_counted")
	ok(not c.can_overcast(copied.uid), "G3: Overcast on the copied die is refused")
	var member: Unit = null
	for u in c.party:
		if (groups[0]["uids"] as Array).has(u.uid):
			member = u
	ok(c.can_overcast(member.uid), "G3: Overcast on a real Set member is allowed (control)")
	# next turn the flag is stale: the die counts again
	c.turn += 1
	ok(c._bo_dice().has(copied), "G3: the next turn the copied die counts again")


func _first_offers(first_run: bool, seeds: int) -> Array:
	var out: Array = []
	for sd in seeds:
		out.append(CoreOffer.build_offer(Rng.new(sd), 0, CoreTestUtil.ctx([], [], TEAM, 1, first_run), 3))
	return out


func _g4_first_run_offer() -> void:
	# memes filtered out by hand from the SAME ctx: pool without memes must equal what the first run offers, i.e. meme defs are
	# inert in first_run. Control: first_run offers with all meme defs disabled are identical to those with memes enabled.
	var memes := ["c_meme_copycat", "c_meme_nametag", "c_meme_jumpy"]
	var first := _first_offers(true, 120)
	var was := {}
	for id in memes:
		var d = RelicRegistry.get_def(id)
		was[id] = d.disabled
		d.disabled = true
	var nomeme := _first_offers(true, 120)
	for id in memes:
		RelicRegistry.get_def(id).disabled = bool(was[id])
	var diff := 0
	for i in first.size():
		if _keys(first[i]) != _keys(nomeme[i]):
			diff += 1
	eq(diff, 0, "G4: first-run offers equal the pre-meme pool (memes disabled) for 120 seeds")
	var live_first := 0
	for o in first:
		for card in o:
			if memes.has(String(card["key"])):
				live_first += 1
	eq(live_first, 0, "G4: no meme card in any first-run offer")
	# from run 2: at most 1 meme per offer, over every tier and a bonus offer too
	var worst := 0
	var seen := 0
	for tier in 3:
		for sd in 150:
			var o := CoreOffer.build_offer(Rng.new(sd), tier, CoreTestUtil.ctx([], [], TEAM, 1, false), 3)
			var n := 0
			for card in o:
				if memes.has(String(card["key"])):
					n += 1
			worst = maxi(worst, n)
			seen += n
	ok(worst <= 1, "G4: at most 1 meme per offer from run 2 (worst %d)" % worst)
	ok(seen > 0, "G4: memes do appear from run 2 (%d)" % seen)


func _keys(o: Array) -> Array:
	var k: Array = []
	for c in o:
		k.append(String(c["key"]))
	return k
