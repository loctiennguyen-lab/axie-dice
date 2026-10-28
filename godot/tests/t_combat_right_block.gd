extends Node
## The combat bottom-right block (Undo / Reroll / End turn / hint, and the 1x / 2x / Skip row while the
## enemy turn plays) must stay inside the viewport with a 24 px right margin, for every label the
## buttons can show, at 1920x1080 and 1280x720. Every label must also fit its own button (text width +
## stylebox padding <= button width), so nothing is clipped. Reported on build b931: "Enemy turn..."
## ran off the right edge.

const SIZES: Array[Vector2] = [Vector2(1920, 1080), Vector2(1280, 720)]
const MARGIN := 24.0

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_combat_right_block: start ===")
	for sz in SIZES:
		await _run(sz)
	print("=== t_combat_right_block: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_combat_right_block: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_combat_right_block: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _run(sz: Vector2) -> void:
	var host := Control.new()
	host.size = sz
	add_child(host)
	var hud := CombatHud.new()
	host.add_child(hud)
	var undo := Button.new()
	var reroll := Button.new()
	var end := Button.new()
	hud.adopt_right_zone(undo, reroll, end)
	await get_tree().process_frame
	var states: Array[Dictionary] = [
		{"name": "player turn", "u": {"enabled": true}, "r": {"n": 3, "max": 3, "enabled": true},
			"e": {"sub": "5 dice unused", "enabled": true, "resolving": false}, "res": false},
		{"name": "no rerolls", "u": {"enabled": false}, "r": {"n": 0, "max": 3, "enabled": false},
			"e": {"sub": "0 dice unused", "enabled": true, "resolving": false}, "res": false},
		{"name": "rerolls 10/10", "u": {"enabled": true}, "r": {"n": 10, "max": 10, "enabled": true},
			"e": {"sub": "10 dice unused", "enabled": true, "resolving": false}, "res": false},
		{"name": "enemy turn", "u": {"enabled": false}, "r": {"n": 0, "max": 3, "enabled": false},
			"e": {"sub": "0 dice unused", "enabled": false, "resolving": true}, "res": true},
		{"name": "fight over", "u": {"enabled": false}, "r": {"n": 0, "max": 3, "enabled": false},
			"e": {"sub": "0 dice unused", "enabled": false, "resolving": false}, "res": false},
	]
	for st in states:
		hud.update_right(st["u"], st["r"], st["e"])
		hud.set_resolving(bool(st["res"]))
		await get_tree().process_frame
		var tag := "%dx%d %s" % [int(sz.x), int(sz.y), st["name"]]
		var block: Array[Control] = [undo, reroll, end, hud.get("_hint"), hud.get("_speed")]
		var vis_rects: Array[Rect2] = []
		for c in block:
			if not c.visible:
				continue
			var r := Rect2(c.global_position - host.global_position, c.size)
			vis_rects.append(r)
			_assert(r.position.x >= 0.0 and r.position.y >= 0.0 and r.end.y <= sz.y and r.end.x <= sz.x - MARGIN + 0.5,
				"%s: %s %s leaves the viewport / right margin (%s)" % [tag, c.name, r, sz])
		for b in [undo, reroll, end]:
			if b.visible:
				_assert(_text_fits(b), "%s: '%s' does not fit its button (%d px)" % [tag, b.text, int(b.size.x)])
		for b in hud.speed_buttons() + [hud.skip_button()]:
			if hud.get("_speed").visible:
				_assert(_text_fits(b), "%s: '%s' does not fit its button (%d px)" % [tag, b.text, int(b.size.x)])
		for i in vis_rects.size():
			for j in range(i + 1, vis_rects.size()):
				_assert(not vis_rects[i].grow(-1.0).intersects(vis_rects[j].grow(-1.0)),
					"%s: right-block controls overlap (%s / %s)" % [tag, vis_rects[i], vis_rects[j]])
		_assert(end.text == ("Enemy turn" if st["res"] else "End turn"), "%s: End turn label is '%s'" % [tag, end.text])
	# Tall enemy column: the Attrition card is placed far down; it must be clamped above the ActionDock top.
	var attr: Control = hud.get("_attr_card")
	attr.visible = true
	hud.place_attrition(Vector2(sz.x - MARGIN - UnitPortrait.card_w(), sz.y - 40.0))
	await get_tree().process_frame
	var dock: Control = hud.get("_dock")
	var attr_r := Rect2(attr.global_position - host.global_position, attr.size)
	var dock_r := Rect2(dock.global_position - host.global_position, dock.size)
	_assert(not attr_r.intersects(dock_r), "%dx%d: Attrition card %s overlaps the ActionDock %s" % [int(sz.x), int(sz.y), attr_r, dock_r])
	_assert(attr_r.position.y >= 0.0, "%dx%d: clamped Attrition card went off the top" % [int(sz.x), int(sz.y)])
	host.queue_free()


func _text_fits(b: Button) -> bool:
	var font := b.get_theme_font("font")
	var fs := b.get_theme_font_size("font_size")
	var w := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return w + b.get_theme_stylebox("normal").get_minimum_size().x <= b.size.x + 0.5
