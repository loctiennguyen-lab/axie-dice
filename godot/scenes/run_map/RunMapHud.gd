class_name RunMapHud
extends RefCounted
## Left plate (party/Cores/relics) and the right detail plate. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

func _rebuild_left() -> void:
	for c in ctrl._left_root.get_children():
		ctrl._left_root.remove_child(c)
		c.queue_free()

	# TopLeft: RunInfo row (frame 03-run-map--cores-strip: MenuButton, RunPill, AnchorChip), then the party plate.
	var info := Ui5RunInfo.new()
	info.position = Vector2(ctrl._SCREEN_MARGIN, ctrl._SCREEN_MARGIN)
	info.menu_button.tooltip_text = tr("Menu")
	info.menu_button.pressed.connect(ctrl.open_run_menu)
	ctrl._left_root.add_child(info)
	var total_rows := ctrl._graph.rows.size() if ctrl._graph != null else 0
	# S4-4: floor numbers match the side card (node.row, 1-based); before the first node it says Start, not "Floor 0".
	var cur_row := ctrl._current_row()
	info.set_info(tr("Floor %d of %d") % [cur_row, total_rows] if cur_row > 0 else tr("Start · %d floors") % total_rows,
		RunState.ascension, 0, RunState.shards_this_run)
	info.turn_chip.visible = false
	if AnchorAdapter.has_anchor():
		var ac := CorePanel.house_chip(true, UI3Theme.size_of("anchor_chip_h"))
		ac.name = "AnchorChip"
		ac.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.add_child(ac)

	var top := UI3.plate(&"plate")
	top.name = "PartyPlate"
	top.custom_minimum_size.x = ctrl._PLATE_LEFT_W
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = ctrl._SCREEN_MARGIN
	top.offset_top = ctrl._SCREEN_MARGIN + float(UI3Theme.size_of("run_pill_h")) + float(UI3Theme.space("12"))
	ctrl._left_root.add_child(top)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	top.add_child(col)

	for entry in RunState.roster:
		col.add_child(_build_party_row(entry))

	# BottomLeft: relics.
	var bottom := UI3.plate(&"plate")
	bottom.name = "CoresPlate"
	bottom.custom_minimum_size.x = ctrl._PLATE_LEFT_W
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_left = ctrl._SCREEN_MARGIN
	bottom.offset_bottom = -ctrl._SCREEN_MARGIN
	ctrl._left_root.add_child(bottom)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 8)
	bottom.add_child(rcol)
	# S3-10: count only the Cores in the Core slots (Anchor and Run rule are shown beside them, not in the count).
	var n_cores := RelicSlots.owned_cores(RunState.owned_relic_ids).size()
	var ct := UI3.label(tr("Cores · %d") % n_cores, "LabelTitle")
	ct.name = "CoresTitle"
	rcol.add_child(ct)
	var core_panel := CorePanel.new()
	core_panel.slot_px = 40
	core_panel.show_house_chip = false
	ctrl._core_panel = core_panel
	rcol.add_child(core_panel)
	core_panel.visible = core_panel.refresh()
	if RunState.run_rule != "":
		var rr = RelicRegistry.get_def(RunState.run_rule)
		if rr != null:
			var rl := UI3.label(tr("Run rule: %s") % String(rr.name), "LabelMuted")
			rl.name = "RunRuleChip"
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rcol.add_child(rl)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS   # polish 3/11 #14: the bar says there is more
	scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	list.name = "OwnedList"
	scroll.add_child(list)
	for relic_id in RunState.owned_relic_ids:
		list.add_child(_build_relic_row(relic_id))
	var list_h := float(RunState.owned_relic_ids.size()) * (ROW_H() + 8.0)
	scroll.custom_minimum_size.y = minf(list_h, 4.0 * (ROW_H() + 8.0))
	scroll.visible = not RunState.owned_relic_ids.is_empty()
	rcol.add_child(scroll)


func _build_party_row(entry: Dictionary) -> Control:
	var hero_key := String(entry.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var base_hp: int = int(entry.get("max_hp", 0))
	if base_hp <= 0:
		base_hp = int(hero_def.get("max_hp", 10))
	var max_hp: int = base_hp + int(entry.get("bonus_hp", 0))   # full rest between nodes

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var line := HBoxContainer.new()
	box.add_child(line)
	var name_lbl := UI3.label(String(hero_def.get("n", hero_key)))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	line.add_child(name_lbl)
	line.add_child(UI3.label("%d" % max_hp, "LabelTitle"))
	box.add_child(UI3.hp_bar(max_hp, max_hp, 0, 0, &"axie"))
	return box


## OwnedCore row (frame 03-run-map--cores-strip): tier socket + family emblem, name over headline, TierShards on the right.
## Run rule: stamp + name + "Run rule". Other relics: plain name + rarity word.
func _build_relic_row(relic_id: String) -> Control:
	var def = RelicRegistry.get_def(relic_id)
	var rarity := int(def.rarity) if def != null else 0
	var is_core: bool = def != null and RelicSlots.is_core(def)
	var is_rule: bool = is_core and String(def.core_axis) == "run_rule"
	var row := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), "OwnedCore")
	row.custom_minimum_size.y = ROW_H()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.add_child(h)
	if true:   # polish 3/11 #14: old relics / pacts get the same socket + headline as Cores
		var px := float(UI3Theme.size_of("slot_emblem")) + 8.0
		var tier := clampi(rarity, 0, 2) if not is_rule else -1
		var sk := TextureRect.new()
		sk.name = "RunRuleSlot" if is_rule else "CoreSlot"
		sk.texture = UI6Assets.slot(tier, px)
		sk.custom_minimum_size = Vector2.ONE * px
		sk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sk.stretch_mode = TextureRect.STRETCH_SCALE
		sk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var e := TextureRect.new()
		e.name = "RunRuleEmblem" if is_rule else "FamilyEmblem"
		e.texture = CoreVisuals.family_texture("run_rule" if is_rule else (String(def.core_axis) if is_core else "stat"), px * 0.6)
		e.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(px * 0.2))
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sk.add_child(e)
		h.add_child(sk)
	var tv := VBoxContainer.new()
	tv.name = "Texts"
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_theme_constant_override("separation", 0)
	h.add_child(tv)
	var nm := PanelParts.text("", "text_body", "text", true)
	nm.name = "CoreName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(nm)
	Ui5Ellipsis.set_text(nm, UI3.title_case(UI3.player_text(String(def.name) if def != null else relic_id)))
	if true:
		var hl := PanelParts.text("", "text_body", "core_headline")
		hl.name = "Headline"
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(hl)
		CoreHeadline.apply(hl, relic_id)
	if is_core and not is_rule:
		h.add_child(TierShards.new().setup(rarity, 28))
	else:
		var rl := UI3.label(tr("Run rule") if is_rule else ctrl._rarity_name(rarity), "LabelMuted")
		rl.add_theme_color_override("font_color", ctrl._rarity_color(rarity))
		rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(rl)
	return row


## Height of an OwnedCore row: socket + padding (name + headline stack).
static func ROW_H() -> float:
	return float(UI3Theme.size_of("btn_s")) + 12.0


func _node_info(node: RunMapNode) -> Dictionary:
	match node.node_type:
		"battle":
			return {"desc": tr("A fight against a squad of enemies."), "win": [tr("Choose 1 of 3 rewards")]}
		"elite":
			return {"desc": tr("A tougher fight against stronger enemies."), "win": [tr("Choose 1 of 3 rewards")]}
		"event":
			return {"desc": tr("Something happens on the road. You choose how it ends."), "win": [tr("Depends on your choice")]}
		"shop":
			return {"desc": tr("A merchant sells Cores for Shards."), "win": [tr("Spend your Shards")]}
		"treasure":
			return {"desc": tr("A sealed vault with a better than usual reward."), "win": [tr("Pick a reward")]}
		"boss":
			return {"desc": tr("The guardian of this stretch of the road."),
				"win": [tr("Clears the run") if ctrl._is_final_boss(node) else tr("Choose 1 of 3 rewards")]}
	return {"desc": "", "win": []}


func _rebuild_detail() -> void:
	for c in ctrl._detail_root.get_children():
		ctrl._detail_root.remove_child(c)
		c.queue_free()
	ctrl._travel_btn = null
	var node: RunMapNode = null
	if ctrl._graph != null and ctrl._selected_id != "":
		node = ctrl._graph.find_node(ctrl._selected_id)
	if node == null:
		return
	var reachable := ctrl._reachable_now_ids().has(node.id)

	var plate := UI3.plate(&"plate")
	plate.name = "DetailPlate"
	plate.custom_minimum_size.x = ctrl._PLATE_RIGHT_W
	plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	plate.offset_right = -ctrl._SCREEN_MARGIN
	plate.offset_top = ctrl._SCREEN_MARGIN
	ctrl._detail_root.add_child(plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	plate.add_child(col)

	var info := _node_info(node)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var icon := TextureRect.new()
	icon.texture = UI3.icon("node_%s" % node.node_type)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(icon)
	var title := UI3.label(ctrl._boss_name(node) if node.node_type == "boss" else ctrl._type_name(node.node_type), "LabelScreenTitle")
	title.name = "DetailTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # polish 3/11 #6: a long boss name wraps to a second line, never cut
	title.custom_minimum_size.x = 120
	head.add_child(title)

	var desc := UI3.label(String(info["desc"]))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 368
	col.add_child(desc)

	col.add_child(UI3.label(tr("If you win"), "LabelMuted"))
	for line in info["win"]:
		var row := UI3.plate(&"row")
		row.add_child(UI3.label(String(line)))
		col.add_child(row)

	if node.reward_kind != "":
		var rrow := UI3.plate(&"row")
		rrow.name = "RewardKindRow"
		var rh := HBoxContainer.new()
		rh.add_theme_constant_override("separation", 8)
		var ri := TextureRect.new()
		ri.texture = UI3.icon(String(ctrl._NODE_REWARD_ICON.get(node.reward_kind, "cur_shard")))
		ri.custom_minimum_size = Vector2(24, 24)
		ri.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ri.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rh.add_child(ri)
		rh.add_child(UI3.label(tr("Reward card: %s") % tr(String(ctrl._NODE_REWARD_NAME.get(node.reward_kind, "")))))
		rrow.add_child(rh)
		col.add_child(rrow)
	for aid in [node.affix, node.affix2]:
		if String(aid) == "":
			continue
		var arow := UI3.plate(&"row")
		arow.name = "AffixRow"
		var al := UI3.label("%s: %s" % [ctrl._affix_name(String(aid)), CombatView.affix_tip(String(aid))])
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		al.custom_minimum_size.x = 340
		arow.add_child(al)
		col.add_child(arow)

	var note: Label
	if node.visited or node.id == RunState.current_node_id:
		note = UI3.label(tr("Already passed"), "LabelMuted")
	elif reachable:
		note = UI3.label(tr("On your path"), "LabelMuted")
	else:
		note = UI3.label(tr("Not on your path"))
		note.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	note.name = "PathNote"
	col.add_child(note)
	if reachable and ctrl._graph != null and not ctrl._graph.boss_rows.is_empty():
		var boss_row := int(ctrl._graph.boss_rows[ctrl._graph.boss_rows.size() - 1])
		var path_note := UI3.label(tr("Floor %d of %d · %d floors to the boss") % [node.row, ctrl._graph.rows.size(), maxi(boss_row - node.row, 0)], "LabelMuted")
		path_note.name = "PathRoute"
		path_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		path_note.custom_minimum_size.x = 368
		col.add_child(path_note)

	var is_boss := node.node_type == "boss"
	ctrl._travel_btn = UI3.button(tr("Face the Boss") if is_boss else tr("Travel"), &"primary", &"L")
	ctrl._travel_btn.name = "TravelButton"
	if reachable:
		ctrl._travel_btn.pressed.connect(ctrl._on_node_pressed.bind(node.id))
	else:
		UI3.set_disabled_reason(ctrl._travel_btn, tr("Already passed") if (node.visited or node.id == RunState.current_node_id) else tr("Not on your path"))
	col.add_child(ctrl._travel_btn)
	if reachable:
		# Focus order: reachable nodes -> Travel -> relics.
		for id in ctrl._reachable_now_ids():
			var entry: Dictionary = ctrl._node_visuals.get(id, {})
			var b: Button = entry.get("root")
			if b != null:
				b.focus_neighbor_right = b.get_path_to(ctrl._travel_btn)
