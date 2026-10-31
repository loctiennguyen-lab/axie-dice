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
	if not _s._skip:
		var dur := 0.2 if not _flashy() else (1.5 if tier >= 5 else 1.2)
		var tw := _s.create_tween()
		tw.tween_method(func(k: float) -> void: Parts.set_tint(chest, k), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var elapsed := 0.0
		while elapsed < dur and not _s._skip and _s.is_inside_tree():
			await _s.get_tree().process_frame
			elapsed += _s.get_process_delta_time()
		tw.kill()
	if not is_instance_valid(scrim) or not scrim.is_inside_tree():
		return   # closed (Esc) during the opening
	for n in [chest, footer]:
		col.remove_child(n)
		n.queue_free()
	_reveal(out, col, title)


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


## Cards flip in (scale x 0 -> 1) one after another, the highest tier last: single 360 ms, grid FLIP_S 160 ms every FLIP_GAP
## 120 ms (TRANS_BACK). Epic+ last card pops 1 -> 1.08 -> 1. Reduce motion / flashing: all at once (caller skips this).
func _flip_in(cards: Array, order: Array) -> void:
	for c in cards:
		(c as Control).scale.x = 0.0
	var dur: float = 0.36 if cards.size() == 1 else _s.FLIP_S
	for k in order.size():
		var c := cards[int(order[k])] as Control
		var last: bool = k == order.size() - 1
		var tw := _s.create_tween()
		tw.tween_interval(_s.FLIP_GAP * k)
		tw.tween_callback(func() -> void: c.pivot_offset = c.size / 2.0)
		tw.tween_property(c, "scale:x", 1.0, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if last and cards.size() > 1 and bool(c.get_meta("tier", 0) >= 3):
			tw.tween_property(c, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(c, "scale", Vector2.ONE, 0.15)
