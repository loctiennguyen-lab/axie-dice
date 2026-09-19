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

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"

var _shot_index := 0


## Borrows the player's real save file and puts it back byte for byte. This capture drives real
## run state — and loading `Result.tscn` alone is enough, because `ResultView._ready()` calls
## `RunState.end_run()`, which banks shards and XP into `MetaState`. See `save_guard.gd`.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	await _capture_main_menu()
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
# MainMenu.tscn
# ===========================================================================

func _capture_main_menu() -> void:
	var menu: Control = load("res://scenes/main_menu/MainMenu.tscn").instantiate()
	add_child(menu)
	await _settle()
	_shot("01_mainmenu_default")

	# Reconfigure away from defaults to prove every control actually drives state:
	# Full mode, Ascension 7, a re-picked hero on slot 0 (bird1, the class the old
	# hardcoded PLACEHOLDER_TEAM could never reach), and a custom seed.
	menu._mode_full_btn.button_pressed = true
	menu._mode_full_btn.toggled.emit(true)
	for _i in 7:
		menu._ascension = min(menu.ASCENSION_MAX, menu._ascension + 1)
	menu._refresh_ascension()

	var slot0_option: OptionButton = menu._hero_cards[0]["option"]
	var bird_idx: int = menu.T1_HERO_KEYS.find("bird1")
	slot0_option.select(bird_idx)
	slot0_option.item_selected.emit(bird_idx)

	menu._seed_edit.text = "123456789"
	menu._seed_edit.text_changed.emit("123456789")

	await _settle()
	_shot("02_mainmenu_reconfigured")

	# Scroll to the bottom so the team-picker cards + BEGIN RUN button are also captured —
	# %ContentRoot is taller than the 1080px viewport once all 6 sections are built.
	var scroll: ScrollContainer = menu.get_node("Scroll")
	scroll.scroll_vertical = 100000
	await _settle()
	_shot("03_mainmenu_team_and_button")

	menu.queue_free()
	await _settle()


# ===========================================================================
# Result.tscn — both outcomes, so the WON/LOST visual distinction is actually checked.
# ===========================================================================

func _capture_result_screens() -> void:
	await _capture_one_result(true, ["r_bastionplate", "r_ember", "r_chainreact"], "04_result_victory")
	await _capture_one_result(false, [], "05_result_defeat_no_relics")


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
