class_name ComboAdapter
extends RefCounted
## Lane GM: the ONE place the UI reads the combo API of lane GD (CoreCombos, RunState.combo_done / core_skipped_t,
## EventBus.combo_*). Until that lane merges every call falls back to "empty", so no screen needs to guard.
## Combo row (core_combos.json): {id, name_en, name_vi, pair:[core_a, core_b] | null, full:core_c | null, jackpot:bool}.
## No combo logic lives here: only lookups and display text.

const COMBOS_SCRIPT := "res://scripts/core/core_combos.gd"

## Test hook: when non-null it replaces CoreCombos.all() (tests must not depend on lane GD's data).
static var test_combos = null


## Every combo enabled for this run (CoreCombos.all()), [] when the API does not exist yet.
static func all() -> Array:
	if test_combos != null:
		return test_combos
	if not ResourceLoader.exists(COMBOS_SCRIPT):
		return []
	var s = load(COMBOS_SCRIPT)
	if s == null:
		return []
	var r = s.call("all")
	return r if r is Array else []


static func find(combo_id: String) -> Dictionary:
	for c in all():
		if String((c as Dictionary).get("id", "")) == combo_id:
			return c
	return {}


## Player-facing name (English; vi only when no English name).
static func display_name(combo_id: String) -> String:
	var c := find(combo_id)
	if c.is_empty():
		return combo_id.replace("_", " ").capitalize()
	var n := String(c.get("name_en", ""))
	return n if n != "" else String(c.get("name_vi", combo_id))


## The Cores of a Pair ([] for a jackpot combo, which has no Pair tier).
static func pair_cores(combo_id: String) -> Array:
	var p = find(combo_id).get("pair", null)
	return (p as Array).duplicate() if p is Array else []


## RunState.combo_done: id -> "pair" | "full". {} before lane GD merges.
static func done() -> Dictionary:
	var d = RunState.get("combo_done")
	return d if d is Dictionary else {}


## RunState.core_skipped_t: Crystal Cores shown and not taken.
static func skipped_t() -> Array:
	var d = RunState.get("core_skipped_t")
	return d if d is Array else []


## Connects `cb` to EventBus.combo_fired when lane GD's signal exists. Returns whether it connected.
static func connect_fired(cb: Callable) -> bool:
	if not EventBus.has_signal("combo_fired"):
		return false
	if not EventBus.is_connected("combo_fired", cb):
		EventBus.connect("combo_fired", cb)
	return true


static func connect_formed(cb: Callable) -> bool:
	if not EventBus.has_signal("combo_formed"):
		return false
	if not EventBus.is_connected("combo_formed", cb):
		EventBus.connect("combo_formed", cb)
	return true
