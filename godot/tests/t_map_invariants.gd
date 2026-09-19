extends Node
## Headless invariant gate for RunMapGenerator (architecture plan §7, "t_map.gd: 10.000
## seed, đủ 10 invariant"). For each of 10,000 seeds, builds a graph (alternating
## short/full mode, ascension cycling 0-10 so invariant #10's ascension>=9 branch gets
## real coverage) and runs RunMapGenerator.validate() against all 10 invariants. Also runs
## a small determinism spot-check ("cùng seed -> graph byte-identical", plan §7).
##
## Implemented as a scene (t_map_invariants.tscn) run via `godot --headless --path godot
## tests/t_map_invariants.tscn`, NOT a bare `--script` SceneTree override — same reasoning
## as tests/t_combat_roundtrip.gd's doc comment, generalized: this file has no autoload
## dependency (RunMapGenerator/RunMapGraph/RunMapNode/Rng are all class_name-based pure
## logic), but a bare `--script` invocation was empirically confirmed to fail anyway on a
## COLD .godot/ cache (godot/.godot/ is gitignored, see .gitignore:43, so every fresh CI
## checkout starts cold) — GDScript's static analyzer doesn't resolve OTHER class_name
## scripts as known global identifiers until the project's global class cache has been
## populated by a prior editor/import pass, which `--script` mode skips entirely. Loading
## through a normal scene's `_ready()` (this file) goes through the standard bootstrap
## (same as MainMenu.tscn/DevReview.tscn) where the class cache is already resolvable,
## exactly like every other script in this project.

const SEED_COUNT := 10000
const DETERMINISM_SAMPLE := 20

func _ready() -> void:
	var start_ms := Time.get_ticks_msec()
	var pass_count := 0
	var fail_count := 0
	var first_failure := ""
	var first_failure_seed := -1

	for seed_value in SEED_COUNT:
		var mode := "short" if seed_value % 2 == 0 else "full"
		var ascension := seed_value % 11
		var rng := Rng.new(seed_value)
		var result := RunMapGenerator.generate_with_diagnostics(rng, mode, ascension)
		if result["graph"] != null:
			pass_count += 1
		else:
			fail_count += 1
			if first_failure == "":
				first_failure_seed = seed_value
				first_failure = "seed=%d mode=%s ascension=%d -> %s" % [
					seed_value, mode, ascension, ", ".join(result["violations"] as Array)]

		if seed_value % 2000 == 0:
			print("t_map_invariants: progress %d/%d..." % [seed_value, SEED_COUNT])

	var determinism_failures := _check_determinism()
	var elapsed_ms := Time.get_ticks_msec() - start_ms

	print("t_map_invariants: %d/%d seeds passed all 10 invariants (%d ms)" % [pass_count, SEED_COUNT, elapsed_ms])
	if fail_count > 0:
		print("t_map_invariants: FIRST FAILURE — %s" % first_failure)
	print("t_map_invariants: determinism spot-check %d/%d OK" % [DETERMINISM_SAMPLE - determinism_failures, DETERMINISM_SAMPLE])

	if fail_count == 0 and determinism_failures == 0:
		print("t_map_invariants: PASS — %d/%d seeds, %d/%d determinism checks OK" % [
			pass_count, SEED_COUNT, DETERMINISM_SAMPLE, DETERMINISM_SAMPLE])
		get_tree().quit(0)
	else:
		print("t_map_invariants: FAIL — %d/%d seeds failed (first at seed %d), %d/%d determinism mismatches" % [
			fail_count, SEED_COUNT, first_failure_seed, determinism_failures, DETERMINISM_SAMPLE])
		get_tree().quit(1)


## generate() called twice from a fresh Rng at the same seed must produce byte-identical
## to_data() output — this is the "generator is a pure function of the seed" guarantee the
## retry loop inside generate() depends on (architecture plan §7).
func _check_determinism() -> int:
	var mismatches := 0
	for i in DETERMINISM_SAMPLE:
		var seed_value := i * 7919 + 1
		var mode := "short" if i % 2 == 0 else "full"
		var ascension := i % 11
		var g1 := RunMapGenerator.generate(Rng.new(seed_value), mode, ascension)
		var g2 := RunMapGenerator.generate(Rng.new(seed_value), mode, ascension)
		if g1 == null or g2 == null:
			mismatches += 1
			continue
		if JSON.stringify(g1.to_data()) != JSON.stringify(g2.to_data()):
			mismatches += 1
	return mismatches
