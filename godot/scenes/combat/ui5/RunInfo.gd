class_name Ui5RunInfo
extends HBoxContainer
## UI-05 b1 lane A: RunInfo, top-left (CSS .run-info / .run-pill / .icon-btn). HBox at the screen margin, gap 12:
##   MenuButton  round plate run_pill_h square, ui_menu at icon_l
##   RunPill     plate pill run_pill_h high, padding 0 12 0 24, gap 12:
##               FightLabel (Rowdies title) · AscensionChip "A6" · TurnChip "Turn 1" (Work Sans) · ShardChip
## Names match the HTML data-names. Pure view; CombatHud feeds it with `set_info`.

var menu_button: Button
var run_pill: PanelContainer
var fight_label: Label
var asc_chip: PanelContainer
var asc_label: Label
var turn_chip: PanelContainer
var turn_label: Label
var shard_chip: PanelContainer
var shard_label: Label
var _shard_icon: TextureRect


func _init() -> void:
	name = "RunInfo"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.theme = UI3Theme.get_theme()
	menu_button.focus_mode = Control.FOCUS_ALL
	menu_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu_button.icon = UI3.cream_icon("ui_menu")
	menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_button.expand_icon = false
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Ui5HudStyle.plate_button(menu_button, UI3Theme.radius("pill"))
	add_child(menu_button)

	run_pill = PanelContainer.new()
	run_pill.name = "RunPill"
	run_pill.theme = UI3Theme.get_theme()
	run_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(run_pill)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	run_pill.add_child(row)
	fight_label = UI3.label("", "LabelTitle")
	fight_label.name = "FightLabel"
	fight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(fight_label)
	asc_chip = Ui5HudStyle.chip("AscensionChip")
	asc_label = UI3.label("", "LabelDisplay")
	asc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	asc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	asc_chip.add_child(asc_label)
	row.add_child(asc_chip)
	turn_chip = Ui5HudStyle.chip("TurnChip")
	turn_label = UI3.label("", "")
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_chip.add_child(turn_label)
	row.add_child(turn_chip)
	shard_chip = Ui5HudStyle.chip("ShardChip")
	shard_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	shard_chip.tooltip_text = "Gene Shards earned this run"
	var srow := HBoxContainer.new()
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_chip.add_child(srow)
	_shard_icon = Ui5HudStyle.icon_rect(UI3.icon("cur_shard"), UI3Theme.size_of("icon_m"))
	srow.add_child(_shard_icon)
	shard_label = UI3.label("0", "LabelDisplay")
	shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shard_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	srow.add_child(shard_label)
	row.add_child(shard_chip)
	refresh_tokens()


## Re-reads every size token (also called after a window-scale change: the 1280 text floor).
func refresh_tokens() -> void:
	add_theme_constant_override("separation", UI3Theme.space("12"))
	var h := UI3Theme.size_of("run_pill_h")
	menu_button.custom_minimum_size = Vector2(h, h)
	menu_button.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_l"))
	run_pill.add_theme_stylebox_override("panel", Ui5HudStyle.plate_box(UI3Theme.radius("pill"),
		Vector4(UI3Theme.space("24"), 0, UI3Theme.space("12"), 0)))
	run_pill.custom_minimum_size = Vector2(0, h)
	(run_pill.get_node("Row") as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("12"))
	for c in [asc_chip, turn_chip, shard_chip]:
		(c as PanelContainer).custom_minimum_size = Vector2(0, UI3Theme.size_of("chip_h"))
	(shard_label.get_parent() as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("8"))
	_shard_icon.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")


## title "Fight 4 of 18" (one label), asc 0 hides the A chip, turn, shards earned this run.
func set_info(title: String, asc: int, turn: int, shards: int) -> void:
	fight_label.text = title
	asc_chip.visible = asc > 0
	asc_label.text = "A%d" % asc
	turn_label.text = TranslationServer.translate("Turn") + " %d" % turn
	shard_label.text = str(shards)
