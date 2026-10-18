class_name UI3Meta
extends RefCounted
## UI-03 meta-screen shell (handoff screens 19-29 "container tree"): bg neutral-1, margin 24, VBox gap 24:
## header HBox [title plate (back + Rowdies 32 title) · tabs · spacer · currency plate], a notice host,
## then the screen body. Built only from UI3 / UI3Theme. Shell dictionary keys match the old R3Shell so a
## screen can switch over without renaming: content, panel, col, header_right (tabs host), banner_host,
## modal_layer, back, sub.

const MARGIN := 24
const GAP := 24
## Tooltip of the back button; one place for the English (localisation hook).
const BACK_HINT := "Back · Esc"


## Builds the shell inside `host` (the scene root Control). `on_back` runs for the back button; Esc is the
## screen's own business (specs differ).
static func build(host: Control, title: String, sub: String, on_back: Callable) -> Dictionary:
	host.theme = UI3Theme.get_theme()
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bg)
	var pad := MarginContainer.new()
	pad.name = "Panel"
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, MARGIN)
	host.add_child(pad)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", GAP)
	pad.add_child(col)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", GAP)
	col.add_child(header)
	var tp := UI3.plate(&"plate")
	tp.name = "TitlePlate"
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", UI3Theme.space("16"))
	tp.add_child(trow)
	var back := UI3.button("←", &"secondary", &"S")
	back.name = "Back"
	back.custom_minimum_size = Vector2(48, 48)
	back.tooltip_text = BACK_HINT
	back.pressed.connect(on_back)
	trow.add_child(back)
	var t := UI3.label(title, "LabelScreenTitle")
	t.name = "Title"
	trow.add_child(t)
	var s := UI3.label(sub, "LabelMuted")
	s.name = "Sub"
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(s)
	header.add_child(tp)
	var right := HBoxContainer.new()
	right.name = "HeaderRight"
	right.add_theme_constant_override("separation", UI3Theme.space("8"))
	header.add_child(right)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	header.add_child(currency_plate())

	var banner_host := VBoxContainer.new()
	banner_host.name = "BannerHost"
	col.add_child(banner_host)
	var modal := Control.new()
	modal.name = "Modals"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(modal)
	return {"content": host, "panel": pad, "col": col, "header_right": right,
		"banner_host": banner_host, "modal_layer": modal, "back": back, "sub": s}


## Currency plate (node "Currencies"). Default = the wallet in Land hub order (UI3.currency_entries).
## `entries` overrides the cells ([{icon, value}]), `loading` shows "···", `hidden` hides the plate
## (signed out).
static func currency_plate(entries: Array = [], loading := false, hidden := false) -> PanelContainer:
	var p := UI3.currency_pill(entries if not entries.is_empty() else UI3.currency_entries(loading))
	p.name = "Currencies"
	p.visible = not hidden
	return p


## Tab button with optional key letter chip. Selected = toggled on.
static func tab(text: String, selected: bool, key := "") -> Button:
	return UI3.tab(text, selected, key)


## Small wood-2 tag ("NFT", "Equipped"): never amber (kam-6 is primary only).
static func tag(text: String) -> PanelContainer:
	var c := PanelContainer.new()
	c.theme = UI3Theme.get_theme()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(0, UI3.CHIP_H)
	c.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("notice_bg"), UI3Theme.radius("s"),
		2, UI3Theme.color("text_muted"), Vector4(12, 0, 12, 0)))
	var l := UI3.label(text, "LabelDisplay")
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c


## Notice row under the header: one sentence, one detail line, optional buttons [{name, text, primary, cb}]
## (`name` is the node name, required).
static func banner(host: VBoxContainer, msg: String, detail: String, buttons: Array = []) -> PanelContainer:
	var p := UI3.plate(&"notice")
	p.name = "Banner"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_child(UI3.label(msg, "LabelTitle"))
	var d := UI3.label(detail)
	d.name = "Detail"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(d)
	h.add_child(t)
	for b in buttons:
		var btn := UI3.button(String(b["text"]), &"primary" if bool(b.get("primary", false)) else &"secondary", &"M")
		btn.name = String(b["name"])
		btn.pressed.connect(b["cb"])
		h.add_child(btn)
	host.add_child(p)
	return p


static func clear(host: Node) -> void:
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()


## Full-rect scrim + centred container for a custom modal; returns the CenterContainer.
static func scrim(modal_layer: Control, name: String) -> CenterContainer:
	var dim := ColorRect.new()
	dim.name = name
	dim.color = UI3Theme.color("scrim")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	return c


## Confirm dialog (UI3.modal, 560 w). `destructive` (default): OK is the danger button and focus starts
## on `keep_text` (Cancel side). Otherwise OK is primary and has focus. Esc = keep.
static func confirm(modal_layer: Control, title: String, body: String, keep_text: String,
		do_text: String, on_do: Callable, on_close: Callable, destructive := true) -> Control:
	var keep := UI3.button(keep_text, &"secondary", &"M")
	keep.name = "Keep"
	keep.pressed.connect(on_close)
	var ok := UI3.button(do_text, &"danger" if destructive else &"primary", &"M")
	ok.name = "Do"
	ok.pressed.connect(on_do)
	var m := UI3.modal(title, body, [keep, ok], 0 if destructive else 1)
	m.name = "Confirm"
	m.cancelled.connect(on_close)
	modal_layer.add_child(m)
	return m


## Esc = back, unless a modal is open (the modal owns Esc then). True when the key was used.
static func esc_back(ev: InputEvent, shell: Dictionary, on_back: Callable) -> bool:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo or k.keycode != KEY_ESCAPE:
		return false
	if (shell["modal_layer"] as Control).get_child_count() > 0:
		return false
	on_back.call()
	return true


## Scrolls `inner` when it is taller than the space left in the column; never clips.
static func scroll(inner: Control) -> ScrollContainer:
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W   # visible overflow (t_ui_laws L2)
	sc.add_child(inner)
	return sc
