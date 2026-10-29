class_name Ui5Ellipsis
extends RefCounted
## UI-05 b1 (B9, QA 29/10): names that do not fit end in "…", always.
##
## Godot's Label OVERRUN_TRIM_ELLIPSIS adds the "…" only when enough characters stay in front of it; a short name a
## few px too wide ("Pomodoro" in a 152 px DieCard) was cut to "Pomodor" with no ellipsis at all. set_text() keeps
## the full text on the label (meta) and shows the longest prefix + "…" that fits the label's own
## width, refitting whenever the label is resized. The Label's own overrun stays on as a backstop.

const META := &"ui5_full_text"
const MARK := "…"


## Shows `full` on `l`, cut with "…" to the label's width. Call it instead of `l.text = full`.
static func set_text(l: Label, full: String) -> void:
	l.set_meta(META, full)
	if not l.has_meta(&"ui5_ellipsis_hooked"):
		l.set_meta(&"ui5_ellipsis_hooked", true)
		l.resized.connect(_refit.bind(l))
	_refit(l)


## The text the label was given (the uncut name). Falls back to the shown text for a label never set here.
static func full_text(l: Label) -> String:
	return String(l.get_meta(META, l.text))


## Re-cuts the label to its current width / font (call after a font size change that did not resize it).
static func refit(l: Label) -> void:
	if l.has_meta(META):
		_refit(l)


static func _refit(l: Label) -> void:
	if not is_instance_valid(l):
		return
	var full := String(l.get_meta(META, ""))
	var shown := fit(full, l.get_theme_font("font"), l.get_theme_font_size("font_size"), _avail(l))
	if l.text != shown:
		l.text = shown


## Room for the text: the label's width minus its style padding. -1 while it has not been laid out (no cut yet).
static func _avail(l: Label) -> float:
	if l.size.x <= 0.0:
		return -1.0
	var sb := l.get_theme_stylebox("normal")
	var pad := sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT) if sb != null else 0.0
	return l.size.x - pad


## Longest prefix of `full` + "…" that fits `avail` px at `font_px` (the whole text when it fits, or when there is
## no width / font to measure against yet).
static func fit(full: String, font: Font, font_px: int, avail: float) -> String:
	if font == null or avail < 0.0 or full == "":
		return full
	if font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x <= avail + 0.5:
		return full
	var n := full.length() - 1
	while n > 0:
		var t := full.left(n).strip_edges(false, true) + MARK
		if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x <= avail + 0.5:
			return t
		n -= 1
	return MARK
