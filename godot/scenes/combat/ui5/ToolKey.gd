class_name Ui5ToolKey
extends VBoxContainer
## UI-05 b1 lane A: one ToolKey of the ActionDock (CSS .tool-key, data-names UndoKey / HoldKey / WildKey /
## OvercastKey). VBox, gap space_4, centred:
##   the Button itself, a round plate tool_key square (style A plate, sky focus ring), glyph icon_m in the middle
##   the word under it (Work Sans body, on-view)
## No key cap (Liam 28/10: only Space is shown). The button keeps its full state text ("Hold: pick a die") for
## tooltips, tests and screen readers; that text is not drawn. The key mirrors the button's own `visible` flag, so
## callers keep toggling `button.visible` exactly as before.

var button: Button
var glyph: ActionGlyph
var word: Label
var _on := false


func _init(key_name: String, b: Button, glyph_kind: StringName, word_text: String) -> void:
	name = key_name
	button = b
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	if b.get_parent() != null:
		b.get_parent().remove_child(b)
	add_child(b)
	glyph = ActionGlyph.new(glyph_kind)
	b.add_child(glyph)
	word = UI3.label(word_text, "")
	word.name = "Word"
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui5HudStyle.on_view_chip(word)   # B4: a chip behind the word, readable on snow / desert
	add_child(word)
	b.visibility_changed.connect(func() -> void: visible = b.visible)
	visible = b.visible
	refresh_tokens()


## Re-reads the size tokens. `key_w` = the key's share of the dock row (CSS width 76 = (dock - 3 gaps) / 4).
func refresh_tokens(key_w := -1.0) -> void:
	# CSS gap 4 is measured from the plate's border box; the lip is drawn below it in Godot, so it is added here.
	add_theme_constant_override("separation", UI3Theme.space("4") + Ui5HudStyle.lip())
	var t := float(UI3Theme.size_of("tool_key"))
	button.custom_minimum_size = Vector2(t, t)
	var g := float(UI3Theme.size_of("icon_m"))
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = (t - g) * 0.5
	glyph.offset_top = (t - g) * 0.5
	glyph.offset_right = -(t - g) * 0.5
	glyph.offset_bottom = -(t - g) * 0.5
	if key_w > 0.0:
		custom_minimum_size.x = key_w
	_style()


## Natural width: the larger of the plate and the word (with its chip) at the current font size.
func natural_width() -> float:
	var f := word.get_theme_font("font")
	var fs := word.get_theme_font_size("font_size")
	var ww := f.get_string_size(word.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if f != null else 0.0
	ww += Ui5HudStyle.view_chip_pad_x(word)
	return maxf(float(UI3Theme.size_of("tool_key")), ceilf(ww))


## A switched-on toggle (Hold full): selected outline instead of the rim; never reads as disabled.
func set_on(on: bool) -> void:
	if on == _on:
		ensure_style()
		return
	_on = on
	_style()


## Unusable tools look the same apart from the dimmed glyph; the tooltip says why.
func sync_dim() -> void:
	glyph.dim = button.disabled and not _on


## Re-asserts the key look if someone restyled the button after it was built (CombatView._connect_ui_buttons runs
## the legacy `_style_utility_button` on %UndoButton after the HUD adopted it). Cheap when nothing changed.
func ensure_style() -> void:
	var sb := button.get_theme_stylebox("normal")
	if sb != null and sb.has_meta("ui5_tool_key") and button.focus_mode == Control.FOCUS_ALL:
		return
	refresh_tokens()


func _style() -> void:
	var b := button
	b.icon = null
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.remove_theme_font_override("font")
	b.remove_theme_font_size_override("font_size")
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Color(0, 0, 0, 0))
	Ui5HudStyle.plate_button(button, UI3Theme.radius("pill"))
	if _on:
		for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			var sb := (button.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.bg_color = UI3Theme.color("btn_secondary")
			sb.set_border_width_all(UI3Theme.stroke("selected"))
			sb.border_color = UI3Theme.color("selected")
			button.add_theme_stylebox_override(st, sb)
	button.get_theme_stylebox("normal").set_meta("ui5_tool_key", true)
	sync_dim()
