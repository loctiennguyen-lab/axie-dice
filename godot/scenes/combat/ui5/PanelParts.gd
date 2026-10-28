extends RefCounted
## UI-05 batch 1, lane D: small builders shared by the panels (defeat, reward pick, boss intro).
## Source: design/handoffs/ui-05-figma/round-1/ui05-combat-panels.html (CSS classes named in each comment).
## Every number is a token (UI3Theme); nothing here is a new component of UI3.gd (lane rule: helpers live in
## their own file). Use through `const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")`.


## `.plate` box: walnut fill, 2 px lighter rim, hard lip (shadow.lip) with no blur. `rad` = radius token.
static func plate_box(rad := "l", pad := 0) -> StyleBoxFlat:
	return UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius(rad), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(pad, pad, pad, pad), lip(UI3Theme.color("plate_ink")))


## `.cell`: a raised row inside a plate (plate_raised, radius m), padding v/h.
static func cell_box(pad_v: int, pad_h: int, rad := "m") -> StyleBoxFlat:
	return UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius(rad), 0, Color.TRANSPARENT,
		Vector4(pad_h, pad_v, pad_h, pad_v))


## Hard lip `{y, color}` for UI3Theme.flat: shadow.lip (6) or shadow.lip_l (8).
static func lip(col: Color, large := false) -> Dictionary:
	var sh: Dictionary = UI3Theme.tokens().get("shadow", {})
	return {"y": int(sh.get("lip_l" if large else "lip", 8 if large else 6)), "color": col}


## PanelContainer with `box` as its panel style and `node_name`.
static func panel(box: StyleBox, node_name := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", box)
	if node_name != "":
		p.name = node_name
	return p


## Label in Rowdies (`display`) or Work Sans at a size token, in a colour token.
static func text(t: String, size_token := "text_body", color_token := "text", display := false) -> Label:
	var l := UI3.label(t, "LabelDisplay" if display else "")
	l.add_theme_font_size_override("font_size", UI3Theme.size_of(size_token))
	l.add_theme_color_override("font_color", UI3Theme.color(color_token))
	return l


## `.on-view` label: text_on_viewport with a hard 2 px text_shadow drop (labels straight on the 3D view or scrim).
static func on_view(l: Label) -> Label:
	var sh: Dictionary = (UI3Theme.tokens().get("shadow", {}) as Dictionary).get("text_on_viewport", {})
	l.add_theme_color_override("font_color", UI3Theme.color("text_on_viewport"))
	l.add_theme_color_override("font_shadow_color", UI3Theme.color("text_shadow"))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", int(sh.get("y", 2)))
	l.add_theme_constant_override("shadow_outline_size", 0)
	return l


## `.btn-primary` / `.btn-secondary` at the panel sizes: primary L = 72 high, text 32; primary M = 56, text 24
## (End run when it takes over the primary); secondary = 56, text 24. The theme's M variants use text 18, so the
## design's 24 is set here from the token.
static func button(t: String, variant := &"secondary", size := &"M") -> Button:
	var b := UI3.button(t, variant, size)
	if not (variant == &"primary" and size == &"L"):
		b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	return b


## `.btn-gem` (paid surfaces only): gem_bg, 3 px gem_border bevel, gem_lip lip, Rowdies 24 gem_text, 56 high.
static func gem_button(t: String) -> Button:
	var b := UI3.button(t, &"secondary", &"M")
	var pad := UI3Theme.space("20")
	var rad := UI3Theme.radius("m")
	var bw := UI3Theme.stroke("btn")
	var normal := UI3Theme.flat(UI3Theme.color("gem_bg"), rad, bw, UI3Theme.color("gem_border"),
		Vector4(pad, 0, pad, 0), lip(UI3Theme.color("gem_lip")))
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UI3Theme.color("gem_bg").lightened(0.1)
	var pressed := normal.duplicate() as StyleBoxFlat
	var lip_px := int(normal.shadow_offset.y)
	var down := maxi(lip_px - int((UI3Theme.tokens().get("shadow", {}) as Dictionary).get("lip_pressed", 2)), 0)
	pressed.shadow_offset.y = lip_px - down
	pressed.expand_margin_top = -down
	pressed.expand_margin_bottom = down
	pressed.content_margin_top = 2 * down
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, UI3Theme.color("gem_text"))
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	return b


## `.cost` chip inside a button: 28 high pill, Rowdies 18. kind gem = gem_bg + 2 px gem_border + gem icon + amount;
## free = the word "Free" in accent on accent_text (the free revive is not a paid surface, so no violet).
static func cost_chip(kind: StringName, amount: int) -> PanelContainer:
	var gem := kind == &"gem"
	var pad := UI3Theme.space("8")
	var box := UI3Theme.flat(UI3Theme.color("gem_bg") if gem else UI3Theme.color("accent_text"), UI3Theme.radius("pill"),
		2 if gem else 0, UI3Theme.color("gem_border"), Vector4(pad, 0, pad, 0))
	var chip := panel(box, "CostChip")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	if gem:
		var ic := TextureRect.new()
		ic.name = "Icon"
		ic.texture = UI3.currency_icon("cur_gem", UI3Theme.size_of("icon_s"))
		ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_s")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
	var l := text(UI3.fmt(amount) if gem else TranslationServer.translate("Free"), "text_body",
		"gem_text" if gem else "accent", true)
	l.name = "Amount"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return chip


## `.chip` on a plate: 40 high pill (chip_h), plate_raised, optional icon (icon_m) + Rowdies 18 word in `color_token`.
static func fact_chip(word: String, color_token := "text", icon: Texture2D = null, node_name := "") -> PanelContainer:
	var pad := UI3Theme.space("12")
	var chip := panel(UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(pad, 0, pad, 0)), node_name)
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("chip_h"))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	if icon != null:
		var ic := TextureRect.new()
		ic.name = "Icon"
		ic.texture = icon
		ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
	var l := text(word, "text_body", color_token, true)
	l.name = "Text"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return chip


## Square icon of `px` (token value) for a texture; null texture = empty box of that size.
static func icon_rect(tex: Texture2D, px: int, node_name := "Icon") -> TextureRect:
	var ic := TextureRect.new()
	ic.name = node_name
	ic.texture = tex
	ic.custom_minimum_size = Vector2(px, px)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


## Ring `width` px wide drawn from `gap` to `gap + width` px outside a box of corner radius `rad_px`
## (CSS outline / spread box-shadow). Used for the selected ring and the sky focus ring on cards.
static func ring_style(col: Color, width: int, gap: int, rad_px: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = col
	s.set_border_width_all(width)
	s.set_expand_margin_all(gap + width)
	s.set_corner_radius_all(rad_px + gap + width)
	s.anti_aliasing = true
	return s
