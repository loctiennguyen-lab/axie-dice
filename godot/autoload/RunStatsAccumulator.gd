extends Node
## Run-level accumulator for the Result screen's six stat tiles
## (docs/design-handoff-v2 §09 — RunStats). See that file's own quoted spec for the field
## table and the two rules ("damage counts what actually lands"; "biggest_hit excludes
## damage-over-time and Thorns").
##
## MEASURED AGAINST THE PORT BEFORE THIS FILE EXISTED (worth recording, because §09 claims the
## six tiles "have no source in the port" and that is only two-thirds true):
##   - turns_taken / kills / biggest_hit already had a correct, working source:
##     RunState.run_stats["turns"/"kills"/"max_hit"], folded in per-combat from
##     CombatEngine.stat since 2026-09-19. Nothing needed to change for these three.
##   - damage_dealt had a source ("dmg") that was WRONG against rule 1 twice over: unclamped
##     (an overkill of 40 into a 6 HP enemy scored 40) and blind to poison/thorns (both paths
##     call DamagePipeline.resolve() with src == null, which "dmg"'s own gate silently
##     dropped). Fixed by ADDING a second, purely-additive key, "dmg_dealt_clamped" — see
##     damage_pipeline.gd's write sites — rather than changing "dmg" itself, because `dealt`/
##     `iv` (the values "dmg" and dmg_dealt_clamped both derive from) also feed relic hooks
##     (e.g. an on_hit "dealt >= 4" check), and changing what THOSE carry would change
##     gameplay, not just a stat display.
##   - waves_cleared / axies_lost were genuinely missing, exactly as §09 says.
##
## waves_cleared -> nodes_cleared. §09 itself grants this: "if a Godot run is tiers of nodes
## rather than a fixed wave count, the tile becomes NODES CLEARED ... and the accumulator
## field is renamed with it." This port's map is an 18/30-row branching graph
## (RunMapGenerator.MODE_CONFIG), not a fixed wave list, so nodes_cleared reuses
## RunState.power_level (already "+1 per node completed, of any type" — see that field's own
## comment) against MODE_CONFIG[mode].total_rows. No new tracking needed for this field.
##
## axies_lost is the one field this file actually tracks: a pure EventBus.unit_died observer,
## deduplicated per persistent roster uid so a relic-revived Axie is not counted twice.
##
## RESET: once, from RunState.reset() (which start_new_run() also calls) — see that function's
## own comment for why one call site covers both a fresh run and a screen/test that just
## finished reading a completed one.
##
## NOT PERSISTED through Save & Quit / Continue Run: axies_lost lives only in memory, so an
## app restart mid-run would under-count deaths that happened before the restart. Left this
## way deliberately for this pass — none of these six numbers feed
## RunState.compute_run_xp() or any ranked-scoring path (verified: that function reads only
## power_level/visited_node_ids/ascension/mode), so the gap is cosmetic, not a fairness one.
## Flagged rather than silently accepted: wiring it into SaveStore is a reasonable follow-up
## if these numbers are ever asked to survive a save/resume.

var axies_lost: int = 0
var _died_uids: Dictionary = {}   # uid -> true; dedup so a revived Axie counts once per run


func _ready() -> void:
	EventBus.unit_died.connect(_on_unit_died)


func reset() -> void:
	axies_lost = 0
	_died_uids.clear()


## Only a ROSTER unit counts. CombatEngine.TOKEN_UID_BASE is the fixed boundary the UID-desync
## fix already relies on elsewhere: persistent roster ids (assigned once in RunState, stable
## for the whole run) are always below it; every in-combat token — summoned allies (Axie Egg)
## and every monster — is always at or above it. A summoned ally dying is not "an Axie lost"
## under the spec's own wording ("party unit"): the party is the 5 roster slots.
func _on_unit_died(uid: int) -> void:
	if uid < CombatEngine.TOKEN_UID_BASE and not _died_uids.has(uid):
		_died_uids[uid] = true
		axies_lost += 1


## Everything the Result screen's six tiles need, assembled in one call so ResultView never
## has to know which fields are tracked here vs. read straight through from RunState.
func snapshot(mode: String) -> Dictionary:
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, RunMapGenerator.MODE_CONFIG["short"])
	var stats: Dictionary = RunState.run_stats
	return {
		"nodes_cleared": RunState.power_level,
		"nodes_total": int(cfg.get("total_rows", 0)),
		"turns_taken": int(stats.get("turns", 0)),
		"damage_dealt": int(stats.get("dmg_dealt_clamped", 0)),
		"kills": int(stats.get("kills", 0)),
		"biggest_hit": int(stats.get("max_hit", 0)),
		"axies_lost": axies_lost,
	}
