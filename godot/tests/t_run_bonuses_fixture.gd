extends Node
## Drift guard: MetaState.run_bonuses() (remote economy, perks ignored) must equal worker/test/fixtures/run_bonuses_cases.json,
## the same file worker/test/run_bonuses_fixture.test.mjs checks verify_job.js runBonuses() against. Change one side without the
## fixture and a test goes red. Also: every unlock in ContentDB.UNLOCKS must appear as a single-unlock case, so a NEW unlock
## forces someone to decide whether it changes run bonuses (and to update both sides).
var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _ready() -> void:
	_guard.capture()
	var path := ProjectSettings.globalize_path("res://").path_join("../worker/test/fixtures/run_bonuses_cases.json").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	_assert(f != null, "fixture readable: " + path)
	if f != null:
		var fx = JSON.parse_string(f.get_as_text())
		f.close()
		_assert(fx is Dictionary and (fx as Dictionary).has("cases"), "fixture has cases")
		if fx is Dictionary:
			_run(fx["cases"] as Array)
	MetaState.use_remote_econ(null)
	_guard.restore()
	if _failures.is_empty():
		print("t_run_bonuses_fixture: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for m in _failures:
		print("t_run_bonuses_fixture: FAIL — %s" % m)
	get_tree().quit(1)


func _run(cases: Array) -> void:
	MetaState.use_remote_econ(RemoteEcon.new())
	# Perks stuffed on purpose: under a remote economy they must change nothing.
	MetaState.perks = {"reroll": 3, "hp4": 2, "relic0": 1, "relic1": 1, "rrw": 2}
	var singles := {}
	for c in cases:
		var ids: Array[String] = []
		for u in (c["unlocks"] as Array):
			ids.append(String(u))
		if ids.size() == 1:
			singles[ids[0]] = true
		var want: Dictionary = c["expected"]
		for ranked in [false, true]:
			MetaState.unlocks = ids.duplicate()
			var got: Dictionary = MetaState.run_bonuses(ranked)
			var ok: bool = got.size() == want.size()
			for k in want:
				ok = ok and got.has(k) and int(got[k]) == int(want[k])
			_assert(ok, "unlocks %s ranked=%s: got %s want %s" % [str(ids), str(ranked), str(got), str(want)])
	for u in ContentDB.UNLOCKS:
		var id := String((u as Dictionary).get("id", ""))
		_assert(singles.has(id), "unlock '%s' has a single-unlock case in the fixture (does it change run bonuses? update MetaState, verify_job.js and the fixture)" % id)
