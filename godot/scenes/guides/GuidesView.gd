extends Control
## SAMPLE TEAMS — the four starter compositions, with why each one works and how to play it.
## Port of `scGuideBody()` (src/client.html:6858) over `ContentDB.GUIDES`.
##
## v2 RESTYLE (docs/design-handoff-v2 §PASS·UNLOCKS·VAULT·GUIDES·CODEX, screenshot
## `screenshots/13-guides.png`): plate + scrim background, four cream cards side by side under an
## archetype-coloured HEADER BAND. Text is unchanged — every "why"/"how" line is still the live
## game's own copy, untouched by this pass.
##
## SUPERSEDES the 2026-09-19 art-director call to use a left-edge ArchStripe instead of a header
## band (see git history / the removed comment this replaces). That call predates the v2 mockup,
## which puts the archetype colour on a header band exactly like every other card on these four
## screens (Vault's class-coloured header, the Codex's CLASSES cards). Per the handoff's own rule
## ("where the spec and a mockup disagree, the mockup is right") this screen now matches the other
## three rather than keeping a bespoke layout be the only screen still doing it differently.
##
## WHY THIS EXISTS AT ALL. Picking five Axies out of eighteen with no idea what any of them do
## together is the hardest moment in the game, and it happens before the player has learned
## anything. The JS build answers it with four worked examples and a one-click "use this team".
##
## WHY IT IS A SCREEN AND NOT A CODEX TAB. In JS these live behind `scCodex()`'s tab bar purely
## because they shared a header. The Codex (a ten-tab rules book) is unported and, per the
## handover, has to be re-audited sentence by sentence against the Godot rules before any of it
## can be copied — it currently says "12 waves" and describes a JS-shaped undo, both wrong here.
## Waiting for that would hold four self-contained cards hostage to a much bigger job.

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

# Matches the mockup exactly — this is the one background of the four meta screens that already
# exists on disk under the name the mockup itself uses.
const BG_TEXTURE := "res://assets/backgrounds/origins/scene/5-crossroad.jpg"


func _ready() -> void:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT)

	_build_header()

	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = 52.0
	scroll.offset_right = -52.0
	scroll.offset_top = 166.0
	scroll.offset_bottom = -30.0
	scroll.anchor_bottom = 1.0
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	# ScrollContainer does not clip its content by default in this Godot version — without
	# this, a list longer than the container's rect draws straight through it and over
	# whatever sits below (found on the Unlocks QA capture: row 10 bled past the panel and
	# over the BACK button).
	scroll.clip_contents = true
	add_child(scroll)

	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for guide in ContentDB.GUIDES:
		var card := _build_card(guide)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(420, 0)
		row.add_child(card)

	_build_back_button()


func _build_header() -> void:
	var col := VBoxContainer.new()
	col.name = "HeaderCol"
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	col.offset_left = 52.0
	col.offset_right = -52.0
	col.offset_top = 44.0
	col.add_theme_constant_override("separation", 9)
	add_child(col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 6)))
	var eyebrow := DangoTheme.display_label("FOUR COMPOSITIONS THAT WORK", 14,
		DangoTheme.INK_ON_PRIMARY, 800)
	eyebrow.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow)
	col.add_child(chip)

	col.add_child(DangoTheme.display_label("SAMPLE TEAMS", 52, DangoTheme.CREAM_RAISED))


func _build_card(guide: Dictionary) -> PanelContainer:
	var arch_key := str(guide.get("arch", ""))
	var arch: Dictionary = ContentDB.ARCH.get(arch_key, {})
	# A missing archetype is a data error, not a styling choice — fall back to a neutral colour
	# rather than to some other archetype's, so it does not masquerade as a real one.
	var accent := Color(str(arch.get("c", ""))) if arch.has("c") else DangoTheme.PANEL_RAISED

	var card := PanelContainer.new()
	card.name = "Guide_" + str(guide.get("id", ""))
	card.add_theme_stylebox_override("panel", DangoTheme.cream_card_style(Color.TRANSPARENT))

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)

	# Header band — archetype colour, matching Vault's class-coloured header and Codex's
	# CLASSES cards rather than the pre-v2 left-edge stripe (see the class doc comment above).
	var band := PanelContainer.new()
	band.name = "ArchBand"
	band.custom_minimum_size = Vector2(0, 66)
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = accent
	band_sb.border_width_bottom = 4
	band_sb.border_color = Color.BLACK
	band_sb.corner_radius_top_left = 11
	band_sb.corner_radius_top_right = 11
	band_sb.content_margin_left = 15.0
	band_sb.content_margin_right = 15.0
	band_sb.content_margin_top = 10.0
	band_sb.content_margin_bottom = 10.0
	band.add_theme_stylebox_override("panel", band_sb)
	outer.add_child(band)

	var band_row := HBoxContainer.new()
	band_row.add_theme_constant_override("separation", 11)
	band.add_child(band_row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(42, 42)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = DangoTheme.CREAM_RAISED
	badge_sb.border_color = Color.BLACK
	badge_sb.set_border_width_all(3)
	badge_sb.set_corner_radius_all(11)
	badge.add_theme_stylebox_override("panel", badge_sb)
	var badge_lbl := Label.new()
	badge_lbl.text = str(arch.get("ic", "?"))
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 21)
	badge_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	badge.add_child(badge_lbl)
	band_row.add_child(badge)

	var band_text := VBoxContainer.new()
	band_text.add_theme_constant_override("separation", 2)
	band_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	band_row.add_child(band_text)

	var name_lbl := DangoTheme.display_label(str(guide.get("n", "")), 22, DangoTheme.INK)
	band_text.add_child(name_lbl)

	var arch_lbl := DangoTheme.display_label(str(arch.get("n", arch_key.to_upper())), 12,
		DangoTheme.INK, 800)
	arch_lbl.name = "ArchLabel"
	arch_lbl.add_theme_constant_override("line_spacing", 0)
	band_text.add_child(arch_lbl)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 15)
	outer.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var diff_lbl := DangoTheme.display_label(str(guide.get("diff", "")), 12,
		DangoTheme.INK_ON_CREAM_MUTED, 800)
	diff_lbl.add_theme_constant_override("line_spacing", 0)
	col.add_child(diff_lbl)

	col.add_child(_build_team_strip(guide.get("team", []), accent))

	var why := _cream_body_label(str(guide.get("why", "")))
	col.add_child(why)

	var how_col := VBoxContainer.new()
	how_col.add_theme_constant_override("separation", 7)
	how_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(how_col)
	for line in guide.get("how", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var bullet := PanelContainer.new()
		bullet.custom_minimum_size = Vector2(7, 7)
		bullet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var bullet_sb := StyleBoxFlat.new()
		bullet_sb.bg_color = accent
		bullet_sb.border_color = Color.BLACK
		bullet_sb.set_border_width_all(2)
		bullet_sb.set_corner_radius_all(2)
		bullet.add_theme_stylebox_override("panel", bullet_sb)
		row.add_child(bullet)
		var text := _cream_body_label(str(line))
		text.add_theme_font_size_override("font_size", 12)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		how_col.add_child(row)

	var use := Button.new()
	use.name = "UseButton"
	use.text = "USE THIS TEAM"
	use.custom_minimum_size = Vector2(0, 50)
	DangoTheme.style_button(use, true)
	use.pressed.connect(_on_use_pressed.bind(guide))
	col.add_child(use)
	return card


## One class-tinted, class-portrait square per member, no name label under it — matches the
## mockup exactly (`m.cls` background, portrait `object-fit: cover`, no caption). `TeamStrip`'s
## direct-child count (5) is asserted by t_guides_daily.gd, so the wrapper stays a flat row.
func _build_team_strip(team: Array, accent: Color) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "TeamStrip"
	strip.add_theme_constant_override("separation", 6)
	for key in team:
		var hero: Dictionary = ContentDB.heroes.get(str(key), {})
		var cls := str(hero.get("cls", ""))
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(56, 56)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_sb := StyleBoxFlat.new()
		slot_sb.bg_color = DangoTheme.class_color(cls) if not cls.is_empty() else accent
		slot_sb.border_color = Color.BLACK
		slot_sb.set_border_width_all(3)
		slot_sb.set_corner_radius_all(10)
		slot.add_theme_stylebox_override("panel", slot_sb)

		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var portrait_path := "res://assets/portraits/%s.png" % cls
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
		slot.add_child(portrait)
		strip.add_child(slot)
	return strip


## Puts the guide's team where the menu will pick it up, and returns it. SEPARATE from the
## navigation below on purpose: a test cannot exercise a method that changes the scene, because
## changing the scene frees the test's own tree and nothing is left to report a result. (Found
## the hard way — the first version did both, and the gate hung forever instead of failing.)
##
## The hand-off is a static var on `MainMenu` rather than a field on `RunState` or `MetaState`.
## A team the player is CONSIDERING is not run state — no run exists yet — and it is certainly
## not persistent state; putting it in either would mean a half-made choice surviving a crash, or
## a saved run's roster and a menu preselection living in the same place and eventually being
## confused for each other.
static func hand_team_to_menu(guide: Dictionary) -> Array[String]:
	var team: Array[String] = []
	for k in guide.get("team", []):
		team.append(str(k))
	MainMenu.pending_team = team
	return team


func _on_use_pressed(guide: Dictionary) -> void:
	hand_team_to_menu(guide)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(52, -44 - 24)
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back)


func _cream_body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	return lbl
