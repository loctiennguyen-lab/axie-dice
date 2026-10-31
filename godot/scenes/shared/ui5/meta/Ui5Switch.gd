class_name Ui5Switch
extends Control
## UI-05 Switch (data-name "SwitchButton", meta1 .switch): keycap_h high and keycap_h x 2 wide, padding 3, knob = height - 6 in
## `text`. Off = `disabled` fill, On = `toggle_on`. keycap_h shrinks at 1280, so the switch scales with it. Hit box >= hit_min
## (the track is drawn centred in it). Space / Enter / click toggle; focus ring when focused. Signal toggled(on). set_on() is silent.

signal toggled(on: bool)

var on := false


func setup(value: bool) -> void:
	name = "SwitchButton"
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	on = value
	refresh()


func track_size() -> Vector2:
	var h := UI3Theme.size_of("keycap_h")
	return Vector2(h * 2, h)


func refresh() -> void:
	var t := track_size()
	var m := UI3Theme.size_of("hit_min")
	custom_minimum_size = Vector2(maxf(t.x, m), maxf(t.y, m))
	queue_redraw()


func set_on(v: bool) -> void:
	on = v
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or \
			(e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER)):
		on = not on
		queue_redraw()
		toggled.emit(on)
		accept_event()


func _draw() -> void:
	var t := track_size()
	var rect := Rect2((size - t) * 0.5, t)
	var sb := UI3Theme.flat(UI3Theme.color("toggle_on") if on else UI3Theme.color("disabled"), UI3Theme.radius("pill"))
	sb.anti_aliasing = true
	draw_style_box(sb, rect)
	var pad := 3.0
	var d := t.y - 2.0 * pad
	var kx := rect.end.x - pad - d * 0.5 if on else rect.position.x + pad + d * 0.5
	draw_circle(Vector2(kx, rect.get_center().y), d * 0.5, UI3Theme.color("text"))
	if has_focus():
		draw_style_box(UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("pill") + 4, UI3Theme.stroke("focus"),
			UI3Theme.color("focus_ring")), rect.grow(UI3Theme.stroke("focus_gap")))
