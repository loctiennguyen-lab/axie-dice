extends Node
## GU 1: every Combos row on Result is either fully inside the visible scroll viewport or the card scroll is
## actually scrollable (has a visible vertical bar). Checked at 1920x1080 and 1280x720 windows (canvas is the same).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	_guard.capture()
	ComboAdapter.test_combos = [
		{"id": "t_pair", "name_en": "Stone Wall", "pair": ["c_bastion", "c_fissure"], "full": null, "jackpot": false},
		{"id": "t_full", "name_en": "Iron Tide", "pair": ["c_bastion", "c_plague_spread"], "full": "c_fissure", "jackpot": false}]
	ComboAdapter.test_done = {"t_pair": "pair", "t_full": "full"}
	ComboAdapter.test_skipped = ["c_bastion", "c_fissure", "c_plague_spread"]
	RunState.start_new_run(777002, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids.append("c_bastion")
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	for _i in 8:
		await get_tree().process_frame
	var sc: ScrollContainer = v.find_child("CardScroll", true, false)
	_check(sc != null, "CardScroll exists")
	if sc != null:
		var vis := sc.get_global_rect()
		var bar := sc.get_v_scroll_bar()
		var scrollable := bar.visible and bar.max_value > bar.page + 1.0
		for n in ["ComboRow_t_pair", "ComboRow_t_full", "SkippedLine"]:
			var r: Control = v.find_child(n, true, false)
			_check(r != null, "%s exists" % n)
			if r != null:
				var rr := r.get_global_rect()
				var inside := rr.position.y >= vis.position.y - 1.0 and rr.end.y <= vis.end.y + 1.0
				_check(inside or scrollable, "%s is visible (%s in %s) or the card has a scrollbar" % [n, rr, vis])
		var plate: Control = v.find_child("ResultPlate", true, false)
		_check(plate.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y + 1.0, "plate stays in the window")
	v.queue_free()
	ComboAdapter.test_combos = null
	ComboAdapter.test_done = null
	ComboAdapter.test_skipped = null
	_guard.restore()
	for m in _fails:
		print("t_gacha_result_fit: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_gacha_result_fit: PASS — %d checks OK" % _checks)
	get_tree().quit(1 if not _fails.is_empty() else 0)
