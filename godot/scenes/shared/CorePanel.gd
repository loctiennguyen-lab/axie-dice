class_name CorePanel
extends VBoxContainer
## Depth v3 owned-Core panel (lane D, design 8.6 item 2/3): 6 Core slots + 1 Run Rule slot, and one chip per
## unfinished quest Core with its step progress. Pure read of RunState; call refresh() whenever it changes.
## Slot colour = tier token, tier WORD in the tooltip. Spec: design/ux/depth-v3/core-offer.md

const TIER_NAME := ["Moss", "Amber", "Crystal"]
const TIER_TOKEN := ["rarity_rare", "rarity_legendary", "rarity_epic"]

var slot_px := 44
var _slots: HBoxContainer
var _quests: VBoxContainer


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


## True when there is anything to show (a Core, a rule or a quest); callers hide the panel otherwise.
func refresh() -> bool:
	for c in _slots.get_children():
		_slots.remove_child(c)
		c.queue_free()
	for c in _quests.get_children():
		_quests.remove_child(c)
		c.queue_free()
	var cores: Array[String] = RelicSlots.owned_cores(RunState.owned_relic_ids)
	var n_slots := RelicSlots.tuning().core_slots
	for i in n_slots:
		_slots.add_child(_slot(RelicRegistry.get_def(cores[i]) if i < cores.size() else null, false, "Core %d" % (i + 1)))
	var rule = RelicRegistry.get_def(RunState.run_rule) if RunState.run_rule != "" else null
	_slots.add_child(_slot(rule, true, "Run rule"))
	var any := not cores.is_empty() or rule != null
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
	return any


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
	s.add_child(l)
	var tip := "%s: empty" % empty_name
	if filled:
		var head := String(def.name) if is_rule else "%s · %s" % [String(def.name), TranslationServer.translate(TIER_NAME[tier])]
		tip = "%s\n%s" % [head, UI3.player_text(String(def.description))]
	UI3Tooltip.bind(s, tip)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.focus_mode = Control.FOCUS_ALL
	return s
