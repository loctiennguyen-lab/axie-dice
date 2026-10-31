class_name RunMapOffers
extends RefCounted
## Reward / Core / Rule / treasure offers (one path), Anchor overlay, awaken beat. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.

const _ConfirmBarUi := preload("res://scenes/shared/ui5/ConfirmBar.gd")
const _PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const _RewardCardUi := preload("res://scenes/shared/ui5/RewardCard.gd")
const _CoreCardUi := preload("res://scenes/run_map/ui5/CoreCard.gd")

var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

## Shown once, right after a won combat, before the player can interact with the map at all
## (RunState.pending_rewards was populated by apply_combat_result() before CombatView even
## changed scene to this one). If pending_rewards is somehow empty on arrival (e.g. an empty
## roster edge case - RewardGenerator's own "hp" fallback fill can only return {} then), the
## map still has to advance exactly once: after_node() is now ONLY ever called from
## _on_reward_chosen(), so nothing else would ever call it for this node.
func _maybe_show_pending_reward() -> void:
	var afx := _play_awaken()   # awakened by something other than a Core pick: plays on this map beat
	if afx != null:
		if afx.running:
			afx.finished.connect(_maybe_show_pending_reward, CONNECT_ONE_SHOT)
			return
	if RunState.phase == RunState.RunPhase.PACT:
		ctrl._show_pact_overlay()
		return
	if RunState.pending_rewards.is_empty() and AnchorAdapter.offer_open():
		_show_anchor_overlay()
		return
	if RunState.pending_rewards.is_empty():
		if RunState.phase == RunState.RunPhase.REWARD:
			RunState.after_node()
			ctrl._refresh(true)
		return
	_show_reward_overlay("CHOOSE ONE REWARD")


## Anchor pick (design/ux/anchor-mvp.md 1): same overlay host as the Core pick, before the first Core offer.
## After the pick the engine opens pick 1 into pending_rewards, so the normal reward overlay follows.
func _show_anchor_overlay() -> void:
	var host := ctrl._open_ui3_screen()
	var view := AnchorPick.new()
	view.name = "AnchorPick"
	host.add_child(view)
	view.setup(AnchorAdapter.offer(), UI3Gacha.first_seen(str(RunState.get("_core_base_seed")), 3))
	view.picked.connect(func(_id: String) -> void:
		ctrl._save_map_progress()
		_maybe_show_pending_reward())


## The eyebrow above the reward title. The mockup reads "WAVE 3 CLEARED"; this build resolves a
## reward per NODE and has no wave concept (ContentDB.gd says so in as many words), so the node
## the player just finished is what the pill names.
func _cleared_eyebrow() -> String:
	if ctrl._graph == null or RunState.current_node_id == "":
		return "NODE CLEARED"
	var node := ctrl._graph.find_node(RunState.current_node_id)
	if node == null:
		return "NODE CLEARED"
	var kind := "MERCHANT" if node.node_type == "shop" else node.node_type.to_upper()
	return "%s CLEARED" % kind


## Reward pick, UI-05 31-reward (design/handoffs/ui-05-figma/round-1/ui05-combat-panels.html, README "Reward pick"):
## `.reward-screen` = one column from d_reward_top, gap 32: head (Title + ShardChip), CardRow (fixed-size cards, gap 32),
## Footer (Reroll · n left, Take). There is no Skip: choosing stays mandatory (owner decision 21/9,
## RunState.after_node() is only reached by a pick). Focus: cards left -> right -> Reroll -> Take.
## The `title` argument is kept for the reroll callback; the words come from the offer kind (sentence case).
func _show_reward_overlay(title: String, _backdrop: Texture2D = null) -> void:
	UI3Theme.sync_scale()   # the 1280 text floor follows the window
	var host := ctrl._open_ui3_screen()
	var col := VBoxContainer.new()
	var core_mode := ctrl._core_offer_active()
	for rr1 in RunState.pending_rewards:
		if bool((rr1 as Dictionary).get("rule", false)):
			core_mode = false   # the Run rule pick keeps the reward layout (R2b)
	col.name = "CoreOffer" if core_mode else "RewardPick"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = UI3Theme.size_of("offer_top" if core_mode else "d_reward_top")
	col.add_theme_constant_override("separation", UI3Theme.space("32"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(col)

	var head := HBoxContainer.new()
	head.name = "Header"
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", UI3Theme.space("20"))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	if ctrl._core_offer_active():
		ctrl._dm("dm_core_open")
	var core_rule := false
	for rr0 in RunState.pending_rewards:
		core_rule = core_rule or bool((rr0 as Dictionary).get("rule", false))
	var title_text := "Choose one reward"
	if ctrl._core_offer_active():
		title_text = "Choose a run rule" if core_rule else "Choose a Core"
	var title_lbl := _PanelParts.on_view(_PanelParts.text(tr(title_text), "text_banner", "text", true))
	title_lbl.name = "Title"
	head.add_child(title_lbl)
	if ctrl._core_offer_active() and not core_rule:
		# TierLadder: Moss / Amber / Crystal; the tooltip says what the tier words mean (S3-9).
		var ladder := HBoxContainer.new()
		ladder.name = "TierLadder"
		ladder.add_theme_constant_override("separation", UI3Theme.space("8"))
		ladder.mouse_filter = Control.MOUSE_FILTER_STOP
		ladder.add_child(_PanelParts.on_view(_PanelParts.text(tr("Core tier:"))))
		for lt in 3:
			if lt > 0:
				ladder.add_child(_PanelParts.on_view(_PanelParts.text("\u2192", "text_body", "text", false)))
			ladder.add_child(_CoreCardUi.tier_chip(lt, tr(ctrl._CORE_TIER_NAME[lt])))
		ladder.add_child(_PanelParts.on_view(_PanelParts.text(tr("(strongest)"))))
		UI3Tooltip.bind(ladder, tr(ctrl.CORE_TIER_HINT))
		head.add_child(ladder)
	# Gacha pack: the NEXT pick's tier is never shown anywhere (Liam 22/10).
	head.add_child(_shard_chip(RunState.shards_this_run))

	ctrl._overlay_vbox = HBoxContainer.new()
	ctrl._overlay_vbox.name = "CardRow"
	ctrl._overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl._overlay_vbox.add_theme_constant_override("separation", UI3Theme.space("32"))
	# Fixed card band (cards are reward_card_h): Take never moves between states (GU 3).
	ctrl._overlay_vbox.custom_minimum_size.y = UI3Theme.size_of("core_card_h" if core_mode else "reward_card_h")
	ctrl._overlay_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl._overlay_vbox.sort_children.connect(_lift_selected_card)
	col.add_child(ctrl._overlay_vbox)

	ctrl._reward_cards.clear()
	ctrl._reward_sel = -1   # UI-05: nothing is chosen until the player picks (Take stays off)
	for reward in RunState.pending_rewards:
		_add_reward_card(reward)

	_start_core_reveal(col)

	var actions := HBoxContainer.new()
	actions.name = "Footer"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", UI3Theme.space("24"))
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(actions)
	var left := RunState.reward_reroll_charges
	if ctrl._core_offer_active() and RunState.get("core_reroll_left") != null:
		left = int(RunState.get("core_reroll_left"))   # lane B: Core rerolls are per run (2), not per node
	var reroll: Button = null
	if ctrl._core_offer_active():
		# Core offer: each card has its own Reroll button; here only the shared counter.
		if not core_rule:
			var lc := _PanelParts.on_view(_PanelParts.text((tr("%d reroll left") if left == 1 else tr("%d rerolls left")) % left,
				"text_title", "text", true))
			lc.name = "RerollCounter"
			actions.add_child(lc)
	else:
		reroll = _PanelParts.button((tr("Reroll · %d left")) % left, &"secondary", &"M")
		reroll.name = "RerollButton"
		reroll.icon = UI3.icon("ui_reroll")
		reroll.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_m"))
		reroll.add_theme_constant_override("h_separation", UI3Theme.space("12"))
		reroll.visible = not core_rule   # no reroll for the Run rule pick (2b.1)
		if left > 0:
			reroll.pressed.connect(_on_reward_reroll.bind(title))
		else:
			UI3.set_disabled_reason(reroll, tr("Reroll · 0 left"))
		actions.add_child(reroll)
	if ctrl._REWARD_ALLOW_SKIP:
		var skip := UI3.button(tr("Skip"), &"secondary", &"M")
		skip.name = "SkipButton"
		skip.pressed.connect(_ask_skip_reward.bind(col))
		actions.add_child(skip)
	var take := UI3.button(tr("Take"), &"primary", &"L")
	take.name = "TakeButton"
	take.custom_minimum_size.x = UI3Theme.size_of("d_take_min_w")
	take.pressed.connect(_take_selected_reward)
	actions.add_child(take)

	# Focus chain: cards left -> right, then Reroll, then Take (design godot comment).
	var chain: Array[Control] = []
	for c in ctrl._reward_cards:
		chain.append(c)
	if reroll != null and reroll.visible:
		chain.append(reroll)
	chain.append(take)
	for k in chain.size():
		var nxt: Control = chain[(k + 1) % chain.size()]
		var prv: Control = chain[(k - 1 + chain.size()) % chain.size()]
		chain[k].focus_next = chain[k].get_path_to(nxt)
		chain[k].focus_previous = chain[k].get_path_to(prv)

	_select_reward(-1)
	_sync_face_down(col, host)
	if not ctrl._reward_cards.is_empty():
		var first_card: Control = ctrl._reward_cards[0]
		if ctrl._reveal != null and is_instance_valid(ctrl._reveal) and ctrl._reveal.running:
			# Face-down cards carry no focus ring (the design has none); card 0 gets focus once they are turned.
			ctrl._reveal.finished.connect(func() -> void:
				if is_instance_valid(first_card) and first_card.is_inside_tree():
					first_card.grab_focus(), CONNECT_ONE_SHOT)
		else:
			first_card.grab_focus.call_deferred()
	else:
		take.grab_focus.call_deferred()


## `.plate.chip` (ShardChip): btn_m high pill on the plate, shard icon + Rowdies 24 count.
func _shard_chip(n: int) -> PanelContainer:
	var pad := UI3Theme.space("16")
	var box := _PanelParts.plate_box("pill")
	box.content_margin_left = pad
	box.content_margin_right = pad
	var chip := _PanelParts.panel(box, "ShardChip")
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


## Inline confirm row under the actions: "Skip this reward? You keep the N Shards." Back / Skip.
func _ask_skip_reward(col: VBoxContainer) -> void:
	var old := col.find_child("SkipConfirm", true, false)
	if old != null:
		return
	var row := HBoxContainer.new()
	row.name = "SkipConfirm"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(UI3.label(tr("Skip this reward? You keep the %d Shards.") % RunState.shards_this_run))
	var back := UI3.button(tr("Back"), &"secondary", &"S")
	back.pressed.connect(row.queue_free)
	row.add_child(back)
	var go := UI3.button(tr("Skip"), &"secondary", &"S")
	go.pressed.connect(func() -> void:
		RunState.pending_rewards.clear()
		ctrl._finish_node())
	row.add_child(go)
	col.add_child(row)
	back.grab_focus()


func _select_reward(i: int) -> void:
	ctrl._reward_sel = -1 if i < 0 or ctrl._reward_cards.is_empty() else clampi(i, 0, ctrl._reward_cards.size() - 1)
	for k in ctrl._reward_cards.size():
		if is_instance_valid(ctrl._reward_cards[k]) and ctrl._reward_cards[k].has_method("set_selected"):   # rebuilt on reroll / chained offers
			ctrl._reward_cards[k].call("set_selected", k == ctrl._reward_sel)
	if ctrl._overlay_vbox != null and is_instance_valid(ctrl._overlay_vbox):
		ctrl._overlay_vbox.queue_sort()
	_refresh_take()


## Take is off until a card is picked (and, on a face-down Core offer, until the cards are revealed) and says why;
## the label and the Space keycap come back when it is on. Chosen cards are never logged.
func _refresh_take() -> void:
	if ctrl._overlay_root == null or not is_instance_valid(ctrl._overlay_root):
		return
	var tb := ctrl._overlay_root.find_child("TakeButton", true, false) as Button
	if tb == null or ctrl._reward_cards.is_empty():
		return
	var face_down: bool = ctrl._reveal != null and is_instance_valid(ctrl._reveal) and ctrl._reveal.running
	if face_down or ctrl._reward_sel < 0:
		var why := "Reveal the cards first"
		if not face_down:
			why = "Pick a card"
			var r0: Dictionary = RunState.pending_rewards[0] if RunState.pending_rewards.size() > 0 else {}
			if bool(tb.get_meta("treasure", false)):
				why = "Pick a reward"
			elif bool(r0.get("rule", false)):
				why = "Pick a rule"
			elif ctrl._is_core_card(r0):
				why = "Pick a Core"
		_set_take_cap(tb, false)
		if tb.has_meta("ui3_label"):
			tb.text = tr(why)
		else:
			UI3.set_disabled_reason(tb, tr(why))
	else:
		if tb.disabled and tb.has_meta("ui3_label"):
			UI3.clear_disabled_reason(tb)
		_set_take_cap(tb, true)


## Space keycap after the Take caption (only while Take is on). Placed by HudStyle once the button is in the tree.
func _set_take_cap(tb: Button, on: bool) -> void:
	var cap := tb.get_node_or_null("KeyCap") as PanelContainer
	var pad := int(tb.get_theme_stylebox("normal").content_margin_left)
	if not on:
		if cap != null:
			tb.remove_child(cap)
			cap.queue_free()
			Ui5HudStyle.reserve_trailing(tb, null, pad)
		return
	if cap == null:
		cap = Ui5Keycap.make(KeyBindings.text(KeyBindings.COMBAT_END_TURN), &"primary")
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tb.add_child(cap)
		if not tb.has_meta("cap_wired"):
			tb.set_meta("cap_wired", true)   # one resized hook per button, however often the cap is re-added
			tb.resized.connect(func() -> void:
				var c := tb.get_node_or_null("KeyCap") as Control
				if c != null:
					Ui5HudStyle.place_trailing(tb, c, pad))
	Ui5HudStyle.place_trailing.call_deferred(tb, cap, pad)


## Face-down Core offer: Take reads "Reveal the cards first", the rerolls counter is hidden and "Click or Space to skip"
## shows, all until the reveal is over.
func _sync_face_down(col: Control, host: Control) -> void:
	_refresh_take()
	if ctrl._reveal == null or not is_instance_valid(ctrl._reveal) or not ctrl._reveal.running:
		return
	var counter := col.find_child("RerollCounter", true, false) as Control
	if counter != null:
		counter.visible = false
	var hint := Ui5SkipHint.new()
	host.add_child(hint)
	hint.place_in.call_deferred(ctrl._overlay_root.get_viewport_rect().size)
	ctrl._reveal.finished.connect(func() -> void:
		if is_instance_valid(hint):
			hint.queue_free()
		if is_instance_valid(counter):
			counter.visible = true
		_refresh_take(), CONNECT_ONE_SHOT)


## The selected card sits 12 px above the row (design `.reward-card.is-selected{margin-top:-12px}`). Runs after
## every sort of the CardRow, so the lift survives layout passes.
func _lift_selected_card() -> void:
	for c in ctrl._reward_cards:
		if is_instance_valid(c) and c.has_method("lift_px") and c.get_parent() == ctrl._overlay_vbox:
			c.position.y -= float(c.call("lift_px"))


func _take_selected_reward() -> void:
	if ctrl._taking or ctrl._reward_sel < 0:
		return   # nothing picked: Space / Enter / Take do nothing (and the reveal is not skipped)
	if ctrl._reveal != null and is_instance_valid(ctrl._reveal):
		ctrl._reveal.skip()
	if ctrl._reward_sel < RunState.pending_rewards.size():
		var r: Dictionary = RunState.pending_rewards[ctrl._reward_sel]
		if String(r.get("t", "")) in ["chaos", "curse"]:
			_ask_lasting_reward(r)
			return
		if ctrl._is_core_card(r):
			ctrl._dm("dm_core_pick")
		ctrl._on_reward_chosen(r)


## Chaos / Curse last the whole run (31-reward--chaos-confirm): the ConfirmBar replaces the Footer, Back has focus and
## "Take it" is the one primary. Back (or Esc) puts the Footer back and focus on the picked card.
func _ask_lasting_reward(r: Dictionary) -> void:
	var col := ctrl._overlay_vbox.get_parent() as Control if ctrl._overlay_vbox != null else null
	if col == null or col.find_child("ConfirmBar", true, false) != null:
		return
	var foot := col.get_node_or_null("Footer") as Control
	var bar := _ConfirmBarUi.new()
	bar.setup(tr("This lasts the whole run. Take it?"), tr("Back"), tr("Take it"))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if foot != null:
		foot.visible = false
	col.add_child(bar)
	var close := func() -> void:
		if is_instance_valid(bar) and bar.get_parent() == col:
			col.remove_child(bar)
			bar.queue_free()
		if foot != null and is_instance_valid(foot):
			foot.visible = true
	bar.back_pressed.connect(func() -> void:
		close.call()
		if ctrl._reward_sel < ctrl._reward_cards.size() and is_instance_valid(ctrl._reward_cards[ctrl._reward_sel]):
			ctrl._reward_cards[ctrl._reward_sel].grab_focus())
	# Take it: the bar goes (the pick is answered); a full Core slot can still open the swap sheet, and "Leave it" there
	# must find a working Footer, not a dead bar. `_taking` guards a second take while the take beat plays.
	bar.confirmed.connect(func() -> void:
		close.call()
		ctrl._on_reward_chosen(r))


## Chaos / Curse card body split into Gain and Gamble/Curse text, from the generator's real strings.
func _trade_parts(r: Dictionary) -> Dictionary:
	var sub := String(r.get("sub", ""))
	var desc := String(r.get("desc", ""))
	if String(r.get("t", "")) == "chaos":
		var lines := sub.split("\n")
		var cost := String(lines[0]).trim_prefix("GAMBLE: ")
		cost = cost.substr(0, 1).to_upper() + cost.substr(1)
		cost = cost.substr(0, 1).to_upper() + cost.substr(1)
		var gain := UI3.describe(String(lines[1]) if lines.size() > 1 else "")
		return {"gain": ("MP %d · " % int(gain["mp"]) if int(gain["mp"]) >= 0 else "") + String(gain["text"]),
			"cost": cost, "cost_kind": &"gamble"}
	return {"gain": sub.trim_prefix("IN EXCHANGE: you gain ").trim_suffix("."), "cost": desc, "cost_kind": &"curse"}


func _prism_hover(card: Control, on: bool) -> void:
	if ctrl._reveal != null and is_instance_valid(ctrl._reveal) and ctrl._reveal.running:
		return
	card.pivot_offset = card.size / 2.0
	ctrl.create_tween().tween_property(card, "scale", Vector2.ONE * (1.04 if on else 1.0), UI3Theme.motion_sec("fast"))


func _start_core_reveal(shake_host: Control) -> void:
	if ctrl._reveal != null and is_instance_valid(ctrl._reveal):
		ctrl._reveal.queue_free()
	ctrl._reveal = null
	if not ctrl._core_offer_active() or ctrl._reward_cards.is_empty():
		return
	var first_r: Dictionary = RunState.pending_rewards[0]
	if bool(first_r.get("rule", false)):
		ctrl._reroll_slot = -1
		return
	if ctrl._reroll_slot >= 0 and ctrl._reroll_slot < ctrl._reward_cards.size():
		var slot := ctrl._reroll_slot
		ctrl._reroll_slot = -1
		var rw: Dictionary = RunState.pending_rewards[slot]
		var rt := clampi(int(rw.get("tier", 0)), 0, 2)
		ctrl._reward_cards[slot].set_meta("gacha_tier", rt)
		ctrl.gacha_log.append("reroll_in:%d" % slot)
		ctrl._reveal = GachaReveal.new()
		ctrl._reveal.name = "GachaReveal"
		ctrl._overlay_root.add_child(ctrl._reveal)
		var jp := rt >= 2 and not UI3Gacha.combo_completes(UI3Gacha.owned_ids(), String(rw.get("key", ""))).is_empty()
		ctrl._reward_cards[slot].set_meta("jackpot_card", jp)
		ctrl._reveal.start([ctrl._reward_cards[slot]], rt, UI3Gacha.first_seen(str(RunState.get("_core_base_seed")), rt), jp, shake_host,
			float(UI3Gacha.timing().get("reroll_in_sec", 0.5)))
		for cv in ctrl._reveal._covers:
			(cv as Node).name = "CoreCardBack"
		_reroll_note(ctrl._reward_cards[slot])
		return
	var tier := 0
	for k in ctrl._reward_cards.size():
		var ct := clampi(int((RunState.pending_rewards[k] as Dictionary).get("tier", 0)), 0, 2)
		ctrl._reward_cards[k].set_meta("gacha_tier", ct)
		tier = maxi(tier, ct)
	var from_t := UI3Gacha.capped_from(tier)
	if from_t > tier:
		ctrl.gacha_log.append("near_miss:%d>%d" % [from_t, tier])
		for cc in ctrl._reward_cards:   # CapStrip on the one card the Crystal cap pulled down
			if cc.has_method("add_cap_strip") and int(cc.get("tier")) == tier:
				cc.call("add_cap_strip", tr("Crystal cap reached \u2014 max %d Crystal Cores this run") % CoreOffer.t_cap(String(RunState.get("mode"))))
				break
	var first := UI3Gacha.first_seen(str(RunState.get("_core_base_seed")), from_t if from_t > tier else tier)
	ctrl._reveal = GachaReveal.new()
	ctrl._reveal.name = "GachaReveal"
	ctrl._overlay_root.add_child(ctrl._reveal)
	var jackpot := false
	if tier >= 2:
		for k in RunState.pending_rewards.size():
			var rw: Dictionary = RunState.pending_rewards[k]
			var hit := int(rw.get("tier", 0)) >= 2 and not UI3Gacha.combo_completes(UI3Gacha.owned_ids(), String(rw.get("key", ""))).is_empty()
			ctrl._reward_cards[k].set_meta("jackpot_card", hit)
			jackpot = jackpot or hit
	ctrl._reveal.start(ctrl._reward_cards, tier, first, jackpot, shake_host, -1.0, from_t)
	for cv in ctrl._reveal._covers:
		(cv as Node).name = "CoreCardBack"


## One UI-05 RewardCard (31-reward): Category + RarityChip, RewardArt (rarity edge), RewardName, then the body:
## RewardBody text, or GainBox + GambleBox / CurseBox (always in that order) for Chaos / Curse. A Core shows its tier
## (Moss / Amber / Crystal) in the RarityChip, the axis / partner / house chips, and its own Reroll at the bottom.
## Real strings come from the offer (RewardGenerator / CoreOffer), never from the mockup samples.
func _add_reward_card(r: Dictionary, _wide := false) -> PanelContainer:
	var t := String(r.get("t", ""))
	var rar := ctrl._reward_rarity(r)
	var is_core := ctrl._is_core_card(r)
	var is_rule := is_core and bool(r.get("rule", false))
	var accent := ctrl._rarity_color(rar)
	var rar_word := ctrl._rarity_name(rar)
	var tier := clampi(int(r.get("tier", 0)), 0, 2)
	if is_core and not is_rule:
		accent = UI3Theme.color(ctrl._CORE_TIER_TOKEN[tier])
		rar_word = tr(ctrl._CORE_TIER_NAME[tier])
	var idx := ctrl._reward_cards.size()
	if is_core and not is_rule:
		return _add_core_card(r)
	var kind_text := String(ctrl._REWARD_KIND.get(t, "Reward"))
	if is_core:
		kind_text = "Run rule" if is_rule else "Core"
	var icon_tex := UI3.icon(String(ctrl._REWARD_ICON.get(t, "ui_mooncard")))
	if is_core:
		icon_tex = UI3.icon(String(CorePanel.AXIS_ICON.get(String(r.get("axis", "")), "face_buff")))

	# A relic offer arrives as title "RELIC", desc = relic name, sub = effect text.
	var name_text := String(r.get("title", ""))
	var body_text := String(r.get("desc", ""))
	if t == "relic" and String(r.get("sub", "")) != "":
		name_text = String(r.get("desc", ""))
		body_text = String(r.get("sub", ""))
	elif String(r.get("sub", "")) != "":
		body_text += "\n" + String(r.get("sub", ""))
	if t == "chaos":
		name_text = String(r.get("desc", ""))
	name_text = UI3.title_case(UI3.player_text(name_text))
	if String(r.get("key", "")) == "rule_none":
		body_text = tr("Play this run with the base rules.")
	var dsc := UI3.describe(body_text)
	body_text = ("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"])

	var card := _RewardCardUi.new()
	card.name = "RewardCard%d" % idx
	card.setup(tr(kind_text), rar_word, accent, icon_tex, name_text)
	var col: VBoxContainer = card.column
	if is_rule:
		card.rarity_chip.visible = false   # a Run rule has no rarity or tier
	if is_core and not is_rule:
		card.rarity_chip.mouse_filter = Control.MOUSE_FILTER_STOP
		UI3Tooltip.bind(card.rarity_chip, tr(ctrl.CORE_TIER_HINT))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_reward(idx)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_reward(idx)
			var tb := ctrl._overlay_root.find_child("TakeButton", true, false) as Control
			if tb != null and tb.is_visible_in_tree():
				tb.grab_focus())
	ctrl._overlay_vbox.add_child(card)
	ctrl._reward_cards.append(card)
	if is_core:
		card.mouse_entered.connect(_dm_core_hover)
		card.focus_entered.connect(_dm_core_hover)
	var crystal := is_core and not is_rule and tier >= 2
	if crystal:
		# A3: Crystal cards keep their own bevelled silhouette and extra rings, and rise on hover.
		card.set_meta("prism_accent", accent)
		card.use_prism(func(sel: bool) -> StyleBoxFlat: return UI3Gacha.prism_style(accent, sel))
		card.add_child(UI3Gacha.prism_frame(accent))
		card.mouse_entered.connect(_prism_hover.bind(card, true))
		card.mouse_exited.connect(_prism_hover.bind(card, false))
	if is_rule and String(r.get("key", "")) != "rule_none":
		card.art_icon.modulate = ctrl.rule_tint(String(r.get("key", "")))

	if is_core and not is_rule:
		# Axis chip (glyph + word), partner / combo labels and the house chip. The tier word is the RarityChip.
		var chips := HFlowContainer.new()
		chips.name = "CoreChips"
		chips.add_theme_constant_override("h_separation", UI3Theme.space("8"))
		chips.add_theme_constant_override("v_separation", UI3Theme.space("8"))
		chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var axis := String(r.get("axis", ""))
		chips.add_child(CorePanel.word_chip(tr(String(CorePanel.AXIS_NAME.get(axis, "Core"))),
			String(CorePanel.AXIS_ICON.get(axis, "face_buff")), UI3Theme.color("text_muted"), "AxisChip"))
		_add_combo_labels(col, String(r.get("key", "")), chips)
		RunMapController._add_house_chip(card, chips, String(r.get("key", "")))
		col.add_child(chips)
	if t in ["chaos", "curse"]:
		var tp := _trade_parts(r)
		col.add_child(_RewardCardUi.trade_box(&"gain", String(tp["gain"])))
		col.add_child(_RewardCardUi.trade_box(tp["cost_kind"], String(tp["cost"])))
		return card
	var body_w := UI3Theme.size_of("reward_card_w") - 2 * UI3Theme.space("20")
	var desc := _PanelParts.text(body_text)
	desc.name = "RewardBody"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = body_w
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(desc)
	if is_rule and ctrl._RULE_PRICE.has(String(r.get("key", ""))):
		var pb := VBoxContainer.new()
		pb.name = "RulePrice"
		pb.add_child(_PanelParts.text(tr("Price"), "text_body", "text_muted"))
		var pl := _PanelParts.text("− " + tr(String(ctrl._RULE_PRICE[String(r.get("key", ""))])), "text_body", "anchor_price", true)
		pl.name = "PriceText"
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.custom_minimum_size.x = body_w
		pb.add_child(pl)
		col.add_child(pb)
	if is_core and not is_rule:
		var rr := _PanelParts.button(tr("Reroll"), &"secondary", &"M")
		rr.name = "CardReroll%d" % idx
		rr.size_flags_vertical = Control.SIZE_SHRINK_END
		if RunState.core_can_reroll(idx):
			rr.pressed.connect(_on_core_card_reroll.bind(idx))
		else:
			UI3.set_disabled_reason(rr, tr("Rerolled") if RunState.core_rerolled_slots.has(idx) else tr("No rerolls left"))
		col.add_child(rr)
	return card


func _add_combo_labels(col: VBoxContainer, key: String, chips: HFlowContainer) -> void:
	var owned := UI3Gacha.owned_ids()
	var done := UI3Gacha.combo_completes(owned, key)
	if not done.is_empty():
		var full := String(done["tier"]) == "full"
		var row := HBoxContainer.new()
		row.name = "ComboTag"
		row.add_theme_constant_override("separation", 8)
		var plate := UI3.combo_tier_tag(full)
		row.add_child(plate)
		var nm := UI3.label(UI3Gacha.combo_name(String(done["id"])), "LabelMuted")
		nm.name = "ComboName"
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(nm)
		col.add_child(row)
	var names: Array[String] = []
	for id in UI3Gacha.combo_matches(owned, key):
		var d = RelicRegistry.get_def(String(id))
		if d != null:
			names.append(UI3.title_case(UI3.player_text(String(d.name))))
	if not names.is_empty():
		var chip := UI3.icon_chip(tr("With: %s") % ", ".join(names), UI3.icon("ui_mooncard"), UI3Theme.color("accent"), "WorksWith")
		chips.add_child(chip)


## Plays the awaken moment when one is pending and this run has not seen it yet. null = nothing to play.
func _play_awaken(extra_line := "") -> AnchorFx:
	if ctrl._overlay_layer == null or not AnchorFx.take_pending():
		return null
	var rect := Rect2()
	if is_instance_valid(ctrl._core_panel) and ctrl._core_panel.is_inside_tree() and ctrl._core_panel.anchor_slot != null \
			and ctrl._core_panel.anchor_slot.is_visible_in_tree():
		rect = ctrl._core_panel.anchor_slot.get_global_rect()
	return AnchorFx.play(ctrl._overlay_layer, AnchorAdapter.current_id(), extra_line, rect)


## "PAIR: <combo> . MUTATION: <name>" for the strongest newly formed combo, "" when none.
func _awaken_extra_line(formed: Array) -> String:
	if formed.is_empty():
		return ""
	var best: Dictionary = formed[0]
	for f in formed:
		if String(f["tier"]) == "full":
			best = f
			break
	var house := AnchorAdapter.house_of_combo(String(best["id"]))
	var line := "%s: %s" % [TranslationServer.translate("PAIR") if String(best["tier"]) != "full" else TranslationServer.translate("FULL"), UI3Gacha.combo_name(String(best["id"]))]
	var mn := String(AnchorAdapter.mutation_of(house)["name"]) if house != "" else ""
	return line + (" . %s: %s" % [TranslationServer.translate("MUTATION"), mn] if mn != "" else "")


func _on_anchor_awakened(id: String) -> void:
	AnchorFx.arm(id)


## Hover/focus tick on a Core card, at most one per 120 ms.
func _dm_core_hover() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if ctrl._dm_hover_at >= 0.0 and now - ctrl._dm_hover_at < 0.12:
		return
	ctrl._dm_hover_at = now
	ctrl._dm("dm_core_hover")


func _on_core_card_reroll(idx: int) -> void:
	var old_card: Control = ctrl._reward_cards[idx] if idx >= 0 and idx < ctrl._reward_cards.size() else null
	var res: Dictionary = await RunState.request_reroll_pending_rewards(idx)
	if not is_instance_valid(ctrl):
		return   # the run map was freed while waiting (scene change); the old Node coroutine stopped here
	if not bool(res["ok"]):
		if String(res["code"]) not in ["illegal", "busy"]:
			NetNotice.show(ctrl, String(res["code"]), _on_core_card_reroll.bind(idx), "Could not reroll the Cores")
		return
	if not UI3Gacha.is_instant() and old_card != null and is_instance_valid(old_card):
		ctrl.gacha_log.append("reroll_out")
		old_card.pivot_offset = old_card.size / 2.0
		var out := float(UI3Gacha.timing().get("reroll_out_sec", 0.3))
		var tw := old_card.create_tween().set_parallel(true)
		tw.tween_property(old_card, "position:y", old_card.position.y - 120.0, out)
		tw.tween_property(old_card, "modulate:a", 0.0, out)
		await tw.finished
	if not is_instance_valid(ctrl):
		return   # the run map was freed while waiting (scene change); the old Node coroutine stopped here
	ctrl._reroll_slot = idx
	_show_reward_overlay("x")


## The "Won't come back" line above the new card, fades after a moment.
func _reroll_note(card: Control) -> void:
	await ctrl.get_tree().process_frame
	if not is_instance_valid(ctrl) or not is_instance_valid(card) or ctrl._overlay_root == null:
		return
	var l := UI3.label(tr("Won't come back this run"), "LabelMuted")
	l.name = "RerollNote"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(card.size.x, 32)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl._overlay_root.add_child(l)
	l.global_position = card.global_position + Vector2(0, -36)
	if UI3Gacha.is_instant():
		return
	var tw := l.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


func _on_reward_reroll(title: String) -> void:
	var res: Dictionary = await RunState.request_reroll_pending_rewards()
	if not is_instance_valid(ctrl):
		return   # the run map was freed while waiting (scene change); the old Node coroutine stopped here
	if not bool(res["ok"]):
		if String(res["code"]) not in ["illegal", "busy"]:
			NetNotice.show(ctrl, String(res["code"]), _on_reward_reroll.bind(title))
		return
	_show_reward_overlay(title)


## One UI-05 CoreCard (47-core-offer): tier chip + category chip + partner / house chips, rule text, own Reroll.
func _add_core_card(r: Dictionary) -> PanelContainer:
	var idx := ctrl._reward_cards.size()
	var tier := clampi(int(r.get("tier", 0)), 0, 2)
	var key := String(r.get("key", ""))
	var axis := String(r.get("axis", ""))
	var name_text := String(r.get("title", ""))
	var body_text := String(r.get("desc", ""))
	if String(r.get("t", "")) == "relic" and String(r.get("sub", "")) != "":
		name_text = String(r.get("desc", ""))
		body_text = String(r.get("sub", ""))
	elif String(r.get("sub", "")) != "":
		body_text += "\n" + String(r.get("sub", ""))
	name_text = UI3.title_case(UI3.player_text(name_text))
	var dsc := UI3.describe(body_text)
	body_text = ("MP %d \u00b7 " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"])
	var card := _CoreCardUi.new()
	card.name = "CoreCard%d" % idx
	card.setup_core(tier, tr(ctrl._CORE_TIER_NAME[tier]), UI3.icon(String(CorePanel.AXIS_ICON.get(axis, "face_buff"))), name_text, body_text)
	card.rarity_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	UI3Tooltip.bind(card.rarity_chip, tr(ctrl.CORE_TIER_HINT))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_reward(idx)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_reward(idx)
			var tb := ctrl._overlay_root.find_child("TakeButton", true, false) as Control
			if tb != null and tb.is_visible_in_tree():
				tb.grab_focus())
	ctrl._overlay_vbox.add_child(card)
	ctrl._reward_cards.append(card)
	card.mouse_entered.connect(_dm_core_hover)
	card.focus_entered.connect(_dm_core_hover)
	if tier >= 2:
		# A3: Crystal cards keep their own bevelled silhouette and extra rings, and rise on hover.
		var accent: Color = card.accent
		card.set_meta("prism_accent", accent)
		card.use_prism(func(sel: bool) -> StyleBoxFlat: return UI3Gacha.prism_style(accent, sel))
		card.add_child(UI3Gacha.prism_frame(accent))
		card.mouse_entered.connect(_prism_hover.bind(card, true))
		card.mouse_exited.connect(_prism_hover.bind(card, false))
	card.chip_row.add_child(CorePanel.word_chip(tr(String(CorePanel.AXIS_NAME.get(axis, "Core"))),
		String(CorePanel.AXIS_ICON.get(axis, "face_buff")), UI3Theme.color("text_muted"), "CategoryChip"))
	_add_combo_labels(card.column, key, card.chip_row)
	var tag := card.column.get_node_or_null("ComboTag")
	if tag != null:
		card.column.remove_child(tag)
		card.body.add_child(tag)
		card.body.move_child(tag, card.name_label.get_index() + 1)
	var wc := card.chip_row.get_node_or_null("WorksWith")
	if wc != null:
		wc.name = "ComboChip"
	RunMapController._add_house_chip(card, card.chip_row, key)
	var hc := card.chip_row.get_node_or_null("HouseChip")
	if hc != null:
		hc.name = "HouseTag"
	var rr := _PanelParts.button(tr("Reroll"), &"secondary", &"M")
	rr.name = "RerollButton"
	rr.size_flags_vertical = Control.SIZE_SHRINK_END
	if RunState.core_can_reroll(idx):
		rr.pressed.connect(_on_core_card_reroll.bind(idx))
	else:
		UI3.set_disabled_reason(rr, tr("Rerolled") if RunState.core_rerolled_slots.has(idx) else tr("No rerolls left"))
	card.reroll_button = rr
	card.column.add_child(rr)
	return card
