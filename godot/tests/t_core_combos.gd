extends Node
## Gacha lane GD: CoreCombos (core_combos.json, 14 combos). Pure checks, no run.
var _failures: Array[String] = []
var _checks := 0


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _ready() -> void:
	CoreCombos.reload()
	var rows: Array = CoreCombos.all([])
	_assert(rows.size() == 14, "14 combos enabled with no rule, got %d" % rows.size())
	# data sanity: every member is a real, enabled Core; ids unique; at most one jackpot-style set of 3
	var ids := {}
	for r in rows:
		_assert(not ids.has(r["id"]), "unique id %s" % r["id"])
		ids[r["id"]] = true
		_assert(String(r["name_en"]) != "" and String(r["name_vi"]) != "", "%s has names" % r["id"])
		var m := CoreCombos.members(r)
		_assert(m.size() == 3, "%s has 3 members" % r["id"])
		for id in m:
			var d = RelicRegistry.get_def(String(id))
			_assert(d != null and not d.disabled and d.core_axis != "", "%s member %s is an enabled Core" % [r["id"], id])
		if not bool(r["jackpot"]):
			# Pair: at most 1 Moss, at most 1 Crystal
			var moss := 0
			var cry := 0
			for id in (r["pair"] as Array):
				var rar := int(RelicRegistry.get_def(String(id)).rarity)
				moss += 1 if rar == 0 else 0
				cry += 1 if rar == 2 else 0
			_assert(moss <= 1 and cry <= 1, "%s pair has <=1 Moss and <=1 Crystal" % r["id"])
	var jack := 0
	for r in rows:
		if bool(r["jackpot"]):
			jack += 1
			_assert(r["pair"] == null, "jackpot has no pair tier")
	_assert(jack == 1, "exactly one jackpot")

	# state: pair then full
	var o := ["c_living_wall"]
	_assert(CoreCombos.state(o).is_empty(), "1 member forms nothing")
	o = ["c_living_wall", "c_gatekeeper"]
	_assert(CoreCombos.state(o).get("combo_turtle_fort", "") == "pair", "pair forms")
	o.append("c_backline_glow")
	_assert(CoreCombos.state(o).get("combo_turtle_fort", "") == "full", "pair + third = full")
	_assert(CoreCombos.state(["c_living_wall", "c_backline_glow"]).get("combo_turtle_fort", "") == "", "pair member + third only = nothing")

	# card_completes
	var cc := CoreCombos.card_completes(["c_living_wall"], "c_gatekeeper")
	_assert(cc.get("id", "") == "combo_turtle_fort" and cc.get("tier", "") == "pair", "gatekeeper completes the Pair")
	cc = CoreCombos.card_completes(["c_living_wall", "c_gatekeeper"], "c_backline_glow")
	_assert(cc.get("tier", "") == "full", "third completes Full")
	_assert(CoreCombos.card_completes(["c_living_wall"], "c_backline_glow").is_empty(), "third alone does not complete")
	_assert(CoreCombos.card_completes(["c_living_wall", "c_gatekeeper"], "c_gatekeeper").is_empty(), "owned card completes nothing")
	_assert(CoreCombos.card_completes([], "c_gatekeeper").is_empty(), "no owned = nothing")
	cc = CoreCombos.card_completes(["c_backline_glow", "c_gatekeeper"], "c_living_wall")
	_assert(cc.get("tier", "") == "full", "third owned first, last pair card gives Full")

	# jackpot: no pair tier
	var jset := ["c_cascade", "c_sixth_die", "c_mirror_face"]
	_assert(CoreCombos.state(["c_cascade", "c_sixth_die"]).get("combo_rain", "") == "", "jackpot has no Pair tier")
	cc = CoreCombos.card_completes(["c_cascade", "c_sixth_die"], "c_mirror_face")
	_assert(cc.get("id", "") == "combo_rain" and cc.get("tier", "") == "full", "jackpot completes straight to full")
	_assert(CoreCombos.card_completes(["c_cascade"], "c_sixth_die").get("id", "") != "combo_rain", "2nd jackpot card is not a completion")
	_assert(CoreCombos.state(jset).get("combo_rain", "") == "full", "jackpot full state")

	# matches: only owned, max 2
	var mm := CoreCombos.matches(["c_living_wall", "c_gatekeeper", "c_growing_shell", "c_finisher"], "c_backline_glow")
	_assert(mm.size() == 2 and mm.has("c_living_wall") and mm.has("c_gatekeeper"), "matches lists owned partners, max 2: %s" % str(mm))
	_assert(CoreCombos.matches([], "c_backline_glow").is_empty(), "matches empty when owning nothing")
	_assert(not CoreCombos.matches(["c_backline_glow"], "c_backline_glow").has("c_backline_glow"), "never matches itself")
	for id in CoreCombos.matches(["c_overflow", "c_dewdrop", "c_nest", "c_loop"], "c_backline_glow"):
		_assert(["c_overflow", "c_dewdrop", "c_living_wall", "c_gatekeeper", "c_sonic_shield", "c_blood_sign", "c_thorn_pact", "c_elder_trunk"].has(id), "match %s is a real partner" % id)

	# hidden by Run Rule
	var hid := CoreCombos.state(["c_living_wall", "c_gatekeeper", "rule_upside_down"])
	_assert(not hid.has("combo_turtle_fort"), "Turtle Fortress hidden under Upside Down")
	_assert(not CoreCombos.all(["rule_upside_down"]).any(func(r): return r["id"] == "combo_turtle_fort"), "all() drops it")
	_assert(CoreCombos.card_completes(["c_living_wall", "rule_upside_down"], "c_gatekeeper").is_empty(), "no label while hidden")
	_assert(CoreCombos.matches(["c_living_wall", "rule_upside_down"], "c_gatekeeper").is_empty(), "no chip while hidden")
	for rid in ["rule_dry_steppe", "rule_cheap_mana", "rule_tundra"]:
		var vis := CoreCombos.all([rid])
		var ex: Array = {"rule_dry_steppe": ["combo_rising_tide", "combo_endless_mana"], "rule_cheap_mana": ["combo_lake_fishing", "combo_blood_deal", "combo_molt"], "rule_tundra": ["combo_lake_fishing", "combo_blood_deal", "combo_molt"]}[rid]
		for e in ex:
			_assert(not vis.any(func(r): return r["id"] == e), "%s hidden by %s" % [e, rid])
		_assert(vis.size() == 14 - ex.size(), "%s leaves %d combos, got %d" % [rid, 14 - ex.size(), vis.size()])
	_assert(CoreCombos.all(["rule_heavy_finish"]).size() == 14, "a neutral rule hides nothing")

	# Quest Core that finished still counts: caller passes it in `owned` (RunState.combo_owned_ids)
	var q := CoreCombos.state(["c_kindle", "c_key_strike"])
	_assert(q.get("combo_kindling_brew", "") == "pair", "quest Core (Key Strike) counts as owned for the Pair")
	RunState.reset()
	RunState.owned_relic_ids = ["c_kindle"]
	RunState.core_quest_done = ["c_key_strike"]
	_assert(CoreCombos.state(RunState.combo_owned_ids()).get("combo_kindling_brew", "") == "pair", "finished quest Core still in combo_owned_ids()")
	_assert(CoreCombos.all().size() == 14, "all() with no arg reads RunState")
	RunState.reset()

	# disabled / enabled:false flag hides
	var saved: Array = CoreCombos._rows.duplicate(true)
	CoreCombos._rows[0]["enabled"] = false
	_assert(CoreCombos.all([]).size() == 13, "enabled:false hides a combo")
	CoreCombos.reload()
	_assert(saved.size() == 14, "json reload still 14")
	_done()


func _done() -> void:
	if _failures.is_empty():
		print("t_core_combos: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_core_combos: FAIL — %s" % f)
	get_tree().quit(1)
