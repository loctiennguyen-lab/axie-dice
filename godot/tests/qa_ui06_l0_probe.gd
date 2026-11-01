extends Node
## UI-06 L0 gate: ONE static CoreCard x 3 tiers (Moss / Amber / Crystal) built from TierFrame + TierCrest + the art
## window nine-patch, to prove the nine-patch frames survive 1280x720 (card 280x500 real px, 100 px corner margins).
## Not headless. Run: godot/tools/shot.sh res://tests/qa_ui06_l0_probe.tscn 1920x1080  (and 1280x720)
## Output: $ADT_EVIDENCE_DIR/ui06_l0_probe_<width>.png

const NAMES := ["Dewdrop", "Kindle", "Sixth Die"]
const HEADS := ["+1 Mana every turn", "Cheaper Wild Face", "Finishing kills -> picks"]
const DETAIL := "Start of combat: front-row Axies gain 5 Shield."


func _ready() -> void:
	# Retina: DPR 2 makes a 1920 window read as scale 0.5 (clamped 0.667), so the scale is forced by env UI6_PROBE_SCALE.
	var want := OS.get_environment("UI6_PROBE_SCALE")
	if want != "":
		UI3Theme.set_scale_override(float(want))
	UI3Theme.sync_scale()
	var bg := ColorRect.new()
	bg.color = Color("#1d130c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI3Theme.get_theme()
	add_child(root)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.add_theme_constant_override("separation", 48)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(row)
	for t in 3:
		row.add_child(_card(t))
	await get_tree().create_timer(0.6).timeout
	var vp := get_viewport().get_visible_rect().size
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var tag := "1920" if UI3Theme.layout_scale() >= 0.99 else "1280"
	var path := "%s/ui06_l0_probe_%s.png" % [dir, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui06_l0_probe: saved %s win=%s vp=%s scale=%.3f card=%s" % [path, str(get_window().size), str(vp), UI3Theme.layout_scale(), str(Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h")))])
	get_tree().quit(0)


func _card(tier: int) -> Control:
	var card := Control.new()
	card.name = "CoreCard"
	card.custom_minimum_size = Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h"))
	card.add_child(TierFrame.new().setup(tier))
	var pad := UI3Theme.size_of("core_pad")
	var content := MarginContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, pad)
	content.add_theme_constant_override("margin_top", pad + 24)
	card.add_child(content)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	content.add_child(v)
	var aw := NinePatchRect.new()
	aw.name = "ArtWindow"
	aw.texture = UI6Assets.artwin(tier)
	var m := UI6Assets.ninepatch_margins("artwin_" + UI6Assets.tier_key(tier))
	aw.patch_margin_left = m.x
	aw.patch_margin_top = m.y
	aw.patch_margin_right = m.z
	aw.patch_margin_bottom = m.w
	aw.custom_minimum_size = Vector2(0, UI3Theme.size_of("core_art_h"))
	v.add_child(aw)
	var emb := TextureRect.new()
	emb.name = "FamilyEmblem"
	emb.texture = UI6Assets.family(["stat", "mana", "dice"][tier], UI3Theme.size_of("core_emblem"))
	emb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var es := float(UI3Theme.size_of("core_emblem"))
	emb.custom_minimum_size = Vector2(es, es)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aw.add_child(cc)
	cc.add_child(emb)
	var n := UI3.label(NAMES[tier], "LabelTitle")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var h := UI3.label(HEADS[tier])
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", UI3Theme.color("core_headline"))
	v.add_child(h)
	var d := UI3.label(DETAIL)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var crest := TierCrest.new().setup(tier)
	card.add_child(crest)
	crest.place_on(card.custom_minimum_size)
	return card
