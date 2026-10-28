extends EnemyPlate
class_name BossPlate
## UI-05 b1 lane C: the boss plate, top-right (`.boss-plate`). Same plate as EnemyPlate, `boss_plate_w` wide.
##
## BossPlate = HBox(BossMain VBox, IntentBlock enemy_intent_w full height), clip on. BossMain: padding 12 16 16, gap 8:
##   boss line : EnemyTag BOSS · EnemyName (text_title, takes the free width) · BigHitBadge · HPValue
##   HPBar     : hp_bar_l with the 1/3 and 2/3 phase ticks
##   ShellRow  : EnemyTag SHELL · ShellBar · ShellValue (hidden without a Shell)
##   Extra     : EnrageRow (UnitPortrait's counter row) and the "Phase 1 of 2" line for two-phase bosses


func _init() -> void:
	super(true)


func _build_main() -> void:
	name_row = _hbox("BossLine")
	main_box.add_child(name_row)
	tag_box = _hbox("Tags")
	name_row.add_child(tag_box)
	name_label = _name()
	name_row.add_child(name_label)
	suffix = EnemyPlate.suffix_chip("A")
	suffix.visible = false
	name_row.add_child(suffix)
	badge = EnemyPlate.bang()
	badge.visible = false
	name_row.add_child(badge)
	hp_label = _value("HPValue")
	name_row.add_child(hp_label)
	tags_row = _hbox("TagsRow")
	tags_row.visible = false
	main_box.add_child(tags_row)
	hp_bar = _bar("HPBar", HPBar.Kind.ENEMY)
	hp_bar.set_marks([1.0 / 3.0, 2.0 / 3.0])
	main_box.add_child(hp_bar)
	_build_shell_row()
	main_box.add_child(shell_row)
	extra_box = VBoxContainer.new()
	extra_box.name = "Extra"
	extra_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_box.add_child(extra_box)
