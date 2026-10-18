extends Control
class_name AidPanel
## The paid "Aid" zone, bottom-left (UI-03 round 2 screen 39): the Aid button (key A), the single offer card,
## the Aid tray and the first-purchase confirm. Pure view: rows and prices come from the caller (`set_state`,
## fed by CombatView from AidPurchase / aid_prices.json); nothing is bought here, it only reports
## `purchase_confirmed(aid_id)`.
##
## Trust rules kept (monetization-v1): real price on every row (disabled rows too), the decline button is the
## same size as the buy button, no timers, the fairness line is verbatim. Hidden entirely for newcomers (first
## 5 runs) and in Mission runs: no button, no offer, no tray.
##
## Geometry (1920 base): button 288x48 at left 16 / bottom 16; offer card 288 wide above it; tray 420 wide
## above it (ends left of the dice tray, x ~436); rows 64 high; confirm 560 over the scrim.
## Focus: rows, then the buy action. Esc closes the confirm first, then the tray.

signal purchase_confirmed(aid_id: String)
signal tray_toggled(open: bool)
signal offer_dismissed

const FAIRNESS := "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
const BTN_W := 288.0
const BTN_H := 48.0
const EDGE := 16.0
const TRAY_W := 420.0
const ROW_H := 64.0

var enabled := true            ## false for newcomers: the whole zone disappears
var used := 0
var cap := 6
var rows: Array = []           ## [{id, title, price, cap_text, enabled, reason, icon}]
var offer: Dictionary = {}     ## {id, title, what, caps:[String], price} — one at a time, or {}
var session_confirmed := false ## the 02i modal is asked once per session

var _button: Button
var _used_label: Label
var _tray: PanelContainer
var _tray_rows: VBoxContainer
var _tray_used: Label
var _offer_card: PanelContainer
var _offer_box: VBoxContainer
var _modal: Control
var _pending_id := ""
var _tray_top := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_button()
	_build_tray()
	_build_offer()
	resized.connect(layout)


func _build_button() -> void:
	_button = UI3.button("", &"secondary")
	_button.name = "AidButton"
	_button.custom_minimum_size = Vector2(BTN_W, BTN_H)
	_button.pressed.connect(toggle_tray)
	add_child(_button)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16.0
	row.offset_right = -12.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	_button.add_child(row)
	var t := UI3.label(TranslationServer.translate("Aid"), "LabelDisplay")
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(t)
	_used_label = UI3.label("", "LabelMuted")
	_used_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_used_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_used_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_used_label)
	var key := UI3.key_hint("A")
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(key)


func _build_tray() -> void:
	_tray = UI3.plate(&"plate")
	_tray.name = "AidTray"
	_tray.visible = false
	_tray.custom_minimum_size = Vector2(TRAY_W, 0)
	_tray.z_index = 6
	add_child(_tray)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	_tray.add_child(col)
	var hrow := HBoxContainer.new()
	col.add_child(hrow)
	var t := UI3.label(TranslationServer.translate("Aid"), "LabelDisplay")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(t)
	_tray_used = UI3.label("", "LabelMuted")
	hrow.add_child(_tray_used)
	_tray_rows = VBoxContainer.new()
	_tray_rows.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(_tray_rows)
	var foot := UI3.label(TranslationServer.translate(FAIRNESS), "LabelMuted")
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(TRAY_W - 40.0, 0)
	col.add_child(foot)


func _build_offer() -> void:
	_offer_card = PanelContainer.new()
	_offer_card.name = "AidOffer"
	_offer_card.visible = false
	_offer_card.custom_minimum_size = Vector2(BTN_W, 0)
	_offer_card.theme = UI3Theme.get_theme()
	# violet border: the one place Aid says "this costs Gem"
	_offer_card.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"),
		UI3Theme.radius("m"), 2, UI3Theme.color("gem_border"), Vector4(16, 16, 16, 16)))
	add_child(_offer_card)
	_offer_box = VBoxContainer.new()
	_offer_box.add_theme_constant_override("separation", UI3Theme.space("8"))
	_offer_card.add_child(_offer_box)


# ── State ────────────────────────────────────────────────────────────────────────────────────

## `d`: enabled(bool), used(int), cap(int), rows(Array), offer(Dictionary).
func set_state(d: Dictionary) -> void:
	enabled = bool(d.get("enabled", true))
	used = int(d.get("used", 0))
	cap = int(d.get("cap", 6))
	rows = d.get("rows", [])
	offer = d.get("offer", {})
	visible = enabled
	var u := TranslationServer.translate("used %d of %d") % [used, cap]
	_used_label.text = u
	_tray_used.text = u
	_rebuild_rows()
	_rebuild_offer()
	if not enabled:
		_tray.visible = false
		_close_modal()
	layout()


func is_open() -> bool:
	return _tray.visible


func toggle_tray() -> void:
	set_open(not _tray.visible)


func set_open(v: bool) -> void:
	if not enabled:
		return
	_tray.visible = v
	_offer_card.visible = not v and not offer.is_empty()
	layout()
	tray_toggled.emit(v)
	if v:
		for r in _tray_rows.get_children():
			if r is Button and not (r as Button).disabled:
				(r as Button).grab_focus()
				break


func _rebuild_rows() -> void:
	for c in _tray_rows.get_children():
		_tray_rows.remove_child(c)
		c.queue_free()
	for r in rows:
		_tray_rows.add_child(_row(r))


## One tray row (a Button, so Enter / click buys): name + sub-line, then the CostChip. The real price shows even
## when the row is disabled; the reason replaces the cap text and stays readable.
func _row(r: Dictionary) -> Control:
	var short := _short(r)
	var on := bool(r.get("enabled", false)) and short == 0
	var b := UI3.button("", &"secondary")
	b.name = "AidRow_%s" % String(r.get("id", ""))
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.disabled = not on
	b.pressed.connect(_ask.bind(String(r.get("id", ""))))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16.0
	row.offset_right = -12.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	b.add_child(row)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var name_l := UI3.label(TranslationServer.translate(String(r.get("title", ""))), "LabelDisplay")
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_l.add_theme_font_size_override("font_size", 18)
	name_l.clip_text = true
	if not on:
		name_l.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	col.add_child(name_l)
	var why := ("Need %d more Gem" % short) if short > 0 else String(r.get("reason", ""))
	var sub := UI3.label(TranslationServer.translate(why if not on and why != "" else String(r.get("cap_text", ""))), "LabelMuted")
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.clip_text = true
	col.add_child(sub)
	var chip := UI3.cost_chip(&"gem", int(r.get("price", 0)), false)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)
	return b


## Gem missing for this row / offer (0 when it can be paid). The confirm never opens when this is > 0.
func _short(r: Dictionary) -> int:
	if not r.has("gems"):
		return 0
	return maxi(int(r.get("price", 0)) - int(r.get("gems", 0)), 0)


func _rebuild_offer() -> void:
	for c in _offer_box.get_children():
		_offer_box.remove_child(c)
		c.queue_free()
	if offer.is_empty():
		_offer_card.visible = false
		return
	_offer_card.visible = not _tray.visible
	_offer_box.add_child(UI3.label(TranslationServer.translate("Aid offer · once"), "LabelMuted"))
	_offer_box.add_child(UI3.label(TranslationServer.translate(String(offer.get("title", ""))), "LabelDisplay"))
	var what := UI3.label(TranslationServer.translate(String(offer.get("what", ""))), "LabelMuted")
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.custom_minimum_size = Vector2(BTN_W - 34.0, 0)
	_offer_box.add_child(what)
	for cap_line in offer.get("caps", []):
		_offer_box.add_child(UI3.label(String(cap_line), "LabelMuted"))
	var buy := UI3.button(TranslationServer.translate("Buy · %d Gem") % int(offer.get("price", 0)), &"primary")
	buy.name = "OfferBuy"
	buy.custom_minimum_size = Vector2(BTN_W - 34.0, 48)
	buy.pressed.connect(_ask.bind(String(offer.get("id", ""))))
	if _short(offer) > 0:
		UI3.set_disabled_reason(buy, TranslationServer.translate("Need %d more Gem") % _short(offer))
	_offer_box.add_child(buy)
	var no := UI3.button(TranslationServer.translate("Not now"), &"secondary")
	no.name = "OfferNotNow"
	no.custom_minimum_size = Vector2(BTN_W - 34.0, 48)   # same size as the buy button, always
	no.pressed.connect(func():
		offer = {}
		offer_dismissed.emit()
		_rebuild_offer()
		layout())
	_offer_box.add_child(no)


# ── Purchase confirm ─────────────────────────────────────────────────────────────────────────

func _ask(aid_id: String) -> void:
	if _short(_find_row(aid_id)) > 0:
		return   # not enough Gem: never open the confirm
	_pending_id = aid_id
	if session_confirmed:
		purchase_confirmed.emit(aid_id)
		return
	_show_modal(aid_id)


func _find_row(aid_id: String) -> Dictionary:
	for r in rows:
		if String(r.get("id", "")) == aid_id:
			return r
	if String(offer.get("id", "")) == aid_id:
		return offer
	return {}


func _show_modal(aid_id: String) -> void:
	_close_modal()
	var r := _find_row(aid_id)
	var price := int(r.get("price", 0))
	var gems := int(r.get("gems", MetaState.gem_wallet().balance()))
	var cancel := UI3.button(TranslationServer.translate("Cancel"), &"secondary")
	cancel.name = "Cancel"
	cancel.custom_minimum_size = Vector2(200, 56)   # same size as Pay, always
	var pay := UI3.button(TranslationServer.translate("Pay %d Gem") % price, &"primary")
	pay.name = "Pay"
	pay.custom_minimum_size = Vector2(200, 56)
	var m := UI3.modal(TranslationServer.translate("Confirm purchase"),
		TranslationServer.translate("We ask once per session. Your spending limit and the option to hide Aid offers are in Settings."),
		[cancel, pay], 0)
	m.z_index = 30
	m.name = "AidConfirm"
	var col := m.find_child("Dialog", true, false).get_child(0) as VBoxContainer
	var item := UI3.plate(&"row")
	item.name = "ConfirmItem"
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", UI3Theme.space("8"))
	var ipad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		ipad.add_theme_constant_override("margin_" + side, 16)
	item.add_child(ipad)
	ipad.add_child(iv)
	var top := HBoxContainer.new()
	iv.add_child(top)
	var nm := UI3.label(TranslationServer.translate(String(r.get("title", ""))), "LabelDisplay")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	top.add_child(UI3.cost_chip(&"gem", price, false))
	var cap_t := String(r.get("cap_text", ""))
	if cap_t == "":
		cap_t = String(r.get("what", ""))
	if cap_t != "":
		iv.add_child(UI3.label(TranslationServer.translate(cap_t), "LabelMuted"))
	iv.add_child(UI3.label(TranslationServer.translate("Your Gem: %d → %d") % [gems, gems - price]))
	iv.add_child(UI3.label(TranslationServer.translate("Aid this run: %d → %d of %d") % [used, used + 1, cap]))
	col.add_child(item)
	col.move_child(item, 1)
	cancel.pressed.connect(_close_modal)
	m.cancelled.connect(_close_modal)
	pay.pressed.connect(func():
		session_confirmed = true
		_close_modal()
		purchase_confirmed.emit(_pending_id))
	_modal = m
	add_child(m)


func _close_modal() -> void:
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null


func modal_open() -> bool:
	return _modal != null and is_instance_valid(_modal)


## Esc: closes the confirm first, then the tray. Returns true if it consumed the key.
func handle_escape() -> bool:
	if modal_open():
		_close_modal()
		return true
	if _tray.visible:
		set_open(false)
		return true
	return false


func tray_top_hint(tray_top: float) -> void:
	_tray_top = tray_top
	layout()


## Top edge of the lowest-left Aid element that is showing (offer card, else the button).
func top_y() -> float:
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	if not enabled:
		return h - EDGE
	if _tray != null and _tray.visible:
		return _tray.position.y
	if _offer_card != null and _offer_card.visible:
		return _offer_card.position.y
	return h - EDGE - BTN_H


func layout() -> void:
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	var btn_top := h - EDGE - BTN_H
	_button.position = Vector2(EDGE, btn_top)
	_button.size = Vector2(BTN_W, BTN_H)
	_offer_card.size = Vector2.ZERO
	var oh := _offer_card.get_combined_minimum_size().y
	_offer_card.size = Vector2(BTN_W, oh)
	_offer_card.position = Vector2(EDGE, btn_top - 8.0 - oh)
	_tray.size = Vector2.ZERO
	var th := _tray.get_combined_minimum_size().y
	_tray.size = Vector2(TRAY_W, th)
	_tray.position = Vector2(EDGE, btn_top - 8.0 - th)
