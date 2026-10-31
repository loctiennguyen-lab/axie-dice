extends RefCounted
## UI-05 S9b: builders for the Echo Box ceremony (20-echo--opening / reveal-* / open10, round-3/ui05-meta2-screens.html).
## Node names = the frame data-names: Scrim, Ceremony, Title, ChestWord, Footer, SkipButton, KeyCap, RevealCard, TierStrip,
## Art (DiceSkinArt / FrameArt / FxArt / StoneIcon / NewChip / FragmentBadge / RaysProposal), Name, Line, RevealGrid,
## EquipButton, OpenAgainButton (CostChip), DoneButton. Every number is a token; names and rarity come from the pull
## result + cosmetics_manifest (CosmeticTile.any_name). Use through `preload`.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
## README/motion mark rays, sparks, ring, shake and hit-stop as PROPOSAL (not approved): code kept, off by default.
const PROPOSAL_FX := false
const Rays := preload("res://scenes/echobox/ui5/ceremony/CeremonyRays.gd")


static func t(s: String) -> String:
	return TranslationServer.translate(s)


## 0..5 (Common..Mythic); Stone is 0.
static func tier_of(r: Dictionary) -> int:
	if String(r.get("kind")) == "stone":
		return 0
	return maxi(EchoBox.RARITIES.find(String(r.get("rarity", "common"))), 0)


static func is_epic_plus(r: Dictionary) -> bool:
	return String(r.get("kind")) != "stone" and tier_of(r) >= 3


## Scrim + Ceremony column on it. Returns {scrim, ceremony, title}. The scrim is a child of `layer`, so the screen's
## close_modal() (which clears the layer) closes it.
static func modal(layer: Control, title_text: String) -> Dictionary:
	var c := UI3Meta.scrim(layer, "Scrim")
	var col := VBoxContainer.new()
	col.name = "Ceremony"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UI3Theme.space("24"))
	c.add_child(col)
	var title := PanelParts.text(title_text, "text_banner", "text", true)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", UI3Theme.color("plate_ink"))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(title)
	return {"scrim": c.get_parent(), "ceremony": col, "title": title}


## ChestWord plate: "<Gold> chest" in text_hero + the rarity word. `tint(0..1)` blends text colour -> tier colour and
## the rim -> tier colour (the "chest word tints in" layer).
static func chest_word(chest: String, sub: String, col: Color) -> PanelContainer:
	var box := Ui5HudStyle.plate_box(UI3Theme.radius("l"), Vector4(40, 24, 40, 24))
	var p := PanelParts.panel(box, "ChestWord")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(v)
	var hero := PanelParts.text(chest, "text_hero", "text", true)
	hero.name = "ChestName"
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hero)
	var line := PanelParts.text(sub, "text_body", "text_muted")
	line.name = "ChestRarity"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(line)
	p.set_meta("tier_color", col)
	set_tint(p, 0.0)
	return p


static func set_tint(p: PanelContainer, k: float) -> void:
	if not is_instance_valid(p):
		return
	var col: Color = p.get_meta("tier_color", Color.WHITE)
	var hero := p.find_child("ChestName", true, false) as Label
	hero.add_theme_color_override("font_color", UI3Theme.color("text").lerp(col, k))
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		var nb := sb.duplicate() as StyleBoxFlat
		nb.set_border_width_all(UI3Theme.stroke("selected") if k > 0.0 else UI3Theme.stroke("rim"))
		nb.border_color = UI3Theme.color("plate_rim").lerp(col, k)
		p.add_theme_stylebox_override("panel", nb)


## A button with a trailing Control (KeyCap or CostChip) centred after its text, safe at any scale: pins the variation's
## styles, then re-places on draw / resize. The trailing control hides while the button is disabled (no keycap or cost
## on a disabled button).
static func attach_trailing(b: Button, trailing: Control) -> void:
	b.add_child(trailing)
	var pad := int(UI3Theme.get_theme().get_stylebox("normal", b.theme_type_variation).content_margin_left)
	var sync := func() -> void:
		if not is_instance_valid(b) or not is_instance_valid(trailing) or not b.is_inside_tree():
			return
		var sig := "%s|%s|%s|%d|%d|%s" % [b.text, b.disabled, b.size, UI3Theme.size_of("keycap_h"),
			b.get_theme_font_size("font_size"), trailing.get_combined_minimum_size()]
		if String(b.get_meta("trail_sig", "")) == sig:
			return
		b.set_meta("trail_sig", sig)
		if not b.has_meta("styles_pinned"):
			b.set_meta("styles_pinned", true)
			for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
				var src: StyleBox = UI3Theme.get_theme().get_stylebox(st, b.theme_type_variation)
				if src != null:
					b.add_theme_stylebox_override(st, src.duplicate())
		trailing.visible = not b.disabled
		Ui5HudStyle.place_trailing(b, trailing, pad)
		b.update_minimum_size()
		b.queue_redraw()
	b.resized.connect(sync)
	b.minimum_size_changed.connect(func() -> void: sync.call_deferred())
	b.tree_entered.connect(func() -> void: sync.call_deferred())
	sync.call_deferred()


static func space_button(label: String, variant: StringName, node_name: String) -> Button:
	var b := PanelParts.button(label, variant, &"M")
	b.name = node_name
	var cap := Ui5Keycap.make("Space", &"primary" if variant == &"primary" else &"plain")
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.set_meta("cap", cap)
	return b


## OpenAgainButton: secondary M, "Open again" + CostChip (ticket icon + number, keycap_h high).
static func ticket_chip(amount: int) -> PanelContainer:
	var pad := UI3Theme.space("8")
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(pad, 0, pad, 0)), "CostChip")
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(Ui5HudStyle.icon_rect(UI3.currency_icon("cur_ticket", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s")))
	var l := PanelParts.text(UI3.fmt(amount), "text_body", "text", true)
	l.name = "Amount"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return p


# ---------------------------------------------------------------- RevealCard

static func slot_word(item: String) -> String:
	var slot := Cosmetics.slot_of(item)
	if slot == Cosmetics.SLOT_DIE:
		return t("dice skin")
	if slot == Cosmetics.SLOT_FRAME:
		return t("frame")
	return t("dice FX")


## One RevealCard. `single` = 480 x 660 (tokens reveal_card_*), else the 10-grid 300 x 380. Epic+ gets the 3 px tier
## border and the glow (reveal_glow); Rare+ cosmetics get RaysProposal unless `flashy` is false (Reduce flashing or motion).
## `screen` supplies the cosmetic art (`_cosmetic_art`: baked thumbnail / live 3D die / frame on the avatar).
static func card(screen: Node, r: Dictionary, single: bool, flashy: bool) -> PanelContainer:
	var stone := String(r.get("kind")) == "stone"
	var tier := tier_of(r)
	var rar := "common" if stone else String(r.get("rarity", "common"))
	var dup := bool(r.get("duplicate", false))
	var col := DiceSkin.tier_color(tier)
	var art_px := UI3Theme.size_of("reveal_art" if single else "grid_art")
	var card_w := UI3Theme.size_of("reveal_card_w" if single else "grid_card_w")
	var card_h := UI3Theme.size_of("reveal_card_h" if single else "grid_card_h")
	var sp12 := UI3Theme.space("12") if single else UI3Theme.space("8")
	var pad_b := UI3Theme.space("20")
	var epic := is_epic_plus(r)
	var box: StyleBoxFlat
	if epic:
		var glow := UI3Theme.color("reveal_glow") if tier < 5 else Color(col.r, col.g, col.b, 0.4)
		glow = Color(col.r, col.g, col.b, 0.4)
		box = UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), 3, col, Vector4(0, 0, 0, pad_b), {"y": 0, "color": glow, "size": 40})
	else:
		box = Ui5HudStyle.plate_box(UI3Theme.radius("xl"), Vector4(0, 0, 0, pad_b))
	var card := PanelParts.panel(box, "RevealCard")
	card.custom_minimum_size = Vector2(card_w, card_h)
	card.clip_contents = false   # the rounded TierStrip fits the corner; clipping would square off the glow
	card.set_meta("tier", tier)
	card.set_meta("single", single)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sp12)
	card.add_child(v)
	# TierStrip: rounded top corners = card radius minus the border, so it never pokes past the card's corner.
	var strip := Panel.new()
	strip.name = "TierStrip"
	var bw := box.border_width_top
	var cr := maxi(UI3Theme.radius("xl") - bw, 0)
	var strip_box := StyleBoxFlat.new()
	strip_box.bg_color = col
	strip_box.corner_radius_top_left = cr
	strip_box.corner_radius_top_right = cr
	strip.add_theme_stylebox_override("panel", strip_box)
	strip.custom_minimum_size = Vector2(0, 8 if single else 4)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(strip)
	# frame: .reveal .art margin-top space-12, on top of the column gap.
	var art_margin := MarginContainer.new()
	art_margin.name = "ArtMargin"
	art_margin.add_theme_constant_override("margin_top", UI3Theme.space("12"))
	art_margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(art_margin)
	var art := Panel.new()
	art.name = "Art"
	art.custom_minimum_size = Vector2(art_px, art_px)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.clip_contents = true
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l")))
	art_margin.add_child(art)
	var title := ""
	var line := ""
	var line_col := DiceSkin.tier_text_color(tier)
	if PROPOSAL_FX and not stone and tier >= 2 and flashy:
		var rays := Rays.new()
		rays.ray_color = col
		rays.spin = not UI3Motion.reduced()
		art.add_child(rays)
	var overlay := MarginContainer.new()
	overlay.name = "Overlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		overlay.add_theme_constant_override("margin_" + side, UI3Theme.space("8"))
	if stone:
		var ic := TextureRect.new()
		ic.name = "StoneIcon"
		ic.texture = UI3.icon("cur_stone_reveal")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var sp := art_px * 0.615
		var m := (art_px - sp) * 0.5
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = m
		ic.offset_top = m
		ic.offset_right = -m
		ic.offset_bottom = -m
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(ic)
		title = t("%s Stone") % UI3.fmt(int(r.get("amount", 0)))
		line = t("Currency")
		line_col = UI3Theme.color("text_muted")
	else:
		var item := String(r.get("item", ""))
		var a: Control = screen._cosmetic_art(item, art_px, single)
		var slot := Cosmetics.slot_of(Cosmetics.art_id(item))
		if a == null:
			a = screen._fx_badge(art_px)
			a.name = "FxArt"
		else:
			a.name = "DiceSkinArt" if slot == Cosmetics.SLOT_DIE else "FrameArt"
		art.add_child(a)
		title = CosmeticTile.any_name(item)
		line = "%s %s" % [t(rar.capitalize()), slot_word(item)]
		if dup:
			var season := r.has("season")
			var n := int(r.get("tickets_back", 0)) if season else int(r.get("fragments", 0))
			line = (t("Duplicate · +%d tickets") if season else t("Duplicate · %d Fragments")) % n
			line_col = UI3Theme.color("text")
			var badge := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
				Vector4(UI3Theme.space("4"), 0, UI3Theme.space("12"), 0)), "FragmentBadge")
			badge.size_flags_horizontal = Control.SIZE_SHRINK_END
			badge.size_flags_vertical = Control.SIZE_SHRINK_END
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.custom_minimum_size = Vector2(0, UI3Theme.size_of("icon_l") + 8)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", UI3Theme.space("4"))
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_child(row)
			row.add_child(Ui5HudStyle.icon_rect(UI3.currency_icon("cur_ticket" if season else "cur_fragment", UI3Theme.size_of("icon_l")),
				UI3Theme.size_of("icon_l")))
			var bl := PanelParts.text("+%d" % n, "text_title", "text", true)
			bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(bl)
			overlay.add_child(badge)
		else:
			var chip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("text"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
				Vector4(UI3Theme.space("8"), 0, UI3Theme.space("8"), 0)), "NewChip")
			chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("keycap_h"))
			var cl := PanelParts.text(t("New"), "text_key", "text_ink", true)
			cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(cl)
			overlay.add_child(chip)
	art.add_child(overlay)
	var nm := PanelParts.text("", "text_screen_title" if single else "text_title", "text", true)
	nm.name = "Name"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.custom_minimum_size.x = art_px
	nm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	Ui5Ellipsis.set_text(nm, title)
	var ln := PanelParts.text("", "text_body", "text")
	ln.name = "Line"
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ln.custom_minimum_size.x = art_px
	ln.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ln.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ln.add_theme_color_override("font_color", line_col)
	v.add_child(ln)
	Ui5Ellipsis.set_text(ln, line)
	return card
