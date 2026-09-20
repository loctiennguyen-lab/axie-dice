extends Node
## Manual VISUAL QA capture for the SAMPLE TEAMS screen and the Daily Mission line on Result.
## Not part of the automated suite — `t_guides_daily` is the blocking gate.
##
## MUST run non-headless: the dummy rasterizer returns an empty image from `get_texture()` and
## the PNG is written blank, a failure with no other symptom.
##
## Borrows and restores MetaState — `daily_date` is in the player's real save.
##
## Run: /path/to/Godot --path godot res://tests/qa_guides_capture.tscn

var _EVIDENCE_DIR := QaPaths.evidence_dir()

## The RAW save file, not a list of fields.
##
## The first version restored `daily_date` and `shard_pool` by hand — and quietly left the
## player's `runs`, `wins`, `xp` and `best` inflated, because the capture drives a REAL
## `end_run()` and end_run touches all of them. Any hand-written restore list is a list that
## falls behind the thing it is restoring. Copying the file back cannot.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("qa_guides_capture: running headless — the PNGs would be blank. "
			+ "Re-run WITHOUT --headless.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	await get_tree().process_frame
	_save_guard.capture()

	await _shot_scene("res://scenes/guides/Guides.tscn", "guides")

	# The Result screen with the daily line present: clear the stamp so this run's end grants it.
	MetaState.daily_date = ""
	RunState.start_new_run(90210, ["plant1", "plant1", "reptile1", "bug1", "aqua1"],
		"short", 0, false)
	RunState.power_level = 7
	RunState.shards_this_run = 143
	await _shot_scene("res://scenes/result/Result.tscn", "result-daily")

	_save_guard.restore()
	RunState.reset()
	print("qa_guides_capture: done, save file restored byte for byte")
	get_tree().quit(0)


func _shot_scene(path: String, label: String) -> void:
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	for _i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var out := "%s/%s_%s.png" % [_EVIDENCE_DIR, _today(), label]
	get_tree().root.get_texture().get_image().save_png(out)
	print("qa_guides_capture: saved ", out)
	scene.queue_free()
	await get_tree().process_frame



## Today, as `YYYY-MM-DD`, for naming the files this capture writes.
##
## The date used to be typed into the filename by hand. That makes a screenshot LIE the moment
## the capture is re-run: the picture is regenerated, the name still says the day it was first
## written, and anyone reading the folder — or a report linking to it — concludes the evidence is
## stale when it is current. Stamping it at run time means a filename can only ever be right.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
