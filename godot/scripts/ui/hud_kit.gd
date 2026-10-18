class_name HudKit
extends RefCounted
## Small builders for the Dice UI R1 combat HUD (design/handoffs/ui-02-round1b). Everything here
## resolves colours / outlines / type through UI3Theme tokens.
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
	for f: Font in [UI3Theme.font_display(), UI3Theme.font_body()]:
		if f != null and f.has_char(codepoint):
			return String.chr(codepoint)
	return fallback


static func arrow() -> String:
	return glyph(0x2192, ">")


static func minus() -> String:
	return glyph(0x2212, "-")


static func dot() -> String:
	return glyph(0x00B7, "-")


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
static func box(fill: Color, radius: int, border_w: int = 3, border: Color = Color.TRANSPARENT,
		shelf: Vector2 = Vector2.ZERO, shelf_color: Color = Color(0, 0, 0, 0.35),
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
static func panel(radius: int = 16, border_w: int = 3, line: bool = false, fill: Color = Color.TRANSPARENT,
		pad: Vector2 = Vector2(8, 0)) -> StyleBoxFlat:
	var f := fill if fill.a > 0.0 else UI3Theme.color("panel")
	var edge := UI3Theme.color("btn_secondary") if line else UI3Theme.color("panel_raised")
	return box(f, radius, border_w, edge, Vector2.ZERO, Color.TRANSPARENT, pad)


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
	var out := {"bg": UI3Theme.color("panel_raised"), "ink": UI3Theme.color("accent"), "text": "", "right": "",
		"pips": [], "icon": icon("boss-clock"), "maxed": false}
	if stacks <= 0:
		var left := start - turn
		if left > 1:
			out["text"] = "ENRAGE IN %d" % left
			out["right"] = "then +%d%%/turn" % step
		else:
			out["bg"] = UI3Theme.color("accent")
			out["ink"] = UI3Theme.color("accent_text")
			out["text"] = "ENRAGE NEXT TURN"
			out["right"] = "+%d%%/turn" % step
		return out
	if stacks >= max_stacks:
		out["bg"] = UI3Theme.color("danger")
		out["ink"] = UI3Theme.color("text")
		out["text"] = "ENRAGE MAX +%d%%" % pct
		out["right"] = "incl. in %d" % intent_total
		out["maxed"] = true
		for i in max_stacks:
			out["pips"].append(UI3Theme.color("text"))
		return out
	out["bg"] = UI3Theme.color("accent")
	out["ink"] = UI3Theme.color("accent_text")
	out["text"] = "ENRAGE +%d%%" % pct
	out["right"] = "incl. in %d" % intent_total
	for i in max_stacks:
		out["pips"].append(pips[i] if i < stacks else UI3Theme.color("btn_secondary"))
	return out
