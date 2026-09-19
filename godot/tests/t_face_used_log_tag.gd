extends Node
## Regression test for the "[AOE]" combat-log mistag bug (godot-port bug-fix session,
## 2026-09-17): CombatView._on_face_used() used to append " [AOE]" to the log line
## whenever the `face_used` signal's `aoe` bool was true — but that bool mirrors
## engine.js's overloaded `ev.aoe` field (combat_engine.gd _exec_face:
## `_has_kw(f,"aoe") or f.type=="mana" or f.type=="summon"`), which is ALSO true for
## mana/summon self-casts that never hit more than one target. Real repro: Olek's
## "ears/mana" face (autoload/ContentDB.gd plant1) has no `aoe` keyword but logged
## "[use] Olek -> Olek (ears/mana) [AOE]" anyway.
##
## This drives Combat.tscn's real EventBus.face_used signal (not a mock) and reads
## CombatView's own log RichTextLabel (white-box %LogPanel access, same pattern
## t_combatview_smoke.gd already uses) to prove the tag now only appears for a face
## that is genuinely multi-target.
##
## Run: godot --headless --path godot tests/t_face_used_log_tag.tscn

var _anomaly := ""


func _ready() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true

	# Arrange: minimal real combat so CombatView/EventBus are the actual wired objects.
	RunState.pending_combat = {
		"node_id": "t_face_used_log_tag_node",
		"kind": "battle",
		"pw": 2,
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": 4242,
	}
	var view: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(view)
	await tree.process_frame

	var log_panel: RichTextLabel = view.get_node("%LogPanel")
	_check(log_panel != null, "CombatView has no %LogPanel node")
	if _anomaly != "":
		_fail(tree)
		return

	# Act 1 — self-cast mana face (Olek's "ears/mana"), matches the real repro exactly:
	# combat_engine.gd's aoe param is true here (mana overload) but this must NOT show [AOE].
	EventBus.face_used.emit(101, "p", 101, true, "ears", "mana", "mana")
	await tree.process_frame
	var mana_line := _last_line(log_panel)
	_check(
		not mana_line.contains("[AOE]"),
		"mana self-cast face wrongly tagged [AOE]: %s" % mana_line
	)

	# Act 2 — real multi-target AOE face (e.g. Momo's tail/aoe dmg face): must still show [AOE].
	EventBus.face_used.emit(102, "p", -1, true, "tail", "aoe_swipe", "dmg")
	await tree.process_frame
	var aoe_line := _last_line(log_panel)
	_check(
		aoe_line.contains("[AOE]"),
		"genuine multi-target aoe face lost its [AOE] tag: %s" % aoe_line
	)

	# Act 3 — summon self-cast: same overload as mana, must also not show [AOE].
	EventBus.face_used.emit(103, "p", 103, true, "back", "call", "summon")
	await tree.process_frame
	var summon_line := _last_line(log_panel)
	_check(
		not summon_line.contains("[AOE]"),
		"summon self-cast face wrongly tagged [AOE]: %s" % summon_line
	)

	if _anomaly == "":
		print("t_face_used_log_tag: PASS — [AOE] tag only shows for genuine multi-target faces")
		tree.quit(0)
	else:
		_fail(tree)


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1,
			"hero_key": keys[i],
			"tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [],
			"growth": {},
			"bonus_hp": 0,
		})
	return out


## The RichTextLabel accumulates every log line ever appended (see CombatView._append_log) —
## isolate just the newest line so each Act only asserts on the event it just emitted.
func _last_line(log_panel: RichTextLabel) -> String:
	var lines := log_panel.text.split("\n")
	return lines[lines.size() - 1] if not lines.is_empty() else ""


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _fail(tree: SceneTree) -> void:
	print("t_face_used_log_tag: FAIL — %s" % _anomaly)
	CombatView.disable_juice_for_tests = false
	tree.quit(1)
