class_name Ui5Spinner
extends Control
## UI-05 Spinner (meta1 .spinner): icon_l square, 4 px ring in `plate_rim` with the top quarter in `accent`, turning once a
## second. Reduce motion (MetaState.reduce_motion) = still. Does not redraw while hidden.

const STROKE := 4.0
var _angle := 0.0


func _ready() -> void:
	name = "Spinner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d := UI3Theme.size_of("icon_l")
	custom_minimum_size = Vector2(d, d)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _process(dt: float) -> void:
	if UI3Motion.reduced() or not is_visible_in_tree():
		return
	_angle = fmod(_angle + dt * TAU, TAU)
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5 - STROKE * 0.5
	var c := size * 0.5
	draw_arc(c, r, 0.0, TAU, 48, UI3Theme.color("plate_rim"), STROKE, true)
	var top := -PI * 0.5 + _angle
	draw_arc(c, r, top - PI * 0.25, top + PI * 0.25, 16, UI3Theme.color("accent"), STROKE, true)
