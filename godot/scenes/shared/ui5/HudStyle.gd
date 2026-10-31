class_name Ui5HudStyle
extends RefCounted
## UI-05 batch 1, lane A: style A boxes for the combat HUD shell (RunInfo, ActionDock, AidZone, StatusChip,
## WaitingPill, SkipHint). Every number comes from tokens_ui3.json through UI3Theme; nothing here is a magic
## px value. Source: design/handoffs/ui-05-figma/round-1/ui05-combat-screens.html (CSS .plate, .chip, .btn,
## .keycap, .cost, .on-view) and README "Style A".
##
## The plate lip is a hard shadow (shadow_offset (0, lip), size 1 = unblurred), the bevel is the 2 px
## plate_rim border (stroke.rim). Style A has no outer ink outline (stroke.ink 0).


## tokens.shadow.<key> as an int (lip 6, lip_l 8, lip_pressed 2).
static func lip(key := "lip") -> int:
	return int((UI3Theme.tokens().get("shadow", {}) as Dictionary).get(key, 6))


## Hard shadow dict for UI3Theme.flat from a tokens.shadow entry ({x, y, color}).
static func shadow_of(key: String) -> Dictionary:
	var sh: Variant = (UI3Theme.tokens().get("shadow", {}) as Dictionary).get(key)
	if sh is Dictionary:
		return {"y": int((sh as Dictionary).get("y", 0)), "color": UI3Theme.hex(String((sh as Dictionary).get("color", "#000000")))}
	return {}


## `.plate`: walnut fill, 2 px plate_rim bevel, hard plate_ink lip under it.
static func plate_box(radius_px: int, pad := Vector4.ZERO, lip_px := -1, fill := "plate") -> StyleBoxFlat:
	var ly := lip() if lip_px < 0 else lip_px
	var shadow := {"y": ly, "color": UI3Theme.color("plate_ink")} if ly > 0 else {}
	return UI3Theme.flat(UI3Theme.color(fill), radius_px, UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"), pad, shadow)


## Button look built on the plate: normal / hover (plate_raised) / pressed (lip 2, box drops) / disabled /
## focus (sky ring, 4 px gap). Applied as overrides so a plain Button reads as a round wood plate.
static func plate_button(b: Button, radius_px: int, pad := Vector4.ZERO) -> void:
	var normal := plate_box(radius_px, pad)
	var hover := plate_box(radius_px, pad, -1, "plate_raised")
	var pressed := plate_box(radius_px, pad, lip("lip_pressed"), "plate_raised")
	var shift := maxi(lip() - lip("lip_pressed"), 0)
	pressed.expand_margin_top = -shift
	pressed.expand_margin_bottom = shift
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal.duplicate())
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(radius_px))


## `.chip`: the inset chip on a plate (A-level, Turn, Shard): chip fill, pill, 0 12 padding, chip_h high.
static func chip(chip_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = chip_name
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("12"), 0, UI3Theme.space("12"), 0)))
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("chip_h"))
	return p


## `.on-view`: text straight on the 3D view, text_on_viewport with a hard 2 px text_shadow drop.
static func on_view(l: Label) -> void:
	l.add_theme_color_override("font_color", UI3Theme.color("text_on_viewport"))
	l.add_theme_color_override("font_shadow_color", UI3Theme.color("text_shadow"))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 0)


## `.on-view` on a chip (B4, QA 29/10): the bare cream text could not be read on the snow and desert biomes, so the
## label also draws a small `chip` pill behind its text (padding space_8 / space_4). The label is SHRINK_CENTER in
## its box so the pill hugs the word; sync_view_chip() drops the pill while the text is empty.
static func on_view_chip(l: Label) -> void:
	on_view(l)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.set_meta("ui5_view_chip", true)
	sync_view_chip(l)


## The pill behind an on_view_chip label: drawn only while there is text.
static func sync_view_chip(l: Label) -> void:
	if l.text.strip_edges() == "":
		if not (l.get_theme_stylebox("normal") is StyleBoxEmpty):
			var e := StyleBoxEmpty.new()   # same padding as the pill: the line keeps its height, nothing jumps
			e.content_margin_top = UI3Theme.space("4")
			e.content_margin_bottom = UI3Theme.space("4")
			l.add_theme_stylebox_override("normal", e)
		return
	var cur := l.get_theme_stylebox("normal")
	if cur != null and cur.has_meta("ui5_view_chip"):
		return
	var sb := UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("8"), UI3Theme.space("4")))
	sb.set_meta("ui5_view_chip", true)
	l.add_theme_stylebox_override("normal", sb)


## Horizontal room the view chip adds around the text (0 for a plain label).
static func view_chip_pad_x(l: Label) -> float:
	return float(UI3Theme.space("8")) * 2.0 if l.has_meta("ui5_view_chip") else 0.0


## Square icon, `px` from a size token, centred.
static func icon_rect(tex: Texture2D, px: int) -> TextureRect:
	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = tex
	ic.custom_minimum_size = Vector2(px, px)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


## `.cost`: CostChip, keycap_h high, pill, icon_s glyph + Rowdies body number.
## kind &"mana": chip fill, mana text. &"gem": gem_bg, 2 px gem_border, gem_text.
static func cost_chip(kind: StringName, amount: int) -> PanelContainer:
	var gem := kind == &"gem"
	var p := PanelContainer.new()
	p.name = "CostChip"
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("gem_bg" if gem else "chip"),
		UI3Theme.radius("pill"), UI3Theme.stroke("hairline") if gem else 0, UI3Theme.color("gem_border"),
		Vector4(UI3Theme.space("8"), 0, UI3Theme.space("8"), 0)))
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(row)
	row.add_child(icon_rect(UI3.currency_icon("cur_gem", UI3Theme.size_of("icon_s")) if gem else HudKit.icon("mana"),
		UI3Theme.size_of("icon_s")))
	var l := UI3.label(str(amount), "LabelDisplay")
	l.name = "Amount"
	l.add_theme_color_override("font_color", UI3Theme.color("gem_text" if gem else "mana"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return p


static func set_cost(chip_node: PanelContainer, amount: int) -> void:
	var l := chip_node.find_child("Amount", true, false) as Label
	if l != null:
		l.text = str(amount)


## Trailing chip (CostChip / KeyCap) after a button's centred text, so [icon] text [chip] reads as one centred group
## with a space_12 gap (CSS .btn gap). `pad` is the button's side padding. Two steps, both safe to call often:
## `reserve_trailing` widens the right content margin (so the button's minimum width counts the chip), and
## `place_trailing` positions the chip once the button has its size. Both need the button in the tree.
static func reserve_trailing(b: Button, trailing: Control, pad: int) -> void:
	if trailing == null or not trailing.visible:
		_set_side_margins(b, pad, pad)
		return
	trailing.size = Vector2.ZERO
	_set_side_margins(b, pad, pad + UI3Theme.space("12") + int(ceilf(trailing.get_combined_minimum_size().x)))


static func place_trailing(b: Button, trailing: Control, pad: int) -> void:
	reserve_trailing(b, trailing, pad)
	if trailing == null or not trailing.visible:
		return
	var gap := UI3Theme.space("12")
	var tw := trailing.get_combined_minimum_size()
	var font := b.get_theme_font("font")
	var fs := b.get_theme_font_size("font_size")
	var text_w := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if font != null else 0.0
	var icon_w := 0.0
	if b.icon != null:
		icon_w = float(b.get_theme_constant("icon_max_width")) + float(b.get_theme_constant("h_separation"))
	var group := icon_w + text_w
	var sb := b.get_theme_stylebox("normal")
	var content_centre := (sb.content_margin_left + b.size.x - sb.content_margin_right) * 0.5
	trailing.position = Vector2(content_centre + group * 0.5 + gap, (b.size.y - tw.y) * 0.5)
	trailing.size = tw


static func _set_side_margins(b: Button, left: int, right: int) -> void:
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
		var base: StyleBox = b.get_theme_stylebox(st)
		if base == null:
			continue
		if is_equal_approx(base.content_margin_left, left) and is_equal_approx(base.content_margin_right, right):
			continue
		var sb: StyleBox = base.duplicate()
		sb.content_margin_left = left
		sb.content_margin_right = right
		b.add_theme_stylebox_override(st, sb)
