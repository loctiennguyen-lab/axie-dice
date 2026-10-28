class_name SetPreview
extends RefCounted
## UI-05 b1 lane B: the numbers a SET shows on the tray. Every number is READ from the engine, never worked out here, and no
## rule file is touched (plan review item 3):
##   before  = CombatEngine._face_base(u, fi), floored at 0: the face before the M bag (growth, vital, weaken, blind, overdrive,
##             Crack, R12, CONDUIT).
##   after   = CombatView._live_face_value(u, fi): what the die really deals (M bag incl. Anchor / Embers / Core set_add /
##             Overcast / chain, resonance, the face_final hook, the poison cap). Same number as the die face.
##   group M = CombatEngine.bo_group_m100(g) (the SetBanner's ×M).
##   Overcast before it is pressed = an ESTIMATE: _mul_up(before, min(group M + overcast add, cap)). It skips chain, resonance and
##             face_final, so the UI always words it as "about".

## SET colour per live SET, in the engine's `bo` order: the first SET lemon (set_a), a second mint (set_b).
const SET_KEYS := ["a", "b"]


## "a" / "b" for the SET `uid` is in, "" when it is in none.
static func set_key(bo: Array, uid: int) -> String:
	for i in bo.size():
		if ((bo[i] as Dictionary)["uids"] as Array).has(uid):
			return String(SET_KEYS[i % SET_KEYS.size()])
	return ""


## Colour token of a SET key ("a" -> set_a).
static func colour_token(key: String) -> String:
	return "set_" + (key if key != "" else "a")


## The face value before the SET multiplies it (engine step 1-3), never below 0. A blinded attack (-1) reads 0.
static func before_value(combat: CombatEngine, u: Unit, fi: int) -> int:
	if combat == null or u == null or fi < 0 or fi >= u.die.size():
		return 0
	return maxi(0, int(combat._face_base(u, fi)))


## What one tray card shows for its SET: {key, before, after, show}. `show` = in a live SET, not used yet, and the SET really
## raises the number (mana / debuff / summon faces are never multiplied, a cracked die is never in a SET).
static func for_die(view: CombatView, u: Unit) -> Dictionary:
	var out := {"key": "", "before": 0, "after": 0, "show": false}
	var combat: CombatEngine = view._combat if view != null else null
	if combat == null or u == null or u.hp <= 0 or not u.has_rolled():
		return out
	out["key"] = set_key(combat.bo, u.uid)
	if String(out["key"]) == "":
		return out
	var fi := u.roll_face_index()
	var before := before_value(combat, u, fi)
	var after := view._live_face_value(u, fi)
	out["before"] = before
	out["after"] = after
	out["show"] = not u.roll_used() and before > 0 and after > before
	return out


## The SetBanner's multiplier in percent (engine group value: Anchor add, Core set_add, Overcast, cap).
static func group_m100(combat: CombatEngine, g: Dictionary) -> int:
	if combat == null:
		return int(g.get("m100", 100))
	return combat.bo_group_m100(g)


## The group multiplier once one more Overcast lands on this SET (estimate, capped at bo.m_cap).
static func overcast_m100(combat: CombatEngine, g: Dictionary) -> int:
	return mini(group_m100(combat, g) + roundi(combat.overcast_add() * 100.0), combat.bo_cap100())


## Estimated value of a die worth `before` after one more Overcast on its SET (rounded up, as the engine does).
static func overcast_estimate(combat: CombatEngine, g: Dictionary, before: int) -> int:
	return CombatEngine._mul_up(maxi(before, 0), overcast_m100(combat, g))


## "4 → 6" (the full preview). Narrow no-break spaces (U+202F) around the arrow, as the HTML: with plain spaces "ATTACK 2 → 5"
## is 2 px wider than the 1920 card's FaceRow in Rowdies.
const ARROW := "\u202f→\u202f"


static func delta_text(before: int, after: int) -> String:
	return "%d%s%d" % [before, ARROW, after]


## "+2": what the card shows when "12 → 27" does not fit next to the face word (the tooltip keeps the full line).
static func compact_text(before: int, after: int) -> String:
	return "+%d" % maxi(after - before, 0)
