extends Control
class_name CombatHud
## Dice UI R1 combat HUD frame (design/handoffs/ui-02-round1b README §3): the top HUD, the
## attrition card, the right zone (Undo / Reroll / END TURN / speed control) and the left zone
## (Aid). Pure view: it is told what to show (`update_*`) and reports clicks (signals). It never
## reads or writes game state; CombatView owns that.
##
## Layout is relationships, not mockup y values (godot/CLAUDE.md rule 2): the top HUD hangs from
## y 0, everything in the bottom half hangs from y H, and extra window height opens up between
## the monsters and the party. `layout()` runs on every resize.

signal menu_pressed
signal ascension_pressed
signal active_pressed(relic_id: String)
signal hold_pressed   ## depth v3 3.2: the Hold button (CombatView turns it into the `stash` action)

const TOP := 24.0
const EDGE := 24.0
const RIGHT_W := 240.0
const GAP := 12.0
const END_H := 64.0
const SMALL_H := 48.0
const HINT_H := 24.0
const UNDO_W := 88.0
const INFO_W := 288.0

var core_panel: CorePanel            ## depth v3: 6 Core slots + Run rule slot + quest chips
var relic_strip: HBoxContainer      ## kept as a public name: tests hover relic chips here
var actives_row: HBoxContainer

var _top_plate: PanelContainer
var _fight_label: Label
var _turn_label: Label
var _shard_box: HBoxContainer
var _shard_label: Label
var _menu_button: Button
var _relic_plate: PanelContainer
var _divider: Control
var _mana_box: HBoxContainer
var _mana_holder: Control
var _attr_card: PanelContainer
var _attr_title: Label
var _attr_sub: Label
var _speed: HBoxContainer          ## 1x / 2x / Skip, takes the Undo+Reroll row while a resolve plays
var _info: PanelContainer           ## die info panel (288 w, wood-2), only while a die is picked
var _info_title: Label
var _info_body: Label
var _info_bottom := -1.0
var _log_plate: PanelContainer      ## battle log, top-left column under the attrition card
const LOG_H := 176.0
var _speed_buttons: Array[Button] = []
var _skip_button: Button

## Right-zone buttons are owned by the scene (%UndoButton etc. keep their names for the tests);
## CombatView hands them over via `adopt_right_zone()`.
var undo_button: Button
var reroll_button: Button
var end_turn_button: Button
var hold_button: Button             ## depth v3 Hold, owned here (no scene node)
var _hint: Label
var _hold_wanted := true
var _foe_card: PanelContainer       ## boss rhythm (3 chips) and / or the Elite affix chip, left column
var _foe_rows: VBoxContainer

var _newcomer := false
var _tray_top := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI3Theme.get_theme()
	_build_top()
	_build_attrition()
	_build_foe_card()
	_build_speed()
	_build_info()
	resized.connect(layout)


# ── Top HUD (UI-03 spec: TopLeft plate, relic plate under it) ───────────────────────────────

func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_top() -> void:
	# TopLeft plate: menu icon button 40, "Fight 4 of 12" Rowdies 20, "A3 · Turn 2" Work Sans 18 muted.
	_top_plate = UI3.plate(&"plate")
	_top_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_plate)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_top_plate.add_child(row)
	_menu_button = UI3.icon_button("ui_menu", "Menu")
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	row.add_child(_menu_button)
	_fight_label = UI3.label("", "LabelDisplay")
	_fight_label.add_theme_font_size_override("font_size", 20)
	_ignore(_fight_label)
	row.add_child(_fight_label)
	_turn_label = UI3.label("", "LabelMuted")
	_ignore(_turn_label)
	row.add_child(_turn_label)
	_shard_box = HBoxContainer.new()
	_shard_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_shard_box.tooltip_text = "Gene Shards earned this run"
	_shard_box.add_theme_constant_override("separation", 6)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("cur_shard")
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_l")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shard_box.add_child(ic)
	_shard_label = UI3.label("0", "LabelDisplay")
	_shard_label.add_theme_font_size_override("font_size", 20)
	_ignore(_shard_label)
	_shard_box.add_child(_shard_label)
	row.add_child(_shard_box)

	# Relic plate under it: passive relics, divider, actives, Mana.
	_relic_plate = UI3.plate(&"plate")
	_relic_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_relic_plate)
	var rrow := HBoxContainer.new()
	rrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rrow.add_theme_constant_override("separation", 4)
	rrow.alignment = BoxContainer.ALIGNMENT_CENTER
	_relic_plate.add_child(rrow)
	core_panel = CorePanel.new()
	rrow.add_child(core_panel)
	relic_strip = HBoxContainer.new()
	relic_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_strip.add_theme_constant_override("separation", 4)
	rrow.add_child(relic_strip)
	var div := ColorRect.new()
	div.color = UI3Theme.color("text_muted")
	div.custom_minimum_size = Vector2(2, 40)
	div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var div_box := MarginContainer.new()
	div_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div_box.add_theme_constant_override("margin_left", 6)
	div_box.add_theme_constant_override("margin_right", 6)
	div_box.add_child(div)
	rrow.add_child(div_box)
	_divider = div_box
	actives_row = HBoxContainer.new()
	actives_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actives_row.add_theme_constant_override("separation", 8)
	rrow.add_child(actives_row)
	# Mana: the active slots spend it, so the player must see it (UI3 status chip, mana tint).
	_mana_holder = Control.new()
	_mana_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mana_box = HBoxContainer.new()
	_mana_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mana_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rrow.add_child(_mana_box)


func _build_attrition() -> void:
	_attr_card = UI3.plate(&"notice")
	_attr_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_attr_card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	_attr_card.add_child(row)
	var ic := TextureRect.new()
	ic.texture = HudKit.icon("attrition")
	ic.custom_minimum_size = Vector2(32, 32)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	_attr_title = UI3.label("", "LabelDisplay")
	_attr_title.add_theme_font_size_override("font_size", 18)
	_ignore(_attr_title)
	col.add_child(_attr_title)
	_attr_sub = UI3.label("", "LabelMuted")
	_attr_sub.add_theme_font_size_override("font_size", 18)
	_ignore(_attr_sub)
	col.add_child(_attr_sub)


# ── Foe card: boss rhythm (3 chips) and the Elite affix chip (depth v3 6.3 / 6.4, spec design/ux/depth-v3/combat-hud.md)

const _PHASES := ["prep", "strike", "hollow"]
const _PHASE_WORD := {"prep": "Prep", "strike": "Strike", "hollow": "Hollow"}


func _build_foe_card() -> void:
	_foe_card = UI3.plate(&"notice")
	_foe_card.name = "FoeCard"
	_foe_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foe_card.visible = false
	_foe_card.add_to_group("ui3_tip_avoid")
	add_child(_foe_card)
	_foe_rows = VBoxContainer.new()
	_foe_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foe_rows.add_theme_constant_override("separation", 6)
	_foe_card.add_child(_foe_rows)


## d: {rhythm: {phase, next, turns_to_strike, tell}, affix: {name, tip, note}}. Either key may be missing;
## with neither the card hides. Phase chips carry the WORD (colour never alone); the current one is the
## selected plate, the next one is marked "next".
func update_foe(d: Dictionary) -> void:
	for c in _foe_rows.get_children():
		_foe_rows.remove_child(c)
		c.queue_free()
	var r: Dictionary = d.get("rhythm", {})
	var a: Dictionary = d.get("affix", {})
	_foe_card.visible = not r.is_empty() or not a.is_empty()
	if not a.is_empty():
		var row := HBoxContainer.new()
		row.name = "AffixRow"
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_theme_constant_override("separation", 8)
		var ic := TextureRect.new()
		ic.texture = UI3.icon("node_elite")
		ic.custom_minimum_size = Vector2(28, 28)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
		var l := UI3.label(String(a.get("name", "")), "LabelDisplay")
		l.add_theme_font_size_override("font_size", 18)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		if String(a.get("note", "")) != "":
			var n := UI3.label(String(a["note"]), "LabelMuted")
			n.add_theme_font_size_override("font_size", 18)
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(n)
		UI3Tooltip.bind(row, String(a.get("tip", "")))
		_foe_rows.add_child(row)
	if not r.is_empty():
		var title := UI3.label("BOSS RHYTHM", "LabelDisplay")
		title.add_theme_font_size_override("font_size", 18)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_foe_rows.add_child(title)
		var chips := HBoxContainer.new()
		chips.name = "RhythmChips"
		chips.mouse_filter = Control.MOUSE_FILTER_PASS
		chips.add_theme_constant_override("separation", 6)
		for ph in _PHASES:
			var is_now: bool = String(r.get("phase", "")) == ph
			var is_next: bool = String(r.get("next", "")) == ph
			var p := UI3.plate(&"card_selected" if is_now else &"row")
			p.name = "Phase_" + ph
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var l2 := UI3.label(String(_PHASE_WORD[ph]) + (" *" if is_next and not is_now else ""), "LabelDisplay")
			l2.add_theme_font_size_override("font_size", 18)
			l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(l2)
			chips.add_child(p)
		UI3Tooltip.bind(chips, "Boss rhythm: 3-turn cycle. Prep, then Strike (its strongest face), then Hollow (it takes +30% from damage faces and deals -30%). * marks the next phase.")
		_foe_rows.add_child(chips)
		var tell := UI3.label(String(r.get("tell", "")), "LabelMuted")
		tell.add_theme_font_size_override("font_size", 18)
		tell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_foe_rows.add_child(tell)
	layout()


func _build_info() -> void:
	# Round 1 components: Info panel 288 w, wood-2, pad 10 12, Rowdies 18 title + Work Sans 18 body.
	_info = UI3.plate(&"info")
	_info.visible = false
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.custom_minimum_size = Vector2(INFO_W, 0)
	add_child(_info)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	_info.add_child(col)
	_info_title = UI3.label("", "LabelDisplay")
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size = Vector2(INFO_W - 24.0, 0)
	_ignore(_info_title)
	col.add_child(_info_title)
	_info_body = UI3.label("")
	_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_body.custom_minimum_size = Vector2(INFO_W - 24.0, 0)
	_ignore(_info_body)
	col.add_child(_info_body)


## Die info panel. d = {} hides it; else {title, body}.
func update_info(d: Dictionary) -> void:
	_info.visible = not d.is_empty()
	if d.is_empty():
		return
	_info_title.text = String(d.get("title", ""))
	_info_body.text = String(d.get("body", ""))
	_info_body.visible = _info_body.text != ""
	layout()


## y the info panel's bottom edge sits on (CombatView passes the top of the Aid zone minus a gap).
func set_info_bottom(y: float) -> void:
	_info_bottom = y
	layout()


func info_panel() -> Control:
	return _info


func _build_speed() -> void:
	# Speed control 1x / 2x / Skip (Space), shown only while a resolve is playing.
	# No plate of its own: the buttons are already opaque, and the row sits in the 240 px right column
	# (same slot as Undo / Reroll, which are hidden meanwhile), so it can never leave the screen.
	_speed = HBoxContainer.new()
	_speed.visible = false
	_speed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed.add_theme_constant_override("separation", 8)
	add_child(_speed)
	for t in ["1x", "2x"]:
		var b := UI3.button(t, &"secondary", &"S")
		b.custom_minimum_size = Vector2(56.0, SMALL_H)
		b.clip_text = true
		_speed.add_child(b)
		_speed_buttons.append(b)
	_skip_button = UI3.button("Skip", &"secondary", &"S")
	_skip_button.custom_minimum_size = Vector2(0.0, SMALL_H)
	_skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skip_button.clip_text = true
	_skip_button.tooltip_text = "Skip the animation (%s)" % KeyBindings.text(KeyBindings.COMBAT_END_TURN)
	_speed.add_child(_skip_button)


# ── Right zone: adopt the scene's buttons, UI3 variants ─────────────────────────────────────

## The battle log lives in the left column, between the attrition card and the info panel, clear of
## the party, the enemy panel (top-right) and the eggs row. Takes the scene's RichTextLabel.
func adopt_log(text: RichTextLabel) -> PanelContainer:
	_log_plate = UI3.plate(&"info")
	_log_plate.name = "BattleLogPlate"
	_log_plate.visible = false
	_log_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_plate.custom_minimum_size = Vector2(INFO_W, LOG_H)
	add_child(_log_plate)
	if text.get_parent() != null:
		text.get_parent().remove_child(text)
	text.custom_minimum_size = Vector2(INFO_W - 24.0, LOG_H - 20.0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.theme = UI3Theme.get_theme()
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_color_override("default_color", UI3Theme.color("text"))
	_log_plate.add_child(text)
	layout()
	return _log_plate


func adopt_right_zone(undo: Button, reroll: Button, end_turn: Button) -> void:
	undo_button = undo
	reroll_button = reroll
	end_turn_button = end_turn
	for b in [undo, reroll, end_turn]:
		if b.get_parent() != null:
			b.get_parent().remove_child(b)
		for c in b.get_children():
			c.queue_free()
		for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			b.remove_theme_stylebox_override(st)
		b.theme = UI3Theme.get_theme()
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(b)
	for b in [undo, reroll]:
		b.add_theme_font_size_override("font_size", 18)
	undo.theme_type_variation = "ButtonSecondaryS"
	undo.text = "Z"
	undo.icon = UI3.cream_icon("ui_undo")
	undo.expand_icon = true
	undo.add_theme_constant_override("icon_max_width", 20)
	reroll.theme_type_variation = "ButtonSecondaryS"
	reroll.text = "Reroll"
	reroll.tooltip_text = "Reroll unused dice (%s)" % KeyBindings.text(KeyBindings.COMBAT_REROLL)
	end_turn.theme_type_variation = "ButtonPrimaryL"
	end_turn.text = "End turn"
	end_turn.add_theme_font_size_override("font_size", 24)   # "Enemy turn" must fit the 240 px column
	undo.custom_minimum_size = Vector2(UNDO_W, SMALL_H)
	reroll.custom_minimum_size = Vector2(RIGHT_W - UNDO_W - GAP, SMALL_H)
	end_turn.custom_minimum_size = Vector2(RIGHT_W, END_H)
	# Backstop: a label can never grow its button past the 240 px column (test: t_combat_right_block).
	for b in [undo, reroll, end_turn]:
		b.clip_text = true
	hold_button = UI3.button("Hold", &"secondary", &"S")
	hold_button.name = "HoldButton"
	hold_button.add_theme_font_size_override("font_size", 18)
	hold_button.custom_minimum_size = Vector2(RIGHT_W, SMALL_H)
	hold_button.clip_text = true
	hold_button.pressed.connect(func(): hold_pressed.emit())
	add_child(hold_button)
	_hint = UI3.label("", "LabelMuted")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	layout()


# ── Update API (called from CombatView._rebuild_all) ─────────────────────────────────────────

func update_top(d: Dictionary) -> void:
	## d: relics:[{icon, tip}], actives:[{id, icon, charges, spent, armed, tip}], mana, turn, title,
	##    ascension, shards, newcomer
	_newcomer = bool(d.get("newcomer", false))
	for c in relic_strip.get_children():
		relic_strip.remove_child(c)
		c.queue_free()
	var relics: Array = d.get("relics", [])
	var shown := mini(relics.size(), 8 if relics.size() <= 8 else 7)
	for i in shown:
		var r: Dictionary = relics[i]
		relic_strip.add_child(_slot(44, r.get("icon"), 32, String(r.get("tip", ""))))
	if relics.size() > 8:
		relic_strip.add_child(_more_slot(relics.size() - 7))
	for c in actives_row.get_children():
		actives_row.remove_child(c)
		c.queue_free()
	for a in d.get("actives", []):
		actives_row.add_child(_active_slot(a))
	for c in _mana_box.get_children():
		_mana_box.remove_child(c)
		c.queue_free()
	if (d.get("actives", []) as Array).size() > 0:
		var mc := UI3.status_chip("face_mana", int(d.get("mana", 0)), UI3Theme.color("mana"))
		mc.tooltip_text = "Mana: spent only on relic actives"
		mc.mouse_filter = Control.MOUSE_FILTER_STOP
		_mana_box.add_child(mc)
	var has_cores := core_panel.refresh()
	core_panel.visible = has_cores
	_divider.visible = (d.get("actives", []) as Array).size() > 0 and (relics.size() > 0 or has_cores)
	relic_strip.visible = relics.size() > 0
	_relic_plate.visible = has_cores or relics.size() > 0 or (d.get("actives", []) as Array).size() > 0
	_fight_label.text = String(d.get("title", ""))
	var asc := int(d.get("ascension", 0))
	_turn_label.text = ("A%d · " % asc if asc > 0 else "") + TranslationServer.translate("Turn") + " %d" % int(d.get("turn", 1))
	_shard_label.text = str(int(d.get("shards", 0)))
	layout()


func _slot(px: int, icon_tex: Variant, icon_px: int, tip: String) -> PanelContainer:
	var s := PanelContainer.new()
	s.custom_minimum_size = Vector2(px, px)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("s")) \
		if tip == "" else UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("s"), 2, UI3Theme.color("text_muted")))
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(cc)
	if icon_tex != null and icon_px > 0:
		var tr := TextureRect.new()
		tr.texture = icon_tex
		tr.custom_minimum_size = Vector2.ONE * icon_px
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(tr)
	if tip != "":
		UI3Tooltip.bind(s, tip)
		s.mouse_filter = Control.MOUSE_FILTER_STOP
		# Keyboard reachable (spec 43: tooltip shows on owner focus) with the shared focus ring.
		s.focus_mode = Control.FOCUS_ALL
		var ring := UI3Theme.focus_style(UI3Theme.radius("s"))
		s.draw.connect(func() -> void:
			if s.has_focus():
				s.draw_style_box(ring, Rect2(Vector2.ZERO, s.size)))
		s.focus_entered.connect(s.queue_redraw)
		s.focus_exited.connect(s.queue_redraw)
	else:
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.modulate.a = 0.5
	return s


func _more_slot(n: int) -> PanelContainer:
	var s := _slot(44, null, 0, "")
	s.modulate.a = 1.0
	var l := UI3.label("+%d" % n, "LabelDisplay")
	l.add_theme_font_size_override("font_size", 18)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(s.get_child(0) as CenterContainer).add_child(l)
	return s


## Active slot: 48 x 48, charge badge bottom-right. Spent: dimmed + disabled. CLICKABLE (the engine's
## play_active); armed = selected outline.
func _active_slot(a: Dictionary) -> Control:
	var spent := bool(a.get("spent", false))
	var armed := bool(a.get("armed", false))
	var b := Button.new()
	b.custom_minimum_size = Vector2(48, 48)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.disabled = spent
	UI3Tooltip.bind(b, String(a.get("tip", "")))
	var fill := UI3Theme.color("disabled") if spent else UI3Theme.color("panel_raised")
	var border: Color = UI3Theme.color("selected_outline") if armed else UI3Theme.color("text_muted")
	var sb := UI3Theme.flat(fill, UI3Theme.radius("s"), 4 if armed else 2, border)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	var aring := UI3Theme.focus_style(UI3Theme.radius("s"))
	aring.set_expand_margin_all(4)   # 4 px offset ring on the active icon
	b.add_theme_stylebox_override("focus", aring)
	var ic := TextureRect.new()
	ic.texture = a.get("icon")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.modulate.a = 0.4 if spent else 1.0
	b.add_child(ic)
	var badge := UI3.label(str(a.get("charges", "")), "LabelDisplay")
	badge.add_theme_font_size_override("font_size", 18)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(34, 26)
	b.add_child(badge)
	var rid := String(a.get("id", ""))
	b.pressed.connect(func(): active_pressed.emit(rid))
	return b


## Attrition card. state = hud_state().attrition; turn; hidden for newcomers.
func update_attrition(state: Dictionary, turn: int, newcomer: bool) -> void:
	_newcomer = newcomer
	_attr_card.visible = not newcomer
	_attr_card.add_to_group("ui3_tip_avoid")
	if newcomer:
		return
	var pct := int(state.get("pct", 0))
	var start := int(state.get("start_turn", 6))
	var maxed := pct >= 25
	if pct <= 0:
		_attr_title.text = "ATTRITION %s NOT YET" % HudKit.dot()
		_attr_sub.text = "starts turn %d %s +5%%/turn %s max +25%%" % [start, HudKit.dot(), HudKit.dot()]
	elif maxed:
		_attr_title.text = "ATTRITION +%d%% %s MAX" % [pct, HudKit.dot()]
		_attr_sub.text = "since turn %d" % (start + 4)
	else:
		_attr_title.text = "ATTRITION +%d%%" % pct
		_attr_sub.text = "+5%% each turn %s max +25%%" % HudKit.dot()


## Right zone texts + enabled states. Disabled buttons say why (UI3 rule).
## undo: {enabled, sub}  reroll: {n, enabled}  end: {sub, warn, enabled, resolving}
func update_right(undo: Dictionary, reroll: Dictionary, end: Dictionary, hold: Dictionary = {}) -> void:
	if undo_button == null:
		return
	undo_button.disabled = not bool(undo.get("enabled", false))
	undo_button.text = "Z"
	undo_button.tooltip_text = ("Undo the last die (%s)" % KeyBindings.text(KeyBindings.COMBAT_UNDO)) if not undo_button.disabled else "Nothing to undo this turn"
	var n := int(reroll.get("n", 0))
	var mx := int(reroll.get("max", 0))
	var cost := int(reroll.get("cost", 0))   # mana for the NEXT reroll once the free charges are gone (3.5)
	var nm := "%d/%d" % [n, mx] if mx > 0 else str(n)
	reroll_button.disabled = not bool(reroll.get("enabled", false))
	if n > 0:
		reroll_button.text = "Reroll %s" % nm
	elif cost > 0 and not bool(reroll.get("capped", false)):
		reroll_button.text = "Reroll %d MP" % cost if not reroll_button.disabled else "Need %d MP" % cost
	else:
		reroll_button.text = "No rerolls"
	reroll_button.tooltip_text = String(reroll.get("tip", "Reroll unused dice (%s)" % KeyBindings.text(KeyBindings.COMBAT_REROLL)))
	_hold_wanted = bool(hold.get("show", false))
	hold_button.disabled = not bool(hold.get("enabled", false))
	hold_button.text = String(hold.get("text", "Hold"))
	hold_button.tooltip_text = String(hold.get("tip", ""))
	end_turn_button.disabled = not bool(end.get("enabled", true))
	var resolving := end_turn_button.disabled and bool(end.get("resolving", false))
	end_turn_button.text = "Enemy turn" if resolving else "End turn"
	_hint.text = ("%s · skip" % KeyBindings.text(KeyBindings.COMBAT_END_TURN)) if resolving else String(end.get("sub", ""))
	layout()


## Show the 1x / 2x / Skip control while a resolve plays.
func set_resolving(v: bool) -> void:
	_speed.visible = v
	layout()


func speed_buttons() -> Array[Button]:
	return _speed_buttons


func skip_button() -> Button:
	return _skip_button


## Bottom of the screen the tray/right zone hang from.
func tray_top() -> float:
	return _tray_top


func layout() -> void:
	if not is_inside_tree():
		return
	var w := size.x
	var h := size.y
	if w <= 1.0:
		var vs := get_viewport_rect().size
		w = vs.x
		h = vs.y
	_top_plate.size = Vector2.ZERO
	_top_plate.position = Vector2(EDGE, TOP)
	_relic_plate.size = Vector2.ZERO
	_relic_plate.position = Vector2(EDGE, TOP + _top_plate.get_combined_minimum_size().y + 8.0)
	var rel_bottom := _relic_plate.position.y + _relic_plate.get_combined_minimum_size().y \
		if _relic_plate.visible else TOP + _top_plate.get_combined_minimum_size().y
	_attr_card.size = Vector2.ZERO
	_attr_card.position = Vector2(EDGE, rel_bottom + 8.0)
	if undo_button != null:
		var x := w - EDGE - RIGHT_W
		var y := h - EDGE - HINT_H
		_hint.position = Vector2(x, y)
		_hint.size = Vector2(RIGHT_W, HINT_H)
		y -= 6.0 + END_H
		end_turn_button.position = Vector2(x, y)
		end_turn_button.size = Vector2(RIGHT_W, END_H)
		y -= GAP + SMALL_H
		undo_button.position = Vector2(x, y)
		undo_button.size = Vector2(UNDO_W, SMALL_H)
		reroll_button.position = Vector2(x + UNDO_W + GAP, y)
		reroll_button.size = Vector2(RIGHT_W - UNDO_W - GAP, SMALL_H)
		y -= GAP + SMALL_H
		hold_button.position = Vector2(x, y)
		hold_button.size = Vector2(RIGHT_W, SMALL_H)
		_tray_top = y
		hold_button.visible = _hold_wanted and not _speed.visible
		# Undo is hidden while input is locked: the speed control takes the slot.
		undo_button.visible = not _speed.visible
		reroll_button.visible = not _speed.visible
		_speed.position = undo_button.position
		_speed.size = Vector2(RIGHT_W, SMALL_H)
	if _log_plate != null:
		var ltop := (_attr_card.position.y + _attr_card.get_combined_minimum_size().y) if _attr_card.visible else rel_bottom
		_foe_card.size = Vector2.ZERO
		_foe_card.position = Vector2(EDGE, ltop + 8.0)
		if _foe_card.visible:
			ltop = _foe_card.position.y + _foe_card.get_combined_minimum_size().y
		_log_plate.size = Vector2(INFO_W, LOG_H)
		_log_plate.position = Vector2(EDGE, ltop + 8.0)
	_info.size = Vector2.ZERO
	var ih := _info.get_combined_minimum_size().y
	_info.size = Vector2(INFO_W, ih)
	var ib := _info_bottom if _info_bottom > 0.0 else h - EDGE - 104.0 - 12.0
	_info.position = Vector2(EDGE, ib - ih)
