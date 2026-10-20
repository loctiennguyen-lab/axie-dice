class_name CoreFeedback
extends RefCounted
## Depth v3 lane VZ: how a Core's activation (EventBus.core_fired) is worded and coloured, in the combat float text
## and on the Result screen. Pure helpers, no nodes. Colour is never alone: every kind also has a sign and a word.

## kind -> [colour token, sign, float word, Result verb format ("%d" = summed amount)]
const KINDS := {
	"dmg": ["face_attack_text", "-", "", "%d dmg"],
	"thorns": ["face_attack_text", "-", "Thorns", "%d thorns"],
	"poison": ["face_poison", "-", "Poison", "%d poison"],
	"shield": ["face_shield", "+", "Shield", "%d shield"],
	"block": ["face_shield", "+", "Block", "blocked %d"],
	"heal": ["face_heal", "+", "Heal", "healed %d"],
	"mana": ["face_mana", "+", "Mana", "+%d mana"],
	"reroll": ["face_buff", "+", "Reroll", "%d rerolls"],
	"quest_step": ["accent", "+", "Step", "%d steps"],
}


static func color_token(kind: String) -> String:
	return String((KINDS.get(kind, ["text"]) as Array)[0])


## "Bastion +3 Block" / "Contagion -4" / "Fissure" (no amount or unknown kind = the name alone).
static func float_line(core_name: String, amount: int, kind: String) -> String:
	if amount <= 0 or not KINDS.has(kind):
		return core_name
	var k: Array = KINDS[kind]
	var word := String(k[2])
	var sign_char := String(k[1]).replace("-", "−")
	return "%s %s%d%s" % [core_name, sign_char, amount, (" " + TranslationServer.translate(word)) if word != "" else ""]


## Result line body for one run-impact entry ({"n": fires, "by": {kind: amount}}): "blocked 18", "42 dmg",
## or "fired 5x" when the Core never reported an amount.
static func impact_text(entry: Dictionary) -> String:
	var parts: Array[String] = []
	var by: Dictionary = entry.get("by", {})
	var kinds: Array = by.keys()
	kinds.sort_custom(func(a, b): return int(by[a]) > int(by[b]))
	for k in kinds:
		if KINDS.has(String(k)) and int(by[k]) > 0:
			parts.append(TranslationServer.translate(String((KINDS[k] as Array)[3])) % int(by[k]))
	if parts.is_empty():
		return TranslationServer.translate("fired %dx") % int(entry.get("n", 0))
	return " · ".join(parts)


static func impact_total(entry: Dictionary) -> int:
	var t := 0
	for k in (entry.get("by", {}) as Dictionary).values():
		t += int(k)
	return t


## The Core with the biggest summed amount (ties: more fires). "" when nothing fired at all.
static func top_core(impact: Dictionary, among: Array = []) -> String:
	var best := ""
	var best_key := Vector2i(0, 0)
	for id in impact.keys():
		if not among.is_empty() and not among.has(String(id)):
			continue
		var e: Dictionary = impact[id]
		var key := Vector2i(impact_total(e), int(e.get("n", 0)))
		if key.x + key.y > 0 and (best == "" or key.x > best_key.x or (key.x == best_key.x and key.y > best_key.y)):
			best = String(id)
			best_key = key
	return best
