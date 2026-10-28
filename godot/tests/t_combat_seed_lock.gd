extends Node
## SR0: the REAL CombatView ignores die / target / undo / Hold / Overcast / wild-face input while a seed
## request is in flight (`_combat.epoch_pending`). Nothing reaches the action log, no die stays picked.
## `epoch_pending` is set directly (a plain var): the engine-level race is t_run_session_race.
## The 6 guards are also checked in the source text, because Hold / Overcast / wild-face can not always be
## armed headless (a missing precondition would make the behaviour check pass without the guard).

const GUARDED := ["_on_die_slot_pressed(slot_index: int)", "_on_target_clicked(uid: int)", "_on_overcast_pressed()",
	"_on_hold_pressed()", "_on_undo_pressed()", "_on_wild_chosen(slot: int)"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.pending_combat = {"node_id": "seed_lock_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 4242}
	var view := load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var eng: CombatEngine = view._combat
	var log: ActionLog = eng.action_log

	# 1. Control: without a request in flight the view DOES act (so the checks below can fail for the right reason).
	var die_uid := -1
	for u in eng.party:
		if (u as Unit).has_rolled() and not (u as Unit).roll_used():
			die_uid = (u as Unit).uid
			break
	_check(die_uid >= 0, "setup: a rolled die exists")
	view._on_die_slot_pressed(0)
	_check(view._selected_die_uid != -1, "control: with no request pending, pressing a die slot picks it")
	view._selected_die_uid = -1

	# 2. Pending: nothing gets through.
	eng.epoch_pending = true
	var n0 := log.size()
	view._on_die_slot_pressed(0)
	_check(view._selected_die_uid == -1, "die slot press ignored while a seed is in flight")
	view._selected_die_uid = die_uid
	var target_uid := int((eng.enemies[0] as Unit).uid)
	view._on_target_clicked(target_uid)
	_check(log.size() == n0 and view._selected_die_uid == die_uid, "target click ignored: nothing logged, die stays picked")
	view._on_undo_pressed()
	view._on_hold_pressed()
	view._on_overcast_pressed()
	view._on_wild_chosen(0)
	_check(log.size() == n0, "undo / Hold / Overcast / wild face wrote nothing to the log (%d -> %d)" % [n0, log.size()])
	eng.epoch_pending = false

	# 3. After the lock is released the same click works again.
	view._selected_die_uid = die_uid
	view._on_target_clicked(target_uid)
	_check(log.size() > n0 or view._selected_die_uid != die_uid, "control: once released, the target click is handled")

	# 3b. HUD: while waiting every dice action is greyed and a one-line hint says why; released = hint gone.
	var hud: CombatHud = view._hud_frame
	hud.set_seed_wait(true)
	_check(hud.undo_button.disabled and hud.reroll_button.disabled and hud.end_turn_button.disabled and hud.hold_button.disabled,
		"waiting: Undo / Reroll / Hold / End turn greyed")
	_check(hud._hint.text == CombatHud.WAITING_TEXT and not hud._hint.text.contains("\n"), "waiting: one-line StatusLine")
	hud.set_seed_wait(false)
	view._update_hud()
	_check(hud._hint.text != CombatHud.WAITING_TEXT, "released: waiting line gone")

	# 4. The six guards are really in the source.
	var src := FileAccess.get_file_as_string("res://scenes/combat/CombatView.gd")
	for sig in GUARDED:
		var head := "func %s -> void:\n" % sig
		var i := src.find(head)
		_check(i >= 0 and src.substr(i + head.length(), 220).contains("if _combat.epoch_pending:\n\t\treturn"), "guard present in " + sig)

	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("PASS t_combat_seed_lock (%d checks)" % _checks)
	else:
		for f in _fails:
			print("FAIL: ", f)
		print("FAIL t_combat_seed_lock")
	get_tree().quit(0 if _fails.is_empty() else 1)
