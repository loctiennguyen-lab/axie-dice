class_name MissionTierRow
extends Ui5ListRow
## UI-05 S5: one tier row of the Missions table (data-name TierRowN1..N6). A Ui5ListRow (height mission_row_h, ring when
## selected, alpha 0.55 when locked) whose content is the six-column grid of the HTML (.mgrid): TIER, MODE, STAKE, WIN BACK,
## STONE, RULES. Nothing is selected by default.

## Column ratios of .mgrid (minmax(0, Nfr)); MissionParts.head_row uses the same ones.
const RATIOS := [0.55, 0.9, 0.7, 1.1, 0.45, 2.3]
var tier := ""
var locked := false
var rules_label: Label


## cells = [tier, mode, stake, win back, stone, rules-or-lock note]; note_is_lock names the last cell "LockNote".
func setup_tier(tier_id: String, cells: Array, note_is_lock: bool) -> void:
	setup(tier_id, "", "", &"mission")
	tier = tier_id
	locked = note_is_lock
	name = "TierRow" + tier_id
	var old := get_node("Row")
	remove_child(old)
	old.queue_free()
	title_label = null
	sub_label = null
	right_label = null
	var row := HBoxContainer.new()
	row.name = "Cells"
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for i in 6:
		var big := i == 0
		var l := Ui5Text.label(String(cells[i]), "text_screen_title" if big else ("text_title" if i == 2 else "text_body"), "text", big or i == 2)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = RATIOS[i]
		l.custom_minimum_size.x = 0
		if i in [2, 3, 4]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if i == 5:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.name = "LockNote" if note_is_lock else "Rules"
			rules_label = l
		row.add_child(l)
	UI3.attach_focus_ring(self)


## Selected = ring; locked = dimmed (a selected locked row keeps both, like .mrow.is-on.locked).
func set_tier_state(selected: bool, is_locked: bool) -> void:
	locked = is_locked
	set_state(&"selected" if selected else (&"locked" if is_locked else &"normal"))
	modulate = Color(1, 1, 1, 0.55) if is_locked else Color.WHITE
