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
	c.focus_entered.connect(_show.bind(c, true))
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


## True while a modal overlay (tutorial welcome curtain, starter card, skip confirm) is up. Controls under it
## cannot be hovered or focused by the player, so they must not raise a tooltip (BUG-0005). Modals join the group
## "ui3_modal"; only a visible member counts.
static func modal_open(tree: SceneTree) -> bool:
	for n in tree.get_nodes_in_group("ui3_modal"):
		if n is CanvasItem and (n as CanvasItem).is_visible_in_tree():
			return true
	return false


## Hides whatever tooltip is up and cancels any pending hover timer. Call when a modal opens.
static func hide_all(tree: SceneTree) -> void:
	_gen += 1
	var l := tree.root.get_node_or_null(LAYER_NAME) as TooltipLayer
	if l != null:
		l.hide_plate()


static func _show(c: Control, from_focus := false) -> void:
	if not c.is_inside_tree() or not c.has_meta("ui3_tip") or not c.is_visible_in_tree():
		return
	if modal_open(c.get_tree()):
		return
	_layer(c).show_for(c, String(c.get_meta("ui3_tip")), from_focus)


## Shows the tooltip at once (touch: the first tap on a place).
static func show_now(c: Control) -> void:
	_show(c)


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
	var title_label: Label
	var box: VBoxContainer
	var from_focus := false   # Esc is only eaten for a keyboard-focus tooltip; on mouse hover it reaches the pause menu

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
		box = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 4)
		plate.add_child(box)
		title_label = UI3.label("", "LabelDisplay")   # Rowdies, like other titles
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(title_label)
		label = UI3.label("")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
		plate.visible = false

	func show_for(c: Control, text: String, focus_origin := false) -> void:   # async: places itself after one frame
		_ensure()
		owner_ctrl = c
		from_focus = focus_origin
		var full := TranslationServer.translate(text)
		var nl := full.find("\n")
		title_label.visible = nl > 0
		title_label.text = full.substr(0, nl) if nl > 0 else ""
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = full.substr(nl + 1) if nl > 0 else full
		label.visible = label.text != ""
		var f := label.get_theme_font("font")
		var w := f.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label.get_theme_font_size("font_size")).x + 2.0
		if nl > 0:
			var tf := title_label.get_theme_font("font")
			w = maxf(w, tf.get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_label.get_theme_font_size("font_size")).x + 2.0)
		w = minf(w, UI3Tooltip.BODY_W)
		label.custom_minimum_size = Vector2(w, 0)
		title_label.custom_minimum_size = Vector2(w, 0)
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
		if c.has_meta("ui3_tip_side_of_row"):
			# Die cards: sit beside the tray (left of its first card) so no Axie above it is covered.
			var row := c.get_parent() as Control
			var rr := row.get_global_rect() if row != null else r
			pos = Vector2(rr.position.x - 16.0 - sz.x, r.position.y)
		var m := 24.0
		pos.x = clampf(pos.x, m, maxf(vp.x - sz.x - m, m))
		pos.y = clampf(pos.y, m, maxf(vp.y - sz.y - m, m))
		# Keep off banners that opt in (Attrition card): drop below them, or above if no room.
		for n in c.get_tree().get_nodes_in_group("ui3_tip_avoid"):
			var ar := (n as Control).get_global_rect()
			if (n as Control).is_visible_in_tree() and Rect2(pos, sz).intersects(ar):
				if ar.end.y + 8.0 + sz.y <= vp.y - m:
					pos.y = ar.end.y + 8.0
				else:
					pos.y = maxf(ar.position.y - 8.0 - sz.y, m)
		plate.position = pos
		plate.size = sz

	func hide_plate() -> void:
		if plate != null:
			plate.visible = false
		owner_ctrl = null

	func _input(event: InputEvent) -> void:
		if plate != null and plate.visible and from_focus and event is InputEventKey and event.pressed and not event.echo \
				and (event as InputEventKey).keycode == KEY_ESCAPE:
			hide_plate()
			get_viewport().set_input_as_handled()
