extends Node
## UI-03 component gallery: every UI3 builder in every state on one 1920x1080 page.
## Saves ui3-gallery.png into QaPaths.evidence_dir() and quits. NOT headless (the dummy rasterizer
## gives a white image): godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_gallery_capture.tscn
## Hover / pressed cannot be forced on a live Button, so those cells put the theme's own hover /
## pressed StyleBox on the normal slot; focus cells show the UI3 focus ring.

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var root := Control.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var left := VBoxContainer.new()
	left.position = Vector2(24, 16)
	left.size = Vector2(1000, 1040)
	left.add_theme_constant_override("separation", 4)
	root.add_child(left)
	var right := VBoxContainer.new()
	right.position = Vector2(1030, 16)
	right.size = Vector2(866, 1040)
	right.add_theme_constant_override("separation", 4)
	root.add_child(right)

	_buttons(left)
	_misc_left(left)
	_dice(right)

	for _i in 12:
		await get_tree().process_frame
	var path := QaPaths.evidence_dir() + "/ui3-gallery.png"
	var img := get_tree().root.get_texture().get_image()
	if img.get_size() != Vector2i(1920, 1080):
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	img.save_png(path)
	print("QA: saved ", path)
	_guard.restore()
	get_tree().quit(0)


func _section(parent: Control, text: String) -> void:
	parent.add_child(UI3.label(text.to_upper(), "LabelKeyHint"))


func _row(parent: Control, gap := 16) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", gap)
	parent.add_child(r)
	return r


func _buttons(parent: Control) -> void:
	_section(parent, "Buttons: normal / hover / pressed / disabled (reason) / focus")
	var th := UI3Theme.get_theme()
	var specs := [[&"primary", &"L", "Start"], [&"primary", &"M", "Confirm"],
		[&"secondary", &"M", "Back"], [&"secondary", &"S", "Retry"],
		[&"danger", &"M", "Abandon"], [&"quiet", &"M", "Skip"]]
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	var flow := HFlowContainer.new()   # disabled buttons carry long reasons, so they wrap instead of widening the grid
	flow.custom_minimum_size.x = 1000
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 4)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		for s in specs:
			var b := UI3.button(s[2], s[0], s[1])
			var tn := b.theme_type_variation
			match state:
				"hover", "pressed":
					b.add_theme_stylebox_override("normal", th.get_stylebox(state, tn))
					b.add_theme_color_override("font_color", th.get_color("font_%s_color" % state, tn))
				"disabled":
					UI3.set_disabled_reason(b, "Locked · needs 50 Shards" if s[1] == &"L" else "Needs 50 Shards")
				"focus":
					UI3.attach_focus_ring(b).visible = true
			var holder := MarginContainer.new()
			holder.add_theme_constant_override("margin_bottom", 4)
			holder.add_child(b)
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			(flow if state == "disabled" else grid).add_child(holder)
	parent.add_child(flow)


func _misc_left(parent: Control) -> void:
	_section(parent, "Icon buttons, chip, key hints, tabs")
	var r := _row(parent)
	var th := UI3Theme.get_theme()
	for ic in ["ui_settings", "ui_undo", "ui_reroll", "ui_lock"]:
		r.add_child(UI3.icon_button(ic))
	var pr := UI3.icon_button("ui_settings")
	pr.add_theme_stylebox_override("normal", th.get_stylebox("pressed", "IconButton"))
	r.add_child(pr)
	var dis := UI3.icon_button("ui_lock")
	dis.disabled = true
	r.add_child(dis)
	var fb := UI3.icon_button("ui_undo")
	UI3.attach_focus_ring(fb).visible = true
	r.add_child(fb)
	r.add_child(UI3.chip("New best"))
	r.add_child(UI3.key_hint("Esc"))
	r.add_child(UI3.key_hint("R"))
	var tabs := _row(parent, 8)
	for i in 3:
		var tab := Label.new()
		tab.text = ["Missions", "Daily", "Pass"][i]
		tab.theme_type_variation = "LabelDisplay"
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(160, 56)
		var key := "tab_selected" if i == 0 else "tab_unselected"
		p.add_theme_stylebox_override("panel", th.get_stylebox(key, "TabBar"))
		tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(tab)
		tabs.add_child(p)
	var hov := PanelContainer.new()
	hov.custom_minimum_size = Vector2(160, 56)
	hov.add_theme_stylebox_override("panel", th.get_stylebox("tab_hovered", "TabBar"))
	hov.add_child(UI3.label("Hover", "LabelDisplay"))
	tabs.add_child(hov)

	_section(parent, "Currency pill, plates, cards")
	var pr2 := _row(parent)
	pr2.add_child(UI3.currency_pill([{"icon": "cur_gem", "value": "1,240"},
		{"icon": "cur_shard", "value": "86"}, {"icon": "cur_stone", "value": "12"}]))
	var plates := _row(parent)
	var kinds := [[&"plate", "Plate"], [&"card", "Card"], [&"card_selected", "Selected"],
		[&"row", "Row"], [&"info", "Info"]]
	for k in kinds:
		var p := UI3.plate(k[0])
		p.custom_minimum_size = Vector2(150, 64)
		p.add_child(UI3.label(k[1], "LabelTitle"))
		plates.add_child(p)
		if k[0] == &"card_selected":
			UI3.set_card_selected.call_deferred(p, true)
	var dis_card := UI3.plate(&"card")
	dis_card.custom_minimum_size = Vector2(150, 64)
	dis_card.modulate.a = 0.4
	dis_card.add_child(UI3.label("Sold out", "LabelTitle"))
	plates.add_child(dis_card)

	_section(parent, "Toast, network notice, skeleton, input, progress, scrollbar")
	var tr_ := _row(parent)
	var t1 := UI3.toast("Run saved")
	t1.custom_minimum_size.x = 230
	tr_.add_child(t1)
	var t2 := UI3.toast("Could not reach server", &"error")
	t2.custom_minimum_size.x = 330
	tr_.add_child(t2)
	var n2 := UI3.net_notice("Reconnecting", "Retry", Callable(), true)
	n2.custom_minimum_size.x = 250
	tr_.add_child(n2)
	var nr := _row(parent)
	var n1 := UI3.net_notice("You are offline. Normal runs still work.", "Retry", Callable())
	n1.custom_minimum_size.x = 600
	nr.add_child(n1)
	var sk := UI3.skeleton_row(48)
	sk.custom_minimum_size.x = 380
	sk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nr.add_child(sk)
	var inp := _row(parent)
	var le := LineEdit.new()
	le.text = "Axie name"
	le.custom_minimum_size = Vector2(230, 44)
	inp.add_child(le)
	var le2 := LineEdit.new()
	le2.placeholder_text = "Placeholder"
	le2.custom_minimum_size = Vector2(230, 44)
	inp.add_child(le2)
	var le3 := LineEdit.new()
	le3.text = "Read only"
	le3.editable = false
	le3.custom_minimum_size = Vector2(230, 44)
	inp.add_child(le3)
	var pb := ProgressBar.new()
	pb.value = 60
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(280, 16)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inp.add_child(pb)
	var sb := VScrollBar.new()
	sb.max_value = 100
	sb.page = 40
	sb.value = 20
	sb.custom_minimum_size = Vector2(8, 80)
	inp.add_child(sb)


func _dice(parent: Control) -> void:
	_section(parent, "Die face tiles: normal / selected / used / disabled (axie 88, egg 56)")
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	parent.add_child(grid)
	var tilts := [-3.0, 2.0, -2.0, 4.0, -4.0, 3.0, -5.0, 2.0, -3.0]
	for st in UI3.DIE_STATES:
		for i in UI3.FACE_TYPES.size():
			var cell := MarginContainer.new()
			cell.add_theme_constant_override("margin_top", 26)
			cell.add_theme_constant_override("margin_bottom", 0)
			cell.add_child(UI3.die_tile(UI3.FACE_TYPES[i], 3 + i, &"axie", st, tilts[i]))
			grid.add_child(cell)
	_section(parent, "Egg dice (56) and HP bars: axie / enemy / boss with shield + poison")
	var egg_pad := MarginContainer.new()
	egg_pad.add_theme_constant_override("margin_top", 22)
	parent.add_child(egg_pad)
	var eggs := _row(egg_pad, 10)
	for i in [0, 2, 3, 6, 7]:
		var st := &"selected" if i == 3 else (&"used" if i == 6 else &"normal")
		eggs.add_child(UI3.die_tile(UI3.FACE_TYPES[i], 2, &"egg", st, 3.0))
	var specs := [[&"axie", 22, 40, 8, 3], [&"enemy", 14, 40, 0, 2], [&"boss", 90, 120, 15, 0]]
	for s in specs:
		var b := UI3.hp_bar(s[1], s[2], s[3], s[4], s[0])
		b.custom_minimum_size.x = 110
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		eggs.add_child(b)
	_section(parent, "Modal: confirm (destructive, focus on Cancel) over scrim")
	var host := Control.new()
	host.custom_minimum_size = Vector2(866, 230)
	host.clip_contents = true
	var fake := ColorRect.new()
	fake.color = UI3Theme.color("viewport")
	fake.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(fake)
	var cancel := UI3.button("Cancel", &"secondary")
	var go := UI3.button("Abandon run", &"danger")
	host.add_child(UI3.modal("Abandon this run?", "You keep your Shards. The run cannot be resumed.", [cancel, go], 0))
	parent.add_child(host)
