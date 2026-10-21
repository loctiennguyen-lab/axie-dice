extends Node
## Lane GM D3 + D4: Result shows the Combos card (Pair / Full, gold frame for Full), the "Skipped" line (max 3 Crystal
## Cores), and the "Copy run card" button puts team + Cores + combos + seed + run rule on the clipboard.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _texts(n: Node, out: Array) -> Array:
	if n is Label:
		out.append((n as Label).text)
	if n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)
	return out

func _ready() -> void:
	_guard.capture()
	ComboAdapter.test_combos = [
		{"id": "t_pair", "name_en": "Stone Wall", "pair": ["c_bastion", "c_fissure"], "full": null, "jackpot": false},
		{"id": "t_full", "name_en": "Iron Tide", "pair": ["c_bastion", "c_plague_spread"], "full": "c_fissure", "jackpot": false}]
	ComboAdapter.test_done = {"t_pair": "pair", "t_full": "full"}
	ComboAdapter.test_skipped = ["c_bastion", "c_fissure", "c_plague_spread", "c_bastion"]
	RunState.start_new_run(777001, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids.append("c_bastion")
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	for _i in 6:
		await get_tree().process_frame
	_check(v.find_child("CombosCard", true, false) != null, "Combos card exists")
	var pr: Node = v.find_child("ComboRow_t_pair", true, false)
	var fr: Node = v.find_child("ComboRow_t_full", true, false)
	_check(pr != null and pr.find_child("ComboTier", true, false).text == "Pair", "Pair row")
	_check(fr != null and fr.find_child("ComboTier", true, false).text == "Full", "Full row")
	_check(fr != null and ((fr as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == 4, "Full has the gold frame")
	_check(pr != null and ((pr as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == 0, "Pair has no frame")
	var sk: Label = v.find_child("SkippedLine", true, false)
	_check(sk != null and sk.text.begins_with("Skipped: ") and sk.text.count(",") == 2, "Skipped line has 3 names: %s" % (sk.text if sk else ""))
	var copy: Button = v.find_child("CopyRunCard", true, false)
	_check(copy != null and copy.text == "Copy run card", "Copy button")
	if copy != null:
		copy.pressed.emit()
		var clip: String = v.last_card_text
		_check(clip.contains("Stone Wall (Pair)") and clip.contains("Iron Tide (Full)"), "clipboard has combos: %s" % clip)
		_check(clip.contains("Seed: 777001") and clip.contains("Team:") and clip.contains("Cores:") and clip.contains("Run rule:"), "clipboard has seed, team, cores, rule")
	v.queue_free()
	ComboAdapter.test_combos = null
	ComboAdapter.test_done = null
	ComboAdapter.test_skipped = null
	_guard.restore()
	for m in _fails:
		print("t_gacha_result: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_gacha_result: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
