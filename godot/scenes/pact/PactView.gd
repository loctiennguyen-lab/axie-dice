class_name PactView
extends Control
## Boss Pact screen (relic-set-v2 §4.4; ascension-v2 A6 first boss / A10 every boss = required).
## Pure view: RunState.pact_cards() in, `picked(index, sell_id)` / `skipped` out. RunMapController hosts it.
## A forced pact has no Skip button and Esc does nothing; when the slots are full the player must sell one
## relic (no Back button when forced). Layout is a first pass pending the Claude Design frame (none exists yet).

signal picked(index: int, sell_id: String)
signal skipped
## Aid R5: the player asked to swap card `index`. The host buys it and calls setup() again.
signal swap_requested(index: int)

var cards: Array = []
var can_skip: bool = true
var take_buttons: Array[Button] = []
var swap_buttons: Array[Button] = []
## AidPurchase.pact_swap_offer() result ({} = no swap UI). {show, enabled, price, reason, used, cap}.
var swap_offer: Dictionary = {}
var skip_button: Button = null
var sell_buttons: Array[Button] = []
var _sell_for: int = -1
var _row: HBoxContainer
var _sell_box: VBoxContainer
var _status: Label


func setup(p_cards: Array, p_can_skip: bool, p_swap_offer: Dictionary = {}) -> void:
	cards = p_cards
	swap_offer = p_swap_offer
	swap_buttons.clear()
	can_skip = p_can_skip
	for c in get_children():
		c.queue_free()
	take_buttons.clear()
	sell_buttons.clear()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	add_child(col)
	col.add_child(_label("BOSS PACT", 56, DangoTheme.CREAM_RAISED))
	_status = _label("Required: take one pact to go on." if not can_skip
		else "Each pact has a benefit and a drawback. Take one, or skip.", 16, DangoTheme.CHIP_INK_ON_WELL)
	col.add_child(_status)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 28)
	col.add_child(_row)
	for i in cards.size():
		_row.add_child(_card(i, cards[i] as Dictionary))
	_sell_box = VBoxContainer.new()
	_sell_box.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_sell_box)
	if can_skip:
		skip_button = Button.new()
		skip_button.text = "SKIP PACT"
		skip_button.custom_minimum_size = Vector2(240, 56)
		skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		skip_button.pressed.connect(func(): skipped.emit())
		col.add_child(skip_button)


func _label(t: String, px: int, color: Color) -> Label:
	var l := DangoTheme.display_label(t, px, color, 800, 0.02)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _card(i: int, c: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 380)
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 20, 5, 0.0, Vector2(-1, -1)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(_label(String(c.get("name", "")), 30, DangoTheme.INK))
	v.add_child(_label("%s pact  -  %s" % [String(c.get("group", "")).capitalize(),
		DangoTheme.rarity_name(int(c.get("rarity", 0)))], 14, DangoTheme.INK_ON_CREAM_SOFT))
	var d := Label.new()
	d.text = String(c.get("description", ""))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.add_theme_font_size_override("font_size", 16)
	d.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	v.add_child(d)
	var b := Button.new()
	b.text = "TAKE" if bool(c.get("ok", false)) else "NO FREE SLOT"
	b.disabled = not bool(c.get("ok", false))
	b.custom_minimum_size.y = 56
	b.pressed.connect(func(): _on_take(i))
	v.add_child(b)
	take_buttons.append(b)
	if bool(swap_offer.get("show", false)):
		var sw := Button.new()
		var enabled := bool(swap_offer.get("enabled", false))
		sw.text = "Swap  -  %d Gem" % int(swap_offer.get("price", 0)) if enabled \
			else "Swap  -  %s" % AidPurchase.reason_text(String(swap_offer.get("reason", "")))
		sw.disabled = not enabled
		sw.custom_minimum_size.y = 44
		sw.pressed.connect(func(): swap_requested.emit(i))
		v.add_child(sw)
		swap_buttons.append(sw)
	return panel


func _on_take(i: int) -> void:
	var c := cards[i] as Dictionary
	if bool(c.get("needs_sell", false)):
		_show_sell(i)
	else:
		picked.emit(i, "")


## Slots full: the player names the relic to sell. Back only when the pact is optional.
func _show_sell(i: int) -> void:
	_sell_for = i
	for ch in _sell_box.get_children():
		ch.queue_free()
	sell_buttons.clear()
	_sell_box.add_child(_label("Slots full. Sell one relic to take %s:" % String((cards[i] as Dictionary)["name"]), 18,
		DangoTheme.CREAM_RAISED))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	_sell_box.add_child(hb)
	for rid in (cards[i] as Dictionary)["sell_from"]:
		var d = RelicRegistry.get_def(String(rid))
		var b := Button.new()
		b.text = "Sell %s (+%d)" % [String(d.name) if d != null else String(rid),
			RelicSlots.sell_price(String(rid), RunState.ascension)]
		b.custom_minimum_size.y = 48
		b.pressed.connect(func(): picked.emit(i, String(rid)))
		hb.add_child(b)
		sell_buttons.append(b)
	if can_skip:
		var back := Button.new()
		back.text = "Back"
		back.custom_minimum_size.y = 48
		back.pressed.connect(func():
			_sell_for = -1
			for ch in _sell_box.get_children():
				ch.queue_free())
		hb.add_child(back)


## Esc skips an optional pact and is swallowed for a required one.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if can_skip:
			skipped.emit()
		get_viewport().set_input_as_handled()
