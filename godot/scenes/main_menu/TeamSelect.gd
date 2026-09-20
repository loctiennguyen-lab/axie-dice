class_name TeamSelect
extends Control
## v2 UI REDESIGN — "Godot Meta Screens v2.dc.html" TEAM tab (design/design-handoff-v2).
## Own screen, split out of MainMenu.gd's old inline team picker (spec-data.js "Main Menu is a
## scrolling form" — the 5-slot hero picker + class passive + six faces used to live in one of
## MainMenu's stacked VBox sections; v2's Main Menu shows a read-only lineup instead and this
## screen owns editing it). The spec-data.js TEAM SELECT entry names its file as
## "MainMenu.tscn (own screen)" — read literally that would mean one shared .tscn switching
## between two layouts, but v2's own three rules ("one hero, one rail" — a screen this dense
## sharing a tree with the title screen would be two screens pretending to be one) and Godot's
## own scene-per-screen convention used by every other meta screen (Vault.tscn, Guides.tscn,
## Codex.tscn, Settings.tscn) both argue for a sibling scene instead. Kept in `scenes/main_menu/`
## because it is still conceptually part of the menu flow and is one of the two files this task
## owns.
##
## HAND-OFF PROTOCOL, reusing `MainMenu.pending_team` (already the channel Guides.tscn's
## "USE THIS TEAM" uses — see that scene's `hand_team_to_menu()`): MainMenu seeds
## `pending_team` with its current `_team_selection` before navigating here; this screen reads
## it once in `_ready()` (falling back to `MainMenu.DEFAULT_TEAM` if empty, e.g. a fresh boot
## that somehow lands here directly) and CLEARS it. CONFIRM TEAM sets `pending_team` to the
## edited roster and returns to MainMenu, which picks it up exactly the same way it already
## does for a Guides hand-off. No back/cancel affordance exists in the mockup's own top bar
## (only SAMPLE TEAMS and CONFIRM TEAM) — every path back through this screen commits the
## current picks, matching the mockup exactly.
##
## RESOLVED 2026-09-21 (TEAM-05): the mockup's bottom "THIS COMP LEANS" strip is now built.
## It was left out of the earlier pass because the mockup's own `archChips` are hardcoded demo
## data (BULWARK/PLAGUE/AEGIS) that does not react to the five picks, and inventing a classifier
## would have been gameplay logic with no spec behind it. There is a spec: the live JS build has
## shipped `archScore()` / `ARCH_PRIORITY` / `faceArch()` in src/data.js since launch, and those
## three are now ported verbatim into ContentDB as `team_arch_score()` / `ARCH_PRIORITY` /
## `face_arch()`. This strip reads that port, so what the player sees is the shipping rule, not
## a guess. See `_build_arch_bar()` at the bottom of this file.

const _CLASS_ORDER: Array[String] = ["plant", "beast", "aqua", "reptile", "bug", "bird"]

var _content: Control
var _team_selection: Array[String] = []
## VLT-05: every key a slot dropdown may hold — the six T1 heroes, then the player's own
## imported Vault Axies. Built once in `_ready()` and never re-ordered, because the
## OptionButton indices in `_build_card()` are positions in THIS array.
var _pick_keys: Array[String] = []
var _subtitle: Label

# One entry per slot: option (OptionButton), header_panel/header_name/header_cls,
# band_panel/portrait/tier_badge/hp_badge, passive_name/passive_text, faces_grid.
var _cards: Array[Dictionary] = []


func _ready() -> void:
	if not MainMenu.pending_team.is_empty():
		_team_selection = MainMenu.pending_team.duplicate()
		MainMenu.pending_team = []
	else:
		_team_selection = MainMenu.DEFAULT_TEAM.duplicate()
	# VLT-05: MetaState registers every vault record into `ContentDB.heroes` as `vault_<id>`,
	# but it does so deferred from its own `_ready()`. Landing here straight from Vault can beat
	# that call, so ask for it now — it is idempotent.
	MetaState.ensure_vault_heroes()
	_pick_keys = _build_pick_keys()
	_build_ui()


## The six starters, then the vault. Stale records are left out on purpose: their dice were
## built under older face rules and cannot be played (MetaState.vault_stale()'s own docstring
## says team select refuses them), and a pick that silently plays wrong numbers is worse than
## one the player cannot make.
func _build_pick_keys() -> Array[String]:
	var keys: Array[String] = MainMenu.T1_HERO_KEYS.duplicate()
	for entry in MetaState.vault:
		if MetaState.vault_stale(entry):
			continue
		var key := MetaState.vault_key(entry)
		if ContentDB.heroes.has(key) and not keys.has(key):
			keys.append(key)
	return keys


## The label for one dropdown row. A vault Axie is marked so the player can tell their own
## imported NFT from a starter at a glance — the JS build makes the same distinction by giving
## the vault its own "YOUR VAULT" grid, which five dropdowns have no room for.
func _pick_label(hero_key: String) -> String:
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var base := "%s (%s)" % [
		String(hero_def.get("n", hero_key)), String(hero_def.get("cls", "")).capitalize()]
	return base + " · VAULT" if MetaState.is_vault_key(hero_key) else base


func _build_ui() -> void:
	# Shell first (FIX-PASS-02 §1 item 4 / godot/CLAUDE.md rule 2). TeamSelect owns its own
	# chrome (SAMPLE TEAMS / CONFIRM TEAM live in its own header, not a shared footer) — no
	# footer, per the routing task's own scene list (Combat/MainMenu/TeamSelect take none).
	#
	# G2 NOTE — why this does NOT pass `side_inset = _RAIL`. `DangoScreen.build()` grew a
	# `side_inset` argument for exactly this screen, but the shell clamps its column to
	# `CONTENT_MAX` (1800) BEFORE centring it: at 1920 wide, `side_inset = 56` gives
	# `min(1920 - 112, 1800) = 1800`, so the content lands at x=60, not the mockup's 56.
	# Anything under 60 is unreachable through that argument until `CONTENT_MAX` changes, and
	# `scenes/shared/` is not this pass's to edit. The shell therefore keeps its own 84 rail and
	# the two blocks below reclaim the 28px difference, which lands on 56 exactly. Flagged in
	# the task report — if `CONTENT_MAX` is raised to >= 1808, switch to `side_inset` and drop
	# the reclaim from both blocks.
	var built := DangoScreen.build(self,
		MockupAssets.tex("assets/bg/crossroad.jpg"), DangoTheme.Scrim.DEFAULT,
		false, false)
	_content = built["content"]

	_build_header()

	var row := HBoxContainer.new()
	row.name = "TeamSlots"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# The mockup's rail on THIS screen is 56, not the shell's 84 — the five cards are sized by
	# what is left over, so the difference is not cosmetic. `_content` starts at the 84 rail, so
	# the row reclaims the 28px on each side. 56 is still outside the 48px safe area (L1).
	row.offset_left = _RAIL - DangoScreen.RAIL_X
	row.offset_right = DangoScreen.RAIL_X - _RAIL
	row.offset_top = 150 - DangoScreen.SAFE
	row.add_theme_constant_override("separation", 14)
	_content.add_child(row)

	_cards.clear()
	for i in MainMenu.TEAM_SIZE:
		row.add_child(_build_card(i))

	_build_arch_bar()


## The mockup's left/right rail for this screen (the shell's own is 84).
const _RAIL := 56.0

## BOX MODEL (design review 2026-09-20). Every fixed size in this mockup is the CONTENT box and
## the black border adds OUTSIDE it, so an outer size is the mockup's number plus its border on
## each edge it has one. `height:54` + `border:4` = 62 for the two header buttons.
const _HEADER_BTN_H := 62


func _build_header() -> void:
	# T4: the mockup's header is ONE row at `top:42` with `align-items:flex-end` and `gap:18`,
	# so the two buttons' bottom edges line up with the bottom of the title block — they are
	# not pinned to the top of a 54px strip. The strip was the bug: a `Control` shell with
	# `custom_minimum_size.y = 54` held the row at 54 while the title column's own two lines
	# measure ~96, so the buttons sat against the top edge with the title running out below
	# them. The HBoxContainer is now the anchored node and takes its height from its own
	# content, exactly as the flex row does.
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = _RAIL - DangoScreen.RAIL_X
	row.offset_right = DangoScreen.RAIL_X - _RAIL
	# RESTORED 2026-09-20: the mockup draws this header at `top:42`. It used to be clamped to
	# the old uniform 48px safe-area law; that law is gone (it now only checks that nothing is
	# clipped by the 1920x1080 canvas edge), so the mockup's own inset is back. `_content`
	# starts at the shell's 48px line, so 42 is 6px above it.
	row.offset_top = 42 - DangoScreen.SAFE
	row.add_theme_constant_override("separation", 18)
	_content.add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_col)

	var title := Label.new()
	title.text = "CHOOSE YOUR TEAM"
	title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	DangoTheme.apply_tracking(title, 0.02, 46)
	title_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _SUBTITLE_BASE
	subtitle.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	subtitle.add_theme_font_size_override("font_size", 14)
	# CORRECTED 2026-09-20 (mockup pass): the note here claimed DangoTheme had no token for the
	# mockup's `#A6B0BF` and settled for MUTED_TEXT (`#8C95A4`). It does — `SUBTITLE_TEXT`, whose
	# own docstring names this very label ("a subtitle under a screen title, on open artwork
	# (Team Select, Vault, Reward)"). Exact hex, no approximation.
	subtitle.add_theme_color_override("font_color", DangoTheme.SUBTITLE_TEXT)
	title_col.add_child(subtitle)
	_subtitle = subtitle
	_refresh_ranked_note()

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 11)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	# `align-items:flex-end` on the outer row: the pair hugs the BOTTOM of the header row
	# rather than stretching over its whole height.
	buttons.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(buttons)

	var sample_btn := Button.new()
	sample_btn.name = "SampleTeamsButton"
	sample_btn.text = "SAMPLE TEAMS"
	# T4: `height:54` + `border:4` = 62 outer — the same off-by-the-border as M2.
	sample_btn.custom_minimum_size = Vector2(0, _HEADER_BTN_H)
	var sample_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 13, 4, 5.0,
		Vector2(20, 0))
	var sample_hover := sample_sb.duplicate() as StyleBoxFlat
	sample_btn.add_theme_stylebox_override("normal", sample_sb)
	sample_btn.add_theme_stylebox_override("hover", sample_hover)
	sample_btn.add_theme_stylebox_override("pressed", sample_hover)
	sample_btn.add_theme_stylebox_override("disabled", sample_sb)
	sample_btn.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	sample_btn.add_theme_color_override("font_hover_color", DangoTheme.CREAM)
	sample_btn.add_theme_color_override("font_pressed_color", DangoTheme.CREAM)
	sample_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	sample_btn.add_theme_font_size_override("font_size", 16)
	DangoTheme.apply_tracking(sample_btn, 0.1, 16)
	sample_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/guides/Guides.tscn"))
	buttons.add_child(sample_btn)

	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmTeamButton"
	confirm_btn.text = "CONFIRM TEAM"
	confirm_btn.custom_minimum_size = Vector2(0, _HEADER_BTN_H)
	DangoTheme.style_button(confirm_btn, true)
	confirm_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	DangoTheme.apply_tracking(confirm_btn, 0.12, 20)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_btn)

	# The mockup draws this pair at radius 13 / 4px outline / 5px shelf and 0 28 padding, which
	# is not the shared primary geometry (15 / 4 / 6 at 18 10). Re-cut here from the states
	# style_button() just installed so the hover/pressed colours stay the system's.
	# REPLACES FIX-PASS-01 T3's 7px shelf: the mockup says 5.
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		var box := confirm_btn.get_theme_stylebox(state_key).duplicate() as StyleBoxFlat
		box.set_corner_radius_all(13)
		box.content_margin_left = 28.0
		box.content_margin_right = 28.0
		box.content_margin_top = 0.0
		box.content_margin_bottom = 0.0
		if box.shadow_offset.y > 0.0:
			box.shadow_offset = Vector2(0, 5)
		confirm_btn.add_theme_stylebox_override(state_key, box)


## VLT-05 / the JS build's `hasVault` rule. `RunState.begin()` already downgrades a ranked run
## to unranked when the roster holds a vault key — silently, in the engine, after the player has
## committed. The Vault screen explains the rule on its own RANKED RUN note; this is the same
## sentence at the moment the pick is actually made. No new element: it extends the subtitle
## line the mockup already draws under the title.
const _SUBTITLE_BASE := "5 Tier-1 Axies · duplicates allowed · every run starts at Tier 1"


func _refresh_ranked_note() -> void:
	if _subtitle == null:
		return
	_subtitle.text = _SUBTITLE_BASE
	if MetaState.team_has_vault_pick(_team_selection):
		_subtitle.text += " · a Vault Axie makes this run unranked"


func _on_confirm_pressed() -> void:
	MainMenu.pending_team = _team_selection.duplicate()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# ===========================================================================
# TEAM-05 — "THIS COMP LEANS"
#
# Mockup box (meta-screens-v2.html, TEAM SELECT, last block): the bar sits at bottom:38 /
# left:56 / right:56, padding 14px 18px, radius 15, background #1B1F27 (Surface.PANEL),
# border 4px black, shelf `0 5px 0`, and lays out `gap:18` — eyebrow, then the chip row.
# Chip: `gap:10; padding:9px 14px; radius:12; background:{arch colour}; border:3px black`,
# glyph 19px, name Baloo 15 w800 tracking .08em line-height 1, description 12px w600 with
# `margin-top:2`. Three chips, same as the mockup's `hint-placeholder-count`.
#
# The ranking is ContentDB.team_arch_top() — the src/data.js `archScore()` port: each hero's
# class passive scores 1 for its own archetype, and every die face scores 3/2/1 by rarity for
# the archetype `face_arch()` assigns it. Ties break on ARCH's own declaration order, so the
# bar never flickers between two equal archetypes as the player re-picks.
# ===========================================================================

## `_content`'s bottom edge is DangoScreen.SAFE above the screen's; the mockup wants 38.
const _ARCH_BAR_BOTTOM := 38.0
## The mockup draws three. Fewer appear only when the comp genuinely leans on fewer (an
## all-Plant five scores exactly two), which is information, not a hole.
const _ARCH_CHIP_COUNT := 3

var _arch_chip_row: HBoxContainer


func _build_arch_bar() -> void:
	var bar := PanelContainer.new()
	bar.name = "CompLeansBar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# Same 28px reclaim as the header and the card row: `_content` starts at the shell's 84
	# rail, this screen's mockup rail is 56.
	bar.offset_left = _RAIL - DangoScreen.RAIL_X
	bar.offset_right = DangoScreen.RAIL_X - _RAIL
	# BOTTOM_WIDE pins both edges to the bottom; with GROW_DIRECTION_BEGIN the bar keeps its
	# bottom on that line and takes its height upward from its own content, so the chips'
	# two-line text sets the height instead of a hardcoded strip (the bug T4 fixed in the
	# header, not repeated here).
	bar.offset_top = DangoScreen.SAFE - _ARCH_BAR_BOTTOM
	bar.offset_bottom = DangoScreen.SAFE - _ARCH_BAR_BOTTOM
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 15, 4, 5.0, Vector2(18, 14)))
	_content.add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)

	var eyebrow := Label.new()
	eyebrow.name = "CompLeansEyebrow"
	eyebrow.text = "THIS COMP LEANS"
	eyebrow.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	DangoTheme.apply_tracking(eyebrow, 0.16, 13)
	eyebrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(eyebrow)

	_arch_chip_row = HBoxContainer.new()
	_arch_chip_row.name = "ArchChips"
	_arch_chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arch_chip_row.add_theme_constant_override("separation", 10)
	row.add_child(_arch_chip_row)

	_refresh_arch_bar()


func _refresh_arch_bar() -> void:
	if _arch_chip_row == null:
		return
	for c in _arch_chip_row.get_children():
		_arch_chip_row.remove_child(c)
		c.queue_free()
	for key in ContentDB.team_arch_top(_team_selection, _ARCH_CHIP_COUNT):
		_arch_chip_row.add_child(_build_arch_chip(String(key)))


func _build_arch_chip(key: String) -> PanelContainer:
	var arch: Dictionary = ContentDB.ARCH.get(key, {})
	# A missing archetype is a data error, not a styling choice — neutral fill rather than
	# some other archetype's colour, same rule GuidesView._build_card() uses.
	var fill := Color(String(arch.get("c", ""))) if arch.has("c") else DangoTheme.PANEL_RAISED
	# The mockup inks all three chips #1A1206 because every ARCH colour today is light. ink_on()
	# gets the same answer for all eleven and keeps it right if a colour is ever darkened.
	var ink := DangoTheme.ink_on(fill)

	var chip := PanelContainer.new()
	chip.name = "ArchChip_" + key
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(fill, 12, 3, Vector2(14, 9)))

	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 10)
	chip.add_child(chip_row)

	var glyph := Label.new()
	glyph.text = String(arch.get("ic", "?"))
	# No FONT_DISPLAY override: Baloo 2 has no coverage for these symbols, so the glyph takes
	# the default UI font exactly as the Guides card badge does.
	glyph.add_theme_font_size_override("font_size", 19)
	glyph.add_theme_color_override("font_color", ink)
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(glyph)

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip_row.add_child(text_col)

	var name_lbl := Label.new()
	name_lbl.name = "ArchName"
	name_lbl.text = String(arch.get("n", key.to_upper()))
	name_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", ink)
	DangoTheme.apply_tracking(name_lbl, 0.08, 15)
	# `line-height:1` on a 15px Baloo 2, whose own line box is ~1.6em — without the clamp the
	# chip grows ~9px taller than the mockup and the two lines drift apart.
	text_col.add_child(DangoTheme.line_box(name_lbl, 15, 1.0))

	var desc := Label.new()
	desc.name = "ArchDesc"
	desc.text = String(arch.get("d", ""))
	desc.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	text_col.add_child(desc)

	return chip


# ===========================================================================
# One team card — mockup box: flex:1 1 0, header 40+4, hero band 186+3*2 (art 164),
# HP badge 32+3*2, face cell pad 8/9, face value 24. Every one of those fixed numbers is the
# CONTENT box; the black border adds outside it (design review 2026-09-20).
# ===========================================================================

## T2: `height:40` + `border-bottom:4` = 44 outer. The build measured ~46 because the header
## was pinned to 40 and then grown by the 21px name label's own line box.
const _CARD_HEADER_H := 44
## `height:36` + `border:3` = 42 outer.
const _PICK_ROW_H := 42
## `height:186` + `border:3` = 192 outer.
const _HERO_BAND_H := 192
## `height:26` + `border:2` = 30 outer.
const _TIER_BADGE_H := 30.0
## `height:32` + `border:3` = 38 outer.
const _HP_BADGE_H := 38.0
## T3: the keyword line's `min-height:12px` is what keeps the six face cells — and therefore
## the five card bottoms — the same height when a face has no keyword. It only bites if the
## line box is the mockup's own `line-height:1.2` (12px at 10px type); Baloo 2's natural line
## box is ~1.6em, which is taller than the floor and makes the floor inert.
const _FACE_LINE_RATIO := 1.2


func _build_card(index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 17, 5, 7.0))
	DangoTheme.clip_to_frame(card)   # G3

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, _CARD_HEADER_H)
	col.add_child(header)
	# The band is 40 + a 4px bottom border in the mockup — its ink is centred in it, not padded
	# to whatever the 21px name label happens to measure (53 with Baloo 2's 1.61em line box).
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var header_name := Label.new()
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_name.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	header_name.add_theme_font_size_override("font_size", 21)
	header_name.add_theme_color_override("font_color", DangoTheme.INK)
	DangoTheme.apply_tracking(header_name, 0.02, 21)
	header_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(header_name)
	var header_cls := Label.new()
	header_cls.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	header_cls.add_theme_font_size_override("font_size", 14)
	header_cls.add_theme_color_override("font_color", DangoTheme.INK)
	DangoTheme.apply_tracking(header_cls, 0.08, 14)
	header_cls.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(header_cls)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 13)
	body_margin.add_theme_constant_override("margin_right", 13)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_bottom", 14)
	col.add_child(body_margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body_margin.add_child(body)

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, _PICK_ROW_H)
	var pick_sb := StyleBoxFlat.new()
	pick_sb.bg_color = DangoTheme.CREAM_RAISED
	pick_sb.border_color = Color.BLACK
	pick_sb.set_border_width_all(3)
	pick_sb.set_corner_radius_all(10)
	pick_sb.content_margin_left = 11.0
	pick_sb.content_margin_right = 11.0
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		option.add_theme_stylebox_override(state_key, pick_sb)
	option.add_theme_color_override("font_color", DangoTheme.INK)
	option.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	option.add_theme_font_size_override("font_size", 14)
	DangoTheme.apply_tracking(option, 0.04, 14)
	# RESTORED 2026-09-20 (mockup pass): FIX-PASS-01 T1 dropped the "(Class)" suffix as
	# redundant. meta-screens-v2.html's own `pickLabel` is `${name} (${Class})`, and
	# godot/CLAUDE.md puts the mockup above a superseded prose pass.
	for hero_key in _pick_keys:
		option.add_item(_pick_label(hero_key))
	# A key the picker cannot show must not stay in the roster: a vault Axie removed between
	# two screens, or a record that went stale, would otherwise sit invisibly in `_team_selection`
	# while the dropdown displayed slot 0's hero — and CONFIRM would hand the run a key
	# `ContentDB.heroes` no longer has, which builds a 0 HP unit.
	var sel := _pick_keys.find(_team_selection[index])
	if sel < 0:
		sel = 0
		_team_selection[index] = _pick_keys[0]
	option.select(sel)
	option.item_selected.connect(func(idx: int) -> void:
		_team_selection[index] = _pick_keys[idx]
		_refresh_card(index)
		_refresh_arch_bar()
		_refresh_ranked_note())
	body.add_child(option)

	# FIX-PASS-01 T1: the Button-state overrides above only reach the OptionButton's own face —
	# its popup (the actual dropdown list) is a separate PopupMenu that otherwise opens as the
	# engine's default dark chrome sitting on top of this cream card. Themed to match.
	var popup := option.get_popup()
	var popup_sb := StyleBoxFlat.new()
	popup_sb.bg_color = DangoTheme.CREAM_RAISED
	popup_sb.border_color = Color.BLACK
	popup_sb.set_border_width_all(3)
	popup_sb.set_corner_radius_all(10)
	popup_sb.content_margin_left = 6.0
	popup_sb.content_margin_right = 6.0
	popup_sb.content_margin_top = 6.0
	popup_sb.content_margin_bottom = 6.0
	popup.add_theme_stylebox_override("panel", popup_sb)
	popup.add_theme_color_override("font_color", DangoTheme.INK)
	popup.add_theme_color_override("font_color_hover", DangoTheme.ink_on(DangoTheme.PRIMARY))
	popup.add_theme_color_override("font_color_pressed", DangoTheme.INK)
	popup.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	var popup_hover_sb := StyleBoxFlat.new()
	popup_hover_sb.bg_color = DangoTheme.PRIMARY
	popup_hover_sb.set_corner_radius_all(6)
	popup.add_theme_stylebox_override("hover", popup_hover_sb)

	var band := Control.new()
	band.custom_minimum_size = Vector2(0, _HERO_BAND_H)
	body.add_child(band)

	var band_panel := Panel.new()
	band_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var band_sb := StyleBoxFlat.new()
	band_sb.border_color = Color.BLACK
	band_sb.set_border_width_all(3)
	band_sb.set_corner_radius_all(14)
	band_panel.add_theme_stylebox_override("panel", band_sb)
	band.add_child(band_panel)

	var portrait_wrap := CenterContainer.new()
	portrait_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(portrait_wrap)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(164, 164)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_wrap.add_child(portrait)

	# Mockup: TIER pill `height:26` + `border:2` = 30 outer, radius 7, 9px in from the band's
	# bottom-LEFT; HP badge `height:32` + `border:3` = 38 outer, radius 9, 9px in from the
	# bottom-RIGHT.
	# CORRECTED 2026-09-20 (mockup pass): the note here claimed DangoTheme had no token at the
	# mockup's `rgba(0,0,0,.36)` and settled for SHELF (.50, visibly heavier). It does —
	# `SHELF_SOFT`, whose own docstring names this very pill.
	var tier_badge := _make_overlay_badge(band, false, DangoTheme.SHELF_SOFT,
		DangoTheme.CREAM_RAISED, 12, _TIER_BADGE_H, 7, 2, 9.0, 0.1)
	var hp_badge := _make_overlay_badge(band, true, DangoTheme.CREAM_RAISED,
		DangoTheme.INK, 20, _HP_BADGE_H, 9, 3, 11.0)

	var passive_panel := PanelContainer.new()
	var passive_sb := StyleBoxFlat.new()
	passive_sb.bg_color = DangoTheme.PRIMARY
	passive_sb.border_color = Color.BLACK
	passive_sb.set_border_width_all(3)
	passive_sb.set_corner_radius_all(11)
	passive_sb.content_margin_left = 11.0
	passive_sb.content_margin_right = 11.0
	passive_sb.content_margin_top = 10.0
	passive_sb.content_margin_bottom = 10.0
	passive_panel.add_theme_stylebox_override("panel", passive_sb)
	body.add_child(passive_panel)

	var passive_col := VBoxContainer.new()
	passive_col.add_theme_constant_override("separation", 4)
	passive_panel.add_child(passive_col)
	var passive_name := Label.new()
	passive_name.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	passive_name.add_theme_font_size_override("font_size", 13)
	passive_name.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	DangoTheme.apply_tracking(passive_name, 0.1, 13)
	passive_col.add_child(passive_name)
	var passive_text := Label.new()
	passive_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_text.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	passive_text.add_theme_font_size_override("font_size", 12)
	passive_text.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	passive_col.add_child(passive_text)

	# The mockup's gap between this caption and the grid is 8, not the body column's 12, so the
	# pair is its own block.
	var faces_block := VBoxContainer.new()
	faces_block.add_theme_constant_override("separation", 8)
	body.add_child(faces_block)

	var faces_caption := Label.new()
	faces_caption.text = "SIX FACES"
	faces_caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	faces_caption.add_theme_font_size_override("font_size", 12)
	faces_caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	DangoTheme.apply_tracking(faces_caption, 0.14, 12)
	faces_block.add_child(faces_caption)

	var faces_grid := GridContainer.new()
	faces_grid.columns = 2
	faces_grid.add_theme_constant_override("h_separation", 8)
	faces_grid.add_theme_constant_override("v_separation", 8)
	faces_block.add_child(faces_grid)

	_cards.append({
		"option": option, "header_panel": header, "header_name": header_name,
		"header_cls": header_cls, "band_panel": band_panel, "portrait": portrait,
		"tier_badge": tier_badge, "hp_badge": hp_badge, "passive_panel": passive_panel,
		"passive_name": passive_name, "passive_text": passive_text, "faces_grid": faces_grid,
	})
	_refresh_card(index)
	return card


## A pill pinned into one bottom corner of the hero band. `right` picks the corner.
##
## It is anchored by its OWN edges (anchor to the corner, grow away from it) rather than by a
## `.position` computed from a guessed pill width — the previous version subtracted a literal
## 70 for the HP badge, which is only correct while "17 HP" is exactly that wide.
func _make_overlay_badge(band: Control, right: bool, bg: Color, ink: Color, font_size: int,
		height: float, radius: int, border_w: int, pad_x: float,
		tracking_em: float = 0.0) -> Label:
	var badge := PanelContainer.new()
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.anchor_left = 1.0 if right else 0.0
	badge.anchor_right = 1.0 if right else 0.0
	badge.grow_horizontal = (Control.GROW_DIRECTION_BEGIN if right
		else Control.GROW_DIRECTION_END)
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	badge.offset_bottom = -9.0
	if right:
		badge.offset_right = -9.0
		badge.offset_left = -9.0
	else:
		badge.offset_left = 9.0
		badge.offset_right = 9.0
	badge.offset_top = badge.offset_bottom - height
	badge.custom_minimum_size.y = height

	var sb := DangoTheme.solid_chip_style(bg, radius, border_w, Vector2(pad_x, 0))
	badge.add_theme_stylebox_override("panel", sb)
	band.add_child(badge)

	var lbl := Label.new()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", ink)
	DangoTheme.apply_tracking(lbl, tracking_em, font_size)
	badge.add_child(lbl)
	return lbl


func _refresh_card(index: int) -> void:
	var card: Dictionary = _cards[index]
	var hero_key := _team_selection[index]
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))
	var accent := DangoTheme.class_color(cls)

	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = accent
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 4)
	header_sb.content_margin_left = 13.0
	header_sb.content_margin_right = 13.0
	header_sb.content_margin_top = 0.0
	header_sb.content_margin_bottom = 0.0
	(card["header_panel"] as PanelContainer).add_theme_stylebox_override("panel", header_sb)
	# FIX-PASS-01 T2: ink_on(class_color(cls)), not a hardcoded INK. Every CLASS_COLORS entry
	# happens to be light enough today that hardcoded dark INK looked correct in every
	# screenshot — but that was luck, not a guarantee, and the whole point of ink_on() existing
	# is that a header never has to be re-audited if a class colour changes later.
	var header_ink := DangoTheme.ink_on(accent)
	(card["header_name"] as Label).add_theme_color_override("font_color", header_ink)
	(card["header_name"] as Label).text = String(hero_def.get("n", hero_key))
	(card["header_cls"] as Label).add_theme_color_override("font_color", header_ink)
	(card["header_cls"] as Label).text = cls.to_upper()

	((card["band_panel"] as Panel).get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent

	var portrait: TextureRect = card["portrait"]
	portrait.texture = MockupAssets.tex("assets/portrait/%s.png" % cls)

	(card["tier_badge"] as Label).text = "TIER %d" % int(hero_def.get("tier", 1))
	(card["hp_badge"] as Label).text = "%d HP" % int(hero_def.get("max_hp", 0))

	# The passive text — straight from ContentDB.CLASS_PASSIVE, never retyped. This is the
	# figure the task brief calls out by name: "the game applies FERAL today and never tells
	# the player FERAL exists". v2's whole point for this screen is putting it on-screen, in a
	# block big enough to read, not hidden behind a hover or a wiki.
	var passive: Dictionary = ContentDB.CLASS_PASSIVE.get(cls, {})
	var passive_name: Label = card["passive_name"]
	var passive_text: Label = card["passive_text"]
	if passive.is_empty():
		passive_name.text = "PASSIVE · NOT DEFINED"
		passive_text.text = "This class has no passive defined yet."
	else:
		passive_name.text = "PASSIVE · %s" % String(passive.get("n", ""))
		passive_text.text = String(passive.get("d", ""))

	var grid: GridContainer = card["faces_grid"]
	for c in grid.get_children():
		c.queue_free()
	for face in (hero_def.get("die", []) as Array):
		grid.add_child(_build_face_cell(face as Dictionary, cls))


## Cream face cell — mockup: pad 8/9, part icon 22, value 24, type swatch 22x22 WITH its
## type glyph inside (G-01/L7 — it was a bare coloured square), caption and keyword line 10px.
##
## RESTORED 2026-09-20: both lines were held at 12 by the old project type floor. The project
## owner has removed that floor in favour of the mockups (godot/CLAUDE.md rule 5 — "use the
## size the mockup uses, including where that is 9px or 11px"), and meta-screens-v2.html draws
## `font-size:10px;letter-spacing:.06em` on both. That is what they are now.
##
## The part icon comes through `MockupAssets.part_icon()` — the mockup writes
## `assets/part/<slot>-<class>.svg` and that translator owns the mapping to this repo's own
## naming. Never a hand-written res:// string (godot/CLAUDE.md, Asset paths).
func _build_face_cell(face: Dictionary, cls: String) -> PanelContainer:
	var face_type := String(face.get("type", ""))
	var part := String(face.get("part", ""))

	var cell := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_RAISED
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 9.0
	sb.content_margin_right = 9.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	cell.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	cell.add_child(col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 7)
	col.add_child(top_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = MockupAssets.part_icon(part, cls)
	top_row.add_child(icon)

	var value_lbl := Label.new()
	var value := int(face.get("value", 0))
	value_lbl.text = "•" if (face_type == "buff" or face_type == "debuff") else str(value)
	value_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	value_lbl.add_theme_font_size_override("font_size", 24)
	value_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	top_row.add_child(value_lbl)

	# G-01/L7: the type is a fill AND a glyph, never a fill alone. One shared builder — see
	# DangoTheme.type_swatch()'s comment for why this is not four inline squares.
	# `width:22;height:22` + `border:2` = 26 outer, with the 14px type glyph inside it.
	top_row.add_child(DangoTheme.type_swatch(face_type, 26, 14, 6, 2))

	var caption := Label.new()
	caption.text = "%s · %s" % [part.to_upper(), face_type.to_upper()]
	caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	DangoTheme.apply_tracking(caption, 0.06, 10)
	caption.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_DISPLAY, 10, _FACE_LINE_RATIO))
	col.add_child(caption)

	var kw_lbl := Label.new()
	kw_lbl.text = _format_keywords(face.get("keywords", []))
	kw_lbl.custom_minimum_size = Vector2(0, 12)
	kw_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	kw_lbl.add_theme_font_size_override("font_size", 10)
	# `#B4600C` — DangoTheme.ACCENT_ON_CREAM is that exact colour and names this very label
	# ("Team Select's face-keyword line"). The inline literal here was a rule-1 violation.
	kw_lbl.add_theme_color_override("font_color", DangoTheme.ACCENT_ON_CREAM)
	DangoTheme.apply_tracking(kw_lbl, 0.06, 10)
	# T3: with the mockup's own 1.2 line box, the 12px floor above is the real height of this
	# line whether or not the face has a keyword — which is what keeps the five cards level.
	kw_lbl.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_DISPLAY, 10, _FACE_LINE_RATIO))
	col.add_child(kw_lbl)

	return cell


func _format_keywords(keywords: Array) -> String:
	if keywords.is_empty():
		return ""
	var parts: Array[String] = []
	for k in keywords:
		parts.append(String(k).replace(":", " ").to_upper())
	return " · ".join(parts)
