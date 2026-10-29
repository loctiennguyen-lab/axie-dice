extends RefCounted
## QA-only helpers for the UI-05 b1 QA scenes (qa_ui5_flow_capture, qa_ui5_resize_capture, qa_ui5_pin):
## screenshot naming + a text-clip audit over every visible Label / Button on screen.
## preload()ed, no class_name (nothing to register before a run).


## Output dir: UI5_SHOT_DIR, else production/qa/ui05-b1/qa/shots.
static func out_dir() -> String:
	var d := OS.get_environment("UI5_SHOT_DIR")
	if d == "":
		d = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/qa/shots").simplify_path()
	DirAccess.make_dir_recursive_absolute(d)
	return d


static func save(vp: Viewport, name: String) -> String:
	var sz := Vector2(vp.get_window().size) if vp.get_window() != null else vp.get_visible_rect().size
	var path := "%s/%s-%dx%d.png" % [out_dir(), name, int(sz.x), int(sz.y)]
	vp.get_texture().get_image().save_png(path)
	print("QA_SHOT %s" % path)
	return path


## Every visible Label / Button whose single-line text is wider than its box (clip_text / overrun on), or that sits
## partly outside the window. Returns lines "<kind> <node path> '<text>' need=<w> have=<w>".
static func clip_audit(root: Node, vp_rect: Rect2) -> Array[String]:
	var out: Array[String] = []
	_walk(root, vp_rect, out)
	return out


static func _walk(n: Node, vp: Rect2, out: Array[String]) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label:
		_check_label(n as Label, vp, out)
	elif n is Button:
		_check_button(n as Button, vp, out)
	for c in n.get_children():
		_walk(c, vp, out)


static func _text_w(c: Control, text: String, font_name := "font", size_name := "font_size") -> float:
	var f := c.get_theme_font(font_name)
	if f == null:
		return 0.0
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size(size_name)).x


static func _check_label(l: Label, vp: Rect2, out: Array[String]) -> void:
	var t := l.text.strip_edges()
	if t == "" or l.modulate.a < 0.05:
		return
	var gr := l.get_global_rect()
	var scale := l.get_global_transform_with_canvas().get_scale().x
	if l.autowrap_mode == TextServer.AUTOWRAP_OFF and not t.contains("\n"):
		var need := _text_w(l, l.text)
		if need > l.size.x + 1.5 and (l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
			out.append("CLIP label %s '%s' need=%.0f have=%.0f" % [l.get_path(), t.left(40), need, l.size.x])
	var screen := Rect2(l.get_global_transform_with_canvas().origin, l.size * scale)
	if l.get_viewport() != null and not l.get_viewport().get_visible_rect().encloses(screen.grow(-2.0)) and screen.size.x > 2:
		out.append("OFFSCREEN label %s '%s' rect=%s" % [l.get_path(), t.left(40), str(screen)])
	if l.get_visible_line_count() < l.get_line_count() and l.max_lines_visible < 0 and l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		out.append("CLIP_LINES label %s '%s' lines=%d visible=%d" % [l.get_path(), t.left(40), l.get_line_count(), l.get_visible_line_count()])
	var _unused := gr


static func _check_button(b: Button, vp: Rect2, out: Array[String]) -> void:
	var t := b.text.strip_edges()
	if t == "":
		return
	var need := _text_w(b, b.text)
	var pad := 0.0
	var sb := b.get_theme_stylebox("normal")
	if sb != null:
		pad = sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
	var icon_w := 0.0
	if b.icon != null and not b.expand_icon:
		icon_w = b.icon.get_width() + b.get_theme_constant("h_separation")
	if need + pad + icon_w > b.size.x + 1.5 and (b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
		out.append("CLIP button %s '%s' need=%.0f have=%.0f" % [b.get_path(), t.left(40), need + pad + icon_w, b.size.x])
	var scale := b.get_global_transform_with_canvas().get_scale().x
	var screen := Rect2(b.get_global_transform_with_canvas().origin, b.size * scale)
	if b.get_viewport() != null and not b.get_viewport().get_visible_rect().encloses(screen.grow(-2.0)) and screen.size.x > 2:
		out.append("OFFSCREEN button %s '%s' rect=%s" % [b.get_path(), t.left(40), str(screen)])
