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
const BG_MOCKUP_PLATE := "assets/bg/temple.jpg"

var _grid: GridContainer
var _level_label: Label
var _level_max_label: Label
var _xp_label: Label
var _xp_fill: Control
var _status_label: Label
var _track_panel: PanelContainer
var _track_scroll: ScrollContainer
var _track_fade: TextureRect

## FIX-PASS-02 §1 item 4: every child goes into the shell's `content`, never `self` — `content`
## is already inside the safe area and the 84px rail (`DangoScreen.RAIL_X`), and re-centres on
## resize. Screens built before this pass hand-rolled that same 84px rail themselves; now that
## `content` supplies it, this screen's own left/right offsets against it are 0, not 84 again.
var _content: Control

## Vertical space the grid may use before scrolling kicks in: viewport height, minus the panel's
## own top offset, minus the shared footer's safe area, minus the panel's own top+bottom content
## margin (20 + 20 from `_build_track_panel()`'s `surface_style` pad). Computed rather than
## hand-picked so a future change to `BP_MAX_LEVEL` or the footer height cannot silently reopen
## the 400px-empty-panel bug (FIX-PASS-01 P2) from the other direction (a grid that no longer fits
## and clips with no scrollbar, FIX-PASS-01 L2).
##
## FIXED 2026-09-20 (mockup pass): this was 202 on the belief that "a redline's offset_top = 202
## stays 202" against `content`. It does not — `DangoScreen.build()` sets `content.offset_top =
## SAFE`, so a child at 202 lands at 250 on the 1080 canvas. The mockup's `top:202` is 154 here.
const TRACK_PANEL_TOP := 202.0 - 48.0
const TRACK_PANEL_PAD_V := 20.0


func _ready() -> void:
	var shell := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PLATE),
		DangoTheme.Scrim.DEFAULT, true)
	_content = shell["content"]

	_build_header()
	_build_track_panel()
	_build_footer(shell["footer"])
	refresh()


# ── Header: eyebrow + title left, level card right (redline: top 50, left/right 84 — the 84 is
# now supplied by `content`'s own rail, so this row sits flush against it) ─────────────────────
func _build_header() -> void:
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 0.0
	row.offset_right = 0.0
	# Mockup `top:50`, measured against `content`'s own top edge (the 48px safe line).
	row.offset_top = 50.0 - 48.0
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content.add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title_col.add_theme_constant_override("separation", 10)
	row.add_child(title_col)

	# Mockup: `letter-spacing:.18em` on this chip.
	var eyebrow := _eyebrow_chip("PERMANENT PROGRESSION", 0.18)
	title_col.add_child(eyebrow)

	var title := DangoTheme.display_label("LUNACIA PASS", 56, DangoTheme.CREAM_RAISED,
		800, 0.02)
	title_col.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	row.add_child(_build_level_card())


func _eyebrow_chip(text: String, tracking_em: float = 0.0) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 6))
	chip.add_theme_stylebox_override("panel", sb)
	var lbl := DangoTheme.display_label(text, 14, DangoTheme.INK_ON_PRIMARY, 800, tracking_em)
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

	_level_label = DangoTheme.display_label("LEVEL 1", 38, DangoTheme.CREAM_RAISED)
	_level_label.name = "LevelLabel"
	top_row.add_child(_level_label)

	# The mockup's "/ 30" is a 22px run in #5C6573 on the same baseline, not part of the 38px
	# number. Two Labels, bottom-aligned in the row, rather than one flattened string.
	_level_max_label = DangoTheme.display_label(" / %d" % ContentDB.BP_MAX_LEVEL, 22,
		DangoTheme.FAINT_TEXT)
	_level_max_label.name = "LevelMaxLabel"
	_level_max_label.size_flags_vertical = Control.SIZE_SHRINK_END
	top_row.add_child(_level_max_label)

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
##
## FIX-PASS-01 L3: this panel used to be `anchor_bottom = 1.0` / `offset_bottom = -96.0` — pinned
## to the viewport regardless of how tall the grid actually was, which is exactly the "400px of
## empty PANEL under a short list" case the audit names this function for. It now only anchors
## its TOP; the height comes from the grid, computed in `refresh()` (the grid's contents, and
## therefore its natural height, are not known until `BP_TRACK` is populated into it there).
func _build_track_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "TrackPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = TRACK_PANEL_TOP
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 18, 5, 7.0, Vector2(20, TRACK_PANEL_PAD_V)))
	_content.add_child(panel)
	_track_panel = panel

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
	_track_scroll = scroll

	_grid = GridContainer.new()
	_grid.name = "RewardGrid"
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	# L2's 24px "there is more below" fade — only shown when `refresh()` finds the grid taller
	# than the room it has (see `_apply_track_height()`); on the normal 30-level track this never
	# triggers, and an always-visible fade over the last, complete row would be its own lie.
	#
	# Added as a sibling of `panel`, not a child of it: `PanelContainer` fits EVERY child to its
	# full content rect (it is built for exactly one), so a second child cannot be positioned as a
	# thin strip inside it. `_apply_track_height()` places this in the PassView root's own
	# coordinate space instead, once the panel's real (content-driven) height is known.
	_track_fade = DangoTheme.scroll_fade(DangoTheme.PANEL)
	_track_fade.name = "TrackScrollFade"
	_track_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track_fade.visible = false
	_track_fade.anchor_left = 0.0
	_track_fade.anchor_right = 1.0
	_track_fade.anchor_top = 0.0
	_track_fade.anchor_bottom = 0.0
	_track_fade.offset_left = 0.0
	_track_fade.offset_right = 0.0
	_content.add_child(_track_fade)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	_content.add_child(_status_label)


## FIX-PASS-01 L4/P3: BACK lives in the shared footer bar, not floating on the art.
## §1 item 4: the footer itself is now `DangoScreen.build()`'s, not a screen-built one.
func _build_footer(footer: HBoxContainer) -> void:
	DangoScreen.add_back_button(footer, func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))


## Rebuilds the level card and the 30-tile grid from live state. Public so a test can drive it
## after a claim, mirroring VaultView.refresh()/GuidesView's own re-render-on-mutation pattern.
func refresh() -> void:
	var prog := MetaState.bp_progress()
	var level: int = int(prog.get("level", 0))
	_level_label.text = "LEVEL %d" % level
	_level_max_label.text = " / %d" % ContentDB.BP_MAX_LEVEL

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

	# `queue_free()`'d tiles are still in the tree (and counted by `get_combined_minimum_size()`)
	# until the end of this frame — measure next frame, once they are actually gone, or a refresh
	# after a claim briefly "sees" 54 tiles instead of 30 and mis-sizes the panel for one frame.
	call_deferred("_apply_track_height")


## FIX-PASS-01 L3 + L2, done together because they are the same measurement: ask the grid how
## tall it actually wants to be, and either let the panel hug that (the normal case — 30 levels in
## 6 columns is 5 rows, comfortably under the safe area) or cap it and let the ScrollContainer
## take over, with the L2 fade to say there is more. This is what replaces the old
## `anchor_bottom = 1.0` / `offset_bottom = -96.0`, which sized the panel to the VIEWPORT
## regardless of the grid, and is exactly the "P2: 400px of empty panel" defect.
func _apply_track_height() -> void:
	if _grid == null or _track_scroll == null or _track_panel == null:
		return
	var natural := _grid.get_combined_minimum_size().y
	var viewport_h := get_viewport_rect().size.y
	# §1 shell pass: `content`'s own height already excludes BOTH safe-area edges (top AND
	# bottom-plus-footer) — TRACK_PANEL_TOP is now measured from content's top, so this must
	# subtract content's full top+bottom budget, not only the bottom half as before.
	var max_scroll_h := viewport_h - DangoScreen.SAFE * 2.0 - DangoScreen.FOOTER_H \
		- TRACK_PANEL_TOP - TRACK_PANEL_PAD_V * 2.0
	var overflow := natural > max_scroll_h
	var scroll_h: float = minf(natural, max_scroll_h) if max_scroll_h > 0.0 else natural
	_track_scroll.custom_minimum_size.y = scroll_h

	_track_fade.visible = overflow
	if overflow:
		# The panel is now pinned at `max_scroll_h` (it cannot grow further), so its bottom edge
		# is at a fixed, known Y — TRACK_PANEL_TOP + the panel's own top+bottom content margin +
		# the scroll's height.
		var panel_bottom := TRACK_PANEL_TOP + TRACK_PANEL_PAD_V * 2.0 + scroll_h
		_track_fade.offset_top = panel_bottom - DangoTheme.SCROLL_FADE_HEIGHT
		_track_fade.offset_bottom = panel_bottom


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
	# FIX-PASS-01 P1, checked against `production/qa/evidence/2026-09-20_meta-v2_pass.png`
	# (settled by state, not by eye — see the ui-programmer session's report for the check): the
	# evidence's "24 identical green tiles" is a real `xp`-maxed / `bp_claimed == []` save (
	# `MetaState.bp_level()` reads only `xp`, entirely independent of `bp_claimed`), not a broken
	# predicate. This ladder already matches L5 exactly (claimed -> CREAM/"CLAIMED", claimable ->
	# SUCCESS/"CLAIM NOW", locked -> WELL/"NEEDS LV n") and needed no change.
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
	# Fixed square, so a two-digit level cannot widen the badge and shift the title column's
	# baseline next to it (FIX-PASS-01 P4). RESTORED to the mockup's 38 from the 32 that fix
	# used — "30" at 18px is ~22px wide, well inside 38 minus the 3px outline.
	lv_badge.custom_minimum_size = Vector2(38, 38)
	lv_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lv_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lv_badge.clip_contents = true
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

	var reward_lbl := DangoTheme.display_label(_reward_label(entry), 14, title_fg, 800, 0.02)
	reward_lbl.clip_text = true
	reward_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reward_lbl.add_theme_constant_override("line_spacing", 0)
	text_col.add_child(reward_lbl)

	var state_lbl := DangoTheme.display_label(state_text, 12, state_fg, 800, 0.08)
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
