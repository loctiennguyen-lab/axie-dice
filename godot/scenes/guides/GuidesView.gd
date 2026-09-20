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
const BG_MOCKUP_PLATE := "assets/bg/crossroad.jpg"

## FIX-PASS-02 §1 item 4: `content` already supplies the safe area and the 84px rail
## (`DangoScreen.RAIL_X`). The absolute margin this screen wants is narrower (52px), so the
## offset against `content` is `52 - 84 = -32` — preserving the same distance from the real
## screen edge the mockup asked for.
const SIDE_INSET := 52.0 - 84.0


func _ready() -> void:
	var shell := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PLATE),
		DangoTheme.Scrim.DEFAULT, true)
	var content: Control = shell["content"]

	_build_header(content)

	# NOT routed through `DangoScreen.fit_or_scroll()`: this ScrollContainer's job is the
	# OPPOSITE of that helper's — it is a horizontal carousel of up to 4 variable-height cards
	# (vertical scrolling is deliberately disabled; see the G1 comment below), and
	# `fit_or_scroll()` hard-disables horizontal scrolling to do its own vertical cap-and-scroll.
	# Applying it here would remove the only scroll axis this region actually needs. What DOES
	# change under the shell: `anchor_bottom = 1.0` no longer needs `SAFE_AREA + FOOTER_HEIGHT`
	# hand-computed against the raw viewport — `content`'s own bottom edge already excludes the
	# footer, so a plain `offset_bottom = 0` lands in the same place with no shared-constant
	# knowledge duplicated here.
	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = SIDE_INSET
	scroll.offset_right = -SIDE_INSET
	scroll.offset_top = 166.0 - 48.0   # mockup top:166, measured against `content`'s own top
	scroll.offset_bottom = 0.0
	scroll.anchor_bottom = 1.0
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	# ScrollContainer does not clip its content by default in this Godot version — without
	# this, a list longer than the container's rect draws straight through it and over
	# whatever sits below (found on the Unlocks QA capture: row 10 bled past the panel and
	# over the BACK button).
	scroll.clip_contents = true
	content.add_child(scroll)

	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.add_theme_constant_override("separation", 14)
	# GDE-01: the row hugs the TALLEST card rather than being stretched to the scroll's own
	# height. That is what stops the old "350-400px of empty cream below the CTA" without
	# giving up equal heights — see the card's own size_flags below.
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(row)

	for guide in ContentDB.GUIDES:
		var card := _build_card(guide)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# GDE-01: "four equal cards ... equal height with the CTA bottom-aligned across all
		# four". SIZE_FILL against a row that now hugs its tallest child gives exactly that —
		# every card is as tall as the longest one, and no taller.
		#
		# This reverses FIX-PASS-01 G1/L3, which set SHRINK_BEGIN and let the four cards end at
		# four different heights. That was the right call at the time: the ScrollContainer
		# (vertical scrolling disabled) forced the row to its own full height, that flowed onto
		# every card, and the slack piled up as 350-400px of empty cream under the CTA. The
		# slack had nowhere to go because the card's body was not flexible. It is now —
		# `how_col` is SIZE_EXPAND_FILL (see _build_card) — so the extra height lands in the
		# bullet list where GDE-01 puts it, and the row no longer inherits the scroll's height.
		# Both halves of that had to change together, which is why the old fix could only opt
		# out instead.
		card.size_flags_vertical = Control.SIZE_FILL
		card.custom_minimum_size = Vector2(420, 0)
		row.add_child(card)

	_build_footer(shell["footer"])


func _build_header(content: Control) -> void:
	var col := VBoxContainer.new()
	col.name = "HeaderCol"
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	col.offset_left = SIDE_INSET
	col.offset_right = -SIDE_INSET
	# RESTORED 2026-09-20: the mockup draws this header at `top:44`. It used to be clamped to
	# the old uniform 48px safe-area law; that law is gone (it now only checks that nothing is
	# clipped by the 1920x1080 canvas edge), so the mockup's own inset is back. `content`
	# starts at the shell's 48px line, so 44 is 4px above it.
	col.offset_top = 44.0 - 48.0
	col.add_theme_constant_override("separation", 9)
	content.add_child(col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 6)))
	var eyebrow := DangoTheme.display_label("FOUR COMPOSITIONS THAT WORK", 14,
		DangoTheme.INK_ON_PRIMARY, 800, 0.16)
	eyebrow.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow)
	col.add_child(chip)

	col.add_child(DangoTheme.display_label("SAMPLE TEAMS", 52, DangoTheme.CREAM_RAISED,
		800, 0.02))


func _build_card(guide: Dictionary) -> PanelContainer:
	var arch_key := str(guide.get("arch", ""))
	var arch: Dictionary = ContentDB.ARCH.get(arch_key, {})
	# A missing archetype is a data error, not a styling choice — fall back to a neutral colour
	# rather than to some other archetype's, so it does not masquerade as a real one.
	var accent := Color(str(arch.get("c", ""))) if arch.has("c") else DangoTheme.PANEL_RAISED

	var card := PanelContainer.new()
	card.name = "Guide_" + str(guide.get("id", ""))
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 17, 5, 7.0))
	DangoTheme.clip_to_frame(card)   # G3

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)

	# Header band — archetype colour, matching Vault's class-coloured header and Codex's
	# CLASSES cards rather than the pre-v2 left-edge stripe (see the class doc comment above).
	var band := PanelContainer.new()
	band.name = "ArchBand"
	band.custom_minimum_size = Vector2(0, 0)
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = accent
	band_sb.border_width_bottom = 4
	band_sb.border_color = Color.BLACK
	band_sb.corner_radius_top_left = 12
	band_sb.corner_radius_top_right = 12
	band_sb.content_margin_left = 15.0
	band_sb.content_margin_right = 15.0
	band_sb.content_margin_top = 12.0
	band_sb.content_margin_bottom = 12.0
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

	var name_lbl := DangoTheme.display_label(str(guide.get("n", "")), 22, DangoTheme.INK,
		800, 0.01)
	band_text.add_child(name_lbl)

	var arch_lbl := DangoTheme.display_label(str(arch.get("n", arch_key.to_upper())), 12,
		DangoTheme.INK, 800, 0.1)
	arch_lbl.name = "ArchLabel"
	arch_lbl.add_theme_constant_override("line_spacing", 0)
	band_text.add_child(arch_lbl)

	var margin := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 15)
	margin.add_theme_constant_override("margin_top", 13)   # mockup: padding 13px 15px 15px
	# GDE-01: the CTA is bottom-aligned across all four cards. `how_col` already expands, but it
	# can only push the button down if THIS block is given the card's spare height first —
	# without it the extra sat below the body as dead cream and each card's button landed
	# wherever its own copy happened to end.
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	# REVERSED 2026-09-20 (mockup pass): FIX-PASS-01 G4 pushed this to 13 on a type-floor
	# argument. The mockup draws 12, which is still exactly t_ui_laws' L8 floor, and
	# godot/CLAUDE.md rule 5 puts a mockup number above the old project floor.
	var diff_lbl := DangoTheme.display_label(str(guide.get("diff", "")), 12,
		DangoTheme.INK_ON_CREAM_MUTED, 800, 0.1)
	diff_lbl.add_theme_constant_override("line_spacing", 0)
	col.add_child(diff_lbl)

	col.add_child(_build_team_strip(guide.get("team", []), accent))

	var why := _cream_body_label(str(guide.get("why", "")))
	why.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_UI_SEMI, 13, 1.5))
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
		text.add_theme_constant_override("line_spacing",
			DangoTheme.leading_for(DangoTheme.FONT_UI_SEMI, 12, 1.5))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		how_col.add_child(row)

	var use := Button.new()
	use.name = "UseButton"
	use.text = "USE THIS TEAM"
	use.custom_minimum_size = Vector2(0, 50)
	DangoTheme.style_button(use, true)
	use.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	use.add_theme_font_size_override("font_size", 17)
	DangoTheme.apply_tracking(use, 0.1, 17)
	# Re-cut to the mockup's own geometry (radius 12 / 3px outline / 4px shelf), which is not
	# the shared primary's 15 / 4 / 6.
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		var box := use.get_theme_stylebox(state_key).duplicate() as StyleBoxFlat
		box.set_corner_radius_all(12)
		box.set_border_width_all(3)
		if box.shadow_offset.y > 0.0:
			box.shadow_offset = Vector2(0, 4)
		use.add_theme_stylebox_override(state_key, box)
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

		slot.clip_contents = true
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# `object-fit: cover` in the mockup, not contain.
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = MockupAssets.tex("assets/portrait/%s.png" % cls)
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


## FIX-PASS-01 L4/G3: BACK lives in the shared footer bar — it used to overlap card 1.
## §1 item 4: the footer is `DangoScreen.build()`'s.
func _build_footer(footer: HBoxContainer) -> void:
	DangoScreen.add_back_button(footer, func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))


func _cream_body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	return lbl
