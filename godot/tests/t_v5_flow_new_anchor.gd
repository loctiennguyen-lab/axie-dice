extends Node
## v5 real flow: the new Anchors Kin and Big Hand. Pick through the real AnchorPick screen (online-style run, stage 2),
## take 2 house Cores through the Core offer overlay -> awakened + AnchorFx plays once, then the real Combat scene.
## Kin: Unison puts 2+ Axies of one class on the same part on turn 1.

const CASES := [
	{"anchor": "a_kin", "team": ["plant1", "plant2", "beast1", "aqua1", "reptile1"]},
	{"anchor": "a_big_hand", "team": ["plant1", "beast1", "aqua1", "reptile1", "bug1"]},
]
var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()
var rm: Node = null


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _offer_with(keys: Array) -> void:
	if rm != null:
		rm.free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(4)
	var cards: Array[Dictionary] = []
	for i in keys.size():
		cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(3)


func _case(c: Dictionary) -> void:
	var aid := String(c["anchor"])
	print("step: case ", aid)
	var team: Array = c["team"]
	var seed_ok := -1
	for sd in range(501, 801):
		RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), sd), {"team_keys": team, "mode": "short", "ascension": 0,
			"ranked": false, "kind": "normal", "anchor": true, "depth_stage": 2, "loadout": {"rules_on": false}}, sd)
		RunState.depth_stage = 2
		RunState.anchor_offer_open()
		if (RunState.anchor_offer as Array).has(aid):
			seed_ok = sd
			break
	_ok(seed_ok >= 0, "%s: found a seed whose offer holds it" % aid)
	if seed_ok < 0:
		return
	AnchorFx.played_run = ""
	AnchorFx.pending = ""
	AnchorFx.log.clear()
	UI3Gacha.instant_override = 1
	var map: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(map)
	await _frames(8)
	var pick := map.find_child("AnchorPick", true, false) as AnchorPick
	_ok(pick != null, "%s: pick screen up" % aid)
	if pick == null:
		map.free()
		return
	var idx := -1
	for i in pick.cards.size():
		if String(pick.cards[i].get_meta("anchor_id")) == aid:
			idx = i
	_ok(idx >= 0 and AnchorAdapter.disabled_reason(aid) == "", "%s: card present and pickable" % aid)
	pick.select(idx)
	pick.take_button.pressed.emit()
	await _frames(10)
	_ok(RunState.anchor_id == aid, "%s: engine holds the Anchor" % aid)
	_ok(not RunState.anchor_awakened, "%s: not awake after the pick" % aid)
	map.free()
	AnchorFx.log.clear()
	var hc: Array = AnchorAdapter.house_cores(aid)
	_ok(hc.size() >= 2, "%s: house has Cores" % aid)
	rm = null
	for k in 2:
		await _offer_with([String(hc[k]), "c_kindle", "c_dewdrop"])
		rm._select_reward(0)
		rm._take_selected_reward()
		await _frames(20)
		if k == 0:
			_ok(not RunState.anchor_awakened, "%s: 1 house Core: not awake" % aid)
	_ok(RunState.owned_relic_ids.has(String(hc[0])) and RunState.owned_relic_ids.has(String(hc[1])), "%s: both house Cores owned" % aid)
	_ok(RunState.anchor_awakened, "%s: awakened after 2 house Cores via the overlay" % aid)
	var plays := AnchorFx.log.filter(func(e) -> bool: return e == "play").size()
	_ok(plays == 1, "%s: AnchorFx played once (%d)" % [aid, plays])
	rm.free()
	rm = null
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(40)
	var e: CombatEngine = v._combat
	_ok(e.anchor_id == aid and e.anchor_awakened, "%s: combat starts awakened" % aid)
	_ok(e.turn == 1, "%s: turn 1" % aid)
	if aid == "a_kin":
		var by_cls := {}
		for u in e.party:
			var un := u as Unit
			if un.cls != "" and un.has_rolled() and not un.is_token and not un.custom_state.has("phantom") and un.uid < 100000:   # eggs / phantom dice are not on the team
				if not by_cls.has(un.cls):
					by_cls[un.cls] = []
				(by_cls[un.cls] as Array).append(un.roll_face_index())
		var best := 0
		for k in by_cls:
			var fl: Array = by_cls[k]
			var same := true
			for f in fl:
				same = same and int(f) == int(fl[0])
			if fl.size() >= 2:
				_ok(same, "Unison: all %d %s Axies show part %d (%s)" % [fl.size(), k, int(fl[0]), str(fl)])
			best = maxi(best, fl.size())
		_ok(best >= 2, "team has 2+ Axies of one class (%d)" % best)
	v.free()
	await _frames(2)


func _ready() -> void:
	print("=== t_v5_flow_new_anchor: start ===")
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	ProjectSettings.set_setting("axie/epoch_source", "local")
	AnchorAdapter.test_state = null
	for c in CASES:
		await _case(c)
	UI3Gacha.instant_override = -1
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_v5_flow_new_anchor: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_v5_flow_new_anchor: PASS")
	get_tree().quit(0 if _fail == 0 else 1)
