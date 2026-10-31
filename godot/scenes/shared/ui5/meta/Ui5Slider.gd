class_name Ui5Slider
extends Control
## UI-05 Slider (meta1 .slider): width 200, track hp_bar_h high on `hp_track`, fill `accent`, both fully rounded, NO knob. The
## clickable box is invisible and >= hit_min high. Drag / click sets the value, Left / Right step it. Signal value_changed(v);
## set_value() is silent.

signal value_changed(v: float)

var min_value := 0.0
var max_value := 1.0
var step := 0.05
var value := 0.0
var _drag := false


func setup(v: float, lo := 0.0, hi := 1.0, stp := 0.05, width := 200) -> void:
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
	custom_minimum_size.y = UI3Theme.size_of("hit_min")
	queue_redraw()


func track_height() -> int:
	return UI3Theme.size_of("hp_bar_h")


func set_value(v: float) -> void:
	value = clampf(v, min_value, max_value)
	queue_redraw()


func _set_from_x(x: float) -> void:
	var f := clampf(x / maxf(size.x, 1.0), 0.0, 1.0)
	var v := clampf(snappedf(min_value + f * (max_value - min_value), step), min_value, max_value)
	if not is_equal_approx(v, value):
		value = v
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
	var th := float(track_height())
	var track := Rect2(0, (size.y - th) * 0.5, size.x, th)
	var sb := UI3Theme.flat(UI3Theme.color("hp_track"), UI3Theme.radius("pill"))
	sb.anti_aliasing = true
	draw_style_box(sb, track)
	var f := 0.0 if is_equal_approx(max_value, min_value) else (value - min_value) / (max_value - min_value)
	if f > 0.0:
		var fill := UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("pill"))
		fill.anti_aliasing = true
		draw_style_box(fill, Rect2(track.position, Vector2(maxf(track.size.x * f, th), th)))
	if has_focus():
		draw_style_box(UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("pill") + 4, UI3Theme.stroke("focus"),
			UI3Theme.color("focus_ring")), track.grow(UI3Theme.stroke("focus_gap")))
