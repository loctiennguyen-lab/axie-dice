extends Control
## UNLOCKS (UI-03 round-2 screen 29, Unlocks tab, on UI3Meta): the ten-item, spend-once-keep-forever Shard
## ladder from ContentDB.UNLOCKS, in the order the data gives. Each row: step number, name, state tag
## (OWNED / AVAILABLE / TOO EXPENSIVE / NO EFFECT YET), description, price button. The first affordable row's
## price button is the screen's one primary; the rest are secondary. A disabled button says why (OWNED, or the
## shortfall). MetaState.buy_unlock is unchanged. Node names kept: UnlockRow_<id>, BuyButton, UnlockList,
## ListScroll, StatusLabel; the Shard total sits in the shared Currencies plate and in ShardLabel.

const SHARD_ICON := "assets/fx/shard.png"

var _shell: Dictionary
var _list: VBoxContainer
var _shard_label: Label
var _status_label: Label
var no_scene_change := false


func _ready() -> void:
	_shell = UI3Meta.build(self, "Unlocks", "Spend once, keep forever", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	UI3Meta.doc_tabs(_shell, "unlocks")
	var col := _shell["col"] as VBoxContainer
	var bar := UI3.plate(&"plate")
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", UI3Theme.space("16"))
	bar.add_child(br)
	var t := UI3.label("Your Shards", "LabelTitle")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br.add_child(t)
	_shard_label = UI3.label("0", "LabelScreenTitle")
	_shard_label.name = "ShardLabel"
	br.add_child(_shard_label)
	col.add_child(bar)
	_status_label = UI3.label("", "LabelMuted")
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	col.add_child(_status_label)
	_list = VBoxContainer.new()
	_list.name = "UnlockList"
	_list.add_theme_constant_override("separation", UI3Theme.space("16"))
	var sc := UI3Meta.scroll(_list)
	sc.name = "ListScroll"
	col.add_child(sc)
	refresh()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func refresh() -> void:
	_shard_label.text = str(MetaState.shard_pool)
	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)
	var primary_given := false
	for def in ContentDB.UNLOCKS:
		var d: Dictionary = def
		var usable := not MetaState.has_unlock(String(d.get("id", ""))) \
			and MetaState.shard_pool >= int(d.get("cost", 0))
		_list.add_child(_build_row(d, usable and not primary_given))
		if usable:
			primary_given = true


func _build_row(def: Dictionary, primary: bool) -> PanelContainer:
	var id := String(def.get("id", ""))
	var cost := int(def.get("cost", 0))
	var owned := MetaState.has_unlock(id)
	var inert := ContentDB.UNLOCKS_WITHOUT_EFFECT.has(id)
	var afford := MetaState.shard_pool >= cost
	var too_expensive := not owned and not afford

	var row := UI3.plate(&"card")
	row.name = "UnlockRow_" + id
	row.custom_minimum_size = Vector2(0, 96)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", UI3Theme.space("16"))
	row.add_child(hbox)
	var step := UI3.label(str(ContentDB.UNLOCKS.find(def) + 1), "LabelScreenTitle")
	step.custom_minimum_size.x = 48
	step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(step)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", UI3Theme.space("8"))
	hbox.add_child(info)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", UI3Theme.space("16"))
	info.add_child(name_row)
	name_row.add_child(UI3.label(String(def.get("n", "")), "LabelTitle"))
	var tag_text := "AVAILABLE"
	if owned:
		tag_text = "OWNED"
	elif too_expensive:
		tag_text = "TOO EXPENSIVE"
	elif inert:
		tag_text = "NO EFFECT YET"
	name_row.add_child(UI3Meta.tag(tag_text))
	var desc := UI3.label(String(def.get("d", "")), "LabelMuted")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)

	var buy: Button
	if owned:
		buy = UI3.button("OWNED", &"secondary", &"M")
		buy.disabled = true
	else:
		buy = UI3.button(str(cost), &"primary" if primary else &"secondary", &"M")
		buy.icon = MockupAssets.tex(SHARD_ICON)
		buy.expand_icon = false
		buy.add_theme_constant_override("icon_max_width", 24)
		if too_expensive:
			buy.disabled = true
			buy.tooltip_text = "%d more Shards needed" % (cost - MetaState.shard_pool)
		else:
			buy.pressed.connect(_on_buy_pressed.bind(id))
	buy.name = "BuyButton"
	buy.custom_minimum_size.x = 176
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(buy)
	return row


func _on_buy_pressed(id: String) -> void:
	var err := MetaState.buy_unlock(id)
	if err != "":
		_status_label.text = err
		_status_label.visible = true
		return
	_status_label.visible = false
	refresh()
