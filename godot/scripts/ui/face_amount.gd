class_name FaceAmount
extends RefCounted
## The number a player reads off a die face.
##
## WHY THIS EXISTS. Buff and debuff faces are built with printed value 0 (AxieToDie: `is_v0`);
## their magnitude lives in the keyword string, e.g. debuff ["weaken:3"] or buff ["thorns:2"].
## CombatEngine._face_value() only knows the printed value, so every WEAKEN / VULNERABLE /
## BLIND / THORNS face read "0" on the card, the 3D die and the info line while the fight
## applied the keyword's N. This helper is display-only and reads, never writes, game data.

## Status keywords whose `:N` is the amount of a debuff / buff face. Order = priority.
const AMOUNT_KW := ["weaken", "vulnerable", "blind", "poison", "burn", "thorns", "regen"]


## Amount from the first status keyword with N > 0, or 0 when the face has none
## (stun, freeze, enrage and blank faces carry no number).
static func keyword_amount(f: Dictionary) -> int:
	var best := {}
	for k in (f.get("keywords", []) as Array):
		var parts := String(k).split(":")
		if parts.size() < 2 or not AMOUNT_KW.has(parts[0]):
			continue
		var n := int(parts[1])
		if n > 0 and not best.has("n"):
			best = {"n": n}
	return int(best.get("n", 0))


## The number to show. `live` is CombatEngine's value for the face. Only buff / debuff faces
## (printed value 0) fall back to the keyword amount; every other face keeps `live`.
static func display_value(f: Dictionary, live: int) -> int:
	var t := String(f.get("type", ""))
	if (t == "debuff" or t == "buff") and live <= 0:
		return keyword_amount(f)
	return live


## Does this face show a number at all (printed value or keyword amount)?
static func has_amount(f: Dictionary) -> bool:
	return display_value(f, int(f.get("value", 0))) > 0


## Replace the placeholder N in a rule sentence ("deals N less damage") with `n`.
static func fill_n(rule: String, n: int) -> String:
	if n <= 0:
		return rule
	var re := RegEx.new()
	re.compile("\\bN\\b")
	return re.sub(rule, str(n), true)
