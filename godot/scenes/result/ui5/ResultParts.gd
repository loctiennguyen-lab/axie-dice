class_name Ui5ResultParts
extends RefCounted
## UI-05 b23 lane S6: small builders for the Result screen (round-3 ui05-meta1-screens.html, frames 10-result--*).
## Every size is a token (UI3Theme); no helper is added to UI3.gd. Node names are the frame data-names.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.tag` pill: Rowdies text_key on a filled pill. `bg`/`fg` are colour tokens. NewBestChip / NewTitleRow use cream
## on ink (`.tag.next`), the combo tags use combo_full / combo_pair.
static func tag(text: String, node_name: String, bg := "text", fg := "text_ink") -> PanelContainer:
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color(bg), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4"))), node_name)
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	var l := PanelParts.text(text, "text_key", fg, true)
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## `.rcard`: raised card, padding 12 / 16, gap 8. Returns {card, col}.
static func card(node_name: String) -> Dictionary:
	var p := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16"), "m"), node_name)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(col)
	return {"card": p, "col": col}


## `.disc.ok` with the tick (ToneDisc): toast_ok fill, ui_check in ink, never colour alone.
static func tone_disc() -> PanelContainer:
	var d := UI3Theme.size_of("toast_dot")
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("toast_ok"), int(d / 2.0), 0, Color.TRANSPARENT,
		Vector4(0, 0, 0, 0)), "ToneDisc")
	p.custom_minimum_size = Vector2(d, d)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := TextureRect.new()
	ic.texture = UI3.icon("ui_check")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = UI3Theme.color("text_ink")
	ic.custom_minimum_size = Vector2.ONE * d * 0.7
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(ic)
	return p


## SavedLine / CopiedLine: ToneDisc + body text, 8 apart.
static func tone_line(text: String, node_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = node_name
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.add_child(tone_disc())
	var l := UI3.label(text)
	l.name = "Text"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row


## XpDisc: `.xp`, xp_disc px accent pill with "XP" (no Pass XP icon in the art kit).
static func xp_disc() -> PanelContainer:
	var d := UI3Theme.size_of("xp_disc")
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("accent"), int(d / 2.0), 0, Color.TRANSPARENT,
		Vector4(0, 0, 0, 0)), "XpDisc")
	p.custom_minimum_size = Vector2(d, d)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := PanelParts.text("XP", "text_key", "text_ink", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## ComboRow / ComboRowFull: chip fill, Full has a 3 px rank_full_frame inset frame; name left, tag right.
static func combo_row(node_name: String, name_text: String, full: bool) -> PanelContainer:
	var sb := UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("s"), UI3Theme.stroke("rim") + 1 if full else 0,
		UI3Theme.color("rank_full_frame") if full else UI3Theme.color("chip"),
		Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8")))
	var p := PanelParts.panel(sb, node_name)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(row)
	var nm := PanelParts.text(name_text, "text_body", "text", true)
	nm.name = "ComboName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	var t := tag(TranslationServer.translate("Full") if full else TranslationServer.translate("Pair"), "ComboTier",
		"combo_full" if full else "combo_pair", "text_ink")
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.name = "ComboTierPill"
	(t.get_node("Text") as Label).name = "ComboTier"   # old checks read the label by this name
	row.add_child(t)
	return p
