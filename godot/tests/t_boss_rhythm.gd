extends Node
## Depth v3 6.3 boss rhythm: prep -> strike -> hollow, readable one turn ahead (design/proposals/depth-v3-design.md).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	# Boss mechanics test, not a Resonance Shell test: the Shell is on for Elite/boss from stage 2 and would soak damage / skew HP thresholds. Switch it off here, restore at the end.
	var _shell_backup: Dictionary = (ContentDB.combat_tune.get("shell", {}) as Dictionary).duplicate(true)
	var _shell_off: Dictionary = _shell_backup.duplicate(true)
	_shell_off["enabled"] = false
	ContentDB.combat_tune["shell"] = _shell_off
	await get_tree().process_frame
	_phases()
	_hollow_damage()
	_strike_face()
	_trait_tells()
	print("=== t_boss_rhythm: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_boss_rhythm: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_boss_rhythm: PASS - %d checks OK" % _checks)
	_guard.restore()
	ContentDB.combat_tune["shell"] = _shell_backup
	get_tree().quit(0 if _failures.is_empty() else 1)


func _combat(boss_key: String) -> CombatEngine:
	var roster: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "rh", "kind": "boss", "pw": 9, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": [], "combat_seed": 4242, "boss_key": boss_key})
	return c


func _boss(c: CombatEngine) -> Unit:
	for e in c.enemies:
		if (e as Unit).is_boss:
			return e
	return null


func _phases() -> void:
	var c := _combat("mecha")
	var b := _boss(c)
	var want := ["prep", "hollow", "prep", "strike", "hollow", "prep", "strike"]
	for tc in want.size():
		b.custom_state["turn_count"] = tc
		_check(c.boss_rhythm_phase(b) == want[tc], "turn_count %d should be %s, is %s" % [tc, want[tc], c.boss_rhythm_phase(b)])
	b.custom_state["turn_count"] = 2
	var st := c.boss_rhythm_state(b)
	_check(st["phase"] == "prep" and st["next"] == "strike" and st["turns_to_strike"] == 1, "early tell on the prep turn: %s" % str(st))
	var a := _boss(_combat("agony"))
	_check(a != null and _combat("agony").boss_rhythm_phase(a) == "", "agony has no rhythm (own two phases)")


func _hollow_damage() -> void:
	var c := _combat("gooey_king")
	var b := _boss(c)
	b.max_hp = 100000
	var dealt := []
	for tc in [2, 1]:   # prep, then hollow
		b.custom_state["turn_count"] = tc
		b.hp = b.max_hp
		b.shield = 0
		DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": b, "value": 10, "attack": true, "face_type": "dmg"})
		dealt.append(b.max_hp - b.hp)
	_check(dealt[0] == 10 and dealt[1] == 15, "hollow should take +50%%: prep %d, hollow %d" % [dealt[0], dealt[1]])
	var fi := b.roll_face_index()
	b.custom_state["turn_count"] = 2
	var normal := c._face_value(b, fi)
	b.custom_state["turn_count"] = 1
	var weak := c._face_value(b, fi)
	_check(normal == 0 or weak < normal, "hollow boss face should hit softer: %d vs %d" % [weak, normal])


func _strike_face() -> void:
	var c := _combat("gooey_king")
	var b := _boss(c)
	b.custom_state["turn_count"] = 3
	c._apply_strike_face(b)
	var best := 0
	for f in b.die:
		if String(f.get("type", "")) == "dmg":
			best = maxi(best, int(f.get("value", 0)))
	_check(int((b.die[b.roll_face_index()] as Dictionary).get("value", 0)) == best, "strike turn must use the strongest dmg face")


func _trait_tells() -> void:
	var c := _combat("mecha")
	var b := _boss(c)
	var perm := int(b.custom_state.get("permanent_thorns", 0))
	b.custom_state["turn_count"] = 0
	c._boss_turn_traits()   # count 1 = hollow
	_check(int(b.status.get("thorns", 0)) == 0, "mecha hollow turn opens the thorns")
	c._boss_turn_traits()   # 2 prep
	_check(int(b.status.get("thorns", 0)) == perm and perm > 0, "mecha thorns are back on prep")
	c._boss_turn_traits()   # 3 strike
	_check(b.overdrive, "mecha OVERDRIVE sits on the strike turn")

	var f := _combat("frost_lord")
	var fb := _boss(f)
	fb.custom_state["turn_count"] = 2
	f._boss_turn_traits()   # 3 strike
	var n := 0
	for u in f.party:
		if u.frozen:
			n += 1
	_check(n == 2, "frost lord freezes 2 on its strike turn, froze %d" % n)
	for u in f.party:
		u.frozen = false
	f._boss_turn_traits()   # 4 hollow
	n = 0
	for u in f.party:
		if u.frozen:
			n += 1
	_check(n == 0, "frost lord freezes none on its hollow turn")


func _check(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
