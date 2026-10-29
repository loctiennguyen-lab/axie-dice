extends RefCounted
## UI-05 rule (Liam 29/10): text under or beside an icon is centred on the icon. Walks a subtree and, in every visible
## BoxContainer, pairs each icon child (a TextureRect / ActionGlyph, or a child whose only drawn content is one) with each
## Label child: in an HBox the label's text line is centred vertically on the icon, in a VBox the text is centred
## horizontally on the icon. The text box is measured (alignment + font size), not the Label rect. Returns the
## problems as readable strings; empty = every pair is within `tol` px.


static func check(root: Node, tol := 1.5, tag := "") -> Array[String]:
	var out: Array[String] = []
	_walk(root, tol, tag, out)
	return out


## How many icon / label pairs were measured under `root` (a check that measured nothing proves nothing).
static func pairs(root: Node) -> int:
	var n := [0]
	_count(root, n)
	return n[0]


static func _count(n: Node, acc: Array) -> void:
	if n is BoxContainer and (n as Control).is_visible_in_tree():
		var icons := 0
		var labels := 0
		for c in n.get_children():
			if c is Control and (c as Control).is_visible_in_tree():
				if _icon_of(c) != null:
					icons += 1
				elif c is Label and (c as Label).text.strip_edges() != "":
					labels += 1
		acc[0] += icons * labels
	for c in n.get_children():
		_count(c, acc)


static func _walk(n: Node, tol: float, tag: String, out: Array[String]) -> void:
	if n is BoxContainer and (n as Control).is_visible_in_tree():
		var box := n as BoxContainer
		var icons: Array[Control] = []
		var labels: Array[Label] = []
		for c in box.get_children():
			if not (c is Control) or not (c as Control).is_visible_in_tree():
				continue
			var ic := _icon_of(c)
			if ic != null:
				icons.append(ic)
			elif c is Label and (c as Label).text.strip_edges() != "":
				labels.append(c)
		for ic in icons:
			var ir := ic.get_global_rect()
			if ir.size.x <= 0.0 or ir.size.y <= 0.0:
				continue
			for l in labels:
				var tc := text_center(l)
				var d := absf(tc.y - ir.get_center().y) if box is HBoxContainer else absf(tc.x - ir.get_center().x)
				if OS.get_environment("AXIE_ALIGN_DEBUG") != "":
					print("ALIGN %s%s: '%s' / %s d=%.2f" % [tag, box.name, l.text.left(20), ic.name, d])
				if d > tol:
					out.append("%s%s: '%s' is %.1f px off the centre of icon %s (%s)" % [tag, box.get_path(), l.text.left(24), d,
						ic.name, "vertical" if box is HBoxContainer else "horizontal"])
	for c in n.get_children():
		_walk(c, tol, tag, out)


## The icon a box child stands for: itself (TextureRect / ActionGlyph), or the one icon drawn inside a child that
## draws no text (a Button holding a glyph, a holder around a TextureRect).
static func _icon_of(c: Node) -> Control:
	if c is TextureRect and (c as TextureRect).texture != null:
		return c
	if c.get_class() == "Control" and c.get_script() != null and String(c.get_script().get_global_name()) == "ActionGlyph":
		return c
	if c is Label or c is Container and not (c is PanelContainer) and not (c is Button):
		return null
	var found: Control = null
	for d in c.find_children("*", "", true, false):
		if d is Label and (d as Label).is_visible_in_tree() and (d as Label).text.strip_edges() != "":
			return null
		if found == null and d is Control and (d as Control).is_visible_in_tree() and (
				(d is TextureRect and (d as TextureRect).texture != null) or
				(d.get_script() != null and String(d.get_script().get_global_name()) == "ActionGlyph")):
			found = d
	if c is Button and (c as Button).text != "" and found == null:
		return null
	return found


## Centre of the drawn text line(s) of a Label in global coordinates.
static func text_center(l: Label) -> Vector2:
	var r := l.get_global_rect()
	var f := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var w := f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if f != null else r.size.x
	w = minf(w, r.size.x)
	var h := float(l.get_line_height()) * maxf(1.0, float(l.get_visible_line_count()))
	h = minf(h, r.size.y)
	var x := r.get_center().x
	match l.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			x = r.position.x + w * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			x = r.end.x - w * 0.5
	var y := r.get_center().y
	match l.vertical_alignment:
		VERTICAL_ALIGNMENT_TOP:
			y = r.position.y + h * 0.5
		VERTICAL_ALIGNMENT_BOTTOM:
			y = r.end.y - h * 0.5
	return Vector2(x, y)
