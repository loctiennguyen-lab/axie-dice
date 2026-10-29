extends Control
class_name DefeatPanel
## Defeat panel, UI-05 batch 1 frames 30-defeat--paid / free / normal / mission
## (design/handoffs/ui-05-figma/round-1/ui05-combat-panels.html, README "Defeat"). Pure view: CombatView fills
## `show_defeat(d)` and listens to `end_run_pressed` / `continue_pressed` / `get_gem_pressed`. The Continue effect
## (heal %, boss kept at HP/phase, clock and attrition reset) is the engine's `continue_after_wipe`; this panel
## only states it and reports the click. Prices, heal % and phase ticks all come in through `d`.
##
## d = {
##   title_line: String                                  # sub-line, e.g. "Fight 4 of 18 · A6 · 5 Axies"
##   boss: {name, hp, max_hp, phase, phases, marks:[0.66, 0.33]} or {}
##   turn, enemies_left, aid_used, aid_cap               # the recap cells
##   heal_pct, keep_line, enrage_reset_line, attrition_reset_line
##   price: int, variant: "paid"|"gift"|"moon"
##   continue_show: bool, continue_enabled: bool, continue_reason: String, need_more: int (Gem short, 0 = none)
##   get_gem_reason: String  # "" = Get Gem is live; else it is drawn disabled and says this
##   mission: bool, stake: int (mission only, default: the open escrow) }
##
## States (README): paid = violet revive card, Continue + Gem chip. Free = amber edge + Free chip, no violet (not
## paid). Not enough Gem = Continue disabled "Need 90 Gem" + Get Gem, End run becomes the primary. Mission = no
## Continue at all, the stake line is the message, End run primary L.
## Esc does nothing (decision required). The primary takes clicks only after PRIMARY_DELAY_MS. Focus: Continue
## then End run (End run first when Continue is not usable).

signal end_run_pressed
signal continue_pressed
signal get_gem_pressed

const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")
const CostButton := preload("res://scenes/combat/ui5/CostButton.gd")
## Design `<!-- godot: Primary becomes clickable after 1000 ms -->`: the click that ended the fight must not
## answer the panel. Tests set `primary_delay_ms` to 0.
const PRIMARY_DELAY_MS := 1000

var primary_delay_ms := PRIMARY_DELAY_MS
var _end_button: Button
var _continue_button: Button   # a CostButton
var _get_gem_button: Button
var _primary: Button = null
var _armed_at := 0
var _busy_caption := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	add_to_group("ui3_modal")   # only counts while visible: HUD tooltips stay quiet under the panel (BUG-0005)


## Locks input and shows "Reviving…" while the purchase is in flight; false restores the panel.
func set_busy(on: bool) -> void:
	if _continue_button == null:
		return
	var cb := _continue_button as CostButton
	var spin := _continue_button.get_node_or_null("BusySpinner")
	if on:
		_busy_caption = cb.caption
		cb.set_caption(TranslationServer.translate("Reviving…"))
		if spin == null:
			spin = UI3.Spinner.new()   # holds still under the reduce-flash setting
			spin.tint = UI3Theme.color("accent_text")
			spin.name = "BusySpinner"
			spin.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			spin.position = Vector2(UI3Theme.space("24"), -UI3Theme.space("12"))
			_continue_button.add_child(spin)
	else:
		if spin != null:
			spin.queue_free()
		if _busy_caption != "":
			cb.set_caption(_busy_caption)
			_busy_caption = ""
	_continue_button.disabled = on
	_end_button.disabled = on
	if _get_gem_button != null and not _get_gem_button.has_meta("ui3_label"):
		_get_gem_button.disabled = on


## The button the panel treats as primary (Continue when usable, else End run).
func primary_button() -> Button:
	return _primary


## True once the primary takes clicks (PRIMARY_DELAY_MS after the panel opened).
func primary_armed() -> bool:
	return Time.get_ticks_msec() >= _armed_at


func show_defeat(d: Dictionary) -> void:
	UI3Theme.sync_scale()   # the 1280 overrides follow the window
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_continue_button = null
	_get_gem_button = null
	_primary = null
	visible = true
	theme = UI3Theme.get_theme()
	if is_inside_tree():
		UI3Tooltip.hide_all(get_tree())
	var dim := ColorRect.new()
	dim.name = "Scrim"
	dim.color = UI3Theme.color("scrim")   # neutral-1 @ 80%
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	# `.dialog`: defeat_panel_w, padding 32, radius xl, gap 20, the plate (rim + lip).
	var panel := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), "DefeatPanel")
	panel.custom_minimum_size = Vector2(UI3Theme.size_of("defeat_panel_w"), 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	panel.add_child(col)

	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	col.add_child(head)
	var t := PanelParts.text(TranslationServer.translate("Party down"), "text_banner", "danger_text", true)
	t.name = "Title"
	head.add_child(t)
	# Sub-line: "Fight 4 of 18 · A6 · 5 Axies" (Fight / Party / Ascension live here, not in the recap).
	var sub := PanelParts.text(String(d.get("title_line", "")), "text_body", "text_muted")
	sub.name = "SubLine"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(sub)

	var mission := bool(d.get("mission", false))
	var boss: Dictionary = d.get("boss", {})
	if not boss.is_empty():
		col.add_child(_boss_bar(boss))
	col.add_child(_recap(d))
	if mission:
		_mission_block(col, d)
	else:
		col.add_child(_revive_card(d))

	var usable := _continue_button != null and _continue_button.visible and not _continue_button.disabled
	# `.dialog-foot`: End run at the right. Secondary next to a usable Continue; otherwise it is the primary
	# (M in the not-enough-Gem state, L in the mission state where it is the only action).
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	var end_variant := &"secondary" if usable else &"primary"
	var end_size := &"L" if mission else &"M"
	_end_button = PanelParts.button(TranslationServer.translate("End run"), end_variant, end_size)
	_end_button.name = "EndRunButton"
	_end_button.pressed.connect(_on_end_pressed)
	foot.add_child(_end_button)

	_primary = _continue_button if usable else _end_button
	_armed_at = Time.get_ticks_msec() + primary_delay_ms
	# Focus order Continue -> (Get Gem) -> End run; Esc is swallowed on purpose.
	_primary.grab_focus()
	_play_in(dim, panel)


func _on_end_pressed() -> void:
	if _primary == _end_button and not primary_armed():
		return
	end_run_pressed.emit()


func _on_continue_pressed() -> void:
	if not primary_armed():
		return
	continue_pressed.emit()


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
	var ref: WeakRef = weakref(panel)   # the panel may be rebuilt (show_defeat again) before the timer fires
	tw.timeout.connect(func() -> void:
		var p: Control = ref.get_ref()
		if p != null and p.is_inside_tree():
			UI3Motion.play("defeat", p))


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


## `.cell.boss-bar` (boss fights): name + "50% left" on one line, 16 px phase bar with the threshold ticks.
func _boss_bar(boss: Dictionary) -> Control:
	var box := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16")), "BossBar")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	box.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(top)
	var nm := PanelParts.text(String(boss.get("name", "")), "text_body", "text", true)
	nm.name = "BossName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var hp := int(boss.get("hp", 0))
	var mx := maxi(int(boss.get("max_hp", 1)), 1)
	var left := TranslationServer.translate("%d%% left") % int(round(100.0 * hp / mx))
	if int(boss.get("phases", 1)) > 1:   # one-phase bosses: no "phase 1 of 1" (Liam 20/10)
		left += " · " + TranslationServer.translate("phase %d of %d") % [int(boss.get("phase", 1)), int(boss.get("phases", 1))]
	var line := PanelParts.text(left)
	line.name = "BossLeft"
	top.add_child(line)
	v.add_child(UI3.phase_bar(hp, mx, boss.get("marks", [])))
	return box


## `.recap`: 3 cells (2 in a mission run, which has no Aid), muted label over a Rowdies 24 value.
func _recap(d: Dictionary) -> Control:
	var g := HBoxContainer.new()
	g.name = "Recap"
	g.add_theme_constant_override("separation", UI3Theme.space("12"))
	var rows := [["Fell on turn", str(int(d.get("turn", 0)))], ["Enemies left", str(int(d.get("enemies_left", 0)))]]
	if not bool(d.get("mission", false)):
		rows.append(["Aid used", TranslationServer.translate("%d of %d") % [int(d.get("aid_used", 0)), int(d.get("aid_cap", 6))]])
	for i in rows.size():
		var cell := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16")), "RecapCell%d" % i)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", UI3Theme.space("4"))
		cell.add_child(v)
		var lab := PanelParts.text(TranslationServer.translate(String(rows[i][0])), "text_body", "text_muted")
		lab.name = "Label"
		v.add_child(lab)
		var val := PanelParts.text(String(rows[i][1]), "text_title", "text", true)
		val.name = "Value"
		v.add_child(val)
		g.add_child(cell)
	return g


## `.revive` card. Paid: gem_bg + 2 px gem_border (the one violet surface). Free: plate_raised + 2 px accent edge.
## Not enough Gem: Continue says "Need <price> Gem" and Get Gem sits under it. Hidden when Continue is not offered.
func _revive_card(d: Dictionary) -> Control:
	var shown := bool(d.get("continue_show", true))
	var enabled := bool(d.get("continue_enabled", true))
	var free := String(d.get("variant", "paid")) == "gift"
	var price := int(d.get("price", 0))
	var pad := UI3Theme.space("20")
	var box := UI3Theme.flat(UI3Theme.color("plate_raised") if free else UI3Theme.color("gem_bg"), UI3Theme.radius("l"),
		UI3Theme.stroke("rim"), UI3Theme.color("accent") if free else UI3Theme.color("gem_border"), Vector4(pad, pad, pad, pad))
	var card := PanelParts.panel(box, "ReviveCard")
	card.set_meta("variant", "free" if free else "paid")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	card.add_child(v)
	var rt := PanelParts.text(TranslationServer.translate("Revive and keep fighting"), "text_title", "text", true)
	rt.name = "ReviveTitle"
	v.add_child(rt)
	var eff := PanelParts.text(_effect_line(d))
	eff.name = "ReviveBody"
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(eff)
	var cb := CostButton.new()
	cb.name = "ContinueButton"
	cb.setup(TranslationServer.translate("Continue"), &"free" if free else &"gem", price)
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb.pressed.connect(_on_continue_pressed)
	v.add_child(cb)
	_continue_button = cb
	if shown and not enabled:
		var no_gem := int(d.get("need_more", 0)) > 0
		cb.show_reason(TranslationServer.translate("Need %d Gem") % price if no_gem
			else String(d.get("continue_reason", TranslationServer.translate("Not available now"))))
		if no_gem:
			_get_gem_button = PanelParts.gem_button(TranslationServer.translate("Get Gem"))
			_get_gem_button.name = "GetGemButton"
			_get_gem_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_get_gem_button.pressed.connect(func() -> void: get_gem_pressed.emit())
			var why := String(d.get("get_gem_reason", ""))
			if why != "":
				UI3.set_disabled_reason(_get_gem_button, why)
			v.add_child(_get_gem_button)
	if not shown:
		cb.visible = false
		card.visible = false
	return card


## Mission run: `.stake` (danger_bg, Shard icon, Rowdies 24 line) when the stake is known, then the muted
## "Mission runs have no Continue." line. No revive card at all.
func _mission_block(col: VBoxContainer, d: Dictionary) -> void:
	var stake := int(d.get("stake", MetaState.mission_escrow.get("stake", 0)))
	if stake > 0:
		var pv := UI3Theme.space("16")
		var ph := UI3Theme.space("20")
		var box := UI3Theme.flat(UI3Theme.color("danger_bg"), UI3Theme.radius("l"), 0, Color.TRANSPARENT, Vector4(ph, pv, ph, pv))
		var st := PanelParts.panel(box, "StakeLost")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI3Theme.space("12"))
		st.add_child(row)
		var icon_px := UI3Theme.size_of("icon_l")
		row.add_child(PanelParts.icon_rect(UI3.currency_icon("cur_shard", icon_px), icon_px))
		var line := PanelParts.text(TranslationServer.translate("Mission lost: your %s Shard stake is gone") % UI3.fmt(stake),
			"text_title", "text", true)
		line.name = "StakeLine"
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(line)
		col.add_child(st)
	var no := PanelParts.text(TranslationServer.translate("Mission runs have no Continue."), "text_body", "text_muted")
	no.name = "NoContinueLine"
	no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(no)


func _effect_line(d: Dictionary) -> String:
	var parts: Array = [TranslationServer.translate("Party back at %d%% HP.") % int(d.get("heal_pct", 25))]
	for k in ["keep_line", "enrage_reset_line", "attrition_reset_line"]:
		if String(d.get(k, "")) != "":
			parts.append(String(d[k]))
	return " ".join(parts)
