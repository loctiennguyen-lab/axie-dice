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


static func gain_mana(combat, n: int, label: String = "") -> void:
	if n <= 0:
		return
	combat.mana += n
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
	for o in combat.party:
		if o == u or o.hp <= 0:
			continue
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


## Sacrifice: the Axie in slot 5 sleeps for the whole fight (no die, never targeted, not counted for a wipe).
static func sacrifice_start(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for u in combat.party:
		if u.roster_index == 4 and not u.is_token:
			u.custom_state["asleep"] = true
			u.held = false
			u.clear_roll()
			EventBus.float_text.emit(u.uid, "ZZZ", "buf", 0)


static func dewdrop_turn(ctx: Dictionary) -> void:
	gain_mana(ctx["combat"], 1)


static func elder_trunk_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	u.max_hp += 8
	for f in u.die:
		if String((f as Dictionary).get("type", "")) == "dmg" and int(f.get("value", 0)) > 0:
			f["value"] = maxi(1, int(f["value"]) - 1)


# --------------------------------------------------------------------------------------------
# dice
# --------------------------------------------------------------------------------------------

## Giu Vung: 2 held dice, and the same die may be held two turns in a row.
static func steady_hold_cap(ctx: Dictionary) -> int:
	return int(ctx["value"]) + 1


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
	gain_mana(combat, 2)


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
	gain_mana(combat, mini(3, int(combat.mana) / 3))


## Ngon Trieu: every 3 Mana spent (reroll or active) deals 2 damage to all enemies.
static func tide_spent(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var cost := int(ctx.get("cost", 0))
	if cost <= 0:
		return
	var st := combat_state(combat, "tide_acc")
	var acc := int(st.get("n", 0)) + cost
	while acc >= 3:
		acc -= 3
		for e in combat.alive_enemies().duplicate():
			DamagePipeline.resolve({"combat": combat, "src": null, "tgt": e, "value": 2, "attack": false})
	st["n"] = acc


# --------------------------------------------------------------------------------------------
# Shared flat-bonus cap (design 3.4): the sum of flat bonuses Cores add to ONE face is at most +10.
# Each Core's flat bonus is a pure function bonus(); flat() adds it on top of the running value and only
# lets it use the room left after the bonuses of Cores owned BEFORE it (pickup order = hook order).
# Penalties (negative) are never capped.
# --------------------------------------------------------------------------------------------

const FLAT_CAP := 10
const FLAT_IDS := ["c_kindle", "c_prime_chain", "c_finisher", "c_mana_pool", "c_three_dice", "c_field_medic",
	"c_plague_spread", "c_hollow_core", "c_thorn_pact", "c_cascade", "c_gatekeeper", "c_golden_egg",
	"rule_tundra", "rule_heavy_finish", "c_sacrifice", "c_concord"]


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
		"rule_tundra":
			return 0 if sec else focus_value(combat, "focus_rule_tundra", u, ft)
		"c_prime_chain":
			return 0 if (sec or ft != "dmg") else int(turn_state(combat, "cs_prime").get(str(u.uid), 0))
		"c_finisher":
			return 0 if (sec or not (ft == "dmg" or ft == "shield" or ft == "heal" or ft == "poison")) else finisher_bonus(combat, u)
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
		"c_concord":
			return 2 if (not sec and val and part != "" and String(turn_state(combat, "cs_concord").get("part", "")) == part) else 0
		"c_golden_egg":
			return 3 if (ft == "dmg" and bool(combat_state(combat, "ge").get("on", false))) else 0
	return 0


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
	var before := 0
	for rid in combat.relic_ids:
		if String(rid) == id:
			break
		if FLAT_IDS.has(String(rid)):
			before += maxi(0, bonus(combat, u, ft, String(rid), part))
	return v + mini(own, maxi(0, FLAT_CAP - before))


## Total flat Core bonus a face would get right now (used by tests / UI).
static func flat_total(combat, u, ft: String, part: String = "") -> int:
	var t := 0
	for rid in combat.relic_ids:
		if FLAT_IDS.has(String(rid)):
			t += maxi(0, bonus(combat, u, ft, String(rid), part))
	return mini(FLAT_CAP, t)


# --------------------------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------------------------

static func _hit_enemy(combat, e, v: int) -> void:
	if v > 0 and e.hp > 0:
		DamagePipeline.resolve({"combat": combat, "src": null, "tgt": e, "value": v, "pierce": true, "attack": false})


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
	for e in combat.alive_enemies().duplicate():
		if aoe or int(e.intent.get("target_uid", -2)) == tid:
			_hit_enemy(combat, e, dmg)


static func field_medic_face(ctx: Dictionary) -> void:
	_dmg_minus(ctx["unit"], 2)


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


static func toxic_still_face(ctx: Dictionary) -> void:
	_dmg_minus(ctx["unit"], 2)


static func toxic_still_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	for e in combat.alive_enemies().duplicate():
		var p := int(e.status.get("poison", 0))
		if p > 0:
			StatusEngine.add_status(combat, e, ["poison:%d" % mini(4, int(ceil(p / 2.0)))], null)


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


static func whittle_roll(ctx: Dictionary) -> int:
	var fi := int(ctx["value"])
	var u = ctx["unit"]
	if u.side == "p" and not u.is_token and fi == weakest_fi(u):
		return ctx["combat"]._rng.next_int(6)
	return fi


## Three Dice: at most 3 dice per turn; the rest are Held automatically with Focus +3.
static func three_auto_hold(combat) -> void:
	var st := combat_state(combat, "focus_c_three_dice")
	for u in living_axies(combat):
		if u.held or not u.has_rolled() or u.roll_used() or u.frozen or _has_kw(u.current_face(), "cantrip"):
			continue
		u.held = true
		st[str(u.uid)] = {"v": 3, "fi": u.roll_face_index()}
		EventBus.float_text.emit(u.uid, "HOLD", "buf", 0)


static func three_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) != "p" or int(ctx.get("depth", 0)) != 0:
		return
	if int(turn_state(ctx["combat"], "cs_used").get("n", 0)) >= 3:
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
	_hit_enemy(combat, src, 3)


static func gatekeeper_used(ctx: Dictionary) -> void:
	if String(ctx.get("side", "")) == "p" and String((ctx["face"] as Dictionary).get("type", "")) == "dmg":
		combat_state(ctx["combat"], "gk")["b"] = 0


static func gatekeeper_turn_end(ctx: Dictionary) -> void:
	combat_state(ctx["combat"], "gk")["b"] = 0   # hits taken AFTER this call feed the next turn


static func backline_value(ctx: Dictionary) -> int:
	var u = ctx["unit"]
	var ft := String(ctx.get("face_type", ""))
	if u.side == "p" and not u.is_token and (ft == "heal" or ft == "mana") and ctx["combat"].row_of(u) == 1:
		return int(ceil(int(ctx["value"]) * 1.5))
	return int(ctx["value"])


static func living_wall_face(ctx: Dictionary) -> void:
	if ctx["unit"].roster_index == 0:
		ctx["unit"].max_hp += 12


static func living_wall_start(ctx: Dictionary) -> void:
	for u in living_axies(ctx["combat"]):
		if u.roster_index == 0:
			StatusEngine.add_status(ctx["combat"], u, ["thorns:2"], null)


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


static func overflow_check(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var ex := int(combat.mana) - 8
	if ex <= 0:
		return
	combat.mana = 8
	for e in combat.alive_enemies().duplicate():
		_hit_enemy(combat, e, ex)


## Hollow Core: reroll costs 1 Mana, up to 8 a turn (the engine cap counts each second paid reroll as free).
static func hollow_paid(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var st := turn_state(combat, "cs_paid")
	st["n"] = int(st.get("n", 0)) + 1
	if int(st["n"]) % 2 == 0:
		combat.reroll_nonaid = maxi(0, combat.reroll_nonaid - 1)


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
			EventBus.hp_changed.emit(u.uid, u.hp, u.max_hp, u.shield)


# --------------------------------------------------------------------------------------------
# rule-axis Cores (batch 2)
# --------------------------------------------------------------------------------------------

static func golden_egg_fall(ctx: Dictionary) -> void:
	var t = ctx["tgt"]
	if not (t.is_token and t.key == "egg") or not fell_now(ctx):
		return
	var combat = ctx["combat"]
	gain_mana(combat, 3)
	var w = null
	for u in living_axies(combat):
		if w == null or u.hp + u.shield < w.hp + w.shield:
			w = u
	if w != null:
		DamagePipeline.apply_shield(combat, w, 4)
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
			_hit_enemy(combat, e, dmg)
	else:
		var t = combat.by_uid(int(ctx.get("target_uid", -1)))
		if t != null and t.side == "e":
			_hit_enemy(combat, t, dmg)


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
		e.hp = maxi(0, e.hp - int(ceil(e.max_hp * pct)))
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
	if int(q["n"]) >= target:
		q["done"] = true
		q["steps_done"] = 1


static func collector_turn_start(ctx: Dictionary) -> void:
	if not quest_done(ctx["combat"], "c_collector"):
		gain_mana(ctx["combat"], 1)


static func collector_turn_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	var st := turn_state(combat, "cs_types")
	var n := 0
	for k in st.keys():
		if k != "_t" and ["dmg", "shield", "heal", "poison", "mana", "debuff"].has(String(k)):
			n += 1
	var cs := combat_state(combat, "collector_fight")
	if n >= 5 and not bool(cs.get("got", false)):
		cs["got"] = true
		_quest_add(combat, "c_collector", 1, 3)


static func dry_well_start(ctx: Dictionary) -> void:
	if not quest_done(ctx["combat"], "c_dry_well"):
		gain_mana(ctx["combat"], 2)


static func dry_well_spent(ctx: Dictionary) -> void:
	_quest_add(ctx["combat"], "c_dry_well", int(ctx.get("cost", 0)), 40)


static func night_watch_face(ctx: Dictionary) -> void:
	var u = ctx["unit"]
	var c = ctx["combat"]
	if u.roster_index >= 0 and u.roster_index < 2 and not quest_done(c, "c_night_watch"):
		u.max_hp += 3


static func night_watch_end(ctx: Dictionary) -> void:
	var combat = ctx["combat"]
	if String(ctx.get("node_kind", "")) != "boss" or String(ctx.get("result", "")) != "won":
		return
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
	q["steps_done"] = maxi(int(q["steps_done"]), s)


# --------------------------------------------------------------------------------------------
# run rules
# --------------------------------------------------------------------------------------------

static func tundra_stash(ctx: Dictionary) -> void:
	combat_state(ctx["combat"], "focus_rule_tundra")[str(ctx["unit"].uid)] = {"v": 2, "fi": int(ctx.get("fi", ctx["unit"].roll_face_index()))}


static func scale_enemies(ctx: Dictionary, mult: float, bosses: bool) -> void:
	for e in ctx["combat"].enemies:
		if e.is_boss and not bosses:
			continue
		e.max_hp = int(ceil(e.max_hp * mult))
		e.hp = e.max_hp


static func old_forest_face(ctx: Dictionary) -> void:
	ctx["unit"].max_hp = int(ceil(ctx["unit"].max_hp * 1.3))


static func old_forest_value(ctx: Dictionary) -> int:
	var ft := String(ctx.get("face_type", ""))
	if ctx["unit"].side == "p" and (ft == "heal" or ft == "poison"):
		return int(ceil(int(ctx["value"]) * 1.5))
	return int(ctx["value"])


static func heavy_enemy_dmg(ctx: Dictionary) -> float:
	var v := float(ctx["value"])
	var src = ctx.get("src", null)
	return float(RulesMath.round_half_up(v * 1.1)) if (src != null and src.side == "e") else v


static func balance_value(ctx: Dictionary) -> int:
	var v := int(ctx["value"])
	if ctx["unit"].side != "p" or String(ctx.get("face_type", "")) != "dmg" or v <= 0:
		return v
	if int(turn_state(ctx["combat"], "cs_dmgn").get("n", 0)) >= 2:
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
		gain_mana(ctx["combat"], 1)


## Cheap Mana: the per-turn reroll cap goes 4 -> 5 (the first paid reroll of a turn does not count).
static func cheap_paid(ctx: Dictionary) -> void:
	var st := turn_state(ctx["combat"], "cs_cheap")
	if not bool(st.get("done", false)):
		st["done"] = true
		ctx["combat"].reroll_nonaid = maxi(0, ctx["combat"].reroll_nonaid - 1)
