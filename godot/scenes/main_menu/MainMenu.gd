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
## copy of the same colour. `_DARK_ON_PRIMARY_DIM` has no existing match and stays local — it is
## genuinely this screen's own copy colour (BEGIN RUN / CONTINUE RUN button subtitles only).
const _DARK_ON_PRIMARY_DIM := Color(0x5A / 255.0, 0x33 / 255.0, 0x10 / 255.0)

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
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load("res://assets/backgrounds/origins/scene/4-entrance.jpg"), DangoTheme.Scrim.MENU)

	_build_title_block()
	_build_run_setup_panel()
	_build_nav_tiles()
	_build_team_row()
	_build_utility_corner()


# ===========================================================================
# Identity + BEGIN RUN / CONTINUE RUN — mockup box: title @ 78,84 w640 ·
# BEGIN RUN 530x86 · CONTINUE RUN 530x68
# ===========================================================================

func _build_title_block() -> void:
	var col := Control.new()
	col.name = "TitleBlock"
	col.position = Vector2(84, 78)
	col.custom_minimum_size = Vector2(640, 0)
	add_child(col)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	col.add_child(vbox)

	var badge := _make_pill("LUNACIA MUTANTS", DangoTheme.PRIMARY, DangoTheme.INK_ON_PRIMARY, 15)
	vbox.add_child(badge)

	# `line_spacing` was -6 here and the two lines still sat 142px apart, because that is Baloo
	# 2's natural line height at size 88 (measured, 1.61em). DangoTheme.display_label() derives
	# the right value from the font's own metrics — see the leading note in that file.
	var title := DangoTheme.display_label("AXIE DICE\nTACTICS", 88, DangoTheme.CREAM_RAISED)
	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_top", 16)
	title_margin.add_child(title)
	vbox.add_child(title_margin)

	var subtitle := Label.new()
	subtitle.text = ("Every Axie is a six-sided die and every face is a body part. "
		+ "Enemies telegraph first — nothing in combat is hidden.")
	subtitle.custom_minimum_size = Vector2(530, 0)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", DangoTheme.INFO_TEXT_ON_WELL)
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
	var sb := DangoTheme.surface_style(DangoTheme.Surface.CREAM, 12, 4, 5.0, Vector2(16, 10))
	sb.content_margin_left = 10.0
	chip.add_theme_stylebox_override("panel", sb)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path := "res://assets/icons/web/shard.png"
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	row.add_child(icon)

	_shard_value_label = Label.new()
	_shard_value_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_shard_value_label.add_theme_font_size_override("font_size", 30)
	_shard_value_label.add_theme_color_override("font_color", DangoTheme.INK)
	row.add_child(_shard_value_label)
	_refresh_shard_label()

	var caption := Label.new()
	caption.text = "GENE SHARD"
	caption.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	row.add_child(caption)

	return chip


func _refresh_shard_label() -> void:
	_shard_value_label.text = str(MetaState.shard_pool)


func _build_begin_run_button() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(530, 86)
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
	text_col.add_child(title)

	_begin_subtitle_label = Label.new()
	_begin_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_begin_subtitle_label.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	_begin_subtitle_label.add_theme_font_size_override("font_size", 13)
	_begin_subtitle_label.add_theme_color_override("font_color", _DARK_ON_PRIMARY_DIM)
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
	btn.custom_minimum_size = Vector2(530, 68)
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
	text_col.add_child(title)

	_continue_subtitle_label = Label.new()
	_continue_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_subtitle_label.text = _continue_run_subtitle()
	_continue_subtitle_label.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	_continue_subtitle_label.add_theme_font_size_override("font_size", 13)
	_continue_subtitle_label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
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
# RUN SETUP panel — mockup box: 566 wide @ top 78, right 84
# ===========================================================================

func _build_run_setup_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "RunSetupPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-84 - 566, 78)
	panel.custom_minimum_size = Vector2(566, 0)
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 18, 5, 7.0, Vector2(-1, -1)))
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)

	var header := PanelContainer.new()
	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = DangoTheme.PANEL_RAISED
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 4)
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
	header_col.add_child(header_title)
	var header_sub := Label.new()
	header_sub.text = "Seed + team + mode + ascension fully determine the run."
	header_sub.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
	header_sub.add_theme_font_size_override("font_size", 13)
	header_sub.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
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
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
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
	_seed_edit.custom_minimum_size = Vector2(0, 50)
	_seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_edit.add_theme_stylebox_override("normal",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(14, -1)))
	_seed_edit.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_seed_edit.add_theme_font_size_override("font_size", 20)
	_seed_edit.add_theme_color_override("font_color", DangoTheme.CREAM)
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	row.add_child(_seed_edit)

	var randomize_btn := Button.new()
	randomize_btn.custom_minimum_size = Vector2(136, 50)
	randomize_btn.text = "RANDOM"
	DangoTheme.style_button(randomize_btn, false)
	randomize_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
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
		_mode_full_btn.text = "%s\n%s  🔒" % [
			_mode_full_btn.text.split("\n")[0], _mode_full_btn.text.split("\n")[1]]


## One "SHORT"/"FULL" card. Kept as a real toggle Button (not a hand-rolled PanelContainer) so
## `.button_pressed`/`.disabled`/`.toggled` keep working exactly as v1's tests expect — only the
## StyleBox and the two-line `.text` content changed for v2's card look.
func _build_mode_card_button(mode: String, group: ButtonGroup) -> Button:
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	var rows := int(cfg.get("total_rows", 0))
	var bosses := (cfg.get("boss_rows", []) as Array).size()
	var btn := Button.new()
	btn.text = "%s\n%d rows · %d bosses" % [mode.to_upper(), rows, bosses]
	btn.toggle_mode = true
	btn.button_group = group
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DangoTheme.style_button(btn, false)
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	return btn


## The authoritative row count for a mode, from the map generator itself — never a second copy.
static func _rows_for(mode: String) -> int:
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	return int(cfg.get("total_rows", 0))


func _refresh_mode_buttons() -> void:
	DangoTheme.style_button(_mode_short_btn, _mode_short_btn.button_pressed)
	DangoTheme.style_button(_mode_full_btn, _mode_full_btn.button_pressed)
	if _mode_full_btn.disabled:
		DangoTheme.style_button(_mode_full_btn, false)


# ===========================================================================
# Ascension (0-10) — mockup: stepper + 4 stat cells (ENEMY HP/ENEMY DMG/BOSS HP/WEAKEN)
# ===========================================================================

func _build_ascension_section(parent: Node) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 11)
	parent.add_child(section)
	_add_field_label("ASCENSION", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)

	var minus_btn := _build_step_button("−")
	minus_btn.pressed.connect(func() -> void:
		_ascension = max(0, _ascension - 1)
		_refresh_ascension())
	row.add_child(minus_btn)

	_ascension_value_label = Label.new()
	_ascension_value_label.custom_minimum_size = Vector2(0, 50)
	_ascension_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ascension_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ascension_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ascension_value_label.add_theme_stylebox_override("normal",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(-1, -1)))
	_ascension_value_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_ascension_value_label.add_theme_font_size_override("font_size", 28)
	_ascension_value_label.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	row.add_child(_ascension_value_label)

	var plus_btn := _build_step_button("+")
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
		k_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		cell_col.add_child(k_lbl)
		var v_lbl := Label.new()
		v_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		v_lbl.add_theme_font_size_override("font_size", 18)
		v_lbl.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
		cell_col.add_child(v_lbl)
		stats_row.add_child(cell)
		# k_lbl stashed as metadata on v_lbl so _refresh_ascension() can address both by index.
		v_lbl.set_meta("key_label", k_lbl)
		_ascension_stat_labels.append(v_lbl)

	if _ascension_ceiling() == 0:
		var hint := Label.new()
		hint.text = "Win a run to unlock Ascension 1."
		hint.add_theme_font_override("font", DangoTheme.FONT_UI_SEMI)
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		section.add_child(hint)

	_refresh_ascension()


func _build_step_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(50, 50)
	DangoTheme.style_button(btn, false)
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", 22)
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
	_refresh_begin_subtitle()


# ===========================================================================
# Nav tiles — mockup: 3x2 grid, 452 wide @ bottom 46, right 84, tile h 66
# ===========================================================================

func _build_nav_tiles() -> void:
	var grid := GridContainer.new()
	grid.name = "NavTiles"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	grid.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Exact, not estimated: 2 rows x fixed tile height (66) + 1 fixed v_separation (9) below.
	# `.position` on a point-anchored Control sets the TOP-LEFT corner's offset regardless of
	# which corner preset was used, so the bottom margin has to be baked into position.y here
	# rather than expressed as an "offset from the bottom" directly.
	grid.position = Vector2(-84 - 452, -46 - (66 * 2 + 9))
	grid.custom_minimum_size = Vector2(452, 66 * 2 + 9)
	add_child(grid)

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
	_nav_tiles["vault"] = _add_nav_tile(grid, "vault", "THE VAULT",
		"%d / %d" % [MetaState.vault.size(), MetaState.VAULT_MAX],
		DangoTheme.SHIELD_BLUE, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/vault/Vault.tscn"))
	_nav_tiles["guides"] = _add_nav_tile(grid, "guides", "SAMPLE TEAMS",
		"%d COMPS" % ContentDB.GUIDES.size(),
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/guides/Guides.tscn"))
	_nav_tiles["codex"] = _add_nav_tile(grid, "codex", "CODEX", "10 TABS",
		DangoTheme.CREAM_RAISED, true, "",
		func() -> void: get_tree().change_scene_to_file("res://scenes/codex/Codex.tscn"))
	_nav_tiles["collection"] = _add_nav_tile(grid, "collection", "COLLECTION", "—",
		DangoTheme.CREAM_RAISED, false,
		"Not built yet: there is no Collection system anywhere in this port yet (no data, no "
		+ "screen) — the mockup's tile is a placeholder for a feature that does not exist.",
		Callable())


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
	tile.custom_minimum_size = Vector2(144, 66)
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
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(content)

	var label_lbl := Label.new()
	label_lbl.text = label_text
	label_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	label_lbl.add_theme_font_size_override("font_size", 12)
	label_lbl.add_theme_color_override("font_color",
		DangoTheme.INFO_TEXT_ON_WELL if enabled else DangoTheme.TEXT_DIM)
	content.add_child(label_lbl)

	var value_lbl := Label.new()
	value_lbl.text = value_text
	value_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	value_lbl.add_theme_font_size_override("font_size", 17)
	value_lbl.add_theme_color_override("font_color", value_color if enabled else DangoTheme.TEXT_DIM)
	content.add_child(value_lbl)

	if enabled and on_press.is_valid():
		tile.pressed.connect(on_press)
	parent.add_child(tile)
	return tile


# ===========================================================================
# Team row — read-only lineup + EDIT TEAM link. Mockup box: 1244 wide @ bottom 46,
# left 84 · team card 220, art 124.
# ===========================================================================

## Header row (~34) + its top margin (12) + the card itself. The card's height is pinned to
## `_TEAM_CARD_HEIGHT` in `_build_team_card()` rather than left content-driven, specifically so
## this position math stays exact instead of an estimate that can drift out of sync with the
## card's real rendered height.
const _TEAM_CARD_HEIGHT := 236

func _build_team_row() -> void:
	var wrap := Control.new()
	wrap.name = "TeamRow"
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wrap.position = Vector2(84, -46 - (34 + 12 + _TEAM_CARD_HEIGHT))
	wrap.custom_minimum_size = Vector2(1244, 34 + 12 + _TEAM_CARD_HEIGHT)
	add_child(wrap)

	var vbox := VBoxContainer.new()
	wrap.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "YOUR TEAM"
	eyebrow.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	header.add_child(eyebrow)

	var edit_btn := Button.new()
	edit_btn.text = "EDIT TEAM →"
	edit_btn.custom_minimum_size = Vector2(0, 26)
	DangoTheme.style_button(edit_btn, false, false, DangoTheme.CREAM_HI)
	edit_btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	edit_btn.add_theme_font_size_override("font_size", 13)
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
	card.custom_minimum_size = Vector2(220, _TEAM_CARD_HEIGHT)
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 15, 4, 6.0))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var header := PanelContainer.new()
	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = accent
	header_sb.border_color = Color.BLACK
	header_sb.set_border_width(SIDE_BOTTOM, 3)
	header_sb.content_margin_left = 11.0
	header_sb.content_margin_right = 11.0
	header_sb.content_margin_top = 6.0
	header_sb.content_margin_bottom = 6.0
	header.add_theme_stylebox_override("panel", header_sb)
	col.add_child(header)

	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var name_lbl := Label.new()
	name_lbl.text = String(hero_def.get("n", hero_key))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", DangoTheme.INK)
	header_row.add_child(name_lbl)
	var cls_lbl := Label.new()
	cls_lbl.text = cls.to_upper()
	cls_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	cls_lbl.add_theme_font_size_override("font_size", 13)
	cls_lbl.add_theme_color_override("font_color", DangoTheme.INK)
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
	var portrait_path := "res://assets/portraits/%s.png" % cls
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	body_col.add_child(portrait)

	var stat_row := HBoxContainer.new()
	body_col.add_child(stat_row)
	var tier_lbl := Label.new()
	tier_lbl.text = "TIER %d" % int(hero_def.get("tier", 1))
	tier_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	tier_lbl.add_theme_font_size_override("font_size", 13)
	tier_lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
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

func _build_utility_corner() -> void:
	var row := HBoxContainer.new()
	row.name = "UtilityCorner"
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	row.position = Vector2(-24 - 40 - 8 - 40, 24)
	add_child(row)

	var how_to_play := Button.new()
	how_to_play.name = "HowToPlayButton"
	how_to_play.text = "?"
	how_to_play.tooltip_text = "How to play"
	how_to_play.custom_minimum_size = Vector2(40, 40)
	DangoTheme.style_button(how_to_play, false)
	how_to_play.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn"))
	row.add_child(how_to_play)

	var settings_btn := Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "⚙"
	settings_btn.tooltip_text = "Settings"
	settings_btn.custom_minimum_size = Vector2(40, 40)
	DangoTheme.style_button(settings_btn, false)
	settings_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/settings/Settings.tscn"))
	row.add_child(settings_btn)


# ===========================================================================
# Shared helpers
# ===========================================================================

func _make_pill(text: String, bg: Color, ink: Color, font_size: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(bg, 9, 4, Vector2(15, 8)))
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", ink)
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
