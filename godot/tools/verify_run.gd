extends Node
## The referee, as a command-line tool. Reads one action log as JSON, replays it through the
## real game rules, and prints the score it computed.
##
## USAGE
##   Godot --headless --path godot res://tools/verify_run.tscn -- --in=/path/to/log.json --out=/path/to/result.json
##   Godot --headless --path godot res://tools/verify_run.tscn -- --in=- < log.json  (--log= là tên cũ, vẫn chạy)
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


## Replay chạm RunState/MetaState (autoload ghi vào save thật): SaveGuard chép save trước và trả
## lại ở _emit, trước khi quit. Chạy qua godot/tools/with_lock.sh (L1, 12/10).
var _guard := SaveGuard.new()


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	var args := _parse_args(OS.get_cmdline_user_args())
	# `--in` là tên chính (SR-V); `--log` giữ lại cho lệnh cũ.
	var log_path := String(args.get("in", args.get("log", "")))
	var out_path := String(args.get("out", ""))
	if log_path.is_empty():
		_emit(VerifyCli.run("")["result"].merged({"reason": "no_input"}, true), out_path, EXIT_INPUT)
		return

	var raw := ""
	if log_path == "-":
		# Đọc tới EOF, không đọc một dòng: log pretty-print nhiều dòng.
		while raw.length() <= VerifyCli.MAX_INPUT_BYTES:
			var line := OS.read_string_from_stdin(1_000_000)
			if line.is_empty():
				break
			raw += line
	else:
		var f := FileAccess.open(log_path, FileAccess.READ)
		if f == null:
			_emit(VerifyCli.run("")["result"].merged({"reason": "unreadable_input"}, true), out_path, EXIT_INPUT)
			return
		# Trần đọc: không nạp file khổng lồ vào bộ nhớ.
		raw = f.get_buffer(mini(f.get_length(), VerifyCli.MAX_INPUT_BYTES + 1)).get_string_from_utf8()
		f.close()

	var r := VerifyCli.run(raw)
	_emit(r["result"], out_path, int(r["code"]))


func _emit(verdict: Dictionary, out_path: String, code: int) -> void:
	var text := JSON.stringify(verdict)
	print("VERDICT_JSON %s" % text)
	if not out_path.is_empty():
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
			f.close()
	_guard.restore()
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
