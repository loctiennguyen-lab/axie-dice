class_name Ui5SkipHint
extends HBoxContainer
## UI-05 b1 lane A: SkipHint "Click or [Space] to skip" (CSS .skip-hint, boss-intro frame; approved string).
## Text on the 3D view (on-view), gap space_8, anchored bottom-right at the screen margin by its host
## (`place_in(host_size)`). Lane E owns when it shows; this is only the look. The key follows the binding.

var action: StringName = KeyBindings.COMBAT_END_TURN
var _cap: PanelContainer


func _init(skip_action: StringName = KeyBindings.COMBAT_END_TURN) -> void:
	action = skip_action
	name = "SkipHint"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI3Theme.get_theme()
	add_theme_constant_override("separation", UI3Theme.space("8"))
	alignment = BoxContainer.ALIGNMENT_END
	var a := UI3.label(TranslationServer.translate("Click or"), "")
	a.name = "Lead"
	_cap = Ui5Keycap.make(KeyBindings.text(action))
	_cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var b := UI3.label(TranslationServer.translate("to skip"), "")
	b.name = "Tail"
	for l in [a, b]:
		Ui5HudStyle.on_view(l)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(a)
	add_child(_cap)
	add_child(b)


## Re-reads the key (rebinds) and the size tokens (1280 floor).
func refresh() -> void:
	(_cap.get_node("Key") as Label).text = KeyBindings.text(action)
	Ui5Keycap.refresh(_cap)


## Bottom-right of a host of `host_size`, at the screen margin.
func place_in(host_size: Vector2) -> void:
	size = Vector2.ZERO
	var m := get_combined_minimum_size()
	var edge := float(UI3Theme.space("screen"))
	position = host_size - Vector2(edge, edge) - m
	size = m
