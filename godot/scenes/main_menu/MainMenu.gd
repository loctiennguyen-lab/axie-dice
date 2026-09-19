class_name MainMenu
extends Control
## MainMenu.tscn root. Reads MetaState/ContentDB for display, commits nothing to RunState
## until "New Run" is pressed (architecture plan §3). Real run-configuration screen —
## team picker (5 slots, T1 heroes, dupes allowed), mode picker, ascension picker, and a
## visible/editable seed — replacing the checklist-step-1 skeleton that hardcoded a fixed
## 5-hero team and always started a "short", Ascension-0 run.
##
## Everything below %ContentRoot (see MainMenu.tscn) is built in code, not hand-laid-out in
## the .tscn — same pattern RunMapController.gd uses for its reward/event/shop overlays —
## because the content is data-driven (6 T1 heroes x 5 slots, 0-10 ascension text pulled
## live from ContentDB.ascension_mods()) rather than a fixed layout a designer hand-placed.
##
## No mockup exists yet for this screen (art-director/ux-designer have not produced one) —
## layout below follows DangoTheme tokens and the project's existing panel/button/chip
## conventions (RunMapController._add_card, CombatView die-slot rendering) so it's visually
## consistent with the rest of the port, but should be treated as a first pass, not a final
## visual spec, until art-director/ux-designer review it.

const T1_HERO_KEYS: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1", "bird1"]
const DEFAULT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const TEAM_SIZE := 5
const ASCENSION_MAX := 10

const _CLASS_LABEL := {
	"plant": "Plant", "beast": "Beast", "aqua": "Aqua",
	"reptile": "Reptile", "bug": "Bug", "bird": "Bird",
}

@onready var _content_root: VBoxContainer = %ContentRoot
@onready var _scroll: ScrollContainer = %Scroll

var _shard_label: Label
var _seed_edit: LineEdit
var _mode_short_btn: Button
var _mode_full_btn: Button
var _ascension_value_label: Label
var _ascension_effect_label: Label
var _new_run_button: Button

# hero_option (OptionButton), name_lbl, meta_lbl, faces_grid — one entry per team slot.
var _hero_cards: Array[Dictionary] = []

## A team handed over by the SAMPLE TEAMS screen, consumed once on the next `_ready()`.
##
## A static var rather than a field on RunState or MetaState: a team the player is CONSIDERING is
## not run state — no run exists yet — and it is not persistent state either. Putting it in either
## place would mean a half-made choice surviving a crash, or a saved run's roster and a menu
## preselection sitting in the same field and eventually being mistaken for one another. Cleared
## as it is read, so coming back to the menu a second time does not silently re-apply it over a
## choice the player has since changed.
static var pending_team: Array[String] = []

var _team_selection: Array[String] = DEFAULT_TEAM.duplicate()
var _mode: String = "short"
var _ascension: int = 0
var _seed_value: int = 0


func _ready() -> void:
	# Onboarding tutorial gate (design/gdd/onboarding-tutorial.md, ported — see
	# MetaState.needs_tutorial()'s own comment for why one check here is enough in this port,
	# unlike the JS build's two gate points). MainMenu.tscn is both the boot scene
	# (project.godot run/main_scene) and the literal destination of every "return to menu"
	# button in this codebase, so this is the single choke point every entry funnels through.
	if MetaState.needs_tutorial():
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn")
		return
	_seed_value = int(randi())
	if not pending_team.is_empty():
		_team_selection = pending_team.duplicate()
		pending_team = []
	# Visual polish backlog P1-5: the default Godot scrollbar was the one stock-engine
	# element left on an otherwise Dango-themed screen. `_rebuild_menu()` only tears down
	# `_content_root`'s children, never `_scroll` itself, so styling it once here holds
	# across purchases/claims too.
	DangoTheme.style_scrollbars(_scroll)
	_build_ui()
	_refresh_shard_label()
	_refresh_mode_buttons()
	_refresh_ascension()
	for i in TEAM_SIZE:
		_refresh_hero_card(i)


func _build_ui() -> void:
	_add_title("AXIE DICE TACTICS")
	_shard_label = _add_body_label("")
	_shard_label.add_theme_color_override("font_color", DangoTheme.PRIMARY)

	_build_seed_section()
	_build_mode_section()
	_build_ascension_section()
	_build_team_section()

	_build_continue_button()
	_build_how_to_play_button()
	_build_codex_button()
	_build_guides_button()
	_build_vault_button()
	_build_pass_section()
	_build_unlocks_section()

	_new_run_button = Button.new()
	_new_run_button.text = "BEGIN RUN"
	_new_run_button.custom_minimum_size = Vector2(0, 56)
	_new_run_button.add_theme_font_size_override("font_size", 22)
	DangoTheme.style_button(_new_run_button, true)
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_content_root.add_child(_new_run_button)


## SAMPLE TEAMS. Sits next to the team picker's own section rather than at the bottom, because
## the moment a player needs it is the moment they are looking at five empty-feeling slots.
func _build_guides_button() -> void:
	var btn := Button.new()
	btn.name = "GuidesButton"
	btn.text = "SAMPLE TEAMS — four compositions that work"
	btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(btn, false)
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/guides/Guides.tscn"))
	_content_root.add_child(btn)


## VAULT — always shown, unlike CONTINUE RUN. An empty vault is the state the screen explains
## (import needs the network layer, step (d)); hiding the door until there is something behind it
## would make the whole Import Axie feature invisible to a new player.
func _build_vault_button() -> void:
	var btn := Button.new()
	btn.name = "VaultButton"
	btn.text = "VAULT — %d/%d imported" % [MetaState.vault.size(), MetaState.VAULT_MAX]
	btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(btn, false)
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/vault/Vault.tscn"))
	_content_root.add_child(btn)


## CONTINUE RUN — only built when there is actually something to continue, so the menu of a
## fresh install is not carrying a dead button. Placed ABOVE BEGIN RUN because a player who
## left mid-run is far more likely to want that than a new one, and because BEGIN RUN
## overwrites the save the moment it is pressed.
func _build_continue_button() -> void:
	if not RunState.has_saved_run():
		return
	var btn := Button.new()
	btn.text = "CONTINUE RUN"
	btn.custom_minimum_size = Vector2(0, 56)
	btn.add_theme_font_size_override("font_size", 22)
	DangoTheme.style_button(btn, true)
	btn.pressed.connect(_on_continue_run_pressed)
	_content_root.add_child(btn)


## The rule book (scenes/codex/Codex.tscn — ten tabs, re-audited against this build's own
## rules rather than copied from the JS one). Sits next to HOW TO PLAY on purpose: the tutorial
## teaches the loop, the Codex answers "what exactly does Burn do", and a player who wants one
## usually wants to know the other exists.
func _build_codex_button() -> void:
	var btn := Button.new()
	btn.name = "CodexButton"
	btn.text = "CODEX"
	btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(btn, false)
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/codex/Codex.tscn"))
	_content_root.add_child(btn)


## Voluntary replay of the onboarding tutorial (task requirement: a menu entry point,
## independent of the first-launch gate above) — always available, unlike CONTINUE RUN, since
## "I want to see that again" is not conditioned on any save-file state.
func _build_how_to_play_button() -> void:
	var btn := Button.new()
	btn.name = "HowToPlayButton"
	btn.text = "HOW TO PLAY"
	btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(btn, false)
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn"))
	_content_root.add_child(btn)


func _on_continue_run_pressed() -> void:
	if not RunState.load_run():
		# load_run() has already warned and changed nothing. Say so on screen rather than doing
		# nothing when clicked, and drop the button so the player is not invited to try again.
		push_warning("MainMenu: saved run could not be loaded")
		RunState.clear_saved_run()
		_shard_label.text = "Saved run could not be read — it has been cleared."
		return
	# A run saved mid-fight resumes INTO that fight; one saved on the map resumes onto it.
	# RunState.resume_combat is what distinguishes them, and CombatView consumes it.
	if not RunState.resume_combat.is_empty():
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")


# ===========================================================================
# Seed
# ===========================================================================

func _build_seed_section() -> void:
	var section := _add_panel_section()
	_add_section_label("SEED", section)
	_add_body_label("This run is fully deterministic: the same seed + team + mode + "
		+ "ascension always plays out identically. Pick your own to share/replay a run.", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)

	_seed_edit = LineEdit.new()
	_seed_edit.text = str(_seed_value)
	# Capped width (visual polish backlog P1-3): a short numeric seed was previously
	# `SIZE_EXPAND_FILL` with no ceiling, stretching the field across the whole content
	# column. SHRINK_BEGIN + a fixed minimum keeps it a sane text-field width instead.
	_seed_edit.custom_minimum_size = Vector2(360, 0)
	_seed_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_seed_edit.add_theme_color_override("font_color", DangoTheme.TEXT)
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	row.add_child(_seed_edit)

	var randomize_btn := Button.new()
	randomize_btn.text = "Randomize"
	DangoTheme.style_button(randomize_btn, false)
	randomize_btn.pressed.connect(_on_randomize_seed_pressed)
	row.add_child(randomize_btn)


func _on_seed_text_changed(new_text: String) -> void:
	# Ignore intermediate/invalid states (e.g. empty field while retyping) — the last
	# valid int stays authoritative until the field holds a valid one again, and
	# _on_new_run_pressed() re-parses the field one more time as a final safety net.
	if new_text.is_valid_int():
		_seed_value = int(new_text)


func _on_randomize_seed_pressed() -> void:
	_seed_value = int(randi())
	_seed_edit.text = str(_seed_value)


# ===========================================================================
# Mode (short/full)
# ===========================================================================

func _build_mode_section() -> void:
	var section := _add_panel_section()
	_add_section_label("MODE", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)

	var group := ButtonGroup.new()
	_mode_short_btn = _build_toggle_button("SHORT — 12 waves", group)
	_mode_short_btn.button_pressed = true
	_mode_short_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_mode = "short"
			_refresh_mode_buttons())
	row.add_child(_mode_short_btn)

	_mode_full_btn = _build_toggle_button("FULL — 20 waves", group)
	_mode_full_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_mode = "full"
			_refresh_mode_buttons())
	row.add_child(_mode_full_btn)

	# DEVIATION FLAGGED (per task instructions): src/data.js defines an `u_full` meta-unlock
	# The gate this comment used to describe as unported is live now: src/client.html:4578
	# `lock = (m === 'full' && !unlocked('u_full'))`. u_full is buyable for 120 Gene Shard in
	# the UNLOCKS section below, and is also the Lunacia Pass level-20 reward.
	if not MetaState.has_unlock("u_full"):
		_mode_full_btn.disabled = true
		# Immediate in-button signal (visual polish backlog P1-6) — previously the ONLY
		# lock indicator was this dim caption below, which requires reading small text to
		# notice at all on a screen where every other button is bright orange. No lock icon
		# exists in the approved web icon set (`godot/assets/icons/web/` — checked, none of
		# battle/boss/chest/event/shard/shop/etc. is a lock; the `part/` subfolder is Axie
		# cosmetic parts, not UI icons), so per task instructions this uses a lock glyph in
		# the button's own text rather than silently borrowing an icon from elsewhere
		# (e.g. Origins Kit). Flagged for art-director: a real lock icon for
		# `assets/icons/web/` would be a straight swap here.
		_mode_full_btn.text = "%s  🔒" % _mode_full_btn.text
		var def: Dictionary = MetaState.unlock_def("u_full")
		var note := _add_body_label("FULL mode is locked. Unlock it for %d Gene Shard below, "
			% int(def.get("cost", 120)) + "or reach Lunacia Pass level 20.", section)
		note.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)


func _build_toggle_button(text: String, group: ButtonGroup) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_group = group
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func _refresh_mode_buttons() -> void:
	_apply_toggle_style(_mode_short_btn)
	_apply_toggle_style(_mode_full_btn)


func _apply_toggle_style(btn: Button) -> void:
	# `toggle_mode=true`: while selected, `button_pressed` stays true and Godot keeps rendering
	# the "pressed" StyleBox (not a momentary click state), so the pressed-state's own
	# colour+geometry shift IS this control's "selected" look — same design language a real
	# press uses elsewhere, not a special case.
	DangoTheme.style_button(btn, btn.button_pressed)


# ===========================================================================
# Ascension (0-10)
# ===========================================================================

func _build_ascension_section() -> void:
	var section := _add_panel_section()
	_add_section_label("ASCENSION", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)

	var minus_btn := _build_step_button("-")
	minus_btn.pressed.connect(func() -> void:
		_ascension = max(0, _ascension - 1)
		_refresh_ascension())
	row.add_child(minus_btn)

	_ascension_value_label = Label.new()
	_ascension_value_label.custom_minimum_size = Vector2(72, 0)
	_ascension_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ascension_value_label.add_theme_font_size_override("font_size", 22)
	_ascension_value_label.add_theme_color_override("font_color", DangoTheme.TEXT)
	row.add_child(_ascension_value_label)

	var plus_btn := _build_step_button("+")
	plus_btn.pressed.connect(func() -> void:
		_ascension = mini(_ascension_ceiling(), _ascension + 1)
		_refresh_ascension())
	row.add_child(plus_btn)

	_ascension_effect_label = _add_body_label("", section)
	if _ascension_ceiling() == 0:
		# JS shows this exact hint at ascMax 0 (client.html:4589).
		var hint := _add_body_label("Win a run to unlock Ascension 1.", section)
		hint.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)


func _build_step_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(44, 44)
	DangoTheme.style_button(btn, false)
	return btn


## Effect text is read straight from ContentDB.ascension_mods() (task instruction: "do not
## re-derive or hardcode the numbers") — never a second copy of the ASCENSION table.
## src/client.html:4584 — the selector offers 0..min(10, META.ascMax). The ladder is climbed by
## WINNING at your current ceiling (RunState.end_run()), so a fresh account can only pick A0
## until its first win.
func _ascension_ceiling() -> int:
	return mini(ASCENSION_MAX, MetaState.asc_max)


func _refresh_ascension() -> void:
	_ascension = clampi(_ascension, 0, _ascension_ceiling())
	_ascension_value_label.text = "A%d" % _ascension
	var m: Dictionary = ContentDB.ascension_mods(_ascension)
	_ascension_effect_label.text = ("Enemy HP x%.2f  ·  Enemy DMG x%.2f  ·  Boss HP x%.2f  ·  "
		+ "Weaken-on-hit: %s") % [
			float(m.get("hp", 1.0)), float(m.get("dmg", 1.0)), float(m.get("boss_hp", 1.0)),
			"YES" if bool(m.get("weaken", false)) else "no",
		]


# ===========================================================================
# Team picker (5 slots, T1 heroes, duplicates allowed)
# ===========================================================================

func _build_team_section() -> void:
	var section := _add_panel_section()
	_add_section_label("CHOOSE YOUR TEAM", section)
	_add_body_label("5 Tier-1 Axies. Every run starts at Tier 1 in this game — duplicates "
		+ "of the same hero are allowed, same as the live game.", section)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(row)

	_hero_cards.clear()
	for i in TEAM_SIZE:
		row.add_child(_build_hero_slot_card(i))


func _build_hero_slot_card(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 10, 10.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var option := OptionButton.new()
	for hero_key in T1_HERO_KEYS:
		var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
		var cls := String(hero_def.get("cls", ""))
		option.add_item("%s (%s)" % [String(hero_def.get("n", hero_key)), _CLASS_LABEL.get(cls, cls)])
	var initial_idx := T1_HERO_KEYS.find(_team_selection[index])
	option.select(max(0, initial_idx))
	option.item_selected.connect(func(idx: int) -> void:
		_team_selection[index] = T1_HERO_KEYS[idx]
		_refresh_hero_card(index))
	col.add_child(option)

	var name_lbl := Label.new()
	name_lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	name_lbl.add_theme_font_size_override("font_size", 18)
	col.add_child(name_lbl)

	var meta_lbl := Label.new()
	meta_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	meta_lbl.add_theme_font_size_override("font_size", 14)
	col.add_child(meta_lbl)

	var faces_grid := GridContainer.new()
	faces_grid.columns = 2
	faces_grid.add_theme_constant_override("h_separation", 6)
	faces_grid.add_theme_constant_override("v_separation", 6)
	col.add_child(faces_grid)

	_hero_cards.append({
		"option": option, "name_lbl": name_lbl, "meta_lbl": meta_lbl, "faces_grid": faces_grid,
	})
	return panel


func _refresh_hero_card(index: int) -> void:
	var card: Dictionary = _hero_cards[index]
	var hero_key := _team_selection[index]
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))

	(card["name_lbl"] as Label).text = String(hero_def.get("n", hero_key))
	(card["meta_lbl"] as Label).text = "%s  ·  %d HP" % [
		_CLASS_LABEL.get(cls, cls), int(hero_def.get("max_hp", 0)),
	]

	var grid: GridContainer = card["faces_grid"]
	for c in grid.get_children():
		c.queue_free()
	for face in (hero_def.get("die", []) as Array):
		grid.add_child(_build_face_chip(face as Dictionary))


## Text-only face chip (no icon texture) — the die-face icons CombatView uses
## (`_face_icon_for()`) are a combat-screen-only preload set; reusing them here would add
## an asset dependency this screen doesn't need. Color comes straight from
## DangoTheme.die_type_color() so it already matches the combat screen's own face colors.
func _build_face_chip(face: Dictionary) -> PanelContainer:
	var face_type := String(face.get("type", ""))
	var col := DangoTheme.die_type_color(face_type)

	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.9)
	sb.border_color = col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	chip.add_theme_stylebox_override("panel", sb)
	chip.custom_minimum_size = Vector2(96, 0)

	var col_box := VBoxContainer.new()
	col_box.add_theme_constant_override("separation", 1)
	chip.add_child(col_box)

	var part := String(face.get("part", ""))
	var type_lbl := Label.new()
	type_lbl.text = "%s · %s" % [part.to_upper(), face_type.to_upper()]
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", col)
	col_box.add_child(type_lbl)

	var value := int(face.get("value", 0))
	if value > 0:
		var value_lbl := Label.new()
		value_lbl.text = str(value)
		value_lbl.add_theme_font_size_override("font_size", 16)
		value_lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
		col_box.add_child(value_lbl)

	var keywords: Array = face.get("keywords", [])
	if not keywords.is_empty():
		var kw_lbl := Label.new()
		kw_lbl.text = ", ".join(keywords.map(func(k): return String(k)))
		kw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kw_lbl.add_theme_font_size_override("font_size", 9)
		kw_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		col_box.add_child(kw_lbl)

	return chip


# ===========================================================================
# Shared label helpers (keep every section's text styling identical)
# ===========================================================================

func _add_title(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	_content_root.add_child(lbl)
	return lbl


## `parent` defaults to `_content_root` (used by `_add_title()` and anything else living
## outside a section card). Every section-building function below passes its own panel's
## inner VBoxContainer instead, so the label lands inside that section's card rather than
## bare on the black background (visual polish backlog P0-5).
func _add_section_label(text: String, parent: Node = null) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	(parent if parent != null else _content_root).add_child(lbl)
	return lbl


func _add_body_label(text: String, parent: Node = null) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	(parent if parent != null else _content_root).add_child(lbl)
	return lbl


## Wraps one screen section (SEED / MODE / ASCENSION / CHOOSE YOUR TEAM / LUNACIA PASS /
## UNLOCKS) in a themed card instead of leaving its Labels/Buttons directly on the flat
## black background — visual polish backlog P0-5. Same `panel_style()` call the hero-slot
## card already uses (`_build_hero_slot_card()`), just at the section level with the
## slightly more opaque `BG_PANEL` (hero-slot cards nested inside stay `BG_PANEL_SOFT`, so
## the two read as "group card" vs. "item inside the group").
## Returns the VBoxContainer callers should add their own content to.
func _add_panel_section() -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		DangoTheme.panel_style(DangoTheme.BG_PANEL, 2, 8, 16.0))
	_content_root.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	return col


func _refresh_shard_label() -> void:
	_shard_label.text = "Gene Shard: %d" % MetaState.shard_pool


# ===========================================================================
# Lunacia Pass + Unlocks
#
# Deliberately plain. The user's standing direction is that this build needs to WORK now and
# that the whole UI gets a design pass later, so these two sections reuse the menu's existing
# label/button helpers and add no new visual language of their own. They are here so the
# systems are reachable and testable, not to be the final screen.
# ===========================================================================

func _build_pass_section() -> void:
	var section := _add_panel_section()
	var prog: Dictionary = MetaState.bp_progress()
	_add_section_label("LUNACIA PASS", section)
	_add_body_label("Level %d of %d  ·  %d XP earned" % [
		int(prog["level"]), ContentDB.BP_MAX_LEVEL, MetaState.xp], section)
	if int(prog["needed"]) > 0:
		_add_body_label("%d / %d XP to level %d" % [
			int(prog["into_level"]), int(prog["needed"]), int(prog["level"]) + 1], section)

	for entry in MetaState.bp_unclaimed():
		var e: Dictionary = entry
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		section.add_child(row)

		var label := Label.new()
		label.text = "Lv %d — %s" % [int(e.get("lv", 0)), _bp_reward_text(e)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", DangoTheme.TEXT)
		row.add_child(label)

		var claim := Button.new()
		claim.text = "CLAIM"
		claim.custom_minimum_size = Vector2(120, 40)
		DangoTheme.style_button(claim, true)
		var lv := int(e.get("lv", 0))
		claim.pressed.connect(func() -> void: _on_claim_pass(lv))
		row.add_child(claim)

	# Earned but unclaimable, shown rather than hidden: a track with silent holes in it reads
	# as a bug, while a player-facing "coming soon" reads as what it is. (Visual polish
	# backlog P0-3: this used to read "(needs the mutation pool, not in this build)" verbatim
	# on screen — a dev note, not product copy — right next to normal CLAIM rows.)
	for entry in MetaState.bp_blocked():
		var e2: Dictionary = entry
		var blocked := _add_body_label("Lv %d — %s — Coming soon"
			% [int(e2.get("lv", 0)), _bp_reward_text(e2)], section)
		blocked.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)


func _bp_reward_text(e: Dictionary) -> String:
	match String(e.get("type", "")):
		"shard":
			return "%d Gene Shard" % int(e.get("value", 0))
		"unlock":
			var def: Dictionary = MetaState.unlock_def(String(e.get("value", "")))
			return "Unlock: %s" % String(def.get("n", e.get("value", "")))
		"perk":
			return String(e.get("note", e.get("value", "")))
		"face":
			return "Gene: %s" % String(e.get("value", ""))
		_:
			return String(e.get("value", ""))


func _on_claim_pass(level: int) -> void:
	var err := MetaState.claim_bp_reward(level)
	if err != "":
		push_warning("MainMenu: claim of pass level %d refused — %s" % [level, err])
	_rebuild_menu()


func _build_unlocks_section() -> void:
	var section := _add_panel_section()
	_add_section_label("UNLOCKS", section)
	for u in ContentDB.UNLOCKS:
		var def: Dictionary = u
		var id := String(def.get("id", ""))
		var owned := MetaState.has_unlock(id)
		var cost := int(def.get("cost", 0))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		section.add_child(row)

		var label := Label.new()
		label.text = "%s — %s" % [String(def.get("n", id)), String(def.get("d", ""))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color",
			DangoTheme.TEXT_DIM if owned else DangoTheme.TEXT)
		row.add_child(label)

		var btn := Button.new()
		btn.text = "OWNED" if owned else "%d ⬧" % cost
		btn.custom_minimum_size = Vector2(120, 40)
		btn.disabled = owned or MetaState.shard_pool < cost
		DangoTheme.style_button(btn, false, false, DangoTheme.TEXT)
		if not btn.disabled:
			btn.pressed.connect(func() -> void: _on_buy_unlock(id))
		row.add_child(btn)


func _on_buy_unlock(id: String) -> void:
	var err := MetaState.buy_unlock(id)
	if err != "":
		push_warning("MainMenu: unlock '%s' refused — %s" % [id, err])
	_rebuild_menu()


## Rebuilds the whole menu after a purchase or a claim. Blunt, and correct: shards, unlock
## states, the FULL-mode gate and the pass list all move together, and repainting one of them
## in place is how they drift apart.
func _rebuild_menu() -> void:
	for c in _content_root.get_children():
		_content_root.remove_child(c)
		c.queue_free()
	_build_ui()
	_refresh_shard_label()
	_refresh_mode_buttons()
	_refresh_ascension()
	for i in _team_selection.size():
		_refresh_hero_card(i)


# ===========================================================================
# Begin run
# ===========================================================================

func _on_new_run_pressed() -> void:
	# Final safety-net re-parse in case the LineEdit is mid-edit with a valid value that
	# text_changed already applied but the field lost focus without triggering another
	# signal — belt-and-suspenders, _on_seed_text_changed already covers the common path.
	if _seed_edit.text.is_valid_int():
		_seed_value = int(_seed_edit.text)
	var team: Array[String] = _team_selection.duplicate()
	RunState.start_new_run(_seed_value, team, _mode, _ascension, false)
	get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")
