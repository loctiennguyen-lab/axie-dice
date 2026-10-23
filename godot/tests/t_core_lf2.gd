extends Node
## Low-fire Cores fix 23/10 (design/proposals/core-visibility-fix.md "Sua 23/10"): R2 Fissure gate, R4 Open Ranks gate,
## R5 Golden Egg second source, R8 Steady Hold ramp, Rising Wave threshold 2.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	t_fissure_gate()
	t_open_ranks_gate()
	print("=== t_core_lf2: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_core_lf2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_lf2: FAIL — %s" % f)
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


func _ctx(keys: Array, owned: Array) -> Dictionary:
	var roster: Array = []
	for k in keys:
		roster.append({"hero_key": k})
	return {"owned_ids": owned, "roster": roster, "seen": [], "mode": "short", "first_run": false, "pick_index": 1, "front_size": 2, "ascension": 0}


func t_fissure_gate() -> void:
	var d = RelicRegistry.get_def("c_fissure")
	_ok((d.requires as PackedStringArray).has("face:poison|weaken|vulnerable|blind|freeze|stun"), "fissure: requires lists every real debuff")
	# a party whose only debuff is a real keyword (no poison, no "debuff" label) must now see Fissure
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3, "keywords": ["weaken:2"]}]}
	_ok(CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: weaken-only party -> valid")
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3, "keywords": ["stun"]}]}
	_ok(CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: stun-only party -> valid")
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3}, {"type": "shield", "value": 2}]}
	_ok(not CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: no debuff -> hidden")
	ContentDB.heroes.erase("t_dbf")


func t_open_ranks_gate() -> void:
	var d = RelicRegistry.get_def("c_open_ranks")
	_ok((d.requires as PackedStringArray).is_empty(), "open_ranks: no requires")
	_ok(CoreOffer.is_valid(d, _ctx(ROSTER, [])), "open_ranks: valid with no front Core owned")
	_ok(not CoreOffer.is_valid(d, _ctx(ROSTER, ["c_living_wall"])), "open_ranks: living_wall excludes it")
	for id in ["c_backline_glow", "c_descend"]:
		var o = RelicRegistry.get_def(id)
		_ok((o.excludes as PackedStringArray).has("owned:c_open_ranks"), "%s excludes open_ranks" % id)
		_ok(not CoreOffer.is_valid(o, _ctx(ROSTER, ["c_open_ranks"])), "%s hidden when open_ranks owned" % id)
