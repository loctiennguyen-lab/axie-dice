extends Control
class_name HPBar
## One stat bar, UI-03 look: flat `hp_track` box, solid token fill (`hp` / `hp_enemy` / `shield`),
## cream "just lost" slice, hatched damage preview, phase ticks. No outline, no numerals in the bar.
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
## Kept so callers that set it still compile; the UI-03 look (flat hp_track box, solid token fill,
## no outline, no numerals in the bar) is the only look now.
var ui3_look: bool = true

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
				img.set_pixel(x, y, UI3Theme.color("accent") if ((x + y) % _HATCH) < _HATCH / 2 \
					else UI3Theme.color("accent").darkened(0.25))
		_hatch_tex = ImageTexture.create_from_image(img)
	return _hatch_tex


func _draw_ui3() -> void:
	var r := mini(UI3Theme.radius("s"), int(size.y * 0.5))
	draw_style_box(UI3Theme.flat(UI3Theme.color("hp_track"), r), Rect2(Vector2.ZERO, size))
	var tok := "hp_enemy" if kind == Kind.ENEMY else ("shield" if kind == Kind.SHIELD else "hp")
	var fill := UI3Theme.color(tok)
	if _fixed_fill.a > 0.0:
		fill = _fixed_fill
	var fw := size.x * clampf(display_ratio, 0.0, 1.0)
	if fw > 1.0:
		var w := maxf(fw, float(r) * 2.0)
		draw_style_box(UI3Theme.flat(fill, r), Rect2(0, 0, w, size.y))
	if lost_ratio > 0.0:
		var lw := minf(size.x * lost_ratio, size.x - fw)
		if lw > 1.0:
			draw_rect(Rect2(fw, 0, lw, size.y), UI3Theme.color("text"))
	if _at_risk > 0 and fw > 1.0:
		var rw := minf(size.x * (float(_at_risk) / float(_max_hp)), fw)
		var rc := UI3Theme.color("hp_enemy")
		rc.a = 0.6
		draw_rect(Rect2(fw - rw, 0, rw, size.y), rc)
	if _preview_dmg > 0 and _hp > 0 and fw > 1.0:
		var pw := minf(size.x * (float(_preview_dmg) / float(_max_hp)), fw)
		draw_texture_rect(hatch_texture(), Rect2(fw - pw, 0, pw, size.y), true)
	for m in marks:
		draw_rect(Rect2(size.x * float(m) - 1.5, 0, 3.0, size.y), UI3Theme.color("text"))


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_ui3()


## The numerals currently drawn ("34 / 52", or the lethal override), for tests and tooltips.
func shown_text() -> String:
	return _lethal_text if _lethal_text != "" else "%d / %d" % [maxi(_hp, 0), _max_hp]
