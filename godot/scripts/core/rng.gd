class_name Rng
extends RefCounted
## Deterministic PRNG — direct port of the mulberry32 algorithm used by src/engine.js
## (see design/gdd/godot-port-rule-spec.md §2 and the architecture plan §5).
##
## Deliberately NOT Godot's RandomNumberGenerator (PCG32): this project's anti-cheat
## replay-verify and the DevReview "compare log against tools/sim.js" workflow both
## require bit-exact draws against the JS implementation. Do not swap this for the
## engine's built-in RNG without an ADR — see architecture plan §5, §9.
##
## Never register an instance of this as an autoload / global singleton. Gameplay RNG
## is owned by RunState (map generation) or CombatEngine (combat), passed explicitly.
## VFX/cosmetic randomness must use a separate instance so it can never perturb the
## gameplay draw sequence.

var _state: int = 0

func _init(seed_value: int) -> void:
	# JS: a=(a+0x6D2B79F5)>>>0 happens on first draw too, so store the raw seed and
	# apply the increment inside next_float() to match draw-for-draw.
	_state = seed_value & 0xFFFFFFFF

## Returns a float in [0, 1), identical draw-for-draw to engine.js's mkRng(seed)() calls.
func next_float() -> float:
	_state = (_state + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = _state
	t = _imul(t ^ (t >> 15), t | 1) & 0xFFFFFFFF
	t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0

## Integer in [0, n) — equivalent to JS `ri(n)` (Math.floor(rng()*n)).
func next_int(n: int) -> int:
	return int(floor(next_float() * n))

## Exposes the raw internal state for CombatEngine.to_data()/from_data() round-tripping
## (architecture plan §4 "to_data()/from_data() BẮT BUỘC ngay từ commit đầu"). Safe to
## restore later via `Rng.new(get_state())`: `_init()` just assigns `_state = seed_value`
## with no extra math (the mulberry32 increment only happens inside next_float()), so this
## is an exact position-in-stream snapshot, not merely a reseed.
func get_state() -> int:
	return _state

## Emulates JS Math.imul: 32-bit integer multiply with wraparound, no BigInt/overflow.
static func _imul(a: int, b: int) -> int:
	@warning_ignore("integer_division")
	var result: int = (a * b) & 0xFFFFFFFF
	return result

## Derives a combat seed from (run_seed, node_id, turn) instead of relying on a single
## continuously-advancing stream. This is what makes save/quit mid-combat, undo, scene
## reload, and DevReview's "jump straight into combat" all reproducible — see
## architecture plan §5. Uses a simple string hash (Godot's String.hash(), stable within
## a single engine version) folded through one more mulberry32 step for distribution.
static func derive_combat_seed(run_seed: int, node_id: String, turn: int) -> int:
	var h: int = ("%d:%s:%d" % [run_seed, node_id, turn]).hash() & 0xFFFFFFFF
	var r := Rng.new(h)
	return int(r.next_float() * 4294967296.0) & 0xFFFFFFFF
