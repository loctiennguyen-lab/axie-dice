extends SceneTree
## Builds `res://resources/theme/dango.tres` — the ONE Theme every scene's root Control wears.
##
##     Godot --headless --path godot --script tools/gen_theme.gd
##
## WHY THIS IS GENERATED AND NOT HAND-AUTHORED IN THE EDITOR. A Theme is ~40 StyleBoxFlat
## sub-resources; hand-editing that .tres is how a border width ends up at 2 on one control and
## 3 on the next. Here every value comes from `DangoTheme`, which is also what the screens call
## at runtime, so the theme and the code-built widgets cannot drift apart. Change DangoTheme,
## re-run this, commit both.
##
## WHAT BELONGS HERE vs. IN A SCREEN. The theme carries DEFAULTS — the font, the type sizes, the
## look of a plain Button, Panel, LineEdit and scrollbar. Anything that is one screen's specific
## object (a die card, a map token, a nameplate) is built by that screen against DangoTheme's
## helpers. If you find yourself adding a theme type named after a screen, it belongs in the
## screen.

const OUT := "res://resources/theme/dango.tres"


func _initialize() -> void:
	var theme := Theme.new()

	# Default = the READING face. An unstyled Label is nearly always prose; display type is
	# opted into by the screen that wants it, never inherited by accident.
	theme.default_font = DangoTheme.FONT_UI
	theme.default_font_size = 15

	_label(theme)
	_button(theme)
	_panels(theme)
	_inputs(theme)
	_scrollbars(theme)
	_progress(theme)
	_tabs(theme)
	_dropdown(theme)
	_checkbox(theme)

	var err := ResourceSaver.save(theme, OUT)
	if err != OK:
		push_error("gen_theme: ResourceSaver.save(%s) failed with %d" % [OUT, err])
		quit(1)
		return
	print("gen_theme: wrote %s" % OUT)
	quit(0)


func _label(theme: Theme) -> void:
	theme.set_font("font", "Label", DangoTheme.FONT_UI)
	theme.set_font_size("font_size", "Label", 15)
	theme.set_color("font_color", "Label", DangoTheme.TEXT)
	# Every Label gets the black outline for free. On a screen whose whole premise is that the
	# painted plate stays bright, a label with no outline is one stray placement away from
	# being illegible — and the alternative the handoff explicitly forbids is darkening the art.
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 0)

	theme.set_font("normal_font", "RichTextLabel", DangoTheme.FONT_UI)
	theme.set_font("bold_font", "RichTextLabel", DangoTheme.FONT_UI_BOLD)
	theme.set_font_size("normal_font_size", "RichTextLabel", 15)
	theme.set_color("default_color", "RichTextLabel", DangoTheme.TEXT)


func _button(theme: Theme) -> void:
	# A plain Button is a utility object: PANEL_RAISED, black outline, hard shelf. Screens that
	# want the Kam CTA call DangoTheme.style_button(btn, true).
	for state in [
			["normal", DangoTheme.ButtonState.NORMAL],
			["hover", DangoTheme.ButtonState.HOVER],
			["pressed", DangoTheme.ButtonState.PRESSED],
			["disabled", DangoTheme.ButtonState.DISABLED],
			["focus", DangoTheme.ButtonState.HOVER]]:
		theme.set_stylebox(String(state[0]), "Button", DangoTheme.secondary_button_style(state[1]))

	# Button LABELS are display type — they are one of the five things §02 names by hand.
	theme.set_font("font", "Button", DangoTheme.FONT_DISPLAY_BOLD)
	theme.set_font_size("font_size", "Button", 17)
	theme.set_color("font_color", "Button", DangoTheme.TEXT)
	theme.set_color("font_hover_color", "Button", DangoTheme.INK_ON_PRIMARY)
	theme.set_color("font_pressed_color", "Button", DangoTheme.INK_ON_PRIMARY)
	theme.set_color("font_focus_color", "Button", DangoTheme.INK_ON_PRIMARY)
	# Full-strength ink on a flattened fill — never a dimmed label. See DangoTheme's DISABLED note.
	theme.set_color("font_disabled_color", "Button", Color(DangoTheme.TEXT.r, DangoTheme.TEXT.g,
		DangoTheme.TEXT.b, 0.72))


func _panels(theme: Theme) -> void:
	# CHROME tone by default. A panel sitting on open artwork wants PANEL_DEEP and has to ask
	# for it — that choice is about the job the surface is doing, so it cannot be a default.
	theme.set_stylebox("panel", "PanelContainer", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL, 13, 3, 4.0))
	theme.set_stylebox("panel", "Panel", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL, 13, 3, 4.0))
	theme.set_stylebox("panel", "PopupPanel", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL_DEEP, 14, 4, 7.0))

	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("separation", "VBoxContainer", 8)


func _inputs(theme: Theme) -> void:
	var well := DangoTheme.surface_style(DangoTheme.Surface.WELL, 10, 3, 0.0, Vector2(12, 7))
	theme.set_stylebox("normal", "LineEdit", well)
	var focused := DangoTheme.surface_style(DangoTheme.Surface.WELL, 10, 3, 0.0, Vector2(12, 7))
	focused.border_color = DangoTheme.PRIMARY
	theme.set_stylebox("focus", "LineEdit", focused)
	theme.set_stylebox("read_only", "LineEdit", DangoTheme.surface_style(
		DangoTheme.Surface.WELL, 10, 3, 0.0, Vector2(12, 7)))
	theme.set_font("font", "LineEdit", DangoTheme.FONT_DISPLAY_SEMI)
	theme.set_font_size("font_size", "LineEdit", 17)
	theme.set_color("font_color", "LineEdit", DangoTheme.TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", DangoTheme.TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", DangoTheme.PRIMARY)

	theme.set_font("font", "Label", DangoTheme.FONT_UI)


func _scrollbars(theme: Theme) -> void:
	# Stock Godot scrollbars are the loudest remaining engine-default tell on the meta screens
	# — §04's last tree note says exactly that. The grabber gets the same 3px black outline as
	# everything else, because "everything else" is the rule with no exceptions.
	var track := DangoTheme.surface_style(DangoTheme.Surface.WELL, 7, 0, 0.0, Vector2(-1, -1))
	var grabber := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 7, 3, 0.0, Vector2(-1, -1))
	var grabber_hi := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 7, 3, 0.0, Vector2(-1, -1))
	grabber_hi.bg_color = DangoTheme.PRIMARY
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, track)
		theme.set_stylebox("grabber", bar, grabber)
		theme.set_stylebox("grabber_highlight", bar, grabber_hi)
		theme.set_stylebox("grabber_pressed", bar, grabber_hi)


func _progress(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", DangoTheme.surface_style(
		DangoTheme.Surface.WELL_DEEP, 7, 3, 0.0, Vector2(-1, -1)))
	var fill := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 5, 0, 0.0, Vector2(-1, -1))
	fill.bg_color = DangoTheme.SUCCESS
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_font("font", "ProgressBar", DangoTheme.FONT_DISPLAY)
	theme.set_font_size("font_size", "ProgressBar", 13)


# ── FIX-PASS-02 RC5 ─────────────────────────────────────────────────────────────────────────
#
# The theme did not define defaults for TabBar, OptionButton or CheckBox, so any screen that did
# not call `style_button()` by hand rendered stock Godot chrome — the Codex tab row and the
# Vault's `Olek (Plant)` dropdown are the two that shipped that way. A widget nobody styled must
# be visually IMPOSSIBLE, not merely discouraged, and the only place that can be guaranteed is
# here: a screen can forget, a generated theme cannot.


func _tabs(theme: Theme) -> void:
	# Selected tab is the Kam fill with ink on it; the others are raised utility objects. Same
	# vocabulary as a button, because to a player a tab IS a button.
	theme.set_stylebox("tab_selected", "TabBar", DangoTheme.primary_button_style(
		false, DangoTheme.ButtonState.NORMAL))
	theme.set_stylebox("tab_hovered", "TabBar", DangoTheme.secondary_button_style(
		DangoTheme.ButtonState.HOVER))
	theme.set_stylebox("tab_unselected", "TabBar", DangoTheme.secondary_button_style(
		DangoTheme.ButtonState.NORMAL))
	theme.set_stylebox("tab_disabled", "TabBar", DangoTheme.secondary_button_style(
		DangoTheme.ButtonState.DISABLED))
	theme.set_stylebox("panel", "TabContainer", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL, 14, 4, 0.0))
	theme.set_font("font", "TabBar", DangoTheme.FONT_DISPLAY_BOLD)
	theme.set_font_size("font_size", "TabBar", 15)
	theme.set_color("font_selected_color", "TabBar", DangoTheme.INK_ON_PRIMARY)
	theme.set_color("font_unselected_color", "TabBar", DangoTheme.TEXT)
	theme.set_color("font_hovered_color", "TabBar", DangoTheme.INK_ON_PRIMARY)
	theme.set_constant("h_separation", "TabBar", 8)


func _dropdown(theme: Theme) -> void:
	for state in [
			["normal", DangoTheme.ButtonState.NORMAL],
			["hover", DangoTheme.ButtonState.HOVER],
			["pressed", DangoTheme.ButtonState.PRESSED],
			["disabled", DangoTheme.ButtonState.DISABLED],
			["focus", DangoTheme.ButtonState.HOVER]]:
		theme.set_stylebox(String(state[0]), "OptionButton",
			DangoTheme.secondary_button_style(state[1]))
	theme.set_font("font", "OptionButton", DangoTheme.FONT_DISPLAY_SEMI)
	theme.set_font_size("font_size", "OptionButton", 15)
	theme.set_color("font_color", "OptionButton", DangoTheme.TEXT)
	theme.set_color("font_hover_color", "OptionButton", DangoTheme.INK_ON_PRIMARY)
	theme.set_color("font_pressed_color", "OptionButton", DangoTheme.INK_ON_PRIMARY)

	# The POPUP is the half everyone forgets: an OptionButton styled through its Button states
	# still drops a stock grey list when you click it, which is exactly what shipped on Vault.
	theme.set_stylebox("panel", "PopupMenu", DangoTheme.surface_style(
		DangoTheme.Surface.PANEL_DEEP, 12, 3, 7.0, Vector2(6, 6)))
	var hover := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 8, 0, 0.0, Vector2(8, 4))
	hover.bg_color = DangoTheme.PRIMARY
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_font("font", "PopupMenu", DangoTheme.FONT_DISPLAY_SEMI)
	theme.set_font_size("font_size", "PopupMenu", 15)
	theme.set_color("font_color", "PopupMenu", DangoTheme.TEXT)
	theme.set_color("font_hover_color", "PopupMenu", DangoTheme.INK_ON_PRIMARY)
	theme.set_constant("v_separation", "PopupMenu", 4)


func _checkbox(theme: Theme) -> void:
	# Godot draws a CheckBox's tick from an ICON, and there is no tick in this project's art. So
	# the box is built as a StyleBox instead: an unchecked box is a WELL (it holds something), a
	# checked box is a solid SUCCESS fill. That reads at a glance and needs no new asset.
	for cls in ["CheckBox", "CheckButton"]:
		for state in [
				["normal", DangoTheme.ButtonState.NORMAL],
				["hover", DangoTheme.ButtonState.HOVER],
				["pressed", DangoTheme.ButtonState.PRESSED],
				["disabled", DangoTheme.ButtonState.DISABLED]]:
			theme.set_stylebox(String(state[0]), cls,
				DangoTheme.secondary_button_style(state[1]))
		theme.set_font("font", cls, DangoTheme.FONT_DISPLAY_SEMI)
		theme.set_font_size("font_size", cls, 15)
		theme.set_color("font_color", cls, DangoTheme.TEXT)
		theme.set_color("font_hover_color", cls, DangoTheme.INK_ON_PRIMARY)
		theme.set_color("font_pressed_color", cls, DangoTheme.INK_ON_PRIMARY)
		theme.set_constant("h_separation", cls, 10)
