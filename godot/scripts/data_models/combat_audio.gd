class_name CombatAudio
extends RefCounted
## Which sound plays for a combat event.
##
## WHERE THE AUDIO COMES FROM
## --------------------------
## `godot/assets/audio/` holds the Axie Origins Kit's own sound set, curated and resampled to
## 24 kHz mono (see the state file for why: no ffmpeg on this machine, so the downsample is
## done in `tools/`-style Python; Godot then compresses to QOA on import).
##
##   sfx/class/<class>_<action>_<phase>.wav   78 files — 6 classes x 13 combat sounds
##   sfx/status/<name>.wav                    38 files — status effects and one-shots
##   music/<track>.wav                         5 tracks, all set to loop forward
##
## WHY A MAPPING LAYER
## -------------------
## The kit's sounds are named by ANIMATION (bite / slash / smash / gore / cast / projectile /
## throw), because that is what drives them in the game they were built for. This game's dice
## faces are named by EFFECT (`dmg` / `shield` / `heal` / `poison` / `mana` / `buff` / `debuff`
## / `summon`) and by BODY PART (`mouth` / `horn` / `back` / `tail` / `eyes` / `ears`). Nothing
## connects the two automatically.
##
## The body part is the better signal, and it is the one the player is already looking at: a
## `mouth` face should bite, a `horn` face should gore, a `tail` face should slash. Falling
## back to the face TYPE only when the part gives nothing useful keeps every face audible
## without inventing a sound for it.
##
## Class prefixes the kit uses that this game has no equivalent for (`mech`, `dawn`, `dusk`)
## were not installed at all, rather than shipped as 39 files nothing can ever play.

const SFX_CLASS_DIR := "res://assets/audio/sfx/class/"
const SFX_STATUS_DIR := "res://assets/audio/sfx/status/"
const MUSIC_DIR := "res://assets/audio/music/"

## The kit names the water class "aquatic"; this game calls it "aqua". Renaming once here
## keeps every call site speaking the game's vocabulary.
const CLASS_TO_KIT := {
	"plant": "plant", "beast": "beast", "aqua": "aquatic",
	"reptile": "reptile", "bug": "bug", "bird": "bird",
}

## Body part -> the kit's action name. This is the primary lookup: it is what makes a horn
## face sound different from a mouth face on the same Axie.
const PART_TO_ACTION := {
	"mouth": "bite",       # bite_attack
	"horn": "gore",        # gore_attack — a horn gores
	"tail": "slash",       # slash_attack
	"back": "smash",       # smash_attack — the shield/back faces land heavy
	"eyes": "cast",        # cast_attack/cast_hit — eyes carry the debuff/utility faces
	"ears": "cast",        # ears are the mana/cantrip faces; the cast set is the softest
}

## Fallback when the part is unknown or absent (enemy faces all use part "m").
const TYPE_TO_ACTION := {
	"dmg": "slash",
	"shield": "smash",
	"heal": "cast",
	"poison": "projectile",
	"mana": "cast",
	"buff": "cast",
	"debuff": "cast",
	"summon": "throw",
}

## Effects that are about what HAPPENED rather than who did it, so they are class-agnostic.
## Keys are this game's own status/effect names; values are files in sfx/status/.
## `vunerable` is the kit's own spelling — kept as-is so the filename and the constant agree;
## the game's status key is `vulnerable`.
const STATUS_SFX := {
	"poison": "poison",
	"burn": "hex",
	"regen": "cure",
	"thorns": "reflect_damage",
	"blind": "doubt",
	"weaken": "weak",
	"vulnerable": "vunerable",
	"stun": "stunned",
	"freeze": "sleep",
	"undying": "power_awaken",
	"shield": "shield",
	"heal": "heal",
	"buff": "buff",
	"debuff": "debuff",
	"summon": "summon_on",
	"death": "death_mark",
	"crit": "power_gain",
	"drain": "drain",
}

## Where a creature's sprite says nothing useful about its family. The plain green blob the
## kit ships as `slime` lands here, and so would any sprite added later without a family
## prefix — `plant` is the softest, least characterful of the six sets, which is the right
## thing for "we do not know what this is".
const MONSTER_VOICE_DEFAULT := "plant"


## Music by situation. `pve_1/2/3` are interchangeable battle themes — varying them per node
## keeps a 18-row run from sounding like one long fight.
const MUSIC := {
	"menu": "home",
	"battle_a": "pve_1",
	"battle_b": "pve_2",
	"battle_c": "pve_3",
	"boss": "boss",
}


## The attack sound for a unit using a face. `phase` is "attack" (the swing), "fly" (a
## projectile in transit) or "hit" (the landing). Not every action has every phase — the kit
## only recorded fly/hit for the ranged ones — so this returns "" rather than a broken path
## when the combination does not exist, and callers simply play nothing.
##
## `allow_fallback` controls what happens when the requested phase was never recorded. The
## default (true) substitutes the swing, which is what a caller asking for "attack" wants:
## every face makes a noise. A caller asking for "hit" must pass false — otherwise a melee
## face, which has no `_hit` recording, would play its swing a second time on landing and
## every melee blow in the game would sound doubled.
static func face_sfx_path(unit_class: String, face_part: String, face_type: String,
		phase: String = "attack", allow_fallback: bool = true) -> String:
	var kit_class := String(CLASS_TO_KIT.get(unit_class, ""))
	if kit_class == "":
		return ""
	var action := String(PART_TO_ACTION.get(face_part, ""))
	if action == "":
		action = String(TYPE_TO_ACTION.get(face_type, "slash"))
	var path := "%s%s_%s_%s.wav" % [SFX_CLASS_DIR, kit_class, action, phase]
	if ResourceLoader.exists(path):
		return path
	if not allow_fallback:
		return ""
	# Melee actions have no fly/hit recording; fall back to the swing so the face is not silent.
	var fallback := "%s%s_%s_attack.wav" % [SFX_CLASS_DIR, kit_class, action]
	return fallback if ResourceLoader.exists(fallback) else ""


## The kit class whose voice a monster or boss speaks with.
##
## WHY THIS EXISTS AT ALL
## ---------------------
## `face_sfx_path()` keys every combat sound off the unit's class, but only HEROES have one:
## `ContentDB._load_enemies()` never sets `cls`, and `Unit.cls` defaults to "" for exactly
## that reason. Passing that "" straight through returns "" from the lookup above, so without
## this function every monster and every boss in the game is silent — half of all the blows
## in a fight, making no sound at all. Nothing crashes and nothing warns; it just goes quiet,
## which is the failure mode this port has been bitten by before.
##
## HOW THE CLASS IS CHOSEN
## -----------------------
## From the Chimera sprite the creature is already WEARING (`MonsterArt`), not from a
## hand-written monster->class table. Two reasons. The player hears what they are looking at:
## a thing made of leaves sounds like the plant set, a wolf sounds like the beast set. And it
## cannot drift — re-assigning a monster's sprite re-assigns its voice in the same edit,
## whereas a parallel table would quietly keep the old sound. This is the same principle
## `monster_art.gd` states for picking the sprites themselves: go by what the creature
## visibly is, never by its name.
##
## The kit's own naming carries the family, so the sprite name is enough: `aqua-*` are the
## water creatures, `dryad-`/`treant`/`forest-`/`flowering-` are the wooden and leafy ones,
## and the wolves and bears are the beasts. Order matters below — `aqua-alpha-wolf` is a
## water creature first and a wolf second.
static func monster_voice_class(key: String, is_boss: bool = false) -> String:
	var sprite := MonsterArt.sprite_name_for(key, is_boss)
	if sprite == "":
		return MONSTER_VOICE_DEFAULT
	if sprite.begins_with("aqua"):
		return "aqua"
	for woody in ["dryad", "treant", "forest", "flowering"]:
		if sprite.contains(woody):
			return "plant"
	if sprite.contains("wolf") or sprite.contains("bear"):
		return "beast"
	return MONSTER_VOICE_DEFAULT


## The voice for a unit, whichever side it is on: its own class when it has one (heroes), the
## sprite-derived voice when it does not (monsters and bosses). `key` is `Unit.key`.
static func voice_class(unit_class: String, key: String, is_boss: bool = false) -> String:
	if CLASS_TO_KIT.has(unit_class):
		return unit_class
	return monster_voice_class(key, is_boss)


static func status_sfx_path(status_or_effect: String) -> String:
	var file := String(STATUS_SFX.get(status_or_effect, ""))
	if file == "":
		return ""
	var path := SFX_STATUS_DIR + file + ".wav"
	return path if ResourceLoader.exists(path) else ""


static func music_path(situation: String) -> String:
	var track := String(MUSIC.get(situation, ""))
	if track == "":
		return ""
	var path := MUSIC_DIR + track + ".wav"
	return path if ResourceLoader.exists(path) else ""


## A battle theme chosen deterministically from the node id, so the same node in a replayed
## seed sounds the same — this game's whole RNG port exists to keep runs reproducible, and
## music picked with randi() would break that property for no benefit.
static func battle_music_path(node_id: String, is_boss: bool) -> String:
	if is_boss:
		return music_path("boss")
	var keys := ["battle_a", "battle_b", "battle_c"]
	return music_path(keys[abs(node_id.hash()) % keys.size()])
