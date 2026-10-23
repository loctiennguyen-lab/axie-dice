extends Node
## Run Rules v5 (design/proposals/cores-rules-v5.md section 10): Pack Alpha, Set Is King, Pilot Light, High Stakes.

const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	t_pack_alpha()
	t_set_king()
	print("=== t_rules_v5: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("t_rules_v5: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_rules_v5: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _fails.is_empty() else 1)


func _enable(id: String) -> void:
	var d = RelicRegistry.get_def(id)
	d.disabled = false
	d.hook_key = id


func _val_face(c: CombatEngine, u: Unit, ft: String) -> int:
	for fi in u.die.size():
		if String(u.die[fi].get("type", "")) == ft and int(u.die[fi].get("value", 0)) > 0:
			return fi
	return -1


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _combat(relics: Array, extra: Dictionary = {}) -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var setup := {"node_id": "t_v5", "kind": "battle", "pw": 6, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0}
	setup.merge(extra, true)
	var c := CombatEngine.new()
	c.setup_new(setup)
	return c


func _hit(c: CombatEngine, src: Unit, tgt: Unit, v: int, single: bool, pierce: bool) -> int:
	var hp0: int = tgt.hp
	tgt.shield = 0
	DamagePipeline.resolve({"combat": c, "src": src, "tgt": tgt, "value": v, "single": single, "pierce": pierce, "attack": true, "face_type": "dmg"})
	return hp0 - tgt.hp


func t_pack_alpha() -> void:
	var base := _combat([])
	var c := _combat(["rule_pack_alpha"])
	_ok(c.enemies.size() >= 2, "pack alpha: fight has 2+ enemies (%d)" % c.enemies.size())
	var best: Unit = base.enemies[0]
	for e in base.enemies:
		if e.max_hp > best.max_hp:
			best = e
	var al = CoreHooks.alpha_unit(c)
	_ok(al != null, "alpha marked")
	_ok(CoreHooks.alpha_unit(base) == null, "no rule: no alpha")
	if al == null:
		return
	_ok(al.uid == best.uid, "alpha = highest HP, tie smallest uid")
	_ok(al.max_hp == int(ceil(best.max_hp * 1.25)), "alpha HP x1.25: %d vs %d" % [al.max_hp, best.max_hp])
	var other: Unit = null
	for e in c.enemies:
		if e != al:
			other = e
			break
	var src: Unit = c.party[0]
	other.max_hp = 100
	other.hp = 100
	_ok(_hit(c, src, other, 10, true, false) == 5, "others take -50% single")
	other.hp = 100
	_ok(_hit(c, src, other, 1, true, false) == 1, "min 1")
	other.hp = 100
	_ok(_hit(c, src, other, 10, false, false) == 10, "AoE not reduced")
	other.hp = 100
	_ok(_hit(c, src, other, 10, true, true) == 10, "pierce not reduced")
	al.max_hp = 100
	al.hp = 100
	var pl := CombatTraits.plating_of(c, al)
	_ok(_hit(c, src, al, 10, true, false) == maxi(1, 10 - pl), "alpha itself not reduced (plating %d)" % pl)
	# save/load keeps the mark
	var c2 := CombatEngine.new()
	c2.from_data(c.to_data())
	_ok(CoreHooks.alpha_unit(c2) != null and CoreHooks.alpha_unit(c2).uid == al.uid, "alpha survives save/load")
	# alpha falls: others lose 20% of current HP
	other.hp = 50
	al.hp = 1
	var hp_before: Array = []
	for e in c.enemies:
		hp_before.append(e.hp)
	_hit(c, src, al, 5, true, true)
	_ok(al.hp <= 0, "alpha dead")
	_ok(other.hp == 40, "others lose 20%% current HP: %d" % other.hp)
	# after alpha died, others are no longer reduced
	other.hp = 100
	_ok(_hit(c, src, other, 10, true, false) == 10, "alpha dead: no reduction")
	# boss: not applied
	var b := _combat(["rule_pack_alpha"], {"kind": "boss"})
	_ok(CoreHooks.alpha_unit(b) == null, "boss fight: no alpha")


func t_set_king() -> void:
	_enable("rule_set_is_king")
	var base := _combat([])
	var c := _combat(["rule_set_is_king"])
	_ok(c.rerolls == base.rerolls - 1 and c.max_rerolls == base.max_rerolls - 1, "set king: no free reroll (%d vs %d)" % [c.rerolls, base.rerolls])
	var tested := 0
	for i in c.party.size():
		var u: Unit = c.party[i]
		var b: Unit = base.party[i]
		var fi := _val_face(c, u, "dmg")
		if fi < 0:
			continue
		var v0 := base._face_value(b, fi)
		if v0 < 3:
			continue
		tested += 1
		c.bo = []
		_ok(c._face_value(u, fi) == maxi(1, v0 - 2), "%s lone die -2: %d -> %d" % [u.key, v0, c._face_value(u, fi)])
		c.bo = [{"part": 0, "size": 3, "uids": [u.uid, 99, 98], "hi": false, "m100": 100}]
		_ok(c._face_value(u, fi) == v0 + 2, "%s set die +2: %d -> %d" % [u.key, v0, c._face_value(u, fi)])
		_ok(base._face_value(b, fi) == v0, "no rule: unchanged")
		var c2 := CombatEngine.new()
		c2.from_data(c.to_data())
		_ok(c2._face_value(c2.party[i], fi) == v0 + 2, "save/load keeps set bonus")
		c.bo = []
	_ok(tested > 0, "set king: tested at least one die")
	_ok(CoreHooks.in_set(c, c.party[0]) == false, "in_set false without sets")
