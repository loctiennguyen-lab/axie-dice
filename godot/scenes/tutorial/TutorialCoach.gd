extends CanvasLayer
class_name TutorialCoach
## The onboarding coach: everything the tutorial draws ON TOP of the real combat screen.
##
## It owns no game state and reads no engine. TutorialView.gd decides what the current step is
## and calls into here; this file only knows how to dim the screen, cut a hole in the dim, and
## put a card next to the hole. That split is what lets the tutorial run on the production
## Combat.tscn instead of a hand-built stand-in of it.
##
## HOW THE DIM AND THE CLICK-LOCK ARE THE SAME THING. The dim is not one translucent sheet with
## a shader hole punched in it — it is FOUR opaque-ish bands (above / below / left / right of
## the spotlight rect), each MOUSE_FILTER_STOP. So the lit rectangle is literally a gap in the
## overlay: a click there reaches whatever is underneath with no forwarding, no
## `set_input_as_handled()`, and no "which control was under the cursor" arithmetic that could
## disagree with what the player can see. Everywhere else, the click hits a band and stops.
##
## The bands are the VISIBLE lock only. The step-lock that actually has to hold is
## CombatView._gated() — Space, Escape and CombatStage3D's own unit_clicked path never travel
## through this overlay at all. See CombatView's `_tutorial` comment.

signal cta_pressed
signal reward_chosen(index: int)
signal skip_pressed

const _DIM := Color(0.02, 0.025, 0.04, 0.72)
const _CARD_W := 420.0
const _CARD_PAD := 20.0     # must match the card's stylebox content margin
const _GAP := 18.0          # between the spotlight edge and the card
const _MARGIN := 24.0       # minimum distance from any screen edge
const _HOLE_PAD := 10.0     # how far the lit rect is grown past the control it frames

var _bands: Array[ColorRect] = []
var _ring: Panel
var _ring_style: StyleBoxFlat
var _ring_tween: Tween

var _card: PanelContainer
var _card_title: Label
var _card_body: Label
var _card_cta: Button
var _card_step: Label

var _curtain: ColorRect
var _curtain_title: Label
var _curtain_body: Label
var _curtain_cta: Button
var _reward_row: HBoxContainer

var _skip: Button
var _root: Control

## The control currently framed, re-read every frame so the hole tracks it through layout
## changes (window resize, the deck bar re-flowing when a summon adds a sixth die card).
var _target: Control = null
var _target_rect: Rect2 = Rect2()
var _has_hole: bool = false
var _dim: bool = false
var _last_hole: Rect2 = Rect2(-1, -1, -1, -1)
var _last_card_size: Vector2 = Vector2(-1, -1)


func _init() -> void:
	layer = 30   # above CombatView's own board (0) and its Info panel (29)


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	for _i in 4:
		var band := ColorRect.new()
		band.color = _DIM
		band.mouse_filter = Control.MOUSE_FILTER_STOP
		_root.add_child(band)
		_bands.append(band)

	_ring = Panel.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_style = StyleBoxFlat.new()
	_ring_style.bg_color = Color(0, 0, 0, 0)
	_ring_style.border_color = DangoTheme.PRIMARY
	_ring_style.set_border_width_all(3)
	_ring_style.set_corner_radius_all(14)
	_ring.add_theme_stylebox_override("panel", _ring_style)
	_root.add_child(_ring)

	_build_card()
	_build_curtain()
	_build_skip()
	clear()


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(_CARD_W, 0)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL, 16, 3, 5.0, Vector2(_CARD_PAD, 16)))
	_root.add_child(_card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_card.add_child(col)

	_card_step = Label.new()
	_card_step.add_theme_font_override("font", DangoTheme.FONT_UI_BOLD)
	_card_step.add_theme_font_size_override("font_size", 12)
	_card_step.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	col.add_child(_card_step)

	_card_title = Label.new()
	_card_title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_card_title.add_theme_font_size_override("font_size", 24)
	_card_title.add_theme_color_override("font_color", DangoTheme.TEXT)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A Label with AUTOWRAP reports its minimum height for its CURRENT width, and that width is
	# zero until the first layout pass — one character per line, and a card as tall as the
	# screen. Pinning the text width makes the wrap (and so the height _place() reads back)
	# measure against the width the card will actually have.
	_card_title.custom_minimum_size = Vector2(_CARD_W - _CARD_PAD * 2.0, 0)
	col.add_child(_card_title)

	_card_body = Label.new()
	_card_body.add_theme_font_size_override("font_size", 16)
	_card_body.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96, 0.78))
	_card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_body.custom_minimum_size = Vector2(_CARD_W - _CARD_PAD * 2.0, 0)
	col.add_child(_card_body)

	_card_cta = Button.new()
	_card_cta.custom_minimum_size = Vector2(0, 44)
	_card_cta.focus_mode = Control.FOCUS_NONE
	DangoTheme.style_button(_card_cta, true)
	_card_cta.pressed.connect(func(): cta_pressed.emit())
	col.add_child(_card_cta)


func _build_curtain() -> void:
	_curtain = ColorRect.new()
	_curtain.color = Color(0.02, 0.025, 0.04, 0.93)
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_curtain)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	_curtain_title = Label.new()
	_curtain_title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_curtain_title.add_theme_font_size_override("font_size", 40)
	_curtain_title.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	_curtain_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_curtain_title)

	_curtain_body = Label.new()
	_curtain_body.custom_minimum_size = Vector2(560, 0)
	_curtain_body.add_theme_font_size_override("font_size", 18)
	_curtain_body.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96, 0.78))
	_curtain_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_curtain_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_curtain_body)

	_reward_row = HBoxContainer.new()
	_reward_row.add_theme_constant_override("separation", 16)
	_reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reward_row.visible = false
	col.add_child(_reward_row)

	_curtain_cta = Button.new()
	_curtain_cta.custom_minimum_size = Vector2(260, 54)
	_curtain_cta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_curtain_cta.focus_mode = Control.FOCUS_NONE
	DangoTheme.style_button(_curtain_cta, true)
	_curtain_cta.pressed.connect(func(): cta_pressed.emit())
	col.add_child(_curtain_cta)


## A quiet way out, in the corner, on every step. A mandatory tutorial with no exit is the
## thing players complain about; one that is easy to find but easy to ignore is not.
func _build_skip() -> void:
	_skip = Button.new()
	_skip.text = "Skip tutorial"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.flat = true
	_skip.add_theme_font_size_override("font_size", 13)
	_skip.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96, 0.45))
	_skip.add_theme_color_override("font_hover_color", DangoTheme.TEXT)
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_skip.offset_left = 16.0
	_skip.offset_top = -40.0
	_skip.offset_right = 160.0
	_skip.offset_bottom = -12.0
	_skip.pressed.connect(func(): skip_pressed.emit())
	_root.add_child(_skip)


# ===========================================================================
# Public API — TutorialView drives all of it
# ===========================================================================

func clear() -> void:
	_has_hole = false
	_dim = false
	_target = null
	_card.visible = false
	_ring.visible = false
	_curtain.visible = false
	_reward_row.visible = false
	for b in _bands:
		b.visible = false


## A coached step: dim everything, cut a hole around `target` (a Control on the combat screen,
## or null for "no hole — dim nothing, just show the card"), and put the card beside it.
## `dim=false` is the free-play case: the card still anchors itself to `extra_rect` so it lands
## somewhere deliberate, but nothing is dimmed and nothing is blocked — the player has the whole
## screen back, which is the entire point of that step.
func show_step(step_label: String, title: String, body: String, cta: String,
		target: Control, extra_rect: Rect2 = Rect2(), dim: bool = true) -> void:
	_curtain.visible = false
	_reward_row.visible = false
	_target = target
	_target_rect = extra_rect
	_has_hole = target != null or extra_rect.size.x > 0.0
	_dim = dim and _has_hole

	_card_step.text = step_label
	_card_step.visible = step_label != ""
	_card_title.text = title
	_card_body.text = body
	_card_body.visible = body != ""
	_card_cta.text = cta
	_card_cta.visible = cta != ""
	_card.visible = true
	_ring.visible = _dim
	for b in _bands:
		b.visible = _dim
	_last_hole = Rect2(-1, -1, -1, -1)   # force a re-place now that the text changed
	_place()
	_pulse_ring()


## A full-screen moment with nothing behind it to teach: welcome, win, loss.
func show_curtain(title: String, body: String, cta: String) -> void:
	_has_hole = false
	_dim = false
	_target = null
	_card.visible = false
	_ring.visible = false
	for b in _bands:
		b.visible = false
	_curtain_title.text = title
	_curtain_body.text = body
	_curtain_cta.text = cta
	_curtain_cta.visible = cta != ""
	_reward_row.visible = false
	_curtain.visible = true


## The reward beat — same curtain, with three cards in it instead of one button.
func show_rewards(title: String, body: String, flavors: Array) -> void:
	show_curtain(title, body, "")
	for c in _reward_row.get_children():
		c.queue_free()
	for i in flavors.size():
		var f: Dictionary = flavors[i]
		_reward_row.add_child(_reward_card(f, i))
	_reward_row.visible = true


func _reward_card(f: Dictionary, index: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(230, 150)
	b.focus_mode = Control.FOCUS_NONE
	b.text = ""
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, DangoTheme.surface_style(
			DangoTheme.Surface.PANEL_RAISED if st == "hover" else DangoTheme.Surface.PANEL,
			16, 3, 5.0, Vector2(16, 14)))
	b.pressed.connect(func(): reward_chosen.emit(index))

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16.0
	col.offset_right = -16.0
	col.offset_top = 14.0
	col.offset_bottom = -14.0
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	b.add_child(col)

	var t := Label.new()
	t.text = String(f.get("title", ""))
	t.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)

	var d := Label.new()
	d.text = String(f.get("desc", ""))
	d.add_theme_font_size_override("font_size", 14)
	d.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96, 0.72))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(d)
	return b


# ===========================================================================
# Layout
# ===========================================================================

func _process(_delta: float) -> void:
	if _has_hole:
		_place()


## Where the lit rectangle is, right now. A tracked Control wins over the fixed rect, so a
## caller can hand over a node and let it move; `extra_rect` covers the parts of the combat
## screen that are not a single Control (the enemy band is a slice of the 3D stage).
func _hole_rect() -> Rect2:
	var r := _target_rect
	if is_instance_valid(_target) and _target.is_visible_in_tree():
		r = _target.get_global_rect()
	return r.grow(_HOLE_PAD)


func _place() -> void:
	var screen := Vector2(_root.size)
	if screen.x <= 0.0:
		screen = Vector2(get_viewport().get_visible_rect().size)
	var hole := _hole_rect().intersection(Rect2(Vector2.ZERO, screen))
	if hole.size.x <= 0.0 or hole.size.y <= 0.0:
		hole = Rect2(screen * 0.5, Vector2.ZERO)
	var card_size := _card.get_combined_minimum_size()
	card_size.x = maxf(card_size.x, _CARD_W)
	if hole.is_equal_approx(_last_hole) and card_size.is_equal_approx(_last_card_size):
		return
	_last_hole = hole
	_last_card_size = card_size

	# Four bands, no overlap: full-width above and below, and the two side strips only as tall
	# as the hole itself. Anything outside the hole is covered exactly once.
	_set_band(0, Rect2(0, 0, screen.x, hole.position.y))
	_set_band(1, Rect2(0, hole.end.y, screen.x, screen.y - hole.end.y))
	_set_band(2, Rect2(0, hole.position.y, hole.position.x, hole.size.y))
	_set_band(3, Rect2(hole.end.x, hole.position.y, screen.x - hole.end.x, hole.size.y))

	_ring.position = hole.position
	_ring.size = hole.size
	if not _dim:
		for b in _bands:
			b.visible = false

	# The card goes on whichever side of the hole has room, then is clamped on screen. Above
	# when the hole is in the lower half (the dice tray, the two action buttons), below when it
	# is in the upper half (the enemy line).
	var above := hole.position.y > screen.y * 0.5
	var y := (hole.position.y - _GAP - card_size.y) if above else (hole.end.y + _GAP)
	var x := hole.get_center().x - card_size.x * 0.5
	_card.position = Vector2(
		clampf(x, _MARGIN, maxf(_MARGIN, screen.x - card_size.x - _MARGIN)),
		clampf(y, _MARGIN, maxf(_MARGIN, screen.y - card_size.y - _MARGIN)))
	_card.size = card_size


func _set_band(i: int, r: Rect2) -> void:
	var b := _bands[i]
	b.position = r.position
	b.size = Vector2(maxf(r.size.x, 0.0), maxf(r.size.y, 0.0))


## A slow breath on the ring, so the eye finds the lit control without an arrow pointing at it.
func _pulse_ring() -> void:
	if _ring_tween != null and _ring_tween.is_valid():
		_ring_tween.kill()
	if not _dim:
		return
	_ring.modulate.a = 1.0
	_ring_tween = create_tween().set_loops()
	_ring_tween.tween_property(_ring, "modulate:a", 0.35, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ring_tween.tween_property(_ring, "modulate:a", 1.0, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
