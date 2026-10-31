class_name Ui5TabBar
extends HBoxContainer
## UI-05 TabBar: row of UI3.tab toggle buttons (one pressed at a time). Signal tab_selected(index) fires on click and on
## select(). Tabs are named Tab0, Tab1 …; a disabled tab keeps its label (use set_tab_disabled with a reason tooltip).

signal tab_selected(index: int)

var _group := ButtonGroup.new()
var _tabs: Array[Button] = []


func setup(labels: Array, selected := 0) -> void:
	name = "TabBar"
	add_theme_constant_override("separation", UI3Theme.space("8"))
	for i in labels.size():
		var b := UI3.tab(String(labels[i]), i == selected)
		b.name = "Tab%d" % i
		b.button_group = _group
		b.pressed.connect(func() -> void: tab_selected.emit(i))
		add_child(b)
		_tabs.append(b)


func select(i: int) -> void:
	if i >= 0 and i < _tabs.size():
		_tabs[i].button_pressed = true
		tab_selected.emit(i)


func selected_index() -> int:
	for i in _tabs.size():
		if _tabs[i].button_pressed:
			return i
	return -1


func set_tab_disabled(i: int, off: bool, reason := "") -> void:
	_tabs[i].disabled = off
	_tabs[i].tooltip_text = reason if off else ""
