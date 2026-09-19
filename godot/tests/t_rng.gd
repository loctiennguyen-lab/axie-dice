extends SceneTree
## Headless RNG parity gate — compares Rng (mulberry32 port) draws against a reference
## dump taken from the real src/engine.js mkRng() via Node, for the same seed. See
## architecture plan §5, §9 ("t_rng.gd: so 10.000 draw mulberry32 Godot vs dump Node").
## Run: godot --headless --path godot --script tests/t_rng.gd
##
## Reference dump generated 2026-09-17 via:
##   node -e "…mkRng(12345)… 10000 draws… fs.writeFileSync('rng_reference_seed12345.json', ...)"
## against src/engine.js's mkRng (engine.js:20). If that function ever changes, regenerate
## this dump (tools/ on the JS side has the reference implementation) before trusting this gate.

const REFERENCE_SEED := 12345
const REFERENCE_PATH := "res://tests/rng_reference_seed12345.json"
const EPSILON := 1e-9

func _initialize() -> void:
	var f := FileAccess.open(REFERENCE_PATH, FileAccess.READ)
	if f == null:
		push_error("t_rng: could not open %s" % REFERENCE_PATH)
		quit(1)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_error("t_rng: reference file did not contain a JSON array")
		quit(1)
		return

	var reference: Array = parsed
	var rng := Rng.new(REFERENCE_SEED)
	var failures := 0
	var first_failure_index := -1
	for i in reference.size():
		var got: float = rng.next_float()
		var want: float = reference[i]
		if absf(got - want) > EPSILON:
			failures += 1
			if first_failure_index == -1:
				first_failure_index = i
				push_error("t_rng: first mismatch at draw %d — got %.17g, want %.17g" % [
					i, got, want])

	if failures == 0:
		print("t_rng: PASS — %d/%d draws match src/engine.js mkRng(%d) bit-for-bit" % [
			reference.size(), reference.size(), REFERENCE_SEED])
	else:
		print("t_rng: FAIL — %d/%d draws mismatched (first at index %d)" % [
			failures, reference.size(), first_failure_index])
	quit(failures)
