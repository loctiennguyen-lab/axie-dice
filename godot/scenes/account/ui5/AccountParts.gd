extends RefCounted
## UI-05 b23 lane S8a1: builders for the Account screen (a01-a08), the desktop sign-in dialog (a09-a12) and the account toast
## (a17-a18). Source: round-3 ui05-meta1-screens.html (.acct, .meta-head, .dialog.s, .toast.bottom). Every size is a token;
## no illustration values here. Used through `const Parts := preload("res://scenes/account/ui5/AccountParts.gd")`.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.meta-head`: plate (radius l, pad 12 24 12 12, gap 16) with BackButton (56 square "←") and Title. Node "Header".
static func header(title: String, on_back: Callable) -> Dictionary:
	var box := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"),
		Vector4(UI3Theme.space("12"), UI3Theme.space("12"), UI3Theme.space("24"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink")))
	var p := PanelParts.panel(box, "Header")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(row)
	var back := PanelParts.button("←", &"secondary", &"M")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(UI3Theme.size_of("btn_m"), UI3Theme.size_of("btn_m"))
	back.tooltip_text = "Back · Esc"
	back.pressed.connect(on_back)
	row.add_child(back)
	var t := Ui5Text.label(title, "text_screen_title", "text", true)
	t.name = "Title"
	row.add_child(t)
	return {"header": p, "back": back}


## `.acct` (AccountPanel) or `.dialog.s` (DesktopSignIn): returns {"panel", "col"}. Account = radius l, pad 32, gap 16,
## account_w wide. Dialog = radius xl, pad 32, gap 20, modal_s_w wide.
static func box(node_name: String, dialog := false) -> Dictionary:
	var pad := UI3Theme.space("32")
	var st := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl" if dialog else "l"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(pad, pad, pad, pad), PanelParts.lip(UI3Theme.color("plate_ink")))
	var p := PanelParts.panel(st, node_name)
	p.custom_minimum_size.x = UI3Theme.size_of("modal_s_w" if dialog else "account_w")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20" if dialog else "16"))
	p.add_child(col)
	return {"panel": p, "col": col}


## `.brand`: AXIE DICE (text_title, Rowdies) + version (muted body).
static func brand(version: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.name = "BrandRow"
	r.add_theme_constant_override("separation", UI3Theme.space("12"))
	var b := Ui5Text.label("AXIE DICE", "text_title", "text", true)
	b.name = "Brand"
	r.add_child(b)
	var v := Ui5Text.label(version, "text_body", "text_muted")
	v.name = "Version"
	r.add_child(v)
	return r


## Banner line: optional ToneDisc (tone &"" = none) + text_banner title. `title_name` is the title's node name.
static func banner(text: String, tone := &"", title_name := "Heading") -> HBoxContainer:
	var r := HBoxContainer.new()
	r.name = "BannerRow"
	r.add_theme_constant_override("separation", UI3Theme.space("12"))
	if tone != &"":
		r.add_child(Ui5ToneDisc.make(tone))
	var t := Ui5Text.label(text, "text_banner", "text", true)
	t.name = title_name
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(t)
	return r


static func body(text: String, muted := false, node_name := "") -> Label:
	var l := Ui5Text.label(text, "text_body", "text_muted" if muted else "text")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if node_name != "":
		l.name = node_name
	return l


static func btn(node_name: String, text: String, variant := &"secondary", size := &"M", wide := false) -> Button:
	var b := PanelParts.button(text, variant, size)
	b.name = node_name
	if wide:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return b


## `.foot-row`: [secondary] [primary], gap 16.
static func foot_row(secondary: Button, primary: Button) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "FootRow"
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	h.add_child(secondary)
	h.add_child(primary)
	return h


## `.who`: raised cell with the avatar (48 disc, accent, initial) + name (title) and "email · Google" (muted).
static func who(display_name: String, sub: String) -> PanelContainer:
	var st := PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16"), "m")
	var p := PanelParts.panel(st, "Who")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(row)
	var av := PanelParts.panel(UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT), "Avatar")
	var d := UI3Theme.size_of("avatar")
	av.custom_minimum_size = Vector2(d, d)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ini := Ui5Text.label(display_name.left(1).to_upper(), "text_title", "text_ink", true)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(ini)
	row.add_child(av)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Ui5Text.label(display_name, "text_title", "text", true)
	nm.name = "AccountName"
	col.add_child(nm)
	col.add_child(Ui5Text.label(sub, "text_body", "text_muted"))
	row.add_child(col)
	return p


## `.kv`: raised row, one text_body line.
static func kv(text: String, node_name := "SaveStatus") -> PanelContainer:
	var st := PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("12"), "s")
	var p := PanelParts.panel(st, "Kv")
	p.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var l := body(text, false, node_name)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p
