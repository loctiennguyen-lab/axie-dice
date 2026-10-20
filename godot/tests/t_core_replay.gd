extends Node
## Depth v3 lane B: a whole run with REAL Core flow (Run Rule offer, Core picks, per-card reroll, a sold Core, a
## shop/event Core pick) is rebuilt by RunVerifier from the tape, and a pick that is not in the offer is refused.
## Sample Cores come from CoreTestUtil.enable(); slots are cut to 2 so the bot is forced to sell.
var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _clone(src: ActionLog) -> ActionLog:
	return ActionLog.from_data(JSON.parse_string(JSON.stringify(src.to_data())))


func _count(log: ActionLog, fn: String, nargs: int = -1) -> int:
	var n := 0
	for e in log.entries:
		if String(e["fn"]) == fn and (nargs < 0 or (e["args"] as Array).size() == nargs):
			n += 1
	return n


func _ready() -> void:
	CoreTestUtil.enable()
	var t := RelicSlots.tuning()
	var old_slots := t.core_slots
	t.core_slots = 2
	MetaState.runs = 1   # not the account's first run: Run Rule offer is on
	RunBot.core_script = true
	var played: Dictionary = {}
	var sd_used := 0
	for sd in [991237, 991238, 4242, 7001, 12345, 5150, 8080, 3141]:
		played = RunBot.play_run(sd, TEAM)
		sd_used = sd
		var l: ActionLog = played["log"]
		if _count(l, "take_reward", 2) > 0 and _count(l, "reroll_rewards", 1) > 0:
			break
	RunBot.core_script = false
	t.core_slots = old_slots
	var log: ActionLog = played["log"]
	_assert(log.is_complete(), "log complete (rejected=%s)" % str(log.rejected))
	_assert(_count(log, "take_reward", 2) > 0, "a Core was sold (take_reward with sell id), seed %d" % sd_used)
	_assert(_count(log, "reroll_rewards", 1) > 0, "a Core card was rerolled")
	t.core_slots = 2
	var verdict := RunVerifier.verify(log, played["tape"])
	_assert(bool(verdict["ok"]), "referee accepts the Core run: %s %s" % [str(verdict["error"]), str(verdict["message"])])
	if bool(verdict["ok"]):
		_assert(int(verdict["score"]) == int(played["score"]), "same score")
		var a: Dictionary = played["state"]
		var b: Dictionary = verdict["state"]
		_assert(str(a.get("owned_relic_ids", a.get("relics"))) == str(b.get("owned_relic_ids", b.get("relics"))), "same owned Cores")
		_assert(JSON.stringify(a.get("core", {})) == JSON.stringify(b.get("core", {})), "same Core state (tier chain, seen, quest, rule)")
	# Tamper 1: a card index outside the offer is refused.
	var idx := -1
	for i in log.entries.size():
		var e: Dictionary = log.entries[i]
		if String(e["fn"]) == "take_reward" and (e["args"] as Array).size() >= 1:
			idx = i
			break
	if idx >= 0:
		var tm := _clone(log)
		tm.entries[idx]["args"] = [9]
		var bad := RunVerifier.verify(tm, played["tape"])
		_assert(not bool(bad["ok"]), "take_reward of a card that is not in the offer is refused")
	# Tamper 2: selling a Core that is not owned is refused / changes the run.
	var si := -1
	for i in log.entries.size():
		var e2: Dictionary = log.entries[i]
		if String(e2["fn"]) == "take_reward" and (e2["args"] as Array).size() == 2:
			si = i
			break
	if si >= 0:
		var tm2 := _clone(log)
		tm2.entries[si]["args"] = [int(tm2.entries[si]["args"][0]), "c_test_not_owned"]
		var bad2 := RunVerifier.verify(tm2, played["tape"])
		_assert(not bool(bad2["ok"]), "selling a Core that is not owned is refused")
	t.core_slots = old_slots
	# Shop sells a Core pick (not a relic), and the money is in-run shards only.
	RunState.reset()
	RunState.start_new_run_seeded(11, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {}})
	var items := RewardGenerator.generate_shop_items(Rng.new(1), [], {}, 2, true)
	var kinds: Array = items.map(func(i): return String(i["kind"]))
	_assert(kinds.has("core") and not kinds.has("relic"), "shop sells a Core pick, no old relic: %s" % str(kinds))
	for k in ["core_reroll", "reroll_core"]:
		_assert(not kinds.has(k), "no Core reroll for sale")
	if _failures.is_empty():
		print("t_core_replay: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_core_replay: FAIL — %s" % f)
	get_tree().quit(1)
