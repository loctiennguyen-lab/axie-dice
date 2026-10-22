extends Node
## Real flow T-03: Pair formed through the Core offer overlay -> PAIR banner with MUTATION strip (name + one rule line)
## -> combat: house mutation tier on the engine, first fire = MUTATION banner, core_fired "mutation" emitted.
## Tier rule: tier 2 only when two Pairs share no Core (3 Cores around one shared Core stay tier 1).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var _fired: Array = []
var rm: Node = null

const CASES := [
	{"house": "h_volley", "anchor": "a_volley", "owned": "c_sonic_shield", "take": "c_thorn_shield", "name": "Spiked Shield"},
	{"house": "h_gambler", "anchor": "a_gambler", "owned": "c_hollow_core", "take": "c_mana_ward", "name": "Crack Mana"},
]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _on_fire(id: String, _uid: int, _amount: int, kind: String) -> void:
	if kind == "mutation":
		_fired.append(id)


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
	var house := String(c["house"])
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	RunState.owned_relic_ids.assign([String(c["owned"])])
	await _offer_with([String(c["take"]), "c_kindle", "c_dewdrop"])
	await get_tree().create_timer(1.0).timeout
	rm.gacha_log.clear()
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(3)
	_check(rm.gacha_log.has("banner:pair"), "%s: PAIR banner raised" % house)
	var ban: Node = rm._overlay_layer.find_child("ComboBanner", true, false)
	_check(ban != null, "%s: banner is up" % house)
	if ban != null:
		var mn := ban.find_child("MutationName", true, false) as Label
		_check(mn != null and mn.text == String(c["name"]), "%s: banner shows mutation name" % house)
		var strip := ban.find_child("MutationStrip", true, false)
		var rule := String(AnchorAdapter.mutation_of(house)["rule"])
		var found := false
		if strip != null:
			for l in strip.find_children("*", "Label", true, false):
				if rule != "" and (l as Label).text.contains(rule.substr(0, 20)):
					found = true
		_check(found, "%s: banner has the one-sentence rule" % house)
	await get_tree().create_timer(2.4).timeout
	# With an Anchor the same pick is an awakening (one merged moment, no banner: t_anchor_awaken_ui); here the banner is tested without one.
	RunState.anchor_id = String(c["anchor"])   # mutations only exist with an Anchor; the pick screen is covered by t_anchor_flow_start
	# engine tier from the owned Cores
	var st := CoreCombos.state(RunState.combo_owned_ids())
	_check(Anchors.mutation_tier(RunState.combo_owned_ids(), house, st) == 1, "%s: tier 1 after one Pair" % house)
	rm.free()
	rm = null
	# combat
	_fired.clear()
	EventBus.core_fired.connect(_on_fire)
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(60)
	_check(v._combat._mut_tier(house) == 1, "%s: combat engine carries tier 1" % house)
	var uid: int = v._combat.party[0].uid
	if house == "h_volley":
		BoTestBase.force(v._combat, [1, 1, 1, 2, 3], [BoTestBase.face("shield", 9), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5)])
		v._combat.use_die(uid, uid)
	else:
		# real Crack Mana: Gamble two dice with a seed where exactly 1+ die Cracks; tier 1 pays +1 mana
		var seed_c := -1
		for sd in 400:
			var pe := CombatEngine.new()
			pe.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
				"relic_ids": [], "combat_seed": 7, "start_mana": 0, "depth_stage": 3, "anchor_id": "a_gambler", "anchor_awakened": false})
			pe.rerolls = 0
			BoTestBase.force(pe, [0, 1, 2, 3, 4], [BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5)])
			pe.reroll_dice([pe.party[0].uid, pe.party[1].uid], sd, false, 0)
			if pe.party[0].cracked or pe.party[1].cracked:
				seed_c = sd
				break
		_check(seed_c >= 0, "h_gambler: found a Cracking seed")
		var ce: CombatEngine = v._combat
		ce.rerolls = 0
		BoTestBase.force(ce, [0, 1, 2, 3, 4], [BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5), BoTestBase.face("dmg", 5)])
		var m0 := ce.mana
		ce.reroll_dice([ce.party[0].uid, ce.party[1].uid], seed_c, false, 0)
		_check(ce.mana - m0 == 1, "h_gambler: a real Gamble Crack pays +1 mana (%d)" % (ce.mana - m0))
	await _frames(4)
	_check(_fired.has(house), "%s: core_fired mutation emitted" % house)
	_check(v.mutation_log.size() >= 1 and v.mutation_log[0]["mode"] == "banner", "%s: first fire shows the MUTATION banner" % house)
	EventBus.core_fired.disconnect(_on_fire)
	v.free()


func _ready() -> void:
	print("=== t_anchor_flow_pair_mutation: start ===")
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	AnchorAdapter.test_state = null
	for c in CASES:
		await _case(c)
	# tier 2 rule (pure, same state the engine reads)
	var shared := ["c_sonic_shield", "c_thorn_shield", "c_living_wall"]   # Shield Engine + Turtle Fortress share c_thorn_shield
	var s1 := CoreCombos.state(shared)
	_check(String(s1.get("combo_shield_engine", "")) == "pair" and String(s1.get("combo_turtle_fort", "")) == "pair", "3 Cores form 2 Pairs")
	_check(Anchors.mutation_tier(shared, "h_volley", s1) == 1, "shared Core: stays tier 1")
	var dj := ["c_sonic_shield", "c_backline_glow", "c_living_wall", "c_thorn_shield"]   # Toxic Guard + Turtle Fortress: disjoint Pairs
	_check(Anchors.mutation_tier(dj, "h_volley", CoreCombos.state(dj)) == 2, "two Pairs with disjoint Cores: tier 2")
	AnchorAdapter.test_state = null
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_anchor_flow_pair_mutation: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("t_anchor_flow_pair_mutation: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_anchor_flow_pair_mutation: PASS")
	get_tree().quit(0 if _fails.is_empty() else 1)
