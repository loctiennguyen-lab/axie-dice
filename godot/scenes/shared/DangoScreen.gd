extends RefCounted
class_name DangoScreen
## The screen shell. EVERY scene's `_ready()` starts with `DangoScreen.build(...)` and adds its
## children to the returned `content` — never to the scene root, never at an absolute viewport
## coordinate.
##
## WHY THIS EXISTS. The build kept drifting out of frame because every screen computed positions
## from a hardcoded 1920x1080 while `project.godot` runs `stretch/aspect="expand"`, which makes
## the logical canvas whatever shape the player's window is. 1920x1080 is the MINIMUM canvas,
## not the design canvas. This file is the only place allowed to know that.
##
## Copy to: godot/scenes/shared/DangoScreen.gd

const SAFE := 48.0          ## every edge, every screen
const RAIL_X := 84.0        ## left/right content inset on meta screens
const FOOTER_H := 72.0
## The widest the centred content column is allowed to get. Raised 1800 → 1808 on 20 Sep 2026.
##
## The clamp is applied BEFORE centring, so it silently overrode any `side_inset` below 60: at a
## 1920 canvas, `side_inset = 56` computed `min(1920 - 112, 1800) = 1800` and landed the column
## at x=60, not 56. Team Select's mockup asks for 56 and could not express it through the
## argument meant for exactly that, so its own blocks had to claw the 4px back by hand. 1808 is
## `1920 - 56*2` — the narrowest value that lets every mockup inset in the set resolve honestly.
const CONTENT_MAX := 1808.0
const MODAL_MIN := 900.0
const MODAL_MAX := 1280.0
const MODAL_FRACTION := 0.55


## Builds plate -> scrim -> content -> footer and returns {"content": Control, "footer": HBox}.
## `footer` is null when `with_footer` is false (Combat and Main Menu own their own chrome).
## The content column re-centres itself on every window resize, so a screen built once stays
## correct at any aspect.
## `side_inset` / `top_inset` / `bottom_inset` — the screen's OWN margins, 20 Sep 2026.
##
## Until today every screen got `RAIL_X` (84) on the sides and `SAFE` (48) top and bottom,
## whatever its mockup said. The design review measured the result: the Run Map's panel sits at
## x=84 where the mockup puts it at 28, Result and Team Select at 88 where the mockup says 80
## and 56. One shared margin was quietly overriding thirteen different design decisions, costing
## the map 56px of panel travel and Team Select 32px of card width across five cards. It read as
## "everything is slightly too small", which is why nobody could name it.
##
## The defaults below preserve the old behaviour, so a screen that has not been updated is
## unchanged. Every screen should end up passing its mockup's own numbers.
##
## `with_footer` still defaults to true, but NO mockup has a footer bar — on Result the bar
## displaced a 340x72 centred CTA into a 132x44 corner button and dropped MAIN MENU entirely.
## Pass `false` and lay the screen's own closing controls out per its mockup.
static func build(host: Control, plate: Texture2D, kind: int = DangoTheme.Scrim.DEFAULT,
		with_footer: bool = true, combat: bool = false,
		side_inset: float = RAIL_X, top_inset: float = SAFE,
		bottom_inset: float = SAFE) -> Dictionary:
	host.set_anchors_preset(Control.PRESET_FULL_RECT)

	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(plate_host)
	DangoTheme.build_plate(plate_host, plate, kind, combat)

	var footer_row: HBoxContainer = null
	if with_footer:
		var bar := PanelContainer.new()
		bar.name = "Footer"
		bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -FOOTER_H
		# frame, not an object: a rule on one edge and no shelf. Same shared shape as the combat
		# top bar, mirrored — see DangoTheme.frame_bar_style().
		var sb := DangoTheme.frame_bar_style(SIDE_TOP, DangoTheme.Surface.PANEL, 3,
			Vector2(RAIL_X, 14))
		bar.add_theme_stylebox_override("panel", sb)
		host.add_child(bar)
		footer_row = HBoxContainer.new()
		footer_row.name = "FooterRow"
		footer_row.add_theme_constant_override("separation", 12)
		footer_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		bar.add_child(footer_row)

	var content := Control.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	# MOUSE_FILTER_IGNORE — THE COLUMN IS A LAYOUT SLOT, NOT A SURFACE (bug, 2026-09-21).
	#
	# `Control.new()` defaults to MOUSE_FILTER_STOP, and this node is a FULL-RECT rectangle
	# appended LAST to `host`. Godot picks GUI input by walking the children in reverse tree
	# order and does NOT consult `z_index` while doing it, so on Combat this transparent,
	# empty column sat on top of the entire board and ate every click inside
	# (side_inset, top_inset) .. (w - side_inset, h - bottom_inset): the enemy/party
	# nameplates, the 3D stage, and all but the bottom ~32px strip of the die cards, the
	# reroll and the end-turn button. That is the whole "only a tiny part of the skill card
	# responds / I cannot target an Axie or a boss" report, in one property.
	#
	# IGNORE does not disable the column's children — Godot tests children BEFORE the parent —
	# so every screen that adds its content here keeps working exactly as before. Nothing in
	# the build connects `gui_input` to this node or relies on it swallowing a click (checked
	# across all thirteen `DangoScreen.build()` call sites).
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(content)

	var apply := func() -> void:
		var vp: Vector2 = host.get_viewport_rect().size
		var col_w: float = minf(vp.x - side_inset * 2.0, CONTENT_MAX)
		var side: float = (vp.x - col_w) * 0.5
		content.offset_left = side
		content.offset_right = -side
		content.offset_top = top_inset
		content.offset_bottom = -(bottom_inset + (FOOTER_H if with_footer else 0.0))
	apply.call()
	host.get_viewport().size_changed.connect(apply)

	return {"content": content, "footer": footer_row}


## The BACK button. Always the first child of the footer, never anchored to the screen.
static func add_back_button(footer: HBoxContainer, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = "BackButton"
	b.text = "BACK"
	b.custom_minimum_size = Vector2(120, 44)
	DangoTheme.style_button(b, false)
	b.pressed.connect(on_press)
	footer.add_child(b)
	return b


## The primary action of a screen, right-aligned in the same footer.
static func add_footer_action(footer: HBoxContainer, text: String, on_press: Callable) -> Button:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(b, true)
	b.pressed.connect(on_press)
	footer.add_child(b)
	return b


## Wraps `inner` so its container HUGS the content and scrolls only on genuine overflow.
## This replaces every `anchor_bottom = 1.0` content panel in the build — those are what leave
## 400px of empty panel under a short grid.
static func fit_or_scroll(inner: Control, max_h: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "FitScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	DangoTheme.style_scrollbars(scroll)
	# style_scrollbars() alone leaves the bar at zero width — invisible, which is how a clipped
	# list ends up looking like a crash instead of like a list.
	scroll.get_v_scroll_bar().custom_minimum_size.x = 10

	var apply := func() -> void:
		scroll.custom_minimum_size.y = minf(inner.get_combined_minimum_size().y, max_h)
	apply.call()
	inner.minimum_size_changed.connect(apply)
	return scroll


## Modal width fitted to the real canvas. A fixed-width modal on a 2300px canvas is what forces
## three-line wraps inside a narrow box while most of the screen sits empty.
static func modal_width(host: Control) -> float:
	return clampf(host.get_viewport_rect().size.x * MODAL_FRACTION, MODAL_MIN, MODAL_MAX)


## Maps normalised 0..1 points into `rect` with a uniform inset. Use for the Run Map graph and
## anything else whose layout is a set of positions rather than a container: lay out in 0..1,
## fit at draw time, and the composition fills whatever canvas it gets.
static func fit_points(points: Array[Vector2], rect: Rect2, inset: float = 64.0) -> Array[Vector2]:
	var inner := Rect2(rect.position + Vector2(inset, inset),
		rect.size - Vector2(inset, inset) * 2.0)
	var out: Array[Vector2] = []
	for p in points:
		out.append(inner.position + Vector2(inner.size.x * p.x, inner.size.y * p.y))
	return out
