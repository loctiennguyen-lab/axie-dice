class_name BossIntroData
extends RefCounted
## Data for the boss intro screen (design/ux/screens/52-boss-intro/spec.md). Presentation only.
##
## `threat` lines: Liam 20/10 (design/proposals/boss-intro-copy.md), checked against the boss mechanics.
## `title` and `chimera` are still the Chimera family names (Liam kept them). `name` is "" = use ContentDB.bosses[key].n (what the map and HUD already say).
## Backgrounds are the PLAIN Chimera paintings (no character); the boss model stands in front of them.
## Only the Venom Chimera (boss key "agony") has a real Chimera model today; the other bosses show their
## current boss model in front of the background matching their class, until their Chimera is made.

const BG_DIR := "res://assets/bosses/chimera_bg/"

## key -> {bg, chimera, cls, name, title, threat}. `cls` is the class word on the chip.
const TABLE := {
	"agony": {"bg": "Venom", "chimera": "Venom Chimera", "cls": "Reptile", "name": "",
		"title": "Venom Chimera", "threat": "Rises once at full HP with a much deadlier die."},
	"gooey_king": {"bg": "Brine", "chimera": "Brine Chimera", "cls": "Aqua", "name": "",
		"title": "Brine Chimera", "threat": "Spawns a Gooey Slime at 2/3 and 1/3 HP."},
	"frost_lord": {"bg": "Brine", "chimera": "Brine Chimera", "cls": "Aqua", "name": "",
		"title": "Brine Chimera", "threat": "Freezes one die each turn. It can't be rerolled."},
	"mecha": {"bg": "Tempest", "chimera": "Tempest Chimera", "cls": "Bird", "name": "",
		"title": "Tempest Chimera", "threat": "Always has Thorns. Every 3rd turn: +50% damage."},
	"mirror": {"bg": "Feral", "chimera": "Feral Chimera", "cls": "Beast", "name": "",
		"title": "Feral Chimera", "threat": "Copies your best face from last turn, +10%."},
	"plague_mother": {"bg": "Parasites", "chimera": "Parasite Chimera", "cls": "Bug", "name": "",
		"title": "Parasite Chimera", "threat": "Summons a minion every 3 turns (max 3). Poisons."},
}

## Real phase count: 2 when the boss has a second die (only agony changes phase today), else 1.
## The 66/33 marks in combat_tune.phase_thresholds are HP bar ticks, not phases.
static func phase_count(boss_key: String) -> int:
	return 2 if not (ContentDB.bosses.get(boss_key, {}).get("die2", []) as Array).is_empty() else 1


## Info for a boss key, or {} when the key or its painting is missing (the caller then skips the intro).
## Result: {key, name, title, cls, threat, phases, bg_path}.
static func info(boss_key: String) -> Dictionary:
	if not TABLE.has(boss_key):
		return {}
	var row: Dictionary = TABLE[boss_key]
	var path := "%sChimera_BG_%s.jpg" % [BG_DIR, String(row["bg"])]
	if not ResourceLoader.exists(path):
		return {}
	var nm := String(row.get("name", ""))
	if nm == "":
		nm = String(ContentDB.bosses.get(boss_key, {}).get("n", boss_key))
	return {"key": boss_key, "name": nm, "title": String(row["title"]), "cls": String(row["cls"]),
		"threat": String(row["threat"]), "phases": phase_count(boss_key), "bg_path": path}
