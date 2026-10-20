class_name CombatTraits
extends RefCounted
## Depth v3 6.7 / 6.7b anti-spam mechanics (Plating, Ward, Mend, Spite, Charge, trait assignment).
## Design: design/proposals/depth-v3-design.md 6.7, 6.7b, "Viec engine moi cho lan A". Every number is a knob in
## combat_tune.json (plating.*, ward.*, mend.*, spite.*, charge.*, traits.*, run_rules.*). Pure helpers over a
## CombatEngine; no rng, no time, so replays stay deterministic.

const DEBUFFS := ["poison", "burn", "weaken", "vulnerable", "blind", "stun", "freeze"]


static func knob(section: String, key: String, default_value: float) -> float:
	return CombatEngine.tune_knob(section, key, default_value)


## P = clamp(round(budget / div), min, max) for the fight's power level (M1, M6).
static func plating_for_pw(pw: int) -> int:
	var b := ContentDB.budget(pw)
	return clampi(RulesMath.round_half_up(b / maxf(1.0, knob("plating", "div", 12.0))),
		int(knob("plating", "min", 2.0)), int(knob("plating", "max", 4.0)))


static func has_rule(combat, rule: String) -> bool:
	return (combat.run_rules as Array).has(rule)


## Plating that counts RIGHT NOW for enemy `u` (0 = none): base (trait / affix / boss rhythm), R12 global floor
## (max, never added), boss only on prep/strike turns, non-boss wears down from plating.decay_turn, 0 while a
## debuff/poison keeps it off.
static func plating_of(combat, u: Unit) -> int:
	if u == null or u.side != "e" or u.hp <= 0:
		return 0
	var p := u.plating
	if has_rule(combat, "R12"):
		p = maxi(p, int(knob("run_rules", "plating_global", 2.0)))
	if p <= 0 or u.plating_off > 0:
		return 0
	if u.is_boss:
		var ph: String = combat.boss_rhythm_phase(u)
		if ph != "prep" and ph != "strike":
			return 0
	else:
		p -= maxi(0, int(combat.turn) - int(knob("plating", "decay_turn", 7.0)) + 1)
	return maxi(0, p)


## Called when a debuff / poison lands on `tgt`: Plating off for plating.off_turns player turns (reset, not added).
static func on_debuff(combat, tgt: Unit) -> void:
	if tgt == null or tgt.side != "e" or tgt.hp <= 0:
		return
	if tgt.plating <= 0 and not tgt.is_boss and not has_rule(combat, "R12"):
		return
	tgt.plating_off = int(knob("plating", "off_turns", 2.0))
	EventBus.plating_off.emit(tgt.uid, tgt.plating_off)


## Start of every player turn (after the first): off-counters tick down, decay is announced.
static func turn_start(combat) -> void:
	var decay_turn := int(knob("plating", "decay_turn", 7.0))
	for raw in combat.enemies:
		var e: Unit = raw
		if e.hp <= 0:
			continue
		if e.plating_off > 0:
			e.plating_off -= 1
		if not e.is_boss and int(combat.turn) >= decay_turn and (e.plating > 0 or has_rule(combat, "R12")):
			EventBus.plating_decay.emit(e.uid, plating_of(combat, e))


## Single-target dmg after multipliers: cut by P, never below 1 (and never raised). Pure, used by the pipeline and
## by the UI preview.
static func reduce(combat, tgt: Unit, v: float) -> float:
	var p := plating_of(combat, tgt)
	if p <= 0 or v <= 1.0:
		return v
	return maxf(1.0, v - float(p))


## Gives the role traits (ContentDB enemy field `trait`: plating / ward / mend) to the freshly built monsters of a
## normal or elite fight. One trait per monster. Normal fight: at most `cap` bearers (early = before the first
## Elite), extra ones lose the trait from the highest slot down (deterministic). Elite fight: companions carry none
## (6.7b.6); the elite keeps its role trait unless an affix of group A replaces it (done by the affix start).
static func assign_traits(combat, units: Array, is_elite: bool, early: bool) -> void:
	var bearers: Array = []
	for i in units.size():
		var u: Unit = units[i]
		if is_elite and i > 0:
			continue
		var t := String((ContentDB.enemies.get(u.key, {}) as Dictionary).get("trait", ""))
		if t == "":
			continue
		bearers.append(u)
		u.custom_state["m_trait"] = t
	if not is_elite:
		var cap := int(knob("traits", "cap_early" if early else "cap_default", 1.0 if early else 2.0))
		while bearers.size() > cap:
			var last: Unit = bearers.pop_back()
			last.custom_state.erase("m_trait")
	var p := plating_for_pw(combat.pw)
	for raw in bearers:
		var b: Unit = raw
		if b.custom_state.has("m_trait") and String(b.custom_state["m_trait"]) == "plating":
			b.plating = p
