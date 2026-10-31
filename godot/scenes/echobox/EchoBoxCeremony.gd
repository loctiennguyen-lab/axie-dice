class_name EchoBoxCeremony
extends RefCounted
## Echo Box opening ceremony (UI-05 b23 lane S9b, 20-echo--opening / reveal-* / open10). State (`_skip`, `instant`,
## `tab`, ...) stays on the screen (`_s`). Builders live in ui5/ceremony/CeremonyParts.gd. Result data comes from the
## pull; nothing here changes game state except Equip now (MetaState.equip_cosmetic, the old path).

const Parts := preload("res://scenes/echobox/ui5/ceremony/CeremonyParts.gd")

var _s: EchoBoxScreen   # the Echo Box screen


func _init(screen: EchoBoxScreen) -> void:
	_s = screen


func _flashy() -> bool:
	return not (_s.reduce_flashing or MetaState.reduce_flash or UI3Motion.reduced())


## Idle -> pressed -> opening -> reveal -> (Open 10 grid). Skip (click / Space / SkipButton) works from the first frame.
## Mythic tint 1.5 s, others 1.2 s; Reduce motion / flashing 0.2 s.
func _play_ceremony(out: Array) -> void:
	_s._skip = _s.instant
	var top := out[0] as Dictionary
	for r in out:
		if Parts.tier_of(r) > Parts.tier_of(top) or (String(top.get("kind")) == "stone" and String(r.get("kind")) != "stone"):
			top = r
	var parts := Parts.modal(_s._modal_layer, Parts.t("Opening…"))
	var scrim := parts["scrim"] as Control
	var col := parts["ceremony"] as VBoxContainer
	var title := parts["title"] as Label
	var tier := Parts.tier_of(top)
	var stone := String(top.get("kind")) == "stone"
	var tcol := DiceSkin.tier_color(tier)
	var chest := Parts.chest_word(Parts.t("%s chest") % _s._chest_tier(top), Parts.t("Stone") if stone else Parts.t(String(top.get("rarity", "common")).capitalize()), tcol)
	col.add_child(chest)
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(footer)
	var skip := Parts.space_button(Parts.t("Skip"), &"secondary", "SkipButton")
	skip.pressed.connect(func() -> void: _s._skip = true)
	footer.add_child(skip)
	Parts.attach_trailing(skip, skip.get_meta("cap") as Control)
	scrim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_s._skip = true)
	_focus(skip)
	var warm := _prewarm_art(out)   # bake the die thumbnails while the chest tint runs, so the flip never shows an empty square
	if not _s._skip:
		var dur := 0.2 if not _flashy() else float(UI3Motion.layer(_moment_id(tier), "chest_tint").get("ms", 1200.0)) / 1000.0
		var tw := _s.create_tween()
		tw.tween_method(func(k: float) -> void: Parts.set_tint(chest, k), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var elapsed := 0.0
		while elapsed < dur and not _s._skip and _s.is_inside_tree():
			await _s.get_tree().process_frame
			elapsed += _s.get_process_delta_time()
		tw.kill()
	if not is_instance_valid(scrim) or not scrim.is_inside_tree():
		return   # closed (Esc) during the opening
	await _await_art(warm)
	if not is_instance_valid(scrim) or not scrim.is_inside_tree():
		return
	for n in [chest, footer]:
		col.remove_child(n)
		n.queue_free()
	_reveal(out, col, title)


## Starts the thumbnail bake of every die in the pull. Returns the ids (frames are drawn from code, nothing to wait for).
func _prewarm_art(out: Array) -> Array:
	var ids: Array = []
	for r in out:
		if String(r.get("kind")) != "cosmetic":
			continue
		var a := Cosmetics.art_id(String(r.get("item", "")))
		if a != "" and Cosmetics.slot_of(a) == Cosmetics.SLOT_DIE and not ids.has(a) and DiceThumb.cached_texture(a) == null:
			ids.append(a)
	for a in ids:
		DiceThumb.get_thumb(_s, a)   # not awaited: runs during the tint (the bake queue serialises them)
	return ids


## Waits (max ~3 s) until every prewarmed die is in the thumbnail cache. Headless: no bake, no wait.
func _await_art(ids: Array) -> void:
	if DisplayServer.get_name() == "headless" or ids.is_empty():
		return
	var t := 0.0
	# Capped at 3 s; a Skip (or the screen going away) stops the wait at once.
	while t < 3.0 and is_instance_valid(_s) and _s.is_inside_tree() and not _s._skip:
		var ready := true
		for a in ids:
			if DiceThumb.cached_texture(a) == null and DiceSkin.has(a):
				ready = false
		if ready:
			return
		await _s.get_tree().process_frame
		t += _s.get_process_delta_time()


func _reveal(out: Array, col: VBoxContainer, title: Label) -> void:
	var single := out.size() == 1
	title.text = Parts.t("Reveal") if single else Parts.t("Open %d") % out.size()
	var flashy := _flashy()
	var order: Array = range(out.size())
	order.sort_custom(func(x: int, y: int) -> bool: return Parts.tier_of(out[x]) < Parts.tier_of(out[y]))   # best last
	var cards: Array = []
	cards.resize(out.size())
	var host: Control
	if single:
		host = Parts.card(_s, out[0], true, flashy)
		cards[0] = host
	else:
		var grid := GridContainer.new()
		grid.name = "RevealGrid"
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
		grid.add_theme_constant_override("v_separation", UI3Theme.space("16"))
		for i in out.size():
			cards[i] = Parts.card(_s, out[i], false, flashy)
			(cards[i] as Control).custom_minimum_size.y = 0.0   # grid cards fit their content (frame: no empty tail)
			grid.add_child(cards[i], true)
		host = grid
		# frame: .ceremony transform:scale(.94) on Open 10, so the Title keeps clear of the first row.
		col.scale = Vector2(0.94, 0.94)
		(func() -> void:
			if is_instance_valid(col):
				col.pivot_offset = col.size * 0.5).call_deferred()
		col.resized.connect(func() -> void: col.pivot_offset = col.size * 0.5)
	var hc := CenterContainer.new()
	hc.name = "RevealHost"
	hc.add_child(host)
	col.add_child(hc)
	var mls: Array[String] = _s._milestone_lines(out)
	if not mls.is_empty():
		var mrow := HBoxContainer.new()
		mrow.name = "RevealMilestones"
		mrow.alignment = BoxContainer.ALIGNMENT_CENTER
		mrow.add_theme_constant_override("separation", UI3Theme.space("8"))
		for line in mls:
			mrow.add_child(UI3.chip(line))
		col.add_child(mrow)
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(footer)
	var first := out[0] as Dictionary
	if single and String(first.get("kind")) == "cosmetic" and Cosmetics.art_id(String(first.get("item", ""))) != "":
		var art_id := Cosmetics.art_id(String(first.get("item", "")))
		var eqb := PanelParts_button(Parts.t("Equip now"), &"secondary", "EquipButton")
		eqb.pressed.connect(func() -> void:
			var why := MetaState.equip_cosmetic(art_id)
			eqb.text = Parts.t("Equipped") if why == "" else Parts.t("Couldn't equip")
			eqb.disabled = true)
		footer.add_child(eqb)
	var n := out.size()
	var again := PanelParts_button(Parts.t("Open again") if single else Parts.t("Open %d again") % n, &"secondary", "OpenAgainButton")
	var ar: String = _s.pull_block_reason(n)
	if ar != "":
		UI3.set_disabled_reason(again, ar)
	again.pressed.connect(func() -> void:
		_s.close_modal()
		_s.pull(n))
	footer.add_child(again)
	if ar == "":
		Parts.attach_trailing(again, Parts.ticket_chip(n * (_s.season_cost() if _s.tab == "seasonal" else 1)))
	var done := Parts.space_button(Parts.t("Done"), &"primary", "DoneButton")
	done.pressed.connect(func() -> void:
		_s.close_modal()
		_s._refresh_all())
	footer.add_child(done)
	Parts.attach_trailing(done, done.get_meta("cap") as Control)
	if not (_s.instant or not flashy or DisplayServer.get_name() == "headless"):
		_flip_in(cards, order)
	_focus(done)
	_s._refresh_all()


static func PanelParts_button(text: String, variant: StringName, node_name: String) -> Button:
	var b := Parts.PanelParts.button(text, variant, &"M")
	b.name = node_name
	return b


func _focus(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()


## Echo moment id of a tier (UI-05 b23 lane M3): Mythic, Rare+ (Epic and up), else normal.
static func _moment_id(tier: int) -> String:
	return "echo-open-mythic" if tier >= 5 else ("echo-open-rare" if tier >= 3 else "echo-open-normal")


## Cards flip in one after another, the highest tier last: the `echo-open-*` card_flip row (single) or the `open-10` rows
## (cards_flip + Epic+ last_pop), played from motion_ui3.json. Reduce motion / flashing: all at once (caller skips this).
func _flip_in(cards: Array, order: Array) -> void:
	for c in cards:
		(c as Control).pivot_offset = (c as Control).size / 2.0
	var host := _s as Node
	if cards.size() == 1:
		var t := int((cards[0] as Control).get_meta("tier", 0))
		var id := _moment_id(t)
		var lead := float(UI3Motion.layer(id, "chest_tint").get("ms", 1200.0))   # the tint already ran
		UI3Motion.play_timeline(id, {"card": cards[0]}, {"host": host, "only": ["card_flip"], "delay_ms": -lead})
		return
	var seq: Array = []
	for k in order:
		seq.append(cards[int(k)])
	var last := seq[seq.size() - 1] as Control
	var only: Array = ["cards_flip"]
	if cards.size() == 10 and int(last.get_meta("tier", 0)) >= 3:   # last_pop delay is fixed for 10 cards
		only.append("last_pop")
	UI3Motion.play_timeline("open-10", {"cards": seq, "last_card": last}, {"host": host, "only": only,
		"delay_ms": -float(UI3Motion.layer("open-10", "cards_flip").get("delay_ms", 0.0))})
