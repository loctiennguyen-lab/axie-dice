class_name DieCard
extends Control
## UI-05 b1 lane B: one party die in the tray (frames 02-combat--set-3 / --set-4 / --die-picked, components--dice).
## Tree, same as the HTML: Plate > Content VBox(DieHolder > Die, FaceRow, PartRow, OwnerRow, OwnerHPBar). The PartRow sits under
## the die, so a lifted die never covers the part (NOTE-DIECARD-PARTS).
## States: default · selected (die lifts, cream rim + 4 px cream ring) · used (chip fill, grey die, "Used") · waiting (the whole
## tray dims, DiceDock). In a SET: a 4 px ring and a filled PartChip in the SET colour, "4 → 6" in the FaceRow. Marks on the die's
## top-right corner (they lift with the die): TEMP (Wild / Temp Face), HELD (Hold), OVERCAST; top-left: 1/2 (Crack), REROLL.
## Lives inside the DieSlotN toggle Button, so clicks, focus, `%DieSlot0` and the tutorial lookups stay on the Button. Everything
## here ignores the mouse except the PartChip and the marks, which PASS (their tooltip shows, the click still reaches the card).
## Every size is a UI3Theme token, so the 1280 interpolation (die_card_w, text floor) applies.

const MARK_NAMES := {&"temp": "TempFaceMark", &"held": "HeldMark", &"overcast": "OvercastMark",
	&"crack": "CrackChip", &"reroll": "RerollChip"}
const MARK_FILL := {&"temp": "temp_face", &"held": "held", &"overcast": "overcast", &"crack": "chip", &"reroll": "selected"}
const MARK_TEXT := {&"temp": "TEMP", &"held": "HELD", &"overcast": "OVERCAST", &"crack": "1/2", &"reroll": "REROLL"}
const MARK_GLYPH := {&"temp": &"wild", &"held": &"hold", &"overcast": &"overcast"}

var plate: PanelContainer
var set_ring: Panel
var sel_ring: Panel
var content: VBoxContainer
var die_holder: Control
var die: Panel
var face_glyph: TextureRect
var face_value: Label
var marks_right: VBoxContainer
var marks_left: VBoxContainer
var crack_line: Line2D
var face_row: HBoxContainer
var face_word: Label
var set_delta: Label
var part_row: HBoxContainer
var part_chip: PanelContainer
var part_glyph: TextureRect
var part_word: Label
var owner_row: HBoxContainer
var owner_name: Label
var owner_hp: Label
var hp_bar: HPBar

var state: StringName = &"default"   ## default | selected | used | disabled
var set_key := ""                    ## "" | "a" | "b"
var lifted := false
var delta_full := ""                 ## "4 → 6" even when the card shows the compact "+2"
var skin_id := ""
var skin_node: Control = null
var _face: StringName = &"blank"
var _marks := {}                     ## kind -> PanelContainer
var _last: Dictionary = {}           ## the last `apply` data, so a SET change can repaint without a full tray rebuild
var _sizes_at := -1.0                ## UI3Theme scale the text sizes were last set for (live 1920 <-> 1280 resize)


func _init() -> void:
	name = "DieCard"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_ring = _ring("SetRing")
	sel_ring = _ring("SelectRing")
	plate = PanelContainer.new()
	plate.name = "Plate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	content = VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", UI3Theme.space("4"))
	plate.add_child(content)
	_build_die()
	_build_rows()
	_sync_sizes()
	_style_plate()


func _ring(nm: String) -> Panel:
	var p := Panel.new()
	p.name = nm
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.visible = false
	add_child(p)
	return p


func _build_die() -> void:
	die_holder = Control.new()
	die_holder.name = "DieHolder"
	die_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	die_holder.custom_minimum_size.y = UI3Theme.size_of("die_h") + UI3Theme.space("12")
	content.add_child(die_holder)
	die = Panel.new()
	die.name = "Die"
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	die.size = Vector2(UI3Theme.size_of("die_w"), UI3Theme.size_of("die_h"))
	die_holder.add_child(die)
	var box := HBoxContainer.new()
	box.name = "FaceBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", UI3Theme.space("4"))
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	die.add_child(box)
	face_glyph = TextureRect.new()
	face_glyph.name = "FaceGlyph"
	var g := UI3Theme.size_of("die_glyph")
	face_glyph.custom_minimum_size = Vector2(g, g)
	face_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(face_glyph)
	face_value = UI3.label("", "LabelDisplay")
	face_value.name = "FaceValue"
	face_value.add_theme_font_size_override("font_size", UI3Theme.size_of("num_die"))
	face_value.add_theme_color_override("font_color", UI3Theme.color("die_ink"))
	face_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face_value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(face_value)
	crack_line = Line2D.new()
	crack_line.name = "CrackMark"
	crack_line.width = 3.0
	crack_line.default_color = UI3Theme.color("die_ink")
	var w := die.size.x
	var h := die.size.y
	crack_line.points = PackedVector2Array([Vector2(w * 0.55, 4), Vector2(w * 0.65, h * 0.3), Vector2(w * 0.52, h * 0.52),
		Vector2(w * 0.66, h * 0.76), Vector2(w * 0.56, h - 4)])
	crack_line.visible = false
	die.add_child(crack_line)
	marks_right = _mark_column("MarksRight")
	marks_left = _mark_column("MarksLeft")
	die_holder.resized.connect(_place_die)


func _mark_column(nm: String) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.name = nm
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_constant_override("separation", UI3Theme.space("4"))
	c.z_index = 2
	die.add_child(c)
	return c


func _build_rows() -> void:
	var body := UI3Theme.size_of("text_body")
	face_row = _row("FaceRow")
	face_word = UI3.label("", "LabelDisplay")
	face_word.name = "FaceWord"
	face_word.add_theme_font_size_override("font_size", body)
	face_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_word.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	face_row.add_child(face_word)
	set_delta = UI3.label("", "LabelDisplay")
	set_delta.name = "SetDelta"
	set_delta.add_theme_font_size_override("font_size", body)
	set_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	set_delta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_row.add_child(set_delta)

	part_row = _row("PartRow")
	part_chip = PanelContainer.new()
	part_chip.name = "PartChip"
	part_chip.mouse_filter = Control.MOUSE_FILTER_PASS   # tooltip; the click still reaches the card
	part_chip.custom_minimum_size.y = UI3Theme.size_of("part_chip_h")
	part_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	part_row.add_child(part_chip)
	var pbox := HBoxContainer.new()
	pbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pbox.add_theme_constant_override("separation", UI3Theme.space("4"))
	part_chip.add_child(pbox)
	part_glyph = TextureRect.new()
	part_glyph.name = "Glyph"
	var pg := UI3Theme.size_of("part_glyph")
	part_glyph.custom_minimum_size = Vector2(pg, pg)
	part_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	part_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	part_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	part_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pbox.add_child(part_glyph)
	part_word = UI3.label("", "LabelDisplay")
	part_word.name = "PartWord"
	part_word.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key"))
	part_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	part_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pbox.add_child(part_word)

	owner_row = _row("OwnerRow")
	owner_name = UI3.label("")
	owner_name.name = "OwnerName"
	owner_name.add_theme_font_size_override("font_size", body)
	owner_name.add_theme_color_override("font_color", UI3Theme.color("text"))
	owner_name.clip_text = true
	owner_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	owner_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_row.add_child(owner_name)
	owner_hp = UI3.label("")
	owner_hp.name = "OwnerHP"
	owner_hp.add_theme_font_size_override("font_size", body)
	owner_hp.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	owner_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_row.add_child(owner_hp)

	hp_bar = HPBar.new()
	hp_bar.name = "OwnerHPBar"
	hp_bar.ui3_look = true
	hp_bar.set_kind(HPBar.Kind.PARTY, UI3Theme.size_of("hp_bar_h"), UI3Theme.radius("s"), UI3Theme.size_of("text_key"))
	hp_bar.custom_minimum_size.x = 0
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(hp_bar)


func _row(nm: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.name = nm
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_constant_override("separation", UI3Theme.space("4"))
	content.add_child(r)
	return r


# ---------------------------------------------------------------- sizes

static func _shadow_px(key: String, fallback: int) -> int:
	var v: Variant = (UI3Theme.tokens().get("shadow", {}) as Dictionary).get(key)
	if v is Dictionary:
		return int((v as Dictionary).get("y", fallback))
	return fallback if v == null else int(v)


## How far a picked die lifts: tokens shadow.die_side_selected.y - die_side.y (18 - 8 = 10, README "die lifts 10 px").
static func lift_px() -> int:
	return _shadow_px("die_side_selected", 18) - _shadow_px("die_side", 8)


## Inner padding of the card plate: rim + space (HTML: padding 12 / 8 inside a 2 px rim).
static func pad() -> Vector2:
	var rim := UI3Theme.stroke("rim")
	return Vector2(UI3Theme.space("8") + rim, UI3Theme.space("12") + rim)


## Height the card needs at the current scale: the die_card_h token, or more when the 1280 text floor makes the rows taller
## (HTML 1280 lets the HP bar eat the bottom padding; here the card grows a few px instead, so nothing is cut).
static func needed_height() -> float:
	var body := UI3Theme.size_of("text_body")
	var gap := float(UI3Theme.space("4"))
	var rows := float(UI3Theme.size_of("die_h") + UI3Theme.space("12"))
	rows += ceilf(UI3Theme.font_display().get_height(body))
	rows += maxf(float(UI3Theme.size_of("part_chip_h")), ceilf(UI3Theme.font_display().get_height(UI3Theme.size_of("text_key"))))
	rows += ceilf(UI3Theme.font_body().get_height(body))
	rows += float(UI3Theme.size_of("hp_bar_h"))
	var h := rows + gap * 4.0 + pad().y * 2.0
	return maxf(float(UI3Theme.size_of("die_card_h")), h)


# ---------------------------------------------------------------- styles

static func card_style(fill_token: String, rim_token: String) -> StyleBoxFlat:
	var p := pad()
	return UI3Theme.flat(UI3Theme.color(fill_token), UI3Theme.radius("xl"), UI3Theme.stroke("rim"), UI3Theme.color(rim_token),
		Vector4(p.x, p.y, p.x, p.y), {"y": _shadow_px("lip", 6), "color": UI3Theme.color("plate_ink")})


## A ring `width` px wide drawn `out` px outside the card (CSS 0 0 0 Npx spread ring).
static func ring_style(col: Color, out: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(UI3Theme.stroke("selected"))
	s.border_color = col
	s.set_corner_radius_all(UI3Theme.radius("xl") + out)
	s.set_expand_margin_all(out)
	s.anti_aliasing = true
	s.set_meta("ui3", true)
	return s


static func die_style(face_col: Color, lip: int, used: bool) -> StyleBoxFlat:
	var body := UI3Theme.color("die_body")
	if used:
		body = body.darkened(0.46)   # HTML .is-used .die #8a8070 has no token: the die body darkened to the same grey
	return UI3Theme.flat(body, UI3Theme.radius("l"), 0, Color.TRANSPARENT, Vector4.ZERO, {"y": lip, "color": face_col})


## A die mark (TEMP / HELD / OVERCAST, also used inside a SetBanner) or a left-corner chip (1/2, REROLL): keycap_h high pill,
## Rowdies text_key in set_text on the mark colour, 2 px plate_ink ring so it reads on the ivory die. Glyph drawn in code.
static func make_mark(kind: StringName, ring := true) -> PanelContainer:
	var m := PanelContainer.new()
	m.name = String(MARK_NAMES.get(kind, "Mark"))
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	m.theme = UI3Theme.get_theme()
	var on_light := kind != &"crack"
	var ink := UI3Theme.color("set_text") if on_light else UI3Theme.color("text")
	var sp := UI3Theme.space("8")
	m.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color(String(MARK_FILL.get(kind, "chip"))), UI3Theme.radius("pill"),
		2 if ring else 0, UI3Theme.color("plate_ink"), Vector4(sp, 0, sp, 0)))
	m.custom_minimum_size.y = UI3Theme.size_of("keycap_h")
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", UI3Theme.space("4"))
	m.add_child(box)
	if MARK_GLYPH.has(kind):
		var holder := Control.new()
		holder.name = "GlyphBox"
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gs := UI3Theme.size_of("text_key")
		holder.custom_minimum_size = Vector2(gs, gs)
		holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var gl := ActionGlyph.new(MARK_GLYPH[kind])
		# ActionGlyph draws in the cream text colour; modulate turns that into set_text exactly (per channel).
		var base := UI3Theme.color("text")
		gl.modulate = Color(ink.r / maxf(base.r, 0.01), ink.g / maxf(base.g, 0.01), ink.b / maxf(base.b, 0.01), 1.0)
		holder.add_child(gl)
		box.add_child(holder)
	var l := UI3.label(TranslationServer.translate(String(MARK_TEXT.get(kind, ""))), "LabelDisplay")
	l.name = "Text"
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key"))
	l.add_theme_color_override("font_color", ink)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	return m


func _style_plate() -> void:
	var used := state == &"used"
	var sel := state == &"selected"
	plate.add_theme_stylebox_override("panel", card_style("chip" if used else "plate", "selected" if sel else "plate_rim"))


# ---------------------------------------------------------------- paint

## Paints the card. `d` (all optional):
##   name, hp, max_hp, shield, incoming, faces:[{type, value}], rolled (-1 = not rolled), alive, spent, selected, legal_target,
##   skin, held, overcast, cracked, rr_tick, wild_text ("" = no Temp Face), part_text, part_word, part_tex,
##   set_key ("" | "a" | "b"), set_before, set_after, set_show.
func apply(d: Dictionary) -> void:
	_last = d.duplicate()
	_sync_sizes()
	var alive := bool(d.get("alive", true))
	var spent := bool(d.get("spent", false))
	var selected := bool(d.get("selected", false))
	var rolled := int(d.get("rolled", -1))
	var faces: Array = d.get("faces", [])
	var show_face := alive and rolled >= 0 and rolled < faces.size()
	_face = &"blank"
	var fval := 0
	if show_face:
		_face = TrayColumn.ui3_face(String((faces[rolled] as Dictionary).get("type", "")))
		fval = int((faces[rolled] as Dictionary).get("value", 0))
	if not show_face:
		state = &"disabled"
	elif spent:
		state = &"used"
	elif selected:
		state = &"selected"
	else:
		state = &"default"
	set_key = String(d.get("set_key", "")) if show_face else ""
	lifted = state == &"selected"
	_style_plate()

	# Die: glyph + value, face-colour lip; a picked die lifts and its lip grows by the same amount.
	var face_col := UI3Theme.color(String(UI3.FACE_COLOR.get(_face, "face_blank")))
	var lip := _shadow_px("die_side_selected" if lifted else "die_side", 8)
	die.add_theme_stylebox_override("panel", die_style(face_col, lip, state == &"used"))
	face_glyph.texture = UI3.icon(String(UI3.FACE_ICON.get(_face, "face_blank"))) if show_face else null
	face_glyph.visible = show_face
	if not alive:
		face_value.text = "KO"
	elif not show_face:
		face_value.text = "-"
	elif _face == &"blank":
		face_value.text = "–"
	else:
		face_value.text = str(fval)
	die.modulate.a = 1.0 if show_face else 0.4
	_place_die()

	# FaceRow: the face word (always: colour-blind cue) and the SET preview / "Used".
	face_word.text = UI3.face_word(_face) if show_face else ""
	face_word.add_theme_color_override("font_color", UI3Theme.color(String(UI3.FACE_WORD_COLOR.get(_face, "text"))))
	delta_full = ""
	if state == &"used":
		set_delta.text = TranslationServer.translate("Used")
		set_delta.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	elif bool(d.get("set_show", false)):
		var b := int(d.get("set_before", 0))
		var a := int(d.get("set_after", 0))
		delta_full = SetPreview.delta_text(b, a)
		set_delta.text = delta_full if _fits(face_word.text, delta_full) else SetPreview.compact_text(b, a)
		set_delta.add_theme_color_override("font_color", UI3Theme.color("set_delta"))
	else:
		set_delta.text = ""

	# PartRow: glyph + word, filled in the SET colour while the die is in a SET.
	var ptext := String(d.get("part_text", ""))
	part_chip.visible = ptext != ""
	part_glyph.texture = d.get("part_tex", null)
	part_glyph.visible = part_glyph.texture != null
	part_word.text = String(d.get("part_word", ptext.capitalize()))
	part_chip.set_meta("part_text", ptext)
	var in_set := set_key != ""
	var sp := UI3Theme.space("8")
	part_chip.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color(SetPreview.colour_token(set_key)) if in_set else UI3Theme.color("chip"), UI3Theme.radius("pill"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("4"), 0, sp, 0)))
	part_word.add_theme_color_override("font_color", UI3Theme.color("set_text") if in_set else UI3Theme.color("text"))
	if ptext != "":
		UI3Tooltip.bind(part_chip, "%s. %s" % [part_word.text, TranslationServer.translate("3 dice of the same part make a SET")])

	# OwnerRow + HP bar.
	var hp_now := int(d.get("hp", 0))
	var hp_max := int(d.get("max_hp", 1))
	Ui5Ellipsis.set_text(owner_name, String(d.get("name", "")))   # B9: "Pomod…", never a bare "Pomodor"
	owner_hp.text = "%d/%d" % [maxi(hp_now, 0), hp_max]
	hp_bar.set_stats(hp_now, hp_max)
	hp_bar.set_at_risk(mini(hp_now, maxi(0, int(d.get("incoming", 0)) - int(d.get("shield", 0)))))
	plate.modulate.a = 1.0 if alive else 0.55

	# Rings: SET colour 4 px outside; selected / legal ally target cream, outside the SET ring when both.
	var w := UI3Theme.stroke("selected")
	set_ring.visible = in_set
	if in_set:
		set_ring.add_theme_stylebox_override("panel", ring_style(UI3Theme.color(SetPreview.colour_token(set_key)), w))
	var lit := lifted or bool(d.get("legal_target", false))
	sel_ring.visible = lit
	if lit:
		sel_ring.add_theme_stylebox_override("panel", ring_style(UI3Theme.color("selected"), w * 2 if in_set else w))

	# Marks.
	_set_mark(&"temp", String(d.get("wild_text", "")) != "", marks_right,
		TranslationServer.translate("Temp Face: this die counts as %s for the SET this turn.") % String(d.get("wild_text", "")).capitalize())
	_set_mark(&"held", bool(d.get("held", false)), marks_right, TranslationServer.translate("Held: this die is kept for next turn."))
	_set_mark(&"overcast", bool(d.get("overcast", false)), marks_right,
		TranslationServer.translate("Overcast: every die in this SET is stronger this turn."))
	var cracked := bool(d.get("cracked", false))
	_set_mark(&"crack", cracked, marks_left, TranslationServer.translate("Cracked: half value, out of the SET. Ends next turn."))
	_set_mark(&"reroll", bool(d.get("rr_tick", false)), marks_left, TranslationServer.translate("Picked for the reroll."))
	crack_line.visible = cracked
	_apply_skin(String(d.get("skin", "")))
	_place_marks()


## Repaints only the SET look (ring, filled PartChip, preview) from SetPreview.for_die(): {key, before, after, show}.
## Used on EventBus.bo_changed, which can arrive without a full tray rebuild.
func apply_set(pv: Dictionary) -> void:
	var d := _last.duplicate()
	d["set_key"] = pv.get("key", "")
	d["set_before"] = pv.get("before", 0)
	d["set_after"] = pv.get("after", 0)
	d["set_show"] = pv.get("show", false)
	apply(d)


## True when the face word and `delta` fit side by side in the FaceRow at the current text size.
func _fits(word: String, delta: String) -> bool:
	var fs := UI3Theme.size_of("text_body")
	var f := UI3Theme.font_display()
	var avail := (size.x if size.x > 1.0 else float(UI3Theme.size_of("die_card_w"))) - pad().x * 2.0
	var need := f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x \
		+ f.get_string_size(delta, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + float(UI3Theme.space("4"))
	return need <= avail


func _set_mark(kind: StringName, on: bool, col: VBoxContainer, tip: String) -> void:
	var m: PanelContainer = _marks.get(kind)
	if on and m == null:
		m = make_mark(kind)
		col.add_child(m)
		_marks[kind] = m
	if m != null:
		m.visible = on
		if on:
			UI3Tooltip.bind(m, tip)


## Mark by kind (&"temp", &"held", &"overcast", &"crack", &"reroll"), or null when it was never shown.
func mark(kind: StringName) -> PanelContainer:
	return _marks.get(kind)


func _place_die() -> void:
	if die == null or die_holder == null:
		return
	var x := (die_holder.size.x - die.size.x) * 0.5
	die.position = Vector2(x, -float(lift_px()) if lifted else 0.0)
	die.pivot_offset = die.size * 0.5


## Marks hang 10 px off the die corners (HTML right:-10px; top:-10px) and lift with it.
func _place_marks() -> void:
	var off := 10.0
	marks_right.size = marks_right.get_combined_minimum_size()
	# A wide mark (OVERCAST at 1280) would hang past the card's left edge: keep it 4 px inside the card instead.
	var min_x := -die.position.x - pad().x + 4.0
	marks_right.position = Vector2(maxf(die.size.x + off - marks_right.size.x, min_x), -off)
	marks_left.size = marks_left.get_combined_minimum_size()
	marks_left.position = Vector2(-off, -off)


## Cosmetic dice skin (47-tray-skin): trim overlay on the die, same rect; glyph and number untouched.
## Text sizes follow the window scale (the 1280 floor raises 16 / 18 to 21 logical). Re-applied whenever the scale moved, so a
## live resize never leaves 12 px text behind. Die, chip and bar sizes have no 1280 override; the card width comes from the slot.
func _sync_sizes() -> void:
	var sc := UI3Theme.current_scale()
	if is_equal_approx(sc, _sizes_at):
		return
	_sizes_at = sc
	var body := UI3Theme.size_of("text_body")
	for l in [face_word, set_delta, owner_name, owner_hp]:
		(l as Label).add_theme_font_size_override("font_size", body)
	part_word.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key"))
	Ui5Ellipsis.refit(owner_name)
	for m in _marks.values():
		size_mark(m)


## Re-applies the token sizes of a mark made by make_mark (after a scale change).
static func size_mark(m: PanelContainer) -> void:
	var key := UI3Theme.size_of("text_key")
	m.custom_minimum_size.y = UI3Theme.size_of("keycap_h")
	var gb: Control = m.find_child("GlyphBox", true, false)
	if gb != null:
		gb.custom_minimum_size = Vector2(key, key)
	var t: Label = m.find_child("Text", true, false)
	if t != null:
		t.add_theme_font_size_override("font_size", key)


func _apply_skin(skin: String) -> void:
	if skin == skin_id:
		return
	if skin_node != null and is_instance_valid(skin_node):
		skin_node.get_parent().remove_child(skin_node)
		skin_node.queue_free()
	skin_node = null
	skin_id = ""
	if skin == "":
		return
	var node := DiceSkin.make_trim(skin, int(round(die.size.x)))
	if node == null:
		return
	die.add_child(node)   # a border trim (transparent centre) over the face, as before; the marks stay above it (z 2)
	skin_id = skin
	skin_node = node
