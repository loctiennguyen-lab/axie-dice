extends Control
class_name AidPanel
## The paid "Aid" zone, bottom-left (Dice UI R1 README 3 "Left zone"): the Aid button, the single
## offer card, the Aid tray and the first-purchase confirm modal. Pure view: rows and prices come
## from the caller (`set_rows`, later `AidCatalog.offer()` from lane E); nothing is bought here, it
## only reports `purchase_confirmed(aid_id)`.
##
## Trust rules kept (monetization-v1): real price on every row (disabled rows too), the decline
## button is the same size as the buy button, no timers, the fairness line is verbatim, the Aid
## zone is 1,472 px from END TURN. Hidden entirely for newcomers (first 5 runs): no button, no
## offer, no tray (Liam 12/10).
##
## Geometry (relationships, README): button left 16 / bottom 16, 216 x 104; offer card left 16,
## bottom 132, 216 wide; tray 252 wide, left 16, bottom = tray top - 8, which keeps it left of
## Axie 1 and >= 16 px under the lowest monster box.

signal purchase_confirmed(aid_id: String)
signal tray_toggled(open: bool)
signal offer_dismissed

const FAIRNESS := "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
const BTN_W := 216.0
const BTN_H := 104.0
const EDGE := 16.0
const TRAY_W := 252.0

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
	_button = Button.new()
	_button.name = "AidButton"
	_button.custom_minimum_size = Vector2(BTN_W, BTN_H)
	_button.focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "disabled"]:
		_button.add_theme_stylebox_override(st, HudKit.box(DangoTheme.GEM_PANEL_TINT, 18, 3,
			DangoTheme.GEM_SHELF, Vector2(3, 5)))
	_button.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(18))
	_button.pressed.connect(toggle_tray)
	add_child(_button)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12.0
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	_button.add_child(row)
	row.add_child(HudKit.tex_rect(HudKit.icon("aid"), 44))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	col.add_child(HudKit.label("Aid %s" % HudKit.glyph(0x25B4, "^"), 22, DangoTheme.INK))
	_used_label = HudKit.label("", 13, DangoTheme.GEM_SHELF, 700)
	col.add_child(_used_label)
	col.add_child(HudKit.prose("Hide offers: Settings", 12, DangoTheme.INK_2))


func _build_tray() -> void:
	_tray = PanelContainer.new()
	_tray.visible = false
	_tray.custom_minimum_size = Vector2(TRAY_W, 0)
	var sb := HudKit.box(DangoTheme.CREAM_100, 22, 4, DangoTheme.GEM_SHELF, Vector2(4, 6))
	sb.content_margin_left = 0.0
	sb.content_margin_right = 0.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	_tray.add_theme_stylebox_override("panel", sb)
	_tray.z_index = 6
	add_child(_tray)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_tray.add_child(col)
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 44)
	var hsb := HudKit.box(DangoTheme.GEM_BOTTOM, 18, 0, DangoTheme.GEM_SHELF, Vector2.ZERO,
		DangoTheme.SHELF, Vector2(12, 0))
	hsb.border_width_bottom = 3
	head.add_theme_stylebox_override("panel", hsb)
	col.add_child(head)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 8)
	head.add_child(hrow)
	hrow.add_child(HudKit.tex_rect(HudKit.icon("aid"), 26))
	var t := HudKit.label("Aid", 20, DangoTheme.GEM_INK)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(t)
	_tray_used = HudKit.label("", 13, DangoTheme.CREAM_RAISED, 800)
	hrow.add_child(_tray_used)
	var body := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		body.add_theme_constant_override("margin_" + k, 10)
	col.add_child(body)
	var bcol := VBoxContainer.new()
	bcol.add_theme_constant_override("separation", 6)
	body.add_child(bcol)
	_tray_rows = VBoxContainer.new()
	_tray_rows.add_theme_constant_override("separation", 6)
	bcol.add_child(_tray_rows)
	var foot := HudKit.prose(FAIRNESS, 12, DangoTheme.INK_2)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(TRAY_W - 20.0, 0)
	bcol.add_child(foot)


func _build_offer() -> void:
	_offer_card = PanelContainer.new()
	_offer_card.visible = false
	_offer_card.custom_minimum_size = Vector2(BTN_W, 0)
	var sb := HudKit.box(DangoTheme.CREAM_100, 18, 3, DangoTheme.GEM_SHELF, Vector2(3, 5),
		DangoTheme.SHELF, Vector2(12, 12))
	_offer_card.add_theme_stylebox_override("panel", sb)
	add_child(_offer_card)
	_offer_box = VBoxContainer.new()
	_offer_box.add_theme_constant_override("separation", 8)
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
	_used_label.text = "used %d of %d" % [used, cap]
	_tray_used.text = "used %d of %d" % [used, cap]
	_rebuild_rows()
	_rebuild_offer()
	if not enabled:
		_tray.visible = false
	layout()


func is_open() -> bool:
	return _tray.visible


func toggle_tray() -> void:
	set_open(not _tray.visible)


func set_open(v: bool) -> void:
	if not enabled:
		return
	_tray.visible = v
	layout()
	tray_toggled.emit(v)


func _rebuild_rows() -> void:
	for c in _tray_rows.get_children():
		_tray_rows.remove_child(c)
		c.queue_free()
	for r in rows:
		_tray_rows.add_child(_row(r))


## One tray row: icon 26 · title (Baloo 15) + cap/reason 12 · price button 58 x 38. The real price
## shows even when the row is disabled; the reason is plain text in INK_DISABLED (readable).
func _row(r: Dictionary) -> Control:
	var on := bool(r.get("enabled", false))
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 52)
	p.add_theme_stylebox_override("panel", HudKit.box(
		DangoTheme.CREAM_RAISED if on else DangoTheme.CREAM_DISABLED, 12, 3,
		DangoTheme.OUTLINE if on else DangoTheme.INK_3, Vector2.ZERO, DangoTheme.SHELF, Vector2(6, 4)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	row.add_child(HudKit.tex_rect(r.get("icon", HudKit.icon("aid")), 26, Color(1, 1, 1, 1.0 if on else 0.5)))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	col.add_child(HudKit.label(String(r.get("title", "")), 15, DangoTheme.INK if on else DangoTheme.INK_DISABLED))
	var sub := HudKit.prose(String(r.get("reason", "")) if not on and String(r.get("reason", "")) != ""
		else String(r.get("cap_text", "")), 12, DangoTheme.INK_2 if on else DangoTheme.INK_DISABLED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(96, 0)
	col.add_child(sub)
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 38)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not on
	DangoTheme.style_button(b, false, false, DangoTheme.GEM_INK, false, true)
	b.icon = HudKit.icon("gem")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 18)
	b.text = str(int(r.get("price", 0)))
	DangoTheme.apply_tracking(b, 0.0, 16, 800)
	b.pressed.connect(_ask.bind(String(r.get("id", ""))))
	row.add_child(b)
	return p


func _rebuild_offer() -> void:
	for c in _offer_box.get_children():
		_offer_box.remove_child(c)
		c.queue_free()
	if offer.is_empty():
		_offer_card.visible = false
		return
	_offer_card.visible = true
	_offer_box.add_child(HudKit.label("AID OFFER %s ONCE" % HudKit.dot(), 12, DangoTheme.GEM_SHELF, 800, 0.08))
	_offer_box.add_child(HudKit.label(String(offer.get("title", "")), 20, DangoTheme.INK))
	var what := HudKit.prose(String(offer.get("what", "")), 13, DangoTheme.INK_2)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.custom_minimum_size = Vector2(BTN_W - 24.0, 0)
	_offer_box.add_child(what)
	for cap_line in offer.get("caps", []):
		var cp := PanelContainer.new()
		cp.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.GEM_PANEL_TINT, 8, 0,
			DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(8, 2)))
		cp.add_child(HudKit.label(String(cap_line), 14, DangoTheme.GEM_SHELF))
		_offer_box.add_child(cp)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(192, 48)
	DangoTheme.style_button(buy, false, false, DangoTheme.GEM_INK, false, true)
	buy.icon = HudKit.icon("gem")
	buy.expand_icon = true
	buy.add_theme_constant_override("icon_max_width", 22)
	buy.text = str(int(offer.get("price", 0)))
	DangoTheme.apply_tracking(buy, 0.0, 19, 800)
	buy.pressed.connect(_ask.bind(String(offer.get("id", ""))))
	_offer_box.add_child(buy)
	var no := Button.new()
	no.custom_minimum_size = Vector2(192, 48)   # same size as the buy button, always
	no.text = "Not now"
	DangoTheme.style_button(no, false)
	DangoTheme.apply_tracking(no, 0.0, 18, 800)
	no.pressed.connect(func():
		offer = {}
		offer_dismissed.emit()
		_rebuild_offer()
		layout())
	_offer_box.add_child(no)


# ── Purchase confirm (02i) ───────────────────────────────────────────────────────────────────

func _ask(aid_id: String) -> void:
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
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	var r := _find_row(aid_id)
	var price := int(r.get("price", 0))
	var gems := int(r.get("gems", 0))
	_modal = Control.new()
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.z_index = 30
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var dim := ColorRect.new()
	dim.color = DangoTheme.SCRIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	var psb := HudKit.box(DangoTheme.CREAM_100, 26, 4, DangoTheme.GEM_SHELF, Vector2(5, 8))
	psb.content_margin_left = 0.0
	psb.content_margin_right = 0.0
	psb.content_margin_top = 0.0
	psb.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", psb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 56)
	var hsb := HudKit.box(DangoTheme.GEM_BOTTOM, 22, 0, DangoTheme.GEM_SHELF, Vector2.ZERO,
		DangoTheme.SHELF, Vector2(22, 0))
	hsb.border_width_bottom = 3
	head.add_theme_stylebox_override("panel", hsb)
	head.add_child(HudKit.label("Confirm purchase", 24, DangoTheme.GEM_INK))
	col.add_child(head)
	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 24)
	body.add_theme_constant_override("margin_right", 24)
	body.add_theme_constant_override("margin_top", 20)
	body.add_theme_constant_override("margin_bottom", 24)
	col.add_child(body)
	var bcol := VBoxContainer.new()
	bcol.add_theme_constant_override("separation", 14)
	body.add_child(bcol)
	var item := PanelContainer.new()
	item.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 14, 3,
		DangoTheme.OUTLINE, Vector2.ZERO, DangoTheme.SHELF, Vector2(12, 12)))
	bcol.add_child(item)
	var irow := HBoxContainer.new()
	irow.add_theme_constant_override("separation", 14)
	item.add_child(irow)
	irow.add_child(HudKit.tex_rect(r.get("icon", HudKit.icon("aid")), 48))
	var icol := VBoxContainer.new()
	icol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icol.add_theme_constant_override("separation", 0)
	irow.add_child(icol)
	icol.add_child(HudKit.label(String(r.get("title", "")), 22, DangoTheme.INK))
	icol.add_child(HudKit.prose(String(r.get("cap_text", "")), 13, DangoTheme.INK_2))
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 0)
	irow.add_child(pcol)
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_END
	prow.add_theme_constant_override("separation", 5)
	prow.add_child(HudKit.tex_rect(HudKit.icon("gem"), 28))
	prow.add_child(HudKit.label(str(price), 30, DangoTheme.INK))
	pcol.add_child(prow)
	var usd := HudKit.prose("%s %.2f USD" % [HudKit.glyph(0x2248, "~"), float(price) / 90.0], 13, DangoTheme.INK_2)
	usd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pcol.add_child(usd)
	var srow := HBoxContainer.new()
	bcol.add_child(srow)
	var g := HudKit.prose("Your Gem: %d %s %d" % [gems, HudKit.arrow(), gems - price], 14, DangoTheme.INK)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(g)
	srow.add_child(HudKit.prose("Aid this run: %d %s %d of %d" % [used, HudKit.arrow(), used + 1, cap], 14, DangoTheme.INK))
	var note := HudKit.prose("We ask once per session. Your spending limit and the option to hide Aid offers are in Settings.", 13, DangoTheme.INK_2)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(540, 0)
	bcol.add_child(note)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 14)
	bcol.add_child(brow)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(268, 60)
	DangoTheme.style_button(cancel, false)
	DangoTheme.apply_tracking(cancel, 0.0, 20, 800)
	cancel.pressed.connect(_close_modal)
	brow.add_child(cancel)
	var pay := Button.new()
	pay.text = "Pay %d" % price
	pay.icon = HudKit.icon("gem")
	pay.expand_icon = true
	pay.add_theme_constant_override("icon_max_width", 24)
	pay.custom_minimum_size = Vector2(268, 60)
	DangoTheme.style_button(pay, false, false, DangoTheme.GEM_INK, false, true)
	DangoTheme.apply_tracking(pay, 0.0, 20, 800)
	pay.pressed.connect(func():
		session_confirmed = true
		_close_modal()
		purchase_confirmed.emit(_pending_id))
	brow.add_child(pay)
	cancel.grab_focus()   # focus starts on Cancel (README 02i)


func _close_modal() -> void:
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null


func modal_open() -> bool:
	return _modal != null and is_instance_valid(_modal)


## Esc: closes the modal first, then the tray. Returns true if it consumed the key.
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


func layout() -> void:
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	_button.position = Vector2(EDGE, h - EDGE - BTN_H)
	_button.size = Vector2(BTN_W, BTN_H)
	_offer_card.size = Vector2.ZERO
	_offer_card.position = Vector2(EDGE, h - 132.0 - _offer_card.get_combined_minimum_size().y)
	_offer_card.size = Vector2(BTN_W, _offer_card.get_combined_minimum_size().y)
	var tray_top := h - EDGE - 176.0   # README: bottom = tray top - 8
	_tray.size = Vector2.ZERO
	var th := _tray.get_combined_minimum_size().y
	_tray.size = Vector2(TRAY_W, th)
	_tray.position = Vector2(EDGE, tray_top - 8.0 - th)
