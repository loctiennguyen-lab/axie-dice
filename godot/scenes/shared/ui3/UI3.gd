class_name UI3
extends RefCounted
## UI-03 "A4 Blend" component builders (components.md). Every function returns a ready Control
## with the UI3Theme applied; no scene file needed. Strings are passed in by the caller (they come
## from the localization layer, never hardcoded here) except the die face words, which go through tr().
##
## Not wired into any existing screen. Layout containers around these (screen trees) are the job of
## each screen spec; this file only owns the reusable parts.

const ICON_DIR := "res://assets/ui3/icons/"

## Face type -> icon file (without extension) in assets/ui3/icons.
const FACE_ICON := {
	&"attack": "face_dmg", &"shield": "face_shield", &"heal": "face_heal", &"poison": "face_poison",
	&"mana": "face_mana", &"buff": "face_buff", &"weaken": "face_debuff", &"summon": "face_summon",
	&"blank": "face_blank",
}
## Face type -> colour token of the die side / glyph.
const FACE_COLOR := {
	&"attack": "face_attack", &"shield": "face_shield", &"heal": "face_heal", &"poison": "face_poison",
	&"mana": "face_mana", &"buff": "face_buff", &"weaken": "face_weaken", &"summon": "face_summon",
	&"blank": "face_blank",
}
## The word under a die (always glyph + word + colour). ATTACK uses red-7 for contrast (tokens).
const FACE_WORD_COLOR := {
	&"attack": "face_attack_text", &"shield": "face_shield", &"heal": "face_heal", &"poison": "face_poison",
	&"mana": "face_mana", &"buff": "face_buff", &"weaken": "face_weaken", &"summon": "face_summon",
	&"blank": "text_muted",
}
const FACE_TYPES: Array[StringName] = [&"attack", &"shield", &"heal", &"poison", &"mana", &"buff",
	&"weaken", &"summon", &"blank"]
const DIE_STATES: Array[StringName] = [&"normal", &"selected", &"used", &"disabled"]


# ---------------------------------------------------------------- basics

## Texture for an icon in assets/ui3/icons (png first, then svg). Null + error when missing.
static func icon(icon_name: String) -> Texture2D:
	for ext in [".png", ".svg"]:
		var p: String = ICON_DIR + icon_name + ext
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	push_error("UI3: missing icon '%s'" % icon_name)
	return null


## A Label with a UI3Theme type variation ("" = body, "LabelTitle", "LabelScreenTitle", "LabelKeyHint",
## "LabelMuted", "LabelDisplay"). Text is passed through as-is (already localized by the caller).
static func label(text: String, variation := "") -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	return l


## Panel container. kind: plate (HUD/meta, wood-1 @ 90%), card, card_selected, dialog, row, notice,
## info (die info panel). Padding comes from the style; add children directly.
static func plate(kind := &"plate") -> PanelContainer:
	var map := {&"plate": "PanelPlate", &"card": "PanelCard", &"card_selected": "PanelCardSelected",
		&"dialog": "PanelDialog", &"row": "PanelRow", &"notice": "PanelNotice", &"info": "PanelInfo"}
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.theme_type_variation = map.get(kind, "PanelPlate")
	return p


## Button. variant: primary | secondary | danger | quiet. size: L (72, primary only) | M (56) | S (48,
## secondary only); unsupported combos fall back to the nearest (secondary L = M). Hit area is never
## below 44 px. Disabled buttons should say why: use `set_disabled_reason`.
static func button(text: String, variant := &"primary", size := &"M") -> Button:
	var b := Button.new()
	b.theme = UI3Theme.get_theme()
	b.text = text
	var type_name := "ButtonSecondary"
	match variant:
		&"primary":
			type_name = "ButtonPrimaryL" if size == &"L" else "ButtonPrimaryM"
		&"danger":
			type_name = "ButtonDanger"
		&"quiet":
			type_name = "ButtonQuiet"
		_:
			type_name = "ButtonSecondaryS" if size == &"S" else "ButtonSecondary"
	b.theme_type_variation = type_name
	var min_h := b.get_theme_constant("min_height", type_name)
	b.custom_minimum_size = Vector2(UI3Theme.size_of("hit_min"), maxi(min_h, UI3Theme.size_of("hit_min")))
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if variant == &"quiet":
		var line := ColorRect.new()  # the link underline (Button has no underline in a Theme)
		line.color = UI3Theme.color("text_muted")
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		line.offset_top = -UI3Theme.stroke("hairline") - 8
		line.offset_bottom = -8
		line.offset_left = 8
		line.offset_right = -8
		b.add_child(line)
	return b


## Disables `btn` and replaces its text with the reason (design rule: disabled controls say why).
static func set_disabled_reason(btn: Button, reason: String) -> void:
	btn.disabled = true
	btn.text = reason


## 48x48 icon button, radius 8, icon 32 (icon_name from assets/ui3/icons, e.g. "ui_settings").
static func icon_button(icon_name: String, tooltip := "") -> Button:
	var b := Button.new()
	b.theme = UI3Theme.get_theme()
	b.theme_type_variation = "IconButton"
	b.icon = icon(icon_name)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("btn_s")
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_ALL
	return b


## Chip / badge: h 32, amber fill, kam-1 Rowdies 18 text ("New best").
static func chip(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.theme_type_variation = "PanelChip"
	p.custom_minimum_size = Vector2(0, 32)
	var l := label(text, "LabelDisplay")
	l.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## Key hint chip ("Esc", "R"): Work Sans 16, 2 px neutral-5 border, radius 4.
static func key_hint(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.theme_type_variation = "PanelKeyHint"
	p.add_child(label(text, "LabelKeyHint"))
	return p


## Currency pill: one plate holding icon 32 + Rowdies 24 value per entry, 24 gap. entries is an Array of
## {"icon": "cur_gem", "value": "1,240"}. Each value Label is named "value_<icon>" for later updates.
static func currency_pill(entries: Array) -> PanelContainer:
	var p := plate(&"plate")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("24"))
	p.add_child(row)
	for e in entries:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", UI3Theme.space("8"))
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		var tr_icon := TextureRect.new()
		tr_icon.texture = icon(String(e["icon"]))
		tr_icon.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_l")
		tr_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(tr_icon)
		var v := label(String(e["value"]), "LabelTitle")
		v.name = "value_" + String(e["icon"])
		cell.add_child(v)
		row.add_child(cell)
	return p


## Status chip above an Axie head: wood-2 pill, icon 22 + Rowdies 20 count in `tint`.
static func status_chip(icon_name: String, count: int, tint: Color) -> PanelContainer:
	var p := plate(&"info")
	p.theme_type_variation = "PanelInfo"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var ic := TextureRect.new()
	ic.texture = icon(icon_name)
	ic.custom_minimum_size = Vector2.ONE * 22
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	var n := label(str(count), "LabelDisplay")
	n.add_theme_font_size_override("font_size", 20)
	n.add_theme_color_override("font_color", tint)
	row.add_child(n)
	p.add_child(row)
	return p


## HP bar. kind: axie (10 h, green) | enemy (8 h, red-6) | boss (16 h, red-6). Shield is a blue segment
## on the same track after the HP; shield/poison > 0 also show a status chip row above the bar.
static func hp_bar(hp: int, max_hp: int, shield := 0, poison := 0, kind := &"axie") -> HpBarView:
	var b := HpBarView.new()
	b.kind = kind
	b.set_values(hp, max_hp, shield, poison)
	return b


## Die face tile. face: attack|shield|heal|poison|mana|buff|weaken|summon|blank. size: axie (88, radius 20)
## or egg (56, radius 14). state: normal (tilted by `tilt` degrees) | selected (lift -18, upright, deep
## shadow, 3 px cream outline at offset 5) | used (40% + "· used") | disabled (40%). The returned Control
## is focusable and shows the amber focus ring around the tile. Hit area = the tile itself.
static func die_tile(face: StringName, value: int, size := &"axie", state := &"normal", tilt := 0.0) -> Control:
	var egg := size == &"egg"
	var px := UI3Theme.size_of("die_egg" if egg else "die")
	var rad := UI3Theme.radius("die_egg" if egg else "die")
	var col := UI3Theme.color(String(FACE_COLOR.get(face, "face_blank")))
	var selected := state == &"selected"

	var root := VBoxContainer.new()
	root.theme = UI3Theme.get_theme()
	root.add_theme_constant_override("separation", 6)
	root.focus_mode = Control.FOCUS_ALL
	root.set_meta("face", face)
	root.set_meta("state", state)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(maxi(px + 8, 80), px + 12)   # room for the hard side shadow
	holder.name = "Holder"
	root.add_child(holder)

	var tile := Panel.new()
	tile.name = "Tile"
	tile.size = Vector2.ONE * px
	tile.position = Vector2((maxi(px + 8, 80) - px) / 2.0, -18 if selected else 0)
	tile.pivot_offset = tile.size * 0.5
	tile.rotation_degrees = 0.0 if selected else tilt
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI3Theme.flat(UI3Theme.color("die_body"), rad, 0, Color.TRANSPARENT, Vector4(0, 0, 0, 0),
		{"y": 12 if selected else 6, "color": col, "size": 1})
	tile.add_theme_stylebox_override("panel", sb)
	holder.add_child(tile)

	var col_box := VBoxContainer.new()
	col_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col_box.alignment = BoxContainer.ALIGNMENT_CENTER
	col_box.add_theme_constant_override("separation", 0)
	col_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col_box)
	var glyph := TextureRect.new()
	glyph.texture = icon(String(FACE_ICON.get(face, "face_blank")))
	var gpx := 22 if egg else 36
	glyph.custom_minimum_size = Vector2.ONE * gpx
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_box.add_child(glyph)
	var num := label("–" if face == &"blank" else str(value), "LabelDisplay")
	num.add_theme_font_size_override("font_size", UI3Theme.size_of("num_die_egg" if egg else "num_die"))
	num.add_theme_color_override("font_color", UI3Theme.color("die_ink"))
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_box.add_child(num)

	if selected:
		var ring := Panel.new()
		ring.name = "SelectedOutline"
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_theme_stylebox_override("panel", UI3Theme.selected_style(rad + 5, 3, 5))
		tile.add_child(ring)

	var word := label(face_word(face) + (TranslationServer.translate(" · used") if state == &"used" else ""), "LabelKeyHint")
	word.name = "Word"
	word.add_theme_color_override("font_color", UI3Theme.color(String(FACE_WORD_COLOR.get(face, "text"))))
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # "WEAKEN · used" wraps instead of widening the tile
	word.custom_minimum_size.x = maxi(px + 8, 80)
	root.add_child(word)

	if state == &"used" or state == &"disabled":
		root.modulate.a = 0.4
		root.focus_mode = Control.FOCUS_NONE
	else:
		attach_focus_ring(root, tile)
	return root


## Localized word for a face type ("ATTACK", "SHIELD", ...). Blank is "–" per the spec.
static func face_word(face: StringName) -> String:
	if face == &"blank":
		return "–"
	return TranslationServer.translate(String(face).to_upper())


## Modal / confirm dialog: full-rect root (mouse blocked) = neutral-1 @ 80% scrim + centred 560 w dialog
## (wood-1, radius 12, pad 32) with title (Rowdies 24), body (wrapped) and the `actions` Buttons right-aligned
## (build them with `button()`; connect their signals yourself). Add the result to a CanvasLayer (z 60).
## `focus_index` picks which action gets focus when the modal enters the tree (destructive: Cancel).
static func modal(title: String, body: String, actions: Array, focus_index := 0) -> Control:
	var root := Control.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = "Modal"
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := plate(&"dialog")
	dlg.name = "Dialog"
	dlg.custom_minimum_size = Vector2(560, 0)
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	dlg.add_child(col)
	col.add_child(label(title, "LabelTitle"))
	var b := label(body)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(row)
	for a in actions:
		row.add_child(a)
	if not actions.is_empty():
		var target: Control = actions[clampi(focus_index, 0, actions.size() - 1)]
		root.ready.connect(func() -> void: target.grab_focus.call_deferred())
	return root


## Toast: h 56, wood-1, 8 px status dot (tone ok = green-6, error = red-6), no actions. The host stacks
## at most 3 and removes them; this only builds one.
static func toast(text: String, tone := &"ok") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.theme_type_variation = "PanelToast"
	p.custom_minimum_size = Vector2(0, 56)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(row)
	var dot := Panel.new()
	dot.name = "Dot"
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color("hp" if tone == &"ok" else "hp_enemy"), 4))
	row.add_child(dot)
	row.add_child(label(text))
	return p


## Network notice: wood-2 row with text and a secondary S "Retry" button (`retry_text` localized by the
## caller). `reconnecting` swaps the button for a 24 px spinner. The button is named "Retry".
static func net_notice(text: String, retry_text: String, on_retry: Callable, reconnecting := false) -> PanelContainer:
	var p := plate(&"notice")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(row)
	var l := label(text)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	if reconnecting:
		row.add_child(Spinner.new())
	else:
		var b := button(retry_text, &"secondary", &"S")
		b.name = "Retry"
		if on_retry.is_valid():
			b.pressed.connect(on_retry)
		row.add_child(b)
	return p


## Skeleton row for loading lists: flat neutral-2 block, radius 8, default 72 high. Static (no pulse), so
## it respects reduce-motion by construction.
static func skeleton_row(height := 72) -> Panel:
	var p := Panel.new()
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size = Vector2(0, height)
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("locked_cell"), UI3Theme.radius("m")))
	return p


## Keyboard-focus ring (2 px amber, 4 px outside) shown while `control` has focus. The ring is a child of
## `host` (default: the control itself), full rect, mouse-ignoring, hidden until focus_entered. Do not
## use `host` = a Container that would resize it; for Buttons the Theme focus stylebox already does this.
static func attach_focus_ring(control: Control, host: Control = null) -> Panel:
	var h := host if host != null else control
	var ring := Panel.new()
	ring.name = "FocusRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.add_theme_stylebox_override("panel", UI3Theme.focus_style(UI3Theme.radius("l")))
	ring.visible = false
	h.add_child(ring)
	control.focus_entered.connect(func() -> void: ring.visible = true)
	control.focus_exited.connect(func() -> void: ring.visible = false)
	return ring


# ---------------------------------------------------------------- inner controls

## HP bar control: optional shield/poison chips above, then a 10/8/16 px track. Use `set_values` to update.
class HpBarView extends VBoxContainer:
	var kind: StringName = &"axie"
	var hp := 0
	var max_hp := 1
	var shield := 0
	var poison := 0
	var _chips := HBoxContainer.new()
	var _track := _Track.new()

	func _init() -> void:
		theme = UI3Theme.get_theme()
		add_theme_constant_override("separation", 4)
		_chips.add_theme_constant_override("separation", 4)
		add_child(_chips)
		add_child(_track)

	## Updates the numbers and redraws.
	func set_values(new_hp: int, new_max: int, new_shield := 0, new_poison := 0) -> void:
		hp = clampi(new_hp, 0, maxi(new_max, 1))
		max_hp = maxi(new_max, 1)
		shield = maxi(new_shield, 0)
		poison = maxi(new_poison, 0)
		for c in _chips.get_children():
			_chips.remove_child(c)
			c.queue_free()
		if shield > 0:
			_chips.add_child(UI3.status_chip("face_shield", shield, UI3Theme.color("shield")))
		if poison > 0:
			_chips.add_child(UI3.status_chip("status_poison", poison, UI3Theme.color("poison")))
		_chips.visible = shield > 0 or poison > 0
		_track.height = bar_height()
		_track.custom_minimum_size = Vector2(0, bar_height())
		_track.fill_color = UI3Theme.color("hp" if kind == &"axie" else "hp_enemy")
		_track.owner_bar = self
		_track.queue_redraw()

	## Bar thickness in px for this kind.
	func bar_height() -> int:
		return 10 if kind == &"axie" else (16 if kind == &"boss" else 8)

	class _Track extends Control:
		var height := 10
		var fill_color := Color.GREEN
		var owner_bar: HpBarView = null

		func _draw() -> void:
			var r := UI3Theme.radius("s")
			var w := size.x
			draw_style_box(UI3Theme.flat(UI3Theme.color("hp_track"), r), Rect2(0, 0, w, height))
			if owner_bar == null:
				return
			var total := float(maxi(owner_bar.max_hp, owner_bar.hp + owner_bar.shield))
			if owner_bar.shield > 0:
				var sw := w * float(owner_bar.hp + owner_bar.shield) / total
				draw_style_box(UI3Theme.flat(UI3Theme.color("shield"), r), Rect2(0, 0, sw, height))
			if owner_bar.hp > 0:
				var hw := maxf(w * float(owner_bar.hp) / total, float(r) * 2.0)
				draw_style_box(UI3Theme.flat(fill_color, r), Rect2(0, 0, hw, height))


## 24 px rotating arc ("reconnecting"). Stops rotating when the project's reduce-flashing/motion setting
## is on is NOT handled here yet (no such setting hook in the foundation): TODO with the first screen.
class Spinner extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _process(delta: float) -> void:
		rotation += delta * TAU * 0.75

	func _ready() -> void:
		pivot_offset = Vector2(12, 12)

	func _draw() -> void:
		draw_arc(Vector2(12, 12), 9, 0.0, TAU * 0.75, 24, UI3Theme.color("text"), 3.0, true)
