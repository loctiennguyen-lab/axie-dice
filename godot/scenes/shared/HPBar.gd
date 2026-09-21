extends Control
class_name HPBar
## One stat bar — CB-10 / CB-11 (FIX-PASS-03 §4). Height 8, radius 5, trough `WELL_DEEP`, 2px
## PURE BLACK border, fill `hp_color(pct)`, width animating over .3s.
##
## REBUILT 2026-09-20 (FIX-PASS-03). Three things the previous version did are now forbidden:
##
##  1. **Shield was drawn INSIDE this control** as a thin cyan cap along the bottom of the HP
##     track. CB-10 is explicit — "Shield is its own bar under HP — it is never a segment inside
##     the HP track and never a badge overlapping the HP number." A second instance of this same
##     class, switched to fixed-fill mode via `use_fixed_fill()`, is that bar.
##  2. **The trough was `Color(1,1,1,0.12)`** — a white alpha wash, which L4 forbids ("colour is
##     a solid fill, never a wash"). It is `WELL_DEEP` now.
##  3. **The border was `Color(0,0,0,0.55)` at 1.5px** — a translucent hairline, which L1
##     forbids. It is pure black at 2px.
##
## The rounded geometry means this draws through StyleBoxFlat rather than `draw_rect`, which
## cannot round corners.
##
## `set_preview()` (hover-driven damage preview, wired from CombatView's die-tray and enemy-intent
## hover) is unchanged in meaning and is NOT the same thing as `set_at_risk()`: preview is a
## transient "if you did this", at-risk is the committed incoming telegraph CB-11 specifies.

const _BAR_RADIUS := 5
const _BORDER_W := 2
## The rendered height of the whole bar: the mockup writes `height:8px; border:2px solid #000`
## with no `box-sizing`, so 8 is the TROUGH and the border sits outside it — 12 rendered pixels.
## Godot draws a StyleBoxFlat border inside the Control rect, so the Control has to be the 12.
const BAR_HEIGHT := 8 + _BORDER_W * 2
const _ANIM_SECONDS := 0.3
const _PREVIEW_ALPHA := 0.8

var _hp: int = 0
var _max_hp: int = 1
var _at_risk: int = 0
var _preview_dmg: int = 0
var _fixed_fill: Color = Color.TRANSPARENT   # non-transparent => shield-bar mode (CB-10 row 3)
var _fill_tween: Tween = null

## Animated fill fraction. `set_stats()` tweens this toward the real ratio rather than snapping,
## which is CB-10's "width animates over .3s". Tweened by name, so it needs the setter to
## repaint.
var display_ratio: float = 0.0:
	set(value):
		display_ratio = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(96, BAR_HEIGHT)   # CB-10: 8px trough inside a 2px black border
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Switch this instance to the shield bar of CB-10's row 3: identical geometry, `INFO` fill, and
## a ratio read against max_hp rather than a health percentage.
func use_fixed_fill(fill: Color) -> void:
	_fixed_fill = fill


func set_stats(hp: int, max_hp: int, _unused_shield: int = 0) -> void:
	_hp = hp
	_max_hp = maxi(max_hp, 1)
	var target := clampf(float(_hp) / float(_max_hp), 0.0, 1.0)
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	# Only animate when the node is actually in the tree; a tween created outside it never runs
	# and would leave the bar stuck at its old ratio (this is what tests and off-screen rebuilds
	# hit).
	if is_inside_tree() and not is_equal_approx(display_ratio, target):
		# A DRAIN waits for the blow to land; a GAIN does not. CombatEngine resolves a face in
		# one call, so without this the bar started emptying on the frame the attacker began
		# moving — before anything had touched the target. CombatView.impact_delay() is the one
		# definition of that moment (and is 0 in test mode, so this stays a plain tween there).
		#
		# Healing, shielding and the turn-start refill are not impacts and get no delay: making
		# a heal hesitate would read as lag, not as timing.
		var delay := CombatView.impact_delay() if target < display_ratio else 0.0
		_fill_tween = create_tween()
		var step := _fill_tween.tween_property(self, "display_ratio", target, _ANIM_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if delay > 0.0:
			step.set_delay(delay)
	else:
		display_ratio = target
	queue_redraw()


## CB-11 — the at-risk slice. `amount` is HP already spoken for by committed incoming damage
## (incoming minus shield, clamped by the caller). Party only; enemies never set it.
func set_at_risk(amount: int) -> void:
	_at_risk = maxi(amount, 0)
	queue_redraw()


func set_preview(dmg: int) -> void:
	_preview_dmg = maxi(dmg, 0)
	queue_redraw()


func clear_preview() -> void:
	set_preview(0)


func _exit_tree() -> void:
	# Godot 4 does not tie a Tween's lifetime to the node it animates — the same leak the run
	# map's ring blink had to fix.
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()


func _bar_style(fill: Color, bordered: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	# An inset fill follows the trough's INNER radius, or it shows four cream-coloured pips in
	# the corners of a bar that is meant to read as one rounded capsule.
	sb.set_corner_radius_all(_BAR_RADIUS if bordered else maxi(_BAR_RADIUS - _BORDER_W, 1))
	if bordered:
		sb.border_color = Color.BLACK      # L1: pure black, never a translucent hairline
		sb.set_border_width_all(_BORDER_W)
	return sb


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	# Trough — a solid surface token, not an alpha wash (L4).
	draw_style_box(_bar_style(DangoTheme.WELL_DEEP, true), Rect2(Vector2.ZERO, size))

	# Every fill below is drawn INSIDE the border, never over it. Drawing them at
	# `Rect2(0, 0, w, size.y)` is what made the bar read as a bare rounded fill with no outline
	# at all in the 20 Sep capture: the trough's 2px black was painted first and then covered by
	# the fill on the same rect. The mockup's fill is `position:absolute; inset:0` inside a
	# bordered, `overflow:hidden` track — i.e. the content box, not the border box.
	var inner := Rect2(float(_BORDER_W), float(_BORDER_W),
		maxf(size.x - _BORDER_W * 2.0, 0.0), maxf(size.y - _BORDER_W * 2.0, 0.0))
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return

	var fill_color: Color = _fixed_fill if _fixed_fill.a > 0.0 \
		else DangoTheme.hp_color(float(_hp) / float(_max_hp))
	var fill_w := inner.size.x * clampf(display_ratio, 0.0, 1.0)
	if fill_w > 1.0:
		draw_style_box(_bar_style(fill_color, false),
			Rect2(inner.position.x, inner.position.y, fill_w, inner.size.y))

	# CB-11: the at-risk block sits ON the right end of the current fill, not beside it — the
	# player reads "this much of what I have is already spoken for".
	if _at_risk > 0 and fill_w > 1.0:
		var risk_w := minf(inner.size.x * (float(_at_risk) / float(_max_hp)), fill_w)
		if risk_w > 1.0:
			draw_style_box(_bar_style(DangoTheme.AT_RISK, false),
				Rect2(inner.position.x + fill_w - risk_w, inner.position.y,
					risk_w, inner.size.y))

	# Hover preview — transient, and deliberately a different thing from the at-risk block above.
	if _preview_dmg > 0 and _hp > 0:
		var preview_w := minf(inner.size.x * (float(_preview_dmg) / float(_max_hp)), fill_w)
		if preview_w > 1.0:
			var preview_color := DangoTheme.DANGER
			preview_color.a = _PREVIEW_ALPHA
			draw_style_box(_bar_style(preview_color, false),
				Rect2(inner.position.x + fill_w - preview_w, inner.position.y,
					preview_w, inner.size.y))
