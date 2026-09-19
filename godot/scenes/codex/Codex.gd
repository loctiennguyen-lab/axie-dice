extends Control
## The Codex — the rule book (godot-port-gap-inventory.md §2.1). Builds all 10 tabs
## procedurally from CodexContent.gd so the same text can be reused by the in-combat
## InfoPanel (godot/scenes/combat/InfoPanelView.gd) without a second copy.
##
## Opened as its own scene. MainMenu.gd should open it with:
##   get_tree().change_scene_to_file("res://scenes/codex/Codex.tscn")
## BACK returns to the main menu the same way.

@onready var _tab_row: HBoxContainer = %TabRow
@onready var _scroll: ScrollContainer = %Scroll
@onready var _body: RichTextLabel = %Body
@onready var _back: Button = %BackButton

var _current_tab: String = "basic"
var _tab_buttons: Dictionary = {}   # key -> Button


func _ready() -> void:
	for pair in CodexContent.TABS:
		var key: String = pair[0]
		var label: String = pair[1]
		var b := Button.new()
		b.text = label
		b.toggle_mode = true
		b.pressed.connect(func(): _select_tab(key))
		_tab_row.add_child(b)
		_tab_buttons[key] = b
	_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))
	_select_tab(_current_tab)


func _select_tab(key: String) -> void:
	_current_tab = key
	for k in _tab_buttons.keys():
		(_tab_buttons[k] as Button).button_pressed = (k == key)
	_body.text = "[b][color=#f4f0ff]CODEX[/color][/b]  -  every rule in the game, nothing hidden.\n\n" \
		+ CodexContent.tab_text(key)
	_scroll.scroll_vertical = 0
