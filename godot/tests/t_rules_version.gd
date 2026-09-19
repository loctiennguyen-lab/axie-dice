extends Node
## Guards the one constant a human has to remember, by refusing to let them forget it.
##
## `ActionLog.RULES_VERSION` tells a verifier which rules a run was played under. A log written
## under different rules is unreadable, not suspicious, and the verifier answers accordingly —
## but only if the constant actually changed when the rules did. A hand-typed version that
## nobody bumps is worse than none: every old log then claims to be current, and the referee
## replays them against rules they were never played under, calling honest players cheats.
##
## So this gate fingerprints the files that decide outcomes and fails when the fingerprint
## moves. A machine cannot tell a rewritten comment from a rewritten formula, and pretending
## otherwise would be the same false confidence — so the failure message asks the human the one
## question only they can answer, and the answer is cheap either way.

## Everything whose content can change what a replay produces: the rules themselves, and the
## balance table they read. NOT the UI, not the scenes — a screen cannot change an outcome, and
## including them would make this gate cry wolf every time a button moved.
const WATCHED_DIRS: Array[String] = ["res://scripts/core", "res://autoload"]
const WATCHED_FILES: Array[String] = ["res://assets/data/part_faces.json"]

## Recorded when RULES_VERSION was last considered. Update it in the same commit that changes
## anything above — and bump RULES_VERSION too if the change can alter an outcome.
##
## Last moved 2026-09-20 by the end-screen work: `CombatEngine.get_result()` now carries the
## fight's `stat` counters, `RunState.run_stats` totals them, `MetaState.reduce_flash` arrived,
## and two pieces of ContentDB display copy stopped saying "waves". RULES_VERSION was NOT
## bumped — none of it can change what a run does. The counters are written and never read by
## a rule; `reduce_flash` is a visual setting; and the unlock text is display only, keyed by
## `id`. `t_replay` re-verifies a full run after every one of these, and still agrees.
##
## Moved before that, 2026-09-19, by `MetaState.tutorial_seen` + `needs_tutorial()`. RULES_VERSION was
## NOT bumped, and the reason is the whole point of asking: that flag decides whether a player
## is shown the tutorial. It cannot change what a run does, because a ranked run reads
## `MetaState.run_bonuses(true)`, which returns zeroes for everything the meta holds.
const FINGERPRINT := "25369214a2e53dce946aac72ef24c5a3e95da82d2ddd9d612637011af336fcec"


func _ready() -> void:
	var files := _watched_files()
	if files.is_empty():
		print("t_rules_version: FAIL — the watch list matched no files, so this gate is blind")
		get_tree().quit(1)
		return

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for path in files:
		ctx.update(path.to_utf8_buffer())
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			print("t_rules_version: FAIL — cannot read watched file %s" % path)
			get_tree().quit(1)
			return
		ctx.update(f.get_buffer(f.get_length()))
		f.close()
	var digest := ctx.finish().hex_encode()

	if digest == FINGERPRINT:
		print("t_rules_version: PASS — %d rule files unchanged since RULES_VERSION '%s' was set"
			% [files.size(), ActionLog.RULES_VERSION])
		get_tree().quit(0)
		return

	print("t_rules_version: FAIL — the rule files changed since RULES_VERSION '%s' was last set."
		% ActionLog.RULES_VERSION)
	print("  Watched: %d files under %s plus %s"
		% [files.size(), str(WATCHED_DIRS), str(WATCHED_FILES)])
	print("  ASK ONE QUESTION: can this change make the same actions produce a different run?")
	print("    YES -> bump ActionLog.RULES_VERSION (old logs then get an honest 'refresh and")
	print("           replay' instead of being replayed against rules they never ran under).")
	print("    NO  -> leave RULES_VERSION alone (a comment, a rename, a new UI-only branch).")
	print("  EITHER WAY, paste this into t_rules_version.gd's FINGERPRINT:")
	print("    %s" % digest)
	get_tree().quit(1)


## Sorted, so the digest depends on the files' content and not on the order the filesystem
## happened to hand them over.
func _watched_files() -> Array[String]:
	var out: Array[String] = []
	for dir_path in WATCHED_DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for name in dir.get_files():
			# `.uid` files are Godot's own bookkeeping and change on import, not on edit.
			if String(name).ends_with(".gd"):
				out.append("%s/%s" % [dir_path, name])
	for path in WATCHED_FILES:
		if FileAccess.file_exists(path):
			out.append(path)
	out.sort()
	return out
