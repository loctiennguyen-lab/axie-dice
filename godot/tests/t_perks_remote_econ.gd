extends Node
## Liam 27/10: perks are NOT applied to a run while the economy is server-owned (remote). Local econ keeps them.
## Ranked never had them. Unlock bonuses (u_reroll...) are unaffected either way.
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	print("=== t_perks_remote_econ: start ===")
	MetaState.perks = {"reroll": 2, "hp4": 1, "relic1": 1, "rrw": 1}
	MetaState.use_remote_econ(null)
	var local := MetaState.run_bonuses(false)
	_check(int(local["bonus_reroll"]) >= 2 and int(local["hp_bonus"]) >= 4, "local econ: perks add reroll and hp")
	_check(int(local["start_relic_max_rarity"]) == 1 and int(local["reward_reroll_max"]) == 2, "local econ: relic1 + rrw perks apply")
	var local_ranked := MetaState.run_bonuses(true)
	_check(int(local_ranked["bonus_reroll"]) < int(local["bonus_reroll"]), "local econ ranked: no perks")

	MetaState.use_remote_econ(RemoteEcon.new())
	var remote := MetaState.run_bonuses(false)
	_check(remote == MetaState.run_bonuses(true), "remote econ: unranked bonuses equal the ranked ones (no perks)")
	_check(int(remote["reward_reroll_max"]) == 1, "remote econ: no perk reward reroll")
	_check(int(remote["start_relic_max_rarity"]) != 1, "remote econ: no perk relic rarity")
	MetaState.use_remote_econ(null)

	print("t_perks_remote_econ: ", "PASS" if _fails == 0 else "FAIL (%d)" % _fails)
	_guard.restore()
	get_tree().quit(0 if _fails == 0 else 1)
