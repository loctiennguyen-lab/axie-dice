class_name ComboAdapter
extends RefCounted
## Lane GM: the ONE place the UI reads the combo API of lane GD (CoreCombos, RunState.combo_done / core_skipped_t,
## EventBus.combo_*). Lane GD's API is merged; the test hooks below still override it.
## Combo row (core_combos.json): {id, name_en, name_vi, pair:[core_a, core_b] | null, full:core_c | null, jackpot:bool}.
## No combo logic lives here: only lookups and display text.

## Test hook: when non-null it replaces CoreCombos.all() (tests must not depend on lane GD's data).
static var test_combos = null
## Test hooks for RunState.combo_done / core_skipped_t while lane GD's fields do not exist (null = read RunState).
static var test_done = null
static var test_skipped = null


## Every combo enabled in the data (CoreCombos.all([]): no run-rule filter, so the daily pick and the Codex are stable
## whatever the current run holds).
static func all() -> Array:
	if test_combos != null:
		return test_combos
	return CoreCombos.all([])


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
	if test_done != null:
		return test_done
	return RunState.combo_done


## RunState.core_skipped_t: Crystal Cores shown and not taken.
static func skipped_t() -> Array:
	if test_skipped != null:
		return test_skipped
	return RunState.core_skipped_t


## Connects `cb` to EventBus.combo_fired when lane GD's signal exists. Returns whether it connected.
static func connect_fired(cb: Callable) -> bool:
	if not EventBus.combo_fired.is_connected(cb):
		EventBus.combo_fired.connect(cb)
	return true


static func connect_formed(cb: Callable) -> bool:
	if not EventBus.combo_formed.is_connected(cb):
		EventBus.combo_formed.connect(cb)
	return true
