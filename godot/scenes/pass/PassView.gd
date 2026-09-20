extends Control
## LUNACIA PASS — the 30-level permanent-progression track. Restyle target: docs/design-handoff-v2
## §PASS ("Godot Meta Screens v2.dc.html"), screenshot `screenshots/10-pass.png`.
##
## THIS SCREEN CLOSES A REAL REGRESSION, NOT A COSMETIC GAP. v1 rendered the Pass track inline on
## the scrolling Main Menu; v2 deleted that when the menu became a fixed title screen, and until
## this scene existed the LUNACIA PASS nav tile was wired disabled (see MainMenu.gd's now-resolved
## "GAP FLAGGED" note). Spending Gene Shard and claiming rewards the pass had already earned was
## unreachable in the UI, with no other screen or shortcut to reach it.
##
## All data is real and already existed before this screen did: `MetaState.bp_level()` /
## `bp_progress()` / `bp_claimed` / `claim_bp_reward()`, and `ContentDB.BP_TRACK` (30 entries,
## `BP_MAX_LEVEL == 30`, matching the mockup's 6x5 grid exactly). Nothing here invents new rules —
## it is presentation over state that already worked.

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

# The plate the mockup asks for. The whole painted set already ships under
# `assets/backgrounds/origins/scene/`, under the kit's own numbered names — the short names the
# handoff uses (`temple.jpg`, `deep-forest.jpg`, `rocky.jpg`) are the same art, renamed for the
# HTML mockups. Three screens briefly fell back to the wrong plate on the belief that these
# images were missing; they never were. Look in that directory before concluding a background
# does not exist, and do not copy the handoff's copies in — that is how a project ends up with
# two of every background and no rule about which one is canonical.
const BG_TEXTURE := "res://assets/backgrounds/origins/scene/8-temple.jpg"

const SHARD_ICON := "res://assets/icons/web/shard.png"

var _grid: GridContainer
var _level_label: Label
var _xp_label: Label
var _xp_fill: Control
var _status_label: Label


func _ready() -> void:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT)

	_build_header()
	_build_track_panel()
	_build_back_button()
	refresh()


# ── Header: eyebrow + title left, level card right (redline: top 50, left/right 84) ───────────
func _build_header() -> void:
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 84.0
	row.offset_right = -84.0
	row.offset_top = 50.0
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title_col.add_theme_constant_override("separation", 10)
	row.add_child(title_col)

	var eyebrow := _eyebrow_chip("PERMANENT PROGRESSION")
	title_col.add_child(eyebrow)

	var title := DangoTheme.display_label("LUNACIA PASS", 56, DangoTheme.CREAM_RAISED)
	title_col.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	row.add_child(_build_level_card())


func _eyebrow_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 6))
	chip.add_theme_stylebox_override("panel", sb)
	var lbl := DangoTheme.display_label(text, 14, DangoTheme.INK_ON_PRIMARY, 800)
	lbl.add_theme_constant_override("line_spacing", 0)
	chip.add_child(lbl)
	return chip


func _build_level_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "LevelCard"
	card.custom_minimum_size = Vector2(540, 0)
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 14, 4, 5.0, Vector2(18, 14)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)

	var top_row := HBoxContainer.new()
	col.add_child(top_row)

	_level_label = DangoTheme.display_label("LEVEL 1 / %d" % ContentDB.BP_MAX_LEVEL, 38,
		DangoTheme.CREAM_RAISED)
	_level_label.name = "LevelLabel"
	top_row.add_child(_level_label)

	var xp_spacer := Control.new()
	xp_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(xp_spacer)

	_xp_label = Label.new()
	_xp_label.name = "XpLabel"
	_xp_label.add_theme_font_size_override("font_size", 14)
	_xp_label.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	_xp_label.size_flags_vertical = Control.SIZE_SHRINK_END
	top_row.add_child(_xp_label)

	var well := PanelContainer.new()
	well.custom_minimum_size = Vector2(0, 18)
	well.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.WELL_DEEP, 10, 3, 0.0, Vector2(-1, -1)))
	col.add_child(well)

	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 12)
	well.add_child(track)

	_xp_fill = ColorRect.new()
	_xp_fill.name = "XpFill"
	_xp_fill.color = DangoTheme.PRIMARY
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xp_fill.anchor_right = 0.0
	track.add_child(_xp_fill)

	return card


# ── Reward grid panel: PANEL surface, radius 18 / border 5 / shelf 7 (redline) ─────────────────
func _build_track_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "TrackPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 84.0
	panel.offset_right = -84.0
	panel.offset_top = 202.0
	panel.offset_bottom = -96.0
	panel.anchor_bottom = 1.0
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 18, 5, 7.0, Vector2(20, 20)))
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.name = "TrackScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	# ScrollContainer does not clip its content by default in this Godot version — without
	# this, a list longer than the container's rect draws straight through it and over
	# whatever sits below (found on the Unlocks QA capture: row 10 bled past the panel and
	# over the BACK button).
	scroll.clip_contents = true
	panel.add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "RewardGrid"
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	add_child(_status_label)


func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(84, -44 - 28)
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back)


## Rebuilds the level card and the 30-tile grid from live state. Public so a test can drive it
## after a claim, mirroring VaultView.refresh()/GuidesView's own re-render-on-mutation pattern.
func refresh() -> void:
	var prog := MetaState.bp_progress()
	var level: int = int(prog.get("level", 0))
	# Redline sets "/ 30" in a smaller, dimmer run inside the same line; Label has no inline
	# rich-text sizing without switching to RichTextLabel, so this keeps one size and one colour
	# rather than faking it — a legibility rule (§ Contrast), not a decoration, is what's binding.
	_level_label.text = "LEVEL %d / %d" % [level, ContentDB.BP_MAX_LEVEL]

	var needed: int = int(prog.get("needed", 0))
	if needed <= 0:
		_xp_label.text = "MAX LEVEL"
	else:
		_xp_label.text = "%d / %d XP to Lv %d" % [int(prog.get("into_level", 0)), needed, level + 1]
	var pct: float = clampf(float(prog.get("percent", 0.0)) / 100.0, 0.0, 1.0)
	_xp_fill.anchor_right = pct

	for child in _grid.get_children():
		child.queue_free()
		_grid.remove_child(child)
	for entry in ContentDB.BP_TRACK:
		_grid.add_child(_build_tile(entry))


func _build_tile(entry: Dictionary) -> Button:
	var lv := int(entry.get("lv", 0))
	var reward_type := String(entry.get("type", ""))
	var claimed := MetaState.bp_claimed.has(lv)
	var reached := lv <= MetaState.bp_level()
	# FACE_POOL is unported; MetaState.claim_bp_reward() already refuses "face" rewards outright
	# (see its own comment). Rendering these as an ordinary "CLAIM NOW" once the level is hit would
	# be a button that fails after being pressed — the same lie the event system already shipped
	# once. They stay in the WELL "locked" fill forever, with their own state text saying why.
	var blocked := reward_type == "face"
	var claimable := reached and not claimed and not blocked

	var btn := Button.new()
	btn.name = "PassTile_%d" % lv
	btn.custom_minimum_size = Vector2(0, 72)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not claimable
	btn.clip_text = false
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if claimable else Control.CURSOR_ARROW

	var tile_bg: Color
	var lv_bg: Color
	var lv_fg: Color
	var title_fg: Color
	var state_fg: Color
	var state_text: String
	if claimed:
		tile_bg = DangoTheme.CREAM
		lv_bg = DangoTheme.CREAM_TRACK
		lv_fg = DangoTheme.INK_ON_CREAM_SOFT
		title_fg = DangoTheme.INK_ON_CREAM_SOFT
		state_fg = DangoTheme.INK_ON_CREAM_MUTED
		state_text = "CLAIMED"
	elif claimable:
		tile_bg = DangoTheme.SUCCESS
		lv_bg = DangoTheme.CREAM_RAISED
		lv_fg = DangoTheme.INK_ON_SUCCESS
		title_fg = DangoTheme.INK_ON_SUCCESS
		state_fg = DangoTheme.INK_ON_SUCCESS
		state_text = "CLAIM NOW"
	else:
		tile_bg = DangoTheme.WELL
		lv_bg = DangoTheme.WELL
		lv_fg = DangoTheme.FAINT_TEXT
		title_fg = DangoTheme.MUTED_TEXT
		state_fg = DangoTheme.FAINT_TEXT
		state_text = ("GENE REWARD · LOCKED" if blocked and reached else "NEEDS LV %d" % lv)

	var normal_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 12, 3, 0.0, Vector2(12, 10))
	normal_sb.bg_color = tile_bg
	btn.add_theme_stylebox_override("normal", normal_sb)
	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = tile_bg.lightened(0.08) if claimable else tile_bg
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	var disabled_sb := normal_sb.duplicate() as StyleBoxFlat
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 11)
	btn.add_child(content)

	var lv_badge := PanelContainer.new()
	lv_badge.custom_minimum_size = Vector2(38, 38)
	lv_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = lv_bg
	badge_sb.border_color = Color.BLACK
	badge_sb.set_border_width_all(3)
	badge_sb.set_corner_radius_all(10)
	lv_badge.add_theme_stylebox_override("panel", badge_sb)
	var lv_lbl := DangoTheme.display_label(str(lv), 18, lv_fg)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv_badge.add_child(lv_lbl)
	content.add_child(lv_badge)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	content.add_child(text_col)

	var reward_lbl := DangoTheme.display_label(_reward_label(entry), 14, title_fg, 800)
	reward_lbl.clip_text = true
	reward_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reward_lbl.add_theme_constant_override("line_spacing", 0)
	text_col.add_child(reward_lbl)

	var state_lbl := DangoTheme.display_label(state_text, 12, state_fg, 800)
	state_lbl.add_theme_constant_override("line_spacing", 0)
	text_col.add_child(state_lbl)

	if claimable:
		btn.pressed.connect(_on_claim_pressed.bind(lv))
	return btn


## Turns one BP_TRACK entry into its display line. Lives here rather than in ContentDB —
## ContentDB is inside `t_rules_version.gd`'s fingerprinted set (`res://autoload`) and a pure
## display formatter cannot change what a run produces, so it does not belong in a file that
## exists to answer "can this change a replay". A second caller would be reason to move it; there
## is only this one.
func _reward_label(entry: Dictionary) -> String:
	match String(entry.get("type", "")):
		"shard":
			return "%d Gene Shard" % int(entry.get("value", 0))
		"unlock":
			var id := String(entry.get("value", ""))
			for u in ContentDB.UNLOCKS:
				if String((u as Dictionary).get("id", "")) == id:
					return String((u as Dictionary).get("n", id))
			return id
		"perk":
			return String(entry.get("note", "Perk"))
		"face":
			# FLAGGED: no player-facing name exists for these in this port (FACE_POOL is
			# unported). `title` only appears on the lv-30 capstone; everything else gets a
			# generic, honest placeholder rather than inventing gene-mutation flavour text.
			return String(entry.get("title", "Gene Mutation"))
		_:
			return "Reward"


func _on_claim_pressed(level: int) -> void:
	var err := MetaState.claim_bp_reward(level)
	if err != "":
		_status_label.text = err
		_status_label.visible = true
		return
	_status_label.visible = false
	refresh()
