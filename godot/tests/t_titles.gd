extends Node
## C7: Ascension titles. Earned on a win at A5/A10 -> listed in Profile, equip persists across
## reload_from_store, Result shows "New title" only on the earning run. Own state, SaveGuard.

var _fail := 0
var _n := 0
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _ok(c: bool, msg: String) -> void:
	_n += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	await _run()
	_guard.restore()
	print("t_titles: %d checks, %d failed" % [_n, _fail])
	print("PASS" if _fail == 0 else "FAIL")
	get_tree().quit(1 if _fail > 0 else 0)


func _texts(root: Node) -> String:
	var out := ""
	for n in root.find_children("*", "Label", true, false):
		out += (n as Label).text + "\n"
	return out


func _result(asc: int, won: bool) -> Node:
	RunState.start_new_run(777002 + asc, TEAM, "short", asc, false)
	RunState.power_level = 9
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var view: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(view)
	await get_tree().process_frame
	await get_tree().process_frame
	return view


func _run() -> void:
	MetaState.cosmetics_owned.clear()
	MetaState.equipped_title = ""
	var ts := TitleNames.ascension_titles()
	_ok(ts.size() == 2 and int(ts[0]["asc"]) == 5 and int(ts[1]["asc"]) == 10, "two ascension titles from data")
	var a5: String = ts[0]["id"]
	var a10: String = ts[1]["id"]
	_ok(MetaState.equip_title(a5) != "", "cannot equip unowned title")

	# a loss and a low win grant nothing
	MetaState.record_run_outcome({"mode": "short", "ascension": 9}, false)
	MetaState.record_run_outcome({"mode": "short", "ascension": 4}, true)
	_ok(TitleNames.owned(MetaState.cosmetics_owned).is_empty() and MetaState.last_run_new_titles.is_empty(), "no title below A5 / on loss")

	# earning run: Result shows the line
	var view := await _result(5, true)
	_ok(MetaState.cosmetics_owned.has(a5) and not MetaState.cosmetics_owned.has(a10), "A5 win grants A5 title only")
	_ok(_texts(view).contains("New title: " + String(ts[0]["name"])), "Result shows new title on earning run")
	view.queue_free()
	await get_tree().process_frame

	# next run (A5 again): already owned -> no line
	view = await _result(5, true)
	_ok(not _texts(view).contains("New title"), "Result has no new-title line on a later run")
	view.queue_free()
	await get_tree().process_frame

	# Profile lists it; equip persists across reload
	var pv: ProfileView = load("res://scenes/profile/Profile.tscn").instantiate()
	pv.no_scene_change = true
	add_child(pv)
	await get_tree().process_frame
	pv.set_tab(2)
	var card := pv.find_child("Title_" + a5.replace(":", "_"), true, false)
	_ok(card != null and (card.find_child("Badge", true, false) as Label).text == "Owned", "Profile lists owned A5 title (Owned)")
	var c10 := pv.find_child("Title_" + a10.replace(":", "_"), true, false)
	_ok((c10.find_child("Badge", true, false) as Label).text == "Locked", "A10 shown as Locked")
	(c10 as Button).pressed.emit()
	_ok((pv.find_child("Equip", true, false) as Button).disabled and "Not yet" in (pv.find_child("Equip", true, false) as Button).text, "locked title: Equip disabled with reason")
	(pv.find_child("Title_" + a5.replace(":", "_"), true, false) as Button).pressed.emit()
	(pv.find_child("Equip", true, false) as Button).pressed.emit()
	_ok(MetaState.equipped_title == a5, "Equip button equips")
	await get_tree().process_frame
	pv.set_tab(0)
	_ok(pv.find_child("EquippedTitle", true, false) != null and "Title:" in (pv.find_child("EquippedTitle", true, false) as Label).text, "equipped title shown under name")
	pv.queue_free()
	MetaState.reload_from_store()
	_ok(MetaState.equipped_title == a5 and MetaState.cosmetics_owned.has(a5), "equip survives reload_from_store")
	MetaState.cosmetics_owned.erase(a5)
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_ok(MetaState.equipped_title == "", "title no longer owned -> unequipped on load")

	# A10 win grants both
	MetaState.record_run_outcome({"mode": "short", "ascension": 10}, true)
	_ok(MetaState.last_run_new_titles.size() == 2, "A10 win grants A5 + A10")

	# A5 already owned -> A10 win grants only A10
	MetaState.cosmetics_owned.clear()
	MetaState.cosmetics_owned.append(a5)
	MetaState.record_run_outcome({"mode": "short", "ascension": 10}, true)
	_ok(MetaState.last_run_new_titles.size() == 1 and MetaState.last_run_new_titles[0] == a10, "A10 win with A5 owned grants only A10")

	# Pass title id equips and persists
	var pass_t := "title:LUNACIA SOVEREIGN"
	_ok(MetaState.equip_title(pass_t) != "", "unowned pass title refused")
	MetaState.cosmetics_owned.append(pass_t)
	_ok(MetaState.equip_title(pass_t) == "" and MetaState.equipped_title == pass_t, "pass title equips")
	MetaState.reload_from_store()
	_ok(MetaState.equipped_title == pass_t, "pass title equip persists across reload")
