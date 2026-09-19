class_name MonsterArt
extends RefCounted
## Which Chimera sprite stands in for each monster and boss on the battlefield.
##
## WHERE THE ART COMES FROM
## ------------------------
## `godot/assets/monsters/*.png` are the 20 Axie Origins Kit Chimeras, converted from their
## Spine 3.8 skeletons by `tools/spine_to_sprites.py` (setup pose, flattened to one PNG each,
## trimmed and capped at 512px). No Spine runtime is involved — see that tool's header for why
## that is both possible and deliberate.
##
## WHY A MAPPING EXISTS AT ALL
## ---------------------------
## The game's monster roster is ported from `src/data.js` MON{} and its names are its own
## (Gooey Slime, Ravenling, Hexeye...). The Origins Kit's creatures are a different set with
## different names. Nothing links them automatically, so the pairing is an authored decision.
##
## Each pairing below was made by LOOKING at the converted sprite and matching it to the
## monster's ROLE and STAT WEIGHT — not by name similarity, which would have produced nonsense
## (there is no "Ravenling" chimera, and the kit's "slime" is not the only slime). The role is
## what the player actually reads off the board: an assassin should look fast and light, a tank
## should look heavy, a healer should read as support.
##
## Reuse is intentional where it happens: 20 sprites cover 17 normal monsters, 4 elites and
## 6 bosses. Elites deliberately reuse the heaviest-looking creatures, since an elite IS a
## bigger version of a threat, and the elite tint/scale is applied on top.

## Monster key (ContentDB.enemies) -> sprite basename in res://assets/monsters/.
const MONSTER_SPRITES := {
	# --- bruisers: straightforward damage, so they read as bulk and weight ---
	"slime": "slime",                       # the literal match: the kit's own green blob
	"chomper": "treant",                    # a stump that is mostly open mouth
	"bruiser": "daddy-bear",                # heaviest humanoid in the kit, carries an axe
	"cleaver": "alpha-wolf",                # maned quadruped, reads as a heavy hitter

	# --- assassins: light, fast silhouettes ---
	"ravenling": "aqua-wolf",               # small and quick; the lowest-HP predator
	"stalker": "gray-wolf",                 # lean and horned, a step up in menace

	# --- tanks: wide, rooted, armoured ---
	"spikelet": "forest-slime-fighter",     # round and covered in spikes — thorns made visible
	"thornback": "dryad-fighter",           # tall woody body, the bigger thorns carrier

	# --- healers: support-shaped, soft ---
	"jellyfin": "aqua-slime-sup",           # the kit's own support slime
	"warden": "aqua-slime-def",             # big shelled defensive slime for the 26 HP healer

	# --- poisoners ---
	"bugling": "aqua-slime-atk",            # small and aggressive, the cheapest poisoner
	"venomaw": "forest-slime-flower",       # bloom on top reads as something that spreads

	# --- mages: casters, visibly ranged ---
	"hexeye": "dryad-mage",                 # floating rings say "caster" at a glance
	"pyrewing": "dryad-ranger",             # the kit's ranged attacker

	# --- one-of-a-kind roles ---
	"broodmaw": "flowering-treant",         # summoner: a thing that sprouts more things
	"bomblet": "aqua-alpha-wolf",           # kamikaze: small, odd, clearly fragile
	"totem": "treant-fighter",              # buffer: a totem-shaped stump, fits the name

	# --- elites: the heaviest silhouettes, reused on purpose (see class comment) ---
	"e_ravager": "werewolf",
	"e_plague": "mommy-bear",
	"e_bulwark": "treant-fighter",
	"e_archon": "dryad-mage",
}

## Boss key (ContentDB.bosses) -> sprite basename.
##
## NOTE ON BOSS ART: the user has said the JS build's boss images were makeshift and that
## better Chimera art may be supplied later. These are real Chimeras, not placeholders, but
## they are the pairing most open to being revisited.
## UPDATED 2026-09-19 on the owner's decision. Four of these six used to be a monster's sprite
## at 2.15x scale, which is the weakest thing a boss can be: the fight the run builds toward
## looked like the thing you already killed twice, only bigger. The kit ships no more Chimeras
## — the owner said so and offered two ways out instead: Starter Axie 3D models that do not
## collide with the player's own heroes, and any suitable Chimera art already on hand.
##
## Both were used. `shilin` was ALREADY IN THE KIT and had never been converted, because it
## ships as Spine JSON while the other 21 ship as binary `.skel` and `tools/spine_to_sprites.py`
## only read the binary. It reported that creature as "missing .skel/.atlas/.png", which reads
## as a broken asset rather than as an unread format. The tool now reads both, and the red
## slime it was hiding is a boss-grade silhouette.
##
## The other four are 3D models, mapped in CombatStage3D.BOSS_MODELS — kept as sprite entries
## here too so that a boss still has art if a model ever fails to load. The banned names are
## still banned: `pomodoro` and `machito` are the display names of the Bug- and Beast-class
## HEROES in the player's own party, and fielding either as a boss means fighting your own
## character. `t_assets` checks identity, not filename, so this cannot come back quietly.
const BOSS_SPRITES := {
	"gooey_king": "aqua-slime-boss",        # the kit's own boss slime — an exact fit
	"mecha": "shilin",                      # RETALIATE: a steel helm and a blue mechanical claw,
	                                         # grafted onto a red blob. Exclusive to this boss.
	# --- the four below are 3D models first (CombatStage3D.BOSS_MODELS); these are fallbacks ---
	"agony": "werewolf",                    # model: paladill — red, horned war-helm, fanged
	"frost_lord": "gray-wolf",              # model: kotaro — white, icy, yellow glare, sword
	"plague_mother": "mommy-bear",          # model: kibo — spore-pods hanging off its cap, BROOD
	"mirror": "dryad-fighter",              # model: xia — armoured, spiked, sullen and still
}

const SPRITE_DIR := "res://assets/monsters/"


## Texture for a unit, or null when there is no pairing. Bosses are looked up first: a boss
## key and a monster key could collide in principle, and the boss art must win.
static func texture_for(key: String, is_boss: bool = false) -> Texture2D:
	var name := sprite_name_for(key, is_boss)
	if name == "":
		return null
	var path := SPRITE_DIR + name + ".png"
	if not ResourceLoader.exists(path):
		push_warning("MonsterArt: '%s' maps to '%s' but %s is missing" % [key, name, path])
		return null
	return load(path) as Texture2D


static func sprite_name_for(key: String, is_boss: bool = false) -> String:
	if is_boss and BOSS_SPRITES.has(key):
		return String(BOSS_SPRITES[key])
	if MONSTER_SPRITES.has(key):
		return String(MONSTER_SPRITES[key])
	if BOSS_SPRITES.has(key):
		return String(BOSS_SPRITES[key])
	return ""
