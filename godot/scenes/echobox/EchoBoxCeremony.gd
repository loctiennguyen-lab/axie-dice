class_name EchoBoxCeremony
extends RefCounted
## Echo Box opening ceremony moved out of EchoBoxScreen.gd (UI-05 b23 lane 0c). Code only moved: all state
## (`_skip`, `instant`, `tab`, ...) stays on the screen (`_s`), which keeps same-name forwarders.

var _s: EchoBoxScreen   # the Echo Box screen


func _init(screen: EchoBoxScreen) -> void:
	_s = screen


## Idle -> pressed -> opening -> reveal -> (Open 10 grid) -> summary. Skip (Space / button)
## is available from the first frame. Mythic <= 2 s. Reduce flashing: static rim, 200 ms fade.
func _play_ceremony(out: Array) -> void:
	_s._skip = _s.instant
	var top := out[0] as Dictionary
	for r in out:
		if _s._rarity_idx(r) > _s._rarity_idx(top):
			top = r
	var m := _s._modal("Opening...", 600)
	m.name = "Ceremony"
	var v: VBoxContainer = m.find_child("V", true, false)
	var skip := UI3.button("Skip", &"secondary", &"M")
	skip.name = "Skip"
	skip.tooltip_text = "Space"
	skip.pressed.connect(func() -> void: _s._skip = true)
	v.add_child(skip)
	var rim := _s._rarity_color("common" if String(top.get("kind")) == "stone" else String(top.get("rarity", "common")))
	var chest := UI3.label("%s chest" % _s._chest_tier(top), "LabelScreenTitle")
	chest.name = "CeremonyChest"
	v.add_child(chest)
	if not _s._skip:
		var t := _s.create_tween()
		var dur := 0.2 if (_s.reduce_flashing or UI3Motion.reduced()) else (1.5 if _s._rarity_idx(top) >= 5 else 1.2)
		t.tween_property(chest, "modulate", Color(rim.r, rim.g, rim.b, 1.0).lerp(Color.WHITE, 0.5), dur)
		var elapsed := 0.0
		while elapsed < dur and not _s._skip and _s.is_inside_tree():
			await _s.get_tree().process_frame
			elapsed += _s.get_process_delta_time()
		t.kill()
	v.remove_child(chest)
	chest.queue_free()
	v.remove_child(skip)
	skip.queue_free()
	(v.get_child(0) as Label).text = "Reveal" if out.size() == 1 else "Open %d" % out.size()
	var single := out.size() == 1
	if not single:
		(m.find_child("Card", true, false) as Control).custom_minimum_size.x = 1760.0
	var grid := GridContainer.new()
	grid.name = "RevealGrid"
	grid.columns = 1 if single else 5
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	var order: Array = range(out.size())
	order.sort_custom(func(x: int, y: int) -> bool: return _s._rarity_idx(out[x]) < _s._rarity_idx(out[y]))   # best last
	var cards: Array = []
	cards.resize(out.size())
	for i in out.size():
		var cd := _s._result_cell(out[i], "single" if single else "grid")
		cards[i] = cd
		grid.add_child(cd)
	var gc := CenterContainer.new()
	gc.add_child(grid)
	v.add_child(gc)
	var mls: Array[String] = _s._milestone_lines(out)
	if not mls.is_empty():
		var mrow := HBoxContainer.new()
		mrow.name = "RevealMilestones"
		mrow.alignment = BoxContainer.ALIGNMENT_CENTER
		mrow.add_theme_constant_override("separation", UI3Theme.space("8"))
		for t in mls:
			mrow.add_child(UI3.chip(t))
		v.add_child(mrow)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(btns)
	var first := out[0] as Dictionary
	if single and String(first.get("kind")) == "cosmetic" and Cosmetics.art_id(String(first.get("item", ""))) != "":
		var art_id := Cosmetics.art_id(String(first.get("item", "")))
		var eqb := UI3.button("Equip now", &"secondary", &"M")
		eqb.name = "EquipNow"
		eqb.pressed.connect(func() -> void:
			var why := MetaState.equip_cosmetic(art_id)
			eqb.text = "Equipped" if why == "" else "Couldn't equip"
			eqb.disabled = true)
		btns.add_child(eqb)
	var again_n := out.size()
	var again := UI3.button("Open again" if single else "Open %d again" % again_n, &"primary", &"L")
	again.name = "OpenAgain"
	var ar := _s.pull_block_reason(again_n)
	if ar != "":
		UI3.set_disabled_reason(again, ar)
	again.pressed.connect(func() -> void:
		_s.close_modal()
		_s.pull(again_n))
	btns.add_child(again)
	if ar == "":
		var cc := UI3.cost_chip(&"ticket", again_n * (_s.season_cost() if _s.tab == "seasonal" else 1))
		cc.name = "AgainCost"
		btns.add_child(cc)
	var done := UI3.button("Done", &"secondary", &"M")
	done.name = "Done"
	done.pressed.connect(func() -> void:
		_s.close_modal()
		_s._refresh_all())
	btns.add_child(done)
	if not (_s.instant or _s.reduce_flashing or MetaState.reduce_flash or UI3Motion.reduced() or DisplayServer.get_name() == "headless"):
		_flip_in(cards, order)
	_s._focus_later(done)
	_s._refresh_all()


## Cards flip in (scale x 0 -> 1, 160 ms) 120 ms apart, the highest tier last. Reduce flashing: all at once.
func _flip_in(cards: Array, order: Array) -> void:
	for c in cards:
		(c as Control).scale.x = 0.0
	for k in order.size():
		var c := cards[int(order[k])] as Control
		var tw := _s.create_tween()
		tw.tween_interval(_s.FLIP_GAP * k)
		tw.tween_callback(func() -> void: c.pivot_offset = c.size / 2.0)
		tw.tween_property(c, "scale:x", 1.0, _s.FLIP_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
