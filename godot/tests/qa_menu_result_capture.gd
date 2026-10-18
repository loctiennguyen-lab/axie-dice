extends Node
## Manual VISUAL QA capture for MainMenu.tscn (real run-configuration screen) and
## Result.tscn (real end-of-run screen) — NOT part of the automated regression suite, see
## qa_anim_capture.gd's header for why (Visual/Feel evidence is ADVISORY per
## coding-standards.md's Test Evidence table). MUST run non-headless: --headless's dummy
## rasterizer returns no texture from get_texture() (same limitation documented in
## t_stage3d_facing.gd and every other qa_*_capture.gd in this directory).
##
## Drives the real scenes via direct method/property access (OptionButton.select() +
## emitting item_selected, Button.pressed.emit(), RunState field writes) rather than
## simulated mouse input — same white-box approach qa_reward_loop_capture.gd uses for
## RunMapController.
##
## Run: /path/to/Godot --path godot tests/qa_menu_result_capture.tscn
## Do not point this at a terminal/window the user (or another agent) is actively using.

var _EVIDENCE_DIR := QaPaths.evidence_dir()

var _shot_index := 0


## Borrows the player's real save file and puts it back byte for byte. This capture drives real
## run state — and loading `Result.tscn` alone is enough, because `ResultView._ready()` calls
## `RunState.end_run()`, which banks shards and XP into `MetaState`. See `save_guard.gd`.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	# MainMenu._ready() routes straight to Tutorial.tscn while the save has never seen it, so on
	# a fresh machine this capture photographed the tutorial instead of the menu — and, because
	# the scene swap happens inside `add_child()`, printed "Parent node is busy adding/removing
	# children" and produced nothing at all. The save is restored byte for byte by `_guard`.
	MetaState.tutorial_seen = true
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	await _capture_result_screens()

	print("qa_menu_result_capture: done, %d frame(s) written to %s" % [_shot_index, _EVIDENCE_DIR])
	_guard.restore()
	get_tree().quit(0)


func _settle(frames: int = 6) -> void:
	for i in frames:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var img := get_tree().root.get_texture().get_image()
	var path := "%s/%s_menu-result_%s.png" % [_EVIDENCE_DIR, _today(), name]
	img.save_png(path)
	_shot_index += 1
	print("qa_menu_result_capture: saved ", path)


# ===========================================================================
# Result.tscn — both outcomes, so the WON/LOST visual distinction is actually checked.
# ===========================================================================

func _capture_result_screens() -> void:
	await _capture_one_result(true, ["r_bastionplate", "r_ember", "r_chainreact"], "05_result_victory")
	await _capture_one_result(false, [], "06_result_defeat_no_relics")


func _capture_one_result(won: bool, relic_ids: Array[String], shot_name: String) -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
	RunState.start_new_run(777001, team, "short", 4, false)
	RunState.phase = RunState.RunPhase.WON if won else RunState.RunPhase.LOST
	RunState.shards_this_run = 87
	RunState.power_level = 9
	RunState.visited_node_ids = ["n0", "n1", "n2", "n3", "n4", "n5", "n6", "n7", "n8"]
	RunState.owned_relic_ids = relic_ids
	# Give bonus_hp to one roster entry so the party section shows a non-base HP value too.
	if not RunState.roster.is_empty():
		RunState.roster[0]["bonus_hp"] = 6

	var result: Control = load("res://scenes/result/Result.tscn").instantiate()
	add_child(result)
	await _settle()
	_shot(shot_name)

	result.queue_free()
	await _settle()
	RunState.reset()


## Today, as `YYYY-MM-DD`, for naming the files this capture writes.
##
## The date used to be typed into the filename by hand. That makes a screenshot LIE the moment
## the capture is re-run: the picture is regenerated, the name still says the day it was first
## written, and anyone reading the folder — or a report linking to it — concludes the evidence is
## stale when it is current. Stamping it at run time means a filename can only ever be right.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
