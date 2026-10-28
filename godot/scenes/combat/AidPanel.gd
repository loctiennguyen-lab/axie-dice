extends Control
class_name AidPanel
## The paid "Aid" zone, bottom-left. UI-05 b1 lane A (ui05-combat-screens.html, 02-combat--aid-offer): AidZone =
## VBox(AidOffer, AidButton) at the screen margin, aid_w wide, gap space_16; the Aid tray and the first-purchase
## confirm open above it. Pure view: rows and prices come from the caller (`set_state`, fed by CombatView from
## AidPurchase / aid_prices.json); nothing is bought here, it only reports `purchase_confirmed(aid_id)`.
##
## Trust rules kept (monetization-v1): real price on every row (disabled rows too), the decline button is the
## same height as the buy button, no timers, the fairness line is verbatim. Hidden entirely for newcomers (first
## 5 runs) and in Mission runs: no button, no offer, no tray.
##
## No key cap on screen (Liam 28/10, only Space is shown); the Aid key (A) still toggles the tray.
## Every size is a token (aid_w has a 1280 override). Focus: rows, then the buy action. Esc closes the confirm
## first, then the tray.

signal purchase_confirmed(aid_id: String)
signal tray_toggled(open: bool)
signal offer_dismissed

const FAIRNESS := "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
const EDGE := 24.0      ## = space.screen; CombatView reads it for the keep-clear rect
const TRAY_W := 420.0   ## Aid tray width (not in the UI-05 frames; CombatView reads it for the keep-clear rect)
const ROW_H := 64.0

var waiting := false           ## server request in flight: the offer hides, the zone dims
var dimmed := false            ## enemy turn: the zone dims (HTML .dim)
var enabled := true            ## false for newcomers: the whole zone disappears
var used := 0
var cap := 6
var rows: Array = []           ## [{id, title, price, cap_text, enabled, reason, icon}]
var offer: Dictionary = {}     ## {id, title, what, caps:[String], price} — one at a time, or {}
var session_confirmed := false ## the 02i modal is asked once per session

var _zone: VBoxContainer       ## AidZone
var _button: Button            ## AidButton
var _used_label: Label
var _aid_icon: TextureRect
var _tray: PanelContainer
var _tray_rows: VBoxContainer
var _tray_used: Label
var _offer_card: PanelContainer   ## AidOffer
var _offer_box: VBoxContainer
var _modal: Control
var _pending_id := ""
var _tray_top := 0.0
var _scale_seen := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI3Theme.get_theme()
	_zone = VBoxContainer.new()
	_zone.name = "AidZone"
	_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The offer card grows after its wrapped lines sort: re-anchor the zone to the bottom edge every time it sorts.
	_zone.minimum_size_changed.connect(_queue_layout)
	_zone.sort_children.connect(_queue_layout)
	add_child(_zone)
	_build_offer()
	_build_button()
	_build_tray()
	_apply_tokens()
	resized.connect(layout)


## AidButton (CSS .aid-btn): plate pill, btn_m high, 0 12 padding, gap 8: aid glyph icon_l · "Aid" · "0 of 6 used".
func _build_button() -> void:
	_button = Button.new()
	_button.name = "AidButton"
	_button.focus_mode = Control.FOCUS_ALL
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.pressed.connect(toggle_tray)
	_button.tooltip_text = "%s (%s)" % [TranslationServer.translate("Aid tray"), KeyBindings.text(KeyBindings.COMBAT_AID)]
	Ui5HudStyle.plate_button(_button, UI3Theme.radius("pill"))
	_zone.add_child(_button)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(row)
	_aid_icon = Ui5HudStyle.icon_rect(HudKit.icon("aid"), UI3Theme.size_of("icon_l"))
	row.add_child(_aid_icon)
	var t := UI3.label(TranslationServer.translate("Aid"), "LabelDisplay")
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(t)
	_used_label = UI3.label("", "LabelMuted")
	_used_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_used_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_used_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_used_label.clip_text = true
	row.add_child(_used_label)


## Size tokens, read again after a window-scale change (aid_w is 342 logical at 1280; body text 21).
func _apply_tokens() -> void:
	_scale_seen = UI3Theme.current_scale()
	var w := float(UI3Theme.size_of("aid_w"))
	_zone.custom_minimum_size = Vector2(w, 0)
	_zone.add_theme_constant_override("separation", UI3Theme.space("16"))
	_button.custom_minimum_size = Vector2(w, UI3Theme.size_of("btn_m"))
	var row := _button.get_node("Row") as HBoxContainer
	row.offset_left = UI3Theme.space("12")
	row.offset_right = -UI3Theme.space("12")
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	_aid_icon.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_l")
	_offer_card.custom_minimum_size = Vector2(w, 0)


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


## AidOffer (CSS .aid-offer): plate fill, radius xl, a stroke_btn gem_border bevel, gem_lip lip, 16 20 padding,
## gap 8. Gem violet = the one place Aid says "this costs Gem"; End turn stays the one amber primary.
func _build_offer() -> void:
	_offer_card = PanelContainer.new()
	_offer_card.name = "AidOffer"
	_offer_card.visible = false
	_offer_card.theme = UI3Theme.get_theme()
	_offer_card.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"),
		UI3Theme.stroke("btn"), UI3Theme.color("gem_border"),
		Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16")),
		{"y": Ui5HudStyle.lip(), "color": UI3Theme.color("gem_lip")}))
	_zone.add_child(_offer_card)
	_offer_box = VBoxContainer.new()
	_offer_box.add_theme_constant_override("separation", UI3Theme.space("8"))
	_offer_box.sort_children.connect(_queue_layout)
	_offer_card.add_child(_offer_box)


# ── State ────────────────────────────────────────────────────────────────────────────────────

## `d`: enabled(bool), used(int), cap(int), rows(Array), offer(Dictionary).
func set_state(d: Dictionary) -> void:
	enabled = bool(d.get("enabled", true))
	used = int(d.get("used", 0))
	cap = int(d.get("cap", 6))
	rows = d.get("rows", [])
	offer = d.get("offer", {})
	dimmed = bool(d.get("dim", false))
	visible = enabled
	var u := TranslationServer.translate("%d of %d used") % [used, cap]
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
	_offer_card.visible = not v and not offer.is_empty() and not waiting
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
	if not on:
		# A row you cannot buy reads as disabled: dark panel fill, hairline border, muted text (not the live slate).
		var dim := UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 2, UI3Theme.color("disabled_border"),
			Vector4(16, 8, 12, 8))
		for st in ["disabled", "normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, dim)
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
	name_l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
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
	_offer_card.visible = not _tray.visible and not waiting
	var inner := float(UI3Theme.size_of("aid_w")) - 2.0 * (UI3Theme.space("20") + UI3Theme.stroke("btn"))
	var once := UI3.label(TranslationServer.translate("Aid offer · once"), "LabelMuted")
	once.name = "Once"
	_offer_box.add_child(once)
	var title := UI3.label(TranslationServer.translate(String(offer.get("title", ""))), "LabelTitle")
	title.name = "Title"
	_offer_box.add_child(title)
	var what := UI3.label(TranslationServer.translate(String(offer.get("what", ""))), "")
	what.name = "What"
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.custom_minimum_size = Vector2(inner, 0)
	_offer_box.add_child(what)
	for cap_line in offer.get("caps", []):
		var cl := UI3.label(String(cap_line), "LabelMuted")
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.custom_minimum_size = Vector2(inner, 0)
		_offer_box.add_child(cl)
	# Actions (margin-top 8, gap 12): AidBuyButton (gem: "Buy" + Gem CostChip) · AidNotNow (quiet). A flow row, so a
	# long "Need N more Gem" reason wraps "Not now" under it instead of leaving the card.
	var short := _short(offer)
	var buy := Button.new()
	buy.name = "AidBuyButton"
	buy.theme = UI3Theme.get_theme()
	buy.text = TranslationServer.translate("Buy")
	buy.focus_mode = Control.FOCUS_ALL
	buy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_gem_button(buy, short > 0)
	var chip := Ui5HudStyle.cost_chip(&"gem", int(offer.get("price", 0)))
	buy.add_child(chip)
	buy.pressed.connect(_ask.bind(String(offer.get("id", ""))))
	if short > 0:
		UI3.set_disabled_reason(buy, TranslationServer.translate("Need %d more Gem") % short)
	var no := UI3.button(TranslationServer.translate("Not now"), &"quiet", &"S")
	no.name = "AidNotNow"
	no.add_theme_color_override("font_color", UI3Theme.color("text"))
	no.add_theme_color_override("font_hover_color", UI3Theme.color("text"))
	no.add_theme_color_override("font_focus_color", UI3Theme.color("text"))
	# Trust rule: the decline is as tall as Buy (the HTML draws it 44; the hit area is btn_m, it has no fill).
	no.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_m"))
	no.pressed.connect(func():
		offer = {}
		offer_dismissed.emit()
		_rebuild_offer()
		layout())
	var pad := MarginContainer.new()
	pad.name = "Actions"
	pad.add_theme_constant_override("margin_top", UI3Theme.space("8"))
	var brow := HFlowContainer.new()
	brow.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	brow.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	brow.custom_minimum_size = Vector2(inner, 0)
	brow.add_child(buy)
	brow.add_child(no)
	pad.add_child(brow)
	_offer_box.add_child(pad)
	buy.resized.connect(_fit_buy)


## Gem button (CSS .btn-gem): btn_m high, gem_bg, stroke_btn gem_border bevel, gem_lip lip, Rowdies title in gem_text,
## 0 20 padding. The disabled reason ("Need N more Gem") drops to body size and 0 12 padding so it fits aid_w.
func _gem_button(b: Button, short: bool) -> void:
	var pad := UI3Theme.space("12") if short else UI3Theme.space("20")
	b.set_meta("pad", pad)
	var m := Vector4(pad, 0, pad, 0)
	var normal := UI3Theme.flat(UI3Theme.color("gem_bg"), UI3Theme.radius("m"), UI3Theme.stroke("btn"),
		UI3Theme.color("gem_border"), m, {"y": Ui5HudStyle.lip(), "color": UI3Theme.color("gem_lip")})
	var pressed := UI3Theme.flat(UI3Theme.color("gem_bg"), UI3Theme.radius("m"), UI3Theme.stroke("btn"),
		UI3Theme.color("gem_border"), m, {"y": Ui5HudStyle.lip("lip_pressed"), "color": UI3Theme.color("gem_lip")})
	var shift := maxi(Ui5HudStyle.lip() - Ui5HudStyle.lip("lip_pressed"), 0)
	pressed.expand_margin_top = -shift
	pressed.expand_margin_bottom = shift
	var disabled := UI3Theme.flat(UI3Theme.color("gem_bg"), UI3Theme.radius("m"), UI3Theme.stroke("btn"),
		UI3Theme.color("gem_border"), m)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("m")))
	b.add_theme_font_override("font", UI3Theme.font_display())
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body" if short else "text_title"))
	for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(fc, UI3Theme.color("gem_text"))
	b.custom_minimum_size = Vector2(UI3Theme.size_of("hit_min"), UI3Theme.size_of("btn_m"))
	b.clip_text = false


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


## Server request in flight (02-combat--waiting): the offer hides, the zone dims to 0.4; the bar stays.
func set_waiting(on: bool) -> void:
	waiting = on
	_offer_card.visible = not on and not offer.is_empty() and not _tray.visible
	layout()


func tray_top_hint(tray_top: float) -> void:
	_tray_top = tray_top
	layout()


## Top edge of the lowest-left Aid element that is showing (tray, else the AidZone: offer card or the button).
func top_y() -> float:
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	if not enabled:
		return h - EDGE
	if _tray != null and _tray.visible:
		return _tray.position.y
	return h - float(UI3Theme.space("screen")) - _zone_height()


## Buy + its Gem chip: reserve the chip's width in the button, then place the chip after the centred text.
func _fit_buy() -> void:
	var buy := _offer_box.find_child("AidBuyButton", true, false) as Button
	if buy == null or not buy.is_inside_tree():
		return
	Ui5HudStyle.place_trailing(buy, buy.find_child("CostChip", true, false) as Control, int(buy.get_meta("pad", 0)))


var _layout_queued := false

func _queue_layout() -> void:
	if _layout_queued:
		return
	_layout_queued = true
	(func() -> void:
		_layout_queued = false
		if is_inside_tree() and _zone_off():
			layout()).call_deferred()


## True when the zone is not exactly at its minimum height on the bottom edge (a wrapped line changed it).
func _zone_off() -> bool:
	var h := size.y if size.y > 1.0 else get_viewport_rect().size.y
	var want := _zone.get_combined_minimum_size().y
	return absf(_zone.size.y - want) > 0.5 or absf(_zone.position.y + _zone.size.y - (h - float(UI3Theme.space("screen")))) > 0.5


func _zone_height() -> float:
	_zone.size = Vector2.ZERO
	return _zone.get_combined_minimum_size().y


func layout() -> void:
	if not is_equal_approx(UI3Theme.current_scale(), _scale_seen):
		_apply_tokens()
		if not offer.is_empty():
			_rebuild_offer()
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	var edge := float(UI3Theme.space("screen"))
	_fit_buy()
	var zh := _zone_height()
	_zone.size = Vector2(float(UI3Theme.size_of("aid_w")), zh)
	_zone.position = Vector2(edge, h - edge - zh)
	_zone.modulate.a = 0.4 if (waiting or dimmed) else 1.0
	_tray.size = Vector2.ZERO
	var th := _tray.get_combined_minimum_size().y
	_tray.size = Vector2(TRAY_W, th)
	var btn_top := h - edge - float(UI3Theme.size_of("btn_m"))
	_tray.position = Vector2(edge, btn_top - UI3Theme.space("8") - th)
