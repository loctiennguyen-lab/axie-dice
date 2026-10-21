extends Node
## Lane GM D1: Codex tabs Cores / Combos. Unmet = dimmed tile with "?" and no name; met = name + tier words.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

## GU 2: a met tile never says "Not met yet"; padding inside; the border is the plain token and the same for both.
func _tile_rules(met: Node, unmet: Node, what: String) -> void:
	_check(met.find_child("TileSub", true, false).text != "Not met yet", "%s: met tile does not say Not met yet" % what)
	_check(unmet.find_child("TileSub", true, false).text == "Not met yet", "%s: unmet tile says Not met yet" % what)
	for t in [met, unmet]:
		var sb := (t as Control).get_theme_stylebox("panel") as StyleBoxFlat
		_check(sb != null and sb.content_margin_left >= 12 and sb.content_margin_top >= 8, "%s: tile has inner padding" % what)
		_check(sb != null and sb.border_color == UI3Theme.color("disabled_border") and sb.border_width_left == 2, "%s: tile border = plain token" % what)


func _ready() -> void:
	_guard.capture()
	ComboAdapter.test_combos = [
		{"id": "t_a", "name_en": "Stone Wall", "pair": ["c_bastion", "c_fissure"], "full": null},
		{"id": "t_b", "name_en": "Iron Tide", "pair": ["c_bastion", "c_plague_spread"], "full": "c_fissure"}]
	MetaState.core_codex = {"c_bastion": {"seen": true, "picked": true}}
	MetaState.combo_codex = {"t_a": {"pair": true, "full": false}}
	var cx: Node = (load("res://scenes/codex/Codex.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(cx)
	for _i in 4:
		await get_tree().process_frame
	_check(cx.find_child("CodexTab_cores", true, false) != null and cx.find_child("CodexTab_combos", true, false) != null, "both tabs exist")
	cx.call("_select_tab", "cores")
	await get_tree().process_frame
	var met: Node = cx.find_child("CoreTile_c_bastion", true, false)
	var unmet: Node = cx.find_child("CoreTile_c_fissure", true, false)
	_check(met != null and met.find_child("TileName", true, false).text == "Bastion" and met.find_child("TileSub", true, false).text.contains("Picked"), "met Core tile shows name + Picked")
	_check(unmet != null and unmet.find_child("TileName", true, false).text == "?" and not bool(unmet.get_meta("seen", true)), "unmet Core tile is a ? (muted, not dimmed)")
	_tile_rules(met, unmet, "core")
	cx.call("_select_tab", "combos")
	await get_tree().process_frame
	_tile_rules(cx.find_child("ComboTile_t_a", true, false), cx.find_child("ComboTile_t_b", true, false), "combo")
	_check(cx.find_child("ComboTile_t_a", true, false).find_child("TileSub", true, false).text == "Pair", "Pair tile")
	_check(cx.find_child("ComboTile_t_b", true, false).find_child("TileName", true, false).text == "?", "unmet combo is ?")
	cx.queue_free()
	ComboAdapter.test_combos = null
	_guard.restore()
	MetaState.reload_from_store()
	for m in _fails:
		print("t_codex_books: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_codex_books: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
