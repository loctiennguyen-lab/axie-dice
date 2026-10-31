class_name Ui5MetaTok
extends RefCounted
## UI-05 b23 lane 0d: token lookup with a fallback for the B3 keys that tokens_ui3.json does not have yet (another lane is
## merging them). A key that exists is read through UI3Theme (so the 1280 interpolation applies); a missing one returns the
## round-3 tokens.json value (1920) or, when UI3Theme.is_small(), the round-3 1280 override divided by the layout scale.
## Once B3 lands the fallbacks are never used. Keys that needed a fallback: see Ui5MetaTok.FALLBACK_KEYS.

const FALLBACK_KEYS := ["toast_dot", "toast_max_w", "toast_under_banner", "toggle_on", "toast_ok", "toast_error",
	"mission_detail_w", "pass_detail_w", "store_detail_w", "profile_detail_w", "mission_row_h", "settings_row_h"]


## Colour token or `fallback` (html hex) when the token is missing.
static func col(key: String, fallback: String) -> Color:
	if (UI3Theme.tokens().get("color", {}) as Dictionary).has(key):
		return UI3Theme.color(key)
	return Color.html(fallback)


## Size token (logical px) or the round-3 value. v1280 = the design's real-px value at 1280 (-1 = same as 1920).
static func px(key: String, v1920: int, v1280 := -1) -> int:
	var s: Dictionary = UI3Theme.tokens().get("size", {})
	if s.has(key) and typeof(s[key]) != TYPE_DICTIONARY:
		return UI3Theme.size_of(key)
	if UI3Theme.is_small() and v1280 >= 0:
		return int(round(float(v1280) / UI3Theme.layout_scale()))
	return v1920


## Label with a font size token and colour token, vertically centred (never clips its own line).
static func text(t: String, size_token := "text_body", color_token := "text", display := false) -> Label:
	var l := UI3.label(t, "LabelDisplay" if display else "")
	l.add_theme_font_size_override("font_size", UI3Theme.size_of(size_token))
	l.add_theme_color_override("font_color", UI3Theme.color(color_token))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
