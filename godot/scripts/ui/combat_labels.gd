class_name CombatLabels
extends RefCounted
## Pure display helpers for the combat HUD (no state, no rules): enemy name suffixes, ELITE/LEADER tag choice,
## big-hit flag, attrition banner timing. Numbers come from the engine; nothing here changes them.

## Attrition banner shows this many turns before it starts (and always once it is running).
const ATTRITION_LEAD := 3


## uid -> display name. When a name repeats in one fight, every copy gets " A", " B", ... in list order.
static func enemy_names(enemies: Array) -> Dictionary:
	var count := {}
	for e in enemies:
		count[String(e.n)] = int(count.get(String(e.n), 0)) + 1
	var seen := {}
	var out := {}
	for e in enemies:
		var nm := String(e.n)
		if int(count[nm]) > 1:
			var i := int(seen.get(nm, 0))
			seen[nm] = i + 1
			out[e.uid] = "%s %s" % [nm, char(65 + (i % 26))]
		else:
			out[e.uid] = nm
	return out


## Nameplate tag. BOSS for bosses; ELITE only for the elite itself (enemy 0 of an elite fight), never its
## companions or summons; the Pack Alpha leader gets no ELITE (the plate shows its own LEADER badge).
static func tag_for(is_boss: bool, fight_kind: String, is_first_enemy: bool, is_alpha: bool) -> String:
	if is_boss:
		return "BOSS"
	if is_alpha:
		return ""
	if fight_kind == "elite" and is_first_enemy:
		return "ELITE"
	return ""


## True when the hit can take an Axie out: dmg >= the lowest HP (+ shield) among living party units.
## `party_effective` = Array of ints (hp + shield per living Axie).
static func is_big_hit(dmg: int, party_effective: Array) -> bool:
	if dmg <= 0 or party_effective.is_empty():
		return false
	var low := 1 << 30
	for v in party_effective:
		low = mini(low, int(v))
	return dmg >= low


static func is_blank_intent(ftype: String) -> bool:
	return ftype == "blank" or ftype == ""


## Attrition card is visible from `ATTRITION_LEAD` turns before the start turn, and from then on.
static func attrition_visible(state: Dictionary, turn: int) -> bool:
	if int(state.get("pct", 0)) > 0:
		return true
	var start := int(state.get("start_turn", 0))
	return start > 0 and turn >= start - ATTRITION_LEAD
