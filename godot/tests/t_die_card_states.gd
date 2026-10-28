extends Node
## UI-05 b1 lane B: DieCard states and the DiceDock layout (frames components--dice, 02-combat--set-3 / --set-4 / --die-picked).
## Part 1, a lone DieCard in a slot Button: default / selected (die lifts 10, lip 18, cream rim + ring, PartChip stays clear of the
## die) / used (chip fill, "Used") / KO / in SET a and b (ring + filled chip + preview) / SET + selected (two rings) / TEMP, HELD,
## OVERCAST marks on the die corner / every size from tokens / FaceRow never clips at 1920 or 1280 (long previews go compact).
## Part 2, the real Combat scene: dock = VBox(SetBanners, DiceHeader, DiceRow) bottom-centred at both sizes (152 / 174 logical
## cards, 808 / 918 dock), waiting dims the row and swaps the header for the pill.
## Run: godot --headless --path godot res://tests/t_die_card_states.tscn
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _base(extra := {}) -> Dictionary:
	var d := {"name": "Pomodor", "hp": 14, "max_hp": 14, "faces": [{"type": "dmg", "value": 2}], "rolled": 0, "alive": true,
		"part_text": "MOUTH", "part_word": "Mouth", "part_tex": UI3.icon("face_dmg")}
	d.merge(extra, true)
	return d


func _make() -> Array:
	var btn := Button.new()
	btn.toggle_mode = true
	add_child(btn)
	var content := TrayColumn.build(btn)
	btn.size = Vector2(TrayColumn.card_w(), TrayColumn.card_h())
	return [btn, content]


func _paint(content: Dictionary, d: Dictionary) -> DieCard:
	TrayColumn.update(content, d)
	return content["card"]


func _settle() -> void:
	for _i in 3:
		await get_tree().process_frame


func _bg(p: Control) -> Color:
	return (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func _border(p: Control) -> Color:
	return (p.get_theme_stylebox("panel") as StyleBoxFlat).border_color


## The FaceRow's word and preview are both drawn whole (no clip) inside the card's content width.
func _row_fits(card: DieCard, tag: String) -> void:
	var w := card.face_word.get_minimum_size().x + card.set_delta.get_minimum_size().x + UI3Theme.space("4")
	_check(w <= card.face_row.size.x + 0.5, "%s: FaceRow '%s' + '%s' needs %.1f, has %.1f" % [tag, card.face_word.text, card.set_delta.text, w, card.face_row.size.x])
	_check(card.face_row.get_global_rect().end.x <= card.get_global_rect().end.x - card.pad().x + 0.5, "%s: FaceRow inside the card padding" % tag)
	var ow := card.owner_hp.get_minimum_size().x
	_check(card.owner_row.size.x >= ow + 20.0, "%s: OwnerRow keeps the HP '%s' whole" % [tag, card.owner_hp.text])
	_check(card.content.get_combined_minimum_size().y <= card.plate.size.y - card.pad().y * 2.0 + 0.5,
		"%s: rows fit the card height (%.1f in %.1f)" % [tag, card.content.get_combined_minimum_size().y, card.plate.size.y - card.pad().y * 2.0])


func _states(tag: String) -> void:
	var made := _make()
	var btn: Button = made[0]
	var content: Dictionary = made[1]
	# default
	var card := _paint(content, _base())
	await _settle()
	_check(is_equal_approx(btn.size.x, float(UI3Theme.size_of("die_card_w"))), "%s: card width = die_card_w" % tag)
	_check(card.die.size == Vector2(UI3Theme.size_of("die_w"), UI3Theme.size_of("die_h")), "%s: die = die_w × die_h" % tag)
	_check(is_equal_approx(card.part_chip.size.y, float(UI3Theme.size_of("part_chip_h"))), "%s: PartChip = part_chip_h (%.1f)" % [tag, card.part_chip.size.y])
	_check(card.state == &"default" and card.die.position.y == 0.0 and not card.sel_ring.visible and not card.set_ring.visible, "%s: default" % tag)
	_check(_bg(card.plate) == UI3Theme.color("plate") and _border(card.plate) == UI3Theme.color("plate_rim"), "%s: default plate + rim" % tag)
	_check(card.face_word.text == UI3.face_word(&"attack") and card.face_value.text == "2" and card.set_delta.text == "", "%s: ATTACK 2, no preview" % tag)
	_check(card.part_word.text == "Mouth" and _bg(card.part_chip) == UI3Theme.color("chip"), "%s: PartChip glyph + word on chip" % tag)
	for nm in ["Die", "FaceRow", "FaceWord", "FaceValue", "SetDelta", "PartRow", "PartChip", "OwnerRow", "OwnerName", "OwnerHP", "OwnerHPBar"]:
		_check(card.find_child(nm, true, false) != null, "%s: node %s" % [tag, nm])
	_row_fits(card, tag + " default")
	# selected: die lifts, PartChip stays visible under it
	card = _paint(content, _base({"selected": true}))
	await _settle()
	var lip_sel := DieCard._shadow_px("die_side_selected", 18)
	_check(card.state == &"selected" and card.die.position.y == -float(DieCard.lift_px()) and DieCard.lift_px() == 10, "%s: picked die lifts 10" % tag)
	_check(int((card.die.get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset.y) == lip_sel, "%s: lifted die lip %d" % [tag, lip_sel])
	_check(card.sel_ring.visible and _border(card.sel_ring) == UI3Theme.color("selected") and _border(card.plate) == UI3Theme.color("selected"), "%s: cream ring + rim" % tag)
	var die_bottom := card.die.get_global_rect().end.y + lip_sel
	_check(die_bottom <= card.part_chip.get_global_rect().position.y, "%s: lifted die (%.1f) never covers the PartChip (%.1f)" % [tag, die_bottom, card.part_chip.get_global_rect().position.y])
	# used
	card = _paint(content, _base({"spent": true}))
	_check(card.state == &"used" and _bg(card.plate) == UI3Theme.color("chip") and card.set_delta.text == TranslationServer.translate("Used"), "%s: used = chip fill + 'Used'" % tag)
	# KO
	card = _paint(content, _base({"alive": false, "hp": 0}))
	_check(card.face_value.text == "KO" and card.plate.modulate.a < 0.6, "%s: KO" % tag)
	# in SET a, preview
	card = _paint(content, _base({"set_key": "a", "set_before": 2, "set_after": 5, "set_show": true}))
	await _settle()
	_check(card.set_ring.visible and _border(card.set_ring) == UI3Theme.color("set_a"), "%s: SET a ring" % tag)
	_check(_bg(card.part_chip) == UI3Theme.color("set_a") and card.part_word.get_theme_color("font_color") == UI3Theme.color("set_text"), "%s: filled PartChip" % tag)
	_check(card.set_delta.text == SetPreview.delta_text(2, 5) and card.set_delta.get_theme_color("font_color") == UI3Theme.color("set_delta"), "%s: preview 2 → 5 (shown '%s', size %s, fonts %s)" % [tag, card.set_delta.text, card.size, UI3Theme.fonts_are_final()])
	_row_fits(card, tag + " set")
	# second SET colour
	card = _paint(content, _base({"set_key": "b", "set_before": 3, "set_after": 4, "set_show": true}))
	_check(_border(card.set_ring) == UI3Theme.color("set_b") and _bg(card.part_chip) == UI3Theme.color("set_b"), "%s: SET b mint" % tag)
	# SET + selected: cream ring outside the SET ring
	card = _paint(content, _base({"set_key": "a", "set_before": 2, "set_after": 5, "set_show": true, "selected": true}))
	var w := UI3Theme.stroke("selected")
	_check((card.set_ring.get_theme_stylebox("panel") as StyleBoxFlat).expand_margin_left == w
		and (card.sel_ring.get_theme_stylebox("panel") as StyleBoxFlat).expand_margin_left == w * 2, "%s: SET ring 4 out, cream ring 8 out" % tag)
	# long preview: compact "+15" so the word is never clipped; the tooltip keeps the full line
	card = _paint(content, _base({"faces": [{"type": "shield", "value": 12}], "set_key": "a", "set_before": 12, "set_after": 27, "set_show": true}))
	await _settle()
	_check(card.delta_full == SetPreview.delta_text(12, 27) and (card.set_delta.text == card.delta_full or card.set_delta.text == "+15"), "%s: long preview %s" % [tag, card.set_delta.text])
	_row_fits(card, tag + " long")
	_check(UI3Tooltip.text_of(btn).contains(SetPreview.delta_text(12, 27)), "%s: card tooltip keeps the full preview" % tag)
	# marks: TEMP / HELD / OVERCAST on the die's top-right corner, 10 px out, keycap_h high
	card = _paint(content, _base({"wild_text": "MOUTH", "overcast": true}))
	await _settle()
	var tm := card.mark(&"temp")
	_check(tm != null and tm.visible and tm.name == "TempFaceMark", "%s: TEMP mark" % tag)
	_check(card.mark(&"overcast") != null and card.mark(&"overcast").visible and card.mark(&"overcast").name == "OvercastMark", "%s: OVERCAST mark" % tag)
	var mr := card.marks_right
	_check((is_equal_approx(mr.position.x + mr.size.x, card.die.size.x + 10.0) or mr.get_global_rect().position.x >= card.get_global_rect().position.x)
		and mr.position.y == -10.0, "%s: marks hang 10 px off the die corner" % tag)
	_check(mr.get_global_rect().position.x >= card.get_global_rect().position.x, "%s: marks never hang past the card's left edge" % tag)
	_check(is_equal_approx(tm.size.y, float(UI3Theme.size_of("keycap_h"))), "%s: mark keycap_h" % tag)
	card = _paint(content, _base({"held": true}))
	_check(card.mark(&"held") != null and card.mark(&"held").visible and card.mark(&"held").name == "HeldMark" and not card.mark(&"temp").visible, "%s: HELD mark only" % tag)
	btn.queue_free()


func _dock(v: Node, tag: String) -> void:
	v._layout_tray()
	await _settle()
	var vs: Vector2 = v.get_viewport_rect().size
	var dock: Control = v._dock_plate
	var cw := float(UI3Theme.size_of("die_card_w"))
	var dw := float(UI3Theme.size_of("dice_dock_w"))
	_check(is_equal_approx(dock.size.x, dw) and absf(dock.position.x + dock.size.x * 0.5 - vs.x * 0.5) <= 0.5, "%s: dock %.0f wide, centred" % [tag, dock.size.x])
	_check(absf(dock.position.y + dock.size.y - (vs.y - UI3Theme.space("screen"))) <= 0.5, "%s: dock bottom 24 above the edge" % tag)
	var xs: Array = []
	for b in v._die_slot_buttons:
		if (b as Button).visible:
			_check(is_equal_approx((b as Button).size.x, cw), "%s: card %.0f wide (die_card_w %.0f)" % [tag, (b as Button).size.x, cw])
			xs.append((b as Button).position.x)
	_check(xs.size() == 5 and is_equal_approx(xs[0], dock.position.x) and is_equal_approx(xs[1] - xs[0], cw + UI3Theme.size_of("dice_gap")), "%s: five cards fill the dock" % tag)
	var bl: BoLayer = v._bo_layer
	_check(is_equal_approx(bl.row.position.y, dock.position.y) and is_equal_approx(bl.row.size.y, float(UI3Theme.size_of("set_banner_h"))), "%s: SetBanners = dock's top band" % tag)
	var front: Label = v._row_strip.find_child("FrontLabel", false, false)
	_check(front != null and front.visible and is_equal_approx(front.position.y, TrayColumn.header_top(vs.y)), "%s: FRONT on the DiceHeader row" % tag)
	_check(dock.get_theme_stylebox("panel") is StyleBoxEmpty, "%s: no panel behind the dice" % tag)
	for bnr in bl.banners():
		var sl: Label = bnr.find_child("SizeLabel", true, false)
		_check(sl.get_theme_font_size("font_size") == UI3Theme.size_of("text_body"), "%s: SetBanner text follows the scale" % tag)
	for i in 5:
		var card: DieCard = (v._die_slot_content[i] as Dictionary)["card"]
		_check(card.owner_name.get_theme_font_size("font_size") == UI3Theme.size_of("text_body")
			and card.part_word.get_theme_font_size("font_size") == UI3Theme.size_of("text_key"), "%s: card %d text follows the scale" % [tag, i])
		if card.face_word.text != "":
			_row_fits(card, "%s dock card %d" % [tag, i])


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	UI3Theme.set_scale_override(1.0)
	await _states("1920")
	UI3Theme.set_scale_override(2.0 / 3.0)
	_check(UI3Theme.size_of("die_card_w") == 174 and UI3Theme.size_of("text_body") == 21, "1280 tokens in effect")
	await _states("1280")
	UI3Theme.set_scale_override(1.0)

	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	v._rebuild_all()
	await _dock(v, "dock 1920")
	UI3Theme.set_scale_override(2.0 / 3.0)
	v._rebuild_all()
	await _dock(v, "dock 1280")
	UI3Theme.set_scale_override(1.0)
	v._rebuild_all()
	await _dock(v, "dock back to 1920")
	# waiting: the row dims to 0.4 and the pill takes the header's place (reduce motion: instant)
	var rm: bool = MetaState.reduce_motion
	MetaState.reduce_motion = true
	v._on_wait_dim(true)
	_check(is_equal_approx(v._tray_root.modulate.a, 0.4) and not v._row_strip.visible and v._dock_pill.visible, "waiting: dim 0.4, pill instead of FRONT/BACK")
	v._on_wait_dim(false)
	_check(is_equal_approx(v._tray_root.modulate.a, 1.0) and v._row_strip.visible and not v._dock_pill.visible, "waiting over: back to normal")
	MetaState.reduce_motion = rm
	v.queue_free()
	await get_tree().process_frame
	UI3Theme.set_scale_override(-1.0)
	UI3Theme.reset_cache()
	_guard.restore()
	CombatView.disable_juice_for_tests = false
	print("=== t_die_card_states: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_die_card_states: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_die_card_states: FAIL - %s" % f)
	get_tree().quit(1)
