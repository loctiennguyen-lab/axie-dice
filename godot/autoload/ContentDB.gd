extends Node
## Loads static content definitions (HeroDef/EventDef/BossDef) once at boot.
##
## VERTICAL SLICE CONTENT (checklist step 6, architecture plan §8): hand-coded here,
## copied verbatim from src/data.js HEROES{} (tier-1 only, one per class) and src/data.js
## MON.slime — numbers below are NOT invented, they are read directly from src/data.js
## (see design/gdd/godot-port-rule-spec.md §2/§7 for face schema, §9/CURVE for the budget
## formula). TODO: replace with .tres resources + a data.js -> .tres converter once that
## pipeline exists (architecture plan §8 checklist step 5+) — do not build that pipeline now.
##
## Must be listed BEFORE RelicRegistry in project.godot's [autoload] section (already is).

## hero_key -> {n, cls, tier, max_hp, die: Array[Dictionary]}
var heroes: Dictionary = {}
## src/data.js TIER_UP (:148-149) — hero_key -> next-tier hero_key, verbatim. Used by the
## tier-up reward (rule spec §7/§9) to know which hero a "class levels up to T2/T3" reward
## should turn into. Leaf tier-3 heroes intentionally have no entry (nowhere further to go),
## matching the JS map exactly (12 entries, not 18).
var tier_up: Dictionary = {}
## enemy_key -> {n, role, cost, hp, die: Array[Dictionary]}
var enemies: Dictionary = {}
## src/data.js NORMAL_POOL (:356-361) — encounter-pool draw list for normal (non-elite) wave
## enemies. `{k: enemy_key, min: power-level gate}` shape kept EXACTLY as JS: `min` is the
## pw gate the real generator applies as `p.min <= pw+1`. Order preserved verbatim — the JS
## generator sorts candidates by cost and then index-picks, so reordering this array changes
## the RNG draw even with an identical seed. NOT YET consumed by CombatEngine._generate_encounter
## (still hardcoded to slime waves) — wiring that is out of scope for this content-only pass.
var normal_pool: Array = []
## src/data.js ELITE_POOL (:362) — elite wave draw list, verbatim, same order-preservation
## reasoning as normal_pool above.
var elite_pool: Array = []
## boss_key -> {n, trait, hpk, hpk2 (optional), dmgk, add_cap, adds, die, die2 (optional), desc}.
## Raw src/data.js BOSSES[] fields, verbatim (rule spec §11) — see boss_stats() below for the
## pure formula (src/engine.js mkBoss) that turns hpk/dmgk into an actual scaled Unit at a
## given power level. NOT YET called from CombatEngine._generate_encounter's boss branch
## (still hardcoded to 3 scaled slimes) — wiring that is out of scope for this content-only
## pass (would require editing combat_engine.gd). See godot/tests/t_content_expansion.gd for
## a direct-construction proof that boss_stats() + the already-generic
## DamagePipeline.check_boss_phase() 2-phase mechanic work correctly today, ahead of that wiring.
var bosses: Dictionary = {}
## src/data.js BOSS_ORDER_12/BOSS_ORDER_20/BOSS_ALT (:389-391) — boss slotting order for the
## short (12-wave) and full (20-wave) run lengths (rule spec §9 RUN_LEN); BOSS_ALT is the pool
## the mid-run boss slot is randomly swapped in from. Verbatim. NOT YET consumed by any
## RunMap/CombatEngine boss-selection code in this pass — same "content ported, wiring is a
## combat_engine.gd/RunMap change" split as the bosses dict above.
var boss_order_12: Array = []
var boss_order_20: Array = []
var boss_alt: Array = []
## Simplest possible in-combat summon token (src/data.js MON.egg) — used by the `summon`
## face type. No tier-1 hero in this slice actually rolls a summon face, so this path is
## unreachable today, but it's cheap to port correctly now rather than leave a crash trap.
var egg_token: Dictionary = {}

var events: Dictionary = {}

# ---------------------------------------------------------------------------
# part_faces — the Axie-part catalogue the Vault/Import feature turns an NFT into a die with.
# ---------------------------------------------------------------------------

## Loaded from `assets/data/part_faces.json`, a straight copy of the repo-root file that
## `tools/gen_faces.mjs` GENERATES. Nothing here is hand-written and nothing here should be
## hand-edited: the generator remains the single source, still runs on the JS side, and Godot
## reads its output. Editing this copy would produce a catalogue that agrees with no one.
##
## Deliberately JSON and not .tres: 285 scarcity entries plus 81 signature faces plus 204
## variants would become hundreds of resource files, and the link back to the generator — the
## thing that makes them trustworthy — would be gone.
##
## Shape (verified 2026-09-19 against the file):
##   constants       22 tuning scalars, including COH (see the key note below)
##   familyVariant   6 classes -> per-slot templates, 147 in total
##   signatureFace   81  hand-authored faces for named parts
##   partVariant     204 formula-derived parts
##   scarcityBucket  285 = 81 + 204, bucket letter per part (C 174 / O 75 / P 18 / X 18)
var part_faces: Dictionary = {}

const PART_FACES_PATH := "res://assets/data/part_faces.json"


func _load_part_faces() -> void:
	part_faces = {}
	if not FileAccess.file_exists(PART_FACES_PATH):
		push_error("ContentDB: %s is missing — Vault/Import cannot build a die without it"
			% PART_FACES_PATH)
		return
	var f := FileAccess.open(PART_FACES_PATH, FileAccess.READ)
	if f == null:
		push_error("ContentDB: could not open %s" % PART_FACES_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ContentDB: %s did not parse as a JSON object" % PART_FACES_PATH)
		return
	part_faces = parsed

	# COH is keyed by coherence COUNT — an integer 0..6 — but JSON has no integer keys, so it
	# arrives as "0".."6". Callers look it up with a number. This project has already shipped
	# one silent bug of exactly this shape (`Unit.growth`, where a string-keyed reader never saw
	# an integer-keyed write and five relics were inert for weeks), so the coercion happens here,
	# once, at the only place the data enters the program.
	#
	# Every OTHER key in this file is a genuine string — part ids look like "aqua|back|Hermit" —
	# so this is targeted, never a blanket "any digit-looking key becomes a number".
	var consts: Dictionary = part_faces.get("constants", {})
	if consts.has("COH"):
		var coh: Dictionary = consts["COH"]
		var fixed: Dictionary = {}
		for k in coh.keys():
			fixed[int(k)] = float(coh[k])
		consts["COH"] = fixed


## src/data.js PASSIVE (:54), verbatim. The BEHAVIOUR of all six passives is already
## implemented in combat_engine.gd/damage_pipeline.gd/status_engine.gd; what was missing was
## the TEXT — so the game applied FERAL and never told the player FERAL existed. Kept as data
## here rather than as strings inside a UI file, because two screens will want it (the unit
## inspector today, the Codex later) and a second copy is a second thing to keep true.
const CLASS_PASSIVE := {
	"plant": {"n": "BULWARK", "a": "shield",
		"d": "Every Shield you create is increased by 2. An Axie with 10 or more Shield gains Thorns 2."},
	"beast": {"n": "FERAL", "a": "exec",
		"d": "Attacks against a target below 50% HP deal 60% more damage."},
	"aqua": {"n": "CONDUIT", "a": "mana",
		"d": "All Mana you gain is increased by 1. Every 4 Mana you spend grants 1 Reroll."},
	"reptile": {"n": "SCALES", "a": "thorns",
		"d": "Always has Thorns 2. Your Thorns also apply Poison 1."},
	"bug": {"n": "VIRULENT", "a": "poison",
		"d": "Applying Poison to a target that already has Poison adds 2 stacks instead of 1."},
	"bird": {"n": "TALON", "a": "pierce",
		"d": "Pierce attacks deal 3 extra damage. Your area faces also gain Pierce."},
}


## src/data.js CURVE.tune — encounter difficulty formula, rule spec §9. Kept as data here
## (not hardcoded inside CombatEngine) so a balance pass only ever touches this file.
##
## DIVERGENCE FROM src/data.js, ON PURPOSE (wayfinder ticket B, decided by the user 2026-09-19):
## `growth` is 1.125 here where the live JS build has 1.15. Everything else is unchanged.
##
## Why: `budget(pw)` is driven by how many NODES the player has completed, and this port's map
## is 18 rows where JS's is 12. Run the same curve over a longer map and every boss arrives
## far stronger than the one the live game ships:
##
##       boss     JS row/pw -> budget     Godot row/pw -> budget    with growth 1.15
##        #1        r4/pw3  ->  16.0        r6/pw5   ->  21.1            +32%
##        #2        r8/pw7  ->  27.9        r12/pw11 ->  48.9            +75%   <- worst
##        #3       r12/pw11 ->  48.9        r18/pw17 ->  71.7            +47%
##
## The mid-boss, not the final one, was the spike: the player meets it with a team that has
## not had time to tier up, against enemies worth nearly double the original.
##
## 1.125 was chosen over the value that matches JS most closely, and the reason is measured.
## `t_full_run_loop` drives a deliberately weak auto-player (never rerolls, never uses a relic)
## and reports how far it gets across four seeds:
##
##       growth   boss #1 / #2 / #3 vs JS      auto-player
##       1.100      +6% /  +7% / -14%          4 wins / 0 deaths   <- a bad player wins always
##       1.115     +13% / +24% /  +1%          2 wins / 2 deaths
##       1.125     +18% / +37% / +13%          2 wins / 2 deaths   <- chosen
##       1.135     +24% / +51% / +25%          2 wins / 2 deaths
##       1.150     +32% / +75% / +47%          0 wins / 4 deaths   <- the unported JS value
##
## Matching JS on paper produced a game a player who does nothing right still wins every time;
## 1.125 keeps the run winnable without that. Read "2 wins / 2 deaths" as a relative gauge
## between curves, NOT as a 50% win rate — a real player is far stronger than this auto-player.
##
## The project docs recorded this gap as "+34%", which came from reading `pw` at the final
## boss as 18 (the row number). It is 17 — `power_level` counts nodes COMPLETED, and the boss
## has not been fought yet. Measured, the real figure was +47%.
##
## Do not "restore" 1.15 to match src/data.js without also changing the row count back.
const TUNE := {"base": 10.5, "growth": 1.125, "growth2": 1.05, "knee": 12, "elite_mult": 1.25}


## Populated in _init() (constructor), NOT _ready(): SceneTree scripts launched via
## `godot --script ...` (all our tests/*.gd headless gates) call their own _initialize()
## before autoload nodes' _ready() fires, so anything filled only in _ready() reads back
## empty from a test connecting to this autoload. _init() runs at object construction,
## which happens while the engine is still setting up autoloads, strictly before that.
func _init() -> void:
	_load_heroes()
	_load_enemies()
	_load_bosses()
	_load_events()
	_load_part_faces()


func _load_heroes() -> void:
	heroes = {
		# --- tier 1 (already shipped in the original vertical slice) ---
		"plant1": _hero("Olek", "plant", 1, 17, [
			_f("back", "shield", 4), _f("back", "shield", 3), _f("mouth", "dmg", 2),
			_f("back", "shield", 2), _f("horn", "dmg", 3), _f("ears", "mana", 1, ["cantrip"]),
		]),
		"beast1": _hero("Buba", "beast", 1, 12, [
			_f("horn", "dmg", 5, ["heavy"]), _f("horn", "dmg", 3), _f("mouth", "dmg", 3),
			_f("mouth", "dmg", 2, ["growth"]), _f("back", "shield", 2), _f("mouth", "dmg", 2),
		]),
		"aqua1": _hero("Puffy", "aqua", 1, 13, [
			_f("ears", "mana", 1, ["cantrip"]), _f("ears", "mana", 1, ["cantrip"]), _f("eyes", "heal", 3),
			_f("mouth", "dmg", 3), _f("horn", "dmg", 4), _f("mouth", "dmg", 2),
		]),
		"reptile1": _hero("Machito", "reptile", 1, 16, [
			_f("back", "shield", 4), _f("tail", "poison", 2), _f("mouth", "dmg", 3),
			_f("eyes", "buff", 0, ["thorns:2"]), _f("back", "shield", 2), _f("horn", "dmg", 3),
		]),
		"bug1": _hero("Pomodoro", "bug", 1, 14, [
			_f("eyes", "debuff", 0, ["weaken:2"]), _f("tail", "poison", 2), _f("mouth", "dmg", 3),
			_f("back", "shield", 3), _f("tail", "poison", 1), _f("horn", "dmg", 3),
		]),
		"bird1": _hero("Momo", "bird", 1, 11, [
			_f("horn", "dmg", 3, ["pierce"]), _f("mouth", "dmg", 4), _f("tail", "dmg", 2, ["aoe"]),
			_f("ears", "mana", 1, ["cantrip"]), _f("mouth", "dmg", 2), _f("horn", "dmg", 2, ["pierce"]),
		]),

		# --- tier 2/3 (content-expansion pass — copied verbatim from src/data.js HEROES{},
		# same character per class leveling up via the TIER_UP reward, rule spec §7/§9) ---
		"plant2": _hero("Olek", "plant", 2, 25, [
			_f("back", "shield", 6), _f("back", "shield", 5, ["aoe"]), _f("mouth", "dmg", 4, ["lifesteal"]),
			_f("eyes", "heal", 4), _f("horn", "dmg", 5), _f("ears", "mana", 1, ["cantrip"]),
		]),
		"plant3": _hero("Olek", "plant", 3, 37, [
			_f("back", "shield", 9), _f("back", "shield", 7, ["aoe"]), _f("mouth", "dmg", 6, ["lifesteal"]),
			_f("eyes", "heal", 6, ["aoe"]), _f("horn", "dmg", 8, ["cleave"]), _f("ears", "mana", 2, ["cantrip"]),
		]),
		"beast2": _hero("Buba", "beast", 2, 18, [
			_f("horn", "dmg", 8, ["heavy"]), _f("horn", "dmg", 5), _f("mouth", "dmg", 4, ["growth"]),
			_f("mouth", "dmg", 6, ["selfharm:2"]), _f("tail", "dmg", 3, ["cleave"]), _f("back", "shield", 3),
		]),
		"beast3": _hero("Buba", "beast", 3, 26, [
			_f("horn", "dmg", 13, ["heavy"]), _f("horn", "dmg", 8, ["vital"]), _f("mouth", "dmg", 6, ["growth"]),
			_f("mouth", "dmg", 10, ["selfharm:3"]), _f("tail", "dmg", 5, ["cleave"]), _f("back", "shield", 5),
		]),
		"aqua2": _hero("Puffy", "aqua", 2, 19, [
			_f("ears", "mana", 2, ["cantrip"]), _f("ears", "mana", 1, ["cantrip", "rerollup"]), _f("eyes", "heal", 5),
			_f("mouth", "dmg", 5), _f("horn", "dmg", 6, ["pierce"]), _f("tail", "dmg", 3, ["aoe"]),
		]),
		"aqua3": _hero("Puffy", "aqua", 3, 27, [
			_f("ears", "mana", 3, ["cantrip"]), _f("ears", "mana", 2, ["cantrip", "rerollup"]), _f("eyes", "heal", 8, ["aoe"]),
			_f("mouth", "dmg", 8), _f("horn", "dmg", 9, ["pierce"]), _f("tail", "dmg", 5, ["aoe"]),
		]),
		"reptile2": _hero("Machito", "reptile", 2, 23, [
			_f("back", "shield", 6), _f("tail", "poison", 3, ["aoe"]), _f("mouth", "dmg", 4),
			_f("eyes", "buff", 0, ["thorns:3"]), _f("back", "shield", 4, ["thorns:2"]), _f("horn", "dmg", 5, ["pierce"]),
		]),
		"reptile3": _hero("Machito", "reptile", 3, 33, [
			_f("back", "shield", 9), _f("tail", "poison", 5, ["aoe"]), _f("mouth", "dmg", 7),
			_f("eyes", "debuff", 0, ["stun"]), _f("back", "shield", 6, ["thorns:4"]), _f("horn", "dmg", 8, ["pierce"]),
		]),
		"bug2": _hero("Pomodoro", "bug", 2, 20, [
			_f("eyes", "debuff", 0, ["weaken:3"]), _f("eyes", "debuff", 0, ["vulnerable:2"]), _f("tail", "poison", 3),
			_f("mouth", "dmg", 4, ["multi:2"]), _f("back", "shield", 4), _f("horn", "dmg", 6),
		]),
		"bug3": _hero("Pomodoro", "bug", 3, 28, [
			_f("eyes", "debuff", 0, ["weaken:4", "aoe"]), _f("eyes", "debuff", 0, ["vulnerable:3"]), _f("tail", "poison", 4, ["aoe"]),
			_f("mouth", "dmg", 5, ["multi:3"]), _f("eyes", "debuff", 0, ["blind:2"]), _f("horn", "dmg", 9),
		]),
		"bird2": _hero("Momo", "bird", 2, 16, [
			_f("horn", "dmg", 5, ["pierce"]), _f("mouth", "dmg", 6), _f("tail", "dmg", 3, ["aoe"]),
			_f("ears", "mana", 1, ["cantrip"]), _f("mouth", "dmg", 3, ["chain:3"]), _f("tail", "dmg", 2, ["aoe"]),
		]),
		"bird3": _hero("Momo", "bird", 3, 23, [
			_f("horn", "dmg", 8, ["pierce"]), _f("mouth", "dmg", 9, ["pierce"]), _f("tail", "dmg", 5, ["aoe"]),
			_f("ears", "mana", 2, ["cantrip"]), _f("mouth", "dmg", 4, ["chain:4"]), _f("tail", "dmg", 4, ["aoe", "pierce"]),
		]),
	}
	# src/data.js TIER_UP (:148-149), verbatim — see the `tier_up` field doc comment up top.
	tier_up = {
		"plant1": "plant2", "plant2": "plant3", "beast1": "beast2", "beast2": "beast3",
		"aqua1": "aqua2", "aqua2": "aqua3", "reptile1": "reptile2", "reptile2": "reptile3",
		"bug1": "bug2", "bug2": "bug3", "bird1": "bird2", "bird2": "bird3",
	}


func _load_enemies() -> void:
	enemies = {
		"slime": {
			"n": "Gooey Slime", "role": "bruiser", "cost": 3, "hp": 9, "die": [
				_f("m", "dmg", 3), _f("m", "dmg", 3), _f("m", "dmg", 2),
				_f("m", "shield", 3), _blank(), _f("m", "dmg", 4),
			],
		},
		# --- content-expansion pass — copied verbatim from src/data.js MON{}, chosen to cover
		# 5 AI roles CombatEngine._pick_enemy_intent() already special-cases (bruiser is
		# covered by slime above): assassin/tank/healer/poisoner/mage. No core-file change
		# needed — the role dispatch in combat_engine.gd is already generic/data-driven. ---
		"chomper": {
			"n": "Chomper", "role": "bruiser", "cost": 4, "hp": 11, "die": [
				_f("m", "dmg", 4), _f("m", "dmg", 4), _f("m", "dmg", 5),
				_blank(), _f("m", "dmg", 3), _f("m", "shield", 2),
			],
		},
		"ravenling": {
			"n": "Ravenling", "role": "assassin", "cost": 5, "hp": 10, "die": [
				_f("m", "dmg", 5, ["pierce"]), _f("m", "dmg", 4), _f("m", "dmg", 3, ["aoe"]),
				_f("m", "dmg", 6), _blank(), _f("m", "dmg", 4, ["pierce"]),
			],
		},
		"spikelet": {
			"n": "Spikelet", "role": "tank", "cost": 4, "hp": 12, "die": [
				_f("m", "dmg", 3), _f("m", "buff", 0, ["thorns:3"]), _f("m", "dmg", 4),
				_f("m", "shield", 4), _f("m", "dmg", 2), _blank(),
			],
		},
		"jellyfin": {
			"n": "Jellyfin", "role": "healer", "cost": 5, "hp": 13, "die": [
				_f("m", "dmg", 4, ["cleave"]), _f("m", "heal", 5), _f("m", "shield", 5),
				_f("m", "heal", 4, ["aoe"]), _f("m", "dmg", 5), _blank(),
			],
		},
		"bugling": {
			"n": "Bugling", "role": "poisoner", "cost": 3, "hp": 8, "die": [
				_f("m", "poison", 2), _f("m", "dmg", 3), _f("m", "dmg", 2),
				_f("m", "poison", 3), _blank(), _f("m", "dmg", 4),
			],
		},
		"hexeye": {
			"n": "Hexeye", "role": "mage", "cost": 7, "hp": 15, "die": [
				_f("m", "debuff", 0, ["blind:2"]), _f("m", "dmg", 6), _f("m", "debuff", 0, ["vulnerable:3"]),
				_f("m", "dmg", 5, ["aoe"]), _f("m", "debuff", 0, ["freeze"]), _blank(),
			],
		},
		# --- content-expansion pass 2 — remaining 14 of the 22 src/data.js MON{} entries
		# (:298-355), copied verbatim. 10 normal + 4 elite (`elite: 1`, matching JS `elite:1`
		# — downstream code that special-cases elite waves reads this field). `broodmaw`
		# keeps `summons: "bugling"` verbatim (src/data.js :332-333); no die face is blank,
		# unlike most other monsters here, because JS gives it 6 real faces (2 summon, not B). ---
		"bruiser": {
			"n": "Bruiser", "role": "bruiser", "cost": 7, "hp": 20, "die": [
				_f("m", "dmg", 8, ["heavy"]), _f("m", "dmg", 6), _f("m", "dmg", 5),
				_f("m", "shield", 5), _f("m", "dmg", 7), _blank(),
			],
		},
		"stalker": {
			"n": "Stalker", "role": "assassin", "cost": 8, "hp": 14, "die": [
				_f("m", "dmg", 9, ["pierce"]), _f("m", "dmg", 7, ["exec"]), _f("m", "dmg", 6),
				_f("m", "dmg", 11, ["pierce"]), _f("m", "shield", 4), _blank(),
			],
		},
		"thornback": {
			"n": "Thornback", "role": "tank", "cost": 6, "hp": 19, "die": [
				_f("m", "shield", 6), _f("m", "dmg", 5), _f("m", "buff", 0, ["thorns:4"]),
				_f("m", "dmg", 6, ["cleave"]), _f("m", "dmg", 4), _blank(),
			],
		},
		"warden": {
			"n": "Warden", "role": "healer", "cost": 9, "hp": 26, "die": [
				_f("m", "shield", 9, ["aoe"]), _f("m", "dmg", 8), _f("m", "heal", 8, ["aoe"]),
				_f("m", "dmg", 10), _f("m", "buff", 0, ["thorns:5"]), _blank(),
			],
		},
		"venomaw": {
			"n": "Venomaw", "role": "poisoner", "cost": 6, "hp": 14, "die": [
				_f("m", "poison", 3, ["aoe"]), _f("m", "dmg", 6), _f("m", "poison", 4),
				_f("m", "dmg", 5), _f("m", "debuff", 0, ["weaken:2"]), _blank(),
			],
		},
		"pyrewing": {
			"n": "Pyrewing", "role": "mage", "cost": 8, "hp": 16, "die": [
				_f("m", "dmg", 6, ["aoe", "burn:3"]), _f("m", "dmg", 8), _f("m", "dmg", 5, ["burn:5"]),
				_f("m", "dmg", 7, ["aoe"]), _f("m", "shield", 6), _blank(),
			],
		},
		"broodmaw": {
			"n": "Broodmaw", "role": "summoner", "cost": 8, "hp": 18, "summons": "bugling", "die": [
				_f("m", "dmg", 6), _f("m", "summon", 1), _f("m", "dmg", 7),
				_f("m", "shield", 6), _f("m", "summon", 1), _f("m", "dmg", 5, ["aoe"]),
			],
		},
		"bomblet": {
			"n": "Bomblet", "role": "kamikaze", "cost": 5, "hp": 7, "die": [
				_f("m", "dmg", 12, ["aoe", "selfkill"]), _f("m", "dmg", 3), _f("m", "dmg", 4),
				_f("m", "dmg", 12, ["aoe", "selfkill"]), _f("m", "shield", 3), _blank(),
			],
		},
		"totem": {
			"n": "Chimera Totem", "role": "buffer", "cost": 6, "hp": 16, "die": [
				_f("m", "buff", 0, ["enrage"]), _f("m", "shield", 7, ["aoe"]), _f("m", "dmg", 5),
				_f("m", "buff", 0, ["enrage"]), _f("m", "heal", 6, ["aoe"]), _blank(),
			],
		},
		"cleaver": {
			"n": "Cleaver", "role": "bruiser", "cost": 8, "hp": 19, "die": [
				_f("m", "dmg", 7, ["cleave"]), _f("m", "dmg", 9), _f("m", "dmg", 6, ["cleave"]),
				_f("m", "dmg", 5), _f("m", "shield", 6), _blank(),
			],
		},
		"e_ravager": {
			"n": "Elite Ravager", "role": "bruiser", "cost": 11, "elite": 1, "hp": 30, "die": [
				_f("m", "dmg", 11, ["heavy"]), _f("m", "dmg", 8, ["cleave"]), _f("m", "dmg", 7),
				_f("m", "dmg", 9), _f("m", "shield", 8), _f("m", "dmg", 6, ["aoe"]),
			],
		},
		"e_plague": {
			"n": "Elite Plaguebearer", "role": "poisoner", "cost": 11, "elite": 1, "hp": 28, "die": [
				_f("m", "poison", 5, ["aoe"]), _f("m", "dmg", 9), _f("m", "poison", 6),
				_f("m", "debuff", 0, ["weaken:3"]), _f("m", "dmg", 8, ["aoe"]), _f("m", "heal", 8),
			],
		},
		"e_bulwark": {
			"n": "Elite Bulwark", "role": "tank", "cost": 11, "elite": 1, "hp": 38, "die": [
				_f("m", "shield", 12, ["aoe"]), _f("m", "dmg", 10), _f("m", "buff", 0, ["thorns:6"]),
				_f("m", "dmg", 12), _f("m", "heal", 10, ["aoe"]), _f("m", "dmg", 7, ["cleave"]),
			],
		},
		"e_archon": {
			"n": "Elite Archon", "role": "mage", "cost": 11, "elite": 1, "hp": 26, "die": [
				_f("m", "dmg", 9, ["aoe", "burn:4"]), _f("m", "debuff", 0, ["blind:2", "aoe"]), _f("m", "dmg", 13),
				_f("m", "debuff", 0, ["vulnerable:4"]), _f("m", "dmg", 8, ["aoe"]), _f("m", "shield", 10),
			],
		},
	}
	egg_token = {
		"n": "Axie Egg", "role": "token", "cost": 2, "hp": 6, "die": [
			_f("m", "dmg", 4), _f("m", "dmg", 3), _f("m", "shield", 3),
			_f("m", "dmg", 5), _f("m", "dmg", 3), _blank(),
		],
	}
	# src/data.js NORMAL_POOL (:356-361), verbatim, order preserved — see the `normal_pool`
	# field doc comment up top for why order matters.
	normal_pool = [
		{"k": "slime", "min": 1}, {"k": "chomper", "min": 1}, {"k": "bugling", "min": 1}, {"k": "spikelet", "min": 2},
		{"k": "jellyfin", "min": 3}, {"k": "ravenling", "min": 3}, {"k": "bomblet", "min": 4}, {"k": "thornback", "min": 5},
		{"k": "venomaw", "min": 5}, {"k": "totem", "min": 6}, {"k": "bruiser", "min": 7}, {"k": "hexeye", "min": 7},
		{"k": "pyrewing", "min": 8}, {"k": "stalker", "min": 9}, {"k": "broodmaw", "min": 9}, {"k": "cleaver", "min": 10}, {"k": "warden", "min": 11},
	]
	# src/data.js ELITE_POOL (:362), verbatim.
	elite_pool = ["e_ravager", "e_plague", "e_bulwark", "e_archon"]


## Content-expansion pass — copied verbatim from src/data.js BOSSES[] (rule spec §11).
## All 6 bosses are now ported as DATA (updated from the earlier 2-of-6 state — see git
## history for the stale version of this comment). Trait *mechanics* remain wired for only
## one of them:
##  - "agony" (NIGHTMARE AGONY, trait 'phase'): the ONLY boss trait whose mechanic already has
##    a real, generic call site in this codebase — DamagePipeline.check_boss_phase() fires
##    unconditionally for any `tgt.is_boss` unit and reads trait/hp2/die2 straight out of
##    custom_state, so this boss's full advertised mechanic (heals to full, switches to a
##    deadlier die, on first death) works today with ZERO core-file changes.
##  - "gooey_king" (trait 'split'), "mecha" (trait 'thorns'), "frost_lord" (trait 'freeze'),
##    "plague_mother" (trait 'summon'), "mirror" (trait 'mirror'): shipped as DATA ONLY. Each
##    needs a per-turn/on-damage trigger that does not exist yet — src/engine.js's real
##    dispatch is a `switch(b.trait)`/`if(b.trait===...)` block inside the JS turn-start/
##    damage flow (~line 878-900), and the Godot equivalent (CombatEngine._boss_turn_traits(),
##    a deliberate no-op stub today) lives in combat_engine.gd, which this content-only pass
##    is NOT allowed to touch. `custom_state` still carries `trait`/`add_cap`/`adds` so wiring
##    each real trigger later is a combat_engine.gd-only change, not a content change —
##    exactly the forward-compat purpose Unit.custom_state documents itself as existing for.
## RESOLVED in the Phase-1 parity pass (2026-09-18) — this used to be a TODO saying the five
## traits split/thorns/freeze/summon/mirror were still unwired, and it was still saying so long
## after they were. All five run today: `CombatEngine._boss_turn_traits()` handles thorns
## (mecha's permThorns + OVERDRIVE every third turn), summon (plague_mother's BROOD), freeze
## (frost_lord) and mirror, and `DamagePipeline.check_boss_phase()` handles split
## (gooey_king, at 2/3 and 1/3 HP, respecting add_cap) alongside agony's phase change.
## `t_boss_encounters` covers all six bosses in 62 checks.
##
## Left as a note rather than deleted because a stale TODO is not harmless here: this project
## has already shipped a comment that described a bug as if it were the spec (`r_chainreact`),
## and a TODO claiming finished work is unfinished invites the next reader to build it twice.
func _load_bosses() -> void:
	bosses = {
		"agony": {
			"n": "NIGHTMARE AGONY", "trait": "phase", "hpk": 2.0, "hpk2": 2.5, "dmgk": 0.50,
			"add_cap": 0, "adds": [],
			"desc": "TWO PHASES — on defeat it heals to full and switches to a far deadlier die.",
			"die": [
				_f("m", "dmg", 16), _f("m", "dmg", 12, ["aoe"]), _f("m", "shield", 16),
				_f("m", "dmg", 14, ["cleave"]), _f("m", "debuff", 0, ["blind:3"]), _f("m", "dmg", 20, ["pierce"]),
			],
			"die2": [
				_f("m", "dmg", 22, ["pierce"]), _f("m", "dmg", 16, ["aoe"]), _f("m", "dmg", 18, ["cleave"]),
				_f("m", "dmg", 14, ["aoe", "pierce"]), _f("m", "debuff", 0, ["vulnerable:4"]), _f("m", "dmg", 26),
			],
		},
		"gooey_king": {
			"n": "GOOEY KING", "trait": "split", "hpk": 3.7, "dmgk": 0.62,
			"add_cap": 2, "adds": ["slime"],
			"desc": "SPLIT — spawns a Gooey Slime at 2/3 and 1/3 HP.",
			"die": [
				_f("m", "dmg", 9), _f("m", "dmg", 7, ["cleave"]), _f("m", "shield", 9),
				_f("m", "dmg", 6, ["aoe"]), _f("m", "dmg", 11), _f("m", "heal", 8),
			],
			"die2": [],
		},
		"mecha": {
			"n": "MECHA CHIMERA", "trait": "thorns", "hpk": 3.3, "dmgk": 0.57,
			"add_cap": 0, "adds": [],
			"desc": "RETALIATE — always has Thorns. Every 3rd turn it enters OVERDRIVE and deals 50% more damage.",
			"die": [
				_f("m", "dmg", 13), _f("m", "dmg", 9, ["aoe"]), _f("m", "shield", 14),
				_f("m", "dmg", 11, ["cleave"]), _f("m", "dmg", 16, ["pierce"]), _f("m", "buff", 0, ["thorns:6"]),
			],
		},
		"frost_lord": {
			"n": "FROST LORD", "trait": "freeze", "hpk": 3.2, "dmgk": 0.55,
			"add_cap": 0, "adds": [],
			"desc": "DEEP FREEZE — freezes one of your dice each turn. Frozen dice cannot be rerolled, but can still be used.",
			"die": [
				_f("m", "dmg", 12, ["aoe"]), _f("m", "dmg", 15), _f("m", "shield", 13, ["aoe"]),
				_f("m", "debuff", 0, ["freeze", "aoe"]), _f("m", "dmg", 18, ["pierce"]), _f("m", "heal", 12),
			],
		},
		"plague_mother": {
			"n": "PLAGUE MOTHER", "trait": "summon", "hpk": 3.0, "dmgk": 0.54,
			"add_cap": 3, "adds": ["bugling", "venomaw"],
			"desc": "BROOD — summons a minion every 3 turns and stacks Poison relentlessly.",
			"die": [
				_f("m", "poison", 7, ["aoe"]), _f("m", "dmg", 14), _f("m", "poison", 9),
				_f("m", "dmg", 12, ["aoe"]), _f("m", "debuff", 0, ["weaken:4"]), _f("m", "heal", 14),
			],
		},
		"mirror": {
			"n": "MIRROR CHIMERA", "trait": "mirror", "hpk": 2.9, "dmgk": 0.52,
			"add_cap": 0, "adds": [],
			"desc": "MIRROR — copies the strongest die face you used last turn and plays it back at you.",
			"die": [
				_f("m", "dmg", 14), _f("m", "dmg", 10, ["aoe"]), _f("m", "shield", 15),
				_f("m", "dmg", 12, ["cleave"]), _f("m", "dmg", 17, ["pierce"]), _f("m", "heal", 13),
			],
		},
	}
	# src/data.js BOSS_ORDER_12/BOSS_ORDER_20/BOSS_ALT (:389-391), verbatim — see the
	# `boss_order_12`/`boss_order_20`/`boss_alt` field doc comments up top.
	boss_order_12 = ["gooey_king", "frost_lord", "agony"]
	boss_order_20 = ["gooey_king", "mecha", "plague_mother", "agony"]
	boss_alt = ["frost_lord", "mirror"]


## Event node content (checklist step 4+, reward/event/shop/treasure loop) — copied
## VERBATIM from src/data.js EVENTS[] (rule spec §9/§10 footnote: "campfire là TÊN loại
## event hiện có trong code, nhưng hiệu ứng của nó KHÔNG phải hồi máu dần — đọc kỹ nội
## dung sự kiện thật khi port, đừng suy diễn từ tên").
##
## 5 of the 6 src/data.js EVENTS entries are ported this pass: "shrine", "campfire"
## (already shipped), plus "treasure"/"casino"/"mutant" (this content-expansion pass).
## "merchant" is DELIBERATELY NOT ported as a playable event — src/engine.js:400 filters
## it out of the random-event draw itself (`EVENTS.filter(e=>!e.shop)`) because
## `{opts:null, shop:1}` marks it as the dedicated shop node, not a choose-an-option event;
## this Godot port already has its own separate shop node type (rule spec §9 footnote), so
## adding "merchant" here would create a second, redundant/broken shop path.
##
## "casino" (`bet_big`) and "mutant" (`dip`, `drink`) read from src/data.js's FACE_POOL via
## `facePool()` (src/engine.js ~1005, 1219, 1224, 1227) to pick a random mutation face —
## FACE_POOL is NOT ported to this file. Those 3 options carry `"needs_face_pool": true` so
## whatever eventually consumes ContentDB.events (RunMapController today just iterates every
## `opts` entry unconditionally — see RunMapController._on_event_node()) can filter them out
## rather than call into RunState.apply_event_fx() with an fx it can't resolve. As of
## this pass RunState.apply_event_fx() (owned by another workstream, not edited here)
## has no case for ANY of casino's/mutant's fx values yet (bet_small/bet_big/shards30/dip/
## drink/leave all fall through to its `return ""` default) — so today picking "casino" or
## "mutant" at a real event node is a silent no-op for every option, not just the 3 marked
## here. The marker only guards against the FACE_POOL-specific crash once the rest gets wired.
func _load_events() -> void:
	events = {
		"shrine": {
			"n": "LUNACIA SHRINE", "icon": "⛩", "desc": "An ancient altar. Power always has a price.",
			"opts": [
				{"text": "Accept the blessing", "desc": "Permanently gain 1 maximum Reroll", "fx": "bless_reroll"},
				{"text": "Make the wager", "desc": "The whole party loses 20% Max HP. Receive a Legendary relic.", "fx": "gamble_legend"},
				{"text": "Pray", "desc": "Heal to full and give one Axie 8 Max HP", "fx": "pray"},
			],
		},
		"campfire": {
			"n": "CAMPFIRE", "icon": "✚", "desc": "Rest, or forge your genes.",
			"opts": [
				{"text": "Rest", "desc": "One Axie gains 12 Max HP", "fx": "rest"},
				{"text": "Forge", "desc": "One Axie gets 30% stronger on all six faces", "fx": "forge"},
				{"text": "Meditate", "desc": "The whole party gains 4 Max HP", "fx": "meditate"},
			],
		},
		"treasure": {
			"n": "ANCIENT CRYPT", "icon": "❖", "desc": "A sealed gene vault.",
			"opts": [
				{"text": "Open the vault", "desc": "Receive a random relic at a better than usual rarity", "fx": "chest"},
				{"text": "Smash it open", "desc": "Receive 60 Gene Shard", "fx": "shards60"},
			],
		},
		# needs_face_pool: true on "Big bet" — src/engine.js `bet_big` fx rolls
		# facePool(s,4,4) (Mythic-tier faces); see the header comment above.
		"casino": {
			"n": "MUTANT CASINO", "icon": "☘", "desc": "The dice decide. Even odds.",
			"opts": [
				{"text": "Small bet", "desc": "50%: an Epic relic. 50%: the party loses 10% Max HP.", "fx": "bet_small"},
				{"text": "Big bet", "desc": "40%: a Mythic face. 60%: lose a random relic.", "fx": "bet_big", "needs_face_pool": true},
				{"text": "Walk away", "desc": "Receive 30 Gene Shard", "fx": "shards30"},
			],
		},
		# needs_face_pool: true on "Dip one Axie" / "Drink it" — src/engine.js `dip` fx rolls
		# facePool(s,2,2) (Epic), `drink` fx rolls facePool(s,3,3) (Legendary); see the header
		# comment above.
		"mutant": {
			"n": "MUTAGEN POOL", "icon": "❂", "desc": "Glowing liquid. Dip an Axie in?",
			"opts": [
				{"text": "Dip one Axie", "desc": "Overwrite 2 random faces with random Epic faces", "fx": "dip", "needs_face_pool": true},
				{"text": "Drink it", "desc": "RISK: one Axie loses 8 Max HP and gains a Legendary face", "fx": "drink", "needs_face_pool": true},
				{"text": "Leave", "desc": "The whole party heals to full", "fx": "leave"},
			],
		},
	}


## Pure formula, direct port of src/engine.js mkBoss() (minus the `uid`/live-Unit assembly,
## which belongs to whatever eventually builds the Unit — CombatEngine, once its
## _generate_encounter() boss branch is wired to call this). Returns {} for an unknown key.
## `mods` is the same {hp, dmg, boss_hp} shape ContentDB.ascension_mods() returns.
func boss_stats(bk: String, pw: int, mods: Dictionary) -> Dictionary:
	var b: Dictionary = bosses.get(bk, {})
	if b.is_empty():
		return {}
	var bud: float = budget(pw)
	var hp_mult: float = float(mods.get("boss_hp", 1.0)) * float(mods.get("hp", 1.0))
	var hp: int = int(round(float(b.get("hpk", 1.0)) * bud * hp_mult))
	var die: Array = b.get("die", [])
	var ds: float = (float(b.get("dmgk", 0.5)) * bud * float(mods.get("dmg", 1.0))) / max(0.0001, avg_face_value(die))
	var out := {
		"n": String(b.get("n", bk)),
		"trait": String(b.get("trait", "")),
		"add_cap": int(b.get("add_cap", 0)),
		"adds": (b.get("adds", []) as Array).duplicate(),
		"max_hp": hp,
		"die": scale_die(die, ds),
	}
	var die2: Array = b.get("die2", [])
	if die2.size() > 0:
		var hpk2: float = float(b.get("hpk2", b.get("hpk", 1.0)))
		out["max_hp2"] = int(round(hpk2 * bud * hp_mult))
		out["die2"] = scale_die(die2, ds)
	return out


func _hero(n: String, cls: String, tier: int, hp: int, die: Array) -> Dictionary:
	return {"n": n, "cls": cls, "tier": tier, "max_hp": hp, "die": die}

func _f(part: String, type: String, value: int, keywords: Array = [], rarity: int = 0) -> Dictionary:
	return {"part": part, "type": type, "value": value, "keywords": keywords.duplicate(), "rarity": rarity}

func _blank() -> Dictionary:
	return {"part": "blank", "type": "blank", "value": 0, "keywords": [], "rarity": 0}


# ---------------------------------------------------------------------------
# Encounter budget — src/data.js CURVE (rule spec §9). pw = "power level" (reward count
# received so far), NOT wave/step index — see rule spec §9 note on why this is
# path-independent and therefore safe for a future branching RunMap.
# ---------------------------------------------------------------------------

func budget(pw: int) -> float:
	var knee: int = TUNE["knee"]
	return TUNE["base"] * pow(TUNE["growth"], min(pw, knee)) * pow(TUNE["growth2"], max(0, pw - knee))

func count(pw: int) -> int:
	return max(2, min(6 if pw >= 14 else 5, 2 + int(floor(pw / 4.0))))


## src/data.js faceScale(t,s) — poison/debuff/buff scale sub-linearly with encounter
## strength `s` so status-effect stacks don't explode at high `pw`; dmg/shield/heal/mana
## scale linearly.
func face_scale(face_type: String, s: float) -> float:
	if face_type == "poison":
		return pow(s, 0.50)
	if face_type == "debuff" or face_type == "buff":
		return pow(s, 0.45)
	return s

## src/data.js scaleDie(die,s) — used by mkMonster/mkAlly to scale a base monster die to
## the current encounter budget.
func scale_die(die: Array, s: float) -> Array:
	var out: Array = []
	for f in die:
		var nf: Dictionary = (f as Dictionary).duplicate(true)
		var v: int = int(nf.get("value", 0))
		nf["value"] = max(1, int(round(v * face_scale(nf.get("type", ""), s)))) if v > 0 else 0
		out.append(nf)
	return out

## Full src/data.js ascMods(a) port (rule spec §9 ASCENSION table), verbatim. Previously only
## the in-combat encounter-generation fields (hp/dmg/boss_hp/weaken) were ported here, with
## `elite_extra`/`rewards`/`extra_elite` left out as "out of scope — no RunMap graph exists
## yet". That reasoning is now stale: the RunMap graph exists, and the reward-generation and
## elite-wave-composition workstreams both need these three fields, so they are ported here
## too (snake_case to match this file's existing key convention; the pre-existing keys are
## unchanged). `elite_extra` (JS `eliteExtra`): 1 from Ascension 2. `rewards` (JS `rewards`):
## starts at 3, drops to 2 from Ascension 7. `extra_elite` (JS `extraElite`): 2 from
## Ascension 9. None of the three are consumed by CombatEngine's encounter generator itself
## (that stays hp/dmg/boss_hp/weaken, unchanged) — they exist purely for the reward/RunMap
## callers this dictionary is also handed to.
func ascension_mods(a: int) -> Dictionary:
	var m := {
		"hp": 1.0, "dmg": 1.0, "boss_hp": 1.0, "weaken": false,
		"elite_extra": 0, "rewards": 3, "extra_elite": 0,
	}
	if a >= 1:
		m.hp *= 1.10
	if a >= 2:
		m.elite_extra = 1
	if a >= 3:
		m.dmg *= 1.10
	if a >= 4:
		m.boss_hp *= 1.15
	if a >= 5:
		m.weaken = true
	if a >= 6:
		m.hp *= 1.10
	if a >= 7:
		m.rewards = 2
	if a >= 8:
		m.dmg *= 1.15
	if a >= 9:
		m.extra_elite = 2
	if a >= 10:
		m.hp *= 1.20
		m.dmg *= 1.20
	return m


func avg_face_value(die: Array) -> float:
	var total := 0.0
	var n := 0
	for f in die:
		var v: int = int(f.get("value", 0))
		if v > 0:
			total += v
			n += 1
	return (total / n) if n > 0 else 1.0


## Event keys that can actually be OFFERED right now, and the options of each that are
## actually PLAYABLE.
##
## `casino` and `mutant` carry options whose src/engine.js effect needs the FACE_POOL /
## Gene-Mutation table, which is not ported (see _load_events()). Those options are tagged
## `needs_face_pool`. Serving them anyway would be the worst of the three available options:
## the player reads "40%: a Mythic face", picks it, and NOTHING happens — silently, with no
## error, indistinguishable from a bug. Filtering them out is honest; an event left with
## fewer than two playable options is not a choice at all, so it is dropped entirely rather
## than presented as a decision with one button.
##
## Delete this filter — do not work around it — once FACE_POOL lands and the `fx` handlers
## in RunState.apply_event_fx() cover bet_big/dip/drink.
func playable_event_options(event_key: String) -> Array:
	var out: Array = []
	for opt in ((events.get(event_key, {}) as Dictionary).get("opts", []) as Array):
		if not bool((opt as Dictionary).get("needs_face_pool", false)):
			out.append(opt)
	return out


func playable_event_keys() -> Array:
	var out: Array = []
	for key in events.keys():
		if playable_event_options(String(key)).size() >= 2:
			out.append(String(key))
	out.sort()   # deterministic: Dictionary key order must never leak into a seeded run
	return out

# ===========================================================================
# META PROGRESSION — src/data.js UNLOCKS (:824) + BP track (:1001) + BP_XP (:999)
# ===========================================================================

## Shard-bought permanent unlocks, verbatim from src/data.js UNLOCKS. Order is the ladder the
## player climbs, so it is the display order too — never sorted by cost at the call site.
##
## Every entry's EFFECT is applied in RunState.start_new_run(); an unlock whose effect has no
## call site would be bought, listed as owned, and do nothing. `u_relic1`/`u_relic2`/`u_face1`/
## `u_face2` are the exception and are marked below: they widen reward pools this port has not
## built out yet, so they are sold but inert, and `t_meta_progression` asserts exactly which
## ids are allowed to be in that state rather than letting the set grow quietly.
const UNLOCKS := [
	# "20 waves" was wrong twice over: the full map is 30 ROWS and it branches (see
	# RunMapGenerator.MODE_CONFIG). Display copy only — the id `u_full` is what everything keys on.
	{"id": "u_full", "n": "FULL RUN (30 rows)", "cost": 120, "d": "Unlocks the 30-row mode with 4 bosses."},
	{"id": "u_relic1", "n": "Relic Pool II", "cost": 150, "d": "Adds Epic relics to the reward pool."},
	{"id": "u_face1", "n": "Gene Pool II", "cost": 180, "d": "Adds Legendary faces to the mutation pool."},
	{"id": "u_reroll", "n": "Survival Instinct", "cost": 220, "d": "Start every run with 1 extra maximum Reroll."},
	{"id": "u_relic2", "n": "Relic Pool III", "cost": 280, "d": "Adds Legendary relics to the reward pool."},
	{"id": "u_face2", "n": "Gene Pool III", "cost": 350, "d": "Adds Mythic faces to the mutation pool."},
	{"id": "u_start", "n": "Lunacia Legacy", "cost": 400, "d": "Start every run with a random Common relic."},
	{"id": "u_hp", "n": "Ancient Bloodline", "cost": 500, "d": "Your whole party permanently gains 3 Max HP."},
	{"id": "u_reroll2", "n": "Overdrive Reflexes", "cost": 650, "d": "Start every run with 1 more extra maximum Reroll (stacks with Survival Instinct)."},
	{"id": "u_hp2", "n": "Titan Bloodline", "cost": 600, "d": "Your whole party permanently gains 2 more Max HP (stacks with Ancient Bloodline)."},
]

## Ids above whose effect genuinely does not exist yet in this port. Kept as data so the test
## can pin the list: adding an unlock here is a deliberate act, not an oversight.
const UNLOCKS_WITHOUT_EFFECT := ["u_relic1", "u_relic2", "u_face1", "u_face2"]

## src/data.js DAILY_MISSION_SHARD (:867). One grant per UTC calendar day, at run end.
const DAILY_MISSION_SHARD := 60

# ===========================================================================
# Archetypes + sample teams (src/data.js ARCH :64, GUIDES :1040)
# ===========================================================================

## src/data.js ARCH — copied verbatim, INCLUDING the archetypes nothing reads yet. A lookup
## table ported halfway is the kind of thing where two entries exist, ten are missing, and the
## first caller to ask for a missing one gets a default instead of an error. `t_guides` pins the
## key set, so a partial copy fails loudly rather than degrading.
##
## The `thorns` icon was changed from ✷ to ✜ on 2026-09-04 (relic-system.md §11): before that
## `aoe` and `thorns` shared ✷, so the UI could not tell two different archetypes apart.
const ARCH := {
	"poison": {"n": "PLAGUE", "ic": "☠", "c": "#8fdc4a",
		"d": "Stack Poison until it kills. Poison is the win condition."},
	"burn": {"n": "INFERNO", "ic": "♨", "c": "#ff9a4d",
		"d": "Burn spreads, doubles, and crits."},
	"shield": {"n": "BULWARK", "ic": "⛨", "c": "#5fb8ff",
		"d": "Endless Shield, then turn that Shield into damage."},
	"mana": {"n": "CONDUIT", "ic": "↯", "c": "#c78cff",
		"d": "Spam active cards. Never run out of Mana."},
	"pierce": {"n": "TALON", "ic": "➤", "c": "#e26fa8",
		"d": "Ignore every Shield and finish off weakened targets."},
	"crit": {"n": "APEX", "ic": "✦", "c": "#ffd76a",
		"d": "High crit chance. Every hit is a big number."},
	"growth": {"n": "EVOLVE", "ic": "⇗", "c": "#66e08a",
		"d": "Your die faces grow without limit during a fight."},
	"summon": {"n": "SWARM", "ic": "✥", "c": "#b0a8d0",
		"d": "Summon Axie Eggs and win on numbers."},
	"aoe": {"n": "TEMPEST", "ic": "✷", "c": "#7ac8ff",
		"d": "Every attack hits the whole board."},
	"thorns": {"n": "AEGIS", "ic": "✜", "c": "#a86fd8",
		"d": "Let the enemy kill itself on your armour."},
}

## src/data.js GUIDES — the four sample teams, copied verbatim.
##
## WHY THE TEXT IS COPIED AND NOT REWRITTEN. Every line of `how` names real relics and real
## passives and makes a claim about how this game plays. Rewording it from memory is how a guide
## ends up recommending a relic that is not in the port, or describing a passive that works
## differently here. `t_guides` checks the hero keys and the archetype keys actually resolve; the
## prose is the live game's own, unedited.
const GUIDES := [
	{
		"id": "wall", "n": "LIVING WALL", "arch": "shield", "diff": "EASY · best starting team",
		"team": ["plant1", "plant1", "reptile1", "bug1", "aqua1"],
		"why": "Two Plants stack Shield on top of each other (their BULWARK passive adds 2 to"
			+ " every Shield), Reptile punishes attackers with Thorns, and Bug weakens the enemy."
			+ " You almost never die out of nowhere, so mistakes are forgiving.",
		"how": [
			"Take Back (Shield) faces over damage faces for the first four waves.",
			"Hunt for: Bastion Plate · Mirror Shell · Sharp Spines · Soul Forge.",
			"Win condition: Bastion Plate turns your Shield into damage, so you are both"
				+ " unkillable and dealing damage at once.",
			"Weakness: you kill slowly. Watch out for bosses that heal, like Warden and Plague"
				+ " Mother.",
		],
	},
	{
		"id": "plague", "n": "PESTILENCE", "arch": "poison", "diff": "MEDIUM",
		"team": ["bug1", "bug1", "reptile1", "plant1", "aqua1"],
		"why": "The Bug passive VIRULENT adds 2 Poison stacks instead of 1 when the target"
			+ " already has Poison, so your stacks grow exponentially. Reptile adds even more"
			+ " Poison through Thorns.",
		"how": [
			"Always put Poison on the SAME target so the passive keeps triggering.",
			"Hunt for: Venom Engine (Poison ticks twice) · Plague Lord (never decays, spreads) ·"
				+ " Open Wound.",
			"Win condition: one target sitting on 40+ Poison stacks is dead, boss included.",
			"Weakness: weak in waves 1-3 before the stacks build. Take event nodes to get through"
				+ " the early game.",
		],
	},
	{
		"id": "apex", "n": "APEX FANG", "arch": "crit", "diff": "MEDIUM · fastest kills",
		"team": ["beast1", "beast1", "bird1", "plant1", "aqua1"],
		"why": "The Beast passive FERAL deals 60% more damage to targets below 50% HP, and Bird"
			+ " ignores Shield. You kill enemies before they get to act, which is the best"
			+ " defence in the game.",
		"how": [
			"Focus one enemy below 50% HP first, then finish it. Do not spread your damage"
				+ " around.",
			"Hunt for: Apex Predator (triple crits) · Lucky Scale · Death Mark · Blood Pact.",
			"Win condition: crit plus execute means a single die face can delete a boss.",
			"Weakness: low HP. One unlucky turn costs you an Axie.",
		],
	},
	{
		"id": "conduit", "n": "THE CURRENT", "arch": "mana", "diff": "HARD · highest ceiling",
		"team": ["aqua1", "aqua1", "plant1", "bird1", "bug1"],
		"why": "The Aqua passive CONDUIT adds 1 to every Mana gain and grants a Reroll for every"
			+ " 4 Mana you spend. More rerolls means you almost always find the face you need.",
		"how": [
			"Spend Mana constantly. Hoarded Mana is wasted Mana, unless you have Mana Flood.",
			"Hunt for active cards: Gene Nova · Lunacia Ultima · Spore Bloom, and Mana Flood.",
			"Win condition: two or three active cards per turn plus rerolls until you hit the"
				+ " perfect face.",
			"Weakness: needs time to set up, and depends on finding active cards.",
		],
	},
]

## src/data.js BP_XP — the XP needed to go from level n-1 to level n.
static func bp_xp_for_level(n: int) -> int:
	return 45 + 22 * (n - 1)


const BP_MAX_LEVEL := 30

## src/data.js BP — 30 milestones. `type` is one of:
##   shard  — value is a shard amount
##   unlock — value is an UNLOCKS id, granted free
##   perk   — value is a perk key (reroll/relic0/relic1/hp4/rrw), stacking in MetaState.perks
##   face   — value is a BP_FACES key. NOT CLAIMABLE in this port: FACE_POOL is unported, so
##            there is no face to grant. `MetaState.claim_bp_reward()` refuses these rather
##            than marking them claimed and granting nothing — the same mistake the event
##            system already made once (an option offered, chosen, and silently inert).
const BP_TRACK := [
	{"lv": 1, "type": "shard", "value": 120},
	{"lv": 2, "type": "shard", "value": 200},
	{"lv": 3, "type": "unlock", "value": "u_relic1"},
	{"lv": 4, "type": "shard", "value": 250},
	{"lv": 5, "type": "face", "value": "bp_plague", "big": true},
	{"lv": 6, "type": "shard", "value": 250},
	{"lv": 7, "type": "perk", "value": "reroll", "note": "Start with 1 extra Reroll"},
	{"lv": 8, "type": "shard", "value": 300},
	{"lv": 9, "type": "unlock", "value": "u_face1"},
	{"lv": 10, "type": "perk", "value": "relic0", "note": "Start every run with a Common relic", "big": true},
	{"lv": 11, "type": "shard", "value": 350},
	{"lv": 12, "type": "face", "value": "bp_apex", "big": true},
	{"lv": 13, "type": "shard", "value": 350},
	{"lv": 14, "type": "unlock", "value": "u_relic2"},
	{"lv": 15, "type": "perk", "value": "hp4", "note": "Whole party gains 4 Max HP", "big": true},
	{"lv": 16, "type": "shard", "value": 400},
	{"lv": 17, "type": "unlock", "value": "u_face2"},
	{"lv": 18, "type": "shard", "value": 400},
	{"lv": 19, "type": "face", "value": "bp_bulwark", "big": true},
	{"lv": 20, "type": "unlock", "value": "u_full", "big": true},
	{"lv": 21, "type": "shard", "value": 450},
	{"lv": 22, "type": "perk", "value": "reroll", "note": "Start with 1 more Reroll (2 total)"},
	{"lv": 23, "type": "shard", "value": 500},
	{"lv": 24, "type": "perk", "value": "hp4", "note": "4 more Max HP (8 total)"},
	{"lv": 25, "type": "perk", "value": "relic1", "note": "Starting relic upgraded to Rare", "big": true},
	{"lv": 26, "type": "face", "value": "bp_conduit", "big": true},
	{"lv": 27, "type": "shard", "value": 600},
	# "per wave" — fifth copy of the JS build's linear-run wording, found by t_mainmenu_ui's
	# gate rather than by reading. A reward offer happens per NODE here; there are no waves.
	{"lv": 28, "type": "perk", "value": "rrw", "note": "Reroll rewards twice per node"},
	{"lv": 29, "type": "shard", "value": 700},
	{"lv": 30, "type": "face", "value": "bp_swarm", "big": true, "title": "LUNACIA SOVEREIGN"},
]
