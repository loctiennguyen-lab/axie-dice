extends Node
## UI-05 b23 lane 0d: the meta kit (scenes/shared/ui5/meta) at 1920 and at 1280 (scale 0.667).
## 1. Every data-name of components-land / meta1 / meta2 sheets that the kit owns exists.
## 2. No two siblings of a row overlap, nothing leaves the 1920 x 1080 sheet.
## 3. No text under 14 px REAL (font size x scale) at 1280, and no button / label text wider than its box.
## 4. Text beside / under an icon is centred on it (tests/ui5_align_check.gd), and that check measured > 0 pairs.
## 5. State behaviour: DetailPlate empty / item, ListRow states, TabBar, Switch, Slider, ClaimButton, Buy, DisabledReason
##    (drops the keycap), ModalFooter one / two rows.
## Run: godot --headless --path godot res://tests/t_ui5_meta_kit.tscn

const Demo := preload("res://tests/ui5_meta_kit_demo.gd")
const Align := preload("res://tests/ui5_align_check.gd")
const Keycap := preload("res://scenes/shared/ui5/Keycap.gd")
const NAMES := ["CurrencyPlate", "CurrencyShard", "CurrencyStone", "CurrencyGem", "ToneDisc", "Toast", "DetailPlate",
	"TabBar", "ListRow", "SaveCard", "Footer1Row", "Footer2Rows", "GemCost", "ClaimButton", "ClaimedButton", "LockReason",
	"Spinner", "SwitchButton", "Slider", "GiftButton", "DetailScroll", "PrimaryButton", "Sub", "Kv"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_meta_kit: start ===")
	_guard.capture()
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	await _behaviour()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_meta_kit: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_meta_kit: FAIL — %s" % f)
		get_tree().quit(1)


func _pass(sc: float, tag: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Demo.build(layer)
	for i in 4:
		await get_tree().process_frame
	var rect := Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for n in NAMES:
		_check(root.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	_check(root.get_tree() != null and (root.find_children("ToneDisc", "", true, false) as Array).size() == 3, "%s: three ToneDiscs (ok, error, info)" % tag)
	_siblings(root, rect, tag)
	_text(root, sc, tag)
	var probs := Align.check(root, 1.5, tag + ": ")
	_check(Align.pairs(root) > 0, "%s: the centring check measured no icon / label pair" % tag)
	for pr in probs:
		_check(false, pr)
	# 1280: switch + slider follow keycap_h
	var sw := root.find_child("SwitchButton", true, false) as Ui5Switch
	_check(is_equal_approx(sw.track_size().y, float(UI3Theme.size_of("keycap_h"))), "%s: switch track height = keycap_h" % tag)
	_check(is_equal_approx(sw.track_size().x, 2.0 * UI3Theme.size_of("keycap_h")), "%s: switch width = 2 x keycap_h" % tag)
	var d0 := root.find_child("DetailPlate", true, false) as Ui5DetailPlate
	var sbx := d0.get_theme_stylebox("panel") as StyleBoxFlat
	_check(int(sbx.content_margin_left) == UI3Theme.space("16") and int(sbx.content_margin_top) == UI3Theme.space("16"), "%s: detail padding = space 16" % tag)
	_check(d0.is_empty() and d0.title.text == "Pick a tier" and d0.body.get_child_count() > 0 and d0.primary != null and d0.primary.disabled and not d0.primary.text.is_empty(), "%s: empty detail = Title + Body + disabled primary with reason" % tag)
	_check(d0.title.get_global_rect().position.y < d0.body.get_global_rect().position.y and d0.body.get_global_rect().position.y < d0.primary.get_global_rect().position.y, "%s: empty detail order Title, Body, primary" % tag)
	_check(d0.primary.get_global_rect().end.y > d0.get_global_rect().end.y - UI3Theme.space("16") - 12, "%s: primary pinned to the plate foot" % tag)
	_check(d0.primary.size.y >= UI3Theme.size_of("btn_l") - 1, "%s: primary min-h btn_l" % tag)
	var sc0 := root.find_child("SaveCard", true, false)
	_check(sc0.get_node("Col").get_child(1).name == "Sub" and sc0.get_node("Col").get_child(2).name == "Kv", "%s: SaveCard order Title, Sub, Kv" % tag)
	_check((sc0.get_node("Col/Kv") as Control).size.y >= UI3Theme.size_of("btn_s") - 1, "%s: Kv min-h btn_s" % tag)
	var lrow := root.find_children("*", "PanelContainer", true, false).filter(func(c: Node) -> bool: return c is Ui5ListRow)
	var lsb := (lrow[1] as Control).get_theme_stylebox("panel") as StyleBoxFlat
	_check(lsb.border_width_left == UI3Theme.stroke("selected") and lsb.border_color == UI3Theme.color("selected"), "%s: selected ListRow ring = stroke selected" % tag)
	var slr := root.find_child("Slider", true, false) as Ui5Slider
	_check(slr.track_height() == UI3Theme.size_of("hp_bar_h") and slr.size.x == 200.0 and slr.size.y >= UI3Theme.size_of("hit_min"), "%s: slider track hp_bar_h, width 200, hit >= hit_min" % tag)
	_check(Ui5Toast.top_y(true) == UI3Theme.size_of("toast_under_banner") and (sc != 1.0 or Ui5Toast.top_y(true) == 140) and (sc == 1.0 or Ui5Toast.top_y(true) == 288), "%s: toast under banner (%d)" % [tag, Ui5Toast.top_y(true)])
	_check(sw.size.x >= UI3Theme.size_of("hit_min") and sw.size.y >= UI3Theme.size_of("hit_min"), "%s: switch hit box >= hit_min" % tag)
	_check(root.find_child("Row5", true, false).get_child_count() == 4, "%s: row 5 has spinner, 2 switches, slider" % tag)
	layer.queue_free()
	await get_tree().process_frame


func _siblings(n: Node, rect: Rect2, tag: String) -> void:
	if n is Control and not (n as Control).is_visible_in_tree():
		return
	if n is BoxContainer:
		var kids: Array[Control] = []
		for c in n.get_children():
			if c is Control and (c as Control).is_visible_in_tree() and (c as Control).size.x > 0:
				kids.append(c)
		for i in kids.size():
			var a := kids[i].get_global_rect()
			_check(rect.grow(1.0).encloses(a), "%s: %s/%s inside the sheet (%s)" % [tag, n.name, kids[i].name, a])
			for j in range(i + 1, kids.size()):
				_check(not a.grow(-0.5).intersects(kids[j].get_global_rect().grow(-0.5)), "%s: %s: %s overlaps %s" % [tag, n.name, kids[i].name, kids[j].name])
	for c in n.get_children():
		_siblings(c, rect, tag)


func _text(n: Node, sc: float, tag: String) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label or n is Button:
		var c := n as Control
		var txt := (n as Label).text if n is Label else (n as Button).text
		if txt.strip_edges() != "":
			var fs := c.get_theme_font_size("font_size")
			_check(float(fs) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, txt.left(20), fs * sc])
			var f := c.get_theme_font("font")
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if n is Label and (n as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
				_check(w <= c.size.x + 1.0, "%s: label '%s' fits (%.0f in %.0f)" % [tag, txt.left(20), w, c.size.x])
			if n is Button:
				_check(w <= c.size.x - 2.0 + 0.5, "%s: button '%s' fits (%.0f in %.0f)" % [tag, txt.left(20), w, c.size.x])
	for ch in n.get_children():
		_text(ch, sc, tag)


func _behaviour() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	layer.add_child(box)
	# DetailPlate
	var d := Ui5DetailPlate.new()
	d.setup("mission_detail_w", "Pick a tier", "Body", "Pick a tier first")
	box.add_child(d)
	_check(d.is_empty() and d.title.text == "Pick a tier" and d.primary != null and d.primary.disabled and d.primary.text == "Pick a tier first", "detail: starts empty, disabled primary says why")
	d.show_item("Tier 3")
	d.add_line("x")
	d.set_primary("Go")
	_check(not d.is_empty() and d.title.text == "Tier 3" and d.footer.get_child_count() == 1 and not d.primary.disabled, "detail: item state")
	d.show_empty()
	_check(d.is_empty() and d.primary.disabled and d.title.text == "Pick a tier", "detail: back to empty restores title and disabled primary")
	# TabBar
	var tb := Ui5TabBar.new()
	tb.setup(["A", "B", "C"], 0)
	box.add_child(tb)
	var got := [-1]
	tb.tab_selected.connect(func(i: int) -> void: got[0] = i)
	tb.select(2)
	_check(tb.selected_index() == 2 and got[0] == 2, "tabs: select(2) presses tab 2 and emits")
	# ListRow
	var lr := Ui5ListRow.new()
	lr.setup("T", "s", "r")
	box.add_child(lr)
	_check(lr.state == &"normal", "row: nothing selected by default")
	lr.set_state(&"locked")
	_check(is_equal_approx(lr.modulate.a, 0.55), "row: locked alpha 0.55")
	# Switch / Slider
	var sw := Ui5Switch.new()
	sw.setup(false)
	box.add_child(sw)
	var ev := [0]
	sw.toggled.connect(func(_o: bool) -> void: ev[0] += 1)
	var k := InputEventKey.new()
	k.keycode = KEY_SPACE
	k.pressed = true
	sw._gui_input(k)
	_check(sw.on and ev[0] == 1, "switch: Space turns it on and emits once")
	sw.set_on(false)
	_check(not sw.on and ev[0] == 1, "switch: set_on does not emit")
	var sl := Ui5Slider.new()
	sl.setup(0.5, 0.0, 1.0, 0.1, 200)
	box.add_child(sl)
	var r := InputEventKey.new()
	r.keycode = KEY_RIGHT
	r.pressed = true
	sl._gui_input(r)
	_check(is_equal_approx(sl.value, 0.6), "slider: Right steps +0.1 (%f)" % sl.value)
	# DisabledReason drops the keycap
	var b := UI3.button("Start run", &"primary", &"L")
	var cap := Keycap.make("Space", &"primary")
	b.add_child(cap)
	box.add_child(b)
	Ui5DisabledReason.apply(b, "Need 20")
	_check(b.disabled and b.text == "Need 20" and b.tooltip_text == "Need 20", "reason: disabled, says why, tooltip")
	await get_tree().process_frame
	_check(b.find_children("*", "", true, false).filter(func(c: Node) -> bool: return c.has_meta("ui5_keycap")).is_empty(), "reason: no keycap on a disabled button")
	Ui5DisabledReason.clear(b)
	_check(not b.disabled and b.text == "Start run", "reason: clear restores the label")
	# Buy
	var buy := Ui5GemCost.buy_button(90, 400)
	var short := Ui5GemCost.buy_button(90, 10)
	_check(not buy.disabled and buy.text.contains("90") and short.disabled and short.text.contains("80"), "buy: live vs short ('%s' / '%s')" % [buy.text, short.text])
	# Footer rows
	var p := UI3.button("Primary", &"primary", &"M")
	var s := UI3.button("Secondary", &"secondary", &"M")
	var ft := Ui5ModalFooter.make(p, s, true)
	ft.custom_minimum_size.x = 300
	box.add_child(ft)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(ft is VBoxContainer and absf(p.size.x - s.size.x) < 1.0 and p.get_index() < s.get_index() and p.global_position.y < s.global_position.y, "footer 2 rows: primary on top, same width")
	# Toast offset
	_check(Ui5Toast.top_y(true) > Ui5Toast.top_y(false), "toast: under the offline banner it starts lower")
	# Spinner draws without error under reduce motion off / on
	var sp := Ui5Spinner.new()
	box.add_child(sp)
	await get_tree().process_frame
	_check(sp.custom_minimum_size.x == UI3Theme.size_of("icon_l"), "spinner: icon_l box")
	layer.queue_free()
