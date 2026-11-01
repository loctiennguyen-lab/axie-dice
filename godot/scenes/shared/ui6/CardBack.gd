class_name CardBack
extends Control
## UI-06 face-down Core card (CoreCardBack): tier frame + crest, back art in the middle (size.back_art), the tier
## word under it in the tier text colour. Same size as CoreCardShell. Nodes: TierFrame, TierCrest, Content >
## BackArt, TierWord.

var tier := 0


func setup(p_tier: int) -> CardBack:
	tier = clampi(p_tier, 0, 2)
	name = "CoreCardBack"
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h"))
	add_child(TierFrame.new().setup(tier))
	var content := CenterContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(v)
	var art := TextureRect.new()
	art.name = "BackArt"
	art.texture = UI6Assets.back_art(tier)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s := float(UI3Theme.size_of("back_art"))
	art.custom_minimum_size = Vector2(s, s)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art)
	var w := UI3.label(CoreVisuals.tier_name(tier), "LabelTitle")
	w.name = "TierWord"
	w.text = TranslationServer.translate(CoreVisuals.tier_name(tier))
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_theme_color_override("font_color", CoreVisuals.tier_text_color(tier))
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(w)
	var crest := TierCrest.new().setup(tier)
	add_child(crest)
	crest.place_on(custom_minimum_size)
	resized.connect(func(): crest.place_on(size))
	return self
