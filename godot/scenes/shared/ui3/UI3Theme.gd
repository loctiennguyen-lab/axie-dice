class_name UI3Theme
extends RefCounted
## UI-03 "A4 Blend" (Terrariums design system) foundation: token loader + the Godot Theme.
##
## Single source of truth is `res://assets/data/ui/tokens_ui3.json` (copied verbatim from the Claude
## Design handoff). Nothing here hardcodes a colour or size that the tokens already name, so a new
## handoff drop means replacing that one JSON file.
##
## NOT a replacement for DangoTheme yet: no existing screen uses this. New screens apply
## `UI3Theme.get_theme()` on their root Control (or use the `UI3` builders, which do it for you).
##
## FONTS: tokens name Rowdies-Bold.ttf (display) and WorkSans-Regular.ttf (body). They are not in the
## repo yet. `font_display()` / `font_body()` look for `res://assets/fonts/<file from tokens>` and fall
## back to Baloo2-Bold / WorkSans-Medium with ONE push_warning for the whole session. Dropping the TTFs
## into assets/fonts/ (and running --import) needs no code change.
##
## THEME TYPE VARIATIONS (set `theme_type_variation` on the node):
##   Button:         ButtonPrimaryL, ButtonPrimaryM, ButtonSecondary (M 56), ButtonSecondaryS (48),
##                   ButtonDanger, ButtonQuiet, IconButton
##   PanelContainer: PanelPlate, PanelCard, PanelCardSelected, PanelDialog, PanelRow, PanelNotice,
##                   PanelChip, PanelKeyHint, PanelInfo, PanelToast
##   ProgressBar:    ProgressBarHP, ProgressBarEnemy, ProgressBarBoss
##   Label:          LabelTitle (24), LabelScreenTitle (32), LabelKeyHint (16), LabelMuted, LabelDisplay (18)
## Plus plain defaults for TabBar/TabContainer, LineEdit, H/VScrollBar, TooltipPanel/TooltipLabel.

const TOKENS_PATH := "res://assets/data/ui/tokens_ui3.json"
const FONT_DIR := "res://assets/fonts/"
const FALLBACK_DISPLAY := "res://assets/fonts/Baloo2-Bold.ttf"
const FALLBACK_BODY := "res://assets/fonts/WorkSans-Medium.ttf"

## Scrollbar grabber shades (wood-4 / 5 / 6). The handoff names them in components.md but tokens.json
## carries no hex for them; wood-4 matches the secondary button hover in the tokens, 5 and 6 are the
## next steps up the same ramp. Replace here when the design system publishes them.
const SCROLL_GRABBER := "#794225"
const SCROLL_GRABBER_HOVER := "#8f5230"
const SCROLL_GRABBER_PRESSED := "#a76238"
## Scrollbar thickness (components.md: ScrollBar 8 w).
const SCROLL_W := 8
## HP bar thickness per kind (components.md ProgressBar row). Single source for theme and UI3.hp_bar.
const HP_BAR_H := {&"axie": 10, &"enemy": 8, &"boss": 16}

static var _tokens: Dictionary = {}
static var _theme: Theme = null
static var _font_display: Font = null
static var _font_body: Font = null
static var _font_warned := false


# ---------------------------------------------------------------- tokens

## Parsed tokens_ui3.json (cached). Empty dictionary and an error if the file is missing or invalid.
static func tokens() -> Dictionary:
	if _tokens.is_empty():
		var f := FileAccess.open(TOKENS_PATH, FileAccess.READ)
		if f == null:
			push_error("UI3Theme: cannot open %s" % TOKENS_PATH)
			return {}
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("UI3Theme: %s is not a JSON object" % TOKENS_PATH)
			return {}
		_tokens = parsed
	return _tokens


## Colour token by name (tokens.color.<name>.value). Alpha comes from #RRGGBBAA. Magenta + error if unknown.
static func color(token: String) -> Color:
	var entry: Variant = (tokens().get("color", {}) as Dictionary).get(token)
	if entry == null:
		push_error("UI3Theme: unknown colour token '%s'" % token)
		return Color.MAGENTA
	return Color.html(String((entry as Dictionary).get("value", "#ff00ff")))


## Parses a "#rrggbb" / "#rrggbbaa" literal (theme items in the tokens carry raw hex).
static func hex(value: String) -> Color:
	return Color.html(value)


## Integer size token (tokens.size.<name>), e.g. size_of("btn_m") == 56. Use `size_dict` for w/h pairs.
static func size_of(token: String) -> int:
	var v: Variant = (tokens().get("size", {}) as Dictionary).get(token)
	if v == null or typeof(v) == TYPE_DICTIONARY:
		push_error("UI3Theme: unknown or non-scalar size token '%s'" % token)
		return 0
	return int(v)


## Size token that is a {w,h} pair (axie_combat, enemy_combat, ...) as a Vector2.
static func size_dict(token: String) -> Vector2:
	var v: Variant = (tokens().get("size", {}) as Dictionary).get(token)
	if typeof(v) != TYPE_DICTIONARY:
		push_error("UI3Theme: size token '%s' is not a w/h pair" % token)
		return Vector2.ZERO
	return Vector2(float((v as Dictionary).get("w", 0)), float((v as Dictionary).get("h", 0)))


## Corner radius token in px (s 4, m 8, l 12, die 20, die_egg 14, pill 999).
static func radius(token: String) -> int:
	return _int_token("radius", token)


## Spacing token in px (4, 8, 12, 16, 24, 32, 40, 48, 64, screen_margin). Pass "16" or "screen_margin".
static func space(token: String) -> int:
	return _int_token("space", token)


## Stroke token in px (hairline 2, selected 4, focus 2, focus_offset 4).
static func stroke(token: String) -> int:
	return _int_token("stroke", token)


## Motion duration in seconds for fast/base/slow/banner_hold/roll_total (tokens store milliseconds).
static func motion_sec(token: String) -> float:
	return float(_int_token("motion", token)) / 1000.0


static func _int_token(group: String, token: String) -> int:
	var v: Variant = (tokens().get(group, {}) as Dictionary).get(token)
	if v == null or typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_STRING:
		push_error("UI3Theme: unknown %s token '%s'" % [group, token])
		return 0
	return int(v)


# ---------------------------------------------------------------- fonts

## Display face (titles, numbers, buttons, tabs): Rowdies Bold, or the Baloo 2 fallback.
static func font_display() -> Font:
	if _font_display == null:
		_font_display = _resolve_font("display", "700", FALLBACK_DISPLAY)
	return _font_display


## Body face (everything the player reads): Work Sans Regular, or the Work Sans Medium fallback.
static func font_body() -> Font:
	if _font_body == null:
		_font_body = _resolve_font("body", "400", FALLBACK_BODY)
	return _font_body


## True when both real faces from the tokens are present (no fallback in use).
static func fonts_are_final() -> bool:
	return _font_path("display", "700") != "" and _font_path("body", "400") != ""


static func _font_path(family: String, weight: String) -> String:
	var fam: Dictionary = (tokens().get("font", {}) as Dictionary).get(family, {})
	var file := String((fam.get("weights", {}) as Dictionary).get(weight, ""))
	if file == "":
		return ""
	var path := FONT_DIR + file
	return path if ResourceLoader.exists(path) else ""


static func _resolve_font(family: String, weight: String, fallback: String) -> Font:
	var path := _font_path(family, weight)
	if path == "":
		path = fallback
		if not _font_warned:
			_font_warned = true
			push_warning("UI3Theme: Rowdies/Work Sans TTF not in assets/fonts yet, using Baloo 2 / Work Sans Medium fallback")
	return load(path) as Font


# ---------------------------------------------------------------- theme

## The shared Theme (built once, cached). Safe to assign to any number of roots.
static func get_theme() -> Theme:
	if _theme == null:
		_theme = build_theme()
	return _theme


## Drops the cached tokens/theme/fonts (tests, hot reload after dropping in the real TTFs).
static func reset_cache() -> void:
	_tokens = {}
	_theme = null
	_font_display = null
	_font_body = null


## Builds a fresh Theme from the tokens. Prefer `get_theme()`.
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_body()
	t.default_font_size = size_of("text_body")
	var cream := color("text")

	_build_labels(t, cream)
	_build_buttons(t, cream)
	_build_panels(t)
	_build_tabs(t, cream)
	_build_line_edit(t, cream)
	_build_progress(t)
	_build_scroll(t)
	_build_slider_check(t, cream)
	_build_tooltip(t, cream)
	return t


## Maps a `tokens.theme` key to where the built Theme stores it: {type, kind, name} with kind one of
## "stylebox" / "font_size". Empty when the key has no mapping (the t_ui3_theme test fails on that).
static func theme_item_for(key: String) -> Dictionary:
	var p := key.split("/")
	match p[0]:
		"Button":
			var variant := {"primary": "ButtonPrimaryL", "secondary": "ButtonSecondary",
				"danger": "ButtonDanger", "quiet": "ButtonQuiet"}
			if p.size() == 4 and p[2] == "styles" and variant.has(p[1]):
				return {"type": variant[p[1]], "kind": "stylebox", "name": p[3]}
		"Tab":
			if p.size() == 3 and p[1] == "styles":
				return {"type": "TabBar", "kind": "stylebox",
					"name": "tab_selected" if p[2] == "selected" else "tab_unselected"}
		"Panel":
			var pv := {"plate": "PanelPlate", "card": "PanelCard", "card_selected": "PanelCardSelected",
				"dialog": "PanelDialog", "row": "PanelRow", "notice": "PanelNotice"}
			if p.size() == 2 and pv.has(p[1]):
				return {"type": pv[p[1]], "kind": "stylebox", "name": "panel"}
		"ProgressBar":
			var bars := {"hp": "ProgressBarHP", "enemy_hp": "ProgressBarEnemy"}
			if p.size() == 2 and bars.has(p[1]):
				return {"type": bars[p[1]], "kind": "stylebox", "name": "fill"}
		"Label":
			if p.size() == 3 and p[1] == "font_sizes":
				return {"type": "Label", "kind": "font_size", "name": p[2]}
	return {}


# --- styleboxes

## Flat box from token-style fields. `shadow` = {y, color} hard offset shadow (size 1 = no blur).
static func flat(bg: Color, radius_px: int, border_px := 0, border_col := Color.TRANSPARENT,
		margins := Vector4(0, 0, 0, 0), shadow := {}) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius_px)
	if border_px > 0:
		s.set_border_width_all(border_px)
		s.border_color = border_col
	s.content_margin_left = margins.x
	s.content_margin_top = margins.y
	s.content_margin_right = margins.z
	s.content_margin_bottom = margins.w
	if not shadow.is_empty():
		s.shadow_color = shadow["color"]
		s.shadow_offset = Vector2(0, float(shadow["y"]))
		s.shadow_size = int(shadow.get("size", 1))
	s.anti_aliasing = true
	return s


## The focus ring: 2 px amber outline drawn 4 px outside the control, no fill (components.md).
static func focus_style(radius_px := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(stroke("focus"))
	s.border_color = color("focus_ring")
	s.set_corner_radius_all(radius_px)
	s.set_expand_margin_all(stroke("focus_offset"))
	s.anti_aliasing = true
	return s


## The "selected" outline: 4 px cream, no fill (cards, rows, tiles).
static func selected_style(radius_px := 12, width_px := 0, offset_px := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(width_px if width_px > 0 else stroke("selected"))
	s.border_color = color("selected_outline")
	s.set_corner_radius_all(radius_px)
	s.set_expand_margin_all(offset_px)
	s.anti_aliasing = true
	return s


static func _theme_entry(key: String) -> Dictionary:
	return (tokens().get("theme", {}) as Dictionary).get(key, {})


static func _margins(entry: Dictionary, fallback := Vector4(0, 0, 0, 0)) -> Vector4:
	var m: Variant = entry.get("content_margin")
	if m is Array and (m as Array).size() == 4:
		return Vector4(m[0], m[1], m[2], m[3])
	return fallback


static func _shadow(entry: Dictionary) -> Dictionary:
	var sh: Variant = entry.get("shadow")
	if sh is Dictionary:
		var d: Dictionary = (sh as Dictionary).duplicate()
		d["color"] = hex(String(d.get("color", "#000000")))
		return d
	return {}


## Builds the normal style of a button variant from tokens, with its pressed 2 px drop.
static func _btn_style(state: String, entry_key: String, variant: String, extra_h := 0) -> StyleBoxFlat:
	var base := _theme_entry("Button/%s/styles/normal" % variant)
	var e := _theme_entry(entry_key)
	var bg := hex(String(e.get("bg", base.get("bg", "#ff00ff"))))
	var rad := int(e.get("radius", base.get("radius", radius("m"))))
	var margins := _margins(base)
	if extra_h != 0:
		margins = Vector4(extra_h, 0, extra_h, 0)
	var border := int(e.get("border", 0))
	var bcol := hex(String(e.get("border_color", "#00000000")))
	var shadow := {}
	match state:
		"normal", "hover":
			shadow = _shadow(base)
		"pressed":
			shadow = _shadow(base)
			if not shadow.is_empty():
				shadow["y"] = 2
			# Whole control moves down 2 px, label included: shift box via expand margins, label via margin.
		"disabled":
			shadow = {}
	var s := flat(bg, rad, border, bcol, margins, shadow)
	if state == "pressed":
		s.content_margin_top += 4
		s.expand_margin_top = -2
		s.expand_margin_bottom = 2
	return s


static func _derived_hover(variant: String) -> Color:
	var e := _theme_entry("Button/%s/styles/hover" % variant)
	return hex(String(e.get("bg", "#ffffff")))


static func _style_button_variant(t: Theme, type_name: String, variant: String, font_px: int,
		min_h: int, margin_x: int, fg: Color, quiet := false) -> void:
	t.set_type_variation(type_name, "Button")
	var key := "Button/%s/styles/" % variant
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBox
		if quiet:
			sb = StyleBoxEmpty.new()
			(sb as StyleBoxEmpty).content_margin_left = 8
			(sb as StyleBoxEmpty).content_margin_right = 8
		else:
			var src_key: String = key + state
			if not tokens()["theme"].has(src_key):
				# Tokens give pressed/disabled only for some variants: derive from the variant's own base.
				src_key = "Button/secondary/styles/" + state if state == "disabled" else key + "normal"
			var s := _btn_style(state, src_key, variant, margin_x)
			if state == "hover" and not tokens()["theme"].has(key + "hover"):
				s.bg_color = s.bg_color.lightened(0.1)
			sb = s
		t.set_stylebox(state, type_name, sb)
	var focus := focus_style(radius("l"))
	t.set_stylebox("focus", type_name, focus)
	t.set_font("font", type_name, font_body() if quiet else font_display())
	t.set_font_size("font_size", type_name, font_px)
	var dis := color("text_on_viewport")
	t.set_color("font_color", type_name, fg)
	t.set_color("font_hover_color", type_name, fg)
	t.set_color("font_pressed_color", type_name, fg)
	t.set_color("font_focus_color", type_name, fg)
	t.set_color("font_hover_pressed_color", type_name, fg)
	t.set_color("font_disabled_color", type_name, dis)
	t.set_constant("outline_size", type_name, 0)
	t.set_constant("h_separation", type_name, 8)
	# min height cannot live in a theme: UI3.button() applies it. Recorded as constant for the builders.
	t.set_constant("min_height", type_name, min_h)


static func _build_buttons(t: Theme, cream: Color) -> void:
	var on_accent := color("accent_text")
	_style_button_variant(t, "ButtonPrimaryL", "primary", size_of("text_screen_title"), size_of("btn_l"), space("48"), on_accent)
	_style_button_variant(t, "ButtonPrimaryM", "primary", size_of("text_body"), size_of("btn_m"), space("32"), on_accent)
	_style_button_variant(t, "ButtonSecondary", "secondary", size_of("text_body"), size_of("btn_m"), space("24"), cream)
	_style_button_variant(t, "ButtonSecondaryS", "secondary", size_of("text_body"), size_of("btn_s"), space("16"), cream)
	_style_button_variant(t, "ButtonDanger", "danger", size_of("text_body"), size_of("btn_m"), space("24"), cream)
	# Danger pressed / disabled are not in the tokens: derived from normal / secondary disabled above.
	_style_button_variant(t, "ButtonQuiet", "quiet", size_of("text_body"), size_of("hit_min"), space("8"), color("text_muted"), true)
	t.set_color("font_hover_color", "ButtonQuiet", color("text"))
	t.set_color("font_pressed_color", "ButtonQuiet", color("text"))

	# IconButton: 48x48, radius 8, wood-3 / wood-4 / pressed y+2 / neutral-4.
	t.set_type_variation("IconButton", "Button")
	var sec := "Button/secondary/styles/"
	var rad := radius("m")
	var n := flat(hex(String(_theme_entry(sec + "normal")["bg"])), rad)
	var h := flat(color("btn_secondary").lightened(0.15), rad)
	var p := flat(hex(String(_theme_entry(sec + "pressed")["bg"])), rad)
	p.content_margin_top = 4
	p.expand_margin_top = -2
	p.expand_margin_bottom = 2
	var d := flat(color("disabled"), rad, stroke("hairline"), color("disabled_border"))
	t.set_stylebox("normal", "IconButton", n)
	t.set_stylebox("hover", "IconButton", h)
	t.set_stylebox("pressed", "IconButton", p)
	t.set_stylebox("disabled", "IconButton", d)
	t.set_stylebox("focus", "IconButton", focus_style(radius("l")))
	t.set_constant("icon_max_width", "IconButton", size_of("icon_l"))
	t.set_constant("min_height", "IconButton", size_of("btn_s"))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "IconButton", cream)
	# Glyphs ship white: tint them cream (never white text/icons) in every state, dimmed when disabled.
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		t.set_color(c, "IconButton", cream)
	t.set_color("icon_disabled_color", "IconButton", Color(cream, 0.5))


static func _build_panels(t: Theme) -> void:
	var map := {"PanelPlate": "Panel/plate", "PanelCard": "Panel/card",
		"PanelCardSelected": "Panel/card_selected", "PanelDialog": "Panel/dialog",
		"PanelRow": "Panel/row", "PanelNotice": "Panel/notice"}
	var card_margins := _margins(_theme_entry("Panel/card"))
	for type_name in map:
		var e := _theme_entry(map[type_name])
		# card_selected has no content_margin in the tokens: it must keep the card's 24 px padding, the
		# 4 px outline is drawn inside the border width and must not eat it.
		var m := _margins(e, card_margins if type_name == "PanelCardSelected" else Vector4(0, 0, 0, 0))
		var sb := flat(hex(String(e["bg"])), int(e["radius"]), int(e.get("border", 0)),
			hex(String(e.get("border_color", "#00000000"))), m, _shadow(e))
		t.set_type_variation(type_name, "PanelContainer")
		t.set_stylebox("panel", type_name, sb)
	# Plain defaults: PanelContainer/Panel get the plate.
	var plate := t.get_stylebox("panel", "PanelPlate")
	t.set_stylebox("panel", "PanelContainer", plate)
	t.set_stylebox("panel", "Panel", plate)
	# Components without their own token entry.
	var chip := flat(color("accent"), radius("s"), 0, Color.TRANSPARENT, Vector4(12, 0, 12, 0))
	t.set_type_variation("PanelChip", "PanelContainer")
	t.set_stylebox("panel", "PanelChip", chip)
	var hint := flat(Color.TRANSPARENT, radius("s"), stroke("hairline"), color("disabled_border"),
		Vector4(8, 2, 8, 2))
	t.set_type_variation("PanelKeyHint", "PanelContainer")
	t.set_stylebox("panel", "PanelKeyHint", hint)
	var info := flat(color("panel_raised"), radius("m"), 0, Color.TRANSPARENT, Vector4(12, 10, 12, 10))
	t.set_type_variation("PanelInfo", "PanelContainer")
	t.set_stylebox("panel", "PanelInfo", info)
	var toast := flat(color("panel"), radius("m"), 0, Color.TRANSPARENT, Vector4(16, 0, 16, 0))
	t.set_type_variation("PanelToast", "PanelContainer")
	t.set_stylebox("panel", "PanelToast", toast)


static func _build_labels(t: Theme, cream: Color) -> void:
	t.set_color("font_color", "Label", cream)
	t.set_font("font", "Label", font_body())
	t.set_font_size("font_size", "Label", size_of("text_body"))
	# The tokens' named sizes live as theme font sizes so a node can read them with get_theme_font_size.
	for k in ["body", "title", "screen_title", "key_hint"]:
		t.set_font_size(k, "Label", _theme_font_size_raw(k))
	var variants := {
		"LabelTitle": [font_display(), "title", cream],
		"LabelScreenTitle": [font_display(), "screen_title", cream],
		"LabelDisplay": [font_display(), "body", cream],
		"LabelKeyHint": [font_body(), "key_hint", color("text_muted")],
		"LabelMuted": [font_body(), "body", color("text_muted")],
	}
	for v in variants:
		t.set_type_variation(v, "Label")
		t.set_font("font", v, variants[v][0])
		t.set_font_size("font_size", v, _theme_font_size_raw(variants[v][1]))
		t.set_color("font_color", v, variants[v][2])


static func _theme_font_size_raw(k: String) -> int:
	return int((tokens().get("theme", {}) as Dictionary).get("Label/font_sizes/" + k, size_of("text_body")))


static func _build_tabs(t: Theme, cream: Color) -> void:
	var n := _theme_entry("Tab/styles/normal")
	var s := _theme_entry("Tab/styles/selected")
	var margins := Vector4(space("24"), 0, space("24"), 0)
	var un := flat(hex(String(n["bg"])), int(n["radius"]), 0, Color.TRANSPARENT, margins)
	var hov := flat(color("panel_raised"), int(n["radius"]), 0, Color.TRANSPARENT, margins)
	var sel := flat(hex(String(s.get("bg", "#58321d"))), int(n["radius"]), int(s["border"]),
		hex(String(s["border_color"])), margins)
	var dis := flat(color("disabled"), int(n["radius"]), 0, Color.TRANSPARENT, margins)
	for type_name in ["TabBar", "TabContainer"]:
		t.set_stylebox("tab_unselected", type_name, un)
		t.set_stylebox("tab_hovered", type_name, hov)
		t.set_stylebox("tab_selected", type_name, sel)
		t.set_stylebox("tab_disabled", type_name, dis)
		t.set_stylebox("tab_focus", type_name, focus_style(radius("l")))
		t.set_font("font", type_name, font_display())
		t.set_font_size("font_size", type_name, size_of("text_body"))
		for c in ["font_selected_color", "font_unselected_color", "font_hovered_color"]:
			t.set_color(c, type_name, cream)
		t.set_color("font_disabled_color", type_name, color("text_on_viewport"))
		t.set_constant("h_separation", type_name, 8)
	t.set_stylebox("panel", "TabContainer", t.get_stylebox("panel", "PanelPlate"))


static func _build_line_edit(t: Theme, cream: Color) -> void:
	var m := Vector4(16, 8, 16, 8)
	var normal := flat(color("panel_raised"), radius("m"), stroke("hairline"), color("disabled_border"), m)
	var ro := flat(color("locked_cell"), radius("m"), stroke("hairline"), color("disabled_border"), m)
	t.set_stylebox("normal", "LineEdit", normal)
	t.set_stylebox("read_only", "LineEdit", ro)
	t.set_stylebox("focus", "LineEdit", focus_style(radius("l")))
	t.set_font("font", "LineEdit", font_body())
	t.set_font_size("font_size", "LineEdit", size_of("text_body"))
	t.set_color("font_color", "LineEdit", cream)
	t.set_color("font_uneditable_color", "LineEdit", color("text_muted"))
	t.set_color("font_placeholder_color", "LineEdit", color("text_muted"))
	t.set_color("caret_color", "LineEdit", color("accent"))
	t.set_color("selection_color", "LineEdit", color("accent"))
	t.set_color("font_selected_color", "LineEdit", color("accent_text"))
	t.set_constant("minimum_character_width", "LineEdit", 4)


static func _build_progress(t: Theme) -> void:
	var specs := {
		"ProgressBarHP": ["ProgressBar/hp", "hp", HP_BAR_H[&"axie"]],
		"ProgressBarEnemy": ["ProgressBar/enemy_hp", "hp_enemy", HP_BAR_H[&"enemy"]],
		"ProgressBarBoss": ["ProgressBar/enemy_hp", "hp_enemy", HP_BAR_H[&"boss"]],
	}
	for type_name in specs:
		var spec: Array = specs[type_name]
		var e := _theme_entry(spec[0])
		var rad := int(e.get("radius", 4))
		var bg := flat(hex(String(e["bg"])), rad)
		var fill := flat(hex(String(e["fill"])), rad)
		for sb in [bg, fill]:
			(sb as StyleBoxFlat).content_margin_top = 0
			(sb as StyleBoxFlat).content_margin_bottom = 0
		t.set_type_variation(type_name, "ProgressBar")
		t.set_stylebox("background", type_name, bg)
		t.set_stylebox("fill", type_name, fill)
		t.set_constant("min_height", type_name, spec[2])
	# Default ProgressBar (pass tier, generic): amber fill, 16 high.
	var gen_bg := flat(color("hp_track"), radius("s"))
	var gen_fill := flat(color("accent"), radius("s"))
	t.set_stylebox("background", "ProgressBar", gen_bg)
	t.set_stylebox("fill", "ProgressBar", gen_fill)
	t.set_font_size("font_size", "ProgressBar", size_of("text_key_hint"))


static func _build_scroll(t: Theme) -> void:
	var rad := radius("s")
	var w := SCROLL_W
	for type_name in ["VScrollBar", "HScrollBar"]:
		var vertical: bool = type_name == "VScrollBar"
		var track := flat(color("panel"), rad)
		var grab := flat(hex(SCROLL_GRABBER), rad)
		var grab_hi := flat(hex(SCROLL_GRABBER_HOVER), rad)
		var grab_pr := flat(hex(SCROLL_GRABBER_PRESSED), rad)
		for f in [track, grab, grab_hi, grab_pr]:
			if vertical:
				f.content_margin_left = w
				f.content_margin_right = 0
			else:
				f.content_margin_top = w
				f.content_margin_bottom = 0
		t.set_stylebox("scroll", type_name, track)
		t.set_stylebox("scroll_focus", type_name, track)
		t.set_stylebox("grabber", type_name, grab)
		t.set_stylebox("grabber_highlight", type_name, grab_hi)
		t.set_stylebox("grabber_pressed", type_name, grab_pr)


static func _build_tooltip(t: Theme, cream: Color) -> void:
	t.set_stylebox("panel", "TooltipPanel", flat(color("panel"), radius("m"), stroke("hairline"),
		color("disabled_border"), Vector4(12, 8, 12, 8)))
	t.set_font("font", "TooltipLabel", font_body())
	t.set_font_size("font_size", "TooltipLabel", size_of("text_body"))
	t.set_color("font_color", "TooltipLabel", cream)


# ---------------------------------------------------------------- contrast

## WCAG relative luminance of an opaque colour.
static func luminance(c: Color) -> float:
	var ch := PackedFloat32Array()
	for v in [c.r, c.g, c.b]:
		ch.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]


## WCAG contrast ratio of `fg` on `bg`. Translucent colours are composited over `under`
## (tokens: "contrast is measured with plates over neutral-4").
static func contrast_ratio(fg: Color, bg: Color, under: Color) -> float:
	var back := under.blend(bg) if bg.a < 1.0 else bg
	back.a = 1.0
	var front := back.blend(fg) if fg.a < 1.0 else fg
	front.a = 1.0
	var a := luminance(front)
	var b := luminance(back)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


## HSlider + CheckBox (Settings rows; components.md: row-embedded Slider / Toggle). Track = hp_track,
## filled part = accent, grabber = cream disc with an accent ring; check box = cream-outlined square
## on wood, accent fill + dark tick when on. Drawn into images so no new asset files are needed.
static func _build_slider_check(t: Theme, cream: Color) -> void:
	var rad := radius("s")
	var track := flat(color("hp_track"), rad)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := flat(color("accent"), rad)
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var knob := _disc_icon(28, cream, color("accent"), 3)
	var knob_hi := _disc_icon(28, color("accent_text"), color("accent"), 3)
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", knob_hi)
	t.set_icon("grabber_disabled", "HSlider", _disc_icon(28, color("disabled"), color("disabled_border"), 3))
	t.set_constant("center_grabber", "HSlider", 0)

	var off := _box_icon(28, color("panel"), cream, false)
	var on := _box_icon(28, color("accent"), cream, true)
	t.set_icon("unchecked", "CheckBox", off)
	t.set_icon("checked", "CheckBox", on)
	t.set_icon("unchecked_disabled", "CheckBox", _box_icon(28, color("panel"), color("disabled_border"), false))
	t.set_icon("checked_disabled", "CheckBox", _box_icon(28, color("disabled"), color("disabled_border"), true))
	t.set_constant("h_separation", "CheckBox", 12)
	# No button plate behind a check box: the row is the plate (otherwise cream text on a cream pill).
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var none := StyleBoxEmpty.new()
		none.content_margin_left = 4
		none.content_margin_right = 4
		none.content_margin_top = 4
		none.content_margin_bottom = 4
		t.set_stylebox(st, "CheckBox", none)
	t.set_stylebox("focus", "CheckBox", focus_style(rad))
	t.set_color("font_color", "CheckBox", cream)
	t.set_color("font_hover_color", "CheckBox", cream)
	t.set_color("font_pressed_color", "CheckBox", cream)
	t.set_color("font_focus_color", "CheckBox", cream)
	t.set_font_size("font_size", "CheckBox", size_of("text_body"))


static func _disc_icon(px: int, fill_col: Color, ring: Color, ring_px: int) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	for y in px:
		for x in px:
			var d := Vector2(x - c, y - c).length()
			var r := px / 2.0
			if d <= r - ring_px:
				img.set_pixel(x, y, fill_col)
			elif d <= r:
				img.set_pixel(x, y, ring)
	return ImageTexture.create_from_image(img)


static func _box_icon(px: int, fill_col: Color, border: Color, ticked: bool) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var bw := 3
	var tick := color("bg")
	for y in px:
		for x in px:
			var edge := x < bw or y < bw or x >= px - bw or y >= px - bw
			img.set_pixel(x, y, border if edge else fill_col)
	if ticked:
		# Two strokes: down-right short, then up-right long.
		for i in 6:
			for w in 3:
				img.set_pixel(7 + i, 14 + i - 1 + w, tick)
		for i in 11:
			for w in 3:
				img.set_pixel(12 + i, 19 - i + w, tick)
	return ImageTexture.create_from_image(img)
