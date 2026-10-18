extends Node
## StatusHeads: icon chips above heads. Icon per status (enrage has none: label chip), "+n" past 4,
## hidden at once for a unit with no screen point / dead / during the victory march, dropped units
## are freed, chips connect gui_input once. Run: godot --headless --path godot res://tests/t_status_heads.tscn

var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_status_heads: start ===")
	for k in ["poison", "burn", "regen", "blind", "weaken", "vulnerable", "thorns", "stun", "undying", "shield"]:
		_check(StatusHeads.icon_for(k) != null, "status %s has an icon" % k)
	_check(StatusHeads.icon_for("enrage") == null, "enrage has no icon (label chip fallback)")
	var items := StatusHeads.items_for(3, {"poison": 2, "thorns": 0, "burn": 1})
	_check(items == [["shield", 3], ["poison", 2], ["burn", 1]], "items: shield first, zero counts dropped (%s)" % str(items))

	var heads := StatusHeads.new()
	add_child(heads)
	var base := {"uid": 1, "anchor": Vector2(400, 300), "hidden": false, "shield": 2, "status": {"poison": 3, "enrage": 1}}
	heads.sync([base])
	var row := heads.row_of(1)
	_check(row != null and row.visible and row.get_child_count() == 3, "row with shield, poison, enrage chips")
	_check(row.position.y + row.size.y <= 300.0 + 0.5 and absf(row.position.x + row.size.x * 0.5 - 400.0) < 1.0,
		"row is centred above the anchor")
	for c in row.get_children():
		_check((c as Control).gui_input.get_connections().size() <= 1, "chip gui_input connected at most once")
	var tip := UI3Tooltip.text_of(row.get_child(1))
	_check(tip.contains("Poison") and tip.length() > 20, "chip tooltip explains the effect (%s)" % tip)

	var no_point := base.duplicate()
	no_point["anchor"] = Vector2(-1, -1)
	heads.sync([no_point])
	_check(not row.visible, "no screen point (dead / hidden model) hides the row")
	heads.sync([base])
	_check(row.visible, "row shows again with a point")
	var march := base.duplicate()
	march["hidden"] = true
	heads.sync([march])
	_check(not row.visible, "hidden flag (victory march) hides the row")
	var many := {"uid": 1, "anchor": Vector2(400, 300), "hidden": false, "shield": 1,
		"status": {"poison": 1, "burn": 1, "regen": 1, "weaken": 1, "thorns": 1}}
	heads.sync([many])
	row = heads.row_of(1)
	_check(row.get_child_count() == 4, "5+ statuses: 3 chips + a +n plate (got %d)" % row.get_child_count())
	heads.sync([])
	await get_tree().process_frame
	_check(heads.row_of(1) == null, "a unit that left is dropped")
	for f in _fails:
		print("t_status_heads: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_status_heads: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
