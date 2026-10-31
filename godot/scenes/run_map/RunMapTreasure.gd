class_name RunMapTreasure
extends RefCounted
## Treasure screen (build only; the node flow stays on the controller). Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

const _PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## UI-05 frames 13-treasure--closed / --opened (design round-2). Closed: `Treasure` = Chest (chest, 384), Title +
## ShardPill, OpenButton (Space). Opened: `TreasureReward` = one column from d_reward_top (the same as the reward pick):
## Title + ShardPill, CardRow of RewardCards, Footer with TakeButton (off and saying "Pick a reward" until a card is
## picked; nothing is preselected, that rule is R2a's and lives in RunMapOffers).
func _build_treasure(opened: bool, animate := false) -> void:
	UI3Theme.sync_scale()   # the 1280 text floor follows the window
	var host := ctrl._open_ui3_screen()
	var col := VBoxContainer.new()
	col.name = "TreasureReward" if opened else "Treasure"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", UI3Theme.space("32" if opened else "24"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if opened:
		col.offset_top = UI3Theme.size_of("d_reward_top")
	else:
		col.alignment = BoxContainer.ALIGNMENT_CENTER
	host.add_child(col)

	if not opened:
		var cp := UI3Theme.size_of("chest")
		var chest := TextureRect.new()
		chest.name = "Chest"
		chest.texture = UI3.icon("node_treasure")   # no 3D chest yet (design: Art requests)
		chest.custom_minimum_size = Vector2(cp, cp)
		chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(chest)
	var hrow := HBoxContainer.new()
	hrow.name = "Header"
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", UI3Theme.space("20"))
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(hrow)
	var title := _PanelParts.on_view(_PanelParts.text(tr("A sealed Gene vault") if not opened else tr("Choose one"), "text_banner", "text", true))
	title.name = "Title"
	hrow.add_child(title)
	hrow.add_child(Ui5RunScreenParts.shard_pill(RunState.shards_this_run))

	if not opened:
		var open := UI3.button(tr("Open chest"), &"primary", &"L")
		open.name = "OpenButton"
		open.pressed.connect(_build_treasure.bind(true, true))
		var oc := HBoxContainer.new()
		oc.name = "Footer"
		oc.alignment = BoxContainer.ALIGNMENT_CENTER
		oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		oc.add_child(open)
		col.add_child(oc)
		Ui5RunScreenParts.set_space_cap(open, true)
		open.grab_focus.call_deferred()
		return

	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if RunState.pending_rewards.is_empty():
		col.add_child(_PanelParts.on_view(UI3.label(tr("The vault was empty."))))
		var cont := UI3.button(tr("Continue"), &"primary", &"L")
		cont.name = "TakeButton"
		cont.pressed.connect(ctrl._finish_node)
		foot.add_child(cont)
		col.add_child(foot)
		Ui5RunScreenParts.set_space_cap(cont, true)
		cont.grab_focus.call_deferred()
		return
	ctrl._overlay_vbox = HBoxContainer.new()
	ctrl._overlay_vbox.name = "CardRow"
	ctrl._overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl._overlay_vbox.add_theme_constant_override("separation", UI3Theme.space("32"))
	ctrl._overlay_vbox.custom_minimum_size.y = UI3Theme.size_of("reward_card_h")   # fixed band: Take never moves
	ctrl._overlay_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl._overlay_vbox.sort_children.connect(ctrl._lift_selected_card)   # same UI-05 RewardCard as the reward pick
	col.add_child(ctrl._overlay_vbox)
	ctrl._reward_cards.clear()
	ctrl._reward_sel = -1
	for reward in RunState.pending_rewards:
		ctrl._add_reward_card(reward)
	col.add_child(foot)
	var take := UI3.button(tr("Take and continue"), &"primary", &"L")
	take.name = "TakeButton"
	take.custom_minimum_size.x = UI3Theme.size_of("d_take_min_w")
	take.set_meta("treasure", true)   # RunMapOffers._refresh_take words the reason "Pick a reward"
	take.pressed.connect(ctrl._take_selected_reward)
	foot.add_child(take)
	ctrl._select_reward(-1)
	ctrl._reward_cards[0].grab_focus.call_deferred()
	if animate and not UI3Gacha.is_instant():
		# UI-05 b23 lane M2: `treasure-open`. The vault / flash / rays nodes do not exist (no 3D chest yet): those rows are data.
		var tg := {"choose": col.find_child("Title", true, false)}
		for k in ctrl._reward_cards.size():
			tg["card%d" % (k + 1)] = ctrl._reward_cards[k]
		UI3Motion.play_timeline("treasure-open", tg, {"host": ctrl, "only": ["card_1", "card_2", "card_3", "choose"]})
