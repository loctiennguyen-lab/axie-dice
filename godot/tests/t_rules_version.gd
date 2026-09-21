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
## Moved 2026-09-20 by the RunStats accumulator (design-handoff-v2 §09, Result screen v2):
## a new autoload (`RunStatsAccumulator.gd`) joined `res://autoload`, and `damage_pipeline.gd`
## gained a second, purely-additive stat key ("dmg_dealt_clamped") written alongside the
## existing "dmg"/"taken"/"turns"/"kills"/"max_hit" — plus matching default-dict/fold-loop
## entries in `combat_engine.gd` and `RunState.gd`. RULES_VERSION was NOT bumped — every new
## line only READS already-computed values (`dealt`, `iv`, `ith`, `hp_before_*`) into a
## Dictionary key that nothing branches on; `dealt`/`iv`/`ith` themselves, and every value
## passed to a relic hook, are byte-for-byte unchanged. `t_run_stats_accumulator.gd` (new)
## exercises the two rules this key exists for directly against DamagePipeline.resolve();
## `t_replay` still verifies a full run to the same score.
##
## Last moved 2026-09-20 by SaveStore: MetaState and RunState now persist through it instead
## of FileAccess, because `user://` does not survive a page reload in a web build. RULES_VERSION
## was NOT bumped — where a save is written cannot change what a run does, and `t_replay` still
## verifies a full run to the same score.
##
## Moved before that, same day, by the end-screen work: `CombatEngine.get_result()` now carries the
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
##
## Moved again, 2026-09-21, by `ContentDB.ARCH` gaining its eleventh entry (`exec`) plus the
## new `ARCH_PRIORITY` / `face_arch()` / `team_arch_score()` / `team_arch_top()` port. NOT
## bumped: ARCH is a tracker/display table. Nothing in `scripts/core` branches on membership in
## it — the only reader outside the UI is `reward_generator._relic_text()`, which falls back to
## "Archetype: <key>" when a relic has no description, and relic SELECTION never filters on it.
## The four new functions have no caller in the engine at all; Team Select reads them to draw
## the "THIS COMP LEANS" bar. Same actions, same run.
##
## BUMPED, 2026-09-21, by `MetaState._hero_def_from_vault()`. This one IS a rules change and
## `ActionLog.RULES_VERSION` moved to `godot-2026-09-21-a` with it. An imported Axie's die was
## stored under src/data.js's short field names (`p/t/v/k/r`) and handed to `ContentDB.heroes`
## untouched, while this port's engine reads the long names it gave the hand-written hero table
## (`part/type/value/keywords/rarity`). Every lookup missed, `Dictionary.get()` returned the
## default, and a vault Axie rolled six 0-value blank faces in real combat. It now rolls the die
## its own six body parts describe — the same actions produce a different run, which is the
## question this file exists to ask.
## Moved, 2026-09-21, by the end_turn() split: `combat_engine.gd` gained `can_end_turn()`,
## `begin_end_turn()`, `step_end_turn_action()` and `finish_end_turn()`, and `end_turn()` is now
## a wrapper that calls the three in order. RULES_VERSION was NOT bumped, and the answer to this
## file's one question was not taken on faith.
##
## The change exists so CombatView can put a gap between enemies and let each one's attack
## animation play; the engine gained no timing, no `await`, and no new state. The same actions
## produce the same run because the split preserves the two things that could have moved:
##   · the ENEMY LOOP body is the old one line for line, including where the party-wipe check
##     sits — only a real `_exec_face()` can end the phase early, and a skipped or stunned
##     enemy returns "keep going" exactly as the old `continue` did;
##   · the stepper takes an INDEX and the caller re-reads `enemies.size()` every pass, so an
##     enemy SUMMONED mid-phase still acts this turn. A list of uids captured up front would
##     have dropped it, and that WOULD have been a rules change — it is the trap this split was
##     most likely to fall into.
##
## `t_enemy_phase_pacing.gd` (new) is the evidence, not the assertion: it replays the pre-split
## begin-block and enemy loop, written out verbatim, against the split path on the same seed and
## compares `to_data()` turn by turn. Its own break-tests are recorded in that file. `t_replay`,
## `t_vertical_slice`, `t_full_run_loop` and `t_combat_roundtrip` all still agree as well.
##
## Moved, 2026-09-21, by the English/punctuation pass before the GitHub push. Six boss `desc`
## strings in `ContentDB.gd` and one sentence each in `reward_generator.gd`,
## `axie_gene_preview.gd` and `run_verifier.gd` lost an em dash; the boss descriptions also
## gained a full stop where the dash used to be. RULES_VERSION was NOT bumped. Every one of
## these is a string the player reads and nothing branches on: `desc` is drawn by the boss
## intro and the codex, `reward_generator`'s is the LEVEL UP card's subtitle (selection reads
## `key`/`tier`, never `desc`), `axie_gene_preview`'s is a Vault warning line, and
## `run_verifier`'s is the text of an already-decided ERR_NOT_RANKED failure. `t_replay` still
## verifies a full run to the same score.
const FINGERPRINT := "9601b57f5049847a63336a0f1f71740c4956cce66eb8fc105360940d439e4c5c"


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
