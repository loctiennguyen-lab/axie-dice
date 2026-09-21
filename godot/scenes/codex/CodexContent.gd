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

## X4 — the one-line lede under each tab's title in the Codex panel header.
##
## The mockup draws the slot; this is the build's own copy for it, written off what each tab
## actually says rather than invented. It lives beside TABS so the two cannot fall out of step.
const TAB_LEDE: Dictionary = {
	"basic": "One run, one turn, one action — the loop everything else sits inside.",
	"dice": "Every Axie is a six-sided die, and its six faces are its six body parts.",
	"mana": "The shared party resource, where it comes from, and the only thing it buys.",
	"kw": "Every keyword a face can carry, and exactly what it does when it lands.",
	"st": "Every status a unit can be carrying — what applies it, and when it wears off.",
	"cls": "The six classes and the always-on passive that gives each one its archetype.",
	"relic": "The full relic pool, by rarity, with what each one hooks into.",
	"reward": "What each node type puts in front of you, and what it costs to take it.",
	"boss": "Six bosses, six mechanics. Three or four of them per run, in a random order.",
	"diff": "Ascension — what each level stacks on top of the run before it.",
}

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


## The keyword rule-book as DATA — same "ONE SOURCE" shape `statuses()` below already uses, and
## for the same reason: the die cards in combat now show a tooltip per keyword chip
## (CombatView._update_die_slot_content()), and a second copy of this prose beside the tray is
## how the Codex and the tray end up disagreeing about what CLEAVE does.
##
## `key` is the ENGINE's own keyword string (the keys of ContentDB's face `keywords` arrays,
## which CombatView._KEYWORD_LABEL is also keyed by) — that is what a hover has in hand. `name`
## is the player-facing heading the Codex prints, which is NOT always the key ("aoe" prints as
## "All / AoE", "rerollup" as "+Reroll"), which is exactly why the two are separate fields.
static func keywords() -> Array:
	return [
		{"group": "TARGETING", "key": "cleave", "name": "Cleave",
			"rule": "Full damage to the target and half to the two units next to it."},
		{"group": "TARGETING", "key": "aoe", "name": "All / AoE",
			"rule": "Hits every unit on that side. No target selection needed."},
		{"group": "TARGETING", "key": "chain", "name": "Chain N",
			"rule": "N separate hits on random targets."},
		{"group": "TARGETING", "key": "multi", "name": "Multi N",
			"rule": "Performs the action N times against the same target."},
		{"group": "DAMAGE", "key": "pierce", "name": "Pierce",
			"rule": "Ignores Shield completely and hits HP directly."},
		{"group": "DAMAGE", "key": "exec", "name": "Execute",
			"rule": "60% more damage against a target below 50% HP."},
		{"group": "DAMAGE", "key": "vital", "name": "Vital",
			"rule": "Double value while the attacking Axie is at full HP."},
		{"group": "DAMAGE", "key": "crit", "name": "Crit N%",
			"rule": "An N% chance to deal double damage, decided when the die lands."},
		{"group": "DAMAGE", "key": "lifesteal", "name": "Lifesteal",
			"rule": "Heals the attacker for the damage dealt."},
		{"group": "CHANGES OVER TIME", "key": "growth", "name": "Growth",
			"rule": "Permanently gains 1 each time you use it, for the rest of the fight."},
		{"group": "CHANGES OVER TIME", "key": "decay", "name": "Decay",
			"rule": "Loses 1 each time you use it."},
		{"group": "SPECIAL RULES", "key": "cantrip", "name": "Cantrip",
			"rule": "Triggers on its own the moment it lands, then the die rerolls itself for free."},
		{"group": "SPECIAL RULES", "key": "heavy", "name": "Heavy",
			"rule": "This die cannot be rerolled. In exchange the number is much higher."},
		{"group": "SPECIAL RULES", "key": "rerollup", "name": "+Reroll",
			"rule": "Using this face immediately gives you another Reroll."},
		{"group": "SPECIAL RULES", "key": "selfharm", "name": "Self-damage N",
			"rule": "The attacking Axie takes N piercing damage."},
		{"group": "SPECIAL RULES", "key": "echo", "name": "Echo x2",
			"rule": "The face resolves a second time against the same target."},
	]


## One keyword's {name, rule}, by the engine's own keyword key, or {} when this build has no
## written rule for it yet. A keyword that is ALSO a status (burn/poison/stun/…) falls through
## to `status_tip()` at the call site — see CombatView._effect_tip().
static func keyword_tip(key: String) -> Dictionary:
	for kw in keywords():
		if String(kw["key"]) == key:
			return {"name": String(kw["name"]), "rule": String(kw["rule"])}
	return {}


## One status's {name, rule}, by the key the ENGINE uses. That is `Unit.status`'s own key set
## (poison/burn/regen/blind/weaken/vulnerable/thorns/stun/undying) plus "shield" — which is not
## a stack at all but is drawn as the first chip of the same strip (CB-13) — and "freeze".
##
## Shield's row carries no `tone` (it has no DangoTheme.status_color() case), so its `icon`
## field is the key; every other row's `tone` IS the engine key. Both are read here rather
## than maintaining a third name for the same eleven things.
static func status_tip(key: String) -> Dictionary:
	for st in statuses():
		var k := String(st["tone"])
		if k == "":
			k = String(st["icon"])
		if k == key:
			return {"name": String(st["name"]), "rule": String(st["rule"])}
	return {}


## Unchanged output from the hand-written version this replaces — same four groups, in the same
## order, with the same blank line between a table and the next heading. It is now BUILT from
## `keywords()` so the Codex page and the in-combat die tooltips cannot drift.
static func _kw() -> String:
	var s := ""
	var last_group := ""
	var rows: Array = []
	for kw in keywords():
		var g := String(kw["group"])
		if g != last_group:
			if last_group != "":
				s += _table(["KEYWORD", "EFFECT"], rows) + "\n"
				rows = []
			s += _H % g
			last_group = g
		rows.append([String(kw["name"]), String(kw["rule"])])
	if not rows.is_empty():
		s += _table(["KEYWORD", "EFFECT"], rows)
	return s


## X3 — the eleven statuses as DATA, so the Codex can lay them out as the mockup's card grid
## instead of as a BBCode table.
##
## ONE SOURCE. `_st()` below still returns BBCode, because the in-combat InfoPanel renders this
## same content on a dark panel and has no grid — but it now builds its two tables FROM this
## list rather than repeating the copy. Edit a rule here and both screens change.
##
## `tone` is the key DangoTheme.status_color() knows. Shield is the one entry it has no case
## for (it is not a stack in Unit.status; CB-13 draws it as an INFO chip), so it carries its
## colour directly. `icon` is the mockup-side name — MockupAssets maps it to assets/icons/web/.
## "vulnerable" is the one key whose icon file is spelled differently, which is why the two
## fields are separate rather than one name used for both.
static func statuses() -> Array:
	return [
		{"name": "Shield", "tone": "", "icon": "shield", "good": true,
			"rule": "Absorbs damage before HP. Does not expire at end of turn. Pierce ignores it."},
		{"name": "Regen N", "tone": "regen", "icon": "regen", "good": true,
			"rule": "Heals N at the end of the turn, then N drops by 1."},
		{"name": "Thorns N", "tone": "thorns", "icon": "thorns", "good": true,
			"rule": "Anything that attacks this unit takes N damage back. Hard cap %d. Reptile always has Thorns 2." % StatusEngine.THORNS_CAP},
		{"name": "Undying", "tone": "undying", "icon": "undying", "good": true,
			"rule": "Survives one lethal hit at 1 HP."},
		{"name": "Poison N", "tone": "poison", "icon": "poison", "good": false,
			"rule": "Deals N piercing damage at end of turn, then N drops by 1. Pierces Shield."},
		{"name": "Burn N", "tone": "burn", "icon": "burn", "good": false,
			"rule": "Deals N damage at end of turn, then N is HALVED. Pierces Shield."},
		{"name": "Weaken N", "tone": "weaken", "icon": "weaken", "good": false,
			"rule": "That unit deals N less damage per hit."},
		{"name": "Vulnerable N", "tone": "vulnerable", "icon": "vuln", "good": false,
			"rule": "That unit takes 50% more damage."},
		{"name": "Blind N", "tone": "blind", "icon": "blind", "good": false,
			"rule": "All of that unit's damage faces deal 0, for N turns."},
		{"name": "Stun", "tone": "stun", "icon": "stun", "good": false,
			"rule": "The unit skips its next turn entirely."},
		{"name": "Frozen", "tone": "freeze", "icon": "freeze", "good": false,
			"rule": "The die cannot be rerolled, but it can still be used."},
	]


## The BBCode form, for the in-combat InfoPanel. The Codex panel uses statuses() directly.
## The helpful/harmful split stays HERE and only here: X3 puts all eleven in one grid on the
## Codex, but the InfoPanel is a mid-fight lookup where "is this good or bad for me" is the
## first thing being asked, and it has no grid to group them any other way.
static func _st() -> String:
	var good: Array = []
	var bad: Array = []
	for st in statuses():
		var row := [String(st["name"]), String(st["rule"])]
		if bool(st["good"]):
			good.append(row)
		else:
			bad.append(row)
	var s := _H % "HELPFUL EFFECTS"
	s += _table(["EFFECT", "RULE"], good)
	s += "\n" + (_H % "HARMFUL EFFECTS")
	s += _table(["EFFECT", "RULE"], bad)
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
