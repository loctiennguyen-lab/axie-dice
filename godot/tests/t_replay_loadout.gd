extends Node
## A ranked run played with the player's unlocks must replay on a machine that has none: the bonuses
## travel in the log header's `loadout`, the verifier never reads its own MetaState (ADR-RNG F9).

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _digest(state: Dictionary) -> String:
	var d := state.duplicate(true)
	d.erase("action_log")
	return JSON.stringify(d)


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()

	# The player: unlocks that give rerolls, HP and a starting relic.
	MetaState.unlocks.assign(["u_reroll", "u_reroll2", "u_hp", "u_hp2", "u_start"])
	MetaState.perks = {}
	var played := RunBot.play_run(991237, TEAM)
	var log: ActionLog = played["log"]
	var bonuses: Dictionary = (log.header.get("loadout", {}) as Dictionary).get("bonuses", {})
	_check(int(bonuses.get("bonus_reroll", 0)) == 2 and int(bonuses.get("hp_bonus", 0)) == 5,
		"the header loadout carries the bonuses the run really used (got %s)" % str(bonuses))
	# JSON round trip, as a log travels
	var wire := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())) as Dictionary)

	# The referee's machine: nothing unlocked.
	MetaState.unlocks.assign([])
	var verdict := RunVerifier.verify(wire, played["tape"])
	_check(bool(verdict["ok"]), "referee without unlocks accepts the honest run: %s" % str(verdict["message"]))
	if bool(verdict["ok"]):
		_check(int(verdict["score"]) == int(played["score"]), "same score")
		_check(_digest(verdict["state"]) == _digest(played["state"]), "same end state")

	# Negative control: take the bonuses out of the header and the replay must NOT match.
	var stripped := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())) as Dictionary)
	stripped.header["loadout"] = {}
	var v2 := RunVerifier.verify(stripped, played["tape"])
	_check((not bool(v2["ok"])) or _digest(v2["state"]) != _digest(played["state"]),
		"without the loadout the replay differs (the bonuses are what made the match)")

	if _fails.is_empty():
		print("t_replay_loadout: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_replay_loadout: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
