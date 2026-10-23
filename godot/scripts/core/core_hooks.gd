class_name CoreHooks
extends RefCounted
## Depth v3 Core (Loi) + Run Rule behaviour (design/proposals/depth-v3-design.md 2.7, 2.10, 2b.2; lane C).
##
## Every function is a static handler that RelicHooks.TABLE points at (entries "c_<slug>" / "rule_<slug>").
## Rules of this file:
##  - Pure side effects through hooks that already exist (no combat_engine / damage_pipeline edits).
##  - `face_final` handlers NEVER mutate state: the UI previews values through _face_value().
##  - Per-turn counters live in combat.relic_combat via turn_state() (snapshot/undo safe, string keys only).
##  - Run-long counters live in combat.relic_run_out (see Mai Lon Dan / Mach Ngam, later batches).

const DMG_TYPES := ["dmg"]
const VALUE_TYPES := ["dmg", "shield", "heal", "poison", "mana"]
const DEBUFF_KW := ["weaken", "vulnerable", "blind", "freeze", "stun"]


## Per-turn dictionary: reset when the turn number changes. Always re-fetch, never keep across calls.
static func turn_state(combat, key: String) -> Dictionary:
	var d = combat.relic_combat.get(key, null)
	if not (d is Dictionary) or int((d as Dictionary).get("_t", -1)) != int(combat.turn):
		d = {"_t": int(combat.turn)}
		combat.relic_combat[key] = d
	return d


## Run-of-combat dictionary (not reset per turn).
static func combat_state(combat, key: String) -> Dictionary:
	var d = combat.relic_combat.get(key, null)
	if not (d is Dictionary):
		d = {}
		combat.relic_combat[key] = d
	return d


static func living_axies(combat) -> Array:
	var out: Array = []
	for u in combat.party:
		if u.hp > 0 and not u.is_token:
			out.append(u)
	return out


static func _first_living(combat):
	var a := living_axies(combat)
	return a[0] if not a.is_empty() else null


## depth v3 lane FX: a Core DID something that changed the outcome. Never fires for amount <= 0.
## kind: dmg thorns poison shield block heal mana reroll quest_step (CoreFeedback.KINDS) or "rule" (changed a rule / build).
## While > 0 `fire` is silent: UI previews / forecasts / look-ahead simulations raise it (see CombatEngine.preview_damage),
## so a Core only counts when it really acted. Combat hooks that have the engine at hand use `_fire_live` (core_emit);
## this mute is the catch-all for every direct `fire` call reachable from a preview.
static var mute: int = 0


static func fire(core_id: String, unit_uid: int, amount: int, kind: String) -> void:
	if mute <= 0 and core_id != "" and amount > 0:
		EventBus.core_fired.emit(core_id, unit_uid, amount, kind)


## True while CombatEngine._do_face computes the value it is about to APPLY (not a UI preview / forecast).
static func live(combat) -> bool:
	return combat != null and "core_emit" in combat and bool(combat.core_emit)


static func _fire_live(combat, id: String, uid: int, amount: int, kind: String) -> void:
	if live(combat):
		fire(id, uid, amount, kind)


static func gain_mana(combat, n: int, label: String = "", core: String = "") -> void:
	if n <= 0:
		return
	combat.mana += n
	fire(core, 0, n, "mana")
	var u = _first_living(combat)
	if u != null:
		EventBus.float_text.emit(u.uid, label if label != "" else "+%d MP" % n, "man", 0)


## Category of a face for "different face types" counting (Prism, Collector).
static func face_category(face: Dictionary) -> String:
	var t := String(face.get("type", ""))
	for kw in (face.get("keywords", []) as Array):
		if DEBUFF_KW.has(String(kw).split(":")[0]):
			return "debuff"
	return t


## True when `u` holds the only die still usable this turn (the "Ket" / finishing die).
static func is_finisher(combat, u) -> bool:
	if u.side != "p" or u.hp <= 0 or not u.has_rolled() or u.roll_used() or u.held:
		return false
	# Three Dice: the die that makes the 3rd use is the last one (the rest get Held right after it).
	if RelicHooks_has(combat, "c_three_dice") and int(turn_state(combat, "cs_three").get("n", 0)) >= 2:
		return true
	for o in combat.party:
		if o == u or o.hp <= 0:
			continue
		if mirror_second(combat, o):
			continue   # Mirror Face: a die waiting for its second use does not block the Final Blow of another die
		if o.has_rolled() and not o.roll_used() and not o.held:
			return false
	return true


static func finisher_bonus(combat, u) -> int:
	if not is_finisher(combat, u):
		return 0
	return mini(4, int(turn_state(combat, "cs_used").get("n", 0)))


# --------------------------------------------------------------------------------------------
# stat
# --------------------------------------------------------------------------------------------

static func early_scales_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for u in living_axies(combat):
		if combat.row_of(u) == 0:
			DamagePipeline.apply_shield(combat, u, 5)
			fire("c_early_scales", u.uid, 5, "shield")


## Sacrifice: the Axie in slot 5 sleeps for the whole fight (no die, never targeted, not counted for a wipe).
static func sacrifice_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for u in combat.party:
		if u.roster_index == 4 and not u.is_token:
			u.custom_state["asleep"] = true
			u.held = false
			u.clear_roll()
			EventBus.float_text.emit(u.uid, "ZZZ", "buf", 0)
			fire("c_sacrifice", u.uid, 1, "rule")


## Take The Field: the back-row Axie with the most heal faces (ties: lowest slot) is the one that descends.
static func descend_pick(ctx: Dictionary) -> int:
	var combat = ctx["combat"]
	var best := -1
	var best_n := 0
	var fs: int = combat.front_row_size()
	var roster: Array = ctx["roster"]
	for i in range(fs, roster.size()):
		var e: Dictionary = roster[i]
		var die: Array = ((ContentDB.heroes.get(String(e.get("hero_key", "")), {}) as Dictionary).get("die", []) as Array).duplicate(true)
		for m in (e.get("muts", []) as Array):
			if String(m.get("type", "")) == "part" and int(m.get("idx", -1)) >= 0 and int(m.get("idx", -1)) < die.size():
				die[int(m["idx"])] = m.get("face", {})
		var n := 0
		for f in die:
			if String((f as Dictionary).get("type", "")) == "heal":
				n += 1
		if n > best_n:
			best_n = n
			best = i
	return best


static func is_descended(combat, u) -> bool:
	var d = combat.relic_combat.get("descend", null)
	return d is Dictionary and int((d as Dictionary)["idx"]) == u.roster_index and u.roster_index >= 0


static func descend_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	if not is_descended(ctx["combat"], u):
		return
	u.max_hp += 8
	fire("c_descend", u.uid, 8, "rule")
	for f in u.die:
		var ty := String((f as Dictionary).get("type", ""))
		if ty == "heal":
			f["type"] = "dmg"
			f["value"] = int(f.get("value", 0)) + 2
			_mark_converted(u, f)
		elif ty == "buff":
			f["type"] = "dmg"
			f["value"] = 2
			f["keywords"] = []
			_mark_converted(u, f)


static func _mark_converted(u, f: Dictionary) -> void:
	var l: Array = u.custom_state.get("desc_fi", [])
	l.append(u.die.find(f))
	u.custom_state["desc_fi"] = l


static func descend_hit(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var d := int(ctx.get("dealt", 0))
	if d > 0 and is_descended(ctx["combat"], u) and u.hp > 0:
		var hp0: int = u.hp
		DamagePipeline.apply_heal(ctx["combat"], u, int(ceil(d * 0.3)))
		fire("c_descend", u.uid, u.hp - hp0, "heal")


## Value of a knob on a held Run Rule / Core definition (rule_knobs), else `default`.
static func rule_knob(id: String, key: String, default):
	var d = RelicRegistry.get_def(id)
	if d == null:
		return default
	return (d.rule_knobs as Dictionary).get(key, default)


## Bastion: front-row Axies take 2 less from single-target hits (min 1). Rising Tide (front fights): 25% less.
## `id` = the owner whose TABLE entry is running (each owner applies only its own part, so owning two of them does
## not apply the others twice).
static func incoming(ctx: Dictionary, id: String = "") -> float:
	var combat = ctx["combat"]
	var tgt = ctx["tgt"]
	var v0 := float(ctx["value"])
	var v := v0
	if tgt.side == "e":
		if id == "c_fissure" and int(tgt.custom_state.get("fissure", -1)) >= int(combat.turn):
			v = ceil(v * 1.25)
			fire(id, tgt.uid, int(v - v0), "dmg")
		if id == "rule_pack_alpha":
			v = alpha_incoming(ctx, v)
		return v
	if tgt.is_token or combat.row_of(tgt) != 0:
		return v
	if id == "c_bastion" and bool(ctx.get("single", false)) and not bool(ctx.get("pierce", false)) and bool(ctx.get("attack", false)):
		v = maxf(1.0, v - 2.0)
	if id == "rule_rising_tide" and String(combat_state(combat, "tide").get("water", "")) == "front":
		v = maxf(1.0, ceil(v * float(rule_knob("rule_rising_tide", "front_dmg_taken", 0.75))))
	fire(id, tgt.uid, int(v0 - v), "block")
	return v


static func RelicHooks_has(combat, id: String) -> bool:
	return (combat.relic_ids as Array).has(id)


## Rising Tide: the water alternates by fight (counter in the run state): even fights the front is in the water.
static func tide_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var n := int((combat.relic_run_in.get("rule_rising_tide", {}) as Dictionary).get("n", 0))
	combat_state(combat, "tide")["water"] = "front" if n % 2 == 0 else "back"
	combat.relic_run_out["rule_rising_tide"] = {"n": n + 1}


## Fissure: a poison face that hits marks the enemy (+25% from all damage until the end of next turn) and strips Plating.
static func fissure_used(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var f: Dictionary = ctx["face"]
	if String(ctx.get("side", "")) != "p" or not ["poison", "debuff"].has(face_category(f)):
		return
	var targets: Array = combat.alive_enemies() if _has_kw(f, "aoe") else [combat.by_uid(int(ctx.get("target_uid", -1)))]
	for t in targets:
		if t != null and t.side == "e" and t.hp > 0:
			t.custom_state["fissure"] = int(combat.turn) + 1
			t.plating_off = maxi(int(t.plating_off), 2)
			EventBus.float_text.emit(t.uid, "FISSURE", "deb", 0)
			fire("c_fissure", t.uid, 1, "rule")


## Nest: start of combat one Egg, and Eggs stand in the front row (single-target attacks can pick them).
static func nest_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	combat.relic_combat["eggs_front"] = true
	if combat._count_alive_tokens(combat.party) < int(RelicHooks.max_val(combat, "tokenCap", 4.0)):
		var egg = combat._mk_ally()
		combat.party.append(egg)
		EventBus.unit_spawned.emit(egg.uid)
		fire("c_nest", egg.uid, 1, "rule")


## Deep Current: up to 12 leftover Mana of a won fight are paid out at the start of the next one.
static func deep_current_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var m := int((combat.relic_run_in.get("c_deep_current", {}) as Dictionary).get("mana", 0))
	combat.relic_run_out["c_deep_current"] = {"mana": 0}
	if m > 0:
		gain_mana(combat, m, "+%d MP (carried)" % m, "c_deep_current")


static func deep_current_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var keep := mini(12, int(combat.mana)) if String(ctx.get("result", "")) == "won" else 0
	combat.relic_run_out["c_deep_current"] = {"mana": keep}


## Growing Shell: stacks (+1 Max HP each) per roster Axie live in relic_state; a kill by a front-row Axie adds one,
## falling drops the stacks to a third (rounded up). Applied at build time (mod_face).
static func shell_face(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var u = ctx["unit"]
	var n := int(((combat.relic_run_in.get("c_growing_shell", {}) as Dictionary)).get(str(u.uid), 0))
	u.max_hp += n
	fire("c_growing_shell", u.uid, n, "rule")


static func _shell_stacks(combat) -> Dictionary:
	var d = combat.relic_run_out.get("c_growing_shell", null)
	if not (d is Dictionary):
		d = {}
		combat.relic_run_out["c_growing_shell"] = d
	return d


static func shell_kill(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var k = ctx.get("killer", null)
	if k == null or k.side != "p" or k.is_token or k.hp <= 0 or combat.row_of(k) != 0:
		return
	var st := _shell_stacks(combat)
	st[str(k.uid)] = int(st.get(str(k.uid), 0)) + 1
	k.max_hp += 1
	k.hp += 1
	EventBus.float_text.emit(k.uid, "+1 MAX HP", "buf", 0)
	fire("c_growing_shell", k.uid, 1, "rule")


static func shell_fall(ctx: Dictionary) -> void:
	if not fell_now(ctx):
		return
	var st := _shell_stacks(ctx["combat"])
	var key := str(ctx["tgt"].uid)
	var n := int(st.get(key, 0))
	if n > 0:
		st[key] = n - int(ceil(2.0 * n / 3.0))   # loses ceil(2n/3) of the stacks (design 2.7)


static func dewdrop_turn(ctx: Dictionary) -> void:
	gain_mana(ctx["combat"], 1, "", "c_dewdrop")


static func elder_trunk_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	u.max_hp += 8
	fire("c_elder_trunk", u.uid, 8, "rule")
	for f in u.die:
		if String((f as Dictionary).get("type", "")) == "dmg" and int(f.get("value", 0)) > 0:
			f["value"] = maxi(1, int(f["value"]) - 1)


# --------------------------------------------------------------------------------------------
# dice
# --------------------------------------------------------------------------------------------

## Giu Vung: 2 held dice, and the same die may be held two turns in a row.
static func steady_hold_cap(ctx: Dictionary) -> int:
	return int(ctx["value"]) + 1


## Giu Vung (LF2, R8): a Held die gains +1 per turn it has been held (max +3, tune core.steady_hold_max), reset when used.
## Same storage as Kindle's Focus, own key; `n` counts consecutive held turns.
static func steady_hold_stash(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var st := combat_state(ctx["combat"], "focus_c_steady_hold")
	var prev := int((st.get(str(u.uid), {}) as Dictionary).get("n", 0)) if u.stash_carry else 0
	var n := prev + 1
	st[str(u.uid)] = {"n": n, "v": mini(n, int(CombatEngine.tune_knob("core", "steady_hold_max", 3.0))), "fi": int(ctx.get("fi", u.roll_face_index()))}


## Cat Lua: a Held die gets Focus. Value = 4 per consecutive held turn (max 8). Stored per die with the
## face index it was held on, applied by kindle_value() while that die is carried over.
static func kindle_stash(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var st := combat_state(ctx["combat"], "focus_c_kindle")
	var chain := 2 if u.stash_carry else 1
	st[str(u.uid)] = {"v": 4 * mini(chain, 2), "fi": int(ctx.get("fi", u.roll_face_index()))}


static func focus_value(combat, key: String, u, face_type: String) -> int:
	if u.side != "p" or not u.stash_carry or not VALUE_TYPES.has(face_type):
		return 0
	var e = combat_state(combat, key).get(str(u.uid), null)
	if e == null or int((e as Dictionary).get("fi", -2)) != u.roll_face_index():
		return 0
	return int((e as Dictionary).get("v", 0))


static func focus_spent(combat, key: String, u) -> void:
	combat_state(combat, key).erase(str(u.uid))


static func kindle_value(ctx: Dictionary) -> int:
	return int(ctx["value"]) + focus_value(ctx["combat"], "focus_c_kindle", ctx["unit"], String(ctx.get("face_type", "")))


## Chuoi Moi: shield / mana faces prime the neighbouring Axies' next damage face this turn (+3).
static func prime_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var combat = ctx["combat"]
	var u = ctx["unit"]
	var t := String((ctx["face"] as Dictionary).get("type", ""))
	var st := turn_state(combat, "cs_prime")
	if t == "dmg":
		st.erase(str(u.uid))
	elif t == "shield" or t == "mana":
		for n in RelicHooks.slot_neighbors(combat, u):
			st[str(n.uid)] = int(st.get(str(n.uid), 0)) + 3


static func prime_value(ctx: Dictionary) -> int:
	var u = ctx["unit"]
	if u.side != "p" or String(ctx.get("face_type", "")) != "dmg":
		return int(ctx["value"])
	return int(ctx["value"]) + int(turn_state(ctx["combat"], "cs_prime").get(str(u.uid), 0))


## Count dice used this turn (shared by Final Blow, Prism-style cores).
static func count_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var st := turn_state(ctx["combat"], "cs_used")
	var k := "u%d" % ctx["unit"].uid
	if st.has(k):
		return   # Mirror Face: the second use of one die is not another die
	st[k] = true
	st["n"] = int(st.get("n", 0)) + 1


## Ket Cuc: the last die used gets +1 per die used before it (max +4).
static func finisher_value(ctx: Dictionary) -> int:
	var ft := String(ctx.get("face_type", ""))
	if not (ft == "dmg" or ft == "shield" or ft == "heal" or ft == "poison"):
		return int(ctx["value"])
	return int(ctx["value"]) + finisher_bonus(ctx["combat"], ctx["unit"])


## Da Sac: remember which face categories were used this turn.
static func note_category(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var st := turn_state(ctx["combat"], "cs_types")
	var cat := face_category(ctx["face"])
	if cat != "" and cat != "blank":
		st[cat] = true


## Concord: remember the part of the last face used this turn (a cantrip resolved at roll time does not count).
static func concord_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0 or _has_kw(ctx["face"], "cantrip"):
		return
	turn_state(ctx["combat"], "cs_concord")["part"] = String((ctx["face"] as Dictionary).get("part", ""))


static func prism_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var st := turn_state(combat, "cs_types")
	var n := 0
	for k in st.keys():
		if k != "_t" and ["dmg", "shield", "heal", "poison", "mana", "debuff"].has(String(k)):
			n += 1
	if n < 4:
		return
	for u in living_axies(combat):
		DamagePipeline.apply_shield(combat, u, 3)
		fire("c_prism", u.uid, 3, "shield")
	gain_mana(combat, 2, "", "c_prism")


# --------------------------------------------------------------------------------------------
# mana
# --------------------------------------------------------------------------------------------

## Ho Mana: mana faces +1 ...
static func mana_pool_value(ctx: Dictionary) -> int:
	if ctx["unit"].side == "p" and String(ctx.get("face_type", "")) == "mana":
		return int(ctx["value"]) + 1
	return int(ctx["value"])


## ... and interest at end of turn: 1 per 3 unspent Mana, max +3.
static func mana_pool_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	gain_mana(combat, mini(3, int(combat.mana) / 3), "", "c_mana_pool")


## Ngon Trieu: every 2 Mana spent (reroll or active) deals 2 damage to all enemies.
static func tide_spent(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var cost := int(ctx.get("cost", 0))
	if cost <= 0:
		return
	var st := combat_state(combat, "tide_acc")
	var acc := int(st.get("n", 0)) + cost
	while acc >= 2:
		acc -= 3
		for e in combat.alive_enemies().duplicate():
			fire("c_tidecaller", e.uid, int(DamagePipeline.resolve({"combat": combat, "src": null, "tgt": e, "value": 2, "attack": false})), "dmg")
	st["n"] = acc


# --------------------------------------------------------------------------------------------
# Shared flat-bonus cap (design 3.4): the sum of flat bonuses Cores add to ONE face is at most +10.
# Each Core's flat bonus is a pure function bonus(); flat() adds it on top of the running value and only
# lets it use the room left after the bonuses of Cores owned BEFORE it (pickup order = hook order).
# Penalties (negative) are never capped.
# --------------------------------------------------------------------------------------------

const FLAT_CAP := 10
const FLAT_IDS := ["c_kindle", "c_steady_hold", "c_prime_chain", "c_finisher", "c_mana_pool", "c_three_dice", "c_field_medic",
	"c_plague_spread", "c_hollow_core", "c_thorn_pact", "c_cascade", "c_gatekeeper", "c_golden_egg",
	"rule_tundra", "rule_heavy_finish", "c_sacrifice", "c_concord", "rule_rising_tide", "rule_set_is_king", "rule_pilot_light"]


static func mirror_second(combat, u) -> bool:
	var st := turn_state(combat, "cs_mirror")
	return bool(st.get("second", false)) and int(st.get("uid", -1)) == u.uid


static func bonus(combat, u, ft: String, id: String, part: String = "") -> int:
	if u.side != "p" or u.is_token:
		return 0
	var val := VALUE_TYPES.has(ft)
	var sec := mirror_second(combat, u)
	match id:
		"c_kindle":
			return 0 if sec else focus_value(combat, "focus_c_kindle", u, ft)
		"c_three_dice":
			return 0 if sec else focus_value(combat, "focus_c_three_dice", u, ft)
		"c_steady_hold":
			return 0 if sec else focus_value(combat, "focus_c_steady_hold", u, ft)
		"rule_tundra":
			return 0 if sec else focus_value(combat, "focus_rule_tundra", u, ft)
		"c_prime_chain":
			return 0 if (sec or ft != "dmg") else int(turn_state(combat, "cs_prime").get(str(u.uid), 0))
		"c_finisher":
			return 0 if (sec or not (ft == "dmg" or ft == "shield" or ft == "heal" or ft == "poison")) else finisher_bonus(combat, u)
		"rule_set_is_king":
			if sec or not val:
				return 0
			return int(rule_knob("rule_set_is_king", "set_dice_bonus", 2)) if in_set(combat, u) else -int(rule_knob("rule_set_is_king", "nonset_penalty", 2))
		"rule_pilot_light":
			return 0 if sec else focus_value(combat, "focus_rule_pilot_light", u, ft)
		"rule_heavy_finish":
			return 0 if (sec or not val or not is_finisher(combat, u)) else 3
		"c_mana_pool":
			return 1 if ft == "mana" else 0
		"c_field_medic":
			return 3 if (ft == "heal" or ft == "shield" or ft == "poison" or ft == "mana") else 0
		"c_plague_spread":
			return 2 if ft == "poison" else 0
		"c_hollow_core":
			var b := 1 if ft == "mana" else 0
			if val:
				b += int(turn_state(combat, "cs_rr").get(str(u.uid), 0))
			return b
		"c_thorn_pact":
			return 2 if (val and u.hp * 2 <= u.max_hp) else 0
		"c_cascade":
			return 2 * mini(4, int(turn_state(combat, "cs_chain").get("n", 0))) if ft == "dmg" else 0
		"c_gatekeeper":
			return mini(6, int(combat_state(combat, "gk").get("b", 0))) if ft == "dmg" else 0
		"c_sacrifice":
			return 2 if val else 0
		"rule_rising_tide":
			return int(rule_knob("rule_rising_tide", "back_dmg", 2)) if (ft == "dmg" and combat.row_of(u) == 1 and String(combat_state(combat, "tide").get("water", "")) == "back") else 0
		"c_concord":
			return 2 if (not sec and val and part != "" and String(turn_state(combat, "cs_concord").get("part", "")) == part) else 0
		"c_golden_egg":
			return 3 if (ft == "dmg" and bool(combat_state(combat, "ge").get("on", false))) else 0
	return 0


## Flat bonuses baked into the face at build time (Hard Shell +2, Whittled Die +1, Take The Field +2): they are not
## face_final handlers, but they use the same +10 room, so every flat Core sees them as "already spent".
static func baked(combat, u, ft: String, fi: int) -> int:
	var b := 0
	if RelicHooks_has(combat, "rule_hard_shell") and u.side == "p":
		b += CombatTraits.side_face_bonus(combat, u, ft, 1.0)
	if fi >= 0 and fi < u.die.size():
		if RelicHooks_has(combat, "c_whittle") and fi != weakest_fi(u) and int((u.die[fi] as Dictionary).get("value", 0)) > 0:
			b += 1
		if (u.custom_state.get("desc_fi", []) as Array).has(fi):
			b += 2
	return b


## Gain of a x1.5 Core (Old Forest, Backline Glow), capped by combat_tune core.mult_cap so it cannot run away.
static func mult_gain(v: int) -> int:
	var up := int(ceil(v * 1.5))
	return v + mini(up - v, int(CombatEngine.tune_knob("core", "mult_cap", 8.0)))


## face_final handler body for every flat-bonus Core / rule.
static func flat(ctx: Dictionary, id: String) -> int:
	var combat = ctx["combat"]
	var u = ctx["unit"]
	var v := int(ctx["value"])
	var ft := String(ctx.get("face_type", ""))
	var part := String(ctx.get("part", ""))
	var own := bonus(combat, u, ft, id, part)
	if own <= 0:
		return v + own
	var before := baked(combat, u, ft, int(ctx.get("fi", -1)))
	for rid in combat.relic_ids:
		if String(rid) == id:
			break
		if FLAT_IDS.has(String(rid)):
			before += maxi(0, bonus(combat, u, ft, String(rid), part))
	var gain := mini(own, maxi(0, FLAT_CAP - before))
	_fire_live(combat, id, u.uid, gain, ft if VALUE_TYPES.has(ft) else "rule")
	return v + gain


## Total flat Core bonus a face would get right now (used by tests / UI).
static func flat_total(combat, u, ft: String, part: String = "", fi: int = -1) -> int:
	var t := baked(combat, u, ft, fi)
	for rid in combat.relic_ids:
		if FLAT_IDS.has(String(rid)):
			t += maxi(0, bonus(combat, u, ft, String(rid), part))
	return mini(FLAT_CAP, t)


# --------------------------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------------------------

static func _hit_enemy(combat, e, v: int, core: String = "", kind: String = "dmg") -> void:
	if v > 0 and e.hp > 0:
		var d := int(DamagePipeline.resolve({"combat": combat, "src": null, "tgt": e, "value": v, "pierce": true, "attack": false}))
		fire(core, e.uid, d, kind)


static func _has_kw(face: Dictionary, kw: String) -> bool:
	for k in (face.get("keywords", []) as Array):
		if String(k).split(":")[0] == kw:
			return true
	return false


## True the first time an Axie / Egg is seen fallen (on_dmg_taken, hp 0).
static func fell_now(ctx: Dictionary) -> bool:
	var t = ctx["tgt"]
	if t.side != "p" or t.hp > 0 or bool(t.custom_state.get("c_fell", false)):
		return false
	t.custom_state["c_fell"] = true
	return true


static func front_axies(combat) -> Array:
	var out: Array = []
	for u in living_axies(combat):
		if combat.row_of(u) == 0:
			out.append(u)
	return out


# --------------------------------------------------------------------------------------------
# dice (batch 2)
# --------------------------------------------------------------------------------------------

## Sonic Shield: a shield / heal face also deals half its value (round up) to the enemies targeting that Axie.
static func sonic_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var combat = ctx["combat"]
	var u = ctx["unit"]
	var face: Dictionary = ctx["face"]
	var t := String(face.get("type", ""))
	if t != "shield" and t != "heal":
		return
	var dmg := int(ceil(combat._face_value(u, int(ctx["fi"])) / 2.0))
	var tid := int(ctx.get("target_uid", -1))
	if tid < 0:
		tid = u.uid
	var aoe := _has_kw(face, "aoe")
	var hit_any := false
	for e in combat.alive_enemies().duplicate():
		if aoe or int(e.intent.get("target_uid", -2)) == tid:
			hit_any = true
			_hit_enemy(combat, e, dmg, "c_sonic_shield")
	if not hit_any:   # nobody targets that Axie: a random living enemy takes it
		var alive: Array = combat.alive_enemies()
		if not alive.is_empty():
			_hit_enemy(combat, alive[combat._rng.next_int(alive.size())], dmg, "c_sonic_shield")


static func field_medic_face(ctx: Dictionary) -> void:
	fire("c_field_medic", ctx["unit"].uid, 3, "rule")
	_dmg_minus(ctx["unit"], 2)
	for f in ctx["unit"].die:   # debuff faces carry their strength in the keyword ("weaken:2"): +3 on every numeric one
		if String((f as Dictionary).get("type", "")) == "debuff":
			f["keywords"] = _bump_keywords(f.get("keywords", []) as Array, 3)


static func _bump_keywords(kws: Array, n: int) -> Array:
	var out: Array = []
	for raw in kws:
		var parts := String(raw).split(":")
		if parts.size() == 2 and ["weaken", "vulnerable", "blind", "burn", "poison", "thorns", "regen"].has(parts[0]) and parts[1].is_valid_int():
			out.append("%s:%d" % [parts[0], int(parts[1]) + n])
		else:
			out.append(String(raw))
	return out


static func _dmg_minus(u, n: int) -> void:
	for f in u.die:
		if String((f as Dictionary).get("type", "")) == "dmg" and int(f.get("value", 0)) > 0:
			f["value"] = maxi(1, int(f["value"]) - n)


static func plague_kill(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var p := int(ctx["tgt"].status.get("poison", 0))
	if p <= 0:
		return
	for e in combat.alive_enemies().duplicate():
		if e != ctx["tgt"]:
			StatusEngine.add_status(combat, e, ["poison:%d" % p], null)
			fire("c_plague_spread", e.uid, p, "poison")


static func toxic_still_face(ctx: Dictionary) -> void:
	fire("c_toxic_still", ctx["unit"].uid, 2, "rule")
	_dmg_minus(ctx["unit"], 2)


static func toxic_still_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for e in combat.alive_enemies().duplicate():
		var p := int(e.status.get("poison", 0))
		if p > 0:
			var add := mini(4, int(ceil(p / 2.0)))
			StatusEngine.add_status(combat, e, ["poison:%d" % add], null)
			fire("c_toxic_still", e.uid, add, "poison")


## Mirror Face: the first die used each turn is not spent; its second use has no Prime / Finisher / Focus.
static func mirror_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	if _has_kw(ctx["face"], "cantrip"):
		return   # a cantrip resolved at roll time is not "the first die you use"
	var st := turn_state(ctx["combat"], "cs_mirror")
	var u = ctx["unit"]
	if st.has("uid"):
		if int(st["uid"]) == u.uid and bool(st.get("second", false)):
			st["second"] = false
		return
	st["uid"] = u.uid
	st["second"] = true
	u.clear_used_for_second_action()
	fire("c_mirror_face", u.uid, 1, "rule")


static func weakest_fi(u) -> int:
	var best := 0
	var bv := 1 << 30
	for i in u.die.size():
		var v := int((u.die[i] as Dictionary).get("value", 0))
		if String(u.die[i].get("type", "")) == "blank":
			v = 0
		if v < bv:
			bv = v
			best = i
	return best


## Whittled Die (per Axie, see report): every face but its weakest +1; a die rolling the weakest face rerolls once.
static func whittle_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var w := weakest_fi(u)
	for i in u.die.size():
		if i != w and int((u.die[i] as Dictionary).get("value", 0)) > 0:
			u.die[i]["value"] = int(u.die[i]["value"]) + 1
			fire("c_whittle", u.uid, 1, "rule")


static func whittle_roll(ctx: Dictionary) -> int:
	var fi := int(ctx["value"])
	var u = ctx["unit"]
	if u.side == "p" and not u.is_token and fi == weakest_fi(u):
		fire("c_whittle", u.uid, 1, "reroll")
		return ctx["combat"]._rng.next_int(6)
	return fi


## Three Dice: at most 3 dice per turn; the rest are Held automatically with Focus +3.
static func three_auto_hold(combat) -> void:
	var st := combat_state(combat, "focus_c_three_dice")
	for u in living_axies(combat):
		if u.held or not u.has_rolled() or u.roll_used() or u.frozen or _has_kw(u.current_face(), "cantrip"):
			continue
		u.held = true
		var fi: int = u.roll_face_index()
		st[str(u.uid)] = {"v": 3, "fi": fi}
		# 2b.3: an auto-Held die also earns the Focus of Kindle (+4, +8 on a second held turn) and Tundra (+2)
		if RelicHooks_has(combat, "c_kindle"):
			combat_state(combat, "focus_c_kindle")[str(u.uid)] = {"v": 4 * (2 if u.stash_carry else 1), "fi": fi}
		if RelicHooks_has(combat, "rule_tundra"):
			combat_state(combat, "focus_rule_tundra")[str(u.uid)] = {"v": 2, "fi": fi}
		EventBus.float_text.emit(u.uid, "HOLD", "buf", 0)
		fire("c_three_dice", u.uid, 1, "rule")


static func three_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var st := turn_state(ctx["combat"], "cs_three")   # counts every use, Mirror Face's second use included
	st["n"] = int(st.get("n", 0)) + 1
	if int(st["n"]) >= 3:
		three_auto_hold(ctx["combat"])


# --------------------------------------------------------------------------------------------
# pos (batch 2)
# --------------------------------------------------------------------------------------------

## Gatekeeper: single-target hits on a front-row Axie take 3 pierce thorns; each such hit feeds the team's next dmg face +2 (max +6).
static func gatekeeper_hit(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var src = ctx.get("src", null)
	var tgt = ctx["tgt"]
	if src == null or src.side != "e" or not bool(ctx.get("attack", false)) or tgt.is_token or combat.row_of(tgt) != 0:
		return
	if src.intent.is_empty() or src.hp <= 0:
		return
	var f: Dictionary = src.die[int(src.intent.get("face_index", 0))]
	if _has_kw(f, "aoe"):
		return
	var st := combat_state(combat, "gk")
	st["b"] = mini(6, int(st.get("b", 0)) + 2)
	_hit_enemy(combat, src, 3, "c_gatekeeper", "thorns")


static func gatekeeper_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) == "p" and String((ctx["face"] as Dictionary).get("type", "")) == "dmg":
		combat_state(ctx["combat"], "gk")["b"] = 0


static func gatekeeper_turn_end(ctx: Dictionary) -> void:
	combat_state(ctx["combat"], "gk")["b"] = 0   # hits taken AFTER this call feed the next turn


## True for an on_dmg_taken ctx that is a single-target enemy attack landing on a front-row Axie.
static func _single_hit_on_front(ctx: Dictionary) -> bool:
	var combat = ctx["combat"]
	var src = ctx.get("src", null)
	var tgt = ctx["tgt"]
	if src == null or src.side != "e" or not bool(ctx.get("attack", false)) or tgt.side != "p" or tgt.is_token or combat.row_of(tgt) != 0:
		return false
	if src.intent.is_empty() or src.hp <= 0:
		return false
	return not _has_kw(src.die[int(src.intent.get("face_index", 0))], "aoe")


## Thorn Growth (Gai Moc): each single-target hit on a front-row Axie gives that Axie +1 Thorns for the fight.
## Thorns never decay, and the +1 is in place before the same hit reflects.
static func thorn_growth_hit(ctx: Dictionary) -> void:
	if _single_hit_on_front(ctx):
		StatusEngine.add_status(ctx["combat"], ctx["tgt"], ["thorns:1"], null)
		fire("c_thorn_growth", ctx["tgt"].uid, 1, "thorns")


## Thorn Shield (Khien Gai): end of the player turn, every 2 leftover Shield of an Axie becomes 1 Thorns (that Shield is lost).
static func thorn_shield_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for u in living_axies(combat):
		var t: int = mini(int(u.shield) / 2, int(combat.tune_knob("thorn", "shield_transfer_cap", 6.0)))   # v4 N5: capped per Axie per transfer
		if t <= 0:
			continue
		u.shield -= t * 2
		EventBus.hp_changed.emit(u.uid, u.hp, u.max_hp, u.shield)
		StatusEngine.add_status(combat, u, ["thorns:%d" % t], null)
		fire("c_thorn_shield", u.uid, t, "thorns")


## Rebound (Phan Chan): the living Axie with the most Thorns (ties: lowest slot). null when nobody has any.
static func rebound_unit(combat):
	var best = null
	for u in living_axies(combat):
		var th := int(u.status.get("thorns", 0))
		if th > 0 and (best == null or th > int(best.status.get("thorns", 0))
				or (th == int(best.status.get("thorns", 0)) and u.roster_index < best.roster_index)):
			best = u
	return best


## thorns_extra value hook: that Axie reflects its current Thorns a second time.
static func rebound_extra(ctx: Dictionary) -> float:
	var combat = ctx["combat"]
	var tgt = ctx["tgt"]
	if tgt == rebound_unit(combat):
		fire("c_thorn_rebound", tgt.uid, int(tgt.status.get("thorns", 0)), "thorns")
		return float(ctx["value"]) + float(int(tgt.status.get("thorns", 0)))
	return float(ctx["value"])


## face_blocked value hook: the Rebound Axie cannot use damage faces.
static func rebound_blocked(ctx: Dictionary) -> bool:
	return bool(ctx["value"]) or ctx["unit"] == rebound_unit(ctx["combat"])


static func backline_value(ctx: Dictionary) -> int:
	var u = ctx["unit"]
	var ft := String(ctx.get("face_type", ""))
	if u.side == "p" and not u.is_token and (ft == "heal" or ft == "mana") and ctx["combat"].row_of(u) == 1:
		var g := mult_gain(int(ctx["value"]))
		_fire_live(ctx["combat"], "c_backline_glow", u.uid, g - int(ctx["value"]), ft)
		return g
	return int(ctx["value"])


## Backline Glow also lifts the numeric keywords of back-row buff faces by 50% (rounded up, same cap).
static func backline_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	if u.side != "p" or u.is_token or ctx["combat"].row_of(u) != 1:
		return
	for f in u.die:
		if String((f as Dictionary).get("type", "")) != "buff":
			continue
		var out: Array = []
		for raw in (f.get("keywords", []) as Array):
			var parts := String(raw).split(":")
			if parts.size() == 2 and parts[1].is_valid_int():
				out.append("%s:%d" % [parts[0], mult_gain(int(parts[1]))])
				fire("c_backline_glow", u.uid, mult_gain(int(parts[1])) - int(parts[1]), "rule")
			else:
				out.append(String(raw))
		f["keywords"] = out


static func living_wall_face(ctx: Dictionary) -> void:
	if ctx["unit"].roster_index == 0:
		ctx["unit"].max_hp += 12
		fire("c_living_wall", ctx["unit"].uid, 12, "rule")


static func living_wall_start(ctx: Dictionary) -> void:
	for u in living_axies(ctx["combat"]):
		if u.roster_index == 0:
			StatusEngine.add_status(ctx["combat"], u, ["thorns:2"], null)
			fire("c_living_wall", u.uid, 2, "thorns")


# --------------------------------------------------------------------------------------------
# mana (batch 2)
# --------------------------------------------------------------------------------------------

static func mana_ward_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var chunks := mini(6, int(combat.mana)) / 2
	if chunks <= 0:
		return
	combat.mana -= chunks * 2
	for u in front_axies(combat):
		DamagePipeline.apply_shield(combat, u, 3 * chunks)
		fire("c_mana_ward", u.uid, 3 * chunks, "shield")


static func overflow_check(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var ex := int(combat.mana) - 8
	if ex <= 0:
		return
	combat.mana = 8
	for e in combat.alive_enemies().duplicate():
		_hit_enemy(combat, e, ex, "c_overflow")


## v4: hollow_core / cheap_mana make a paid reroll 1 Mana cheaper than the knob price (reroll.mana_cost_2/_3), never below 1:
## a free Safe reroll would let these Cores farm mana from rerolled mana faces (A+ review).
static func reroll_cheaper(ctx: Dictionary) -> int:
	var v := int(ctx["value"])
	return v if v <= 1 else v - 1


## v4: hollow_core / cheap_mana lift the hard per-turn reroll cap (reroll.hard_cap) by reroll.core_hard_cap_add, or the cap of 4 would eat their gain.
static func reroll_cap_up(ctx: Dictionary) -> int:
	return int(ctx["value"]) + int(ctx["combat"].tune_knob("reroll", "core_hard_cap_add", 1.0))


## Hollow Core: reroll costs 1 Mana, up to 8 a turn (the engine cap counts each second paid reroll as free).
static func hollow_paid(ctx: Dictionary) -> void:
	if int(ctx.get("rmode", 1)) != 1:
		return   # Lieu (rmode 0) is free and is never discounted: only a mana-paid Safe reroll counts
	var combat = ctx["combat"]
	var st := turn_state(combat, "cs_paid")
	st["n"] = int(st.get("n", 0)) + 1
	fire("c_hollow_core", 0, 1, "reroll")
	if int(st["n"]) % 2 == 0:
		combat.reroll_paid_k = maxi(0, combat.reroll_paid_k - 1)


static func rerolled_count(ctx: Dictionary) -> void:
	var st := turn_state(ctx["combat"], "cs_rr")
	for uid in (ctx.get("rerolled_uids", []) as Array):
		st[str(uid)] = int(st.get(str(uid), 0)) + 1


## Thorn Pact: a reroll costs 2 HP of each rerolled Axie (refused at 2 HP or less).
static func thorn_allowed(ctx: Dictionary) -> bool:
	return bool(ctx["value"]) and int(ctx["unit"].hp) > 2


static func thorn_settled(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for uid in (ctx.get("rerolled_uids", []) as Array):
		var u = combat.by_uid(int(uid))
		if u != null and u.hp > 2:
			u.hp -= 2
			EventBus.float_text.emit(u.uid, "-2", "dmg", 0)
			fire("c_thorn_pact", u.uid, 1, "reroll")
			EventBus.hp_changed.emit(u.uid, u.hp, u.max_hp, u.shield)


# --------------------------------------------------------------------------------------------
# rule-axis Cores (batch 2)
# --------------------------------------------------------------------------------------------

static func golden_egg_fall(ctx: Dictionary) -> void:
	var t = ctx["tgt"]
	if not (t.is_token and t.key == "egg") or not fell_now(ctx):
		return
	golden_egg_trigger(ctx["combat"])


## Golden Egg payout, shared by an Egg dying and an Egg hatching (summon face / Broodmother).
static func golden_egg_trigger(combat) -> void:
	gain_mana(combat, 3, "", "c_golden_egg")
	var w = null
	for u in living_axies(combat):
		if w == null or u.hp + u.shield < w.hp + w.shield:
			w = u
	if w != null:
		DamagePipeline.apply_shield(combat, w, 4)
		fire("c_golden_egg", w.uid, 4, "shield")
	combat_state(combat, "ge")["on"] = true


static func golden_egg_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) == "p" and String((ctx["face"] as Dictionary).get("type", "")) == "dmg":
		combat_state(ctx["combat"], "ge")["on"] = false


## Blood Sign: dmg dealt adds 1 poison per 3 (down); poison faces also deal half their value.
static func blood_hit(ctx: Dictionary) -> void:
	if String((ctx["face"] as Dictionary).get("type", "")) != "dmg":
		return
	var n := int(ctx.get("dealt", 0)) / 3
	if n > 0 and ctx["tgt"].hp > 0:
		StatusEngine.add_status(ctx["combat"], ctx["tgt"], ["poison:%d" % n], ctx["unit"])
		fire("c_blood_sign", ctx["tgt"].uid, n, "poison")


static func blood_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var face: Dictionary = ctx["face"]
	if String(face.get("type", "")) != "poison":
		return
	var combat = ctx["combat"]
	var dmg := int(ceil(combat._face_value(ctx["unit"], int(ctx["fi"])) / 2.0))
	if _has_kw(face, "aoe"):
		for e in combat.alive_enemies().duplicate():
			_hit_enemy(combat, e, dmg, "c_blood_sign")
	else:
		var t = combat.by_uid(int(ctx.get("target_uid", -1)))
		if t != null and t.side == "e":
			_hit_enemy(combat, t, dmg, "c_blood_sign")


static func cascade_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var st := turn_state(ctx["combat"], "cs_chain")
	if String((ctx["face"] as Dictionary).get("type", "")) == "dmg":
		st["n"] = int(st.get("n", 0)) + 1
	else:
		st["n"] = 0


static func spore_fall(ctx: Dictionary) -> void:
	if not fell_now(ctx):
		return
	var combat = ctx["combat"]
	var half: bool = ctx["tgt"].is_token
	for e in combat.alive_enemies().duplicate():
		var pct := 0.08 if e.is_boss else 0.2
		if half:
			pct *= 0.5
		var hp0: int = e.hp
		e.hp = maxi(0, e.hp - int(ceil(e.max_hp * pct)))
		fire("c_spore_burst", e.uid, hp0 - e.hp, "dmg")
		EventBus.float_text.emit(e.uid, "SPORE", "dmg", 0)
		EventBus.hp_changed.emit(e.uid, e.hp, e.max_hp, e.shield)
		if e.hp <= 0:
			EventBus.unit_died.emit(e.uid)
			DamagePipeline.on_enemy_death(combat, e, null)


# --------------------------------------------------------------------------------------------
# quests: progress lives in combat.relic_run_out["<core id>"] = {n, boss, steps_done, done}; lane B pays rewards
# --------------------------------------------------------------------------------------------

static func quest(combat, id: String) -> Dictionary:
	var d = combat.relic_run_out.get(id, null)
	if not (d is Dictionary):
		d = {"n": 0, "boss": 0, "steps_done": 0, "done": false}
		combat.relic_run_out[id] = d
	return d


static func quest_done(combat, id: String) -> bool:
	return bool(quest(combat, id).get("done", false))


static func _quest_add(combat, id: String, n: int, target: int) -> void:
	var q := quest(combat, id)
	if bool(q["done"]):
		return
	q["n"] = int(q["n"]) + n
	fire(id, 0, n, "rule")   # progress tick: the Core panel lights up
	if int(q["n"]) >= target:
		q["done"] = true
		q["steps_done"] = 1
		fire(id, 0, 1, "quest_step")


static func collector_turn_start(ctx: Dictionary) -> void:
	if not quest_done(ctx["combat"], "c_collector"):
		gain_mana(ctx["combat"], 1, "", "c_collector")


static func collector_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var st := turn_state(combat, "cs_types")
	var n := 0
	for k in st.keys():
		if k != "_t" and ["dmg", "shield", "heal", "poison", "mana", "debuff"].has(String(k)):
			n += 1
	var cs := combat_state(combat, "collector_fight")
	if n >= 4 and not bool(cs.get("got", false)):
		cs["got"] = true
		_quest_add(combat, "c_collector", 1, 3)


static func dry_well_start(ctx: Dictionary) -> void:
	if not quest_done(ctx["combat"], "c_dry_well"):
		gain_mana(ctx["combat"], 2, "", "c_dry_well")


static func dry_well_spent(ctx: Dictionary) -> void:
	_quest_add(ctx["combat"], "c_dry_well", int(ctx.get("cost", 0)), 40)


static func night_watch_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var c = ctx["combat"]
	if u.roster_index >= 0 and c.row_of(u) == 0 and not quest_done(c, "c_night_watch"):
		u.max_hp += 3
		fire("c_night_watch", u.uid, 3, "rule")


static func night_watch_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	if String(ctx.get("node_kind", "")) != "boss" or String(ctx.get("result", "")) != "won":
		return
	var q := quest(combat, "c_night_watch")
	if int(q["boss"]) >= 1 or bool(q["done"]):
		return   # only the NEXT boss counts; after that fight the quest is over, done or not
	q["boss"] = 1
	for u in combat.party:
		if not u.is_token and u.hp <= 0:
			return
	_quest_add(combat, "c_night_watch", 1, 1)


static func key_strike_hit(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	if bool(ctx.get("first", false)) and u.stash_carry and int(ctx.get("dealt", 0)) >= 9:
		_quest_add(ctx["combat"], "c_key_strike", 1, 3)


static func chimera_kill(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var k = ctx.get("killer", null)
	if k == null or not is_finisher(combat, k):
		return
	var q := quest(combat, "c_chimera_hunt")
	if bool(q["done"]):
		return
	q["n"] = int(q["n"]) + 1
	fire("c_chimera_hunt", ctx["tgt"].uid, 1, "rule")
	if ctx["tgt"].is_boss:
		q["boss"] = 1
	var s := 0
	if int(q["n"]) >= 8:
		s = 1
	if int(q["n"]) >= 20:
		s = 2
	if int(q["boss"]) >= 1:
		s = 3
		q["done"] = true
	if s > int(q["steps_done"]):
		fire("c_chimera_hunt", ctx["tgt"].uid, s - int(q["steps_done"]), "quest_step")
	q["steps_done"] = maxi(int(q["steps_done"]), s)


# --------------------------------------------------------------------------------------------
# run rules
# --------------------------------------------------------------------------------------------

static func tundra_stash(ctx: Dictionary) -> void:
	combat_state(ctx["combat"], "focus_rule_tundra")[str(ctx["unit"].uid)] = {"v": 2, "fi": int(ctx.get("fi", ctx["unit"].roll_face_index()))}


static func scale_enemies(ctx: Dictionary, mult: float, bosses: bool, id: String = "") -> void:
	for e in ctx["combat"].enemies:
		if e.is_boss and not bosses:
			continue
		var hp0: int = e.max_hp
		e.max_hp = int(ceil(e.max_hp * mult))
		e.hp = e.max_hp
		fire(id, e.uid, e.max_hp - hp0, "rule")


static func old_forest_face(ctx: Dictionary) -> void:
	var hp0: int = ctx["unit"].max_hp
	ctx["unit"].max_hp = int(ceil(ctx["unit"].max_hp * 1.3))
	fire("rule_old_forest", ctx["unit"].uid, ctx["unit"].max_hp - hp0, "rule")


static func old_forest_value(ctx: Dictionary) -> int:
	var ft := String(ctx.get("face_type", ""))
	if ctx["unit"].side == "p" and (ft == "heal" or ft == "poison"):
		var g := mult_gain(int(ctx["value"]))
		_fire_live(ctx["combat"], "rule_old_forest", ctx["unit"].uid, g - int(ctx["value"]), ft)
		return g
	return int(ctx["value"])


## Heavy Finish (design 2b R5): enemy attacks deal +10% (knob enemy_dmg_mult). Runs from the `incoming_dmg` hook, which
## DamagePipeline calls for every attack on a party unit; the old `mod_dmg` slot only ever runs for player-side sources,
## so this half never fired there.
static func heavy_enemy_dmg(ctx: Dictionary) -> float:
	var v := float(ctx["value"])
	var src = ctx.get("src", null)
	var tgt = ctx["tgt"]
	if src == null or src.side != "e" or tgt.side != "p" or not bool(ctx.get("attack", false)):
		return v
	var nv := float(RulesMath.round_half_up(v * float(rule_knob("rule_heavy_finish", "enemy_dmg_mult", 1.1))))
	fire("rule_heavy_finish", tgt.uid, int(nv - v), "rule")
	return nv


static func balance_value(ctx: Dictionary) -> int:
	var v := int(ctx["value"])
	if ctx["unit"].side != "p" or String(ctx.get("face_type", "")) != "dmg" or v <= 0:
		return v
	if int(turn_state(ctx["combat"], "cs_dmgn").get("n", 0)) >= 2:
		_fire_live(ctx["combat"], "rule_balance", ctx["unit"].uid, v - maxi(1, v - 2), "rule")
		return maxi(1, v - 2)
	return v


static func balance_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	var t := String((ctx["face"] as Dictionary).get("type", ""))
	if t == "dmg":
		var st := turn_state(ctx["combat"], "cs_dmgn")
		st["n"] = int(st.get("n", 0)) + 1
	elif t != "blank":
		gain_mana(ctx["combat"], 1, "", "rule_balance")


## Cheap Mana: the per-turn reroll cap goes 4 -> 5 (the first paid reroll of a turn does not count).
static func cheap_paid(ctx: Dictionary) -> void:
	if int(ctx.get("rmode", 1)) != 1:
		return   # Lieu is free: it must not eat the "first paid reroll does not count" discount
	var st := turn_state(ctx["combat"], "cs_cheap")
	if not bool(st.get("done", false)):
		st["done"] = true
		ctx["combat"].reroll_paid_k = maxi(0, ctx["combat"].reroll_paid_k - 1)
		fire("rule_cheap_mana", 0, 1, "reroll")


# --------------------------------------------------------------------------------------------
# Gacha C5 meme Cores (design/proposals/meme-cores.md, Moss, weak but funny). All randomness uses combat._rng (engine seed).
# --------------------------------------------------------------------------------------------

const MEME_NAMES_PATH := "res://assets/data/rules/meme_enemy_names.json"
static var _meme_names: Array = []


static func meme_names() -> Array:
	if _meme_names.is_empty():
		var f := FileAccess.open(MEME_NAMES_PATH, FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			if d is Array:
				_meme_names = d
	return _meme_names


## Dice that may be rewritten by a meme Core: count for Sets now, not held / spent / Wild-faced / already copied.
static func _meme_dice(combat) -> Array:
	var out: Array = []
	for u in combat._bo_dice():
		if u.held or u.stash_carry or u.roll_used() or u.wild_slot >= 0 or int(u.custom_state.get("copycat_turn", -1)) == int(combat.turn):
			continue
		out.append(u)
	return out


static func _set_face(u, fi: int) -> void:
	var f: Dictionary = u.die[fi]
	var crit: bool = u.roll_crit_now()
	u.set_roll(fi, crit and String(f.get("type", "")) == "dmg")
	u.heavy = _has_kw(f, "heavy")


## Copycat: only the first roll of a turn. The weakest die outside every Set copies the best Set's part; it shows that face
## for 1 (face_final) and does not count toward Sets (combat._bo_dice skips custom_state.copycat_turn == turn). No rng.
static func copycat_settled(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for u in combat.party:
		if int(u.uid) in (ctx.get("rerolled_uids", []) as Array):
			u.custom_state.erase("copycat_turn")
	if not (ctx.get("rerolled_uids", []) as Array).is_empty() or bool(turn_state(combat, "cs_copycat").get("done", false)):
		return
	var groups: Array = combat.recompute_bo()
	if groups.is_empty():
		return
	var best: Dictionary = groups[0]
	for g in groups:
		if int(g["size"]) > int(best["size"]) or (int(g["size"]) == int(best["size"]) and int(g["part"]) < int(best["part"])):
			best = g
	var in_set := {}
	for g in groups:
		for id in (g["uids"] as Array):
			in_set[int(id)] = true
	var pick = null
	var pick_v := 0
	for u in _meme_dice(combat):
		if in_set.has(int(u.uid)):
			continue
		var v := int((u.die[u.roll_face_index()] as Dictionary).get("value", 0))
		if pick == null or v < pick_v:
			pick = u
			pick_v = v
	if pick == null:
		return
	turn_state(combat, "cs_copycat")["done"] = true
	_set_face(pick, int(best["part"]))
	pick.custom_state["copycat_turn"] = int(combat.turn)
	EventBus.float_text.emit(pick.uid, "COPY!", "buf", 0)
	fire("c_meme_copycat", pick.uid, 1, "rule")
	combat._snap_bo()


## Copycat die value is 1 for the turn it copied (a rerolled die sheds the flag in copycat_settled).
static func copycat_face(ctx: Dictionary) -> int:
	var u = ctx["unit"]
	if int(u.custom_state.get("copycat_turn", -1)) == int(ctx["combat"].turn):
		return 1
	return int(ctx["value"])


## Jumpy Dice: after the first roll of a turn two random eligible dice swap face index. Part multiplicities are unchanged.
static func jumpy_settled(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	if not (ctx.get("rerolled_uids", []) as Array).is_empty() or bool(turn_state(combat, "cs_jumpy").get("done", false)):
		return
	var pool := _meme_dice(combat)
	if pool.size() < 2:
		return
	turn_state(combat, "cs_jumpy")["done"] = true
	var i: int = combat._rng.next_int(pool.size())
	var j: int = combat._rng.next_int(pool.size() - 1)
	if j >= i:
		j += 1
	var a = pool[i]
	var b = pool[j]
	var fa: int = a.roll_face_index()
	var fb: int = b.roll_face_index()
	_set_face(a, fb)
	_set_face(b, fa)
	EventBus.float_text.emit(a.uid, "JUMP!", "buf", 0)
	EventBus.float_text.emit(b.uid, "JUMP!", "buf", 0)
	fire("c_meme_jumpy", a.uid, 1, "rule")
	combat._snap_bo()


## Name Tag: start of combat a random non-boss living enemy gets a silly name (custom_state.nick); its death pays +1 Mana once.
static func nametag_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var pool: Array = []
	for e in combat.enemies:
		if e.hp > 0 and not e.is_boss:
			pool.append(e)
	var names := meme_names()
	if pool.is_empty() or names.is_empty():
		return
	var e = pool[combat._rng.next_int(pool.size())]
	e.custom_state["nick"] = String(names[combat._rng.next_int(names.size())])
	fire("c_meme_nametag", e.uid, 1, "rule")


static func nametag_kill(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var e = ctx["tgt"]
	if not e.custom_state.has("nick") or bool(combat_state(combat, "cs_nametag").get("paid", false)):
		return
	combat_state(combat, "cs_nametag")["paid"] = true
	gain_mana(combat, 1, "RIP " + String(e.custom_state["nick"]), "c_meme_nametag")


## ---- Pack Alpha (design/proposals/cores-rules-v5.md R17, approved 23/10) --------------------------------------------
## Start of a normal / elite fight with 2+ non-boss enemies: the one with the most HP (tie: smallest uid) becomes the
## Alpha (custom_state.alpha, saved with the unit) and gets +alpha_hp_mult HP. No RNG.
static func alpha_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var kind := String(ctx.get("node_kind", ""))
	if kind != "battle" and kind != "elite":
		return
	var pool: Array = []
	for e in combat.enemies:
		if e.is_boss:
			return
		if e.hp > 0:
			pool.append(e)
	if pool.size() < 2:
		return
	var best = pool[0]
	for e in pool:
		if e.max_hp > best.max_hp or (e.max_hp == best.max_hp and e.uid < best.uid):
			best = e
	var hp0: int = best.max_hp
	best.max_hp = int(ceil(best.max_hp * float(rule_knob("rule_pack_alpha", "alpha_hp_mult", 1.25))))
	best.hp = best.max_hp
	best.custom_state["alpha"] = true
	fire("rule_pack_alpha", best.uid, best.max_hp - hp0, "rule")


static func alpha_unit(combat):
	for e in combat.enemies:
		if bool(e.custom_state.get("alpha", false)):
			return e
	return null


## Other enemies take others_single_mult from single-target damage faces while the Alpha lives (min 1). AoE, pierce, poison and
## thorns (no player source / not single) are untouched.
static func alpha_incoming(ctx: Dictionary, v: float) -> float:
	var combat = ctx["combat"]
	var tgt = ctx["tgt"]
	var src = ctx.get("src", null)
	if not bool(ctx.get("attack", false)) or not bool(ctx.get("single", false)) or bool(ctx.get("pierce", false)):
		return v
	if src == null or src.side != "p" or bool(tgt.custom_state.get("alpha", false)):
		return v
	var a = alpha_unit(combat)
	if a == null or a.hp <= 0:
		return v
	var nv := maxf(1.0, ceil(v * float(rule_knob("rule_pack_alpha", "others_single_mult", 0.5))))
	if nv < v:
		fire("rule_pack_alpha", tgt.uid, int(v - nv), "block")
	return minf(v, nv)


## The Alpha falls: every other living enemy loses alpha_death_pct of its current HP (never to 0).
static func alpha_kill(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var dead = ctx["tgt"]
	if not bool(dead.custom_state.get("alpha", false)):
		return
	var pct := float(rule_knob("rule_pack_alpha", "alpha_death_pct", 0.2))
	for e in combat.enemies:
		if e == dead or e.hp <= 0 or e.is_boss:
			continue
		var loss := mini(RulesMath.round_half_up(e.hp * pct), e.hp - 1)
		if loss <= 0:
			continue
		e.hp -= loss
		EventBus.hp_changed.emit(e.uid, e.hp, e.max_hp, e.shield)
		EventBus.float_text.emit(e.uid, "-%d" % loss, "dmg", 0)
		fire("rule_pack_alpha", e.uid, loss, "dmg")


## ---- Set Is King (R14): a die in a SET gets +set_dice_bonus, any other die -nonset_penalty (min 1). No free reroll = rerollUp -1.
static func in_set(combat, u) -> bool:
	for g in combat.bo:
		if (g as Dictionary).get("uids", []).has(u.uid):
			return true
	return false


static func set_king_value(ctx: Dictionary) -> int:
	var v := int(ctx["value"])
	var u = ctx["unit"]
	var ft := String(ctx.get("face_type", ""))
	if v <= 0 or u.side != "p" or u.is_token or not VALUE_TYPES.has(ft):
		return v
	var own := bonus(ctx["combat"], u, ft, "rule_set_is_king")
	if own >= 0:
		return flat(ctx, "rule_set_is_king")
	var nv := maxi(1, v + own)
	_fire_live(ctx["combat"], "rule_set_is_king", u.uid, v - nv, ft)
	return nv


## ---- Pilot Light (R15): turn 1 of a normal / elite fight your damage faces deal t1_dmg_mult (0), you may Hold t1_stash_cap dice and
## each die Held on turn 1 gets +held_bonus when used on turn 2. Normal / elite enemies +enemy_hp_mult HP. Not in boss fights.
## `combat_state("pilot").on` is set at combat start (saved with the fight).
static func pilot_on(combat) -> bool:
	return RelicHooks_has(combat, "rule_pilot_light") and bool(combat_state(combat, "pilot").get("on", false))


static func pilot_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var kind := String(ctx.get("node_kind", ""))
	if kind != "battle" and kind != "elite":
		return
	for e in combat.enemies:
		if e.is_boss:
			return
	combat_state(combat, "pilot")["on"] = true
	scale_enemies(ctx, float(rule_knob("rule_pilot_light", "enemy_hp_mult", 1.1)), false, "rule_pilot_light")


static func pilot_cap(ctx: Dictionary) -> int:
	var v := int(ctx["value"])
	if pilot_on(ctx["combat"]) and int(ctx["combat"].turn) <= 1:
		return maxi(v, int(rule_knob("rule_pilot_light", "t1_stash_cap", 4)))
	return v


static func pilot_stash(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	if not pilot_on(combat) or int(combat.turn) > 1:
		return
	var u = ctx["unit"]
	combat_state(combat, "focus_rule_pilot_light")[str(u.uid)] = {"v": int(rule_knob("rule_pilot_light", "held_bonus", 3)), "fi": int(ctx.get("fi", u.roll_face_index()))}


## Damage pipeline: turn-1 player damage faces are scaled by t1_dmg_mult. Returns the new value.
static func pilot_dmg(combat, src, ctx: Dictionary, v: float) -> float:
	if src == null or src.side != "p" or not bool(ctx.get("attack", false)) or String(ctx.get("face_type", "dmg")) != "dmg":
		return v
	if int(combat.turn) > 1 or not pilot_on(combat):
		return v
	var nv: float = ceil(v * float(rule_knob("rule_pilot_light", "t1_dmg_mult", 0)))
	if nv < v:
		fire("rule_pilot_light", src.uid, int(v - nv), "dmg")
	return nv
