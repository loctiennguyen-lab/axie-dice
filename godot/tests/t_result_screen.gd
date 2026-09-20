extends Node
## The end-of-run screen, and the three different things its RANKED box has to say.
##
## This screen is where a player learns what their run was worth, so every number on it is one
## they may screenshot and argue about. Two things it did wrong until now, both invisible to a
## passing test:
##   * It told the player "Short (12 waves)" on a map that is 18 rows and branches. Same stale
##     number the Codex had to correct — a wrong constant copied from the JS build outlives
##     every individual fix unless something checks it.
##   * It showed no run statistics at all, because the run never totalled them.
##
## And the RANKED box must never be a button that does nothing: when a run cannot be submitted
## the REASON goes on screen. There are exactly three states and this gate pins all three.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _ready() -> void:
	print("=== t_result_screen: start ===")
	_guard.capture()
	await get_tree().process_frame

	await test_a_real_runs_statistics_reach_the_screen()
	await test_an_unranked_run_says_why_it_cannot_be_scored()
	await test_a_ranked_run_can_export_the_record_the_verifier_reads()
	await test_an_incomplete_record_is_refused_before_it_is_offered()
	await test_the_screen_never_prints_a_null()

	_guard.restore()
	print("=== t_result_screen: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_result_screen: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_result_screen: FAIL — %s" % f)
	get_tree().quit(1)


## UPDATED 2026-09-20 for the v2 Result screen (docs/design-handoff-v2 §06/§09). v1 showed
## these five numbers as prose lines ("Damage dealt: 137", ...); v2 replaces that with a
## six-tile stat ribbon (RunStatsAccumulator.snapshot()) whose values render as bare numbers
## next to a separate caption Label, so a single "Damage dealt: 137" string no longer exists
## anywhere on screen. The RULE under test has not moved — a real run's statistics must reach
## the screen — only the format has, so each check below now looks for the tile's VALUE text
## instead of the old combined sentence. "taken" is dropped outright: v2's six tiles (§09) are
## nodes_cleared/turns_taken/damage_dealt/kills/biggest_hit/axies_lost, and "damage taken" is
## not one of them — this is a deliberate scope match to the spec, not an oversight.
## `dmg_dealt_clamped` is what damage_dealt actually reads (see RunStatsAccumulator.gd); it is
## seeded here alongside the legacy `dmg` key so the test still drives a real value through.
func test_a_real_runs_statistics_reach_the_screen() -> void:
	var view := await _build_result(true, {"dmg": 137, "dmg_dealt_clamped": 137, "taken": 44,
		"turns": 21, "kills": 9, "max_hit": 26})
	var text := _all_text(view)
	for pair in [["137", "damage dealt"], ["21", "turns taken"], ["9", "kills"],
			["26", "biggest hit"]]:
		_assert(text.contains(String(pair[0])),
			"the end screen does not show %s — expected the value '%s' somewhere on the "
			% [pair[1], pair[0]] + "stat ribbon")
	# The stale wave count, pinned so it cannot come back a fourth time.
	_assert(not text.contains("waves"),
		"the end screen still describes the map in 'waves'; this map is a branching graph of "
		+ "rows, and the wave count it used to print was wrong for both modes")
	# UPDATED 2026-09-20: v1 printed "Mode: Short (18 rows)" as its own prose line; v2's
	# NODES CLEARED tile carries the same row-count information as its denominator
	# ("<power_level> / 18") instead of a separate sentence — same rule (read the row count
	# from RunMapGenerator, never hardcode it), different tile.
	_assert(text.contains("/ 18"),
		"the end screen's NODES CLEARED tile should show the row count from RunMapGenerator "
		+ "as its denominator; full screen text was: %s" % text.substr(0, 400))
	view.queue_free()
	await get_tree().process_frame


func test_an_unranked_run_says_why_it_cannot_be_scored() -> void:
	var view := await _build_result(false, {})
	var text := _all_text(view)
	_assert(text.contains("not Ranked"),
		"an unranked run does not say so on the end screen")
	_assert(_find_button(view, "SAVE RUN RECORD") == null,
		"an unranked run offers to export a record that no verifier would accept")
	view.queue_free()
	await get_tree().process_frame


func test_a_ranked_run_can_export_the_record_the_verifier_reads() -> void:
	var view := await _build_result(true, {})
	var btn := _find_button(view, "SAVE RUN RECORD")
	_assert(btn != null, "a ranked run with a complete record offers nothing to do with it")
	if btn == null:
		view.queue_free()
		return
	_assert(not btn.disabled, "the export button is disabled on a run that can be exported")

	btn.pressed.emit()
	await get_tree().process_frame
	var text := _all_text(view)
	_assert(text.contains("Saved to"),
		"pressing the export button reported nothing; a control that does something has to say "
		+ "what it did")
	_assert(btn.disabled,
		"the export button stayed live after writing the record, so a second press would write "
		+ "a second copy of the same run")

	# The file must be real, and must be the shape the referee reads — not merely written.
	var saved_path := _line_containing(view, "Saved to").replace("Saved to ", "").strip_edges()
	var f := FileAccess.open(saved_path, FileAccess.READ)
	_assert(f != null, "the screen says it saved to '%s', and nothing is there" % saved_path)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		_assert(parsed is Dictionary, "the exported record is not JSON")
		if parsed is Dictionary:
			var restored := ActionLog.from_data(parsed as Dictionary)
			_assert(int(restored.header.get("seed", -1)) == RunState.run_seed,
				"the exported record carries seed %s, not this run's %d"
				% [str(restored.header.get("seed", "?")), RunState.run_seed])
			_assert(bool(restored.header.get("ranked", false)),
				"the exported record does not declare itself ranked, so the referee would "
				+ "refuse it")
		DirAccess.remove_absolute(saved_path)
	view.queue_free()
	await get_tree().process_frame


func test_an_incomplete_record_is_refused_before_it_is_offered() -> void:
	var view := await _build_result(true, {}, true)
	var text := _all_text(view)
	_assert(text.contains("incomplete"),
		"a run whose record has a hole in it does not say so")
	_assert(_find_button(view, "SAVE RUN RECORD") == null,
		"a run with an incomplete record still offers to export it — the referee refuses that "
		+ "file (RunVerifier.ERR_INCOMPLETE), so offering it sends the player to be told no")
	view.queue_free()
	await get_tree().process_frame


## The JS build's UI rules (tools/verify.mjs) forbid these three strings on any screen, and
## GDScript's str(null) produces the literal "<NULL>" — not an empty string — which this
## project has shipped to a screen before.
func test_the_screen_never_prints_a_null() -> void:
	var view := await _build_result(true, {"dmg": 5, "taken": 1, "turns": 2, "kills": 1,
		"max_hit": 5})
	var text := _all_text(view)
	for bad in ["<NULL>", "NaN", "undefined", "null"]:
		_assert(not text.contains(bad),
			"the end screen prints '%s' somewhere: %s" % [bad, text.substr(0, 300)])
	view.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------

## Stages a finished run and instantiates the real Result.tscn against it.
func _build_result(ranked: bool, stats: Dictionary, hole_in_log: bool = false) -> Node:
	RunState.start_new_run(777001, TEAM, "short", 0, ranked)
	RunState.power_level = 9
	RunState.shards_this_run = 87
	if not stats.is_empty():
		RunState.run_stats = stats.duplicate(true)
	if hole_in_log:
		RunState.action_log.rejected.append("a deliberate hole, for this gate")
	RunState.set_phase(RunState.RunPhase.WON)

	var view: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	# Deferred: _ready() runs while the root is still setting up children, and a plain
	# add_child() there fails with "Parent node is busy setting up children" — after which the
	# screen builds nothing and every assertion below would be reading an empty tree.
	get_tree().root.add_child.call_deferred(view)
	await get_tree().process_frame
	await get_tree().process_frame
	return view


func _all_text(root: Node) -> String:
	var out := ""
	for node in _descendants(root):
		var lbl := node as Label
		if lbl != null:
			out += lbl.text + "\n"
		var btn := node as Button
		if btn != null:
			out += btn.text + "\n"
	return out


func _line_containing(root: Node, needle: String) -> String:
	for line in _all_text(root).split("\n"):
		if String(line).contains(needle):
			return String(line)
	return ""


func _find_button(root: Node, label: String) -> Button:
	for node in _descendants(root):
		var btn := node as Button
		if btn != null and btn.text == label:
			return btn
	return null


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
