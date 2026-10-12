extends Control
class_name HPBar
## One stat bar — Dice UI R1 (design/handoffs/ui-02-round1b README §1 "HP bar").
##
## r 9 (8 on a plate), border 3 `OUTLINE`, track `BAR_TRACK`; fill is a vertical 2-stop gradient
## (party green `#86D65E -> #4FA62F`, enemy `#F58A5E -> #D9472B`); numerals centred, 2px outlined
## cream; the damage preview is a gold hatched segment (`#FFC445` / `#E8A23A`, 135 deg, 6 px)
## sitting on the right end of the current fill; phase marks are 3px `OUTLINE` ticks.
##
## The class keeps the API CombatView / UnitPortrait already use (`set_stats`, `set_at_risk`,
## `set_preview`, `use_fixed_fill`) so nothing upstream had to change; what is new is `text_mode`
## (draw "34 / 52" in the bar), `kind`, `marks`, and `lost_ratio` (HP just lost, drawn cream for
## 400 ms then shrinking away — README 02d).
##
## Gradients: StyleBoxFlat has none, so the fill is two rounded boxes (bottom colour full height,
## top colour on the upper half). A true per-pixel gradient needs a shader; this reads the same
## at 24 px and costs two draws.

enum Kind { PARTY, ENEMY, SHIELD }

const _BORDER_W := 3
## Callers that sized a bar with BAR_HEIGHT get the plate bar (24 tall).
const BAR_HEIGHT := 24
const _ANIM_SECONDS := 0.3
const _HATCH := 12     # px period of the 135deg hatch tile (6 + 6)

static var _hatch_tex: ImageTexture = null

var kind: Kind = Kind.PARTY
var bar_radius: int = 9
var text_mode: bool = false        ## draw "hp / max" inside the bar
var text_size: int = 16
var marks: Array = []              ## fractions 0..1 where a 3px phase tick is drawn (boss)

var _hp: int = 0
var _max_hp: int = 1
var _at_risk: int = 0
var _preview_dmg: int = 0
var _lethal_text: String = ""      ## when set, replaces "hp / max" (e.g. "11 / 70 -> 0")
var _fixed_fill: Color = Color.TRANSPARENT
var _fill_tween: Tween = null
var _lost_tween: Tween = null

## Animated fill fraction (tweened by `set_stats`).
var display_ratio: float = 0.0:
	set(value):
		display_ratio = value
		queue_redraw()

## Fraction of max HP shown as the cream "just lost" slice right of the fill.
var lost_ratio: float = 0.0:
	set(value):
		lost_ratio = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(96, BAR_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Switch this instance to a fixed-colour bar (the shield bar).
func use_fixed_fill(fill: Color) -> void:
	_fixed_fill = fill
	kind = Kind.SHIELD


func set_kind(p_kind: Kind, height: int = BAR_HEIGHT, radius: int = 9, p_text_size: int = 16) -> void:
	kind = p_kind
	bar_radius = radius
	text_size = p_text_size
	custom_minimum_size.y = height
	queue_redraw()


func set_stats(hp: int, max_hp: int, _unused_shield: int = 0) -> void:
	var prev_hp := _hp
	_hp = hp
	_max_hp = maxi(max_hp, 1)
	var target := clampf(float(_hp) / float(_max_hp), 0.0, 1.0)
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	if is_inside_tree() and not is_equal_approx(display_ratio, target):
		var dropping := target < display_ratio
		var delay := CombatView.impact_delay() if dropping else 0.0
		# Cream "lost" slice: shown at the old fill edge for 400 ms, then shrinks away.
		if dropping and prev_hp > hp and not CombatView.disable_juice_for_tests:
			if _lost_tween != null and _lost_tween.is_valid():
				_lost_tween.kill()
			lost_ratio = clampf(float(prev_hp - hp) / float(_max_hp), 0.0, 1.0)
			_lost_tween = create_tween()
			_lost_tween.tween_interval(0.4 + delay)
			_lost_tween.tween_property(self, "lost_ratio", 0.0, 0.25)
		_fill_tween = create_tween()
		var step := _fill_tween.tween_property(self, "display_ratio", target, _ANIM_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if delay > 0.0:
			step.set_delay(delay)
	else:
		display_ratio = target
	queue_redraw()


## HP already spoken for by committed incoming damage (party only).
func set_at_risk(amount: int) -> void:
	_at_risk = maxi(amount, 0)
	queue_redraw()


## Hover preview: gold hatched segment of `dmg` HP at the right end of the fill.
func set_preview(dmg: int) -> void:
	_preview_dmg = maxi(dmg, 0)
	queue_redraw()


func clear_preview() -> void:
	_lethal_text = ""
	set_preview(0)


## Replaces the numerals while a lethal hit is previewed ("11 / 70 -> 0").
func set_lethal_text(t: String) -> void:
	_lethal_text = t
	queue_redraw()


func set_marks(fracs: Array) -> void:
	marks = fracs
	queue_redraw()


func _exit_tree() -> void:
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	if _lost_tween != null and _lost_tween.is_valid():
		_lost_tween.kill()


static func hatch_texture() -> ImageTexture:
	if _hatch_tex == null:
		var img := Image.create(_HATCH, _HATCH, false, Image.FORMAT_RGBA8)
		for y in _HATCH:
			for x in _HATCH:
				img.set_pixel(x, y, DangoTheme.GOLD if ((x + y) % _HATCH) < _HATCH / 2 \
					else DangoTheme.GOLD_HATCH)
		_hatch_tex = ImageTexture.create_from_image(img)
	return _hatch_tex


func _fill_colors() -> Array:
	match kind:
		Kind.ENEMY:
			return [DangoTheme.HP_ENEMY_TOP, DangoTheme.HP_ENEMY_BOTTOM]
		Kind.SHIELD:
			var c: Color = _fixed_fill if _fixed_fill.a > 0.0 else DangoTheme.SHIELD_BLUE
			return [c.lightened(0.15), c]
	return [DangoTheme.HP_PARTY_TOP, DangoTheme.HP_PARTY_BOTTOM]


func _box(fill: Color, radius: int, border: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if border:
		sb.border_color = DangoTheme.OUTLINE
		sb.set_border_width_all(_BORDER_W)
	return sb


func _draw_gradient_rounded(r: Rect2, radius: int, top: Color, bottom: Color) -> void:
	draw_style_box(_box(bottom, radius, false), r)
	var top_r := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5))
	var sb := _box(top, radius, false)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	draw_style_box(sb, top_r)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_style_box(_box(DangoTheme.BAR_TRACK, bar_radius, true), Rect2(Vector2.ZERO, size))
	var inner := Rect2(float(_BORDER_W), float(_BORDER_W),
		maxf(size.x - _BORDER_W * 2.0, 0.0), maxf(size.y - _BORDER_W * 2.0, 0.0))
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	var inner_r := maxi(bar_radius - _BORDER_W, 1)
	var cols := _fill_colors()
	var fill_w := inner.size.x * clampf(display_ratio, 0.0, 1.0)
	if fill_w > 1.0:
		_draw_gradient_rounded(Rect2(inner.position, Vector2(fill_w, inner.size.y)),
			inner_r, cols[0], cols[1])

	# Cream "just lost" slice right of the fill.
	if lost_ratio > 0.0:
		var lw := minf(inner.size.x * lost_ratio, inner.size.x - fill_w)
		if lw > 1.0:
			var c := DangoTheme.CREAM_RAISED
			c.a = 0.85
			draw_rect(Rect2(inner.position.x + fill_w, inner.position.y, lw, inner.size.y), c)

	# At-risk (committed incoming) on the fill's right end.
	if _at_risk > 0 and fill_w > 1.0:
		var risk_w := minf(inner.size.x * (float(_at_risk) / float(_max_hp)), fill_w)
		if risk_w > 1.0:
			var rc := DangoTheme.AT_RISK
			rc.a = 0.55
			draw_rect(Rect2(inner.position.x + fill_w - risk_w, inner.position.y, risk_w, inner.size.y), rc)

	# Damage preview — gold hatched segment.
	if _preview_dmg > 0 and _hp > 0 and fill_w > 1.0:
		var pw := minf(inner.size.x * (float(_preview_dmg) / float(_max_hp)), fill_w)
		if pw > 1.0:
			draw_texture_rect(hatch_texture(),
				Rect2(inner.position.x + fill_w - pw, inner.position.y, pw, inner.size.y), true)

	# Phase marks.
	for m in marks:
		var mx := inner.position.x + inner.size.x * float(m) - 1.5
		draw_rect(Rect2(mx, inner.position.y, 3.0, inner.size.y), DangoTheme.OUTLINE)

	# Numerals.
	if text_mode:
		var txt := _lethal_text if _lethal_text != "" else "%d / %d" % [maxi(_hp, 0), _max_hp]
		var font: Font = DangoTheme.FONT_DISPLAY
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size)
		var pos := Vector2((size.x - ts.x) * 0.5,
			(size.y + font.get_ascent(text_size) - font.get_descent(text_size)) * 0.5)
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, 4,
			DangoTheme.OUTLINE)
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size,
			DangoTheme.CREAM_RAISED)


## The numerals currently drawn ("34 / 52", or the lethal override), for tests and tooltips.
func shown_text() -> String:
	return _lethal_text if _lethal_text != "" else "%d / %d" % [maxi(_hp, 0), _max_hp]
