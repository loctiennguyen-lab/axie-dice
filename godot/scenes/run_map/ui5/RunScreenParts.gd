class_name Ui5RunScreenParts
extends RefCounted
## UI-05 b23 lane R5b: the two small parts the Event and Treasure screens share.
## Source: design/handoffs/ui-05-figma/round-2/ui05-run-screens.html (`.shard-pill`, `.btn .keycap`).
## `shard_pill` = ShardPill (plate pill, shard icon + Rowdies title value). `set_space_cap` = the Space KeyCap after a
## button's caption, only while the button is on (a disabled button says why instead and carries no cap).

const _PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## ShardPill: pill plate, 16 side padding, `btn_m` high, shard icon (icon_m) then the count.
static func shard_pill(n: int) -> PanelContainer:
	var pad := UI3Theme.space("16")
	var box := _PanelParts.plate_box("pill")
	box.content_margin_left = pad
	box.content_margin_right = pad
	var chip := _PanelParts.panel(box, "ShardPill")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_m"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var px := UI3Theme.size_of("icon_m")
	row.add_child(_PanelParts.icon_rect(UI3.currency_icon("cur_shard", px), px))
	var v := _PanelParts.text(UI3.fmt(n), "text_title", "text", true)
	v.name = "Value"
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(v)
	return chip


## Adds (on) or removes (off) the Space KeyCap on `b`. The button must be in the tree; the cap is placed after layout.
static func set_space_cap(b: Button, on: bool) -> void:
	var pad := int(b.get_theme_stylebox("normal").content_margin_left)
	var cap := b.get_node_or_null("KeyCap") as PanelContainer
	if not on:
		if cap != null:
			b.remove_child(cap)
			cap.queue_free()
			Ui5HudStyle.reserve_trailing(b, null, pad)
		return
	if cap == null:
		cap = Ui5Keycap.make(KeyBindings.text(KeyBindings.COMBAT_END_TURN), &"primary")
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_child(cap)
		if not b.has_meta("cap_wired"):
			b.set_meta("cap_wired", true)
			b.resized.connect(_on_cap_resized.bind(b, pad))
	# Placed next frame, by instance id: a screen rebuilt before then frees the button, and a Callable that captured
	# the node itself would log "Lambda capture ... freed".
	(Engine.get_main_loop() as SceneTree).process_frame.connect(_place_by_id.bind(b.get_instance_id(), pad), CONNECT_ONE_SHOT)


static func _on_cap_resized(b: Button, pad: int) -> void:
	var c := b.get_node_or_null("KeyCap") as Control
	if c != null:
		Ui5HudStyle.place_trailing(b, c, pad)


static func _place_by_id(id: int, pad: int) -> void:
	var b := instance_from_id(id) as Button
	if b == null or not is_instance_valid(b) or not b.is_inside_tree():
		return
	var c := b.get_node_or_null("KeyCap") as Control
	if c != null:
		Ui5HudStyle.place_trailing(b, c, pad)
