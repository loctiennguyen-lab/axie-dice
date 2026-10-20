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


func _init() -> void:
	name = "CorePanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	_slots = HBoxContainer.new()
	_slots.name = "CoreSlots"
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots.add_theme_constant_override("separation", 4)
	add_child(_slots)
	_quests = VBoxContainer.new()
	_quests.name = "QuestChips"
	_quests.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quests.add_theme_constant_override("separation", 4)
	add_child(_quests)


func _ready() -> void:
	if not EventBus.core_fired.is_connected(_on_core_fired):
		EventBus.core_fired.connect(_on_core_fired)


## Depth v3 lane VZ: the Core's slot flashes (and its counter ticks up) whenever the engine reports it fired.
func _on_core_fired(core_id: String, _uid: int, _amount: int, _kind: String) -> void:
	_fires[core_id] = int(_fires.get(core_id, 0)) + 1
	var s: PanelContainer = _slot_by_id.get(core_id)
	if s == null or not is_instance_valid(s):
		return
	_update_count(s, core_id)
	pulse(core_id)


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
	if CombatView.flashes_suppressed():
		s.modulate = tint
		tw.tween_interval(0.3)
		tw.tween_property(s, "modulate", Color.WHITE, 0.01)
		return
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector2(1.18, 1.18), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate", tint, 0.12)
	tw.chain().tween_property(s, "scale", Vector2.ONE, 0.18)
	tw.parallel().tween_property(s, "modulate", Color.WHITE, 0.18)


func fire_count(core_id: String) -> int:
	return int(_fires.get(core_id, 0))


func reset_counts() -> void:
	_fires.clear()
	_sig = ""
	refresh()


func _update_count(s: PanelContainer, core_id: String) -> void:
	var l := s.get_node_or_null("FireCount") as Label
	var n := int(_fires.get(core_id, 0))
	if l == null:
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
		return _any
	_sig = sig
	_slot_by_id.clear()
	for c in _slots.get_children():
		_slots.remove_child(c)
		c.queue_free()
	for c in _quests.get_children():
		_quests.remove_child(c)
		c.queue_free()
	var cores: Array[String] = RelicSlots.owned_cores(RunState.owned_relic_ids)
	var n_slots := RelicSlots.tuning().core_slots
	for i in n_slots:
		var sn := _slot(RelicRegistry.get_def(cores[i]) if i < cores.size() else null, false, "Core %d" % (i + 1))
		_slots.add_child(sn)
		if i < cores.size():
			_slot_by_id[cores[i]] = sn
			_add_count_label(sn, cores[i])
	var rule = RelicRegistry.get_def(RunState.run_rule) if RunState.run_rule != "" else null
	_slots.add_child(_slot(rule, true, "Run rule"))
	var any := not cores.is_empty() or rule != null
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
	return any


func _signature() -> String:
	var parts: Array[String] = [",".join(RelicSlots.owned_cores(RunState.owned_relic_ids)), RunState.run_rule, str(slot_px)]
	for qid in RunState.core_quest_progress.keys():
		parts.append("%s:%s" % [qid, JSON.stringify(RunState.core_quest_progress[qid])])
	return "|".join(parts)


func _add_count_label(s: PanelContainer, core_id: String) -> void:
	var l := UI3.label("", "LabelDisplay")
	l.name = "FireCount"
	l.add_theme_font_size_override("font_size", 18)
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
	UI3Tooltip.bind(s, tip)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.focus_mode = Control.FOCUS_ALL
	return s
