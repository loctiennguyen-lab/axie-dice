class_name Ui5SettingsCheck
extends CheckBox
## UI-05 `.check`: keycap_h square, radius s, 2 px text_muted ring; on = checkbox_on fill + dark tick. The theme icons are
## transparent spacers of the box size; the box and tick are drawn here. data-name "Checkbox".


func setup(label: String) -> void:
	name = "Checkbox"
	text = label
	var d := UI3Theme.size_of("keycap_h")
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	for n in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
		add_theme_icon_override(n, tex)
	add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	add_theme_constant_override("h_separation", UI3Theme.space("16"))
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _draw() -> void:
	var d := float(UI3Theme.size_of("keycap_h"))
	var r := Rect2(0, (size.y - d) * 0.5, d, d)
	var rad := UI3Theme.radius("s")
	if button_pressed:
		draw_style_box(UI3Theme.flat(UI3Theme.color("checkbox_on"), rad), r)
		var ink := UI3Theme.color("text_ink")
		draw_polyline(PackedVector2Array([r.position + r.size * Vector2(0.22, 0.52), r.position + r.size * Vector2(0.43, 0.72),
			r.position + r.size * Vector2(0.78, 0.30)]), ink, maxf(2.0, d * 0.12), true)
	else:
		draw_style_box(UI3Theme.flat(Color.TRANSPARENT, rad, UI3Theme.stroke("hairline"), UI3Theme.color("text_muted")), r)
