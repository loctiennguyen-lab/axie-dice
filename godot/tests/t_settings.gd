extends Node
## The settings screen, and the one rule that matters on it: every control does something.
##
## A settings screen is the easiest place in a game to ship a lie. A slider that moves and
## changes no volume, a "reduce flashing" box that flashes anyway, an ABANDON RUN that leaves
## the save on disk — all of them look identical to working ones in a screenshot, and all of
## them are found by the player rather than by us. So each check below drives the control and
## then looks at what it was supposed to change.

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
var _guard := SaveGuard.new()

const EXPECTED_TESTS: Array[String] = [
	"test_the_volume_sliders_move_the_real_audio_buses",
	"test_reduce_flashing_actually_suppresses_the_effects_that_flash",
	"test_abandon_run_is_hidden_when_there_is_no_run_to_abandon",
	"test_abandon_run_needs_a_confirmation_and_then_deletes_the_save",
	"test_settings_survive_a_reload",
]


func _ready() -> void:
	print("=== t_settings: start ===")
	_guard.capture()
	await get_tree().process_frame

	await test_the_volume_sliders_move_the_real_audio_buses()
	await test_reduce_flashing_actually_suppresses_the_effects_that_flash()
	await test_abandon_run_is_hidden_when_there_is_no_run_to_abandon()
	await test_abandon_run_needs_a_confirmation_and_then_deletes_the_save()
	await test_settings_survive_a_reload()

	for test_name in EXPECTED_TESTS:
		if not _completed.has(test_name):
			_failures.append("test '%s' did not run to completion" % test_name)

	_guard.restore()
	print("=== t_settings: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_settings: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_settings: FAIL — %s" % f)
	get_tree().quit(1)


func test_the_volume_sliders_move_the_real_audio_buses() -> void:
	var view := await _open()
	var slider := _find(view, HSlider, "MusicSlider") as HSlider
	_assert(slider != null, "there is no music slider on the settings screen")
	if slider == null:
		_done("test_the_volume_sliders_move_the_real_audio_buses")
		return

	slider.value = 0.25
	await get_tree().process_frame
	_assert(is_equal_approx(MetaState.audio_music_volume, 0.25),
		"moving the music slider left MetaState at %f" % MetaState.audio_music_volume)

	# And the BUS, not just the number: the setting is only real if something hears it.
	var bus := AudioServer.get_bus_index("Music")
	_assert(bus != -1, "the Music bus does not exist after the settings screen touched it")
	if bus != -1:
		var quiet := AudioServer.get_bus_volume_db(bus)
		slider.value = 1.0
		await get_tree().process_frame
		var loud := AudioServer.get_bus_volume_db(bus)
		_assert(loud > quiet,
			"the Music bus reads %f dB at 100%% and %f dB at 25%% — the slider is not reaching "
			% [loud, quiet] + "the audio server")
	view.queue_free()
	await get_tree().process_frame
	_done("test_the_volume_sliders_move_the_real_audio_buses")


## The box is only worth having if the effects it names actually stop. `flashes_suppressed()`
## is the single gate both the screen shake and the resonance flash read.
func test_reduce_flashing_actually_suppresses_the_effects_that_flash() -> void:
	var was_test_flag := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	MetaState.reduce_flash = false
	_assert(not CombatView.flashes_suppressed(),
		"effects report themselves suppressed with the setting off and no test flag set")

	var view := await _open()
	var box := _find(view, CheckBox, "ReduceCheck") as CheckBox
	_assert(box != null, "there is no reduce-flashing checkbox on the settings screen")
	if box != null:
		box.button_pressed = true
		await get_tree().process_frame
		_assert(MetaState.reduce_flash, "ticking the box did not set MetaState.reduce_flash")
		_assert(CombatView.flashes_suppressed(),
			"reduce_flash is on and the effects still report themselves live — the setting is "
			+ "stored and ignored, which is the worst of both")
	view.queue_free()
	await get_tree().process_frame
	MetaState.reduce_flash = false
	CombatView.disable_juice_for_tests = was_test_flag
	_done("test_reduce_flashing_actually_suppresses_the_effects_that_flash")


func test_abandon_run_is_hidden_when_there_is_no_run_to_abandon() -> void:
	RunState.clear_saved_run()
	var view := await _open()
	_assert(_find_button(view, "ABANDON RUN") == null,
		"the screen offers to abandon a run when there is no saved run — a question the player "
		+ "should never be asked")
	_assert(_all_text(view).contains("No run in progress"),
		"with no saved run the screen says nothing about it; an empty section reads as a bug")
	view.queue_free()
	await get_tree().process_frame
	_done("test_abandon_run_is_hidden_when_there_is_no_run_to_abandon")


func test_abandon_run_needs_a_confirmation_and_then_deletes_the_save() -> void:
	RunState.start_new_run(4242, ["plant1", "beast1", "aqua1", "reptile1", "bird1"],
		"short", 0, false)
	RunState.save_run({})
	_assert(RunState.has_saved_run(), "test setup failed to produce a saved run")

	var view := await _open()
	var btn := _find_button(view, "ABANDON RUN")
	_assert(btn != null, "there is a saved run and no way to abandon it")
	if btn == null:
		view.queue_free()
		_done("test_abandon_run_needs_a_confirmation_and_then_deletes_the_save")
		return

	_assert(btn.disabled,
		"ABANDON RUN is live before the player has confirmed anything — this is the only "
		+ "control in the game that destroys a save")
	# BY NAME, not "the first CheckBox": the first one on this screen is Mute, and an earlier
	# draft of this test ticked that instead and then reported the confirmation as broken.
	var confirm := _find(view, CheckBox, "ConfirmAbandonCheck") as CheckBox
	_assert(confirm != null, "there is no confirmation control next to ABANDON RUN")
	if confirm != null:
		confirm.button_pressed = true
		await get_tree().process_frame
		_assert(not btn.disabled, "confirming did not enable ABANDON RUN")
		btn.pressed.emit()
		await get_tree().process_frame
		_assert(not RunState.has_saved_run(),
			"ABANDON RUN was pressed and the save is still on disk")
		_assert(_all_text(view).contains("deleted"),
			"the save was deleted and the screen said nothing")
	view.queue_free()
	await get_tree().process_frame
	_done("test_abandon_run_needs_a_confirmation_and_then_deletes_the_save")


## Settings that do not persist are settings the player sets again every launch.
func test_settings_survive_a_reload() -> void:
	MetaState.audio_sfx_volume = 0.4
	MetaState.reduce_flash = true
	MetaState.save_to_disk()
	MetaState.audio_sfx_volume = 1.0
	MetaState.reduce_flash = false
	MetaState.load_from_disk()
	_assert(is_equal_approx(MetaState.audio_sfx_volume, 0.4),
		"sfx volume came back as %f after a reload" % MetaState.audio_sfx_volume)
	_assert(MetaState.reduce_flash, "reduce_flash did not survive a reload")
	MetaState.reduce_flash = false
	_done("test_settings_survive_a_reload")


# ---------------------------------------------------------------------------

func _open() -> Node:
	var view: Node = (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	# Deferred: _ready() runs while the root is still setting up children, and a plain
	# add_child() there fails with "Parent node is busy setting up children".
	get_tree().root.add_child.call_deferred(view)
	await get_tree().process_frame
	await get_tree().process_frame
	return view


## First node of `type` whose name starts with `name_prefix` ("" matches the first of the type).
func _find(root: Node, type, name_prefix: String) -> Node:
	for node in _descendants(root):
		if not is_instance_of(node, type):
			continue
		if name_prefix.is_empty() or String(node.name).begins_with(name_prefix):
			return node
	return null


func _find_button(root: Node, label: String) -> Button:
	for node in _descendants(root):
		var btn := node as Button
		if btn != null and btn.text == label:
			return btn
	return null


func _all_text(root: Node) -> String:
	var out := ""
	for node in _descendants(root):
		var lbl := node as Label
		if lbl != null and lbl.visible:
			out += lbl.text + "\n"
	return out


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
