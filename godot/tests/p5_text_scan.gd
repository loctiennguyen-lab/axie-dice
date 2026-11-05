extends RefCounted
## Real-px text scan (p5-ui): every visible text control under `root` whose font is smaller than `floor_px` real px
## at layout scale `sc` (canvas is logical 1920). Covers Label, Button, LinkButton, LineEdit and RichTextLabel
## (normal / bold / italics / mono), which the older per-screen scans skipped.
## Returns "path 'text' 13.3px" strings, empty when everything reads.


static func small(root: Node, sc: float, floor_px := 14.0) -> Array[String]:
	var out: Array[String] = []
	_walk(root, sc, floor_px, out)
	return out


static func _walk(n: Node, sc: float, floor_px: float, out: Array[String]) -> void:
	var c := n as Control
	if c != null:
		sc *= (c.scale.x + c.scale.y) * 0.5   # a tween-scaled card shrinks its text too
	if c != null and not c.is_visible_in_tree():
		return
	if c is RichTextLabel:
		var r := c as RichTextLabel
		if r.get_parsed_text().strip_edges() != "":
			for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
				var px := float(r.get_theme_font_size(k)) * sc
				if px < floor_px - 0.01:
					out.append("%s '%s' %s=%.1fpx" % [r.get_path(), r.get_parsed_text().left(24), k, px])
					break
	elif c is Label or c is Button or c is LineEdit:
		var t: String = (c as Label).text if c is Label else ((c as Button).text if c is Button else (c as LineEdit).text)
		if t.strip_edges() != "" and not (c.get_theme_color("font_color").a < 0.01 and c is Button):
			var px := float(c.get_theme_font_size("font_size")) * sc
			if px < floor_px - 0.01:
				out.append("%s '%s' %.1fpx" % [c.get_path(), t.left(24), px])
	for ch in n.get_children():
		_walk(ch, sc, floor_px, out)
