class_name PassParts
extends RefCounted
## UI-05 b23 lane S10: pieces of the Season Pass screen (round-3 frames 21-pass--*). Pure drawing: no state, no claims.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


static func plate(node_name: String, pad_v: int, pad_h: int, rad := "l") -> PanelContainer:
	return PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius(rad), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(pad_h, pad_v, pad_h, pad_v), PanelParts.lip(UI3Theme.color("plate_ink"))), node_name)


## Notice under the header (data-name Banner): ToneDisc + title + one line.
static func banner(tone: StringName, title: String, body: String) -> PanelContainer:
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("notice_warn"), Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink"))), "Banner")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(tone))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Ui5Text.label(title, "text_body", "text", true)
	t.name = "Title"
	v.add_child(t)
	var b := Ui5Text.label(body, "text_body", "text")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	return p


## "ResultLine": tick disc + the outcome of the last claim.
static func result_line(text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "ResultLine"
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.add_child(Ui5ToneDisc.make(&"ok"))
	var l := Ui5Text.label(text, "text_title", "text")
	l.name = "Text"
	h.add_child(l)
	return h


## Tier of a cosmetic id from the manifest (0 = common).
static func tier_of(cos_id: String) -> int:
	var m: Dictionary = CosmeticArt.manifest()
	var art_id := Cosmetics.art_id(cos_id)
	var e: Variant = (m.get("dice", {}) as Dictionary).get(art_id, (m.get("frames", {}) as Dictionary).get(art_id, (m.get("fx", {}) as Dictionary).get(cos_id, {})))
	return int((e as Dictionary).get("tier", 0)) if e is Dictionary else 0


## "die" | "frame" | "FX" for the line under the name ("Uncommon frame").
static func kind_of(cos_id: String) -> String:
	var m: Dictionary = CosmeticArt.manifest()
	var art_id := Cosmetics.art_id(cos_id)
	if (m.get("dice", {}) as Dictionary).has(art_id):
		return "die"
	if (m.get("frames", {}) as Dictionary).has(art_id):
		return "frame"
	return "FX"


## "Uncommon frame" for a cosmetic id.
static func tier_kind(cos_id: String) -> String:
	return "%s %s" % [tier_word(tier_of(cos_id)), kind_of(cos_id)]


static func tier_word(tier: int) -> String:
	return String(DiceSkin.TIER_NAMES.values()[clampi(tier, 0, 5)])


## Cosmetic reward block: art box (px) with the tier colour on top, then name and tier word (rarity colour).
static func cosmetic_block(cos_id: String, art_px: float, node_name := "CosBlock") -> HBoxContainer:
	var tier := tier_of(cos_id)
	var h := HBoxContainer.new()
	h.name = node_name
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	var box := PanelContainer.new()
	box.name = "Mini"
	box.custom_minimum_size = Vector2(art_px, art_px)
	box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("s")))
	var art := CosmeticTile.art(cos_id, art_px - 8.0)
	if art != null:
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cc := CenterContainer.new()
		cc.add_child(art)
		box.add_child(cc)
	else:   # FX has no thumbnail: chip with the word FX (HTML .mini t-key)
		var kl := Ui5Text.label("FX", "text_body", "text_muted", true)
		kl.name = "FxKey"
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(kl)
	h.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm := Ui5Text.label(CosmeticTile.any_name(cos_id), "text_body", "text")
	nm.name = "RewardName"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var tw := Ui5Text.label(tier_word(tier), "text_body", "text")
	tw.name = "RewardTier"
	tw.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier))
	v.add_child(tw)
	h.add_child(v)
	return h


## Reward popup (LevelPopup): returns {root, close, claim (null when not claimable)}. Caller adds `root` to its modal layer,
## then calls place_claim_cap(). Space presses the focused button; focus starts on Claim when there is one.
static func level_popup(title: String, cos_ids: Array, lines: Array, claimable: bool) -> Dictionary:
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = "LevelPopup"
	root.add_to_group("ui3_modal")
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), "Dialog")
	dlg.custom_minimum_size.x = UI3Theme.size_of("modal_s_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var ttl := Ui5Text.label(title, "text_banner", "text", true)
	ttl.name = "Title"
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(ttl)
	for cid in cos_ids:
		col.add_child(cosmetic_block(String(cid), 96.0, "FrameArt"))
	for ln in lines:
		var l := Ui5Text.label(String(ln), "text_body", "text")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
	var close := PanelParts.button("Close", &"secondary", &"M")
	close.name = "CloseButton"
	var claim: Button = null
	if claimable:
		claim = PanelParts.button("Claim", &"primary", &"M")
		claim.name = "ClaimButton"
	col.add_child(Ui5ModalFooter.make(claim if claim != null else close, close if claim != null else null))
	root.actions = [close] if claim == null else [close, claim]
	root.focus_index = root.actions.size() - 1
	return {"root": root, "close": close, "claim": claim}


## Space keycap on the popup's Claim (call once the popup is in the tree).
static func place_claim_cap(claim: Button) -> void:
	if claim == null:
		return
	var cap := Ui5Keycap.make("Space", &"primary")
	claim.add_child(cap)
	var pad := UI3Theme.space("16")
	Ui5HudStyle.place_trailing(claim, cap, pad)
	claim.resized.connect(func() -> void:
		if is_instance_valid(claim) and is_instance_valid(cap):
			Ui5HudStyle.place_trailing(claim, cap, pad))
