extends Node
## Guards the save path, because the way it broke on the web is the way it will break again:
## silently, on the READ side, a day after the player earned the thing they lost.
##
## What can be tested from a desktop run is the contract (round trip, absence, deletion) and
## the WIRING — that MetaState and RunState actually go through SaveStore rather than reaching
## for FileAccess again. The web half is a browser measurement; see save_store.gd's header and
## `godot/tools/probe_web_save.gd`.

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
var _guard := SaveGuard.new()

const PROBE_PATH := "user://t_save_store_probe.json"

const EXPECTED_TESTS: Array[String] = [
	"test_text_survives_a_round_trip",
	"test_a_missing_save_reads_as_empty_not_as_garbage",
	"test_erase_removes_it_everywhere",
	"test_the_two_real_saves_go_through_this_store",
	"test_a_saved_run_round_trips_through_the_store",
]


func _ready() -> void:
	print("=== t_save_store: start ===")
	_guard.capture()
	await get_tree().process_frame

	test_text_survives_a_round_trip()
	test_a_missing_save_reads_as_empty_not_as_garbage()
	test_erase_removes_it_everywhere()
	test_the_two_real_saves_go_through_this_store()
	test_a_saved_run_round_trips_through_the_store()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append("test '%s' did not run to completion" % name)

	SaveStore.erase(PROBE_PATH)
	_guard.restore()
	print("=== t_save_store: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_save_store: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_save_store: FAIL — %s" % f)
	get_tree().quit(1)


func test_text_survives_a_round_trip() -> void:
	# A save is JSON and JSON is full of quotes and backslashes. The web path used to be built
	# by pasting text into a JavaScript string, where the first quote in a player's data ends
	# the string and the rest becomes code — hence get_interface(), and hence this payload.
	var payload := '{"name":"He said \\"hi\\"","path":"C:\\\\Users\\\\x","emoji":"◈","n":-1.5}'
	_assert(SaveStore.write_text(PROBE_PATH, payload), "the store refused a normal save")
	_assert(SaveStore.read_text(PROBE_PATH) == payload,
		"a save came back changed:\n  wrote: %s\n  read:  %s"
		% [payload, SaveStore.read_text(PROBE_PATH)])
	_assert(SaveStore.exists(PROBE_PATH), "a save that was just written reports as missing")
	_done("test_text_survives_a_round_trip")


func test_a_missing_save_reads_as_empty_not_as_garbage() -> void:
	SaveStore.erase(PROBE_PATH)
	_assert(not SaveStore.exists(PROBE_PATH), "an erased save still reports as present")
	_assert(SaveStore.read_text(PROBE_PATH) == "",
		"a missing save read back as '%s' — callers check for empty, so anything else would be "
		% SaveStore.read_text(PROBE_PATH) + "parsed as if it were real data")
	_done("test_a_missing_save_reads_as_empty_not_as_garbage")


func test_erase_removes_it_everywhere() -> void:
	SaveStore.write_text(PROBE_PATH, "{}")
	SaveStore.erase(PROBE_PATH)
	_assert(not FileAccess.file_exists(PROBE_PATH),
		"erase left the file behind; on web the same gap would leave the localStorage copy, "
		+ "and the next launch would offer to continue a run the player abandoned")
	_assert(not SaveStore.exists(PROBE_PATH), "erase left something the store can still find")
	_done("test_erase_removes_it_everywhere")


## The wiring gate. The bug was not in SaveStore — it did not exist. It was that the save code
## used FileAccess directly, which is correct on a desktop and silently lossy on the web. This
## fails if either save path reaches for FileAccess on its own save file again.
func test_the_two_real_saves_go_through_this_store() -> void:
	for spec in [["res://autoload/MetaState.gd", "MetaState"],
			["res://autoload/RunState.gd", "RunState"]]:
		var path := String(spec[0])
		var who := String(spec[1])
		var f := FileAccess.open(path, FileAccess.READ)
		_assert(f != null, "cannot read %s to check how it saves" % path)
		if f == null:
			continue
		var src := f.get_as_text()
		f.close()
		_assert(src.contains("SaveStore."),
			"%s does not use SaveStore at all" % who)
		_assert(not src.contains("FileAccess.open(SAVE_PATH"),
			"%s opens SAVE_PATH with FileAccess directly again. That works on a desktop and "
			% who + "loses the player's progress on the web — the exact regression SaveStore "
			+ "exists to prevent.")
	_done("test_the_two_real_saves_go_through_this_store")


## End to end through the real API, because the contract test above would still pass if
## RunState wrote its save somewhere nothing reads it back from.
func test_a_saved_run_round_trips_through_the_store() -> void:
	RunState.start_new_run(31337, ["plant1", "beast1", "aqua1", "reptile1", "bird1"],
		"short", 0, false)
	RunState.shards_this_run = 41
	RunState.save_run({})
	_assert(RunState.has_saved_run(), "a run was saved and has_saved_run() says no")

	RunState.reset()
	_assert(RunState.load_run(), "the saved run would not load back")
	_assert(RunState.run_seed == 31337,
		"the restored run has seed %d, not the one that was saved" % RunState.run_seed)
	_assert(RunState.shards_this_run == 41,
		"the restored run has %d shards, not the 41 that were saved" % RunState.shards_this_run)

	RunState.clear_saved_run()
	_assert(not RunState.has_saved_run(), "clear_saved_run() left the save behind")
	_done("test_a_saved_run_round_trips_through_the_store")


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
