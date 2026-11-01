class_name GachaFx
extends Control
## Gacha moments that are not the card flip: A5 bet spin (Dim Stone), and the base node of the combo band
## (`ComboBand.build` makes a GachaFx named "ComboBanner"; click / Space / skip() dismiss it).
## UI only. The result is always decided before this runs; nothing here reads rng or changes state.
## Click / Space / Enter skips a spin to its result. The banner node is dismissed by a click (consumed) and carries no spin label.

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
## card_rect (global): when given, the plate sits ON the picked card, so the other cards stay visible.
func start_spin(pool: Array, final: String, accent: Color, card_rect := Rect2()) -> void:
	z_index = 50   # UI3 card panels use z_index 6; without this the plate drew behind the cards
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_frame = PanelContainer.new()
	_frame.name = "SpinPlate"
	_frame.custom_minimum_size = Vector2(640, 200)
	var on_card := card_rect.size.x > 0.0
	if on_card:
		_frame.custom_minimum_size = card_rect.size
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
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_label)
	if on_card:
		cc.queue_free()
		add_child(_frame)
		_frame.global_position = card_rect.position
		_frame.size = card_rect.size
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
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
	_pop(1.0 + 0.1 * float(i) / 16.0, 0.12)


## Slot-reel feel: each name pops in; the last one lands bigger. No pop with reduce flashing.
func _pop(amount: float, sec: float) -> void:
	if MetaState.reduce_flash or UI3Motion.reduced() or _label == null:
		return
	_label.pivot_offset = _label.size / 2.0
	_label.scale = Vector2.ONE * amount
	create_tween().tween_property(_label, "scale", Vector2.ONE, sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stop() -> void:
	if _label == null:
		return
	_label.text = _final
	_pop(1.3, 0.35)
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
	if name == "ComboBanner":   # a banner has no spin label: skipping it is the same as a click (emit + free)
		_banner_end()
		return
	if _label != null:
		_label.text = _final
	_done()


func _input(ev: InputEvent) -> void:
	if not running:
		return
	if name == "ComboBanner":   # a click / Space dismisses it (and is consumed: nothing below it reacts)
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
				and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE])):
			get_viewport().set_input_as_handled()
			_banner_end()
		return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
			and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		get_viewport().set_input_as_handled()
		skip()


func _banner_end() -> void:
	if not running:
		return
	running = false
	finished.emit()
	queue_free()
