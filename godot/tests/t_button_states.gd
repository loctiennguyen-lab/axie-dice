extends Node
## Gate for DangoTheme's button hover/pressed/disabled states (art-director state spec,
## `.claude/agent-memory/art-director/reference_dangotheme-button-state-spec.md`, decided
## 2026-09-19). Measured problem this closes: `DangoTheme.gd` had no hover/pressed StyleBox
## variants at all, and call sites either forced normal==hover==pressed to the identical
## StyleBoxFlat, or only ever set "normal" — either way, no button in the Godot port gave any
## visual feedback on hover or press.
##
## SCOPE: only the two button families the spec actually covers — `primary_button_style()`
## (filled CTA, e.g. End Turn/Begin Run) and `secondary_button_style()` (outline, e.g.
## Reroll/Back). Die-slot buttons (CombatView) and run-map node buttons (RunMapController) are a
## DELIBERATELY separate third family — their StyleBox/visual state already encodes game state
## (face type, used/dead, node type/fog), not press feedback, and changing that is its own
## design decision, out of scope here (per coordinator direction, 2026-09-19).
##
## Pure logic gate — no scene loading, no autoload dependency beyond DangoTheme itself (a
## RefCounted utility class, not an autoload), so this runs in plain SceneTree `--script` mode
## the same way `t_rng.gd`/`t_map_invariants.gd` do: fast, deterministic, no headless-render or
## timing risk.
##
## Run: godot --headless --path godot res://tests/t_button_states.tscn

## Every test in this file, by name. See t_vault.gd's own comment on why this list (and the
## completion check in _ready()) exists: a runtime error mid-test silently aborts the function,
## leaves `_failures` empty, and the gate reports PASS with fewer checks than it should have run.
const EXPECTED_TESTS: Array[String] = [
	"test_primary_four_states_are_pairwise_distinct",
	"test_primary_hover_changes_color_only_not_geometry",
	"test_primary_pressed_changes_color_and_geometry_opposite_of_hover",
	"test_primary_warning_true_differs_from_warning_false_on_normal_and_hover",
	"test_primary_disabled_ignores_warning_and_never_uses_hover_or_pressed_direction",
	"test_secondary_four_states_are_pairwise_distinct",
	"test_secondary_hover_changes_color_only_not_geometry",
	"test_secondary_pressed_changes_color_and_geometry_opposite_of_hover",
	"test_secondary_disabled_never_uses_hover_or_pressed_direction",
	"test_style_button_helper_applies_all_four_states_and_respects_font_color_scope",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	print("=== t_button_states: start ===")

	test_primary_four_states_are_pairwise_distinct()
	test_primary_hover_changes_color_only_not_geometry()
	test_primary_pressed_changes_color_and_geometry_opposite_of_hover()
	test_primary_warning_true_differs_from_warning_false_on_normal_and_hover()
	test_primary_disabled_ignores_warning_and_never_uses_hover_or_pressed_direction()
	test_secondary_four_states_are_pairwise_distinct()
	test_secondary_hover_changes_color_only_not_geometry()
	test_secondary_pressed_changes_color_and_geometry_opposite_of_hover()
	test_secondary_disabled_never_uses_hover_or_pressed_direction()
	test_style_button_helper_applies_all_four_states_and_respects_font_color_scope()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_button_states: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_button_states: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_button_states: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## A StyleBoxFlat's "does this look different" fingerprint — bg_color, border_color and
## border width (set_border_width_all() keeps all four sides equal everywhere in DangoTheme, so
## reading one side is representative). Two states with the same fingerprint would be visually
## indistinguishable to a player, which is exactly the bug this gate exists to prevent.
func _fingerprint(sb: StyleBoxFlat) -> String:
	return "%s|%s|%d" % [sb.bg_color, sb.border_color, sb.border_width_top]


func _assert_all_pairwise_distinct(styles: Dictionary, family: String) -> void:
	var names := styles.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: String = names[i]
			var b: String = names[j]
			_assert(_fingerprint(styles[a]) != _fingerprint(styles[b]),
				"%s: '%s' and '%s' states render identically (%s) — a player gets no visual "
				% [family, a, b, _fingerprint(styles[a])]
				+ "signal telling them apart")


# ===========================================================================
# Primary family (filled CTA — e.g. End Turn / Begin Run)
# ===========================================================================

func test_primary_four_states_are_pairwise_distinct() -> void:
	var styles := {
		"normal": DangoTheme.primary_button_style(false, DangoTheme.ButtonState.NORMAL),
		"hover": DangoTheme.primary_button_style(false, DangoTheme.ButtonState.HOVER),
		"pressed": DangoTheme.primary_button_style(false, DangoTheme.ButtonState.PRESSED),
		"disabled": DangoTheme.primary_button_style(false, DangoTheme.ButtonState.DISABLED),
	}
	_assert_all_pairwise_distinct(styles, "primary")
	# The single most important assertion per the task: hover must differ from pressed, not
	# merely from normal — a button that only lightens on hover AND on press gives no feedback
	# that a click actually registered as a PRESS rather than a second hover.
	_assert(styles["hover"].bg_color != styles["pressed"].bg_color,
		"primary: hover.bg_color == pressed.bg_color (%s) — hover and pressed are only "
		% styles["hover"].bg_color + "distinguishable from normal, not from each other")
	_done("test_primary_four_states_are_pairwise_distinct")


func test_primary_hover_changes_color_only_not_geometry() -> void:
	var normal := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.HOVER)

	_assert(hover.bg_color != normal.bg_color, "primary hover: bg_color did not change at all")
	# PRIMARY.lightened(0.15) per spec — hover must be brighter than normal, not just different.
	var normal_luma := normal.bg_color.r + normal.bg_color.g + normal.bg_color.b
	var hover_luma := hover.bg_color.r + hover.bg_color.g + hover.bg_color.b
	_assert(hover_luma > normal_luma,
		"primary hover: bg_color (%s) is not brighter than normal (%s) — spec calls for "
		% [hover.bg_color, normal.bg_color] + "PRIMARY.lightened(0.15)")

	# Geometry must be UNCHANGED on hover — this is the asymmetry the spec calls out by name.
	_assert(hover.border_width_top == normal.border_width_top,
		"primary hover: border_width changed (%d -> %d) — hover must only change colour"
		% [normal.border_width_top, hover.border_width_top])
	_assert(is_equal_approx(hover.content_margin_top, normal.content_margin_top)
			and is_equal_approx(hover.content_margin_bottom, normal.content_margin_bottom),
		"primary hover: content_margin changed (top %f->%f, bottom %f->%f) — hover must not "
		% [normal.content_margin_top, hover.content_margin_top,
			normal.content_margin_bottom, hover.content_margin_bottom]
		+ "move geometry, only pressed does")
	_assert(hover.corner_radius_top_left == normal.corner_radius_top_left,
		"primary hover: corner radius changed — hover must only change colour")
	_done("test_primary_hover_changes_color_only_not_geometry")


func test_primary_pressed_changes_color_and_geometry_opposite_of_hover() -> void:
	var normal := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.HOVER)
	var pressed := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.PRESSED)

	# PRIMARY.darkened(0.12) per spec — pressed must be darker than normal, opposite direction
	# from hover's lighten.
	var normal_luma := normal.bg_color.r + normal.bg_color.g + normal.bg_color.b
	var pressed_luma := pressed.bg_color.r + pressed.bg_color.g + pressed.bg_color.b
	_assert(pressed_luma < normal_luma,
		"primary pressed: bg_color (%s) is not darker than normal (%s) — spec calls for "
		% [pressed.bg_color, normal.bg_color] + "PRIMARY.darkened(0.12)")
	_assert(pressed_luma < hover.bg_color.r + hover.bg_color.g + hover.bg_color.b,
		"primary pressed: not darker than hover — hover/pressed must move in opposite colour "
		+ "directions from normal, not the same one")

	# Geometry: border_width +1, content_margin_top +1.0 / content_margin_bottom -1.0, net zero.
	_assert(pressed.border_width_top == normal.border_width_top + 1,
		"primary pressed: border_width is %d, expected normal(%d) + 1"
		% [pressed.border_width_top, normal.border_width_top])
	_assert(is_equal_approx(pressed.content_margin_top, normal.content_margin_top + 1.0),
		"primary pressed: content_margin_top is %f, expected normal(%f) + 1.0"
		% [pressed.content_margin_top, normal.content_margin_top])
	_assert(is_equal_approx(pressed.content_margin_bottom, normal.content_margin_bottom - 1.0),
		"primary pressed: content_margin_bottom is %f, expected normal(%f) - 1.0"
		% [pressed.content_margin_bottom, normal.content_margin_bottom])
	# Net zero — minimum-size / outer Control rect must not move.
	_assert(is_equal_approx(
			pressed.content_margin_top + pressed.content_margin_bottom,
			normal.content_margin_top + normal.content_margin_bottom),
		"primary pressed: content_margin top+bottom sum changed — this would move the button's "
		+ "minimum size / outer rect, which the +1/-1 asymmetry is supposed to net out to zero")

	# Pressed always drops the shadow, even under `warning` (spec: "và bỏ shadow").
	var pressed_warn := DangoTheme.primary_button_style(true, DangoTheme.ButtonState.PRESSED)
	_assert(pressed_warn.shadow_size == 0,
		"primary pressed (warning=true): shadow_size is %d, expected 0 — pressed must drop the "
		% pressed_warn.shadow_size + "shadow per spec")
	# ...while hover keeps it (hover only changes colour, the chrome should not vanish).
	#
	# UPDATED 2026-09-20 for the v2 surface system. This used to assert `shadow_size > 0`,
	# because v1 drew the warning state as a blurred DANGER glow. v2 has exactly one shadow in
	# the whole design — a hard shelf, which is `shadow_size == 0` with a y-only
	# `shadow_offset` — so `shadow_size > 0` now asserts the presence of the blurred shadow the
	# redesign exists to remove. The RULE is unchanged and is what is checked here: hover keeps
	# the button's depth, pressed takes it away.
	var hover_warn := DangoTheme.primary_button_style(true, DangoTheme.ButtonState.HOVER)
	_assert(hover_warn.shadow_offset.y > 0.0,
		"primary hover (warning=true): shadow_offset.y is %f, expected > 0 — hover must not "
		% hover_warn.shadow_offset.y + "strip the shelf, only pressed does")
	_assert(hover_warn.shadow_size == 0,
		"primary hover: shadow_size is %d, expected 0 — the only shadow in the v2 system is a "
		% hover_warn.shadow_size + "hard offset shelf; any blur is the dark-dashboard tell")
	_assert(pressed_warn.shadow_offset == Vector2.ZERO,
		"primary pressed: shadow_offset is %s, expected (0, 0) — the shelf being taken away IS "
		% pressed_warn.shadow_offset + "the press")
	_done("test_primary_pressed_changes_color_and_geometry_opposite_of_hover")


func test_primary_warning_true_differs_from_warning_false_on_normal_and_hover() -> void:
	for state in [DangoTheme.ButtonState.NORMAL, DangoTheme.ButtonState.HOVER,
			DangoTheme.ButtonState.PRESSED]:
		var off := DangoTheme.primary_button_style(false, state)
		var on := DangoTheme.primary_button_style(true, state)
		_assert(_fingerprint(off) != _fingerprint(on),
			"primary state %d: warning=true renders identically to warning=false (%s) — the "
			% [state, _fingerprint(off)] + "End Turn warning glow would be invisible")
	_done("test_primary_warning_true_differs_from_warning_false_on_normal_and_hover")


func test_primary_disabled_ignores_warning_and_never_uses_hover_or_pressed_direction() -> void:
	var disabled_off := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.DISABLED)
	var disabled_on := DangoTheme.primary_button_style(true, DangoTheme.ButtonState.DISABLED)
	_assert(_fingerprint(disabled_off) == _fingerprint(disabled_on),
		"primary disabled: warning=true (%s) differs from warning=false (%s) — spec says "
		% [_fingerprint(disabled_on), _fingerprint(disabled_off)]
		+ "disabled ignores the warning param entirely")

	var normal := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.HOVER)
	var pressed := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.PRESSED)
	# Disabled must not borrow hover's lighten or pressed's darken direction on bg_color — it is
	# its own flattened tone, distinct from all three.
	#
	# UPDATED 2026-09-20 for the v2 surface system. v1 flattened by dropping bg alpha to 0.45;
	# v2 forbids that outright, and says so in DangoTheme's own DISABLED note: a disabled surface
	# is a flat DESATURATED FILL with its ink at FULL strength, because blanket transparency
	# drops the label along with the card, and on the surface this rule was written for — a relic
	# active you cannot afford — the cost line is the entire reason the card is on screen. So the
	# alpha assertion is replaced by a saturation assertion in the same place, testing the same
	# thing it always tested: that "disabled" is visibly its own state and not a dimmer normal.
	_assert(disabled_off.bg_color.r != normal.bg_color.r
			or disabled_off.bg_color.g != normal.bg_color.g
			or disabled_off.bg_color.b != normal.bg_color.b,
		"primary disabled: bg_color rgb identical to normal's — it must be a distinct "
		+ "flattened tone")
	_assert(disabled_off.bg_color.s < normal.bg_color.s * 0.8,
		"primary disabled: saturation %f is not meaningfully below normal's %f — v2 flattens by "
		% [disabled_off.bg_color.s, normal.bg_color.s] + "desaturating the fill, never by alpha")
	_assert(is_equal_approx(disabled_off.bg_color.a, 1.0),
		"primary disabled: bg_color alpha is %f — v2 requires an OPAQUE disabled fill so the ink "
		% disabled_off.bg_color.a + "on top can stay at full strength")
	_assert(disabled_off.shadow_offset == Vector2.ZERO and disabled_off.shadow_size == 0,
		"primary disabled: has a shelf (offset %s, size %d) — a control that cannot be pressed "
		% [disabled_off.shadow_offset, disabled_off.shadow_size] + "does not sit above the page")
	_assert(disabled_off.border_width_top == normal.border_width_top,
		"primary disabled: border_width is %d, expected normal's %d regardless of warning — "
		% [disabled_off.border_width_top, normal.border_width_top]
		+ "disabled changes colour, never geometry")
	_done("test_primary_disabled_ignores_warning_and_never_uses_hover_or_pressed_direction")


# ===========================================================================
# Secondary family (outline — e.g. Reroll / Back / Remove)
# ===========================================================================

func test_secondary_four_states_are_pairwise_distinct() -> void:
	var styles := {
		"normal": DangoTheme.secondary_button_style(DangoTheme.ButtonState.NORMAL),
		"hover": DangoTheme.secondary_button_style(DangoTheme.ButtonState.HOVER),
		"pressed": DangoTheme.secondary_button_style(DangoTheme.ButtonState.PRESSED),
		"disabled": DangoTheme.secondary_button_style(DangoTheme.ButtonState.DISABLED),
	}
	_assert_all_pairwise_distinct(styles, "secondary")
	_assert(styles["hover"].bg_color != styles["pressed"].bg_color,
		"secondary: hover.bg_color == pressed.bg_color (%s) — an outline button's fill is "
		% styles["hover"].bg_color + "mostly transparent, so this is the one channel most "
		+ "likely to silently collide")
	_done("test_secondary_four_states_are_pairwise_distinct")


func test_secondary_hover_changes_color_only_not_geometry() -> void:
	var normal := DangoTheme.secondary_button_style(DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.secondary_button_style(DangoTheme.ButtonState.HOVER)

	# UPDATED 2026-09-20 for the v2 surface system. v1 made this button a translucent outline and
	# signalled its states through ALPHA; v2 makes it an opaque PANEL_RAISED object with a
	# pure-black outline and signals through FILL, because an alpha change against a bright
	# painted plate — which, after the background formula, is now every screen — is not a
	# reliable signal, and the orange outline had started reading as a selection state. The rule
	# being tested is the same one as before and has not moved: hover changes COLOUR ONLY.
	_assert(is_equal_approx(normal.bg_color.a, 1.0) and is_equal_approx(hover.bg_color.a, 1.0),
		"secondary: fill is translucent (normal a=%f, hover a=%f) — v2 secondary is an opaque "
		% [normal.bg_color.a, hover.bg_color.a] + "PANEL_RAISED surface")
	var normal_luma := normal.bg_color.r + normal.bg_color.g + normal.bg_color.b
	var hover_luma := hover.bg_color.r + hover.bg_color.g + hover.bg_color.b
	_assert(hover_luma > normal_luma,
		"secondary hover: bg_color (%s) is not brighter than normal (%s) — the REROLL redline "
		% [hover.bg_color, normal.bg_color] + "calls for a PRIMARY fill on hover")
	_assert(hover.border_color == Color.BLACK and normal.border_color == Color.BLACK,
		"secondary: border is not pure black (normal %s, hover %s) — one outline, #000000, "
		% [normal.border_color, hover.border_color] + "never a coloured or translucent hairline")

	_assert(hover.border_width_top == normal.border_width_top,
		"secondary hover: border_width changed (%d -> %d) — hover must only change colour"
		% [normal.border_width_top, hover.border_width_top])
	_assert(is_equal_approx(hover.content_margin_top, normal.content_margin_top)
			and is_equal_approx(hover.content_margin_bottom, normal.content_margin_bottom),
		"secondary hover: content_margin changed — hover must not move geometry, only pressed "
		+ "does")
	_done("test_secondary_hover_changes_color_only_not_geometry")


func test_secondary_pressed_changes_color_and_geometry_opposite_of_hover() -> void:
	var normal := DangoTheme.secondary_button_style(DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.secondary_button_style(DangoTheme.ButtonState.HOVER)
	var pressed := DangoTheme.secondary_button_style(DangoTheme.ButtonState.PRESSED)

	# UPDATED 2026-09-20 with the hover assertion above, and for the same reason. v1 put hover
	# and pressed in opposite ALPHA directions; v2 puts them in opposite LUMA directions — hover
	# fills PRIMARY, pressed darkens it — which is the same "translucent glow vs. solid sunken"
	# contrast expressed in a channel that survives being drawn over artwork. Pressed also drops
	# the shelf, which v1 had no shelf to drop.
	var pressed_luma := pressed.bg_color.r + pressed.bg_color.g + pressed.bg_color.b
	var hover_luma := hover.bg_color.r + hover.bg_color.g + hover.bg_color.b
	_assert(pressed_luma < hover_luma,
		"secondary pressed: bg_color (%s) is not darker than hover (%s) — hover and pressed must "
		% [pressed.bg_color, hover.bg_color] + "move in opposite directions, not just both away "
		+ "from normal")
	_assert(pressed.bg_color != normal.bg_color,
		"secondary pressed: fill is identical to normal's (%s)" % pressed.bg_color)
	_assert(pressed.shadow_offset == Vector2.ZERO and normal.shadow_offset.y > 0.0,
		"secondary: normal shelf %s / pressed shelf %s — the press is the shelf being taken away"
		% [normal.shadow_offset, pressed.shadow_offset])

	_assert(pressed.border_width_top == normal.border_width_top + 1,
		"secondary pressed: border_width is %d, expected normal(%d) + 1"
		% [pressed.border_width_top, normal.border_width_top])
	_assert(is_equal_approx(pressed.content_margin_top, normal.content_margin_top + 1.0),
		"secondary pressed: content_margin_top is %f, expected normal(%f) + 1.0"
		% [pressed.content_margin_top, normal.content_margin_top])
	_assert(is_equal_approx(pressed.content_margin_bottom, normal.content_margin_bottom - 1.0),
		"secondary pressed: content_margin_bottom is %f, expected normal(%f) - 1.0"
		% [pressed.content_margin_bottom, normal.content_margin_bottom])
	_assert(is_equal_approx(
			pressed.content_margin_top + pressed.content_margin_bottom,
			normal.content_margin_top + normal.content_margin_bottom),
		"secondary pressed: content_margin top+bottom sum changed — minimum-size must not move")
	_done("test_secondary_pressed_changes_color_and_geometry_opposite_of_hover")


func test_secondary_disabled_never_uses_hover_or_pressed_direction() -> void:
	var normal := DangoTheme.secondary_button_style(DangoTheme.ButtonState.NORMAL)
	var hover := DangoTheme.secondary_button_style(DangoTheme.ButtonState.HOVER)
	var pressed := DangoTheme.secondary_button_style(DangoTheme.ButtonState.PRESSED)
	var disabled := DangoTheme.secondary_button_style(DangoTheme.ButtonState.DISABLED)

	_assert(_fingerprint(disabled) != _fingerprint(normal)
			and _fingerprint(disabled) != _fingerprint(hover)
			and _fingerprint(disabled) != _fingerprint(pressed),
		"secondary disabled (%s) collides with another state — a disabled REMOVE/BACK button "
		% _fingerprint(disabled) + "would be indistinguishable from an interactive one")
	# The SPEC GAP this block used to flag is now closed. v1 had no numeric disabled formula for
	# the secondary family, so the implementation inferred one (alpha-only flatten) and this
	# assertion checked only that the inference was self-consistent. The v2 handoff states the
	# rule for every surface in the system, not just the primary family: a disabled surface is a
	# flat DESATURATED fill with its ink at FULL strength, never a blanket alpha. So the check
	# is now against a stated rule rather than an inference.
	_assert(is_equal_approx(disabled.bg_color.a, 1.0),
		"secondary disabled: alpha is %f — v2 flattens by darkening an OPAQUE fill, never by "
		% disabled.bg_color.a + "dropping alpha, so the label on top can stay readable")
	var disabled_luma := disabled.bg_color.r + disabled.bg_color.g + disabled.bg_color.b
	var normal_luma_d := normal.bg_color.r + normal.bg_color.g + normal.bg_color.b
	_assert(disabled_luma < normal_luma_d,
		"secondary disabled (%s) is not flatter than normal (%s) — disabled must reduce "
		% [disabled.bg_color, normal.bg_color] + "presence, not raise it")
	_assert(disabled.shadow_offset == Vector2.ZERO,
		"secondary disabled: keeps a shelf (%s) — a control that cannot be pressed does not sit "
		% disabled.shadow_offset + "above the page")
	_done("test_secondary_disabled_never_uses_hover_or_pressed_direction")


# ===========================================================================
# style_button() convenience helper
# ===========================================================================

func test_style_button_helper_applies_all_four_states_and_respects_font_color_scope() -> void:
	var primary_btn := Button.new()
	DangoTheme.style_button(primary_btn, true)
	for key in ["normal", "hover", "pressed", "disabled"]:
		_assert(primary_btn.has_theme_stylebox_override(key),
			"style_button(primary=true): no '%s' StyleBox override applied" % key)
	# REVERSED 2026-09-20, deliberately. This used to assert the OPPOSITE — that style_button()
	# must not touch a font colour when none was passed — because the white-on-Kam-orange pair
	# was a known ~2.2:1 failure that was explicitly out of scope and awaiting sign-off. The v2
	# handoff signs it off (§02: "Never white ink on the orange fill... All primary buttons use
	# #2A1505"), so the default is now the fix rather than the bug, and it is applied in
	# style_button() rather than at each call site precisely so the bad pairing cannot come back
	# one screen at a time.
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		_assert(primary_btn.has_theme_color_override(key),
			"style_button(primary=true, font_color=null) left '%s' unset — a primary button must "
			% key + "ink itself at INK_ON_PRIMARY, never inherit white onto the orange fill")
		_assert(primary_btn.get_theme_color(key).is_equal_approx(DangoTheme.INK_ON_PRIMARY),
			"style_button(primary=true): '%s' is %s, expected INK_ON_PRIMARY #2A1505 (11.4:1); "
			% [key, primary_btn.get_theme_color(key)] + "white on #FF9345 measures 2.2:1")

	var secondary_btn := Button.new()
	DangoTheme.style_button(secondary_btn, false, false, DangoTheme.TEXT)
	for key in ["normal", "hover", "pressed", "disabled"]:
		_assert(secondary_btn.has_theme_stylebox_override(key),
			"style_button(primary=false): no '%s' StyleBox override applied" % key)
	_assert(secondary_btn.get_theme_color("font_color") == DangoTheme.TEXT,
		"style_button(): font_color override did not stick")
	_assert(secondary_btn.get_theme_color("font_hover_color") == DangoTheme.TEXT,
		"style_button(): font_hover_color did not match the font_color passed in — hovering "
		+ "this button would flip its text to Godot's default theme colour")
	_assert(secondary_btn.get_theme_color("font_pressed_color") == DangoTheme.TEXT,
		"style_button(): font_pressed_color did not match the font_color passed in")
	var disabled_font: Color = secondary_btn.get_theme_color("font_disabled_color")
	_assert(disabled_font.a < DangoTheme.TEXT.a,
		"style_button(): font_disabled_color alpha (%f) is not lower than the base font_color's alpha (%f) — a disabled button's text should read as dimmer"
		% [disabled_font.a, DangoTheme.TEXT.a])

	# Cleanup — these two Buttons were never added to the tree (pure StyleBox/theme-override
	# checks don't need it), so nothing else will free them.
	primary_btn.free()
	secondary_btn.free()
	_done("test_style_button_helper_applies_all_four_states_and_respects_font_color_scope")
