extends Node
## Anchor lane: anchor_codex in the meta save (SaveStore, reload_from_store, account switch, old save), updated on offer / pick /
## awaken; Result shows the Anchor row + Mutations line; Codex has an Anchors tab.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
const ACCT := "google_test-anchorcodex"
const META := "user://meta_save.json"


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_guard.capture()
	SaveStore.profile = ""
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.is_empty(), "fresh: empty")
	RunState.start_new_run(5151, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.anchor_offer = ["a_volley", "a_gambler", "a_mana_mine"]
	_check(MetaState.codex_sync_run(), "offer changes the book")
	_check(MetaState.anchor_codex["a_volley"] == {"seen": true, "picked": false, "awakened": false}, "offered = seen only")
	RunState.anchor_id = "a_volley"
	MetaState.codex_sync_run()
	_check(MetaState.anchor_codex["a_volley"]["picked"] == true and MetaState.anchor_codex["a_gambler"]["picked"] == false, "pick marks only the taken one")
	RunState.anchor_awakened = true
	MetaState.codex_sync_run()
	_check(MetaState.anchor_codex["a_volley"]["awakened"] == true, "awaken recorded")
	_check(not MetaState.codex_sync_run(), "second sync: nothing new")
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.get("a_volley", {}).get("awakened", false) == true, "survives reload_from_store")
	SaveStore.profile = ACCT
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.is_empty(), "other account starts empty")
	MetaState.anchor_codex["a_gambler"] = {"seen": true, "picked": false, "awakened": false}
	MetaState.save_to_disk()
	SaveStore.profile = ""
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.has("a_volley") and MetaState.anchor_codex["a_gambler"]["picked"] == false, "guest book unchanged")
	SaveStore.profile = ACCT
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.size() == 1, "account book kept apart")
	SaveStore.erase_as(ACCT, META)
	SaveStore.profile = ""
	var m = JSON.parse_string(SaveStore.read_text(META))
	m.erase("anchor_codex")
	SaveStore.write_text(META, JSON.stringify(m))
	MetaState.reload_from_store()
	_check(MetaState.anchor_codex.is_empty(), "old save = {}")
	# Codex tab
	MetaState.anchor_codex = {"a_volley": {"seen": true, "picked": true, "awakened": true}}
	var cx: Node = (load("res://scenes/codex/Codex.tscn") as PackedScene).instantiate()
	add_child(cx)
	await get_tree().process_frame
	_check(cx.find_child("CodexTab_anchors", true, false) != null, "Anchors tab exists")
	cx._select_tab("anchors")
	await get_tree().process_frame
	var t: Node = cx.find_child("AnchorTile_a_volley", true, false)
	_check(t != null and t.get_meta("seen") == true and (t.find_child("TileSub", true, false) as Label).text.contains("Awakened"), "met tile shows Awakened")
	var u: Node = cx.find_child("AnchorTile_a_gambler", true, false)
	_check(u != null and u.get_meta("seen") == false and (u.find_child("TileName", true, false) as Label).text == "?", "unmet tile is ?")
	# click a met tile: Rule / Price / Awakens detail; click again closes; unmet tile does nothing
	for aid in ["a_kin", "a_embers", "a_big_hand"]:
		MetaState.anchor_codex[aid] = {"seen": true, "picked": false, "awakened": false}
	cx._select_tab("anchors")
	await get_tree().process_frame
	var mb := InputEventMouseButton.new()
	mb.pressed = true
	mb.button_index = MOUSE_BUTTON_LEFT
	for aid in ["a_volley", "a_kin", "a_embers", "a_big_hand"]:
		cx.find_child("AnchorTile_" + aid, true, false).gui_input.emit(mb)
		var det: Node = cx.find_child("AnchorDetail", true, false)
		_check(det != null and det.find_child("RuleText", true, false) != null and (det.find_child("AwakenName", true, false) as Label).text == AnchorAdapter.awaken_name(aid), "%s detail shows rule + awaken" % aid)
		_check((det.find_child("PriceText", true, false) != null) == (AnchorAdapter.price_text(aid) != ""), "%s detail price" % aid)
	cx.find_child("AnchorTile_a_big_hand", true, false).gui_input.emit(mb)
	await get_tree().process_frame
	_check(cx.find_child("AnchorDetail", true, false) == null, "same tile again closes the detail")
	cx.find_child("AnchorTile_a_gambler", true, false).gui_input.emit(mb)
	_check(cx.find_child("AnchorDetail", true, false) == null, "unmet tile has no detail")
	cx.queue_free()
	# Result
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	for _i in 6:
		await get_tree().process_frame
	var ar: Node = v.find_child("AnchorRow", true, false)
	_check(ar != null and (ar.find_child("AnchorState", true, false) as Label).text == "Awakened", "Result: Anchor row Awakened")
	_check(ar != null and (ar.find_child("AnchorName", true, false) as Label).text.contains("Volley"), "Result: Anchor name")
	var ml: Label = v._mutation_line({"h_volley": 2, "h_kin": 0}) as Label
	_check(ml != null and ml.text.begins_with("Mutations: ") and ml.text.contains("(T2)") and not ml.text.contains("(T0)"), "Mutations line")
	_check(v._mutation_line({}) == null, "no mutations: no line")
	v.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_anchor_codex: FAIL - " + f)
	if _fails.is_empty():
		print("t_anchor_codex: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
