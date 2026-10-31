extends RefCounted
## UI-05 b23 lane S1a: Land HUD plates (round-3 ui05-land-screens.html: ProfilePlate, LandPlate, LinksPlate cell
## buttons, RunPlate with its Space keycap). Static builders only: LandHud owns the state and wires the signals.
## Every size is a token (UI3Theme); no illustration values live here. Used through
## `const Plates := preload("res://scenes/land/ui5/LandPlates.gd")`.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## Pill/plate box with `.plate` rim + hard lip. `rad` = radius token.
static func box(rad: String, pad: Vector4) -> StyleBoxFlat:
	return UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius(rad), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), pad, PanelParts.lip(UI3Theme.color("plate_ink")))


## Flat transparent Button covering a plate's content: hover tint + amber focus ring, both grown by `grow` (l,t,r,b)
## so they follow the whole plate, not just the padded content rect.
static func cover(btn_name: String, radius_px: int, grow: Vector4, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = btn_name
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	var hov := UI3Theme.flat(Color(1, 1, 1, 0.08), radius_px)
	var foc := UI3Theme.focus_style(radius_px)
	for s in [hov, foc]:
		(s as StyleBoxFlat).expand_margin_left += grow.x
		(s as StyleBoxFlat).expand_margin_top += grow.y
		(s as StyleBoxFlat).expand_margin_right += grow.z
		(s as StyleBoxFlat).expand_margin_bottom += grow.w
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("focus", foc)
	b.pressed.connect(on_press)
	return b


## ProfilePlate (340 wide pill): Avatar disc + Name (Rowdies title) + SubLine (muted body). The cover button
## "ProfileButton" opens the profile. `framed` wraps the avatar in the equipped cosmetic frame.
static func profile_plate(guest: bool, player: String, sub: String, frame_id: String, on_press: Callable) -> PanelContainer:
	var s8 := UI3Theme.space("8")
	var s16 := UI3Theme.space("16")
	var plate := PanelParts.panel(box("pill", Vector4(s8, s8, s16, s8)), "ProfilePlate")
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	plate.custom_minimum_size.x = UI3Theme.size_of("profile_plate_w")
	var h := HBoxContainer.new()
	h.name = "Row"
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	var px := float(UI3Theme.size_of("avatar"))
	var av := PanelContainer.new()
	av.name = "Avatar"
	av.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color("avatar_guest") if guest else UI3Theme.color("accent"), int(px * 0.5), 3, UI3Theme.color("plate_rim")))
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ini := PanelParts.text("?" if guest else player.left(1).to_upper(), "text_title",
		"text" if guest else "text_ink", true)
	ini.name = "Initial"
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.add_child(ini)
	h.add_child(AvatarFrame.wrap_holder(av, px, frame_id))
	var col := VBoxContainer.new()
	col.name = "Text"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	# width left for the text: plate - paddings - avatar - gap - rim both sides
	col.custom_minimum_size.x = UI3Theme.size_of("profile_plate_w") - s8 - s16 - px - UI3Theme.space("12") - 2 * UI3Theme.stroke("rim")
	var nl := PanelParts.text(player.left(16), "text_title", "text", true)
	nl.name = "Name"
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nl)
	var sl := PanelParts.text(sub.left(24), "text_body", "text_muted")
	sl.name = "SubLine"
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sl)
	h.add_child(col)
	plate.add_child(h)
	var cv := cover("ProfileButton", UI3Theme.radius("pill"), Vector4(s8, s8, s16, s8), on_press)
	cv.tooltip_text = "Profile"
	plate.add_child(cv)
	return plate


## LandPlate at max tier: a plain plate (radius m, pad 8/16) with one Rowdies body line. No button: nothing to upgrade.
static func max_plate(text: String) -> PanelContainer:
	var p := PanelParts.panel(box("m", Vector4(UI3Theme.space("16"), UI3Theme.space("8"), UI3Theme.space("16"), UI3Theme.space("8"))), "LandPlate")
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l := PanelParts.text(text, "text_body", "text", true)
	l.name = "Label"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## `.cell-btn` of the LinksPlate: 44 high, raised wood, Rowdies body text, 16 side padding.
static func cell_button(btn_name: String, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = btn_name
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var pad := Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0)
	var rad := UI3Theme.radius("m")
	var normal := UI3Theme.flat(UI3Theme.color("plate_raised"), rad, 0, Color.TRANSPARENT, pad)
	var hover := UI3Theme.flat(UI3Theme.color("plate_raised").lightened(0.12), rad, 0, Color.TRANSPARENT, pad)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(rad))
	b.add_theme_font_override("font", UI3Theme.font_display())
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UI3Theme.color("text"))
	b.pressed.connect(on_press)
	return b


## Space keycap on a primary button (primary variant), shown only while the button is enabled (a disabled primary has
## no keycap, Liam 30/10). Positioned after the centred label via Ui5HudStyle.place_trailing; re-synced on redraw/resize.
static func attach_space_cap(b: Button, pad_in: int) -> PanelContainer:
	var cap := Ui5Keycap.make("Space", &"primary")
	b.add_child(cap)
	var pad := maxi(pad_in, UI3Theme.space("24"))   # space token "32" may be absent: never 0
	var gap := UI3Theme.space("12")
	cap.set_anchors_preset(Control.PRESET_CENTER_RIGHT)   # layout-independent: pinned pad px from the right edge
	cap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cap.grow_vertical = Control.GROW_DIRECTION_BOTH
	cap.offset_right = -pad
	var sync := func() -> void:
		if not is_instance_valid(b) or not is_instance_valid(cap):
			return
		var sig := "%s|%s|%s|%d|%d" % [b.text, b.disabled, b.size, UI3Theme.size_of("keycap_h"), b.get_theme_font_size("font_size")]
		if String(b.get_meta("cap_sig", "")) == sig:
			return
		b.set_meta("cap_sig", sig)
		cap.visible = not b.disabled
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT if cap.visible else HORIZONTAL_ALIGNMENT_CENTER   # label left, Space right: never overlap
		var cs := cap.get_combined_minimum_size()
		var extra := (gap + int(ceilf(cs.x))) if cap.visible else 0
		var font := b.get_theme_font("font")
		var tw := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x if font != null else 0.0
		var base_w := float(b.get_meta("base_w", b.custom_minimum_size.x))
		b.set_meta("base_w", base_w)
		b.custom_minimum_size.x = maxf(base_w, ceilf(tw) + 2.0 * pad + extra) if cap.visible else base_w
		# Styles come from the theme by variation (b.get_theme_stylebox is the grey engine default before the button
		# is in the tree); the right content margin grows by the cap so the label centres in what is left.
		var th := UI3Theme.get_theme()
		for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			var src: StyleBox = th.get_stylebox(st, b.theme_type_variation)
			if src is StyleBoxFlat:
				var d := (src as StyleBoxFlat).duplicate() as StyleBoxFlat
				d.content_margin_right = maxf(d.content_margin_right, float(pad)) + extra if cap.visible else d.content_margin_right
				if cap.visible:
					d.content_margin_left = maxf(d.content_margin_left, float(pad))
				b.add_theme_stylebox_override(st, d)
	b.draw.connect(sync)
	b.resized.connect(sync)
	b.minimum_size_changed.connect(sync)
	sync.call_deferred()
	return cap
