class_name Ui5Switch
extends Control
## UI-05 Switch (Settings): track keycap_h high and 1.8x wide, knob = track height minus 2 x 3, On = toggle_on green, Off =
## plate_raised. keycap_h is the token that shrinks at 1280, so the switch scales with it. Hit box >= hit_min. Space / Enter
## toggle, focus ring when focused. Signal toggled(on). set_on() does not emit.

signal toggled(on: bool)

var on := false


func setup(value: bool) -> void:
	name = "Switch"
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	on = value
	refresh()


func track_size() -> Vector2:
	var h := UI3Theme.size_of("keycap_h")
	return Vector2(int(round(h * 1.8)), h)


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
	var o := (size - t) * 0.5
	var rect := Rect2(o, t)
	var sb := UI3Theme.flat(Ui5MetaTok.col("toggle_on", "#7ade61") if on else UI3Theme.color("plate_raised"),
		UI3Theme.radius("pill"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"))
	sb.anti_aliasing = true
	draw_style_box(sb, rect)
	var pad := float(UI3Theme.stroke("btn"))
	var d := t.y - 2.0 * pad
	var kx := rect.end.x - pad - d * 0.5 if on else rect.position.x + pad + d * 0.5
	draw_circle(Vector2(kx, rect.get_center().y), d * 0.5, UI3Theme.color("text"))
	if has_focus():
		draw_style_box(UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("pill") + 4, UI3Theme.stroke("focus"),
			UI3Theme.color("focus_ring")), rect.grow(UI3Theme.stroke("focus_gap")))
