class_name MainMenu
extends Control
## MainMenu.tscn root. Reads MetaState/ContentDB for display, commits nothing to RunState
## until BEGIN RUN is pressed (architecture plan §3).
##
## v2 UI REDESIGN (design/design-handoff-v2, "Godot Meta Screens v2.dc.html" MENU tab —
## see docs/design-handoff-v2/README.md for where the source-of-truth bundle lives).
## This replaces the v1 scrolling-form build (title -> shard -> SEED -> MODE -> ASCENSION ->
## TEAM -> buttons, one VBox in a ScrollContainer — spec-data.js "Main Menu is a scrolling
## form"). v2 is a TITLE SCREEN: nothing scrolls, everything is laid out at fixed offsets
## against the 1920x1080 design canvas (STRETCH canvas_items / aspect expand, already the
## project's setting) —
##   - identity block + BEGIN RUN / CONTINUE RUN on the left (title:78,84)
##   - the whole run setup (seed/mode/ascension) as one panel on the right (566 wide, right 84)
##   - the team lineup along the bottom-left (read-only cards; editing moved to TeamSelect.tscn)
##   - six nav tiles as a compact 3x2 block bottom-right (452 wide, right 84)
##
## TEAM PICKING MOVED OUT. Editing the 5-slot roster (hero picker, class passive, six faces)
## used to live inline here; v2 gives it its own screen, TeamSelect.tscn (see that file's own
## header for why it is a sibling scene rather than a mode of this one). The hand-off between
## the two re-uses the exact mechanism Guides.tscn already established for "hand a team to the
## menu": `MainMenu.pending_team`, a static var read once in `_ready()` and cleared as it is
## read. MainMenu -> TeamSelect seeds `pending_team` with the CURRENT `_team_selection` before
## changing scene; TeamSelect -> MainMenu (CONFIRM TEAM) sets it to the edited team. No new
## channel invented.
##
## DEVIATION FLAGGED (told to the user in the task report, not silently done): the mockup's
## CONTINUE RUN subtitle is the literal placeholder string "Row 4 of 18 · Wave 3 · 4 Axies
## alive". Two problems with shipping that text verbatim: (1) "Wave" is exactly the wording
## `t_mainmenu_ui.gd`'s `test_nothing_promises_waves_on_a_map_made_of_rows` exists to forbid on
## this screen — this map is rows, not waves, and that gate predates this pass; (2) "N Axies
## alive" has no honest source — this port does not persist per-Axie HP on `RunState.roster`
## between map nodes, so the number would be fabricated. The subtitle below instead reads
## "Row X of Y · SHORT/FULL · Ascension N", built entirely from real `RunState` fields.
##
## DEVIATION FLAGGED: the mockup's RUN LENGTH subtitle ("12 waves · ~15 min · 3 bosses") has
## the same "waves" problem plus a "~15 min" pacing estimate this port has no data for. Replaced
## with "%d rows · %d bosses", both read from `RunMapGenerator.MODE_CONFIG` (rows already did
## this pre-v2; bosses is `boss_rows.size()`, new).
##
## GAP FLAGGED, RESOLVED 2026-09-20: the mockup's six nav tiles are LUNACIA PASS / UNLOCKS /
## THE VAULT / SAMPLE TEAMS / CODEX / COLLECTION. VAULT, SAMPLE TEAMS and CODEX already had real
## scenes and routed normally. LUNACIA PASS and UNLOCKS did NOT have a screen of their own — v1
## rendered them as inline sections on this very menu, and v2 deleted that inline content (the
## whole point of "nothing scrolls") without replacing it, which left their tiles disabled with
## a tooltip and left spending Gene Shard / claiming Pass rewards unreachable in the UI. Both now
## route to real screens (`scenes/pass/Pass.tscn`, `scenes/unlocks/Unlocks.tscn`) — see
## `_build_nav_tiles()`. COLLECTION still has no backing system anywhere in the project (not even
## an inline v1 section) and stays disabled.
##
## GAP FLAGGED: neither this mockup nor any other v2 meta-screen mockup shows a Settings entry
## point or a way to replay the tutorial. Both are real, necessary features already wired
## in this build (ABANDON RUN destroys a save; the tutorial has a voluntary replay requirement)
## and cannot simply disappear. A small top-right utility pair (gear / "?") fills that gap —
## the same secondary-utility-cluster convention Combat's own TopBar ButtonsRow already uses
## (Undo/Info/Log/Sound), not a new visual language.
##
## No mockup review has happened yet for anything this note doesn't call out — treat pixel
## values as a faithful-effort read of the mockup's inline styles, not a pixel-perfect port.

const T1_HERO_KEYS: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1", "bird1"]
const DEFAULT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const TEAM_SIZE := 5
const ASCENSION_MAX := 10

## CORRECTED 2026-09-20 consistency sweep: the `#C7BBD6` subtitle and `#6B5433` shard-chip
## caption were claimed above as one-off screen tints "not a reusable token" — they were wrong.
## Both are exact hex matches for tokens DangoTheme already carries (INFO_TEXT_ON_WELL,
## INK_ON_CREAM_MUTED), so both call sites now read those directly instead of a second local
## copy of the same colour.
##
## CORRECTED AGAIN 2026-09-20 (mockup pass): so was the third one. `_DARK_ON_PRIMARY_DIM` was
## `#5A3310`, which is `DangoTheme.INK_ON_PRIMARY_DIM` exactly — a token whose own docstring
## names "the BEGIN RUN and mode-card subtitles" as its call sites. The local copy is gone.

var _shard_value_label: Label
var _seed_edit: LineEdit
var _mode_short_btn: Button
var _mode_full_btn: Button
var _ascension_value_label: Label
var _ascension_stat_labels: Array[Label] = []
var _new_run_button: Button
var _continue_button: Button
var _begin_subtitle_label: Label
var _continue_subtitle_label: Label
var _team_row: HBoxContainer
var _content: Control
## Direct references for tests (t_mainmenu_ui.gd) — kept rather than a name-based recursive
## lookup, which silently breaks the next time a node here is renamed or re-parented (exactly
## the failure mode this routing task's own `Content` re-parenting invites).
var _run_setup_panel: PanelContainer
var _nav_tiles_grid: GridContainer

## Nav tiles keyed by id, for tests and for `_refresh_nav_tiles()`.
var _nav_tiles: Dictionary = {}

## A team handed over by the SAMPLE TEAMS screen or by TeamSelect's CONFIRM TEAM, consumed once
## on the next `_ready()`. See TeamSelect.gd's own header for the round-trip this now also
## carries. Cleared as it is read (see the original rationale below, unchanged by v2).
##
## A static var rather than a field on RunState or MetaState: a team the player is CONSIDERING is
## not run state — no run exists yet — and it is not persistent state either. Putting it in either
## place would mean a half-made choice surviving a crash, or a saved run's roster and a menu
## preselection sitting in the same field and eventually being mistaken for one another.
static var pending_team: Array[String] = []

var _team_selection: Array[String] = DEFAULT_TEAM.duplicate()
var _mode: String = "short"
var _ascension: int = 0
var _seed_value: int = 0


func _ready() -> void:
	# Onboarding tutorial gate (design/gdd/onboarding-tutorial.md, ported). MainMenu.tscn is
	# both the boot scene and the destination of every "return to menu" button, so this is the
	# single choke point every entry funnels through.
	if MetaState.needs_tutorial():
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn")
		return
	_seed_value = int(randi())
	if not pending_team.is_empty():
		_team_selection = pending_team.duplicate()
		pending_team = []
	_build_ui()


func _build_ui() -> void:
	# Shell first (FIX-PASS-02 §1 item 4 / godot/CLAUDE.md rule 2). MainMenu owns its own chrome
	# (title screen, no shared BACK/action bar) — no footer, per the routing task's scene list.
	var built := DangoScreen.build(self,
		MockupAssets.tex("assets/bg/entrance.jpg"), DangoTheme.Scrim.MENU,
		false, false)
	_content = built["content"]

	_build_title_block()
	_build_run_setup_panel()
	_build_nav_tiles()
	_build_team_row()


# ===========================================================================
# Identity + BEGIN RUN / CONTINUE RUN — mockup box: title @ 78,84 w640 ·
# BEGIN RUN 530x(86+5*2) · CONTINUE RUN 530x(68+4*2)
# ===========================================================================

func _build_title_block() -> void:
	var col := Control.new()
	col.name = "TitleBlock"
	# Was (84, 78) against the raw viewport; `_content` already provides the shell's 84px rail
	# and 48px safe-area top inset, so this is (0, 78-48) relative to it.
	col.position = Vector2(0, 78 - DangoScreen.SAFE)
	col.custom_minimum_size = Vector2(640, 0)
	_content.add_child(col)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	col.add_child(vbox)

	# BOX MODEL (design review 2026-09-20): every fixed size on this screen is the mockup's
	# CONTENT box; the black border adds OUTSIDE it. `height:36` + `border:4` = 44 outer.
	var badge := _make_pill("LUNACIA MUTANTS", DangoTheme.PRIMARY, DangoTheme.INK_ON_PRIMARY,
		15, 44.0, 15.0, 9, 4, 5.0, 0.24)
	vbox.add_child(badge)

	# Baloo 2's natural line height is 1.61em, so a raw two-line title opens a gap the design
	# never has. DangoTheme.display_label() derives the right `line_spacing` from the font's own
	# metrics — see the leading note in that file.
	var title := DangoTheme.display_label("AXIE DICE\nTACTICS", 104, DangoTheme.CREAM_RAISED,
		800, 0.005)
	# The mockup sets `line-height:.9` on this one block, not the system's .92 default, and puts
	# a hard 0/6px shelf under it. `DangoTheme.SHELF` is the nearest token to the mockup's
	# rgba(0,0,0,.45) — see the task report; no literal is inlined for it here.
	title.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_DISPLAY, 104, 0.9))
	title.add_theme_color_override("font_shadow_color", DangoTheme.SHELF)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_top", 16)
	title_margin.add_child(title)
	vbox.add_child(title_margin)

	var subtitle := Label.new()
	subtitle.text = ("Every Axie is a six-sided die and every face is a body part. "
		+ "Enemies telegraph first, so nothing in combat is hidden.")
	subtitle.custom_minimum_size = Vector2(530, 0)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", DangoTheme.INFO_TEXT_ON_WELL)
	subtitle.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_UI_SEMI, 16, 1.55))
	var subtitle_margin := MarginContainer.new()
	subtitle_margin.add_theme_constant_override("margin_top", 18)
	subtitle_margin.add_child(subtitle)
	vbox.add_child(subtitle_margin)

	var shard_chip := _build_shard_chip()
	var shard_margin := MarginContainer.new()
	shard_margin.add_theme_constant_override("margin_top", 24)
	shard_margin.add_child(shard_chip)
	vbox.add_child(shard_margin)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.custom_minimum_size = Vector2(530, 0)
	var buttons_margin := MarginContainer.new()
	buttons_margin.add_theme_constant_override("margin_top", 28)
	buttons_margin.add_child(buttons)
	vbox.add_child(buttons_margin)

	_new_run_button = _build_begin_run_button()
	buttons.add_child(_new_run_button)

	if RunState.has_saved_run():
		_continue_button = _build_continue_run_button()
		buttons.add_child(_continue_button)
	else:
		_continue_button = null


func _build_shard_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := DangoTheme.surface_style(DangoTheme.Surface.CREAM, 12, 4, 5.0, Vector2(16, 0))
	sb.content_margin_left = 10.0
	chip.add_theme_stylebox_override("panel", sb)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# `height:52` + `border:4` = 60 outer.
	chip.custom_minimum_size.y = 60

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = MockupAssets.tex("assets/fx/shard.png")
	row.add_child(icon)

	_shard_value_label = Label.new()
	_shard_value_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_shard_value_label.add_theme_font_size_override("font_size", 30)
	_shard_value_label.add_theme_color_override("font_color", DangoTheme.INK)
	_shard_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_shard_value_label)
	_refresh_shard_label()

	var caption := Label.new()
	caption.text = "GENE SHARD"
	caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	DangoTheme.apply_tracking(caption, 0.12, 13)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption)

	return chip


func _refresh_shard_label() -> void:
	_shard_value_label.text = str(MetaState.shard_pool)


func _build_begin_run_button() -> Button:
	var btn := Button.new()
	# M2: `height:86` + `border:5` = 96 outer. The 530 is the column's own width, which the
	# mockup already measures as the border box (a block child fills its parent's content box).
	btn.custom_minimum_size = Vector2(530, 96)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_hero_button_style(btn, DangoTheme.PRIMARY, 16, 5, 7.0)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 18)
	content.offset_left = 24
	content.offset_right = -24
	btn.add_child(content)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)

	var title := Label.new()
	title.text = "BEGIN RUN"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	DangoTheme.apply_tracking(title, 0.1, 30)
	text_col.add_child(title)

	_begin_subtitle_label = Label.new()
	_begin_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_begin_subtitle_label.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	_begin_subtitle_label.add_theme_font_size_override("font_size", 13)
	_begin_subtitle_label.add_theme_color_override("font_color",
		DangoTheme.INK_ON_PRIMARY_DIM)
	text_col.add_child(_begin_subtitle_label)

	var arrow := Label.new()
	arrow.text = "→"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	arrow.add_theme_font_size_override("font_size", 34)
	arrow.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	content.add_child(arrow)

	btn.pressed.connect(_on_new_run_pressed)
	_refresh_begin_subtitle()
	return btn


func _refresh_begin_subtitle() -> void:
	if _begin_subtitle_label == null:
		return
	_begin_subtitle_label.text = "%s · Ascension %d · seed %d" % [
		_mode.capitalize(), _ascension, _seed_value]


func _build_continue_run_button() -> Button:
	var btn := Button.new()
	# Same off-by-the-border as M2: `height:68` + `border:4` = 76 outer.
	btn.custom_minimum_size = Vector2(530, 76)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_hero_button_style(btn, DangoTheme.PANEL, 14, 4, 5.0, DangoTheme.PANEL_RAISED)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 16)
	content.offset_left = 22
	content.offset_right = -22
	btn.add_child(content)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)

	var title := Label.new()
	title.text = "CONTINUE RUN"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", DangoTheme.CREAM_HI)
	DangoTheme.apply_tracking(title, 0.1, 20)
	text_col.add_child(title)

	_continue_subtitle_label = Label.new()
	_continue_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_subtitle_label.text = _continue_run_subtitle()
	_continue_subtitle_label.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	_continue_subtitle_label.add_theme_font_size_override("font_size", 13)
	_continue_subtitle_label.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	text_col.add_child(_continue_subtitle_label)

	var arrow := Label.new()
	arrow.text = "↺"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	arrow.add_theme_font_size_override("font_size", 26)
	arrow.add_theme_color_override("font_color", DangoTheme.CREAM_HI)
	content.add_child(arrow)

	btn.pressed.connect(_on_continue_run_pressed)
	return btn


## See the DEVIATION FLAGGED note at the top of the file: this is deliberately NOT the mockup's
## literal "Row 4 of 18 · Wave 3 · 4 Axies alive" — no "wave" wording (regression-gated by
## t_mainmenu_ui.gd) and no fabricated "Axies alive" figure this port cannot back with real data.
func _continue_run_subtitle() -> String:
	var total := _rows_for(RunState.mode)
	var row := 0
	if RunState.current_node_id != "" and not RunState.map_graph.is_empty():
		var graph := RunMapGraph.from_data(RunState.map_graph)
		var node := graph.find_node(RunState.current_node_id)
		if node != null:
			row = node.row
	return "Row %d of %d · %s · Ascension %d" % [
		row, total, RunState.mode.capitalize(), RunState.ascension]


func _on_continue_run_pressed() -> void:
	if not RunState.load_run():
		push_warning("MainMenu: saved run could not be loaded")
		RunState.clear_saved_run()
		if _continue_button != null:
			_continue_button.queue_free()
			_continue_button = null
		return
	if not RunState.resume_combat.is_empty():
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")


# ===========================================================================
# RUN SETUP panel — mockup box: 566 + 5px border each side = 576 outer @ top 78, right 84
# ===========================================================================

func _build_run_setup_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "RunSetupPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Was (-84-566, 78) against the raw viewport; `_content`'s right edge is already the shell's
	# rail, so the rail's own 84 is dropped here (see _build_title_block()'s note).
	# M1: `width:566` + `border:5` EACH SIDE = 576 outer. With `right:84` that puts the panel's
	# left edge at x=1260, not the 1270 the build measured.
	panel.position = Vector2(-576, 78 - DangoScreen.SAFE)
	panel.custom_minimum_size = Vector2(576, 0)
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 18, 5, 7.0, Vector2(-1, -1)))
	DangoTheme.clip_to_frame(panel)   # G3
	_content.add_child(panel)
	_run_setup_panel = panel

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)

	var header := PanelContainer.new()
	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = DangoTheme.PANEL_RAISED
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 4)
	# Follow the panel's curve: radius 18 on a 5px border, inner edge at 13. A square band in a
	# rounded frame leaves a black wedge in both top corners — see DangoTheme.inner_radius().
	DangoTheme.round_top(header_sb, DangoTheme.inner_radius(18, 5))
	header_sb.content_margin_left = 22.0
	header_sb.content_margin_right = 22.0
	header_sb.content_margin_top = 16.0
	header_sb.content_margin_bottom = 16.0
	header.add_theme_stylebox_override("panel", header_sb)
	outer.add_child(header)

	var header_col := VBoxContainer.new()
	header.add_child(header_col)
	var header_title := Label.new()
	header_title.text = "RUN SETUP"
	header_title.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	header_title.add_theme_font_size_override("font_size", 28)
	header_title.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	DangoTheme.apply_tracking(header_title, 0.02, 28)
	header_col.add_child(header_title)
	var header_sub := Label.new()
	header_sub.text = "Seed + team + mode + ascension fully determine the run."
	header_sub.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	header_sub.add_theme_font_size_override("font_size", 13)
	header_sub.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	header_col.add_child(header_sub)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 22)
	body_margin.add_theme_constant_override("margin_right", 22)
	body_margin.add_theme_constant_override("margin_top", 18)
	body_margin.add_theme_constant_override("margin_bottom", 22)
	body_margin.add_child(body)
	outer.add_child(body_margin)

	_build_seed_section(body)
	_build_mode_section(body)
	_build_ascension_section(body)


func _add_field_label(text: String, parent: Node) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	DangoTheme.apply_tracking(lbl, 0.16, 13)
	parent.add_child(lbl)


# ===========================================================================
# Seed
# ===========================================================================

func _build_seed_section(parent: Node) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	parent.add_child(section)
	_add_field_label("SEED", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	section.add_child(row)

	_seed_edit = LineEdit.new()
	_seed_edit.text = str(_seed_value)
	# `height:50` + `border:3` = 56 outer.
	_seed_edit.custom_minimum_size = Vector2(0, 56)
	_seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_edit.add_theme_stylebox_override("normal",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(14, -1)))
	_seed_edit.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD)
	_seed_edit.add_theme_font_size_override("font_size", 24)
	_seed_edit.add_theme_color_override("font_color", DangoTheme.CREAM)
	DangoTheme.apply_tracking(_seed_edit, 0.04, 24, 700)
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	row.add_child(_seed_edit)

	var randomize_btn := Button.new()
	randomize_btn.name = "RandomSeedButton"
	# `width:136; height:50` + `border:3` = 142x56 outer.
	randomize_btn.custom_minimum_size = Vector2(142, 56)
	# The mockup draws a glyph + label pair inside this button, which `Button.icon` cannot size
	# to an exact 17px, so the pair is a child row (same convention as the nav tiles below).
	var rand_normal := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 11, 3, 0.0,
		Vector2(-1, -1))
	var rand_hover := rand_normal.duplicate() as StyleBoxFlat
	rand_hover.bg_color = DangoTheme.PRIMARY
	randomize_btn.add_theme_stylebox_override("normal", rand_normal)
	randomize_btn.add_theme_stylebox_override("hover", rand_hover)
	randomize_btn.add_theme_stylebox_override("pressed", rand_hover)
	randomize_btn.add_theme_stylebox_override("disabled", rand_normal)

	var rand_row := HBoxContainer.new()
	rand_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rand_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	rand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rand_row.add_theme_constant_override("separation", 8)
	randomize_btn.add_child(rand_row)

	var rand_icon := TextureRect.new()
	rand_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rand_icon.custom_minimum_size = Vector2(17, 17)
	rand_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rand_icon.texture = MockupAssets.tex("assets/fx/reroll.svg")
	rand_row.add_child(rand_icon)

	var rand_lbl := Label.new()
	rand_lbl.text = "RANDOM"
	rand_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rand_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rand_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	rand_lbl.add_theme_font_size_override("font_size", 15)
	rand_lbl.add_theme_color_override("font_color", DangoTheme.CREAM)
	DangoTheme.apply_tracking(rand_lbl, 0.08, 15)
	rand_row.add_child(rand_lbl)

	randomize_btn.pressed.connect(_on_randomize_seed_pressed)
	row.add_child(randomize_btn)


func _on_seed_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		_seed_value = int(new_text)
		_refresh_begin_subtitle()


func _on_randomize_seed_pressed() -> void:
	_seed_value = int(randi())
	_seed_edit.text = str(_seed_value)
	_refresh_begin_subtitle()


# ===========================================================================
# Mode (short/full) — mockup: two flex cards, SHORT/FULL, each with a subtitle
# ===========================================================================

func _build_mode_section(parent: Node) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	parent.add_child(section)
	_add_field_label("RUN LENGTH", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	section.add_child(row)

	var group := ButtonGroup.new()
	_mode_short_btn = _build_mode_card_button("short", group)
	_mode_short_btn.button_pressed = true
	_mode_short_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_mode = "short"
			_refresh_mode_buttons()
			_refresh_begin_subtitle())
	row.add_child(_mode_short_btn)

	_mode_full_btn = _build_mode_card_button("full", group)
	_mode_full_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_mode = "full"
			_refresh_mode_buttons()
			_refresh_begin_subtitle())
	row.add_child(_mode_full_btn)

	if not MetaState.has_unlock("u_full"):
		_mode_full_btn.disabled = true
		# Immediate in-button signal (P1-6, unchanged from v1): the lock glyph lives IN the
		# button's own text, not only in a separate caption — see
		# `test_locked_mode_button_signals_beyond_caption`.
		_mode_full_btn.text = "%s  🔒" % _mode_full_btn.text
		var full_sub := _mode_full_btn.get_node_or_null("Subtitle") as Label
		if full_sub != null:
			full_sub.text = "%d rows · unlock for %d shard" % [
				_rows_for("full"), _unlock_cost("u_full")]

	# FIX-PASS-01 M4: `_mode_short_btn.button_pressed = true` above fires BEFORE `.toggled` is
	# connected (the connect() call comes after it), so the initial SHORT selection never ran
	# through `_refresh_mode_buttons()` — it kept `_build_mode_card_button()`'s plain secondary
	# stylebox, and a `toggle_mode` Button with `button_pressed = true` renders its PRESSED state
	# by default, which for the secondary style is `PRIMARY.darkened(0.22)`: a muddy brown that
	# is not a real token, not the crisp PRIMARY fill every other selected state in this game
	# uses. One explicit refresh after both buttons exist fixes the INITIAL paint the same way
	# every later click already fixes it.
	_refresh_mode_buttons()


## One "SHORT"/"FULL" card. Kept as a real toggle Button (not a hand-rolled PanelContainer) so
## `.button_pressed`/`.disabled`/`.toggled` keep working exactly as v1's tests expect.
##
## The mockup draws the card's two lines at two DIFFERENT sizes (19 / 12), which one
## `Button.text` cannot do. So the title line stays in `.text` — which is also where the lock
## glyph has to live, per `t_mainmenu_ui.test_locked_mode_button_signals_beyond_the_lock_glyph`
## — and the 12px subtitle is a child Label pinned to a strip the stylebox reserves at the
## bottom of the card. `padding:12px 14px` in the mockup is the L/R margin and the top margin;
## the bottom margin is that 12 plus the strip and its 3px gap.
const _MODE_SUB_STRIP := 18.0
const _MODE_CARD_PAD := 12.0
const _MODE_CARD_PAD_X := 14.0

func _build_mode_card_button(mode: String, group: ButtonGroup) -> Button:
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	var rows := int(cfg.get("total_rows", 0))
	var bosses := (cfg.get("boss_rows", []) as Array).size()
	var btn := Button.new()
	btn.name = "ModeCard_%s" % mode
	btn.text = mode.to_upper()
	btn.toggle_mode = true
	btn.button_group = group
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", 19)
	DangoTheme.apply_tracking(btn, 0.08, 19)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "%d rows · %d bosses" % [rows, bosses]
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sub.offset_left = _MODE_CARD_PAD_X
	sub.offset_right = -_MODE_CARD_PAD_X
	sub.offset_top = -(_MODE_CARD_PAD + _MODE_SUB_STRIP)
	sub.offset_bottom = -_MODE_CARD_PAD
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	sub.add_theme_font_size_override("font_size", 12)
	btn.add_child(sub)
	return btn


## The selected card is the one loud fill on this panel (PRIMARY, 4px outline, 4px shelf); the
## other is a WELL with a 3px outline and no shelf, exactly as the mockup draws the pair.
func _apply_mode_card_style(btn: Button, selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.PRIMARY if selected else DangoTheme.surface_color(
		DangoTheme.Surface.WELL)
	sb.border_color = Color.BLACK
	sb.set_border_width_all(4 if selected else 3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = _MODE_CARD_PAD_X
	sb.content_margin_right = _MODE_CARD_PAD_X
	sb.content_margin_top = _MODE_CARD_PAD
	sb.content_margin_bottom = _MODE_CARD_PAD + _MODE_SUB_STRIP + 3.0
	if selected:
		sb.shadow_color = DangoTheme.SHELF
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 4)
	var hover := sb.duplicate() as StyleBoxFlat
	if not selected:
		hover.bg_color = DangoTheme.PANEL_RAISED
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)

	var ink: Color = DangoTheme.INK_ON_PRIMARY if selected else DangoTheme.FAINT_TEXT
	for color_key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_disabled_color"]:
		btn.add_theme_color_override(color_key, ink)
	var sub := btn.get_node_or_null("Subtitle") as Label
	if sub != null:
		sub.add_theme_color_override("font_color",
			DangoTheme.INK_ON_PRIMARY_DIM if selected else DangoTheme.FAINT_TEXT)


## The shard price of an unlock, read from ContentDB rather than copied into this screen.
## Returns 0 when the id is unknown, which is a content bug, not a display state.
## NOT static: it reads the ContentDB autoload, and every caller is an instance method anyway.
func _unlock_cost(unlock_id: String) -> int:
	for u in ContentDB.UNLOCKS:
		var row: Dictionary = u
		if String(row.get("id", "")) == unlock_id:
			return int(row.get("cost", 0))
	return 0


## The authoritative row count for a mode, from the map generator itself — never a second copy.
static func _rows_for(mode: String) -> int:
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	return int(cfg.get("total_rows", 0))


func _refresh_mode_buttons() -> void:
	_apply_mode_card_style(_mode_short_btn, _mode_short_btn.button_pressed)
	_apply_mode_card_style(_mode_full_btn,
		_mode_full_btn.button_pressed and not _mode_full_btn.disabled)


# ===========================================================================
# Ascension (0-10) — mockup: stepper + 4 stat cells (ENEMY HP/ENEMY DMG/BOSS HP/WEAKEN)
# ===========================================================================

func _build_ascension_section(parent: Node) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 11)
	parent.add_child(section)
	_add_field_label("ASCENSION", section)

	var row := HBoxContainer.new()
	# The mockup's gap here is 12, not the 10 used by the other rows in this panel.
	row.add_theme_constant_override("separation", 12)
	# REVERSED 2026-09-20 (mockup pass): FIX-PASS-01 M5 made this row SHRINK_BEGIN to close
	# "380px of empty well". meta-screens-v2.html draws the value well as `flex:1 1 auto`
	# between two fixed 50px buttons — it is meant to span the panel body, and godot/CLAUDE.md
	# puts the mockup above a prose restatement of it.
	section.add_child(row)

	var minus_btn := _build_step_button("−", false)
	minus_btn.pressed.connect(func() -> void:
		_ascension = max(0, _ascension - 1)
		_refresh_ascension())
	row.add_child(minus_btn)

	_ascension_value_label = Label.new()
	# `height:50` + `border:3` = 56 outer.
	_ascension_value_label.custom_minimum_size = Vector2(0, 56)
	_ascension_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ascension_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ascension_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ascension_value_label.add_theme_stylebox_override("normal",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(-1, -1)))
	_ascension_value_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_ascension_value_label.add_theme_font_size_override("font_size", 28)
	_ascension_value_label.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	row.add_child(_ascension_value_label)

	var plus_btn := _build_step_button("+", true)
	plus_btn.pressed.connect(func() -> void:
		_ascension = mini(_ascension_ceiling(), _ascension + 1)
		_refresh_ascension())
	row.add_child(plus_btn)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 8)
	section.add_child(stats_row)
	_ascension_stat_labels.clear()
	for _i in 4:
		var cell := PanelContainer.new()
		cell.add_theme_stylebox_override("panel",
			DangoTheme.surface_style(DangoTheme.Surface.WELL, 10, 3, 0.0, Vector2(10, 8)))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cell_col := VBoxContainer.new()
		cell_col.add_theme_constant_override("separation", 2)
		cell.add_child(cell_col)
		var k_lbl := Label.new()
		k_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		k_lbl.add_theme_font_size_override("font_size", 11)
		k_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
		DangoTheme.apply_tracking(k_lbl, 0.1, 11)
		cell_col.add_child(k_lbl)
		var v_lbl := Label.new()
		v_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		v_lbl.add_theme_font_size_override("font_size", 19)
		v_lbl.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
		cell_col.add_child(v_lbl)
		stats_row.add_child(cell)
		# k_lbl stashed as metadata on v_lbl so _refresh_ascension() can address both by index.
		v_lbl.set_meta("key_label", k_lbl)
		_ascension_stat_labels.append(v_lbl)

	# REMOVED 2026-09-20 (mockup pass): a "Win a run to unlock Ascension 1." hint used to sit
	# here. meta-screens-v2.html's ASCENSION block is the stepper and the four stat cells and
	# nothing else, and godot/CLAUDE.md's "never invent UI" covers helper text specifically.
	# Called out in the task report rather than dropped silently.
	_refresh_ascension()


## `primary` is the mockup's asymmetry, not a mistake: − is a PANEL_RAISED utility and + is
## the loud PRIMARY fill, both `50x50` + `border:3` = 56x56 outer, radius 11, no shelf.
func _build_step_button(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	# `width:50; height:50` + `border:3` = 56x56 outer.
	btn.custom_minimum_size = Vector2(56, 56)
	var sb := DangoTheme.surface_style(
		DangoTheme.Surface.PANEL_RAISED, 11, 3, 0.0, Vector2(-1, -1))
	if primary:
		sb.bg_color = DangoTheme.PRIMARY
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = DangoTheme.PRIMARY.lightened(0.12) if primary else DangoTheme.PRIMARY
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", sb)
	var ink: Color = DangoTheme.INK_ON_PRIMARY if primary else DangoTheme.MUTED_TEXT
	for color_key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_disabled_color"]:
		btn.add_theme_color_override(color_key, ink)
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", 26)
	return btn


## src/client.html:4584 — the selector offers 0..min(10, META.ascMax). The ladder is climbed by
## WINNING at your current ceiling (RunState.end_run()).
func _ascension_ceiling() -> int:
	return mini(ASCENSION_MAX, MetaState.asc_max)


func _refresh_ascension() -> void:
	_ascension = clampi(_ascension, 0, _ascension_ceiling())
	_ascension_value_label.text = "A%d" % _ascension
	var m: Dictionary = ContentDB.ascension_mods(_ascension)
	var stats := [
		["ENEMY HP", "×%.2f" % float(m.get("hp", 1.0))],
		["ENEMY DMG", "×%.2f" % float(m.get("dmg", 1.0))],
		["BOSS HP", "×%.2f" % float(m.get("boss_hp", 1.0))],
		["WEAKEN", "YES" if bool(m.get("weaken", false)) else "NO"],
	]
	for i in _ascension_stat_labels.size():
		var v_lbl := _ascension_stat_labels[i]
		var k_lbl: Label = v_lbl.get_meta("key_label")
		k_lbl.text = stats[i][0]
		v_lbl.text = stats[i][1]
		v_lbl.add_theme_color_override("font_color",
			DangoTheme.FAINT_TEXT if stats[i][1] == "NO" else DangoTheme.CREAM_RAISED)
	_refresh_begin_subtitle()


# ===========================================================================
# Nav tiles — mockup: 3x2 grid, 452 wide @ bottom 46, right 84, tile h 66 + border 3
# ===========================================================================

## M3/M5 box model. `height:66` is the tile's CONTENT box and the 3px black border adds outside
## it, so the tile is 72 outer — which is also what makes the grid 153 tall rather than 141.
## `padding:9px 11px` sits INSIDE that border, so the content inset measured from the tile's
## outer edge is border + padding on each side.
const _NAV_TILE_H := 72.0
const _NAV_TILE_GAP := 9.0
const _NAV_TILE_BORDER := 3.0
const _NAV_TILE_PAD_X := 11.0
const _NAV_TILE_PAD_Y := 9.0
const _NAV_GRID_W := 452.0


func _build_nav_tiles() -> void:
	var grid := GridContainer.new()
	grid.name = "NavTiles"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	grid.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Exact, not estimated: 2 rows x fixed OUTER tile height (72) + 1 fixed v_separation (9).
	# `.position` on a point-anchored Control sets the TOP-LEFT corner's offset regardless of
	# which corner preset was used, so the bottom margin has to be baked into position.y here
	# rather than expressed as an "offset from the bottom" directly. Was
	# (-84-452, -SAFE_AREA-(66*2+9)) against the raw viewport; `_content`'s own right/bottom
	# edges already sit at the rail and the safe line (this screen takes no footer), so both the
	# rail's 84 and the extra SAFE_AREA subtraction are dropped here.
	# RESTORED 2026-09-20: meta-screens-v2.html puts this block at `bottom:46`. The old
	# uniform-48 safe-area law clamped it outward to the shell's own bottom edge; that law is
	# gone, so the 2px the mockup actually draws is added back here. `_content` ends at the
	# 48px line (this screen takes no footer), so a 46px inset is +2 past it.
	grid.position = Vector2(-_NAV_GRID_W,
		-(_NAV_TILE_H * 2.0 + _NAV_TILE_GAP) + (DangoScreen.SAFE - 46.0))
	grid.custom_minimum_size = Vector2(_NAV_GRID_W, _NAV_TILE_H * 2.0 + _NAV_TILE_GAP)
	_content.add_child(grid)
	_nav_tiles_grid = grid

	_nav_tiles.clear()
	# UPDATED 2026-09-20: both tiles now route to real screens (scenes/pass/Pass.tscn,
	# scenes/unlocks/Unlocks.tscn). This closes the gap the comment above still documents for
	# history — v2 deleted the inline Pass/Unlocks lists from this menu, and until these two
	# screens existed, spending Gene Shard and claiming Pass rewards were unreachable in the UI.
	_nav_tiles["pass"] = _add_nav_tile(grid, "pass", "LUNACIA PASS",
		"LV %d / %d" % [int(MetaState.bp_progress().get("level", 0)), ContentDB.BP_MAX_LEVEL],
		DangoTheme.CREAM_HI, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/pass/Pass.tscn"))
	_nav_tiles["unlocks"] = _add_nav_tile(grid, "unlocks", "UNLOCKS",
		"%d / %d" % [_owned_unlock_count(), ContentDB.UNLOCKS.size()],
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/unlocks/Unlocks.tscn"))
	# The mockup inks this value #8BDCFF, a pale ice blue — NOT SHIELD_BLUE (#31C6FF).
	# STATUS_FREEZE is the only exact match DangoTheme carries for that hex; the right fix is a
	# named token of its own, which is in the task report rather than added here.
	_nav_tiles["vault"] = _add_nav_tile(grid, "vault", "THE VAULT",
		"%d / %d" % [MetaState.vault.size(), MetaState.VAULT_MAX],
		DangoTheme.STATUS_FREEZE, true, "",
		func() -> void:
			# VLT-05: the Vault's USE IN TEAM puts one imported Axie into the CURRENT roster,
			# so the roster has to survive the trip. Same hand-off channel the EDIT TEAM
			# button already uses — and if the player just comes back with BACK, this
			# `_ready()` reads it again and the team is unchanged.
			pending_team = _team_selection.duplicate()
			get_tree().change_scene_to_file("res://scenes/vault/Vault.tscn"))
	_nav_tiles["guides"] = _add_nav_tile(grid, "guides", "SAMPLE TEAMS",
		"%d COMPS" % ContentDB.GUIDES.size(),
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/guides/Guides.tscn"))
	_nav_tiles["codex"] = _add_nav_tile(grid, "codex", "CODEX",
		"%d TABS" % CodexContent.TABS.size(),
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/codex/Codex.tscn"))
	# MNU-06 names all six destinations of this grid, and Settings is the sixth. It used to be a
	# 44px "⚙" floating in the screen's top-right corner next to a "?" — two pieces of chrome the
	# mockup does not draw anywhere, sitting over the artwork, while the grid the mockup DOES
	# draw was one tile short. Both corner buttons are gone; the tutorial they also carried is
	# reachable from Settings (SET-tutorial), which is where a replay belongs.
	#
	# FIX-PASS-01 M2 dropped COLLECTION from this grid — "an empty tile is worse than a missing
	# one", and COLLECTION has no backing system in this port. That still holds, and Settings
	# takes the slot it left, so the grid is the full 3 x 2 the mockup draws.
	_nav_tiles["settings"] = _add_nav_tile(grid, "settings", "SETTINGS", "AUDIO · SAVE",
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/settings/Settings.tscn"))


func _owned_unlock_count() -> int:
	var n := 0
	for u in ContentDB.UNLOCKS:
		if MetaState.has_unlock(String((u as Dictionary).get("id", ""))):
			n += 1
	return n


func _add_nav_tile(parent: GridContainer, id: String, label_text: String, value_text: String,
		value_color: Color, enabled: bool, disabled_reason: String, on_press: Callable) -> Button:
	var tile := Button.new()
	tile.name = "NavTile_%s" % id
	# BUG FIX (found via qa_menu_result_capture screenshot review): with no width floor, an
	# empty-`.text` Button's own minimum size is ~0 wide (all the real label content lives in
	# child Labels the Button itself does not measure), so GridContainer collapsed every column
	# to near-zero width and every tile's content painted on top of its neighbours'. 144 = one
	# third of the 452-wide block minus the two 9px gaps, per the mockup's 3-column grid.
	tile.custom_minimum_size = Vector2(144, _NAV_TILE_H)
	# `grid-template-columns:repeat(3,minmax(0,1fr))` — the three columns share the 452 exactly.
	# Without EXPAND the grid leaves the remainder as a dead strip on the right.
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.disabled = not enabled
	tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not enabled:
		tile.tooltip_text = disabled_reason

	var normal_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL_ON_ART, 12, 3, 4.0,
		Vector2(11, 9))
	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = DangoTheme.PANEL_RAISED
	var disabled_sb := normal_sb.duplicate() as StyleBoxFlat
	disabled_sb.bg_color = DangoTheme.PANEL_ON_ART.darkened(0.25)
	tile.add_theme_stylebox_override("normal", normal_sb)
	tile.add_theme_stylebox_override("hover", hover_sb)
	tile.add_theme_stylebox_override("pressed", hover_sb)
	tile.add_theme_stylebox_override("disabled", disabled_sb)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	# M5: the label and the value share ONE left edge. `PRESET_FULL_RECT` on a child of a Button
	# spans the button's raw rect and ignores the stylebox's content margins entirely, which is
	# why the 17px value painted hard against the tile's black border, left of its own 12px
	# label. The mockup's `padding:9px 11px` is spelled out here instead, measured from the
	# outer edge — border first, then the padding.
	content.offset_left = _NAV_TILE_BORDER + _NAV_TILE_PAD_X
	content.offset_right = -(_NAV_TILE_BORDER + _NAV_TILE_PAD_X)
	content.offset_top = _NAV_TILE_BORDER + _NAV_TILE_PAD_Y
	content.offset_bottom = -(_NAV_TILE_BORDER + _NAV_TILE_PAD_Y)
	# `justify-content:space-between`: label pinned to the top of the padding box, value to the
	# bottom. A VBoxContainer has no space-between, so the label takes the slack instead.
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	tile.add_child(content)

	var label_lbl := Label.new()
	label_lbl.text = label_text
	label_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	# REVERSED 2026-09-20 (mockup pass): FIX-PASS-01 M2 pushed this to 13 on a type-floor
	# argument. meta-screens-v2.html draws 12 here, and godot/CLAUDE.md rule 5 is explicit that
	# a mockup number beats the old project floor.
	label_lbl.add_theme_font_size_override("font_size", 12)
	label_lbl.add_theme_color_override("font_color",
		DangoTheme.INFO_TEXT_ON_WELL if enabled else DangoTheme.TEXT_DIM)
	DangoTheme.apply_tracking(label_lbl, 0.08, 12)
	label_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content.add_child(label_lbl)

	var value_lbl := Label.new()
	value_lbl.text = value_text
	value_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	value_lbl.add_theme_font_size_override("font_size", 17)
	value_lbl.add_theme_color_override("font_color", value_color if enabled else DangoTheme.TEXT_DIM)
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	content.add_child(value_lbl)

	if enabled and on_press.is_valid():
		tile.pressed.connect(on_press)
	parent.add_child(tile)
	return tile


# ===========================================================================
# Team row — read-only lineup + EDIT TEAM link. Mockup box: 1244 wide @ bottom 46,
# left 84 · team card 220 + 4px border each side = 228 outer, art 124.
# ===========================================================================

## Header row (30) + its top margin (12) + the card itself. The card's height is pinned to
## `_TEAM_CARD_HEIGHT` in `_build_team_card()` rather than left content-driven, specifically so
## this position math stays exact instead of an estimate that can drift out of sync with the
## card's real rendered height.
## FIX-PASS-01 M1: was 236, which put the card's bottom edge inside the old 46px bottom margin
## instead of the law's 48px safe area (L1) — right at the edge of the viewport with no room to
## spare. Capped at 220 per the audit's own suggested fix ("cap the card at 220px").
const _TEAM_CARD_HEIGHT := 220

## M4 box model: `width:220` + `border:4` EACH SIDE = 228 outer, and with `gap:13` that makes
## the pitch 241 — not the 220/233 the build measured. The header is `height:34` +
## `border-bottom:3` = 37 outer, the same off-by-the-border.
const _TEAM_CARD_WIDTH := 228
const _TEAM_CARD_HEADER_H := 37
## The EDIT TEAM chip is `height:26` + `border:2` = 30 outer, and it is the tallest thing in the
## YOUR TEAM header row, so it sets that row's height for the block's position math below.
const _TEAM_HEADER_ROW_H := 30


func _build_team_row() -> void:
	var wrap := Control.new()
	wrap.name = "TeamRow"
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Was (84, -SAFE_AREA-(...)) against the raw viewport; `_content`'s own left/bottom edges
	# already sit at the rail and the safe line, so both are dropped here (see the nav-tiles
	# grid's identical note above).
	# RESTORED 2026-09-20: `bottom:46` in the mockup — same +2 past `_content`'s 48px bottom
	# edge as the nav-tile grid above.
	wrap.position = Vector2(0,
		-(_TEAM_HEADER_ROW_H + 12 + _TEAM_CARD_HEIGHT) + (DangoScreen.SAFE - 46.0))
	wrap.custom_minimum_size = Vector2(1244, _TEAM_HEADER_ROW_H + 12 + _TEAM_CARD_HEIGHT)
	_content.add_child(wrap)

	var vbox := VBoxContainer.new()
	wrap.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "YOUR TEAM"
	eyebrow.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	DangoTheme.apply_tracking(eyebrow, 0.16, 13)
	header.add_child(eyebrow)

	var edit_btn := Button.new()
	edit_btn.text = "EDIT TEAM →"
	edit_btn.custom_minimum_size = Vector2(0, _TEAM_HEADER_ROW_H)
	# Mockup: a 26px chip, radius 7, 2px outline, PANEL_RAISED, no shelf — not the 12/3/shelf-4
	# secondary button `style_button()` builds.
	var edit_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 7, 2, 0.0,
		Vector2(10, 0))
	var edit_hover := edit_sb.duplicate() as StyleBoxFlat
	edit_hover.bg_color = DangoTheme.PRIMARY
	edit_btn.add_theme_stylebox_override("normal", edit_sb)
	edit_btn.add_theme_stylebox_override("hover", edit_hover)
	edit_btn.add_theme_stylebox_override("pressed", edit_hover)
	edit_btn.add_theme_stylebox_override("disabled", edit_sb)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_disabled_color"]:
		edit_btn.add_theme_color_override(color_key, DangoTheme.CREAM_HI)
	edit_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edit_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	edit_btn.add_theme_font_size_override("font_size", 13)
	DangoTheme.apply_tracking(edit_btn, 0.06, 13)
	edit_btn.pressed.connect(_on_edit_team_pressed)
	header.add_child(edit_btn)

	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_top", 12)
	vbox.add_child(row_margin)

	_team_row = HBoxContainer.new()
	_team_row.add_theme_constant_override("separation", 13)
	row_margin.add_child(_team_row)

	_refresh_team_row()


func _on_edit_team_pressed() -> void:
	pending_team = _team_selection.duplicate()
	get_tree().change_scene_to_file("res://scenes/main_menu/TeamSelect.tscn")


func _refresh_team_row() -> void:
	for c in _team_row.get_children():
		_team_row.remove_child(c)
		c.queue_free()
	for hero_key in _team_selection:
		_team_row.add_child(_build_team_card(hero_key))


func _build_team_card(hero_key: String) -> PanelContainer:
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))
	var accent := DangoTheme.class_color(cls)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_TEAM_CARD_WIDTH, _TEAM_CARD_HEIGHT)
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 15, 4, 6.0))
	DangoTheme.clip_to_frame(card)   # G3

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var header := PanelContainer.new()
	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = accent
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 3)
	# Card is radius 15 on a 4px border -> inner edge at 11.
	DangoTheme.round_top(header_sb, DangoTheme.inner_radius(15, 4))
	header_sb.content_margin_left = 11.0
	header_sb.content_margin_right = 11.0
	header_sb.content_margin_top = 0.0
	header_sb.content_margin_bottom = 0.0
	header.add_theme_stylebox_override("panel", header_sb)
	header.custom_minimum_size.y = _TEAM_CARD_HEADER_H
	col.add_child(header)

	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var name_lbl := Label.new()
	name_lbl.text = String(hero_def.get("n", hero_key))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	DangoTheme.apply_tracking(name_lbl, 0.02, 16)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(name_lbl)
	var cls_lbl := Label.new()
	cls_lbl.text = cls.to_upper()
	cls_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	cls_lbl.add_theme_font_size_override("font_size", 13)
	cls_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	DangoTheme.apply_tracking(cls_lbl, 0.06, 13)
	cls_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(cls_lbl)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 11)
	body_margin.add_theme_constant_override("margin_right", 11)
	body_margin.add_theme_constant_override("margin_top", 8)
	body_margin.add_theme_constant_override("margin_bottom", 11)
	col.add_child(body_margin)

	var body_col := VBoxContainer.new()
	body_col.add_theme_constant_override("separation", 5)
	body_margin.add_child(body_col)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0, 124)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = MockupAssets.tex("assets/portrait/%s.png" % cls)
	body_col.add_child(portrait)

	var stat_row := HBoxContainer.new()
	body_col.add_child(stat_row)
	var tier_lbl := Label.new()
	tier_lbl.text = "TIER %d" % int(hero_def.get("tier", 1))
	tier_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	tier_lbl.add_theme_font_size_override("font_size", 13)
	tier_lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	DangoTheme.apply_tracking(tier_lbl, 0.06, 13)
	stat_row.add_child(tier_lbl)
	var hp_lbl := Label.new()
	hp_lbl.text = "%d HP" % int(hero_def.get("max_hp", 0))
	hp_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	hp_lbl.add_theme_font_size_override("font_size", 19)
	hp_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	stat_row.add_child(hp_lbl)

	return card


# ===========================================================================
# Utility corner (SETTINGS / HOW TO PLAY) — see the GAP FLAGGED note at the top of the file.
# Not in the mockup at all; kept small and out of the way, same convention as Combat's own
# TopBar ButtonsRow (Undo/Info/Log/Sound).
# ===========================================================================

# _build_utility_corner() — DELETED 2026-09-20 (MNU-06).
#
# A 44px "?" and a 44px "⚙" floated in the top-right corner over the artwork. Neither is in
# meta-screens-v2.html, and MNU-06 lists Settings as one of the nav grid's six tiles rather than
# as corner chrome. Settings is a tile now; the tutorial the "?" opened is reachable from the
# Settings screen.


# ===========================================================================
# Shared helpers
# ===========================================================================

func _make_pill(text: String, bg: Color, ink: Color, font_size: int, height: float = 0.0,
		pad_x: float = 15.0, radius: int = 9, border_w: int = 4,
		shelf: float = 0.0, tracking_em: float = 0.0) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := DangoTheme.solid_chip_style(bg, radius, border_w, Vector2(pad_x, 0))
	if shelf > 0.0:
		sb.shadow_color = DangoTheme.SHELF_DEEP if shelf >= 6.0 else DangoTheme.SHELF
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, shelf)
	pill.add_theme_stylebox_override("panel", sb)
	if height > 0.0:
		pill.custom_minimum_size.y = height
	var lbl := Label.new()
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", ink)
	DangoTheme.apply_tracking(lbl, tracking_em, font_size)
	pill.add_child(lbl)
	return pill


## Shared look for the two hero-object buttons (BEGIN RUN / CONTINUE RUN) — full custom StyleBox
## per state since neither is a plain `style_button()` primary/secondary (BEGIN RUN's shelf/press
## geometry and CONTINUE RUN's PANEL tone are both bespoke to this screen's redline).
func _apply_hero_button_style(btn: Button, fill: Color, radius: int, border_w: int,
		shelf: float, hover_fill: Variant = null) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = Color.BLACK
	normal.set_border_width_all(border_w)
	normal.set_corner_radius_all(radius)
	normal.shadow_color = DangoTheme.SHELF_DEEP if shelf >= 6.0 else DangoTheme.SHELF
	normal.shadow_size = 0
	normal.shadow_offset = Vector2(0, shelf)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = (hover_fill as Color) if hover_fill is Color else fill.lightened(0.12)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.shadow_size = 0
	pressed.shadow_offset = Vector2.ZERO
	pressed.set_border_width_all(border_w + 1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)


# ===========================================================================
# Begin run
# ===========================================================================

func _on_new_run_pressed() -> void:
	if _seed_edit.text.is_valid_int():
		_seed_value = int(_seed_edit.text)
	var team: Array[String] = _team_selection.duplicate()
	RunState.start_new_run(_seed_value, team, _mode, _ascension, false)
	get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")
