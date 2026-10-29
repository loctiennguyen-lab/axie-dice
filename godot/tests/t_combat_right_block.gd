extends Node
## The combat ActionDock (UI-05 b1 lane A: ToolKeys / Reroll / End turn / StatusLine, bottom-right) must stay inside
## the canvas with the screen margin on the right and bottom, for every label the buttons can show, at scale 1.0
## (1920x1080) and at the 1280x720 window scale (0.667, the 1280 text floor makes body text 21 logical px).
## Every label must fit its own button with its trailing chip / key cap (no clipped "Reroll · need 1 MP" or
## "End turn"), every ToolKey word must fit its key and the row must fit the dock width ("Undo Hold Wild
## Overcast"), and no text in the dock may be below 14 real px. The canvas is always 1920 logical wide
## (stretch canvas_items), so the host stays 1920x1080 and the scale is forced.

const SCALES: Array[float] = [1.0, 2.0 / 3.0]
const HOST := Vector2(1920, 1080)

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_combat_right_block: start ===")
	for sc in SCALES:
		UI3Theme.set_scale_override(sc)
		await _run(sc)
	UI3Theme.set_scale_override(-1.0)
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


func _rect(c: Control, host: Control) -> Rect2:
	return Rect2(c.global_position - host.global_position, c.size)


func _run(sc: float) -> void:
	var host := Control.new()
	host.size = HOST
	add_child(host)
	var hud := CombatHud.new()
	host.add_child(hud)
	var undo := Button.new()
	var reroll := Button.new()
	var end := Button.new()
	hud.adopt_right_zone(undo, reroll, end)
	await get_tree().process_frame
	var tools_all := {"show": true, "enabled": true, "text": "x", "tip": "t"}
	var states: Array[Dictionary] = [
		{"name": "player turn (paid reroll, chip)", "u": {"enabled": true}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": true},
			"e": {"sub": "5 dice unused", "enabled": true, "resolving": false}, "res": false, "status": "5 dice unused"},
		{"name": "need MP, dice unused (unused wins, Liam 29/10)", "u": {"enabled": false}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": false},
			"e": {"sub": "5 dice unused", "unused": 5, "enabled": true, "resolving": false}, "res": false, "status": "5 dice unused"},
		{"name": "need MP, no die unused", "u": {"enabled": false}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": false},
			"e": {"sub": "0 dice unused", "unused": 0, "enabled": true, "resolving": false}, "res": false, "status": "Reroll: need 1 MP"},
		{"name": "need 12 MP", "u": {"enabled": false}, "r": {"n": 0, "max": 0, "cost": 12, "enabled": false},
			"e": {"sub": "0 dice unused", "enabled": true, "resolving": false}, "res": false, "status": "Reroll: need 12 MP"},
		{"name": "free rerolls 10/10", "u": {"enabled": true}, "r": {"n": 10, "max": 10, "enabled": true},
			"e": {"sub": "10 dice unused", "enabled": true, "resolving": false}, "res": false, "status": "10 dice unused"},
		{"name": "die picked", "u": {"enabled": true}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": true},
			"e": {"sub": "5 dice unused", "enabled": true, "resolving": false, "picked": true}, "res": false, "status": "Pick a target"},
		{"name": "gamble", "u": {"enabled": true}, "r": {"n": 0, "max": 0, "cost": 0, "stakes": 25, "enabled": true},
			"e": {"sub": "5 dice unused", "enabled": true, "resolving": false}, "res": false, "status": "5 dice unused"},
		{"name": "enemy turn", "u": {"enabled": false}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": false},
			"e": {"sub": "0 dice unused", "enabled": false, "resolving": true}, "res": true, "status": CombatHud.ENEMY_TEXT},
		{"name": "fight over", "u": {"enabled": false}, "r": {"n": 0, "max": 3, "enabled": false, "capped": true},
			"e": {"sub": "0 dice unused", "enabled": false, "resolving": false}, "res": false, "status": "0 dice unused"},
		{"name": "waiting", "u": {"enabled": true}, "r": {"n": 0, "max": 0, "cost": 1, "enabled": true},
			"e": {"sub": "5 dice unused", "enabled": true, "resolving": false}, "res": false, "wait": true,
			"status": CombatHud.WAITING_TEXT},
	]
	for st in states:
		hud.update_right(st["u"], st["r"], st["e"], tools_all, tools_all, tools_all)
		hud.set_resolving(bool(st["res"]))
		hud.set_seed_wait(bool(st.get("wait", false)))
		hud.layout()
		await get_tree().process_frame
		await get_tree().process_frame
		var tag := "scale %.3f %s" % [sc, st["name"]]
		var dock: Control = hud.get("_dock")
		var edge := float(UI3Theme.space("screen"))
		var dr := _rect(dock, host)
		_assert(dr.position.x >= 0.0 and dr.position.y >= 0.0 and dr.end.x <= HOST.x - edge + 0.5 and dr.end.y <= HOST.y - edge + 0.5,
			"%s: ActionDock %s leaves the canvas / screen margin" % [tag, dr])
		_assert(absf(dr.size.x - UI3Theme.size_of("action_dock_w")) < 0.5, "%s: ActionDock is action_dock_w wide (%s)" % [tag, dr.size.x])
		var parts: Array[Control] = [hud.get("_tools"), reroll, end, hud.get("_hint")]
		var rects: Array[Rect2] = []
		for c in parts:
			if not c.visible:
				continue
			var r := _rect(c, host)
			rects.append(r)
			_assert(r.position.x >= dr.position.x - 0.5 and r.end.x <= dr.end.x + 0.5 and r.end.y <= dr.end.y + 0.5,
				"%s: %s %s is outside the ActionDock %s" % [tag, c.name, r, dr])
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				_assert(not rects[i].grow(-1.0).intersects(rects[j].grow(-1.0)), "%s: dock rows overlap (%s / %s)" % [tag, rects[i], rects[j]])
		_assert(_fits_with_trailing(reroll, hud.get("_cost_chip")), "%s: '%s' does not fit Reroll (%d px)" % [tag, reroll.text, int(reroll.size.x)])
		_assert(_fits_with_trailing(end, hud.get("_end_cap")), "%s: '%s' does not fit End turn with its key cap (%d px)" % [tag, end.text, int(end.size.x)])
		var hint: Label = hud.get("_hint")
		_assert(hint.text == TranslationServer.translate(String(st["status"])), "%s: StatusLine '%s' (want '%s')" % [tag, hint.text, st["status"]])
		_assert(_label_fits(hint), "%s: StatusLine '%s' wider than the dock" % [tag, hint.text])
		var want_end := "End turn"
		if st["res"]:
			want_end = "Enemy turn"
		elif st.get("wait", false):
			want_end = CombatHud.WAITING_END
		_assert(end.text == want_end, "%s: End turn label is '%s' (want '%s')" % [tag, end.text, want_end])
		var cap: Control = hud.get("_end_cap")
		_assert(cap.visible, "%s: Space key cap stays on End turn" % tag)
		_check_tools(hud, host, tag)
		_check_floor(dock, sc, tag)
		hud.set_seed_wait(false)
	# Tall enemy column: the Attrition card is placed far down; it must be clamped above the ActionDock top.
	var attr: Control = hud.get("_attr_card")
	attr.visible = true
	hud.place_attrition(Vector2(HOST.x - float(UI3Theme.space("screen")) - UnitPortrait.card_w(), HOST.y - 40.0))
	await get_tree().process_frame
	var dock2: Control = hud.get("_dock")
	var attr_r := _rect(attr, host)
	var dock_r := _rect(dock2, host)
	_assert(not attr_r.intersects(dock_r), "scale %.3f: Attrition card %s overlaps the ActionDock %s" % [sc, attr_r, dock_r])
	_assert(attr_r.position.y >= 0.0, "scale %.3f: clamped Attrition card went off the top" % sc)
	host.queue_free()
	await get_tree().process_frame


## ToolKeys: four keys in one row inside the dock, each word fully inside its key, keys never overlap.
func _check_tools(hud: CombatHud, host: Control, tag: String) -> void:
	var row: Control = hud.get("_tools")
	var rr := _rect(row, host)
	_assert(rr.size.x <= UI3Theme.size_of("action_dock_w") + 0.5, "%s: ToolKeys row %s is wider than the dock" % [tag, rr])
	var keys: Array = hud.get("_tool_keys")
	_assert(keys.size() == 4, "%s: four ToolKeys" % tag)
	var prev_end := -1.0
	for k in keys:
		var key := k as Ui5ToolKey
		if not key.visible:
			continue
		var kr := _rect(key, host)
		_assert(kr.position.x >= prev_end - 0.5, "%s: %s overlaps the key before it" % [tag, key.name])
		prev_end = kr.end.x
		_assert(kr.end.x <= rr.end.x + 0.5, "%s: %s leaves the ToolKeys row" % [tag, key.name])
		_assert(_label_fits(key.word), "%s: word '%s' is cut in %s (%.0f px)" % [tag, key.word.text, key.name, key.word.size.x])
		var br := _rect(key.button, host)
		_assert(absf(br.size.x - UI3Theme.size_of("tool_key")) < 0.5 and absf(br.size.y - UI3Theme.size_of("tool_key")) < 0.5,
			"%s: %s plate is tool_key square (%s)" % [tag, key.name, br.size])


## No text in the dock below the real-px floor (14 at 1280).
func _check_floor(root: Control, sc: float, tag: String) -> void:
	var floor_px := float((UI3Theme.tokens().get("_size_1280_overrides", {}) as Dictionary).get("min_text", 14))
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if c is Label or c is Button:
			var fs := c.get_theme_font_size("font_size")
			if c is Button and (c as Button).text == "":
				continue
			_assert(float(fs) * sc >= floor_px - 0.01, "%s: %s text %d logical = %.1f real px < %d" % [tag, c.name, fs, fs * sc, int(floor_px)])


func _label_fits(l: Label) -> bool:
	var font := l.get_theme_font("font")
	var w := font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	return w <= l.size.x + 0.5


## Text (+ icon) + side padding + trailing chip/cap all inside the button, and the chip never covers the text.
func _fits_with_trailing(b: Button, trailing: Control) -> bool:
	var font := b.get_theme_font("font")
	var fs := b.get_theme_font_size("font_size")
	var w := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if b.icon != null:
		w += b.get_theme_constant("icon_max_width") + b.get_theme_constant("h_separation")
	var sb := b.get_theme_stylebox("normal")
	if w + sb.get_minimum_size().x > b.size.x + 0.5:
		return false
	if trailing != null and trailing.visible:
		if trailing.position.x < 0.0 or trailing.position.x + trailing.size.x > b.size.x - 0.5:
			return false
		var text_end := (sb.content_margin_left + b.size.x - sb.content_margin_right) * 0.5 + w * 0.5
		if trailing.position.x < text_end + UI3Theme.space("12") - 0.5:
			return false
	return true
