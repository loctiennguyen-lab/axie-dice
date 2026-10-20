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


# ---------------------------------------------------------------------------
# M2 Ward / M4 Mend: start of the enemy phase
# ---------------------------------------------------------------------------

## Shield a ward source hands out: S = min(ward.max, ward.base + floor(pw / ward.pw_div)).
static func ward_amount(pw: int) -> int:
	return mini(int(knob("ward", "max", 7.0)), int(knob("ward", "base", 3.0)) + int(floor(float(pw) / maxf(1.0, knob("ward", "pw_div", 4.0)))))


static func _has_debuff(u: Unit) -> bool:
	for k in ["poison", "burn", "weaken", "vulnerable", "blind", "stun"]:
		if int(u.status.get(k, 0)) > 0:
			return true
	return false


## Called once at the start of the enemy phase (CombatEngine.begin_end_turn), in enemy order.
static func enemy_phase_start(combat) -> void:
	for raw in (combat.enemies as Array).duplicate():
		var e: Unit = raw
		if e.hp <= 0:
			continue
		var t := String(e.custom_state.get("m_trait", ""))
		var a: Dictionary = combat._aff(e)
		if t == "ward":
			_ward(combat, e, false)
		if bool(a.get("ward_self", false)):
			_ward(combat, e, true)
		if t == "mend" or bool(a.get("mend", false)):
			_mend(combat, e)


static func _ward(combat, src: Unit, self_only: bool) -> void:
	if int(combat.turn) >= int(knob("plating", "decay_turn", 7.0)) and not src.is_boss:
		return                                  # anti-stall (6.7b.3): ward stops from the decay turn
	var amount := ward_amount(int(combat.pw))
	var tgt: Unit = src
	if self_only:
		amount = int(floor(float(amount) * knob("ward", "elite_mult", 1.5)))
	else:
		tgt = null
		for raw in combat.enemies:
			var u: Unit = raw
			if u.hp > 0 and (tgt == null or u.shield < tgt.shield):   # lowest shield, tie = smallest slot (strict <)
				tgt = u
		if tgt == null:
			return
	var room := int(knob("ward", "stack_cap_mult", 2.0)) * amount - tgt.shield
	var amt := mini(amount, room)
	if amt <= 0:
		return
	DamagePipeline.apply_shield(combat, tgt, amt)
	EventBus.ward.emit(src.uid, tgt.uid, amt)


static func _mend(combat, src: Unit) -> void:
	var tgt: Unit = null
	for raw in combat.enemies:
		var u: Unit = raw
		if u.hp <= 0:
			continue
		if tgt == null or float(u.hp) / maxf(1.0, float(u.max_hp)) < float(tgt.hp) / maxf(1.0, float(tgt.max_hp)):
			tgt = u
	if tgt == null or tgt.hp >= tgt.max_hp or _has_debuff(tgt):
		return                                  # a debuffed target is not mended (M4)
	var fight_cap := int(floor(float(src.max_hp) * knob("mend", "fight_cap_pct", 0.5)))
	var left := fight_cap - int(src.custom_state.get("mend_done", 0))
	var amt := mini(int(RulesMath.round_half_up(float(tgt.max_hp) * knob("mend", "pct", 0.2))), int(knob("mend", "cap", 6.0)))
	amt = mini(amt, mini(left, tgt.max_hp - tgt.hp))
	if amt <= 0:
		return
	var before := tgt.hp
	DamagePipeline.apply_heal(combat, tgt, amt)
	src.custom_state["mend_done"] = int(src.custom_state.get("mend_done", 0)) + (tgt.hp - before)
	EventBus.mend.emit(src.uid, tgt.uid, tgt.hp - before)


# ---------------------------------------------------------------------------
# M3 Spite: the 3rd single-target dmg face on the same enemy in one player turn hurts the Axie that used it
# ---------------------------------------------------------------------------

static func spite_damage(pw: int) -> int:
	return int(knob("spite", "dmg_hi", 3.0)) if pw >= int(knob("spite", "pw_step", 8.0)) else int(knob("spite", "dmg", 2.0))


static func on_single_hit(combat, attacker: Unit, tgt: Unit) -> void:
	if tgt == null or tgt.side != "e" or not bool(tgt.custom_state.get("spite", false)):
		return
	var n := int(combat.spite_hits.get(tgt.uid, 0)) + 1
	combat.spite_hits[tgt.uid] = n
	if n < int(knob("spite", "after", 3.0)) or tgt.hp <= 0 or attacker == null or attacker.hp <= 0:
		return
	var dmg := spite_damage(int(combat.pw))
	DamagePipeline.resolve({"combat": combat, "src": tgt, "tgt": attacker, "value": dmg, "pierce": true, "attack": false})
	EventBus.spite.emit(tgt.uid, attacker.uid, dmg, n)


# ---------------------------------------------------------------------------
# M5 Charged Strike (affix "charge", boss rhythm tell). Cycle = charge.period enemy turns: charge turn
# n % period == charge_at (public tell, no attack), strike turn n % period == (charge_at + 1) % period (strongest
# dmg face x charge.mult at the chosen Axie). Only stun / freeze (freeze on an enemy IS stun) on the charge turn
# breaks it; damage never does. A boss only borrows the tell + target lock on the prep turn before its strike: no
# x2.5, and a break turns the strike back into a plain roll. No rng: the target is the lowest HP+shield (tie =
# smallest slot) among the Axie the monster may hit.
# ---------------------------------------------------------------------------

static func charge_period() -> int:
	return maxi(2, int(knob("charge", "period", 4.0)))


static func charge_at() -> int:
	return int(knob("charge", "charge_at", 3.0)) % charge_period()


static func is_charge_turn(turn: int) -> bool:
	return turn % charge_period() == charge_at()


static func is_strike_turn(turn: int) -> bool:
	return turn % charge_period() == (charge_at() + 1) % charge_period()


static func _lowest_target(combat) -> Unit:
	var ps: Array = combat.alive_party()
	if ps.is_empty():
		return null
	var pool: Array = combat.front_row_targets(ps)
	return combat._lowest_by(pool, func(u: Unit) -> float: return float(u.hp + u.shield))


## Charge target of `e`: the locked one while alive, else re-picked by the same rule.
static func _locked_or_new(combat, e: Unit) -> Unit:
	var uid := int(e.custom_state.get("charge_target", -1))
	var t: Unit = combat.by_uid(uid) if uid >= 0 else null
	if t == null or t.hp <= 0 or t.side != "p":
		t = _lowest_target(combat)
	return t


static func _best_dmg_face(e: Unit) -> int:
	var best := -1
	var best_v := -1
	for i in e.die.size():
		var f: Dictionary = e.die[i]
		if String(f.get("type", "")) == "dmg" and int(f.get("value", 0)) > best_v:
			best_v = int(f.get("value", 0))
			best = i
	return best


## Called from roll_all after the intent of `e` is picked.
static func charge_roll(combat, e: Unit) -> void:
	if e.hp <= 0 or e.intent.is_empty():
		return
	if e.is_boss:
		var ph: String = combat.boss_rhythm_phase(e)
		if ph == "prep" and combat.boss_rhythm_phase(e, 1) == "strike":
			var t := _lowest_target(combat)
			if t != null:
				e.custom_state["charge_target"] = t.uid
				e.intent["charge"] = "tell"
				EventBus.charge_start.emit(e.uid, t.uid)
		elif ph == "strike":
			if not bool(e.custom_state.get("charge_broken", false)) and e.custom_state.has("charge_target"):
				var t2 := _locked_or_new(combat, e)
				var f: Dictionary = e.die[int(e.intent.get("face_index", 0))]
				if t2 != null and String(f.get("type", "")) == "dmg" and not CombatEngine._has_kw(f, "aoe") \
						and not CombatEngine._has_kw(f, "pierce"):
					e.intent["target_uid"] = t2.uid
			e.custom_state.erase("charge_target")
			e.custom_state.erase("charge_broken")
		return
	if not bool(combat._aff(e).get("charge", false)):
		return
	var turn: int = int(combat.turn)
	if is_charge_turn(turn):
		var t3 := _lowest_target(combat)
		if t3 == null:
			return
		e.custom_state["charge_target"] = t3.uid
		e.custom_state["charge_pending"] = true
		e.intent["charge"] = "start"
		e.intent["target_uid"] = t3.uid
		EventBus.charge_start.emit(e.uid, t3.uid)
	elif is_strike_turn(turn) and bool(e.custom_state.get("charge_pending", false)):
		e.custom_state["charge_pending"] = false
		var bi := _best_dmg_face(e)
		var t4 := _locked_or_new(combat, e)
		if bi >= 0 and t4 != null:
			e.set_roll(bi, false)
			e.heavy = CombatEngine._has_kw(e.die[bi], "heavy")
			e.intent = {"face_index": bi, "target_uid": t4.uid, "charge": "hit"}
		e.custom_state.erase("charge_target")
	else:
		e.custom_state["charge_pending"] = false


## Called when `e` is stunned at its action (freeze = stun on an enemy). Returns true when a charge was broken.
static func charge_on_stun(combat, e: Unit) -> bool:
	if String(e.intent.get("charge", "")) == "start":
		e.custom_state["charge_pending"] = false
		e.custom_state.erase("charge_target")
		EventBus.charge_break.emit(e.uid)
		return true
	if String(e.intent.get("charge", "")) == "tell":
		e.custom_state["charge_broken"] = true
		e.custom_state.erase("charge_target")
		EventBus.charge_break.emit(e.uid)
		return true
	return false


## True while the monster's strike is a charged one (elite only): _face_value multiplies by charge.mult.
static func charge_mult(e: Unit) -> float:
	if e != null and not e.is_boss and String(e.intent.get("charge", "")) == "hit":
		return knob("charge", "mult", 2.5)
	return 1.0


# ---------------------------------------------------------------------------
# 6.7b team_can_break, affix choice (6.4 rule), guarantee_tank (A.13)
# ---------------------------------------------------------------------------

const BREAK_KEYWORDS := ["pierce", "aoe", "stun", "freeze", "weaken", "vulnerable", "poison"]
const AFFIX_SALT := 0x41F1C5


static func _faces_of(entry) -> Array:
	if entry is Unit:
		return (entry as Unit).die
	if entry is Array:
		return entry
	if entry is Dictionary:
		var d: Dictionary = entry
		if d.has("die"):
			return d["die"] as Array
		var die: Array = ((ContentDB.heroes.get(String(d.get("hero_key", "")), {}) as Dictionary).get("die", []) as Array).duplicate(true)
		for m in (d.get("muts", []) as Array):
			if String(m.get("type", "")) == "part":
				var idx := int(m.get("idx", -1))
				if idx >= 0 and idx < die.size():
					die[idx] = (m.get("face", {}) as Dictionary)
		return die
	return []


## 6.7b: can this team strip Plating? True when any face of any die is poison / debuff or carries pierce, aoe,
## stun, freeze, weaken, vulnerable or poison:N. `team` entries: Unit, a die (Array of faces), a Dictionary with
## "die", or a roster entry (hero_key + muts). Pure, deterministic, no rng.
static func team_can_break(team: Array) -> bool:
	for entry in team:
		for raw in _faces_of(entry):
			var f: Dictionary = raw
			var t := String(f.get("type", ""))
			if t == "poison" or t == "debuff":
				return true
			for k in (f.get("keywords", []) as Array):
				if BREAK_KEYWORDS.has(String(k).split(":")[0]):
					return true
	return false


static func affix_forbidden(a: String, b: String) -> bool:
	for pr in (ContentDB.elite_affix_meta.get("forbidden_pairs", []) as Array):
		if (pr[0] == a and pr[1] == b) or (pr[0] == b and pr[1] == a):
			return true
	return false


static func _affix_ids(group: String, can_break: bool) -> Array:
	var ids: Array = []
	for id in ContentDB.elite_affixes:
		var a: Dictionary = ContentDB.elite_affixes[id]
		if bool(a.get("retired", false)) or String(a.get("group", "")) != group:
			continue
		if group == "A" and not can_break and not bool(a.get("no_break_ok", false)):
			continue
		ids.append(String(id))
	ids.sort()                                  # fixed order, independent of dictionary order
	return ids


## 6.4 rule. Returns {"affix": id, "affix2": id or ""}. Elite before boss 1 (after_boss1 false): one group A
## affix. After boss 1: A + one group B, skipping forbidden pairs (charge+rush, charge+frenzy). Team that cannot
## break Plating draws A only from no_break_ok. First run of the account: fixed iron (ward when it cannot break),
## no B. Draws come from a private Rng(seed ^ AFFIX_SALT): the run's shared rng is never touched.
static func choose_affixes(seed_value: int, can_break: bool, after_boss1: bool, first_run: bool = false) -> Dictionary:
	if first_run:
		var fr: Dictionary = ContentDB.elite_affix_meta.get("first_run", {})
		return {"affix": String(fr.get("default", "iron")) if can_break else String(fr.get("no_break", "ward")), "affix2": ""}
	var r := Rng.new(seed_value ^ AFFIX_SALT)
	var pool_a := _affix_ids("A", can_break)
	if pool_a.is_empty():
		return {"affix": "", "affix2": ""}
	var a: String = pool_a[r.next_int(pool_a.size())]
	var b := ""
	if after_boss1:
		var pool_b: Array = []
		for id in _affix_ids("B", can_break):
			if not affix_forbidden(a, String(id)):
				pool_b.append(id)
		if not pool_b.is_empty():
			b = String(pool_b[r.next_int(pool_b.size())])
	return {"affix": a, "affix2": b}


## A.13: a normal fight before the first Elite must hold one plating tank (so the player meets Plating where it
## costs nothing). Replaces the last monster by the cheapest available tank when none is present, then puts the tank in slot 0 so the early trait cap keeps it. Deterministic.
static func guarantee_tank(keys: Array, avail: Array) -> Array:
	var tank_keys: Array = []
	for k in avail:
		var d: Dictionary = ContentDB.enemies.get(k, {})
		if String(d.get("trait", "")) == "plating":
			tank_keys.append(k)
	if tank_keys.is_empty() or keys.is_empty():
		return keys
	var out := keys.duplicate()
	var at := -1
	for i in out.size():
		if tank_keys.has(out[i]):
			at = i
			break
	if at < 0:
		at = out.size() - 1
		out[at] = tank_keys[tank_keys.size() - 1]             # avail is sorted cost DESC: last = cheapest
	var first = out[0]                                         # slot 0: assign_traits trims the highest slots first
	out[0] = out[at]
	out[at] = first
	return out


# ---------------------------------------------------------------------------
# R12 Vo Cung side bonus: shield, poison and debuff faces of the Axie are +run_rules.side_face_bonus
# (R13 The Can Bang is NOT here: lane C does it through the Core hook, doing it twice would double the cut).
# ---------------------------------------------------------------------------

static func side_bonus() -> int:
	return int(knob("run_rules", "side_face_bonus", 2.0))


## Extra value for a shield / poison face (value > 0) of a party unit while R12 is active; 0 otherwise.
static func side_face_bonus(combat, u: Unit, face_type: String, v: float) -> int:
	if u == null or u.side != "p" or v <= 0.0 or not has_rule(combat, "R12"):
		return 0
	return side_bonus() if (face_type == "shield" or face_type == "poison") else 0


## Debuff faces carry their strength in the keyword ("weaken:2"): R12 raises every numeric one by the bonus
## (stun / freeze have no number and stay as they are).
static func side_bonus_keywords(combat, u: Unit, face_type: String, kws: Array) -> Array:
	if u == null or u.side != "p" or face_type != "debuff" or not has_rule(combat, "R12"):
		return kws
	var out: Array = []
	for raw in kws:
		var ks := String(raw)
		var parts := ks.split(":")
		if parts.size() == 2 and ["weaken", "vulnerable", "blind", "burn", "poison"].has(parts[0]) and parts[1].is_valid_int():
			out.append("%s:%d" % [parts[0], int(parts[1]) + side_bonus()])
		else:
			out.append(ks)
	return out
