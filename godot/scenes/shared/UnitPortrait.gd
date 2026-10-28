extends Control
class_name UnitPortrait
## Per-unit combat overlay — Dice UI R1 (design/handoffs/ui-02-round1b README §3).
##
## ENEMY: the nameplate. 320 wide (boss 640), r16, border 3 (4 when lit), built in code:
##   left  : name (Baloo 18, + ELITE/BOSS tag) · HP bar (h24, boss h30 with phase marks) ·
##           chips row (h26: shield, statuses, "+N") with "-> target" right-aligned
##   right : INTENT block 88 wide (boss 128): "NEXT" 12 · icon 26 + number Baloo 30 (boss 44) ·
##           action label 12. `#DDBF8C`, gold `#FFC445` when enrage is active.
##   under : counter TAB (spike or boss clock) overlapping the plate by 4, h32, side inset 14.
##   below : one transient chip (illegal-target reason / damage preview / lethal).
## The intent number is the ONLY number the player needs: base x (1+enrage%+attrition%) x spike,
## computed by the engine (`hud_state().enemy_next`), never summed here.
##
## PARTY: no UI above heads (README §3 "Party"). A party UnitPortrait still exists because the
## damage numbers rise from it and CombatView positions it at the Axie, but it draws nothing and
## takes no mouse; party HP lives only in the dice tray.
##
## Public API kept from the pre-R1 file so CombatView keeps compiling: setup, set_incoming,
## update_stats, set_selected, set_targetable, set_preview_damage, clear_preview_damage,
## spawn_float_text, flash_resonance, play_death_fade, signals clicked / inspect_requested.

signal clicked(uid: int)
signal inspect_requested(uid: int)
## Pointer entered/left the plate (`on_intent` = the intent block specifically): drives the damage preview.
signal hover_changed(uid: int, hovering: bool, on_intent: bool)

const WIDTH := 320.0
const BOSS_WIDTH := 480.0
const ENEMY_HEIGHT := 98.0          ## plate only; tab + chip hang below it
const BOSS_HEIGHT := 140.0
const INTENT_W := 88.0
const BOSS_INTENT_W := 120.0
const TAB_H := 32.0
## The vertical slot an enemy column reserves (plate + tab overlap + chip row).
const SLOT_HEIGHT := ENEMY_HEIGHT + TAB_H - 4.0 + 6.0 + 40.0

const _STATUS_ICON := {
	"poison": preload("res://assets/icons/web/poison.png"),
	"burn": preload("res://assets/icons/web/burn.png"),
	"regen": preload("res://assets/icons/web/regen.png"),
	"blind": preload("res://assets/icons/web/blind.png"),
	"weaken": preload("res://assets/icons/web/weaken.png"),
	"vulnerable": preload("res://assets/icons/web/vuln.png"),
	"thorns": preload("res://assets/icons/web/thorns.png"),
	"stun": preload("res://assets/icons/web/stun.png"),
	"undying": preload("res://assets/icons/web/undying.png"),
	"freeze": preload("res://assets/icons/web/freeze.png"),
	"enrage": preload("res://assets/icons/web/enrage.png"),
}

## Float text. R1: numerals over the scene = Baloo, cream/tint fill, dark 8-way outline; party
## damage is Baloo 52 `#FFD0C0` with a 3px outline.
const _FLOAT_COLOR := {
	"dmg": Color("FFD0C0"), "heal": Color("D6F0C2"), "shd": Color("CFE7F7"),
	"poi": Color("DDF2C4"), "buf": Color("F2E0FF"), "deb": Color("FFE3A6"),
	"man": Color("F2E0FF"),
}
const _FLOAT_RISE := 48.0
const _FLOAT_RISE_REDUCED := 24.0
const _FLOAT_DURATION := 0.7
const _RESONANCE_FLASH_COLOR := Color(1.6, 1.6, 0.8)
const _RESONANCE_FLASH_IN := 0.12
const _RESONANCE_FLASH_OUT := 0.18
const _DEATH_FADE_DURATION := 0.45

var uid: int = -1
var _is_enemy := false
var _is_boss := false
var _dying := false
var _incoming := 0
var _hp := 0
var _max_hp := 1

var _plate: PanelContainer
var _plate_style: StyleBoxFlat
var _name_label: Label
var _tag_chip: PanelContainer
var _tag_label: Label
var _hp_bar: HPBar
var _hp_label: Label
var _phase_label: Label
var _target_label: Label
var _intent_panel: PanelContainer
var _intent_style: StyleBoxFlat
var _intent_next: Label
var _intent_icon: TextureRect
var _intent_num: Label
var _intent_action: Label
var _tab: PanelContainer
var _tab_style: StyleBoxFlat
var _tab_icon: TextureRect
var _tab_text: Label
var _tab_right: Label
var _tab_pips: HBoxContainer
var _chip: PanelContainer
var _chip_style: StyleBoxFlat
var _chip_icon: TextureRect
var _chip_text: Label
var _click_catcher: Button
var _leader_badge: PanelContainer
var _nick := ""
var _orig_name := ""
var _shell_row: Control
var _shell_bar: HPBar
var _shell_label: Label

var _lit := false          # legal target / selected
var _acting := false
var _lethal := false
var _illegal_reason := ""
var _boosted := false
var _preview := 0


## Lane GM (Name Tag meme Core): a nickname (custom_state.nick) replaces the nameplate text; the original name moves
## into the plate tooltip. nick "" restores the original.
func set_nick(nick: String, original: String) -> void:
	_nick = nick
	_orig_name = original
	_refresh_name()


## Name text: the nickname if any. "Elite X" drops its "Elite " (the ELITE chip says it) while that chip shows.
## Then 20 -> 18 px so a long name is not clipped; the full name is always in the tooltip.
func _refresh_name() -> void:
	if _name_label == null:
		return
	var full := _nick if _nick != "" else _orig_name
	var txt := full
	var chip_elite := _tag_chip != null and _tag_chip.visible and _tag_label.text == "ELITE"
	if chip_elite and txt.begins_with("Elite ") and _nick == "":
		txt = txt.substr(6)
	_name_label.text = txt
	var base := 24 if _is_boss else 20
	var avail := (BOSS_WIDTH - 22.0 - BOSS_INTENT_W - 70.0) if _is_boss else (WIDTH - 22.0 - INTENT_W - 70.0)
	var f := _name_label.get_theme_font("font")
	var fs := base
	if f != null and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs = 18
	_name_label.add_theme_font_size_override("font_size", fs)
	if _click_catcher != null:
		UI3Tooltip.bind(_click_catcher, full if (_nick != "" or txt != full) else "")
		if _nick != "":
			UI3Tooltip.bind(_click_catcher, "%s (%s)" % [_nick, _orig_name])


func _ready() -> void:
	pass


## Called once per unit when a combat starts (CombatView._spawn_portrait).
func setup(p_uid: int, display_name: String, _cls: String, is_enemy: bool, is_boss: bool = false,
		tag: String = "") -> void:
	uid = p_uid
	_is_enemy = is_enemy
	_is_boss = is_boss
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not is_enemy:
		# No UI above Axie heads. Size 0: it is only the anchor damage numbers rise from.
		custom_minimum_size = Vector2(1, 1)
		size = Vector2(1, 1)
		return
	var w := BOSS_WIDTH if is_boss else WIDTH
	var plate_h := BOSS_HEIGHT if is_boss else ENEMY_HEIGHT
	theme = UI3Theme.get_theme()
	custom_minimum_size = Vector2(w, plate_h + SLOT_HEIGHT - ENEMY_HEIGHT)
	size = custom_minimum_size

	# --- click catcher goes FIRST (behind chips so chip tooltips still pick) ---
	_click_catcher = Button.new()
	_click_catcher.flat = true
	_click_catcher.focus_mode = Control.FOCUS_NONE
	_click_catcher.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_click_catcher.position = Vector2.ZERO
	_click_catcher.custom_minimum_size = Vector2(w, plate_h)
	_click_catcher.size = Vector2(w, plate_h)
	_click_catcher.pressed.connect(func(): clicked.emit(uid))
	_click_catcher.gui_input.connect(_on_click_catcher_gui_input)
	_click_catcher.mouse_entered.connect(func(): hover_changed.emit(uid, true, false))
	_click_catcher.mouse_exited.connect(func(): hover_changed.emit(uid, false, false))
	add_child(_click_catcher)

	# --- plate (UI-03: wood-1 plate, wood-2 intent block; lit = 4 px cream outline) ---
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.position = Vector2.ZERO
	_plate.custom_minimum_size = Vector2(w, plate_h)
	_plate.size = Vector2(w, plate_h)
	_plate_style = _make_plate_style(0)
	_plate.add_theme_stylebox_override("panel", _plate_style)
	_plate.z_index = 2
	add_child(_plate)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	_plate.add_child(row)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	var lm := MarginContainer.new()
	lm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lm.add_theme_constant_override("margin_left", 12)
	lm.add_theme_constant_override("margin_right", 10)
	lm.add_theme_constant_override("margin_top", 6)
	lm.add_theme_constant_override("margin_bottom", 6)
	lm.add_child(left)
	row.add_child(lm)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 6)
	left.add_child(name_row)
	_name_label = UI3.label(display_name, "LabelDisplay")
	_name_label.add_theme_font_size_override("font_size", 24 if is_boss else 20)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_row.add_child(_name_label)
	_tag_chip = UI3.plate(&"info")
	_tag_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tag_label = UI3.label(tag, "LabelDisplay")
	_tag_label.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key_hint"))
	_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_chip.add_child(_tag_label)
	_tag_chip.visible = tag != ""
	_hp_label = UI3.label("", "LabelDisplay")
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_hp_label)

	_hp_bar = HPBar.new()
	_hp_bar.ui3_look = true
	_hp_bar.set_kind(HPBar.Kind.ENEMY, 16 if is_boss else 8, 4, 16)
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_boss:
		_hp_bar.set_marks([0.66, 0.33])
	left.add_child(_hp_bar)

	# --- Resonance Shell (anti-spam B): glyph + bar + number, hidden until the engine reports a Shell ---
	_shell_row = Control.new()
	_shell_row.name = "ShellRow"
	_shell_row.custom_minimum_size = Vector2(0, 16)
	_shell_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_shell_row.gui_input.connect(_on_forward_gui_input)
	_shell_row.visible = false
	var sic := TextureRect.new()
	sic.name = "Icon"
	sic.texture = UI3.icon("face_shield")
	sic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sic.position = Vector2.ZERO
	sic.size = Vector2(16, 16)
	sic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell_row.add_child(sic)
	_shell_bar = HPBar.new()
	_shell_bar.name = "ShellBar"
	_shell_bar.use_fixed_fill(UI3Theme.color("shell"))
	_shell_bar.set_kind(HPBar.Kind.SHIELD, 8, 4, 16)
	_shell_bar.use_fixed_fill(UI3Theme.color("shell"))
	_shell_bar.custom_minimum_size.x = 0.0   # HPBar defaults to 96 wide: it would sit under the label
	_shell_bar.anchor_right = 1.0
	_shell_bar.offset_left = 22.0
	_shell_bar.offset_right = -138.0
	_shell_bar.offset_top = 4.0
	_shell_bar.offset_bottom = 12.0
	_shell_row.add_child(_shell_bar)
	_shell_label = UI3.label("", "LabelDisplay")
	_shell_label.name = "ShellText"
	_shell_label.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	_shell_label.add_theme_color_override("font_color", UI3Theme.color("shell"))
	_shell_label.anchor_left = 1.0
	_shell_label.anchor_right = 1.0
	_shell_label.offset_left = -134.0
	_shell_label.offset_right = 0.0
	_shell_label.offset_top = -4.0
	_shell_label.offset_bottom = 20.0
	_shell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shell_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell_row.add_child(_shell_label)
	UI3Tooltip.bind(_shell_row, TranslationServer.translate("Shell: dice outside a SET deal 50% to Shell. Break it to reach the HP."))
	left.add_child(_shell_row)

	if is_boss:
		_phase_label = UI3.label("Phase 1 of 2", "LabelMuted")
		_phase_label.visible = false   # set_phase() shows it for multi-phase bosses
		_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left.add_child(_phase_label)

	var chips_row := HBoxContainer.new()
	chips_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_row.custom_minimum_size = Vector2(0, UI3.CHIP_H)
	chips_row.clip_contents = true
	chips_row.add_theme_constant_override("separation", 4)
	left.add_child(chips_row)
	chips_row.add_child(_tag_chip)   # ELITE / BOSS tag sits under the name so a long name keeps its full width
	_leader_badge = UI3.mini_badge("LEADER", UI3.icon("node_elite"), UI3Theme.color("leader"), "LeaderBadge")
	_leader_badge.gui_input.connect(_on_forward_gui_input)
	_leader_badge.visible = false
	UI3Tooltip.bind(_leader_badge, TranslationServer.translate("Pack Alpha: while it lives, single-target hits on other enemies deal 50%. Kill it first."))
	chips_row.add_child(_leader_badge)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips_row.add_child(spacer)
	_target_label = UI3.label("", "LabelMuted")
	_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_label.clip_text = true   # min width 0: a long "→ Name" never widens the plate (the intent column stays on screen)
	_target_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chips_row.add_child(_target_label)

	# --- intent block (IntentBadge: wood-2, left border in the kind colour) ---
	var iw := BOSS_INTENT_W if is_boss else INTENT_W
	_intent_panel = PanelContainer.new()
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_STOP   # hover = preview + tooltip; clicks are forwarded
	_intent_panel.gui_input.connect(_on_forward_gui_input)
	_intent_panel.custom_minimum_size = Vector2(iw, 0)
	_intent_style = UI3Theme.flat(UI3Theme.color("panel_raised"), 0, 0)
	_intent_style.border_width_left = 4
	_intent_style.border_color = UI3Theme.color("intent_buff")
	_intent_style.corner_radius_top_right = UI3Theme.radius("m")
	_intent_style.corner_radius_bottom_right = UI3Theme.radius("m")
	_intent_panel.add_theme_stylebox_override("panel", _intent_style)
	_intent_panel.mouse_entered.connect(func(): hover_changed.emit(uid, true, true))
	_intent_panel.mouse_exited.connect(func(): hover_changed.emit(uid, false, true))
	row.add_child(_intent_panel)
	var ic := VBoxContainer.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.alignment = BoxContainer.ALIGNMENT_CENTER
	ic.add_theme_constant_override("separation", 0)
	_intent_panel.add_child(ic)
	_intent_next = UI3.label("Next", "LabelMuted")
	_intent_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(_intent_next)
	var num_row := HBoxContainer.new()
	num_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num_row.alignment = BoxContainer.ALIGNMENT_CENTER
	num_row.add_theme_constant_override("separation", 4)
	ic.add_child(num_row)
	_intent_icon = HudKit.tex_rect(null, 28 if is_boss else 24)
	num_row.add_child(_intent_icon)
	_intent_num = UI3.label("", "LabelDisplay")
	_intent_num.add_theme_font_size_override("font_size", 32 if is_boss else 28)
	_intent_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num_row.add_child(_intent_num)
	_intent_action = UI3.label("", "LabelMuted")
	_intent_action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(_intent_action)

	# --- counter tab ---
	_tab = PanelContainer.new()
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab.position = Vector2(14, plate_h - 4)
	_tab.custom_minimum_size = Vector2(w - 28, TAB_H)
	_tab.size = Vector2(w - 28, TAB_H)
	_tab.z_index = 1
	if is_boss:
		_tab.custom_minimum_size = Vector2(0, TAB_H)   # the boss clock (ENRAGE IN n) lives INSIDE the plate
	_tab_style = UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("m"))
	if not is_boss:
		_tab_style.corner_radius_top_left = 0
		_tab_style.corner_radius_top_right = 0
	_tab_style.content_margin_left = 10.0
	_tab_style.content_margin_right = 10.0
	_tab_style.content_margin_top = 4.0
	_tab_style.content_margin_bottom = 2.0
	_tab.add_theme_stylebox_override("panel", _tab_style)
	var trow := HBoxContainer.new()
	trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_theme_constant_override("separation", 6)
	_tab.add_child(trow)
	_tab_icon = HudKit.tex_rect(null, 20)
	trow.add_child(_tab_icon)
	_tab_text = UI3.label("", "LabelDisplay")
	_tab_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(_tab_text)
	var tsp := Control.new()
	tsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(tsp)
	_tab_pips = HBoxContainer.new()
	_tab_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_pips.add_theme_constant_override("separation", 3)
	_tab_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(_tab_pips)
	_tab_right = UI3.label("", "LabelMuted")
	_tab_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(_tab_right)
	_tab.visible = false
	if is_boss:
		left.add_child(_tab)
	else:
		add_child(_tab)

	# --- transient label under the tab: "Target · Name" (cream), reason (red-2), damage preview ---
	_chip = PanelContainer.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.z_index = 1
	_chip_style = UI3Theme.flat(UI3Theme.color("text"), UI3Theme.radius("m"))
	_chip_style.content_margin_left = 10.0
	_chip_style.content_margin_right = 12.0
	_chip_style.content_margin_top = 2.0
	_chip_style.content_margin_bottom = 2.0
	_chip.add_theme_stylebox_override("panel", _chip_style)
	var crow := HBoxContainer.new()
	crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_theme_constant_override("separation", 6)
	_chip.add_child(crow)
	_chip_icon = HudKit.tex_rect(null, 20)
	crow.add_child(_chip_icon)
	_chip_text = UI3.label("")
	_chip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(_chip_text)
	_chip.visible = false
	add_child(_chip)
	_refresh_plate()
	if is_boss:
		_fit_boss.call_deferred()


func _make_plate_style(border_w: int) -> StyleBoxFlat:
	var sb := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("m"), border_w, UI3Theme.color("selected_outline"))
	return sb


## Boss plate hugs its content (name, bar, phase, statuses, ENRAGE line): resize the plate, the click area
## and this slot to match.
func _fit_boss() -> void:
	if not _is_boss or _plate == null:
		return
	_plate.reset_size()
	var ph := maxf(_plate.get_combined_minimum_size().y, ENEMY_HEIGHT)
	_plate.size = Vector2(_plate.size.x, ph)
	_click_catcher.size = Vector2(_plate.size.x, ph)
	custom_minimum_size.y = ph + 6.0 + 40.0
	size = Vector2(size.x, custom_minimum_size.y)
	_place_chip()


## Height this card takes in the enemy column, including whatever hangs under the plate right now
## (counter tab for non-bosses, Target / reason / preview label).
func stack_height() -> float:
	if _plate == null:
		return 0.0
	var h := _plate.size.y
	if not _is_boss and _tab != null and _tab.visible:
		h += TAB_H - 4.0
	if _chip != null and _chip.visible:
		h += 6.0 + _chip.get_combined_minimum_size().y
	return h


func _refresh_plate() -> void:
	if _plate_style == null:
		return
	var bw := 4 if (_lit or _acting or _lethal) else 0
	_plate_style.set_border_width_all(bw)
	_plate_style.border_color = UI3Theme.color("danger_text") if _lethal else UI3Theme.color("selected_outline")
	if not _dying:
		modulate.a = 0.6 if _illegal_reason != "" else 1.0
	_place_chip()


func _place_chip() -> void:
	if _chip == null:
		return
	var txt := _chip_text.text
	_chip.visible = txt != ""
	var top := (_tab.position.y + TAB_H + 6.0) if (_tab.visible and not _is_boss) \
		else (_plate.size.y + 6.0)
	_chip.size = Vector2.ZERO
	_chip.position = Vector2((size.x - _chip.get_combined_minimum_size().x) * 0.5, top)


# ── State pushed by CombatView ───────────────────────────────────────────────────────────────

## CB-11 / CB-12 compat: committed incoming damage. Party plates draw nothing, so only stored.
func set_incoming(amount: int) -> void:
	_incoming = maxi(amount, 0)


## Pack Alpha: shows the LEADER badge (glyph + word) under the name.
func set_leader(on: bool) -> void:
	if _leader_badge != null:
		_leader_badge.visible = on
		# LEADER replaces the ELITE chip (the fight already says Elite): ELITE + LEADER + "-> name" does not fit the plate.
		if _tag_chip != null:
			_tag_chip.visible = (not on) and _tag_label.text != ""
		_refresh_name()


## Resonance Shell: bar + "cur / max"; hidden when max <= 0 (feature off, or no Shell on this unit).
func set_shell(cur: int, max_v: int) -> void:
	if _shell_row == null:
		return
	_shell_row.visible = max_v > 0
	if max_v <= 0:
		return
	_shell_bar.set_stats(maxi(cur, 0), max_v)
	_shell_label.text = "SHELL %d/%d" % [maxi(cur, 0), max_v]
	_shell_row.set_meta("shell_text", _shell_label.text)


func has_shell() -> bool:
	return _shell_row != null and _shell_row.visible


func is_leader() -> bool:
	return _leader_badge != null and _leader_badge.visible


## The "single read-model entry point": HP, shield, statuses.
func update_stats(hp: int, max_hp: int, shield: int, status: Dictionary) -> void:
	_hp = hp
	_max_hp = maxi(max_hp, 1)
	if not _is_enemy or _hp_bar == null:
		return
	_hp_bar.set_stats(hp, _max_hp)
	_hp_label.text = "%d / %d" % [maxi(hp, 0), _max_hp]
	if hp > 0:
		_dying = false
		visible = true
		modulate.a = 1.0 if _illegal_reason == "" else 0.6
	elif not _dying:
		modulate.a = 0.0
		visible = false


## Name + intent block + target. `intent` = {show:bool, type:String, num:int, label:String,
## target:String, boosted:bool}. `show=false` renders "NO MOVE".
func set_intent(intent: Dictionary) -> void:
	if not _is_enemy or _intent_panel == null:
		return
	_boosted = bool(intent.get("boosted", false))
	_intent_style.border_color = UI3Theme.color("accent") if _boosted \
		else UI3.intent_color(String(intent.get("type", "")))
	var big := bool(intent.get("big_hit", false))
	if big:
		_intent_style.border_color = UI3Theme.color("danger_text")
	_intent_next.text = ("! " + TranslationServer.translate("Next")) if big else TranslationServer.translate("Next")
	_intent_next.add_theme_color_override("font_color", UI3Theme.color("danger_text") if big else UI3Theme.color("text_muted"))
	_intent_num.add_theme_color_override("font_color", UI3Theme.color("danger_text") if big else UI3Theme.color("text"))
	if not bool(intent.get("show", false)):
		_intent_icon.texture = UI3.icon("face_blank")
		_intent_num.text = "-"
		_intent_action.text = "NO MOVE"
		_target_label.text = ""
		return
	_intent_icon.texture = UI3.icon(String(UI3.FACE_ICON.get(TrayColumn.ui3_face(String(intent.get("type", "blank"))), "face_blank")))
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if CombatLabels.is_blank_intent(String(intent.get("type", ""))):
		_intent_num.text = "-"
		_intent_action.text = "IDLE"
		_target_label.text = ""
		UI3Tooltip.bind(_intent_panel, "Does nothing this turn.")
		return
	# UI3 plate, not the native tooltip: a native one is an OS-level popup that no overlay can cover (BUG-0005).
	UI3Tooltip.bind(_intent_panel, ("Can knock out an Axie.\n" if big else "") + "Next: %s %d%s\nEnemy intent is public: this is the number that lands, with enrage, attrition and big hits already included." % [
		String(intent.get("label", "")), int(intent.get("num", 0)),
		(" on " + String(intent.get("target", ""))) if String(intent.get("target", "")) != "" else ""])
	_intent_num.text = str(int(intent.get("num", 0)))
	_intent_action.text = "ACTING" if _acting else String(intent.get("label", ""))
	var tgt := String(intent.get("target", ""))
	_target_label.text = "%s %s" % [HudKit.arrow(), tgt] if tgt != "" else ""


## Boss phase line (e.g. "Phase 1 of 2"). One-phase bosses hide it (Liam 20/10); the 66/33 HP bar
## marks are ticks, not phases.
func set_phase(phase: int, total: int = 1) -> void:
	if _phase_label != null:
		_phase_label.visible = total > 1
		_phase_label.text = "Phase %d of %d" % [phase, total]


## The counter tab. spec: {} hides it. Else {kind:"spike"|"clock", bg, ink, text, right, pips:[Color],
## icon}. Built by HudKit.clock_tab() / CombatView for spikes.
func set_tab(spec: Dictionary) -> void:
	if _tab == null:
		return
	if spec.is_empty():
		_tab.visible = false
		if _is_boss:
			_fit_boss.call_deferred()
		_place_chip()
		return
	_tab.visible = true
	if _is_boss:
		_fit_boss.call_deferred()
	_tab_icon.texture = spec.get("icon", null)
	_tab_text.text = String(spec.get("text", ""))
	_tab_right.text = String(spec.get("right", ""))
	for c in _tab_pips.get_children():
		_tab_pips.remove_child(c)
		c.queue_free()
	for col in spec.get("pips", []):
		var pip := PanelContainer.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.custom_minimum_size = Vector2(9, 14)
		pip.add_theme_stylebox_override("panel", HudKit.box(col, 3, 2))
		_tab_pips.add_child(pip)
	_place_chip()


## Plate lit (legal target / selected).
func set_selected(v: bool) -> void:
	_lit = v
	_refresh_plate()


## View-only "legal target" affordance (gold plate border; the ground ring is Stage3D's).
func set_targetable(v: bool) -> void:
	_lit = v
	_restore_chip()
	_refresh_plate()


## The resting label under a legal target: "Target · Name" (cream fill, wood-1 text). A reason or a damage
## preview replaces it while they last.
func _restore_chip() -> void:
	if _chip_text == null or _preview > 0 or _illegal_reason != "":
		return
	if _lit and _name_label != null:
		_show_chip("%s %s %s" % [TranslationServer.translate("Target"), HudKit.dot(), _name_label.text],
			UI3Theme.color("text"), UI3Theme.color("die_ink"), null)
	else:
		_hide_chip()


## Illegal target: plate at 60% + reason chip (dusk + lock). "" clears.
## `show_chip` false: still dimmed + untargetable, but the reason line is left to ONE sibling (CombatView shows it on
## the first living unit of the side), so four foes do not repeat the same strip.
func set_illegal(reason: String, show_chip := true) -> void:
	_illegal_reason = reason
	if _chip_text == null:
		return
	if reason != "" and not show_chip:
		_hide_chip()
	elif reason != "":
		_show_chip(reason, UI3Theme.color("danger_bg"), UI3Theme.color("text"), UI3.icon("ui_lock"))
	else:
		_hide_chip()
		_restore_chip()
	_refresh_plate()


func set_acting(v: bool) -> void:
	_acting = v
	_refresh_plate()


## Damage preview from a hovered/selected die: gold hatched HP segment + chip "-12 | 38 > 26",
## or, if it kills, THREAT border, HP text "11 / 70 > 0" and the gold WILL DIE chip (the big-hit
## tab stays visible).
func set_preview_damage(dmg: int) -> void:
	_preview = dmg
	if _hp_bar == null:
		return
	_hp_bar.set_preview(dmg)
	if dmg <= 0:
		clear_preview_damage()
		return
	var after := maxi(_hp - dmg, 0)
	_lethal = _hp > 0 and dmg >= _hp
	if _lethal:
		_hp_bar.set_lethal_text("%d / %d %s 0" % [_hp, _max_hp, HudKit.arrow()])
		_show_chip("Will die %s %s%d" % [HudKit.dot(), HudKit.minus(), dmg], UI3Theme.color("danger_bg"),
			UI3Theme.color("text"), UI3.icon("face_dmg"))
	else:
		_hp_bar.set_lethal_text("")
		_show_chip("%s%d %s %d %s %d" % [HudKit.minus(), dmg, HudKit.dot(), _hp, HudKit.arrow(),
			after], UI3Theme.color("text"), UI3Theme.color("die_ink"), UI3.icon("face_dmg"))
	_hp_label.text = _hp_bar.shown_text()
	_refresh_plate()


func clear_preview_damage() -> void:
	_preview = 0
	_lethal = false
	if _hp_bar != null:
		_hp_bar.clear_preview()
		_hp_label.text = _hp_bar.shown_text()
	if _illegal_reason == "":
		_hide_chip()
		_restore_chip()
	_refresh_plate()


func _show_chip(text: String, fill: Color, ink: Color, icon_tex: Texture2D) -> void:
	_chip_style.bg_color = fill
	_chip_text.text = text
	_chip_text.add_theme_color_override("font_color", ink)
	_chip_icon.texture = icon_tex
	_chip_icon.visible = icon_tex != null
	_place_chip()


func _hide_chip() -> void:
	if _chip_text != null:
		_chip_text.text = ""
		_place_chip()


## Shown HP text, for tests ("34 / 52").
func shown_hp_text() -> String:
	return _hp_bar.shown_text() if _hp_bar != null else ""


## "Poison 3" + the rule, off the ONE rule-book (CodexContent).
static func _effect_tooltip(key: String, count: int) -> String:
	if key == "shield":
		return "Shield %d\nAbsorbs damage before HP." % count
	var tip: Dictionary = CodexContent.status_tip(key)
	if tip.is_empty():
		return "%s %d" % [key.to_upper(), count]
	var label := String(tip["name"]).trim_suffix(" N")
	return "%s %d\n%s" % [label, count, String(tip["rule"])]


## The intent block and the status chips sit on top of the click catcher, so they hand clicks back.
func _on_forward_gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	match (ev as InputEventMouseButton).button_index:
		MOUSE_BUTTON_LEFT:
			clicked.emit(uid)
			accept_event()
		MOUSE_BUTTON_RIGHT:
			inspect_requested.emit(uid)
			accept_event()


func _on_click_catcher_gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(uid)
		accept_event()


# ═══ Juice ═══════════════════════════════════════════════════════════════════════════════════

func spawn_float_text(text: String, css_class: String, big: int) -> void:
	if CombatView.disable_juice_for_tests or not is_inside_tree():
		return
	var lbl := UI3.float_text(text, css_class, clampi(big, 0, 2))
	lbl.z_index = 5
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(size.x * 0.5 - 20.0 + randf_range(-10.0, 10.0), -18.0)
	add_child(lbl)
	var rise := _FLOAT_RISE_REDUCED if CombatView.motion_suppressed() else _FLOAT_RISE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - rise, _FLOAT_DURATION)
	tw.tween_property(lbl, "modulate:a", 0.0, _FLOAT_DURATION)
	tw.chain().tween_callback(lbl.queue_free)


func flash_resonance() -> void:
	if CombatView.flashes_suppressed() or not is_inside_tree():
		return
	var base := modulate
	var flash := _RESONANCE_FLASH_COLOR
	flash.a = base.a
	var tw := create_tween()
	tw.tween_property(self, "modulate", flash, _RESONANCE_FLASH_IN)
	tw.tween_property(self, "modulate", base, _RESONANCE_FLASH_OUT)


func play_death_fade() -> void:
	if _dying or not is_inside_tree():
		return
	_dying = true
	if CombatView.disable_juice_for_tests:
		modulate.a = 0.0
		visible = false
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, _DEATH_FADE_DURATION)
	tw.finished.connect(func(): visible = false)
