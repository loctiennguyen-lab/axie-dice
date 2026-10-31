class_name Ui5PresetParts
extends RefCounted
## UI-05 b23 lane S4a: parts of the Team presets frames t01-t09 (round-3 ui05-land-screens.html).
## Seat / SeatMissing cells, the guest banner, the modal layer (Scrim + centred dialog) and the safe-first confirm.
## Every size is a token (UI3Theme.size_of / space), so the 1280 frames are the 1920 ones scaled. Names repeated on
## purpose (Seat, TeamCard ...) are added with add_child(x, true) by the caller.

const KIND := &"ui5_modal_kind"


## Portrait texture of a hero key ("" when the key is not a known hero).
static func portrait_tex(key: String) -> Texture2D:
	var def: Dictionary = ContentDB.heroes.get(key, {})
	if def.is_empty():
		return null
	return MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))


## Square portrait (data-name "Portrait", .portrait: chip fill, radius m). `px` = side in logical px.
static func portrait(key: String, px: int) -> Control:
	var p := PanelContainer.new()
	p.name = "Portrait"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("m")))
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = portrait_tex(key)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(t)
	return p


## One seat of a team (.seat, aspect 1 : 1.15). Hero = portrait + name; missing = "Missing" on the red seat colours.
## Name: "Seat" or "SeatMissing". Empty key with missing=false draws nothing useful: callers pass real heroes or missing.
static func seat(key: String, missing: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "SeatMissing" if missing else "Seat"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, int(round(UI3Theme.size_of("seat") * 1.15)))
	var pad := UI3Theme.space("4")
	if missing:
		p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("seat_missing_bg"), UI3Theme.radius("m"), 2,
			UI3Theme.color("seat_missing_border"), Vector4(pad, pad, pad, pad)))
	else:
		p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0,
			Color.TRANSPARENT, Vector4(pad, pad, pad, pad)))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER if missing else BoxContainer.ALIGNMENT_END
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	if not missing:
		var tr_ := TextureRect.new()
		tr_.name = "Portrait"
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr_.texture = portrait_tex(key)
		tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tr_.custom_minimum_size = Vector2(0, 0)
		v.add_child(tr_)
	var nm := Ui5Text.label("Missing" if missing else hero_name(key), "text_key", "seat_missing_border" if missing else "text")
	nm.name = "SeatName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.custom_minimum_size.x = 0
	v.add_child(nm)
	Ui5Ellipsis.set_text(nm, nm.text)
	return p


static func hero_name(key: String) -> String:
	return String((ContentDB.heroes.get(key, {}) as Dictionary).get("n", key))


static func class_name_of(key: String) -> String:
	return String((ContentDB.heroes.get(key, {}) as Dictionary).get("cls", "")).capitalize()


## Five seats in a row (.seats): equal columns, gap space-8. `keys` are hero keys, "" / unknown = a missing seat when
## `missing_of` says so.
static func seats(keys: Array, missing_of: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Seats"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	for k in keys:
		row.add_child(seat(String(k), bool(missing_of.call(String(k)))), true)
	return row


## "NFT" tag with the cream ring of the frame.
static func nft_tag() -> PanelContainer:
	var t := UI3Meta.tag("NFT")
	t.name = "NftTag"
	t.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 2,
		UI3Theme.color("text"), Vector4(UI3Theme.space("12"), 0, UI3Theme.space("12"), 0)))
	return t


## GuestBanner: ToneDisc (info) + two text lines + SignInButton (secondary S).
static func guest_banner(msg: String, detail: String, on_sign_in: Callable) -> PanelContainer:
	var p := UI3.plate(&"notice")
	p.name = "GuestBanner"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(&"info"))
	var t := VBoxContainer.new()
	t.name = "Txt"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_child(Ui5Text.label(msg, "text_body", "text", true))
	t.add_child(Ui5Text.label(detail, "text_body", "text"))
	h.add_child(t)
	var b := UI3.button("Sign in", &"secondary", &"S")
	b.name = "SignInButton"
	b.pressed.connect(on_sign_in)
	h.add_child(b)
	return p


## Modal layer entry: a full-rect root (blocks the screen, meta KIND) holding Scrim and a centred container; returns the
## container. The root is named "<Kind>Layer".
static func modal_root(layer: Control, kind: StringName) -> CenterContainer:
	var root := Control.new()
	root.name = "%sLayer" % String(kind).capitalize()
	root.set_meta(KIND, kind)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root, true)
	var dim := ColorRect.new()
	dim.name = "Scrim"
	dim.color = UI3Theme.color("scrim")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(c)
	return c


## Kind of a modal-layer child ("" when it is none of ours).
static func kind_of(root: Node) -> StringName:
	return StringName(root.get_meta(KIND, &""))


## Confirm dialog (DeleteConfirm / DiscardConfirm): Title (banner) + Body, Footer = [safe secondary with a Space keycap]
## ... [danger, no keycap]. The safe button is focused by the caller. Returns the dialog plate.
static func confirm(layer: Control, dialog_name: String, title: String, body: String, safe: Button, danger: Button) -> PanelContainer:
	var c := modal_root(layer, &"confirm")
	var d := UI3.plate(&"dialog")
	d.name = dialog_name
	d.custom_minimum_size.x = UI3Theme.size_of("modal_s_w")
	c.add_child(d)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("20"))
	d.add_child(v)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.add_child(head)
	var t := Ui5Text.label(title, "text_banner", "text", true)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(t)
	var b := Ui5Text.label(body, "text_body", "text")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(b)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(foot)
	foot.add_child(safe)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	foot.add_child(danger)
	attach_space_cap(safe)
	return d


## Space keycap after the label of `b` (plain variant), placed with Ui5HudStyle.place_trailing once `b` is in the tree.
static func attach_space_cap(b: Button) -> PanelContainer:
	var cap := Ui5Keycap.make("Space")
	b.add_child(cap)
	var sync := func() -> void:
		if not is_instance_valid(b) or not is_instance_valid(cap) or not b.is_inside_tree():
			return
		var sig := "%s|%s|%d|%s" % [b.text, b.size, b.get_theme_font_size("font_size"), cap.get_combined_minimum_size()]
		if String(b.get_meta("cap_sig", "")) == sig:
			return
		b.set_meta("cap_sig", sig)
		if not b.has_meta("styles_pinned"):
			b.set_meta("styles_pinned", true)
			for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
				var src: StyleBox = UI3Theme.get_theme().get_stylebox(st, b.theme_type_variation)
				if src != null:
					b.add_theme_stylebox_override(st, src.duplicate())
		var pad := int(b.get_theme_stylebox("normal").content_margin_left)
		Ui5HudStyle.place_trailing(b, cap, maxi(pad, UI3Theme.space("20")))
	b.resized.connect(sync)
	b.draw.connect(sync)
	sync.call_deferred()
	return cap
