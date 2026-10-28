extends Control
class_name UnitPortrait
## Per-unit combat overlay. ENEMY: one EnemyCluster of the UI-05 EnemyColumn (lane C, UI-05 batch 1,
## design/handoffs/ui-05-figma/round-1 frames 02-combat--bighit / --boss / --ab-names / --attrition-*).
##
## ENEMY cluster, top to bottom, right-aligned, 8 apart (`.enemy-cluster`):
##   EnemyPlate (scenes/combat/ui5/EnemyPlate.gd, BossPlate.gd for a boss): name row, HP bar, intent column.
##   counter tab   : spike "BIG HIT IN n" (non-boss). A boss shows its clock as the EnrageRow inside the plate.
##   BigHitStrip   : "Can knock out an Axie" (ui5/BigHitStrip.gd) while the intent can knock out an Axie.
##   label         : "Target · Name" (cream), illegal-target reason, or the damage preview.
## Lit (legal target / selected): TargetRing, a 4 px `selected` outline 4 px outside the plate.
## Widths are tokens (enemy_card_w, boss_plate_w, enemy_intent_w); nothing here is a hardcoded px width.
## The intent number is the ONLY number the player needs, computed by the engine (`hud_state().enemy_next`).
##
## PARTY: no UI above heads. A party UnitPortrait still exists because the damage numbers rise from it and
## CombatView positions it at the Axie, but it draws nothing and takes no mouse; party HP lives in the dice tray.
##
## Public API kept so CombatView / EnemyColumn keep compiling: setup, set_incoming, update_stats, set_selected,
## set_targetable, set_preview_damage, clear_preview_damage, spawn_float_text, flash_resonance, play_death_fade,
## set_intent, set_tab, set_phase, set_leader, set_shell, set_nick, intent_block, stack_height, signals.

signal clicked(uid: int)
signal inspect_requested(uid: int)
## Pointer entered/left the plate (`on_intent` = the intent block specifically): drives the damage preview.
signal hover_changed(uid: int, hovering: bool, on_intent: bool)

## Name keeps at least this many px in its row; past that the tags move to their own row under it.
const MIN_NAME_W := 72.0


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

var _plate: EnemyPlate              ## EnemyPlate / BossPlate
var _ring: Panel                    ## TargetRing (lit)
var _name_label: Label              ## = _plate.name_label (tests read it)
var _suffix_chip: PanelContainer
var _bang: PanelContainer           ## BigHitBadge
var _tag_chip: PanelContainer       ## ELITE / BOSS EnemyTag
var _tag_kind := ""                 ## "ELITE" | "BOSS" | "" (the word the tag shows)
var _hp_bar: HPBar
var _hp_label: Label
var _phase_label: Label
var _intent_panel: IntentBlock      ## the plate's IntentBlock
var _intent_next: Label
var _intent_icon: TextureRect
var _intent_num: Label
var _intent_action: Label
var _strip: BigHitStrip
var _tab: PanelContainer            ## spike tab (non-boss) / EnrageRow (boss)
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
var _big_hit := false
var _illegal_reason := ""
var _boosted := false
var _preview := 0
var _fit_queued := false
var _compact := false      ## tall column: the BigHitStrip folds away (plate edge + "!" badge still say it)
var _built_scale := 1.0


## Plate width tokens (were the WIDTH 416 / BOSS_WIDTH 520 constants).
static func card_w() -> float:
	return float(EnemyPlate.card_width(false))


static func boss_w() -> float:
	return float(EnemyPlate.card_width(true))


## Lane GM (Name Tag meme Core): a nickname (custom_state.nick) replaces the nameplate text; the original name moves
## into the plate tooltip. nick "" restores the original.
func set_nick(nick: String, original: String) -> void:
	_nick = nick
	_orig_name = original
	_refresh_name()


## The whole name the player means ("Ravenling A", the nickname...). Chips and tooltips use this, not the shortened text.
func full_name() -> String:
	return _nick if _nick != "" else _orig_name


## Name text: the nickname if any. "Elite X" drops its "Elite " (the ELITE tag says it) while that tag shows.
## A repeated name's trailing " A" / " B" becomes a NameSuffix disc (max one letter). The tags stay in the name
## row while the name keeps MIN_NAME_W, else they get their own row. Boss name text_title, text_body when it does
## not fit. The name ellipsizes; the full name is always in the tooltip.
func _refresh_name() -> void:
	if _name_label == null:
		return
	var full := full_name()
	var txt := full
	var chip_elite := _tag_chip != null and _tag_chip.visible and _tag_kind == "ELITE"
	if chip_elite and txt.begins_with("Elite ") and _nick == "":
		txt = txt.substr(6)
	var suffix := ""
	if _nick == "" and txt.length() >= 3 and txt[txt.length() - 2] == " " and txt[txt.length() - 1] >= "A" and txt[txt.length() - 1] <= "Z":
		suffix = txt.substr(txt.length() - 1)
		txt = txt.substr(0, txt.length() - 2)
	if _is_boss:
		txt = UI3.title_case(txt)
	_name_label.text = txt
	if _suffix_chip != null:
		_suffix_chip.visible = suffix != ""
		if suffix != "":
			(_suffix_chip.get_node("Text") as Label).text = suffix
	_plate.place_tags(MIN_NAME_W)
	var key := "text_title" if _is_boss else "text_body"
	var avail := _name_avail()
	var f := UI3Theme.font_display()
	if _is_boss and f != null and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI3Theme.size_of(key)).x > avail:
		key = "text_body"
	EnemyPlate.set_text_size(_name_label, key, true, 1.2 if key == "text_title" else 1.3)
	var fs := UI3Theme.size_of(key)
	var cut := f != null and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail + 0.5
	if _click_catcher != null:
		if _nick != "":
			UI3Tooltip.bind(_click_catcher, "%s (%s)" % [_nick, _orig_name])
		else:
			UI3Tooltip.bind(_click_catcher, full if (cut or txt != full) else "")
	_queue_fit()


## Width the name label gets in its row: EnemyMain's inner width minus everything else visible in the row.
func _name_avail() -> float:
	var row := _plate.name_row
	var sep := float(row.get_theme_constant("separation"))
	var w := _plate.main_inner_width()
	var hp_min := -1.0
	for c in row.get_children():
		if c == _name_label or not (c as Control).visible:
			continue
		if c == _hp_label and (c as Control).size_flags_horizontal & Control.SIZE_EXPAND:
			hp_min = (c as Control).get_combined_minimum_size().x
			w -= sep
			continue
		w -= (c as Control).get_combined_minimum_size().x + sep
	if hp_min >= 0.0:   # name and HPValue both expand: halves, unless the HP text needs more than its half
		w = w - hp_min if hp_min > w * 0.5 else w * 0.5
	return maxf(w, 0.0)


func _ready() -> void:
	pass


## Called once per unit when a combat starts (EnemyColumn._spawn_portrait).
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
	_built_scale = UI3Theme.current_scale()
	theme = UI3Theme.get_theme()
	var w := boss_w() if is_boss else card_w()
	custom_minimum_size = Vector2(w, 0)
	size = Vector2(w, 0)

	# --- click catcher goes FIRST (behind the plate, so the intent / tags / shell row still pick) ---
	_click_catcher = Button.new()
	_click_catcher.name = "ClickCatcher"
	_click_catcher.flat = true
	_click_catcher.focus_mode = Control.FOCUS_NONE
	_click_catcher.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_click_catcher.position = Vector2.ZERO
	_click_catcher.pressed.connect(func(): clicked.emit(uid))
	_click_catcher.gui_input.connect(_on_click_catcher_gui_input)
	_click_catcher.mouse_entered.connect(func(): hover_changed.emit(uid, true, false))
	_click_catcher.mouse_exited.connect(func(): hover_changed.emit(uid, false, false))
	add_child(_click_catcher)

	# --- TargetRing: 4 px `selected` outline, 4 px outside the plate (`.target-ring`) ---
	_ring = Panel.new()
	_ring.name = "TargetRing"
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.visible = false
	_ring.z_index = 2
	add_child(_ring)

	# --- EnemyPlate / BossPlate ---
	_plate = BossPlate.new() if is_boss else EnemyPlate.new()
	_plate.position = Vector2.ZERO
	_plate.z_index = 2
	add_child(_plate)
	_name_label = _plate.name_label
	_name_label.text = display_name
	_suffix_chip = _plate.suffix
	_bang = _plate.badge
	_hp_bar = _plate.hp_bar
	_hp_label = _plate.hp_label
	_intent_panel = _plate.intent
	_intent_next = _intent_panel.next_label
	_intent_icon = _intent_panel.glyph
	_intent_num = _intent_panel.value_label
	_intent_action = _intent_panel.verb_label
	_intent_panel.gui_input.connect(_on_forward_gui_input)
	_intent_panel.mouse_entered.connect(func(): hover_changed.emit(uid, true, true))
	_intent_panel.mouse_exited.connect(func(): hover_changed.emit(uid, false, true))

	# EnemyTag(s): ELITE / BOSS from the fight, LEADER from the Pack Alpha rule (it replaces ELITE).
	_tag_kind = tag
	if tag != "":
		_tag_chip = EnemyPlate.tag(&"boss" if tag == "BOSS" else &"elite", tag)
		_plate.tag_box.add_child(_tag_chip)
	_leader_badge = EnemyPlate.tag(&"leader", "LEADER")
	_leader_badge.name = "LeaderBadge"
	_leader_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_leader_badge.gui_input.connect(_on_forward_gui_input)
	_leader_badge.visible = false
	UI3Tooltip.bind(_leader_badge, TranslationServer.translate("Pack Alpha: while it lives, single-target hits on other enemies deal 50%. Kill it first."))
	_plate.tag_box.add_child(_leader_badge)

	# --- Resonance Shell (anti-spam B): SHELL tag + bar + n/m, hidden until the engine reports a Shell ---
	_shell_row = _plate.shell_row
	_shell_bar = _plate.shell_bar
	_shell_label = _plate.shell_label
	_shell_row.gui_input.connect(_on_forward_gui_input)
	UI3Tooltip.bind(_shell_row, TranslationServer.translate("Shell: dice outside a SET deal 50% to Shell. Break it to reach the HP."))

	if is_boss:
		_phase_label = UI3.label("Phase 1 of 2", "LabelMuted")
		_phase_label.name = "PhaseLine"
		_phase_label.visible = false   # set_phase() shows it for multi-phase bosses
		_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- counter tab: non-boss = spike tab under the plate; boss = the EnrageRow inside the plate ---
	_build_tab()
	if is_boss:
		_plate.extra_box.add_child(_tab)
		_plate.extra_box.add_child(_phase_label)
	else:
		add_child(_tab)

	# --- BigHitStrip: under the plate, right-aligned ---
	_strip = BigHitStrip.new()
	_strip.visible = false
	_strip.z_index = 1
	add_child(_strip)

	# --- transient label: "Target · Name" (cream), reason (danger), damage preview ---
	_chip = PanelContainer.new()
	_chip.name = "PlateLabel"
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.z_index = 3   # over the next plate when the column is compact
	_chip_style = UI3Theme.flat(UI3Theme.color("text"), UI3Theme.radius("pill"))
	_chip.add_theme_stylebox_override("panel", _chip_style)
	var crow := HBoxContainer.new()
	crow.name = "Row"
	crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.add_child(crow)
	_chip_icon = TextureRect.new()
	_chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chip_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(_chip_icon)
	_chip_text = UI3.label("")
	_chip_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(_chip_text)
	_chip.visible = false
	add_child(_chip)
	_apply_own_sizes()
	_refresh_name()
	_refresh_plate()


func _build_tab() -> void:
	_tab = PanelContainer.new()
	_tab.name = "EnrageRow" if _is_boss else "CounterTab"
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab.z_index = 1
	_tab_style = UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("pill"))
	if _is_boss:   # EnrageRow: a plain row in the plate, no fill
		_tab_style.bg_color = Color.TRANSPARENT
	_tab.add_theme_stylebox_override("panel", _tab_style)
	var trow := HBoxContainer.new()
	trow.name = "Row"
	trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab.add_child(trow)
	_tab_icon = TextureRect.new()
	_tab_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tab_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tab_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tab_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(_tab_icon)
	_tab_text = UI3.label("", "LabelDisplay")
	_tab_text.name = "Text"
	_tab_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tab_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(_tab_text)
	_tab_pips = HBoxContainer.new()
	_tab_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_pips.add_theme_constant_override("separation", 3)
	_tab_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(_tab_pips)
	_tab_right = UI3.label("", "LabelMuted")
	_tab_right.name = "Right"
	_tab_right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tab_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(_tab_right)
	_tab.visible = false


## Token sizes of what UnitPortrait builds itself (the plate and strip size themselves).
func _apply_own_sizes() -> void:
	var sp8 := float(UI3Theme.space("8"))
	var sp12 := float(UI3Theme.space("12"))
	(_tab.get_node("Row") as HBoxContainer).add_theme_constant_override("separation", int(sp8))
	_tab_style.content_margin_left = 0.0 if _is_boss else sp12
	_tab_style.content_margin_right = 0.0 if _is_boss else sp12
	_tab.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h") if _is_boss else UI3Theme.size_of("status_chip_h"))
	var ic := UI3Theme.size_of("icon_m")
	_tab_icon.custom_minimum_size = Vector2(ic, ic)
	_tab_text.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	_tab_right.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	if _phase_label != null:
		_phase_label.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	_chip_style.content_margin_left = sp12
	_chip_style.content_margin_right = sp12
	_chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	(_chip.get_node("Row") as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("4"))
	var cs := UI3Theme.size_of("icon_s")
	_chip_icon.custom_minimum_size = Vector2(cs, cs)
	_chip_text.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	var w := boss_w() if _is_boss else card_w()
	custom_minimum_size.x = w
	size.x = w
	var ring := UI3Theme.selected_style(UI3Theme.radius("l") + 2 * UI3Theme.stroke("selected"), UI3Theme.stroke("selected"),
		UI3Theme.space("4") + UI3Theme.stroke("selected"))
	_ring.add_theme_stylebox_override("panel", ring)


## The window scale changed (1920 <-> 1280): re-read every size token. Cheap no-op otherwise; EnemyColumn calls it
## once per layout pass.
func sync_scale() -> void:
	if not _is_enemy or _plate == null:
		return
	var sc := UI3Theme.current_scale()
	if is_equal_approx(sc, _built_scale):
		return
	_built_scale = sc
	_plate.apply_sizes()
	_strip.apply_sizes()
	for t in [_tag_chip, _leader_badge]:
		if t != null:
			EnemyPlate.size_tag(t)
	_apply_own_sizes()
	_refresh_name()
	_refresh_plate()


## Plate, click area, ring and this cluster follow the content. Deferred once per frame so several state pushes
## cost one pass.
func _queue_fit() -> void:
	if _fit_queued or not _is_enemy or _plate == null:
		return
	_fit_queued = true
	_fit_plate.call_deferred()


func _fit_plate() -> void:
	_fit_queued = false
	if _plate == null or not is_instance_valid(_plate):
		return
	var w := boss_w() if _is_boss else card_w()
	_plate.reset_size()
	var ph := _plate.get_combined_minimum_size().y
	_plate.size = Vector2(w, ph)
	_click_catcher.size = Vector2(w, ph)
	_ring.position = Vector2.ZERO
	_ring.size = Vector2(w, ph)
	_place_hangers()


## Kept for callers/tests that fit the boss plate by name.
func _fit_boss() -> void:
	_fit_plate()


## Tall column: fold the BigHitStrip away (the plate edge and the "!" badge still mark the big hit). EnemyColumn.
func set_compact(on: bool) -> void:
	if _compact == on:
		return
	_compact = on
	_strip.visible = _big_hit and not on
	_place_hangers()


## Stacks the hanging items under the plate, right-aligned, 8 apart: counter tab, BigHitStrip, then the label.
## The label is transient (hover / target): in a compact column it floats over what is below instead of taking room.
func _place_hangers() -> void:
	if _plate == null or _chip == null:
		return
	var w := _plate.size.x if _plate.size.x > 0.0 else (boss_w() if _is_boss else card_w())
	var gap := float(UI3Theme.space("8"))
	var y := _plate.size.y
	var items: Array[Control] = []
	if not _is_boss:
		items.append(_tab)
	items.append(_strip)
	for c in items:
		if not c.visible:
			continue
		c.size = Vector2.ZERO
		var m := c.get_combined_minimum_size()
		c.size = Vector2(minf(m.x, w), m.y)
		c.position = Vector2(w - c.size.x, y + gap)
		y = c.position.y + c.size.y
	var body := y
	_chip.visible = _chip_text.text != ""
	if _chip.visible:
		_chip.size = Vector2.ZERO
		var cm := _chip.get_combined_minimum_size()
		_chip.size = Vector2(minf(cm.x, w), cm.y)
		_chip.position = Vector2(w - _chip.size.x, y + gap)
		if not _compact:
			y = _chip.position.y + _chip.size.y
	custom_minimum_size.y = y
	size = Vector2(w, y)
	if _compact:
		custom_minimum_size.y = body
		size = Vector2(w, body)


## Height this cluster takes in the enemy column: the plate and whatever hangs under it right now (the label only
## when not compact).
func stack_height() -> float:
	if _plate == null:
		return 0.0
	if _plate.size.y <= 0.0:
		_fit_plate()
	return size.y


## Height the cluster would take, without touching it: the plate, the counter tab, and (not compact) the
## BigHitStrip and the label. EnemyColumn uses it to decide whether the column must go compact.
func cluster_height(compact: bool) -> float:
	if _plate == null:
		return 0.0
	if _plate.size.y <= 0.0:
		_fit_plate()
	var gap := float(UI3Theme.space("8"))
	var h := _plate.size.y
	if not _is_boss and _tab.visible:
		h += gap + _tab.get_combined_minimum_size().y
	if _big_hit and not compact:
		h += gap + _strip.get_combined_minimum_size().y
	if not compact and _chip_text.text != "":
		h += gap + _chip.get_combined_minimum_size().y
	return h


## Plate edge: 4 px when acting / lethal preview / big hit, else the 2 px plate_rim bevel. Lit = the TargetRing.
func _refresh_plate() -> void:
	if _plate == null:
		return
	var thick := _acting or _lethal or _big_hit
	var col := UI3Theme.color("plate_rim")
	if _lethal:
		col = UI3Theme.color("danger_text")
	elif _acting:
		col = UI3Theme.color("selected_outline")
	elif _big_hit:
		col = UI3Theme.color("intent_bighit_border")
	_plate.set_border(UI3Theme.stroke("selected") if thick else UI3Theme.stroke("rim"), col)
	_ring.visible = _lit
	if not _dying:
		modulate.a = 0.6 if _illegal_reason != "" else 1.0
	_queue_fit()
	_place_hangers()


# ── State pushed by CombatView ───────────────────────────────────────────────────────────────

## CB-11 / CB-12 compat: committed incoming damage. Party plates draw nothing, so only stored.
func set_incoming(amount: int) -> void:
	_incoming = maxi(amount, 0)


## Pack Alpha: shows the LEADER tag (glyph + word) in the name row.
func set_leader(on: bool) -> void:
	if _leader_badge != null:
		_leader_badge.visible = on
		# LEADER replaces the ELITE tag (the fight already says Elite): ELITE + LEADER does not fit the plate.
		if _tag_chip != null and not _is_boss:
			_tag_chip.visible = (not on) and _tag_kind != ""
		_refresh_name()


## Resonance Shell: bar + "cur/max"; hidden when max <= 0 (feature off, or no Shell on this unit).
func set_shell(cur: int, max_v: int) -> void:
	if _shell_row == null:
		return
	_shell_row.visible = max_v > 0
	_queue_fit()
	if max_v <= 0:
		return
	_shell_bar.set_stats(maxi(cur, 0), max_v)
	_shell_label.text = "%d/%d" % [maxi(cur, 0), max_v]   # the SHELL word is the tag on the left of the row
	_shell_row.set_meta("shell_text", "SHELL " + _shell_label.text)


func has_shell() -> bool:
	return _shell_row != null and _shell_row.visible


func is_leader() -> bool:
	return _leader_badge != null and _leader_badge.visible


## HPValue text: "19 / 19" on an enemy, "167/167" on the boss line (as the frames).
func _hp_text() -> String:
	if _hp_bar != null and _lethal:
		return _hp_bar.shown_text()
	return ("%d/%d" if _is_boss else "%d / %d") % [maxi(_hp, 0), _max_hp]


## The "single read-model entry point": HP, shield, statuses.
func update_stats(hp: int, max_hp: int, shield: int, status: Dictionary) -> void:
	_hp = hp
	_max_hp = maxi(max_hp, 1)
	if not _is_enemy or _hp_bar == null:
		return
	_hp_bar.set_stats(hp, _max_hp)
	var prev_len := _hp_label.text.length()
	_hp_label.text = _hp_text()
	if _hp_label.text.length() != prev_len:
		_refresh_name()   # the name's share of the row depends on the HP text width
	if hp > 0:
		_dying = false
		visible = true
		modulate.a = 1.0 if _illegal_reason == "" else 0.6
	elif not _dying:
		modulate.a = 0.0
		visible = false
	_queue_fit()


## Intent column. `intent` = {show:bool, type:String, num:int, label:String, target:String, boosted:bool,
## big_hit:bool}. `show=false` renders "NO MOVE"; a blank face renders IDLE.
func set_intent(intent: Dictionary) -> void:
	if not _is_enemy or _intent_panel == null:
		return
	_boosted = bool(intent.get("boosted", false))
	var show := bool(intent.get("show", false))
	var ftype := String(intent.get("type", "blank"))
	var big := bool(intent.get("big_hit", false)) and show and not CombatLabels.is_blank_intent(ftype)
	_intent_panel.set_intent(show, ftype, int(intent.get("num", 0)), String(intent.get("label", "")), big,
		_boosted, _acting)
	_set_big_hit(big)
	if not show:
		UI3Tooltip.bind(_intent_panel, "")
		return
	if CombatLabels.is_blank_intent(ftype):
		UI3Tooltip.bind(_intent_panel, "Does nothing this turn.")
		return
	# UI3 plate, not the native tooltip: a native one is an OS-level popup that no overlay can cover (BUG-0005).
	var tgt := String(intent.get("target", ""))
	UI3Tooltip.bind(_intent_panel, ("Can knock out an Axie.\n" if big else "") + "Next: %s %d%s\nEnemy intent is public: this is the number that lands, with enrage, attrition and big hits already included." % [
		String(intent.get("label", "")), int(intent.get("num", 0)), (" on " + tgt) if tgt != "" else ""])


## Big hit: "!" badge in the name row, 4 px intent_bighit_border plate edge, BigHitStrip under the plate.
func _set_big_hit(on: bool) -> void:
	_big_hit = on
	if _bang != null:
		_bang.visible = on
	if _strip != null:
		_strip.visible = on and not _compact
	_refresh_name()
	_refresh_plate()


## True while the strip / badge show (tests, motion).
func is_big_hit() -> bool:
	return _big_hit


## Boss phase line (e.g. "Phase 1 of 2"). One-phase bosses hide it (Liam 20/10); the 1/3 and 2/3 HP bar
## marks are ticks, not phases.
func set_phase(phase: int, total: int = 1) -> void:
	if _phase_label != null:
		_phase_label.visible = total > 1
		_phase_label.text = "Phase %d of %d" % [phase, total]
		_queue_fit()


## The counter tab. spec: {} hides it. Else {kind:"spike"|"clock", bg, ink, text, right, pips:[Color], icon, maxed}.
## Built by HudKit.clock_tab() / EnemyColumn for spikes. Boss: the EnrageRow (no fill, attrition word, red at the cap).
func set_tab(spec: Dictionary) -> void:
	if _tab == null:
		return
	if spec.is_empty():
		_tab.visible = false
		_queue_fit()
		_place_hangers()
		return
	_tab.visible = true
	_tab_icon.texture = spec.get("icon", null)
	_tab_icon.visible = _tab_icon.texture != null
	_tab_text.text = String(spec.get("text", ""))
	if _is_boss:
		_tab_text.add_theme_color_override("font_color",
			UI3Theme.color("attrition_max") if bool(spec.get("maxed", false)) else UI3Theme.color("attrition"))
	else:
		_tab_style.bg_color = spec.get("bg", UI3Theme.color("plate_raised"))
		_tab_text.add_theme_color_override("font_color", spec.get("ink", UI3Theme.color("text")))
		_tab_right.add_theme_color_override("font_color", spec.get("ink", UI3Theme.color("text")))
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
	_queue_fit()
	_place_hangers()


## Plate lit (legal target / selected).
func set_selected(v: bool) -> void:
	_lit = v
	_refresh_plate()


## View-only "legal target" affordance (TargetRing around the plate; the ground ring is Stage3D's).
func set_targetable(v: bool) -> void:
	_lit = v
	_restore_chip()
	_refresh_plate()


## The resting label under a legal target: "Target · Name" (cream fill, ink text). A reason or a damage
## preview replaces it while they last.
func _restore_chip() -> void:
	if _chip_text == null or _preview > 0 or _illegal_reason != "":
		return
	if _lit and _name_label != null:
		_show_chip("%s %s %s" % [TranslationServer.translate("Target"), HudKit.dot(), full_name()],
			UI3Theme.color("text"), UI3Theme.color("text_ink"), null)
	else:
		_hide_chip()


## Illegal target: plate at 60% + reason label (danger_bg + lock). "" clears.
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


## Damage preview from a hovered/selected die: gold hatched HP segment + label "-12 · 38 > 26",
## or, if it kills, the danger plate edge, HP text "11 / 70 > 0" and the "Will die" label.
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
			after], UI3Theme.color("text"), UI3Theme.color("text_ink"), UI3.icon("face_dmg"))
	_hp_label.text = _hp_text()
	_refresh_plate()


func clear_preview_damage() -> void:
	_preview = 0
	_lethal = false
	if _hp_bar != null:
		_hp_bar.clear_preview()
		_hp_label.text = _hp_text()
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
	_place_hangers()


func _hide_chip() -> void:
	if _chip_text != null:
		_chip_text.text = ""
		_place_hangers()


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

## The intent block (UI-04 intent-reveal motion target); null on a player portrait.
func intent_block() -> Control:
	return _intent_panel


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
