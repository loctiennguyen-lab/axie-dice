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
	# ...while hover keeps it (hover only changes colour, the warning glow should not vanish).
	var hover_warn := DangoTheme.primary_button_style(true, DangoTheme.ButtonState.HOVER)
	_assert(hover_warn.shadow_size > 0,
		"primary hover (warning=true): shadow_size is %d, expected > 0 — hover must not strip "
		% hover_warn.shadow_size + "chrome, only pressed does")
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
	# Disabled must not borrow hover's lighten or pressed's darken direction on bg_color — it
	# flattens via alpha only (Color(PRIMARY.darkened(0.3), 0.45) per spec, a distinct rgb from
	# all three of normal/hover/pressed).
	_assert(disabled_off.bg_color.r != normal.bg_color.r
			or disabled_off.bg_color.g != normal.bg_color.g
			or disabled_off.bg_color.b != normal.bg_color.b,
		"primary disabled: bg_color rgb identical to normal's — spec calls for "
		+ "PRIMARY.darkened(0.3), a distinct flattened tone")
	_assert(not is_equal_approx(disabled_off.bg_color.a, 1.0),
		"primary disabled: bg_color alpha is opaque (%f) — spec calls for alpha 0.45, the "
		% disabled_off.bg_color.a + "flatten signal a disabled control needs")
	_assert(disabled_off.shadow_size == 0,
		"primary disabled: shadow_size is %d, expected 0 (spec: 'không shadow')"
		% disabled_off.shadow_size)
	_assert(disabled_off.border_width_top == 2,
		"primary disabled: border_width is %d, expected fixed 2 per spec regardless of warning"
		% disabled_off.border_width_top)
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

	# Hover keeps BG_PANEL_SOFT's 0.55 alpha (per spec) but lightens rgb + brightens border.
	_assert(is_equal_approx(hover.bg_color.a, normal.bg_color.a),
		"secondary hover: alpha changed (%f -> %f) — spec says hover KEEPS the 0.55 alpha, only "
		% [normal.bg_color.a, hover.bg_color.a] + "pressed changes alpha")
	var normal_luma := normal.bg_color.r + normal.bg_color.g + normal.bg_color.b
	var hover_luma := hover.bg_color.r + hover.bg_color.g + hover.bg_color.b
	_assert(hover_luma > normal_luma,
		"secondary hover: bg_color rgb (%s) is not lighter than normal (%s) — spec calls for "
		% [hover.bg_color, normal.bg_color] + ".lightened(0.08)")
	_assert(hover.border_color != normal.border_color,
		"secondary hover: border_color unchanged — spec calls for PRIMARY.lightened(0.2), a "
		+ "brighter border ('translucent glow')")

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

	# Pressed jumps alpha to 0.85 with UNCHANGED rgb (opaque, not lightened) — opposite
	# alpha/lightness direction from hover, per spec ("solid, sunken" vs. "translucent glow").
	_assert(pressed.bg_color.a > normal.bg_color.a and pressed.bg_color.a > hover.bg_color.a,
		"secondary pressed: alpha (%f) is not higher than normal (%f) / hover (%f) — spec calls "
		% [pressed.bg_color.a, normal.bg_color.a, hover.bg_color.a] + "for alpha 0.85")
	_assert(is_equal_approx(pressed.bg_color.r, normal.bg_color.r)
			and is_equal_approx(pressed.bg_color.g, normal.bg_color.g)
			and is_equal_approx(pressed.bg_color.b, normal.bg_color.b),
		"secondary pressed: rgb (%s) differs from normal's (%s) — spec says pressed keeps rgb "
		% [pressed.bg_color, normal.bg_color] + "UNCHANGED (opaque, not lightened); only hover "
		+ "lightens rgb")
	_assert(pressed.border_color != normal.border_color and pressed.border_color != hover.border_color,
		"secondary pressed: border_color must be its own darker tone (PRIMARY.darkened(0.15)) "
		+ "distinct from both normal and hover's brighter border")

	_assert(pressed.border_width_top == 3 and pressed.border_width_top == normal.border_width_top + 1,
		"secondary pressed: border_width is %d, expected 3 (normal(%d) + 1)"
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
	# NOTE ON SPEC GAP (flag per task instructions): the art-director spec gave a numeric
	# disabled formula for the PRIMARY family only ("Color(PRIMARY.darkened(0.3), 0.45)"). No
	# secondary-family disabled formula was specified. DangoTheme.secondary_button_style()'s
	# DISABLED branch is this implementer's inferred analogue (alpha-only flatten, no
	# hover/pressed colour direction, no geometry change, no shadow — same INTENT as primary's
	# disabled, no matching numeric sign-off yet). This assertion only checks that inferred
	# value is self-consistent and distinct from the other three states; it is not a
	# reproduction of a designer-approved number the way the primary-family checks above are.
	_assert(disabled.bg_color.a < normal.bg_color.a,
		"secondary disabled: alpha (%f) is not lower than normal's (%f) — the inferred "
		% [disabled.bg_color.a, normal.bg_color.a] + "disabled treatment is meant to flatten, "
		+ "not raise, presence")
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
	# DELIBERATE SCOPE BOUNDARY: no font_color argument was passed, so style_button() must not
	# touch any font colour key. Every primary call site in the codebase that does not pass a
	# font_color today relies on this — touching font colour here would silently start "fixing"
	# the already-flagged white-on-orange ~2.2:1 contrast issue, which is explicitly out of
	# scope for this pass (needs separate art-director/user sign-off).
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		_assert(not primary_btn.has_theme_color_override(key),
			"style_button(primary=true, font_color=null) set a '%s' override — this must stay "
			% key + "untouched, it would silently change primary buttons' normal look")

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
