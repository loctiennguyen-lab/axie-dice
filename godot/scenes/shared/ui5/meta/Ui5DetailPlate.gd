class_name Ui5DetailPlate
extends PanelContainer
## UI-05 DetailPlate: the right-hand plate of a list screen (Missions, Pass, Store, Profile, Leaderboard). Two states:
## empty ("Pick a tier": muted, centred, nothing selected, no primary) and item (Title + Body + Footer).
## Width = the screen's *_detail_w token. Fill `body` and `footer` after show_item(); they are cleared on every call.
## Build: var d := Ui5DetailPlate.new(); d.setup("mission_detail_w", tr("Pick a tier"), 420, 340)

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var empty_label: Label
var title: Label
var body: VBoxContainer
var footer: VBoxContainer
var _w_token := "mission_detail_w"
var _w1920 := 440
var _w1280 := 340


## width_token: size token of the screen; w1920 / w1280 only used while the token is missing (see Ui5MetaTok).
func setup(width_token: String, empty_text: String, w1920 := 440, w1280 := 340) -> void:
	name = "DetailPlate"
	theme = UI3Theme.get_theme()
	_w_token = width_token
	_w1920 = w1920
	_w1280 = w1280
	add_theme_stylebox_override("panel", PanelParts.plate_box("l", UI3Theme.space("24")))
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	add_child(col)
	empty_label = Ui5MetaTok.text(empty_text, "text_title", "text_muted", true)
	empty_label.name = "Empty"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(empty_label)
	title = Ui5MetaTok.text("", "text_title", "text", true)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	body = VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", UI3Theme.space("8"))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	footer = VBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(footer)
	refresh()
	show_empty(empty_text)


func refresh() -> void:
	custom_minimum_size = Vector2(Ui5MetaTok.px(_w_token, _w1920, _w1280), 0)


func is_empty() -> bool:
	return empty_label.visible


## Nothing picked: only the muted "Pick a …" line. `text` replaces the line when not empty.
func show_empty(text := "") -> void:
	if text != "":
		empty_label.text = text
	_clear(body)
	_clear(footer)
	empty_label.visible = true
	title.visible = false
	body.visible = false
	footer.visible = false


## Item picked: title set, body / footer emptied and shown (add your lines and buttons next).
func show_item(title_text: String) -> void:
	_clear(body)
	_clear(footer)
	empty_label.visible = false
	title.text = title_text
	title.visible = true
	body.visible = true
	footer.visible = true


## A body line (text_body, wraps). Returns the Label.
func add_line(t: String, color_token := "text") -> Label:
	var l := Ui5MetaTok.text(t, "text_body", color_token)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.add_child(l)
	return l


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
