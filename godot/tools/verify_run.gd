extends Node
## The referee, as a command-line tool. Reads one action log as JSON, replays it through the
## real game rules, and prints the score it computed.
##
## USAGE
##   Godot --headless --path godot res://tools/verify_run.tscn -- --log=/path/to/log.json
##   Godot --headless --path godot res://tools/verify_run.tscn -- --log=- < log.json
##   (optional) --out=/path/to/verdict.json
##
## Exit code 0 means the run verified, 1 means it did not, 2 means the tool could not read its
## input. The verdict is printed on one line prefixed `VERDICT_JSON ` so a caller can find it
## without parsing Godot's own startup output — and written verbatim to `--out` when given.
##
## A SCENE, NOT `--script`. Godot does not load autoloads in `--script` mode, and this tool is
## nothing but a driver for RunState/ContentDB/MetaState, which are autoloads. Written as a
## `--script` first, it failed by reporting that `ContentDB` does not exist, which reads as a
## missing file rather than as the wrong launch mode. See probe_axie_live.tscn for the same
## lesson learned the same way.

const EXIT_OK := 0
const EXIT_REJECTED := 1
const EXIT_INPUT := 2


func _ready() -> void:
	await get_tree().process_frame
	var args := _parse_args(OS.get_cmdline_user_args())
	var log_path := String(args.get("log", ""))
	if log_path.is_empty():
		_emit({"ok": false, "error": "no_input",
			"message": "Pass --log=<path>, or --log=- to read the log on standard input."},
			String(args.get("out", "")), EXIT_INPUT)
		return

	var raw := ""
	if log_path == "-":
		# One log per invocation: read to EOF rather than a line, because a pretty-printed log
		# spans many lines and reading one would silently verify a fragment.
		while true:
			var line := OS.read_string_from_stdin(8_000_000)
			if line.is_empty():
				break
			raw += line
	else:
		var f := FileAccess.open(log_path, FileAccess.READ)
		if f == null:
			_emit({"ok": false, "error": "unreadable_input",
				"message": "Cannot read '%s'." % log_path},
				String(args.get("out", "")), EXIT_INPUT)
			return
		raw = f.get_as_text()
		f.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_emit({"ok": false, "error": "bad_json",
			"message": "The log is not a JSON object."},
			String(args.get("out", "")), EXIT_INPUT)
		return

	var verdict := RunVerifier.verify(ActionLog.from_data(parsed as Dictionary))
	# The full end state is for tests and debugging, not for a caller that only needs a score —
	# and it is large. Dropped here so the verdict stays one readable line.
	verdict.erase("state")
	verdict["rules_version"] = ActionLog.RULES_VERSION
	verdict["content_version"] = String(ContentDB.part_faces.get("engineVersion", ""))
	_emit(verdict, String(args.get("out", "")),
		EXIT_OK if bool(verdict.get("ok", false)) else EXIT_REJECTED)


func _emit(verdict: Dictionary, out_path: String, code: int) -> void:
	var text := JSON.stringify(verdict)
	print("VERDICT_JSON %s" % text)
	if not out_path.is_empty():
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
			f.close()
	get_tree().quit(code)


## `--key=value` pairs from everything after `--` on the command line.
func _parse_args(argv: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for a in argv:
		var arg := String(a)
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq < 0:
			out[body] = true
		else:
			out[body.substr(0, eq)] = body.substr(eq + 1)
	return out
