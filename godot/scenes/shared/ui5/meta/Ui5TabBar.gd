class_name Ui5TabBar
extends HBoxContainer
## UI-05 TabBar (meta1 .tab): each tab btn_m high, padding 0 / 20, radius m, bg plate_raised, Rowdies text_body. On =
## btn_secondary + 3 px ring in `selected`. Tabs share the width equally unless `fit` (then they hug their text).
## Signal tab_selected(index) on click and select(). Tabs are named Tab0, Tab1 …

signal tab_selected(index: int)

var _group := ButtonGroup.new()
var _tabs: Array[Button] = []


func setup(labels: Array, selected := 0, fit := false) -> void:
	name = "TabBar"
	add_theme_constant_override("separation", UI3Theme.space("8"))
	for i in labels.size():
		var b := Button.new()
		b.name = "Tab%d" % i
		b.theme = UI3Theme.get_theme()
		b.text = String(labels[i])
		b.toggle_mode = true
		b.button_group = _group
		b.button_pressed = i == selected
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size.y = UI3Theme.size_of("btn_m")
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if fit else Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", UI3Theme.font_display())
		b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		var pad := UI3Theme.space("20")
		var off := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0, Color.TRANSPARENT, Vector4(pad, 0, pad, 0))
		var on := UI3Theme.flat(UI3Theme.color("btn_secondary"), UI3Theme.radius("m"), 3, UI3Theme.color("selected"), Vector4(pad, 0, pad, 0))
		for st in ["normal", "hover", "disabled"]:
			b.add_theme_stylebox_override(st, off)
		for st in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, on)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, UI3Theme.color("text"))
		b.pressed.connect(func() -> void:
			_focus_follow(i)
			tab_selected.emit(i))
		add_child(b)
		_tabs.append(b)


func select(i: int) -> void:
	if i >= 0 and i < _tabs.size():
		_tabs[i].button_pressed = true
		_focus_follow(i)
		tab_selected.emit(i)


## The focus ring must not stay on the old tab: if focus is inside the bar it moves to the tab just chosen.
func _focus_follow(i: int) -> void:
	if not is_inside_tree() or _tabs[i].has_focus():
		return
	for t in _tabs:
		if t.has_focus():
			_tabs[i].grab_focus()
			return


func selected_index() -> int:
	for i in _tabs.size():
		if _tabs[i].button_pressed:
			return i
	return -1


func set_tab_disabled(i: int, off: bool, reason := "") -> void:
	_tabs[i].disabled = off
	_tabs[i].tooltip_text = reason if off else ""
