extends Node
## Lane GM D2 UI: the Daily screen shows the "Form combo X" card (real CoreCombos data), flips to Done when the
## run forms it (EventBus.combo_formed -> MetaState.codex_sync_run), and grants a title, never Shards.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	_guard.capture()
	MetaState.combo_daily = {"day": "", "done": false, "count": 0}
	MetaState.cosmetics_owned.erase(ComboDaily.TITLE_FIRST)
	ComboAdapter.test_combos = null
	ComboAdapter.test_done = null
	RunState.combo_done = {}
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.no_scene_change = true
	add_child(d)
	await get_tree().process_frame
	var t := MetaState.combo_daily_today()
	var cid := String(t["id"])
	_check(cid != "" and not CoreCombos.get_combo(cid).is_empty(), "real combo picked: %s" % cid)
	var card := d.find_child("ComboCard", true, false)
	_check(card != null, "combo card exists")
	var chip := d.find_child("ComboStatus", true, false)
	_check(chip != null and _text(chip) == "Not yet", "starts Not yet")
	var shards := MetaState.shard_pool
	RunState.combo_done = {cid: "pair"}
	EventBus.combo_formed.emit(cid, "pair")
	_check(bool(MetaState.combo_daily_today()["done"]), "combo_formed completes the daily")
	d._refresh()
	chip = d.find_child("ComboStatus", true, false)
	_check(chip != null and _text(chip) == "Done", "card shows Done")
	_check(MetaState.cosmetics_owned.has(ComboDaily.TITLE_FIRST), "title granted")
	_check(MetaState.shard_pool == shards, "no Shards")
	RunState.combo_done = {}
	_guard.restore()
	MetaState.reload_from_store()
	for m in _fails:
		print("t_combo_daily_card: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_combo_daily_card: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)

func _text(n: Node) -> String:
	if n is Label:
		return (n as Label).text
	for c in n.find_children("*", "Label", true, false):
		return (c as Label).text
	return ""
