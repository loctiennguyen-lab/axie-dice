extends Node
## Loads all RelicDef resources from resources/relics/ once at boot, sorted by the
## explicit `sort_index` field — NEVER by directory scan order, which is not stable
## across OS/filesystem/CI (architecture plan §6, fixing the reviewed draft's reliance
## on "definition order" that doesn't exist once relics become individual .tres files).
##
## Relic HOOK LOGIC lives in scripts/core/relic_hooks.gd as static functions, looked up
## by RelicDef.hook_key through RelicHooks.call_hook(...) at the call site — never bound
## as a Callable stored on the Resource itself (Resource instances are cached by
## ResourceLoader per-path; writing a Callable onto one mutates a shared, potentially
## editor-persisted object, and breaks under script hot-reload). See architecture plan §6.

var _defs_by_id: Dictionary = {}     # id -> RelicDef
var _defs_sorted: Array = []          # RelicDef, sorted by sort_index — the ONLY iteration
                                       # order allowed for modFace/modDmg/onHit/etc. hooks

const RELIC_DIR := "res://resources/relics/"

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	_defs_by_id.clear()
	_defs_sorted.clear()
	var dir := DirAccess.open(RELIC_DIR)
	if dir == null:
		# Expected until the data.js -> .tres converter tool (checklist step 8) exists.
		push_warning("RelicRegistry: %s not found or empty — no relics loaded yet" % RELIC_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var def = load(RELIC_DIR + file_name)
			if def != null and def.has_method("get") and "id" in def:
				_defs_by_id[def.id] = def
		file_name = dir.get_next()
	dir.list_dir_end()
	_defs_sorted = _defs_by_id.values()
	_defs_sorted.sort_custom(func(a, b): return a.sort_index < b.sort_index)

## Ordered list of currently-loaded RelicDefs, sorted by sort_index. Callers filtering to
## "owned relics for this combat" must filter THIS array (preserving order), never re-sort
## by pickup order.
func all_defs_sorted() -> Array:
	return _defs_sorted

func get_def(id: String):
	return _defs_by_id.get(id)


## Relics the player may actually be OFFERED (reward cards, shop stock, event grants).
##
## Excludes pseudo-relics — ids prefixed `__`. These are engine-internal carriers for effects
## that JS models as a relic so they inherit the normal hook and INV-5 ordering machinery,
## e.g. `__curse_dmg`, the +4-damage half of the CURSE PACT reward (src/engine.js:1188).
## They must resolve through get_def() like any other relic, but offering one as loot would
## hand the player a card that only exists as another card's side effect.
##
## Guarding structurally here rather than leaning on the rarity band: `__curse_dmg` happens
## to be rarity 4 and so falls outside every current offer range by luck, not by design, and
## the next pseudo-relic might not.
func offerable_defs_sorted() -> Array:
	var out: Array = []
	for def in _defs_sorted:
		if not String(def.id).begins_with("__"):
			out.append(def)
	return out
