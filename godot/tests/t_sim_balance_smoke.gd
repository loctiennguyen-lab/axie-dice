extends Node
## Smoke: 2 sim runs, twice, give the same records (determinism) and the sim does not hang.
func _ready() -> void:
	var guard := SaveGuard.new()
	guard.capture()
	var sim = load("res://tools/sim_balance.gd").new()
	var args := {"runs": 1, "seed": 77, "asc": "0", "policies": "greedy,random_legal,expert,expert_legacy", "teams": "mixed_std", "cores": "random"}
	var a: Array = sim.run_batch(args.duplicate())
	var b: Array = sim.run_batch(args.duplicate())
	guard.restore()
	sim.free()
	var ok := a.size() == 4 and b.size() == 4 and var_to_str(a) == var_to_str(b)
	print("t_sim_balance_smoke: ", "PASS" if ok else "FAIL (records differ or wrong count)")
	get_tree().quit(0 if ok else 1)
