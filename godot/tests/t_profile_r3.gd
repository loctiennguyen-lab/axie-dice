extends Node
## R3 M12 / M14: Profile tabs, stat tiles from saved data, run log (last 10, Aid / Pure), guest banner +
## Sign in, cosmetics tab (counts, owned vs missing, equip / unequip / disabled reason), reload keeps log.
## Own state, SaveGuard, stub account (no network).

class StubService extends Node:
	signal changed
	var status: int = 0
	var account: Dictionary = {}
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

var _fail := 0
var _n := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_n += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	_guard.capture()
	await _run()
	_guard.restore()
	print("t_profile_r3: %d checks, %d failed" % [_n, _fail])
	print("PASS" if _fail == 0 else "FAIL")
	get_tree().quit(1 if _fail > 0 else 0)


func _view(svc: Node) -> ProfileView:
	var pv := ProfileView.new()
	pv.service = svc
	pv.no_scene_change = true
	add_child(pv)
	await get_tree().process_frame
	return pv


func _run() -> void:
	MetaState.reload_from_store()
	MetaState.runs = 0
	MetaState.wins = 0
	MetaState.asc_wins = {}
	MetaState.run_log = []
	MetaState.profile_stats = {"pure_wins": 0, "ms_played": 0, "ms_won": 0}
	MetaState.cosmetics_owned.clear()
	MetaState.equipped_die_skin = ""
	MetaState.equipped_frame = ""
	var svc := StubService.new()
	add_child(svc)

	# guest + empty
	var pv := await _view(svc)
	_ok(pv.find_child("Banner", true, false) != null and pv.find_child("SignIn", true, false) != null, "guest: banner with Sign in")
	_ok(pv.find_child("RunsEmpty", true, false) != null, "empty: no runs line")
	_ok(String((pv.find_child("PlayerName", true, false) as Label).text) == "Guest", "guest name")
	_ok("Guest" in (pv.find_child("SyncText", true, false) as Label).text, "guest sync chip")
	_ok(String((pv.find_child("Stat_Wins", true, false).find_child("Value", true, false) as Label).text) == "0", "wins tile 0")
	pv.queue_free()

	# run log: 12 runs, newest first, cap 10; aid / pure / mission counted
	for i in 12:
		MetaState.record_run_outcome({"mode": "short", "ascension": i % 3, "kind": "normal", "aid_used": 0, "mission_id": ""}, true)
	MetaState.record_run_outcome({"mode": "full", "ascension": 4, "kind": "ranked", "aid_used": 2, "mission_id": ""}, false)
	MetaState.record_run_outcome({"mode": "short", "ascension": 3, "kind": "normal", "aid_used": 0, "mission_id": "ms_x"}, true)
	_ok(MetaState.run_log.size() == 10, "log capped at 10")
	_ok(bool(MetaState.run_log[0]["mission"]) and int(MetaState.run_log[1]["aid"]) == 2, "newest first")
	_ok(int(MetaState.profile_stats["pure_wins"]) == 12, "pure wins = wins with no Aid, not mission")
	_ok(int(MetaState.profile_stats["ms_played"]) == 1 and int(MetaState.profile_stats["ms_won"]) == 1, "mission counters")
	MetaState.runs = 14
	MetaState.wins = 13
	svc.account = {"name": "Mai", "sky_mavis": true}
	pv = await _view(svc)
	_ok(pv.find_child("Banner", true, false) == null, "signed in: no banner")
	_ok(pv.find_children("Run_*", "PanelContainer", true, false).size() == 10, "ten run rows")
	_ok(pv.find_child("Run_1", true, false).find_child("AidMark", true, false).text == "Aid 2", "Aid marker")
	_ok(pv.find_child("Run_0", true, false).find_child("AidMark", true, false).text == "no Aid (mission)", "mission marker")
	_ok(pv.find_child("Run_2", true, false).find_child("PurePill", true, false) != null, "pure pill")
	_ok(pv.find_child("Run_1", true, false).find_child("PurePill", true, false) == null, "no pill when Aid used")
	_ok(String((pv.find_child("Stat_Pure wins".replace(" ", ""), true, false).find_child("Value", true, false) as Label).text) == "12", "pure tile")
	pv.queue_free()

	# survives reload
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_ok(MetaState.run_log.size() == 10 and int(MetaState.profile_stats["ms_won"]) == 1, "run log + stats survive reload_from_store")

	# cosmetics tab
	pv = await _view(svc)
	pv.set_tab(1)
	var tiles := pv.find_children("Tile_die_*", "Button", true, false)
	_ok(tiles.size() == ProfileView.catalog("die").size() + 1 - 1 and tiles.size() > 0 and pv.find_child("Tile_default_die", true, false) != null,
		"grid lists every die skin (owned or not) + the Default tile first")
	var eq := pv.find_child("Equip", true, false) as Button
	_ok(eq.disabled and eq.text == "Equipped", "default selected and equipped: Equip says Equipped")
	pv.queue_free()
	MetaState.cosmetics_owned.append("die_c_clay")
	pv = await _view(svc)
	pv.set_tab(1)
	_ok("2 of 21" in (pv.find_child("Cat_die", true, false) as Button).text, "category count")
	var other := ProfileView.catalog("die")[1]
	(pv.find_child("Tile_" + other, true, false) as Button).pressed.emit()
	await get_tree().process_frame
	eq = pv.find_child("Equip", true, false) as Button
	_ok(eq.disabled and eq.text == "Locked", "unowned selected: disabled, says Locked")
	(pv.find_child("Tile_die_c_clay", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	(pv.find_child("Equip", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(MetaState.equipped_die_skin == "die_c_clay", "Equip equips")
	_ok((pv.find_child("Equip", true, false) as Button).text == "Equipped" and (pv.find_child("Equip", true, false) as Button).disabled, "button says Equipped, disabled")
	(pv.find_child("Tile_default_die", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	(pv.find_child("Equip", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(MetaState.equipped_die_skin == "", "Equip on the Default tile clears the skin")
	(pv.find_child("Cat_frame", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(pv.find_child("Grid_frame", true, false) != null, "frames category")
	pv.queue_free()

	# real path: RunState.end_run puts kind + aid_used in run_log; tutorial and abandoned runs add nothing
	MetaState.run_log = []
	RunState.start_new_run(11, TEAM, "short", 0, false)
	RunState.run_kind = "daily"
	RunState.aid_uses.append({"aid": "a_x", "node_id": "n1"})
	RunState.aid_uses.append({"aid": "a_y", "node_id": "n2"})
	RunState.end_run(false)
	_ok(MetaState.run_log.size() == 1, "end_run adds exactly one run_log entry")
	if MetaState.run_log.size() == 1:
		var le: Dictionary = MetaState.run_log[0]
		_ok(String(le["kind"]) == "daily" and int(le["aid"]) == 2 and not bool(le["won"]), "end_run: kind + aid_used reach run_log")
	RunState.start_new_run(12, TEAM, "short", 0, false)   # abandon (Land New run / Settings): no end_run
	RunState.clear_saved_run()
	RunState.reset()
	_ok(MetaState.run_log.size() == 1, "abandoned run adds no entry")
	RunState.pending_combat = {"node_id": "tutorial", "kind": "battle", "pw": 0, "ascension": 0, "tutorial": true}   # what TutorialView sets; it never calls end_run
	RunState.reset()
	_ok(MetaState.run_log.size() == 1, "tutorial run adds no entry")
	MetaState.run_log = []
