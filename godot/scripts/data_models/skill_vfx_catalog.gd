class_name SkillVfxCatalog
extends RefCounted
## Which Origins VFX clip plays for a die face, and what the clip's own metadata says about it.
##
## WHERE THE ART COMES FROM
## ------------------------
## `godot/assets/vfx/<kit_class>_<action>.png` — 42 additive sprite sheets lifted from the Axie
## Origins Asset Kit's web plate (`web-vfx/public/vfx/<id>/atlas.png`), 6 classes x 7 actions.
## `godot/assets/data/skill_vfx.json` is each clip's own `clip.json` trimmed to the fields the
## player needs. Both are Sky Mavis IP under the kit's Vibeathon licence — see the kit's
## LICENSE.md before shipping outside an approved programme.
##
## WHY THIS SHARES CombatAudio'S MAPPINGS RATHER THAN REPEATING THEM
## -----------------------------------------------------------------
## The kit names a VFX folder and a sound file by the SAME two things: its class prefix and
## its action (`plant_slash` the atlas, `plant_slash_attack.wav` the sound). CombatAudio
## already owns the two tables that get from this game's vocabulary to that one -
## CLASS_TO_KIT (aqua -> aquatic) and PART_TO_ACTION (horn -> gore) - so this file reads them
## instead of declaring its own. A horn face therefore CANNOT gore in the speakers and slash
## on screen: there is one table, and both media read it.
##
## WHAT "RANGED" MEANS HERE
## -----------------------
## Not a judgement call - `is_ranged` is the clip's own `isRanged` flag, captured from the
## Origins prefab. It comes out as exactly cast / projectile / throw, and CombatStage3D uses
## it to decide whether the attacker lunges (melee) or plants and fires (ranged). Reading it
## off the data means a future clip swap moves the behaviour with the art.

const CATALOG_PATH := "res://assets/data/skill_vfx.json"
const ATLAS_DIR := "res://assets/vfx/"

static var _catalog: Dictionary = {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true   # set FIRST: a missing/!broken file must not re-parse on every face used
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		push_warning("SkillVfxCatalog: %s missing — skill VFX disabled" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SkillVfxCatalog: %s is not a JSON object — skill VFX disabled" % CATALOG_PATH)
		return
	var clips: Variant = (parsed as Dictionary).get("clips", {})
	if typeof(clips) == TYPE_DICTIONARY:
		_catalog = clips as Dictionary


## `<kit_class>_<action>`, or "" when this unit/face has no clip. Mirrors
## CombatAudio.face_sfx_path()'s own lookup order exactly: the body part first because that is
## what the player is looking at, the face type only as the fallback for units whose part says
## nothing (every enemy face uses part "m").
static func clip_key(voice_class: String, face_part: String, face_type: String) -> String:
	_load()
	var kit_class := String(CombatAudio.CLASS_TO_KIT.get(voice_class, ""))
	if kit_class == "":
		return ""
	var action := String(CombatAudio.PART_TO_ACTION.get(face_part, ""))
	if action == "":
		action = String(CombatAudio.TYPE_TO_ACTION.get(face_type, ""))
	if action == "":
		return ""
	var key := "%s_%s" % [kit_class, action]
	return key if _catalog.has(key) else ""


## The clip's trimmed metadata, or {} when unknown. Keys: cols/rows/frame_w/frame_h/frames/
## fps/peak_frame/is_ranged/projectile_travel/anchor[2]/attacker[2].
static func clip(key: String) -> Dictionary:
	_load()
	var d: Variant = _catalog.get(key, {})
	return d as Dictionary if typeof(d) == TYPE_DICTIONARY else {}


## True when the Origins capture marked this clip ranged (cast / projectile / throw). An
## unknown key answers false, which is the safe default: a unit with no clip keeps the melee
## lunge it had before this system existed, rather than silently standing still.
static func is_ranged(key: String) -> bool:
	return bool(clip(key).get("is_ranged", false))


static func atlas_path(key: String) -> String:
	return ATLAS_DIR + key + ".png"
