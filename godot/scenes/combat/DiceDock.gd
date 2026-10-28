extends RefCounted
class_name DiceDock
## UI-05 b1 lane 0: the dice tray (five DieCard columns, the dock plate, the FRONT/BACK strip, throw targets, die juice),
## moved out of CombatView.gd as-is. CombatView keeps one-line forwarders with the same names, so tests and
## TutorialView (`_die_slot()`, `_dice_tray()`, `_reroll_button`, step lock "die:<slot>") keep working.
## State stays on the view (`v._die_slot_content`, `v._tray_root`, ...); this class holds no state of its own.
## Lane B edits THIS file for the tray; it must not reach back into CombatView for anything new.

var v: CombatView


func _init(view: CombatView) -> void:
	v = view

## Dice tray: five 272 x 176 columns, gap 16, bottom 16, centred (x0 = 248 at 1920).
func _layout_tray() -> void:
	if v._tray_root == null:
		return
	var vs := v.get_viewport_rect().size
	var n := 0
	for b in v._die_slot_buttons:
		if (b as Button).visible:
			n += 1
	var col_w := TrayColumn.W
	var gap := 16.0
	if n > 5:   # summoned tokens: narrow the gap so one row still fits (the card stays 152 wide)
		gap = clampf((vs.x - 32.0 - col_w * n) / float(n - 1), 4.0, 16.0)
	var total := n * col_w + maxf(n - 1, 0.0) * gap
	var x0 := (vs.x - total) * 0.5
	var top := TrayColumn.card_top(vs.y)   # DiceDock: cards sit under the plate padding and the FRONT/BACK row
	var i := 0
	for b in v._die_slot_buttons:
		var btn: Button = b
		if not btn.visible:
			continue
		btn.position = Vector2(x0 + i * (col_w + gap), top)
		btn.size = Vector2(col_w, TrayColumn.H)
		i += 1
	_layout_dice_dock(vs, x0, total)
	_layout_row_strip(x0, col_w, gap, top)
	v._refresh_bo_layer()

## DiceDock plate (848 wide, grows only when summoned tokens widen the row) + the waiting pill centred on it.
func _layout_dice_dock(vs: Vector2, x0: float, total: float) -> void:
	if v._dock_plate == null:
		return
	var w := maxf(848.0, total + 32.0)
	v._dock_plate.size = Vector2.ZERO
	v._dock_plate.position = Vector2((vs.x - w) * 0.5, TrayColumn.dock_top(vs.y))
	v._dock_plate.size = Vector2(w, TrayColumn.DOCK_H)
	v._dock_plate.visible = total > 0.0
	if v._dock_pill != null:
		v._dock_pill.size = Vector2.ZERO
		v._dock_pill.position = v._dock_plate.position + (v._dock_plate.size - v._dock_pill.get_combined_minimum_size()) * 0.5
		v._dock_pill.size = v._dock_pill.get_combined_minimum_size()

## Waiting for the server (HUD dim fires 300 ms after the request): the card grid drops to 0.4, a pill says why,
## and the Aid offer hides. 120 ms fade, instant when motion is reduced.
func _on_wait_dim(on: bool) -> void:
	if v._tray_root != null:
		if UI3Motion.reduced() or not v.is_inside_tree():
			v._tray_root.modulate.a = 0.4 if on else 1.0
		else:
			v.create_tween().tween_property(v._tray_root, "modulate:a", 0.4 if on else 1.0, 0.12)
	if v._dock_pill != null:
		v._dock_pill.visible = on
	if v._aid != null:
		v._aid.set_waiting(on)

## Depth v3 4: a FRONT / BACK bracket over the tray columns (front = the first rows.front_size Axies).
## Enemies' single hits land on FRONT first; the words carry it, the bracket colours only back them.
func _layout_row_strip(x0: float, col_w: float, gap: float, top: float) -> void:
	if v._combat == null:
		return
	if v._row_strip == null:
		v._row_strip = Control.new()
		v._row_strip.name = "RowStrip"
		v._row_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v._tray_root.add_child(v._row_strip)
	for c in v._row_strip.get_children():
		v._row_strip.remove_child(c)
		c.queue_free()
	var units := v._party_dice_units()
	var spans := {0: [-1, -1], 1: [-1, -1]}
	var idx := 0
	for k in v._die_slot_buttons.size():
		if not (v._die_slot_buttons[k] as Button).visible or k >= units.size():
			continue
		var r := v._combat.row_of(units[k])
		var sp: Array = spans[r]
		if sp[0] < 0:
			sp[0] = idx
		sp[1] = idx
		idx += 1
	for r in [0, 1]:
		var sp: Array = spans[r]
		if sp[0] < 0:
			continue
		var x: float = x0 + sp[0] * (col_w + gap)
		var w: float = (sp[1] - sp[0] + 1) * col_w + (sp[1] - sp[0]) * gap
		var word := "FRONT" if r == 0 else "BACK"
		var l := UI3.label(word, "LabelDisplay")
		l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		l.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.position = Vector2(x, top - 8.0 - TrayColumn.DOCK_LABEL_H)
		l.size = Vector2(l.get_minimum_size().x, TrayColumn.DOCK_LABEL_H)
		var lab_w := l.size.x
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		UI3Tooltip.bind(l, "Front row (first %d Axies) takes single-target hits first. Back row is only hit once the front is down, or by area / piercing attacks." % v._combat.front_row_size()
			if r == 0 else "Back row: safe from single-target hits while a front-row Axie stands.")
		v._row_strip.add_child(l)
		l.visible = v._combat.bo.is_empty()
		var line := ColorRect.new()
		line.color = UI3Theme.color("btn_secondary")   # wood-3
		line.position = Vector2(x + lab_w + 8.0, top - 8.0 - TrayColumn.DOCK_LABEL_H * 0.5 - 1.0)
		line.size = Vector2(maxf(w - lab_w - 8.0, 0.0), 2)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v._row_strip.add_child(line)

## R1 tray column content — see TrayColumn. Returns the dictionary `_update_dice_tray()` repaints.
func _build_die_slot_content(btn: Button) -> Dictionary:
	return TrayColumn.build(btn)

## One die slot's looks (R1: the column paints its own panel; only the base behaviour is set here).
func _style_die_slot(btn: Button) -> void:
	btn.text = ""
	btn.focus_mode = Control.FOCUS_ALL

## The tooltip on a tray column: the face's name and every keyword's rule, as before.
func _tray_tooltip(u: Unit) -> String:
	if u.hp <= 0:
		return "%s is down. This die cannot be used." % u.n
	if not u.has_rolled():
		return "%s has not rolled this turn." % u.n
	var fi := u.roll_face_index()
	var f: Dictionary = u.die[fi]
	var face_type := String(f.get("type", ""))
	var part := String(f.get("part", ""))
	var part_name := String(CombatView._PART_LABEL.get(part, ""))
	var cap := ("%s %s %s" % [part_name, HudKit.dot(), UI3.type_label(face_type)]) \
		if part_name != "" else UI3.type_label(face_type)
	var value := v._live_face_value(u, fi)
	var lines := PackedStringArray(["%s  %s  %s" % [u.n, HudKit.dot(), cap]])
	if value > 0:
		lines.append("Value %d" % value)
	for k in (f.get("keywords", []) as Array):
		var kw_key := String(k).split(":")[0]
		var kw_tip: Dictionary = v._effect_tip(kw_key)
		var kw_head := String(CombatView._KEYWORD_LABEL.get(kw_key, kw_key.to_upper()))
		var kw_parts := String(k).split(":")
		var kw_n := int(kw_parts[1]) if kw_parts.size() > 1 else 0
		lines.append(kw_head if kw_tip.is_empty() else "%s: %s" % [kw_head, FaceAmount.fill_n(String(kw_tip["rule"]), kw_n)])
	return "\n".join(lines)

func _update_dice_tray() -> void:
	var fresh: Array = []
	var units := v._party_dice_units()
	_ensure_die_slots(units.size())
	for i in v._die_slot_buttons.size():
		var btn: Button = v._die_slot_buttons[i]
		var content: Dictionary = v._die_slot_content[i]
		if i >= units.size():
			btn.visible = false
			continue
		var u: Unit = units[i]
		btn.visible = true
		var usable := u.hp > 0 and u.has_rolled() and not u.roll_used() and not u.held
		var used_this_turn := u.hp > 0 and u.has_rolled() and u.roll_used()
		var is_sel := (u.uid == v._selected_die_uid)
		# A column stays clickable while a die is selected, so allies can be TARGETED (heal /
		# shield): party HP lives only in the tray, so the column is the ally's click target.
		var as_target := v._selected_die_uid != -1 and not is_sel and u.hp > 0
		btn.disabled = not (usable or as_target)
		btn.button_pressed = is_sel
		var faces: Array = []
		for fi in u.die.size():
			faces.append({"type": String((u.die[fi] as Dictionary).get("type", "")),
				"value": v._live_face_value(u, fi)})
		var card := {
			"name": "%s%s" % [u.n, CombatView._TIER_SUFFIX.get(u.tier, "")],
			"class_icon": v._class_portrait(u.cls), "hp": u.hp, "max_hp": u.max_hp,
			"shield": u.shield, "status": u.status, "incoming": v._incoming_damage_for(u),
			"icons": UnitPortrait._STATUS_ICON, "status_tip": Callable(UnitPortrait, "_effect_tooltip"),
			"skin": MetaState.equipped_die_skin,
			"faces": faces, "rolled": u.roll_face_index() if u.has_rolled() else -1,
			"alive": u.hp > 0, "spent": used_this_turn, "selected": is_sel, "held": u.held, "overcast": u.overcast, "row": v._combat.row_of(u),
			"legal_target": as_target and v._selected_ally_target_ok(u),
			"tip": _tray_tooltip(u)}.merged(v._v4_card_data(u), true)
		TrayColumn.update(content, card)
		_update_bonus_chip(content, u, btn, String(card["tip"]))
		TrayColumn.set_lifted(v, content, is_sel, CombatView.disable_juice_for_tests)
		if _maybe_play_roll_juice(u, btn):
			fresh.append({"slot": i, "u": u})
		_maybe_play_die_used_flip(u, btn)
		if v._dice_pending.has(u.uid):
			btn.modulate.a = 0.0   # the die is still in the air; its card shows on arrival
	v._start_dice_throw(fresh)

## Anchor dice marks on a tray card, written out on the chip (no hover needed): "BONUS" (phantom die: use it this turn, never part of
## the SET), "EMBER +0.5" (a carried Held die of Embers; value read from the engine knob) and "FREE · 0 mana" (Passed Flame can take it
## as a Temp Face). Returns {} when the die has no mark, else {text, tip, house} (house "" = neutral chip, no glyph).
func _anchor_die_mark(u: Unit) -> Dictionary:
	if u.hp <= 0 or v._combat == null:
		return {}
	if u.custom_state.has("phantom"):
		# The engine does not tag the phantom's source. Big Hand only when it is clearly Sixth Hand (awakened, no Sixth Die Core owned).
		var hand: bool = v._combat.anchor_id == "a_big_hand" and v._combat.anchor_awakened and not RunState.owned_relic_ids.has("c_sixth_die")
		return {"text": TranslationServer.translate("BONUS"), "house": "h_big_hand" if hand else "",
			"tip": TranslationServer.translate("Bonus die: use it this turn. It is not part of your SET.")}
	if v._combat.anchor_id == "a_embers" and u.stash_carry:
		var house := AnchorAdapter.house_id("a_embers")
		if bool(v._combat.call("_pf_ready", u)):
			return {"text": TranslationServer.translate("FREE · 0 mana"), "house": house,
				"tip": TranslationServer.translate("Passed Flame: this carried die joins any SET as a Temp Face, free of mana.")}
		var add := float(v._combat.call("anchor_embers_real100", u)) / 100.0   # real value after the M cap, not the knob
		var amt := String.num(add, 2).rstrip("0").rstrip(".")
		return {"text": TranslationServer.translate("EMBER +%s") % amt, "house": house,
			"tip": TranslationServer.translate("Carried Held die: +%s when used.") % String.num(add, 2)}
	return {}

func _update_bonus_chip(content: Dictionary, u: Unit, btn: Button, base_tip: String) -> void:
	var mark := _anchor_die_mark(u)
	var body: Control = content["body"]
	var chip: Control = content.get("anchor_chip", null)
	if mark.is_empty():
		if chip != null:
			chip.visible = false
		return
	var text := String(mark["text"])
	var house := String(mark["house"])
	var key := text + "|" + house
	if chip != null and String(chip.get_meta("chip_key", "")) != key:
		chip.queue_free()
		chip = null
	if chip == null:
		var tex: Texture2D = null   # no glyph: the word is the mark (a glyph would not fit the card width); the house shows as the border colour
		var col := AnchorAdapter.house_color(house) if house != "" else UI3Theme.color("text_muted")
		chip = UI3.icon_chip(text, tex, col, "AnchorDieChip")
		chip.mouse_filter = Control.MOUSE_FILTER_PASS   # PASS so the chip tooltip can show; clicks still reach the card
		chip.set_meta("chip_key", key)
		chip.set_meta("chip_text", text)
		# Above the card, one line, no glyph so it fits a 152 px card. HOLD / OVERCAST / ? chips hang at
		# y -8 (32 high) and the REROLL chip at -32 (reroll mode only), so this row sits over them (y = -(height) - 8).
		body.add_child(chip)
		chip.z_index = 5   # over the FRONT / BACK row captions and their line
		chip.position = Vector2(4.0, -chip.get_combined_minimum_size().y - 8.0)
		content["anchor_chip"] = chip
	chip.visible = true
	UI3Tooltip.bind(chip, String(mark["tip"]))
	UI3Tooltip.bind(btn, "%s\n%s" % [base_tip, String(mark["tip"])])

func _throw_tray_target(i: int) -> Vector2:
	if i < 0 or i >= v._throw_slots.size():
		return Vector2.ZERO
	var slot := int(v._throw_slots[i])
	var tile: Variant = (v._die_slot_content[slot] as Dictionary).get("die")
	if tile is Control and is_instance_valid(tile):
		return (tile as Control).get_global_rect().get_center() - v._stage3d.global_position
	var btn: Button = v._die_slot_buttons[slot]
	return btn.get_global_rect().get_center() - v._stage3d.global_position

func _wire_die_slot(idx: int) -> void:
	var btn: Button = v._die_slot_buttons[idx]
	btn.pressed.connect(func(): v._on_die_slot_pressed(idx))
	btn.mouse_entered.connect(func(): v._on_die_slot_hover(idx, true))
	btn.mouse_exited.connect(func(): v._on_die_slot_hover(idx, false))

func _ensure_die_slots(count: int) -> void:
	var want := maxi(count, 5)         # never shrink below the roster's five
	if v._tray_root == null:
		return
	while v._die_slot_buttons.size() < want:
		var btn := Button.new()
		btn.name = "DieSlot%d" % v._die_slot_buttons.size()
		btn.toggle_mode = true
		btn.text = ""
		btn.custom_minimum_size = Vector2(TrayColumn.W, TrayColumn.H)
		v._tray_root.add_child(btn)
		v._die_slot_buttons.append(btn)
		_style_die_slot(btn)
		v._die_slot_content.append(_build_die_slot_content(btn))
		v._die_slot_lifted.append(false)
		_wire_die_slot(v._die_slot_buttons.size() - 1)
	_layout_tray()

## Flip-on-use juice (review P1 #6). Detects the unused->used transition here (inside
## _update_dice_tray(), part of the sanctioned full-model-read path — same rationale
## _maybe_play_roll_juice() below already documents for why this isn't a signal handler).
func _maybe_play_die_used_flip(u: Unit, btn: Button) -> void:
	var used_now := u.hp > 0 and u.has_rolled() and u.roll_used()
	var was_used: bool = v._last_die_used.get(u.uid, false)
	v._last_die_used[u.uid] = used_now
	if used_now and not was_used:
		_play_die_flip(btn)

func _play_die_flip(btn: Button) -> void:
	if CombatView.disable_juice_for_tests or not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := v.create_tween()
	tw.tween_property(btn, "scale:x", 0.0, CombatView._DIE_FLIP_DURATION * 0.5)
	tw.tween_property(btn, "scale:x", 1.0, CombatView._DIE_FLIP_DURATION * 0.5)

func _play_die_roll_bounce(btn: Button) -> void:
	if CombatView.disable_juice_for_tests:
		return
	if not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := v.create_tween()
	tw.tween_property(btn, "scale", Vector2(CombatView._ROLL_ANIM_SCALE, CombatView._ROLL_ANIM_SCALE), CombatView._ROLL_ANIM_DURATION * 0.5)
	tw.parallel().tween_property(btn, "rotation_degrees", randf_range(-8.0, 8.0), CombatView._ROLL_ANIM_DURATION * 0.5)
	tw.tween_property(btn, "scale", Vector2.ONE, CombatView._ROLL_ANIM_DURATION * 0.5)
	tw.parallel().tween_property(btn, "rotation_degrees", 0.0, CombatView._ROLL_ANIM_DURATION * 0.5)

## Roll-bounce juice (unchanged from the pre-review pass — see original file history/report for
## why this lives here instead of a signal handler: EventBus has no dedicated "die just
## rolled" signal with the right payload).
## Returns true when this die was rolled for the first time since it was last unrolled (turn
## start, hatched Egg), i.e. it should be thrown in 3D.
func _maybe_play_roll_juice(u: Unit, btn: Button) -> bool:
	if not u.has_rolled():
		v._last_die_face.erase(u.uid)
		return false
	var fi := u.roll_face_index()
	var prev = v._last_die_face.get(u.uid, null)
	v._last_die_face[u.uid] = fi
	if v._reroll_prev.has(u.uid):
		return true   # rerolled: thrown in 3D again, even when it lands on the same face
	if prev == null:
		return true
	if prev == fi:
		return false
	_play_die_roll_bounce(btn)
	return false
