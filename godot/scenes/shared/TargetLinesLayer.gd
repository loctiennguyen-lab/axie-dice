extends Control
class_name TargetLinesLayer
## Enemy-intent -> target line layer (review-uiux-battle-screen.md P0 #3: "một đường cong mờ
## chạy từ quái tới đúng Axie bị nhắm, sáng lên khi hover"). Pure presentation — CombatView
## computes both screen endpoints every frame via CombatStage3D.get_unit_screen_pos() and calls
## set_lines(); this file never reads CombatEngine/Unit itself.
##
## AESTHETIC PASS (ui-programmer task 4/4, coordinator correction 2026-09-18): the first version
## of this file just thickened/opacified a single flat-color quadratic-bezier polyline in
## response to "user thấy khó nhận ra" — the coordinator explicitly rejected that as "chỉ tăng độ
## dày/độ đậm cho to ra, rõ ra" and asked for something that reads as "một chi tiết UI được thiết
## kế cẩn thận" instead. This rewrite keeps the same smooth quadratic-bezier curve (still built
## from the same two CombatStage3D.get_unit_screen_pos() endpoints CombatView hands in via
## set_lines() — the shape was never the complaint) but replaces the single draw_polyline() call
## with, per segment: a color+alpha gradient that deepens toward the target (soft near the
## source, full saturation near the target) instead of one flat tint, a soft fade-in at the
## source instead of a hard cut, and a width taper (thin at the source, wider at the target) —
## plus a small arrowhead at the target end for unambiguous "this is pointed AT you" directionality,
## and a few small light "energy" dots animated traveling toward the target. Colors still follow
## the existing dmg=DANGER / other=INFO semantic split (CombatView._layout_unit_visuals() picks
## `color` before calling set_lines()) — only softened via a lerp toward white, never replaced —
## so "red = incoming damage" still holds and the line still belongs to this file's own palette
## instead of introducing a new one.
##
## MOTION: the energy-dot animation is real-time (Control._process() calling queue_redraw() every
## frame) and is gated on CombatView.disable_juice_for_tests exactly like every other Tween/juice
## entry point in this combat scene (CombatStage3D.gd/CombatView.gd's own "HEADLESS TEST MODE"
## comments) — headless automated tests get a static, undotted line, so this never introduces
## frame-timing nondeterminism into the test suite. No project-level "reduced motion" setting
## exists yet (grepped godot/autoload/*.gd before writing this) — if one is ever added, gate the
## dot loop on it here too, the same way disable_juice_for_tests already is.

const _STEPS := 28
const _BOW_HEIGHT := 46.0

const _WIDTH_SOURCE := 1.4
const _WIDTH_TARGET := 3.6
const _WIDTH_SOURCE_HL := 2.2
const _WIDTH_TARGET_HL := 5.4

const _ALPHA_PEAK := 0.55
const _ALPHA_PEAK_HL := 0.92
const _FADE_IN_T := 0.14        # fraction of the curve (from the source) over which alpha ramps
	# up from 0 — replaces the old hard "for lines that exist, draw at one flat alpha" cut.
const _SOFTEN_TOWARD_WHITE := 0.22   # how far the base theme color is lerped toward white before
	# the target-ward gradient blends back to full saturation — keeps the semantic color (danger
	# red / info cyan) but stops it reading as a raw, chōi-màu neon line on the desert background.

const _ARROW_LEN := 13.0
const _ARROW_WIDTH := 8.0
const _ARROW_LEN_HL := 16.0
const _ARROW_WIDTH_HL := 10.0

const _DOT_COUNT := 3
const _DOT_SPEED := 0.35        # curve-fractions per second
const _DOT_SPEED_HL := 0.56
const _DOT_RADIUS := 2.6
const _DOT_END_T := 0.92        # dots stop short of the target so they don't visually collide
	# with the arrowhead

var _lines: Array = []   # [{from: Vector2, to: Vector2, color: Color, highlighted: bool}]
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if CombatView.disable_juice_for_tests or _lines.is_empty():
		return
	_time += delta
	queue_redraw()   # only the energy dots need a per-frame repaint; set_lines() already
		# queue_redraws() itself for every other content change


func set_lines(lines: Array) -> void:
	_lines = lines
	queue_redraw()


func _draw() -> void:
	for l in _lines:
		_draw_one(l as Dictionary)


func _draw_one(entry: Dictionary) -> void:
	var from: Vector2 = entry.get("from", Vector2(-1, -1))
	var to: Vector2 = entry.get("to", Vector2(-1, -1))
	if from.x < 0.0 or to.x < 0.0:
		return
	var highlighted: bool = entry.get("highlighted", false)
	var base_color: Color = entry.get("color", DangoTheme.DANGER)
	var soft_color := base_color.lerp(Color.WHITE, _SOFTEN_TOWARD_WHITE)
	var peak_alpha := _ALPHA_PEAK_HL if highlighted else _ALPHA_PEAK
	var w_src := _WIDTH_SOURCE_HL if highlighted else _WIDTH_SOURCE
	var w_tgt := _WIDTH_TARGET_HL if highlighted else _WIDTH_TARGET

	var mid := (from + to) * 0.5 - Vector2(0, _BOW_HEIGHT)
	var pts := PackedVector2Array()
	for i in _STEPS + 1:
		var t := float(i) / float(_STEPS)
		var inv := 1.0 - t
		pts.append(from * (inv * inv) + mid * (2.0 * inv * t) + to * (t * t))

	# Drawn as short per-segment draw_line() calls (not one draw_polyline()) so both color/alpha
	# AND width can vary continuously along the curve — draw_polyline() only takes one constant
	# width for the whole call, which is exactly the "everything looks the same" limitation this
	# rewrite is fixing.
	for i in _STEPS:
		var t0 := float(i) / float(_STEPS)
		var t1 := float(i + 1) / float(_STEPS)
		var tm := (t0 + t1) * 0.5
		var fade := smoothstep(0.0, _FADE_IN_T, tm)
		var seg_color := soft_color.lerp(base_color, tm)
		seg_color.a = peak_alpha * fade
		var seg_width := lerpf(w_src, w_tgt, tm)
		draw_line(pts[i], pts[i + 1], seg_color, seg_width, true)

	_draw_arrowhead(pts[_STEPS - 1], pts[_STEPS], base_color, peak_alpha, highlighted)
	_draw_energy_dots(pts, base_color, soft_color, peak_alpha, highlighted)


## Small solid triangle at the target end — the one part of the line that stays fully opaque
## regardless of the fade-in gradient above, so "which unit this intent targets" always reads
## unambiguously even before the gradient reaches full strength.
func _draw_arrowhead(tail: Vector2, tip: Vector2, color: Color, alpha: float, highlighted: bool) -> void:
	var dir := tip - tail
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)   # perpendicular — Vector2 has no built-in "orthogonal()"
		# in every Godot 4.x point release verified so far, so this is computed by hand rather
		# than risk an API that may not exist on this project's pinned 4.7.2 (see VERSION.md
		# knowledge-gap warning / CombatStage3D.gd's own note on verifying against the real binary).
	var arrow_len := _ARROW_LEN_HL if highlighted else _ARROW_LEN
	var arrow_w := _ARROW_WIDTH_HL if highlighted else _ARROW_WIDTH
	var back := tip - dir * arrow_len
	var p1 := back + side * arrow_w * 0.5
	var p2 := back - side * arrow_w * 0.5
	var col := color
	col.a = minf(alpha + 0.15, 1.0)
	draw_colored_polygon(PackedVector2Array([tip, p1, p2]), col)


## Small traveling "energy" dots — the ambient-motion cue the coordinator asked for ("hiệu ứng
## dash/particle nhỏ chạy dọc đường gợi ý năng lượng"). Purely additive/decorative: skipped
## entirely whenever _process() isn't advancing _time (test mode), so a single static call to
## _draw_one() from a non-animating context (e.g. a future unit test) still renders a complete,
## correct line without these.
func _draw_energy_dots(pts: PackedVector2Array, base_color: Color, soft_color: Color,
		peak_alpha: float, highlighted: bool) -> void:
	if CombatView.disable_juice_for_tests:
		return
	var speed := _DOT_SPEED_HL if highlighted else _DOT_SPEED
	for d in _DOT_COUNT:
		var phase := float(d) / float(_DOT_COUNT)
		var t := fmod(_time * speed + phase, 1.0)
		if t < _FADE_IN_T or t > _DOT_END_T:
			continue
		var idx := clampi(int(t * float(_STEPS)), 0, _STEPS)
		var pos: Vector2 = pts[idx]
		var glow_col := soft_color.lerp(Color.WHITE, 0.4)
		glow_col.a = peak_alpha * 0.35
		draw_circle(pos, _DOT_RADIUS * 1.8, glow_col)   # soft outer glow
		var core_col := base_color.lerp(Color.WHITE, 0.6)
		core_col.a = peak_alpha * 0.95
		draw_circle(pos, _DOT_RADIUS, core_col)   # bright inner core
