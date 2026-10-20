class_name ActionGlyph
extends Control
## Flat glyph for the combat action tiles and the Gamble / Safe buttons (combat-v4.md 5.1b, UX review items 3-5).
## Shapes are drawn (flat polygons and lines, no gradient, no blur) so meaning never rests on colour alone.
## kinds: undo, hold (UI3 icon textures) · wild (4-point star) · overcast (bolt) · crack (cracked die = Gamble) ·
## drop (mana drop = Safe).

var kind: StringName = &"wild"
var dim := false:
	set(v):
		dim = v
		queue_redraw()


func _init(k: StringName = &"wild") -> void:
	kind = k
	name = "Glyph"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func set_kind(k: StringName) -> void:
	kind = k
	queue_redraw()


func _draw() -> void:
	var col := UI3Theme.color("text_muted" if dim else "text")
	var s := minf(size.x, size.y)
	if s <= 1.0:
		return
	var o := (size - Vector2(s, s)) * 0.5
	var u := s / 24.0
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	match kind:
		&"undo", &"hold":
			var tex := UI3.cream_icon("ui_undo" if kind == &"undo" else "ui_lock")
			if tex != null:
				draw_texture_rect(tex, Rect2(o, Vector2(s, s)), false, Color(1, 1, 1, 0.55 if dim else 1.0))
		&"wild":
			draw_colored_polygon(PackedVector2Array([p.call(12, 1), p.call(15, 9), p.call(23, 12), p.call(15, 15),
				p.call(12, 23), p.call(9, 15), p.call(1, 12), p.call(9, 9)]), col)
		&"overcast":
			draw_colored_polygon(PackedVector2Array([p.call(14, 1), p.call(5, 13), p.call(11, 13), p.call(9, 23),
				p.call(19, 10), p.call(13, 10)]), col)
		&"crack":
			var r := Rect2(o + Vector2(3, 3) * u, Vector2(18, 18) * u)
			draw_rect(r, col, false, 2.0 * u)
			draw_polyline(PackedVector2Array([p.call(13, 3), p.call(10, 10), p.call(14, 13), p.call(10, 21)]), col, 2.0 * u)
		&"drop":
			draw_circle(p.call(12, 15), 7.0 * u, col)
			draw_colored_polygon(PackedVector2Array([p.call(12, 1), p.call(5.6, 12.5), p.call(18.4, 12.5)]), col)
