class_name U5VictoryBand
extends Control
## UI-05 b1 lane E: the Victory moment (moment-victory.html, motion row "victory"). Full-screen, on the Ui5Moments
## layer: scrim 0 -> 0.45, eight cream rays turning behind the band, the amber "Victory" band dropping from -480
## (text_hero 56 held at scale 1.3: no 72 size, Liam 28/10), the "Fight 4 of 18 cleared" sub-line, the
## "Click or Space to continue" hint, a shake on landing and two confetti bursts.
## First click / Space / Enter / Esc while it plays jumps to the end state and is eaten; after that presses pass
## through (CombatView skips the victory march with them). Stays up until U5Moments.end_victory or the scene ends.

var run: UI3Motion.Timeline


static func show_on(parent: Control, sub_text: String, shake: Callable = Callable()) -> U5VictoryBand:
	var row: Dictionary = UI3Motion.table().get("victory", {})
	var vb := U5VictoryBand.new()
	vb.name = "VictoryBand"
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(vb)
	var w := parent.size.x if parent.size.x > 0.0 else 1920.0
	var targets := {}
	var ls := UI3Motion.layer("victory", "scrim")
	var scrim := U5Moments.overlay(String(ls.get("color_token", "bg")), "Scrim")
	vb.add_child(scrim)
	targets["scrim"] = scrim
	# Rays: 8 bars 1400 x 90, every 22.5 deg, turning around the band centre.
	var lr := UI3Motion.layer("victory", "rays")
	var rays := Control.new()
	rays.name = "Rays"
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.position = Vector2(w * 0.5, float(row.get("rays_y", 400)))
	rays.modulate.a = 0.0
	for i in 8:
		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.color = UI3Theme.color(String(lr.get("color_token", "text_on_viewport")))
		bar.size = Vector2(1400, 90)
		bar.position = -bar.size * 0.5
		bar.pivot_offset = bar.size * 0.5
		bar.rotation = deg_to_rad(22.5 * i)
		rays.add_child(bar)
	vb.add_child(rays)
	targets["rays"] = rays
	var lb := UI3Motion.layer("victory", "band")
	var band := U5Moments.band(String(lb.get("color_token", "banner_player")), float(row.get("band_y", 330)),
		float(row.get("band_h", 150)), "Band")
	vb.add_child(band)
	var title := U5Moments.band_label(band, TranslationServer.translate(String(lb.get("text", "Victory"))),
		String(lb.get("size_token", "text_hero")), String(lb.get("text_token", "text_ink")), "accent_rim")
	title.name = "Title"
	var k := float(lb.get("label_scale", 1.3))
	title.scale = Vector2(k, k)
	targets["band"] = band
	var lsub := UI3Motion.layer("victory", "sub")
	var sub := U5Moments.hero_label(sub_text, String(lsub.get("size_token", "text_screen_title")), "text")
	sub.name = "SubLine"
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = float(row.get("sub_y", 520))
	sub.offset_bottom = sub.offset_top + float(UI3Theme.size_of("text_screen_title")) * 1.4
	sub.modulate.a = 0.0
	sub.visible = sub_text != ""
	vb.add_child(sub)
	targets["sub"] = sub
	var hint := _hint()
	vb.add_child(hint)
	targets["hint"] = hint
	var fx := Control.new()
	fx.name = "Fx"
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.position = Vector2(w * 0.5, float(row.get("confetti_y", 420)))
	vb.add_child(fx)
	targets["fx"] = fx
	vb.run = UI3Motion.play_timeline("victory", targets, {"host": vb, "shake": shake})
	return vb


## "Click or [Space] to continue", bottom right (screen margin 24), body text with the viewport drop shadow.
static func _hint() -> Control:
	var row := HBoxContainer.new()
	row.name = "ContinueHint"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var m := float(UI3Theme.space("screen"))
	row.offset_right = -m
	row.offset_bottom = -m
	for part in [TranslationServer.translate("Click or"), "<Space>", TranslationServer.translate("to continue")]:
		if part == "<Space>":
			row.add_child(UI3.keycap(TranslationServer.translate("Space"), true))
			continue
		var l := Label.new()
		l.text = part
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UI3Theme.font_body())
		l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		l.add_theme_color_override("font_color", UI3Theme.color("text_on_viewport"))
		l.add_theme_color_override("font_shadow_color", UI3Theme.color("text_shadow"))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 2)
		row.add_child(l)
	row.modulate.a = 0.0
	return row


func playing() -> bool:
	return run != null and not run.done


func _input(event: InputEvent) -> void:
	if not playing():
		return
	var press := false
	if event is InputEventMouseButton:
		press = (event as InputEventMouseButton).pressed
	elif event is InputEventKey:
		var kk := event as InputEventKey
		press = kk.pressed and not kk.echo and [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE].has(kk.keycode)
	if not press:
		return
	run.skip()
	if is_inside_tree():
		get_viewport().set_input_as_handled()
