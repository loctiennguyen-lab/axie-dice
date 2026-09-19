class_name CodexContent
extends RefCounted
## Shared rule-book text for Codex.gd (godot/scenes/codex/Codex.tscn) and the in-combat
## InfoPanel (godot/scenes/combat/InfoPanelView.gd) — three tabs ("st","kw","mana") are
## identical content in both screens, per the task brief ("three tabs shared with the Codex").
##
## Every static paragraph/table below was checked against design/gdd/godot-port-rule-spec.md
## and the actual GDScript in godot/scripts/core/ + godot/autoload/ — NOT copied verbatim from
## src/client.html's scCodex(). See the corrections list in the ui-programmer report for what
## had to change and why. Dynamic tabs (RELIC TABLE, CLASSES, BOSSES) read RelicRegistry /
## ContentDB live at render time so this file can never drift from the data those systems
## actually run on.
##
## Output format: BBCode strings for a single RichTextLabel per tab (bbcode_enabled=true,
## fit_content=true), using RichTextLabel's built-in [table=N] tag — chosen over hand-built
## GridContainer/Label trees to keep this file's size reasonable under a hard time budget.

const TABS: Array = [
	["basic", "THE BASICS"], ["dice", "DICE & BODY PARTS"], ["mana", "MANA & CARDS"],
	["kw", "KEYWORDS"], ["st", "STATUS EFFECTS"], ["cls", "CLASSES & PLAYSTYLES"],
	["relic", "RELIC TABLE"], ["reward", "MAP & REWARDS"], ["boss", "BOSSES"],
	["diff", "DIFFICULTY & KEYS"],
]

## In-combat InfoPanel tabs: 3 live (built by InfoPanelView.gd itself) + 3 shared with Codex.
const INFO_TABS: Array = [
	["party", "YOUR TEAM"], ["relic", "YOUR RELICS"], ["enemy", "ENEMIES"],
	["st", "STATUS EFFECTS"], ["kw", "KEYWORDS"], ["mana", "MANA"],
]

const _H := "[b][color=#ffd76a]%s[/color][/b]\n"


static func tab_text(key: String) -> String:
	match key:
		"basic": return _basic()
		"dice": return _dice()
		"mana": return _mana()
		"kw": return _kw()
		"st": return _st()
		"cls": return _cls()
		"relic": return _relic()
		"reward": return _reward()
		"boss": return _boss()
		"diff": return _diff()
	return "(no content for tab '%s')" % key


static func _basic() -> String:
	var mc: Dictionary = RunMapGenerator.MODE_CONFIG
	var short_rows: int = int(mc["short"]["total_rows"])
	var full_rows: int = int(mc["full"]["total_rows"])
	var s := _H % "A RUN"
	s += ("A run's map is a branching path of nodes: several node's are open on a row at once, "
		+ "and every row funnels back down to a single mandatory node — a required fight, or a "
		+ "boss. Short mode is %d rows, Full is %d rows. After every node you clear, you pick "
		+ "one of up to three rewards. After every fight your party heals to full and any "
		+ "fallen Axie is revived, so the difficulty sits inside each individual fight rather "
		+ "than in slow attrition.\nLosing a fight ends the run immediately, but you keep every "
		+ "Gene Shard and every point of Lunacia XP you earned.\n\n") % [short_rows, full_rows]
	s += _H % "A TURN IN COMBAT"
	s += _table(["STEP", "WHAT HAPPENS"], [
		["1 - ROLL", "All five of your dice and every enemy die roll at once. Whatever an enemy rolls is shown on its card, so its intent is public."],
		["2 - REROLL", "Pick which dice to reroll and press Reroll. Pick none and every die rerolls. You get 2 rerolls per turn by default."],
		["3 - ACT", "Click a die, then click a target. Undo is available until you Reroll or press End Turn."],
		["4 - END TURN", "Enemies act out exactly the intent they showed, one at a time. Then status effects such as Poison, Burn and Regen tick."],
	])
	s += "\n" + (_H % "UNDO")
	s += ("Undo restores a full snapshot of the turn, and that snapshot INCLUDES the game's "
		+ "random-number cursor. Redoing the exact same action always reproduces the exact same "
		+ "result — undo lets you change your mind about WHICH move to make, it does not let you "
		+ "re-roll for a better outcome. History is still cleared the moment you press Reroll or "
		+ "End Turn (both draw new randomness), unless you are carrying the Infinite Die relic.\n\n")
	s += _H % "WINNING AND LOSING"
	s += _table(["", "CONDITION"], [
		["WIN A FIGHT", "Every enemy is reduced to 0 HP."],
		["LOSE", "All five of your main Axies are down. Summoned Axie Eggs do not count."],
		["WIN THE RUN", "Defeat the final boss on the last row of the map (row %d Short / row %d Full)." % [short_rows, full_rows]],
	])
	return s


static func _dice() -> String:
	var s := _H % "A DIE IS AN AXIE"
	s += ("Every Axie carries one six-sided die, and those six faces are its six body parts. "
		+ "Class does not decide which part sits on which face — class decides the DISTRIBUTION "
		+ "of parts. The row of six small squares under each die shows all six faces, with the "
		+ "current one lit.\n\n")
	s += _H % "THE SIX PARTS"
	s += _table(["PART", "ROLE"], [
		["MOUTH", "Single-target damage. Often carries Lifesteal."],
		["HORN", "Your heaviest hits. Often carries Pierce or Heavy."],
		["BACK", "Shield for itself or an ally."],
		["TAIL", "Multi-target work: Cleave, area damage and Poison."],
		["EYES", "Utility: healing, debuffs and summoning."],
		["EARS", "Mana. Always triggers on its own without using your action."],
	])
	s += "\n" + (_H % "RARITY LIVES ON THE FACE")
	s += ("Rarity is a property of each individual face, not the die as a whole. Two or more "
		+ "Legendary faces makes it a GOLDEN DIE; a single Mythic face makes it a COSMIC DIE.\n\n")
	s += _H % "WHY CRIT IS SHOWN BEFORE YOU ATTACK"
	s += ("Crit is decided the moment the die lands, not when you use it, and is shown on the "
		+ "face immediately — you always see everything before you commit to a turn.")
	return s


static func _mana() -> String:
	var s := _H % "WHAT MANA IS FOR"
	s += ("Mana is a shared PARTY resource, spent on Lunacia Cards — the active relics with a "
		+ "button along the bottom bar.\n\n")
	s += _H % "EARNING MANA"
	s += _table(["SOURCE", "DETAIL"], [
		["EARS faces", "Your main source. An Ears face always triggers on its own the moment it lands and never costs you an action."],
		["AQUA class", "The CONDUIT passive adds 1 to every Mana gain."],
		["Mana keyword", "Some faces grant Mana alongside their main effect."],
	])
	s += "\n" + (_H % "THE RULES")
	s += _table(["RULE", "WHAT IT MEANS"], [
		["Carries over", "Mana is not lost at the end of a turn."],
		["Resets each fight", "Every new fight starts at 0 Mana."],
		["No cap", "There is no maximum."],
		["One use per card", "Each Lunacia Card can be used once per turn."],
	])
	s += "\n" + (_H % "SPENDING MANA")
	s += ("The AQUA passive turns every 4 Mana SPENT this fight into 1 Reroll. Hoarding Mana "
		+ "chokes off that reroll supply — spend steadily.\n\n")
	s += _H % "LUNACIA CARDS"
	var rows: Array = []
	for def in RelicRegistry.offerable_defs_sorted():
		if int(def.act_cost) > 0:
			rows.append([String(def.name), "%d MP" % int(def.act_cost), String(def.description)])
	s += _table(["CARD", "COST", "EFFECT"], rows)
	return s


static func _kw() -> String:
	var s := _H % "TARGETING"
	s += _table(["KEYWORD", "EFFECT"], [
		["Cleave", "Full damage to the target and half to the two units next to it."],
		["All / AoE", "Hits every unit on that side. No target selection needed."],
		["Chain N", "N separate hits on random targets."],
		["Multi N", "Performs the action N times against the same target."],
	])
	s += "\n" + (_H % "DAMAGE")
	s += _table(["KEYWORD", "EFFECT"], [
		["Pierce", "Ignores Shield completely and hits HP directly."],
		["Execute", "60% more damage against a target below 50% HP."],
		["Vital", "Double value while the attacking Axie is at full HP."],
		["Crit N%", "An N% chance to deal double damage, decided when the die lands."],
		["Lifesteal", "Heals the attacker for the damage dealt."],
	])
	s += "\n" + (_H % "CHANGES OVER TIME")
	s += _table(["KEYWORD", "EFFECT"], [
		["Growth", "Permanently gains 1 each time you use it, for the rest of the fight."],
		["Decay", "Loses 1 each time you use it."],
	])
	s += "\n" + (_H % "SPECIAL RULES")
	s += _table(["KEYWORD", "EFFECT"], [
		["Cantrip", "Triggers on its own the moment it lands, then the die rerolls itself for free."],
		["Heavy", "This die cannot be rerolled. In exchange the number is much higher."],
		["+Reroll", "Using this face immediately gives you another Reroll."],
		["Self-damage N", "The attacking Axie takes N piercing damage."],
	])
	return s


static func _st() -> String:
	var s := _H % "HELPFUL EFFECTS"
	s += _table(["EFFECT", "RULE"], [
		["Shield", "Absorbs damage before HP. Does not expire at end of turn. Pierce ignores it."],
		["Regen N", "Heals N at the end of the turn, then N drops by 1."],
		["Thorns N", "Anything that attacks this unit takes N damage back. Hard cap %d. Reptile always has Thorns 2." % StatusEngine.THORNS_CAP],
		["Undying", "Survives one lethal hit at 1 HP."],
	])
	s += "\n" + (_H % "HARMFUL EFFECTS")
	s += _table(["EFFECT", "RULE"], [
		["Poison N", "Deals N piercing damage at end of turn, then N drops by 1. Pierces Shield."],
		["Burn N", "Deals N damage at end of turn, then N is HALVED. Pierces Shield."],
		["Weaken N", "That unit deals N less damage per hit."],
		["Vulnerable N", "That unit takes 50% more damage."],
		["Blind N", "All of that unit's damage faces deal 0, for N turns."],
		["Stun", "The unit skips its next turn entirely."],
		["Frozen", "The die cannot be rerolled, but it can still be used."],
	])
	return s


static func _cls() -> String:
	var s := _H % "THE SIX CLASSES"
	s += "A passive is always on, needs no activation, and drives one archetype.\n\n"
	var rows: Array = []
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		var p: Dictionary = ContentDB.CLASS_PASSIVE.get(cls, {})
		rows.append([cls.to_upper(), String(p.get("n", "")), String(p.get("d", ""))])
	s += _table(["CLASS", "PASSIVE", "EFFECT"], rows)
	s += "\n" + (_H % "THE TEN PLAYSTYLES")
	var arows: Array = []
	for k in ContentDB.ARCH.keys():
		var a: Dictionary = ContentDB.ARCH[k]
		arows.append([String(a.get("n", "")), String(a.get("d", ""))])
	s += _table(["PLAYSTYLE", "DIRECTION"], arows)
	return s


static func _relic() -> String:
	var all_defs: Array = RelicRegistry.offerable_defs_sorted()
	var act := 0
	for d in all_defs:
		if int(d.act_cost) > 0:
			act += 1
	var s := _H % "THE FULL RELIC TABLE"
	s += ("There are %d relics: %d passives that are always on, and %d active Lunacia Cards "
		+ "that cost Mana. Relics apply to your whole party.\n\n") % [all_defs.size(), all_defs.size() - act, act]
	var by_rar: Dictionary = {}
	for d in all_defs:
		var r := int(d.rarity)
		if not by_rar.has(r):
			by_rar[r] = []
		by_rar[r].append(d)
	var names := ["COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
	for r in [0, 1, 2, 3, 4]:
		var list: Array = by_rar.get(r, [])
		if list.is_empty():
			continue
		s += _H % ("%s  -  %d relics" % [names[r], list.size()])
		var rows: Array = []
		for d in list:
			rows.append([String(d.name), String(d.archetype) if d.archetype != "" else "-",
				("[CARD - %d MANA] " % int(d.act_cost) if int(d.act_cost) > 0 else "") + String(d.description)])
		s += _table(["NAME", "PLAYSTYLE", "EFFECT"], rows)
	return s


static func _reward() -> String:
	var s := _H % "MAP NODES"
	s += _table(["NODE", "DESCRIPTION"], [
		["BATTLE", "Regular Chimeras. Standard reward."],
		["ELITE", "Much more dangerous. Bigger reward and more Shard."],
		["BOSS", "A boss with its own mechanic. Huge reward."],
		["EVENT", "A risk-and-reward text choice. No combat."],
		["MERCHANT", "Buy relics, a healing Serum and an extra Reroll with Gene Shard."],
		["TREASURE", "A free reward with no risk."],
	])
	s += "\n" + (_H % "REWARD TYPES")
	s += ("There are 7 reward types. Gene Mutation and Rune Imbue — replacing or adding a "
		+ "single face — are not in the game yet.\n\n")
	s += _table(["TYPE", "EFFECT"], [
		["LEVEL UP", "Promotes an Axie to the next tier: rewrites all six faces and Max HP."],
		["ASCENSION", "For an Axie already at max tier: all six faces get 25% stronger, permanently, and it stacks without limit."],
		["RELIC", "An item that changes a rule of the game for your whole party."],
		["MAX HP", "A flat, permanent Max HP bonus for one Axie."],
		["REROLL +1", "Raises your maximum Rerolls per turn, up to 4."],
		["CHAOS DEAL", "The party loses 20% Max HP for the rest of the run in exchange for a Rare-or-better relic."],
		["CURSE PACT", "Enemies gain HP and damage for the rest of the run, in exchange for 1 extra maximum Reroll."],
	])
	s += "\n" + (_H % "GENE SHARD")
	s += ("The only currency in the game. You earn it during a run and spend it at the "
		+ "Merchant. Whatever is left when the run ends is added to your permanent wallet.")
	return s


static func _boss() -> String:
	var s := _H % "SIX BOSSES, SIX MECHANICS"
	s += ("A single run meets 3 bosses (Short) or 4 (Full); the order is randomised every run. "
		+ "The final boss is always NIGHTMARE AGONY.\n\n")
	var rows: Array = []
	var order := ["agony", "gooey_king", "mecha", "frost_lord", "plague_mother", "mirror"]
	for k in order:
		var b: Dictionary = ContentDB.bosses.get(k, {})
		if b.is_empty():
			continue
		rows.append([String(b.get("n", "")), String(b.get("desc", ""))])
	s += _table(["BOSS", "MECHANIC"], rows)
	return s


static func _diff() -> String:
	var mc: Dictionary = RunMapGenerator.MODE_CONFIG
	var s := _H % "ASCENSION — THE DIFFICULTY CEILING"
	s += "Every run you win unlocks the next Ascension level.\n\n"
	s += _table(["LEVEL", "MODIFIER (STACKING)"], [
		["A1", "+10% enemy HP"], ["A2", "+1 Elite per wave"], ["A3", "+10% enemy damage"],
		["A4", "+15% boss HP"], ["A5", "Random Weaken at the start of a fight"],
		["A6", "+10% enemy HP again"], ["A7", "Rewards drop to 2 choices"],
		["A8", "+15% enemy damage again"], ["A9", "+2 more Elites per wave"],
		["A10", "+20% enemy HP and +20% enemy damage"],
	])
	s += "\n" + (_H % "TWO RUN LENGTHS")
	s += _table(["MODE", "ROWS", "BOSS ROWS", "ELITE ROWS"], [
		["SHORT", str(mc["short"]["total_rows"]), str(mc["short"]["boss_rows"]), str(mc["short"]["elite_rows"])],
		["FULL", str(mc["full"]["total_rows"]), str(mc["full"]["boss_rows"]), str(mc["full"]["elite_rows"])],
	])
	s += "\n" + (_H % "CONTROLS")
	s += ("Die-select, Reroll, Undo, Info and Log are on-screen buttons; none of them has a "
		+ "keyboard shortcut yet.\n\n")
	s += _table(["KEY", "ACTION"], [
		["Space", "End turn — the only keyboard shortcut so far"],
	])
	return s


static func _table(headers: Array, rows: Array) -> String:
	var cols: int = headers.size()
	var s := "[table=%d]" % cols
	for h in headers:
		s += "[cell][b]%s[/b][/cell]" % _safe(h)
	for row in rows:
		for cell in row:
			s += "[cell]%s[/cell]" % _safe(cell)
	s += "[/table]\n"
	return s


## Defends the "never <NULL>/NaN/undefined" UI rule (inherited from tools/verify.mjs) at the
## one choke point every dynamic value in this file passes through.
static func _safe(v) -> String:
	if v == null:
		return ""
	var s := str(v)
	if s.to_upper() == "<NULL>" or s.to_upper() == "NAN" or s == "undefined":
		return ""
	return s
