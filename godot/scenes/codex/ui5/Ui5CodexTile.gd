class_name Ui5CodexTile
extends PanelContainer
## Pressable plate for the Codex (book tile, search hit). `pressable` makes it focusable (Space / Enter / click emit
## `activated`). `selected` draws a 3 px selected ring; `inset_ring` (alpha > 0) draws an inset ring (Full combo).
signal activated

var pressable := false: set = _set_pressable
var selected := false: set = _set_selected
var inset_ring := Color(0, 0, 0, 0)


func _set_pressable(v: bool) -> void:
	pressable = v
	focus_mode = Control.FOCUS_ALL if v else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if v else Control.CURSOR_ARROW


func _set_selected(v: bool) -> void:
	selected = v
	queue_redraw()


func _ready() -> void:
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _gui_input(ev: InputEvent) -> void:
	if not pressable:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		activated.emit()
		accept_event()
	elif ev.is_action_pressed(&"ui_accept"):
		activated.emit()
		accept_event()


func _draw() -> void:
	var rad := UI3Theme.radius("m")
	var r := Rect2(Vector2.ZERO, size)
	if inset_ring.a > 0.0:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_border_width_all(3)
		sb.border_color = inset_ring
		sb.set_corner_radius_all(rad)
		draw_style_box(sb, r)
	if selected:
		draw_style_box(PanelParts.ring_style(UI3Theme.color("selected"), 3, 0, rad), r)
	if has_focus():
		draw_style_box(PanelParts.ring_style(UI3Theme.color("focus_ring"), UI3Theme.stroke("focus"), UI3Theme.stroke("focus_gap"), rad), r)


const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
