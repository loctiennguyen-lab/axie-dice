extends Node
## Real flow T-04: the 2nd house Core is taken through the Core offer overlay (awakening moment plays once, on the map),
## then the real Combat scene: the Anchor's own effect runs (Volley: Thorn Storm second blast; Gambler: Second Wind
## re-rolls the Cracked die), the HUD badge never goes back to "x/2", no second moment in combat, and the Result
## screen shows AnchorCard (Anchor + Awakened) right above the Cores card.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node = null

const CASES := [
	{"anchor": "a_volley", "owned": "c_sonic_shield", "take": "c_thorn_shield"},
	{"anchor": "a_gambler", "owned": "c_hollow_core", "take": "c_mana_ward"},
	{"anchor": "a_mana_mine", "owned": "c_mana_pool", "take": "c_deep_current"},
]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


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


func _cracking_seed(anchor: String) -> int:
	for s in 400:
		var e := CombatEngine.new()
		e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
			"relic_ids": [], "combat_seed": 7, "start_mana": 0, "depth_stage": 3, "anchor_id": anchor, "anchor_awakened": false})
		e.rerolls = 0
		BoTestBase.force(e, [0, 1, 2, 3, 4], [BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5)])
		e.reroll_dice([e.party[0].uid, e.party[1].uid], s, false, 0)
		if e.party[0].cracked or e.party[1].cracked:
			return s
	return -1


func _case(c: Dictionary) -> void:
	var aid := String(c["anchor"])
	AnchorFx.played_run = ""
	AnchorFx.pending = ""
	AnchorFx.log.clear()
	UI3Gacha.instant_override = 1
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	RunState.depth_stage = 3
	RunState.anchor_id = aid
	RunState.owned_relic_ids.assign([String(c["owned"])])
	_check(not RunState.anchor_awakened, "%s: 1 house Core: not awake" % aid)
	await _offer_with([String(c["take"]), "c_kindle", "c_dewdrop"])
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(20)
	_check(RunState.anchor_awakened, "%s: 2 house Cores through the overlay: engine awake" % aid)
	var plays := AnchorFx.log.filter(func(e) -> bool: return e == "play").size()
	_check(plays == 1, "%s: awakening moment played once (%d)" % [aid, plays])
	rm.free()
	rm = null
	# combat
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(60)
	var e: CombatEngine = v._combat
	_check(e.anchor_id == aid and e.anchor_awakened, "%s: combat engine starts awakened" % aid)
	_check(v.awaken_log.is_empty(), "%s: no second moment in combat" % aid)
	var d5 := BoTestBase.face("dmg", 5)
	if aid == "a_volley":
		BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		for t in e.enemies:
			(t as Unit).hp = 90
			(t as Unit).max_hp = 90
			(t as Unit).shield = 50
		var tgt := e.enemies[1] as Unit
		var other := e.enemies[0] as Unit
		for i in 3:
			e.use_die(e.party[i].uid, tgt.uid)
		await _frames(4)
		# SET of three 5s: base 15; the second blast pierces Shield and deals floor(15 * volley_pct_3 / 100) (knob, not hard-coded)
		var want_hp := 90 - int(floor(15.0 * CombatEngine.tune_knob("anchor", "volley_pct_3", 40.0) / 100.0))
		_check(bool(e.anchor_turn["vol2"]) and other.hp == want_hp, "a_volley: Thorn Storm blasts a second time (hp %d, want %d)" % [other.hp, want_hp])
	elif aid == "a_mana_mine":
		# Roll turns until the first roll is a natural SET with an Overcast-able die (rng is the run's; bounded loop).
		var tried := 0
		var pick_uid := -1
		var gain := -1
		while tried < 600 and pick_uid < 0:
			tried += 1
			var m_before := e.mana
			e.roll_all()
			if not bool(e.anchor_turn.get("mine", false)) or e.bo.is_empty():
				continue
			for mu in (e.bo[0]["uids"] as Array):
				var bu := e.by_uid(int(mu))
				var m_now := e.mana
				e.mana = 10
				var can := bu != null and e.can_overcast(bu.uid)
				e.mana = m_now
				if can:
					pick_uid = bu.uid
					gain = m_now - m_before
					break
		_check(pick_uid >= 0, "a_mana_mine: found a natural SET turn (%d rolls)" % tried)
		if pick_uid >= 0:
			var mine_mana := int(CombatEngine.tune_knob("anchor", "mine_mana", 1.0))
			_check(gain == mine_mana, "a_mana_mine: natural SET on the first roll pays +mine_mana (%d, want %d)" % [gain, mine_mana])
			e.mana = 10
			_check(e.overcast_cost() == 1, "a_mana_mine: Overcast costs 1 after the SET")
			_check(e.overcast(pick_uid) and e.mana == 9, "a_mana_mine: first Overcast paid 1 (mana %d)" % e.mana)
			_check(e.overcast_cost() == 2 and e.overcast_per_turn() == 2, "a_mana_mine awake: second Overcast costs 2, 2 per turn")
			_check(e.overcast(pick_uid) and e.mana == 7, "a_mana_mine awake: second Overcast accepted, paid 2 (mana %d)" % e.mana)
			_check(not e.overcast(pick_uid), "a_mana_mine: no third Overcast")
	else:
		var seed_c := _cracking_seed("a_gambler")
		_check(seed_c >= 0, "a_gambler: found a Cracking seed")
		e.rerolls = 0
		BoTestBase.force(e, [0, 1, 2, 3, 4], [d5, d5, d5, d5, d5])
		e.reroll_dice([e.party[0].uid, e.party[1].uid], seed_c, false, 0)
		await _frames(4)
		_check(bool(e.anchor_turn["sw_used"]) and not e.party[0].cracked and not e.party[1].cracked, "a_gambler: Second Wind re-rolled the Cracked die")
	var cp = v._hud_frame.core_panel if v._hud_frame != null else null
	_check(cp != null and cp.anchor_slot != null, "%s: HUD Anchor tile" % aid)
	if cp != null and cp.anchor_slot != null:
		cp.refresh()
		var badge := cp.anchor_slot.find_child("AnchorBadge", true, false) as Label
		_check(badge != null and badge.text.begins_with("x") and not badge.text.contains("/2"), "%s: HUD badge stays awake, not x/2 (%s)" % [aid, badge.text if badge != null else "none"])
	v.free()
	# result screen
	RunState.set_phase(RunState.RunPhase.WON)
	var rv: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(rv)
	await _frames(3)
	var card := rv.find_child("AnchorCard", true, false)
	_check(card != null, "%s: Result has AnchorCard" % aid)
	if card != null:
		var nm := card.find_child("AnchorName", true, false) as Label
		var st := card.find_child("AnchorState", true, false) as Label
		_check(nm != null and nm.text.contains(AnchorAdapter.name_of(aid)), "%s: AnchorCard names the Anchor" % aid)
		_check(st != null and st.text == "Awakened", "%s: AnchorCard says Awakened" % aid)
		var rel := rv.find_child("RelicsCard", true, false)
		_check(rel != null and rel.get_parent() == card.get_parent() and card.get_index() == rel.get_index() - 1, "%s: AnchorCard sits directly above the Cores card" % aid)
	rv.free()


func _ready() -> void:
	print("=== t_anchor_flow_awaken_in_combat: start ===")
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	AnchorAdapter.test_state = null
	for c in CASES:
		await _case(c)
	UI3Gacha.instant_override = -1
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_anchor_flow_awaken_in_combat: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("t_anchor_flow_awaken_in_combat: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_anchor_flow_awaken_in_combat: PASS")
	get_tree().quit(0 if _fails.is_empty() else 1)
