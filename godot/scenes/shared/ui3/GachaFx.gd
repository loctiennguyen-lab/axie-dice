class_name GachaFx
extends Control
## Gacha moments that are not the card flip: A5 bet spin (Dim Stone) and the combo banner (Pair / Full).
## UI only. The result is always decided before this runs; nothing here reads rng or changes state.
## Click / Space / Enter skips a spin to its result. The banner is click-through (a click only dismisses it).

signal finished

var events: Array[String] = []
var running := false
var _label: Label
var _frame: PanelContainer
var _names: Array = []
var _final := ""
var _tween: Tween


## Pure: `ticks` intervals that add up to `total`, short first, long last (the wheel slows down).
static func spin_schedule(total: float, ticks: int) -> Array[float]:
	var w: Array[float] = []
	var sum := 0.0
	for i in ticks:
		var x := float(i + 1) / float(ticks)
		w.append(0.4 + x * x * 3.6)
		sum += w[i]
	var out: Array[float] = []
	for i in ticks:
		out.append(total * w[i] / sum)
	return out


## Pure: names shown on each tick. Cycles through `pool`, never ends on anything but `final`.
static func spin_faces(pool: Array, final: String, ticks: int) -> Array[String]:
	var out: Array[String] = []
	var others: Array = pool.filter(func(n): return n != final)
	for i in ticks - 1:
		out.append(String(others[i % others.size()]) if not others.is_empty() else final)
	out.append(final)
	return out


## Builds the spin plate centred on the screen and runs it. pool: real Crystal Core names; final: the granted Core.
func start_spin(pool: Array, final: String, accent: Color) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_frame = PanelContainer.new()
	_frame.name = "SpinPlate"
	_frame.custom_minimum_size = Vector2(640, 200)
	_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected"), accent))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	_frame.add_child(v)
	var cap := UI3.label(tr("Rolling a Crystal Core"), "LabelMuted")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	_label = UI3.label("", "LabelScreenTitle")
	_label.name = "SpinName"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_label)
	cc.add_child(_frame)
	_final = final
	var t := UI3Gacha.timing()
	var ticks := 16
	var faces := spin_faces(pool, final, ticks)
	_names = faces
	if UI3Gacha.is_instant():
		events.append("instant")
		_label.text = final
		_done()
		return
	running = true
	events.append("spin")
	var sched := spin_schedule(float(t.get("spin_sec", 2.0)), ticks)
	_tween = create_tween()
	for i in ticks:
		_tween.tween_callback(_tick.bind(i))
		_tween.tween_interval(sched[i])
	_tween.tween_callback(_stop)
	_tween.tween_interval(float(t.get("spin_hold_sec", 0.6)))
	_tween.tween_callback(_done)


func _tick(i: int) -> void:
	_label.text = String(_names[i])
	events.append("tick:%d" % i)


func _stop() -> void:
	_label.text = _final
	events.append("stop")
	UI3Gacha.play_sfx(self, "spin_stop")


func _done() -> void:
	running = false
	finished.emit()


func skip() -> void:
	if not running:
		return
	events.append("skip")
	if _tween != null:
		_tween.kill()
	_label.text = _final
	_done()


func _input(ev: InputEvent) -> void:
	if not running:
		return
	if name == "ComboBanner":   # click-through: a click only dismisses it
		if ev is InputEventMouseButton and ev.pressed:
			_banner_end()
		return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
			and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		get_viewport().set_input_as_handled()
		skip()


## Combo banner at the top of the screen: "PAIR: <name>" 1.2 s, "FULL: <name>" 1.8 s with a gold frame.
## Click-through; a click removes it early. Returns the node (already added to `parent`).
static func banner(parent: Node, tier: String, combo_name: String) -> Control:
	var full := tier == "full"
	var root := GachaFx.new()
	root.name = "ComboBanner"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := CenterContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 96
	top.offset_bottom = 224
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var plate := PanelContainer.new()
	plate.name = "BannerPlate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gold := UI3Theme.color("rarity_legendary")
	plate.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected") * (2 if full else 1), gold if full else UI3Theme.color("text")))
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(m)
	var l := UI3.label("%s %s" % [TranslationServer.translate("FULL!" if full else "PAIR!"), combo_name], "LabelScreenTitle")
	l.name = "BannerText"
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", gold if full else UI3Theme.color("text"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(l)
	top.add_child(plate)
	parent.add_child(root)
	root.set_meta("tier", tier)
	UI3Gacha.play_sfx(root, "full" if full else "pair")
	var secs := float(UI3Gacha.timing().get("banner_full_sec" if full else "banner_pair_sec", 1.2))
	if UI3Gacha.is_instant():
		return root
	root.running = true
	var tw := root.create_tween()
	tw.tween_interval(secs)
	tw.tween_callback(root._banner_end)
	return root


func _banner_end() -> void:
	running = false
	queue_free()
