extends Control
class_name DefeatPanel
## Defeat panel, UI-03 round 2 screen 30. Pure view: CombatView fills `show_defeat(d)` and listens to
## `end_run_pressed` / `continue_pressed`. The Continue effect (heal %, boss kept at HP/phase, clock and
## attrition reset) is the engine's `continue_after_wipe`; this panel only states it and reports the click.
## Prices, heal % and phase ticks all come in through `d` (aid_prices.json, ascension, combat_tune).
##
## d = {
##   title_line: String                                  # context line, e.g. "Boss fight · A6 · turn 14"
##   boss: {name, hp, max_hp, phase, phases, spike_in, marks:[0.66, 0.33]} or {}
##   recap: [{turn, what, result, final}]                 # newest last
##   aid_used, aid_cap, heal_pct, party:[{name,max_hp}], keep_line, enrage_reset_line, attrition_reset_line
##   price: int, variant: "paid"|"gift"|"moon", price_was: int
##   continue_show: bool, continue_enabled: bool, continue_reason: String, need_more: int (Gem short, 0 = none)
##   mission: bool, stake: int (mission only, default: the open escrow), foot: String }
## Esc does nothing: the panel must be answered. Focus: Continue, then End run (End run when Continue is off).

signal end_run_pressed
signal continue_pressed

const PANEL_W := 720

var _end_button: Button
var _continue_button: Button
var _busy_label := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Locks input and shows "Reviving…" while the purchase is in flight; false restores the panel.
func set_busy(on: bool) -> void:
	if _continue_button == null:
		return
	var spin := _continue_button.get_node_or_null("BusySpinner")
	if on:
		_busy_label = _continue_button.text
		_continue_button.text = TranslationServer.translate("Reviving…")
		if spin == null:
			spin = UI3.Spinner.new()   # holds still under the reduce-flash setting
			spin.tint = UI3Theme.color("accent_text")
			spin.name = "BusySpinner"
			spin.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			spin.position = Vector2(24, -12)
			_continue_button.add_child(spin)
	else:
		if spin != null:
			spin.queue_free()
		if _busy_label != "":
			_continue_button.text = _busy_label
			_busy_label = ""
	_continue_button.disabled = on
	_end_button.disabled = on


func show_defeat(d: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	theme = UI3Theme.get_theme()
	var dim := ColorRect.new()
	dim.name = "Scrim"
	dim.color = UI3Theme.color("scrim")   # neutral-1 @ 80%
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UI3.plate(&"dialog")
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("24"))
	panel.add_child(col)

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(head)
	var t := UI3.label(TranslationServer.translate("Party down"), "LabelScreenTitle")
	t.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	head.add_child(t)
	# Sub-line: "Fight 4 of 18 · A6 · 5 Axies" (Fight / Party / Ascension moved here from the old recap boxes).
	var ctx := UI3.label(String(d.get("title_line", "")), "LabelMuted")
	ctx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(ctx)

	var boss: Dictionary = d.get("boss", {})
	if not boss.is_empty():
		col.add_child(_boss_block(boss))
	col.add_child(_recap_grid(d))
	col.add_child(_continue_block(d))

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	var mission := bool(d.get("mission", false))
	_end_button = UI3.button(TranslationServer.translate("End run"), &"primary" if mission else &"secondary")
	_end_button.name = "EndRun"
	_end_button.pressed.connect(func(): end_run_pressed.emit())
	foot.add_child(_end_button)
	# Esc is swallowed on purpose.
	var usable := _continue_button != null and _continue_button.visible and not _continue_button.disabled
	(_continue_button if usable else _end_button).grab_focus()
	_play_in(dim, panel)


## Defeat moment (motion.md): scrim fades 240, the panel scales 0.96 -> 1 + fades from +200. Never blocks input.
func _play_in(dim: ColorRect, panel: Control) -> void:
	var full := dim.color
	if UI3Motion.reduced() or not is_inside_tree():
		return
	dim.color = Color(full, 0.0)
	create_tween().tween_property(dim, "color", full, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	panel.pivot_offset = panel.size * 0.5
	var tw := get_tree().create_timer(0.2)
	tw.timeout.connect(func() -> void:
		if is_instance_valid(panel):
			UI3Motion.play("defeat", panel))


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _boss_block(boss: Dictionary) -> Control:
	var box := UI3.plate(&"row")
	box.name = "BossBlock"
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	box.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	pad.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var nm := UI3.label(String(boss.get("name", "")), "LabelDisplay")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var hp := int(boss.get("hp", 0))
	var mx := maxi(int(boss.get("max_hp", 1)), 1)
	var left := "%d%% left" % int(round(100.0 * hp / mx))
	if int(boss.get("phases", 1)) > 1:   # one-phase bosses: no "phase 1 of 1" (Liam 20/10)
		left += " · phase %d of %d" % [int(boss.get("phase", 1)), int(boss.get("phases", 1))]
	var line := UI3.label(left)
	top.add_child(line)
	v.add_child(UI3.phase_bar(hp, mx, boss.get("marks", [])))
	if int(boss.get("spike_in", 0)) > 0:
		var n := int(boss["spike_in"])
		v.add_child(UI3.label("Big hit was due in %d turn%s" % [n, "" if n == 1 else "s"], "LabelMuted"))
	return box


func _recap_grid(d: Dictionary) -> Control:
	var g := HBoxContainer.new()
	g.name = "Recap"
	g.add_theme_constant_override("separation", UI3Theme.space("16"))
	# UI-04 C4: 3 numbers. Fight / Party / Ascension live in the sub-line. A mission run has no Aid, so no third cell.
	var rows := [["Fell on turn", str(int(d.get("turn", 0)))], ["Enemies left", str(int(d.get("enemies_left", 0)))]]
	if not bool(d.get("mission", false)):
		rows.append(["Aid used", "%d of %d" % [int(d.get("aid_used", 0)), int(d.get("aid_cap", 6))]])
	for r in rows:
		var cell := UI3.plate(&"row")
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pad := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, 12)
		cell.add_child(pad)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		pad.add_child(v)
		v.add_child(UI3.label(TranslationServer.translate(String(r[0])), "LabelMuted"))
		var val := UI3.label(TranslationServer.translate(String(r[1])), "LabelDisplay")
		val.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		v.add_child(val)
		g.add_child(cell)
	return g


func _continue_block(d: Dictionary) -> Control:
	if bool(d.get("mission", false)):
		var m := UI3.plate(&"row")
		m.name = "ContinueBlock"
		var mp := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			mp.add_theme_constant_override("margin_" + side, 16)
		m.add_child(mp)
		var stake := int(d.get("stake", MetaState.mission_escrow.get("stake", 0)))
		var lost := UI3.label(TranslationServer.translate("Mission lost: your %s Shard stake is gone. Mission runs have no Continue.") % UI3.fmt(stake)
			if stake > 0 else TranslationServer.translate("Mission runs have no Continue."), "LabelMuted")
		lost.name = "MissionLostLine"
		lost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mp.add_child(lost)
		return m
	var box := UI3.plate(&"row")
	box.name = "ContinueBlock"
	# UI-04 C4: the revive card is the only violet surface (paid surfaces only: revive_bg + gem_border).
	box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("revive_bg"), UI3Theme.radius("m"), 2,
		UI3Theme.color("gem_border"), Vector4(0, 0, 0, 0)))
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	box.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	pad.add_child(v)
	v.add_child(UI3.label(TranslationServer.translate("Revive and keep fighting"), "LabelDisplay"))
	var eff := UI3.label(_effect_line(d), "LabelMuted")
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(eff)
	var variant := String(d.get("variant", "paid"))
	var shown := bool(d.get("continue_show", true))
	var enabled := bool(d.get("continue_enabled", true))
	var price := int(d.get("price", 0))
	# The price appears once, inside the primary button.
	_continue_button = UI3.button_with_cost("Continue", &"free" if variant == "gift" else &"gem", price, not enabled, &"L")
	_continue_button.name = "Continue"
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	_continue_button.visible = shown
	if shown and not enabled:
		var need := int(d.get("need_more", 0))
		UI3.set_disabled_reason(_continue_button, "Need %d more Gem" % need if need > 0
			else String(d.get("continue_reason", "Not available now")))
		var why := UI3.label(String(d.get("continue_reason", "")), "LabelMuted")
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(why)
	if not shown:
		box.visible = false
	v.add_child(_continue_button)
	return box


func _effect_line(d: Dictionary) -> String:
	var parts: Array = ["Party back at %d%% HP." % int(d.get("heal_pct", 25))]
	for k in ["keep_line", "enrage_reset_line", "attrition_reset_line"]:
		if String(d.get(k, "")) != "":
			parts.append(String(d[k]))
	return " ".join(parts)
