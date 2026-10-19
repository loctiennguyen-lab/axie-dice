class_name KeyBindings
extends RefCounted
## Rebindable keyboard shortcuts. Every shortcut is a named InputMap action; screens ask
## `event.is_action_pressed(KeyBindings.LAND_RUN)` instead of comparing keycodes, and key hints read
## `KeyBindings.text(action)` so they follow the player's choice.
##
## Defaults live in DEFS. A player's changes are stored as `MetaState.key_bindings`
## ({action: [keycode, ...]}, only actions that differ from default) and written through SaveStore with
## the rest of the settings. `ensure()` is idempotent and cheap: call it before reading an action.
## Esc is reserved: it cancels a rebind, so no action can be bound to it by the player.

const GROUPS := ["Land", "Combat", "Map", "General"]

const LAND_RUN := &"land_run"
const MENU_BACK := &"menu_back"
const BOSS_INTRO_SKIP := &"boss_intro_skip"
const COMBAT_END_TURN := &"combat_end_turn"
const COMBAT_UNDO := &"combat_undo"
const COMBAT_REROLL := &"combat_reroll"
const COMBAT_AID := &"combat_aid"
const COMBAT_INSPECT := &"combat_inspect"
const DIE_ACTIONS: Array[StringName] = [&"die_1", &"die_2", &"die_3", &"die_4", &"die_5"]
## Land hub entries in number-key order (1-7), then the letter shortcuts.
const LAND_ACTIONS: Array[StringName] = [
	&"land_portal", &"land_house", &"land_missions", &"land_echobox", &"land_pass", &"land_vault",
	&"land_store", &"land_board", &"land_new_run", &"land_upgrade", &"land_profile", &"land_daily",
	&"land_codex", &"land_run"]

## Ordered: this is the order the Settings list shows. {id, group, label, keys}.
const DEFS: Array[Dictionary] = [
	{"id": &"land_run", "group": "Land", "label": "Start or continue run", "keys": [KEY_ENTER, KEY_KP_ENTER]},
	{"id": &"land_portal", "group": "Land", "label": "Run portal", "keys": [KEY_1, KEY_KP_1]},
	{"id": &"land_house", "group": "Land", "label": "House (team presets)", "keys": [KEY_2, KEY_KP_2]},
	{"id": &"land_missions", "group": "Land", "label": "Missions", "keys": [KEY_3, KEY_KP_3]},
	{"id": &"land_echobox", "group": "Land", "label": "Echo Box", "keys": [KEY_4, KEY_KP_4]},
	{"id": &"land_pass", "group": "Land", "label": "Pass", "keys": [KEY_5, KEY_KP_5]},
	{"id": &"land_vault", "group": "Land", "label": "Vault", "keys": [KEY_6, KEY_KP_6]},
	{"id": &"land_store", "group": "Land", "label": "Store", "keys": [KEY_7, KEY_KP_7]},
	{"id": &"land_board", "group": "Land", "label": "Leaderboard", "keys": [KEY_B]},
	{"id": &"land_new_run", "group": "Land", "label": "New run", "keys": [KEY_N]},
	{"id": &"land_upgrade", "group": "Land", "label": "Upgrade Land", "keys": [KEY_L]},
	{"id": &"land_profile", "group": "Land", "label": "Profile", "keys": [KEY_P]},
	{"id": &"land_daily", "group": "Land", "label": "Daily", "keys": [KEY_D]},
	{"id": &"land_codex", "group": "Land", "label": "Codex", "keys": [KEY_C]},
	{"id": &"combat_end_turn", "group": "Combat", "label": "End turn", "keys": [KEY_SPACE, KEY_E]},
	{"id": &"combat_reroll", "group": "Combat", "label": "Reroll unused dice", "keys": [KEY_R]},
	{"id": &"combat_undo", "group": "Combat", "label": "Undo last die", "keys": [KEY_Z]},
	{"id": &"combat_aid", "group": "Combat", "label": "Aid tray", "keys": [KEY_A]},
	{"id": &"combat_inspect", "group": "Combat", "label": "Inspect unit", "keys": [KEY_I]},
	{"id": &"die_1", "group": "Combat", "label": "Pick die 1", "keys": [KEY_1, KEY_KP_1]},
	{"id": &"die_2", "group": "Combat", "label": "Pick die 2", "keys": [KEY_2, KEY_KP_2]},
	{"id": &"die_3", "group": "Combat", "label": "Pick die 3", "keys": [KEY_3, KEY_KP_3]},
	{"id": &"die_4", "group": "Combat", "label": "Pick die 4", "keys": [KEY_4, KEY_KP_4]},
	{"id": &"die_5", "group": "Combat", "label": "Pick die 5", "keys": [KEY_5, KEY_KP_5]},
	{"id": &"map_menu", "group": "Map", "label": "Run menu", "keys": [KEY_ESCAPE]},
	{"id": &"menu_back", "group": "General", "label": "Back / close", "keys": [KEY_ESCAPE]},
	{"id": &"boss_intro_skip", "group": "General", "label": "Skip boss intro", "keys": [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]},
]

static var _ready_done := false


## Registers every action with its default keys, then applies MetaState's overrides. Safe to call often.
static func ensure() -> void:
	if _ready_done:
		return
	_register()
	apply_overrides(_stored())


static func _register() -> void:
	_ready_done = true
	for d in DEFS:
		var id: StringName = d["id"]
		if InputMap.has_action(id):
			InputMap.erase_action(id)
		InputMap.add_action(id)
		for k in d["keys"]:
			InputMap.action_add_event(id, _event(int(k)))


## Forces a fresh registration (tests, after the save changed under us).
static func reset_registration() -> void:
	_register()
	apply_overrides(_stored())


static func _stored() -> Dictionary:
	var ms: Node = Engine.get_main_loop().root.get_node_or_null("MetaState") if Engine.get_main_loop() is SceneTree else null
	if ms == null:
		return {}
	var v: Variant = ms.get("key_bindings")
	return v if v is Dictionary else {}


static func _event(keycode: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode as Key
	return e


static func def_of(action: StringName) -> Dictionary:
	for d in DEFS:
		if d["id"] == action:
			return d
	return {}


static func default_keys(action: StringName) -> Array:
	return (def_of(action).get("keys", []) as Array).duplicate()


## Current keycodes of an action (what InputMap holds right now).
static func keys_of(action: StringName) -> Array:
	ensure()
	var out: Array = []
	for e in InputMap.action_get_events(action):
		var k := e as InputEventKey
		if k != null:
			out.append(int(k.keycode))
	return out


## Replaces an action's keys. An empty array restores the default.
static func set_keys(action: StringName, keycodes: Array) -> void:
	ensure()
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	var ks := keycodes if not keycodes.is_empty() else default_keys(action)
	for k in ks:
		InputMap.action_add_event(action, _event(int(k)))


## The override dictionary to persist: only actions that differ from the default.
static func overrides() -> Dictionary:
	ensure()
	var out := {}
	for d in DEFS:
		var cur := keys_of(d["id"])
		if cur != (d["keys"] as Array):
			out[String(d["id"])] = cur
	return out


## Applies a saved dictionary on top of the defaults. Unknown actions and junk values are ignored.
static func apply_overrides(saved: Dictionary) -> void:
	if not _ready_done:
		_register()
	for d in DEFS:
		set_keys(d["id"], [])
	for a in saved:
		var id := StringName(String(a))
		if def_of(id).is_empty() or not (saved[a] is Array):
			continue
		var ks: Array = []
		for k in (saved[a] as Array):
			if (typeof(k) == TYPE_INT or typeof(k) == TYPE_FLOAT) and int(k) > 0:
				ks.append(int(k))
		if not ks.is_empty():
			set_keys(id, ks)


static func reset_all() -> void:
	ensure()
	for d in DEFS:
		set_keys(d["id"], [])


## Display name of one keycode ("Space", "Enter", "R", "1").
static func key_name(keycode: int) -> String:
	match keycode:
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		KEY_ESCAPE:
			return "Esc"
	var s := OS.get_keycode_string(keycode as Key)
	if keycode >= KEY_KP_0 and keycode <= KEY_KP_9:
		return "Num " + str(keycode - KEY_KP_0)
	return s if s != "" else "?"


## Hint text for an action: the first key that is not a numpad / keypad duplicate, else the first.
static func text(action: StringName) -> String:
	var ks := keys_of(action)
	if ks.is_empty():
		return "-"
	for k in ks:
		if not (int(k) >= KEY_KP_0 and int(k) <= KEY_KP_ADD) and int(k) != KEY_KP_ENTER:
			return key_name(int(k))
	return key_name(int(ks[0]))


## Text of all keys of an action ("Space / E").
static func text_all(action: StringName) -> String:
	var seen: Array[String] = []
	for k in keys_of(action):
		var n := key_name(int(k))
		if not seen.has(n) and not (int(k) >= KEY_KP_0 and int(k) <= KEY_KP_9) and int(k) != KEY_KP_ENTER:
			seen.append(n)
	if seen.is_empty():
		return "-"
	return " / ".join(seen)


## Other actions in the same group that already use `keycode`. Land, Combat and Map are separate
## screens, so the same key in two groups is not a conflict.
static func conflicts(action: StringName, keycode: int) -> Array[StringName]:
	ensure()
	var out: Array[StringName] = []
	var g: String = def_of(action).get("group", "")
	for d in DEFS:
		var id: StringName = d["id"]
		if id != action and d["group"] == g and keys_of(id).has(keycode):
			out.append(id)
	return out


## Whether a key may be bound at all (no bare modifiers, no Esc: Esc cancels the capture).
static func bindable(keycode: int) -> bool:
	if keycode == KEY_ESCAPE or keycode == KEY_NONE or keycode == KEY_UNKNOWN:
		return false
	return not [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK].has(keycode)
