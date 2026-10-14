class_name R3Shell
extends RefCounted
## Round 3 wide meta panel pieces shared by Team presets (M2) and Leaderboard (M9): the panel
## (width capped at PANEL_W, extra width becomes margin) inside the column DangoScreen.build()
## returns, wood header band 64, dusk state banner, confirm modal. Numbers: design/handoffs/
## ui-02-round3 README section 0. Positions are relationships, never a mockup y.

const PANEL_W := 1520.0
const BAND_H := 64.0


## DangoTheme.surface_style() with optional fill / border colour tokens for the few R3 cells
## (locked, dusk, pinned) that are not one of the Surface kinds.
static func surface(kind: DangoTheme.Surface = DangoTheme.Surface.CREAM_RAISED, radius := 20,
		border_w := 3, pad := Vector2(12, 12), fill: Variant = null, border: Variant = null) -> StyleBoxFlat:
	var sb := DangoTheme.surface_style(kind, radius, border_w, 0.0, pad)
	if fill is Color:
		sb.bg_color = fill
	if border is Color:
		sb.border_color = border
	return sb


## Plain label; `display` uses the project's Baloo helper (no per-Label font override here).
static func label(text: String, size: int, color: Color = DangoTheme.INK, display := false) -> Label:
	if display:
		return DangoTheme.display_label(text, size, color)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, w: float, h: float, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, maxf(h, 36))
	b.add_theme_font_size_override("font_size", 16 if h < 44 else 18)
	DangoTheme.style_button(b, primary)
	return b


## Builds the shell inside `host`. Returns {content, panel, col, header_right, banner_host,
## modal_layer, back, sub}.
static func build(host: Control, title: String, sub: String, on_back: Callable) -> Dictionary:
	var shell := DangoScreen.build(host, MockupAssets.tex("assets/bg/rocky.jpg"),
		DangoTheme.Scrim.DEFAULT, false)
	var content: Control = shell["content"]
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", surface(DangoTheme.Surface.CREAM, 28, 4, Vector2(-1, -1)))
	content.add_child(panel)
	# Full column height; width capped at PANEL_W and centred, so extra width is margin.
	var fit := func() -> void:
		var w := minf(content.size.x, PANEL_W)
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.anchor_top = 0.0
		panel.anchor_bottom = 1.0
		panel.offset_left = -w * 0.5
		panel.offset_right = w * 0.5
		panel.offset_top = 0
		panel.offset_bottom = 0
	fit.call()
	content.resized.connect(fit)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, BAND_H)
	var hb := StyleBoxFlat.new()
	hb.bg_color = DangoTheme.WOOD_TOP
	hb.border_color = DangoTheme.LINE
	hb.border_width_bottom = 4
	hb.content_margin_left = 8
	hb.content_margin_right = 16
	band.add_theme_stylebox_override("panel", hb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	band.add_child(row)
	var back := button("← Back  Esc", 150, 48)
	back.name = "Back"
	back.pressed.connect(on_back)
	row.add_child(back)
	var t := label(title, 36, DangoTheme.INK_ON_PRIMARY, true)
	t.name = "Title"
	row.add_child(t)
	var s := label(sub, 14, DangoTheme.INK)
	s.name = "Sub"
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var right := HBoxContainer.new()
	right.name = "HeaderRight"
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	col.add_child(band)
	var banner_host := VBoxContainer.new()
	banner_host.name = "BannerHost"
	col.add_child(banner_host)
	# Modals dim the whole column, above the panel.
	var modal := Control.new()
	modal.name = "Modals"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(modal)
	return {"content": content, "panel": panel, "col": col, "header_right": right,
		"banner_host": banner_host, "modal_layer": modal, "back": back, "sub": s}


## Dusk banner under the header: warning glyph, one sentence, one detail line, optional buttons
## [{text, primary, cb}] on the right.
static func banner(host: VBoxContainer, msg: String, detail: String, buttons: Array = []) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Banner"
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.DUSK
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	h.add_child(label("⚠", 28, DangoTheme.DUSK_INK))
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_child(label(msg, 18, DangoTheme.DUSK_INK, true))
	var d := label(detail, 14, DangoTheme.DUSK_INK)
	d.name = "Detail"
	t.add_child(d)
	h.add_child(t)
	for b in buttons:
		var btn := button(String(b["text"]), 160, 44, bool(b.get("primary", false)))
		btn.name = "Btn_" + String(b["text"]).replace(" ", "")
		btn.pressed.connect(b["cb"])
		h.add_child(btn)
	host.add_child(p)
	return p


static func clear(host: Node) -> void:
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()


## Full-column scrim with a centred child plate; returns the scrim (child of modal_layer).
static func scrim(modal_layer: Control, name: String) -> CenterContainer:
	var dim := ColorRect.new()
	dim.name = name
	dim.color = DangoTheme.SCRIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	return c


## Confirm modal 600 wide; focus starts on the decline button.
static func confirm(modal_layer: Control, title: String, body: String, keep_text: String,
		do_text: String, on_do: Callable, on_close: Callable) -> Control:
	var c := scrim(modal_layer, "Confirm")
	var p := PanelContainer.new()
	p.name = "ConfirmPlate"
	p.custom_minimum_size = Vector2(600, 0)
	p.add_theme_stylebox_override("panel", surface(DangoTheme.Surface.CREAM, 24, 4, Vector2(-1, -1)))
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 56)
	var hs := StyleBoxFlat.new()
	hs.bg_color = DangoTheme.WOOD_TOP
	hs.border_width_bottom = 4
	hs.border_color = DangoTheme.LINE
	hs.content_margin_left = 22
	head.add_theme_stylebox_override("panel", hs)
	head.add_child(label(title, 24, DangoTheme.INK_ON_PRIMARY, true))
	v.add_child(head)
	var pad := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 22)
	v.add_child(pad)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 18)
	pad.add_child(inner)
	var bl := label(body, 16)
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(bl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	inner.add_child(row)
	var keep := button(keep_text, 0, 60)
	keep.name = "Keep"
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep.pressed.connect(on_close)
	row.add_child(keep)
	var ok := button(do_text, 0, 60, true)
	ok.name = "Do"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(on_do)
	row.add_child(ok)
	keep.grab_focus.call_deferred()
	return c.get_parent()


## fit_or_scroll whose cap follows `panel`'s height (minus `reserve` px of chrome) instead of a
## fixed number, so it re-fits on every window size.
static func fit_in(inner: Control, panel: Control, reserve: float) -> ScrollContainer:
	var vp_h: float = panel.get_viewport_rect().size.y
	var sc := DangoScreen.fit_or_scroll(inner, maxf(220.0, vp_h - 2.0 * DangoScreen.SAFE - reserve))
	var refit := func() -> void:
		if not is_instance_valid(sc):
			return
		sc.custom_minimum_size.y = minf(inner.get_combined_minimum_size().y,
			maxf(220.0, panel.size.y - reserve))
	panel.resized.connect(refit)
	return sc
