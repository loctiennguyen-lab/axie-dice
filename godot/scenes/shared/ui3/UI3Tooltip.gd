class_name UI3Tooltip
extends RefCounted
## UI-03 43 tooltips: hover (after tokens.motion.tooltip_delay_ms) and keyboard focus (at once) show ONE plate:
## <= 360 wide, wood-1, radius m, padding 16 x 12, soft shadow, body <= 178 chars wrapped at 328. Esc hides it.
## Replaces the native tooltip on the controls it is bound to (the text moves from `tooltip_text` into meta
## "ui3_tip"; read it back with `text_of`). Pure view: nothing here touches game state.

const MAX_W := 360.0
const BODY_W := 328.0
const LAYER_NAME := "UI3TooltipLayer"

static var _gen := 0


## Binds `text` to `c`. Empty text unbinds (no tooltip). Safe to call every refresh.
static func bind(c: Control, text: String) -> void:
	c.tooltip_text = ""
	if text == "":
		c.remove_meta("ui3_tip")
		return
	c.set_meta("ui3_tip", text)
	if c.has_meta("ui3_tip_bound"):
		return
	c.set_meta("ui3_tip_bound", true)
	c.mouse_entered.connect(_arm.bind(c))
	c.mouse_exited.connect(hide_for.bind(c))
	c.focus_entered.connect(_show.bind(c))
	c.focus_exited.connect(hide_for.bind(c))
	c.tree_exiting.connect(hide_for.bind(c))


static func text_of(c: Control) -> String:
	return String(c.get_meta("ui3_tip", c.tooltip_text))


static func _arm(c: Control) -> void:
	if not c.is_inside_tree():
		return
	_gen += 1
	var mine := _gen
	await c.get_tree().create_timer(UI3Theme.motion_sec("tooltip_delay_ms")).timeout
	if mine == _gen and is_instance_valid(c) and c.is_inside_tree() and c.get_global_rect().has_point(c.get_global_mouse_position()):
		_show(c)


static func _layer(c: Control) -> TooltipLayer:
	var root := c.get_tree().root
	var l := root.get_node_or_null(LAYER_NAME) as TooltipLayer
	if l == null:
		l = TooltipLayer.new()
		l.name = LAYER_NAME
		root.add_child(l)
	return l


## The plate for the current owner, or null while none is shown (tests read this).
static func shown_plate(tree: SceneTree) -> Control:
	var l := tree.root.get_node_or_null(LAYER_NAME) as TooltipLayer
	return l.plate if l != null and l.plate != null and l.plate.visible else null


static func _show(c: Control) -> void:
	if not c.is_inside_tree() or not c.has_meta("ui3_tip") or not c.is_visible_in_tree():
		return
	_layer(c).show_for(c, String(c.get_meta("ui3_tip")))


static func hide_for(c: Control) -> void:
	_gen += 1
	if c == null or not c.is_inside_tree():
		return
	var l := c.get_tree().root.get_node_or_null(LAYER_NAME) as TooltipLayer
	if l != null and l.owner_ctrl == c:
		l.hide_plate()


class TooltipLayer extends CanvasLayer:
	var plate: PanelContainer
	var label: Label
	var owner_ctrl: Control = null

	func _init() -> void:
		layer = 60

	func _ensure() -> void:
		if plate != null:
			return
		plate = PanelContainer.new()
		plate.name = "UI3Tooltip"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.theme = UI3Theme.get_theme()
		plate.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 2,
			UI3Theme.color("disabled_border"), Vector4(16, 12, 16, 12), {"y": 8, "color": Color(0, 0, 0, 0.35)}))
		add_child(plate)
		label = UI3.label("")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(label)
		plate.visible = false

	func show_for(c: Control, text: String) -> void:   # async: places itself after one frame
		_ensure()
		owner_ctrl = c
		label.text = TranslationServer.translate(text)
		var f := label.get_theme_font("font")
		var w := minf(f.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			label.get_theme_font_size("font_size")).x + 2.0, UI3Tooltip.BODY_W)
		label.custom_minimum_size = Vector2(w, 0)
		plate.visible = true
		plate.modulate.a = 0.0   # hidden for the one frame the wrapped label needs to know its height
		plate.reset_size()
		await get_tree().process_frame
		if not is_instance_valid(c) or owner_ctrl != c:
			return
		plate.reset_size()
		plate.modulate.a = 1.0
		var vp := c.get_viewport().get_visible_rect().size
		var r := c.get_global_rect()
		var sz := plate.get_combined_minimum_size()
		var pos := Vector2(r.position.x + r.size.x * 0.5 - sz.x * 0.5, r.end.y + 8.0)
		if pos.y + sz.y > vp.y - 8.0:
			pos.y = r.position.y - 8.0 - sz.y
		pos.x = clampf(pos.x, 8.0, maxf(vp.x - sz.x - 8.0, 8.0))
		pos.y = clampf(pos.y, 8.0, maxf(vp.y - sz.y - 8.0, 8.0))
		plate.position = pos
		plate.size = sz

	func hide_plate() -> void:
		if plate != null:
			plate.visible = false
		owner_ctrl = null

	func _input(event: InputEvent) -> void:
		if plate != null and plate.visible and event is InputEventKey and event.pressed and not event.echo \
				and (event as InputEventKey).keycode == KEY_ESCAPE:
			hide_plate()
			get_viewport().set_input_as_handled()
