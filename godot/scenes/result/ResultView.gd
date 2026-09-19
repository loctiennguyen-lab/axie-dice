extends Control
## Result.tscn root. Reads the RunState snapshot BEFORE end_run() is called (architecture
## plan §3.2.4: "đọc RunState snapshot cuối cùng TRƯỚC KHI RunState.end_run() xoá state") —
## RunState.end_run() itself only pushes shards into MetaState and emits a signal, it does
## not clear RunState today, but reading first keeps this file correct even if that changes.
##
## Real end-of-run screen: outcome (visually distinct WON/LOST), progress reached, shards
## earned, relics collected, and the roster's final state — replacing the checklist-step-1
## one-line placeholder. Built in code under %ContentRoot (see Result.tscn), same pattern as
## MainMenu.gd, for the same reason: this content is data-driven per run, not a fixed layout.
##
## STATS NOT SHOWN (flagged per task instructions — "if a stat you want is not exposed by
## RunState, DO NOT add it there... report it as a needed follow-up, omit rather than fake"):
## the JS end screen (src/client.html scEnd(), ~5436-5449) also shows dmg dealt/taken, turns
## played, kills, and biggest single hit, plus run XP / battle-pass level-ups. None of these
## are tracked anywhere reachable from RunState/MetaState today:
##   - dmg/taken/turns/kills/maxHit are per-combat CombatEngine-local counters (if they exist
##     at all — not confirmed) that never get folded into a run-level total anywhere.
##   - Run XP and pass level: WIRED as of 2026-09-18 and shown below — this note used to say
##     there was no XP value to read, which stopped being true when RunState.compute_run_xp()
##     landed. Damage/turns/kills/max-hit are still genuinely untracked at run level.

@onready var _content_root: VBoxContainer = %ContentRoot

const _CLASS_LABEL := {
	"plant": "Plant", "beast": "Beast", "aqua": "Aqua",
	"reptile": "Reptile", "bug": "Bug", "bird": "Bird",
}
const _RARITY_LABEL := ["Common", "Rare", "Epic", "Legendary"]


func _ready() -> void:
	var won := RunState.phase == RunState.RunPhase.WON

	# Snapshot every field this screen needs OUT of RunState before end_run() runs, per the
	# file-header ordering note — even though end_run() doesn't currently clear anything,
	# nothing here should rely on that staying true.
	var snapshot := {
		"won": won,
		"mode": RunState.mode,
		"ascension": RunState.ascension,
		"seed": RunState.run_seed,
		"power_level": RunState.power_level,
		"shards_this_run": RunState.shards_this_run,
		"relic_ids": RunState.owned_relic_ids.duplicate(),
		"roster": RunState.roster.duplicate(true),
		"run_stats": RunState.run_stats.duplicate(true),
		"ranked": RunState.ranked,
		"score": RunState.compute_run_xp(won),
		"action_log": RunState.action_log,
	}

	# end_run() BEFORE the UI, snapshot already taken. The architecture rule is "read the
	# RunState snapshot before end_run()", which the dictionary above satisfies; running it
	# before the build is what lets this screen show the numbers end_run() PRODUCES — the XP it
	# awards, and a vault total that includes this run's shards. Built the other way round, the
	# "total in your vault" line was showing the balance from before the run was banked.
	RunState.end_run(won)   # pushes shards + XP into MetaState (see file header)
	snapshot["xp_gained"] = RunState.last_run_xp
	snapshot["pass_level"] = MetaState.bp_level()
	snapshot["daily_mission_granted"] = RunState.daily_mission_granted

	_build_ui(snapshot)


## Order (UX audit, production/qa/2026-09-19_runloop-ux-backlog.md P1-2): OUTCOME -> RELICS
## COLLECTED -> PROGRESS -> GENE SHARD -> LUNACIA PASS -> PARTY. RELICS COLLECTED — what the
## player actually built THIS run — is promoted ahead of the two meta-progression blocks (Gene
## Shard / Lunacia Pass), which are vault-wide totals that exist on every run and used to read
## first. RUN (mode/ascension/seed) stays bundled with PROGRESS: both are built by the same
## _build_run_summary_section() call and the backlog's own before/after listing did not call out
## splitting them, only reordering the pre-built blocks — colors/fonts untouched, per that file's
## own instruction.
func _build_ui(s: Dictionary) -> void:
	_build_outcome_banner(s["won"])
	_build_relics_section(s["relic_ids"])
	_build_stats_section(s)
	_build_ranked_section(s)
	_build_run_summary_section(s)
	_build_shards_section(s)
	_build_pass_section(s)
	_build_roster_section(s["roster"])

	var menu_btn := Button.new()
	menu_btn.text = "BACK TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(0, 56)
	menu_btn.add_theme_font_size_override("font_size", 20)
	DangoTheme.style_button(menu_btn, true)
	menu_btn.pressed.connect(_on_menu_pressed)
	_content_root.add_child(menu_btn)


# ===========================================================================
# Outcome banner — the visually-distinct WON/LOST headline the task asks for.
# ===========================================================================

func _build_outcome_banner(won: bool) -> void:
	var accent := DangoTheme.SUCCESS if won else DangoTheme.DANGER

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.16)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", sb)
	_content_root.add_child(panel)

	var lbl := Label.new()
	lbl.text = "VICTORY" if won else "DEFEAT"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", accent)
	panel.add_child(lbl)


# ===========================================================================
# Run summary — mode / ascension / seed, and progress reached.
# ===========================================================================

func _build_run_summary_section(s: Dictionary) -> void:
	_add_section_label("RUN")
	# "12 waves"/"20 waves" was wrong here too — the same stale number the Codex had to correct,
	# and it is a LINEAR-run word for a map that branches. Read from the generator's own config
	# so it cannot drift a fourth time.
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(String(s["mode"]),
		RunMapGenerator.MODE_CONFIG["short"])
	_add_body_label("Mode: %s (%d rows)  ·  Ascension: A%d  ·  Seed: %d" % [
		"Full" if String(s["mode"]) == "full" else "Short", int(cfg.get("total_rows", 0)),
		int(s["ascension"]), int(s["seed"]),
	])

	_add_section_label("PROGRESS")
	# UX audit (production/qa/2026-09-19_runloop-ux-backlog.md P1-1) flagged "Power level
	# reached: 7 · Nodes visited: 0" as two numbers that read as contradictory. Traced against
	# RunState: they are NOT two independently-measured stats that can disagree in real play —
	# RunState.after_node() is the ONLY place either one changes, and it advances both together
	# in the same call (power_level += 1; visited_node_ids.append(current_node_id)), every time
	# a node resolves. Their sizes are identical in every real run; the "7 / 0" example traces to
	# tests/qa_guides_capture.gd poking `power_level` directly for screenshot staging without also
	# seeding `visited_node_ids` — a test-fixture artifact, not a state reachable through normal
	# play. Showing both here was printing the same number twice under different names, not
	# clarifying two different measurements — merged into one line instead of just relabeling.
	# (power_level is still the closest RunState equivalent to the JS end screen's "wave reached";
	# this port's RunMap is a branching graph, not a fixed wave list, so there is no single "wave
	# number" to read — see RunState.after_node()'s own comments for why power_level is the
	# path-independent stand-in.)
	var nodes_done := int(s["power_level"])
	_add_body_label("%d node%s completed this run" % [nodes_done, "" if nodes_done == 1 else "s"])


## The five numbers the JS end screen shows and this one could not: damage dealt and taken,
## turns played, kills, and the biggest single hit.
##
## This file used to carry a note saying they were "not tracked anywhere reachable from
## RunState/MetaState". That was true of the RUN and false of the game: CombatEngine had
## counted all five from the beginning and nothing outside a fight ever read them.
## RunState.run_stats folds them in as each fight ends, so these are measured, not estimated.
func _build_stats_section(s: Dictionary) -> void:
	var stats: Dictionary = s.get("run_stats", {})
	_add_section_label("THIS RUN")
	_add_body_label("Damage dealt: %d  ·  Damage taken: %d" % [
		int(stats.get("dmg", 0)), int(stats.get("taken", 0))])
	_add_body_label("Turns played: %d  ·  Enemies defeated: %d  ·  Biggest hit: %d" % [
		int(stats.get("turns", 0)), int(stats.get("kills", 0)), int(stats.get("max_hit", 0))])


## The ranked box (JS scSubmitBox). It says three different things depending on what is
## actually true, and never shows a button that does nothing — the reason a run cannot be
## submitted goes ON SCREEN, which is this project's standing rule for disabled controls.
##
## No leaderboard exists for this build yet: ADR-0004 settles that a headless Godot referee
## scores a submitted run, and that referee is not deployed. Rather than a dead SUBMIT button
## or a fake "submitted!", the honest action available today is to EXPORT the run record —
## the same JSON `godot/tools/verify_run.tscn` verifies, which is what a submission would
## carry. That makes the score checkable by the person who ran it, today, by hand.
func _build_ranked_section(s: Dictionary) -> void:
	_add_section_label("RANKED")
	_add_body_label("Score: %d" % int(s.get("score", 0)))

	if not bool(s.get("ranked", false)):
		_add_body_label("This run was not Ranked, so it has no verifiable score. A Ranked run "
			+ "starts from the same baseline for everyone — no unlocks, no imported Axie.")
		return

	var log: ActionLog = s.get("action_log")
	if log == null or not log.is_complete():
		# An incomplete record is refused by the referee before it is even replayed
		# (RunVerifier.ERR_INCOMPLETE), so saying so here is the same verdict, earlier.
		_add_body_label("This run's record is incomplete, so its score cannot be verified. "
			+ "Nothing to submit.")
		return

	_add_body_label("A leaderboard for this build is not live yet. You can save this run's "
		+ "record — the same file the verifier reads — and check the score yourself.")
	var btn := Button.new()
	btn.text = "SAVE RUN RECORD"
	btn.custom_minimum_size = Vector2(0, 40)
	DangoTheme.style_button(btn, false)
	var status := _add_body_label("")
	status.visible = false
	btn.pressed.connect(func() -> void:
		var path := _save_run_record(log)
		status.text = ("Saved to %s" % path) if path != "" else \
			"Could not write the run record to disk."
		status.visible = true
		btn.disabled = true)
	_content_root.add_child(btn)
	# The status line is created before the button so the closure can capture it; move it back
	# underneath, where a reader expects the result of pressing a button to appear.
	_content_root.move_child(status, btn.get_index() + 1)


## Writes the action log beside the save file. `user://` because it is the one directory a
## packaged build can always write to — the project directory is read-only in an export.
func _save_run_record(log: ActionLog) -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://run_record_%s.json" % stamp
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(log.to_data()))
	f.close()
	return ProjectSettings.globalize_path(path)


# ===========================================================================
# Lunacia Pass
# ===========================================================================

## src/data.js runXp() is the formula; RunState.compute_run_xp() is the port. Shown because a
## progression system the player cannot see the input to is one they cannot reason about.
func _build_pass_section(s: Dictionary) -> void:
	_add_section_label("LUNACIA PASS")
	var prog: Dictionary = MetaState.bp_progress()
	var lbl := _add_body_label("+%d XP this run  ·  level %d of %d  ·  %d XP total" % [
		int(s.get("xp_gained", 0)), int(prog["level"]), ContentDB.BP_MAX_LEVEL, MetaState.xp,
	])
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	lbl.add_theme_font_size_override("font_size", 16)
	var pending: int = MetaState.bp_unclaimed().size()
	if pending > 0:
		_add_body_label("%d pass reward%s waiting on the main menu."
			% [pending, "" if pending == 1 else "s"])


# ===========================================================================
# Shards
# ===========================================================================

func _build_shards_section(s: Dictionary) -> void:
	_add_section_label("GENE SHARD")
	var lbl := _add_body_label("+%d earned this run  ·  %d total in your vault" % [
		int(s["shards_this_run"]), MetaState.shard_pool,
	])
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	lbl.add_theme_font_size_override("font_size", 16)

	# Shown only on the run that actually granted it. The shards are already inside the total
	# above, so printing this line every run would read as a reward the player is not getting —
	# and printing nothing on the day it lands would hide 60 shards appearing from nowhere.
	if bool(s.get("daily_mission_granted", false)):
		var daily := _add_body_label("Daily Mission  +%d  ·  first run of the day (UTC)"
			% ContentDB.DAILY_MISSION_SHARD)
		daily.add_theme_color_override("font_color", DangoTheme.SUCCESS)
		daily.add_theme_font_size_override("font_size", 15)


# ===========================================================================
# Relics collected
# ===========================================================================

func _build_relics_section(relic_ids: Array) -> void:
	_add_section_label("RELICS COLLECTED (%d)" % relic_ids.size())
	if relic_ids.is_empty():
		_add_body_label("None this run.")
		return

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_content_root.add_child(grid)

	for relic_id in relic_ids:
		grid.add_child(_build_relic_chip(String(relic_id)))


func _build_relic_chip(relic_id: String) -> PanelContainer:
	var def = RelicRegistry.get_def(relic_id)
	var display_name := String(def.name) if def != null else relic_id
	var rarity := int(def.rarity) if def != null else 0
	var rarity_name: String = _RARITY_LABEL[rarity] if rarity >= 0 and rarity < _RARITY_LABEL.size() else "?"

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 10.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = rarity_name
	rarity_lbl.add_theme_color_override("font_color", DangoTheme.INFO)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(rarity_lbl)

	return panel


# ===========================================================================
# Roster — final state of the 5 Axies that ran this route.
# ===========================================================================

func _build_roster_section(roster: Array) -> void:
	_add_section_label("YOUR PARTY")
	if roster.is_empty():
		_add_body_label("No roster data.")
		return
	for entry in roster:
		var e: Dictionary = entry
		var hero_key := String(e.get("hero_key", ""))
		var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
		var cls := String(hero_def.get("cls", ""))
		var effective_hp := int(e.get("max_hp", 0)) + int(e.get("bonus_hp", 0))
		_add_body_label("%s  (%s, T%d)  ·  %d Max HP" % [
			String(hero_def.get("n", hero_key)), _CLASS_LABEL.get(cls, cls),
			int(e.get("tier", 1)), effective_hp,
		])


# ===========================================================================
# Shared label helpers (mirrors MainMenu.gd's — kept local rather than a shared util
# class for two call sites; promote to shared/ if a third screen needs the same pattern)
# ===========================================================================

func _add_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	_content_root.add_child(lbl)
	return lbl


func _add_body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_content_root.add_child(lbl)
	return lbl


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
