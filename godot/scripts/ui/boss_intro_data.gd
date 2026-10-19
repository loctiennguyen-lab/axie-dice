class_name BossIntroData
extends RefCounted
## Data for the boss intro screen (design/ux/screens/52-boss-intro/spec.md). Presentation only.
##
## PLACEHOLDER: every `title`, `threat` and `chimera` string below is a stand-in. Liam renames them in
## the design phase. `name` is "" = use ContentDB.bosses[key].n (what the map and HUD already say).
## Backgrounds are the PLAIN Chimera paintings (no character); the boss model stands in front of them.
## Only the Venom Chimera (boss key "agony") has a real Chimera model today; the other bosses show their
## current boss model in front of the background matching their class, until their Chimera is made.

const BG_DIR := "res://assets/bosses/chimera_bg/"

## key -> {bg, chimera, cls, name, title, threat}. `cls` is the class word on the chip.
const TABLE := {
	"agony": {"bg": "Venom", "chimera": "Venom Chimera", "cls": "Reptile", "name": "",
		"title": "Venom Chimera", "threat": "Heals to full once, then hits far harder."},
	"gooey_king": {"bg": "Brine", "chimera": "Brine Chimera", "cls": "Aqua", "name": "",
		"title": "Brine Chimera", "threat": "Splits off a slime at 2/3 and 1/3 HP."},
	"frost_lord": {"bg": "Brine", "chimera": "Brine Chimera", "cls": "Aqua", "name": "",
		"title": "Brine Chimera", "threat": "Freezes one of your dice every turn."},
	"mecha": {"bg": "Tempest", "chimera": "Tempest Chimera", "cls": "Bird", "name": "",
		"title": "Tempest Chimera", "threat": "Always has Thorns. Overdrive every 3rd turn."},
	"mirror": {"bg": "Feral", "chimera": "Feral Chimera", "cls": "Beast", "name": "",
		"title": "Feral Chimera", "threat": "Copies the strongest die you used last turn."},
	"plague_mother": {"bg": "Parasites", "chimera": "Parasite Chimera", "cls": "Bug", "name": "",
		"title": "Parasite Chimera", "threat": "Summons a minion every 3 turns. Stacks Poison."},
}

const PHASES := 3   # same constant CombatView hands the defeat panel


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
		"threat": String(row["threat"]), "phases": PHASES, "bg_path": path}
