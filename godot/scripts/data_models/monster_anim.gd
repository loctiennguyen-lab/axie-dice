class_name MonsterAnim
extends RefCounted
## Frame sheets that let a rigless monster actually animate.
##
## WHERE THEY COME FROM
## --------------------
## `tools/spine_runtime/spine_sheet.py` samples the kit's own Spine 3.8 clips with Esoteric's
## 3.8 runtime and bakes each one into a grid sheet under `res://assets/monsters/anim/`.
## Godot has no Spine runtime and the kit is Spine 3.8, so spine-godot could not read these
## even if it were added — but nothing says the animation has to be SOLVED at play time. It
## is solved once, offline, and the game steps through frames. Exactly what the Origins skill
## VFX in `res://assets/vfx/` already do.
##
## WHY EVERY STATE SHARES A CELL SIZE
## ----------------------------------
## The exporter measures ONE box per monster across every clip it emits plus the resting
## pose, so `<name>.png` (the resting sprite) and `<name>_attack.png` are drawn at the same
## scale on the same ground line. That is what lets `_swap_sheet()` change a Sprite3D's
## texture mid-combat without the creature jumping in size or lifting off the floor.
##
## COVERAGE is not uniform and callers must handle a miss: 20/20 monsters have `attack` and
## `hit`, 15/20 have `die`. The five without ship a `defense/hit-die` of 0.17-0.25s, which is
## a placeholder rather than an animation; those keep the code-driven scale-to-zero fade.

const CATALOG_PATH := "res://assets/data/monster_anim.json"
const SHEET_DIR := "res://assets/monsters/anim/"

static var _catalog: Dictionary = {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true   # set FIRST: a missing file must not re-parse on every attack
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		push_warning("MonsterAnim: %s missing — monsters fall back to static sprites"
			% CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("MonsterAnim: %s is not a JSON object" % CATALOG_PATH)
		return
	var clips: Variant = (parsed as Dictionary).get("clips", {})
	if typeof(clips) == TYPE_DICTIONARY:
		_catalog = clips as Dictionary


## Metadata for one sprite's one state, or {} when there is none. Keys: frames, cols, rows,
## frame_w, frame_h, fps, duration, clip.
static func sheet(sprite_name: String, state: String) -> Dictionary:
	_load()
	var per_sprite: Variant = _catalog.get(sprite_name, {})
	if typeof(per_sprite) != TYPE_DICTIONARY:
		return {}
	var meta: Variant = (per_sprite as Dictionary).get(state, {})
	return meta as Dictionary if typeof(meta) == TYPE_DICTIONARY else {}


static func has(sprite_name: String, state: String) -> bool:
	return not sheet(sprite_name, state).is_empty()


static func sheet_path(sprite_name: String, state: String) -> String:
	return "%s%s_%s.png" % [SHEET_DIR, sprite_name, state]


## How long the state runs. 0.0 when unknown, which callers read as "no sheet".
static func duration(sprite_name: String, state: String) -> float:
	var meta := sheet(sprite_name, state)
	if meta.is_empty():
		return 0.0
	var fps := maxf(1.0, float(meta.get("fps", 12.0)))
	return float(meta.get("frames", 1)) / fps
