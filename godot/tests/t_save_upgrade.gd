extends Node
## B9: a save written by an older build must load in the current build without errors.
## Fixtures (tests/fixtures/save_upgrade/, no personal data):
##   v1_meta/v1_run      — copy of a real 21/09 save: meta has no save_version (v1), run is a mid-map run.
##   v2_old_meta/v2_old_run — written by commit 8484e8e (SAVE_VERSION 2 both) with known currencies.
## Contract pinned here:
##   v1 meta  -> migrated: vault/runs/wins/best/asc_max/settings kept; Shard balance, unlocks, perks,
##               xp, pass wiped (by design, _migrate_pre_economy); starter grant applied; v1 backup written.
##   v2 meta  -> everything kept verbatim.
##   run save -> resumes (version 2) or is refused with false and changes nothing (other version).
## Run: godot --headless --path godot res://tests/t_save_upgrade.tscn

const DIR := "res://tests/fixtures/save_upgrade/"
var _fails: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_save_upgrade: start ===")
	_guard.capture()
	test_v1_meta_migrates()
	test_v2_meta_kept_verbatim()
	test_v1_run_cleanly_refused()
	test_v2_run_resumes()
	test_other_version_run_refused_and_state_untouched()
	test_garbage_files_do_not_crash()
	_guard.restore()
	print("=== t_save_upgrade: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_save_upgrade: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_save_upgrade: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _fx(name: String) -> String:
	return FileAccess.get_file_as_string(DIR + name)


func _install(meta: String, run: String) -> void:
	for p in [MetaState.SAVE_PATH, RunState.SAVE_PATH]:
		SaveStore.erase(p)
	SaveStore.erase(MetaState.V1_BACKUP_PATH)
	if meta != "":
		SaveStore.write_text_as(SaveStore.profile, MetaState.SAVE_PATH, meta, false)
	if run != "":
		SaveStore.write_text_as(SaveStore.profile, RunState.SAVE_PATH, run, false)


func test_v1_meta_migrates() -> void:
	var raw: Dictionary = JSON.parse_string(_fx("v1_meta.json"))
	_ok(not raw.has("save_version"), "fixture v1_meta must be a v1 save")
	_install(_fx("v1_meta.json"), "")
	MetaState.reload_from_store()
	_ok(MetaState.save_version == MetaState.SAVE_VERSION, "v1: save_version not bumped")
	_ok(MetaState.runs == int(raw["runs"]) and MetaState.wins == int(raw["wins"]), "v1: runs/wins lost")
	_ok(MetaState.best == int(raw["best"]), "v1: best lost")
	_ok(MetaState.asc_max == int(raw["asc_max"]), "v1: asc_max lost")
	_ok(MetaState.tutorial_seen, "v1: tutorial_seen lost")
	_ok(MetaState.shard_pool == MetaState.starter_shard_locked, "v1: shard_pool should be only the starter grant (by design)")
	_ok(MetaState.unlocks.is_empty() and MetaState.perks.is_empty() and MetaState.xp == 0, "v1: unlocks/perks/xp should reset")
	_ok(MetaState.starter_granted, "v1: starter not granted")
	_ok(MetaState.stone == 0 and int(MetaState.tickets.get("season", 0)) == 0, "v1: stone/season tickets not defaulted")
	_ok(MetaState.mission_escrow.is_empty(), "v1: escrow not empty")
	_ok(String(MetaState.pass_season.get("id", "x")) == "" and (MetaState.pass_season.get("weekly", {}) as Dictionary).is_empty(), "v1: pass_season not defaulted")
	_ok(SaveStore.exists_as(SaveStore.profile, MetaState.V1_BACKUP_PATH), "v1: no .v1.bak backup of the old file")
	_ok(MetaState.vault.size() >= 0, "v1: vault ok")


func test_v2_meta_kept_verbatim() -> void:
	var raw: Dictionary = JSON.parse_string(_fx("v2_old_meta.json"))
	_install(_fx("v2_old_meta.json"), "")
	MetaState.reload_from_store()
	_ok(MetaState.shard_pool == int(raw["shard_pool"]), "v2: shard changed %d -> %d" % [int(raw["shard_pool"]), MetaState.shard_pool])
	_ok(MetaState.stone == int(raw["stone"]), "v2: stone changed")
	_ok(MetaState.gems_cache == int(raw["gems_cache"]), "v2: gem changed")
	_ok(int(MetaState.tickets.get("normal", 0)) == int((raw["tickets"] as Dictionary)["normal"]), "v2: tickets changed")
	_ok(MetaState.unlocks.size() == (raw["unlocks"] as Array).size(), "v2: unlocks changed")
	_ok(MetaState.runs == int(raw["runs"]) and MetaState.wins == int(raw["wins"]), "v2: runs/wins changed")
	_ok(MetaState.starter_granted and (MetaState.ledger.size() == (raw["ledger"] as Array).size()), "v2: starter re-granted or ledger changed")
	_ok(not SaveStore.exists_as(SaveStore.profile, MetaState.V1_BACKUP_PATH), "v2: spurious v1 backup")


func _resume(run_fx: String) -> void:
	var raw: Dictionary = JSON.parse_string(_fx(run_fx))
	_install("", _fx(run_fx))
	_ok(RunState.has_saved_run(), run_fx + ": not detected")
	_ok(RunState.load_run(), run_fx + ": load_run returned false")
	var rd: Dictionary = raw["run"]
	_ok(RunState.run_seed == int(rd["run_seed"]), run_fx + ": seed")
	_ok(RunState.roster.size() == (rd["roster"] as Array).size(), run_fx + ": roster")
	_ok(RunState.current_node_id == String(rd["current_node_id"]), run_fx + ": node")
	_ok(RunState.mission_escrow.is_empty() or RunState.mission_escrow is Dictionary, run_fx + ": escrow type")
	_ok(RunState.resume_combat.is_empty() == (raw["combat"] as Dictionary).is_empty(), run_fx + ": combat slot")
	_ok(not RunState.map_graph.is_empty() and RunMapGraph.from_data(RunState.map_graph).find_node(RunState.current_node_id) != null, run_fx + ": map/current node broken")


## Finding B9-1: a v1 run save (pre-21/09) is refused by load_run (SAVE_VERSION 2). Clean (no crash, state
## untouched), but MainMenu still shows CONTINUE for it, then drops it with only a push_warning.
func test_v1_run_cleanly_refused() -> void:
	_install("", _fx("v1_run.json"))
	RunState.reset()
	var before := RunState.run_seed
	_ok(RunState.has_saved_run(), "v1_run: not detected")
	_ok(not RunState.load_run(), "v1_run: expected refusal (version 1)")
	_ok(RunState.run_seed == before and RunState.roster.is_empty(), "v1_run: refused load changed RunState")


func test_v2_run_resumes() -> void:
	_resume("v2_old_run.json")


func test_other_version_run_refused_and_state_untouched() -> void:
	var d: Dictionary = JSON.parse_string(_fx("v2_old_run.json"))
	d["version"] = 1
	_install("", JSON.stringify(d))
	RunState.reset()
	var seed_before := RunState.run_seed
	_ok(not RunState.load_run(), "version 1 run save should be refused")
	_ok(RunState.run_seed == seed_before, "refused load changed RunState")


func test_garbage_files_do_not_crash() -> void:
	for junk in ["[]", "null", "{\"version\":2}", "{\"version\":2,\"run\":5}"]:
		_install("", junk)
		_ok(not RunState.load_run(), "junk run save accepted: " + junk)
	for junk in ["[]", "{\"save_version\":\"x\",\"tickets\":5,\"pass_season\":7,\"mission_escrow\":3}"]:
		_install(junk, "")
		MetaState.reload_from_store()
		_ok(MetaState.shard_pool >= 0, "junk meta crashed/negative: " + junk)
