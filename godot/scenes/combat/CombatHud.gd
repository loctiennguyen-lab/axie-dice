extends Control
class_name CombatHud
## Combat HUD shell (UI-05 batch 1, lane A; design/handoffs/ui-05-figma/round-1/ui05-combat-screens.html, style A):
## RunInfo top-left, the ActionDock bottom-right (ToolKeys · Reroll · End turn · StatusLine), plus the left column
## kept from UI-04 (Anchor chip, Core plate, attrition card, boss rhythm, battle log, die info panel). Pure view: it
## is told what to show (`update_*`) and reports clicks (signals). It never reads or writes game state; CombatView
## owns that.
##
## Only one key is drawn on screen: Space on End turn (Liam 28/10). Every other shortcut still works (CombatView
## reads KeyBindings) and is named in its button's tooltip.
##
## Layout is relationships, not mockup y values (godot/CLAUDE.md rule 2): the top HUD hangs from y 0, the docks hang
## from the bottom edge. Every size is a token read through UI3Theme (1280 text floor included); `layout()` runs on
## every resize and re-reads the tokens when the window scale changed.

signal menu_pressed
signal ascension_pressed
signal active_pressed(relic_id: String)
signal overcast_pressed   ## Overcast button (CombatView turns it into the `overcast` action)
signal wild_pressed   ## depth v4 Wild face button (CombatView opens the pick)
signal hold_pressed   ## depth v3 3.2: the Hold button (CombatView turns it into the `stash` action)

const TOP := 24.0
const EDGE := 24.0
const INFO_W := 288.0

const WAITING_TEXT := "Waiting for the server"   ## StatusLine while a seed request is in flight (approved string)
const WAITING_END := "Waiting…"                  ## End turn label meanwhile
const ENEMY_TEXT := "Enemies are acting"         ## StatusLine during the enemy turn
const PICK_TEXT := "Pick a target"               ## StatusLine while a die is picked

var core_panel: CorePanel            ## depth v3: 6 Core slots + Run rule slot + quest chips
var relic_strip: HBoxContainer      ## kept as a public name: tests hover relic chips here
var actives_row: HBoxContainer

var _run_info: Ui5RunInfo           ## RunInfo (MenuButton + RunPill)
var _top_plate: Control             ## = _run_info (left-column layout and tests read its rect)
var _anchor_chip: PanelContainer
var _relic_plate: PanelContainer
var _divider: Control
var _mana_box: HBoxContainer
var _mana_holder: Control
var _attr_card: PanelContainer
var _attr_title: Label
var _attr_pips: HBoxContainer
var _attr_dashed := false
var _attr_right_pos := Vector2(-1.0, -1.0)
var _info: PanelContainer           ## die info panel (288 w, wood-2), only while a die is picked
var _info_title: Label
var _info_body: Label
var _info_bottom := -1.0
var _log_plate: PanelContainer      ## battle log, top-left column under the attrition card
const LOG_H := 176.0

## ActionDock (bottom-right, no plate behind it in style A): VBox(ToolKeys, RerollButton, EndTurnButton, StatusLine).
## The Undo / Reroll / End turn buttons are owned by the scene (%UndoButton etc. keep their names for the tests and
## the tutorial); CombatView hands them over via `adopt_right_zone()`.
var _dock: VBoxContainer
var _tools: HBoxContainer           ## ToolKeys
var _tool_keys: Array[Ui5ToolKey] = []
var _cost_chip: PanelContainer      ## CostChip inside Reroll (paid reroll price)
signal wait_dim_changed(on: bool)
var _wait_dim := false
var _resolving := false
var _dim_tweens: Array[Tween] = []
var _dim_timer_gen := 0   ## bumps on every set_seed_wait: a stale 300 ms dim timer checks it and does nothing
var undo_button: Button
var reroll_button: Button
var end_turn_button: Button
var overcast_button: Button        ## Overcast (lane OC), owned here
var _overcast_wanted := true
var wild_button: Button             ## depth v4 Wild face (stage >= 2)
var _wild_wanted := false
var _seed_wait := false
var _hint_before_wait := ""
var _end_before_wait := ""
var hold_button: Button             ## depth v3 Hold, owned here (no scene node)
var _hint: Label                    ## StatusLine
var _end_cap: PanelContainer      # the one key cap on screen: Space on End turn
var _end_cap_label: Label
var _hold_wanted := true
var _foe_card: PanelContainer       ## boss rhythm (3 chips) and / or the Elite affix chip, left column
var _foe_rows: VBoxContainer

var _newcomer := false
var _tray_top := 0.0
var _scale_seen := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI3Theme.get_theme()
	_build_top()
	_build_attrition()
	_build_foe_card()
	_build_info()
	resized.connect(layout)


# ── Top HUD: RunInfo, Anchor chip and the Core plate under it ───────────────────────────────

func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_top() -> void:
	_run_info = Ui5RunInfo.new()
	_top_plate = _run_info
	_run_info.menu_button.tooltip_text = "%s (%s)" % [TranslationServer.translate("Menu"), KeyBindings.text(KeyBindings.MENU_BACK)]
	_run_info.menu_button.pressed.connect(func(): menu_pressed.emit())
	add_child(_run_info)

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
	core_panel.show_counts = true   # lane VZ: "xN" activations this fight on each Core slot
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
	# AttritionCard (UI-04): 416 x 56 plate, attrition glyph 28, ONE Rowdies 18 line in the attrition colour, 3 pips
	# before it starts. Dashed edge before start, solid while running, red edge + red text at MAX.
	_attr_card = UI3.plate(&"plate")
	_attr_card.custom_minimum_size = Vector2(UI3Theme.size_of("attrition_w"), UI3Theme.size_of("attrition_h"))
	_attr_card.mouse_filter = Control.MOUSE_FILTER_STOP   # hover = attrition tooltip
	add_child(_attr_card)
	_attr_card.draw.connect(_draw_attr_edge)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	_attr_card.add_child(row)
	var ic := TextureRect.new()
	ic.texture = HudKit.icon("attrition")
	ic.custom_minimum_size = Vector2(28, 28)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	_attr_title = UI3.label("", "LabelDisplay")
	_attr_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attr_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_attr_title.add_theme_color_override("font_color", UI3Theme.color("attrition"))
	_ignore(_attr_title)
	row.add_child(_attr_title)
	_attr_pips = HBoxContainer.new()
	_attr_pips.name = "Pips"
	_attr_pips.add_theme_constant_override("separation", 4)
	_attr_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ignore(_attr_pips)
	row.add_child(_attr_pips)


## Dashed edge while the attrition has not started (a StyleBox cannot dash).
func _draw_attr_edge() -> void:
	if not _attr_dashed:
		return
	var r := Rect2(Vector2.ZERO, _attr_card.size).grow(-1.0)
	var col := UI3Theme.color("attrition")
	var tl := r.position
	var tr := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	for seg in [[tl + Vector2(12, 0), tr - Vector2(12, 0)], [tr + Vector2(0, 12), br - Vector2(0, 12)],
			[bl + Vector2(12, 0), br - Vector2(12, 0)], [tl + Vector2(0, 12), bl - Vector2(0, 12)]]:
		_attr_card.draw_dashed_line(seg[0], seg[1], col, 2.0, 8.0)


# ── BossRhythm (UI-05 b1 lane A, 02-combat--boss: CSS .boss-rhythm): plate under RunInfo (top = screen margin +
## run_pill_h + space_20), padding 12 16, gap 8: "BOSS RHYTHM" · the 3 steps · the tell line. Also hosts the Elite
## affix chip and the plating coach line (depth v3 6.3 / 6.4), which have no UI-05 frame of their own.

const _PHASES := ["prep", "strike", "hollow"]
const _PHASE_WORD := {"prep": "Prep", "strike": "Strike", "hollow": "Hollow"}


func _build_foe_card() -> void:
	_foe_card = PanelContainer.new()
	_foe_card.name = "BossRhythm"
	_foe_card.theme = UI3Theme.get_theme()
	_foe_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foe_card.visible = false
	_foe_card.add_to_group("ui3_tip_avoid")
	add_child(_foe_card)
	_foe_rows = VBoxContainer.new()
	_foe_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foe_card.add_child(_foe_rows)


## Dashed rounded-ish border for a Control (StyleBoxFlat cannot dash): drawn on its `draw` signal.
func _dashed(c: Control, col: Color) -> void:
	c.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, c.size).grow(-1.0)
		var tl := r.position
		var tr := Vector2(r.end.x, r.position.y)
		var br := r.end
		var bl := Vector2(r.position.x, r.end.y)
		for seg in [[tl + Vector2(10, 0), tr - Vector2(10, 0)], [tr + Vector2(0, 10), br - Vector2(0, 10)],
				[bl + Vector2(10, 0), br - Vector2(10, 0)], [tl + Vector2(0, 10), bl - Vector2(0, 10)]]:
			c.draw_dashed_line(seg[0], seg[1], col, 2.0, 8.0))


func update_foe(d: Dictionary) -> void:
	for c in _foe_rows.get_children():
		_foe_rows.remove_child(c)
		c.queue_free()
	_foe_card.add_theme_stylebox_override("panel", Ui5HudStyle.plate_box(UI3Theme.radius("l"),
		Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12"))))
	_foe_rows.add_theme_constant_override("separation", UI3Theme.space("8"))
	var r: Dictionary = d.get("rhythm", {})
	var a: Dictionary = d.get("affix", {})
	var coach := String(d.get("coach", ""))
	_foe_card.visible = not r.is_empty() or not a.is_empty() or coach != ""
	var wraps: Array[Label] = []
	if coach != "":
		var cl := UI3.label(coach, "LabelMuted")
		cl.name = "CoachPlating"
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wraps.append(cl)
		_foe_rows.add_child(cl)
	if not a.is_empty():
		var row := HBoxContainer.new()
		row.name = "AffixRow"
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_theme_constant_override("separation", UI3Theme.space("8"))
		var ic := Ui5HudStyle.icon_rect(UI3.icon("node_elite"), UI3Theme.size_of("icon_m"))
		row.add_child(ic)
		var l := UI3.label(String(a.get("name", "")), "LabelDisplay")
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		if String(a.get("note", "")) != "":
			var n := UI3.label(String(a["note"]), "LabelMuted")
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(n)
		UI3Tooltip.bind(row, String(a.get("tip", "")))
		_foe_rows.add_child(row)
	if not r.is_empty():
		var title := UI3.label("BOSS RHYTHM", "LabelDisplay")
		title.name = "Title"
		title.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_foe_rows.add_child(title)
		var chips := HBoxContainer.new()
		chips.name = "RhythmChips"
		chips.mouse_filter = Control.MOUSE_FILTER_PASS
		chips.add_theme_constant_override("separation", UI3Theme.space("8"))
		for ph in _PHASES:
			var is_now: bool = String(r.get("phase", "")) == ph
			var is_next: bool = String(r.get("next", "")) == ph and not is_now
			# CSS .rhythm-step: btn_s high, 0 16 padding, radius m, plate_raised. Now = cream fill, ink text; next = 2 px
			# dashed accent edge and a muted "next".
			var p := PanelContainer.new()
			p.name = "Phase_" + ph
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_s"))
			p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("text" if is_now else "plate_raised"),
				UI3Theme.radius("m"), 0, Color.TRANSPARENT, Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0)))
			if is_next:
				_dashed(p, UI3Theme.color("accent"))
			var cc := HBoxContainer.new()
			cc.alignment = BoxContainer.ALIGNMENT_CENTER
			cc.add_theme_constant_override("separation", UI3Theme.space("8"))
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(cc)
			var l2 := UI3.label(TranslationServer.translate(String(_PHASE_WORD[ph])), "LabelDisplay")
			l2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if is_now:
				l2.add_theme_color_override("font_color", UI3Theme.color("text_ink"))
			l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cc.add_child(l2)
			if is_next:
				var nl := UI3.label(TranslationServer.translate("next"), "LabelMuted")
				nl.name = "NextTag"
				nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cc.add_child(nl)
			chips.add_child(p)
		UI3Tooltip.bind(chips, "Boss rhythm: 3-turn cycle. Prep, then Strike (its strongest face), then Hollow (it takes +30% from damage faces and deals -30%). The chip tagged Next is the phase that comes next.")
		_foe_rows.add_child(chips)
		var tell := UI3.label(String(r.get("tell", "")), "")
		tell.name = "Tell"
		tell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wraps.append(tell)
		_foe_rows.add_child(tell)
	# Wrapped lines take the width of the widest fixed row (the 3 steps, the affix row); alone, the attrition card's.
	var wrap_w := 0.0
	for c in _foe_rows.get_children():
		if not (c is Label):
			wrap_w = maxf(wrap_w, (c as Control).get_combined_minimum_size().x)
	if wrap_w <= 0.0:
		wrap_w = float(UI3Theme.size_of("attrition_w"))
	for l3 in wraps:
		l3.custom_minimum_size.x = wrap_w
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
	text.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	text.add_theme_color_override("default_color", UI3Theme.color("text"))
	_log_plate.add_child(text)
	layout()
	return _log_plate


func adopt_right_zone(undo: Button, reroll: Button, end_turn: Button) -> void:
	undo_button = undo
	reroll_button = reroll
	end_turn_button = end_turn
	_dock = VBoxContainer.new()
	_dock.name = "ActionDock"
	_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock.add_to_group("ui3_tip_avoid")
	add_child(_dock)
	_tools = HBoxContainer.new()
	_tools.name = "ToolKeys"
	_tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock.add_child(_tools)
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
	# ToolKeys, in the HTML order: Undo · Hold · Wild · Overcast.
	undo.text = "Undo"
	hold_button = Button.new()
	hold_button.name = "HoldButton"
	hold_button.text = "Hold"
	hold_button.pressed.connect(func(): hold_pressed.emit())
	wild_button = Button.new()
	wild_button.name = "WildButton"
	wild_button.text = "Wild"
	wild_button.pressed.connect(func(): wild_pressed.emit())
	overcast_button = Button.new()
	overcast_button.name = "OvercastButton"
	overcast_button.text = "Overcast"
	overcast_button.pressed.connect(func(): overcast_pressed.emit())
	for spec in [["UndoKey", undo, &"undo", "Undo"], ["HoldKey", hold_button, &"hold", "Hold"],
			["WildKey", wild_button, &"wild", "Wild"], ["OvercastKey", overcast_button, &"overcast", "Overcast"]]:
		var k := Ui5ToolKey.new(spec[0], spec[1], spec[2], TranslationServer.translate(spec[3]))
		_tools.add_child(k)
		_tool_keys.append(k)
	# RerollButton: secondary M, Rowdies title, reroll glyph, CostChip (mana) when the next reroll is paid.
	reroll.theme_type_variation = "ButtonSecondary"
	reroll.text = "Reroll"
	reroll.icon = UI3.cream_icon("ui_reroll")
	reroll.expand_icon = false
	reroll.clip_text = true
	reroll.tooltip_text = "Reroll unused dice (%s)" % KeyBindings.text(KeyBindings.COMBAT_REROLL)
	_cost_chip = Ui5HudStyle.cost_chip(&"mana", 1)
	_cost_chip.visible = false
	reroll.add_child(_cost_chip)
	_dock.add_child(reroll)
	# EndTurnButton: the one amber primary, Rowdies screen title, the one key cap on screen (Space).
	end_turn.theme_type_variation = "ButtonPrimaryL"
	end_turn.text = "End turn"
	end_turn.clip_text = true
	end_turn.tooltip_text = "End turn (%s)" % KeyBindings.text(KeyBindings.COMBAT_END_TURN)
	_end_cap = Ui5Keycap.make(KeyBindings.text(KeyBindings.COMBAT_END_TURN), &"primary")
	_end_cap.name = "EndKeyCap"
	_end_cap_label = _end_cap.get_node("Key") as Label
	end_turn.add_child(_end_cap)
	_dock.add_child(end_turn)
	# StatusLine: one Work Sans body line on the 3D view, centred.
	_hint = UI3.label("", "")
	_hint.name = "StatusLine"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui5HudStyle.on_view(_hint)
	_dock.add_child(_hint)
	_apply_tokens()
	layout()


## Every size / font token of the HUD shell, re-read after a window-scale change (UI3Theme rebuilds the shared
## Theme in place; overrides set here have to be set again).
func _apply_tokens() -> void:
	_scale_seen = UI3Theme.current_scale()
	if _run_info != null:
		_run_info.refresh_tokens()
	if _dock == null:
		return
	var dock_w := float(UI3Theme.size_of("action_dock_w"))
	_dock.custom_minimum_size = Vector2(dock_w, 0)
	_dock.add_theme_constant_override("separation", UI3Theme.space("16"))
	var key_w := floorf((dock_w - 3.0 * UI3Theme.space("16")) / 4.0)   # CSS .tool-key width 76 at 1920
	for k in _tool_keys:
		k.refresh_tokens(key_w)
	reroll_button.custom_minimum_size = Vector2(dock_w, UI3Theme.size_of("btn_m"))
	reroll_button.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	reroll_button.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_m"))
	reroll_button.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	end_turn_button.custom_minimum_size = Vector2(dock_w, UI3Theme.size_of("btn_l"))
	end_turn_button.add_theme_font_size_override("font_size", UI3Theme.size_of("text_screen_title"))
	Ui5Keycap.refresh(_end_cap)
	_cost_chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	(_cost_chip.find_child("Icon", true, false) as Control).custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_s")
	_hint.custom_minimum_size = Vector2(dock_w, 0)


## ToolKeys row: only the unlocked tools take a slot. Each key is (dock - 3 gaps) / 4 wide unless its word needs
## more (Overcast at the 1280 text floor); the gap shrinks from space_16 to fit, keys pack from the left.
func _layout_tools() -> void:
	var dock_w := float(UI3Theme.size_of("action_dock_w"))
	var key_w := floorf((dock_w - 3.0 * UI3Theme.space("16")) / 4.0)
	var vis: Array[Ui5ToolKey] = []
	var total := 0.0
	for k in _tool_keys:
		if k.button.visible:
			vis.append(k)
			var kw := maxf(key_w, k.natural_width())
			k.custom_minimum_size.x = kw
			total += kw
	var gap := float(UI3Theme.space("16"))
	if vis.size() > 1:
		gap = clampf(floorf((dock_w - total) / float(vis.size() - 1)), 0.0, gap)
	_tools.add_theme_constant_override("separation", int(gap))
	_tools.visible = not vis.is_empty()


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
	_run_info.set_info(String(d.get("title", "")), int(d.get("ascension", 0)), int(d.get("turn", 1)), int(d.get("shards", 0)))
	_refresh_anchor_chip()
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
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
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
	badge.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(34, 26)
	b.add_child(badge)
	var rid := String(a.get("id", ""))
	b.pressed.connect(func(): active_pressed.emit(rid))
	return b


## Attrition card. state = hud_state().attrition; turn; hidden for newcomers. Build strings only:
## "ATTRITION · TURN N" (before), "ATTRITION +N%" (running), "ATTRITION +N% · MAX" (cap).
func update_attrition(state: Dictionary, turn: int, newcomer: bool) -> void:
	_newcomer = newcomer
	_attr_card.visible = (not newcomer) and CombatLabels.attrition_visible(state, turn)   # only a few turns before it starts
	_attr_card.add_to_group("ui3_tip_avoid")
	UI3Tooltip.bind(_attr_card, "Attrition: from turn %d every enemy hits 5%% harder each turn, up to +25%%. Long fights get dangerous, so finish them. It resets every fight." % int(state.get("start_turn", 6)))
	if newcomer:
		return
	var pct := int(state.get("pct", 0))
	var start := int(state.get("start_turn", 6))
	var maxed := pct >= 25
	var running := pct > 0
	var col := UI3Theme.color("danger_text" if maxed else "attrition")
	if not running:
		_attr_title.text = "ATTRITION %s TURN %d" % [HudKit.dot(), start]
	elif maxed:
		_attr_title.text = "ATTRITION +%d%% %s MAX" % [pct, HudKit.dot()]
	else:
		_attr_title.text = "ATTRITION +%d%%" % pct
	_attr_title.add_theme_color_override("font_color", col)
	_attr_dashed = not running
	var sb := (_attr_card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	sb.set_border_width_all(0 if _attr_dashed else 2)
	sb.border_color = col
	_attr_card.add_theme_stylebox_override("panel", sb)
	for c in _attr_pips.get_children():
		_attr_pips.remove_child(c)
		c.queue_free()
	if not running:   # 3 pips only before start: 4 - N turns to go filled
		var filled := clampi(4 - (start - turn), 0, 3)
		for i in 3:
			var d := Panel.new()
			d.custom_minimum_size = Vector2(14, 14)
			d.add_theme_stylebox_override("panel", UI3Theme.flat(col if i < filled else Color.TRANSPARENT, 7, 2, col))
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_attr_pips.add_child(d)
	_attr_card.queue_redraw()


## CombatView puts the card under the enemy plates (right column); Vector2(-1, -1) = default left column.
func place_attrition(pos: Vector2) -> void:
	_attr_right_pos = pos
	layout()


## ActionDock texts + enabled states. Disabled buttons say why (UI3 rule).
## undo: {enabled, sub}  reroll: {n, max, cost, tip, stakes, capped, enabled}
## end: {sub, warn, enabled, resolving, picked}  hold / overcast / wild: {show, enabled, text, tip[, on]}
## StatusLine (HTML frames): Waiting for the server > Enemies are acting > Pick a target > Reroll: need N MP > sub.
func update_right(undo: Dictionary, reroll: Dictionary, end: Dictionary, hold: Dictionary = {}, overcast: Dictionary = {}, wild: Dictionary = {}) -> void:
	if undo_button == null:
		return
	undo_button.disabled = not bool(undo.get("enabled", false))
	undo_button.text = "Undo"   # not drawn: the key shows the Undo glyph and word
	undo_button.tooltip_text = ("Undo the last die (%s)" % KeyBindings.text(KeyBindings.COMBAT_UNDO)) if not undo_button.disabled else ("Nothing to undo this turn (%s)" % KeyBindings.text(KeyBindings.COMBAT_UNDO))
	var n := int(reroll.get("n", 0))
	var mx := int(reroll.get("max", 0))
	var cost := int(reroll.get("cost", 0))   # mana for the NEXT reroll once the free charges are gone (3.5)
	var capped := bool(reroll.get("capped", false))
	var nm := "%d/%d" % [n, mx] if mx > 0 else str(n)
	reroll_button.disabled = not bool(reroll.get("enabled", false))
	var need_mp := n <= 0 and cost > 0 and not capped and reroll_button.disabled and not bool(end.get("resolving", false))
	var show_cost := false
	if n > 0:
		reroll_button.text = "Reroll %s" % nm
	elif cost > 0 and not capped:
		# Paid reroll: "Reroll" + the mana CostChip; short of mana: the reason, no glyph, no chip (aid-offer frame).
		reroll_button.text = "Reroll · need %d MP" % cost if need_mp else "Reroll"
		show_cost = not need_mp
	else:
		reroll_button.text = "No rerolls"
	var stakes := int(reroll.get("stakes", 0))
	if stakes > 0 and n <= 0 and cost <= 0 and not capped:
		reroll_button.text = "Gamble · Crack %d%%" % stakes   # High Stakes forces every paid reroll to be a Gamble
	reroll_button.icon = null if need_mp else UI3.cream_icon("ui_reroll")
	_cost_chip.visible = show_cost
	Ui5HudStyle.set_cost(_cost_chip, cost)
	reroll_button.tooltip_text = String(reroll.get("tip", "Reroll unused dice (%s)" % KeyBindings.text(KeyBindings.COMBAT_REROLL)))
	_overcast_wanted = bool(overcast.get("show", false))
	overcast_button.disabled = not bool(overcast.get("enabled", false))
	overcast_button.text = String(overcast.get("text", "Overcast"))
	overcast_button.tooltip_text = String(overcast.get("tip", ""))
	_wild_wanted = bool(wild.get("show", false))
	wild_button.disabled = not bool(wild.get("enabled", false))
	wild_button.text = String(wild.get("text", "Wild"))
	wild_button.tooltip_text = String(wild.get("tip", ""))
	_hold_wanted = bool(hold.get("show", false))
	var hold_on := bool(hold.get("on", false))
	hold_button.disabled = not bool(hold.get("enabled", false)) and not hold_on   # "on" = a pressed-in toggle, not disabled
	hold_button.text = String(hold.get("text", "Hold"))
	_tool_key_of(hold_button).set_on(hold_on)
	hold_button.tooltip_text = String(hold.get("tip", ""))
	end_turn_button.disabled = not bool(end.get("enabled", true))
	var resolving := end_turn_button.disabled and bool(end.get("resolving", false))
	end_turn_button.text = "Enemy turn" if resolving else "End turn"
	end_turn_button.tooltip_text = ("Skip the animation (%s)" if resolving else "End turn (%s)") % KeyBindings.text(KeyBindings.COMBAT_END_TURN)
	for k in _tool_keys:
		k.ensure_style()
		k.sync_dim()
	if resolving:
		_hint.text = TranslationServer.translate(ENEMY_TEXT)
	elif bool(end.get("picked", false)):
		_hint.text = TranslationServer.translate(PICK_TEXT)
	elif need_mp:
		_hint.text = TranslationServer.translate("Reroll: need %d MP") % cost
	else:
		_hint.text = String(end.get("sub", ""))
	_end_cap_label.text = KeyBindings.text(KeyBindings.COMBAT_END_TURN)
	_apply_seed_wait()
	_sync_end_cap()
	layout()


func _tool_key_of(b: Button) -> Ui5ToolKey:
	for k in _tool_keys:
		if k.button == b:
			return k
	return null


## Space stays on End turn in every state (Space also skips the enemy turn); its look follows the button.
func _sync_end_cap() -> void:
	if _end_cap == null:
		return
	var v: StringName = &"disabled" if end_turn_button.disabled else &"primary"
	if _end_cap.get_meta("variant", &"") != v:
		Ui5Keycap.set_variant(_end_cap, v)


## A seed request is in flight: grey every dice action and say why on the StatusLine, so the HUD does not look hung.
## The real guard stays `_combat.epoch_pending` in CombatView.
func set_seed_wait(on: bool) -> void:
	if on == _seed_wait or undo_button == null:
		_seed_wait = on
		return
	_seed_wait = on
	_dim_timer_gen += 1
	if on:
		_apply_seed_wait()
		_sync_end_cap()
		layout()
		# Waiting state (motion `waiting_server`): the tools dim only after 300 ms, so a quick answer never flickers.
		if is_inside_tree():
			var gen := _dim_timer_gen
			get_tree().create_timer(0.3).timeout.connect(func() -> void:
				if _seed_wait and gen == _dim_timer_gen:
					_set_dim(true))
	else:
		_hint.text = _hint_before_wait   # the next update_right() refreshes everything else
		end_turn_button.text = _end_before_wait if _end_before_wait != "" else end_turn_button.text
		_set_dim(false)


## Waiting (02-combat--waiting): the ToolKeys row drops to 0.4; Reroll and End turn are disabled-styled, not faded.
## 120 ms fade, instant when reduced.
func _set_dim(on: bool) -> void:
	if on == _wait_dim or undo_button == null:
		return
	_wait_dim = on
	wait_dim_changed.emit(on)
	_fade_tools(true)


## ToolKeys alpha: 0.4 while waiting or during the enemy turn (HTML .dim), else 1.
func _fade_tools(animate: bool) -> void:
	if _tools == null:
		return
	for old in _dim_tweens:   # a flip within the 120 ms fade must not leave two tweens fighting over alpha
		if old != null and old.is_valid():
			old.kill()
	_dim_tweens.clear()
	var a := 0.4 if (_wait_dim or _resolving) else 1.0
	if not animate or UI3Motion.reduced() or not is_inside_tree():
		_tools.modulate.a = a
		return
	var tw := create_tween()
	tw.tween_property(_tools, "modulate:a", a, 0.12)
	_dim_tweens.append(tw)


func _apply_seed_wait() -> void:
	if not _seed_wait:
		return
	if _hint.text != TranslationServer.translate(WAITING_TEXT):
		_hint_before_wait = _hint.text
	if end_turn_button.text != TranslationServer.translate(WAITING_END):
		_end_before_wait = end_turn_button.text
	for b in [undo_button, reroll_button, end_turn_button, hold_button, overcast_button, wild_button]:
		if b != null:
			b.disabled = true
	_hint.text = TranslationServer.translate(WAITING_TEXT)
	end_turn_button.text = TranslationServer.translate(WAITING_END)


## The enemy turn is playing (02-combat--enemy-turn): ToolKeys at 0.4. Space on End turn skips it.
func set_resolving(v: bool) -> void:
	if v == _resolving:
		return
	_resolving = v
	_fade_tools(false)
	layout()


## Bottom of the screen the tray/right zone hang from.
func tray_top() -> float:
	return _tray_top


## Anchor chip (under the run plate): shared HouseChip, 48 high; pips fill per House Core held, word "Awakened" at 2/2.
func _refresh_anchor_chip() -> void:
	var key := "%s/%s/%d" % [AnchorAdapter.current_id(), AnchorAdapter.awakened(), AnchorAdapter.house_count()]
	if _anchor_chip != null and is_instance_valid(_anchor_chip) and String(_anchor_chip.get_meta("key", "")) == key:
		return
	if _anchor_chip != null and is_instance_valid(_anchor_chip):
		_anchor_chip.get_parent().remove_child(_anchor_chip)
		_anchor_chip.queue_free()
	_anchor_chip = null
	if not AnchorAdapter.has_anchor():
		layout()
		return
	var house := AnchorAdapter.house_id(AnchorAdapter.current_id())
	var hk := StringName(house.trim_prefix("h_"))
	var awake := AnchorAdapter.awakened()
	var n := AnchorAdapter.house_count()
	var chip := UI3.house_chip(hk, AnchorAdapter.house_name(house), mini(n, 2), 2, awake, UI3Theme.size_of("anchor_chip_h"))
	chip.name = "AnchorChip"
	chip.set_meta("key", key)
	var txt := chip.find_child("Text", true, false) as Label
	txt.add_theme_color_override("font_color", UI3Theme.color("anchor_awake") if awake else AnchorAdapter.house_color(house))
	var more := UI3.label(TranslationServer.translate("Awakened") if awake else "%s %d/2" % [TranslationServer.translate("House Cores"), mini(n, 2)], "LabelMuted")
	more.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.get_parent().add_child(more)
	add_child(chip)
	_anchor_chip = chip
	layout()


func layout() -> void:
	if not is_inside_tree():
		return
	var w := size.x
	var h := size.y
	if w <= 1.0:
		var vs := get_viewport_rect().size
		w = vs.x
		h = vs.y
	if not is_equal_approx(UI3Theme.current_scale(), _scale_seen):
		_apply_tokens()   # the window scale moved (1280 text floor): every token override is read again
	_top_plate.size = Vector2.ZERO
	_top_plate.position = Vector2(UI3Theme.space("screen"), UI3Theme.space("screen"))
	# Left column, top to bottom: RunInfo (run_pill_h) · 20 · BossRhythm (boss / elite) · 16 · Anchor chip (48) · Cores plate
	# · attrition (when not in the enemy column) · log.
	var col_bottom := _top_plate.position.y + _top_plate.get_combined_minimum_size().y
	_foe_card.size = Vector2.ZERO
	_foe_card.position = Vector2(UI3Theme.space("screen"), col_bottom + UI3Theme.space("20"))   # CSS .boss-rhythm top
	if _foe_card.visible:
		col_bottom = _foe_card.position.y + _foe_card.get_combined_minimum_size().y
	if _anchor_chip != null and is_instance_valid(_anchor_chip):
		_anchor_chip.size = Vector2.ZERO
		_anchor_chip.position = Vector2(EDGE, col_bottom + 16.0)
		col_bottom = _anchor_chip.position.y + _anchor_chip.get_combined_minimum_size().y
	_relic_plate.size = Vector2.ZERO
	_relic_plate.position = Vector2(EDGE, col_bottom + 8.0)
	var rel_bottom := _relic_plate.position.y + _relic_plate.get_combined_minimum_size().y \
		if _relic_plate.visible else col_bottom
	_attr_card.size = Vector2.ZERO
	if _attr_right_pos.x >= 0.0:
		_attr_card.position = _attr_right_pos
		_attr_card.size = Vector2(UI3Theme.size_of("attrition_w"), UI3Theme.size_of("attrition_h"))
	else:
		_attr_card.position = Vector2(EDGE, rel_bottom + 8.0)
	if _dock != null:
		# ActionDock (02-combat frames): bottom-right at the screen margin, action_dock_w wide, gap space_16:
		# ToolKeys (tool_key + word) · Reroll btn_m · End turn btn_l · StatusLine. No plate behind it (style A).
		var edge := float(UI3Theme.space("screen"))
		var dock_w := float(UI3Theme.size_of("action_dock_w"))
		overcast_button.visible = _overcast_wanted
		wild_button.visible = _wild_wanted
		hold_button.visible = _hold_wanted
		_layout_tools()
		reroll_button.size = Vector2(dock_w, UI3Theme.size_of("btn_m"))
		end_turn_button.size = Vector2(dock_w, UI3Theme.size_of("btn_l"))
		Ui5HudStyle.place_trailing(reroll_button, _cost_chip, UI3Theme.space("24"))
		Ui5HudStyle.place_trailing(end_turn_button, _end_cap, UI3Theme.space("32"))
		_dock.size = Vector2.ZERO
		var dm := _dock.get_combined_minimum_size()
		_dock.size = Vector2(dock_w, dm.y)
		_dock.position = Vector2(w - edge - dock_w, h - edge - dm.y)
		_tray_top = _dock.position.y
		# A tall enemy column (boss + 4-5 enemies) pushes the Attrition card down behind the ActionDock: keep it above.
		if _attr_right_pos.x >= 0.0 and _attr_card.visible:
			var max_y := _tray_top - 8.0 - UI3Theme.size_of("attrition_h")
			if _attr_card.position.y > max_y:
				_attr_card.position.y = max_y
	if _log_plate != null:
		var ltop := rel_bottom
		if _attr_right_pos.x < 0.0 and _attr_card.visible:
			ltop = _attr_card.position.y + _attr_card.get_combined_minimum_size().y
		_log_plate.size = Vector2(INFO_W, LOG_H)
		_log_plate.position = Vector2(EDGE, ltop + 8.0)
	_info.size = Vector2.ZERO
	var ih := _info.get_combined_minimum_size().y
	_info.size = Vector2(INFO_W, ih)
	var ib := _info_bottom if _info_bottom > 0.0 else h - EDGE - 104.0 - 12.0
	_info.position = Vector2(EDGE, ib - ih)
