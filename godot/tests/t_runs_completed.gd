extends Node
## Depth v4 offline stage: MetaState.runs_completed survives save/reload through SaveStore, old saves derive it,
## depth_stage() uses the same thresholds as worker/src/runs.js depthStage(), and Ranked is blocked below stage 3.
## Run: godot --headless --path godot res://tests/t_runs_completed.tscn

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_guard.capture()
	_new_account()
	_round_trip()
	_old_saves()
	_ranked_gate()
	_guard.restore()
	if _fails.is_empty():
		print("t_runs_completed: PASS - %d checks OK" % _checks)
	else:
		for f in _fails:
			print("FAIL: " + f)
		print("t_runs_completed: FAIL - %d of %d" % [_fails.size(), _checks])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _load(d: Dictionary) -> void:
	SaveStore.write_text(MetaState.SAVE_PATH, JSON.stringify(d))
	MetaState.reload_from_store()


func _new_account() -> void:
	_load({"save_version": 2})
	_check(MetaState.runs_completed == 0, "fresh save: 0")
	_check(MetaState.depth_stage() == 1, "fresh newcomer, nothing completed -> stage 1")
	MetaState.note_run_completed()
	_check(MetaState.depth_stage() == 2, "1 completed -> stage 2")
	MetaState.note_run_completed()
	_check(MetaState.depth_stage() == 2, "2 completed -> still stage 2")
	MetaState.note_run_completed()
	_check(MetaState.depth_stage() == 3, "3 completed -> stage 3")


func _round_trip() -> void:
	_load({"save_version": 2, "runs_completed": 2, "runs_with_battle": 2, "runs": 2})
	_check(MetaState.runs_completed == 2, "field read back")
	MetaState.note_run_completed()
	MetaState.save_to_disk()
	MetaState.runs_completed = 0
	MetaState.reload_from_store()
	_check(MetaState.runs_completed == 3, "saved through SaveStore and restored by reload_from_store")
	var parsed = JSON.parse_string(SaveStore.read_text(MetaState.SAVE_PATH))
	_check(typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("runs_completed", -1)) == 3, "present in the save text")


func _old_saves() -> void:
	_load({"runs": 2, "save_version": 2})
	_check(MetaState.runs_completed == 2, "old save: derived from runs")
	_load({"runs": 8, "runs_with_battle": 8, "save_version": 2})
	_check(MetaState.runs_completed == 8 and MetaState.depth_stage() == 3, "old account past the newcomer gate -> stage 3")
	_load({"runs": 0, "runs_with_battle": 6, "save_version": 2})
	_check(MetaState.depth_stage() == 3, "old account with 6 fought runs but runs 0 -> stage 3")


func _ranked_gate() -> void:
	# The Ranked block itself is asserted in t_run_setup ("stage 2: Ranked locked").
	_load({"save_version": 2, "runs_completed": 2, "runs_with_battle": 9, "runs": 2})
	_check(MetaState.depth_stage() == 2 and not MetaState.is_newcomer(), "stage 2 but not a newcomer: only the stage gate applies")
