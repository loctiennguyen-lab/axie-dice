extends RefCounted
## UI-05 b23 lane R4: MakeRoomSheet (round-2 ui05-run-screens.html, 47-core-offer--make-room). Build with
## MakeRoomSheet.build(...). Tree: SlotSwapSheet (ModalRoot) > Scrim + MakeRoomSheet > [Head(Title, Line), OwnedList >
## SellRow(CoreSlot, CoreName, TierChip, SellButton)*, Footer(Taking(Label, TakingName), BackButton)].
## Each SellButton is the explicit action: pressing it sells that Core and takes the new one. Esc = Back (frame has no confirm).
## Every size is a token. `cells` = [{id, name, kind, sell, eternal}] (as RunMapSlotSwap builds them).

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Parts := preload("res://scenes/run_map/ui5/RunMenuParts.gd")
const ComboBand := preload("res://scenes/run_map/ui5/ComboBand.gd")


static func build(new_title: String, new_tier: int, line: String, cells: Array, on_confirm: Callable,
		on_back: Callable, title_text := "") -> UI3.ModalRoot:
	var root := UI3.ModalRoot.new()
	root.name = "SlotSwapSheet"
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var pad := UI3Theme.space("32")
	var sheet := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(pad, pad, pad, pad)), "MakeRoomSheet")
	sheet.custom_minimum_size.x = UI3Theme.size_of("room_panel_w")
	center.add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	sheet.add_child(col)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	col.add_child(head)
	var title := PanelParts.text(title_text if title_text != "" else TranslationServer.translate("Make room"), "text_banner", "text", true)
	title.name = "Title"
	head.add_child(title)
	var ln := PanelParts.text(line, "text_body", "text")
	ln.name = "Line"
	ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(ln)
	var list := VBoxContainer.new()
	list.name = "OwnedList"
	list.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(list)

	var sells: Array[Button] = []
	var fired := [false]
	var back := UI3.button(TranslationServer.translate("Back"), &"secondary", &"M")
	back.name = "BackButton"
	var refresh_actions := func() -> void:
		var a: Array = []
		a.append_array(sells.filter(func(x: Button) -> bool: return not x.disabled))
		a.append(back)
		root.actions = a
		root.focus_index = sells.filter(func(x: Button) -> bool: return not x.disabled).size()   # Back, as the frame
	for c in cells:
		var cell: Dictionary = c
		var id := String(cell.get("id", ""))
		var def = RelicRegistry.get_def(id)
		var tier := clampi(int(def.rarity) if def != null else 0, 0, 2)
		var row := PanelParts.panel(_row_box(false), "SellRow")
		row.custom_minimum_size.y = UI3Theme.size_of("menu_row_h")
		row.set_meta("relic_id", id)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", UI3Theme.space("12"))
		row.add_child(h)
		h.add_child(ComboBand.core_socket(id, UI3Theme.size_of("core_slot")))
		var names := VBoxContainer.new()
		names.name = "Names"
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		names.add_theme_constant_override("separation", 0)
		var nm := PanelParts.text(String(cell.get("name", "")), "text_body", "text", true)
		nm.name = "CoreName"
		names.add_child(nm)
		var hl := PanelParts.text("", "text_body", "core_headline")
		hl.name = "Headline"
		CoreHeadline.apply(hl, id)
		names.add_child(hl)
		h.add_child(names)
		var sh := TierShards.new().setup(tier, UI3Theme.size_of("icon_m"))
		sh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(sh)
		var eternal := bool(cell.get("eternal", false))
		var sb := UI3.button("%s · +%d" % [TranslationServer.translate("Sell"), int(cell.get("sell", 0))], &"secondary", &"S")
		sb.name = "SellButton"
		sb.set_meta("relic_id", id)
		sb.icon = UI3.icon("cur_shard")
		sb.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sb.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_s"))
		h.add_child(sb)
		list.add_child(row, true)   # readable unique names: SellRow, SellRow2 ...
		sells.append(sb)
		if eternal:
			UI3.set_disabled_reason(sb, TranslationServer.translate("Can't sell"))
			sb.icon = null
			row.modulate.a = 0.6
			continue
		sb.pressed.connect(func() -> void:
			if fired[0]:
				return   # one sale per sheet: a double click must not log a second swap
			fired[0] = true
			on_confirm.call(id))
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(foot)
	var taking := HBoxContainer.new()
	taking.name = "Taking"
	taking.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	taking.add_theme_constant_override("separation", UI3Theme.space("8"))
	var lead := PanelParts.text(TranslationServer.translate("Taking: %s").replace("%s", "").strip_edges(), "text_body", "text_muted")
	lead.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	taking.add_child(lead)
	var tsh := TierShards.new().setup(new_tier, UI3Theme.size_of("icon_m"))
	tsh.name = "TakingShards"
	tsh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	taking.add_child(tsh)
	var tn := PanelParts.text(new_title, "text_body", Parts.TIER_TOKEN[clampi(new_tier, 0, 2)], true)
	tn.name = "TakingName"
	tn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	taking.add_child(tn)
	foot.add_child(taking)
	foot.add_child(back)
	back.pressed.connect(func() -> void: on_back.call())
	root.cancelled.connect(func() -> void: on_back.call())
	refresh_actions.call()
	return root


## `.room-row`: plate_raised, radius m, padding 8 8 8 16; the picked row gets the selected ring.
static func _row_box(_picked: bool) -> StyleBoxFlat:
	var p8 := UI3Theme.space("8")
	return UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0,
		UI3Theme.color("selected_outline"), Vector4(UI3Theme.space("16"), p8, p8, p8))
