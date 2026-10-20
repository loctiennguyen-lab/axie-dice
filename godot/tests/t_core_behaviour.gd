extends Node
## Depth v3 Cores: one behaviour proof per Core (lane C). Batch 1: stat/dice/mana basics.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	t_early_scales()
	t_dewdrop_and_pool()
	t_elder_trunk()
	t_steady_hold()
	t_finisher()
	print("=== t_core_behaviour: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_core_behaviour: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_behaviour: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _combat(relics: Array) -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_core", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0})
	return c


func t_early_scales() -> void:
	var base := _combat([])
	var c := _combat(["c_early_scales"])
	for i in c.party.size():
		var u: Unit = c.party[i]
		var want := (5 + (2 if u.cls == "plant" else 0)) if c.row_of(u) == 0 else 0   # plant BULWARK adds 2
		_ok(u.shield - (base.party[i] as Unit).shield == want, "early_scales: slot %d shield delta != %d" % [i, want])


func t_dewdrop_and_pool() -> void:
	var base := _combat([])
	_ok(_combat(["c_dewdrop"]).mana == base.mana + 1, "dewdrop: +1 mana on turn 1")
	var c := _combat(["c_mana_pool"])
	c.mana = 7
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 9, "mana_pool: 7 unspent -> +2 interest, got %d" % c.mana)
	c.mana = 30
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 33, "mana_pool: interest capped at +3")


func t_elder_trunk() -> void:
	var base := _combat([])
	var c := _combat(["c_elder_trunk"])
	for i in c.party.size():
		var u: Unit = c.party[i]
		var b: Unit = base.party[i]
		_ok(u.max_hp == b.max_hp + 8, "elder_trunk: +8 max hp")
		for fi in u.die.size():
			if String(b.die[fi].get("type", "")) == "dmg" and int(b.die[fi].get("value", 0)) > 0:
				_ok(int(u.die[fi]["value"]) == maxi(1, int(b.die[fi]["value"]) - 1), "elder_trunk: dmg -1")


func t_steady_hold() -> void:
	var c := _combat(["c_steady_hold"])
	_ok(c.stash_cap() == 2, "steady_hold: cap 2")
	_ok(_combat([]).stash_cap() == 1, "baseline cap 1")


func t_finisher() -> void:
	var c := _combat(["c_finisher"])
	var live: Array = c.alive_party()
	# mark all but the last as used by hand: the last die is the finisher with +N for N used before it
	CoreHooks.turn_state(c, "cs_used")["n"] = 3
	for i in live.size() - 1:
		(live[i] as Unit).mark_used()
	var last: Unit = live[live.size() - 1]
	_ok(CoreHooks.is_finisher(c, last), "finisher: last unused die is the finisher")
	_ok(CoreHooks.finisher_bonus(c, last) == 3, "finisher: +3 after 3 used")
	CoreHooks.turn_state(c, "cs_used")["n"] = 9
	_ok(CoreHooks.finisher_bonus(c, last) == 4, "finisher: capped at +4")
