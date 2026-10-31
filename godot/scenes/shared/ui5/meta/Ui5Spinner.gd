class_name Ui5Spinner
extends Control
## UI-05 Spinner ("Loading…", reconnecting): a 3/4 ring, icon_m big, accent colour, turning once a second. Reduce motion
## (MetaState.reduce_motion) = a still ring. Stops drawing when hidden.

var _angle := 0.0


func _ready() -> void:
	name = "Spinner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d := UI3Theme.size_of("icon_m")
	custom_minimum_size = Vector2(d, d)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _process(dt: float) -> void:
	if UI3Motion.reduced() or not is_visible_in_tree():
		return
	_angle = fmod(_angle + dt * TAU, TAU)
	queue_redraw()


func _draw() -> void:
	var w := float(UI3Theme.stroke("btn"))
	var r := minf(size.x, size.y) * 0.5 - w
	draw_arc(size * 0.5, r, 0.0, TAU, 32, UI3Theme.color("plate_rim"), w, true)
	draw_arc(size * 0.5, r, _angle, _angle + TAU * 0.75, 32, UI3Theme.color("accent"), w, true)
