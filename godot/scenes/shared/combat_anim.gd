class_name CombatAnim
extends RefCounted
## Which body clip a party Axie plays in combat, and the extra clips it can play (view only).
##
## Before this, an Axie had ~8 base clips and every damage face was WalkAttack. The Axie Mixer
## weapon package ships more body motions; the ones that read right WITHOUT a held weapon (there are
## no weapon meshes in the pack) are baked per body by `tools/bake_combat_clips.tscn` into
## `assets/axie/combat_clips/<Body>/<Clip>.res` and registered on each Axie's AxiePlayable at spawn.
## The weapon GLBs themselves are 20 MB each and excluded from every export, so the game never
## loads them at runtime.
##
## Nothing here touches the run: choices come from the face that was already played (type, part,
## Set/Overcast) plus a hash of uid/turn/count. Never the run RNG, never randf().

## Baked extra clips, by the name they are registered under. Rejected clips and why are listed in
## production/qa/ui05-b1/anim/INDEX.md (weapon-pose clips such as FluteSkill/TomeSkill hold an
## invisible prop; PourWater barely moves without its can).
const EXTRA_CLIPS: Array[String] = [
	"AttackHead", "AttackRange", "AttackCombo", "HitTree", "CutTree", "StoneHarvest",
	"LootItem", "Shoveling", "MalaSkill", "TalismanSkill", "StaffSkill", "FlagAttack",
]
const CLIP_DIR := "res://assets/axie/combat_clips"

## Base clips every body GLB ships (AnimNames).
const BASE_CLIPS: Array[String] = [
	"Idle", "WalkAttack", "RunAttack", "IdleCarryItem", "IdleGetHit", "Dead", "Run", "Walk", "Stun",
]

## A play spec: clip, time_scale, normalized start (skips a wind-up so the blow lands near the
## damage number, which appears CombatView.impact_delay() = 0.18 s after the action starts).
static func _s(clip: String, ts := 1.0, start := 0.0) -> Dictionary:
	return {"clip": clip, "time_scale": ts, "start": start}

## Damage faces by the die's body part. First entry is the part's signature move (2 of 3 uses);
## the second keeps a long fight from repeating one pose.
static var DMG_BY_PART := {
	"mouth": [_s("WalkAttack"), _s("AttackHead", 1.1)],
	"horn": [_s("AttackHead"), _s("StoneHarvest", 1.3, 0.25)],
	"back": [_s("AttackRange"), _s("CutTree", 1.3, 0.3)],
	"tail": [_s("CutTree", 1.3, 0.3), _s("AttackRange", 1.1)],
	"ears": [_s("StoneHarvest", 1.3, 0.25), _s("RunAttack")],
	"eyes": [_s("StoneHarvest", 1.3, 0.25), _s("AttackRange", 1.1)],
}
## Part names as the dice data spells them, folded onto the keys above.
const PART_ALIAS := {"ear": "ears", "eye": "eyes", "horns": "horn", "mouths": "mouth", "tails": "tail", "backs": "back"}

## Non-damage faces: each its own motion, none of them an attack.
static var SELF_BY_TYPE := {
	"shield": _s("IdleCarryItem", 1.05),
	"buff": _s("MalaSkill", 1.3, 0.1),
	"heal": _s("LootItem", 1.15),
	"mana": _s("TalismanSkill", 1.6, 0.35),
	"summon": _s("Shoveling", 1.2),
	"poison": _s("RunAttack", 0.7),
	"debuff": _s("AttackRange", 0.85),
}
static var BIG_SET := _s("AttackCombo", 1.35, 0.1)    ## damage die inside a Set
static var BIG_OVERCAST := _s("HitTree", 1.15)        ## damage die of an Overcast Set: jump and slam
static var DEFAULT_SPEC := _s("WalkAttack")
static var VICTORY := _s("FlagAttack", 1.5, 0.15)     ## arms out and spin before running for the gate
static var FIDGET := _s("StaffSkill", 1.0)             ## a turn-start "hmm" by one Axie
const STUN := "Stun"
const HIT := "IdleGetHit"
const VICTORY_CHEER_SEC := 0.55   ## how long the cheer holds the slot before the run starts


static func norm_part(part: String) -> String:
	var p := part.strip_edges().to_lower()
	return String(PART_ALIAS.get(p, p))


## Deterministic, view-only spread. Same inputs, same pick; different uid/turn/count, different pick.
static func hash3(a: int, b: int, c: int) -> int:
	var h := hash([a, b, c])
	return absi(h)


## The clip for one face use. `big` = the die is in a Set; `overcast` = its Set was Overcast;
## `seed` = hash3(uid, turn, n). Reduce motion swaps the whole-body jump/spin for the headbutt.
static func pick_action(face_type: String, part: String, big: bool, overcast: bool, seed: int,
		reduced := false) -> Dictionary:
	if face_type == "dmg":
		if overcast or big:
			if reduced:
				return _s("AttackHead")
			return BIG_OVERCAST if overcast else BIG_SET
		var pool: Array = DMG_BY_PART.get(norm_part(part), [])
		if pool.is_empty():
			return DEFAULT_SPEC
		return pool[0] if (seed % 3) != 0 or pool.size() < 2 else pool[1]
	if SELF_BY_TYPE.has(face_type):
		return SELF_BY_TYPE[face_type]
	return DEFAULT_SPEC


## Hit reaction: one clip, played heavier on a big hit and with a small per-hit speed spread.
static func pick_hit(heavy: bool, seed: int) -> Dictionary:
	if heavy:
		return _s(HIT, 0.75)
	return _s(HIT, 0.9 + float(seed % 5) * 0.05)


## Idle desync: each Axie breathes at its own phase and pace instead of all five in lockstep.
static func idle_params(uid: int) -> Dictionary:
	var h := hash3(uid, 7, 11)
	return {"start": float(h % 100) / 100.0, "time_scale": 0.92 + float(h % 17) * 0.01}


## Every clip name a spec in this file can return (tests resolve each one on every body).
static func all_clips() -> Array[String]:
	var out: Array[String] = []
	var specs: Array = [BIG_SET, BIG_OVERCAST, DEFAULT_SPEC, VICTORY, FIDGET, _s(STUN), _s(HIT)]
	specs.append_array(SELF_BY_TYPE.values())
	for pool in DMG_BY_PART.values():
		specs.append_array(pool)
	for s in specs:
		var c := String((s as Dictionary)["clip"])
		if not out.has(c):
			out.append(c)
	return out


static func clip_path(body: int, clip: String) -> String:
	return "%s/%s/%s.res" % [CLIP_DIR, AxieTypes.body_name(body), clip]


## Registers the baked extra clips on one Axie, plus baked stand-ins for base clips its body GLB
## does not ship. Returns how many were registered. A missing file
## is skipped (the face then falls back to its base clip in CombatStage3D.play_action()).
static func register_extras(character: AxieCharacter3D) -> int:
	if character == null or character.playable == null or character.descriptor == null:
		return 0
	var n := 0
	var names: Array[String] = EXTRA_CLIPS.duplicate()
	names.append_array(BASE_CLIPS)   # only bodies whose GLB lacks one have a baked copy (Bigyak)
	for clip in names:
		var path := clip_path(character.descriptor.body, clip)
		if not ResourceLoader.exists(path):
			continue
		var anim := load(path) as Animation
		if anim != null:
			character.playable.register(clip, anim)
			n += 1
	return n


## Plays `spec` on `playable` with its own time_scale/start. Returns the track (null when the clip
## does not resolve on this body: the caller can fall back).
static func play_spec(playable: AxiePlayable, spec: Dictionary, loop := false,
		on_complete := Callable()) -> AnimTrack:
	if playable == null or not playable.is_registered(String(spec["clip"])):
		return null
	var p := AnimPlayParams.new(String(spec["clip"]), "", loop)
	p.time_scale = float(spec.get("time_scale", 1.0))
	p.normalized_start = float(spec.get("start", 0.0))
	p.on_complete = on_complete
	return playable.play(p)
