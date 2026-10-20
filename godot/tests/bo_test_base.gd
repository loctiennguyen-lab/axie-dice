class_name BoTestBase
extends Node
## Shared helpers for the depth v4 BO tests (design/gdd/dice-depth-v4.md 3.2-3.4, 8.1). Subclasses override run().
## Knob sets (N11): nominal = bo.scale 1.0 / m_cap 3.5 (numbers of the doc); default = whatever combat_tune.json ships (0.8 / 3.0).

var _guard := SaveGuard.new()
var _fail: Array[String] = []
var _checks := 0
var _name := "bo_test"
var _tune_backup: Dictionary = {}


func _ready() -> void:
	_guard.capture()
	_tune_backup = ContentDB.combat_tune.duplicate(true)
	await get_tree().process_frame
	run()
	ContentDB.combat_tune = _tune_backup
	_guard.restore()
	if _fail.is_empty():
		print("%s: PASS - %d checks OK" % [_name, _checks])
		get_tree().quit(0)
		return
	for f in _fail:
		print("%s: FAIL - %s" % [_name, f])
	get_tree().quit(1)


func run() -> void:
	pass


func ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func eq(a, b, msg: String) -> void:
	ok(a == b, "%s (got %s, want %s)" % [msg, str(a), str(b)])


## "nominal" (scale 1.0, cap 3.5) or "default" (shipped knobs).
func set_knobs(which: String) -> void:
	ContentDB.combat_tune = _tune_backup.duplicate(true)
	if which == "nominal":
		var b: Dictionary = ContentDB.combat_tune["bo"]
		b["scale"] = 1.0
		b["m_cap"] = 3.5


static func engine(relics: Array = [], mana: int = 0, seed_v: int = 7, stage: int = 3) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(),
		"relic_ids": relics, "combat_seed": seed_v, "start_mana": mana, "depth_stage": stage})
	return e


static func face(type: String, value: int, rarity: int = 0, kw: Array = []) -> Dictionary:
	return {"part": "x", "type": type, "value": value, "keywords": kw, "rarity": rarity}


## Forces party[i] to show face index fis[i] holding `f` (a face dict, or one per die when `f` is an Array), clears roll state, snapshots BO.
static func force(e: CombatEngine, fis: Array, f = null, snap: bool = true) -> void:
	for i in fis.size():
		var u: Unit = e.party[i]
		var fd: Dictionary = (f[i] if f is Array else f) if f != null else face("dmg", 5)
		u.die[int(fis[i])] = fd.duplicate(true)
		u.set_roll(int(fis[i]), false)
		u.heavy = false
		u.held = false
		u.frozen = false
		u.cracked = false
		u.wild_slot = -1
		u.overcast = false
		u.hp = maxi(u.hp, 1)
	if snap:
		e._snap_bo()


static func digest(e: CombatEngine) -> String:
	var d: Dictionary = e.to_data().duplicate(true)
	d.erase("undo_stack")
	return JSON.stringify(d)
