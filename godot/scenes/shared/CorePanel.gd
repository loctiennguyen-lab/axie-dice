class_name CorePanel
extends VBoxContainer
## Depth v3 owned-Core panel (lane D, design 8.6 item 2/3): 6 Core slots + 1 Run Rule slot, and one chip per
## unfinished quest Core with its step progress. Pure read of RunState; call refresh() whenever it changes.
## Slot colour = tier token, tier WORD in the tooltip. Spec: design/ux/depth-v3/core-offer.md

const TIER_NAME := ["Moss", "Amber", "Crystal"]
const TIER_TOKEN := ["rarity_rare", "rarity_legendary", "rarity_epic"]

## Axis -> icon (assets/ui3/icons) and word. One glyph per axis so the axis never relies on colour alone.
const AXIS_ICON := {"stat": "face_buff", "dice": "face_dmg", "pos": "face_summon", "mana": "face_mana",
	"quest": "node_treasure", "rule": "face_debuff", "run_rule": "ui_settings"}
const AXIS_NAME := {"stat": "Stat", "dice": "Dice faces", "pos": "Position", "mana": "Mana",
	"quest": "Quest", "rule": "Rule change", "run_rule": "Run rule"}

var slot_px := 44
## Combat HUD sets this: each Core slot then carries a small "xN" chip counting its activations this fight.
var show_counts := false
var _slots: HBoxContainer
var _quests: VBoxContainer
var _slot_by_id: Dictionary = {}     ## core id -> its slot node (rebuilt by refresh)
var _fires: Dictionary = {}          ## core id -> activations seen by THIS panel (one fight in the combat HUD)
var _sig := ""
var _any := false
var _chip_row: HBoxContainer          ## "House Cores x/2" chip, outside combat only (spec 2.2)
var anchor_slot: PanelContainer = null  ## lane AU2: the 56 px Anchor tile at the head of CoreSlots (null = no Anchor)

const ANCHOR_PX := 56
const AWAKEN_ICON := "face_buff"       ## stand-in for ui_awaken (art pending)


func _init() -> void:
	name = "CorePanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	_slots = HBoxContainer.new()
	_slots.name = "CoreSlots"
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots.add_theme_constant_override("separation", 4)
	add_child(_slots)
	_chip_row = HBoxContainer.new()
	_chip_row.name = "HouseChipRow"
	_chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chip_row)
	_quests = VBoxContainer.new()
	_quests.name = "QuestChips"
	_quests.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quests.add_theme_constant_override("separation", 4)
	add_child(_quests)


func _ready() -> void:
	if not EventBus.core_fired.is_connected(_on_core_fired):
		EventBus.core_fired.connect(_on_core_fired)


## Depth v3 lane VZ: the Core's slot flashes (and its counter ticks up) whenever the engine reports it fired.
func _on_core_fired(core_id: String, _uid: int, _amount: int, kind: String) -> void:
	_fires[core_id] = int(_fires.get(core_id, 0)) + 1
	var s: PanelContainer = _slot_by_id.get(core_id)
	if s == null or not is_instance_valid(s):
		return
	_update_count(s, core_id)
	_update_anchor_badge()
	pulse(core_id)
	if kind == "awaken":
		_awaken_mark(s)


## Awaken rule acted: the Anchor tile gets a gold outline for 0.8 s (not a flash: it fades, no strobing).
var awaken_marks := 0


func _awaken_mark(s: PanelContainer) -> void:
	awaken_marks += 1
	if not s.is_inside_tree():
		return
	var old := s.get_node_or_null("AwakenMark")
	if old != null:
		old.queue_free()
	var m := Panel.new()
	m.name = "AwakenMark"
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("s"), 4, UI3Theme.color("anchor_awake")))
	s.add_child(m)
	var tw := m.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(m, "modulate:a", 0.0, 0.3)
	tw.tween_callback(m.queue_free)


## Short flash on a Core slot: scale 1 -> 1.18 -> 1 plus a cream tint (~0.3 s). Reduced motion: tint only.
func pulse(core_id: String) -> void:
	var s: PanelContainer = _slot_by_id.get(core_id)
	if s == null or not is_instance_valid(s) or not s.is_inside_tree():
		return
	if s.has_meta("pulse_tw"):
		var old = s.get_meta("pulse_tw")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	s.pivot_offset = s.size * 0.5
	s.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tw := s.create_tween()
	s.set_meta("pulse_tw", tw)
	s.set_meta("pulsed", int(s.get_meta("pulsed", 0)) + 1)
	var hot := UI3Theme.color("text")
	var tint := Color(1.0 + hot.r * 0.5, 1.0 + hot.g * 0.5, 1.0 + hot.b * 0.5, 1.0)
	if CombatView.motion_suppressed():
		s.modulate = tint
		tw.tween_interval(0.3)
		tw.tween_property(s, "modulate", Color.WHITE, 0.01)
		return
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector2(1.18, 1.18), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate", tint, 0.12)
	tw.chain().tween_property(s, "scale", Vector2.ONE, 0.18)
	tw.parallel().tween_property(s, "modulate", Color.WHITE, 0.18)


## Lane GM (B5): a combo went off. Both Cores' slots light up; with `link` (the first time this fight) an accent
## bar joins them for 1.2 s. Reduced motion: the bar still shows (it is not a flash), only the pulse is tint-only.
## Test hooks: combo_links = how many bars were drawn, combo_link_ids = the Cores of the last bar.
var combo_links := 0
var combo_link_ids: Array = []
var _link_ids: Array = []
var _link_tw: Tween = null


func flash_combo(core_ids: Array, link: bool) -> void:
	for id in core_ids:
		pulse(String(id))
	if not link:
		return
	var a: PanelContainer = _slot_by_id.get(String(core_ids[0])) if core_ids.size() > 0 else null
	var b: PanelContainer = _slot_by_id.get(String(core_ids[1])) if core_ids.size() > 1 else null
	if a == null or b == null:
		return
	combo_links += 1
	combo_link_ids = [String(core_ids[0]), String(core_ids[1])]
	_link_ids = combo_link_ids.duplicate()
	if not _slots.draw.is_connected(_draw_link):
		_slots.draw.connect(_draw_link)
	_slots.queue_redraw()
	if _link_tw != null and _link_tw.is_valid():
		_link_tw.kill()
	if not is_inside_tree():
		return
	_link_tw = create_tween()
	_link_tw.tween_interval(1.2)
	_link_tw.tween_callback(func() -> void:
		_link_ids = []
		_slots.queue_redraw())


func _draw_link() -> void:
	if _link_ids.size() < 2:
		return
	var a: PanelContainer = _slot_by_id.get(String(_link_ids[0]))
	var b: PanelContainer = _slot_by_id.get(String(_link_ids[1]))
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
		return
	var ca := a.position + a.size * 0.5
	var cb := b.position + b.size * 0.5
	_slots.draw_line(ca, cb, UI3Theme.color("accent"), 4.0)
	_slots.draw_circle(ca, 6.0, UI3Theme.color("accent"))
	_slots.draw_circle(cb, 6.0, UI3Theme.color("accent"))


func fire_count(core_id: String) -> int:
	return int(_fires.get(core_id, 0))


func reset_counts() -> void:
	_fires.clear()
	_sig = ""
	refresh()


func _update_count(s: PanelContainer, core_id: String) -> void:
	var l := s.get_node_or_null("FireCount") as Label
	var n := int(_fires.get(core_id, 0))
	if l == null or s == anchor_slot:
		return
	l.text = "x%d" % n if n < 10 else "x9+"   # two digits would spill out of the slot
	l.visible = show_counts and n > 0


## True when there is anything to show (a Core, a rule or a quest); callers hide the panel otherwise.
func refresh() -> bool:
	# Rebuilding on every HUD repaint would cut a running pulse short: skip when nothing it shows changed.
	var sig := _signature()
	if sig == _sig and _slots.get_child_count() > 0:
		for id in _slot_by_id.keys():
			_update_count(_slot_by_id[id], String(id))
		_update_anchor_badge()
		return _any
	_sig = sig
	_slot_by_id.clear()
	for c in _slots.get_children():
		_slots.remove_child(c)
		c.queue_free()
	for c in _quests.get_children():
		_quests.remove_child(c)
		c.queue_free()
	for c in _chip_row.get_children():
		_chip_row.remove_child(c)
		c.queue_free()
	anchor_slot = null
	var anchored := AnchorAdapter.has_anchor()
	if anchored:
		anchor_slot = _anchor_slot()
		_slots.add_child(anchor_slot)
		_slot_by_id[AnchorAdapter.current_id()] = anchor_slot
		var sep := VSeparator.new()
		sep.name = "AnchorDivider"
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots.add_child(sep)
		if not show_counts:
			_chip_row.add_child(house_chip(false))
	var cores: Array[String] = RelicSlots.owned_cores(RunState.owned_relic_ids)
	var n_slots := RelicSlots.tuning().core_slots
	for i in n_slots:
		var sn := _slot(RelicRegistry.get_def(cores[i]) if i < cores.size() else null, false, "Core %d" % (i + 1))
		_slots.add_child(sn)
		if i < cores.size():
			_slot_by_id[cores[i]] = sn
			_add_count_label(sn, cores[i])
			if AnchorAdapter.is_house_core(cores[i]):
				_add_house_mark(sn)
	var rule = RelicRegistry.get_def(RunState.run_rule) if RunState.run_rule != "" else null
	_slots.add_child(_slot(rule, true, "Run rule"))
	var any := not cores.is_empty() or rule != null or anchored
	if rule != null:
		_slot_by_id[String(rule.id)] = _slots.get_child(_slots.get_child_count() - 1)
	for qid in RunState.core_quest_progress.keys():
		var d = RelicRegistry.get_def(String(qid))
		if d == null:
			continue
		var steps: Array = (d.quest as Dictionary).get("steps", [])
		var pr: Dictionary = RunState.core_quest_progress[qid]
		var step := int(pr.get("step", 0))
		var target := int((steps[mini(step, steps.size() - 1)] as Dictionary).get("target", 1)) if not steps.is_empty() else 1
		var chip := UI3.chip("%s %d/%d · %s %d/%d" % [String(d.name), int(pr.get("progress", 0)), target,
			TranslationServer.translate("Step"), mini(step + 1, steps.size()), steps.size()])
		chip.name = "Quest_%s" % qid
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		UI3Tooltip.bind(chip, UI3.player_text(String(d.description)))
		_quests.add_child(chip)
		any = true
	_any = any
	_update_anchor_badge()
	return any


func _signature() -> String:
	var parts: Array[String] = [",".join(RelicSlots.owned_cores(RunState.owned_relic_ids)), RunState.run_rule, str(slot_px),
		"%s/%s/%d/%s" % [AnchorAdapter.current_id(), AnchorAdapter.awakened(), AnchorAdapter.house_count(), show_counts]]
	for qid in RunState.core_quest_progress.keys():
		parts.append("%s:%s" % [qid, JSON.stringify(RunState.core_quest_progress[qid])])
	return "|".join(parts)


func _add_count_label(s: PanelContainer, core_id: String) -> void:
	var l := UI3.label("", "LabelDisplay")
	l.name = "FireCount"
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	l.add_theme_color_override("font_outline_color", UI3Theme.color("panel"))
	l.add_theme_constant_override("outline_size", 4)
	l.size_flags_horizontal = Control.SIZE_SHRINK_END
	l.size_flags_vertical = Control.SIZE_SHRINK_END
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	s.add_child(l)
	_update_count(s, core_id)


## Chip with an icon + word; see UI3.icon_chip. icon "" = word only.
static func word_chip(text: String, icon_name: String, border: Color, chip_name := "") -> PanelContainer:
	return UI3.icon_chip(text, UI3.icon(icon_name) if icon_name != "" else null, border, chip_name)


func _slot(def, is_rule: bool, empty_name: String) -> PanelContainer:
	var s := PanelContainer.new()
	s.name = "RuleSlot" if is_rule else "CoreSlot_%s" % empty_name.replace(" ", "")
	s.custom_minimum_size = Vector2(slot_px, slot_px)
	var filled := def != null
	var tier := clampi(int(def.rarity), 0, 2) if filled else 0
	var border := UI3Theme.color("accent") if is_rule else UI3Theme.color("text_muted")
	if filled and not is_rule:
		border = UI3Theme.color(TIER_TOKEN[tier])
	s.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color("panel_raised") if filled else UI3Theme.color("panel"), UI3Theme.radius("s"), 2 if filled or is_rule else 1, border))
	var l := UI3.label(("R" if is_rule else String(def.name).substr(0, 1).to_upper()) if filled else ("R" if is_rule else ""), "LabelTitle")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not filled:
		l.modulate.a = 0.35
	if filled:
		var ax := "run_rule" if is_rule else String(def.core_axis)
		var ic := TextureRect.new()
		ic.name = "AxisIcon"
		ic.texture = UI3.icon(String(AXIS_ICON.get(ax, "face_buff")))
		ic.custom_minimum_size = Vector2(slot_px * 0.5, slot_px * 0.5)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.add_child(ic)
		l.visible = false
	s.add_child(l)
	var tip := "%s: empty" % empty_name
	if filled:
		var head := String(def.name) if is_rule else "%s · %s" % [String(def.name), TranslationServer.translate(TIER_NAME[tier])]
		tip = "%s\n%s" % [head, UI3.player_text(String(def.description))]
		if not is_rule:
			tip += "\n" + TranslationServer.translate("Core tier: Moss → Amber → Crystal (strongest)")
	UI3Tooltip.bind(s, tip)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.focus_mode = Control.FOCUS_ALL
	return s


## "House Cores x/2" chip, or the lit "Awakened" chip once latched. `short` = glyph + x/2 only (tight 1280x720 combat HUD).
static func house_chip(short := false) -> PanelContainer:
	var id := AnchorAdapter.current_id()
	var house := AnchorAdapter.house_id(id)
	if AnchorAdapter.awakened():
		var aw_txt: String = TranslationServer.translate("Awakened") if short else "%s · %s" % [AnchorAdapter.name_of(id), TranslationServer.translate("Awakened")]
		var c := UI3.icon_chip(aw_txt, UI3.icon(AWAKEN_ICON), UI3Theme.color("anchor_awake"), "HouseChip")
		c.set_meta("state", "awakened")
		return c
	var txt := "%d/%d" % [AnchorAdapter.house_count(), Anchors.AWAKEN_NEED]
	if not short:
		txt = "%s · %s %s" % [AnchorAdapter.name_of(id), TranslationServer.translate("House Cores"), txt]
		txt += " · %s %s" % [TranslationServer.translate("awakens"), AnchorAdapter.awaken_name(id)]
	var chip := UI3.icon_chip(txt, UI3.icon(AnchorAdapter.house_icon(house)), AnchorAdapter.house_color(house), "HouseChip")
	chip.set_meta("state", "count")
	return chip


## Anchor tile: house-coloured frame + house glyph; awakened = double frame + awaken glyph. Tooltip lists rule, price,
## awaken rule and the 5 house Cores (Owned marked).
func _anchor_slot() -> PanelContainer:
	var id := AnchorAdapter.current_id()
	var house := AnchorAdapter.house_id(id)
	var col := AnchorAdapter.house_color(house)
	var awake := AnchorAdapter.awakened()
	var s := PanelContainer.new()
	s.name = "AnchorSlot"
	s.custom_minimum_size = Vector2(ANCHOR_PX, ANCHOR_PX)
	var frame := UI3Theme.color("anchor_awake") if awake else col
	s.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"), 4 if awake else 3, frame))
	if awake:
		var inner := Panel.new()
		inner.name = "AwakeInnerFrame"
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 4
		inner.offset_top = 4
		inner.offset_right = -4
		inner.offset_bottom = -4
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("s"), 2, col))
		s.add_child(inner)
	var ic := TextureRect.new()
	ic.name = "HouseGlyph"
	ic.texture = UI3.icon(AnchorAdapter.house_icon(house))
	ic.custom_minimum_size = Vector2(ANCHOR_PX * 0.5, ANCHOR_PX * 0.5)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(ic)
	if awake:
		var aw := TextureRect.new()
		aw.name = "AwakenGlyph"
		aw.texture = UI3.icon(AWAKEN_ICON)
		aw.custom_minimum_size = Vector2(18, 18)
		aw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		aw.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		aw.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		aw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.add_child(aw)
	# Badge (combat only): x/2 until awakened, then xN activations. Never two badges at once.
	var b := UI3.label("", "LabelDisplay")
	b.name = "AnchorBadge"
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	b.add_theme_color_override("font_outline_color", UI3Theme.color("panel"))
	b.add_theme_constant_override("outline_size", 4)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.visible = false
	s.add_child(b)
	var lines: Array[String] = ["%s · %s" % [AnchorAdapter.name_of(id), AnchorAdapter.house_name(house)],
		AnchorAdapter.rule_text(id)]
	if AnchorAdapter.price_text(id) != "":
		lines.append(AnchorAdapter.price_text(id))
	lines.append("%s %s: %s" % [TranslationServer.translate("Awakens:"), AnchorAdapter.awaken_name(id), AnchorAdapter.awaken_rule(id)])
	lines.append("%s %d/%d" % [TranslationServer.translate("House Cores"), AnchorAdapter.house_count(), Anchors.AWAKEN_NEED])
	var own := AnchorAdapter.owned()
	for cid in AnchorAdapter.house_cores(id):
		var d = RelicRegistry.get_def(String(cid))
		lines.append("%s %s" % [TranslationServer.translate("Owned") + ":" if own.has(cid) else "-", String(d.name) if d != null else String(cid)])
	UI3Tooltip.bind(s, "\n".join(lines))
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.focus_mode = Control.FOCUS_ALL
	return s


func _update_anchor_badge() -> void:
	if anchor_slot == null or not is_instance_valid(anchor_slot):
		return
	var b := anchor_slot.get_node_or_null("AnchorBadge") as Label
	if b == null:
		return
	var n := int(_fires.get(AnchorAdapter.current_id(), 0))
	if AnchorAdapter.awakened():
		b.text = "x%d" % n if n < 10 else "x9+"
		b.visible = show_counts and n > 0
	else:
		b.text = "%d/%d" % [AnchorAdapter.house_count(), Anchors.AWAKEN_NEED]
		b.visible = show_counts


## House Core inside the panel: 3 px house ring just inside the tier border + house glyph (the glyph is the main sign).
func _add_house_mark(s: PanelContainer) -> void:
	var house := AnchorAdapter.house_id(AnchorAdapter.current_id())
	var ring := Panel.new()
	ring.name = "HouseRing"
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = 4
	ring.offset_top = 4
	ring.offset_right = -4
	ring.offset_bottom = -4
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("s"), 3, AnchorAdapter.house_color(house)))
	s.add_child(ring)
	var g := TextureRect.new()
	g.name = "HouseGlyph"
	g.texture = UI3.icon(AnchorAdapter.house_icon(house))
	g.custom_minimum_size = Vector2(16, 16)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN   # bottom-left: bottom-right is the xN count
	g.size_flags_vertical = Control.SIZE_SHRINK_END
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(g)
	UI3Tooltip.bind(s, "%s\n%s %s" % [String(s.get_meta("ui3_tip", "")), TranslationServer.translate("House Core of"), AnchorAdapter.house_name(house)])
