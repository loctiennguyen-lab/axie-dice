extends Node
## Plays one run with the bot and writes its action log to disk — the fixture a verifier is
## tested against, and the smoke test for a deployed referee.
##
## USAGE
##   Godot --headless --path godot res://tools/record_sample_run.tscn -- --seed=991237 [--mode=short|full] [--asc=N] \
##       --out=/tmp/run_log.json
##
## Then feed it back:
##   Godot --headless --path godot res://tools/verify_run.tscn -- --log=/tmp/run_log.json
## The score printed by the second command must equal the one printed by this one. That round
## trip IS the anti-cheat, run by hand.


## Cả hai tool này chơi qua MetaState/RunState (autoload ghi vào save thật). SaveGuard chép save
## trước và trả lại sau, để chạy tool không đè progress của người chơi (L1, 12/10). Chạy qua
## godot/tools/with_lock.sh như mọi lần chạy Godot khác.
var _guard := SaveGuard.new()


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	var args := _parse_args(OS.get_cmdline_user_args())
	var seed_value := int(args.get("seed", 991237))
	var out_path := String(args.get("out", "user://sample_run_log.json"))

	var played := RunBot.play_run(seed_value, RunBot.DEFAULT_TEAM, String(args.get("mode", "short")), int(args.get("asc", 0)))
	var log: ActionLog = played["log"]
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		print("record_sample_run: cannot write '%s'" % out_path)
		_guard.restore()
		get_tree().quit(2)
		return
	var bundle := log.to_data()
	bundle["tape"] = played["tape"]   # the verifier needs the epochs as well as the decisions
	f.store_string(JSON.stringify(bundle))
	f.close()

	print("record_sample_run: seed=%d actions=%d score=%d won=%s complete=%s -> %s"
		% [seed_value, log.size(), int(played["score"]), str(played["won"]),
			str(log.is_complete()), out_path])
	_guard.restore()
	get_tree().quit(0)


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
