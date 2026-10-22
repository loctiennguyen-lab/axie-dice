extends Node
## Anchor run state (lane AE 2a; production/anchor-contract.md, anchor-mvp-qa-plan.md #1-#3 #11 G6).

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

var _checks := 0
var _failures: Array[String] = []
var _chosen: Array[String] = []
var _awakened: Array[String] = []


func _assert(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_failures.append(msg)


func _start(seed: int, extra: Dictionary = {}, src: EpochSource = null) -> bool:
	var params := {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "anchor": true,
		"loadout": {"rules_on": false}}
	params.merge(extra, true)
	return RunState.start_run_with_epoch(src if src != null else LocalEpochSource.new(PackedByteArray(), seed), params, seed)


func _ready() -> void:
	EventBus.anchor_chosen.connect(func(id): _chosen.append(String(id)))
	EventBus.anchor_awakened.connect(func(id): _awakened.append(String(id)))

	# --- gate: normal offline run opens the offer, holds pick 1 ---
	_assert(_start(101), "run starts")
	_assert(RunState.anchor_gate_reason() == "", "gate open on a normal offline run: " + RunState.anchor_gate_reason())
	_assert(RunState.anchor_offer_open(), "offer open")
	_assert(RunState.anchor_offer.size() == 3, "3 ids offered")
	_assert(RunState.pending_rewards.is_empty() and RunState.phase == RunState.RunPhase.REWARD, "pick 1 held back: no Core offer yet")
	_assert(not RunState._core_offer_active and RunState.core_pick_index == 0, "no Core offer was built before the Anchor")
	var offer: Array = RunState.anchor_offer.duplicate()
	_assert(not RunState.pick_anchor("a_kin"), "disabled Anchor refused")
	var other := "a_nope"
	_assert(not RunState.pick_anchor(other), "unknown id refused")
	var pick := String(offer[0])
	_assert(RunState.pick_anchor(pick), "pick ok")
	_assert(RunState.anchor_id == pick and _chosen == [pick], "locked + anchor_chosen emitted once")
	_assert(not RunState.pick_anchor(String(offer[1])), "cannot pick twice")
	_assert(not RunState.anchor_offer_open(), "offer closed after pick")
	_assert(RunState._core_offer_active and RunState.pending_rewards.size() > 0, "Core offer 1 exists after the pick")
	# QA #11: the save written by pick_anchor already holds the Anchor
	var parsed = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	_assert(parsed is Dictionary and String(((parsed as Dictionary).get("run", {}) as Dictionary).get("anchor", {}).get("id", "")) == pick, "save file holds the Anchor")
	RunState.clear_saved_run()

	# --- same seed, same offer ---
	_start(101)
	_assert(RunState.anchor_offer == offer, "anchor_offer deterministic per seed")

	# --- save/load mid run ---
	RunState.pick_anchor(pick)
	RunState.anchor_awakened = true
	var data := RunState.to_data()
	RunState.reset()
	_assert(RunState.anchor_id == "", "reset clears anchor")
	RunState.from_data(JSON.parse_string(JSON.stringify(data)))
	_assert(RunState.anchor_id == pick and RunState.anchor_awakened and RunState.anchor_offer == offer, "save/load keeps id, flag, offer")
	RunState.clear_saved_run()

	# --- waiting state survives save/load, decline works ---
	_start(102)
	_assert(RunState._anchor_waiting, "waiting")
	var wd := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(wd)))
	_assert(RunState._anchor_waiting and RunState.anchor_offer.size() == 3, "waiting state restored")
	_assert(RunState.decline_anchor() and RunState.anchor_id == "" and RunState._core_offer_active, "decline opens pick 1 with no Anchor")
	_assert(not RunState.anchor_offer_open(), "no second offer after decline")
	RunState.clear_saved_run()

	# --- awaken: >= 2 house cores, latched, survives selling ---
	_chosen.clear()
	_awakened.clear()
	_start(103)
	var aid := String(RunState.anchor_offer[0])
	_assert(RunState.pick_anchor(aid), "pick for awaken test")
	var hc: Array = Anchors.get_def(aid)["house_cores"]
	RunState._grant_relic(String(hc[0]), "test")
	_assert(not RunState.anchor_awakened and _awakened.is_empty(), "1 house Core: not awake")
	RunState._grant_relic("c_test_not_house_x", "test")
	RunState._grant_relic(String(hc[1]), "test")
	_assert(RunState.anchor_awakened and _awakened == [aid], "2nd house Core awakens, signal once")
	RunState._grant_relic(String(hc[2]), "test")
	_assert(_awakened == [aid], "3rd house Core: no second signal")
	RunState.sell_relic(String(hc[0]))
	RunState.sell_relic(String(hc[1]))
	RunState.owned_relic_ids.erase(String(hc[0]))
	RunState.owned_relic_ids.erase(String(hc[1]))
	_assert(RunState.anchor_awakened, "flag never turns off when house Cores are sold")
	RunState.clear_saved_run()
	# a finished quest Core counts for awakening
	_awakened.clear()
	_start(104)
	var qa := String(RunState.anchor_offer[0])
	RunState.pick_anchor(qa)
	var qh: Array = Anchors.get_def(qa)["house_cores"]
	RunState.core_quest_done = [String(qh[0])]
	RunState._grant_relic(String(qh[1]), "test")
	_assert(RunState.anchor_awakened, "quest-done Core + one owned Core awaken")
	RunState.clear_saved_run()

	# --- gates ---
	for kind in ["daily", "mission", "ranked"]:
		_start(105, {"kind": kind, "ranked": kind == "ranked"})
		_assert(RunState.anchor_gate_reason() != "" and not RunState.anchor_offer_open(), "%s run: no Anchor" % kind)
		_assert(not RunState.pick_anchor("a_volley"), "%s run: pick refused" % kind)
		_assert(not RunState._anchor_waiting, "%s run: flow not held" % kind)
	_start(106, {"anchor": false})
	_assert(RunState.anchor_gate_reason() == "off" and RunState._core_offer_active, "no opt-in: old flow, pick 1 straight away")
	_start(107)
	RunState.depth_stage = 2
	RunState.anchor_offer = []
	RunState._anchor_waiting = false
	_assert(RunState.anchor_gate_reason() == "stage" and not RunState.anchor_offer_open(), "stage < 3: no Anchor")
	RunState.depth_stage = 3
	var tape := TapeEpochSource.new([])
	_start(108, {}, null)
	RunState.epoch = tape
	_assert(RunState.anchor_gate_reason() == "online", "non-local epoch source: gate shut")

	# --- G6: Run Rule leaving < 2 valid house Cores disables that Anchor ---
	_start(109)
	var rules: Array = []
	for d in RelicRegistry.all_defs_sorted():
		if String(d.core_axis) == "run_rule" and not String(d.id).begins_with("rule_test"):
			rules.append(String(d.id))
	var disabled_n := 0
	for r in rules:
		RunState.run_rule = r
		for a in Anchors.enabled():
			var why := RunState.anchor_disabled_reason(String(a["id"]))
			var valid := 0
			var ctx := {"owned_ids": [r], "roster": RunState.roster, "seen": [], "mode": "short", "first_run": true,
				"pick_index": 1, "front_size": 2, "ascension": 0, "tier_chain": RunState.core_tier_chain}
			for c in a["house_cores"]:
				if CoreOffer.is_valid(RelicRegistry.get_def(String(c)), ctx):
					valid += 1
			_assert((why == "") == (valid >= 2), "G6 %s under %s: reason '%s', valid %d" % [a["id"], r, why, valid])
			if why != "":
				disabled_n += 1
				print("  G6 disabled: %s under %s (%d valid house Cores)" % [a["id"], r, valid])
	print("  G6: %d (anchor, rule) pairs disabled of %d" % [disabled_n, rules.size() * 3])
	RunState.run_rule = ""
	# forced: data where only 1 house Core can ever be valid -> pick refused, offer reports closed, reason says why
	_start(110)
	var vol := Anchors.get_def("a_volley")
	var saved_cores = vol["house_cores"]
	vol["house_cores"] = ["c_sonic_shield", "c_not_a_real_core", "c_not_a_real_core2", "c_x3", "c_x4"]
	_assert(RunState.anchor_disabled_reason("a_volley") == "rule_too_few_house_cores", "G6: < 2 valid house Cores -> reason")
	RunState.anchor_offer = ["a_volley"]
	_assert(not RunState.anchor_offer_open() and not RunState.pick_anchor("a_volley"), "G6: disabled Anchor cannot be picked, offer closed")
	vol["house_cores"] = saved_cores
	Anchors.reload()
	RunState.clear_saved_run()

	# --- verifier: online header with anchor_id -> bad_header ---
	var log := ActionLog.new()
	log.header = {"rules_version": ActionLog.RULES_VERSION, "ranked": true, "anchor_id": "a_volley",
		"content_version": String(ContentDB.part_faces.get("engineVersion", "")), "team_keys": TEAM}
	var res := RunVerifier.verify(log, [{"seq": 0}])
	_assert(not bool(res["ok"]) and String(res["error"]) == RunVerifier.ERR_BAD_HEADER and String(res["message"]).contains("Anchors"), "verifier: anchor_id on an online run -> bad_header: " + String(res.get("error", "")))
	RunState.reset()

	if _failures.is_empty():
		print("t_anchor_runstate: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_anchor_runstate: FAIL — %s" % f)
	get_tree().quit(1)
