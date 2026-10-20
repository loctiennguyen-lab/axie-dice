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
