class_name RerollTags
extends Control
## After a reroll: the small tags that stay from the old tray. A "MAX!" tag on a die that rolled its
## best face, and a +2 / -1 / NEW / MAX chip over its card. Fired by CombatView on DiceRoller3D's
## die_arrived. No grade stamp, no power line (Liam, 18/10). Pure HUD: text and colours come from
## UI3 tokens, sizes are 18 (chip) and 24 (MAX tag) from the font rules.

const CHIP_SIZE := 24
const TAG_SIZE := 24
const RISE := 28.0
const LIFE := 1.5


## {text, color_token} for the chip, or {} when nothing changed. `faces` = 6 {type, value}.
## Same order as the old tray: MAX, NEW (other type), +n, -n.
static func chip_for(faces: Array, prev_index: int, new_index: int) -> Dictionary:
	if new_index < 0 or new_index >= faces.size():
		return {}
	var nf: Dictionary = faces[new_index]
	if is_max_face(faces, new_index):
		return {"text": "MAX", "token": "accent"}
	if prev_index < 0 or prev_index >= faces.size():
		return {}
	var pf: Dictionary = faces[prev_index]
	if String(pf.get("type", "")) != String(nf.get("type", "")):
		return {"text": "NEW", "token": String(UI3.FACE_COLOR[UI3.face_key(String(nf.get("type", "blank")))])}
	var d := int(nf.get("value", 0)) - int(pf.get("value", 0))
	if d > 0:
		return {"text": "+%d" % d, "token": "success_text"}
	if d < 0:
		return {"text": "-%d" % -d, "token": "danger_text"}
	return {}


static func is_max_face(faces: Array, index: int) -> bool:
	var mx := 0
	for f in faces:
		mx = maxi(mx, int((f as Dictionary).get("value", 0)))
	var v := int((faces[index] as Dictionary).get("value", 0))
	return v > 0 and v >= mx


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 20


## `card` = the tray card to hang the tags above. `faces` / indices as in chip_for().
## `animate` false (reduced motion) shows the tags still, and they fade without moving.
func show_for(card: Control, faces: Array, prev_index: int, new_index: int, animate: bool) -> void:
	if card == null or not is_instance_valid(card) or not card.is_inside_tree():
		return
	var r := card.get_global_rect()
	var top := r.position.y
	var cx := r.get_center().x
	var chip := chip_for(faces, prev_index, new_index)
	var max_face := is_max_face(faces, new_index)
	# B11 (QA 29/10): on a best face the "MAX!" tag on the die already says it; the "MAX" chip above the card only sat
	# on the dice header's FRONT / BACK words. The +n / -n / NEW chips stay.
	if not chip.is_empty() and not max_face:
		_spawn(String(chip["text"]), UI3Theme.color(String(chip["token"])), CHIP_SIZE, Vector2(cx, top + 12.0), 0.0, animate)
	if max_face:
		_spawn("MAX!", UI3Theme.color("accent_text"), TAG_SIZE, Vector2(r.end.x - 36.0, top + 56.0), -8.0, animate, true)


func _spawn(text: String, ink: Color, font_size: int, at: Vector2, tilt: float, animate: bool, filled := false) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI3Theme.flat(UI3Theme.color("accent") if filled else UI3Theme.color("panel_raised"), UI3Theme.radius("s"),
		2, UI3Theme.color("accent") if not filled else UI3Theme.color("panel"))
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var l := UI3.label(text, "LabelDisplay")
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", ink)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	add_child(p)
	p.reset_size()
	p.size = p.get_combined_minimum_size()
	p.pivot_offset = p.size * 0.5
	var base := at - Vector2(p.size.x * 0.5, p.size.y)
	p.position = base
	p.rotation_degrees = tilt
	if not animate or not is_inside_tree():
		if is_inside_tree():
			get_tree().create_timer(LIFE).timeout.connect(p.queue_free)
		else:
			p.queue_free()
		return
	p.scale = Vector2(0.6, 0.6)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(p, "position:y", base.y - 8.0, 0.2)
	tw.tween_interval(LIFE - 0.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.25)
	tw.tween_callback(p.queue_free)
