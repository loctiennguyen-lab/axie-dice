extends Node
## Lane GM D1 + D2: Core / combo codex in meta save (SaveStore, reload_from_store, account switch, old save) and the
## daily "Form combo X" challenge (deterministic pick, completion, title reward, never Shards).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
const ACCT := "google_test-codex"
const META := "user://meta_save.json"

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	_guard.capture()
	SaveStore.profile = ""
	ComboAdapter.test_combos = [
		{"id": "t_a", "name_en": "A", "pair": ["c_bastion", "c_fissure"], "full": null},
		{"id": "t_b", "name_en": "B", "pair": ["c_bastion", "c_plague_spread"], "full": "c_fissure"},
		{"id": "t_jack", "name_en": "J", "pair": null, "full": "c_bastion", "jackpot": true}]
	# --- D1 save / reload
	MetaState.reload_from_store()
	_check(MetaState.core_codex.is_empty() and MetaState.combo_codex.is_empty(), "fresh: empty codex")
	RunState.start_new_run(5150, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids.append("c_bastion")
	RunState.core_seen.append("c_fissure")
	ComboAdapter.test_done = {"t_a": "pair"}
	_check(MetaState.codex_sync_run(), "sync reports a change")
	_check(MetaState.core_codex["c_bastion"] == {"seen": true, "picked": true}, "held Core = seen + picked")
	_check(MetaState.core_codex["c_fissure"] == {"seen": true, "picked": false}, "offered Core = seen only")
	_check(MetaState.combo_codex["t_a"] == {"pair": true, "full": false}, "pair combo")
	_check(not MetaState.codex_sync_run(), "second sync: nothing new")
	ComboAdapter.test_done = {"t_a": "full"}
	MetaState.codex_sync_run()
	_check(MetaState.combo_codex["t_a"]["full"] == true, "full is recorded apart from pair")
	MetaState.reload_from_store()
	_check(MetaState.core_codex.get("c_bastion", {}).get("picked", false) == true, "survives reload_from_store")
	_check(MetaState.combo_codex.get("t_a", {}).get("full", false) == true, "combo survives reload")
	# --- account switch: another account has its own (empty) book, ours is intact on switch back
	SaveStore.profile = ACCT
	MetaState.reload_from_store()
	_check(MetaState.core_codex.is_empty(), "other account starts empty")
	MetaState.core_codex["c_fissure"] = {"seen": true, "picked": false}
	MetaState.save_to_disk()
	SaveStore.profile = ""
	MetaState.reload_from_store()
	_check(MetaState.core_codex.has("c_bastion") and MetaState.core_codex["c_fissure"]["picked"] == false, "guest book unchanged")
	SaveStore.profile = ACCT
	MetaState.reload_from_store()
	_check(MetaState.core_codex.size() == 1, "account book kept apart: %s" % str(MetaState.core_codex))
	SaveStore.erase_as(ACCT, META)
	SaveStore.profile = ""
	# --- old save without the fields
	var m = JSON.parse_string(SaveStore.read_text(META))
	m.erase("core_codex")
	m.erase("combo_codex")
	m.erase("combo_daily")
	SaveStore.write_text(META, JSON.stringify(m))
	MetaState.reload_from_store()
	_check(MetaState.core_codex.is_empty() and MetaState.combo_codex.is_empty() and MetaState.combo_daily["count"] == 0, "old save = empty")
	# --- D2 daily challenge
	var day := "2026-10-22"
	var pick := ComboDaily.pick(day, ComboAdapter.all())
	_check(pick == ComboDaily.pick(day, ComboAdapter.all()) and ["t_a", "t_b"].has(pick), "pick is stable and Pair-tier only: %s" % pick)
	var picks := {}
	for d in 28:
		picks[ComboDaily.pick("2026-11-%02d" % (d + 1), ComboAdapter.all())] = true
	_check(picks.size() == 2, "different days reach different combos")
	_check(ComboDaily.pick(day, []) == "", "no combos = no challenge")
	var today := MetaState.combo_daily_today()
	_check(String(today["id"]) != "" and not bool(today["done"]), "today: a combo, not done")
	var shards := MetaState.shard_pool
	ComboAdapter.test_done = {String(today["id"]): "pair"}
	MetaState.codex_sync_run()
	today = MetaState.combo_daily_today()
	_check(bool(today["done"]) and int(today["count"]) == 1, "forming today's combo completes it")
	_check(MetaState.cosmetics_owned.has(ComboDaily.TITLE_FIRST), "first completion grants the title")
	_check(MetaState.shard_pool == shards, "no Gene Shard reward")
	MetaState.codex_sync_run()
	_check(int(MetaState.combo_daily_today()["count"]) == 1, "done once per day")
	MetaState.reload_from_store()
	_check(bool(MetaState.combo_daily_today()["done"]), "done survives reload")
	ComboAdapter.test_combos = null
	ComboAdapter.test_done = null
	_guard.restore()
	MetaState.reload_from_store()
	for m2 in _fails:
		print("t_core_codex: FAIL — %s" % m2)
	if _fails.is_empty():
		print("t_core_codex: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
