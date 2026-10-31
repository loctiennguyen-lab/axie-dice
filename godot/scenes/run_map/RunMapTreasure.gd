class_name RunMapTreasure
extends RefCounted
## Treasure screen (build only; the node flow stays on the controller). Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

func _build_treasure(opened: bool) -> void:
	var host := ctrl._open_ui3_screen()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var col := VBoxContainer.new()
	col.name = "TreasureColumn"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	center.add_child(col)
	var chest := TextureRect.new()
	chest.name = "Chest"
	chest.texture = UI3.icon("node_treasure")
	# Opened: 192 so the fixed UI-05 reward cards (reward_card_h) + Take still fit inside the 24 px screen margin.
	chest.custom_minimum_size = Vector2(0, 192 if opened else 384)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(chest)
	var hrow := HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", 24)
	col.add_child(hrow)
	hrow.add_child(UI3.label(tr("A sealed Gene vault") if not opened else tr("Choose one"), "LabelScreenTitle"))
	hrow.add_child(UI3.currency_pill([{"icon": "cur_shard", "value": str(RunState.shards_this_run)}]))

	if not opened:
		var open := UI3.button(tr("Open chest"), &"primary", &"L")
		open.name = "OpenChest"
		open.pressed.connect(func() -> void: _build_treasure(true))
		var oc := HBoxContainer.new()
		oc.alignment = BoxContainer.ALIGNMENT_CENTER
		oc.add_child(open)
		col.add_child(oc)
		open.grab_focus.call_deferred()
		return

	if RunState.pending_rewards.is_empty():
		col.add_child(UI3.label(tr("The vault was empty.")))
		var cont := UI3.button(tr("Continue"), &"primary", &"L")
		cont.name = "TakeButton"
		cont.pressed.connect(func() -> void: ctrl._finish_node())
		col.add_child(cont)
		cont.grab_focus.call_deferred()
		return
	ctrl._overlay_vbox = HBoxContainer.new()
	ctrl._overlay_vbox.name = "TreasureCards"
	ctrl._overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl._overlay_vbox.add_theme_constant_override("separation", 32)
	ctrl._overlay_vbox.sort_children.connect(ctrl._lift_selected_card)   # same UI-05 RewardCard as the reward pick
	col.add_child(ctrl._overlay_vbox)
	ctrl._reward_cards.clear()
	ctrl._reward_sel = -1
	for reward in RunState.pending_rewards:
		ctrl._add_reward_card(reward)
	var take := UI3.button(tr("Take and continue"), &"primary", &"L")
	take.name = "TakeButton"
	take.pressed.connect(ctrl._take_selected_reward)
	var tc := HBoxContainer.new()
	tc.alignment = BoxContainer.ALIGNMENT_CENTER
	tc.add_child(take)
	col.add_child(tc)
	ctrl._select_reward(-1)
	ctrl._reward_cards[0].grab_focus.call_deferred()
