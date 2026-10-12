class_name HudKit
extends RefCounted
## Small builders for the Dice UI R1 combat HUD (design/handoffs/ui-02-round1b). Everything here
## resolves colours / outlines / type through DangoTheme, so the HUD cannot drift from the sheet.
## Pure UI: no game state is read or written here.

const ICON_DIR := "res://assets/icons/web/"
const HL_DIR := "res://assets/icons/hl/"


## Icon texture by short name. R1's new icons live in `assets/icons/hl/` (spike, attrition, lethal,
## aid, gift, mooncard, reroll, skip, undo); the old set stays in `assets/icons/web/`.
static func icon(name: String) -> Texture2D:
	for dir in [HL_DIR, ICON_DIR]:
		for ext in [".svg", ".png"]:
			var p: String = dir + name + ext
			if ResourceLoader.exists(p):
				return load(p)
	return null


## A glyph the display font actually has, else its ASCII fallback (U+2713 and the music note were
## already missing from every project font; do not assume arrows exist).
static func glyph(codepoint: int, fallback: String) -> String:
	var f: Font = DangoTheme.FONT_DISPLAY
	return String.chr(codepoint) if f != null and f.has_char(codepoint) else fallback


static func arrow() -> String:
	return glyph(0x2192, ">")


static func minus() -> String:
	return glyph(0x2212, "-")


static func dot() -> String:
	return glyph(0x00B7, "-")


## Baloo label. weight 800 default; `outline` > 0 draws the R1 numeral-over-scene outline.
static func label(text: String, size: int, color: Color = DangoTheme.INK, weight: int = 800,
		tracking_em: float = 0.0) -> Label:
	var l := DangoTheme.display_label(text, size, color, weight, tracking_em)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Work Sans (prose) label.
static func prose(text: String, size: int, color: Color = DangoTheme.INK_2) -> Label:
	var l := DangoTheme.prose_label(text, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func tex_rect(tex: Texture2D, px: int, modulate: Color = Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = modulate
	return t


## Flat box on the R1 outline. `fill` = mid of the sheet's 2-stop gradient.
static func box(fill: Color, radius: int, border_w: int = 3, border: Color = DangoTheme.OUTLINE,
		shelf: Vector2 = Vector2.ZERO, shelf_color: Color = DangoTheme.SHELF,
		pad: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad.x
	sb.content_margin_right = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_bottom = pad.y
	if shelf != Vector2.ZERO:
		sb.shadow_color = shelf_color
		sb.shadow_size = 0
		sb.shadow_offset = shelf
	return sb


## The standard raised panel: cream, 3px outline (HUD bars) or 4px LINE (panels).
static func panel(radius: int = 16, border_w: int = 3, line: bool = false, fill: Color = DangoTheme.PANEL,
		pad: Vector2 = Vector2(8, 0)) -> StyleBoxFlat:
	return box(fill, radius, border_w, DangoTheme.LINE if line else DangoTheme.OUTLINE,
		Vector2(3, 5), DangoTheme.SHELF, pad)


## Status chip: h26 (tray / plates), r8, border 2, icon 18, Baloo 14. `fill` CREAM_RAISED or
## SHIELD_CHIP. Tooltip optional.
static func status_chip(icon_tex: Texture2D, n: Variant, fill: Color = DangoTheme.CREAM_RAISED,
		tip: String = "") -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 26)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", box(fill, 8, 2, DangoTheme.OUTLINE, Vector2.ZERO,
		DangoTheme.SHELF, Vector2(5, 0)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	if icon_tex != null:
		row.add_child(tex_rect(icon_tex, 18))
	var ink := DangoTheme.INK_ON_SHIELD_CHIP if fill == DangoTheme.SHIELD_CHIP else DangoTheme.INK
	row.add_child(label(str(n), 14, ink))
	if tip != "":
		chip.tooltip_text = tip
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return chip


## "+N" overflow chip (dusk).
static func more_chip(n: int) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 26)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", box(DangoTheme.DUSK, 8, 2, DangoTheme.OUTLINE,
		Vector2.ZERO, DangoTheme.SHELF, Vector2(6, 0)))
	chip.add_child(label("+%d" % n, 14, DangoTheme.CREAM_RAISED))
	return chip


## Fill a chip row from a status dictionary + shield: shield first, max `cap` chips, then "+N".
## `icons` maps status key -> Texture2D, `tips` is a Callable(key, n) -> String.
static func fill_status_row(row: Control, status: Dictionary, shield: int, icons: Dictionary,
		tip_fn: Callable, cap: int = 4) -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var items: Array = []
	if shield > 0:
		items.append({"icon": DangoTheme.face_type_icon("shield"), "n": shield,
			"fill": DangoTheme.SHIELD_CHIP, "tip": tip_fn.call("shield", shield)})
	for key in icons:
		var v := int(status.get(key, 0))
		if v > 0:
			items.append({"icon": icons[key], "n": v, "fill": DangoTheme.CREAM_RAISED,
				"tip": tip_fn.call(key, v)})
	var shown := mini(items.size(), cap if items.size() <= cap else cap - 1)
	for i in shown:
		var it: Dictionary = items[i]
		row.add_child(status_chip(it["icon"], it["n"], it["fill"], it["tip"]))
	if items.size() > shown:
		row.add_child(more_chip(items.size() - shown))


# ── Boss clock / spike tab model (README 3) ─────────────────────────────────────────────────
const PIPS_FULL: Array[Color] = [Color("FFB23F"), Color("FF9345"), Color("F56A40"),
	Color("F54540"), Color("C9302B")]
const PIPS_LIGHT: Array[Color] = [Color("FFB23F"), Color("F56A40"), Color("C9302B")]


## Turns a `hud_state().clock` (+ optional `max_stacks`, `step_pct`) into the tab's look.
## Returns {} when the clock is not active (no tab). Keys: bg, ink, text, right, pips (Array of
## {fill: Color}), pip_empty, icon.
static func clock_tab(clock: Dictionary, turn: int, intent_total: int) -> Dictionary:
	if not bool(clock.get("active", false)):
		return {}
	var start := int(clock.get("start_turn", 10))
	var stacks := int(clock.get("stacks", 0))
	var pct := int(clock.get("pct", 0))
	var max_stacks := int(clock.get("max_stacks", 3 if (stacks > 0 and pct / maxi(stacks, 1) == 10) else 5))
	var step := int(clock.get("step_pct", 10 if max_stacks == 3 else 20))
	var light := max_stacks == 3
	var pips: Array[Color] = PIPS_LIGHT if light else PIPS_FULL
	var out := {"bg": DangoTheme.DUSK, "ink": DangoTheme.DUSK_INK, "text": "", "right": "",
		"pips": [], "icon": icon("boss-clock"), "maxed": false}
	if stacks <= 0:
		var left := start - turn
		if left > 1:
			out["text"] = "ENRAGE IN %d" % left
			out["right"] = "then +%d%%/turn" % step
		else:
			out["bg"] = DangoTheme.GOLD
			out["ink"] = DangoTheme.GOLD_INK
			out["text"] = "ENRAGE NEXT TURN"
			out["right"] = "+%d%%/turn" % step
		return out
	if stacks >= max_stacks:
		out["bg"] = DangoTheme.ASCENSION_RED
		out["ink"] = DangoTheme.CREAM_RAISED
		out["text"] = "ENRAGE MAX +%d%%" % pct
		out["right"] = "incl. in %d" % intent_total
		out["maxed"] = true
		for i in max_stacks:
			out["pips"].append(DangoTheme.CREAM_RAISED)
		return out
	out["bg"] = DangoTheme.GOLD_SOFT
	out["ink"] = DangoTheme.GOLD_INK
	out["text"] = "ENRAGE +%d%%" % pct
	out["right"] = "incl. in %d" % intent_total
	for i in max_stacks:
		out["pips"].append(pips[i] if i < stacks else DangoTheme.CREAM_300)
	return out
