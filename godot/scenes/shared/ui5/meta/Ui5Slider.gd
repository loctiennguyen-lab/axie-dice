class_name Ui5Slider
extends Control
## UI-05 Slider (Settings volume): track keycap_h / 2 high, knob keycap_h round, fill = accent. value in [min_value, max_value]
## snapped to `step`. Drag or click sets it, Left / Right arrows step it. Signal value_changed(v). set_value() does not emit.

signal value_changed(v: float)

var min_value := 0.0
var max_value := 1.0
var step := 0.05
var value := 0.0
var _drag := false


func setup(v: float, lo := 0.0, hi := 1.0, stp := 0.05, width := 240) -> void:
	name = "Slider"
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	min_value = lo
	max_value = hi
	step = stp
	value = clampf(v, lo, hi)
	custom_minimum_size.x = width
	refresh()


func refresh() -> void:
	custom_minimum_size.y = maxf(UI3Theme.size_of("keycap_h"), UI3Theme.size_of("hit_min"))
	queue_redraw()


func set_value(v: float) -> void:
	value = clampf(v, min_value, max_value)
	queue_redraw()


func _set_from_x(x: float) -> void:
	var r := UI3Theme.size_of("keycap_h") * 0.5
	var f := clampf((x - r) / maxf(size.x - 2.0 * r, 1.0), 0.0, 1.0)
	var v := snappedf(min_value + f * (max_value - min_value), step)
	if not is_equal_approx(v, value):
		value = clampf(v, min_value, max_value)
		queue_redraw()
		value_changed.emit(value)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_drag = e.pressed
		if e.pressed:
			_set_from_x(e.position.x)
	elif e is InputEventMouseMotion and _drag:
		_set_from_x(e.position.x)
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_LEFT or e.keycode == KEY_RIGHT):
		var nv := clampf(value + (step if e.keycode == KEY_RIGHT else -step), min_value, max_value)
		if not is_equal_approx(nv, value):
			value = nv
			queue_redraw()
			value_changed.emit(value)
		accept_event()


func _draw() -> void:
	var kh := float(UI3Theme.size_of("keycap_h"))
	var th := kh * 0.5
	var r := kh * 0.5
	var cy := size.y * 0.5
	var track := Rect2(r, cy - th * 0.5, size.x - 2.0 * r, th)
	var sb := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("pill"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"))
	sb.anti_aliasing = true
	draw_style_box(sb, track)
	var f := 0.0 if is_equal_approx(max_value, min_value) else (value - min_value) / (max_value - min_value)
	var kx := track.position.x + f * track.size.x
	if kx > track.position.x:
		var fill := UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("pill"))
		fill.anti_aliasing = true
		draw_style_box(fill, Rect2(track.position, Vector2(kx - track.position.x, th)))
	draw_circle(Vector2(kx, cy), r, UI3Theme.color("plate_ink"))
	draw_circle(Vector2(kx, cy), r - float(UI3Theme.stroke("btn")), UI3Theme.color("text"))
	if has_focus():
		draw_arc(Vector2(kx, cy), r + UI3Theme.stroke("focus_gap"), 0.0, TAU, 32, UI3Theme.color("focus_ring"), UI3Theme.stroke("focus"), true)
